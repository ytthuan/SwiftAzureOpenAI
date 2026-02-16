#!/usr/bin/env swift

/*
 * CustomBaseURLExample.swift
 * SwiftAzureOpenAI
 *
 * Example demonstrating how to use custom base URLs with SwiftAzureOpenAI.
 * This feature allows you to:
 * - Use proxy servers
 * - Connect to Azure OpenAI compatibility endpoints
 * - Use custom OpenAI-compatible API servers
 * - Test with mock servers
 *
 * Similar to the Python OpenAI SDK's base_url parameter:
 * client = OpenAI(api_key="...", base_url="https://custom.example.com/v1")
 */

import Foundation
import SwiftAzureOpenAI

@main
struct CustomBaseURLExample {
    static func main() async {
        print("🔧 SwiftAzureOpenAI - Custom Base URL Examples")
        print("=" .repeating(50))
        print()

        // Example 1: Default OpenAI endpoint (no custom base URL)
        print("1️⃣ Default OpenAI Endpoint")
        print("-" .repeating(50))
        let defaultConfig = SAOAIOpenAIConfiguration(
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-api-key"
        )
        print("   Base URL: \(defaultConfig.baseURL.absoluteString)")
        print("   Headers: \(defaultConfig.headers)")
        print()

        // Example 2: Custom proxy server
        print("2️⃣ Custom Proxy Server")
        print("-" .repeating(50))
        if let proxyURL = URL(string: "https://proxy.company.com/openai/v1/responses") {
            let proxyConfig = SAOAIOpenAIConfiguration(
                apiKey: "sk-proxy-key",
                baseURL: proxyURL
            )
            print("   Base URL: \(proxyConfig.baseURL.absoluteString)")
            print("   Use case: Corporate proxy, rate limiting, monitoring")
        }
        print()

        // Example 3: Azure OpenAI compatibility endpoint
        print("3️⃣ Azure OpenAI Compatibility Endpoint")
        print("-" .repeating(50))
        if let azureURL = URL(string: "https://your-resource.openai.azure.com/openai/deployments/gpt-4/responses") {
            let azureCompatConfig = SAOAIOpenAIConfiguration(
                apiKey: "your-azure-key",
                baseURL: azureURL
            )
            print("   Base URL: \(azureCompatConfig.baseURL.absoluteString)")
            print("   Use case: Azure OpenAI with OpenAI SDK format")
            print("   Note: You may still need to add api-version as query parameter")
        }
        print()

        // Example 4: Local mock server for testing
        print("4️⃣ Local Mock Server (Testing)")
        print("-" .repeating(50))
        if let mockURL = URL(string: "http://localhost:8080/v1/responses") {
            let mockConfig = SAOAIOpenAIConfiguration(
                apiKey: "test-key",
                baseURL: mockURL
            )
            print("   Base URL: \(mockConfig.baseURL.absoluteString)")
            print("   Use case: Integration testing, development")
        }
        print()

        // Example 5: Custom OpenAI-compatible API
        print("5️⃣ Custom OpenAI-Compatible API")
        print("-" .repeating(50))
        if let customURL = URL(string: "https://api.custom-llm.com/v1/responses") {
            let customConfig = SAOAIOpenAIConfiguration(
                apiKey: "custom-api-key",
                organization: "org-custom",
                baseURL: customURL
            )
            print("   Base URL: \(customConfig.baseURL.absoluteString)")
            print("   Headers: \(customConfig.headers)")
            print("   Use case: Alternative LLM providers with OpenAI-compatible APIs")
        }
        print()

        // Example 6: Using the configuration with a client
        print("6️⃣ Practical Usage with Client")
        print("-" .repeating(50))

        // Check if we have a real API key
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !apiKey.isEmpty {
            let config = SAOAIOpenAIConfiguration(apiKey: apiKey)
            let client = SAOAIClient(configuration: config)

            print("   ✅ Client created with configuration")
            print("   Endpoint: \(config.baseURL.absoluteString)")
            print()
            print("   You can now use client.responses.create() to make requests")
            print("   All requests will use the configured base URL")
        } else {
            print("   ℹ️  Set OPENAI_API_KEY to test with real API")
            print("   Example: export OPENAI_API_KEY='your-key'")
        }
        print()

        print("=" .repeating(50))
        print("✨ Custom base URL support is compatible with OpenAI Python SDK")
        print("   Python: OpenAI(api_key='...', base_url='...')")
        print("   Swift:  SAOAIOpenAIConfiguration(apiKey: '...', baseURL: URL(...))")
    }
}
