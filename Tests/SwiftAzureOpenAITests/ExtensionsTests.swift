import XCTest
@testable import SwiftAzureOpenAI

final class ExtensionsTests: XCTestCase {
    func testNormalizedHeadersLowercasesAndStringifies() {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "X-Request-Id": "abc",
                "x-RateLimit-Remaining": "42",
                "mixed": NSNumber(value: 123)
            ]
        )!

        let headers = response.normalizedHeaders
        XCTAssertEqual(headers["x-request-id"], "abc")
        XCTAssertEqual(headers["x-ratelimit-remaining"], "42")
        XCTAssertEqual(headers["mixed"], "123")
    }

    func testStringValueForHeader() {
        let dict: [String: Any] = [
            "lower": "value",
            "number": NSNumber(value: 7)
        ]
        XCTAssertEqual(dict.stringValue(forHeader: "lower"), "value")
        XCTAssertNil(dict.stringValue(forHeader: "number"))
    }
}