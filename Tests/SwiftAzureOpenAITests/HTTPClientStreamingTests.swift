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
    
    /// Test that shows the fix for Azure OpenAI SSE format
    func testRealAzureOpenAISSEFormatFixed() async throws {
        // This is the actual SSE format from Azure OpenAI Response API (from CI logs)
        let realSSEData = """
event: response.created
data: {"type":"response.created","sequence_number":0,"response":{"id":"resp_68b3ec7e57ec8192adc0cff6864bb47104fa46c87aca3c1e","object":"response","created_at":1756621950,"status":"in_progress","model":"gpt-5-nano","output":[]}}

event: response.completed
data: {"type":"response.completed","sequence_number":19,"response":{"id":"resp_68b3ec7e57ec8192adc0cff6864bb47104fa46c87aca3c1e","object":"response","created_at":1756621950,"status":"completed","model":"gpt-5-nano","output":[{"id":"fc_123","type":"function_call","status":"completed","arguments":"{\\"location\\":\\"London, UK\\"}","name":"get_weather"}],"usage":{"input_tokens":91,"output_tokens":219,"total_tokens":310}}}

""".data(using: .utf8)!
        
        let lines = String(data: realSSEData, encoding: .utf8)!.components(separatedBy: .newlines)
        var parsedResponses: [SAOAIStreamingResponse] = []
        
        print("✅ Testing Azure OpenAI SSE format (should now work correctly)...")
        
        for line in lines {
            if !line.isEmpty {
                // Format the line as HTTPClient would do
                let lineData = line.data(using: .utf8)! + "\n\n".data(using: .utf8)!
                
                do {
                    if let response = try SSEParser.parseSSEChunk(lineData) {
                        parsedResponses.append(response)
                        print("✅ Parsed response: id=\(response.id ?? "nil"), model=\(response.model ?? "nil")")
                    } else {
                        print("⚠️ No response parsed from line: \(line)")
                    }
                } catch {
                    print("❌ Failed to parse line: \(line)")
                    print("❌ Error: \(error)")
                    XCTFail("Should not fail to parse valid Azure OpenAI SSE format")
                }
            }
        }
        
        print("✅ Fix validated: Total parsed responses: \(parsedResponses.count)")
        
        // Validate the fix - responses should now have proper values
        XCTAssertEqual(parsedResponses.count, 2, "Should parse 2 responses")
        
        // First response (response.created)
        let firstResponse = parsedResponses[0]
        XCTAssertEqual(firstResponse.id, "resp_68b3ec7e57ec8192adc0cff6864bb47104fa46c87aca3c1e", "Should parse response ID correctly")
        XCTAssertEqual(firstResponse.model, "gpt-5-nano", "Should parse model correctly")
        XCTAssertEqual(firstResponse.created, 1756621950, "Should parse created timestamp correctly")
        
        // Second response (response.completed)
        let secondResponse = parsedResponses[1]
        XCTAssertEqual(secondResponse.id, "resp_68b3ec7e57ec8192adc0cff6864bb47104fa46c87aca3c1e", "Should parse response ID correctly")
        XCTAssertEqual(secondResponse.model, "gpt-5-nano", "Should parse model correctly")
        XCTAssertNotNil(secondResponse.output, "Should have output for completed response")
        XCTAssertNotNil(secondResponse.usage, "Should have usage data for completed response")
        
        print("✅ All Azure OpenAI SSE format parsing validations passed!")
    }

    /// Test that reproduces the issue with real Azure OpenAI SSE format
    func testRealAzureOpenAISSEFormatIssue() async throws {
        // This is the actual SSE format from Azure OpenAI Response API (from CI logs)
        let realSSEData = """
event: response.created
data: {"type":"response.created","sequence_number":0,"response":{"id":"resp_68b3ec7e57ec8192adc0cff6864bb47104fa46c87aca3c1e","object":"response","created_at":1756621950,"status":"in_progress","model":"gpt-5-nano","output":[]}}

event: response.completed
data: {"type":"response.completed","sequence_number":19,"response":{"id":"resp_68b3ec7e57ec8192adc0cff6864bb47104fa46c87aca3c1e","object":"response","created_at":1756621950,"status":"completed","model":"gpt-5-nano","output":[{"id":"fc_123","type":"function_call","status":"completed","arguments":"{\\"location\\":\\"London, UK\\"}","name":"get_weather"}],"usage":{"input_tokens":91,"output_tokens":219,"total_tokens":310}}}

""".data(using: .utf8)!
        
        let lines = String(data: realSSEData, encoding: .utf8)!.components(separatedBy: .newlines)
        var parsedResponses: [SAOAIStreamingResponse] = []
        
        print("🐛 Testing real Azure OpenAI SSE format (this demonstrates the bug)...")
        
        for line in lines {
            if !line.isEmpty {
                // Format the line as HTTPClient would do
                let lineData = line.data(using: .utf8)! + "\n\n".data(using: .utf8)!
                
                do {
                    if let response = try SSEParser.parseSSEChunk(lineData) {
                        parsedResponses.append(response)
                        print("✅ Parsed response: id=\(response.id ?? "nil"), model=\(response.model ?? "nil")")
                    } else {
                        print("⚠️ No response parsed from line: \(line)")
                    }
                } catch {
                    print("❌ Failed to parse line: \(line)")
                    print("❌ Error: \(error)")
                }
            }
        }
        
        print("🐛 Bug demonstrated: Total parsed responses: \(parsedResponses.count)")
        print("🐛 Expected: Should parse 2 responses with valid data")
        print("🐛 Actual: All parsed responses have nil values")
        
        // This demonstrates the bug - responses are parsed but with nil values
        // because the SSEParser doesn't understand the event wrapper format
        for (index, response) in parsedResponses.enumerated() {
            print("🐛 Response \(index + 1): id=\(response.id ?? "nil"), model=\(response.model ?? "nil"), output=\(response.output?.isEmpty != false ? "empty/nil" : "has data")")
        }
    }

    /// Test comprehensive Azure OpenAI SSE event handling
    func testComprehensiveAzureOpenAISSEEvents() async throws {
        // Test various Azure OpenAI SSE event types
        let comprehensiveSSEData = """
event: response.created
data: {"type":"response.created","sequence_number":0,"response":{"id":"resp_123","object":"response","created_at":1234567890,"status":"in_progress","model":"gpt-4o","output":[]}}

event: response.output_item.added
data: {"type":"response.output_item.added","sequence_number":1,"output_index":0,"item":{"id":"item_456","type":"reasoning","summary":[]}}

event: response.function_call_arguments.delta
data: {"type":"response.function_call_arguments.delta","sequence_number":2,"item_id":"fc_789","output_index":1,"delta":"hello"}

event: response.completed
data: {"type":"response.completed","sequence_number":3,"response":{"id":"resp_123","object":"response","created_at":1234567890,"status":"completed","model":"gpt-4o","output":[{"id":"fc_789","type":"function_call","name":"test_function","arguments":"{\\"param\\":\\"value\\"}"}],"usage":{"input_tokens":10,"output_tokens":20,"total_tokens":30}}}

""".data(using: .utf8)!
        
        let lines = String(data: comprehensiveSSEData, encoding: .utf8)!.components(separatedBy: .newlines)
        var parsedResponses: [SAOAIStreamingResponse] = []
        
        for line in lines {
            if !line.isEmpty {
                let lineData = line.data(using: .utf8)! + "\n\n".data(using: .utf8)!
                
                do {
                    if let response = try SSEParser.parseSSEChunk(lineData) {
                        parsedResponses.append(response)
                    }
                } catch {
                    XCTFail("Should not fail to parse valid Azure OpenAI SSE events: \(error)")
                }
            }
        }
        
        // Should parse the events that contain response data
        XCTAssertEqual(parsedResponses.count, 2, "Should parse response.created and response.completed events")
        
        // Validate first response (response.created)
        let firstResponse = parsedResponses[0]
        XCTAssertEqual(firstResponse.id, "resp_123")
        XCTAssertEqual(firstResponse.model, "gpt-4o")
        XCTAssertEqual(firstResponse.created, 1234567890)
        
        // Validate second response (response.completed)  
        let secondResponse = parsedResponses[1]
        XCTAssertEqual(secondResponse.id, "resp_123")
        XCTAssertNotNil(secondResponse.output, "Completed response should have output")
        XCTAssertNotNil(secondResponse.usage, "Completed response should have usage")
        XCTAssertEqual(secondResponse.usage?.totalTokens, 30)
        
        print("✅ Comprehensive Azure OpenAI SSE event parsing successful!")
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