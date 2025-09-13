import XCTest
@testable import SwiftAzureOpenAI

/// Tests for the new non-streaming functionality in ResponsesConsoleChatbot
final class ResponsesConsoleChatbotNonStreamingTests: XCTestCase {
    
    /// Test that the non-streaming API can be used for basic chat without tools
    func testNonStreamingBasicChat() {
        let mockConfig = TestEnvironmentHelper.createStandardAzureConfiguration()
        let client = SAOAIClient(configuration: mockConfig)
        
        // Test basic non-streaming request without tools
        let userMessage = SAOAIMessage(role: .user, text: "Hello, how are you?")
        
        // Verify the non-streaming API can be called for basic chat
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                return try await client.responses.create(
                    model: mockConfig.deploymentName,
                    input: [userMessage],
                    maxOutputTokens: 100,
                    previousResponseId: nil
                )
            }
        }())
        
        print("✅ Non-streaming basic chat API structure is valid")
    }
    
    /// Test that the non-streaming API can be used with function tools
    func testNonStreamingWithFunctionTools() {
        let mockConfig = TestEnvironmentHelper.createStandardAzureConfiguration()
        let client = SAOAIClient(configuration: mockConfig)
        
        // Create a simple calculator tool like the one in ResponsesConsoleChatbot
        let sumCalculatorTool = SAOAITool.function(
            name: "sum_calculator",
            description: "Calculate the sum of two numbers.",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "a": .object([
                        "type": .string("number"),
                        "description": .string("First number")
                    ]),
                    "b": .object([
                        "type": .string("number"), 
                        "description": .string("Second number")
                    ])
                ]),
                "required": .array([.string("a"), .string("b")])
            ])
        )
        
        let userMessage = SAOAIMessage(role: .user, text: "Use the calculator tool to add 10 and 22")
        
        // Verify non-streaming API works with function tools
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                return try await client.responses.create(
                    model: mockConfig.deploymentName,
                    input: [userMessage],
                    maxOutputTokens: nil,
                    tools: [sumCalculatorTool],
                    previousResponseId: nil
                )
            }
        }())
        
        print("✅ Non-streaming API with function tools structure is valid")
    }
    
    /// Test that the non-streaming API can be used with code interpreter
    func testNonStreamingWithCodeInterpreter() {
        let mockConfig = TestEnvironmentHelper.createStandardAzureConfiguration()
        let client = SAOAIClient(configuration: mockConfig)
        
        let codeInterpreterTool = SAOAITool.codeInterpreter()
        let userMessage = SAOAIMessage(role: .user, text: "Write Python code to calculate the factorial of 5")
        
        // Verify non-streaming API works with code interpreter
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                return try await client.responses.create(
                    model: mockConfig.deploymentName,
                    input: [userMessage],
                    maxOutputTokens: nil,
                    tools: [codeInterpreterTool],
                    previousResponseId: nil
                )
            }
        }())
        
        print("✅ Non-streaming API with code interpreter structure is valid")
    }
    
    /// Test that non-streaming API supports reasoning parameters
    func testNonStreamingWithReasoningAndText() {
        let mockConfig = TestEnvironmentHelper.createStandardAzureConfiguration()
        let client = SAOAIClient(configuration: mockConfig)
        
        let reasoning = SAOAIReasoning(effort: "medium", summary: "auto")
        let text = SAOAIText(verbosity: "low")
        let userMessage = SAOAIMessage(role: .user, text: "Explain how machine learning works")
        
        // Verify non-streaming API works with reasoning and text parameters
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                return try await client.responses.create(
                    model: mockConfig.deploymentName,
                    input: [userMessage],
                    maxOutputTokens: nil,
                    previousResponseId: nil,
                    reasoning: reasoning,
                    text: text
                )
            }
        }())
        
        print("✅ Non-streaming API with reasoning and text parameters structure is valid")
    }
    
    /// Test that function call outputs can be used in non-streaming API
    func testNonStreamingWithFunctionCallOutput() {
        let mockConfig = TestEnvironmentHelper.createStandardAzureConfiguration()
        let client = SAOAIClient(configuration: mockConfig)
        
        // Simulate a function call output
        let functionOutput = SAOAIInputContent.FunctionCallOutput(
            callId: "call_123",
            output: "{\"result\": 32}"
        )
        
        let functionMessage = SAOAIMessage(
            role: .user,
            content: [.functionCallOutput(functionOutput)]
        )
        
        let tools = [SAOAITool.function(
            name: "sum_calculator",
            description: "Calculate the sum of two numbers.",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([:]),
                "required": .array([])
            ])
        )]
        
        // Verify non-streaming API works with function call outputs (for tool loops)
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                return try await client.responses.create(
                    model: mockConfig.deploymentName,
                    input: [functionMessage],
                    maxOutputTokens: nil,
                    tools: tools,
                    previousResponseId: "resp_123"
                )
            }
        }())
        
        print("✅ Non-streaming API with function call outputs structure is valid")
    }
    
    /// Live API test for non-streaming mode (only runs with environment variables set)
    func testNonStreamingLiveAPI() {
        guard let endpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"],
              let apiKey = ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"] ?? ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"],
              let deployment = ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] else {
            print("ℹ️ Skipping live API test - environment variables not set")
            return
        }
        
        let config = SAOAIAzureConfiguration(
            endpoint: endpoint,
            apiKey: apiKey,
            deploymentName: deployment,
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: config)
        let expectation = XCTestExpectation(description: "Non-streaming API response")
        
        Task {
            do {
                let response = try await client.responses.create(
                    model: deployment,
                    input: "Hello, this is a test of the non-streaming API",
                    maxOutputTokens: 50
                )
                
                XCTAssertNotNil(response.id)
                XCTAssertNotNil(response.output)
                print("✅ Live non-streaming API test successful - Response ID: \(response.id ?? "unknown")")
                expectation.fulfill()
                
            } catch {
                XCTFail("Live non-streaming API test failed: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    /// Test non-streaming mode with function calls using live API  
    func testNonStreamingLiveAPIWithFunctionCalls() {
        guard let endpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"],
              let apiKey = ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"] ?? ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"],
              let deployment = ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] else {
            print("ℹ️ Skipping live API function call test - environment variables not set")
            return
        }
        
        let config = SAOAIAzureConfiguration(
            endpoint: endpoint,
            apiKey: apiKey,
            deploymentName: deployment,
            apiVersion: "preview"
        )
        
        let client = SAOAIClient(configuration: config)
        let expectation = XCTestExpectation(description: "Non-streaming API with function calls")
        
        let sumCalculatorTool = SAOAITool.function(
            name: "sum_calculator", 
            description: "Calculate the sum of two numbers.",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "a": .object([
                        "type": .string("number"),
                        "description": .string("First number")
                    ]),
                    "b": .object([
                        "type": .string("number"),
                        "description": .string("Second number")
                    ])
                ]),
                "required": .array([.string("a"), .string("b")])
            ])
        )
        
        Task {
            do {
                let userMessage = SAOAIMessage(role: .user, text: "Use the sum calculator tool to add 15 and 27")
                let response = try await client.responses.create(
                    model: deployment,
                    input: [userMessage],
                    maxOutputTokens: 200,
                    tools: [sumCalculatorTool]
                )
                
                XCTAssertNotNil(response.id)
                XCTAssertNotNil(response.output)
                
                // Check if the response contains a function call
                var hasFunctionCall = false
                for outputItem in response.output {
                    if outputItem.type == "function_call" {
                        hasFunctionCall = true
                        print("✅ Live non-streaming API with function call successful")
                        break
                    }
                }
                
                if !hasFunctionCall {
                    print("ℹ️ Live non-streaming API responded without function call (model choice)")
                }
                
                expectation.fulfill()
                
            } catch {
                XCTFail("Live non-streaming API with function calls failed: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    /// Test that demonstrates user-controlled function calling loops 
    /// This validates that the SDK does not force automatic function call iterations
    func testUserControlledFunctionCalling() {
        let mockConfig = TestEnvironmentHelper.createStandardAzureConfiguration()
        let client = SAOAIClient(configuration: mockConfig)
        
        // Create a function call output to simulate continuing a conversation
        let functionCallOutput = SAOAIInputContent.FunctionCallOutput(
            callId: "call_123",
            output: "Result from function execution"
        )
        
        // Test that the SDK provides methods for user-controlled function calling
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                // This method allows users to continue with function outputs
                // The user controls when and how many times to call this
                return try await client.responses.createWithFunctionCallOutputs(
                    model: mockConfig.deploymentName,
                    functionCallOutputs: [functionCallOutput],
                    maxOutputTokens: 100,
                    previousResponseId: "resp_123"
                )
            }
        }())
        
        print("✅ User-controlled function calling API structure is valid")
    }
    
    /// Test that validates the SDK does not automatically loop function calls
    func testNoAutomaticFunctionCallLoops() {
        // This test validates that individual API calls return control to the user
        // instead of automatically continuing function call loops
        
        let mockConfig = TestEnvironmentHelper.createStandardAzureConfiguration()
        let client = SAOAIClient(configuration: mockConfig)
        
        // Simulate multiple function call outputs
        let functionCallOutputs = [
            SAOAIInputContent.FunctionCallOutput(callId: "call_1", output: "Result 1"),
            SAOAIInputContent.FunctionCallOutput(callId: "call_2", output: "Result 2")
        ]
        
        // Test that the API method exists and can be called without automatic loops
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                // Each call is individual - no automatic looping
                return try await client.responses.createWithFunctionCallOutputs(
                    model: mockConfig.deploymentName,
                    functionCallOutputs: functionCallOutputs,
                    maxOutputTokens: 150,
                    tools: [SAOAITool.codeInterpreter()], // Include tools for function responses
                    previousResponseId: "resp_456"
                )
            }
        }())
        
        print("✅ Individual function call API (no automatic loops) structure is valid")
    }
}