# SwiftAzureOpenAI

A Swift package focused on the Azure OpenAI/OpenAI Responses API for iOS, macOS, watchOS, tvOS, and other Apple platforms.

> **⚠️ Internal Development Notice**: This SDK is currently under active internal development and testing. It is not yet published or intended for external production use. The API surface and features are subject to change as we complete our internal roadmap.

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
- Swift 6.0+ (currently developed with Swift 6.2)

## API Support

This package targets the Azure/OpenAI Responses API. It is model-agnostic; use the deployment or model name appropriate for your account. Examples below use `gpt-4o`/`gpt-4o-mini`.

> Check the Azure models documentation for availability: https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models

### File API Support

SwiftAzureOpenAI includes comprehensive support for the Azure OpenAI File API, enabling file upload, management, and integration with the Responses API:

- 📁 **File Upload**: Upload documents, images, and data files  
- 📋 **File Management**: List, retrieve, and delete files
- 🔗 **Responses Integration**: Reference uploaded files in conversations
- 🎯 **Direct File Input**: Include file data directly in requests
- 📡 **Streaming Downloads**: Stream large file content in chunks
- 🛡️ **Type Safety**: Strongly typed file operations and responses

Supported operations:
- `client.files.create()` - Upload files
- `client.files.list()` - List all files  
- `client.files.retrieve()` - Get file details
- `client.files.delete()` - Remove files
- `client.files.streamContent()` - Stream file content for large downloads

## Installation (Internal Development)

> **Note**: This package is not yet published to public package managers. For internal development and testing, use local package references or direct GitHub integration.

### Swift Package Manager

For internal development, add SwiftAzureOpenAI as a local package or via GitHub:

```swift
dependencies: [
    .package(url: "https://github.com/ytthuan/SwiftAzureOpenAI", branch: "main")
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
- `EmbeddingsClient` (embeddings client at `client.embeddings`)
- `FilesClient` (files client at `client.files`)
- `SAOAIAzureConfiguration`, `SAOAIOpenAIConfiguration`
- `SAOAIRequest`, `SAOAIResponse`, `SAOAIMessage` (request/response models)
- `SAOAIEmbeddingsRequest`, `SAOAIEmbeddingsResponse` (embeddings models)
- `EmbeddingBatchHelper` (batch processing utilities)
- `ResponseCacheService` (caching with TTL support)
- `MetricsDelegate` (observability and performance tracking)
- `SAOAIRequest`, `SAOAIMessage`, `SAOAIInputContent`
- `SAOAIResponse`, `SAOAIOutput`, `SAOAIOutputContent`
- `SAOAIStreamingResponse` (SSE events)
- `SAOAIEmbeddingsRequest`, `SAOAIEmbeddingsResponse`, `SAOAIEmbedding`
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

### 🔍 Vector Embeddings

SwiftAzureOpenAI provides comprehensive embeddings support with built-in similarity utilities:

```swift
// Create embeddings for a single text
let response = try await client.embeddings.create(
    text: "Swift is a powerful programming language",
    model: "text-embedding-ada-002" // Azure: deployment name
)

// Access the embedding vector
let embedding = response.data.first!
print("Embedding dimensions: \(embedding.dimensions)")
print("Embedding vector: \(embedding.vector)")
```

#### Batch Embeddings

```swift
let texts = [
    "Swift programming language",
    "Python programming language", 
    "Machine learning algorithms",
    "Database management systems"
]

let response = try await client.embeddings.create(
    texts: texts,
    model: "text-embedding-ada-002"
)

// Process all embeddings
for embedding in response.data {
    print("Text \(embedding.index): \(embedding.dimensions) dims")
}
```

#### Cosine Similarity & Vector Operations

```swift
let embedding1 = response.data[0]
let embedding2 = response.data[1]

// Calculate similarity (returns value between -1.0 and 1.0)
let similarity = embedding1.cosineSimilarity(with: embedding2)
print("Similarity: \(similarity)")

// Other distance metrics
let euclideanDist = embedding1.euclideanDistance(with: embedding2)
let dotProduct = embedding1.dotProduct(with: embedding2)
```

#### Semantic Search

```swift
let documents = [
    "Swift is used for iOS development",
    "Python is popular for AI and ML",
    "JavaScript runs in web browsers",
    "Rust focuses on memory safety"
]

// Find documents most similar to a query
let results = try await client.embeddings.semanticSearch(
    query: "mobile app development",
    documents: documents,
    model: "text-embedding-ada-002",
    threshold: 0.7
)

for result in results {
    print("Document: \(result.document) (similarity: \(result.similarity))")
}
```

#### Advanced Similarity Search

```swift
// Find top-K most similar texts
let similarities = try await client.embeddings.findSimilar(
    query: "artificial intelligence",
    candidates: documents,
    model: "text-embedding-ada-002",
    topK: 3
)

for (text, index, similarity) in similarities {
    print("Rank \(index + 1): \(text) (\(similarity))")
}
```

### 🛠️ Ergonomics and Observability Utilities

SwiftAzureOpenAI provides production-ready utilities for enhanced developer experience and observability:

#### Embedding Batch Helper

Process large sets of texts efficiently with automatic batching, concurrency control, and retry logic:

```swift
// Setup
let cache = EmbeddingCache(maxCapacity: 10000)
let batchHelper = EmbeddingBatchHelper(
    embeddingsClient: client.embeddings,
    cache: cache
)

// Process many texts efficiently
let texts = ["Text 1", "Text 2", "Text 3", /* ... hundreds more ... */]

let result = try await batchHelper.processEmbeddings(
    texts: texts,
    model: "text-embedding-ada-002",
    configuration: .highThroughput // or .default, .conservative
) { progress in
    print("Progress: \(Int(progress * 100))%")
}

print("Processed \(result.embeddings.count) embeddings")
print("Success rate: \(Int(result.successRate * 100))%")
print("Throughput: \(result.statistics.throughput(for: texts.count)) items/second")
```

Configuration options:
- **Default**: 5 concurrent requests, batch size 100
- **High Throughput**: 10 concurrent requests, batch size 200  
- **Conservative**: 2 concurrent requests, batch size 50

#### In-Memory Embedding Cache

Automatic caching with TTL and LRU eviction:

```swift
let cache = EmbeddingCache(maxCapacity: 5000)

// Cache embeddings automatically when using batch helper
// Or manually:
cache.cacheEmbedding(embedding, for: "text", model: "model", expiresIn: 3600)

// Retrieve cached embeddings
if let cached = cache.getCachedEmbedding(for: "text", model: "model") {
    print("Cache hit! Vector: \(cached.embedding.prefix(3))")
}

// Monitor cache performance
let stats = cache.statistics
print("Hit rate: \(Int(stats.hitRate * 100))%")
print("Utilization: \(Int(stats.utilization * 100))%")
```

#### Metrics Delegation and Correlation Logging

Track request performance and enable distributed tracing:

```swift
// Setup observability
let metricsDelegate = ConsoleMetricsDelegate(logLevel: .verbose)
let aggregatingDelegate = AggregatingMetricsDelegate()

// Create client with metrics integration
let client = SAOAIClient(
    configuration: config,
    metricsDelegate: metricsDelegate
)

// Or use the factory method
let responsesClient = ResponsesClient.create(
    configuration: config,
    metricsDelegate: metricsDelegate
)

// Requests automatically generate correlation IDs and emit metrics
let response = try await client.responses.create(...)

// Access aggregated statistics
let stats = aggregatingDelegate.statistics
print("Success rate: \(Int(stats.successRate * 100))%")
print("Average duration: \(String(format: "%.3fs", stats.averageRequestDuration))")
```

Available metrics delegates:
- **ConsoleMetricsDelegate**: Logs events to console with correlation IDs
- **AggregatingMetricsDelegate**: Collects statistics for analysis
- **Custom**: Implement `MetricsDelegate` for integration with your monitoring system

#### Complete Example

See `examples/ErgonomicsUtilitiesExample.swift` for a comprehensive example demonstrating:
- Batch processing with different configurations
- Caching benefits and performance improvements  
- Metrics collection and correlation ID tracking
- Integration of all utilities in a production workflow

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

## Azure OpenAI File API Examples

### Upload and Use Files

```swift
import SwiftAzureOpenAI

func fileAPIExample() async throws {
    // Configure client
    let config = SAOAIAzureConfiguration(
        endpoint: "https://your-resource.openai.azure.com",
        apiKey: "your-api-key",
        deploymentName: "gpt-4o",
        apiVersion: "preview"
    )
    
    let client = SAOAIClient(configuration: config)
    
    // Upload a file
    let fileData = try Data(contentsOf: URL(fileURLWithPath: "document.pdf"))
    let file = try await client.files.create(
        file: fileData,
        filename: "document.pdf",
        purpose: .assistants  // Use .assistants as workaround for .userData
    )
    
    print("Uploaded file: \(file.id)")
    
    // Use the file in a conversation
    let fileInput = SAOAIInputContent.inputFile(.init(fileId: file.id))
    let textInput = SAOAIInputContent.inputText(.init(text: "Summarize this document"))
    
    let message = SAOAIMessage(
        role: .user,
        content: [fileInput, textInput]
    )
    
    let response = try await client.responses.create(
        model: "gpt-4o",
        input: [.message(message)]
    )
    
    print("Summary: \(response.outputText ?? "")")
    
    // List all files
    let fileList = try await client.files.list()
    print("Found \(fileList.data.count) files")
    
    // Delete the file when done
    let deleteResult = try await client.files.delete(file.id)
    print("File deleted: \(deleteResult.deleted)")
}
```

### Streaming File Downloads

For large files, you can stream file content in chunks rather than loading the entire file into memory:

```swift
// Stream file content for large files
let stream = client.files.streamContent("file-abc123")

// Process chunks as they arrive
for try await chunk in stream {
    // Process data chunk (e.g., write to file, parse incrementally)
    print("Received chunk of \(chunk.count) bytes")
    
    // Example: Write to local file
    // fileHandle.write(chunk)
}

print("File download completed")
```

### Direct File Input (Base64)

```swift
func directFileExample() async throws {
    let config = SAOAIAzureConfiguration(
        endpoint: "https://your-resource.openai.azure.com", 
        apiKey: "your-api-key",
        deploymentName: "gpt-4o",
        apiVersion: "preview"
    )
    
    let client = SAOAIClient(configuration: config)
    
    // Load image file
    let imageData = try Data(contentsOf: URL(fileURLWithPath: "chart.png"))
    let base64Image = imageData.base64EncodedString()
    
    // Include file directly in request (no upload needed)
    let fileInput = SAOAIInputContent.inputFile(.init(
        filename: "chart.png",
        base64Data: base64Image,
        mimeType: "image/png"
    ))
    
    let textInput = SAOAIInputContent.inputText(.init(text: "What does this chart show?"))
    
    let message = SAOAIMessage(
        role: .user,
        content: [fileInput, textInput]
    )
    
    let response = try await client.responses.create(
        model: "gpt-4o",
        input: [.message(message)]
    )
    
    print("Chart analysis: \(response.outputText ?? "")")
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 Documentation: project README (this file) and [docs/](docs/) directory
- 🧪 Live API Testing: [Live API Testing Guide](docs/LIVE_API_TESTING.md)
- 🔧 Internal Development: [Contributing Guide](CONTRIBUTING.md) and [CI/CD Documentation](docs/CI-CD.md)
- 🐛 Issues: [GitHub Issues](https://github.com/ytthuan/SwiftAzureOpenAI/issues) (internal development tracking)
- 📚 Azure OpenAI Responses API: [Official Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference-preview-latest#create-response)

---

**Note:** This package is under active internal development and not officially affiliated with OpenAI or Microsoft. It provides Swift-native data models and client utilities designed for the Azure/OpenAI Responses API for internal use and testing.