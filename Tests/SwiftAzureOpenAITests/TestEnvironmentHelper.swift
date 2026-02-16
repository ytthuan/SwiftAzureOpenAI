import Foundation
@testable import SwiftAzureOpenAI

/// Helper for managing test environment configuration consistently across all tests
enum TestEnvironmentHelper {

    // MARK: - Environment Variable Retrieval

    /// Retrieves OpenAI API key from environment variables
    static var openAIAPIKey: String {
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "test-key"
    }

    /// Retrieves OpenAI organization from environment variables (optional)
    static var openAIOrganization: String? {
        ProcessInfo.processInfo.environment["OPENAI_ORGANIZATION"]
    }

    // MARK: - Standard Test Configuration

    /// Creates a standard OpenAI configuration using environment variables
    static func createStandardOpenAIConfiguration() -> SAOAIOpenAIConfiguration {
        return SAOAIOpenAIConfiguration(
            apiKey: openAIAPIKey,
            organization: openAIOrganization
        )
    }

    /// Creates a standard OpenAI configuration with custom parameters, falling back to environment variables
    static func createOpenAIConfiguration(
        apiKey: String? = nil,
        organization: String? = nil
    ) -> SAOAIOpenAIConfiguration {
        return SAOAIOpenAIConfiguration(
            apiKey: apiKey ?? openAIAPIKey,
            organization: organization ?? openAIOrganization
        )
    }

    // MARK: - Debug Information

    /// Prints current environment variable configuration for debugging
    static func printEnvironmentConfiguration() {
        print("🔍 Test Environment Configuration:")
        print("  OPENAI_API_KEY: '\(ProcessInfo.processInfo.environment["OPENAI_API_KEY"]?.isEmpty == false ? "[REDACTED]" : "not set")' -> '[REDACTED]'")
        print("  OPENAI_ORGANIZATION: '\(ProcessInfo.processInfo.environment["OPENAI_ORGANIZATION"] ?? "not set")' -> '\(openAIOrganization ?? "not set")'")
    }
}