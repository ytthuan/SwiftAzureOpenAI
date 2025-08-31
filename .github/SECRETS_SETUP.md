# GitHub Secrets Setup for Azure OpenAI Integration

This document explains how to configure GitHub secrets for Azure OpenAI API testing in the SwiftAzureOpenAI repository.

## Required Secrets

The following secrets must be configured in the repository settings to enable live Azure OpenAI API testing:

### Repository Secrets

Navigate to **Settings > Secrets and variables > Actions** in your GitHub repository and add these secrets:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AZURE_OPENAI_ENDPOINT` | Your Azure OpenAI resource endpoint | `https://your-resource.openai.azure.com` |
| `AZURE_OPENAI_API_KEY` | Your Azure OpenAI API key | `abcd1234...` (32+ character key) |
| `AZURE_OPENAI_DEPLOYMENT` | Your Azure OpenAI deployment name | `gpt-4o` |

### Environment-Specific Secrets

For enhanced security in the `release-approval` environment, you may also configure environment-specific secrets:

1. Go to **Settings > Environments**
2. Select or create the `release-approval` environment
3. Add the same secrets listed above as environment secrets

## How Secrets Are Used

The GitHub Actions workflows automatically provide these secrets as environment variables to test jobs:

```yaml
- name: Run tests
  run: swift test
  env:
    AZURE_OPENAI_ENDPOINT: ${{ secrets.AZURE_OPENAI_ENDPOINT }}
    AZURE_OPENAI_API_KEY: ${{ secrets.AZURE_OPENAI_API_KEY }}
    AZURE_OPENAI_DEPLOYMENT: ${{ secrets.AZURE_OPENAI_DEPLOYMENT }}
```

## Test Behavior

- **With secrets configured**: Live API tests will run and validate actual Azure OpenAI functionality
- **Without secrets**: Live API tests will be automatically skipped with informative messages

## Security Notes

- Secrets are automatically masked in workflow logs
- API keys should be production-ready keys with appropriate rate limits
- Consider using separate Azure OpenAI resources for CI/CD testing
- Environment secrets provide additional protection for release workflows

## Workflows That Use Secrets

The following workflows have been updated to use Azure OpenAI secrets:

- `.github/workflows/ci.yml` - Main CI pipeline
- `.github/workflows/release-approval.yml` - Release validation
- `.github/workflows/release.yml` - Release testing

## Validation

To verify secrets are working correctly:

1. Check the workflow run logs for "Test skipped" messages (if secrets missing)
2. Look for actual API test execution (if secrets present)
3. Monitor test coverage reports for live API test inclusion