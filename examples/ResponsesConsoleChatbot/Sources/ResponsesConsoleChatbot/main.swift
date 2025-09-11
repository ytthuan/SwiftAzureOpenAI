import Foundation
import SwiftAzureOpenAI

// MARK: - ResponsesConsoleManager

/// Console-only variant of ResponsesChatManager.
/// Swift conversion of the Python script focusing on:
/// - Streaming Azure Responses API events to stdout
/// - Supporting a simple in-file calculation tool (sum_calculator)
/// - Supporting code_interpreter tool (no file/image handling)
final class ResponsesConsoleManager {
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

extension ResponsesConsoleManager {
    
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

// MARK: - Streaming Response Handler

extension ResponsesConsoleManager {
    
    func respondStreaming(userText: String) async throws {
        var previousResponseId: String? = lastResponseId
        let tools = buildFunctionTools(includeCodeInterpreter: true)
        
        var currentResponseId: String? = nil
        
        // Track function metadata and arguments across stream
        var functionMetaByItemId: [String: [String: String]] = [:]
        var functionArgsByItemId: [String: String] = [:]
        var processedFunctionCallIds: Set<String> = []
        
        while true {
            var outputsForModel: [SAOAIInputContent.FunctionCallOutput] = []
            var assistantMessageCompleted = false
            
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
            
            // Start streaming
            let stream = client.responses.createStreaming(
                model: model,
                input: inputMessages,
                maxOutputTokens: nil,
                tools: tools,
                previousResponseId: previousResponseId,
                reasoning: reasoning,
                text: text
            )
            
            try await processStreamingEvents(
                stream: stream,
                functionMetaByItemId: &functionMetaByItemId,
                functionArgsByItemId: &functionArgsByItemId,
                processedFunctionCallIds: &processedFunctionCallIds,
                outputsForModel: &outputsForModel,
                assistantMessageCompleted: &assistantMessageCompleted,
                lastResponseId: &currentResponseId
            )
            
            // Handle function call outputs if any
            if !outputsForModel.isEmpty {
                // Set up for next iteration with function outputs
                previousResponseId = currentResponseId
                
                // Create a new stream with function outputs
                let outputStream = client.responses.createStreaming(
                    model: model,
                    functionCallOutputs: outputsForModel,
                    previousResponseId: previousResponseId
                )
                
                // Process the response to function calls
                try await processFunctionResponseStream(
                    stream: outputStream,
                    lastResponseId: &currentResponseId
                )
                
                // Persist latest response id for future turns
                self.lastResponseId = currentResponseId
                
                break // Exit after processing function responses
            }
            
            if assistantMessageCompleted {
                // Persist latest response id for future turns
                self.lastResponseId = currentResponseId
                break
            }
            
            break
        }
    }
    
    private func processStreamingEvents(
        stream: AsyncThrowingStream<SAOAIStreamingResponse, Error>,
        functionMetaByItemId: inout [String: [String: String]],
        functionArgsByItemId: inout [String: String],
        processedFunctionCallIds: inout Set<String>,
        outputsForModel: inout [SAOAIInputContent.FunctionCallOutput],
        assistantMessageCompleted: inout Bool,
        lastResponseId: inout String?
    ) async throws {
        
        // Track reasoning state for enhanced display
        var reasoningStartTime: Date?
        var reasoningDotCount = 0
        // write to file
        for try await event in stream {
            guard let eventType = event.eventType else { continue }
            
            // Show reasoning progress if reasoning is active
            if let startTime = reasoningStartTime {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > Double(reasoningDotCount) * 0.5 { // Add dot every 0.5 seconds
                    print(".", terminator: "")
                    reasoningDotCount += 1
                }
            }
            
            switch eventType {
            case .responseOutputItemAdded:
                if let item = event.item {
                    switch item.type {
                    case .message:
                        print("[assistant]:", terminator: "")
                    case .codeInterpreterCall:
                        let containerId = item.containerId ?? "unknown"
                        print("\n[tool] Code Interpreter started (container: \(containerId))")
                    case .functionCall:
                        let name = item.name ?? "Function Call"
                        let callId = item.callId ?? ""
                        functionMetaByItemId[item.id ?? ""] = ["name": name, "call_id": callId]
                        print("\n[tool] Function started: \(name) (call_id: \(callId))")
                    case .reasoning:
                        print("\n[reasoning] Analyzing request", terminator: "")
                        reasoningStartTime = Date()
                    default:
                        break
                    }
                }
                
            case .responseOutputTextDelta:
                if let output = event.output?.first,
                   let content = output.content?.first,
                   let text = content.text {
                    print(text, terminator: "")
                    
                }
            
            // Reasoning streams - these should display actual reasoning content as it arrives
            case .responseReasoningDelta:
                if let output = event.output?.first,
                   let content = output.content?.first,
                   let text = content.text, !text.isEmpty {
                    print(" \(text)", terminator: "")
                }
            case .responseReasoningSummaryDelta, .responseReasoningSummaryTextDelta:
                if let output = event.output?.first,
                   let content = output.content?.first,
                   let text = content.text, !text.isEmpty {
                    print(" \(text)", terminator: "")
                }
                
            case .responseCodeInterpreterCallCodeDelta, .responseFunctionCallArgumentsDelta:
                if let output = event.output?.first,
                   let content = output.content?.first,
                   let text = content.text {
                    
                    if eventType == .responseFunctionCallArgumentsDelta {
                        // Some delta events omit item; fall back to event.id which matches the function item id
                        let idForArgs = event.item?.id ?? event.id ?? ""
                        if !idForArgs.isEmpty {
                            if functionArgsByItemId[idForArgs] == nil {
                                functionArgsByItemId[idForArgs] = ""
                            }
                            functionArgsByItemId[idForArgs]! += text
                        }
                    } else {
                        // Stream code being executed by the interpreter
                        print(text, terminator: "")
                        
                    }
                }
                
            case .responseCodeInterpreterCallCompleted:
                print("\n[tool] Code Interpreter completed")
                
            case .responseReasoningDone, .responseReasoningSummaryDone, .responseReasoningSummaryTextDone:
                // Add a soft separator when reasoning sections complete
                print("", terminator: "")
                
            case .responseFunctionCallArgumentsDone:
                // Use event.id fallback when item is omitted on 'arguments.done'
                let itemId = event.item?.id ?? event.id ?? ""
                if !itemId.isEmpty,
                   let meta = functionMetaByItemId[itemId],
                   let funcName = meta["name"] {
                    let argsStr = functionArgsByItemId[itemId] ?? ""
                    let snippet = argsStr.count > 300 ? "\(argsStr.prefix(200)) ... \(argsStr.suffix(80))" : argsStr
                    print("[tool] \(funcName) arguments: \(snippet)")
                }
                
            case .responseOutputItemDone:
                // Prefer explicit item.id; fall back to event.id when necessary
                let itemId = event.item?.id ?? event.id ?? ""
                if let item = event.item, item.type == .functionCall, !itemId.isEmpty {
                    if let meta = functionMetaByItemId[itemId],
                       let funcName = meta["name"],
                       let callIdForSubmit = meta["call_id"],
                       !processedFunctionCallIds.contains(callIdForSubmit) {
                        
                        let rawArgs = functionArgsByItemId[itemId] ?? ""
                        
                        let resultStr = await runFunctionCall(funcName: funcName, rawArgs: rawArgs)
                        let preview = resultStr.count > 4000 ? "\(resultStr.prefix(2000)) ... \(resultStr.suffix(1500))" : resultStr
                        print("[tool] \(funcName) result: \(preview)")
                        
                        outputsForModel.append(SAOAIInputContent.FunctionCallOutput(
                            callId: callIdForSubmit,
                            output: resultStr
                        ))
                        processedFunctionCallIds.insert(callIdForSubmit)
                    }
                }
                
                if let item = event.item, 
                   item.type == .message,
                   item.status == "completed" {
                    assistantMessageCompleted = true
                    print("")
                }
                
                if let item = event.item, item.type == .reasoning {
                    reasoningStartTime = nil // Reset reasoning tracking
                    // Display reasoning summary if available
                    if let summary = item.summary, !summary.isEmpty {
                        let summaryText = summary.joined(separator: " ")
                        print("\n[reasoning] \(summaryText)")
                    } else {
                        print("\n[reasoning] Analysis complete")
                    }
                }
                
            case .responseCompleted:
                if let responseId = event.id {
                    lastResponseId = responseId
                }
                
            default:
                // Handle other event types as needed
                break
            }
        }
    }
    
    private func processFunctionResponseStream(
        stream: AsyncThrowingStream<SAOAIStreamingResponse, Error>,
        lastResponseId: inout String?
    ) async throws {
        
        for try await event in stream {
            guard let eventType = event.eventType else { continue }
            
            switch eventType {
            case .responseOutputTextDelta:
                if let output = event.output?.first,
                   let content = output.content?.first,
                   let text = content.text {
                    print(text, terminator: "")
                    
                }
            // Reasoning streams in function response stage
            case .responseReasoningDelta:
                if let output = event.output?.first,
                   let content = output.content?.first,
                   let text = content.text, !text.isEmpty {
                    print("[reasoning] \(text)", terminator: "")
                }
            case .responseReasoningSummaryDelta, .responseReasoningSummaryTextDelta:
                if let output = event.output?.first,
                   let content = output.content?.first,
                   let text = content.text, !text.isEmpty {
                    print("[reasoning-summary] \(text)", terminator: "")
                }
                
            case .responseCompleted:
                if let responseId = event.id {
                    lastResponseId = responseId
                }
                print("") // New line after completion
                
            case .responseReasoningDone, .responseReasoningSummaryDone, .responseReasoningSummaryTextDone:
                print("", terminator: "")
                
            default:
                break
            }
        }
    }
}

// MARK: - Console Interface

extension ResponsesConsoleManager {
    
    static func console(model: String, instructions: String = "", reasoningEffort: String? = nil, reasoningSummary: String? = nil, textVerbosity: String? = nil, inputMessage: String? = nil) async throws {
        let manager = try ResponsesConsoleManager(
            model: model,
            instructions: instructions,
            reasoningEffort: reasoningEffort,
            reasoningSummary: reasoningSummary,
            textVerbosity: textVerbosity
        )
        
        print("Model: \(model)")
        
        // If input message is provided, use it once and exit
        if let message = inputMessage {
            print("You: \(message)")
            do {
                try await manager.respondStreaming(userText: message)
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
                try await manager.respondStreaming(userText: userText)
            } catch {
                print("[error] \(error.localizedDescription)")
            }
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
struct ResponsesConsoleChatbotApp {
    static func main() async {
        // Parse command line arguments
        let arguments = CommandLine.arguments
        var model = ProcessInfo.processInfo.environment["DEFAULT_MODEL"] ?? "gpt-5-mini"
        var instructions = ProcessInfo.processInfo.environment["DEFAULT_INSTRUCTIONS"] ?? ""
        var reasoningEffort: String? = ProcessInfo.processInfo.environment["DEFAULT_REASONING_EFFORT"]
        var reasoningSummary: String? = ProcessInfo.processInfo.environment["DEFAULT_REASONING_SUMMARY"]
        var textVerbosity: String? = ProcessInfo.processInfo.environment["DEFAULT_TEXT_VERBOSITY"]
        var inputMessage: String? = nil
        
        // Simple argument parsing
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
        
        print("🤖 SwiftAzureOpenAI Responses Console Chatbot")
        print("=============================================")
        print("Console chat using Azure Responses API (no UI)")
        if inputMessage == nil {
            print("Type 'exit' or 'quit' to stop.")
            print("Try: 'can you use tool to calculate 10 plus 22'")
        }
        print("=============================================")
        
        do {
            try await ResponsesConsoleManager.console(
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
        print("ResponsesConsoleChatbot - Swift Azure OpenAI console chatbot")
        print("")
        print("Usage:")
        print("  ResponsesConsoleChatbot [options]")
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
        print("Environment Variables:")
        print("  AZURE_OPENAI_ENDPOINT       Azure OpenAI endpoint (required)")
        print("  AZURE_OPENAI_API_KEY        Azure OpenAI API key")
        print("  AZURE_OPENAI_DEPLOYMENT     Azure OpenAI deployment name")
        print("  DEFAULT_MODEL               Default model name")
        print("  DEFAULT_INSTRUCTIONS        Default system instructions")
        print("  DEFAULT_REASONING_EFFORT    Default reasoning effort")
        print("  DEFAULT_REASONING_SUMMARY   Default reasoning summary")
        print("  DEFAULT_TEXT_VERBOSITY      Default text verbosity")
        print("")
        print("Examples:")
        print("  ResponsesConsoleChatbot --reasoning high --reasoning-summary detailed --text-verbosity low --message \"Explain quantum physics\"")
        print("  ResponsesConsoleChatbot --reasoning medium --reasoning-summary auto --message \"Calculate the square root of 144\"")
        print("  ResponsesConsoleChatbot --model gpt-5-nano --instructions \"You are a helpful assistant\"")
    }
}