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
}