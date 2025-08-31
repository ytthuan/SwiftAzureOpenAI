# SwiftAzureOpenAI

A Swift package focused on the Azure OpenAI/OpenAI Responses API for iOS, macOS, watchOS, tvOS, and other Apple platforms.

## Overview

SwiftAzureOpenAI provides Swift-native models and utilities for working with the Azure OpenAI Responses API. The Responses API is a stateful API from Azure OpenAI that brings together the best capabilities from the chat completions and assistants API in one unified experience.

This package emphasizes strongly typed request/response models, response metadata extraction, and streaming-friendly types, designed specifically for Apple platforms and Swift development.

## Features

- 🚀 **Azure OpenAI Responses API**: Unified request/response models aligned with the latest Azure OpenAI Responses API
- 🔄 **Full Async/Await Support**: Modern Swift concurrency with async response processing and streaming
- 📡 **Real-time Streaming**: Built-in support for streaming responses with `StreamingResponseChunk` and SSE parsing
- 🎯 **Python-style API**: Simple, intuitive API similar to OpenAI Python SDK for quick integration
- 🛡️ **Typed errors**: Clear error modeling with `OpenAIError` and `ErrorResponse`
- 🧩 **Structured content**: Input and output content parts (text, images, multi-modal support)
- 📊 **Metadata extraction**: Built-in support for response metadata and rate limits
- 🌐 **Cross-platform**: Works with both Azure OpenAI and OpenAI services
- 📦 **Swift Package Manager**: Easy integration with SPM
- 🔐 **Secure**: Support for Azure authentication patterns

## Requirements

- iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ / tvOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## API Support

This package is designed for the Azure OpenAI Responses API (Preview) and OpenAI Responses API. The Responses API provides a unified experience that combines the best capabilities from chat completions and assistants APIs.

### Supported Models

The Responses API supports a wide range of models including:

**GPT-5 Series:**
- `gpt-5` (Version: `2025-08-07`)
- `gpt-5-mini` (Version: `2025-08-07`)
- `gpt-5-nano` (Version: `2025-08-07`)
- `gpt-5-chat` (Version: `2025-08-07`)

**GPT-4 Series:**
- `gpt-4o` (Versions: `2024-11-20`, `2024-08-06`, `2024-05-13`)
- `gpt-4o-mini` (Version: `2024-07-18`)
- `gpt-4.1` (Version: `2025-04-14`)
- `gpt-4.1-nano` (Version: `2025-04-14`)
- `gpt-4.1-mini` (Version: `2025-04-14`)

**Reasoning Models:**
- `o1` (Version: `2024-12-17`)
- `o3-mini` (Version: `2025-01-31`)
- `o3` (Version: `2025-04-16`)
- `o4-mini` (Version: `2025-04-16`)

**Specialized Models:**
- `computer-use-preview`
- `gpt-image-1` (Version: `2025-04-15`)

> **Note:** Model availability varies by region. Check the [Azure OpenAI models documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models) for the latest model and region availability.

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
- **🎉 Simple Python-style API** (Recommended) - For easy, quick async usage
- **📡 Full Streaming Support** - Real-time response streaming with built-in SSE parsing
- **Advanced API** - For complex scenarios requiring full control

### Import the Package

```swift
import SwiftAzureOpenAI
```

### 🆕 Improved Class Names (v2.0+)

SwiftAzureOpenAI v2.0 introduces improved class names with the `SAOAI` prefix to resolve naming conflicts and improve clarity:

**New Recommended Names:**
- `SAOAIClient` (main client class)
- `SAOAIResponse` (fixes confusing "ResponsesResponse" name)
- `SAOAIRequest`, `SAOAIMessage`, `SAOAIOutput`
- `SAOAIConfiguration`, `SAOAIAzureConfiguration`, `SAOAIOpenAIConfiguration`
- `SAOAIError`, `SAOAIJSONValue` (prevents conflicts with Foundation/other libraries)

**Full Backward Compatibility:**
All old class names are still supported via deprecated aliases, so existing code continues to work without changes.

```swift
// ✅ New recommended syntax
let client = SAOAIClient(configuration: SAOAIAzureConfiguration(...))
let response: SAOAIResponse = try await client.responses.create(...)

// ✅ Legacy syntax (still works, shows deprecation warnings)
let client = SwiftAzureOpenAI(configuration: AzureOpenAIConfiguration(...))
let response: ResponsesResponse = try await client.responses.create(...)
```

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
    model: "gpt-4o-mini",
    input: "Write a haiku about Swift programming.",
    maxOutputTokens: 200,
    temperature: 0.7
)

// Extract the response text
if let output = response.output.first,
   let content = output.content.first,
   case let .outputText(text) = content {
    print(text.text)
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
    model: "gpt-4o-mini",
    input: messages,
    maxOutputTokens: 300
)
```

### 📡 Streaming Responses

SwiftAzureOpenAI provides full support for real-time streaming responses:

```swift
// Enable streaming for real-time response processing
let response = try await client.responses.create(
    model: "gpt-4o-mini",
    input: "Write a story about space exploration",
    maxOutputTokens: 500,
    stream: true  // Enable streaming
)

// Process streaming chunks as they arrive
for try await chunk in response.stream {
    if let content = chunk.chunk.output.first?.content.first,
       case let .outputText(text) = content {
        print(text.text, terminator: "")  // Print text as it streams
        fflush(stdout)  // Flush output for real-time display
    }
}
```

### Reasoning Models Support

For reasoning models like `o1`, `o3-mini`, `o4-mini`, you can specify reasoning effort:

```swift
// Create reasoning configuration
let reasoning = Reasoning(effort: "medium") // "low", "medium", "high"

// Use with simple string input
let response = try await client.responses.create(
    model: "o4-mini",
    input: "What is the weather like today?",
    maxOutputTokens: 100,
    reasoning: reasoning
)

// Or with message arrays
let response = try await client.responses.create(
    model: "o3-mini", 
    input: messages,
    maxOutputTokens: 300,
    reasoning: Reasoning(effort: "high")
)
```

### Retrieve and Delete Responses

```swift
// Retrieve a response by ID
let retrieved = try await client.responses.retrieve("resp_abc123")

// Delete a response
let deleted = try await client.responses.delete("resp_abc123")
```

### Advanced: Build a Responses API request (Legacy)

For advanced use cases, you can still use the detailed API:

```swift
let request = SAOAIRequest(
    model: "gpt-4o-mini", // Azure: deployment name; OpenAI: model name
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

The `input` parameter uses an array of `SAOAIMessage` objects, each containing structured content parts. This unified approach replaces the separate `messages` parameter from the legacy chat completions API.

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
    for part in output.content {
        switch part {
        case .outputText(let text):
            print(text.text)
        }
    }
}
```

### Streaming model support (types)

This package provides `StreamingResponseChunk<T>` for representing streamed decoding results. You can adapt your networking layer (e.g., SSE) to yield `StreamingResponseChunk<SAOAIResponse>` items as they become available.

```swift
func processStream(chunks: AsyncThrowingStream<Data, Error>) async throws {
    var sequence = 0
    for try await data in chunks {
        let partial = try JSONDecoder().decode(SAOAIResponse.self, from: data)
        let chunk = StreamingResponseChunk(
            chunk: partial,
            isComplete: false, // set true when your parser detects completion
            sequenceNumber: sequence
        )
        sequence += 1
        // handle chunk
    }
}
```

## Data Models

The Responses API uses a unified data model structure that consolidates the best features from chat completions and assistants APIs:

### Request Models

- **`SAOAIRequest`** - Main request payload for the Responses API
  - `model: String?` — Azure deployment name or OpenAI model name
  - `input: [SAOAIMessage]` — Unified message array with structured content parts
  - `maxOutputTokens: Int?` — Maximum tokens to generate in the response
  - `temperature: Double?`, `topP: Double?` — Sampling parameters
  - `tools: [SAOAITool]?` — Optional tool definitions for function calling
  - `reasoning: SAOAIReasoning?` — Reasoning configuration for reasoning models

- **`SAOAIReasoning`** - Reasoning configuration for reasoning models
  - `effort: String` — Reasoning effort level: "low", "medium", or "high"

- **`SAOAIMessage`** - Individual message in the conversation
  - `role: SAOAIMessageRole` — Message role: `.system`, `.user`, `.assistant`, or `.tool`
  - `content: [SAOAIInputContent]` — Array of structured content parts

- **`SAOAIInputContent`** - Structured input content
  - `.inputText(SAOAIInputText)` — Text content: `{ type: "input_text", text: "..." }`
  - `.inputImage(SAOAIInputImage)` — Image content: `{ type: "input_image", image_url: "..." }`

### Response Models

- **`SAOAIResponse`** - Main response payload from the Responses API
  - `id: String?` — Unique response identifier
  - `model: String?` — Model used for the response
  - `created: Int?` — Creation timestamp
  - `output: [SAOAIOutput]` — Array of output content from the assistant
  - `usage: SAOAITokenUsage?` — Token consumption details

- **`SAOAIOutput`** - Assistant's output content
  - `content: [SAOAIOutputContent]` — Array of output content parts
  - `role: String?` — Output role (typically "assistant")

- **`SAOAIOutputContent`** - Structured output content
  - `.outputText(SAOAIOutputText)` — Text output: `{ type: "output_text", text: "..." }`

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

- **`OpenAIError`**, **`ErrorResponse`** - Error handling
  - Typed errors for network, decoding, and server-reported issues

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
    apiVersion: "preview" // Latest preview API version for Responses API
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
let openaiConfig = OpenAIServiceConfiguration(
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
} catch let error as OpenAIError {
    print(error.localizedDescription)
} catch let error as DecodingError {
    throw OpenAIError.decodingError(error)
} catch {
    throw OpenAIError.networkError(error)
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
export AZURE_OPENAI_API_KEY="your-azure-api-key"
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
          let apiKey = ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"],
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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 Documentation: project README (this file) and [docs/](docs/) directory
- 🧪 Live API Testing: [Live API Testing Guide](docs/LIVE_API_TESTING.md)
- 🐛 Issues: [GitHub Issues](https://github.com/ytthuan/SwiftAzureOpenAI/issues)
- 📚 Azure OpenAI Responses API: [Official Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference-preview-latest#create-response)

---

**Note:** This package is community-maintained and not officially affiliated with OpenAI or Microsoft. It provides Swift-native data models specifically designed for the Azure OpenAI Responses API and OpenAI Responses API. The Responses API represents the latest unified approach that combines the best capabilities from chat completions and assistants APIs.