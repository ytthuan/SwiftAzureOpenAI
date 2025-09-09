import XCTest
@testable import SwiftAzureOpenAI

final class MultiModalAndChainingTests: XCTestCase {
    
    // MARK: - Multi-Modal Input Tests
    
    func testInputImageWithURL() {
        let imageInput = SAOAIInputContent.InputImage(imageURL: "https://example.com/image.jpg")
        XCTAssertEqual(imageInput.type, "input_image")
        XCTAssertEqual(imageInput.imageURL, "https://example.com/image.jpg")
    }
    
    func testInputImageWithBase64() {
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        let imageInput = SAOAIInputContent.InputImage(base64Data: base64Data, mimeType: "image/png")
        XCTAssertEqual(imageInput.type, "input_image")
        XCTAssertEqual(imageInput.imageURL, "data:image/png;base64,\(base64Data)")
    }
    
    func testInputImageWithBase64DefaultMimeType() {
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        let imageInput = SAOAIInputContent.InputImage(base64Data: base64Data)
        XCTAssertEqual(imageInput.type, "input_image")
        XCTAssertEqual(imageInput.imageURL, "data:image/jpeg;base64,\(base64Data)")
    }
    
    func testSAOAIMessageWithTextAndImageURL() {
        let message = SAOAIMessage(role: .user, text: "What is in this image?", imageURL: "https://example.com/image.jpg")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content.count, 2)
        
        // Verify text content
        if case .inputText(let textInput) = message.content[0] {
            XCTAssertEqual(textInput.text, "What is in this image?")
        } else {
            XCTFail("First content should be text")
        }
        
        // Verify image content
        if case .inputImage(let imageInput) = message.content[1] {
            XCTAssertEqual(imageInput.imageURL, "https://example.com/image.jpg")
        } else {
            XCTFail("Second content should be image")
        }
    }
    
    func testSAOAIMessageWithTextAndBase64Image() {
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        let message = SAOAIMessage(role: .user, text: "Analyze this image", base64Image: base64Data, mimeType: "image/png")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content.count, 2)
        
        // Verify text content
        if case .inputText(let textInput) = message.content[0] {
            XCTAssertEqual(textInput.text, "Analyze this image")
        } else {
            XCTFail("First content should be text")
        }
        
        // Verify image content
        if case .inputImage(let imageInput) = message.content[1] {
            XCTAssertEqual(imageInput.imageURL, "data:image/png;base64,\(base64Data)")
        } else {
            XCTFail("Second content should be image")
        }
    }
    
    func testSAOAIMessageWithTextAndBase64ImageDefaultMimeType() {
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        let message = SAOAIMessage(role: .user, text: "Describe this image", base64Image: base64Data)
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content.count, 2)
        
        // Verify image content uses default JPEG MIME type
        if case .inputImage(let imageInput) = message.content[1] {
            XCTAssertEqual(imageInput.imageURL, "data:image/jpeg;base64,\(base64Data)")
        } else {
            XCTFail("Second content should be image")
        }
    }
    
    // MARK: - Response Chaining Tests
    
    func testSAOAIRequestWithPreviousResponseId() {
        let message = SAOAIMessage(role: .user, text: "Continue the conversation")
        let request = SAOAIRequest(
            model: "gpt-4o",
            input: [SAOAIInput.message(message)],
            maxOutputTokens: 200,
            temperature: 0.7,
            topP: 1.0,
            tools: nil,
            previousResponseId: "resp_abc123"
        )
        
        XCTAssertEqual(request.model, "gpt-4o")
        XCTAssertEqual(request.input.count, 1)
        XCTAssertEqual(request.maxOutputTokens, 200)
        XCTAssertEqual(request.temperature, 0.7)
        XCTAssertEqual(request.topP, 1.0)
        XCTAssertNil(request.tools)
        XCTAssertEqual(request.previousResponseId, "resp_abc123")
    }
    
    func testSAOAIRequestWithoutPreviousResponseId() {
        let message = SAOAIMessage(role: .user, text: "Start a new conversation")
        let request = SAOAIRequest(
            model: "gpt-4o",
            input: [SAOAIInput.message(message)]
        )
        
        XCTAssertEqual(request.model, "gpt-4o")
        XCTAssertEqual(request.input.count, 1)
        XCTAssertNil(request.maxOutputTokens)
        XCTAssertNil(request.temperature)
        XCTAssertNil(request.topP)
        XCTAssertNil(request.tools)
        XCTAssertNil(request.previousResponseId)
    }
    
    // MARK: - JSON Encoding/Decoding Tests
    
    func testSAOAIRequestJSONEncodingWithPreviousResponseId() throws {
        let message = SAOAIMessage(role: .user, text: "Test message")
        let request = SAOAIRequest(
            model: "gpt-4o",
            input: [SAOAIInput.message(message)],
            maxOutputTokens: 100,
            temperature: 0.5,
            topP: 0.9,
            tools: nil,
            previousResponseId: "resp_xyz789"
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(request)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"previous_response_id\":\"resp_xyz789\""))
        XCTAssertTrue(jsonString.contains("\"model\":\"gpt-4o\""))
        XCTAssertTrue(jsonString.contains("\"max_output_tokens\":100"))
        XCTAssertTrue(jsonString.contains("\"temperature\":0.5"))
        XCTAssertTrue(jsonString.contains("\"top_p\":0.9"))
    }
    
    func testSAOAIRequestJSONEncodingWithoutPreviousResponseId() throws {
        let message = SAOAIMessage(role: .user, text: "Test message")
        let request = SAOAIRequest(
            model: "gpt-4o",
            input: [SAOAIInput.message(message)]
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(request)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Should not include null previous_response_id field
        XCTAssertFalse(jsonString.contains("previous_response_id"))
        XCTAssertTrue(jsonString.contains("\"model\":\"gpt-4o\""))
    }
    
    func testInputImageJSONEncoding() throws {
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        let imageInput = SAOAIInputContent.InputImage(base64Data: base64Data, mimeType: "image/png")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(imageInput)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"type\":\"input_image\""))
        XCTAssertTrue(jsonString.contains("\"image_url\":\"data:image\\/png;base64,"))
        XCTAssertTrue(jsonString.contains(base64Data.replacingOccurrences(of: "/", with: "\\/")))
    }
    
    func testMultiModalMessageJSONEncoding() throws {
        let message = SAOAIMessage(
            role: .user,
            text: "What's in this image?",
            imageURL: "https://example.com/test.jpg"
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(message)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"role\":\"user\""))
        XCTAssertTrue(jsonString.contains("\"type\":\"input_text\""))
        XCTAssertTrue(jsonString.contains("\"text\":\"What's in this image?\""))
        XCTAssertTrue(jsonString.contains("\"type\":\"input_image\""))
        XCTAssertTrue(jsonString.contains("\"image_url\":\"https:\\/\\/example.com\\/test.jpg\""))
    }
    
    // MARK: - Integration Tests
    
    func testCompleteMultiModalRequestStructure() throws {
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        let message = SAOAIMessage(
            role: .user,
            text: "Please analyze this image and tell me what you see",
            base64Image: base64Data,
            mimeType: "image/png"
        )
        
        let request = SAOAIRequest(
            model: "gpt-4o",
            input: [SAOAIInput.message(message)],
            maxOutputTokens: 300,
            temperature: 0.7,
            previousResponseId: "resp_previous123"
        )
        
        // Validate structure
        XCTAssertEqual(request.model, "gpt-4o")
        XCTAssertEqual(request.input.count, 1)
        XCTAssertEqual(request.maxOutputTokens, 300)
        XCTAssertEqual(request.temperature, 0.7)
        XCTAssertEqual(request.previousResponseId, "resp_previous123")
        
        let messageInput = request.input[0]
        if case .message(let message) = messageInput {
            XCTAssertEqual(message.role, .user)
            XCTAssertEqual(message.content.count, 2)
        } else {
            XCTFail("Expected message input type")
        }
        
        // Test JSON serialization
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(request)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"model\":\"gpt-4o\""))
        XCTAssertTrue(jsonString.contains("\"max_output_tokens\":300"))
        XCTAssertTrue(jsonString.contains("\"temperature\":0.7"))
        XCTAssertTrue(jsonString.contains("\"previous_response_id\":\"resp_previous123\""))
        XCTAssertTrue(jsonString.contains("\"type\":\"input_text\""))
        XCTAssertTrue(jsonString.contains("\"type\":\"input_image\""))
        XCTAssertTrue(jsonString.contains("\"data:image\\/png;base64,"))
        XCTAssertTrue(jsonString.contains(base64Data.replacingOccurrences(of: "/", with: "\\/")))
    }
    
    func testBackwardCompatibilityWithExistingCode() {
        // Test that existing code still works without changes
        let message = SAOAIMessage(role: .user, text: "Simple text message")
        XCTAssertEqual(message.content.count, 1)
        
        if case .inputText(let textInput) = message.content[0] {
            XCTAssertEqual(textInput.text, "Simple text message")
        } else {
            XCTFail("Content should be text")
        }
        
        let request = SAOAIRequest(
            model: "gpt-4o",
            input: [SAOAIInput.message(message)],
            maxOutputTokens: 200
        )
        
        XCTAssertEqual(request.model, "gpt-4o")
        XCTAssertEqual(request.input.count, 1)
        XCTAssertEqual(request.maxOutputTokens, 200)
        XCTAssertNil(request.previousResponseId) // Should be nil for backward compatibility
    }
}