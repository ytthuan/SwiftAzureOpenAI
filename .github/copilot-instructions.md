# SwiftAzureOpenAI Development Instructions

**ALWAYS follow these instructions first and only fallback to additional search and context gathering if the information here is incomplete or found to be in error.**

SwiftAzureOpenAI is a Swift Package Manager library that provides seamless integration with Azure OpenAI and OpenAI APIs for iOS, macOS, watchOS, tvOS, and other Apple ecosystem applications.

## Requirements

- Swift 6.1+ (verified working with Swift 6.1.2)
- Swift Package Manager (built into Swift toolchain)
- No external dependencies required

## Bootstrap and Build Instructions

### Initial Setup
Run these commands to set up and validate the development environment:

```bash
# Verify Swift installation
swift --version

# Navigate to repository root
cd /path/to/SwiftAzureOpenAI

# Clean any existing build artifacts
swift package clean
```

### Build Commands
**CRITICAL TIMING INFORMATION:**
- Debug build (clean): ~2-25 seconds (NEVER CANCEL - set timeout to 60+ seconds)
- Debug build (incremental): ~0.2-2 seconds  
- Release build: ~1-2 seconds  
- Tests: ~6-15 seconds (NEVER CANCEL - set timeout to 30+ seconds)

```bash
# Debug build (default configuration)
swift build
# Expected time: Clean build ~2-25 seconds, incremental builds ~0.2-2 seconds

# Release build (optimized)
swift build --configuration release
# Expected time: ~1-2 seconds

# Clean build artifacts
swift package clean
```

### Test Commands
**NEVER CANCEL TEST RUNS** - Always wait for completion even if they appear to hang.

```bash
# Run all tests (debug configuration)
swift test
# Expected time: ~6-15 seconds, timeout: 30+ seconds

# Run tests with release configuration  
swift test --configuration release
# Expected time: ~6-15 seconds

# Run tests in parallel
swift test --parallel
# Expected time: ~0.2-6 seconds (faster due to minimal test suite)

# Run tests with environment variables (for live API testing)
export AZURE_OPENAI_ENDPOINT="your-test-endpoint"
export AZURE_OPENAI_API_KEY="your-test-key"
export AZURE_OPENAI_DEPLOYMENT="your-test-deployment"
swift test
```

## Package Management Commands

```bash
# Show package information
swift package describe

# Show dependency graph (currently no external dependencies)
swift package show-dependencies

# Resolve dependencies
swift package resolve

# Get package metadata as JSON
swift package dump-package

# Update dependencies (when they exist)
swift package update
```

## Project Structure

### Key Directories and Files
```
SwiftAzureOpenAI/
├── Package.swift                          # Package manifest (Swift 6.1 tools version)
├── README.md                             # Comprehensive documentation
├── Sources/
│   └── SwiftAzureOpenAI/
│       └── SwiftAzureOpenAI.swift       # Main library source (minimal placeholder)
├── Tests/
│   └── SwiftAzureOpenAITests/
│       └── SwiftAzureOpenAITests.swift  # Test suite (placeholder test)
└── .build/                              # Build artifacts (created after building)
```

### Important Notes About Project Structure
- **No external dependencies**: This package has zero external dependencies
- **Minimal implementation**: Current source files contain placeholder code only
- **Missing files**: CONTRIBUTING.md, LICENSE, CHANGELOG.md mentioned in README do not exist
- **No Examples directory**: Despite README mentions, the Examples directory does not exist
- **No GitHub workflows**: No CI/CD configuration present

## Working Effectively

### Development Workflow
1. **Always build first** after making changes:
   ```bash
   swift build
   ```

2. **Run tests** to validate changes:
   ```bash
   swift test
   ```

3. **Test both configurations** for important changes:
   ```bash
   swift build --configuration release
   swift test --configuration release
   ```

### Validation Requirements
**CRITICAL**: After making any code changes, ALWAYS run:

1. **Build validation**:
   ```bash
   swift build                    # Debug build
   swift build --configuration release  # Release build
   ```

2. **Test validation**:
   ```bash
   swift test                     # All tests
   swift test --parallel          # Parallel execution
   ```

3. **Package validation**:
   ```bash
   swift package describe         # Verify package structure
   ```

### Manual Testing Scenarios
Since this is a library package with minimal implementation:

1. **Build verification**: Ensure both debug and release builds complete successfully
2. **Test execution**: Verify test suite runs without failures
3. **Package validation**: Confirm package structure is valid
4. **Environment variable testing**: Test with Azure OpenAI environment variables set

**Note**: Currently no functional validation scenarios are possible due to placeholder implementation.

## Common Tasks and Troubleshooting

### Build Issues
- **Clean build**: Use `swift package clean` to remove all build artifacts
- **Build hanging**: NEVER CANCEL - builds may take up to 25 seconds
- **Missing Swift**: Verify Swift 6.1+ is installed with `swift --version`

### Test Issues  
- **Tests hanging**: NEVER CANCEL - test runs may take up to 15 seconds
- **Environment variable tests**: Set AZURE_OPENAI_* variables before running tests
- **No actual tests**: Current test suite only contains a placeholder test

### Package Issues
- **No dependencies**: This package intentionally has no external dependencies
- **Package resolution**: `swift package resolve` will complete instantly

## Performance Expectations

### Command Timing (measured on standard development environment)
- `swift build` (clean debug): ~2-25 seconds
- `swift build` (incremental debug): ~0.2-2 seconds  
- `swift build --configuration release`: ~1-2 seconds
- `swift test`: ~6-15 seconds
- `swift test --parallel`: ~0.2-6 seconds
- `swift package clean`: <1 second
- `swift package describe`: <1 second

### **CRITICAL TIMEOUT SETTINGS**
When using these commands in automated environments:
- Build commands: Set timeout to **60+ minutes** (NEVER CANCEL)
- Test commands: Set timeout to **30+ minutes** (NEVER CANCEL)  
- Package commands: Set timeout to **5+ minutes**

## Platform and Target Information

### Supported Platforms (per README)
- iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ / tvOS 13.0+
- Xcode 15.0+
- Swift 5.9+ (package uses Swift 6.1 tools version)

### Build Targets
- **SwiftAzureOpenAI**: Main library target
- **SwiftAzureOpenAITests**: Test target

## Code Quality and Validation

### No Linting Tools Present
- SwiftFormat: Not installed/configured
- SwiftLint: Not installed/configured  
- No custom linting scripts or configurations

### Validation Checklist
Before committing changes, ALWAYS:
- [ ] Run `swift build` successfully
- [ ] Run `swift build --configuration release` successfully  
- [ ] Run `swift test` with all tests passing
- [ ] Verify package structure with `swift package describe`
- [ ] Test with environment variables if making API-related changes

## Quick Reference

### Repository Information
- **GitHub URL**: https://github.com/ytthuan/SwiftAzureOpenAI
- **Package Name**: SwiftAzureOpenAI
- **Swift Tools Version**: 6.1
- **Dependencies**: None
- **License**: MIT (per README, file not present)

### Essential Commands Summary
```bash
# Setup and validation
swift --version                    # Check Swift installation
swift package describe             # Package information

# Build and test
swift build                        # Debug build (~25s)
swift build --configuration release # Release build (~1s)
swift test                         # Run tests (~15s)

# Maintenance  
swift package clean               # Clean build artifacts
swift package resolve             # Resolve dependencies (instant)
```

**Remember**: This package is currently in early development with placeholder implementation. The comprehensive API described in the README is not yet implemented in the source code.