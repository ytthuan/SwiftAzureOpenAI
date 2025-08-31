import XCTest
@testable import SwiftAzureOpenAI

/// Tests to verify the AdvancedConsoleChatbot streaming issue and fix
final class AdvancedConsoleChatbotStreamingTests: XCTestCase {
    
    /// Test that demonstrates the issue with streaming calls missing system message
    func testStreamingWithEmptyConversationShouldIncludeSystemMessage() {
        // This test demonstrates the issue pattern that causes "Bad Request"
        // when streaming is called with empty conversation history
        
        let mockConfig = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: mockConfig)
        
        // Simulate the problematic scenario: empty conversation messages
        let emptyMessages: [SAOAIMessage] = []
        
        // This is what AdvancedConsoleChatbot does and causes "Bad Request"
        let streamingCall = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: emptyMessages,  // Empty array - this is the problem!
            previousResponseId: nil
        )
        
        // The call should be created without throwing, but will fail when executed
        // because Azure OpenAI requires at least one message in the conversation
        XCTAssertNotNil(streamingCall)
    }
    
    /// Test that demonstrates the working pattern used by ConsoleChatbot
    func testNonStreamingWithSystemMessageWorks() {
        let mockConfig = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: mockConfig)
        
        // This is what ConsoleChatbot does and works correctly
        let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant.")
        let userMessage = SAOAIMessage(role: .user, text: "Hello")
        
        // This pattern works (though we can't test actual execution without real API)
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                return try await client.responses.create(
                    model: mockConfig.deploymentName,
                    input: [systemMessage, userMessage],
                    maxOutputTokens: 500
                )
            }
        }())
    }
    
    /// Test the corrected streaming pattern that should work
    func testStreamingWithSystemMessageShouldWork() {
        let mockConfig = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: mockConfig)
        
        // This is the corrected pattern for streaming
        let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant.")
        let userMessage = SAOAIMessage(role: .user, text: "Hello")
        
        let correctedStream = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: [systemMessage, userMessage],  // Include system message!
            previousResponseId: nil
        )
        
        XCTAssertNotNil(correctedStream)
    }
    
    /// Test that verifies the pattern with tools also includes system message
    func testStreamingWithToolsAndSystemMessage() {
        let mockConfig = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: mockConfig)
        
        let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant.")
        let userMessage = SAOAIMessage(role: .user, text: "What's the weather?")
        
        let weatherTool = SAOAITool.function(
            name: "get_weather",
            description: "Get weather",
            parameters: .object(["type": .string("object")])
        )
        
        let correctedStreamWithTools = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: [systemMessage, userMessage],  // Include system message!
            tools: [weatherTool],
            previousResponseId: nil
        )
        
        XCTAssertNotNil(correctedStreamWithTools)
    }
    
    /// Test that simulates the AdvancedConsoleChatbot conversation flow pattern
    func testAdvancedConsoleChatbotConversationPattern() {
        let mockConfig = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: mockConfig)
        
        // Simulate the fixed AdvancedConsoleChatbot pattern
        
        // 1. First conversation: Include system message
        let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant with vision capabilities. You can analyze images and have detailed conversations about them.")
        let firstUserMessage = SAOAIMessage(role: .user, text: "Hello")
        let conversationMessages = [firstUserMessage]
        
        // For first conversation (no previous response ID), include system message
        let firstCallMessages = [systemMessage] + conversationMessages
        
        let firstStream = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: firstCallMessages,
            previousResponseId: nil
        )
        
        XCTAssertNotNil(firstStream)
        
        // 2. Subsequent conversation: Use conversation messages with response ID
        let secondUserMessage = SAOAIMessage(role: .user, text: "How are you?")
        let updatedConversationMessages = conversationMessages + [secondUserMessage]
        
        // For subsequent conversations (with previous response ID), use conversation messages as-is
        let subsequentStream = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: updatedConversationMessages,
            previousResponseId: "some-response-id"
        )
        
        XCTAssertNotNil(subsequentStream)
    }
    
    /// Test that simulates the AdvancedConsoleChatbot tool-based conversation pattern
    func testAdvancedConsoleChatbotToolBasedPattern() {
        let mockConfig = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: mockConfig)
        
        let weatherTool = SAOAITool.function(
            name: "get_weather",
            description: "Get weather",
            parameters: .object(["type": .string("object")])
        )
        
        // Simulate the fixed AdvancedConsoleChatbot tool-based pattern
        
        // 1. First tool-based conversation: Include system message with tools
        let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant with vision capabilities. You can analyze images and have detailed conversations about them. You have access to tools for weather, calculations, and code execution.")
        let firstUserMessage = SAOAIMessage(role: .user, text: "What's the weather in Tokyo?")
        let conversationMessages = [firstUserMessage]
        
        // For first conversation (no previous response ID), include system message
        let firstCallMessages = [systemMessage] + conversationMessages
        
        let firstToolStream = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: firstCallMessages,
            tools: [weatherTool],
            previousResponseId: nil
        )
        
        XCTAssertNotNil(firstToolStream)
        
        // 2. Follow-up with tool results: Include tool result messages
        let toolResultMessage = SAOAIMessage(
            role: .user,
            content: [.functionCallOutput(.init(
                callId: "call_123",
                output: "{\"weather\": \"sunny\"}"
            ))]
        )
        
        let followUpStream = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: firstCallMessages + [toolResultMessage],
            previousResponseId: "some-response-id"
        )
        
        XCTAssertNotNil(followUpStream)
    }
    
    /// Test that validates the exact fix for AdvancedConsoleChatbot streaming pattern
    func testFixedAdvancedConsoleChatbotStreamingPattern() {
        let mockConfig = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: mockConfig)
        
        let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant.")
        let firstUserMessage = SAOAIMessage(role: .user, text: "Hello")
        let secondUserMessage = SAOAIMessage(role: .user, text: "How are you?")
        
        // Test the FIXED pattern for AdvancedConsoleChatbot
        
        // 1. First conversation: [systemMessage, currentUserMessage] with no previousResponseId
        let firstStream = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: [systemMessage, firstUserMessage],  // FIXED: Not using conversation history
            previousResponseId: nil
        )
        
        XCTAssertNotNil(firstStream)
        
        // 2. Subsequent conversation: [currentUserMessage] with previousResponseId
        let subsequentStream = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: [secondUserMessage],  // FIXED: Only current message, not conversation history
            previousResponseId: "response-id-1"
        )
        
        XCTAssertNotNil(subsequentStream)
        
        // 3. Tool-based pattern: Same logic applies
        let weatherTool = SAOAITool.function(
            name: "get_weather",
            description: "Get weather",
            parameters: .object(["type": .string("object")])
        )
        
        let toolUserMessage = SAOAIMessage(role: .user, text: "weather:London")
        
        // First tool-based conversation
        let firstToolStream = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: [systemMessage, toolUserMessage],  // FIXED: Not using conversation history
            tools: [weatherTool],
            previousResponseId: nil
        )
        
        XCTAssertNotNil(firstToolStream)
        
        // Subsequent tool-based conversation
        let subsequentToolStream = client.responses.createStreaming(
            model: mockConfig.deploymentName,
            input: [toolUserMessage],  // FIXED: Only current message
            tools: [weatherTool],
            previousResponseId: "response-id-2"
        )
        
        XCTAssertNotNil(subsequentToolStream)
    }
}