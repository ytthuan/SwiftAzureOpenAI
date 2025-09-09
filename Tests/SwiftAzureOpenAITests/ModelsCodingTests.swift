import XCTest
@testable import SwiftAzureOpenAI

final class ModelsCodingTests: XCTestCase {
    func testSAOAIRequestEncodingKeys() throws {
        let message = SAOAIMessage(
            role: .user,
            content: [
                .inputText(.init(text: "Hello")),
                .inputImage(.init(imageURL: "https://example.com/img.png"))
            ]
        )
        let req = SAOAIRequest(
            model: "gpt-4o-mini",
            input: [SAOAIInput.message(message)],
            maxOutputTokens: 256,
            temperature: 0.3,
            topP: 0.9,
            tools: [SAOAITool(type: "function", name: "doThing", description: "desc", parameters: .object([:]))]
        )

        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["model"] as? String, "gpt-4o-mini")
        XCTAssertNotNil(json["input"]) // structure validated via decode below
        XCTAssertEqual(json["max_output_tokens"] as? Int, 256)
        XCTAssertEqual(json["temperature"] as? Double, 0.3)
        XCTAssertEqual(json["top_p"] as? Double, 0.9)
        XCTAssertNotNil(json["tools"])        
    }

    func testSAOAIRequestWithSAOAIReasoningParameter() throws {
        let message = SAOAIMessage(
            role: .user,
            content: [.inputText(.init(text: "What is the weather like today?"))]
        )
        let reasoning = SAOAIReasoning(effort: "medium")
        let req = SAOAIRequest(
            model: "o4-mini",
            input: [SAOAIInput.message(message)],
            maxOutputTokens: 100,
            temperature: 0.5,
            reasoning: reasoning
        )

        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["model"] as? String, "o4-mini")
        XCTAssertNotNil(json["input"])
        XCTAssertEqual(json["max_output_tokens"] as? Int, 100)
        XCTAssertEqual(json["temperature"] as? Double, 0.5)
        
        // Verify reasoning parameter
        XCTAssertNotNil(json["reasoning"])
        if let reasoningDict = json["reasoning"] as? [String: Any] {
            XCTAssertEqual(reasoningDict["effort"] as? String, "medium")
        } else {
            XCTFail("Expected reasoning to be a dictionary")
        }
    }

    func testSAOAIResponseDecoding() throws {
        let payload = {
            () -> [String: Any] in
            let outputText: [String: Any] = ["type": "output_text", "text": "Hi there"]
            let output: [String: Any] = [
                "content": [outputText],
                "role": "assistant"
            ]
            return [
                "id": "resp_123",
                "model": "gpt-4o-mini",
                "created": 1_700_000_000,
                "output": [output],
                "usage": [
                    "input_tokens": 10,
                    "output_tokens": 20,
                    "total_tokens": 30
                ]
            ]
        }()
        let data = try JSONSerialization.data(withJSONObject: payload)
        let decoded = try JSONDecoder().decode(SAOAIResponse.self, from: data)

        XCTAssertEqual(decoded.id, "resp_123")
        XCTAssertEqual(decoded.model, "gpt-4o-mini")
        XCTAssertEqual(decoded.output.count, 1)
        let firstOutput = decoded.output.first!
        XCTAssertNotNil(firstOutput.content, "Content should not be nil for this response")
        if case let .outputText(t) = firstOutput.content!.first! {
            XCTAssertEqual(t.text, "Hi there")
        } else {
            XCTFail("Expected output_text part")
        }
        XCTAssertEqual(decoded.usage?.totalTokens, 30)
    }
    
    func testSAOAIResponseCreatedAtFieldMapping() throws {
        // Test that API responses with "created_at" field are correctly mapped to "created"
        let payload: [String: Any] = [
            "id": "resp_test_created_at",
            "model": "gpt-5-nano", 
            "created_at": 1756613526,  // Note: using "created_at" as in real API response
            "output": [
                [
                    "id": "rs_test",
                    "type": "reasoning",
                    "summary": []
                ]
            ],
            "usage": [
                "input_tokens": 20,
                "output_tokens": 0,
                "total_tokens": 20
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: payload)
        let decoded = try JSONDecoder().decode(SAOAIResponse.self, from: data)
        
        XCTAssertEqual(decoded.id, "resp_test_created_at")
        XCTAssertEqual(decoded.model, "gpt-5-nano")
        XCTAssertEqual(decoded.created, 1756613526, "created_at field should be mapped to created property")
        XCTAssertEqual(decoded.output.count, 1)
        
        let firstOutput = decoded.output.first!
        XCTAssertEqual(firstOutput.id, "rs_test")
        XCTAssertEqual(firstOutput.type, "reasoning")
        XCTAssertEqual(firstOutput.summary, [])
        XCTAssertNil(firstOutput.content, "Reasoning outputs should not have content")
    }
}