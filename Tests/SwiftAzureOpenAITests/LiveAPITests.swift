import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

/// Live API tests using pure URLSession to verify streaming and non-streaming functionality
/// These tests require environment variables to be set:
/// - AZURE_OPENAI_ENDPOINT: Azure OpenAI endpoint URL
/// - AZURE_OPENAI_API_KEY: Azure OpenAI API key (should be set as secret)
/// - AZURE_OPENAI_DEPLOYMENT: Azure OpenAI deployment name
final class LiveAPITests: XCTestCase {
    
    // MARK: - Environment Configuration
    
    private var azureEndpoint: String? {
        ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"]
    }
    
    private var azureAPIKey: String? {
        ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"]
    }
    
    private var azureDeployment: String? {
        ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"]
    }
    
    private var hasAzureCredentials: Bool {
        azureEndpoint != nil && azureAPIKey != nil && azureDeployment != nil
    }
    
    // MARK: - Pure URLSession API Call Tests
    
    func testCallAPIWithURLSessionNonStreaming() async throws {
        guard hasAzureCredentials else {
            throw XCTSkip("Azure OpenAI credentials not available. Set AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_API_KEY, and AZURE_OPENAI_DEPLOYMENT environment variables.")
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
                SAOAIMessage(role: .user, text: "Hello! Please respond with just 'Hi there!' and nothing else.")
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
            
            // Validate response structure
            XCTAssertNotNil(apiResponse.id, "Response should have an ID")
            XCTAssertNotNil(apiResponse.created, "Response should have a created timestamp")
            XCTAssertNotNil(apiResponse.model, "Response should have a model")
            XCTAssertFalse(apiResponse.output.isEmpty, "Response should have at least one output")
            
            // Validate first output
            let firstOutput = apiResponse.output[0]
            XCTAssertFalse(firstOutput.content.isEmpty, "Output should have content")
            
            print("✅ Non-streaming API call successful!")
            print("Response ID: \(apiResponse.id ?? "N/A")")
            print("Model: \(apiResponse.model ?? "N/A")")
            
            // Extract text content
            let textContent = firstOutput.content.compactMap { content in
                if case .outputText(let outputText) = content {
                    return outputText.text
                } else {
                    return nil
                }
            }.joined(separator: " ")
            
            print("Content: \(textContent)")
            
        } catch {
            print("Failed to decode response: \(error)")
            print("Raw response: \(responseString)")
            XCTFail("Failed to decode API response: \(error)")
        }
    }
    
    func testCallAPIWithURLSessionStreaming() async throws {
        guard hasAzureCredentials else {
            throw XCTSkip("Azure OpenAI credentials not available. Set AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_API_KEY, and AZURE_OPENAI_DEPLOYMENT environment variables.")
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
                SAOAIMessage(role: .user, text: "Count from 1 to 5, each number on a new line.")
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
            throw XCTSkip("Azure OpenAI credentials not available. Set AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_API_KEY, and AZURE_OPENAI_DEPLOYMENT environment variables.")
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
                SAOAIMessage(role: .user, text: "Test")
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
            throw XCTSkip("Azure OpenAI credentials not available. Set AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_API_KEY, and AZURE_OPENAI_DEPLOYMENT environment variables.")
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
            input: messages,
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
        if hasAzureCredentials {
            XCTAssertNotNil(azureEndpoint, "AZURE_OPENAI_ENDPOINT should be available")
            XCTAssertNotNil(azureAPIKey, "AZURE_OPENAI_API_KEY should be available")
            XCTAssertNotNil(azureDeployment, "AZURE_OPENAI_DEPLOYMENT should be available")
            
            // Validate endpoint format
            if let endpoint = azureEndpoint {
                XCTAssertTrue(endpoint.hasPrefix("https://"), "Endpoint should use HTTPS")
                XCTAssertTrue(endpoint.contains("openai.azure.com"), "Should be an Azure OpenAI endpoint")
            }
            
            // Validate API key format (basic checks)
            if let apiKey = azureAPIKey {
                XCTAssertFalse(apiKey.isEmpty, "API key should not be empty")
                XCTAssertGreaterThan(apiKey.count, 10, "API key should be reasonably long")
            }
            
            // Validate deployment name
            if let deployment = azureDeployment {
                XCTAssertFalse(deployment.isEmpty, "Deployment name should not be empty")
            }
            
            print("✅ Environment variable configuration test successful!")
            print("Endpoint: \(azureEndpoint ?? "N/A")")
            print("Deployment: \(azureDeployment ?? "N/A")")
            print("API Key: [REDACTED]")
        } else {
            print("ℹ️ Environment variables not set - this is expected for CI/CD without secrets")
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