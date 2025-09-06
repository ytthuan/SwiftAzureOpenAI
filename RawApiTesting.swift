#!/usr/bin/env swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 * RawApiTesting.swift - Comprehensive Azure OpenAI API Testing & Response Capture
 * 
 * Enhanced testing functionality that captures HTTP response message sample data
 * from real Azure OpenAI endpoints for later reference. Based on latest Microsoft
 * documentation for data structure validation to ensure SDK decodes correctly and safely.
 * 
 * Edge Cases Covered (one file per case):
 * 1. Normal conversation - non streaming → api_response_normal_conversation_non_streaming.json
 * 2. Tool call (function calls) - non streaming → api_response_tool_call_function_non_streaming.json
 * 3. Normal conversation - streaming → api_response_normal_conversation_streaming.json
 * 4. Tool call (function calls) - streaming → api_response_tool_call_function_streaming.json
 * 
 * Purpose:
 * - Direct inspection of Azure OpenAI endpoint responses per Microsoft docs
 * - Capture and save real API response data for SDK validation reference
 * - Validation of tool call data structures per Azure OpenAI API specification
 * - Ensure proper decoding of function call arguments, streaming events, etc.
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
    let tools: [RawTool]?
    
    enum CodingKeys: String, CodingKey {
        case model
        case input
        case maxOutputTokens = "max_output_tokens"
        case temperature
        case stream
        case tools
    }
}

// Tool definition for raw API testing (simplified)
struct RawTool: Codable {
    let type: String
    let name: String?
    let description: String?
    let parameters: RawParameters?
    let container: String? // For code_interpreter tools
    
    init(type: String, name: String? = nil, description: String? = nil, parameters: RawParameters? = nil, container: String? = nil) {
        self.type = type
        self.name = name
        self.description = description
        self.parameters = parameters
        self.container = container
    }
}

// Simplified parameters structure
struct RawParameters: Codable {
    let type: String
    let properties: [String: RawPropertyDefinition]?
    let required: [String]?
}

struct RawPropertyDefinition: Codable {
    let type: String
    let description: String?
    let `enum`: [String]?
}

// Helper to create tools easily
extension RawTool {
    static func function(name: String, description: String, properties: [String: RawPropertyDefinition], required: [String] = []) -> RawTool {
        return RawTool(
            type: "function",
            name: name,
            description: description,
            parameters: RawParameters(
                type: "object",
                properties: properties,
                required: required.isEmpty ? nil : required
            )
        )
    }
    
    static func codeInterpreter() -> RawTool {
        return RawTool(
            type: "code_interpreter",
            name: nil,
            description: nil,
            parameters: nil,
            container: "auto" // Set container directly on tool
        )
    }
}

// Response capture structure
struct ResponseCapture: Codable {
    let testCase: String
    let timestamp: String
    let requestBody: String
    let responseStatus: Int
    let responseHeaders: [String: String]
    let responseBody: String
    let notes: String
}

// File manager for saving responses - one file per case for reference
struct ResponseSaver {
    static func saveResponse(_ capture: ResponseCapture) {
        // Create simple filename without timestamp - one file per case
        let filename = "api_response_\(capture.testCase.replacingOccurrences(of: " ", with: "_")).json"
        let url = URL(fileURLWithPath: filename)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(capture)
            try data.write(to: url)
            print("💾 Response saved to: \(filename)")
        } catch {
            print("❌ Failed to save response: \(error)")
        }
    }
}

// MARK: - Enhanced API Testing Functions with Response Capture

func buildSessionUrl(config: EnvironmentConfig) -> URL? {
    var components = URLComponents(string: config.endpoint)
    components?.path = "/openai/v1/responses"
    components?.queryItems = [URLQueryItem(name: "api-version", value: "preview")]
    return components?.url
}

// Test case 1: Normal conversation - non streaming
func testNormalConversationNonStreaming(sessionUrl: URL, config: EnvironmentConfig) async throws {
    print("🔍 Test Case 1: Normal Conversation - Non Streaming")
    print("=================================================")
    
    let rawRequest = RawRequest(
        model: config.deployment,
        input: [
            RawMessage(role: "system", text: "You are a helpful assistant."),
            RawMessage(role: "user", text: "Hello! Tell me a short joke about programming.")
        ],
        maxOutputTokens: 100,
        temperature: nil, // Remove temperature for gpt-5-nano
        stream: false,
        tools: nil
    )
    
    try await performAPICallAndSave(
        sessionUrl: sessionUrl,
        config: config,
        request: rawRequest,
        testCase: "normal_conversation_non_streaming",
        notes: "Basic conversation without tools or streaming"
    )
}

// Test case 2: Tool call (function call only) - non streaming
func testToolCallNonStreaming(sessionUrl: URL, config: EnvironmentConfig) async throws {
    print("\n🛠️ Test Case 2: Tool Call (Function Call) - Non Streaming")
    print("==========================================================")
    
    let tools = [
        RawTool.function(
            name: "get_weather",
            description: "Get current weather for a location",
            properties: [
                "location": RawPropertyDefinition(
                    type: "string",
                    description: "The city and country, e.g. 'Tokyo, Japan'",
                    enum: nil
                )
            ],
            required: ["location"]
        ),
        RawTool.function(
            name: "calculate_math",
            description: "Perform mathematical calculations",
            properties: [
                "expression": RawPropertyDefinition(
                    type: "string",
                    description: "Mathematical expression to evaluate",
                    enum: nil
                )
            ],
            required: ["expression"]
        )
    ]
    
    let rawRequest = RawRequest(
        model: config.deployment,
        input: [
            RawMessage(role: "system", text: "You are a helpful assistant with access to weather data and calculation capabilities."),
            RawMessage(role: "user", text: "What's the weather in Tokyo? Also calculate 15 * 23.")
        ],
        maxOutputTokens: 200,
        temperature: nil, // Remove temperature for gpt-5-nano
        stream: false,
        tools: tools
    )
    
    try await performAPICallAndSave(
        sessionUrl: sessionUrl,
        config: config,
        request: rawRequest,
        testCase: "tool_call_function_non_streaming",
        notes: "Function calls (weather and math) in non-streaming mode"
    )
}

// Test case 3: Normal conversation - streaming
func testNormalConversationStreaming(sessionUrl: URL, config: EnvironmentConfig) async throws {
    print("\n🌊 Test Case 3: Normal Conversation - Streaming")
    print("===============================================")
    
    let rawRequest = RawRequest(
        model: config.deployment,
        input: [
            RawMessage(role: "system", text: "You are a helpful assistant."),
            RawMessage(role: "user", text: "Tell me a story about a programmer who discovers AI. Keep it short but engaging.")
        ],
        maxOutputTokens: 150,
        temperature: nil, // Remove temperature for gpt-5-nano
        stream: true,
        tools: nil
    )
    
    try await performAPICallAndSave(
        sessionUrl: sessionUrl,
        config: config,
        request: rawRequest,
        testCase: "normal_conversation_streaming",
        notes: "Basic conversation with streaming enabled, no tools"
    )
}

// Test case 4: Tool call (function call only) - streaming
func testToolCallStreaming(sessionUrl: URL, config: EnvironmentConfig) async throws {
    print("\n🛠️🌊 Test Case 4: Tool Call (Function Call) - Streaming")
    print("========================================================")
    
    let tools = [
        RawTool.function(
            name: "calculate_math",
            description: "Perform mathematical calculations",
            properties: [
                "expression": RawPropertyDefinition(
                    type: "string",
                    description: "Mathematical expression to evaluate",
                    enum: nil
                )
            ],
            required: ["expression"]
        ),
        RawTool.function(
            name: "get_current_time",
            description: "Get the current time in a specific timezone",
            properties: [
                "timezone": RawPropertyDefinition(
                    type: "string",
                    description: "Timezone identifier (e.g., 'America/New_York')",
                    enum: nil
                )
            ],
            required: ["timezone"]
        )
    ]
    
    let rawRequest = RawRequest(
        model: config.deployment,
        input: [
            RawMessage(role: "system", text: "You are a helpful assistant with math and time capabilities."),
            RawMessage(role: "user", text: "Calculate the square root of 144, then tell me the current time in Tokyo timezone.")
        ],
        maxOutputTokens: 200,
        temperature: nil, // Remove temperature for gpt-5-nano
        stream: true,
        tools: tools
    )
    
    try await performAPICallAndSave(
        sessionUrl: sessionUrl,
        config: config,
        request: rawRequest,
        testCase: "tool_call_function_streaming",
        notes: "Function calls (math and time) in streaming mode - this tests the challenging scenario of tool calls with streaming"
    )
}

// Generic API call performer with response capture
func performAPICallAndSave(
    sessionUrl: URL,
    config: EnvironmentConfig,
    request: RawRequest,
    testCase: String,
    notes: String
) async throws {
    let requestData = try JSONEncoder().encode(request)
    
    var urlRequest = URLRequest(url: sessionUrl)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue(config.apiKey, forHTTPHeaderField: "api-key")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = requestData
    
    print("📤 Request Details:")
    if let requestString = String(data: requestData, encoding: .utf8) {
        print("   Body: \(requestString)")
    }
    print("   Endpoint: \(sessionUrl.absoluteString)")
    print("")
    
    print("🚀 Making API call...")
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response type")
        return
    }
    
    print("📊 Response Status: \(httpResponse.statusCode)")
    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
    
    // Convert headers to String dictionary
    var headerDict: [String: String] = [:]
    for (key, value) in httpResponse.allHeaderFields {
        if let keyString = key as? String, let valueString = value as? String {
            headerDict[keyString] = valueString
        }
    }
    
    // Create and save response capture
    let capture = ResponseCapture(
        testCase: testCase,
        timestamp: ISO8601DateFormatter().string(from: Date()),
        requestBody: String(data: requestData, encoding: .utf8) ?? "Unable to encode request",
        responseStatus: httpResponse.statusCode,
        responseHeaders: headerDict,
        responseBody: responseString,
        notes: notes
    )
    
    ResponseSaver.saveResponse(capture)
    
    print("📥 Response Body Preview:")
    print(String(responseString.prefix(500)) + (responseString.count > 500 ? "... (truncated)" : ""))
    print("")
    
    if (200...299).contains(httpResponse.statusCode) {
        print("✅ Test case '\(testCase)' successful!")
        
        // Analyze response for key patterns
        if responseString.contains("function_call") {
            print("   🛠️ Function call detected in response")
        }
        if responseString.contains("code_interpreter") {
            print("   💻 Code interpreter detected in response")
        }
        if responseString.contains("data: ") {
            print("   🌊 Streaming format detected")
        }
        if responseString.contains("\"type\":\"response.completed\"") {
            print("   ✅ Response completion event detected")
        }
    } else {
        print("❌ Test case '\(testCase)' failed with status \(httpResponse.statusCode)")
        
        // Try to parse error details
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
    
    print("   Response saved for later reference")
    print("")
}

// MARK: - Main Execution with Comprehensive Testing

func liveAPItest() async {
    print("🧪 SwiftAzureOpenAI - Live API Testing & Response Capture Tool")
    print("==============================================================")
    print("This tool tests Azure OpenAI endpoints directly and captures response data")
    print("aligned with Microsoft documentation for SDK validation and safe decoding.")
    print("Saves one file per edge case for future reference (no duplicates).")
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
    
    print("📍 Configuration Loaded:")
    print("   Endpoint: \(config.endpoint)")
    print("   Deployment: \(config.deployment)")
    print("   API Key: \(String(config.apiKey.prefix(10)))...***")
    print("")
    
    // Build session URL
    guard let sessionUrl = buildSessionUrl(config: config) else {
        print("❌ Failed to build session URL from endpoint: \(config.endpoint)")
        return
    }
    
    print("🔗 Session URL: \(sessionUrl.absoluteString)")
    print("")
    
    do {
        // Execute all test cases
        print("🚀 Starting comprehensive API testing across all edge cases...")
        print("============================================================")
        
        // Test Case 1: Normal conversation - non streaming
        try await testNormalConversationNonStreaming(sessionUrl: sessionUrl, config: config)
        
        // Test Case 2: Tool call (function call + code interpreter) - non streaming
        try await testToolCallNonStreaming(sessionUrl: sessionUrl, config: config)
        
        // Test Case 3: Normal conversation - streaming
        try await testNormalConversationStreaming(sessionUrl: sessionUrl, config: config)
        
        // Test Case 4: Tool call (function call + code interpreter) - streaming
        try await testToolCallStreaming(sessionUrl: sessionUrl, config: config)
        
        print("🎉 Live API testing completed successfully!")
        print("===========================================")
        print("✅ All 4 edge cases tested and response data captured:")
        print("   1. ✅ Normal conversation - non streaming")
        print("   2. ✅ Tool call (function calls) - non streaming")
        print("   3. ✅ Normal conversation - streaming") 
        print("   4. ✅ Tool call (function calls) - streaming")
        print("")
        print("📂 Response files saved (one per case for reference):")
        print("   • api_response_normal_conversation_non_streaming.json")
        print("   • api_response_tool_call_function_non_streaming.json")
        print("   • api_response_normal_conversation_streaming.json")
        print("   • api_response_tool_call_function_streaming.json")
        print("")
        print("💡 These captured responses aligned with Microsoft docs can be used for:")
        print("   • SDK validation and safe decoding verification")
        print("   • Response format analysis per Azure OpenAI API spec")
        print("   • Tool call data structure validation")
        print("   • Streaming vs non-streaming comparison")
        print("   • Function call argument parsing reference")
        
    } catch {
        print("\n❌ Live API testing failed with error:")
        print("   \(error.localizedDescription)")
        print("\nThis indicates an issue with the Azure OpenAI endpoint configuration")
        print("or network connectivity that should be resolved before SDK integration.")
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                print("   • Check internet connectivity")
            case .timedOut:
                print("   • API request timed out - try again")
            case .badURL:
                print("   • Check AZURE_OPENAI_ENDPOINT format")
            default:
                print("   • URL Error: \(urlError.localizedDescription)")
            }
        }
    }
}

// Legacy function for backward compatibility
func runRawApiTesting() async {
    print("⚠️  Note: runRawApiTesting() is deprecated. Use liveAPItest() instead.")
    print("    The new function provides comprehensive testing across all edge cases.")
    print("")
    await liveAPItest()
}

// Execute the live API testing
await liveAPItest()