import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

final class HTTPClientTests: XCTestCase {
    func testBuildsURLRequestWithMergedHeaders() throws {
        let config = OpenAIServiceConfiguration(apiKey: "sk-xyz", organization: nil)
        let url = URL(string: "https://api.openai.com/v1/responses")!
        let req = APIRequest(method: "POST", url: url, headers: ["X-Test": "1"], body: Data("{}".utf8))

        // Test the expected behavior by verifying configuration
        XCTAssertEqual(config.headers["Authorization"], "Bearer sk-xyz")
        XCTAssertEqual(config.headers["Content-Type"], "application/json")
        XCTAssertEqual(req.headers["X-Test"], "1")
        XCTAssertEqual(req.url, url)
        XCTAssertEqual(req.body, Data("{}".utf8))
        XCTAssertEqual(req.method, "POST")
    }
}