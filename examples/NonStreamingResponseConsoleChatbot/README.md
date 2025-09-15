# NonStreamingResponseConsoleChatbot with File API Support

A **non-streaming only** console example for SwiftAzureOpenAI that demonstrates blocking response handling with the Azure OpenAI Responses API, now enhanced with comprehensive file input/output capabilities.

## Features

- **Non-streaming mode only**: All responses are returned as complete blocks
- **File-based input/output**: Read prompts from files and write responses to files
- **File API integration**: Support for PDF, image, text, and JSON file processing
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

# File-based input/output
swift run NonStreamingResponseConsoleChatbot --input-file prompts.txt --output-file responses.txt

# Single message with output file
swift run NonStreamingResponseConsoleChatbot --message "Explain AI" --output-file explanation.txt

# With reasoning and file processing
swift run NonStreamingResponseConsoleChatbot \
  --reasoning high \
  --reasoning-summary detailed \
  --input-file questions.txt \
  --output-file detailed_answers.txt

# Full options
swift run NonStreamingResponseConsoleChatbot \
  --model "gpt-4o" \
  --instructions "You are a helpful math tutor" \
  --reasoning high \
  --reasoning-summary detailed \
  --text-verbosity low \
  --input-file math_problems.txt \
  --output-file solutions.txt
```

### Available Options

- `--model MODEL`: Model to use (default: gpt-5-mini)
- `--instructions TEXT`: System instructions
- `--reasoning EFFORT`: Reasoning effort: low, medium, high
- `--reasoning-summary TYPE`: Reasoning summary: auto, concise, detailed
- `--text-verbosity LEVEL`: Text verbosity: low, medium, high
- `--message TEXT`: Single message to send (non-interactive mode)
- `--input-file PATH`: Read prompts from file (one per line)
- `--output-file PATH`: Write responses to file
- `--help`: Show help information

## File Input Format

Input files should contain one prompt per line. The format supports:

### Text Prompts
```
# This is a comment (lines starting with # are ignored)
What is the weather like today?
Calculate the sum of 25 and 17
Explain quantum mechanics in simple terms
```

### File References
Reference external files for analysis using the `file:` prefix:
```
# Analyze documents using File API
file:/path/to/document.pdf
file:/path/to/image.jpg
file:/path/to/data.json
```

### Example Input File (prompts.txt)
```
# Sample prompts for testing File API
What is 2 + 2?

# Mathematical reasoning
Calculate the square root of 144 and explain your process

# File analysis using SwiftAzureOpenAI File API
file:/path/to/report.pdf

# Knowledge question  
What are the three laws of thermodynamics?
```

## File Processing Support

The chatbot supports various file types through the SwiftAzureOpenAI File API:

### Text Files
- **Extensions**: `.txt`, `.md`
- **Processing**: Content included directly in prompts
- **MIME Types**: `text/plain`, `text/markdown`

### Structured Data
- **Extensions**: `.json`
- **Processing**: Content included as formatted text
- **MIME Type**: `application/json`

### Binary Files (File API Integration)
- **Extensions**: `.pdf`, `.jpg`, `.jpeg`, `.png`
- **Processing**: Base64 encoded for Azure OpenAI File API
- **MIME Types**: `application/pdf`, `image/jpeg`, `image/png`
- **Models**: Requires vision-capable models (gpt-4o, gpt-4o-mini, etc.)

## Output File Format

Response files contain structured output with:
- Prompt numbers and original text
- Complete assistant responses
- Tool/function call results
- Reasoning summaries (when enabled)
- Error messages (if any)

### Example Output
```
Prompt 1: What is 2 + 2?
Response: [assistant]: 2 + 2 equals 4.

Prompt 2: Calculate the square root of 144
Response: [reasoning] I need to find the square root of 144...
[assistant]: The square root of 144 is 12.

Prompt 3: file:/path/to/document.pdf
Response: [assistant]: After analyzing the PDF document using the File API, I found...
```

## Function Calling

This example demonstrates **user-controlled function calling**:

- SDK returns function call outputs to your code
- You decide when and how many times to continue function calling
- Maximum of 5 function call rounds per conversation (configurable)
- No automatic loops - full user control

### Available Tools

1. **sum_calculator**: Calculates the sum of two numbers
2. **code_interpreter**: Executes Python code (via Azure OpenAI)

## Example Sessions

### Interactive Mode
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
[tool] sum_calculator arguments: {"a": 10, "b": 22}
[tool] sum_calculator result: {"result": 32.0}

[debug] Function call round 1/5
[assistant]: The sum of 10 and 22 is 32.

You: exit
Exiting.
```

### File-based Mode
```bash
# Create input file
echo "What is the capital of France?" > questions.txt
echo "Calculate 15 * 7" >> questions.txt

# Run with file processing
swift run NonStreamingResponseConsoleChatbot --input-file questions.txt --output-file answers.txt

# Output shows:
📁 File-based conversation mode
Input file: questions.txt
Output file: answers.txt
----
Processing prompt 1/2:
You: What is the capital of France?
[assistant]: The capital of France is Paris.
----
Processing prompt 2/2:
You: Calculate 15 * 7
[assistant]: 15 × 7 = 105.
📝 All responses written to: answers.txt
```

## File API Integration Examples

### PDF Analysis
```bash
# Create input with PDF reference
echo "file:/path/to/document.pdf" > analyze.txt

# Process with vision-capable model
swift run NonStreamingResponseConsoleChatbot \
  --model gpt-4o \
  --input-file analyze.txt \
  --output-file analysis.txt \
  --reasoning high
```

### Multiple File Types
```bash
# Create comprehensive input file
cat > mixed_input.txt << EOF
# Text analysis
What is machine learning?

# PDF document analysis  
file:/reports/quarterly_report.pdf

# Image analysis
file:/images/chart.png

# JSON data analysis
file:/data/metrics.json
EOF

# Process all file types
swift run NonStreamingResponseConsoleChatbot \
  --input-file mixed_input.txt \
  --output-file comprehensive_analysis.txt
```

## Error Handling

The application handles various error scenarios:
- Missing environment variables
- Invalid file paths
- File read/write errors
- Unsupported file formats
- API request failures
- Function call errors

Errors are logged to console and included in output files when applicable.

## Differences from ResponsesConsoleChatbot

This non-streaming example is a **focused, simplified version** that:

- **Removes streaming complexity**: No real-time event processing or streaming state management
- **Removes mode selection**: Only supports non-streaming mode (no `--streaming`/`--non-streaming` flags)
- **Adds comprehensive file support**: File input/output and File API integration
- **Simplifies the codebase**: Easier to understand and customize for non-streaming use cases
- **Maintains full functionality**: All features (reasoning, function calling, code interpreter) work in blocking mode

## When to Use This Example

Use `NonStreamingResponseConsoleChatbot` when you:

- Want blocking, complete responses rather than real-time streaming
- Need file-based input/output for batch processing or validation
- Want to leverage the SwiftAzureOpenAI File API for document analysis
- Need simpler code without streaming complexity
- Are building applications that process complete responses at once
- Want to understand non-streaming Azure OpenAI integration patterns
- Prefer to wait for full responses before processing

Use the main `ResponsesConsoleChatbot` when you need both streaming and non-streaming options in a single application.

## See Also

- [SwiftAzureOpenAI Library Documentation](../../README.md)
- [File API Documentation](../../README.md#file-input-and-processing)
- [Streaming Console Chatbot](../ConsoleChatbot/README.md)
- [Live API Testing Guide](../../docs/LIVE_API_TESTING.md)