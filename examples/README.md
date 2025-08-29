# SwiftAzureOpenAI Examples

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

### 2. [PythonStyleAPI](PythonStyleAPI/)
Demonstrates the new simplified Python-style API:
- Simple string input: `client.responses.create(model: ..., input: "text")`
- Convenience message creation: `SAOAIMessage(role: .user, text: "...")`
- Python-style operations: `retrieve()`, `delete()`
- Before/after comparisons showing API simplification

**Usage:**
```bash
cd PythonStyleAPI
swift run
```

### 3. [MultiModalAndChaining](MultiModalAndChaining/)
Shows multi-modal input and response chaining:
- Image URL support: `SAOAIMessage(role: .user, text: "analyze this", imageURL: "...")`
- Base64 image support: `SAOAIMessage(role: .user, text: "analyze this", base64Image: data)`
- Response chaining with `previousResponseId`
- Complex multi-step workflows

**Usage:**
```bash
cd MultiModalAndChaining
swift run
```

### 4. [FunctionCalling](FunctionCalling/)
Demonstrates function calling capabilities:
- Function definition with `SAOAITool.function()`
- Function call handling from AI responses
- Multiple function support
- Python-style patterns for familiarity

**Usage:**
```bash
cd FunctionCalling
swift run
```

### 5. [AdvancedConsoleChatbot](AdvancedConsoleChatbot/) ⭐ **NEW**
A comprehensive interactive console chatbot demonstrating **all** SwiftAzureOpenAI features:
- 🌊 **Streaming output simulation** with word-by-word display
- 🔧 **Function calling** (weather API, calculator)
- 🐍 **Code interpreter tool** with Python execution simulation
- 🖼️ **Multi-modal support** (image URLs and base64)
- 📚 **Conversation history** with response chaining
- 🎮 **Interactive commands** and specialized syntax
- 🛠️ **Complete tooling ecosystem** in one example

**Usage:**
```bash
cd AdvancedConsoleChatbot
swift run
```

**Example Commands:**
- `weather:London` - Get weather information
- `code:print('Hello, World!')` - Execute Python code
- `calc:sqrt(64)` - Mathematical calculations
- `image:https://example.com/photo.jpg` - Analyze images

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
   cd ConsoleChatbot  # or any other example
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

All examples demonstrate the latest SwiftAzureOpenAI v2.0+ features:
- **SAOAI-prefixed class names**: `SAOAIClient`, `SAOAIMessage`, etc.
- **Python-style convenience methods**: Simplified API calls
- **Multi-modal support**: Text + images in single requests
- **Response chaining**: Use `previousResponseId` for context
- **Function calling**: Tool integration with AI responses
- **Streaming support**: Real-time response processing
- **Code interpreter tools**: Execute code within AI workflows
- **Full backward compatibility**: Complex patterns still supported

### ⭐ Featured Example: AdvancedConsoleChatbot

The [AdvancedConsoleChatbot](AdvancedConsoleChatbot/) is a **comprehensive demonstration** of all SDK capabilities in a single, interactive application. It's perfect for:

- **Learning**: See all features working together in realistic scenarios
- **Testing**: Validate SDK functionality with live interactions
- **Reference**: Use as a complete implementation guide
- **Development**: Copy patterns for your own applications

## Requirements

- Swift 6.0+
- Xcode 15.0+ (for iOS development)
- macOS 10.15+ / iOS 13.0+ / watchOS 6.0+ / tvOS 13.0+

Each example can run in demo mode without API credentials and will show you what it would do with real API access.