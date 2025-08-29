#!/usr/bin/env swift

import Foundation
import SwiftAzureOpenAI

// Example demonstrating the new simplified Python-style API

// MARK: - Configuration Examples

// Azure OpenAI Configuration
let azureConfig = SAOAIAzureConfiguration(
    endpoint: "https://your-resource.openai.azure.com",
    apiKey: "your-azure-api-key",
    deploymentName: "gpt-4o-mini",
    apiVersion: "preview"
)

// OpenAI Configuration  
let openaiConfig = SAOAIOpenAIConfiguration(
    apiKey: "sk-your-openai-api-key",
    organization: nil
)

// MARK: - Simple Usage (Python-style)

func demonstrateSimpleAPI() async {
    let client = SAOAIClient(configuration: azureConfig)
    
    do {
        // 🎉 NEW: Simple string input (Python-style)
        let response = try await client.responses.create(
            model: "gpt-4o-mini",
            input: "Hello, what is the meaning of life?",
            maxOutputTokens: 200,
            temperature: 0.7
        )
        
        print("Response ID:", response.id ?? "N/A")
        print("Model:", response.model ?? "N/A")
        
        // Extract the text from the response
        if let firstOutput = response.output.first,
           let firstContent = firstOutput.content.first,
           case let .outputText(textOutput) = firstContent {
            print("Response:", textOutput.text)
        }
        
    } catch {
        print("Error:", error)
    }
}

// MARK: - Multiple Messages (Conversation)

func demonstrateConversationAPI() async {
    let client = SAOAIClient(configuration: azureConfig)
    
    do {
        // 🎉 NEW: Simple message creation with convenience initializer
        let messages = [
            SAOAIMessage(role: .system, text: "You are a helpful assistant."),
            SAOAIMessage(role: .user, text: "What's the weather like?"),
            SAOAIMessage(role: .assistant, text: "I don't have access to real-time weather data."),
            SAOAIMessage(role: .user, text: "Can you help me with Swift programming?")
        ]
        
        let response = try await client.responses.create(
            model: "gpt-4o-mini",
            input: messages,
            maxOutputTokens: 300,
            temperature: 0.5
        )
        
        print("Conversation response:", response.id ?? "N/A")
        
    } catch {
        print("Error:", error)
    }
}

// MARK: - Retrieve and Delete Operations (Python-style)

func demonstrateRetrieveAndDelete() async {
    let client = SAOAIClient(configuration: azureConfig)
    
    do {
        // Create a response first
        let createResponse = try await client.responses.create(
            model: "gpt-4o-mini",
            input: "Tell me a joke"
        )
        
        guard let responseId = createResponse.id else {
            print("No response ID returned")
            return
        }
        
        // 🎉 NEW: Retrieve response by ID (Python-style)
        let retrievedResponse = try await client.responses.retrieve(responseId)
        print("Retrieved response:", retrievedResponse.id ?? "N/A")
        
        // 🎉 NEW: Delete response (Python-style)
        let deleted = try await client.responses.delete(responseId)
        print("Response deleted:", deleted)
        
    } catch {
        print("Error:", error)
    }
}

// MARK: - Backward Compatibility

func demonstrateBackwardCompatibility() async {
    let client = SAOAIClient(configuration: azureConfig)
    
    // ✅ Old complex way still works for advanced users
    let complexRequest = SAOAIRequest(
        model: "gpt-4o-mini",
        input: [
            SAOAIMessage(
                role: .user,
                content: [
                    .inputText(.init(text: "Hello")),
                    .inputImage(.init(imageURL: "https://example.com/image.jpg"))
                ]
            )
        ],
        maxOutputTokens: 200,
        temperature: 0.7,
        topP: 1.0
    )
    
    print("Complex request created with model:", complexRequest.model ?? "N/A")
    print("Input messages:", complexRequest.input.count)
}

// MARK: - Comparison: Before vs After

func showBeforeAndAfter() {
    print("=== BEFORE (Complex) ===")
    print("""
    let request = SAOAIRequest(
        model: "gpt-5-chat",
        input: [
            SAOAIMessage(
                role: .user,
                content: [.inputText(.init(text: "Hello, what is the meaning of life?"))]
            )
        ],
        maxOutputTokens: 200,
        temperature: 0.5,
        topP: 1
    )
    
    // Then manually create URLRequest, encode JSON, set headers, etc...
    """)
    
    print("\n=== AFTER (Simple) ===")
    print("""
    let response = try await client.responses.create(
        model: "gpt-4o-mini",
        input: "Hello, what is the meaning of life?",
        maxOutputTokens: 200,
        temperature: 0.5
    )
    """)
}

// MARK: - Demo

print("🚀 SwiftAzureOpenAI - New Python-style API Demo")
print("===============================================")

showBeforeAndAfter()

print("\n✨ The new API provides:")
print("• Simple string input: client.responses.create(model: ..., input: \"text\")")
print("• Convenience message creation: SAOAIMessage(role: .user, text: \"...\")")
print("• Python-style operations: client.responses.retrieve(id), client.responses.delete(id)")
print("• Full backward compatibility with existing complex API")
print("• All the power of the underlying robust HTTP client and response processing")

// Note: These functions would actually make HTTP calls if run with real credentials
// demonstrateSimpleAPI()
// demonstrateConversationAPI()
// demonstrateRetrieveAndDelete()
// demonstrateBackwardCompatibility()