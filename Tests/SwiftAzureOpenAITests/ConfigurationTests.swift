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

        // Test that URL is constructed correctly (v1 API doesn't need api-version query parameter)
        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let apiVersion = components?.queryItems?.first(where: { $0.name == "api-version" })?.value
        XCTAssertNil(apiVersion, "v1 API should not include api-version query parameter")

        XCTAssertEqual(config.headers["api-key"], "test-key")
        XCTAssertEqual(config.headers["Content-Type"], "application/json")
    }

    func testSAOAIAzureConfigurationDefaultAPIVersion() {
        let config = SAOAIAzureConfiguration(
            endpoint: "https://myresource.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o-mini"
        )

        // Test that default configuration doesn't include api-version query parameter in v1 API
        let components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false)
        let apiVersion = components?.queryItems?.first(where: { $0.name == "api-version" })?.value
        XCTAssertNil(apiVersion, "v1 API should not include api-version query parameter")
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