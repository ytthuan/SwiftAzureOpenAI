# ResponsesConsoleChatbot

A Swift console chatbot implementation using Azure OpenAI Responses API, converted from a Python script. This example demonstrates streaming responses, function calling, and code interpreter capabilities in a terminal interface.

## Features

- **Streaming Responses**: Real-time streaming of Azure OpenAI responses to console
- **Function Calling**: Built-in `sum_calculator` tool for mathematical operations
- **Code Interpreter**: Support for code execution through Azure OpenAI
- **Tool Integration**: Easy-to-extend function calling framework
- **Console Interface**: Interactive command-line chat experience

## Quick Start

1. **Set Environment Variables**:
   ```bash
   export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
   export AZURE_OPENAI_API_KEY="your-api-key"
   export AZURE_OPENAI_DEPLOYMENT="your-deployment-name"
   ```

2. **Build and Run**:
   ```bash
   cd examples/ResponsesConsoleChatbot
   swift run
   ```

3. **Test Function Calling**:
   ```
   You: can you use tool to calculate 10 plus 22
   ```

## Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI resource endpoint | ✅ | - |
| `AZURE_OPENAI_API_KEY` | API key for authentication | ✅ | - |
| `AZURE_OPENAI_DEPLOYMENT` | Deployment/model name | | `gpt-4o` |
| `DEFAULT_MODEL` | Default model to use | | `gpt-4o` |
| `DEFAULT_INSTRUCTIONS` | System instructions | | "" |
| `DEFAULT_REASONING_EFFORT` | Reasoning effort level | | `nil` |

### Command Line Arguments

```bash
swift run ResponsesConsoleChatbot [options]

Options:
  --model MODEL        Model to use (default: gpt-4o)
  --instructions TEXT  System instructions  
  --reasoning EFFORT   Reasoning effort: low, medium, high
  --help              Show help message
```

## Available Tools

### 1. Sum Calculator
- **Function**: `sum_calculator`
- **Description**: Calculates the sum of two numbers
- **Parameters**: 
  - `a` (number): The first number
  - `b` (number): The second number
- **Example**: "Calculate 10 plus 22"

### 2. Code Interpreter
- **Type**: `code_interpreter`
- **Description**: Execute code in a sandboxed environment
- **Example**: "Write Python code to calculate fibonacci numbers"

## Usage Examples

### Basic Chat
```
You: Hello, how are you?
[assistant]: Hello! I'm doing well, thank you for asking. How can I help you today?
```

### Function Calling
```
You: can you use tool to calculate 10 plus 22
[tool] Function started: sum_calculator (call_id: call_abc123)
[tool] sum_calculator arguments: {"a": 10, "b": 22}
[tool] sum_calculator result: {"result": 32}
[assistant]: I used the sum calculator tool to add 10 and 22, and the result is 32.
```

### Code Interpreter
```
You: Write code to generate first 5 fibonacci numbers
[tool] Code Interpreter started (container: container_xyz789)
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

for i in range(5):
    print(f"F({i}) = {fibonacci(i)}")
[tool] Code Interpreter completed
[assistant]: Here are the first 5 Fibonacci numbers: F(0) = 0, F(1) = 1, F(2) = 1, F(3) = 2, F(4) = 3
```

## Implementation Details

### Architecture

The chatbot is built using SwiftAzureOpenAI's streaming API with the following key components:

- **ResponsesConsoleManager**: Main class managing the chat session
- **Function Tools**: Extensible function calling system
- **Event Processing**: Handles streaming events for real-time output
- **Error Handling**: Robust error handling for network and API issues

### API Configuration

- **API Version**: Uses "preview" version as required for Responses API
- **Authentication**: API key-based authentication
- **Streaming**: Utilizes `AsyncThrowingStream` for real-time responses
- **Tool Support**: Both function tools and code interpreter

### Key Differences from Python Version

1. **Type Safety**: Full Swift type safety with strongly-typed models
2. **Async/Await**: Native Swift concurrency instead of asyncio
3. **Error Handling**: Swift's robust error handling with `throws`
4. **Stream Processing**: Swift's `AsyncThrowingStream` for event handling
5. **Memory Management**: Automatic memory management with ARC

## Development

### Adding New Functions

To add a new function tool:

1. **Define the tool**:
   ```swift
   private func newFunctionDefinition() -> SAOAITool {
       return SAOAITool.function(
           name: "new_function",
           description: "Description of what the function does",
           parameters: .object([
               "type": .string("object"),
               "properties": .object([
                   "param1": .object([
                       "type": .string("string"),
                       "description": .string("Parameter description")
                   ])
               ]),
               "required": .array([.string("param1")])
           ])
       )
   }
   ```

2. **Implement the handler**:
   ```swift
   private func handleNewFunction(args: String) async throws -> String {
       // Parse args and implement logic
       return "{\"result\": \"success\"}"
   }
   ```

3. **Register the handler**:
   ```swift
   functionHandlers["new_function"] = handleNewFunction
   ```

### Testing

Build and test the chatbot:

```bash
# Build
swift build

# Run with custom model
swift run ResponsesConsoleChatbot --model gpt-4o --instructions "You are a helpful math assistant"

# Run with reasoning
swift run ResponsesConsoleChatbot --reasoning medium
```

## Troubleshooting

### Common Issues

1. **Missing Environment Variables**:
   ```
   Error: AZURE_OPENAI_ENDPOINT is not set
   ```
   Solution: Set all required environment variables

2. **API Key Issues**:
   ```
   Error: 401 Unauthorized
   ```
   Solution: Verify your API key is correct and has necessary permissions

3. **Model Not Found**:
   ```
   Error: 404 Not Found
   ```
   Solution: Check that your deployment name matches your Azure OpenAI deployment

### Debug Mode

For debugging, you can add verbose logging by modifying the streaming event handlers to print additional information about events and responses.

## License

This example follows the same license as the SwiftAzureOpenAI package.