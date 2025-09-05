#!/usr/bin/env swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 * RawApiTesting.swift - Direct Azure OpenAI API Testing
 * 
 * This file provides raw API testing functionality that bypasses the SwiftAzureOpenAI SDK
 * and communicates directly with the Azure OpenAI endpoint using only URLSession.
 * 
 * Purpose:
 * - Direct inspection of Azure OpenAI endpoint responses
 * - Verification that the SDK adapts correctly to raw API outputs
 * - Integration validation after bug fixes or feature enhancements
 * 
 * Usage:
 * Set environment variables and run:
 * export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
 * export AZURE_OPENAI_API_KEY="your-api-key"
 * export AZURE_OPENAI_DEPLOYMENT="your-deployment-name"
 * swift RawApiTesting.swift
 */

// MARK: - Environment Configuration

struct EnvironmentConfig {
    let endpoint: String
    let apiKey: String
    let deployment: String
    
    static func fromEnvironment() -> EnvironmentConfig? {
        guard let endpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !endpoint.isEmpty,
              let apiKey = (ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ?? 
                           ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"])?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty,
              let deployment = ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !deployment.isEmpty else {
            return nil
        }
        
        return EnvironmentConfig(endpoint: endpoint, apiKey: apiKey, deployment: deployment)
    }
}

// MARK: - Raw Request/Response Models (minimal, no SDK dependencies)

struct RawMessage: Codable {
    let role: String
    let content: [RawContent]
    
    init(role: String, text: String) {
        self.role = role
        self.content = [RawContent(type: "input_text", text: text)]
    }
}

struct RawContent: Codable {
    let type: String
    let text: String
}

struct RawRequest: Codable {
    let model: String
    let input: [RawMessage]
    let maxOutputTokens: Int?
    let temperature: Double?
    let stream: Bool?
    
    enum CodingKeys: String, CodingKey {
        case model
        case input
        case maxOutputTokens = "max_output_tokens"
        case temperature
        case stream
    }
}

// MARK: - Raw API Testing Functions

func buildSessionUrl(config: EnvironmentConfig) -> URL? {
    var components = URLComponents(string: config.endpoint)
    components?.path = "/openai/v1/responses"
    components?.queryItems = [URLQueryItem(name: "api-version", value: "preview")]
    return components?.url
}

func createRawRequest(deployment: String) -> RawRequest {
    return RawRequest(
        model: deployment,
        input: [
            RawMessage(role: "system", text: "You are a helpful assistant for SDK testing."),
            RawMessage(role: "user", text: "Please respond with 'Raw API test successful!' to verify the connection.")
        ],
        maxOutputTokens: 50,
        temperature: 0.7,
        stream: false
    )
}

func performRawAPICall(sessionUrl: URL, config: EnvironmentConfig) async throws {
    print("🔍 Raw API Testing - Direct Azure OpenAI Call")
    print("==============================================")
    print("📍 Endpoint: \(config.endpoint)")
    print("🎯 Deployment: \(config.deployment)")
    print("🔗 Session URL: \(sessionUrl.absoluteString)")
    print("")
    
    // Create raw request payload
    let rawRequest = createRawRequest(deployment: config.deployment)
    let requestData = try JSONEncoder().encode(rawRequest)
    
    // Create URLRequest using sessionUrl directly
    var urlRequest = URLRequest(url: sessionUrl)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue(config.apiKey, forHTTPHeaderField: "api-key")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = requestData
    
    print("📤 Raw Request Structure:")
    if let requestString = String(data: requestData, encoding: .utf8) {
        print(requestString)
    }
    print("")
    
    // Perform raw URLSession call
    print("🚀 Making direct API call...")
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    // Process raw response
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response type")
        return
    }
    
    print("📊 Raw Response Details:")
    print("   Status Code: \(httpResponse.statusCode)")
    print("   Headers: \(httpResponse.allHeaderFields)")
    print("")
    
    // Output raw response data
    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
    print("📥 Raw Response Body:")
    print(responseString)
    print("")
    
    // Validate response
    if (200...299).contains(httpResponse.statusCode) {
        print("✅ Raw API test successful!")
        print("   Direct Azure OpenAI endpoint communication verified")
        print("   Response contains raw data without SDK processing")
    } else {
        print("❌ Raw API test failed with status \(httpResponse.statusCode)")
        
        // Try to parse error details from raw response
        if let errorData = responseString.data(using: .utf8) {
            do {
                if let errorJSON = try JSONSerialization.jsonObject(with: errorData) as? [String: Any],
                   let error = errorJSON["error"] as? [String: Any] {
                    print("   Error Type: \(error["type"] ?? "unknown")")
                    print("   Error Message: \(error["message"] ?? "unknown")")
                    print("   Error Code: \(error["code"] ?? "unknown")")
                }
            } catch {
                print("   Could not parse error details")
            }
        }
    }
}

func testStreamingRawAPI(sessionUrl: URL, config: EnvironmentConfig) async throws {
    print("\n🌊 Raw Streaming API Testing")
    print("=============================")
    
    let streamingRequest = RawRequest(
        model: config.deployment,
        input: [RawMessage(role: "user", text: "Count from 1 to 3, each number on a new line.")],
        maxOutputTokens: 30,
        temperature: 0.5,
        stream: true
    )
    
    let requestData = try JSONEncoder().encode(streamingRequest)
    
    var urlRequest = URLRequest(url: sessionUrl)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue(config.apiKey, forHTTPHeaderField: "api-key")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = requestData
    
    print("🚀 Making streaming API call...")
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid streaming response type")
        return
    }
    
    print("📊 Streaming Response Status: \(httpResponse.statusCode)")
    
    if (200...299).contains(httpResponse.statusCode) {
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        print("📥 Raw Streaming Data:")
        print(responseString)
        print("\n✅ Raw streaming API test completed!")
        print("   Streaming endpoint communication verified")
    } else {
        print("❌ Streaming API test failed with status \(httpResponse.statusCode)")
    }
}

// MARK: - Main Execution

func runRawApiTesting() async {
        print("🧪 SwiftAzureOpenAI - Raw API Testing Tool")
        print("==========================================")
        print("This tool tests Azure OpenAI endpoints directly without SDK dependencies")
        print("")
        
        // Check environment configuration
        guard let config = EnvironmentConfig.fromEnvironment() else {
            print("❌ Missing required environment variables!")
            print("Please set the following environment variables:")
            print("   AZURE_OPENAI_ENDPOINT=\"https://your-resource.openai.azure.com\"")
            print("   AZURE_OPENAI_API_KEY=\"your-api-key\"")
            print("   AZURE_OPENAI_DEPLOYMENT=\"your-deployment-name\"")
            print("")
            print("Optional: You can also use COPILOT_AGENT_AZURE_OPENAI_API_KEY instead of AZURE_OPENAI_API_KEY")
            return
        }
        
        // Build session URL
        guard let sessionUrl = buildSessionUrl(config: config) else {
            print("❌ Failed to build session URL from endpoint: \(config.endpoint)")
            return
        }
        
        do {
            // Test non-streaming API
            try await performRawAPICall(sessionUrl: sessionUrl, config: config)
            
            // Test streaming API
            try await testStreamingRawAPI(sessionUrl: sessionUrl, config: config)
            
            print("\n🎉 Raw API testing completed successfully!")
            print("The Azure OpenAI endpoint is working correctly with direct URL calls.")
            print("SDK integration can proceed with confidence.")
            
        } catch {
            print("\n❌ Raw API testing failed with error:")
            print("   \(error.localizedDescription)")
            print("\nThis indicates an issue with the Azure OpenAI endpoint configuration")
            print("or network connectivity that should be resolved before SDK integration.")
        }
    }

// Execute the raw API testing
await runRawApiTesting()