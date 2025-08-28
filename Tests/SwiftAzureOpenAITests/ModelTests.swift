import XCTest
@testable import SwiftAzureOpenAI

final class ModelTests: XCTestCase {
    
    // MARK: - APIResponse Tests
    
    func testAPIResponseInitialization() {
        struct TestData: Codable, Equatable {
            let value: String
        }
        
        let testData = TestData(value: "test")
        let metadata = ResponseMetadata(requestId: "123", processingTime: 0.5, rateLimit: nil)
        let response = APIResponse(data: testData, metadata: metadata, statusCode: 200, headers: ["Content-Type": "application/json"])
        
        XCTAssertEqual(response.data.value, "test")
        XCTAssertEqual(response.metadata.requestId, "123")
        XCTAssertEqual(response.metadata.processingTime, 0.5)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.headers["Content-Type"], "application/json")
    }
    
    func testAPIResponseCodable() throws {
        struct TestData: Codable, Equatable {
            let name: String
            let count: Int
        }
        
        let testData = TestData(name: "sample", count: 42)
        let rateLimit = RateLimitInfo(remaining: 10, resetTime: Date(timeIntervalSince1970: 1700000000), limit: 100)
        let metadata = ResponseMetadata(requestId: "req_test", processingTime: 1.2, rateLimit: rateLimit)
        let response = APIResponse(data: testData, metadata: metadata, statusCode: 201, headers: ["X-Custom": "value"])
        
        // Encode
        let encoded = try JSONEncoder().encode(response)
        
        // Decode
        let decoded = try JSONDecoder().decode(APIResponse<TestData>.self, from: encoded)
        
        XCTAssertEqual(decoded.data.name, "sample")
        XCTAssertEqual(decoded.data.count, 42)
        XCTAssertEqual(decoded.metadata.requestId, "req_test")
        XCTAssertEqual(decoded.metadata.processingTime, 1.2)
        XCTAssertEqual(decoded.metadata.rateLimit?.remaining, 10)
        XCTAssertEqual(decoded.statusCode, 201)
        XCTAssertEqual(decoded.headers["X-Custom"], "value")
    }
    
    // MARK: - ErrorResponse Tests
    
    func testErrorResponseDecoding() throws {
        let jsonData = """
        {
            "error": {
                "message": "Invalid API key provided",
                "type": "invalid_request_error",
                "code": "invalid_api_key",
                "param": "api_key"
            }
        }
        """.data(using: .utf8)!
        
        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: jsonData)
        
        XCTAssertEqual(errorResponse.error.message, "Invalid API key provided")
        XCTAssertEqual(errorResponse.error.type, "invalid_request_error")
        XCTAssertEqual(errorResponse.error.code, "invalid_api_key")
        XCTAssertEqual(errorResponse.error.param, "api_key")
    }
    
    func testErrorResponseWithMinimalData() throws {
        let jsonData = """
        {
            "error": {
                "message": "Something went wrong"
            }
        }
        """.data(using: .utf8)!
        
        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: jsonData)
        
        XCTAssertEqual(errorResponse.error.message, "Something went wrong")
        XCTAssertNil(errorResponse.error.type)
        XCTAssertNil(errorResponse.error.code)
        XCTAssertNil(errorResponse.error.param)
    }
    
    // MARK: - RateLimitInfo Tests
    
    func testRateLimitInfoInitialization() {
        let resetDate = Date(timeIntervalSince1970: 1700000000)
        let rateLimit = RateLimitInfo(remaining: 50, resetTime: resetDate, limit: 100)
        
        XCTAssertEqual(rateLimit.remaining, 50)
        XCTAssertEqual(rateLimit.limit, 100)
        XCTAssertEqual(rateLimit.resetTime, resetDate)
    }
    
    func testRateLimitInfoCodable() throws {
        let resetDate = Date(timeIntervalSince1970: 1700001234)
        let rateLimit = RateLimitInfo(remaining: 25, resetTime: resetDate, limit: 200)
        
        // Encode
        let encoded = try JSONEncoder().encode(rateLimit)
        
        // Decode
        let decoded = try JSONDecoder().decode(RateLimitInfo.self, from: encoded)
        
        XCTAssertEqual(decoded.remaining, 25)
        XCTAssertEqual(decoded.limit, 200)
        XCTAssertEqual(decoded.resetTime?.timeIntervalSince1970 ?? 0, 1700001234, accuracy: 0.001)
    }
    
    // MARK: - ResponseMetadata Tests
    
    func testResponseMetadataWithAllFields() {
        let resetDate = Date(timeIntervalSince1970: 1700000000)
        let rateLimit = RateLimitInfo(remaining: 75, resetTime: resetDate, limit: 100)
        let metadata = ResponseMetadata(
            requestId: "req_metadata_test",
            processingTime: 2.5,
            rateLimit: rateLimit
        )
        
        XCTAssertEqual(metadata.requestId, "req_metadata_test")
        XCTAssertEqual(metadata.processingTime, 2.5)
        XCTAssertEqual(metadata.rateLimit?.remaining, 75)
    }
    
    func testResponseMetadataWithMinimalFields() {
        let metadata = ResponseMetadata(
            requestId: "minimal_req",
            processingTime: nil,
            rateLimit: nil
        )
        
        XCTAssertEqual(metadata.requestId, "minimal_req")
        XCTAssertNil(metadata.processingTime)
        XCTAssertNil(metadata.rateLimit)
    }
    
    // MARK: - StreamingResponseChunk Tests
    
    func testStreamingResponseChunkInitialization() {
        struct TestChunk: Codable, Equatable, Sendable {
            let content: String
        }
        
        let chunk = TestChunk(content: "streaming test")
        let streamingChunk = StreamingResponseChunk(chunk: chunk, isComplete: false, sequenceNumber: 5)
        
        XCTAssertEqual(streamingChunk.chunk.content, "streaming test")
        XCTAssertEqual(streamingChunk.isComplete, false)
        XCTAssertEqual(streamingChunk.sequenceNumber, 5)
    }
    
    func testStreamingResponseChunkCodable() throws {
        struct TestChunk: Codable, Equatable, Sendable {
            let id: String
            let data: [String]
        }
        
        let chunk = TestChunk(id: "chunk_123", data: ["item1", "item2"])
        let streamingChunk = StreamingResponseChunk(chunk: chunk, isComplete: true, sequenceNumber: 10)
        
        // Encode
        let encoded = try JSONEncoder().encode(streamingChunk)
        
        // Decode
        let decoded = try JSONDecoder().decode(StreamingResponseChunk<TestChunk>.self, from: encoded)
        
        XCTAssertEqual(decoded.chunk.id, "chunk_123")
        XCTAssertEqual(decoded.chunk.data, ["item1", "item2"])
        XCTAssertEqual(decoded.isComplete, true)
        XCTAssertEqual(decoded.sequenceNumber, 10)
    }
    
    // MARK: - SAOAITokenUsage Tests
    
    func testSAOAITokenUsageInitialization() {
        let usage = SAOAITokenUsage(inputTokens: 100, outputTokens: 50, totalTokens: 150)
        
        XCTAssertEqual(usage.inputTokens, 100)
        XCTAssertEqual(usage.outputTokens, 50)
        XCTAssertEqual(usage.totalTokens, 150)
    }
    
    func testSAOAITokenUsageCodable() throws {
        let usage = SAOAITokenUsage(inputTokens: 75, outputTokens: 25, totalTokens: 100)
        
        // Encode
        let encoded = try JSONEncoder().encode(usage)
        
        // Decode
        let decoded = try JSONDecoder().decode(SAOAITokenUsage.self, from: encoded)
        
        XCTAssertEqual(decoded.inputTokens, 75)
        XCTAssertEqual(decoded.outputTokens, 25)
        XCTAssertEqual(decoded.totalTokens, 100)
    }
    
    // MARK: - SAOAITool Tests
    
    func testSAOAIToolInitialization() {
        let params: SAOAIJSONValue = .object([
            "type": .string("object"),
            "properties": .object([
                "name": .object([
                    "type": .string("string"),
                    "description": .string("The name parameter")
                ])
            ])
        ])
        
        let tool = SAOAITool(
            type: "function",
            name: "test_function",
            description: "A test function",
            parameters: params
        )
        
        XCTAssertEqual(tool.type, "function")
        XCTAssertEqual(tool.name, "test_function")
        XCTAssertEqual(tool.description, "A test function")
    }
    
    func testSAOAIToolCodable() throws {
        let params: SAOAIJSONValue = .object(["type": .string("object")])
        let tool = SAOAITool(
            type: "function",
            name: "encode_test",
            description: "Encoding test",
            parameters: params
        )
        
        // Encode
        let encoded = try JSONEncoder().encode(tool)
        
        // Decode
        let decoded = try JSONDecoder().decode(SAOAITool.self, from: encoded)
        
        XCTAssertEqual(decoded.type, "function")
        XCTAssertEqual(decoded.name, "encode_test")
        XCTAssertEqual(decoded.description, "Encoding test")
    }
    
    // MARK: - SAOAIReasoning Tests
    
    func testSAOAIReasoningInitialization() {
        let reasoning = SAOAIReasoning(effort: "medium")
        XCTAssertEqual(reasoning.effort, "medium")
    }
    
    func testSAOAIReasoningCodable() throws {
        let reasoning = SAOAIReasoning(effort: "high")
        
        // Encode
        let encoded = try JSONEncoder().encode(reasoning)
        
        // Decode
        let decoded = try JSONDecoder().decode(SAOAIReasoning.self, from: encoded)
        
        XCTAssertEqual(decoded.effort, "high")
    }
    
    func testSAOAIReasoningEquatable() {
        let reasoning1 = SAOAIReasoning(effort: "low")
        let reasoning2 = SAOAIReasoning(effort: "low")
        let reasoning3 = SAOAIReasoning(effort: "medium")
        
        XCTAssertEqual(reasoning1, reasoning2)
        XCTAssertNotEqual(reasoning1, reasoning3)
    }
}