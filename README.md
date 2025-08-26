# SwiftAzureOpenAI

A Swift package focused on the Azure OpenAI/OpenAI Responses API for iOS, macOS, watchOS, tvOS, and other Apple platforms.

## Overview

SwiftAzureOpenAI provides Swift-native models and utilities for working with the Responses API as described in Microsoft's Azure OpenAI documentation. It emphasizes strongly typed request/response models, response metadata extraction, and streaming-friendly types.

## Features

- 🚀 **Responses API-first**: Unified request/response models aligned with the Responses API
- 🔄 **Async/Await-ready**: Modern Swift concurrency-friendly data types
- 🛡️ **Typed errors**: Clear error modeling with `OpenAIError` and `ErrorResponse`
- 🧩 **Structured content**: Input and output content parts (text, images)
- 📊 **Metadata extraction-ready**: Models for response metadata and rate limits
- 📦 **Swift Package Manager**: Easy integration with SPM

## Requirements

- iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ / tvOS 13.0+
- Xcode 15.0+
- Swift 5.9+

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

### Import the Package

```swift
import SwiftAzureOpenAI
```

### Build a Responses API request

```swift
import SwiftAzureOpenAI

let request = ResponsesRequest(
    model: "gpt-4o-mini", // Azure: deployment name; OpenAI: model name
    input: [
        ResponseMessage(
            role: .system,
            content: [ .inputText(.init(text: "You are a helpful assistant.")) ]
        ),
        ResponseMessage(
            role: .user,
            content: [ .inputText(.init(text: "Write a haiku about Swift.")) ]
        )
    ],
    maxOutputTokens: 200,
    temperature: 0.7
)
```

### Decode a Responses API response

Use your preferred HTTP stack to send requests and decode responses into the provided models:

```swift
import Foundation
import SwiftAzureOpenAI

let decoder = JSONDecoder()
// Configure if needed, e.g. date decoding strategy depending on your metadata usage.

func handleResponse(data: Data, httpResponse: HTTPURLResponse) throws -> APIResponse<ResponsesResponse> {
    // Extract any metadata you collect from headers and timing
    let rateLimit = RateLimitInfo(remaining: nil, resetTime: nil, limit: nil)
    let metadata = ResponseMetadata(
        requestId: httpResponse.allHeaderFields["x-request-id"] as? String,
        timestamp: Date(),
        processingTime: nil,
        rateLimit: rateLimit
    )

    let body = try decoder.decode(ResponsesResponse.self, from: data)
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
let apiResponse: APIResponse<ResponsesResponse> = /* from your network layer */
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

This package provides `StreamingResponseChunk<T>` for representing streamed decoding results. You can adapt your networking layer (e.g., SSE) to yield `StreamingResponseChunk<ResponsesResponse>` items as they become available.

```swift
func processStream(chunks: AsyncThrowingStream<Data, Error>) async throws {
    var sequence = 0
    for try await data in chunks {
        let partial = try JSONDecoder().decode(ResponsesResponse.self, from: data)
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

- `ResponsesRequest`
  - `model: String?` — Azure deployment or OpenAI model
  - `input: [ResponseMessage]` — messages with structured content parts
  - `maxOutputTokens: Int?`, `temperature: Double?`, `topP: Double?`, `tools: [ToolDefinition]?`
- `ResponseMessage`
  - `role: MessageRole` — `.system | .user | .assistant | .tool`
  - `content: [InputContentPart]`
- `InputContentPart`
  - `.inputText(InputText)` — `{ type: "input_text", text }`
  - `.inputImage(InputImage)` — `{ type: "input_image", image_url }`
- `ResponsesResponse`
  - `id: String?`, `model: String?`, `created: Int?`
  - `output: [ResponseOutput]` — array of content for the assistant's output
  - `usage: TokenUsage?` — token accounting
- `ResponseOutput`
  - `content: [OutputContentPart]`, `role: String?`
- `OutputContentPart`
  - `.outputText(OutputText)` — `{ type: "output_text", text }`
- `TokenUsage`
  - `inputTokens`, `outputTokens`, `totalTokens`
- `APIResponse<T>`
  - `data: T`, `metadata: ResponseMetadata`, `statusCode: Int`, `headers: [String: String]`
- `ResponseMetadata`
  - `requestId: String?`, `timestamp: Date`, `processingTime: TimeInterval?`, `rateLimit: RateLimitInfo?`
- `RateLimitInfo`
  - `remaining: Int?`, `resetTime: Date?`, `limit: Int?`
- `OpenAIError`, `ErrorResponse`
  - Typed errors for network, decoding, and server-reported issues

## Usage with Azure OpenAI and OpenAI

This package provides data models only. You can use any HTTP client (e.g., `URLSession`) to call either Azure OpenAI or OpenAI endpoints.

- **Azure OpenAI (Responses API)**
  - Endpoint: `https://{resource}.openai.azure.com/openai/responses?api-version=2024-10-21`
  - Headers: `api-key: <AZURE_API_KEY>`, `Content-Type: application/json`
  - Body: `ResponsesRequest` encoded as JSON

- **OpenAI (Responses API)**
  - Endpoint: `https://api.openai.com/v1/responses`
  - Headers: `Authorization: Bearer <OPENAI_API_KEY>`, `Content-Type: application/json`
  - Body: `ResponsesRequest` encoded as JSON

Example request sending with `URLSession` (sketch):

```swift
let json = try JSONEncoder().encode(request)
var url = URL(string: "https://api.openai.com/v1/responses")!
var urlRequest = URLRequest(url: url)
urlRequest.httpMethod = "POST"
urlRequest.httpBody = json
urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
urlRequest.setValue("Bearer YOUR_OPENAI_API_KEY", forHTTPHeaderField: "Authorization")

let (data, response) = try await URLSession.shared.data(for: urlRequest)
let httpResponse = response as! HTTPURLResponse
let apiResponse: APIResponse<ResponsesResponse> = try handleResponse(data: data, httpResponse: httpResponse)
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

```bash
swift test
```

For live testing, export environment variables for your client code (not provided by this package), then run your tests. Example:

```bash
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
export AZURE_OPENAI_API_KEY="your-azure-key"
export AZURE_OPENAI_DEPLOYMENT="your-deployment"
export OPENAI_API_KEY="your-openai-key"
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 Documentation: project README (this file)
- 🐛 Issues: GitHub Issues

---

Note: This package is community-maintained and not officially affiliated with OpenAI or Microsoft. It focuses on data models aligned to the Responses API specification.