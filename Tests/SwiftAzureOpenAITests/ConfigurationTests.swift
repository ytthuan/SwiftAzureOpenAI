import XCTest
@testable import SwiftAzureOpenAI

final class ConfigurationTests: XCTestCase {
    func testSAOAIAzureConfigurationBuildsBaseURLAndHeaders() {
        let config = TestEnvironmentHelper.createStandardAzureConfiguration()

        let baseURL = config.baseURL
        XCTAssertEqual(baseURL.scheme, "https")
        
        // Use expected values from environment variables or defaults
        let expectedHost = URL(string: TestEnvironmentHelper.azureEndpoint)?.host ?? "test.openai.azure.com"
        XCTAssertEqual(baseURL.host, expectedHost)
        XCTAssertEqual(baseURL.path, "/openai/v1/responses")

        XCTAssertEqual(config.headers["api-key"], TestEnvironmentHelper.azureAPIKey)
        XCTAssertEqual(config.headers["Content-Type"], "application/json")
    }

    func testSAOAIAzureConfigurationDefaultAPIVersion() {
        let config = TestEnvironmentHelper.createAzureConfiguration(
            apiVersion: nil  // Test default API version
        )

        // Base URL should follow OpenAI-style path without query parameters
        XCTAssertEqual(config.baseURL.path, "/openai/v1/responses")
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
