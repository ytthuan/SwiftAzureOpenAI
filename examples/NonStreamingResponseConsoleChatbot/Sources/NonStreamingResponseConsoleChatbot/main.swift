import Foundation
import SwiftAzureOpenAI

// MARK: - NonStreamingResponsesManager

/// Non-streaming console variant for Azure Responses API.
/// Focused specifically on blocking, non-streaming responses with user-controlled function calling.
/// This example demonstrates:
/// - Non-streaming Azure Responses API requests
/// - User-controlled function calling (no automatic loops)
/// - Simple calculation tool and code interpreter support
/// - Reasoning, function calls, and code interpreter in blocking mode
final class NonStreamingResponsesManager {
    private let client: SAOAIClient
    private let model: String
    private let instructions: String
    private let reasoningEffort: String?
    private let reasoningSummary: String?
    private let textVerbosity: String?
    private var lastResponseId: String?
    
    // Local function tool handlers implemented in this file only
    private var functionHandlers: [String: (String) async throws -> String] = [:]
    
    init(model: String, instructions: String, reasoningEffort: String? = nil, reasoningSummary: String? = nil, textVerbosity: String? = nil) throws {
        // Get Azure OpenAI configuration from environment
        guard let azureEndpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] else {
            throw RuntimeError("AZURE_OPENAI_ENDPOINT is not set")
        }
        
        // Use API key authentication as specified in the issue  
        let apiKey = ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ??
                    ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"] ??
                    "your-api-key"
        
        let deploymentName = ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? model

        let mainFileURL = URL(fileURLWithPath: #filePath)
        let logDirectoryURL = mainFileURL.deletingLastPathComponent()
        let logPath = logDirectoryURL.appendingPathComponent("sse_events.log").path
        
        // Enable SSE logger via configuration so core pipeline logs events
        let sseConfig = SSELoggerConfiguration.enabled(
            logFilePath: logPath,
            includeTimestamp: true,
            includeSequenceNumber: true
        )
        
        // Create Azure configuration with "preview" API version as required
        let azureConfig = SAOAIAzureConfiguration(
            endpoint: azureEndpoint,
            apiKey: apiKey,
            deploymentName: deploymentName,
            apiVersion: "preview",  // Required API version from issue
            sseLoggerConfiguration: sseConfig
        )
        
        self.client = SAOAIClient(configuration: azureConfig)
        self.model = model
        self.instructions = instructions
        self.reasoningEffort = reasoningEffort
        self.reasoningSummary = reasoningSummary
        self.textVerbosity = textVerbosity
        
        // Set up function handlers
        setupFunctionHandlers()
    }
    
    private func setupFunctionHandlers() {
        functionHandlers["sum_calculator"] = handleSumCalculator
    }
}

// MARK: - Function Tool Definitions

extension NonStreamingResponsesManager {
    
    private func sumCalculatorDefinition() -> SAOAITool {
        return SAOAITool.function(
            name: "sum_calculator",
            description: "Calculates the sum of two numbers.",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "a": .object([
                        "type": .string("number"),
                        "description": .string("The first number.")
                    ]),
                    "b": .object([
                        "type": .string("number"),
                        "description": .string("The second number.")
                    ])
                ]),
                "required": .array([.string("a"), .string("b")])
            ])
        )
    }
    
    private func handleSumCalculator(args: String) async throws -> String {
        do {
            print("args: \(args)")
            guard let data = args.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return "{\"error\": \"Invalid JSON arguments\"}"
            }

            
            let a = json["a"] as? Double ?? 0
            let b = json["b"] as? Double ?? 0
            
            // Validate numeric inputs
            if !json.keys.contains("a") || !json.keys.contains("b") {
                return "{\"error\": \"Parameters 'a' and 'b' must be provided.\"}"
            }
            
            let result = a + b
            let resultJson = ["result": result]
            let resultData = try JSONSerialization.data(withJSONObject: resultJson)
            return String(data: resultData, encoding: .utf8) ?? "{\"error\": \"Failed to serialize result\"}"
            
        } catch {
            return "{\"error\": \"\(error.localizedDescription)\"}"
        }
    }
    
    private func buildFunctionTools(includeCodeInterpreter: Bool = true, includeSumCalculator: Bool = true) -> [SAOAITool] {
        var tools: [SAOAITool] = []
        
        if includeCodeInterpreter {
            tools.append(SAOAITool.codeInterpreter())
        }
        
        if includeSumCalculator {
            tools.append(sumCalculatorDefinition())
        }
        
        return tools
    }
    
    private func runFunctionCall(funcName: String, rawArgs: String) async -> String {
        let args: String
        if rawArgs.isEmpty {
            args = "{}"
        } else {
            args = rawArgs
        }
        
        guard let handler = functionHandlers[funcName] else {
            return "{\"error\": \"Requested function '\(funcName)' is not available.\"}"
        }
        
        do {
            let result = try await handler(args)
            return result
        } catch {
            return "{\"error\": \"\(error.localizedDescription)\"}"
        }
    }
}

// MARK: - Non-Streaming Response Handler

extension NonStreamingResponsesManager {
    
    func respond(userText: String) async throws -> [SAOAIInputContent.FunctionCallOutput]? {
        let tools = buildFunctionTools(includeCodeInterpreter: true)
        
        // Create user message
        let userMessage = SAOAIMessage(role: .user, text: userText)
        let inputMessages = [userMessage]
        
        // Create flexible reasoning configuration with new summary support
        let reasoning: SAOAIReasoning? = reasoningEffort.map { effort in
            if let summary = reasoningSummary {
                return SAOAIReasoning(effort: effort, summary: summary)
            } else {
                return SAOAIReasoning(effort: effort)
            }
        }
        
        // Create text configuration for verbosity control
        let text: SAOAIText? = textVerbosity.map { SAOAIText(verbosity: $0) }
        
        if let effort = reasoningEffort {
            let summaryText = reasoningSummary ?? "none"
            let verbosityText = textVerbosity ?? "default"
            print("[debug] flexible reasoning enabled (effort=\(effort), summary=\(summaryText), verbosity=\(verbosityText))")
        }
        
        // Make non-streaming request
        let response = try await client.responses.create(
            model: model,
            input: inputMessages,
            maxOutputTokens: nil,
            tools: tools,
            previousResponseId: lastResponseId,
            reasoning: reasoning,
            text: text
        )
        
        // Update last response ID
        self.lastResponseId = response.id
        
        // Process the response and extract function calls
        let functionCallOutputs = try await processNonStreamingResponse(response)
        
        return functionCallOutputs.isEmpty ? nil : functionCallOutputs
    }
    
    func continueWithFunctionOutputs(_ functionCallOutputs: [SAOAIInputContent.FunctionCallOutput]) async throws -> [SAOAIInputContent.FunctionCallOutput]? {
        let tools = buildFunctionTools(includeCodeInterpreter: true)
        
        // Make non-streaming request with function call outputs
        let response = try await client.responses.createWithFunctionCallOutputs(
            model: model,
            functionCallOutputs: functionCallOutputs,
            maxOutputTokens: nil,
            tools: tools,
            previousResponseId: lastResponseId
        )
        
        // Update last response ID
        self.lastResponseId = response.id
        
        // Process the response and extract any new function calls
        let newFunctionCallOutputs = try await processNonStreamingResponse(response)
        
        return newFunctionCallOutputs.isEmpty ? nil : newFunctionCallOutputs
    }
    
    private func processNonStreamingResponse(_ response: SAOAIResponse) async throws -> [SAOAIInputContent.FunctionCallOutput] {
        var functionCallOutputs: [SAOAIInputContent.FunctionCallOutput] = []
        
        // Process each output item in the response
        for output in response.output {
            
            // Handle different output types based on the type field
            if let type = output.type {
                switch type {
                case "reasoning":
                    // Display reasoning summary if available
                    if let summary = output.summary, !summary.isEmpty {
                        let summaryText = summary.joined(separator: " ")
                        print("\n[reasoning] \(summaryText)")
                    }
                    
                case "function_call":
                    // Handle function call at the output level
                    if let name = output.name,
                       let callId = output.callId,
                       let arguments = output.arguments {
                        
                        print("\n[tool] Function started: \(name) (call_id: \(callId))")
                        let snippet = arguments.count > 300 ? "\(arguments.prefix(200)) ... \(arguments.suffix(80))" : arguments
                        print("[tool] \(name) arguments: \(snippet)")
                        
                        // Execute the function call
                        let resultStr = await runFunctionCall(funcName: name, rawArgs: arguments)
                        let preview = resultStr.count > 4000 ? "\(resultStr.prefix(2000)) ... \(resultStr.suffix(1500))" : resultStr
                        print("[tool] \(name) result: \(preview)")
                        
                        // Add to function call outputs for potential continuation
                        functionCallOutputs.append(SAOAIInputContent.FunctionCallOutput(
                            callId: callId,
                            output: resultStr
                        ))
                    }
                    
                default:
                    // Handle other output types at the content level
                    break
                }
            }
            
            // Process content array if present
            if let contentArray = output.content {
                for content in contentArray {
                    switch content {
                    case .outputText(let textContent):
                        print("[assistant]: \(textContent.text)")
                        
                    case .functionCall(let functionContent):
                        print("\n[tool] Function started: \(functionContent.name) (call_id: \(functionContent.callId))")
                        let snippet = functionContent.arguments.count > 300 ? "\(functionContent.arguments.prefix(200)) ... \(functionContent.arguments.suffix(80))" : functionContent.arguments
                        print("[tool] \(functionContent.name) arguments: \(snippet)")
                        
                        // Execute the function call
                        let resultStr = await runFunctionCall(funcName: functionContent.name, rawArgs: functionContent.arguments)
                        let preview = resultStr.count > 4000 ? "\(resultStr.prefix(2000)) ... \(resultStr.suffix(1500))" : resultStr
                        print("[tool] \(functionContent.name) result: \(preview)")
                        
                        // Add to function call outputs for potential continuation
                        functionCallOutputs.append(SAOAIInputContent.FunctionCallOutput(
                            callId: functionContent.callId,
                            output: resultStr
                        ))
                    }
                }
            }
        }
        
        if !functionCallOutputs.isEmpty {
            print("") // Add line break after function calls
        }
        
        return functionCallOutputs
    }
}

// MARK: - Console Interface

extension NonStreamingResponsesManager {
    
    static func console(model: String, instructions: String = "", reasoningEffort: String? = nil, reasoningSummary: String? = nil, textVerbosity: String? = nil, inputMessage: String? = nil) async throws {
        let manager = try NonStreamingResponsesManager(
            model: model,
            instructions: instructions,
            reasoningEffort: reasoningEffort,
            reasoningSummary: reasoningSummary,
            textVerbosity: textVerbosity
        )
        
        print("Model: \(model) (Non-streaming mode)")
        print("Function calling: User-controlled (max 5 rounds)")
        
        // If input message is provided, use it once and exit
        if let message = inputMessage {
            print("You: \(message)")
            do {
                try await handleUserMessage(manager: manager, message: message)
            } catch {
                print("[error] \(error.localizedDescription)")
            }
            return
        }
        
        // Interactive mode
        while true {
            print("You: ", terminator: "")
            
            guard let userText = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !userText.isEmpty else {
                continue
            }
            
            // Check for exit commands
            if userText.lowercased() == "exit" || userText.lowercased() == "quit" {
                print("Exiting.")
                break
            }
            
            do {
                try await handleUserMessage(manager: manager, message: userText)
            } catch {
                print("[error] \(error.localizedDescription)")
            }
        }
    }
    
    private static func handleUserMessage(manager: NonStreamingResponsesManager, message: String) async throws {
        // User-controlled function calling with configurable maximum rounds
        let maxFunctionCallRounds = 5
        var currentRound = 0
        
        // Initial response
        var functionCallOutputs = try await manager.respond(userText: message)
        
        // Continue function calling rounds based on user-defined logic
        while let outputs = functionCallOutputs, currentRound < maxFunctionCallRounds {
            currentRound += 1
            print("[debug] Function call round \(currentRound)/\(maxFunctionCallRounds)")
            
            functionCallOutputs = try await manager.continueWithFunctionOutputs(outputs)
        }
        
        if currentRound >= maxFunctionCallRounds {
            print("[debug] Maximum function call rounds (\(maxFunctionCallRounds)) reached")
        }
    }
}

// MARK: - Runtime Error

struct RuntimeError: Error, LocalizedError {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var errorDescription: String? {
        return message
    }
}

// MARK: - Main Entry Point

@main
struct NonStreamingResponseConsoleChatbotApp {
    static func main() async {
        // Parse command line arguments
        let arguments = CommandLine.arguments
        var model = ProcessInfo.processInfo.environment["DEFAULT_MODEL"] ?? "gpt-5-mini"
        var instructions = ProcessInfo.processInfo.environment["DEFAULT_INSTRUCTIONS"] ?? ""
        var reasoningEffort: String? = ProcessInfo.processInfo.environment["DEFAULT_REASONING_EFFORT"]
        var reasoningSummary: String? = ProcessInfo.processInfo.environment["DEFAULT_REASONING_SUMMARY"]
        var textVerbosity: String? = ProcessInfo.processInfo.environment["DEFAULT_TEXT_VERBOSITY"]
        var inputMessage: String? = nil
        
        // Simple argument parsing (no streaming options since this is non-streaming only)
        var i = 1
        while i < arguments.count {
            switch arguments[i] {
            case "--model":
                if i + 1 < arguments.count {
                    model = arguments[i + 1]
                    i += 1
                }
            case "--instructions":
                if i + 1 < arguments.count {
                    instructions = arguments[i + 1]
                    i += 1
                }
            case "--reasoning":
                if i + 1 < arguments.count {
                    let value = arguments[i + 1]
                    reasoningEffort = ["low", "medium", "high"].contains(value) ? value : nil
                    i += 1
                }
            case "--reasoning-summary":
                if i + 1 < arguments.count {
                    let value = arguments[i + 1]
                    reasoningSummary = ["auto", "concise", "detailed"].contains(value) ? value : nil
                    i += 1
                }
            case "--text-verbosity":
                if i + 1 < arguments.count {
                    let value = arguments[i + 1]
                    textVerbosity = ["low", "medium", "high"].contains(value) ? value : nil
                    i += 1
                }
            case "--message":
                if i + 1 < arguments.count {
                    inputMessage = arguments[i + 1]
                    i += 1
                }
            case "--help":
                printHelp()
                return
            default:
                break
            }
            i += 1
        }
        
        print("🤖 SwiftAzureOpenAI Non-Streaming Responses Console Chatbot")
        print("============================================================")
        print("Console chat using Azure Responses API in blocking mode (no streaming)")
        print("Mode: Non-streaming with user-controlled function calling")
        if inputMessage == nil {
            print("Type 'exit' or 'quit' to stop.")
            print("Try: 'can you use tool to calculate 10 plus 22'")
        }
        print("============================================================")
        
        do {
            try await NonStreamingResponsesManager.console(
                model: model,
                instructions: instructions,
                reasoningEffort: reasoningEffort,
                reasoningSummary: reasoningSummary,
                textVerbosity: textVerbosity,
                inputMessage: inputMessage
            )
        } catch {
            print("Failed to start console: \(error.localizedDescription)")
        }
    }
    
    static func printHelp() {
        print("NonStreamingResponseConsoleChatbot - Swift Azure OpenAI non-streaming console chatbot")
        print("")
        print("Usage:")
        print("  NonStreamingResponseConsoleChatbot [options]")
        print("")
        print("Options:")
        print("  --model MODEL            Model to use (default: gpt-5-mini)")
        print("  --instructions TEXT      System instructions")
        print("  --reasoning EFFORT       Reasoning effort: low, medium, high")
        print("  --reasoning-summary TYPE Reasoning summary: auto, concise, detailed")
        print("  --text-verbosity LEVEL   Text verbosity: low, medium, high")
        print("  --message TEXT           Single message to send (non-interactive)")
        print("  --help                   Show this help")
        print("")
        print("Mode:")
        print("  This example runs in non-streaming mode only - all responses are")
        print("  returned as complete blocks rather than streaming in real-time.")
        print("")
        print("Function Calling:")
        print("  User-controlled function calling with max 5 rounds per conversation.")
        print("  SDK returns function call outputs to user instead of automatic loops.")
        print("  User decides when and how many times to continue function calling.")
        print("")
        print("Environment Variables:")
        print("  AZURE_OPENAI_ENDPOINT       Azure OpenAI endpoint (required)")
        print("  AZURE_OPENAI_API_KEY        Azure OpenAI API key")
        print("  COPILOT_AGENT_AZURE_OPENAI_API_KEY  Alternative API key")
        print("  AZURE_OPENAI_DEPLOYMENT     Azure OpenAI deployment name")
        print("  DEFAULT_MODEL               Default model name")
        print("  DEFAULT_INSTRUCTIONS        Default system instructions")
        print("  DEFAULT_REASONING_EFFORT    Default reasoning effort")
        print("  DEFAULT_REASONING_SUMMARY   Default reasoning summary")
        print("  DEFAULT_TEXT_VERBOSITY      Default text verbosity")
        print("")
        print("Examples:")
        print("  # Interactive non-streaming mode")
        print("  NonStreamingResponseConsoleChatbot")
        print("")
        print("  # Single message with function calls (user controls iterations)")
        print("  NonStreamingResponseConsoleChatbot --message \"calculate 10 plus 22\"")
        print("")
        print("  # Advanced reasoning in blocking mode")
        print("  NonStreamingResponseConsoleChatbot --reasoning high --reasoning-summary detailed --text-verbosity low --message \"Explain quantum physics\"")
        print("")
        print("  # Simple calculation with reasoning")
        print("  NonStreamingResponseConsoleChatbot --reasoning medium --reasoning-summary auto --message \"Calculate the square root of 144\"")
    }
}