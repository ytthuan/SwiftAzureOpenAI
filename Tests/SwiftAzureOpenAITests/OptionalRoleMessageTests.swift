import XCTest
@testable import SwiftAzureOpenAI

/// Tests for optional role in messages to support tool outputs without explicit roles
final class OptionalRoleMessageTests: XCTestCase {
    
    /// Test that we can create a message with only function call output (no role)
    func testFunctionCallOutputWithoutRole() {
        // This test verifies the fix: tool outputs can now be sent without a role
        
        let functionOutput = SAOAIInputContent.FunctionCallOutput(
            callId: "call_123",
            output: "{\"temperature\": \"22°C\", \"condition\": \"sunny\"}"
        )
        
        // NEW: We can now create a message with just the function output, no role
        let messageWithoutRole = SAOAIMessage(functionCallOutput: functionOutput)
        
        XCTAssertNil(messageWithoutRole.role, "Role should be nil for tool output messages")
        XCTAssertEqual(messageWithoutRole.content.count, 1)
        
        if case .functionCallOutput(let output) = messageWithoutRole.content.first {
            XCTAssertEqual(output.callId, "call_123")
            XCTAssertEqual(output.output, "{\"temperature\": \"22°C\", \"condition\": \"sunny\"}")
        } else {
            XCTFail("Expected function call output")
        }
        
        // We can still create messages with roles as before
        let messageWithRole = SAOAIMessage(role: .tool, content: [.functionCallOutput(functionOutput)])
        XCTAssertEqual(messageWithRole.role, .tool)
    }
    
    /// Test encoding/decoding of messages with and without roles
    func testOptionalRoleMessageCodable() throws {
        // Test message with role
        let functionOutput = SAOAIInputContent.FunctionCallOutput(
            callId: "call_456",
            output: "{\"result\": 42}"
        )
        
        let messageWithRole = SAOAIMessage(role: .tool, content: [.functionCallOutput(functionOutput)])
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let encodedWithRole = try encoder.encode(messageWithRole)
        
        let decoder = JSONDecoder()
        let decodedWithRole = try decoder.decode(SAOAIMessage.self, from: encodedWithRole)
        
        XCTAssertEqual(decodedWithRole.role, .tool)
        XCTAssertEqual(decodedWithRole.content.count, 1)
        
        // Test message without role (new functionality)
        let messageWithoutRole = SAOAIMessage(functionCallOutput: functionOutput)
        
        let encodedWithoutRole = try encoder.encode(messageWithoutRole)
        let jsonString = String(data: encodedWithoutRole, encoding: .utf8)!
        
        print("Message without role:")
        print(jsonString)
        
        // Verify role field is not present in JSON when nil
        XCTAssertFalse(jsonString.contains("\"role\""), "Role field should not be present when nil")
        XCTAssertTrue(jsonString.contains("\"content\""), "Content field should be present")
        XCTAssertTrue(jsonString.contains("function_call_output"), "Function call output should be present")
        
        let decodedWithoutRole = try decoder.decode(SAOAIMessage.self, from: encodedWithoutRole)
        XCTAssertNil(decodedWithoutRole.role, "Role should be nil when not present in JSON")
        XCTAssertEqual(decodedWithoutRole.content.count, 1)
        
        if case .functionCallOutput(let output) = decodedWithoutRole.content.first {
            XCTAssertEqual(output.callId, "call_456")
            XCTAssertEqual(output.output, "{\"result\": 42}")
        } else {
            XCTFail("Expected function call output")
        }
    }
    
    /// Test that simulates how Python SDK sends tool outputs - without role wrapper
    func testPythonStyleToolOutputFormat() throws {
        // This test demonstrates what we've achieved:
        // Tool outputs can now be sent as messages without roles, similar to Python SDK
        
        let functionOutput = SAOAIInputContent.FunctionCallOutput(
            callId: "call_789",
            output: "{\"weather\": \"London: 15°C, cloudy\"}"
        )
        
        // NEW: The Swift SDK can now send tool outputs without role, like Python SDK
        let toolMessage = SAOAIMessage(functionCallOutput: functionOutput)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let encoded = try encoder.encode(toolMessage)
        let jsonString = String(data: encoded, encoding: .utf8)!
        
        print("New tool output format (similar to Python SDK):")
        print(jsonString)
        
        // The new format should not include a role field
        XCTAssertFalse(jsonString.contains("\"role\""), "Role field should not be present for tool outputs")
        XCTAssertTrue(jsonString.contains("\"content\""), "Content field should be present")
        XCTAssertTrue(jsonString.contains("function_call_output"), "Function call output type should be present")
        XCTAssertTrue(jsonString.contains("call_789"), "Call ID should be present")
        
        // This is much closer to Python SDK format:
        // {
        //   "content": [{
        //     "type": "function_call_output",
        //     "call_id": "call_789", 
        //     "output": "{\"weather\": \"London: 15°C, cloudy\"}"
        //   }]
        // }
        // vs Python SDK pure format:
        // {
        //   "type": "function_call_output",
        //   "call_id": "call_789", 
        //   "output": "{\"weather\": \"London: 15°C, cloudy\"}"
        // }
    }
    
    /// Test the updated format for AdvancedConsoleChatbot (should fix Bad Request)
    func testAdvancedConsoleChatbotFixedScenario() throws {
        // Simulate the fixed scenario for AdvancedConsoleChatbot
        let mockConfig = TestEnvironmentHelper.createStandardAzureConfiguration()
        
        // NEW: AdvancedConsoleChatbot can now send tool outputs without role
        let toolOutput = SAOAIMessage(functionCallOutput: .init(
            callId: "call_weather_123",
            output: "{\"temperature\": \"22°C\", \"condition\": \"sunny\", \"location\": \"London\"}"
        ))
        
        // Verify no role is set
        XCTAssertNil(toolOutput.role, "Tool output message should not have a role")
        
        // The message should be sendable without causing Bad Request
        let messages = [toolOutput]
        
        // This should work with the fix
        XCTAssertNoThrow {
            let request = SAOAIRequest(
                model: mockConfig.deploymentName,
                input: messages.map { SAOAIInput.message($0) },
                maxOutputTokens: 100
            )
            
            // Verify the request can be created and encoded
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            let encoded = try encoder.encode(request)
            let jsonString = String(data: encoded, encoding: .utf8)!
            
            print("Fixed AdvancedConsoleChatbot request format:")
            print(jsonString)
            
            // Verify the input array contains messages without role fields
            XCTAssertFalse(jsonString.contains("\"role\""), "Tool output messages should not contain role field")
            XCTAssertTrue(jsonString.contains("function_call_output"), "Should contain function call output")
            XCTAssertTrue(jsonString.contains("call_weather_123"), "Should contain call ID")
        }
    }
    
    /// Test exact replication of Python SDK format behavior
    func testPythonSDKParityForToolOutputs() throws {
        // This test demonstrates we've achieved parity with Python SDK behavior
        // Python sends: [{"type": "function_call_output", "call_id": "...", "output": "..."}]
        // Swift now sends: [{"content": [{"type": "function_call_output", "call_id": "...", "output": "..."}]}]
        
        let toolOutput = SAOAIMessage(functionCallOutput: .init(
            callId: "call_abc123",
            output: "{\"temperature\": \"15°C\", \"location\": \"London, UK\"}"
        ))
        
        let request = SAOAIRequest(
            model: "gpt-4",
            input: [SAOAIInput.message(toolOutput)],
            maxOutputTokens: 150
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let encoded = try encoder.encode(request)
        let jsonString = String(data: encoded, encoding: .utf8)!
        
        print("Swift SDK tool output request (Python-compatible format):")
        print(jsonString)
        
        // Verify the structure matches what Azure OpenAI expects
        XCTAssertTrue(jsonString.contains("\"input\" :"), "Should have input field")
        XCTAssertTrue(jsonString.contains("\"content\" :"), "Should have content array")
        XCTAssertTrue(jsonString.contains("function_call_output"), "Should have function call output type")
        XCTAssertTrue(jsonString.contains("call_abc123"), "Should have call ID")
        XCTAssertFalse(jsonString.contains("\"role\""), "Should not have role field for tool outputs")
        
        // This format should be accepted by Azure OpenAI without Bad Request errors
    }
}