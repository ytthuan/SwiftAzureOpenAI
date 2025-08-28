import XCTest
@testable import SwiftAzureOpenAI

final class ConfigurationTests: XCTestCase {
    func testSAOAIAzureConfigurationBuildsBaseURLAndHeaders() {
        let config = SAOAIAzureConfiguration(
            endpoint: "https://myresource.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o-mini",
            apiVersion: "preview"
        )

        let baseURL = config.baseURL
        XCTAssertEqual(baseURL.scheme, "https")
        XCTAssertEqual(baseURL.host, "myresource.openai.azure.com")
        XCTAssertEqual(baseURL.path, "/openai/v1/responses")

        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let apiVersion = components?.queryItems?.first(where: { $0.name == "api-version" })?.value
        XCTAssertEqual(apiVersion, "preview")

        XCTAssertEqual(config.headers["api-key"], "test-key")
        XCTAssertEqual(config.headers["Content-Type"], "application/json")
    }

    func testSAOAIAzureConfigurationDefaultAPIVersion() {
        let config = SAOAIAzureConfiguration(
            endpoint: "https://myresource.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o-mini"
        )

        let components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false)
        let apiVersion = components?.queryItems?.first(where: { $0.name == "api-version" })?.value
        XCTAssertEqual(apiVersion, "preview")
    }

    func testSAOAIOpenAIConfigurationHeaders() {
        let config = SAOAIOpenAIConfiguration(apiKey: "sk-123", organization: "org_abc")
        XCTAssertEqual(config.baseURL.absoluteString, "https://api.openai.com/v1/responses")

        let headers = config.headers
        XCTAssertEqual(headers["Authorization"], "Bearer sk-123")
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertEqual(headers["OpenAI-Organization"], "org_abc")
    }
}