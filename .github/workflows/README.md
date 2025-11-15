# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the SwiftAzureOpenAI package.

## Workflows

### 1. CI (`ci.yml`)
- **Trigger**: Push/PR to main or develop branches
- **Purpose**: Continuous integration testing on macOS and Linux
- **No configuration required**

### 2. Release Approval (`release-approval.yml`)
- **Trigger**: CI success or manual dispatch
- **Purpose**: Human-approved release process
- **Requires**: Environment `release-approval` with required reviewers

### 3. Release (`release.yml`)
- **Trigger**: Version tags (e.g., `v1.0.0`)
- **Purpose**: Automated release creation
- **No configuration required**

### 4. Nightly Code Generation (`nightly-codegen.yml`)
- **Trigger**: Scheduled nightly at 2 AM UTC or manual dispatch
- **Purpose**: Automated OpenAPI spec sync and model regeneration
- **Requires**: `PAT_TOKEN` secret (see below)

## Required Secrets

### PAT_TOKEN (Required for Nightly Code Generation)

The nightly code generation workflow requires a Personal Access Token to create pull requests.

**Why is this needed?**
- The default `GITHUB_TOKEN` has restrictions that prevent automated PR creation when "Allow GitHub Actions to create and approve pull requests" is disabled in repository settings
- A PAT bypasses this restriction for authorized users

**Setup Instructions:**

1. **Create a Personal Access Token (PAT)**:
   - Go to [GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)](https://github.com/settings/tokens)
   - Click "Generate new token (classic)"
   - **Name**: `SwiftAzureOpenAI Nightly Codegen`
   - **Scopes**: Select `repo` (Full control of private repositories)
   - **Expiration**: Set to 1 year (GitHub will notify before expiration)
   - Click "Generate token" and **copy the token value** (you won't see it again!)

2. **Add the PAT to repository secrets**:
   - Go to repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - **Name**: `PAT_TOKEN`
   - **Value**: Paste the token value from step 1
   - Click "Add secret"

3. **Verification**:
   - Navigate to Actions → Nightly Code Generation → Run workflow
   - Manually trigger the workflow to test
   - The "Create Pull Request" step should succeed

**Fallback Behavior**:
- If `PAT_TOKEN` is not configured, the workflow will fall back to `GITHUB_TOKEN`
- This may work in some repository configurations but will fail if GitHub Actions is not permitted to create PRs

**Token Security**:
- Secrets are encrypted and never exposed in logs
- Only workflow runs can access secrets
- Rotate the token periodically for security

## Other Optional Secrets

### AZURE_OPENAI_API_KEY
- **Purpose**: Live API testing with Azure OpenAI
- **Used by**: `ci.yml` (optional tests)
- **Setup**: Add your Azure OpenAI API key as a repository secret

## Troubleshooting

### Nightly Codegen Fails with "not permitted to create pull requests"
→ Solution: Configure `PAT_TOKEN` secret (see above)

### PR Creation Works but CI Doesn't Trigger on Created PR
→ This is expected behavior with `GITHUB_TOKEN` to prevent recursive workflows
→ Solution: Use `PAT_TOKEN` which allows triggering workflows on created PRs

### Token Expired
→ Solution: Generate a new PAT and update the `PAT_TOKEN` secret

## Documentation

For detailed workflow documentation, see:
- [CI/CD Documentation](../../docs/CI-CD.md)
- [Code Generation Documentation](../../docs/CODE_GENERATION.md)
