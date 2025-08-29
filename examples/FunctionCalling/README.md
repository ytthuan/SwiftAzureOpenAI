# Function Calling Example

This is a complete, compilable Swift Package demonstrating function calling capabilities with SwiftAzureOpenAI, following Python OpenAI SDK patterns.

## Features

- **Function Definition**: Define tools/functions using `SAOAITool.function()`
- **Function Call Handling**: Process function calls from AI responses
- **Function Result Processing**: Send function results back to continue conversation
- **Multiple Functions**: Handle multiple function calls in a single response
- **Python-Style API**: Matches Python OpenAI SDK patterns for familiarity

## How to Run

1. **Clone this example**:
   ```bash
   cd examples/FunctionCalling
   ```

2. **Build and run**:
   ```bash
   swift run
   ```

## Example Functions

The package demonstrates:

- **Weather Function**: `get_weather(location)` - simulates weather API calls
- **Calculator Function**: `calculate_sum(a, b)` - performs mathematical operations
- **Multi-Function Handling**: Processing multiple function calls simultaneously
- **Result Chaining**: Using function outputs to generate final responses

## Code Patterns

Shows how to:
- Define functions with JSON Schema parameters
- Handle `SAOAIOutputContent.functionCall` responses
- Create `SAOAIInputContent.functionCallOutput` inputs
- Chain function results with `previousResponseId`

## Dependencies

This package depends on the parent SwiftAzureOpenAI package and demonstrates advanced function calling capabilities.