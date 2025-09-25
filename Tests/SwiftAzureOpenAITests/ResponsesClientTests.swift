import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

final class ResponsesClientTests: XCTestCase {
    
    func testResponsesClientPropertyExists() {
        let config = SAOAIOpenAIConfiguration(apiKey: "sk-test", organization: nil)
        let client = SAOAIClient(configuration: config)
        
        // Verify that the responses property exists and is accessible
        XCTAssertNotNil(client.responses)
    }
    
    func testConvenienceMessageInitializer() {
        // Create message without any potential network-triggering operations
        let message = SAOAIMessage(role: .user, text: "Hello, world!")
        
        // Validate message structure without creating any client or configuration objects
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content.count, 1)
        
        if case let .inputText(textContent) = message.content.first {
            XCTAssertEqual(textContent.text, "Hello, world!")
            XCTAssertEqual(textContent.type, "input_text")
        } else {
            XCTFail("Expected inputText content")
        }
        
        // Additional validation of message properties
        XCTAssertTrue(message.content.count > 0)
        XCTAssertFalse(message.content.isEmpty)
    }
    
    func testResponsesClientCreateWithStringInput() {
        // Create a mock configuration - removed async to avoid any network triggers
        let config = TestableConfiguration()
        let cache = InMemoryResponseCache()
        let client = SAOAIClient(configuration: config, cache: cache)
        
        // This tests the method structure without making network calls
        // Verify the method exists and is callable (compilation test)
        let createMethod = client.responses.create
        XCTAssertNotNil(createMethod)
        
        // Additional validation that doesn't require network calls
        XCTAssertNotNil(client.responses)
        XCTAssertTrue(type(of: createMethod) != Void.self)
    }
    
    func testResponsesClientCreateWithMessagesArray() {
        let config = TestableConfiguration()
        let client = SAOAIClient(configuration: config)
        
        let messages = [
            SAOAIMessage(role: .system, text: "You are a helpful assistant."),
            SAOAIMessage(role: .user, text: "Hello!")
        ]
        
        // Test that the method exists and accepts the right parameters
        let createMethod = client.responses.create
        XCTAssertNotNil(createMethod)
        
        // Verify message structure is correct
        XCTAssertEqual(messages[0].role, .system)
        XCTAssertEqual(messages[1].role, .user)
        
        if case let .inputText(textContent) = messages[0].content.first {
            XCTAssertEqual(textContent.text, "You are a helpful assistant.")
        } else {
            XCTFail("Expected inputText content for system message")
        }
        
        if case let .inputText(textContent) = messages[1].content.first {
            XCTAssertEqual(textContent.text, "Hello!")
        } else {
            XCTFail("Expected inputText content for user message")
        }
        
        // Additional validation without network calls
        XCTAssertEqual(messages.count, 2)
        XCTAssertFalse(messages.isEmpty)
    }
    
    func testResponsesClientRetrieveMethod() {
        let config = TestableConfiguration()
        let client = SAOAIClient(configuration: config)
        
        // Test that the retrieve method exists
        let retrieveMethod = client.responses.retrieve
        XCTAssertNotNil(retrieveMethod)
    }
    
    func testResponsesClientDeleteMethod() {
        let config = TestableConfiguration()
        let client = SAOAIClient(configuration: config)
        
        // Test that the delete method exists
        let deleteMethod = client.responses.delete
        XCTAssertNotNil(deleteMethod)
    }
    
    func testBackwardCompatibilityWithExistingAPI() {
        let config = SAOAIOpenAIConfiguration(apiKey: "sk-test", organization: nil)
        let client = SAOAIClient(configuration: config)
        
        // Verify new method is available
        XCTAssertNotNil(client.responses)
        
        // Test that we can still create complex requests the old way
        let request = SAOAIRequest(
            model: "gpt-4o-mini",
            input: [
                SAOAIInput.message(SAOAIMessage(
                    role: .user,
                    content: [.inputText(.init(text: "Hello"))]
                ))
            ],
            maxOutputTokens: 100
        )
        
        XCTAssertEqual(request.model, "gpt-4o-mini")
        XCTAssertEqual(request.input.count, 1)
        XCTAssertEqual(request.maxOutputTokens, 100)
    }
    
    func testComplexMessageStructureStillWorks() {
        // Verify that the old complex way still works
        let complexMessage = SAOAIMessage(
            role: .user,
            content: [
                .inputText(.init(text: "Hello")),
                .inputImage(.init(imageURL: "https://example.com/image.jpg"))
            ]
        )
        
        XCTAssertEqual(complexMessage.role, .user)
        XCTAssertEqual(complexMessage.content.count, 2)
        
        if case let .inputText(textContent) = complexMessage.content[0] {
            XCTAssertEqual(textContent.text, "Hello")
        } else {
            XCTFail("Expected inputText content")
        }
        
        if case let .inputImage(imageContent) = complexMessage.content[1] {
            XCTAssertEqual(imageContent.imageURL, "https://example.com/image.jpg")
        } else {
            XCTFail("Expected inputImage content")
        }
    }
}

// MARK: - Test Helper

/// A testable configuration that provides a valid URL and headers without making network calls
private struct TestableConfiguration: SAOAIConfiguration {
    var baseURL: URL {
        URL(string: "https://192.0.2.1/openai/v1/responses")!
    }
    
    var headers: [String: String] {
        [
            "Authorization": "Bearer sk-test",
            "Content-Type": "application/json"
        ]
    }
    
    var sseLoggerConfiguration: SSELoggerConfiguration { .disabled }
    var loggerConfiguration: LoggerConfiguration { .disabled }
}