import Foundation
import SwiftAzureOpenAI

// MARK: - Advanced Console Chatbot Example

/// Comprehensive console chatbot demonstrating all SwiftAzureOpenAI features:
/// - Interactive console interface with streaming simulation
/// - Function calling (weather API example)
/// - Code interpreter tool support
/// - Multi-modal support (images via URL and base64)
/// - Response chaining with conversation history
/// - Tool result processing and display

// MARK: - Configuration
nonisolated(unsafe) let azureConfig = SAOAIAzureConfiguration(
    endpoint: ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] ?? "https://your-resource.openai.azure.com",
    apiKey: ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ?? "your-api-key",
    deploymentName: ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? "gpt-4o",
    apiVersion: "preview"
)

nonisolated(unsafe) let client = SAOAIClient(configuration: azureConfig)

// MARK: - Tool Definitions

/// Weather API function tool
nonisolated(unsafe) let weatherTool = SAOAITool.function(
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
nonisolated(unsafe) let codeInterpreterTool = SAOAITool(
    type: "code_interpreter",
    name: "code_interpreter",
    description: "Execute Python code and return results",
    parameters: .object([
        "type": .string("object"),
        "properties": .object([
            "code": .object([
                "type": .string("string"),
                "description": .string("Python code to execute")
            ])
        ]),
        "required": .array([.string("code")])
    ])
)

/// Math calculator function tool
nonisolated(unsafe) let calculatorTool = SAOAITool.function(
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
            for content in output.content {
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

// MARK: - Streaming Simulation
struct StreamingSimulator {
    /// Simulate streaming output by yielding text chunks
    static func simulateStreamingResponse(_ text: String) async {
        let words = text.split(separator: " ")
        for (index, word) in words.enumerated() {
            print(word, terminator: index < words.count - 1 ? " " : "\n")
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        }
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
        print("• 🌊 Streaming output simulation")
        print("• 🔧 Function calling (weather, calculator)")
        print("• 🐍 Code interpreter tool")
        print("• 🖼️  Multi-modal support (images)")
        print("• 📚 Conversation history chaining")
        print("")
        print("Commands:")
        print("• 'weather:[location]' - Get weather for a location")
        print("• 'code:[python code]' - Execute Python code")
        print("• 'calc:[expression]' - Calculate mathematical expression")
        print("• 'image:[url]' - Analyze an image from URL")
        print("• 'base64:[data]' - Analyze base64 image data")
        print("• 'history' - Show conversation history")
        print("• 'clear' - Clear conversation history")
        print("• 'help' - Show this help message")
        print("• 'quit' - Exit the chatbot")
        print("\n💡 Example: 'weather:London' or 'code:print(2+2)'")
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
        
        print("\n🤖 Assistant: ", terminator: "")
        
        if needsTools {
            try await handleToolBasedRequest(input, message: message)
        } else {
            try await handleRegularRequest(message)
        }
    }
    
    private func processInput(_ input: String) -> (SAOAIMessage, Bool) {
        // Check for tool-specific commands
        if input.hasPrefix("weather:") || input.hasPrefix("code:") || input.hasPrefix("calc:") {
            let message = SAOAIMessage(role: .user, text: input)
            return (message, true)
        }
        
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
        
        // Regular text message
        let message = SAOAIMessage(role: .user, text: input)
        return (message, false)
    }
    
    private func handleToolBasedRequest(_ input: String, message: SAOAIMessage) async throws {
        print("🔧 Processing with tools...\n")
        
        // Simulate API call with tools
        let response = try await client.responses.create(
            model: "gpt-4o",
            input: chatHistory.conversationMessages,
            tools: availableTools,
            previousResponseId: chatHistory.lastResponseId
        )
        
        // Process tool calls
        var toolResults: [SAOAIMessage] = []
        
        for output in response.output {
            for content in output.content {
                switch content {
                case .outputText(let textOutput):
                    await StreamingSimulator.simulateStreamingResponse(textOutput.text)
                    
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
                        content: [.functionCallOutput(.init(
                            callId: functionCall.callId,
                            output: result
                        ))]
                    ))
                }
            }
        }
        
        chatHistory.addAssistantResponse(response)
        
        // If we have tool results, send follow-up request
        if !toolResults.isEmpty {
            print("\n🔧 Processing tool results...")
            let finalResponse = try await client.responses.create(
                model: "gpt-4o",
                input: chatHistory.conversationMessages + toolResults,
                previousResponseId: response.id
            )
            
            for output in finalResponse.output {
                for content in output.content {
                    if case let .outputText(textOutput) = content {
                        await StreamingSimulator.simulateStreamingResponse(textOutput.text)
                    }
                }
            }
            
            chatHistory.addAssistantResponse(finalResponse)
        }
        
        print("\n")
    }
    
    private func handleRegularRequest(_ message: SAOAIMessage) async throws {
        let response = try await client.responses.create(
            model: "gpt-4o",
            input: chatHistory.conversationMessages,
            previousResponseId: chatHistory.lastResponseId
        )
        
        for output in response.output {
            for content in output.content {
                if case let .outputText(textOutput) = content {
                    await StreamingSimulator.simulateStreamingResponse(textOutput.text)
                }
            }
        }
        
        chatHistory.addAssistantResponse(response)
        print("\n")
    }
    
    private func executeTool(name: String, arguments: String, input: String) async -> String {
        switch name {
        case "get_weather":
            let location = extractValue(from: input, prefix: "weather:")
            return ToolExecutor.getWeather(location: location)
            
        case "code_interpreter":
            let code = extractValue(from: input, prefix: "code:")
            print("🐍 Executing: \(code)")
            return ToolExecutor.executeCode(code)
            
        case "calculate":
            let expression = extractValue(from: input, prefix: "calc:")
            print("🧮 Calculating: \(expression)")
            return ToolExecutor.calculate(expression)
            
        default:
            return "{\"error\": \"Unknown tool: \(name)\"}"
        }
    }
    
    private func extractValue(from input: String, prefix: String) -> String {
        if input.hasPrefix(prefix) {
            return String(input.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        }
        return input
    }
}

// MARK: - Demo Mode (for when running without real API credentials)
func runDemoMode() {
    print("🔧 Demo Mode - Advanced Console Chatbot")
    print("=======================================")
    print("This example demonstrates all SwiftAzureOpenAI features in an interactive console:")
    print("")
    print("📝 Features showcased:")
    print("• ✅ Streaming output simulation")
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
    print("2. Uncomment the line below and run:")
    print("   // Task { await AdvancedConsoleChatbot().start() }")
    print("")
    print("💡 Example interactions:")
    print("👤 User: weather:Tokyo")
    print("🤖 Assistant: 🔧 Calling tool: get_weather")
    print("             The current weather in Tokyo is 22°C and sunny...")
    print("")
    print("👤 User: code:print('Hello, World!')")
    print("🤖 Assistant: 🐍 Executing: print('Hello, World!')")
    print("             I've executed your Python code. Output: Hello, World!")
    print("")
    print("👤 User: calc:sqrt(64)")
    print("🤖 Assistant: 🧮 Calculating: sqrt(64)")
    print("             The square root of 64 is 8.")
    print("")
    print("👤 User: image:https://example.com/photo.jpg")
    print("🤖 Assistant: I can see this is an image showing...")
}

// MARK: - Main Execution
@main
struct AdvancedConsoleChatbotApp {
    static func main() async {
        // Check if we have valid API credentials
        let hasCredentials = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] != nil &&
                           ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] != nil &&
                           ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] != "https://your-resource.openai.azure.com"
        
        if hasCredentials {
            // Run with real API
            await AdvancedConsoleChatbot().start()
        } else {
            // Run in demo mode
            runDemoMode()
        }
    }
}