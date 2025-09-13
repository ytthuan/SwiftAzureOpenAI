# SwiftAzureOpenAI Development Instructions

**ALWAYS follow these instructions first and only fallback to additional search and context gathering if the information here is incomplete or found to be in error.**

## Repository Overview

SwiftAzureOpenAI is a Swift Package Manager library providing seamless integration with Azure OpenAI and OpenAI Responses APIs for iOS, macOS, watchOS, tvOS, and other Apple platforms.

**Key Facts:**
- **Language**: Swift 6.0+ (currently using Swift 6.1.2)
- **Package Manager**: Swift Package Manager (SPM) only
- **Dependencies**: Zero external dependencies (intentional design)
- **Test Coverage**: 260 comprehensive tests across 40+ test files
- **Platforms**: iOS 13.0+, macOS 10.15+, watchOS 6.0+, tvOS 13.0+
- **API Focus**: Azure OpenAI Responses API (preview) and OpenAI Responses API

## Azure OpenAI API Requirements

### **CRITICAL API VERSION REQUIREMENT**
- **API Version**: Uses `"preview"` version through query parameter
- **Endpoint Format**: `https://{resource}.openai.azure.com/openai/v1/responses?api-version=preview`
- **Authentication**: Use `api-key` header (not Authorization Bearer token)

Default configuration:
```swift
guard let endpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] else {
            throw RuntimeError("AZURE_OPENAI_ENDPOINT is not set")
        }

// Use API key authentication as specified in the issue
let apiKey = ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ??
                    ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"] ??
                    "your-api-key"
        
let deploymentName = ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? "gpt-5-nano"


SAOAIAzureConfiguration(
    endpoint: endpoint,
    apiKey: apiKey, 
    deploymentName: deploymentName,
    apiVersion: "preview"  // ✅ Used as query parameter
)
```

## Build and Test Commands

### **CRITICAL TIMING INFORMATION**
Commands may take longer than expected - NEVER CANCEL:
- `swift build` (clean): ~2-25 seconds
- `swift test`: ~10-25 seconds (260 tests)
- Set timeouts to 60+ seconds for builds, 30+ seconds for tests

### Essential Commands
```bash
# Setup and validation
swift --version                    # Check Swift installation (need 6.0+)
swift package describe             # Package structure validation

# Build (NEVER CANCEL - wait full timeout)
swift build                        # Debug build
swift build --configuration release # Release build

# Test (NEVER CANCEL - 260 tests take time)
swift test                         # All tests
swift test --parallel             # Parallel execution (faster)

# Maintenance
swift package clean               # Clean build artifacts
swift package resolve             # Resolve dependencies (instant - zero deps)
```

### Environment Variables for Live API Testing - already set below variables and secret: 

Variables: AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_DEPLOYMENT
Secret: COPILOT_AGENT_AZURE_OPENAI_API_KEY
```bash
swift test  # Enables live API tests
```

### RawApiTesting.swift - Standalone API Testing Tool - already set below variables and secret, use them

# Direct Azure OpenAI endpoint testing (captures real response data)
Variables: AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_DEPLOYMENT
Secret: COPILOT_AGENT_AZURE_OPENAI_API_KEY

```bash
swift RawApiTesting.swift           # Direct endpoint validation
```

## Project Architecture and Key Locations

### Core Structure
```
SwiftAzureOpenAI/
├── Package.swift                    # Package manifest (Swift 6.0 tools)
├── Sources/SwiftAzureOpenAI/
│   ├── Core/                       # Main client and configuration
│   │   ├── Configuration.swift     # Azure/OpenAI configurations
│   │   ├── HTTPClient.swift        # HTTP networking
│   │   ├── ResponsesClient.swift   # Main API client
│   │   └── SwiftAzureOpenAI.swift  # Legacy client
│   ├── Services/                   # Response processing services
│   │   ├── *ResponseService.swift  # Response processing
│   │   ├── *StreamingResponseService.swift # Streaming
│   │   └── ResponseCacheService.swift # Caching
│   ├── Models/                     # Request/Response models
│   │   ├── Common/                 # Shared models (errors, metadata)
│   │   ├── Requests/               # Request models
│   │   └── Responses/              # Response models
│   └── Extensions/                 # Foundation extensions
├── Tests/SwiftAzureOpenAITests/    # 260 comprehensive tests
├── RawApiTesting.swift             # Standalone API testing tool
├── .github/workflows/              # CI/CD automation
│   ├── ci.yml                      # Continuous integration
│   ├── release-approval.yml        # Release approval workflow
│   └── release.yml                 # Release automation
├── scripts/prepare-release.sh      # Release validation script
└── docs/                          # Comprehensive documentation
```

### Key Files for Common Changes
- **API Integration**: `Sources/SwiftAzureOpenAI/Core/ResponsesClient.swift`
- **Request Models**: `Sources/SwiftAzureOpenAI/Models/Requests/`
- **Response Models**: `Sources/SwiftAzureOpenAI/Models/Responses/`
- **Error Handling**: `Sources/SwiftAzureOpenAI/Models/Common/OpenAIError.swift`
- **Streaming**: `Sources/SwiftAzureOpenAI/Services/*StreamingResponseService.swift`
- **Configuration**: `Sources/SwiftAzureOpenAI/Core/Configuration.swift`

### Important Dependencies and Facts
- **Zero External Dependencies**: Package intentionally has no external dependencies
- **Modern Swift**: Uses Swift 6.0 with full concurrency support (async/await)
- **Cross-Platform**: Works on all Apple platforms + Linux
- **Test-Driven**: 260 tests covering all functionality including streaming, caching, error handling
- **CI/CD Integration**: Comprehensive GitHub Actions with multi-platform testing

## Validation Requirements

### After ANY Code Changes, ALWAYS Run:
```bash
# 1. Build validation
swift build                         # Debug build
swift build --configuration release # Release build

# 2. Test validation  
swift test                          # All 260 tests
swift test --parallel               # Parallel execution

# 3. Package validation
swift package describe              # Verify structure

# 4. Raw API integration (if API changes)
swift RawApiTesting.swift           # Direct endpoint testing
```

### Release Validation Script
```bash
./scripts/prepare-release.sh        # Comprehensive validation
```

## CI/CD and Quality Checks

### GitHub Actions Workflows
- **`.github/workflows/ci.yml`**: Multi-platform testing (macOS, Linux)
- **`.github/workflows/release-approval.yml`**: Human-approved releases
- **`.github/workflows/release.yml`**: Automated release creation

### No Linting Tools Present
- No SwiftFormat, SwiftLint, or custom linting configurations
- Quality ensured through comprehensive testing and CI/CD

### Manual Testing Scenarios
1. **Build verification**: Debug and release builds successful
2. **Test execution**: All 260 tests pass
3. **Environment variable testing**: With Azure OpenAI credentials set
4. **API integration**: `RawApiTesting.swift` for direct endpoint validation

## Common Issues and Troubleshooting

### Build Issues
- **Clean build**: Use `swift package clean` first
- **Build hanging**: NEVER CANCEL - wait full timeout (builds can take 25+ seconds)
- **Swift version**: Must be 6.0+ (`swift --version`)

### Test Issues
- **Tests hanging**: NEVER CANCEL - 260 tests take 10-25 seconds
- **Environment variables**: Set `AZURE_OPENAI_*` for live API testing

### Performance Expectations
- `swift build` (clean): ~2-25 seconds
- `swift build` (incremental): ~0.2-2 seconds
- `swift test`: ~10-25 seconds (260 tests)
- `swift package` commands: <1 second

## Comprehensive Documentation

The repository includes detailed documentation in the `docs/` directory:
- **`docs/LIVE_API_TESTING.md`**: Complete guide for live API testing with environment setup
- **`docs/CI-CD.md`**: Detailed CI/CD workflow documentation and GitHub Actions
- **`docs/Release-Guide.md`**: Release process and versioning guidelines
- **`docs/Best-Practices-Analysis.md`**: Development best practices and analysis
- **`AGENTS.md`**: Coding Agent instruction

## Quick Reference

**Repository**: https://github.com/ytthuan/SwiftAzureOpenAI  
**Package Name**: SwiftAzureOpenAI  
**License**: MIT  
**Swift Tools Version**: 6.0  

**Remember**: This is a fully-functional Azure OpenAI/OpenAI Responses API implementation with comprehensive features including response processing, error handling, caching, streaming, and request/response ID tracking.
