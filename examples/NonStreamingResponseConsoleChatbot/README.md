# NonStreamingResponseConsoleChatbot

A **non-streaming only** console example for SwiftAzureOpenAI that demonstrates blocking response handling with the Azure OpenAI Responses API. This example focuses specifically on non-streaming mode, providing a simpler alternative to the unified `ResponsesConsoleChatbot` example.

## Features

- **Non-streaming mode only**: All responses are returned as complete blocks
- **User-controlled function calling**: SDK returns function call outputs instead of forcing automatic loops
- **Complete feature support**: Reasoning, function calls, code interpreter all work in blocking mode
- **Simple calculation tool**: Built-in sum calculator function for testing
- **Code interpreter support**: Execute Python code through Azure OpenAI
- **Flexible reasoning**: Support for different reasoning efforts and summary types
- **Text verbosity control**: Configure response detail level

## Requirements

- Swift 6.0+
- Azure OpenAI endpoint with Responses API access
- Environment variables configured (see below)

## Environment Variables

Required:
- `AZURE_OPENAI_ENDPOINT`: Your Azure OpenAI endpoint URL
- `AZURE_OPENAI_API_KEY` or `COPILOT_AGENT_AZURE_OPENAI_API_KEY`: Your Azure OpenAI API key

Optional:
- `AZURE_OPENAI_DEPLOYMENT`: Deployment name (defaults to model name)
- `DEFAULT_MODEL`: Default model to use (defaults to "gpt-5-mini")
- `DEFAULT_INSTRUCTIONS`: Default system instructions
- `DEFAULT_REASONING_EFFORT`: Default reasoning effort ("low", "medium", "high")
- `DEFAULT_REASONING_SUMMARY`: Default reasoning summary ("auto", "concise", "detailed")
- `DEFAULT_TEXT_VERBOSITY`: Default text verbosity ("low", "medium", "high")

## Usage

### Build and Run

```bash
cd examples/NonStreamingResponseConsoleChatbot
swift build
swift run NonStreamingResponseConsoleChatbot
```

### Command Line Options

```bash
# Interactive mode (default)
swift run NonStreamingResponseConsoleChatbot

# Single message
swift run NonStreamingResponseConsoleChatbot --message "calculate 10 plus 22"

# With reasoning
swift run NonStreamingResponseConsoleChatbot --reasoning high --message "Explain quantum physics"

# With custom model
swift run NonStreamingResponseConsoleChatbot --model "gpt-4o" --message "Hello!"

# Full options
swift run NonStreamingResponseConsoleChatbot \
  --model "gpt-4o" \
  --instructions "You are a helpful math tutor" \
  --reasoning high \
  --reasoning-summary detailed \
  --text-verbosity low \
  --message "Calculate the area of a circle with radius 5"
```

### Available Options

- `--model MODEL`: Model to use (default: gpt-5-mini)
- `--instructions TEXT`: System instructions
- `--reasoning EFFORT`: Reasoning effort: low, medium, high
- `--reasoning-summary TYPE`: Reasoning summary: auto, concise, detailed
- `--text-verbosity LEVEL`: Text verbosity: low, medium, high
- `--message TEXT`: Single message to send (non-interactive mode)
- `--help`: Show help information

## Function Calling

This example demonstrates **user-controlled function calling**:

- SDK returns function call outputs to your code
- You decide when and how many times to continue function calling
- Maximum of 5 function call rounds per conversation (configurable)
- No automatic loops - full user control

### Available Tools

1. **sum_calculator**: Calculates the sum of two numbers
2. **code_interpreter**: Executes Python code (via Azure OpenAI)

## Example Session

```
🤖 SwiftAzureOpenAI Non-Streaming Responses Console Chatbot
============================================================
Console chat using Azure Responses API in blocking mode (no streaming)
Mode: Non-streaming with user-controlled function calling
Type 'exit' or 'quit' to stop.
Try: 'can you use tool to calculate 10 plus 22'
============================================================
Model: gpt-5-mini (Non-streaming mode)
Function calling: User-controlled (max 5 rounds)
You: calculate 10 plus 22

[tool] Function started: sum_calculator (call_id: call_xyz123)
args: {"a": 10, "b": 22}
[tool] sum_calculator arguments: {"a": 10, "b": 22}
[tool] sum_calculator result: {"result": 32.0}

[debug] Function call round 1/5
[assistant]: The sum of 10 and 22 is 32.

You: exit
Exiting.
```

## Differences from ResponsesConsoleChatbot

This non-streaming example is a **focused, simplified version** that:

- **Removes streaming complexity**: No real-time event processing or streaming state management
- **Removes mode selection**: Only supports non-streaming mode (no `--streaming`/`--non-streaming` flags)
- **Simplifies the codebase**: Easier to understand and customize for non-streaming use cases
- **Maintains full functionality**: All features (reasoning, function calling, code interpreter) work in blocking mode

## When to Use This Example

Use `NonStreamingResponseConsoleChatbot` when you:

- Want blocking, complete responses rather than real-time streaming
- Need simpler code without streaming complexity
- Are building applications that process complete responses at once
- Want to understand non-streaming Azure OpenAI integration patterns
- Prefer to wait for full responses before processing

Use the main `ResponsesConsoleChatbot` when you need both streaming and non-streaming options in a single application.