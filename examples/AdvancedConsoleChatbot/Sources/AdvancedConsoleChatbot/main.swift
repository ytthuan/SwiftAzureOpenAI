import Foundation
import SwiftAzureOpenAI

// MARK: - Advanced Console Chatbot Example

/// Comprehensive console chatbot demonstrating all SwiftAzureOpenAI features:
/// - Interactive console interface
/// - Function calling (weather API example)
/// - Code interpreter tool support
/// - Multi-modal support (images via URL and base64)
/// - Response chaining with conversation history
/// - Tool result processing and display

// MARK: - Configuration
let azureConfig = SAOAIAzureConfiguration(
    endpoint: ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] ?? "https://your-resource.openai.azure.com",
    apiKey: ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ?? ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"] ?? "your-api-key",
    deploymentName: ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? "gpt-4o",
    apiVersion: "preview"
)

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
        "required": .array([.string("location")])
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
        {
            "location": "\(location)",
            "temperature": "\(convertedTemp)",
            "condition": "\(condition)",
            "humidity": "\(Int.random(in: 30...80))%",
            "wind_speed": "\(Int.random(in: 5...25)) km/h",
            "unit": "\(unit)"
        }
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
            {
                "output": "\(output)",
                "status": "success",
                "execution_time": "0.05s"
            }
            """
        } else if code.contains("+") || code.contains("-") || code.contains("*") || code.contains("/") {
            let result = Int.random(in: 1...100)
            return """
            {
                "output": "\(result)",
                "status": "success",
                "execution_time": "0.02s"
            }
            """
        } else if code.contains("import") {
            return """
            {
                "output": "Module imported successfully",
                "status": "success",
                "execution_time": "0.15s"
            }
            """
        } else {
            return """
            {
                "output": "Code executed successfully",
                "status": "success",
                "execution_time": "0.08s"
            }
            """
        }
    }
    
    /// Simple calculator implementation
    static func calculate(_ expression: String) -> String {
        // Simple math evaluation simulation
        if expression.contains("+") {
            let result = Int.random(in: 10...100)
            return """
            {
                "expression": "\(expression)",
                "result": \(result),
                "type": "addition"
            }
            """
        } else if expression.contains("sqrt") {
            let result = Int.random(in: 2...10)
            return """
            {
                "expression": "\(expression)",
                "result": \(result),
                "type": "square_root"
            }
            """
        } else {
            let result = Double.random(in: 1...100)
            return """
            {
                "expression": "\(expression)",
                "result": \(String(format: "%.2f", result)),
                "type": "calculation"
            }
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
            print("\(index + 1). \(roleIcon) \(message.role.rawValue.capitalized):")
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
        print("• 🐍 Code interpreter tool")
        print("• 🖼️  Multi-modal support (images)")
        print("• 📚 Conversation history chaining")
        print("")
        print("Available commands:")
        print("• 'history' - Show conversation history")
        print("• 'clear' - Clear conversation history")
        print("• 'help' - Show this help message")
        print("• 'quit' - Exit the chatbot")
        print("")
        print("Just ask naturally and I'll use tools when needed!")
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
        print("\n🔧 Processing with tools...")
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
        
        // Use non-streaming API for tool-based requests to ensure proper function call handling
        // This fixes the "Bad Request" issue that occurs when tools are used with streaming API
        let response = try await client.responses.create(
            model: azureConfig.deploymentName,
            input: messagesToSend,
            tools: availableTools,
            previousResponseId: chatHistory.lastResponseId
        )
        
        // Process function calls from the response
        await processFunctionCalls(response: response, input: input)
    }
    
    private func processFunctionCalls(response: SAOAIResponse, input: String) async {
        var toolResults: [SAOAIMessage] = []
        var hasTextContent = false
        var textResponse = ""
        
        // Process response content and function calls
        for output in response.output {
            // Check for function calls at output level (Azure OpenAI Responses API format)
            if output.type == "function_call" {
                if let name = output.name, let callId = output.callId, let arguments = output.arguments {
                    print("🔧 Calling tool: \(name)")
                    
                    let result = await executeTool(
                        name: name,
                        arguments: arguments,
                        input: input
                    )
                    
                    chatHistory.addToolCall(
                        callId: callId,
                        function: name,
                        result: result
                    )
                    
                    // Add tool result to conversation
                    toolResults.append(SAOAIMessage(
                        role: .user,
                        content: [.inputText(.init(
                            text: "Function \(name) (call_id: \(callId)) result: \(result)"
                        ))]
                    ))
                }
            } else {
                // Check content for both text and function calls
                if let contentArray = output.content {
                    for content in contentArray {
                        switch content {
                        case .outputText(let textOutput):
                            if !textOutput.text.isEmpty {
                                print(textOutput.text, terminator: "")
                                textResponse += textOutput.text
                                hasTextContent = true
                            }
                        case .functionCall(let functionCall):
                            print("🔧 Calling tool: \(functionCall.name)")
                            
                            let result = await executeTool(
                                name: functionCall.name,
                                arguments: functionCall.arguments,
                                input: input
                            )
                            
                            chatHistory.addToolCall(
                                callId: functionCall.callId,
                                function: functionCall.name,
                                result: result
                            )
                            
                            // Add tool result to conversation
                            toolResults.append(SAOAIMessage(
                                role: .user,
                                content: [.inputText(.init(
                                    text: "Function \(functionCall.name) (call_id: \(functionCall.callId)) result: \(result)"
                                ))]
                            ))
                        }
                    }
                }
            }
        }
        
        chatHistory.addAssistantResponse(response)
        
        // If we have tool results, send follow-up streaming request for the final response
        if !toolResults.isEmpty {
            print("\n🔧 Processing tool results...")
            print("🤖 Assistant: ", terminator: "")
            
            let messagesToSend: [SAOAIMessage]
            if chatHistory.lastResponseId == nil {
                let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant with access to tools for weather information, code execution, and mathematical calculations. Use these tools when users ask relevant questions. You also have vision capabilities to analyze images.")
                messagesToSend = [systemMessage] + toolResults
            } else {
                messagesToSend = toolResults
            }
            
            do {
                let followUpStream = client.responses.createStreaming(
                    model: azureConfig.deploymentName,
                    input: messagesToSend,
                    previousResponseId: response.id
                )
                
                var finalResponse = ""
                var finalResponseId: String?
                
                for try await chunk in followUpStream {
                    if finalResponseId == nil {
                        finalResponseId = chunk.id
                    }
                    
                    for output in chunk.output ?? [] {
                        for content in output.content ?? [] {
                            if let text = content.text, !text.isEmpty, content.type != "status" {
                                print(text, terminator: "")
                                finalResponse += text
                            }
                        }
                    }
                }
                
                // Create final response for history
                let finalResponseObj = SAOAIResponse(
                    id: finalResponseId,
                    model: azureConfig.deploymentName,
                    created: Int(Date().timeIntervalSince1970),
                    output: [SAOAIOutput(content: [.outputText(.init(text: finalResponse))])],
                    usage: nil
                )
                
                chatHistory.addAssistantResponse(finalResponseObj)
            } catch {
                print("❌ Error processing tool results: \(error.localizedDescription)")
            }
        } else if hasTextContent {
            // If there was only text content and no tool calls, just display it
            print("")
        }
        
        print("\n")
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
    print("• ✅ Code interpreter tool")
    print("• ✅ Mathematical calculator")
    print("• ✅ Multi-modal support (images)")
    print("• ✅ Conversation history chaining")
    print("• ✅ Interactive command handling")
    print("• ✅ Tool result processing")
    print("")
    print("🚀 To run with real API:")
    print("1. Set environment variables:")
    print("   export AZURE_OPENAI_ENDPOINT='https://your-resource.openai.azure.com'")
    print("   export AZURE_OPENAI_API_KEY='your-api-key'")
    print("   export AZURE_OPENAI_DEPLOYMENT='gpt-4o'")
    print("2. Run the chatbot and chat naturally!")
    print("")
    print("The AI will automatically use tools when appropriate.")
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
            // Run with real API
            await AdvancedConsoleChatbot().start()
        } else {
            // Run in demo mode
            runDemoMode()
        }
    }
}