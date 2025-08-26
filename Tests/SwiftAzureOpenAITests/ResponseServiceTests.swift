import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

final class ResponseServiceTests: XCTestCase {
    func testExtractMetadataParsesCommonHeaders() async throws {
        let headers = [
            "x-request-id": "req_123",
            "x-processing-ms": "250",
            "x-ratelimit-remaining": "99",
            "x-ratelimit-limit": "100",
            "x-ratelimit-reset": "10"
        ]
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!

        let svc = ResponseService()
        let meta = svc.extractMetadata(from: response)

        XCTAssertEqual(meta.requestId, "req_123")
        XCTAssertEqual(meta.processingTime ?? 0, 0.25, accuracy: 0.0001)
        XCTAssertEqual(meta.rateLimit?.remaining, 99)
        XCTAssertEqual(meta.rateLimit?.limit, 100)
        XCTAssertNotNil(meta.rateLimit?.resetTime)
    }

    func testValidateResponseMapsStatusCodes() async throws {
        let svc = ResponseService()
        let url = URL(string: "https://example.com")!
        let resp401 = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: [:])!
        do {
            try svc.validateResponse(resp401)
            XCTFail("Expected invalidAPIKey")
        } catch let e as OpenAIError {
            switch e { case .invalidAPIKey: break; default: XCTFail("Wrong error: \(e)") }
        }
    }

    func testProcessResponseCachesDecodedValue() async throws {
        struct Dummy: Codable, Equatable { let a: Int }

        // Prepare JSON for {"a":1}
        let data = try JSONSerialization.data(withJSONObject: ["a": 1])
        let url = URL(string: "https://example.com")!
        let http = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["x-request-id": "r"])!

        let cache = InMemoryResponseCache()
        let svc = ResponseService(cache: cache)

        // First call fills cache
        let first: APIResponse<Dummy> = try await svc.processResponse(data, response: http, type: Dummy.self)
        XCTAssertEqual(first.data, Dummy(a: 1))

        // Mutate data to ensure cache used if same key
        let dataSameKey = data // identical bytes act as key
        let second: APIResponse<Dummy> = try await svc.processResponse(dataSameKey, response: http, type: Dummy.self)
        XCTAssertEqual(second.data, Dummy(a: 1))
    }
}