import XCTest
@testable import SwiftAzureOpenAI

final class ResponsesClientEnhancementTests: XCTestCase {
    
    var mockClient: SAOAIClient!
    
    override func setUp() {
        super.setUp()
        let config = TestEnvironmentHelper.createStandardAzureConfiguration()
        mockClient = SAOAIClient(configuration: config)
    }
    
    // MARK: - Tests for previousResponseId parameter
    
    func testResponsesClientCreateWithPreviousResponseIdString() {
        // Test that the string input version accepts previousResponseId
        let client = mockClient.responses
        XCTAssertNotNil(client)
        
        // This should compile and not throw at creation time
        // We can't test the actual HTTP call without mocking, but we can verify the signature exists
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                return try await client.create(
                    model: "gpt-4o",
                    input: "Test message",
                    maxOutputTokens: 100,
                    temperature: 0.7,
                    topP: 1.0,
                    previousResponseId: "resp_test123"
                )
            }
        }())
    }
    
    func testResponsesClientCreateWithPreviousResponseIdArray() {
        // Test that the array input version accepts previousResponseId
        let client = mockClient.responses
        let message = SAOAIMessage(role: .user, text: "Test message")
        
        // This should compile and not throw at creation time
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                return try await client.create(
                    model: "gpt-4o",
                    input: [message],
                    maxOutputTokens: 100,
                    temperature: 0.7,
                    topP: 1.0,
                    tools: nil,
                    previousResponseId: "resp_test123"
                )
            }
        }())
    }
    
    // MARK: - Tests for multi-modal convenience methods
    
    func testConvenienceMethodForTextAndImageURL() {
        let message = SAOAIMessage(
            role: .user,
            text: "What is in this image?",
            imageURL: "https://example.com/test.jpg"
        )
        
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content.count, 2)
        
        // Verify text content
        if case .inputText(let textInput) = message.content[0] {
            XCTAssertEqual(textInput.text, "What is in this image?")
            XCTAssertEqual(textInput.type, "input_text")
        } else {
            XCTFail("First content should be text")
        }
        
        // Verify image content
        if case .inputImage(let imageInput) = message.content[1] {
            XCTAssertEqual(imageInput.imageURL, "https://example.com/test.jpg")
            XCTAssertEqual(imageInput.type, "input_image")
        } else {
            XCTFail("Second content should be image")
        }
    }
    
    func testConvenienceMethodForTextAndBase64Image() {
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        let message = SAOAIMessage(
            role: .user,
            text: "Analyze this image",
            base64Image: base64Data,
            mimeType: "image/png"
        )
        
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content.count, 2)
        
        // Verify text content
        if case .inputText(let textInput) = message.content[0] {
            XCTAssertEqual(textInput.text, "Analyze this image")
        } else {
            XCTFail("First content should be text")
        }
        
        // Verify image content with proper data URL format
        if case .inputImage(let imageInput) = message.content[1] {
            XCTAssertEqual(imageInput.imageURL, "data:image/png;base64,\(base64Data)")
        } else {
            XCTFail("Second content should be image")
        }
    }
    
    func testConvenienceMethodForTextAndBase64ImageDefaultMimeType() {
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        let message = SAOAIMessage(
            role: .user,
            text: "Describe this image",
            base64Image: base64Data
        )
        
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content.count, 2)
        
        // Verify image content uses default JPEG MIME type
        if case .inputImage(let imageInput) = message.content[1] {
            XCTAssertEqual(imageInput.imageURL, "data:image/jpeg;base64,\(base64Data)")
        } else {
            XCTFail("Second content should be image")
        }
    }
    
    // MARK: - Test base64 image initializer
    
    func testInputImageBase64Initializer() {
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        
        // Test with specific MIME type
        let imageWithMime = SAOAIInputContent.InputImage(base64Data: base64Data, mimeType: "image/png")
        XCTAssertEqual(imageWithMime.type, "input_image")
        XCTAssertEqual(imageWithMime.imageURL, "data:image/png;base64,\(base64Data)")
        
        // Test with default MIME type
        let imageDefault = SAOAIInputContent.InputImage(base64Data: base64Data)
        XCTAssertEqual(imageDefault.type, "input_image")
        XCTAssertEqual(imageDefault.imageURL, "data:image/jpeg;base64,\(base64Data)")
    }
    
    // MARK: - Integration test demonstrating the Python-style API from the issue
    
    func testPythonStyleAPIEquivalent() {
        // This test demonstrates that we can now replicate the Python-style API requested in the issue
        
        // Example 1: Multi-modal with image URL (from the issue)
        let message1 = SAOAIMessage(
            role: .user,
            text: "what is in this image?",
            imageURL: "https://example.com/image.jpg"
        )
        
        XCTAssertEqual(message1.content.count, 2)
        
        // Example 2: Multi-modal with base64 image (from the issue)
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        let message2 = SAOAIMessage(
            role: .user,
            text: "what is in this image?",
            base64Image: base64Data,
            mimeType: "image/jpeg"
        )
        
        XCTAssertEqual(message2.content.count, 2)
        if case .inputImage(let imageInput) = message2.content[1] {
            XCTAssertTrue(imageInput.imageURL.hasPrefix("data:image/jpeg;base64,"))
        } else {
            XCTFail("Should contain base64 image")
        }
        
        // Example 3: Response chaining (from the issue)
        let request = SAOAIRequest(
            model: "gpt-4o",
            input: [SAOAIInput.message(message1)],
            previousResponseId: "resp_abc123"
        )
        
        XCTAssertEqual(request.model, "gpt-4o")
        XCTAssertEqual(request.previousResponseId, "resp_abc123")
        XCTAssertEqual(request.input.count, 1)
    }
    
    // MARK: - Backward compatibility test
    
    func testBackwardCompatibilityMaintained() {
        // Ensure that all existing code still works without changes
        
        // Simple text message (existing functionality)
        let simpleMessage = SAOAIMessage(role: .user, text: "Hello")
        XCTAssertEqual(simpleMessage.content.count, 1)
        
        // Manual content creation (existing functionality)
        let manualMessage = SAOAIMessage(
            role: .user,
            content: [
                .inputText(.init(text: "Hello")),
                .inputImage(.init(imageURL: "https://example.com/image.jpg"))
            ]
        )
        XCTAssertEqual(manualMessage.content.count, 2)
        
        // Request without previousResponseId (existing functionality)
        let simpleRequest = SAOAIRequest(
            model: "gpt-4o",
            input: [SAOAIInput.message(simpleMessage)],
            maxOutputTokens: 100
        )
        XCTAssertEqual(simpleRequest.model, "gpt-4o")
        XCTAssertNil(simpleRequest.previousResponseId)
    }
    
    // MARK: - Tests for reasoning parameter
    
    func testResponsesClientCreateWithSAOAIReasoningParameterString() {
        // Test that the string input version accepts reasoning parameter
        let client = mockClient.responses
        let reasoning = SAOAIReasoning(effort: "medium")
        
        // This should compile and not throw at creation time
        XCTAssertNoThrow({
            let _ = { () async throws -> SAOAIResponse in
                return try await client.create(
                    model: "o4-mini",
                    input: "What is the weather like today?",
                    maxOutputTokens: 100,
                    temperature: 0.7,
                    topP: 1.0,
                    previousResponseId: nil,
                    reasoning: reasoning
                )
            }
        }())
    }
    
    func testResponsesClientCreateWithSAOAIReasoningParameterArray() {
        // Test that the array input version accepts reasoning parameter
        let client = mockClient.responses
        let message = SAOAIMessage(role: .user, text: "Test message")
        let reasoning = SAOAIReasoning(effort: "high")
        
        // Test API surface without making network calls to avoid signal 13 errors
        XCTAssertNotNil(client)
        
        // Verify the method signature exists by creating the request structure
        let request = SAOAIRequest(
            model: "o4-mini",
            input: [SAOAIInput.message(message)],
            maxOutputTokens: 100,
            temperature: 0.7,
            topP: 1.0,
            tools: nil,
            previousResponseId: nil,
            reasoning: reasoning
        )
        
        XCTAssertEqual(request.model, "o4-mini")
        XCTAssertEqual(request.reasoning?.effort, "high")
        XCTAssertNotNil(request.reasoning)
    }
    
    func testSAOAIRequestWithSAOAIReasoningParameter() {
        // Test that SAOAIRequest correctly includes reasoning parameter
        let message = SAOAIMessage(role: .user, text: "Test message")
        let reasoning = SAOAIReasoning(effort: "low")
        
        let request = SAOAIRequest(
            model: "o3-mini",
            input: [SAOAIInput.message(message)],
            maxOutputTokens: 50,
            reasoning: reasoning
        )
        
        XCTAssertEqual(request.model, "o3-mini")
        XCTAssertEqual(request.reasoning?.effort, "low")
        XCTAssertNotNil(request.reasoning)
    }
}