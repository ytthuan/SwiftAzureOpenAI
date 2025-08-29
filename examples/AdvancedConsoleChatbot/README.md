# Advanced Console Chatbot Example

This is a comprehensive, interactive console chatbot demonstrating all major features of SwiftAzureOpenAI, including function calling, code interpreter tools, multimodal support, and real-time streaming.

## Features Demonstrated

### 🚀 Real-Time Streaming
- **Live Response Streaming**: See text appear word-by-word as the AI generates it
- **Server-Sent Events**: Uses OpenAI/Azure OpenAI streaming API
- **Immediate Feedback**: Real-time user experience with streaming responses

### 🔧 Function Calling
- **Weather API**: Get current weather for any location
- **Calculator**: Perform mathematical calculations 
- **Code Interpreter**: Execute Python code (simulated)

### 🐍 Code Interpreter Tool
- Execute Python code snippets
- Display execution results and timing
- Supports various code patterns (print statements, calculations, imports)

### 🖼️ Multi-Modal Support
- **Image URLs**: Analyze images from web URLs
- **Base64 Images**: Process base64-encoded image data
- Automatic image format detection and validation

### 📚 Conversation History
- Maintains complete conversation context
- Uses `previousResponseId` for proper response chaining
- Tracks tool calls and their results
- History viewing and clearing commands

### 🎮 Interactive Commands
- Specialized command syntax for different features
- Help system with usage examples
- Error handling and user guidance

## How to Run

1. **Clone this example**:
   ```bash
   cd examples/AdvancedConsoleChatbot
   ```

2. **Set environment variables** (optional - runs in demo mode without them):
   ```bash
   export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
   export AZURE_OPENAI_API_KEY="your-api-key"
   export AZURE_OPENAI_DEPLOYMENT="gpt-4o"
   ```

3. **Build and run**:
   ```bash
   swift run
   ```

## Usage Examples

### Basic Text Chat
```
👤 You: Hello, how are you doing today?
🤖 Assistant: Hello! I'm doing well, thank you for asking...
```

### Weather Function Calling
```
👤 You: weather:London
🤖 Assistant: 🔧 Calling tool: get_weather
The current weather in London is 18°C and cloudy with 65% humidity...
```

### Code Execution
```
👤 You: code:print("Hello, World!")
🤖 Assistant: 🐍 Executing: print("Hello, World!")
I've executed your Python code. The output is: Hello, World!
```

### Mathematical Calculations
```
👤 You: calc:sqrt(64)
🤖 Assistant: 🧮 Calculating: sqrt(64)
The square root of 64 is 8.
```

### Image Analysis
```
👤 You: image:https://example.com/photo.jpg
🤖 Assistant: I can see this is an image showing...

👤 You: base64:data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==
🤖 Assistant: I can analyze this base64 image data...
```

### Command Examples
```
👤 You: history        # View conversation history
👤 You: clear          # Clear conversation history
👤 You: help           # Show help message
👤 You: quit           # Exit the chatbot
```

## Available Tools

### 1. Weather Tool (`get_weather`)
- **Usage**: `weather:[location]`
- **Example**: `weather:Tokyo` or `weather:New York, NY`
- **Parameters**: 
  - `location` (required): City and state/country
  - `unit` (optional): Temperature unit (celsius/fahrenheit)

### 2. Code Interpreter (`code_interpreter`)
- **Usage**: `code:[python code]`
- **Example**: `code:import math; print(math.pi)`
- **Features**: Simulates Python code execution with realistic outputs

### 3. Calculator (`calculate`)
- **Usage**: `calc:[mathematical expression]`
- **Example**: `calc:2 + 2` or `calc:sqrt(16)`
- **Supports**: Basic arithmetic, square roots, and mathematical expressions

## Technical Implementation

### Tool Definition Example
```swift
let weatherTool = SAOAITool.function(
    name: "get_weather",
    description: "Get current weather information for a specified location",
    parameters: .object([
        "type": .string("object"),
        "properties": .object([
            "location": .object([
                "type": .string("string"),
                "description": .string("The city and state/country")
            ])
        ]),
        "required": .array([.string("location")])
    ])
)
```

### Code Interpreter Tool
```swift
let codeInterpreterTool = SAOAITool(
    type: "code_interpreter",
    name: "code_interpreter", 
    description: "Execute Python code and return results",
    parameters: .object([...])
)
```

## Architecture

### Chat History Management
- **`AdvancedChatHistory`**: Manages conversation state, response IDs, and tool call tracking
- **Response Chaining**: Uses `previousResponseId` for contextual conversations
- **Tool Call Tracking**: Maintains history of function calls and results

### Image Processing
- **URL Validation**: Checks for valid image URLs with supported formats
- **Base64 Detection**: Validates base64 image data format
- **Multi-modal Messages**: Creates appropriate `SAOAIMessage` content types

### Tool Execution
- **Modular Design**: Separate `ToolExecutor` class with static methods
- **Realistic Simulation**: Weather, code execution, and calculation simulators
- **Error Handling**: Graceful fallbacks for unknown tools

## Demo Mode

When run without API credentials, the chatbot operates in demo mode:

- Shows comprehensive feature overview
- Provides setup instructions
- Demonstrates example interactions
- Explains all available commands and tools

## Dependencies

This example depends on the parent `SwiftAzureOpenAI` package and demonstrates:

- **Latest SAOAI class names**: `SAOAIClient`, `SAOAIMessage`, `SAOAITool`, etc.
- **Python-style API patterns**: Similar to OpenAI Python SDK
- **Comprehensive tool support**: Function calling, code interpreter simulation
- **Modern Swift concurrency**: async/await throughout

## Educational Value

This example serves as a complete reference for:

1. **Interactive Console Applications**: Building responsive CLI interfaces
2. **Function Calling Implementation**: Complete workflow from definition to execution
3. **Multi-modal AI Integration**: Handling text and image inputs
4. **Tool Integration Patterns**: Extensible tool system design
5. **Error Handling**: Robust error management and user feedback

Perfect for developers learning to integrate Azure OpenAI capabilities into their Swift applications!