import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

final class ResponseIDExtractionTests: XCTestCase {
    
    // MARK: - Response ID from Headers (already tested but included for completeness)
    
    func testResponseIDFromStandardHeaders() {
        let headers = ["x-request-id": "req_header_123"]
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
        
        let service = ResponseService()
        let metadata = service.extractMetadata(from: response)
        
        XCTAssertEqual(metadata.requestId, "req_header_123")
    }
    
    func testResponseIDFromAzureHeaders() {
        let headers = ["x-ms-request-id": "azure_header_456"]
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
        
        let service = ResponseService()
        let metadata = service.extractMetadata(from: response)
        
        XCTAssertEqual(metadata.requestId, "azure_header_456")
    }
    
    // MARK: - Response ID from Response Body
    
    func testResponseIDFromResponseBody() async throws {
        let service = ResponseService()
        
        // Response with ID in body
        let responseData: [String: Any] = [
            "id": "resp_body_789", // This should be accessible from the decoded response
            "model": "gpt-4o-mini",
            "created": 1700000000,
            "output": [
                [
                    "role": "assistant",
                    "content": [
                        [
                            "type": "output_text",
                            "text": "Response with body ID"
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
        // No request ID in headers this time
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
        
        let result: APIResponse<SAOAIResponse> = try await service.processResponse(
            data, 
            response: httpResponse, 
            type: SAOAIResponse.self
        )
        
        // Response ID should be available in the decoded response body
        XCTAssertEqual(result.data.id, "resp_body_789")
        
        // Metadata might not have request ID since it comes from headers
        XCTAssertNil(result.metadata.requestId)
    }
    
    func testResponseIDFromBothHeadersAndBody() async throws {
        let service = ResponseService()
        
        // Response with ID in both headers and body
        let responseData: [String: Any] = [
            "id": "resp_body_999", // Body ID
            "model": "gpt-4o-mini",
            "created": 1700000000,
            "output": [
                [
                    "role": "assistant",
                    "content": [
                        [
                            "type": "output_text",
                            "text": "Response with both IDs"
                        ]
                    ]
                ]
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: responseData)
        let url = URL(string: "https://api.openai.com/v1/responses")!
        let headers = ["x-request-id": "req_header_888"] // Header ID
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
        
        let result: APIResponse<SAOAIResponse> = try await service.processResponse(
            data, 
            response: httpResponse, 
            type: SAOAIResponse.self
        )
        
        // Should have both IDs available
        XCTAssertEqual(result.data.id, "resp_body_999") // Response body ID
        XCTAssertEqual(result.metadata.requestId, "req_header_888") // Request header ID
    }
    
    func testResponseIDExtractionFromDifferentResponseTypes() async throws {
        let service = ResponseService()
        
        // Test with a minimal response structure
        struct MinimalResponse: Codable {
            let id: String
            let status: String
        }
        
        let responseData = [
            "id": "minimal_123",
            "status": "completed"
        ]
        
        let data = try JSONSerialization.data(withJSONObject: responseData)
        let url = URL(string: "https://api.example.com/minimal")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
        
        let result: APIResponse<MinimalResponse> = try await service.processResponse(
            data, 
            response: httpResponse, 
            type: MinimalResponse.self
        )
        
        XCTAssertEqual(result.data.id, "minimal_123")
        XCTAssertEqual(result.data.status, "completed")
    }
    
    func testResponseWithoutIDInBody() async throws {
        let service = ResponseService()
        
        // Response without ID field in body
        struct ResponseWithoutID: Codable {
            let status: String
            let message: String
        }
        
        let responseData: [String: Any] = [
            "status": "success",
            "message": "No ID field here"
        ]
        
        let data = try JSONSerialization.data(withJSONObject: responseData)
        let url = URL(string: "https://api.example.com/no-id")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
        
        let result: APIResponse<ResponseWithoutID> = try await service.processResponse(
            data, 
            response: httpResponse, 
            type: ResponseWithoutID.self
        )
        
        // Should decode successfully even without ID
        XCTAssertEqual(result.data.status, "success")
        XCTAssertEqual(result.data.message, "No ID field here")
        XCTAssertNil(result.metadata.requestId)
    }
    
    func testResponseIDExtractionFromComplexResponse() async throws {
        let service = ResponseService()
        
        // Complex response with nested structures and multiple IDs
        let responseData: [String: Any] = [
            "id": "complex_response_456",
            "model": "gpt-4o-mini",
            "created": 1700000000,
            "output": [
                [
                    "role": "assistant",
                    "content": [
                        [
                            "type": "output_text",
                            "text": "Complex response content"
                        ]
                    ]
                ]
            ],
            "usage": [
                "input_tokens": 25,
                "output_tokens": 15,
                "total_tokens": 40
            ],
            "metadata": [
                "internal_id": "internal_789",
                "processing_id": "proc_321"
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: responseData)
        let url = URL(string: "https://api.openai.com/v1/responses")!
        let headers = [
            "x-request-id": "req_complex_111",
            "x-trace-id": "trace_222"
        ]
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
        
        let result: APIResponse<SAOAIResponse> = try await service.processResponse(
            data, 
            response: httpResponse, 
            type: SAOAIResponse.self
        )
        
        // Main response ID from body
        XCTAssertEqual(result.data.id, "complex_response_456")
        
        // Request ID from headers
        XCTAssertEqual(result.metadata.requestId, "req_complex_111")
        
        // Other response fields
        XCTAssertEqual(result.data.model, "gpt-4o-mini")
        XCTAssertEqual(result.data.usage?.totalTokens, 40)
    }
    
    // MARK: - Edge Cases for ID Extraction
    
    func testResponseIDWithSpecialCharacters() async throws {
        let service = ResponseService()
        
        // IDs with special characters and formats
        let specialIDs = [
            "resp_123-456_abc",
            "req.with.dots",
            "id@with@symbols",
            "id_with_underscores_and_numbers_123",
            "UPPERCASE_ID_456"
        ]
        
        for specialID in specialIDs {
            struct TestResponse: Codable {
                let id: String
            }
            
            let responseData = ["id": specialID]
            let data = try JSONSerialization.data(withJSONObject: responseData)
            let url = URL(string: "https://api.example.com/test")!
            let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
            
            let result: APIResponse<TestResponse> = try await service.processResponse(
                data, 
                response: httpResponse, 
                type: TestResponse.self
            )
            
            XCTAssertEqual(result.data.id, specialID, "Failed for ID: \(specialID)")
        }
    }
    
    func testResponseIDWithEmptyOrNullValues() async throws {
        let service = ResponseService()
        let url = URL(string: "https://api.example.com/test")!
        
        // Test with empty string ID
        struct TestResponse: Codable {
            let id: String
        }
        
        let emptyIDData = ["id": ""]
        let data1 = try JSONSerialization.data(withJSONObject: emptyIDData)
        let httpResponse1 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
        
        let result1: APIResponse<TestResponse> = try await service.processResponse(
            data1, 
            response: httpResponse1, 
            type: TestResponse.self
        )
        
        XCTAssertEqual(result1.data.id, "")
        
        // Test with optional ID that can be null
        struct TestResponseOptional: Codable {
            let id: String?
        }
        
        let nullIDData = ["id": NSNull()]
        let data2 = try JSONSerialization.data(withJSONObject: nullIDData)
        let httpResponse2 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
        
        let result2: APIResponse<TestResponseOptional> = try await service.processResponse(
            data2, 
            response: httpResponse2, 
            type: TestResponseOptional.self
        )
        
        XCTAssertNil(result2.data.id)
    }
}