import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

final class SwiftAzureOpenAITests: XCTestCase {
    
    func testInitializationWithConfiguration() {
        let config = OpenAIServiceConfiguration(apiKey: "sk-test", organization: nil)
        let client = SwiftAzureOpenAI(configuration: config)
        
        // Should initialize without throwing
        XCTAssertNotNil(client)
    }
    
    func testInitializationWithCache() {
        let config = AzureOpenAIConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o-mini"
        )
        let cache = InMemoryResponseCache()
        let client = SwiftAzureOpenAI(configuration: config, cache: cache)
        
        // Should initialize with cache without throwing
        XCTAssertNotNil(client)
    }
    
    func testHandleResponseWithValidData() async throws {
        let config = OpenAIServiceConfiguration(apiKey: "sk-test", organization: nil)
        let client = SwiftAzureOpenAI(configuration: config)
        
        // Prepare test response data
        let responseData: [String: Any] = [
            "id": "resp_123",
            "model": "gpt-4o-mini", 
            "created": 1700000000,
            "output": [
                [
                    "role": "assistant",
                    "content": [
                        [
                            "type": "output_text",
                            "text": "Hello, world!"
                        ]
                    ]
                ]
            ],
            "usage": [
                "input_tokens": 10,
                "output_tokens": 5,
                "total_tokens": 15
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: responseData)
        
        let url = URL(string: "https://api.openai.com/v1/responses")!
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["x-request-id": "req_456"]
        )!
        
        let result: APIResponse<ResponsesResponse> = try await client.handleResponse(
            data: data,
            response: httpResponse
        )
        
        XCTAssertEqual(result.data.id, "resp_123")
        XCTAssertEqual(result.data.model, "gpt-4o-mini")
        XCTAssertEqual(result.metadata.requestId, "req_456")
    }
    
    func testHandleResponseWithInvalidResponse() async throws {
        let config = OpenAIServiceConfiguration(apiKey: "sk-test", organization: nil)
        let client = SwiftAzureOpenAI(configuration: config)
        
        let data = Data("test".utf8)
        
        // Create a proper URLResponse using URL initializer
        let url = URL(string: "https://invalid.response.com")!
        let invalidResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        
        do {
            let _: APIResponse<ResponsesResponse> = try await client.handleResponse(
                data: data,
                response: invalidResponse
            )
            XCTFail("Expected networkError to be thrown")
        } catch let error as OpenAIError {
            if case .networkError(let urlError as URLError) = error {
                XCTAssertEqual(urlError.code, URLError.badServerResponse)
            } else {
                XCTFail("Expected networkError with badServerResponse, got: \(error)")
            }
        }
    }
    
    func testProcessStreamingResponseReturnsStream() {
        let config = OpenAIServiceConfiguration(apiKey: "sk-test", organization: nil)
        let client = SwiftAzureOpenAI(configuration: config)
        
        // Create test streaming data
        let inputStream = AsyncThrowingStream<Data, Error> { continuation in
            let testData = try! JSONSerialization.data(withJSONObject: ["value": 42])
            continuation.yield(testData)
            continuation.finish()
        }
        
        struct TestType: Codable { let value: Int }
        let outputStream = client.processStreamingResponse(from: inputStream, type: TestType.self)
        
        // Should return a stream without throwing
        XCTAssertNotNil(outputStream)
    }
}
