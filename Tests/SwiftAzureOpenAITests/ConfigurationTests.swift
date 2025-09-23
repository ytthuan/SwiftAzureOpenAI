import XCTest
@testable import SwiftAzureOpenAI

final class ConfigurationTests: XCTestCase {
    func testSAOAIAzureConfigurationBuildsBaseURLAndHeaders() {
        let config = TestEnvironmentHelper.createStandardAzureConfiguration()

        let baseURL = config.baseURL
        XCTAssertEqual(baseURL.scheme, "https")
        
        // Use expected values from environment variables or defaults
        let expectedHost = URL(string: TestEnvironmentHelper.azureEndpoint)?.host ?? "192.0.2.1"
        XCTAssertEqual(baseURL.host, expectedHost)
        XCTAssertEqual(baseURL.path, "/openai/v1/responses")

        // Test that URL is constructed correctly (v1 API needs api-version query parameter)
        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let apiVersion = components?.queryItems?.first(where: { $0.name == "api-version" })?.value
        XCTAssertEqual(apiVersion, TestEnvironmentHelper.azureAPIVersion, "v1 Response API should include api-version query parameter")

        XCTAssertEqual(config.headers["api-key"], TestEnvironmentHelper.azureAPIKey)
        XCTAssertEqual(config.headers["Content-Type"], "application/json")
    }

    func testSAOAIAzureConfigurationDefaultAPIVersion() {
        let config = TestEnvironmentHelper.createAzureConfiguration(
            apiVersion: nil  // Test default API version
        )

        // Test that default configuration includes api-version query parameter in v1 API
        let components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false)
        let apiVersion = components?.queryItems?.first(where: { $0.name == "api-version" })?.value
        XCTAssertEqual(apiVersion, TestEnvironmentHelper.azureAPIVersion, "v1 Response API should include api-version query parameter")
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