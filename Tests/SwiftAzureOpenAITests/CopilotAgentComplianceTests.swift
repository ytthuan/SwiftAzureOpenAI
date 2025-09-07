import XCTest
@testable import SwiftAzureOpenAI

/// Tests to validate Copilot agent compliance requirements using environment variables
final class CopilotAgentComplianceTests: XCTestCase {
    
    // MARK: - Environment Variable Mock Configuration Tests
    
    func testStandardMockAzureConfiguration() {
        // Test that the standard mock configuration using environment variables is properly structured
        let config = TestEnvironmentHelper.createStandardAzureConfiguration()
        
        // Validate endpoint  
        XCTAssertEqual(config.baseURL.scheme, "https")
        
        // Use expected values from environment variables or defaults
        let expectedHost = URL(string: TestEnvironmentHelper.azureEndpoint)?.host
        XCTAssertEqual(config.baseURL.host, expectedHost)
        XCTAssertEqual(config.baseURL.path, "/openai/v1/responses")
        
        // Validate API version query parameter
        let components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false)
        let apiVersion = components?.queryItems?.first(where: { $0.name == "api-version" })?.value
        XCTAssertEqual(apiVersion, TestEnvironmentHelper.azureAPIVersion)
        
        // Validate headers
        XCTAssertEqual(config.headers["api-key"], TestEnvironmentHelper.azureAPIKey)
        XCTAssertEqual(config.headers["Content-Type"], "application/json")
    }
    
    func testStandardMockClientInitialization() {
        // Test that client can be initialized with environment variable configuration
        let config = TestEnvironmentHelper.createStandardAzureConfiguration()
        
        let client = SAOAIClient(configuration: config)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.responses)
    }
    
    func testEnvironmentVariablePriorityCompliance() {
        // Test that environment variable priority follows Copilot agent requirements
        
        // Test the actual priority logic implemented in TestEnvironmentHelper
        let currentAPIKey = TestEnvironmentHelper.azureAPIKey
        
        // Verify the key comes from environment variables or defaults appropriately
        XCTAssertNotNil(currentAPIKey, "API key should always be available (from env vars or default)")
        
        // Test the expected priority: AZURE_OPENAI_API_KEY first, then COPILOT_AGENT_AZURE_OPENAI_API_KEY fallback
        let azureKey = ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"]
        let copilotKey = ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"]
        
        if azureKey != nil {
            // If AZURE_OPENAI_API_KEY is set, it should be used
            XCTAssertEqual(currentAPIKey, azureKey, "AZURE_OPENAI_API_KEY should have priority when set")
        } else if copilotKey != nil {
            // If only COPILOT_AGENT_AZURE_OPENAI_API_KEY is set, it should be used as fallback
            XCTAssertEqual(currentAPIKey, copilotKey, "COPILOT_AGENT_AZURE_OPENAI_API_KEY should be used as fallback")
        } else {
            // If neither is set, should use default
            XCTAssertEqual(currentAPIKey, "test-key", "Should use default when no environment variables are set")
        }
    }
    
    func testMockConfigurationConsistency() {
        // Test that various test scenarios use consistent environment variable values
        
        // Create configurations that should match our environment variable standards
        let configVariations = [
            TestEnvironmentHelper.createStandardAzureConfiguration(),
            TestEnvironmentHelper.createAzureConfiguration(apiVersion: "preview")
        ]
        
        for config in configVariations {
            // All should resolve to the same base URL pattern from environment variables
            let expectedHost = URL(string: TestEnvironmentHelper.azureEndpoint)?.host
            XCTAssertEqual(config.baseURL.host, expectedHost)
            XCTAssertEqual(config.headers["api-key"], TestEnvironmentHelper.azureAPIKey)
            
            // All should use environment variable API version or default
            let components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false)
            let apiVersion = components?.queryItems?.first(where: { $0.name == "api-version" })?.value
            XCTAssertEqual(apiVersion, TestEnvironmentHelper.azureAPIVersion)
        }
    }
    
    func testOpenAIMockConfigurationPattern() {
        // Test that OpenAI mock configurations follow expected patterns
        let openAIConfig = SAOAIOpenAIConfiguration(apiKey: "sk-test", organization: nil)
        
        XCTAssertEqual(openAIConfig.baseURL.absoluteString, "https://api.openai.com/v1/responses")
        XCTAssertEqual(openAIConfig.headers["Authorization"], "Bearer sk-test")
        XCTAssertEqual(openAIConfig.headers["Content-Type"], "application/json")
    }
    
    func testCopilotAgentDocumentationCompliance() {
        // Test that the documented patterns match our implementation using environment variables
        
        // This validates that our environment variable configuration matches what's documented
        // for Copilot agent compatibility
        
        let documentedConfig = TestEnvironmentHelper.createStandardAzureConfiguration()
        
        // Validate this matches our environment variable configuration standards
        let expectedHost = URL(string: TestEnvironmentHelper.azureEndpoint)?.host
        XCTAssertEqual(documentedConfig.baseURL.host, expectedHost)
        XCTAssertEqual(documentedConfig.headers["api-key"], TestEnvironmentHelper.azureAPIKey)
        
        let components = URLComponents(url: documentedConfig.baseURL, resolvingAgainstBaseURL: false)
        let apiVersion = components?.queryItems?.first(where: { $0.name == "api-version" })?.value
        XCTAssertEqual(apiVersion, TestEnvironmentHelper.azureAPIVersion)
        
        print("✅ Copilot agent environment variable configuration compliance validated")
        print("   Endpoint: \(documentedConfig.baseURL.absoluteString)")
        print("   API Key: [REDACTED]")
        print("   Deployment: \(TestEnvironmentHelper.azureDeployment)")
        print("   API Version: \(TestEnvironmentHelper.azureAPIVersion)")
    }
}