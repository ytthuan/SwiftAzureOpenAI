#!/usr/bin/env swift

import Foundation
import SwiftAzureOpenAI

// Simple test to verify tool calling with our fixes
let config = SAOAIAzureConfiguration(
    endpoint: ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] ?? "",
    apiKey: ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ?? "",
    deploymentName: ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? "",
    apiVersion: "preview"
)

let client = SAOAIClient(configuration: config)

// Define weather tool
let weatherTool = SAOAITool.function(
    name: "get_weather",
    description: "Get current weather information for a specified location",
    parameters: .object([
        "location": .object([
            "type": .string,
            "description": .string("The city and country, e.g. 'London, UK'")
        ]),
        "unit": .object([
            "type": .string,
            "description": .string("Temperature unit, either 'celsius' or 'fahrenheit'")
        ])
    ]),
    required: ["location"]
)

print("🧪 Testing minimal tool call scenario...")

Task {
    do {
        let messages = [
            SAOAIMessage(role: .user, text: "What's the weather like in London, UK using celsius?")
        ]
        
        print("📤 Making streaming request...")
        let stream = client.responses.createStreaming(
            model: config.deploymentName,
            input: messages,
            tools: [weatherTool],
            maxOutputTokens: 500  // Increase tokens to avoid incomplete responses
        )
        
        print("📥 Processing stream...")
        var responseContent = ""
        var toolCallFound = false
        
        for try await chunk in stream {
            if let eventType = chunk.eventType {
                print("🔍 Event: \(eventType)")
                
                // Check for function calls
                if case .responseFunctionCallArgumentsComplete = eventType {
                    toolCallFound = true
                    print("✅ Function call found!")
                }
                
                // Check for text output
                if case .responseOutputTextDelta = eventType {
                    if let delta = chunk.response?.output?.first?.content?.first {
                        if case .outputText(let textOutput) = delta {
                            responseContent += textOutput.text
                            print("📝 Text: \(textOutput.text)")
                        }
                    }
                }
            }
        }
        
        print("\n🎯 Test Results:")
        print("Tool call found: \(toolCallFound)")
        print("Response content: \(responseContent)")
        
        if toolCallFound {
            print("✅ SUCCESS: Tool calling is working!")
        } else {
            print("❌ ISSUE: No tool calls detected")
        }
        
        exit(0)
        
    } catch {
        print("❌ Error: \(error)")
        exit(1)
    }
}

RunLoop.main.run()