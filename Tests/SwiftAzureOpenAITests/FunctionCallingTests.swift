import XCTest
@testable import SwiftAzureOpenAI

/// Tests for function calling functionality
final class FunctionCallingTests: XCTestCase {
    
    // MARK: - Function Call Output Content Tests
    
    func testFunctionCallOutputContentInitialization() {
        let functionCall = SAOAIOutputContent.FunctionCall(
            callId: "call_123",
            name: "get_weather",
            arguments: "{\"location\": \"San Francisco\"}"
        )
        
        XCTAssertEqual(functionCall.type, "function_call")
        XCTAssertEqual(functionCall.callId, "call_123")
        XCTAssertEqual(functionCall.name, "get_weather")
        XCTAssertEqual(functionCall.arguments, "{\"location\": \"San Francisco\"}")
    }
    
    func testFunctionCallOutputContentCodable() throws {
        let functionCall = SAOAIOutputContent.FunctionCall(
            callId: "call_456",
            name: "calculate_sum",
            arguments: "{\"a\": 5, \"b\": 3}"
        )
        
        let outputContent = SAOAIOutputContent.functionCall(functionCall)
        
        // Encode
        let encoded = try JSONEncoder().encode(outputContent)
        
        // Decode
        let decoded = try JSONDecoder().decode(SAOAIOutputContent.self, from: encoded)
        
        if case let .functionCall(decodedFunctionCall) = decoded {
            XCTAssertEqual(decodedFunctionCall.type, "function_call")
            XCTAssertEqual(decodedFunctionCall.callId, "call_456")
            XCTAssertEqual(decodedFunctionCall.name, "calculate_sum")
            XCTAssertEqual(decodedFunctionCall.arguments, "{\"a\": 5, \"b\": 3}")
        } else {
            XCTFail("Expected functionCall content type")
        }
    }
    
    // MARK: - Function Call Output Input Content Tests
    
    func testFunctionCallOutputInputContentInitialization() {
        let functionOutput = SAOAIInputContent.FunctionCallOutput(
            callId: "call_789",
            output: "{\"temperature\": \"70 degrees\"}"
        )
        
        XCTAssertEqual(functionOutput.type, "function_call_output")
        XCTAssertEqual(functionOutput.callId, "call_789")
        XCTAssertEqual(functionOutput.output, "{\"temperature\": \"70 degrees\"}")
    }
    
    func testFunctionCallOutputInputContentCodable() throws {
        let functionOutput = SAOAIInputContent.FunctionCallOutput(
            callId: "call_101112",
            output: "{\"result\": 42}"
        )
        
        let inputContent = SAOAIInputContent.functionCallOutput(functionOutput)
        
        // Encode
        let encoded = try JSONEncoder().encode(inputContent)
        
        // Decode
        let decoded = try JSONDecoder().decode(SAOAIInputContent.self, from: encoded)
        
        if case let .functionCallOutput(decodedFunctionOutput) = decoded {
            XCTAssertEqual(decodedFunctionOutput.type, "function_call_output")
            XCTAssertEqual(decodedFunctionOutput.callId, "call_101112")
            XCTAssertEqual(decodedFunctionOutput.output, "{\"result\": 42}")
        } else {
            XCTFail("Expected functionCallOutput content type")
        }
    }
    
    // MARK: - Tool Definition Tests
    
    func testSAOAIToolFunctionConvenience() {
        let parameters: SAOAIJSONValue = .object([
            "type": .string("object"),
            "properties": .object([
                "location": .object([
                    "type": .string("string"),
                    "description": .string("The location to get weather for")
                ])
            ]),
            "required": .array([.string("location")])
        ])
        
        let tool = SAOAITool.function(
            name: "get_weather",
            description: "Get the weather for a location",
            parameters: parameters
        )
        
        XCTAssertEqual(tool.type, "function")
        XCTAssertEqual(tool.name, "get_weather")
        XCTAssertEqual(tool.description, "Get the weather for a location")
        XCTAssertEqual(tool.parameters, parameters)
    }
    
    func testSAOAIToolFunctionConvenienceCodable() throws {
        let parameters: SAOAIJSONValue = .object([
            "type": .string("object"),
            "properties": .object([
                "query": .object([
                    "type": .string("string")
                ])
            ])
        ])
        
        let tool = SAOAITool.function(
            name: "search",
            description: "Search for information",
            parameters: parameters
        )
        
        // Encode
        let encoded = try JSONEncoder().encode(tool)
        
        // Decode
        let decoded = try JSONDecoder().decode(SAOAITool.self, from: encoded)
        
        XCTAssertEqual(decoded.type, "function")
        XCTAssertEqual(decoded.name, "search")
        XCTAssertEqual(decoded.description, "Search for information")
        XCTAssertEqual(decoded.parameters, parameters)
    }
    
    // MARK: - Integration Tests
    
    func testResponsesClientWithToolsStringInput() throws {
        let config = TestableConfiguration()
        let client = SAOAIClient(configuration: config)
        
        // Test that the method exists and compiles correctly
        let createMethod = client.responses.create(model:input:tools:maxOutputTokens:temperature:topP:previousResponseId:reasoning:)
        XCTAssertNotNil(createMethod)
    }
    
    func testCompleteWorkflowStructure() throws {
        // This test validates the complete workflow structure without making HTTP calls
        
        // 1. Create tool definition (Python-style)
        let weatherTool = SAOAITool.function(
            name: "get_weather",
            description: "Get the weather for a location",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        )
        
        // 2. Simulate a function call response (what the AI would return)
        let functionCallOutput = SAOAIOutputContent.functionCall(
            .init(
                callId: "call_abc123",
                name: "get_weather",
                arguments: "{\"location\": \"San Francisco\"}"
            )
        )
        
        // 3. Create function call result input (to send back to the AI)
        let functionResultInput = SAOAIInputContent.functionCallOutput(
            .init(
                callId: "call_abc123",
                output: "{\"temperature\": \"70 degrees\", \"condition\": \"sunny\"}"
            )
        )
        
        // 4. Create a follow-up message with the function result
        let followUpMessage = SAOAIMessage(
            role: .user,
            content: [functionResultInput]
        )
        
        // Verify all structures are properly initialized
        XCTAssertEqual(weatherTool.type, "function")
        XCTAssertEqual(weatherTool.name, "get_weather")
        
        if case let .functionCall(callContent) = functionCallOutput {
            XCTAssertEqual(callContent.callId, "call_abc123")
            XCTAssertEqual(callContent.name, "get_weather")
        } else {
            XCTFail("Expected function call output")
        }
        
        if case let .functionCallOutput(resultContent) = functionResultInput {
            XCTAssertEqual(resultContent.callId, "call_abc123")
            XCTAssertEqual(resultContent.output, "{\"temperature\": \"70 degrees\", \"condition\": \"sunny\"}")
        } else {
            XCTFail("Expected function call output input")
        }
        
        XCTAssertEqual(followUpMessage.role, .user)
        XCTAssertEqual(followUpMessage.content.count, 1)
    }
}

// MARK: - Test Configuration Helper

private struct TestableConfiguration: SAOAIConfiguration {
    var baseURL: URL { URL(string: "https://test.example.com")! }
    var headers: [String: String] { ["Authorization": "Bearer test"] }
    var sseLoggerConfiguration: SSELoggerConfiguration { .disabled }
}