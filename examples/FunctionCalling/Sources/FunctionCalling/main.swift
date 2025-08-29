import Foundation
import SwiftAzureOpenAI

// Example demonstrating function calling with the SwiftAzureOpenAI SDK
// This closely follows the Python OpenAI SDK style shown in the problem statement

// MARK: - Configuration

// Azure OpenAI Configuration  
nonisolated(unsafe) let azureConfig = SAOAIAzureConfiguration(
    endpoint: "https://your-resource.openai.azure.com",
    apiKey: "your-azure-api-key",
    deploymentName: "gpt-4o",
    apiVersion: "preview"
)

// OpenAI Configuration (alternative)
nonisolated(unsafe) let openaiConfig = SAOAIOpenAIConfiguration(
    apiKey: "sk-your-openai-api-key",
    organization: nil
)

// MARK: - Function Calling Example (Python-style)

func demonstrateFunctionCalling() async throws {
    print("🛠️ SwiftAzureOpenAI - Function Calling Example (Python-style)")
    print("==============================================================")
    
    let client = SAOAIClient(configuration: azureConfig)
    
    // Step 1: Define tools/functions (Python-style)
    let tools = [
        SAOAITool.function(
            name: "get_weather",
            description: "Get the weather for a location",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        )
    ]
    
    print("\n=== Step 1: Initial request with function definition ===")
    
    // Step 2: Create initial request with tools (Python-style)
    let response = try await client.responses.create(
        model: "gpt-4o",
        input: "What's the weather in San Francisco?",
        tools: tools
    )
    
    print("Response ID: \(response.id ?? "N/A")")
    print("Output count: \(response.output.count)")
    
    // Step 3: Process the response and handle function calls
    var input: [SAOAIMessage] = []
    
    for output in response.output {
        for content in output.content {
            switch content {
            case .outputText(let textOutput):
                print("Text output: \(textOutput.text)")
                
            case .functionCall(let functionCall):
                print("Function call: \(functionCall.name)")
                print("Call ID: \(functionCall.callId)")
                print("Arguments: \(functionCall.arguments)")
                
                // Handle the function call (matches Python style)
                switch functionCall.name {
                case "get_weather":
                    // Simulate calling the actual function
                    let functionResult = getFakeWeatherData(for: functionCall.arguments)
                    
                    // Create function call output (Python-style)
                    input.append(SAOAIMessage(
                        role: .user,
                        content: [.functionCallOutput(.init(
                            callId: functionCall.callId,
                            output: functionResult
                        ))]
                    ))
                    
                default:
                    print("⚠️ Unknown function call: \(functionCall.name)")
                }
            }
        }
    }
    
    // Step 4: Send follow-up request with function results (Python-style)
    if !input.isEmpty {
        print("\n=== Step 2: Follow-up request with function results ===")
        
        let secondResponse = try await client.responses.create(
            model: "gpt-4o",
            input: input,
            previousResponseId: response.id
        )
        
        print("Second response ID: \(secondResponse.id ?? "N/A")")
        
        // Process final response
        for output in secondResponse.output {
            for content in output.content {
                if case let .outputText(textOutput) = content {
                    print("Final response: \(textOutput.text)")
                }
            }
        }
    }
}

// MARK: - Helper Functions

func getFakeWeatherData(for arguments: String) -> String {
    // In a real implementation, you would parse the arguments and call a weather API
    return "{\"temperature\": \"70 degrees\", \"condition\": \"sunny\", \"humidity\": \"45%\"}"
}

// MARK: - Multiple Function Example

func demonstrateMultipleFunctions() async throws {
    print("\n\n🔧 Multiple Functions Example")
    print("==============================")
    
    let client = SAOAIClient(configuration: azureConfig)
    
    // Define multiple tools
    let tools = [
        SAOAITool.function(
            name: "get_weather",
            description: "Get current weather for a location",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object(["type": .string("string")])
                ]),
                "required": .array([.string("location")])
            ])
        ),
        SAOAITool.function(
            name: "calculate_sum",
            description: "Calculate the sum of two numbers",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "a": .object(["type": .string("number")]),
                    "b": .object(["type": .string("number")])
                ]),
                "required": .array([.string("a"), .string("b")])
            ])
        )
    ]
    
    let response = try await client.responses.create(
        model: "gpt-4o",
        input: "What's the weather in Tokyo and what's 15 + 27?",
        tools: tools
    )
    
    print("Response with multiple function calls:")
    
    var functionResults: [SAOAIMessage] = []
    
    for output in response.output {
        for content in output.content {
            if case let .functionCall(functionCall) = content {
                print("- Function: \(functionCall.name), Call ID: \(functionCall.callId)")
                
                let result: String
                switch functionCall.name {
                case "get_weather":
                    result = "{\"temperature\": \"22°C\", \"condition\": \"cloudy\"}"
                case "calculate_sum":
                    result = "{\"result\": 42}"
                default:
                    result = "{\"error\": \"Unknown function\"}"
                }
                
                functionResults.append(SAOAIMessage(
                    role: .user,
                    content: [.functionCallOutput(.init(
                        callId: functionCall.callId,
                        output: result
                    ))]
                ))
            }
        }
    }
    
    // Send results back
    if !functionResults.isEmpty {
        let finalResponse = try await client.responses.create(
            model: "gpt-4o",
            input: functionResults,
            previousResponseId: response.id
        )
        
        print("Final synthesized response:")
        for output in finalResponse.output {
            for content in output.content {
                if case let .outputText(textOutput) = content {
                    print(textOutput.text)
                }
            }
        }
    }
}

// MARK: - Comparison with Python

func showPythonStyleComparison() {
    print("\n\n📝 Python vs Swift Comparison")
    print("==============================")
    
    print("""
    Python OpenAI SDK style:
    ```python
    response = client.responses.create(
        model="gpt-4o",
        tools=[{
            "type": "function",
            "name": "get_weather",
            "description": "Get the weather for a location",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {"type": "string"}
                },
                "required": ["location"]
            }
        }],
        input=[{"role": "user", "content": "What's the weather in San Francisco?"}]
    )
    
    for output in response.output:
        if output.type == "function_call":
            # Handle function call
    ```
    
    SwiftAzureOpenAI equivalent:
    ```swift
    let response = try await client.responses.create(
        model: "gpt-4o",
        input: "What's the weather in San Francisco?",
        tools: [
            SAOAITool.function(
                name: "get_weather",
                description: "Get the weather for a location",
                parameters: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "location": .object(["type": .string("string")])
                    ]),
                    "required": .array([.string("location")])
                ])
            )
        ]
    )
    
    for output in response.output {
        for content in output.content {
            if case let .functionCall(functionCall) = content {
                // Handle function call
            }
        }
    }
    ```
    """)
}

// MARK: - Main Demo

func runFunctionCallingDemo() async {
    print("🚀 SwiftAzureOpenAI - Function Calling Demo")
    print("===========================================")
    
    print("\n📝 This demo shows how to use function calling with SwiftAzureOpenAI")
    print("   following the same patterns as the Python OpenAI SDK.")
    
    print("\n🔧 To run these examples with real API calls:")
    print("   1. Set your Azure OpenAI endpoint and API key")
    print("   2. Update the deployment name to match your model")
    print("   3. Uncomment the async function calls below")
    
    showPythonStyleComparison()
    
    // Note: These examples would make actual HTTP calls if run with real credentials
    // To test with real API calls, uncomment the lines below:
    
    // try await demonstrateFunctionCalling()
    // try await demonstrateMultipleFunctions()
    
    print("\n✅ Function calling implementation complete!")
    print("   • Function call output content type: SAOAIOutputContent.functionCall")
    print("   • Function call result input type: SAOAIInputContent.functionCallOutput")
    print("   • Python-style tool creation: SAOAITool.function(name:description:parameters:)")
    print("   • Full workflow support with previousResponseId")
}

// MARK: - Execution

@main 
struct FunctionCallingExample {
    static func main() async {
        await runFunctionCallingDemo()
    }
}