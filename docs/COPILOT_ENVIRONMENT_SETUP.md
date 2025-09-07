# GitHub Copilot Development Environment Setup

This document explains how to set up the GitHub Copilot development environment for the SwiftAzureOpenAI project.

## Overview

The SwiftAzureOpenAI project includes a custom GitHub Copilot setup configuration in `.github/workflows/copilot-setup-steps.yml` that automatically prepares the development environment with the necessary Swift toolchain and dependencies.

## Automatic Setup

When GitHub Copilot starts working on this project, it will automatically:

1. **Install Swift 6.0+** - Downloads and configures Swift 6.0.2 (compatible with the project requirements)
2. **Install System Dependencies** - Installs required Linux packages (libc6-dev, libicu-dev, libcurl4-openssl-dev, libssl-dev)
3. **Validate Package Structure** - Verifies the Swift package configuration is valid
4. **Resolve Dependencies** - Runs `swift package resolve` (though this project has zero external dependencies)
5. **Build Verification** - Tests both debug and release builds to ensure compilation works
6. **Test Environment** - Runs the comprehensive test suite to verify functionality
7. **Environment Summary** - Provides a summary of the setup for reference

## Environment Variables for Azure OpenAI Testing

To enable live Azure OpenAI API testing in the Copilot environment, you can configure environment variables in the `copilot` GitHub environment:

### Setting Up the Copilot Environment

1. Navigate to your repository **Settings** → **Environments**
2. Create a new environment named `copilot`
3. Add the following environment variables and secrets:

#### Environment Variables (Public)
- `AZURE_OPENAI_ENDPOINT` - Your Azure OpenAI endpoint URL (e.g., `https://your-resource.openai.azure.com`)
- `AZURE_OPENAI_DEPLOYMENT` - Your Azure OpenAI deployment name (e.g., `gpt-4o`)

#### Environment Secrets (Private)
- `COPILOT_AGENT_AZURE_OPENAI_API_KEY` - Your Azure OpenAI API key (primary, keep this secret!)
- `AZURE_OPENAI_API_KEY` - Alternative Azure OpenAI API key (fallback, keep this secret!)

### Environment Variable Configuration Example

```bash
# Example values (replace with your actual values)
AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
COPILOT_AGENT_AZURE_OPENAI_API_KEY="your-azure-api-key"  # Store as secret (primary)
AZURE_OPENAI_API_KEY="your-azure-api-key"  # Store as secret (fallback)
AZURE_OPENAI_DEPLOYMENT="gpt-4o"
```

### Testing Without Environment Variables

The SwiftAzureOpenAI test suite is designed to work gracefully without these environment variables:

- Tests will skip live API calls if credentials aren't available
- All unit tests and offline functionality tests will still run
- Environment variable configuration tests will show informational messages

This ensures Copilot can work effectively even without Azure OpenAI credentials configured.

## Manual Validation

You can manually test the setup steps by running:

```bash
# Check Swift version
swift --version

# Validate package
swift package describe

# Build and test
swift build
swift test --parallel
```

## Project Requirements

The copilot-setup-steps.yml configuration ensures the environment meets these project requirements:

- **Swift Version**: 6.0+ (specifically installs 6.0.2)
- **Platforms**: iOS 13.0+, macOS 10.15+, watchOS 6.0+, tvOS 13.0+
- **Dependencies**: Zero external dependencies (validated during setup)
- **Build Configurations**: Both debug and release builds tested
- **Test Coverage**: Comprehensive test suite with 21+ test files

## Troubleshooting

### If Setup Fails

1. **Swift Installation Issues**: The setup uses official Swift.org releases for Ubuntu 22.04
2. **Build Failures**: Check for syntax errors or package structure issues
3. **Test Failures**: Review test output for specific failure reasons
4. **Environment Variables**: Verify credentials are correctly set in the `copilot` environment

### Getting Help

- Check the [CI/CD documentation](./CI-CD.md) for comprehensive workflow information
- Review [LIVE_API_TESTING.md](../LIVE_API_TESTING.md) for Azure OpenAI testing guidance
- Examine existing GitHub Actions workflows for reference patterns

## Benefits of the Custom Setup

This configuration provides GitHub Copilot with:

1. **Faster Development** - Pre-installed Swift toolchain eliminates setup delays
2. **Consistent Environment** - Same Swift version and dependencies across sessions
3. **Validated Builds** - Ensures the development environment can compile and test the project
4. **Azure Integration** - Ready for live API testing when credentials are available
5. **Zero Dependencies** - Validates the project's policy of having no external dependencies

The setup typically completes in under 2 minutes, providing Copilot with a fully functional Swift development environment for the SwiftAzureOpenAI project.