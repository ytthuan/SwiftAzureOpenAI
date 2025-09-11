import XCTest
@testable import SwiftAzureOpenAI

/// Test to verify the function call output fix
final class FunctionCallOutputFixTests: XCTestCase {
    
    func testFunctionCallOutputMessageStructure() throws {
        // Create a mock function call output
        let functionOutput = SAOAIInputContent.FunctionCallOutput(
            callId: "call_test123",
            output: "{\"result\":42}"
        )
        
        // Test the fixed approach: using SAOAIMessage
        let functionCallMessage = SAOAIMessage(functionCallOutput: functionOutput)
        XCTAssertNil(functionCallMessage.role, "Function call output message should have nil role")
        XCTAssertEqual(functionCallMessage.content.count, 1, "Should have exactly one content item")
        
        if case let .functionCallOutput(output) = functionCallMessage.content.first! {
            XCTAssertEqual(output.callId, "call_test123")
            XCTAssertEqual(output.output, "{\"result\":42}")
            XCTAssertEqual(output.type, "function_call_output")
        } else {
            XCTFail("Expected function call output content")
        }
        
        // Test JSON encoding to ensure it matches expected format
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(functionCallMessage)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        print("Function call output message JSON:")
        print(jsonString)
        
        // Verify the JSON structure matches Azure OpenAI expectations
        XCTAssertTrue(jsonString.contains("\"type\" : \"function_call_output\""))
        XCTAssertTrue(jsonString.contains("\"call_id\" : \"call_test123\""))
        XCTAssertTrue(jsonString.contains("\"output\" : \"{\\\"result\\\":42}\""))
        // Role should be omitted (not included in JSON) for function call outputs
        XCTAssertFalse(jsonString.contains("\"role\""), "Role should be omitted for function call outputs")
    }
    
    func testBothApproachesProduceSameRequestStructure() throws {
        // This test ensures that both the old functionCallOutputs approach
        // and the new message-based approach produce the same request structure
        let functionOutput = SAOAIInputContent.FunctionCallOutput(
            callId: "call_abc123",
            output: "{\"temperature\":\"70 degrees\"}"
        )
        
        // New approach: Use messages
        let functionCallMessages = [SAOAIMessage(functionCallOutput: functionOutput)]
        let newRequest = SAOAIRequest(
            model: "gpt-4o",
            input: functionCallMessages.map { SAOAIInput.message($0) },
            previousResponseId: "resp_test123"
        )
        
        // Old approach would create: [SAOAIInput.functionCallOutput(functionOutput)]
        let oldRequest = SAOAIRequest(
            model: "gpt-4o", 
            input: [SAOAIInput.functionCallOutput(functionOutput)],
            previousResponseId: "resp_test123"
        )
        
        // Encode both and compare structure
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let newData = try encoder.encode(newRequest)
        let newString = String(data: newData, encoding: .utf8)!
        
        let oldData = try encoder.encode(oldRequest)
        let oldString = String(data: oldData, encoding: .utf8)!
        
        print("New approach (messages):")
        print(newString)
        print("\nOld approach (direct):")
        print(oldString)
        
        // Both should contain the essential function call output information
        XCTAssertTrue(newString.contains("function_call_output"))
        XCTAssertTrue(oldString.contains("function_call_output"))
        XCTAssertTrue(newString.contains("call_abc123"))
        XCTAssertTrue(oldString.contains("call_abc123"))
        XCTAssertTrue(newString.contains("temperature"))
        XCTAssertTrue(oldString.contains("temperature"))
        
        // Both should have the same model and previousResponseId
        XCTAssertTrue(newString.contains("\"model\":\"gpt-4o\""))
        XCTAssertTrue(oldString.contains("\"model\":\"gpt-4o\""))
        XCTAssertTrue(newString.contains("resp_test123"))
        XCTAssertTrue(oldString.contains("resp_test123"))
    }
}

// MARK: - Test Configuration Helper

private struct TestableConfiguration: SAOAIConfiguration {
    var baseURL: URL { URL(string: "https://test.example.com")! }
    var headers: [String: String] { ["Authorization": "Bearer test"] }
    var sseLoggerConfiguration: SSELoggerConfiguration { .disabled }
}