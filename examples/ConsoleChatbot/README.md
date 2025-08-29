# Console Chatbot Example

This is a complete, compilable Swift Package demonstrating an interactive console chatbot using SwiftAzureOpenAI.

## Features

- **Interactive Console Interface**: Real-time user input/output with command handling
- **Proper Chat History Chaining**: Uses `previousResponseId` to maintain conversation context across requests
- **Multi-Modal Support**: Handles both image URLs (`image: https://...`) and base64 images (`base64: <data>`)
- **User Commands**: `history`, `clear`, `quit` for enhanced user experience
- **Environment Configuration**: Uses environment variables for API credentials
- **Error Handling**: Comprehensive validation and user-friendly error messages
- **Demo Mode**: Shows capabilities when no API credentials are available

## How to Run

1. **Clone this example**:
   ```bash
   cd examples/ConsoleChatbot
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

- **Text chat**: Just type your message and press Enter
- **Image URL**: `image: https://example.com/photo.jpg`
- **Base64 image**: `base64: <base64-encoded-image-data>`
- **Commands**: `history`, `clear`, `quit`

## Dependencies

This package depends on the parent SwiftAzureOpenAI package and demonstrates the latest SAOAI class names and API patterns.