#!/bin/bash

# Demo script for ResponsesConsoleChatbot
# This script demonstrates the chatbot with the exact test case from the issue

echo "🤖 SwiftAzureOpenAI ResponsesConsoleChatbot Demo"
echo "==============================================="
echo ""
echo "This demo will test the chatbot with the example from the issue:"
echo "Input: 'can you use tool to calculate 10 plus 22'"
echo "Expected: The chatbot should use the sum_calculator tool and return 32"
echo ""

# Check if environment variables are set
if [ -z "$AZURE_OPENAI_ENDPOINT" ]; then
    echo "⚠️  AZURE_OPENAI_ENDPOINT is not set"
    echo "   Set this to your Azure OpenAI endpoint:"
    echo "   export AZURE_OPENAI_ENDPOINT=\"https://your-resource.openai.azure.com\""
    echo ""
fi

if [ -z "$AZURE_OPENAI_API_KEY" ] && [ -z "$COPILOT_AGENT_AZURE_OPENAI_API_KEY" ]; then
    echo "⚠️  AZURE_OPENAI_API_KEY is not set"
    echo "   Set this to your Azure OpenAI API key:"
    echo "   export AZURE_OPENAI_API_KEY=\"your-api-key\""
    echo ""
fi

if [ -z "$AZURE_OPENAI_DEPLOYMENT" ]; then
    echo "ℹ️  AZURE_OPENAI_DEPLOYMENT not set, will use default model name"
    echo ""
fi

echo "🚀 Starting ResponsesConsoleChatbot..."
echo "   Type the test command: can you use tool to calculate 10 plus 22"
echo "   Then type 'exit' when done"
echo ""

# Navigate to the chatbot directory and run it
cd "$(dirname "$0")"
swift run ResponsesConsoleChatbot