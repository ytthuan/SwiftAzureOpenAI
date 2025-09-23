import XCTest
@testable import SwiftAzureOpenAI

/// Tests for flexible reasoning parameter format and text parameters
/// Validates the new API pattern that allows flexible reasoning and text configurations
final class FlexibleReasoningParameterTests: XCTestCase {
    
    // MARK: - Backward Compatibility Tests
    
    func testBackwardCompatibilityWithExistingReasoningUsage() throws {
        // Test that existing effort-only usage still works
        let reasoning = SAOAIReasoning(effort: "medium")
        
        XCTAssertEqual(reasoning.effort, "medium")
        XCTAssertNil(reasoning.summary)
        
        // Test JSON encoding matches expected format
        let encoded = try JSONEncoder().encode(reasoning)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        XCTAssertEqual(json["effort"] as? String, "medium")
        XCTAssertNil(json["summary"])
    }
    
    // MARK: - Flexible Reasoning Tests
    
    func testFlexibleReasoningWithSummary() throws {
        let reasoning = SAOAIReasoning(effort: "high", summary: "detailed")
        
        XCTAssertEqual(reasoning.effort, "high")
        XCTAssertEqual(reasoning.summary, "detailed")
        
        // Test JSON encoding
        let encoded = try JSONEncoder().encode(reasoning)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        XCTAssertEqual(json["effort"] as? String, "high")
        XCTAssertEqual(json["summary"] as? String, "detailed")
    }
    
    func testReasoningSummaryOptions() throws {
        let summaryOptions = ["auto", "concise", "detailed"]
        
        for summary in summaryOptions {
            let reasoning = SAOAIReasoning(effort: "medium", summary: summary)
            XCTAssertEqual(reasoning.summary, summary)
            
            // Test encoding/decoding
            let encoded = try JSONEncoder().encode(reasoning)
            let decoded = try JSONDecoder().decode(SAOAIReasoning.self, from: encoded)
            XCTAssertEqual(decoded.summary, summary)
        }
    }
    
    // MARK: - Text Parameter Tests
    
    func testTextVerbosityParameter() throws {
        let text = SAOAIText(verbosity: "low")
        
        XCTAssertEqual(text.verbosity, "low")
        
        // Test JSON encoding
        let encoded = try JSONEncoder().encode(text)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        XCTAssertEqual(json["verbosity"] as? String, "low")
    }
    
    func testTextVerbosityOptions() throws {
        let verbosityOptions = ["low", "medium", "high"]
        
        for verbosity in verbosityOptions {
            let text = SAOAIText(verbosity: verbosity)
            XCTAssertEqual(text.verbosity, verbosity)
            
            // Test encoding/decoding
            let encoded = try JSONEncoder().encode(text)
            let decoded = try JSONDecoder().decode(SAOAIText.self, from: encoded)
            XCTAssertEqual(decoded.verbosity, verbosity)
        }
    }
    
    // MARK: - Request Integration Tests
    
    func testRequestWithFlexibleParameters() throws {
        let message = SAOAIMessage(
            role: .user,
            content: [.inputText(.init(text: "Analyze this complex problem"))]
        )
        let reasoning = SAOAIReasoning(effort: "high", summary: "auto")
        let text = SAOAIText(verbosity: "medium")
        
        let request = SAOAIRequest(
            model: "gpt-4o",
            input: [.message(message)],
            maxOutputTokens: 500,
            reasoning: reasoning,
            text: text
        )
        
        XCTAssertEqual(request.reasoning?.effort, "high")
        XCTAssertEqual(request.reasoning?.summary, "auto")
        XCTAssertEqual(request.text?.verbosity, "medium")
        
        // Test full request encoding
        let encoded = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        if let reasoningDict = json["reasoning"] as? [String: Any] {
            XCTAssertEqual(reasoningDict["effort"] as? String, "high")
            XCTAssertEqual(reasoningDict["summary"] as? String, "auto")
        } else {
            XCTFail("Expected reasoning dictionary in JSON")
        }
        
        if let textDict = json["text"] as? [String: Any] {
            XCTAssertEqual(textDict["verbosity"] as? String, "medium")
        } else {
            XCTFail("Expected text dictionary in JSON")
        }
    }
    
    // MARK: - Client API Tests
    
    func testResponsesClientWithFlexibleParameters() async throws {
        // Mock configuration for testing
        let config = SAOAIAzureConfiguration(
            endpoint: "https://192.0.2.1",
            apiKey: "test-key",
            deploymentName: "test-deployment"
        )
        
        let client = SAOAIClient(configuration: config)
        let reasoning = SAOAIReasoning(effort: "medium", summary: "concise")
        let text = SAOAIText(verbosity: "low")
        
        // Test that client accepts new parameters (this will fail on actual call but validates API surface)
        do {
            _ = try await client.responses.create(
                model: "gpt-4o",
                input: "Test input",
                reasoning: reasoning,
                text: text
            )
        } catch {
            // Expected to fail since we don't have real credentials, but API surface is validated
            XCTAssertTrue(error is SAOAIError || error is URLError)
        }
    }
    
    func testStreamingResponsesClientWithFlexibleParameters() {
        // Mock configuration for testing
        let config = SAOAIAzureConfiguration(
            endpoint: "https://192.0.2.1",
            apiKey: "test-key",
            deploymentName: "test-deployment"
        )
        
        let client = SAOAIClient(configuration: config)
        let reasoning = SAOAIReasoning(effort: "high", summary: "detailed")
        let text = SAOAIText(verbosity: "high")
        
        // Test that streaming client accepts new parameters
        let stream = client.responses.createStreaming(
            model: "gpt-4o",
            input: "Test streaming input",
            reasoning: reasoning,
            text: text
        )
        
        // Validate that stream is created (actual streaming would require real API)
        XCTAssertNotNil(stream)
    }
    
    // MARK: - Edge Cases and Validation
    
    func testNilParametersStillWork() throws {
        let reasoning = SAOAIReasoning(effort: "low", summary: nil)
        XCTAssertEqual(reasoning.effort, "low")
        XCTAssertNil(reasoning.summary)
        
        let text = SAOAIText(verbosity: nil)
        XCTAssertNil(text.verbosity)
        
        // Test encoding with nil values
        let reasoningEncoded = try JSONEncoder().encode(reasoning)
        let reasoningJson = try JSONSerialization.jsonObject(with: reasoningEncoded) as! [String: Any]
        XCTAssertEqual(reasoningJson["effort"] as? String, "low")
        XCTAssertNil(reasoningJson["summary"])
        
        let textEncoded = try JSONEncoder().encode(text)
        let textJson = try JSONSerialization.jsonObject(with: textEncoded) as! [String: Any]
        XCTAssertNil(textJson["verbosity"])
    }
    
    func testEquatabilityWithNewFields() {
        let reasoning1 = SAOAIReasoning(effort: "medium", summary: "auto")
        let reasoning2 = SAOAIReasoning(effort: "medium", summary: "auto")
        let reasoning3 = SAOAIReasoning(effort: "medium", summary: "detailed")
        let reasoning4 = SAOAIReasoning(effort: "medium", summary: nil)
        
        XCTAssertEqual(reasoning1, reasoning2)
        XCTAssertNotEqual(reasoning1, reasoning3)
        XCTAssertNotEqual(reasoning1, reasoning4)
        
        let text1 = SAOAIText(verbosity: "low")
        let text2 = SAOAIText(verbosity: "low")
        let text3 = SAOAIText(verbosity: "high")
        
        XCTAssertEqual(text1, text2)
        XCTAssertNotEqual(text1, text3)
    }
}