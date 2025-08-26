import XCTest
@testable import SwiftAzureOpenAI

final class OpenAIErrorTests: XCTestCase {
    func testFromStatusCodeMapping() {
        XCTAssertEqual(OpenAIError.from(statusCode: 401), .invalidAPIKey)
        XCTAssertEqual(OpenAIError.from(statusCode: 429), .rateLimitExceeded)
        if case let .serverError(code)? = OpenAIError.from(statusCode: 500) { XCTAssertEqual(code, 500) } else { XCTFail("Expected serverError") }
        XCTAssertNil(OpenAIError.from(statusCode: 204))
    }

    func testErrorDescriptions() {
        XCTAssertEqual(OpenAIError.invalidAPIKey.errorDescription, "The provided API key is invalid.")
        XCTAssertEqual(OpenAIError.rateLimitExceeded.errorDescription, "Rate limit exceeded. Please try again later.")
        XCTAssertEqual(OpenAIError.invalidRequest("bad").errorDescription, "Invalid request: bad")
        let network = OpenAIError.networkError(URLError(.notConnectedToInternet))
        XCTAssertTrue(network.errorDescription?.contains("Network error:") == true)
        let decoding = OpenAIError.decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "")))
        XCTAssertTrue(decoding.errorDescription?.contains("Failed to decode response:") == true)
        let api = OpenAIError.apiError(ErrorResponse(error: .init(message: "msg", type: nil, code: nil, param: nil)))
        XCTAssertEqual(api.errorDescription, "msg")
    }
}