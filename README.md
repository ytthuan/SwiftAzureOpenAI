# SwiftAzureOpenAI

A Swift package focused on the Azure OpenAI/OpenAI Responses API for iOS, macOS, watchOS, tvOS, and other Apple platforms.

## Overview

SwiftAzureOpenAI provides Swift-native models and utilities for working with the Azure/OpenAI Responses API, a unified, stateful API that combines chat, tools, and assistants patterns.

This package emphasizes strongly typed request/response models, response metadata extraction, and streaming-friendly types, designed specifically for Apple platforms and Swift development.

## Features

- 🚀 **Responses API-first**: Unified request/response models aligned with Azure/OpenAI Responses API
- 🔄 **Async/Await**: Modern Swift concurrency for non-streaming and streaming
- 📡 **Real-time Streaming**: Native SSE handling with optimized parsing
- 🎯 **Python-style API**: `client.responses.create(...)` for fast adoption
- 🛡️ **Typed errors**: Clear error modeling with `SAOAIError` and `ErrorResponse`
- 🧩 **Structured content**: Text, images, and tool/function calling
- 📊 **Metadata extraction**: Request id, rate limits, processing time
- 🌐 **Azure + OpenAI**: Works with both services via `SAOAIConfiguration`
- 📦 **Swift Package Manager**: First-class SPM support
- ⚡ **Optimized services**: High-performance parsing/streaming and optional response caching

## Requirements

- iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ / tvOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## API Support

This package targets the Azure/OpenAI Responses API. It is model-agnostic; use the deployment or model name appropriate for your account. Examples below use `gpt-4o`/`gpt-4o-mini`.

> Check the Azure models documentation for availability: https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models

## Installation

### Swift Package Manager

Add SwiftAzureOpenAI to your project using Xcode:

1. In Xcode, go to `File` → `Add Package Dependencies...`
2. Enter the repository URL: `https://github.com/ytthuan/SwiftAzureOpenAI`
3. Select the version you want to use
4. Add the package to your target

Or add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/ytthuan/SwiftAzureOpenAI", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftAzureOpenAI"]
)
```

## Quick Start

SwiftAzureOpenAI provides modern async/await support with comprehensive streaming capabilities:
- **🎉 Python-style API (Recommended)** - `client.responses.create(...)`
- **📡 Streaming API** - `client.responses.createStreaming(...)`
- **Advanced API** - Build `SAOAIRequest` and use your own HTTP stack

### Import the Package

```swift
import SwiftAzureOpenAI
```

### API Surface (SAOAI-prefixed types)

- `SAOAIClient` (main client)
- `ResponsesClient` (Python-style client at `client.responses`)
- `SAOAIAzureConfiguration`, `SAOAIOpenAIConfiguration`
- `SAOAIRequest`, `SAOAIMessage`, `SAOAIInputContent`
- `SAOAIResponse`, `SAOAIOutput`, `SAOAIOutputContent`
- `SAOAIStreamingResponse` (SSE events)
- `SAOAIReasoning`, `SAOAIText`
- `SAOAITool`, `SAOAIJSONValue`
- `APIResponse<T>`, `ResponseMetadata`, `RateLimitInfo`, `SAOAIError`, `ErrorResponse`

### Simple Python-style API (Recommended)

The easiest way to use SwiftAzureOpenAI with a simple, Python-inspired API:

```swift
import SwiftAzureOpenAI

// Configure your client
let config = SAOAIAzureConfiguration(
    endpoint: "https://your-resource.openai.azure.com",
    apiKey: "your-api-key",
    deploymentName: "gpt-4o-mini"
)
let client = SAOAIClient(configuration: config)

// Simple string input - just like Python!
let response = try await client.responses.create(
    model: config.deploymentName,
    input: "Write a haiku about Swift programming.",
    maxOutputTokens: 200,
    temperature: 0.7
)

// Extract the response text
for output in response.output {
    for part in output.content ?? [] {
        switch part {
        case .outputText(let text):
            print(text.text)
        case .functionCall(let call):
            print("Function call: \(call.name) args=\(call.arguments)")
        }
    }
}
```

### Advanced Usage with Multiple Messages

For conversations with multiple messages:

```swift
// Create messages easily with convenience initializer
let messages = [
    SAOAIMessage(role: .system, text: "You are a helpful assistant."),
    SAOAIMessage(role: .user, text: "What's the weather like?"),
    SAOAIMessage(role: .assistant, text: "I don't have real-time weather data."),
    SAOAIMessage(role: .user, text: "Can you help me with Swift programming?")
]

let response = try await client.responses.create(
    model: config.deploymentName,
    input: messages,
    maxOutputTokens: 300
)
```

### 📡 Streaming Responses

SwiftAzureOpenAI provides full support for real-time streaming responses via SSE:

```swift
// Create a streaming call
let stream = client.responses.createStreaming(
    model: config.deploymentName,
    input: "Write a story about space exploration",
    maxOutputTokens: 500,
    temperature: 0.7
)

// Process events as they arrive
for try await event in stream {
    if let parts = event.output?.first?.content {
        for part in parts {
            if let text = part.text, !text.isEmpty { print(text, terminator: "") }
        }
        fflush(stdout)
    }
}
```

### Reasoning Models Support

For reasoning models like `o1`, `o3-mini`, `o4-mini`, you can specify reasoning effort:

```swift
// Reasoning configuration (effort and optional summary)
let reasoning = SAOAIReasoning(effort: "medium", summary: "concise")
let text = SAOAIText.low()

let response = try await client.responses.create(
    model: config.deploymentName,
    input: "Explain BFS vs DFS",
    maxOutputTokens: 200,
    reasoning: reasoning,
    text: text
)
```

### Function Calling (tools)

```swift
// Define a function tool using SAOAIJSONValue
let sumTool = SAOAITool.function(
    name: "sum_calculator",
    description: "Return the sum of two integers",
    parameters: .object([
        "type": .string("object"),
        "properties": .object([
            "a": .object(["type": .string("integer")]),
            "b": .object(["type": .string("integer")])
        ]),
        "required": .array([.string("a"), .string("b")])
    ])
)

// Pass tool definitions in the request
let toolResponse = try await client.responses.create(
    model: config.deploymentName,
    input: "What's 15 + 27?",
    tools: [sumTool]
)

// If the model asks to call a tool in streaming, send function outputs back (minimal form)
let functionOutput = SAOAIInputContent.FunctionCallOutput(callId: "call_123", output: "{\"result\": 42}")
let functionStream = client.responses.createStreaming(
    model: config.deploymentName,
    functionCallOutputs: [functionOutput],
    previousResponseId: "resp_abc123"
)
for try await _ in functionStream { /* handle follow-up events */ }
```

### File Input and Processing

SwiftAzureOpenAI supports file inputs (especially PDFs) following Azure AI Foundry guidelines. Files can be provided as Base64-encoded data or as file IDs from previously uploaded files.

```swift
// Example 1: PDF analysis with Base64-encoded data
let pdfData = // Your PDF data as Data
let base64String = pdfData.base64EncodedString()

let pdfResponse = try await client.responses.create(
    model: "gpt-4o", // Vision models support PDF inputs
    input: [
        .message(SAOAIMessage(
            role: .user,
            text: "Summarize this PDF document",
            filename: "report.pdf", 
            base64FileData: base64String,
            mimeType: "application/pdf"
        ))
    ]
)

// Example 2: Using a file ID from uploaded files
let fileIdResponse = try await client.responses.create(
    model: "gpt-4o-mini",
    input: [
        .message(SAOAIMessage(
            role: .user,
            text: "Analyze the uploaded document", 
            fileId: "assistant-KaVLJQTiWEvdz8yJQHHkqJ"
        ))
    ]
)

// Example 3: Direct file content creation
let message = SAOAIMessage(role: .user, content: [
    .inputText(.init(text: "What are the key findings in this document?")),
    .inputFile(.init(fileId: "assistant-123456789"))
])
```

**File Input Requirements:**
- Only models with vision capabilities (gpt-4o, gpt-4o-mini, o1, etc.) support PDF file inputs
- Files can be up to 100 pages and 32MB total content per request
- Both extracted text and page images are included in the model's context
- Currently supported file types: PDF (primary), with support for various document formats

### Retrieve and Delete Responses

```swift
// Retrieve a response by ID
let retrieved = try await client.responses.retrieve("resp_abc123")

// Delete a response
let deleted = try await client.responses.delete("resp_abc123")
```

### Advanced: Build a Responses API request

For advanced use cases, you can still use the detailed API:

```swift
let request = SAOAIRequest(
    model: config.deploymentName, // Azure: deployment name; OpenAI: model name
    input: [
        SAOAIMessage(
            role: .system,
            content: [ .inputText(.init(text: "You are a helpful assistant.")) ]
        ),
        SAOAIMessage(
            role: .user,
            content: [ .inputText(.init(text: "Write a haiku about Swift programming.")) ]
        )
    ],
    maxOutputTokens: 200,
    temperature: 0.7
)
```

The `input` parameter uses an array of `SAOAIMessage` objects, each containing structured content parts. This unified approach replaces the separate `messages` parameter from legacy chat completions APIs.

### Decode a Responses API response

Use your preferred HTTP stack to send requests and decode responses into the provided models:

```swift
import Foundation
import SwiftAzureOpenAI

let decoder = JSONDecoder()
// Configure if needed, e.g. date decoding strategy depending on your metadata usage.

func handleResponse(data: Data, httpResponse: HTTPURLResponse) throws -> APIResponse<SAOAIResponse> {
    // Extract any metadata you collect from headers and timing
    let rateLimit = RateLimitInfo(remaining: nil, resetTime: nil, limit: nil)
    let metadata = ResponseMetadata(
        requestId: httpResponse.allHeaderFields["x-request-id"] as? String,
        timestamp: Date(),
        processingTime: nil,
        rateLimit: rateLimit
    )

    let body = try decoder.decode(SAOAIResponse.self, from: data)
    return APIResponse(
        data: body,
        metadata: metadata,
        statusCode: httpResponse.statusCode,
        headers: httpResponse.allHeaderFields as? [String: String] ?? [:]
    )
}
```

### Reading output content

```swift
let apiResponse: APIResponse<SAOAIResponse> = /* from your network layer */
let outputs = apiResponse.data.output
for output in outputs {
    for part in output.content ?? [] {
        switch part {
        case .outputText(let text):
            print(text.text)
        case .functionCall(let call):
            print("Function call: \(call.name) \narguments: \(call.arguments)")
        }
    }
}
```

### Streaming model support (low-level types)

For advanced scenarios, the core includes `StreamingResponseChunk<T>` and services to process arbitrary streams of `Data`. Prefer the high-level `client.responses.createStreaming(...)` for Responses API.

## Data Models

The Responses API uses a unified data model structure that consolidates the best features from chat completions and assistants APIs:

### Request Models

- **`SAOAIRequest`** - Main request payload for the Responses API
  - `model: String?` — Azure deployment name or OpenAI model name
  - `input: [SAOAIInput]` — Unified input array (messages and/or function call outputs)
  - `maxOutputTokens: Int?` — Maximum tokens to generate in the response
  - `temperature: Double?`, `topP: Double?` — Sampling parameters
  - `tools: [SAOAITool]?` — Optional tool definitions for function calling
  - `previousResponseId: String?` — Chain follow-ups to a prior response
  - `reasoning: SAOAIReasoning?` — Reasoning configuration
  - `text: SAOAIText?` — Text verbosity configuration
  - `stream: Bool?` — Enable streaming

- **`SAOAIReasoning`** - Reasoning configuration
  - `effort: String` — Reasoning effort level: "low", "medium", or "high"
  - `summary: String?` — Optional summary style: e.g. "concise", "detailed"

- **`SAOAIMessage`** - Conversation message
  - `role: SAOAIMessageRole?` — `.system`, `.user`, `.assistant`, or omitted for tool outputs
  - `content: [SAOAIInputContent]` — Structured content parts

- **`SAOAIInputContent`** - Structured input content
  - `.inputText(InputText)` — `{ type: "input_text", text }`
  - `.inputImage(InputImage)` — `{ type: "input_image", image_url }` or base64 data URI
  - `.inputFile(InputFile)` — `{ type: "input_file", filename?, file_data?, file_id? }` for PDF and document processing
  - `.functionCallOutput(FunctionCallOutput)` — `{ type: "function_call_output", call_id, output }`

### Response Models

- **`SAOAIResponse`** - Top-level response
  - `id: String?`
  - `model: String?`
  - `created: Int?` (mapped from `created_at`)
  - `output: [SAOAIOutput]`
  - `usage: SAOAITokenUsage?`

- **`SAOAIOutput`** - Output item
  - `content: [SAOAIOutputContent]?`
  - `role: String?`
  - Function call fields for tool use (e.g., `type`, `name`, `callId`, `arguments`, `status`)

- **`SAOAIOutputContent`**
  - `.outputText(OutputText)` — `{ type: "output_text", text }`
  - `.functionCall(FunctionCall)` — `{ type: "function_call", call_id, name, arguments }`

### Supporting Models

- **`SAOAITokenUsage`** - Token consumption tracking
  - `inputTokens: Int?`, `outputTokens: Int?`, `totalTokens: Int?`

- **`APIResponse<T>`** - Wrapper for HTTP response data
  - `data: T` — Decoded response payload
  - `metadata: ResponseMetadata` — Request/response metadata
  - `statusCode: Int` — HTTP status code
  - `headers: [String: String]` — Response headers

- **`ResponseMetadata`** - Request/response tracking
  - `requestId: String?` — Unique request identifier
  - `timestamp: Date` — Response timestamp
  - `processingTime: TimeInterval?` — Processing duration
  - `rateLimit: RateLimitInfo?` — Rate limit information

- **`RateLimitInfo`** - Rate limiting details
  - `remaining: Int?`, `resetTime: Date?`, `limit: Int?`

- **`SAOAIError`**, **`ErrorResponse`** - Error handling
  - Typed errors for network, decoding, status, and server-reported issues

## Usage with Azure OpenAI and OpenAI

This package provides data models and configurations for both Azure OpenAI and OpenAI services. You can use any HTTP client (e.g., `URLSession`) to call the respective endpoints.

### Azure OpenAI Configuration

For Azure OpenAI, use the Responses API endpoint with your resource configuration:

```swift
import SwiftAzureOpenAI

// Configure Azure OpenAI
let azureConfig = SAOAIAzureConfiguration(
    endpoint: "https://your-resource.openai.azure.com",
    apiKey: "your-azure-api-key",
    deploymentName: "gpt-4o-mini", // Your deployment name
    apiVersion: "preview" // Responses API version (default: "preview")
)

// Build your request
let request = SAOAIRequest(
    model: azureConfig.deploymentName,
    input: [
        SAOAIMessage(
            role: .user,
            content: [.inputText(.init(text: "Hello, Azure OpenAI!"))]
        )
    ],
    maxOutputTokens: 100
)
```

**Azure OpenAI Responses API Endpoint:**
- URL: `https://{resource}.openai.azure.com/openai/v1/responses?api-version=preview`
- Headers: `api-key: <AZURE_API_KEY>`, `Content-Type: application/json`
- Body: `SAOAIRequest` encoded as JSON

### OpenAI Configuration

For OpenAI, use the standard Responses API endpoint:

```swift
// Configure OpenAI
let openaiConfig = SAOAIOpenAIConfiguration(
    apiKey: "sk-your-openai-api-key",
    organization: "org-your-organization" // Optional
)
```

**OpenAI Responses API Endpoint:**
- URL: `https://api.openai.com/v1/responses`
- Headers: `Authorization: Bearer <OPENAI_API_KEY>`, `Content-Type: application/json`
- Body: `SAOAIRequest` encoded as JSON

### Example HTTP Request

Here's a complete example using `URLSession` with Azure OpenAI:

```swift
import Foundation
import SwiftAzureOpenAI

func sendResponsesRequest() async throws -> APIResponse<SAOAIResponse> {
    let config = SAOAIAzureConfiguration(
        endpoint: "https://your-resource.openai.azure.com",
        apiKey: "your-api-key",
        deploymentName: "gpt-4o-mini"
    )
    
    let request = SAOAIRequest(
        model: config.deploymentName,
        input: [
            SAOAIMessage(
                role: .user,
                content: [.inputText(.init(text: "Hello!"))]
            )
        ]
    )
    
    let json = try JSONEncoder().encode(request)
    var urlRequest = URLRequest(url: config.baseURL)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = json
    
    // Apply configuration headers
    for (key, value) in config.headers {
        urlRequest.setValue(value, forHTTPHeaderField: key)
    }
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    let httpResponse = response as! HTTPURLResponse
    
    return try handleResponse(data: data, httpResponse: httpResponse)
}
```

## Error Handling

```swift
do {
    // ... perform request and decode ...
} catch let error as SAOAIError {
    print(error.localizedDescription)
} catch let error as DecodingError {
    throw SAOAIError.decodingError(error)
} catch {
    throw SAOAIError.networkError(error)
}
```

If the server returns a structured error payload, decode into `ErrorResponse` and surface it via `.apiError(ErrorResponse)`.

## Testing

### Running Tests

```bash
swift test
```

### Live API Testing

For comprehensive live testing with Azure OpenAI or OpenAI services, see the [Live API Testing Guide](docs/LIVE_API_TESTING.md).

Quick setup for live testing:

```bash
# Azure OpenAI
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
export COPILOT_AGENT_AZURE_OPENAI_API_KEY="your-azure-api-key"
export AZURE_OPENAI_DEPLOYMENT="your-deployment-name"

# Or OpenAI
export OPENAI_API_KEY="sk-your-openai-api-key"
```

Then create a simple test client:

```swift
import SwiftAzureOpenAI
import Foundation

// Example test function
func testAzureOpenAI() async throws {
    guard let endpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"],
          let apiKey = ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"] ?? ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"],
          let deployment = ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] else {
        print("Azure OpenAI environment variables not set")
        return
    }
    
    let config = SAOAIAzureConfiguration(
        endpoint: endpoint,
        apiKey: apiKey,
        deploymentName: deployment
    )
    
    let request = SAOAIRequest(
        model: deployment,
        input: [
            SAOAIMessage(
                role: .user,
                content: [.inputText(.init(text: "Hello, Azure OpenAI!"))]
            )
        ],
        maxOutputTokens: 50
    )
    
    // Implement your HTTP client logic here
    print("Request configured successfully")
}
```

## File-based Validation and Console Examples

The SwiftAzureOpenAI library includes console applications that demonstrate file-based input/output for validation and testing purposes.

### NonStreamingResponseConsoleChatbot with File API

The enhanced NonStreamingResponseConsoleChatbot supports file-based validation:

```bash
# Navigate to the example
cd examples/NonStreamingResponseConsoleChatbot

# File-based processing with input prompts and output responses
swift run NonStreamingResponseConsoleChatbot \
  --input-file prompts.txt \
  --output-file responses.txt \
  --reasoning high

# Single message with file output for validation
swift run NonStreamingResponseConsoleChatbot \
  --message "Analyze the quarterly report" \
  --output-file analysis.txt
```

#### Input File Format
Create `prompts.txt` with one prompt per line:
```
# Comments start with # and are ignored
What is machine learning?

# Reference files for File API processing
file:/path/to/document.pdf
file:/path/to/chart.png

# Regular text prompts
Calculate the square root of 144
```

#### File Processing Features
- **Text files** (`.txt`, `.md`, `.json`): Content included directly
- **Binary files** (`.pdf`, `.jpg`, `.png`): Base64-encoded for File API
- **Structured output**: Responses written with prompt numbering
- **Error handling**: File errors captured in output
- **File API integration**: Leverages SwiftAzureOpenAI File API models

#### Example Output Structure
```
Prompt 1: What is machine learning?
Response: [assistant]: Machine learning is a field of computer science...

Prompt 2: file:/path/to/document.pdf  
Response: [assistant]: After analyzing the PDF document, I found...

Prompt 3: Calculate the square root of 144
Response: [assistant]: The square root of 144 is 12.
```

### Use Cases for File-based Validation
- **Batch testing**: Process multiple prompts systematically
- **Response validation**: Compare outputs across model versions
- **File API testing**: Validate PDF and image processing capabilities
- **Performance benchmarking**: Measure response times and quality
- **Integration testing**: Test real-world scenarios with actual files

### Additional Examples
See the [examples/](examples/) directory for:
- **ConsoleChatbot**: Interactive streaming/non-streaming modes
- **ResponsesConsoleChatbot**: Advanced unified console example
- **NonStreamingResponseConsoleChatbot**: File-based validation example

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 Documentation: project README (this file) and [docs/](docs/) directory
- 🧪 Live API Testing: [Live API Testing Guide](docs/LIVE_API_TESTING.md)
- 🐛 Issues: [GitHub Issues](https://github.com/ytthuan/SwiftAzureOpenAI/issues)
- 📚 Azure OpenAI Responses API: [Official Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference-preview-latest#create-response)

---

**Note:** This package is community-maintained and not officially affiliated with OpenAI or Microsoft. It provides Swift-native data models and client utilities designed for the Azure/OpenAI Responses API.