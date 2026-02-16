import XCTest
@testable import SwiftAzureOpenAI

final class ConfigurationTests: XCTestCase {
    func testSAOAIOpenAIConfigurationBuildsBaseURLAndHeaders() {
        let config = TestEnvironmentHelper.createStandardOpenAIConfiguration()

        let baseURL = config.baseURL
        XCTAssertEqual(baseURL.scheme, "https")
        XCTAssertEqual(baseURL.host, "api.openai.com")
        XCTAssertEqual(baseURL.path, "/v1/responses")

        XCTAssertEqual(config.headers["Authorization"], "Bearer \(TestEnvironmentHelper.openAIAPIKey)")
        XCTAssertEqual(config.headers["Content-Type"], "application/json")
    }

    func testSAOAIOpenAIConfigurationWithOrganization() {
        let config = SAOAIOpenAIConfiguration(apiKey: "sk-123", organization: "org_abc")
        XCTAssertEqual(config.baseURL.absoluteString, "https://api.openai.com/v1/responses")

        let headers = config.headers
        XCTAssertEqual(headers["Authorization"], "Bearer sk-123")
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertEqual(headers["OpenAI-Organization"], "org_abc")
    }

    func testSAOAIOpenAIConfigurationWithoutOrganization() {
        let config = SAOAIOpenAIConfiguration(apiKey: "sk-456")
        XCTAssertEqual(config.baseURL.absoluteString, "https://api.openai.com/v1/responses")

        let headers = config.headers
        XCTAssertEqual(headers["Authorization"], "Bearer sk-456")
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertNil(headers["OpenAI-Organization"])
    }

    func testSAOAIOpenAIConfigurationWithCustomBaseURL() {
        let customURL = URL(string: "https://custom-proxy.example.com/v1/responses")!
        let config = SAOAIOpenAIConfiguration(
            apiKey: "sk-789",
            baseURL: customURL
        )

        XCTAssertEqual(config.baseURL.absoluteString, "https://custom-proxy.example.com/v1/responses")
        XCTAssertEqual(config.baseURL.scheme, "https")
        XCTAssertEqual(config.baseURL.host, "custom-proxy.example.com")
        XCTAssertEqual(config.baseURL.path, "/v1/responses")

        // Headers should still work correctly with custom base URL
        let headers = config.headers
        XCTAssertEqual(headers["Authorization"], "Bearer sk-789")
        XCTAssertEqual(headers["Content-Type"], "application/json")
    }

    func testSAOAIOpenAIConfigurationWithCustomBaseURLAndOrganization() {
        let customURL = URL(string: "https://azure-compatible.example.com/openai/deployments/gpt-4/responses")!
        let config = SAOAIOpenAIConfiguration(
            apiKey: "sk-custom",
            organization: "org_custom",
            baseURL: customURL
        )

        XCTAssertEqual(config.baseURL.absoluteString, "https://azure-compatible.example.com/openai/deployments/gpt-4/responses")

        // Both custom URL and organization should work together
        let headers = config.headers
        XCTAssertEqual(headers["Authorization"], "Bearer sk-custom")
        XCTAssertEqual(headers["OpenAI-Organization"], "org_custom")
        XCTAssertEqual(headers["Content-Type"], "application/json")
    }

    func testSAOAIOpenAIConfigurationDefaultBaseURLWhenNilProvided() {
        let config = SAOAIOpenAIConfiguration(
            apiKey: "sk-default",
            baseURL: nil
        )

        // Should use default OpenAI URL when nil is explicitly provided
        XCTAssertEqual(config.baseURL.absoluteString, "https://api.openai.com/v1/responses")
    }
}