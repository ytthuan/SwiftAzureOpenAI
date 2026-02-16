import Foundation
import SwiftAzureOpenAI

// MARK: - Interactive Console Chatbot Example

/// Complete console chatbot example demonstrating:
/// - Interactive user input/output in console
/// - Proper chat history chaining with previous_response_id
/// - Multi-modal support (text + images)
/// - Function calling and tools integration
/// - Code interpreter functionality
/// - Latest SAOAI class names and API patterns

// MARK: - Configuration
let openAIConfig = SAOAIOpenAIConfiguration(
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-api-key",
    organization: ProcessInfo.processInfo.environment["OPENAI_ORGANIZATION"]
)

let client = SAOAIClient(configuration: openAIConfig)

// MARK: - Chat History Management
class ChatHistory {
    var messages: [SAOAIMessage] = []
    var responseIds: [String] = []
    var toolsEnabled: Bool = false
    
    func addUserMessage(_ message: SAOAIMessage) {
        messages.append(message)
    }
    
    func addAssistantResponse(_ response: SAOAIResponse) {
        // Extract assistant message from response
        for output in response.output {
            guard let contentArray = output.content else { continue }
            for content in contentArray {
                switch content {
                case .outputText(let textOutput):
                    let assistantMessage = SAOAIMessage(role: .assistant, text: textOutput.text)
                    messages.append(assistantMessage)
                case .functionCall(_):
                    // Function calls are handled separately and don't get added to history directly
                    break
                }
            }
        }
        
        // Store response ID for chaining
        if let responseId = response.id {
            responseIds.append(responseId)
        }
    }
    
    func addFunctionResults(_ functionResults: [SAOAIMessage]) {
        messages.append(contentsOf: functionResults)
    }
    
    var lastResponseId: String? {
        return responseIds.last
    }
    
    var conversationMessages: [SAOAIMessage] {
        return messages
    }
    
    func printHistory() {
        print("\n📜 Chat History:")
        print("================")
        for (index, message) in messages.enumerated() {
            let roleIcon = message.role == .user ? "👤" : message.role == .assistant ? "🤖" : "🔧"
            let content = message.content.first?.description ?? "No content"
            let roleName = message.role?.rawValue.capitalized ?? "ToolOutput"
            print("\(index + 1). \(roleIcon) \(roleName): \(content)")
        }
        print("Tools enabled: \(toolsEnabled ? "✅" : "❌")")
        print("================\n")
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
        // Simple check for base64 image data
        return input.hasPrefix("data:image/") || 
               (input.count > 100 && input.allSatisfy { $0.isLetter || $0.isNumber || "=+/".contains($0) })
    }
}

// MARK: - Function Call Definitions
struct FunctionRegistry {
    static let tools: [SAOAITool] = [
        SAOAITool.function(
            name: "get_weather",
            description: "Get current weather information for a specific location",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("The city or location to get weather for")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        ),
        SAOAITool.function(
            name: "calculate",
            description: "Perform mathematical calculations",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "expression": .object([
                        "type": .string("string"),
                        "description": .string("Mathematical expression to evaluate (e.g., '2 + 3 * 4')")
                    ])
                ]),
                "required": .array([.string("expression")])
            ])
        ),
        SAOAITool.function(
            name: "execute_code",
            description: "Execute Python-like code and return results",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "code": .object([
                        "type": .string("string"),
                        "description": .string("Python-like code to execute")
                    ]),
                    "language": .object([
                        "type": .string("string"),
                        "description": .string("Programming language (python, swift, javascript)")
                    ])
                ]),
                "required": .array([.string("code")])
            ])
        ),
        SAOAITool.function(
            name: "file_operations",
            description: "Perform file operations like reading, writing, or listing files",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "operation": .object([
                        "type": .string("string"),
                        "description": .string("Operation to perform: 'read', 'write', 'list'")
                    ]),
                    "path": .object([
                        "type": .string("string"),
                        "description": .string("File or directory path")
                    ]),
                    "content": .object([
                        "type": .string("string"),
                        "description": .string("Content to write (for write operation)")
                    ])
                ]),
                "required": .array([.string("operation"), .string("path")])
            ])
        )
    ]
    
    static func executeFunction(name: String, arguments: String) -> String {
        switch name {
        case "get_weather":
            return executeWeatherFunction(arguments: arguments)
        case "calculate":
            return executeCalculateFunction(arguments: arguments)
        case "execute_code":
            return executeCodeFunction(arguments: arguments)
        case "file_operations":
            return executeFileOperation(arguments: arguments)
        default:
            return "{\"error\": \"Unknown function: \(name)\"}"
        }
    }
    
    private static func executeWeatherFunction(arguments: String) -> String {
        guard let data = arguments.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let location = json["location"] as? String else {
            return "{\"error\": \"Invalid arguments for weather function\"}"
        }
        
        // Simulate weather data based on location
        let weatherData = [
            "location": location,
            "temperature": getRandomTemperature(),
            "condition": getRandomCondition(),
            "humidity": "\(Int.random(in: 30...80))%",
            "wind_speed": "\(Int.random(in: 5...25)) mph"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: weatherData)
            return String(data: jsonData, encoding: .utf8) ?? "{\"error\": \"Failed to serialize weather data\"}"
        } catch {
            return "{\"error\": \"Failed to create weather response\"}"
        }
    }
    
    private static func executeCalculateFunction(arguments: String) -> String {
        guard let data = arguments.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let expression = json["expression"] as? String else {
            return "{\"error\": \"Invalid arguments for calculation function\"}"
        }
        
        // Simple expression evaluator (for demo purposes)
        let result = evaluateExpression(expression)
        return "{\"expression\": \"\(expression)\", \"result\": \(result)}"
    }
    
    private static func executeCodeFunction(arguments: String) -> String {
        guard let data = arguments.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = json["code"] as? String else {
            return "{\"error\": \"Invalid arguments for code execution function\"}"
        }
        
        let language = json["language"] as? String ?? "python"
        
        // Simulate code execution (in a real implementation, this would be sandboxed)
        let output = simulateCodeExecution(code: code, language: language)
        return "{\"language\": \"\(language)\", \"code\": \"\(code)\", \"output\": \"\(output)\"}"
    }
    
    private static func executeFileOperation(arguments: String) -> String {
        guard let data = arguments.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let operation = json["operation"] as? String,
              let path = json["path"] as? String else {
            return "{\"error\": \"Invalid arguments for file operation function\"}"
        }
        
        switch operation {
        case "list":
            // Simulate directory listing
            return "{\"operation\": \"list\", \"path\": \"\(path)\", \"files\": [\"file1.txt\", \"file2.py\", \"folder1/\"]}"
        case "read":
            // Simulate file reading
            return "{\"operation\": \"read\", \"path\": \"\(path)\", \"content\": \"Sample file content for demonstration\"}"
        case "write":
            let content = json["content"] as? String ?? ""
            return "{\"operation\": \"write\", \"path\": \"\(path)\", \"status\": \"success\", \"bytes_written\": \(content.count)}"
        default:
            return "{\"error\": \"Unknown operation: \(operation)\"}"
        }
    }
    
    // Helper functions
    private static func getRandomTemperature() -> String {
        return "\(Int.random(in: 50...85))°F"
    }
    
    private static func getRandomCondition() -> String {
        let conditions = ["sunny", "cloudy", "partly cloudy", "rainy", "overcast"]
        return conditions.randomElement() ?? "sunny"
    }
    
    private static func evaluateExpression(_ expression: String) -> Double {
        // Simple expression evaluator - in reality you'd use a proper parser
        let cleanExpression = expression.replacingOccurrences(of: " ", with: "")
        
        // Handle basic operations for demo
        if cleanExpression.contains("+") {
            let parts = cleanExpression.split(separator: "+")
            if parts.count == 2,
               let a = Double(parts[0]), let b = Double(parts[1]) {
                return a + b
            }
        } else if cleanExpression.contains("-") {
            let parts = cleanExpression.split(separator: "-")
            if parts.count == 2,
               let a = Double(parts[0]), let b = Double(parts[1]) {
                return a - b
            }
        } else if cleanExpression.contains("*") {
            let parts = cleanExpression.split(separator: "*")
            if parts.count == 2,
               let a = Double(parts[0]), let b = Double(parts[1]) {
                return a * b
            }
        } else if cleanExpression.contains("/") {
            let parts = cleanExpression.split(separator: "/")
            if parts.count == 2,
               let a = Double(parts[0]), let b = Double(parts[1]), b != 0 {
                return a / b
            }
        }
        
        return Double(cleanExpression) ?? 0
    }
    
    private static func simulateCodeExecution(code: String, language: String) -> String {
        // Simulate different types of code execution
        switch language.lowercased() {
        case "python":
            if code.contains("print(") {
                let output = code.replacingOccurrences(of: "print(", with: "").replacingOccurrences(of: ")", with: "")
                return "Output: \(output)"
            } else if code.contains("import") {
                return "Modules imported successfully"
            } else if code.contains("=") {
                return "Variables assigned successfully"
            } else {
                return "Code executed: \(code)"
            }
        case "swift":
            return "Swift code compiled and executed: \(code)"
        case "javascript":
            return "JavaScript executed in Node.js environment: \(code)"
        default:
            return "Code executed in \(language) environment: \(code)"
        }
    }
}

// MARK: - Console Interface
class ConsoleChatbot {
    private let chatHistory = ChatHistory()
    private var isRunning = true
    
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
        
        print("👋 Goodbye! Thanks for using the SwiftAzureOpenAI Console Chatbot!")
    }
    
    private func printWelcome() {
        print("🤖 SwiftAzureOpenAI Console Chatbot with Tools")
        print("==============================================")
        print("Welcome! I'm your AI assistant with multi-modal capabilities and tools support.")
        print("\nCommands:")
        print("• Type your message and press Enter")
        print("• For images: 'image: https://example.com/image.jpg'")
        print("• For base64 images: 'base64: <base64-data>'")
        print("• Type 'history' to see conversation history")
        print("• Type 'clear' to start a new conversation")
        print("• Type 'tools' to toggle tools/function calling on/off")
        print("• Type 'tools list' to see available tools")
        print("• Type 'quit' to exit")
        print("\nNote: Using environment variables for configuration:")
        print("• OPENAI_API_KEY (required)")
        print("• OPENAI_ORGANIZATION (optional)")
        print("• MODEL: gpt-4o (default)")
        print("\n🔧 Tools Status: \(chatHistory.toolsEnabled ? "✅ Enabled" : "❌ Disabled")")
        print("==============================================\n")
    }
    
    private func handleUserInput() async throws {
        print("👤 You: ", terminator: "")
        guard let input = readLine(), !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle commands
        switch trimmedInput.lowercased() {
        case "quit", "exit":
            isRunning = false
            return
        case "history":
            chatHistory.printHistory()
            return
        case "clear":
            await startNewConversation()
            return
        case "tools":
            chatHistory.toolsEnabled.toggle()
            print("🔧 Tools \(chatHistory.toolsEnabled ? "enabled" : "disabled")\n")
            return
        case "tools list":
            printAvailableTools()
            return
        default:
            break
        }
        
        // Process user input and create message
        let userMessage = try createUserMessage(from: trimmedInput)
        chatHistory.addUserMessage(userMessage)
        
        // Send to AI and get response
        print("🤖 Assistant: ", terminator: "")
        let response = try await sendMessage(userMessage)
        
        // Handle function calls if present
        if await handleFunctionCalls(response: response) {
            return // Function calls were processed
        }
        
        // Display regular response
        displayResponse(response)
        
        // Add to history for chaining
        chatHistory.addAssistantResponse(response)
        print()
    }
    
    private func createUserMessage(from input: String) throws -> SAOAIMessage {
        // Check for image URL
        if input.lowercased().hasPrefix("image:") {
            let imageURL = String(input.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard ImageProcessor.isValidImageURL(imageURL) else {
                throw NSError(domain: "ChatbotError", code: 1, 
                             userInfo: [NSLocalizedDescriptionKey: "Invalid image URL format. Please use: image: https://example.com/image.jpg"])
            }
            return SAOAIMessage(role: .user, text: "Please analyze this image:", imageURL: imageURL)
        }
        
        // Check for base64 image
        if input.lowercased().hasPrefix("base64:") {
            let base64Data = String(input.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard ImageProcessor.isValidBase64Image(base64Data) else {
                throw NSError(domain: "ChatbotError", code: 2,
                             userInfo: [NSLocalizedDescriptionKey: "Invalid base64 image data. Please provide valid base64 encoded image."])
            }
            return SAOAIMessage(role: .user, text: "Please analyze this image:", base64Image: base64Data, mimeType: "image/jpeg")
        }
        
        // Regular text message
        return SAOAIMessage(role: .user, text: input)
    }
    
    private func sendMessage(_ message: SAOAIMessage) async throws -> SAOAIResponse {
        let model = "gpt-4o"
        // Use response chaining if we have a previous response
        if let previousResponseId = chatHistory.lastResponseId {
            return try await client.responses.create(
                model: model,
                input: [message],
                maxOutputTokens: 500,
                tools: chatHistory.toolsEnabled ? FunctionRegistry.tools : nil,
                previousResponseId: previousResponseId
            )
        } else {
            // First message in conversation - include system message
            let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant with vision capabilities and access to various tools. You can analyze images, perform calculations, execute code, get weather information, and handle file operations. When tools are available, use them to provide accurate and helpful responses.")
            return try await client.responses.create(
                model: model,
                input: [systemMessage, message],
                maxOutputTokens: 500,
                tools: chatHistory.toolsEnabled ? FunctionRegistry.tools : nil
            )
        }
    }
    
    private func displayResponse(_ response: SAOAIResponse) {
        var hasContent = false

        for output in response.output {
            guard let contentArray = output.content else { continue }
            for content in contentArray {
                switch content {
                case .outputText(let textOutput):
                    print(textOutput.text)
                    hasContent = true
                case .functionCall(let functionCall):
                    print("🔧 Function call: \(functionCall.name)")
                    hasContent = true
                }
            }
        }
        
        if !hasContent {
            print("(No response content)")
        }
        
        // Show response metadata
        if let responseId = response.id {
            print("\n💡 Response ID: \(responseId)")
        }
        if let usage = response.usage {
            print("📊 Tokens - Input: \(usage.inputTokens ?? 0), Output: \(usage.outputTokens ?? 0)")
        }
    }
    
    private func printAvailableTools() {
        print("\n🔧 Available Tools:")
        print("==================")
        print("1. 🌤️  get_weather - Get current weather for any location")
        print("2. 🧮 calculate - Perform mathematical calculations")
        print("3. 💻 execute_code - Execute Python, Swift, or JavaScript code")
        print("4. 📁 file_operations - Read, write, or list files")
        print("\nYou can use these tools by:")
        print("• Asking me naturally (e.g., 'What's the weather in Tokyo?')")
        print("• Enabling tools with 'tools' command first")
        print("==================\n")
    }
    
    private func handleFunctionCalls(response: SAOAIResponse) async -> Bool {
        var functionCalls: [(String, String, String)] = [] // name, callId, arguments
        
        // Check for function calls in response output - OpenAI Responses API puts function calls at output level
        for output in response.output {
            // For OpenAI Responses API, function calls appear at output level with type: "function_call"
            if output.type == "function_call" {
                // Access function call fields directly from the updated SDK model
                if let name = output.name, let callId = output.callId, let arguments = output.arguments {
                    functionCalls.append((name, callId, arguments))
                    print("🔧 Calling function: \(name)")
                }
            } else {
                // Also check content for function calls (fallback for Chat Completions API or other versions)
                if let contentArray = output.content {
                    for content in contentArray {
                        switch content {
                        case .outputText(let textOutput):
                            print(textOutput.text)
                        case .functionCall(let functionCall):
                            functionCalls.append((functionCall.name, functionCall.callId, functionCall.arguments))
                            print("🔧 Calling function: \(functionCall.name)")
                        }
                    }
                }
            }
        }
        
        // If no function calls, return false to continue with normal flow
        if functionCalls.isEmpty {
            return false
        }
        
        // Execute function calls and prepare results
        var functionResults: [SAOAIMessage] = []
        
        for (name, callId, arguments) in functionCalls {
            print("⚙️  Executing \(name)...")
            let result = FunctionRegistry.executeFunction(name: name, arguments: arguments)
            print("✅ \(name) completed")
            
            functionResults.append(SAOAIMessage(
                role: .user,
                content: [.inputText(.init(
                    text: "Function \(name) (call_id: \(callId)) result: \(result)"
                ))]
            ))
        }
        
        // Add function results to history
        chatHistory.addFunctionResults(functionResults)
        
        // Send function results back to get final response
        do {
            let model = "gpt-4o"
            print("\n🤖 Processing results...")
            let finalResponse = try await client.responses.create(
                model: model,
                input: functionResults,
                maxOutputTokens: 500,
                previousResponseId: response.id
            )
            
            // Display final response
            print("🤖 Assistant: ", terminator: "")
            displayResponse(finalResponse)
            
            // Add final response to history
            chatHistory.addAssistantResponse(finalResponse)
            print()
            
        } catch {
            print("❌ Error processing function results: \(error.localizedDescription)")
        }
        
        return true // Function calls were processed
    }
    
    private func startNewConversation() async {
        print("🔄 Starting new conversation...")
        // Keep the ChatHistory instance but reset it (preserve tools setting)
        let toolsEnabled = chatHistory.toolsEnabled
        chatHistory.messages.removeAll()
        chatHistory.responseIds.removeAll()
        chatHistory.toolsEnabled = toolsEnabled
        print("✅ Conversation cleared. You can start fresh!")
        print("🔧 Tools: \(toolsEnabled ? "✅ Enabled" : "❌ Disabled")\n")
    }
}

// MARK: - Extension for Content Display
extension SAOAIInputContent: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .inputText(let text):
            return text.text
        case .inputImage(let image):
            return "Image: \(image.imageURL)"
        case .functionCallOutput(let output):
            return "Function output: \(output.callId)"
        }
    }
}

// MARK: - Main Execution
@main
struct ConsoleChatbotApp {
    static func main() async {
        print("🚀 SwiftAzureOpenAI Enhanced Console Chatbot with Tools")
        print("======================================================")

        // Check if we have API key
        let hasAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil

        if hasAPIKey {
            print("✅ Found OpenAI API key - Starting live chatbot...")
            await ConsoleChatbot().start()
        } else {
            print("ℹ️  No API key found, but starting chatbot anyway...")
            print("🔑 Set OPENAI_API_KEY environment variable for live mode")
            await ConsoleChatbot().start()
        }


    }
}