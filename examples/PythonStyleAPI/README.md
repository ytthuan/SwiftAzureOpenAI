# Python-Style API Example

This is a complete, compilable Swift Package demonstrating the new simplified Python-style API for SwiftAzureOpenAI.

## Features

- **Simple String Input**: Use Python-style `client.responses.create(model: ..., input: "text")`
- **Convenience Message Creation**: `SAOAIMessage(role: .user, text: "...")`
- **Python-style Operations**: `client.responses.retrieve(id)`, `client.responses.delete(id)`
- **Full Backward Compatibility**: Advanced users can still use complex API patterns
- **Configuration Examples**: Both Azure OpenAI and OpenAI configurations

## How to Run

1. **Clone this example**:
   ```bash
   cd examples/PythonStyleAPI
   ```

2. **Build and run**:
   ```bash
   swift run
   ```

## What You'll See

The example demonstrates:

- **Before vs After**: Comparison showing how the API was simplified
- **Simple Usage**: String input for quick interactions
- **Conversation API**: Multi-message conversations
- **Retrieve and Delete**: Managing response lifecycle
- **Backward Compatibility**: Complex requests still work

## Dependencies

This package depends on the parent SwiftAzureOpenAI package and showcases the modern API patterns while maintaining full backward compatibility.