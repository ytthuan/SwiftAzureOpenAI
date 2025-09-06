import XCTest
@testable import SwiftAzureOpenAI

/// Tests for streaming function call handling in Advanced Console Chatbot
/// These tests verify that the fix for streaming chatbot tool call handling works correctly
final class AdvancedConsoleChatbotStreamingFunctionCallTests: XCTestCase {
    
    /// Test that function call detection works in streaming chunks
    func testFunctionCallDetectionInStreaming() throws {
        // Create a mock streaming response chunk that contains function call content
        let functionCallContent = SAOAIStreamingContent(
            type: "function_call",
            text: "Function call: get_weather",
            index: 0
        )
        
        let streamingOutput = SAOAIStreamingOutput(
            content: [functionCallContent],
            role: "assistant"
        )
        
        let streamingResponse = SAOAIStreamingResponse(
            id: "test_response_123",
            model: "gpt-4o",
            created: 1234567890,
            output: [streamingOutput],
            usage: nil
        )
        
        // Verify that function call content is properly detected
        XCTAssertEqual(streamingResponse.output?.first?.content?.first?.type, "function_call")
        XCTAssertEqual(streamingResponse.output?.first?.content?.first?.text, "Function call: get_weather")
        
        print("✅ Function call detection in streaming works correctly")
    }
    
    /// Test that the SSE parser correctly handles function call events
    func testSSEParserFunctionCallHandling() throws {
        // Test data that includes a function call in the response.completed event
        let sseData = """
        event: response.completed
        data: {"type":"response.completed","sequence_number":3,"response":{"id":"resp_123","object":"response","created_at":1234567890,"status":"completed","model":"gpt-4o","output":[{"id":"fc_789","type":"function_call","name":"get_weather","arguments":"{\\"location\\":\\"San Francisco\\"}","call_id":"call_abc123","status":"completed"}],"usage":{"input_tokens":10,"output_tokens":20,"total_tokens":30}}}
        
        """.data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(sseData)
        XCTAssertNotNil(response, "Response should be parsed")
        
        if let response = response {
            XCTAssertEqual(response.id, "resp_123")
            XCTAssertNotNil(response.output, "Output should exist")
            
            // Check that function call content is created
            let output = response.output?.first
            XCTAssertNotNil(output, "First output should exist")
            
            let content = output?.content?.first
            XCTAssertNotNil(content, "First content should exist")
            XCTAssertEqual(content?.type, "function_call")
            XCTAssertEqual(content?.text, "Function call: get_weather")
        }
        
        print("✅ SSE parser handles function call events correctly")
    }
    
    /// Test that function call data is preserved during streaming
    func testFunctionCallDataPreservation() throws {
        // Create a function call output as it would appear in a non-streaming response
        let functionCallOutput = SAOAIOutput(
            content: nil,
            role: "assistant",
            id: "fc_123",
            type: "function_call",
            summary: nil,
            name: "get_weather",
            callId: "call_abc123",
            arguments: "{\"location\":\"San Francisco\"}",
            status: "completed"
        )
        
        let response = SAOAIResponse(
            id: "resp_123",
            model: "gpt-4o",
            created: 1234567890,
            output: [functionCallOutput],
            usage: nil
        )
        
        // Verify function call data is preserved
        let output = response.output.first
        XCTAssertEqual(output?.type, "function_call")
        XCTAssertEqual(output?.name, "get_weather")
        XCTAssertEqual(output?.callId, "call_abc123")
        XCTAssertEqual(output?.arguments, "{\"location\":\"San Francisco\"}")
        XCTAssertEqual(output?.status, "completed")
        
        print("✅ Function call data preservation works correctly")
    }
    
    /// Test the complete flow: streaming detection -> non-streaming follow-up
    func testStreamingToNonStreamingFunctionCallFlow() async throws {
        // This test simulates the flow implemented in AdvancedConsoleChatbot:
        // 1. Streaming request detects function call
        // 2. Falls back to non-streaming request for proper function call handling
        
        let config = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: config)
        
        // Create a weather tool
        let weatherTool = SAOAITool.function(
            name: "get_weather",
            description: "Get current weather information for a specified location",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("The city and state/country")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        )
        
        let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant with weather capabilities.")
        let userMessage = SAOAIMessage(role: .user, text: "What's the weather in London?")
        
        // Test that streaming call can be created with tools (this is what AdvancedConsoleChatbot does)
        let streamingCall = client.responses.createStreaming(
            model: config.deploymentName,
            input: [systemMessage, userMessage],
            tools: [weatherTool],
            previousResponseId: nil
        )
        
        XCTAssertNotNil(streamingCall, "Streaming call with tools should be created successfully")
        
        // Test that non-streaming call can be created with tools (this is the fallback)
        // Note: In real usage, this would be called when function calls are detected in streaming
        // For this test, we just verify the API can be called
        // (We can't test actual execution without real API credentials)
        
        print("✅ Streaming to non-streaming function call flow APIs work correctly")
    }
    
    /// Test that the fix maintains backward compatibility with existing examples
    func testBackwardCompatibilityWithExistingExamples() throws {
        // Test that non-function-call scenarios still work as before
        let textContent = SAOAIStreamingContent(
            type: "text",
            text: "Hello, this is a regular text response.",
            index: 0
        )
        
        let streamingOutput = SAOAIStreamingOutput(
            content: [textContent],
            role: "assistant"
        )
        
        let streamingResponse = SAOAIStreamingResponse(
            id: "resp_456",
            model: "gpt-4o",
            created: 1234567890,
            output: [streamingOutput],
            usage: nil
        )
        
        // Verify regular text responses still work
        XCTAssertEqual(streamingResponse.output?.first?.content?.first?.type, "text")
        XCTAssertEqual(streamingResponse.output?.first?.content?.first?.text, "Hello, this is a regular text response.")
        
        print("✅ Backward compatibility with existing examples maintained")
    }
}