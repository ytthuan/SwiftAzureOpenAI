import Foundation
import SwiftAzureOpenAI

// MARK: - Interactive Console Chatbot Example

/// Complete console chatbot example demonstrating:
/// - Interactive user input/output in console
/// - Proper chat history chaining with previous_response_id
/// - Multi-modal support (text + images)
/// - Latest SAOAI class names and API patterns

// MARK: - Configuration
let azureConfig = SAOAIAzureConfiguration(
    endpoint: ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] ?? "https://your-resource.openai.azure.com",
    apiKey: ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ?? "your-api-key",
    deploymentName: ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? "gpt-4o",
    apiVersion: "preview"
)

let client = SAOAIClient(configuration: azureConfig)

// MARK: - Chat History Management
class ChatHistory {
    var messages: [SAOAIMessage] = []
    var responseIds: [String] = []
    
    func addUserMessage(_ message: SAOAIMessage) {
        messages.append(message)
    }
    
    func addAssistantResponse(_ response: SAOAIResponse) {
        // Extract assistant message from response
        for output in response.output {
            guard let contentArray = output.content else { continue }
            for content in contentArray {
                if case let .outputText(textOutput) = content {
                    let assistantMessage = SAOAIMessage(role: .assistant, text: textOutput.text)
                    messages.append(assistantMessage)
                    break
                }
            }
        }
        
        // Store response ID for chaining
        if let responseId = response.id {
            responseIds.append(responseId)
        }
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
            let roleIcon = message.role == .user ? "👤" : "🤖"
            let content = message.content.first?.description ?? "No content"
            print("\(index + 1). \(roleIcon) \(message.role.rawValue.capitalized): \(content)")
        }
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
        print("🤖 SwiftAzureOpenAI Console Chatbot")
        print("==================================")
        print("Welcome! I'm your AI assistant with multi-modal capabilities.")
        print("\nCommands:")
        print("• Type your message and press Enter")
        print("• For images: 'image: https://example.com/image.jpg'")
        print("• For base64 images: 'base64: <base64-data>'")
        print("• Type 'history' to see conversation history")
        print("• Type 'clear' to start a new conversation")
        print("• Type 'quit' to exit")
        print("\nNote: Using environment variables for configuration:")
        print("• AZURE_OPENAI_ENDPOINT (or default placeholder)")
        print("• AZURE_OPENAI_API_KEY (or default placeholder)")
        print("• AZURE_OPENAI_DEPLOYMENT (or default: gpt-4o)")
        print("==================================\n")
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
        default:
            break
        }
        
        // Process user input and create message
        let userMessage = try createUserMessage(from: trimmedInput)
        chatHistory.addUserMessage(userMessage)
        
        // Send to AI and get response
        print("🤖 Assistant: ", terminator: "")
        let response = try await sendMessage(userMessage)
        
        // Display response
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
        // Use response chaining if we have a previous response
        if let previousResponseId = chatHistory.lastResponseId {
            return try await client.responses.create(
                model: azureConfig.deploymentName,
                input: [message],
                maxOutputTokens: 500,
                previousResponseId: previousResponseId
            )
        } else {
            // First message in conversation - include system message
            let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant with vision capabilities. You can analyze images and have detailed conversations about them.")
            return try await client.responses.create(
                model: azureConfig.deploymentName,
                input: [systemMessage, message],
                maxOutputTokens: 500
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
    
    private func startNewConversation() async {
        print("🔄 Starting new conversation...")
        // Keep the ChatHistory instance but reset it
        chatHistory.messages.removeAll()
        chatHistory.responseIds.removeAll()
        print("✅ Conversation cleared. You can start fresh!\n")
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

// MARK: - Demo Mode (for when running without real API credentials)
func runDemoMode() {
    print("🔧 Demo Mode - Simulating Console Chatbot")
    print("========================================")
    print("This example shows how the console chatbot would work with real API credentials.")
    print("\n📝 Features demonstrated:")
    print("• ✅ Interactive console input/output")
    print("• ✅ Chat history management with chaining")
    print("• ✅ Multi-modal support (text + images)")
    print("• ✅ Command handling (history, clear, quit)")
    print("• ✅ Error handling and validation")
    print("• ✅ Latest SAOAI class names (SAOAIClient, SAOAIMessage, etc.)")
    
    print("\n🚀 To run with real API:")
    print("1. Set environment variables:")
    print("   export AZURE_OPENAI_ENDPOINT='https://your-resource.openai.azure.com'")
    print("   export AZURE_OPENAI_API_KEY='your-api-key'")
    print("   export AZURE_OPENAI_DEPLOYMENT='gpt-4o'")
    print("2. Uncomment the line below and run:")
    print("   // Task { await ConsoleChatbot().start() }")
    
    print("\n💡 Example interactions:")
    print("👤 User: Hello, how are you?")
    print("🤖 Assistant: Hello! I'm doing well, thank you for asking...")
    print()
    print("👤 User: image: https://example.com/photo.jpg")
    print("🤖 Assistant: I can see this is an image of...")
    print()
    print("👤 User: What was in that image again?")
    print("🤖 Assistant: [Chained response based on previous image analysis]...")
}

// MARK: - Main Execution
@main
struct ConsoleChatbotApp {
    static func main() async {
        print("🚀 SwiftAzureOpenAI Interactive Console Chatbot Example")
        print("======================================================")

        // Check if we have real credentials (basic check)
        let hasCredentials = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] != nil && 
                            ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] != nil

        if hasCredentials {
            print("✅ Found environment variables - Starting live chatbot...")
            // Uncomment the next line to run with real API calls:
            // await ConsoleChatbot().start()
            print("⚠️  Live mode disabled for this demo. Uncomment the await line to enable.")
            runDemoMode()
        } else {
            print("ℹ️  No API credentials detected - Running in demo mode...")
            runDemoMode()
        }

        print("\n🎯 This example demonstrates:")
        print("• Complete interactive console chatbot")
        print("• Proper chat history chaining with previous_response_id")
        print("• Multi-modal support (image URLs and base64)")
        print("• Modern SwiftAzureOpenAI v2.0+ class names")
        print("• Error handling and user experience")
        print("• Environment variable configuration")
    }
}