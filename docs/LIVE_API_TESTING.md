# Live API Testing Guide

> **⚠️ Internal Development**: This guide is for internal development and testing of the SwiftAzureOpenAI SDK. It describes testing procedures used during our internal development process.

This document explains how to run the live API tests that use pure URLSession to verify streaming and non-streaming functionality with real Azure OpenAI services.

## Prerequisites

### Environment Variables

Set the following environment variables before running live API tests:

```bash
# Required: Azure OpenAI endpoint URL
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"

# Required: Azure OpenAI API key (should be kept secret)
export COPILOT_AGENT_AZURE_OPENAI_API_KEY="your-azure-api-key"
# Alternative: export AZURE_OPENAI_API_KEY="your-azure-api-key"

# Required: Azure OpenAI deployment name
export AZURE_OPENAI_DEPLOYMENT="your-deployment-name"
```

### Deployment Requirements

Your Azure OpenAI deployment should:
- Be compatible with the Responses API (`api-version=preview`)
- Support function calling (for the debug test)
- Have sufficient quota for test requests

## Running Live API Tests

### Run All Live API Tests

```bash
# Set environment variables first
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
export COPILOT_AGENT_AZURE_OPENAI_API_KEY="your-azure-api-key"
export AZURE_OPENAI_DEPLOYMENT="gpt-4o"

# Run all live API tests
swift test --filter LiveAPITests
```

### Run Individual Tests

#### Test Environment Variable Configuration
```bash
swift test --filter LiveAPITests.testEnvironmentVariableConfiguration
```
This test validates that environment variables are properly configured and have the expected format.

#### Test Non-Streaming API Call
```bash
swift test --filter LiveAPITests.testCallAPIWithURLSessionNonStreaming
```
This test performs a real non-streaming API call using pure URLSession and validates the response structure.

#### Test Streaming API Call
```bash
swift test --filter LiveAPITests.testCallAPIWithURLSessionStreaming
```
This test performs a real streaming API call using pure URLSession and processes Server-Sent Events.

#### Test Error Handling
```bash
swift test --filter LiveAPITests.testAPIErrorHandling
```
This test validates error response handling by making a request with an invalid model name.

#### Debug Request Structure
```bash
swift test --filter LiveAPITests.testDebugRequestStructure
```
This test helps debug issues by printing the exact JSON structure being sent and the response received. Use this test to diagnose problems like the "Bad Request" error from the console chatbot example.

## Test Behavior Without Environment Variables

If environment variables are not set, the tests will:
- Skip gracefully with appropriate messages
- Not fail the test suite
- Print informational messages explaining what's missing

This ensures the tests work properly in CI/CD environments without secrets.

## Understanding Test Output

### Successful Test Output

```
✅ Non-streaming API call successful!
Response ID: resp_123abc
Model: gpt-4o
Content: Hi there!
```

### Debug Test Output

The debug test prints detailed information:

```
🔍 Debug: Request JSON structure:
{
  "input" : [
    {
      "content" : [
        {
          "text" : "hi, what the weather like in london",
          "type" : "input_text"
        }
      ],
      "role" : "user"
    }
  ],
  "model" : "gpt-4o",
  "stream" : true,
  "tools" : [...]
}

🔍 Debug: Request URL: https://your-resource.openai.azure.com/openai/v1/responses?api-version=preview

🔍 Debug: Request headers:
  Content-Type: application/json
  api-key: [REDACTED]
  Accept: text/event-stream

🔍 Debug: Response status code: 200
```

### Error Output

If there's an issue, you'll see detailed error information:

```
❌ Request failed with status 400
❌ Error details:
   Type: invalid_request_error
   Message: Invalid model specified
   Code: model_not_found
```

## Troubleshooting

### "Bad Request" Error

If you get a "Bad Request" error like in the console chatbot example:

1. Run the debug test to see the exact request structure:
   ```bash
   swift test --filter LiveAPITests.testDebugRequestStructure
   ```

2. Check that your deployment name is correct
3. Verify your endpoint URL format
4. Ensure your API key is valid and has access to the deployment
5. Check that the deployment supports the Responses API with `api-version=preview`

### Common Issues

- **Wrong API version**: Make sure you're using `api-version=preview` for the Responses API
- **Incorrect endpoint**: Ensure the endpoint follows the format `https://your-resource.openai.azure.com`
- **Model/deployment mismatch**: The model name in the request should match your actual deployment name
- **Insufficient permissions**: Ensure your API key has access to the specific deployment

## Security Notes

- Never commit API keys to source code
- Use environment variables or secure secret management
- The debug test redacts API keys in output
- Consider using different API keys for testing vs production

## Integration with CI/CD

These tests are designed to work in CI/CD pipelines:

- Tests skip gracefully when environment variables aren't set
- No failures occur in environments without secrets
- Detailed logging helps with debugging in automated environments
- Tests can be run selectively based on environment availability