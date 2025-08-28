import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

final class EdgeCaseTests: XCTestCase {
    
    // MARK: - Configuration Edge Cases
    
    func testAzureConfigurationWithInvalidEndpoint() {
        // Should not crash with malformed endpoint
        let config = SAOAIAzureConfiguration(
            endpoint: "not-a-valid-url",
            apiKey: "test-key",
            deploymentName: "gpt-4o-mini"
        )
        
        // Should still create configuration object
        XCTAssertNotNil(config)
        XCTAssertEqual(config.headers["api-key"], "test-key")
    }
    
    func testAzureConfigurationWithEmptyValues() {
        let config = SAOAIAzureConfiguration(
            endpoint: "",
            apiKey: "",
            deploymentName: ""
        )
        
        XCTAssertEqual(config.headers["api-key"], "")
        XCTAssertNotNil(config.baseURL)
    }
    
    func testSAOAIConfigurationWithEmptyOrganization() {
        let config = SAOAIOpenAIConfiguration(apiKey: "sk-test", organization: "")
        
        // Empty organization should be included in headers
        XCTAssertEqual(config.headers["OpenAI-Organization"], "")
    }
    
    // MARK: - JSON Parsing Edge Cases
    
    func testSAOAIJSONValueWithDeeplyNestedStructure() throws {
        let deepNested: SAOAIJSONValue = .object([
            "level1": .object([
                "level2": .object([
                    "level3": .object([
                        "level4": .array([
                            .string("deep_value"),
                            .number(42),
                            .bool(true),
                            .null
                        ])
                    ])
                ])
            ])
        ])
        
        let encoded = try JSONEncoder().encode(deepNested)
        let decoded = try JSONDecoder().decode(SAOAIJSONValue.self, from: encoded)
        
        XCTAssertEqual(decoded, deepNested)
    }
    
    func testSAOAIJSONValueWithLargeNumbers() throws {
        let largeNumbers: SAOAIJSONValue = .object([
            "large_int": .number(9223372036854774784), // Large number that can be represented as Double
            "large_double": .number(1.7976931348623157e+308), // Close to Double.max
            "small_double": .number(2.2250738585072014e-308) // Close to Double.min
        ])
        
        let encoded = try JSONEncoder().encode(largeNumbers)
        let decoded = try JSONDecoder().decode(SAOAIJSONValue.self, from: encoded)
        
        XCTAssertEqual(decoded, largeNumbers)
    }
    
    func testSAOAIJSONValueWithUnicodeCharacters() throws {
        let unicode: SAOAIJSONValue = .object([
            "emoji": .string("🚀🎉💻"),
            "chinese": .string("你好世界"),
            "arabic": .string("مرحبا بالعالم"),
            "special": .string("\"\\n\\t\\r")
        ])
        
        let encoded = try JSONEncoder().encode(unicode)
        let decoded = try JSONDecoder().decode(SAOAIJSONValue.self, from: encoded)
        
        XCTAssertEqual(decoded, unicode)
    }
    
    func testSAOAIJSONValueWithEmptyStructures() throws {
        let empty: SAOAIJSONValue = .object([
            "empty_object": .object([:]),
            "empty_array": .array([]),
            "empty_string": .string(""),
            "null_value": .null
        ])
        
        let encoded = try JSONEncoder().encode(empty)
        let decoded = try JSONDecoder().decode(SAOAIJSONValue.self, from: encoded)
        
        XCTAssertEqual(decoded, empty)
    }
    
    // MARK: - Error Handling Edge Cases
    
    func testSAOAIErrorWithUnknownStatusCode() {
        // Test boundary cases
        XCTAssertNil(SAOAIError.from(statusCode: 0))
        XCTAssertNil(SAOAIError.from(statusCode: -1))
        XCTAssertNil(SAOAIError.from(statusCode: 999))
        
        // Test exact boundaries
        XCTAssertNil(SAOAIError.from(statusCode: 199))
        XCTAssertNil(SAOAIError.from(statusCode: 300))
        XCTAssertEqual(SAOAIError.from(statusCode: 400), .invalidRequest("Bad Request"))
        XCTAssertEqual(SAOAIError.from(statusCode: 401), .invalidAPIKey)
    }
    
    func testSAOAIErrorDescriptionLengths() {
        // Test very long error messages
        let longMessage = String(repeating: "a", count: 10000)
        let longError = SAOAIError.invalidRequest(longMessage)
        
        XCTAssertTrue(longError.errorDescription?.contains(longMessage) == true)
        
        // Test empty error message
        let emptyError = SAOAIError.invalidRequest("")
        XCTAssertEqual(emptyError.errorDescription, "Invalid request: ")
    }
    
    func testErrorResponseWithMalformedJSON() {
        let validator = DefaultResponseValidator()
        let url = URL(string: "https://example.com")!
        
        // Test with malformed JSON
        let malformedData = Data("{\"error\": {\"message\": \"incomplete".utf8)
        let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: [:])!
        
        XCTAssertThrowsError(try validator.validate(response, data: malformedData)) { error in
            // Should fall back to status code mapping when JSON parsing fails
            guard case SAOAIError.invalidRequest = error else {
                return XCTFail("Expected invalidRequest, got: \(error)")
            }
        }
    }
    
    // MARK: - Response Metadata Edge Cases
    
    func testResponseMetadataWithInvalidHeaders() {
        let headers = [
            "x-request-id": "valid_id",
            "x-processing-ms": "not-a-number", // Invalid processing time
            "x-ratelimit-remaining": "", // Empty rate limit
            "x-ratelimit-limit": "invalid", // Invalid rate limit
            "x-ratelimit-reset": "-1" // Invalid reset time
        ]
        
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
        
        let service = ResponseService()
        let metadata = service.extractMetadata(from: response)
        
        // Should extract valid values and ignore invalid ones
        XCTAssertEqual(metadata.requestId, "valid_id")
        XCTAssertNil(metadata.processingTime) // Should be nil due to invalid value
        XCTAssertNotNil(metadata.rateLimit) // RateLimit object should exist but with nil values
        XCTAssertNil(metadata.rateLimit?.remaining) // Should be nil due to invalid value
        XCTAssertNil(metadata.rateLimit?.limit) // Should be nil due to invalid value
    }
    
    func testResponseMetadataWithMissingHeaders() {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
        
        let service = ResponseService()
        let metadata = service.extractMetadata(from: response)
        
        // Should handle missing headers gracefully
        XCTAssertNil(metadata.requestId)
        XCTAssertNil(metadata.processingTime)
        XCTAssertNotNil(metadata.rateLimit) // RateLimit object should exist but with nil values
        XCTAssertNil(metadata.rateLimit?.remaining)
        XCTAssertNil(metadata.rateLimit?.limit)
        XCTAssertNil(metadata.rateLimit?.resetTime)
    }
    
    func testResponseMetadataWithDifferentRequestIdHeaders() {
        // Test priority: x-request-id should take precedence over x-ms-request-id
        let headers = [
            "x-request-id": "standard_id",
            "x-ms-request-id": "azure_id"
        ]
        
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
        
        let service = ResponseService()
        let metadata = service.extractMetadata(from: response)
        
        // Should prefer x-request-id over x-ms-request-id
        XCTAssertEqual(metadata.requestId, "standard_id")
    }
    
    // MARK: - Streaming Edge Cases
    
    func testStreamingWithEmptyStream() async throws {
        let service = StreamingResponseService()
        
        // Create empty stream
        let emptyStream = AsyncThrowingStream<Data, Error> { continuation in
            continuation.finish()
        }
        
        struct TestType: Codable { let value: String }
        let processedStream = service.processStream(emptyStream, type: TestType.self)
        
        var chunkCount = 0
        for try await _ in processedStream {
            chunkCount += 1
        }
        
        XCTAssertEqual(chunkCount, 0)
    }
    
    func testStreamingWithInvalidJSON() async throws {
        let service = StreamingResponseService()
        
        // Create stream with invalid JSON
        let invalidStream = AsyncThrowingStream<Data, Error> { continuation in
            continuation.yield(Data("invalid json".utf8))
            continuation.finish()
        }
        
        struct TestType: Codable { let value: String }
        let processedStream = service.processStream(invalidStream, type: TestType.self)
        
        do {
            for try await _ in processedStream {
                XCTFail("Should not yield any chunks with invalid JSON")
            }
        } catch {
            // Expected to throw error
            XCTAssertTrue(error is DecodingError || error is SAOAIError)
        }
    }
    
    func testStreamingWithMixedValidInvalidData() async throws {
        let service = StreamingResponseService()
        
        struct TestType: Codable, Equatable { let value: Int }
        
        // Create stream with mix of valid and invalid data
        let mixedStream = AsyncThrowingStream<Data, Error> { continuation in
            // Valid JSON
            continuation.yield(try! JSONEncoder().encode(TestType(value: 1)))
            // Invalid JSON
            continuation.yield(Data("invalid".utf8))
            // Valid JSON again
            continuation.yield(try! JSONEncoder().encode(TestType(value: 2)))
            continuation.finish()
        }
        
        let processedStream = service.processStream(mixedStream, type: TestType.self)
        
        var validChunks: [TestType] = []
        var errorOccurred = false
        
        do {
            for try await chunk in processedStream {
                validChunks.append(chunk.chunk)
            }
        } catch {
            errorOccurred = true
        }
        
        // Should fail on the invalid JSON
        XCTAssertTrue(errorOccurred)
        // Should have processed the first valid chunk before failing
        XCTAssertEqual(validChunks.count, 1)
        XCTAssertEqual(validChunks[0].value, 1)
    }
    
    // MARK: - Cache Edge Cases
    
    func testCacheWithLargeData() async throws {
        let cache = InMemoryResponseCache()
        
        // Create large data structure
        struct LargeData: Codable, Equatable {
            let items: [String]
        }
        
        let largeItems = Array(repeating: "x", count: 10000)
        let largeData = LargeData(items: largeItems)
        let metadata = ResponseMetadata(requestId: "large", processingTime: nil, rateLimit: nil)
        let response = APIResponse(data: largeData, metadata: metadata, statusCode: 200, headers: [:])
        let key = Data("large-key".utf8)
        
        // Should handle large data without issues
        await cache.store(response: response, for: key)
        let retrieved: APIResponse<LargeData>? = await cache.retrieve(for: key, as: LargeData.self)
        
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.data.items.count, 10000)
    }
    
    func testCacheWithIdenticalKeys() async throws {
        let cache = InMemoryResponseCache()
        
        struct TestData: Codable, Equatable {
            let id: String
        }
        
        // Use identical key data for different logical keys
        let keyData = Data("identical".utf8)
        
        let data1 = TestData(id: "first")
        let data2 = TestData(id: "second")
        
        let response1 = APIResponse(data: data1, metadata: ResponseMetadata(requestId: "1", processingTime: nil, rateLimit: nil), statusCode: 200, headers: [:])
        let response2 = APIResponse(data: data2, metadata: ResponseMetadata(requestId: "2", processingTime: nil, rateLimit: nil), statusCode: 200, headers: [:])
        
        // Store both with same key (second should overwrite first)
        await cache.store(response: response1, for: keyData)
        await cache.store(response: response2, for: keyData)
        
        let retrieved: APIResponse<TestData>? = await cache.retrieve(for: keyData, as: TestData.self)
        
        // Should return the last stored value
        XCTAssertEqual(retrieved?.data.id, "second")
    }
}