# SwiftAzureOpenAI Examples

> **⚠️ Internal Development**: These examples are part of our internal development and testing process. They demonstrate the latest SDK capabilities but are not intended for external production use.

This directory contains complete, compilable Swift Package examples demonstrating SwiftAzureOpenAI capabilities. Each example is a standalone Swift package that you can download, build, and run independently.

## Available Examples

### 1. [ConsoleChatbot](ConsoleChatbot/)
A complete interactive console chatbot demonstrating:
- Interactive console interface with real-time user input/output
- Chat history chaining with `previousResponseId`
- Multi-modal support (text + images)
- Command handling (`history`, `clear`, `quit`)
- Environment variable configuration
- Error handling and validation

**Usage:**
```bash
cd ConsoleChatbot
swift run
```

### 2. [ResponsesConsoleChatbot](ResponsesConsoleChatbot/)
A console chatbot using the Responses API with both streaming and non-streaming modes, featuring user-controlled function calling:
- Real-time streaming and blocking non-streaming modes (switchable via flags)
- User-controlled function calling (no automatic loops)
- Code interpreter and custom function tools
- Flexible reasoning configuration
- Complete feature parity between streaming/non-streaming

**Usage:**
```bash
cd ResponsesConsoleChatbot
swift run ResponsesConsoleChatbot --streaming      # Real-time mode (default)
swift run ResponsesConsoleChatbot --non-streaming  # Blocking mode
```

### 3. [NonStreamingResponseConsoleChatbot](NonStreamingResponseConsoleChatbot/)
A **simplified, non-streaming only** version of the Responses API console chatbot:
- Non-streaming mode only (no streaming complexity)
- User-controlled function calling with max 5 rounds
- Same tools and features as ResponsesConsoleChatbot but focused on blocking responses
- Easier to understand and customize for non-streaming use cases

**Usage:**
```bash
cd NonStreamingResponseConsoleChatbot
swift run NonStreamingResponseConsoleChatbot
swift run NonStreamingResponseConsoleChatbot --message "calculate 10 plus 22"
```

## File API Integration

All examples support the Azure OpenAI File API for document analysis and multi-modal conversations:

### Upload and Analyze Files

```swift
// In any of the console chatbot examples
let client = SAOAIClient(configuration: config)

// Upload a document
let fileData = try Data(contentsOf: URL(fileURLWithPath: "report.pdf"))
let file = try await client.files.create(
    file: fileData,
    filename: "report.pdf", 
    purpose: .assistants
)

// Reference the file in conversation
let response = try await client.responses.create(
    model: deploymentName,
    input: "Analyze the uploaded report and summarize key findings",
    // Reference the uploaded file by including its ID in the input:
    files: [file.id] // Pass the file ID(s) to associate with the request
)
```

### Direct File Input

```swift
// Include file data directly without uploading
let inputFile = SAOAIInputContent.inputFile(.init(
    filename: "chart.png",
    base64Data: imageData.base64EncodedString(),
    mimeType: "image/png"
))

let message = SAOAIMessage(
    role: .user, 
    content: [inputFile, textInput]
)
```

### File Management

```swift
// List all uploaded files
let fileList = try await client.files.list()
print("Found \(fileList.data.count) files")

// Retrieve specific file details  
let file = try await client.files.retrieve("file-abc123")

// Delete files when done
let result = try await client.files.delete("file-abc123")

 

## How These Examples Work

Each example is a complete Swift Package that:
1. **Dependencies**: Uses the parent SwiftAzureOpenAI package as a dependency
2. **Executables**: Contains a `main.swift` that can be run with `swift run`
3. **Documentation**: Has its own README explaining features and usage
4. **Compilation**: Can be built independently with `swift build`

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ytthuan/SwiftAzureOpenAI.git
   cd SwiftAzureOpenAI/examples
   ```

2. **Choose an example**:
   ```bash
   cd ConsoleChatbot                        # Basic interactive chatbot
   cd ResponsesConsoleChatbot              # Streaming + non-streaming modes
   cd NonStreamingResponseConsoleChatbot   # Non-streaming only (simplified)
   ```

3. **Build and run**:
   ```bash
   swift build
   swift run
   ```

4. **For live API testing** (optional):
   ```bash
   export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
   export AZURE_OPENAI_API_KEY="your-api-key"
   export AZURE_OPENAI_DEPLOYMENT="gpt-4o"
   swift run
   ```

## Modern API Features

All examples demonstrate the current SwiftAzureOpenAI SDK features:
- **SAOAI-prefixed class names**: `SAOAIClient`, `SAOAIMessage`, etc.
- **Python-style convenience methods**: Simplified API calls
- **Multi-modal support**: Text + images in single requests
- **Response chaining**: Use `previousResponseId` for context
- **Function calling**: Tool integration with AI responses
- **Streaming support**: Real-time response processing
- **Code interpreter tools**: Execute code within AI workflows

 

## Requirements

- Swift 6.0+
- Xcode 15.0+ (for iOS development)
- macOS 10.15+ / iOS 13.0+ / watchOS 6.0+ / tvOS 13.0+

Each example can run in demo mode without API credentials and will show you what it would do with real API access.

## Environment Variables for Testing

For internal development and live API testing, set these environment variables:

```bash
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
export AZURE_OPENAI_API_KEY="your-api-key"  
# Alternative: COPILOT_AGENT_AZURE_OPENAI_API_KEY
export AZURE_OPENAI_DEPLOYMENT="your-deployment-name"
```

## Current Status

All examples reflect the **current state** of the SwiftAzureOpenAI SDK after completing the internal roadmap phases. They demonstrate production-ready APIs including:

- Modern async/await Swift 6.0 concurrency
- Complete Responses API implementation 
- Full Azure OpenAI File API integration
- Vector embeddings with batch processing
- Streaming and non-streaming modes
- Advanced error handling and observability