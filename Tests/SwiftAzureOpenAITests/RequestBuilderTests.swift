import XCTest
@testable import SwiftAzureOpenAI

final class RequestBuilderTests: XCTestCase {
    
    func testAzureRequestBuilderURL() {
        let azureConfig = SAOAIAzureConfiguration(
            endpoint: "https://test-resource.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "test-deployment",
            apiVersion: "preview"
        )
        
        let builder = AzureRequestBuilder.create(from: azureConfig)
        
        // Test responses endpoint
        let responsesURL = builder.buildURL(for: AzureRequestBuilder.Endpoint.responses)
        XCTAssertEqual(responsesURL.absoluteString, "https://test-resource.openai.azure.com/openai/v1/responses?api-version=preview")
        
        // Test embeddings endpoint
        let embeddingsURL = builder.buildURL(for: AzureRequestBuilder.Endpoint.embeddings)
        XCTAssertEqual(embeddingsURL.absoluteString, "https://test-resource.openai.azure.com/openai/v1/embeddings?api-version=preview")
        
        // Test files endpoint
        let filesURL = builder.buildURL(for: AzureRequestBuilder.Endpoint.files)
        XCTAssertEqual(filesURL.absoluteString, "https://test-resource.openai.azure.com/openai/v1/files?api-version=preview")
    }
    
    func testOpenAIRequestBuilderURL() {
        let openAIConfig = SAOAIOpenAIConfiguration(
            apiKey: "sk-test",
            organization: "org-123"
        )
        
        let builder = AzureRequestBuilder.create(from: openAIConfig)
        
        // Test responses endpoint (should work for OpenAI too)
        let responsesURL = builder.buildURL(for: AzureRequestBuilder.Endpoint.responses)
        XCTAssertTrue(responsesURL.absoluteString.contains("/responses"))
        
        // Test embeddings endpoint
        let embeddingsURL = builder.buildURL(for: AzureRequestBuilder.Endpoint.embeddings)
        XCTAssertTrue(embeddingsURL.absoluteString.contains("/embeddings"))
    }
    
    func testRequestBuilderBuildRequest() {
        let azureConfig = SAOAIAzureConfiguration(
            endpoint: "https://test-resource.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "test-deployment",
            apiVersion: "preview"
        )
        
        let builder = AzureRequestBuilder.create(from: azureConfig)
        let body = Data("test body".utf8)
        
        let request = builder.buildRequest(
            method: "POST",
            endpoint: AzureRequestBuilder.Endpoint.embeddings,
            body: body,
            additionalHeaders: ["X-Custom": "test"]
        )
        
        XCTAssertEqual(request.method, "POST")
        XCTAssertTrue(request.url.absoluteString.contains("/embeddings"))
        XCTAssertEqual(request.body, body)
        XCTAssertEqual(request.headers["api-key"], "test-key")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        XCTAssertEqual(request.headers["X-Custom"], "test")
    }
    
    func testRequestBuilderStreamingRequest() {
        let azureConfig = SAOAIAzureConfiguration(
            endpoint: "https://test-resource.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "test-deployment"
        )
        
        let builder = AzureRequestBuilder.create(from: azureConfig)
        let body = Data("test body".utf8)
        
        let request = builder.buildStreamingRequest(
            endpoint: AzureRequestBuilder.Endpoint.responses,
            body: body
        )
        
        XCTAssertEqual(request.method, "POST")
        XCTAssertTrue(request.url.absoluteString.contains("/responses"))
        XCTAssertEqual(request.body, body)
        
        // Check streaming headers
        XCTAssertEqual(request.headers["Accept"], "text/event-stream")
        XCTAssertEqual(request.headers["Cache-Control"], "no-cache")
        XCTAssertEqual(request.headers["Connection"], "keep-alive")
        
        // Check Azure headers are still there
        XCTAssertEqual(request.headers["api-key"], "test-key")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
    }
    
    func testEndpointNames() {
        XCTAssertEqual(AzureRequestBuilder.Endpoint.responses, "responses")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.embeddings, "embeddings")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.files, "files")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.completions, "completions")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.chatCompletions, "chat/completions")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.images, "images")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.audio, "audio")
    }
    
    func testEndpointTypeNames() {
        XCTAssertEqual(AzureRequestBuilder.Endpoint.name(for: .responses), "responses")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.name(for: .embeddings), "embeddings")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.name(for: .files), "files")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.name(for: .completions), "completions")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.name(for: .chatCompletions), "chat/completions")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.name(for: .images), "images")
        XCTAssertEqual(AzureRequestBuilder.Endpoint.name(for: .audio), "audio")
        
        // Test all cases are covered
        let allCases = AzureRequestBuilder.EndpointType.allCases
        XCTAssertEqual(allCases.count, 7)
    }
    
    func testEndpointTypeCaseIterable() {
        let allCases = AzureRequestBuilder.EndpointType.allCases
        XCTAssertTrue(allCases.contains(.responses))
        XCTAssertTrue(allCases.contains(.embeddings))
        XCTAssertTrue(allCases.contains(.files))
        XCTAssertTrue(allCases.contains(.completions))
        XCTAssertTrue(allCases.contains(.chatCompletions))
        XCTAssertTrue(allCases.contains(.images))
        XCTAssertTrue(allCases.contains(.audio))
    }
    
    func testCustomTimeoutInterval() {
        let azureConfig = SAOAIAzureConfiguration(
            endpoint: "https://test-resource.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "test-deployment"
        )
        
        let builder = AzureRequestBuilder.create(from: azureConfig)
        
        let request = builder.buildRequest(
            endpoint: AzureRequestBuilder.Endpoint.embeddings,
            timeoutInterval: 120.0
        )
        
        XCTAssertEqual(request.timeoutInterval, 120.0)
    }
}