# SwiftAzureOpenAI CI/CD Documentation

## Overview

This package includes comprehensive CI/CD automation through GitHub Actions to ensure code quality, testing, and automated releases.

## GitHub Actions Workflows

### 1. Continuous Integration (`.github/workflows/ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**
- **test-macos**: Tests on macOS with Xcode 15.4
- **test-linux**: Tests on Ubuntu with Swift 6.1.2
- **validate-package**: Validates package structure and dependencies
- **code-quality**: Checks for warnings and code quality

**Features:**
- Tests both debug and release configurations
- Parallel test execution
- Multi-platform validation (macOS, Linux)
- Zero external dependencies verification
- Build warning detection

### 2. Release Automation (`.github/workflows/release.yml`)

**Triggers:**
- Version tags (e.g., `v1.0.0`, `v1.0.0-beta`)

**Jobs:**
- **validate-release**: Final validation before release
- **test-release**: Multi-platform release build testing
- **create-release**: Creates GitHub release with changelog
- **validate-installation**: Tests package installation

**Features:**
- Automatic changelog generation
- Cross-platform release validation
- GitHub release creation
- Installation validation with test projects

## Release Process

### Automated Release

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

### Manual Validation

Use the included release preparation script:

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

## Package Quality Standards

### Testing
- **85+ comprehensive tests** covering all functionality
- **Multi-platform testing** (macOS, Linux)
- **Both debug and release** configuration testing
- **Parallel test execution** support

### Build Quality
- **Zero warnings** requirement
- **No external dependencies** policy
- **Swift 6.1+ compatibility**
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

## Benefits

1. **Automated Quality Assurance**: Every change is validated
2. **Multi-Platform Support**: Tested on macOS and Linux
3. **Zero-Downtime Releases**: Automated release process
4. **Installation Validation**: Confirms packages work for end users
5. **Comprehensive Testing**: 85+ tests ensure reliability