import XCTest
@testable import SwiftAzureOpenAI

final class ConfigurationTests: XCTestCase {
    func testAzureOpenAIConfigurationBuildsBaseURLAndHeaders() {
        let config = AzureOpenAIConfiguration(
            endpoint: "https://myresource.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o-mini",
            apiVersion: "2024-02-01"
        )

        let baseURL = config.baseURL
        XCTAssertEqual(baseURL.scheme, "https")
        XCTAssertEqual(baseURL.host, "myresource.openai.azure.com")
        XCTAssertEqual(baseURL.path, "/openai/responses")

        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let apiVersion = components?.queryItems?.first(where: { $0.name == "api-version" })?.value
        XCTAssertEqual(apiVersion, "2024-02-01")

        XCTAssertEqual(config.headers["api-key"], "test-key")
        XCTAssertEqual(config.headers["Content-Type"], "application/json")
    }

    func testOpenAIServiceConfigurationHeaders() {
        let config = OpenAIServiceConfiguration(apiKey: "sk-123", organization: "org_abc")
        XCTAssertEqual(config.baseURL.absoluteString, "https://api.openai.com/v1/responses")

        let headers = config.headers
        XCTAssertEqual(headers["Authorization"], "Bearer sk-123")
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertEqual(headers["OpenAI-Organization"], "org_abc")
    }
}