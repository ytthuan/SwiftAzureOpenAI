# GitHub Copilot Agent Environment Setup

This document describes how to configure the GitHub Copilot coding agent environment for the SwiftAzureOpenAI project.

## Overview

The `.github/workflows/copilot-setup-steps.yml` file configures the environment that GitHub Copilot uses when working with this repository. This ensures Copilot has access to:

- Swift 6.0.2 development environment
- Pre-built package dependencies
- Azure OpenAI API credentials through GitHub environment variables
- Proper toolchain for building and testing SwiftAzureOpenAI

## Environment Variables

The Copilot agent has access to the following environment variables through the `copilot` environment in GitHub:

### Repository Variables
- `AZURE_OPENAI_ENDPOINT`: The Azure OpenAI endpoint URL (e.g., `https://your-resource.openai.azure.com`)
- `AZURE_OPENAI_DEPLOYMENT`: The deployment name for your Azure OpenAI model

### Repository Secrets  
- `AZURE_OPENAI_API_KEY`: Your Azure OpenAI API key (sensitive, stored as a secret)

## Setup Steps

### 1. Configure GitHub Environment Variables

To set up the environment variables for Copilot:

1. Navigate to your repository on GitHub
2. Go to **Settings** > **Environments**
3. Select or create the `copilot` environment
4. Add the following environment variables:
   - **Variables**: `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_DEPLOYMENT`
   - **Secrets**: `AZURE_OPENAI_API_KEY`

### 2. Copilot Setup Workflow

The `copilot-setup-steps.yml` workflow automatically:

1. **Installs Swift 6.0.2**: Downloads and configures the latest Swift toolchain
2. **Installs System Dependencies**: Sets up required Linux packages for Swift
3. **Resolves Package Dependencies**: Prepares the SwiftAzureOpenAI package
4. **Pre-builds the Package**: Compiles the package for faster Copilot operations
5. **Validates Environment**: Ensures all tools are working correctly

### 3. Validation

The setup workflow can be manually triggered to validate the environment:

1. Go to **Actions** tab in your repository
2. Select "Copilot Setup Steps" workflow
3. Click "Run workflow" to test the setup

## How It Works

When GitHub Copilot starts working on your repository:

1. The `copilot-setup-steps` job runs first in a clean Ubuntu environment
2. All setup steps complete, preparing the development environment
3. Copilot begins working with a fully configured Swift development environment
4. Environment variables are available during Copilot's operations
5. The package is pre-built, so Copilot can immediately run tests and builds

## Benefits

- **Faster Operations**: Pre-built environment reduces setup time for each Copilot session
- **Consistent Environment**: Ensures Copilot uses the exact same Swift version and dependencies
- **API Access**: Copilot can run live tests against Azure OpenAI when needed
- **Better Context**: Copilot understands the project structure and can build/test effectively

## Troubleshooting

### Environment Variables Not Available
- Verify the variables are set in the `copilot` environment (not just repository variables)
- Check that variable names exactly match: `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_DEPLOYMENT`

### Setup Workflow Fails
- Check the workflow logs in the Actions tab
- Ensure the workflow file is on the main branch
- Verify YAML syntax is valid

### Copilot Can't Build/Test
- Run the setup workflow manually to validate the environment
- Check that Swift 6.0.2 installation completed successfully
- Verify package dependencies resolved without errors

## Security Notes

- The API key is stored as a secret and not exposed in logs
- The setup workflow only has `contents: read` permissions
- Environment variables are only available to the Copilot agent, not to other workflows or users