# SwiftAzureOpenAI

A Swift package that provides seamless integration with Azure OpenAI and OpenAI APIs for iOS, macOS, watchOS, tvOS, and other Apple ecosystem applications.

## Overview

SwiftAzureOpenAI is designed to simplify the integration of OpenAI's powerful language models into your Apple ecosystem applications. Whether you're using Azure OpenAI Service or OpenAI's direct API, this package provides a unified, Swift-native interface that feels natural to iOS and macOS developers.

## Features

- 🚀 **Unified API**: Single interface for both Azure OpenAI and OpenAI endpoints
- 🍎 **Apple Ecosystem**: Full support for iOS, macOS, watchOS, and tvOS
- 🔄 **Async/Await**: Modern Swift concurrency support
- 🛡️ **Type Safety**: Strongly typed Swift models for all API interactions
- 📱 **Swift Package Manager**: Easy integration with SPM
- 🔐 **Secure**: Built-in secure credential handling
- ⚡ **Lightweight**: Minimal dependencies and efficient networking
- 🧪 **Testable**: Comprehensive test suite and mockable interfaces

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

### Azure OpenAI Configuration

```swift
// Configure for Azure OpenAI
let azureConfig = AzureOpenAIConfiguration(
    endpoint: "https://your-resource.openai.azure.com",
    apiKey: "your-api-key",
    deploymentName: "your-deployment-name",
    apiVersion: "2024-02-01"
)

let client = SwiftAzureOpenAI(configuration: azureConfig)
```

### OpenAI Configuration

```swift
// Configure for OpenAI
let openAIConfig = OpenAIConfiguration(
    apiKey: "your-openai-api-key",
    organization: "your-org-id" // Optional
)

let client = SwiftAzureOpenAI(configuration: openAIConfig)
```

### Basic Chat Completion

```swift
import SwiftAzureOpenAI

class ChatService {
    private let client: SwiftAzureOpenAI
    
    init() {
        let config = AzureOpenAIConfiguration(
            endpoint: "https://your-resource.openai.azure.com",
            apiKey: "your-api-key",
            deploymentName: "gpt-4",
            apiVersion: "2024-02-01"
        )
        self.client = SwiftAzureOpenAI(configuration: config)
    }
    
    func sendMessage(_ message: String) async throws -> String {
        let request = ChatCompletionRequest(
            messages: [
                .system("You are a helpful assistant."),
                .user(message)
            ],
            model: "gpt-4",
            maxTokens: 150
        )
        
        let response = try await client.createChatCompletion(request: request)
        return response.choices.first?.message.content ?? ""
    }
}
```

### Streaming Chat Completion

```swift
func streamChat(_ message: String) async throws {
    let request = ChatCompletionRequest(
        messages: [.user(message)],
        model: "gpt-4",
        stream: true
    )
    
    for try await chunk in client.createChatCompletionStream(request: request) {
        if let content = chunk.choices.first?.delta.content {
            print(content, terminator: "")
        }
    }
}
```

## API Reference

### Core Classes

#### `SwiftAzureOpenAI`
The main client class for interacting with OpenAI APIs.

#### `AzureOpenAIConfiguration`
Configuration for Azure OpenAI Service endpoints.

#### `OpenAIConfiguration`
Configuration for direct OpenAI API endpoints.

### Chat Completions

```swift
// Create a chat completion
func createChatCompletion(request: ChatCompletionRequest) async throws -> ChatCompletionResponse

// Create a streaming chat completion
func createChatCompletionStream(request: ChatCompletionRequest) -> AsyncThrowingStream<ChatCompletionChunk, Error>
```

### Embeddings

```swift
// Create embeddings
func createEmbeddings(request: EmbeddingRequest) async throws -> EmbeddingResponse
```

### Text Completions

```swift
// Create text completion (for legacy models)
func createCompletion(request: CompletionRequest) async throws -> CompletionResponse
```

## Configuration Examples

### Environment Variables

```swift
// Using environment variables for security
let config = AzureOpenAIConfiguration(
    endpoint: ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] ?? "",
    apiKey: ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ?? "",
    deploymentName: ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? "",
    apiVersion: "2024-02-01"
)
```

### iOS App Configuration

```swift
// In your iOS app, store credentials securely
class OpenAIService: ObservableObject {
    private let client: SwiftAzureOpenAI
    
    init() {
        // Retrieve from Keychain or secure storage
        let apiKey = KeychainHelper.retrieve(key: "openai_api_key")
        let config = OpenAIConfiguration(apiKey: apiKey)
        self.client = SwiftAzureOpenAI(configuration: config)
    }
}
```

## Error Handling

```swift
do {
    let response = try await client.createChatCompletion(request: request)
    // Handle success
} catch let error as OpenAIError {
    switch error {
    case .invalidAPIKey:
        print("Invalid API key")
    case .rateLimitExceeded:
        print("Rate limit exceeded")
    case .serverError(let statusCode):
        print("Server error: \(statusCode)")
    default:
        print("Other OpenAI error: \(error)")
    }
} catch {
    print("Network or other error: \(error)")
}
```

## Supported Models

### Azure OpenAI
- GPT-4 and GPT-4 Turbo
- GPT-3.5 Turbo
- Embeddings models (text-embedding-ada-002, etc.)
- DALL-E (where available)

### OpenAI
- All current OpenAI models including:
  - GPT-4 and GPT-4 Turbo
  - GPT-3.5 Turbo
  - Embeddings models
  - DALL-E 2 and DALL-E 3

## Best Practices

### Security
- Never hardcode API keys in your source code
- Use environment variables or secure storage (Keychain on iOS/macOS)
- Implement proper error handling for authentication failures

### Performance
- Use streaming for long-form content generation
- Implement proper retry logic with exponential backoff
- Cache embeddings when appropriate

### Rate Limiting
- Implement client-side rate limiting to respect API quotas
- Handle rate limit errors gracefully with retry mechanisms

## Example Apps

Check out the `Examples` directory for complete sample applications:

- **iOS Chat App**: Full-featured chat interface
- **macOS Text Editor**: AI-powered writing assistant
- **Command Line Tool**: Simple CLI for API testing

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

Run the test suite:

```bash
swift test
```

For testing with live APIs, set up your test configuration:

```bash
export AZURE_OPENAI_ENDPOINT="your-test-endpoint"
export AZURE_OPENAI_API_KEY="your-test-key"
export AZURE_OPENAI_DEPLOYMENT="your-test-deployment"
swift test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](https://github.com/ytthuan/SwiftAzureOpenAI/wiki)
- 🐛 [Report Issues](https://github.com/ytthuan/SwiftAzureOpenAI/issues)
- 💬 [Discussions](https://github.com/ytthuan/SwiftAzureOpenAI/discussions)

## Acknowledgments

- OpenAI for providing the API
- Microsoft Azure for Azure OpenAI Service
- The Swift community for excellent package management tools

---

**Note**: This package is not officially affiliated with OpenAI or Microsoft. It's a community-driven Swift package for easier integration with OpenAI services.