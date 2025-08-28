import XCTest
@testable import SwiftAzureOpenAI

final class SAOAIErrorTests: XCTestCase {
    func testFromStatusCodeMapping() {
        XCTAssertEqual(SAOAIError.from(statusCode: 401), .invalidAPIKey)
        XCTAssertEqual(SAOAIError.from(statusCode: 429), .rateLimitExceeded)
        if case let .serverError(code)? = SAOAIError.from(statusCode: 500) { XCTAssertEqual(code, 500) } else { XCTFail("Expected serverError") }
        XCTAssertNil(SAOAIError.from(statusCode: 204))
    }

    func testErrorDescriptions() {
        XCTAssertEqual(SAOAIError.invalidAPIKey.errorDescription, "The provided API key is invalid.")
        XCTAssertEqual(SAOAIError.rateLimitExceeded.errorDescription, "Rate limit exceeded. Please try again later.")
        XCTAssertEqual(SAOAIError.invalidRequest("bad").errorDescription, "Invalid request: bad")
        let network = SAOAIError.networkError(URLError(.notConnectedToInternet))
        XCTAssertTrue(network.errorDescription?.contains("Network error:") == true)
        let decoding = SAOAIError.decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "")))
        XCTAssertTrue(decoding.errorDescription?.contains("Failed to decode response:") == true)
        let api = SAOAIError.apiError(ErrorResponse(error: .init(message: "msg", type: nil, code: nil, param: nil)))
        XCTAssertEqual(api.errorDescription, "msg")
    }
}