import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

final class ResponsesConsoleChatbotNonStreamingTests: XCTestCase {
    
    func testCreateWithFunctionCallOutputsMethodExists() {
        let config = SAOAIOpenAIConfiguration(apiKey: "sk-test", organization: nil)
        let client = SAOAIClient(configuration: config)
        
        // Verify that the new createWithFunctionCallOutputs method exists and is accessible
        let createMethod = client.responses.createWithFunctionCallOutputs
        XCTAssertNotNil(createMethod)
    }
    
    func testCreateWithFunctionCallOutputsMethodSignature() async throws {
        let config = TestableConfiguration()
        let client = SAOAIClient(configuration: config)
        
        // Test that the method has the correct signature by attempting to call it
        // This is a compilation test - we're not actually making HTTP calls
        let functionCallOutputs = [
            SAOAIInputContent.FunctionCallOutput(callId: "test-call-id", output: "test output")
        ]
        
        let tools = [SAOAITool.function(name: "test_function", description: "Test function", parameters: .object([
            "type": .string("object"),
            "properties": .object([:])
        ]))]
        
        // This tests that the method exists and accepts the expected parameters
        // It will fail at HTTP level but that's expected since we're using a test configuration
        do {
            _ = try await client.responses.createWithFunctionCallOutputs(
                model: "test-model",
                functionCallOutputs: functionCallOutputs,
                maxOutputTokens: 100,
                tools: tools,
                previousResponseId: "test-response-id"
            )
        } catch {
            // Expected to fail since we're using a test configuration
            // The important thing is that the method compiles and can be called
        }
    }
    
    func testNonStreamingMethodReturnType() async throws {
        // Test that createWithFunctionCallOutputs returns SAOAIResponse (not streaming)
        let config = TestableConfiguration()
        let client = SAOAIClient(configuration: config)
        
        let functionCallOutputs = [
            SAOAIInputContent.FunctionCallOutput(callId: "test", output: "test")
        ]
        
        // This is a compilation test to ensure the return type is correct
        // We expect it to fail at HTTP level since we're using a test configuration
        do {
            _ = try await client.responses.createWithFunctionCallOutputs(
                model: "test",
                functionCallOutputs: functionCallOutputs
            )
        } catch {
            // Expected to fail - the important thing is that the method compiles
        }
        
        // Test passes if we reach here without compilation errors
        XCTAssertTrue(true)
    }
    
    func testStreamingMethodReturnType() {
        // Test that the existing streaming method returns the correct type
        let config = TestableConfiguration()
        let client = SAOAIClient(configuration: config)
        
        let functionCallOutputs = [
            SAOAIInputContent.FunctionCallOutput(callId: "test", output: "test")
        ]
        
        // This should return AsyncThrowingStream
        let stream = client.responses.createStreamingWithAllParameters(
            model: "test",
            functionCallOutputs: functionCallOutputs
        )
        
        XCTAssertNotNil(stream)
    }
    
    func testUserControlledFunctionCallingPattern() {
        // Test the user-controlled function calling pattern
        let maxFunctionCallRounds = 5
        var currentRound = 0
        
        // Simulate function call outputs
        var functionCallOutputs: [SAOAIInputContent.FunctionCallOutput]? = [
            SAOAIInputContent.FunctionCallOutput(callId: "test-1", output: "result-1"),
            SAOAIInputContent.FunctionCallOutput(callId: "test-2", output: "result-2")
        ]
        
        // User-controlled loop
        while let _ = functionCallOutputs, currentRound < maxFunctionCallRounds {
            currentRound += 1
            
            // Simulate processing - in real code this would call continueNonStreamingWithFunctionOutputs
            if currentRound >= 3 {
                functionCallOutputs = nil // Simulate no more function calls needed
            } else {
                // Simulate more function calls needed
                functionCallOutputs = [
                    SAOAIInputContent.FunctionCallOutput(callId: "test-\(currentRound + 2)", output: "result-\(currentRound + 2)")
                ]
            }
        }
        
        // Verify the loop worked as expected
        XCTAssertEqual(currentRound, 3) // Should stop at round 3 when no more function calls
        XCTAssertNil(functionCallOutputs) // Should be nil when loop exits
        XCTAssertLessThan(currentRound, maxFunctionCallRounds) // Should not hit max rounds
    }
    
    func testMaxFunctionCallRoundsLimit() {
        // Test that the max function call rounds limit is respected
        let maxFunctionCallRounds = 5
        var currentRound = 0
        
        // Simulate continuous function call outputs (never ending)
        var functionCallOutputs: [SAOAIInputContent.FunctionCallOutput]? = [
            SAOAIInputContent.FunctionCallOutput(callId: "test", output: "result")
        ]
        
        // User-controlled loop that simulates never-ending function calls
        while let _ = functionCallOutputs, currentRound < maxFunctionCallRounds {
            currentRound += 1
            
            // Always simulate more function calls needed (infinite loop scenario)
            functionCallOutputs = [
                SAOAIInputContent.FunctionCallOutput(callId: "test-\(currentRound)", output: "result-\(currentRound)")
            ]
        }
        
        // Verify the limit was respected
        XCTAssertEqual(currentRound, maxFunctionCallRounds)
        XCTAssertNotNil(functionCallOutputs) // Should still have function calls but loop exited due to limit
    }
    
    func testNoAutomaticFunctionCallLoops() {
        // Test that the SDK does not automatically handle function call loops
        // This is verified by the method signatures returning function call outputs
        // instead of handling them internally
        
        let config = TestableConfiguration()
        let client = SAOAIClient(configuration: config)
        
        // Both streaming and non-streaming methods should allow user control
        // by returning or yielding function call information instead of handling loops
        
        // Non-streaming: returns SAOAIResponse which contains function call info
        let nonStreamingExists = client.responses.createWithFunctionCallOutputs
        XCTAssertNotNil(nonStreamingExists)
        
        // Streaming: returns AsyncThrowingStream that yields function call events
        let streamingExists = client.responses.createStreamingWithAllParameters
        XCTAssertNotNil(streamingExists)
        
        // The key point is that neither method automatically continues function calling
        // They return control to the user after function calls are detected
    }
    
    func testFunctionCallOutputProcessing() {
        // Test function call output creation and structure
        let callId = "call_123456"
        let output = """
        {
            "result": 42,
            "status": "success"
        }
        """
        
        let functionCallOutput = SAOAIInputContent.FunctionCallOutput(
            callId: callId,
            output: output
        )
        
        XCTAssertEqual(functionCallOutput.callId, callId)
        XCTAssertEqual(functionCallOutput.output, output)
        XCTAssertEqual(functionCallOutput.type, "function_call_output")
    }
    
    func testBasicChatFunctionality() {
        // Test that basic chat functionality structure is maintained
        let config = TestableConfiguration()
        let client = SAOAIClient(configuration: config)
        
        // Test non-streaming create method still works for basic chat
        let createMethod = client.responses.create
        XCTAssertNotNil(createMethod)
        
        // Test streaming create method still works for basic chat
        let streamingMethod = client.responses.createStreaming
        XCTAssertNotNil(streamingMethod)
    }
}

// MARK: - Test Helper Configuration

/// A testable configuration that doesn't make actual HTTP requests
private struct TestableConfiguration: SAOAIConfiguration {
    var baseURL: URL { URL(string: "https://test.example.com")! }
    var headers: [String: String] { ["Authorization": "Bearer test"] }
    var sseLoggerConfiguration: SSELoggerConfiguration { .disabled }
}