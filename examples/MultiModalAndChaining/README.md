# Multi-Modal and Response Chaining Example

This is a complete, compilable Swift Package demonstrating multi-modal input support and response chaining with SwiftAzureOpenAI.

## Features

- **Multi-Modal Input with Image URLs**: Send text + image URL in a single message
- **Multi-Modal Input with Base64 Images**: Send text + base64-encoded images
- **Response Chaining**: Use `previousResponseId` to maintain context across requests
- **Complex Multi-Modal Requests**: Multiple images and text in one request
- **Complete Workflows**: End-to-end scenarios combining all features

## How to Run

1. **Clone this example**:
   ```bash
   cd examples/MultiModalAndChaining
   ```

2. **Build and run**:
   ```bash
   swift run
   ```

## Example Scenarios

The package demonstrates:

1. **Image URL Analysis**: `SAOAIMessage(role: .user, text: "what is in this image?", imageURL: "https://...")`
2. **Base64 Image Analysis**: `SAOAIMessage(role: .user, text: "analyze this", base64Image: data, mimeType: "image/png")`
3. **Response Chaining**: Using `previousResponseId` to maintain conversation context
4. **Complex Workflows**: Multi-step analysis with image comparisons

## Dependencies

This package depends on the parent SwiftAzureOpenAI package and demonstrates the Python-style API for multi-modal interactions.