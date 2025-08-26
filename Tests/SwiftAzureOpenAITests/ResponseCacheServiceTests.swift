import XCTest
@testable import SwiftAzureOpenAI

final class ResponseCacheServiceTests: XCTestCase {
    
    func testInMemoryResponseCacheStoreAndRetrieve() async throws {
        let cache = InMemoryResponseCache()
        
        struct TestData: Codable, Equatable {
            let id: String
            let value: Int
        }
        
        let testData = TestData(id: "test123", value: 42)
        let metadata = ResponseMetadata(
            requestId: "req_123",
            processingTime: 0.5,
            rateLimit: nil
        )
        let response = APIResponse(data: testData, metadata: metadata, statusCode: 200, headers: [:])
        let key = Data("test-key".utf8)
        
        // Store response
        await cache.store(response: response, for: key)
        
        // Retrieve response
        let retrieved: APIResponse<TestData>? = await cache.retrieve(for: key, as: TestData.self)
        
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.data, testData)
        XCTAssertEqual(retrieved?.metadata.requestId, "req_123")
    }
    
    func testInMemoryResponseCacheRetrieveNonExistentKey() async throws {
        let cache = InMemoryResponseCache()
        
        struct TestData: Codable {
            let value: String
        }
        
        let key = Data("non-existent-key".utf8)
        let retrieved: APIResponse<TestData>? = await cache.retrieve(for: key, as: TestData.self)
        
        XCTAssertNil(retrieved)
    }
    
    func testInMemoryResponseCacheWithDifferentKeys() async throws {
        let cache = InMemoryResponseCache()
        
        struct TestData: Codable, Equatable {
            let value: String
        }
        
        let data1 = TestData(value: "first")
        let data2 = TestData(value: "second")
        
        let response1 = APIResponse(data: data1, metadata: ResponseMetadata(requestId: "1", processingTime: nil, rateLimit: nil), statusCode: 200, headers: [:])
        let response2 = APIResponse(data: data2, metadata: ResponseMetadata(requestId: "2", processingTime: nil, rateLimit: nil), statusCode: 200, headers: [:])
        
        let key1 = Data("key1".utf8)
        let key2 = Data("key2".utf8)
        
        // Store both responses
        await cache.store(response: response1, for: key1)
        await cache.store(response: response2, for: key2)
        
        // Retrieve and verify they don't interfere
        let retrieved1: APIResponse<TestData>? = await cache.retrieve(for: key1, as: TestData.self)
        let retrieved2: APIResponse<TestData>? = await cache.retrieve(for: key2, as: TestData.self)
        
        XCTAssertEqual(retrieved1?.data.value, "first")
        XCTAssertEqual(retrieved2?.data.value, "second")
    }
    
    func testInMemoryResponseCacheWithCustomEncoderDecoder() async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let cache = InMemoryResponseCache(encoder: encoder, decoder: decoder)
        
        struct TestData: Codable, Equatable {
            let firstName: String // Will be encoded as "first_name"
        }
        
        let testData = TestData(firstName: "John")
        let metadata = ResponseMetadata(requestId: "req_456", processingTime: nil, rateLimit: nil)
        let response = APIResponse(data: testData, metadata: metadata, statusCode: 200, headers: [:])
        let key = Data("custom-encoder-key".utf8)
        
        // Store and retrieve
        await cache.store(response: response, for: key)
        let retrieved: APIResponse<TestData>? = await cache.retrieve(for: key, as: TestData.self)
        
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.data.firstName, "John")
    }
    
    func testInMemoryResponseCacheOverwriteExistingKey() async throws {
        let cache = InMemoryResponseCache()
        
        struct TestData: Codable, Equatable {
            let value: Int
        }
        
        let data1 = TestData(value: 1)
        let data2 = TestData(value: 2)
        
        let response1 = APIResponse(data: data1, metadata: ResponseMetadata(requestId: "old", processingTime: nil, rateLimit: nil), statusCode: 200, headers: [:])
        let response2 = APIResponse(data: data2, metadata: ResponseMetadata(requestId: "new", processingTime: nil, rateLimit: nil), statusCode: 200, headers: [:])
        
        let key = Data("same-key".utf8)
        
        // Store first response
        await cache.store(response: response1, for: key)
        
        // Overwrite with second response
        await cache.store(response: response2, for: key)
        
        // Retrieve should return the latest value
        let retrieved: APIResponse<TestData>? = await cache.retrieve(for: key, as: TestData.self)
        
        XCTAssertEqual(retrieved?.data.value, 2)
        XCTAssertEqual(retrieved?.metadata.requestId, "new")
    }
    
    func testInMemoryResponseCacheWithComplexData() async throws {
        let cache = InMemoryResponseCache()
        
        let response = APIResponse(
            data: ResponsesResponse(
                id: "resp_complex",
                model: "gpt-4o-mini",
                created: 1700000000,
                output: [
                    ResponseOutput(
                        content: [
                            .outputText(OutputContentPart.OutputText(text: "Complex response test"))
                        ],
                        role: "assistant"
                    )
                ],
                usage: TokenUsage(inputTokens: 50, outputTokens: 25, totalTokens: 75)
            ),
            metadata: ResponseMetadata(
                requestId: "complex_req",
                processingTime: 1.5,
                rateLimit: RateLimitInfo(
                    remaining: 99,
                    resetTime: Date(timeIntervalSince1970: 1700001000),
                    limit: 100
                )
            ),
            statusCode: 200,
            headers: [:]
        )
        
        let key = Data("complex-data-key".utf8)
        
        // Store and retrieve complex data
        await cache.store(response: response, for: key)
        let retrieved: APIResponse<ResponsesResponse>? = await cache.retrieve(for: key, as: ResponsesResponse.self)
        
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.data.id, "resp_complex")
        XCTAssertEqual(retrieved?.data.usage?.totalTokens, 75)
        XCTAssertEqual(retrieved?.metadata.requestId, "complex_req")
        XCTAssertEqual(retrieved?.metadata.rateLimit?.remaining, 99)
    }
}