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
}