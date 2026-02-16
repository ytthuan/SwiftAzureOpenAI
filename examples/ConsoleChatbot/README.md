# Enhanced Console Chatbot with Tools Example

> **⚠️ Internal Development Example**: This enhanced console chatbot demonstrates the latest SwiftAzureOpenAI SDK capabilities during internal development. It showcases production-ready APIs but is intended for internal testing and development.

This is a complete, compilable Swift Package demonstrating an interactive console chatbot with tools support using SwiftAzureOpenAI.

## Features

### Core Functionality
- **Interactive Console Interface**: Real-time user input/output with command handling
- **Proper Chat History Chaining**: Uses `previousResponseId` to maintain conversation context across requests
- **Multi-Modal Support**: Handles both image URLs (`image: https://...`) and base64 images (`base64: <data>`)
- **Environment Configuration**: Uses environment variables for API credentials
- **Error Handling**: Comprehensive validation and user-friendly error messages
- **Demo Mode**: Shows capabilities when no API credentials are available

### New Tools Integration
- **Function Calling Support**: Full integration with Azure OpenAI function calling capabilities
- **Code Interpreter**: Execute Python, Swift, and JavaScript code snippets
- **Weather Information**: Get current weather for any location
- **Mathematical Calculator**: Perform complex mathematical calculations
- **File Operations**: Simulate file reading, writing, and directory listing

### Interactive Commands
- `history` - View conversation history including tools usage
- `clear` - Start a new conversation (preserves tools settings)
- `quit` - Exit the chatbot
- `tools` - Toggle tools/function calling on/off
- `tools list` - Show all available tools and their descriptions

### Direct Tool Commands
- `calc: <expression>` - Direct mathematical calculation (e.g., `calc: 2 + 3 * 4`)
- `code: <code>` - Direct code execution (e.g., `code: print('Hello, World!')`)
- `weather: <location>` - Direct weather lookup (e.g., `weather: Tokyo`)

## How to Run

1. **Clone this example**:
   ```bash
   cd examples/ConsoleChatbot
   ```

2. **Set environment variables** (optional - runs in demo mode without them):
   ```bash
   export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
   export AZURE_OPENAI_API_KEY="your-api-key"
   export AZURE_OPENAI_MODEL="gpt-4o" # or AZURE_OPENAI_DEPLOYMENT for legacy setups
   ```

3. **Build and run**:
   ```bash
   swift run
   ```

## Usage Examples

### Basic Chat
- **Text chat**: Just type your message and press Enter
- **Image URL**: `image: https://example.com/photo.jpg`
- **Base64 image**: `base64: <base64-encoded-image-data>`

### Tools Usage

#### Enable Tools
```
👤 You: tools
🔧 Tools enabled
```

#### Natural Language with Tools
```
👤 You: What's the weather in Paris and can you calculate 15 * 24?
🔧 Calling function: get_weather
⚙️  Executing get_weather...
✅ get_weather completed
🔧 Calling function: calculate
⚙️  Executing calculate...
✅ calculate completed
🤖 Assistant: The weather in Paris is currently sunny at 73°F with 65% humidity. And 15 * 24 equals 360.
```

#### Direct Commands
```
👤 You: calc: (50 + 30) / 4
🧮 Calculating: (50 + 30) / 4
📤 Result: {"expression": "(50 + 30) / 4", "result": 20}

👤 You: code: print('Hello from Python!')
💻 Executing code: print('Hello from Python!')
📤 Result: {"language": "python", "code": "print('Hello from Python!')", "output": "Output: Hello from Python!"}

👤 You: weather: London
🌤️  Getting weather for: London
📤 Result: {"location": "London", "temperature": "68°F", "condition": "partly cloudy", "humidity": "55%", "wind_speed": "12 mph"}
```

#### Code Interpreter Examples
```
👤 You: Can you write a Python function to calculate fibonacci numbers?
🤖 Assistant: I'll create a fibonacci function for you.
🔧 Calling function: execute_code
⚙️  Executing execute_code...
✅ execute_code completed
🤖 Assistant: Here's a Python function that calculates Fibonacci numbers:

def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

The function has been executed successfully.
```

## Available Tools

1. **🌤️ Weather Service** (`get_weather`)
   - Get current weather information for any location
   - Returns temperature, conditions, humidity, and wind speed

2. **🧮 Calculator** (`calculate`)
   - Perform mathematical calculations
   - Supports basic arithmetic operations
   - Handles complex expressions

3. **💻 Code Interpreter** (`execute_code`)
   - Execute Python, Swift, or JavaScript code
   - Simulates code execution environment
   - Returns execution results and output

4. **📁 File Operations** (`file_operations`)
   - Simulate file system operations
   - Support for read, write, and list operations
   - Demonstrates file handling capabilities

## Architecture Highlights

### Function Registry
The `FunctionRegistry` struct contains all tool definitions and execution logic:
- Tool definitions using `SAOAITool.function`
- Execution handlers for each function type
- JSON argument parsing and response formatting

### Enhanced Chat History
The `ChatHistory` class now includes:
- Tools enable/disable state management
- Function call result tracking
- Proper conversation flow with tools integration

### Function Call Handling
- Automatic detection of function calls in AI responses
- Sequential execution of multiple function calls
- Result aggregation and follow-up response generation
- Error handling for tool execution failures

## Implementation Notes

- **Sandboxing**: Code execution is simulated for safety in this example
- **Error Handling**: Comprehensive error handling for all tool operations
- **State Management**: Tools settings persist across conversation clearing
- **Response Chaining**: Proper use of `previousResponseId` for context continuity
- **Multi-Tool Support**: Can handle multiple function calls in a single response

## Dependencies

This package depends on the parent SwiftAzureOpenAI package and demonstrates the latest SAOAI class names and API patterns including:
- `SAOAIClient` for API interactions
- `SAOAITool` for function definitions
- `SAOAIMessage` for conversation handling
- `SAOAIResponse` for response processing
