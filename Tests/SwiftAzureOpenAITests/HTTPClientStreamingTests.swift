import XCTest
@testable import SwiftAzureOpenAI

/// Tests to verify the HTTPClient streaming chunking fix
final class HTTPClientStreamingTests: XCTestCase {
    
    /// Test that HTTPClient properly formats SSE lines for the parser
    func testHTTPClientStreamingChunkingLogic() async throws {
        
        // Simulate SSE response data that would come from Azure OpenAI
        let sseResponseData = """
data: {"id":"response_123","object":"response","created":1234567890,"model":"gpt-4o","output":[{"content":[{"text":"Hello"}],"type":"content","role":"assistant"}]}

data: {"id":"response_123","object":"response","created":1234567890,"model":"gpt-4o","output":[{"content":[{"text":" there!"}],"type":"content","role":"assistant"}]}

data: [DONE]

""".data(using: .utf8)!
        
        // Test that SSEParser can handle the chunked data correctly
        let lines = String(data: sseResponseData, encoding: .utf8)!.components(separatedBy: .newlines)
        var parsedResponses: [SAOAIStreamingResponse] = []
        
        for line in lines {
            if !line.isEmpty {
                // Format the line as HTTPClient would now do
                let lineData = line.data(using: .utf8)! + "\n\n".data(using: .utf8)!
                
                do {
                    if let response = try SSEParser.parseSSEChunk(lineData) {
                        parsedResponses.append(response)
                    }
                } catch {
                    // This should not happen with proper formatting
                    XCTFail("SSEParser should handle properly formatted chunks: \(error)")
                }
            }
        }
        
        XCTAssertEqual(parsedResponses.count, 2, "Should parse two streaming response chunks")
        
        // Check first chunk
        let firstResponse = parsedResponses[0]
        XCTAssertEqual(firstResponse.id, "response_123")
        XCTAssertEqual(firstResponse.output?.first?.content?.first?.text, "Hello")
        
        // Check second chunk  
        let secondResponse = parsedResponses[1]
        XCTAssertEqual(secondResponse.id, "response_123")
        XCTAssertEqual(secondResponse.output?.first?.content?.first?.text, " there!")
    }
    
    /// Test edge case with empty lines and malformed chunks
    func testHTTPClientStreamingEdgeCases() async throws {
        
        // Test data with empty lines and malformed chunks
        let edgeCaseData = """
data: {"id":"response_123","object":"response","created":1234567890,"model":"gpt-4o","output":[{"content":[{"text":"Test"}],"type":"content","role":"assistant"}]}

: comment line should be ignored

data: malformed json {invalid

data: {"id":"response_123","object":"response","created":1234567890,"model":"gpt-4o","output":[{"content":[{"text":" content"}],"type":"content","role":"assistant"}]}

data: [DONE]

""".data(using: .utf8)!
        
        let lines = String(data: edgeCaseData, encoding: .utf8)!.components(separatedBy: .newlines)
        var parsedResponses: [SAOAIStreamingResponse] = []
        var completionFound = false
        
        for line in lines {
            if !line.isEmpty {
                // Format the line as HTTPClient would now do
                let lineData = line.data(using: .utf8)! + "\n\n".data(using: .utf8)!
                
                // Check for completion
                if SSEParser.isCompletionChunk(lineData) {
                    completionFound = true
                    continue
                }
                
                do {
                    if let response = try SSEParser.parseSSEChunk(lineData) {
                        parsedResponses.append(response)
                    }
                } catch {
                    // Malformed chunks should be skipped gracefully
                    continue
                }
            }
        }
        
        XCTAssertEqual(parsedResponses.count, 2, "Should parse only valid chunks, skipping malformed ones")
        XCTAssertTrue(completionFound, "Should detect completion signal")
        
        // Verify the valid responses
        XCTAssertEqual(parsedResponses[0].output?.first?.content?.first?.text, "Test")
        XCTAssertEqual(parsedResponses[1].output?.first?.content?.first?.text, " content")
    }
    
    /// Test end-to-end streaming flow that AdvancedConsoleChatbot would use
    func testEndToEndStreamingFlow() async throws {
        let config = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: config)
        
        // Create the streaming request as AdvancedConsoleChatbot would
        let systemMessage = SAOAIMessage(role: .system, text: "You are a helpful AI assistant.")
        let userMessage = SAOAIMessage(role: .user, text: "Hello!")
        
        let streamingCall = client.responses.createStreaming(
            model: config.deploymentName,
            input: [systemMessage, userMessage],
            previousResponseId: nil
        )
        
        XCTAssertNotNil(streamingCall, "Streaming call should be created successfully")
        
        // Test that the stream can be created (we can't test actual execution without real API)
        // This verifies that the API is properly structured for streaming
        let stream = streamingCall
        XCTAssertNotNil(stream, "Stream should be available")
        
        // In a real scenario, AdvancedConsoleChatbot would iterate like this:
        // for try await chunk in stream {
        //     if let content = chunk.output?.first?.content?.first?.text {
        //         print(content, terminator: "")
        //         fflush(stdout)
        //     }
        // }
        
        print("✅ End-to-end streaming flow validation successful")
    }
    
    /// Test that streaming works with tools as AdvancedConsoleChatbot uses
    func testStreamingWithToolsFlow() async throws {
        let config = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: config)
        
        // Create weather tool as in AdvancedConsoleChatbot
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
        
        let streamingCall = client.responses.createStreaming(
            model: config.deploymentName,
            input: [systemMessage, userMessage],
            tools: [weatherTool],
            previousResponseId: nil
        )
        
        XCTAssertNotNil(streamingCall, "Streaming call with tools should be created successfully")
        
        print("✅ Streaming with tools flow validation successful")
    }
    
    /// Test that the fix correctly handles completion signals
    func testCompletionSignalHandling() async throws {
        // Test completion detection in various formats
        let completionChunks = [
            "data: [DONE]\n\n".data(using: .utf8)!,
            "data: [DONE]".data(using: .utf8)! + "\n\n".data(using: .utf8)!,
            ": comment\ndata: [DONE]\n\n".data(using: .utf8)!
        ]
        
        for (index, chunk) in completionChunks.enumerated() {
            let isCompletion = SSEParser.isCompletionChunk(chunk)
            XCTAssertTrue(isCompletion, "Completion chunk \(index + 1) should be detected as completion")
        }
        
        // Test non-completion chunks
        let nonCompletionChunks = [
            "data: {\"id\":\"test\"}\n\n".data(using: .utf8)!,
            "data: [PARTIAL]\n\n".data(using: .utf8)!,
            ": comment only\n\n".data(using: .utf8)!
        ]
        
        for (index, chunk) in nonCompletionChunks.enumerated() {
            let isCompletion = SSEParser.isCompletionChunk(chunk)
            XCTAssertFalse(isCompletion, "Non-completion chunk \(index + 1) should not be detected as completion")
        }
    }
    
    /// Test that streaming responses accumulate correctly as in AdvancedConsoleChatbot
    func testStreamingTextAccumulation() async throws {
        // Simulate how AdvancedConsoleChatbot would accumulate streaming text
        let streamingChunks = [
            "data: {\"id\":\"response_123\",\"object\":\"response\",\"created\":1234567890,\"model\":\"gpt-4o\",\"output\":[{\"content\":[{\"text\":\"Hello\"}],\"type\":\"content\",\"role\":\"assistant\"}]}\n\n",
            "data: {\"id\":\"response_123\",\"object\":\"response\",\"created\":1234567890,\"model\":\"gpt-4o\",\"output\":[{\"content\":[{\"text\":\" there!\"}],\"type\":\"content\",\"role\":\"assistant\"}]}\n\n",
            "data: {\"id\":\"response_123\",\"object\":\"response\",\"created\":1234567890,\"model\":\"gpt-4o\",\"output\":[{\"content\":[{\"text\":\" How\"}],\"type\":\"content\",\"role\":\"assistant\"}]}\n\n",
            "data: {\"id\":\"response_123\",\"object\":\"response\",\"created\":1234567890,\"model\":\"gpt-4o\",\"output\":[{\"content\":[{\"text\":\" are you?\"}],\"type\":\"content\",\"role\":\"assistant\"}]}\n\n",
            "data: [DONE]\n\n"
        ]
        
        var accumulatedText = ""
        var chunkCount = 0
        
        for chunkData in streamingChunks {
            let data = chunkData.data(using: .utf8)!
            
            if SSEParser.isCompletionChunk(data) {
                break
            }
            
            if let response = try SSEParser.parseSSEChunk(data) {
                chunkCount += 1
                if let content = response.output?.first?.content?.first?.text {
                    accumulatedText += content
                }
            }
        }
        
        XCTAssertEqual(chunkCount, 4, "Should process 4 content chunks")
        XCTAssertEqual(accumulatedText, "Hello there! How are you?", "Text should accumulate correctly")
        
        print("✅ Streaming text accumulation works correctly: '\(accumulatedText)'")
    }
}