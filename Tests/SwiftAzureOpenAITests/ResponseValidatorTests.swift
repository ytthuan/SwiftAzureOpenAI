import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

final class ResponseValidatorTests: XCTestCase {
    func testAccepts2xx() throws {
        let validator = DefaultResponseValidator()
        let url = URL(string: "https://example.com")!
        let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
        XCTAssertNoThrow(try validator.validate(resp, data: Data()))
    }

    func testMapsKnownErrors() {
        let validator = DefaultResponseValidator()
        let url = URL(string: "https://example.com")!
        let resp401 = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: [:])!
        XCTAssertThrowsError(try validator.validate(resp401, data: Data())) { error in
            guard case SAOAIError.invalidAPIKey = error else { return XCTFail("Expected invalidAPIKey") }
        }
    }

    func testParsesAPIErrorPayload() {
        let validator = DefaultResponseValidator()
        let url = URL(string: "https://example.com")!
        let payload = ["error": ["message": "bad"]]
        let data = try! JSONSerialization.data(withJSONObject: payload)
        let resp = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: [:])!
        XCTAssertThrowsError(try validator.validate(resp, data: data)) { error in
            guard case SAOAIError.apiError(let err) = error else { return XCTFail("Expected apiError") }
            XCTAssertEqual(err.error.message, "bad")
        }
    }
}