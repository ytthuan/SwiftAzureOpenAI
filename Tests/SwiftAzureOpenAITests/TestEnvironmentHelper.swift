import Foundation
@testable import SwiftAzureOpenAI

/// Helper for managing test environment configuration consistently across all tests
enum TestEnvironmentHelper {
    
    // MARK: - Environment Variable Retrieval
    
    /// Retrieves Azure OpenAI endpoint from environment variables
    static var azureEndpoint: String {
        ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] ?? "https://192.0.2.1"
    }
    
    /// Retrieves Azure OpenAI API key from environment variables with proper fallback
    /// Priority: AZURE_OPENAI_API_KEY -> COPILOT_AGENT_AZURE_OPENAI_API_KEY -> default
    static var azureAPIKey: String {
        ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ?? 
        ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"] ?? 
        "test-key"
    }
    
    /// Retrieves Azure OpenAI deployment name from environment variables
    static var azureDeployment: String {
        ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? "gpt-4o"
    }
    
    /// Retrieves Azure OpenAI API version from environment variables
    static var azureAPIVersion: String {
        ProcessInfo.processInfo.environment["AZURE_OPENAI_API_VERSION"] ?? "preview"
    }
    
    // MARK: - Standard Test Configuration
    
    /// Creates a standard Azure configuration using environment variables
    static func createStandardAzureConfiguration() -> SAOAIAzureConfiguration {
        return SAOAIAzureConfiguration(
            endpoint: azureEndpoint,
            apiKey: azureAPIKey,
            deploymentName: azureDeployment,
            apiVersion: azureAPIVersion
        )
    }
    
    /// Creates a standard Azure configuration with custom parameters, falling back to environment variables
    static func createAzureConfiguration(
        endpoint: String? = nil,
        apiKey: String? = nil, 
        deploymentName: String? = nil,
        apiVersion: String? = nil
    ) -> SAOAIAzureConfiguration {
        return SAOAIAzureConfiguration(
            endpoint: endpoint ?? azureEndpoint,
            apiKey: apiKey ?? azureAPIKey,
            deploymentName: deploymentName ?? azureDeployment,
            apiVersion: apiVersion ?? azureAPIVersion
        )
    }
    
    // MARK: - Debug Information
    
    /// Prints current environment variable configuration for debugging
    static func printEnvironmentConfiguration() {
        print("🔍 Test Environment Configuration:")
        print("  AZURE_OPENAI_ENDPOINT: '\(ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] ?? "not set")' -> '\(azureEndpoint)'")
        print("  AZURE_OPENAI_API_KEY: '\(ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"]?.isEmpty == false ? "[REDACTED]" : "not set")' -> '[REDACTED]'")
        print("  COPILOT_AGENT_AZURE_OPENAI_API_KEY: '\(ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"]?.isEmpty == false ? "[REDACTED]" : "not set")' -> '[REDACTED]'")
        print("  AZURE_OPENAI_DEPLOYMENT: '\(ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? "not set")' -> '\(azureDeployment)'")
        print("  AZURE_OPENAI_API_VERSION: '\(ProcessInfo.processInfo.environment["AZURE_OPENAI_API_VERSION"] ?? "not set")' -> '\(azureAPIVersion)'")
    }
}