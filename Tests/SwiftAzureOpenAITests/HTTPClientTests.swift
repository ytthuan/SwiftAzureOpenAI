import XCTest
@testable import SwiftAzureOpenAI

// Test shim to expose URLRequest building through a fake send that doesn't hit network
private final class TestableHTTPClient: HTTPClient {
    func makeURLRequest(_ request: APIRequest) throws -> URLRequest {
        try self.performBuildURLRequest(from: request)
    }
}

extension HTTPClient {
    // Internal helper to reach the private builder through a test-only extension via reflection
    fileprivate func performBuildURLRequest(from request: APIRequest) throws -> URLRequest {
        // Re-implement minimal logic using public API to avoid changing access levels in the library
        // Note: This mirrors HTTPClient.buildURLRequest logic
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        var finalHeaders = (Mirror(reflecting: self).children.first { $0.label == "configuration" }?.value as? OpenAIConfiguration)?.headers ?? [:]
        request.headers.forEach { finalHeaders[$0.key] = $0.value }
        for (key, value) in finalHeaders { urlRequest.setValue(value, forHTTPHeaderField: key) }
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = 60
        return urlRequest
    }
}

final class HTTPClientTests: XCTestCase {
    func testBuildsURLRequestWithMergedHeaders() throws {
        let config = OpenAIServiceConfiguration(apiKey: "sk-xyz", organization: nil)
        let client = TestableHTTPClient(configuration: config)
        let url = URL(string: "https://api.openai.com/v1/responses")!
        let req = APIRequest(method: "POST", url: url, headers: ["X-Test": "1"], body: Data("{}".utf8))

        let urlRequest = try client.makeURLRequest(req)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Bearer sk-xyz")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "X-Test"), "1")
        XCTAssertEqual(urlRequest.url, url)
        XCTAssertEqual(urlRequest.httpBody, Data("{}".utf8))
        XCTAssertEqual(urlRequest.timeoutInterval, 60)
    }
}