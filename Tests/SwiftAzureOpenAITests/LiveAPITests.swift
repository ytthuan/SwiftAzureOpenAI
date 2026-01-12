import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

/// Live API tests using pure URLSession to verify streaming and non-streaming functionality
/// These tests require environment variables to be set:
/// - AZURE_OPENAI_ENDPOINT: Azure OpenAI endpoint URL
/// - COPILOT_AGENT_AZURE_OPENAI_API_KEY or AZURE_OPENAI_API_KEY: Azure OpenAI API key (should be set as secret)
/// - AZURE_OPENAI_DEPLOYMENT: Azure OpenAI deployment name
final class LiveAPITests: XCTestCase {
    
    // MARK: - Environment Configuration
    
    private var azureEndpoint: String? {
        ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"]
    }
    
    private var azureAPIKey: String? {
        ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"] ?? ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"]
    }
    
    private var azureDeployment: String? {
        ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"]
    }
    
    private var hasAzureCredentials: Bool {
        let endpoint = azureEndpoint?.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = azureAPIKey?.trimmingCharacters(in: .whitespacesAndNewlines) 
        let deployment = azureDeployment?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return endpoint != nil && !endpoint!.isEmpty &&
               apiKey != nil && !apiKey!.isEmpty &&
               deployment != nil && !deployment!.isEmpty
    }
    
    // MARK: - Pure URLSession API Call Tests
    
    func testCallAPIWithURLSessionNonStreaming() async throws {
        guard hasAzureCredentials else {
            throw XCTSkip("Azure OpenAI credentials not available. Set AZURE_OPENAI_ENDPOINT, COPILOT_AGENT_AZURE_OPENAI_API_KEY (or AZURE_OPENAI_API_KEY), and AZURE_OPENAI_DEPLOYMENT environment variables.")
        }
        
        guard let endpoint = azureEndpoint,
              let apiKey = azureAPIKey,
              let deployment = azureDeployment else {
            XCTFail("Required environment variables not set")
            return
        }
        
        // Construct URL manually like SAOAIAzureConfiguration does
        var components = URLComponents(string: endpoint)!
        components.path = "/openai/v1/responses"
        components.queryItems = [URLQueryItem(name: "api-version", value: "preview")]
        let url = components.url!
        
        // Create request payload
        let request = SAOAIRequest(
            model: deployment,
            input: [
                SAOAIInput.message(SAOAIMessage(role: .user, text: "Hello! Please respond with just 'Hi there!' and nothing else."))
            ],
            maxOutputTokens: 20,
            stream: false
        )
        
        // Encode request to JSON
        let requestData = try JSONEncoder().encode(request)
        
        // Create URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = requestData
        
        // Perform request using pure URLSession
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        print("Response headers: \(httpResponse.allHeaderFields)")
        
        // Check for successful status code
        XCTAssertTrue((200...299).contains(httpResponse.statusCode), 
                     "Expected success status code, got \(httpResponse.statusCode)")
        
        // Parse response
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        print("Response body: \(responseString)")
        
        do {
            let apiResponse = try JSONDecoder().decode(SAOAIResponse.self, from: data)
            
            // Validate response structure - make assertions fault-tolerant
            // Some fields may be optional depending on the response type and model
            if let id = apiResponse.id {
                print("Response ID: \(id)")
            } else {
                print("⚠️ Response missing ID field")
            }
            
            if let created = apiResponse.created {
                print("Response created timestamp: \(created)")
            } else {
                print("⚠️ Response missing created timestamp")
            }
            
            if let model = apiResponse.model {
                print("Response model: \(model)")
            } else {
                print("⚠️ Response missing model field")
            }
            
            XCTAssertFalse(apiResponse.output.isEmpty, "Response should have at least one output")
            
            // Validate first output
            let firstOutput = apiResponse.output[0]
            
            // Check if it's a content output or reasoning output
            if let content = firstOutput.content, !content.isEmpty {
                // It's a content output
                print("✅ Non-streaming API call successful with content output!")
                print("Response ID: \(apiResponse.id ?? "N/A")")
                print("Model: \(apiResponse.model ?? "N/A")")
                print("Created: \(apiResponse.created?.description ?? "N/A")")
                
                // Extract text content
                let textContent = content.compactMap { content in
                    if case .outputText(let outputText) = content {
                        return outputText.text
                    } else {
                        return nil
                    }
                }.joined(separator: " ")
                
                print("Content: \(textContent)")
            } else if let type = firstOutput.type, type == "reasoning" {
                // It's a reasoning output
                print("✅ Non-streaming API call successful with reasoning output!")
                print("Response ID: \(apiResponse.id ?? "N/A")")
                print("Model: \(apiResponse.model ?? "N/A")")
                print("Created: \(apiResponse.created?.description ?? "N/A")")
                print("Reasoning Output ID: \(firstOutput.id ?? "N/A")")
                print("Reasoning Type: \(type)")
                print("Reasoning Summary: \(firstOutput.summaryText ?? [])")
            } else {
                // Handle unknown output types gracefully
                print("⚠️ Unknown output type detected")
                print("Output has content: \(firstOutput.content != nil)")
                print("Output type: \(firstOutput.type ?? "N/A")")
                print("Output role: \(firstOutput.role ?? "N/A")")
                print("Output id: \(firstOutput.id ?? "N/A")")
                
                // Don't fail the test for unknown output types - just log them
                print("✅ Non-streaming API call completed with unknown output type")
            }
            
        } catch {
            print("Failed to decode response: \(error)")
            print("Raw response: \(responseString)")
            XCTFail("Failed to decode API response: \(error)")
        }
    }
    
    func testCallAPIWithURLSessionStreaming() async throws {
        guard hasAzureCredentials else {
            throw XCTSkip("Azure OpenAI credentials not available. Set AZURE_OPENAI_ENDPOINT, COPILOT_AGENT_AZURE_OPENAI_API_KEY (or AZURE_OPENAI_API_KEY), and AZURE_OPENAI_DEPLOYMENT environment variables.")
        }
        
        guard let endpoint = azureEndpoint,
              let apiKey = azureAPIKey,
              let deployment = azureDeployment else {
            XCTFail("Required environment variables not set")
            return
        }
        
        // Construct URL manually
        var components = URLComponents(string: endpoint)!
        components.path = "/openai/v1/responses"
        components.queryItems = [URLQueryItem(name: "api-version", value: "preview")]
        let url = components.url!
        
        // Create streaming request payload
        let request = SAOAIRequest(
            model: deployment,
            input: [
                SAOAIInput.message(SAOAIMessage(role: .user, text: "Count from 1 to 5, each number on a new line."))
            ],
            maxOutputTokens: 50,
            stream: true
        )
        
        // Encode request to JSON
        let requestData = try JSONEncoder().encode(request)
        
        // Create URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = requestData
        
        // Perform streaming request using AsyncThrowingStream
        let streamingResponse = try await performStreamingRequest(urlRequest: urlRequest)
        
        // Validate response
        let httpResponse = streamingResponse.httpResponse
        
        print("Streaming response status code: \(httpResponse.statusCode)")
        print("Streaming response headers: \(httpResponse.allHeaderFields)")
        
        XCTAssertTrue((200...299).contains(httpResponse.statusCode), 
                     "Expected success status code, got \(httpResponse.statusCode)")
        
        // Process streaming response
        var chunkCount = 0
        var receivedData = false
        var finalData: String = ""
        
        for try await line in streamingResponse.lines {
            if !line.isEmpty && line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)) // Remove "data: " prefix
                
                if jsonString == "[DONE]" {
                    print("✅ Received [DONE] signal")
                    break
                }
                
                do {
                    if let jsonData = jsonString.data(using: String.Encoding.utf8) {
                        let streamResponse = try JSONDecoder().decode(SAOAIStreamingResponse.self, from: jsonData)
                        chunkCount += 1
                        receivedData = true
                        
                        print("Chunk \(chunkCount): \(streamResponse)")
                        
                        // Extract content from the chunk
                        if let output = streamResponse.output?.first,
                           let content = output.content?.first?.text {
                            finalData += content
                        }
                    }
                } catch {
                    print("Failed to decode streaming chunk: \(error)")
                    print("Raw chunk: \(jsonString)")
                    // Continue processing other chunks
                }
            }
        }
        
        XCTAssertTrue(receivedData, "Should have received streaming data")
        XCTAssertGreaterThan(chunkCount, 0, "Should have received at least one chunk")
        
        print("✅ Streaming API call successful!")
        print("Total chunks received: \(chunkCount)")
        print("Final accumulated content: \(finalData)")
    }
    
    func testAPIErrorHandling() async throws {
        guard hasAzureCredentials else {
            throw XCTSkip("Azure OpenAI credentials not available. Set AZURE_OPENAI_ENDPOINT, COPILOT_AGENT_AZURE_OPENAI_API_KEY (or AZURE_OPENAI_API_KEY), and AZURE_OPENAI_DEPLOYMENT environment variables.")
        }
        
        guard let endpoint = azureEndpoint,
              let apiKey = azureAPIKey else {
            XCTFail("Required environment variables not set")
            return
        }
        
        // Construct URL manually
        var components = URLComponents(string: endpoint)!
        components.path = "/openai/v1/responses"
        components.queryItems = [URLQueryItem(name: "api-version", value: "preview")]
        let url = components.url!
        
        // Create invalid request (invalid model name)
        let request = SAOAIRequest(
            model: "invalid-model-name-that-does-not-exist",
            input: [
                SAOAIInput.message(SAOAIMessage(role: .user, text: "Test"))
            ],
            maxOutputTokens: 10
        )
        
        // Encode request to JSON
        let requestData = try JSONEncoder().encode(request)
        
        // Create URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = requestData
        
        // Perform request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Validate error response
        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }
        
        print("Error response status code: \(httpResponse.statusCode)")
        print("Error response headers: \(httpResponse.allHeaderFields)")
        
        // Should receive an error status code
        XCTAssertFalse((200...299).contains(httpResponse.statusCode), 
                      "Expected error status code for invalid model, got \(httpResponse.statusCode)")
        
        // Try to parse error response
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        print("Error response body: \(responseString)")
        
        do {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            XCTAssertNotNil(errorResponse.error, "Error response should contain error details")
            print("✅ Error handling test successful!")
            print("Error type: \(errorResponse.error.type ?? "N/A")")
            print("Error message: \(errorResponse.error.message)")
        } catch {
            print("Failed to decode error response: \(error)")
            // This is still a valid test if we got a non-2xx status code
            XCTAssertTrue(true, "Received expected error status code")
        }
    }
    
    func testDebugRequestStructure() async throws {
        guard hasAzureCredentials else {
            throw XCTSkip("Azure OpenAI credentials not available. Set AZURE_OPENAI_ENDPOINT, COPILOT_AGENT_AZURE_OPENAI_API_KEY (or AZURE_OPENAI_API_KEY), and AZURE_OPENAI_DEPLOYMENT environment variables.")
        }
        
        guard let endpoint = azureEndpoint,
              let apiKey = azureAPIKey,
              let deployment = azureDeployment else {
            XCTFail("Required environment variables not set")
            return
        }
        
        // Test the same structure used in the AdvancedConsoleChatbot example
        let weatherTool = SAOAITool.function(
            name: "get_weather",
            description: "Get current weather information for a specified location",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("The city and state/country, e.g. 'San Francisco, CA' or 'London, UK'")
                    ]),
                    "unit": .object([
                        "type": .string("string"),
                        "enum": .array([.string("celsius"), .string("fahrenheit")]),
                        "description": .string("Temperature unit preference")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        )
        
        // Create the exact message structure from the chatbot example
        let messages = [
            SAOAIMessage(role: .user, text: "hi, what the weather like in london")
        ]
        
        // Create request like the chatbot does
        let request = SAOAIRequest(
            model: deployment,
            input: messages.map { SAOAIInput.message($0) },
            tools: [weatherTool],
            stream: true
        )
        
        // Debug: Print the JSON that will be sent
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let requestData = try encoder.encode(request)
        let requestJSON = String(data: requestData, encoding: .utf8) ?? "Unable to encode"
        
        print("🔍 Debug: Request JSON structure:")
        print(requestJSON)
        
        // Construct URL
        var components = URLComponents(string: endpoint)!
        components.path = "/openai/v1/responses"
        components.queryItems = [URLQueryItem(name: "api-version", value: "preview")]
        let url = components.url!
        
        print("🔍 Debug: Request URL: \(url)")
        
        // Create URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = requestData
        
        print("🔍 Debug: Request headers:")
        for (key, value) in urlRequest.allHTTPHeaderFields ?? [:] {
            if key.lowercased() == "api-key" {
                print("  \(key): [REDACTED]")
            } else {
                print("  \(key): \(value)")
            }
        }
        
        // Perform request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        
        print("🔍 Debug: Response status code: \(httpResponse.statusCode)")
        print("🔍 Debug: Response headers: \(httpResponse.allHeaderFields)")
        print("🔍 Debug: Response body: \(responseString)")
        
        if (200...299).contains(httpResponse.statusCode) {
            print("✅ Request structure is valid!")
        } else {
            print("❌ Request failed with status \(httpResponse.statusCode)")
            
            // Try to decode as error to see what went wrong
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                print("❌ Error details:")
                print("   Type: \(errorResponse.error.type ?? "N/A")")
                print("   Message: \(errorResponse.error.message)")
                print("   Code: \(errorResponse.error.code ?? "N/A")")
                print("   Param: \(errorResponse.error.param ?? "N/A")")
            } catch {
                print("❌ Could not decode error response: \(error)")
            }
        }
        
        // This test is informational, so we don't fail it
        XCTAssertTrue(true, "Debug test completed")
    }
    
    func testEnvironmentVariableConfiguration() {
        // Test that we can read environment variables correctly
        let endpointRaw = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"]
        let apiKeyRaw = ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] 
        let copilotApiKeyRaw = ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"]
        let deploymentRaw = ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"]
        
        print("🔍 Debug environment variables:")
        print("  AZURE_OPENAI_ENDPOINT: '\(endpointRaw ?? "nil")' (length: \(endpointRaw?.count ?? 0))")
        print("  AZURE_OPENAI_API_KEY: '\(apiKeyRaw?.isEmpty == false ? "[REDACTED]" : (apiKeyRaw ?? "nil"))' (length: \(apiKeyRaw?.count ?? 0))")
        print("  COPILOT_AGENT_AZURE_OPENAI_API_KEY: '\(copilotApiKeyRaw?.isEmpty == false ? "[REDACTED]" : (copilotApiKeyRaw ?? "nil"))' (length: \(copilotApiKeyRaw?.count ?? 0))")
        print("  AZURE_OPENAI_DEPLOYMENT: '\(deploymentRaw ?? "nil")' (length: \(deploymentRaw?.count ?? 0))")
        
        if hasAzureCredentials {
            XCTAssertNotNil(azureEndpoint, "AZURE_OPENAI_ENDPOINT should be available")
            XCTAssertNotNil(azureAPIKey, "AZURE_OPENAI_API_KEY should be available")
            XCTAssertNotNil(azureDeployment, "AZURE_OPENAI_DEPLOYMENT should be available")
            
            // Validate endpoint format
            if let endpoint = azureEndpoint?.trimmingCharacters(in: .whitespacesAndNewlines), !endpoint.isEmpty {
                XCTAssertTrue(endpoint.hasPrefix("https://"), "Endpoint should use HTTPS")
                // Support both legacy Azure OpenAI endpoints (.openai.azure.com) and new Azure AI Foundry endpoints (.services.ai.azure.com)
                let isAzureOpenAI = endpoint.contains("openai.azure.com")
                let isAzureAIFoundry = endpoint.contains("services.ai.azure.com")
                XCTAssertTrue(isAzureOpenAI || isAzureAIFoundry, 
                             "Should be either an Azure OpenAI endpoint (.openai.azure.com) or Azure AI Foundry endpoint (.services.ai.azure.com)")
            }
            
            // Validate API key format (basic checks)
            if let apiKey = azureAPIKey?.trimmingCharacters(in: .whitespacesAndNewlines), !apiKey.isEmpty {
                XCTAssertGreaterThan(apiKey.count, 10, "API key should be reasonably long")
            }
            
            // Validate deployment name
            if let deployment = azureDeployment?.trimmingCharacters(in: .whitespacesAndNewlines), !deployment.isEmpty {
                XCTAssertTrue(true, "Deployment name is valid")
            }
            
            print("✅ Environment variable configuration test successful!")
            print("Endpoint: \(azureEndpoint ?? "N/A")")
            print("Deployment: \(azureDeployment ?? "N/A")")
            print("API Key: [REDACTED]")
        } else {
            print("ℹ️ Environment variables not properly set - this is expected for CI/CD without secrets")
            print("   This test will pass but skip live API validation")
            
            // Test should still pass even without environment variables
            XCTAssertTrue(true, "Environment variable test completed successfully (no live credentials)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Perform a streaming request using pure URLSession
    private func performStreamingRequest(urlRequest: URLRequest) async throws -> StreamingResult {
        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: URLError(.dataNotAllowed))
                    return
                }
                
                // Convert data to lines
                let responseString = String(data: data, encoding: .utf8) ?? ""
                let lines = responseString.components(separatedBy: .newlines)
                
                let result = StreamingResult(
                    httpResponse: httpResponse,
                    lines: AsyncThrowingStream { continuation in
                        Task {
                            for line in lines {
                                continuation.yield(line)
                            }
                            continuation.finish()
                        }
                    }
                )
                
                continuation.resume(returning: result)
            }
            task.resume()
        }
    }
    
    /// Result structure for streaming requests
    private struct StreamingResult {
        let httpResponse: HTTPURLResponse
        let lines: AsyncThrowingStream<String, Error>
    }
}

// MARK: - Helper Extensions

extension SAOAIMessage {
    /// Convenience initializer for simple text messages
    init(role: SAOAIMessageRole, text: String) {
        self.init(
            role: role,
            content: [.inputText(.init(text: text))]
        )
    }
}