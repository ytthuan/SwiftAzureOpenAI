# SwiftAzureOpenAI CI/CD Documentation

> **⚠️ Internal Development**: This document describes the CI/CD workflows implemented for internal development and testing of the SwiftAzureOpenAI SDK.

## Overview

This package includes comprehensive CI/CD automation through GitHub Actions to ensure code quality, testing, and automated releases during our internal development process.

## GitHub Actions Workflows

### 1. Continuous Integration (`.github/workflows/ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**
- **test-macos**: Tests on macOS with Swift 6.0.2 (Xcode 16.0)
- **test-linux**: Tests on Ubuntu with Swift 6.0.2
- **validate-package**: Validates package structure and dependencies
- **code-quality**: Checks for warnings and code quality

**Features:**
- Tests both debug and release configurations
- Parallel test execution
- Multi-platform validation (macOS, Linux)
- Zero external dependencies verification
- Build warning detection

### 2. Release Approval Workflow (`.github/workflows/release-approval.yml`) - **Enhanced**

**Triggers:**
- CI workflow completion with success on main/develop branches
- Manual workflow dispatch (workflow_dispatch)

**Jobs:**
- **check-ci-success**: Validates CI workflow completed successfully (for automated triggers)
- **validate-for-release**: Comprehensive package validation
- **await-release-approval**: Human approval gate with environment protection
- **trigger-release**: Creates version tag after approval

**Features:**
- Automatically triggers after CI workflow success
- Human approval requirement with GitHub Environments (can approve/reject)
- Version suggestion based on existing tags
- Manual version override capability
- Support for different release types (release/prerelease/beta/alpha)
- Comprehensive validation summary and release checklist
- Clear indication of trigger source (CI success vs manual)

### 3. Release Automation (`.github/workflows/release.yml`) - **Enhanced**

**Triggers:**
- Version tags (e.g., `v1.0.0`, `v1.0.0-beta`, `1.0.0`)

**Jobs:**
- **validate-release**: Final validation before release
- **test-release**: Multi-platform release build testing
- **create-release**: Creates GitHub release with changelog
- **validate-installation**: Tests package installation

**Features:**
- Automatic changelog generation
- Cross-platform release validation
- GitHub release creation with prerelease detection
- Installation validation with test projects
- Support for both `v1.0.0` and `1.0.0` tag formats

### 4. Nightly Code Generation (`.github/workflows/nightly-codegen.yml`)

**Triggers:**
- Scheduled nightly at 2 AM UTC
- Manual workflow dispatch with optional force regeneration

**Jobs:**
- **check-and-regenerate**: Automated model regeneration on macOS 15

**Features:**
- Downloads latest Azure OpenAPI specification
- Compares with current specification for changes
- Automatically regenerates Swift models if changes detected
- Creates pull requests with generated model updates
- Runs full test suite to validate generated code
- Provides detailed diff reports for code review

**Environment:**
- **Platform**: macOS 15 (changed from Ubuntu for better Swift toolchain compatibility)
- **Swift**: 6.0.2 via Xcode 16.0
- **Python**: 3.9 for code generation scripts

**Benefits:**
- Zero manual intervention for API updates
- Fast update cycle (changes reflected within 24 hours)
- Quality assurance through automated testing
- Transparent process with pull request workflow

## Release Process

### Option 1: Automated Release with Human Approval (Recommended)

This is the **recommended approach** for production releases, providing automated validation with human oversight.

#### Workflow:
1. **Push to main branch** - Triggers CI workflow
2. **CI workflow completes successfully** - Automatically triggers release approval workflow
3. **Human approval required** - Review validation results and approve/reject
4. **Automatic release creation** - Creates GitHub release once approved

#### Steps:
1. **Ensure main branch is ready:**
   ```bash
   # Make sure all changes are on main
   git checkout main
   git pull origin main
   ```

2. **Push triggers CI, then release approval:**
   - Push to main triggers the CI workflow first
   - When CI completes successfully, `release-approval.yml` automatically runs
   - Validates package structure, tests, and quality
   - Suggests next version number
   - Waits for human approval

3. **Review and approve:**
   - Go to GitHub Actions tab
   - Find the "Release Approval Workflow" run
   - Review validation results
   - Approve the deployment in the `release-approval` environment
   - **OR** reject if issues are found

4. **Automatic release creation:**
   - Once approved, creates and pushes version tag
   - Triggers the main release workflow
   - Creates GitHub release with changelog

#### Important Notes:
- **CI Must Pass**: The release approval workflow only triggers if CI completes successfully
- **If CI Fails**: Fix issues in your code and push again - the workflow will retry after CI passes
- **Manual Override**: You can still trigger releases manually if needed (see below)

#### Manual Version Override:
You can also trigger this workflow manually with a specific version:

1. Go to GitHub Actions → "Release Approval Workflow"
2. Click "Run workflow"
3. Enter your desired version (e.g., `1.2.0`)
4. Select release type (release/prerelease/beta/alpha)
5. Approve when ready

### Option 2: Direct Tag Release (Legacy)

For immediate releases without approval (use with caution):

1. **Create a version tag:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **GitHub Actions automatically:**
   - Validates the package
   - Runs comprehensive tests
   - Creates a GitHub release
   - Tests installation

### Option 3: Manual Validation Before Release

Use the included release preparation script to validate before any release:

```bash
./scripts/prepare-release.sh
```

This script validates:
- Swift version compatibility
- Package structure
- Zero dependencies requirement
- Clean builds (debug and release)
- All 85 tests passing
- No build warnings
- Required files (README.md, LICENSE)

### Release Types

The enhanced workflow supports different release types:

- **`release`** - Stable production release (default)
- **`prerelease`** - Release candidate, feature preview
- **`beta`** - Beta testing version
- **`alpha`** - Early development version

Versions with suffixes (e.g., `1.0.0-beta`, `1.0.0-rc1`) are automatically marked as prereleases.

### Best Practices

1. **Use the approval workflow** for all production releases
2. **Test thoroughly** before pushing to main
3. **Review validation results** carefully before approval
4. **Use semantic versioning** (major.minor.patch)
5. **Use prereleases** for testing new features
6. **Document changes** in commit messages for automatic changelog generation

### Environment Protection

The approval workflow uses GitHub Environments with protection rules:

- **Environment**: `release-approval`
- **Required reviewers**: Repository maintainers
- **Deployment branches**: Only `main` branch
- **Manual approval**: Required for all releases

To configure:
1. Go to Settings → Environments
2. Click "release-approval"
3. Add required reviewers
4. Configure protection rules as needed

## Package Quality Standards

### Testing
- **85+ comprehensive tests** covering all functionality
- **Multi-platform testing** (macOS, Linux)
- **Both debug and release** configuration testing
- **Parallel test execution** support

### Build Quality
- **Zero warnings** requirement
- **No external dependencies** policy
- **Swift 6.0+ compatibility**
- **Cross-platform compilation**

### Code Quality
- **Comprehensive error handling**
- **Full Azure OpenAI and OpenAI Responses API coverage**
- **Response caching and streaming support**
- **Request/response ID extraction**

## Installation for Developers

Users can install this package via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/ytthuan/SwiftAzureOpenAI", from: "1.0.0")
]
```

## CI/CD Maintenance

### Updating Workflows

1. **Add new platforms**: Update matrix in workflows
2. **Update Swift versions**: Modify version specifications
3. **Add quality checks**: Extend validation steps

### Monitoring

- Check GitHub Actions tab for workflow status
- Review failed builds promptly
- Monitor test coverage and performance

### Recent Improvements

**Enhanced CI Efficiency (Issue #53 Fixes):**
- **CI-Triggered Release**: `release-approval.yml` now triggers automatically after CI success on main/develop
- **Human Approval Gate**: Requires manual approval before release creation (can approve/reject)
- **Consistent Swift Versions**: Standardized on Swift 6.0.2 across all platforms (macOS and Linux)
- **Improved Workflow**: Clear sequence: CI Success → Release Approval → Human Decision → Release Creation

**Workflow Triggers:**
- **CI Workflow**: Runs on pushes/PRs to main/develop branches
- **Release Approval**: Triggers after CI success OR manual dispatch (workflow_dispatch)
- **Release**: Triggered by version tags after approval

## Benefits

1. **Automated Quality Assurance**: Every change is validated
2. **Multi-Platform Support**: Tested on macOS and Linux with consistent Swift 6.0.2
3. **Efficient CI Process**: Single CI run per push, no duplicate workflows
4. **Zero-Downtime Releases**: Automated release process with human approval
5. **Installation Validation**: Confirms packages work for end users
6. **Comprehensive Testing**: 85+ tests ensure reliability