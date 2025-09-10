import Foundation
import SwiftAzureOpenAI

// MARK: - Enhanced Event Handling Structures

/// Step management for tracking tool calls and their UI representation
class StepManager {
    var toolSteps: [String: ConsoleStep] = [:]  // item_id -> step
    var itemSteps: [String: ConsoleStep] = [:]  // item_id -> step  
    var functionNameToStep: [String: ConsoleStep] = [:]  // function_name -> step
    var functionArgsByItemId: [String: String] = [:]  // item_id -> accumulated args
    var functionMetaByItemId: [String: FunctionMetadata] = [:]  // item_id -> metadata
    var stepInputsByFuncName: [String: String] = [:]  // function_name -> accumulated input
    var stepOutputsByFuncName: [String: String] = [:]  // function_name -> accumulated output
    var processedFunctionCallIds: Set<String> = []  // call_id set
    
    struct FunctionMetadata {
        let name: String
        let callId: String
    }
}

/// Console representation of a tool step
class ConsoleStep {
    let name: String
    let type: String
    var input: String = ""
    var output: String = ""
    var language: String = ""
    var showInput: String = ""
    
    init(name: String, type: String, language: String = "") {
        self.name = name
        self.type = type
        self.language = language
    }
    
    func streamToken(_ text: String, isInput: Bool = false) {
        if isInput {
            input += text
        } else {
            output += text
        }
    }
    
    func update() {
        // In a real UI, this would update the display
        // For console, we'll handle this in the display logic
    }
}

/// Console representation of a message
class ConsoleMessage {
    var content: String = ""
    let metadata: [String: Any]
    let parentId: String?
    
    init(content: String = "", metadata: [String: Any] = [:], parentId: String? = nil) {
        self.content = content
        self.metadata = metadata
        self.parentId = parentId
    }
    
    func streamToken(_ text: String) {
        content += text
    }
    
    func update() {
        // In a real UI, this would update the display
    }
}

// MARK: - Advanced Console Chatbot Example

/// Comprehensive console chatbot demonstrating all SwiftAzureOpenAI features:
/// - Interactive console interface
/// - Function calling (weather API example)
/// - Code interpreter tool support
/// - Multi-modal support (images via URL and base64)
/// - Response chaining with conversation history
/// - Tool result processing and display

// MARK: - Configuration
let azureConfig: SAOAIAzureConfiguration = {
    // Default config
    let endpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] ?? "https://your-resource.openai.azure.com"
    let apiKey = ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ?? ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"] ?? "your-api-key"
    let deployment = ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? "gpt-4o"
    let apiVersion = "preview"
    
    // Build log path next to this main.swift for consistency
    let mainFileURL = URL(fileURLWithPath: #filePath)
    let logDirectoryURL = mainFileURL.deletingLastPathComponent()
    let logPath = logDirectoryURL.appendingPathComponent("sse_events.log").path
    
    // Enable SSE logger via configuration so core pipeline logs events
    let sseConfig = SSELoggerConfiguration.enabled(
        logFilePath: logPath,
        includeTimestamp: true,
        includeSequenceNumber: true
    )
    
    return SAOAIAzureConfiguration(
        endpoint: endpoint,
        apiKey: apiKey,
        deploymentName: deployment,
        apiVersion: apiVersion,
        sseLoggerConfiguration: sseConfig
    )
}()

let client = SAOAIClient(configuration: azureConfig)

// MARK: - Tool Definitions

/// Weather API function tool
let weatherTool = SAOAITool.function(
    name: "get_weather",
    description: "Get current weather information for a specified location",
    parameters: .object([
        "type": .string("object"),
        "properties": .object([
            "location": .object([
                "type": .string("string"),
                "description": .string("The city and state/country, e.g. 'San Francisco, CA' or 'London, UK'")
            ]),
            "unit": .object([
                "type": .string("string"),
                "enum": .array([.string("celsius"), .string("fahrenheit")]),
                "description": .string("Temperature unit preference")
            ])
        ]),
        "required": .array([.string("location"), .string("unit")])
    ])
)

/// Code interpreter tool (custom implementation for demonstration)
let codeInterpreterTool = SAOAITool.codeInterpreter()

/// Math calculator function tool
let calculatorTool = SAOAITool.function(
    name: "calculate",
    description: "Perform mathematical calculations",
    parameters: .object([
        "type": .string("object"),
        "properties": .object([
            "expression": .object([
                "type": .string("string"),
                "description": .string("Mathematical expression to evaluate, e.g. '2 + 2' or 'sqrt(16)'")
            ])
        ]),
        "required": .array([.string("expression")])
    ])
)

// MARK: - Tool Implementations

struct ToolExecutor {
    /// Simulate weather API call
    static func getWeather(location: String, unit: String = "celsius") -> String {
        let temperatures = ["22°C", "18°C", "25°C", "15°C", "28°C"]
        let conditions = ["sunny", "cloudy", "rainy", "partly cloudy", "overcast"]
        
        let temp = temperatures.randomElement() ?? "20°C"
        let condition = conditions.randomElement() ?? "partly cloudy"
        
        let convertedTemp = unit == "fahrenheit" ? 
            "\(Int.random(in: 60...85))°F" : temp
        
        return """
        {"location": "\(location)", "temperature": "\(convertedTemp)", "condition": "\(condition)", "humidity": "\(Int.random(in: 30...80))%", "wind_speed": "\(Int.random(in: 5...25)) km/h", "unit": "\(unit)"}
        """
    }
    
    /// Simulate code interpreter execution
    static func executeCode(_ code: String) -> String {
        // Simulate various Python code execution results
        if code.contains("print") {
            let output = code.replacingOccurrences(of: "print(", with: "")
                              .replacingOccurrences(of: ")", with: "")
                              .replacingOccurrences(of: "\"", with: "")
                              .replacingOccurrences(of: "'", with: "")
            return """
            {"output": "\(output)", "status": "success", "execution_time": "0.05s"}
            """
        } else if code.contains("+") || code.contains("-") || code.contains("*") || code.contains("/") {
            let result = Int.random(in: 1...100)
            return """
            {"output": "\(result)", "status": "success", "execution_time": "0.02s"}
            """
        } else if code.contains("import") {
            return """
            {"output": "Module imported successfully", "status": "success", "execution_time": "0.15s"}
            """
        } else {
            return """
            {"output": "Code executed successfully", "status": "success", "execution_time": "0.08s"}
            """
        }
    }
    
    /// Simple calculator implementation
    static func calculate(_ expression: String) -> String {
        // Simple math evaluation simulation
        if expression.contains("+") {
            let result = Int.random(in: 10...100)
            return """
            {"expression": "\(expression)", "result": \(result), "type": "addition"}
            """
        } else if expression.contains("sqrt") {
            let result = Int.random(in: 2...10)
            return """
            {"expression": "\(expression)", "result": \(result), "type": "square_root"}
            """
        } else {
            let result = Double.random(in: 1...100)
            return """
            {"expression": "\(expression)", "result": "\(String(format: "%.2f", result))", "type": "calculation"}
            """
        }
    }
}

// MARK: - Chat History Management
class AdvancedChatHistory {
    var messages: [SAOAIMessage] = []
    var responseIds: [String] = []
    var toolCalls: [(callId: String, function: String, result: String)] = []
    
    func addUserMessage(_ message: SAOAIMessage) {
        messages.append(message)
    }
    
    func addAssistantResponse(_ response: SAOAIResponse) {
        // Process response and extract content
        for output in response.output {
            for content in output.content ?? [] {
                switch content {
                case .outputText(let textOutput):
                    let assistantMessage = SAOAIMessage(role: .assistant, text: textOutput.text)
                    messages.append(assistantMessage)
                case .functionCall(let functionCall):
                    // Store function call info but don't add to messages yet
                    print("🔧 Function call detected: \(functionCall.name)")
                }
            }
        }
        
        // Store response ID for chaining
        if let responseId = response.id {
            responseIds.append(responseId)
        }
    }
    
    func addToolCall(callId: String, function: String, result: String) {
        // only need for function calls, not for code interpreter
        toolCalls.append((callId: callId, function: function, result: result))
    }
    
    var lastResponseId: String? {
        return responseIds.last
    }
    
    var conversationMessages: [SAOAIMessage] {
        return messages
    }
    
    func printHistory() {
        print("\n📜 Conversation History:")
        print("========================")
        for (index, message) in messages.enumerated() {
            let roleIcon = message.role == .user ? "👤" : 
                          message.role == .assistant ? "🤖" : "🔧"
            let roleName = message.role?.rawValue.capitalized ?? "ToolOutput"
            print("\(index + 1). \(roleIcon) \(roleName):")
            for content in message.content {
                switch content {
                case .inputText(let text):
                    print("   Text: \(text.text)")
                case .inputImage(let image):
                    print("   Image: \(image.imageURL)")
                case .functionCallOutput(let output):
                    print("   Function output: \(output.callId)")
                }
            }
        }
        
        if !toolCalls.isEmpty {
            print("\n🔧 Tool Calls History:")
            for (index, call) in toolCalls.enumerated() {
                print("\(index + 1). \(call.function) (ID: \(call.callId))")
                print("   Result: \(call.result)")
            }
        }
        print("========================\n")
    }
    
    func clear() {
        messages.removeAll()
        responseIds.removeAll()
        toolCalls.removeAll()
    }
}

// MARK: - Image Processing Utilities
struct ImageProcessor {
    static func isValidImageURL(_ input: String) -> Bool {
        guard let url = URL(string: input),
              url.scheme == "http" || url.scheme == "https" else { return false }
        let path = url.pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "webp"].contains(path)
    }
    
    static func isValidBase64Image(_ input: String) -> Bool {
        return input.hasPrefix("data:image/") || 
               (input.count > 100 && input.allSatisfy { $0.isLetter || $0.isNumber || "=+/".contains($0) })
    }
}

// MARK: - Advanced Console Interface
class AdvancedConsoleChatbot {
    private let chatHistory = AdvancedChatHistory()
    private var isRunning = true
    private let availableTools = [weatherTool, codeInterpreterTool, calculatorTool]
    
    // Enhanced event handling infrastructure
    private let stepManager = StepManager()
    private let codeInterpreterTracker = CodeInterpreterTracker()
    private var sseLogger: SSELogger?
    private var currentMessage: ConsoleMessage?
    private var currentStep: ConsoleStep?
    private var currentToolCall: Any?
    
    // Container ID tracking for code interpreter
    private var containerIds: Set<String> = []
    
    init(enableSSELogging: Bool = false, logFilePath: String? = nil) {
        if enableSSELogging {
            let logConfig = SSELoggerConfiguration.enabled(
                logFilePath: logFilePath,
                includeTimestamp: true,
                includeSequenceNumber: true
            )
            self.sseLogger = SSELogger(configuration: logConfig)
        }
    }
    
    func start() async {
        printWelcome()
        
        while isRunning {
            do {
                try await handleUserInput()
            } catch {
                print("❌ Error: \(error.localizedDescription)")
                print("Please try again or type 'quit' to exit.\n")
            }
        }
    }
    
    private func printWelcome() {
        print("🚀 Advanced SwiftAzureOpenAI Console Chatbot")
        print("=============================================")
        print("Features demonstrated:")
        print("• 🔧 Function calling (weather, calculator)")
        print("• 🐍 Code interpreter tool with container tracking")
        print("• 🖼️  Multi-modal support (images)")
        print("• 📚 Conversation history chaining")
        print("• 📝 Enhanced SSE event handling (Python SDK style)")
        print("• 🗂️  Parallel tool call management")
        if sseLogger != nil {
            print("• 📋 SSE event logging enabled")
        }
        print("")
        print("Available commands:")
        print("• 'history' - Show conversation history")
        print("• 'clear' - Clear conversation history")
        print("• 'help' - Show this help message")
        print("• 'quit' - Exit the chatbot")
        print("")
        print("Just ask naturally and I'll use tools when needed!")
        print("Try: 'can you write fibonacci code to execute and get first 10 number'")
        print("===================================================\n")
    }
    
    private func handleUserInput() async throws {
        print("👤 You: ", terminator: "")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !input.isEmpty else {
            print("Please enter a message.\n")
            return
        }
        
        // Handle special commands
        switch input.lowercased() {
        case "quit", "exit":
            print("👋 Goodbye!")
            isRunning = false
            return
        case "history":
            chatHistory.printHistory()
            return
        case "clear":
            chatHistory.clear()
            print("🧹 Conversation history cleared.\n")
            return
        case "help":
            printWelcome()
            return
        default:
            break
        }
        
        // Process input and determine if it needs special handling
        let (message, needsTools) = processInput(input)
        chatHistory.addUserMessage(message)
        
        if needsTools {
            try await handleToolBasedRequest(input, message: message)
        } else {
            try await handleRegularRequest(message)
        }
    }
    
    private func processInput(_ input: String) -> (SAOAIMessage, Bool) {
        // Check for image inputs
        if input.hasPrefix("image:") {
            let imageURL = String(input.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            if ImageProcessor.isValidImageURL(imageURL) {
                let message = SAOAIMessage(role: .user, content: [
                    .inputImage(.init(imageURL: imageURL))
                ])
                return (message, false)
            }
        }
        
        if input.hasPrefix("base64:") {
            let base64Data = String(input.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            if ImageProcessor.isValidBase64Image(base64Data) {
                let message = SAOAIMessage(role: .user, content: [
                    .inputImage(.init(base64Data: base64Data))
                ])
                return (message, false)
            }
        }
        
        // All text messages (including natural language requests for tools) should use tools
        let message = SAOAIMessage(role: .user, text: input)
        return (message, true)
    }
    
    private func handleToolBasedRequest(_ input: String, message: SAOAIMessage) async throws {
        // print("\n🔧 Processing with tools...")
        print("🤖 Assistant: ", terminator: "")
        
        // Prepare messages for API call - include system message for first conversation
        let messagesToSend: [SAOAIMessage]
        if chatHistory.lastResponseId == nil {
            // First message in conversation - include system message
            let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant with access to tools for weather information, code execution, and mathematical calculations. Use these tools when users ask relevant questions. You also have vision capabilities to analyze images.")
            messagesToSend = [systemMessage, message]
        } else {
            // Subsequent messages - send only current message with previousResponseId
            messagesToSend = [message]
        }
        
        // Use streaming API with enhanced SSE event handling
        let stream = client.responses.createStreaming(
            model: azureConfig.deploymentName,
            input: messagesToSend,
            tools: availableTools,
            previousResponseId: chatHistory.lastResponseId
        )
        
        // Process the stream with Python SDK-style event handling
        await processStreamWithEnhancedEventHandling(stream: stream, input: input)
    }
    
    /// Process streaming response with enhanced event handling like Python SDK
    private func processStreamWithEnhancedEventHandling(
        stream: AsyncThrowingStream<SAOAIStreamingResponse, Error>,
        input: String
    ) async {
        var assistantMessageCompleted = false
        var lastResponseId: String?
        var functionCallOutputs: [SAOAIInputContent.FunctionCallOutput] = []
        var previousResponseId: String? = chatHistory.lastResponseId
        var assistantContent = "" // Track assistant response content across the entire flow
        
        // Reset current message for this conversation round
        currentMessage = nil
        
        // First round - process the initial stream
        do {
            for try await chunk in stream {
                // Extract response ID from first chunk
                if lastResponseId == nil {
                    lastResponseId = chunk.id
                }
                
                // Process enhanced SSE events using raw SSE parsing for detailed event handling
                await processChunkWithEnhancedEventHandling(
                    chunk: chunk,
                    input: input,
                    assistantMessageCompleted: &assistantMessageCompleted,
                    functionCallOutputs: &functionCallOutputs
                )
                
                // Track assistant content from text deltas
                if let text = chunk.output?.first?.content?.first?.text, 
                   !text.isEmpty,
                   chunk.eventType == .responseOutputTextDelta {
                    assistantContent += text
                }
                
                // Also track from legacy streaming for robustness
                if chunk.eventType == nil {
                    for output in chunk.output ?? [] {
                        for content in output.content ?? [] {
                            if let text = content.text, !text.isEmpty, content.type != "status" {
                                assistantContent += text
                            }
                        }
                    }
                }
                
                // Check for completion
                if assistantMessageCompleted {
                    break
                }
            }
            
            // Update previous response ID for next round
            previousResponseId = lastResponseId
            
        } catch {
            print("❌ Error processing stream: \(error.localizedDescription)")
        }
        
        // Main conversation loop - continue until assistant message is completed
        while !functionCallOutputs.isEmpty && !assistantMessageCompleted {
            print("\n🔧 Submitting tool results for next round...")
            
            do {
                // Use the new function call outputs API for proper Azure OpenAI Responses API format
                let followUpStream = client.responses.createStreaming(
                    model: azureConfig.deploymentName,
                    functionCallOutputs: functionCallOutputs,
                    previousResponseId: previousResponseId
                )
                
                // Reset outputs for next round
                functionCallOutputs.removeAll()
                
                // Process follow-up stream
                for try await chunk in followUpStream {
                    // Update response ID
                    if let chunkId = chunk.id {
                        lastResponseId = chunkId
                    }
                    
                    // Process enhanced SSE events
                    await processChunkWithEnhancedEventHandling(
                        chunk: chunk,
                        input: input,
                        assistantMessageCompleted: &assistantMessageCompleted,
                        functionCallOutputs: &functionCallOutputs
                    )
                    
                    // Track assistant content from text deltas  
                    if let text = chunk.output?.first?.content?.first?.text,
                       !text.isEmpty,
                       chunk.eventType == .responseOutputTextDelta {
                        assistantContent += text
                    }
                    
                    // Also track from legacy streaming for robustness in follow-up rounds
                    if chunk.eventType == nil {
                        for output in chunk.output ?? [] {
                            for content in output.content ?? [] {
                                if let text = content.text, !text.isEmpty, content.type != "status" {
                                    assistantContent += text
                                }
                            }
                        }
                    }
                    
                    // Check for completion
                    if assistantMessageCompleted {
                        break
                    }
                }
                
                // Update previous response ID for next round
                previousResponseId = lastResponseId
                
            } catch {
                print("❌ Error processing follow-up stream: \(error.localizedDescription)")
                
                // Try to extract more specific error information
                if let openAIError = error as? SAOAIError {
                    switch openAIError {
                    case .invalidAPIKey:
                        print("   - Invalid API key")
                    case .rateLimitExceeded:
                        print("   - Rate limit exceeded")
                    case .serverError(let statusCode):
                        print("   - Server error with status code: \(statusCode)")
                    case .invalidRequest(let message):
                        print("   - Invalid request: \(message)")
                    case .networkError(let underlying):
                        print("   - Network error: \(underlying.localizedDescription)")
                    case .decodingError(let underlying):
                        print("   - Decoding error: \(underlying.localizedDescription)")
                    case .apiError(let errorResponse):
                        print("   - API error: \(errorResponse.error.message)")
                        print("   - Error type: \(errorResponse.error.type ?? "unknown")")
                        print("   - Error code: \(errorResponse.error.code ?? "unknown")")
                    }
                }
                break
            }
        }
        
        // Create final response for history using accumulated content
        if let responseId = lastResponseId {
            // Use currentMessage content if available, fall back to assistantContent
            let finalContent = currentMessage?.content ?? assistantContent
            
            // Ensure we have some content for the assistant response
            let responseContent = finalContent.isEmpty ? "I completed the requested action." : finalContent
            
            let finalResponse = SAOAIResponse(
                id: responseId,
                model: azureConfig.deploymentName,
                created: Int(Date().timeIntervalSince1970),
                output: [SAOAIOutput(content: [.outputText(.init(text: responseContent))])],
                usage: nil
            )
            chatHistory.addAssistantResponse(finalResponse)
        }
        
        print("\n")
    }
    
    /// Process individual chunk with enhanced event handling similar to Python SDK
    private func processChunkWithEnhancedEventHandling(
        chunk: SAOAIStreamingResponse,
        input: String,
        assistantMessageCompleted: inout Bool,
        functionCallOutputs: inout [SAOAIInputContent.FunctionCallOutput]
    ) async {
        // Simulate the event-based processing from Python SDK
        // Since the current streaming response doesn't expose full event details,
        // we'll work with what we have and simulate the enhanced tracking
        
        guard let eventType = chunk.eventType else {
            // Handle legacy streaming without event type
            await processLegacyStreamingChunk(chunk)
            return
        }
        
        // Log the event if SSE logger is enabled
        if let logger = sseLogger {
            // Convert chunk back to SSE event for logging (simplified)
            let sseEvent = AzureOpenAISSEEvent(
                type: eventType.rawValue,
                sequenceNumber: nil,
                response: nil,
                outputIndex: nil,
                item: chunk.item.map { streamingItem in
                    AzureOpenAIEventItem(
                        id: streamingItem.id,
                        type: streamingItem.type?.rawValue,
                        status: streamingItem.status,
                        arguments: streamingItem.arguments,
                        callId: streamingItem.callId,
                        name: streamingItem.name,
                        summary: streamingItem.summary,
                        containerId: streamingItem.containerId
                    )
                },
                itemId: chunk.item?.id,
                delta: chunk.output?.first?.content?.first?.text,
                arguments: chunk.item?.arguments
            )
            logger.logEvent(sseEvent)
        }
        
        // Handle specific event types like Python SDK
        switch eventType {
        case .responseOutputItemAdded:
            // print("🔍 DEBUG: Processing event: responseOutputItemAdded")
            await handleOutputItemAdded(chunk: chunk, assistantMessageCompleted: &assistantMessageCompleted)
            
        case .responseOutputTextDelta:
            // Don't print debug for text deltas as they interfere with response display
            await handleOutputTextDelta(chunk: chunk)
            
        case .responseCodeInterpreterCallCodeDelta:
            // print("🔍 DEBUG: Processing event: responseCodeInterpreterCallCodeDelta") 
            await handleCodeInterpreterCallCodeDelta(chunk: chunk)
            
        case .responseFunctionCallArgumentsDelta:
            // print("🔍 DEBUG: Processing event: responseFunctionCallArgumentsDelta")
            await handleFunctionCallArgumentsDelta(chunk: chunk)
            
        case .responseCodeInterpreterCallCompleted:
            // print("🔍 DEBUG: Processing event: responseCodeInterpreterCallCompleted")
            await handleCodeInterpreterCallCompleted(chunk: chunk)
            
        case .responseFunctionCallArgumentsDone:
            // print("🔍 DEBUG: Processing event: responseFunctionCallArgumentsDone")
            await handleFunctionCallArgumentsDone(chunk: chunk)
            
        case .responseOutputItemCompleted, .responseOutputItemDone:
            // print("🔍 DEBUG: Processing event: responseOutputItemCompleted/Done")
            await handleOutputItemDone(chunk: chunk, functionCallOutputs: &functionCallOutputs, assistantMessageCompleted: &assistantMessageCompleted)
            
        case .responseCompleted:
            // print("🔍 DEBUG: Processing event: responseCompleted")
            // Handle response completion
            break
            
        default:
            // print("🔍 DEBUG: Processing event: \(eventType.rawValue) (fallback to legacy)")
            // Handle other event types or fallback to legacy processing
            await processLegacyStreamingChunk(chunk)
        }
    }
    
    /// Handle response.output_item.added events (Python SDK equivalent)
    private func handleOutputItemAdded(
        chunk: SAOAIStreamingResponse,
        assistantMessageCompleted: inout Bool
    ) async {
        guard let item = chunk.item else { return }
        
        switch item.type {
        case .message:
            // Create new message
            currentMessage = ConsoleMessage(
                content: "",
                metadata: ["api_type": "responses_api"]
            )
            
        case .codeInterpreterCall:
            // Track container ID from code interpreter call
            if let containerId = item.containerId {
                containerIds.insert(containerId)
                print("\n🐍 Code Interpreter Started (Container: \(containerId))")
            }
            
            // Create step for code interpreter
            currentStep = ConsoleStep(
                name: "Code Interpreter",
                type: "tool",
                language: "python"
            )
            currentStep?.showInput = "python"
            
            if let itemId = item.id {
                stepManager.toolSteps[itemId] = currentStep
                stepManager.itemSteps[itemId] = currentStep
            }
            
        case .functionCall:
            // Handle function call creation
            let fnName = item.name ?? "Function Call"
            
            // Reuse step per function name or create new one
            let stepForFn = stepManager.functionNameToStep[fnName] ?? {
                let step = ConsoleStep(
                    name: "Function: \(fnName)",
                    type: "tool",
                    language: "json"
                )
                step.showInput = "json"
                stepManager.functionNameToStep[fnName] = step
                return step
            }()
            
            currentStep = stepForFn
            
            if let itemId = item.id {
                stepManager.toolSteps[itemId] = stepForFn
                stepManager.itemSteps[itemId] = stepForFn
                
                // Save metadata
                stepManager.functionMetaByItemId[itemId] = StepManager.FunctionMetadata(
                    name: fnName,
                    callId: item.callId ?? ""
                )
            }
            
        case .mcpCall:
            // Handle MCP call creation
            currentStep = ConsoleStep(
                name: "MCP Call",
                type: "tool"
            )
            
            if let itemId = item.id {
                stepManager.toolSteps[itemId] = currentStep
                stepManager.itemSteps[itemId] = currentStep
            }
            
        default:
            break
        }
    }
    
    /// Handle response.output_text.delta events
    private func handleOutputTextDelta(chunk: SAOAIStreamingResponse) async {
        guard let text = chunk.output?.first?.content?.first?.text, !text.isEmpty else { return }
        
        if let message = currentMessage {
            message.streamToken(text)
            print(text, terminator: "")
        }
    }
    
    /// Handle response.code_interpreter_call_code.delta events
    private func handleCodeInterpreterCallCodeDelta(chunk: SAOAIStreamingResponse) async {
        guard let delta = chunk.output?.first?.content?.first?.text, !delta.isEmpty else { return }
        guard let itemId = chunk.item?.id else { return }
        
        // Stream delta into correct step by item_id
        let targetStep = stepManager.itemSteps[itemId] ?? currentStep
        if let step = targetStep {
            step.streamToken(delta, isInput: true)
            // In a real UI, this would update immediately. For console, we'll show accumulated code
        }
        
        // Track in code interpreter tracker
        _ = codeInterpreterTracker.appendCodeDelta(itemId: itemId, code: delta)
    }
    
    /// Handle response.function_call_arguments.delta events
    private func handleFunctionCallArgumentsDelta(chunk: SAOAIStreamingResponse) async {
        // Use chunk.id as itemId for function call arguments delta events
        guard let itemId = chunk.id else { 
            return 
        }
        
        let delta = chunk.output?.first?.content?.first?.text ?? ""
        
        guard !delta.isEmpty else { 
            return 
        }
        
        // Accumulate deltas instead of streaming them directly (Python SDK approach)
        if stepManager.functionArgsByItemId[itemId] == nil {
            stepManager.functionArgsByItemId[itemId] = ""
        }
        stepManager.functionArgsByItemId[itemId]! += delta
    }
    
    /// Handle response.code_interpreter_call.completed events
    private func handleCodeInterpreterCallCompleted(chunk: SAOAIStreamingResponse) async {
        guard let itemId = chunk.item?.id else { return }
        
        let step = stepManager.toolSteps[itemId] ?? stepManager.itemSteps[itemId]
        if let step = step {
            // Show completed marker
            step.output = chunk.output?.first?.content?.first?.text ?? "Completed"
            step.language = "markdown"
            step.update()
            
            print("\n🐍 Code Interpreter Completed")
            if !step.input.isEmpty {
                print("Code executed:")
                print("```python")
                print(step.input)
                print("```")
            }
            if !step.output.isEmpty && step.output != "Completed" {
                print("Output:")
                print(step.output)
            }
        }
        
        // Mark as completed in tracker
        _ = codeInterpreterTracker.markCompleted(itemId: itemId)
    }
    
    /// Handle response.function_call_arguments.done events
    private func handleFunctionCallArgumentsDone(chunk: SAOAIStreamingResponse) async {
        guard let itemId = chunk.item?.id else { return }
        
        // Get final accumulated arguments
        let argsStr = stepManager.functionArgsByItemId[itemId] ?? ""
        
        // Update step input
        if let meta = stepManager.functionMetaByItemId[itemId] {
            let fnName = meta.name
            let prevInput = stepManager.stepInputsByFuncName[fnName] ?? ""
            let combinedInput = prevInput.isEmpty ? argsStr : "\(prevInput)\n\(argsStr)"
            stepManager.stepInputsByFuncName[fnName] = combinedInput
            
            if let stepForFn = stepManager.functionNameToStep[fnName] {
                stepForFn.input = combinedInput
                stepForFn.language = "json"
                stepForFn.update()
            }
        }
    }
    
    /// Handle response.output_item.done events
    private func handleOutputItemDone(
        chunk: SAOAIStreamingResponse,
        functionCallOutputs: inout [SAOAIInputContent.FunctionCallOutput],
        assistantMessageCompleted: inout Bool
    ) async {
        guard let item = chunk.item else { return }
        
        // Handle function call completion and execution
        if item.type == .functionCall {
            guard let itemId = item.id else { return }
            let step = stepManager.itemSteps[itemId]
            let meta = stepManager.functionMetaByItemId[itemId]
            let funcName = meta?.name ?? ""
            let callIdForSubmit = meta?.callId ?? ""
            
            // Avoid duplicate processing
            if !callIdForSubmit.isEmpty && stepManager.processedFunctionCallIds.contains(callIdForSubmit) {
                return
            }
            
            // Get final arguments
            let rawArgs = stepManager.functionArgsByItemId[itemId] ?? ""
            
            if !funcName.isEmpty && !callIdForSubmit.isEmpty {
                print("\n🔧 Executing \(funcName)...")
                
                // Execute the tool function
                let result = await executeTool(name: funcName, arguments: rawArgs, input: "")
                
                // Update step output
                let prevOutput = stepManager.stepOutputsByFuncName[funcName] ?? ""
                let rawDisplay = result
                let appendedOutput = prevOutput.isEmpty ? rawDisplay : "\(prevOutput)\n\(rawDisplay)"
                stepManager.stepOutputsByFuncName[funcName] = appendedOutput
                
                let stepForFn = stepManager.functionNameToStep[funcName] ?? step
                if let step = stepForFn {
                    step.streamToken("\n\(rawDisplay)")
                    print("Result: \(rawDisplay)")
                }
                
                // Stage for model with proper function call output format (Azure Responses API style)
                let functionCallOutput = SAOAIInputContent.FunctionCallOutput(
                    callId: callIdForSubmit,
                    output: result
                )
                functionCallOutputs.append(functionCallOutput)
                stepManager.processedFunctionCallIds.insert(callIdForSubmit)
            }
        }
        
        // Detect assistant message completion
        if item.type == .message && item.status == "completed" {
            assistantMessageCompleted = true
        }
    }
    
    /// Handle legacy streaming chunks (fallback for chunks without detailed event info)
    private func processLegacyStreamingChunk(_ chunk: SAOAIStreamingResponse) async {
        // Process legacy streaming content
        for output in chunk.output ?? [] {
            for content in output.content ?? [] {
                if let text = content.text, !text.isEmpty, content.type != "status" {
                    if let message = currentMessage {
                        message.streamToken(text)
                    }
                    print(text, terminator: "")
                }
            }
        }
    }
    
    private func handleRegularRequest(_ message: SAOAIMessage) async throws {
        print("\n🤖 Assistant: ", terminator: "")
        
        // Prepare messages for streaming - include system message for first conversation
        let messagesToSend: [SAOAIMessage]
        if chatHistory.lastResponseId == nil {
            // First message in conversation - include system message
            let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant with access to tools for weather information, code execution, and mathematical calculations. Use these tools when users ask relevant questions. You also have vision capabilities to analyze images.")
            messagesToSend = [systemMessage, message]
        } else {
            // Subsequent messages - send only current message with previousResponseId
            messagesToSend = [message]
        }
        
        // Use streaming for better real-time experience
        let stream = client.responses.createStreaming(
            model: azureConfig.deploymentName,
            input: messagesToSend,
            previousResponseId: chatHistory.lastResponseId
        )
        
        var fullResponse = ""
        var responseId: String?
        
        for try await chunk in stream {
            // Extract response ID from first chunk
            if responseId == nil {
                responseId = chunk.id
            }
            
            // Process streaming content
            for output in chunk.output ?? [] {
                for content in output.content ?? [] {
                    if let text = content.text, !text.isEmpty, content.type != "status" {
                        print(text, terminator: "")
                        fullResponse += text
                    }
                }
            }
        }
        
        // Create a response object for history tracking
        let response = SAOAIResponse(
            id: responseId,
            model: azureConfig.deploymentName,
            created: Int(Date().timeIntervalSince1970),
            output: [SAOAIOutput(content: [.outputText(.init(text: fullResponse))])],
            usage: nil
        )
        
        chatHistory.addAssistantResponse(response)
        print("\n")
    }
    
    private func executeTool(name: String, arguments: String, input: String) async -> String {
        // Parse the JSON arguments from the function call
        guard let data = arguments.data(using: .utf8),
              let argumentsDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "{\"error\": \"Invalid arguments format\"}"
        }
        
        switch name {
        case "get_weather":
            let location = argumentsDict["location"] as? String ?? "Unknown location"
            let unit = argumentsDict["unit"] as? String ?? "celsius"
            return ToolExecutor.getWeather(location: location, unit: unit)
            
        case "code_interpreter":
            let code = argumentsDict["code"] as? String ?? ""
            print("🐍 Executing: \(code)")
            return ToolExecutor.executeCode(code)
            
        case "calculate":
            let expression = argumentsDict["expression"] as? String ?? ""
            print("🧮 Calculating: \(expression)")
            return ToolExecutor.calculate(expression)
            
        default:
            return "{\"error\": \"Unknown tool: \(name)\"}"
        }
    }
}

// MARK: - Demo Mode (for when running without real API credentials)
func runDemoMode() {
    print("🔧 Demo Mode - Advanced Console Chatbot")
    print("=======================================")
    print("This example demonstrates all SwiftAzureOpenAI features in an interactive console:")
    print("")
    print("📝 Features showcased:")
    print("• ✅ Function calling (weather API)")
    print("• ✅ Code interpreter tool with container tracking")
    print("• ✅ Mathematical calculator")
    print("• ✅ Multi-modal support (images)")
    print("• ✅ Conversation history chaining")
    print("• ✅ Interactive command handling")
    print("• ✅ Tool result processing")
    print("• ✅ Enhanced SSE event handling (Python SDK style)")
    print("• ✅ Parallel tool call management")
    print("• ✅ SSE event logging for diagnostics")
    print("")
    print("🚀 To run with real API:")
    print("1. Set environment variables:")
    print("   export AZURE_OPENAI_ENDPOINT='https://your-resource.openai.azure.com'")
    print("   export AZURE_OPENAI_API_KEY='your-api-key'")
    print("   export AZURE_OPENAI_DEPLOYMENT='gpt-4o'")
    print("2. Run the chatbot and chat naturally!")
    print("")
    print("🐍 Test with code interpreter:")
    print("   Try: 'can you write fibonacci code to execute and get first 10 number'")
    print("")
    print("The AI will automatically use tools when appropriate and log all SSE events.")
}

// MARK: - Main Execution
@main
struct AdvancedConsoleChatbotApp {
    static func main() async {
        // Check if we have valid API credentials
        let endpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"]
        let apiKey = ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ?? ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"]
        
        let hasCredentials = endpoint != nil &&
                           apiKey != nil &&
                           endpoint != "https://your-resource.openai.azure.com"
        
        if hasCredentials {
            // Run with real API and enable SSE logging
            let mainFileURL = URL(fileURLWithPath: #filePath)
            let logDirectoryURL = mainFileURL.deletingLastPathComponent()
            let logPath = logDirectoryURL.appendingPathComponent("sse_events.log").path
            print("📋 SSE event logging enabled at: \(logPath)")
            await AdvancedConsoleChatbot(enableSSELogging: true, logFilePath: logPath).start()
        } else {
            // Run in demo mode
            runDemoMode()
        }
    }
}