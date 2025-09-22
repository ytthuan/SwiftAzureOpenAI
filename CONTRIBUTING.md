# Contributing to SwiftAzureOpenAI

Welcome! This guide covers how to contribute to SwiftAzureOpenAI, including our selective code generation approach and development workflow.

## 🎯 Project Philosophy

SwiftAzureOpenAI follows a **focused scope** approach:
- **Primary Platform**: Azure OpenAI (compatible with OpenAI where trivial)
- **Core Features**: Responses API, Embeddings API, Files API  
- **Modalities**: Text + Vision (no audio, no realtime)
- **Architecture**: High-level Swift-friendly API on top of generated DTOs

## 🔧 Development Setup

### Prerequisites
- Swift 6.0+ (currently using Swift 6.1.2)
- macOS, Linux, or other Swift-supported platform
- Python 3.11+ (for code generation scripts)

### Quick Start
```bash
# Clone and build
git clone https://github.com/ytthuan/SwiftAzureOpenAI.git
cd SwiftAzureOpenAI
swift build

# Run tests
swift test
```

### Environment Variables for Testing
```bash
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
export AZURE_OPENAI_API_KEY="your-api-key"  
export AZURE_OPENAI_DEPLOYMENT="your-deployment-name"

# Enable live API tests
swift test
```

## 📋 Project Structure

```
SwiftAzureOpenAI/
├── Sources/SwiftAzureOpenAI/
│   ├── Core/                     # Main clients and configuration
│   ├── Models/                   # Hand-written request/response models
│   ├── Services/                 # Response processing services
│   ├── Extensions/               # Foundation extensions
│   └── Generated/                # 🤖 Generated models from OpenAPI
├── Scripts/
│   └── prune-openapi-spec.py     # OpenAPI specification pruning
├── Specs/
│   ├── azure-openai-full.json    # Full Azure OpenAI specification
│   ├── pruned-openapi.json       # Pruned spec (responses/files/embeddings)
│   └── spec-metadata.json        # Update metadata
├── Tests/                        # Comprehensive test suite (330+ tests)
└── .github/workflows/
    └── nightly-spec-regeneration.yml  # Automated spec updates
```

## 🤖 Selective Code Generation

SwiftAzureOpenAI uses **selective code generation** to generate only low-level DTOs while maintaining hand-written high-level APIs.

### How It Works

1. **Full Specification**: Download complete Azure OpenAI API spec
2. **Pruning**: Keep only `/responses`, `/files`, `/embeddings` endpoints  
3. **Generation**: Generate Swift models for pruned specification
4. **Integration**: Use generated models in hand-written high-level API

### OpenAPI Specification Management

#### Automatic Updates
- **Nightly Workflow**: `.github/workflows/nightly-spec-regeneration.yml`
- **Monitors**: Azure OpenAI API specification changes
- **Actions**: Downloads, prunes, regenerates, and creates review issues

#### Manual Regeneration
```bash
# 1. Update full specification (if needed)
curl -o Specs/azure-openai-full.json \
  "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/preview/2024-10-01-preview/inference.json"

# 2. Prune specification
python3 Scripts/prune-openapi-spec.py

# 3. Generate Swift models (using your preferred generator)
# See "Code Generation" section below
```

### Pruning Script (`Scripts/prune-openapi-spec.py`)

The pruning script removes unnecessary endpoints and schemas:

**Keeps:**
- `/responses` - Core response generation endpoint
- `/embeddings` - Vector embeddings endpoint
- `/files` - File upload/management endpoints
- Related schemas and security definitions

**Removes:**
- `/chat/completions` - Use `/responses` instead
- `/completions` - Legacy completions
- `/images/generations` - Image generation (out of scope)
- `/moderations` - Moderation (future consideration)
- Unused schemas and security schemes

**Usage:**
```bash
python3 Scripts/prune-openapi-spec.py
# Input:  Specs/azure-openapi-full.json
# Output: Specs/pruned-openapi.json
```

### Code Generation

#### Generate Swift Models

You can use any OpenAPI code generator. Here are recommended approaches:

**Option 1: OpenAPI Generator CLI**
```bash
# Install openapi-generator
npm install -g @openapitools/openapi-generator-cli

# Generate Swift models
openapi-generator generate \
  -i Specs/pruned-openapi.json \
  -g swift5 \
  -o Sources/SwiftAzureOpenAI/Generated/ \
  --additional-properties=projectName=SwiftAzureOpenAI,unwrapRequired=true
```

**Option 2: Swift OpenAPI Generator**
```bash
# Using Swift OpenAPI Generator (if available)
swift-openapi-generator generate \
  --input Specs/pruned-openapi.json \
  --output Sources/SwiftAzureOpenAI/Generated/
```

**Option 3: Custom Generation** 
The current `Sources/SwiftAzureOpenAI/Generated/GeneratedModels.swift` provides a template that can be updated manually or with custom scripts.

#### Generated Model Guidelines

**Naming Convention:**
- Prefix generated models with `Generated` (e.g., `GeneratedResponsesRequest`)
- Use clear, descriptive names matching OpenAPI schema names
- Follow Swift naming conventions (camelCase for properties)

**Property Handling:**
- Make all properties optional to handle unknown fields gracefully
- Use proper `CodingKeys` for snake_case API fields
- Implement `Codable` and `Equatable` protocols

**Example:**
```swift
public struct GeneratedResponsesRequest: Codable, Equatable {
    public let model: String
    public let input: [GeneratedInputMessage]
    public let maxOutputTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case model, input
        case maxOutputTokens = "max_output_tokens"
    }
}
```

## 🏗️ Architecture Guidelines

### High-Level API Design
- **Client Structure**: `client.responses.create()`, `client.embeddings.create()`, `client.files.upload()`
- **Request/Response**: Use hand-written models for public API, generated models internally
- **Error Handling**: Comprehensive error taxonomy with categories
- **Streaming**: Support for server-sent events with structured parsing

### Model Integration Strategy
```swift
// Hand-written public API
public struct SAOAIResponsesRequest {
    // High-level, Swift-friendly properties
    public let model: String
    public let messages: [ResponseMessage]
    public let reasoning: SAOAIReasoning?
    
    // Convert to generated model for API call
    func toGenerated() -> GeneratedResponsesRequest {
        return GeneratedResponsesRequest(
            model: model,
            input: messages.map { $0.toGenerated() }
        )
    }
}

// Generated model (internal use)
public struct GeneratedResponsesRequest: Codable {
    public let model: String
    public let input: [GeneratedInputMessage]
    // ... generated properties
}
```

### Testing Strategy
- **Unit Tests**: Test hand-written models and conversion logic
- **Integration Tests**: Test against generated models and real API
- **Fixture Tests**: Use captured API responses for regression testing
- **Live API Tests**: Optional tests with real Azure OpenAI credentials

## 🔄 Development Workflow

### Making Changes

1. **Open Issue**: Describe the feature or fix needed
2. **Create Branch**: Use descriptive branch names (`feature/embeddings-batch`, `fix/streaming-error`)
3. **Implement**: Make minimal, focused changes
4. **Test**: Ensure all tests pass (`swift test`)
5. **Update Models**: If API shapes change, regenerate models
6. **Update Changelog**: Add entry to `CHANGELOG.md`
7. **Submit PR**: Include tests and documentation updates

### Model Shape Changes

When modifying request/response models:
1. **Update OpenAPI Spec**: If needed, update the pruned specification
2. **Regenerate Models**: Run code generation process
3. **Update Conversions**: Ensure hand-written ↔ generated model conversions work
4. **Test Thoroughly**: Run full test suite including live API tests

### Release Process

1. **Validation**: Run `./scripts/prepare-release.sh` for comprehensive checks
2. **Version**: Update version in appropriate files
3. **Changelog**: Ensure `CHANGELOG.md` is updated
4. **Tag**: Create version tag (triggers automated release)

## 📊 Quality Standards

### Code Quality
- **Swift 6 Compliance**: Use latest Swift features and strict concurrency
- **Zero Dependencies**: Maintain dependency-free architecture
- **Comprehensive Tests**: Aim for high test coverage (currently 330+ tests)
- **Performance**: Optimize for memory usage and response time

### API Design
- **Backward Compatibility**: Avoid breaking changes in public API
- **Forward Compatibility**: Handle unknown JSON fields gracefully
- **Ergonomics**: Provide Swift-friendly convenience methods
- **Documentation**: Include comprehensive examples and documentation

### Generated Code
- **Minimal Changes**: Only regenerate when OpenAPI spec changes
- **Review Changes**: Manually review generated model changes before committing
- **Namespace Separation**: Keep generated models in separate namespace/directory
- **No Manual Edits**: Never manually edit generated files

## 🎯 Contribution Areas

### High Priority
- **Ergonomics Improvements**: Convenience methods, helper functions
- **Observability**: Metrics, logging, correlation IDs  
- **Performance**: Streaming optimizations, memory efficiency
- **Testing**: Additional edge cases and integration scenarios

### Medium Priority  
- **Code Generation**: Improve automation and tooling
- **Documentation**: Examples, guides, API reference
- **Error Handling**: Enhanced error messages and recovery

### Future Considerations
- **New Endpoints**: Moderations, assistants (if community demand)
- **Advanced Features**: Vector search helpers, chunking utilities
- **Platform Support**: Additional Swift platforms

## 🐛 Bug Reports and Feature Requests

### Bug Reports
Include:
- Swift version and platform
- Minimal reproduction case  
- Expected vs actual behavior
- Relevant logs or error messages

### Feature Requests
Include:
- Use case description
- Proposed API design
- Alignment with project scope and philosophy

## 📚 Resources

- **Roadmap**: [`ROADMAP.md`](ROADMAP.md) - Project direction and phases
- **API Documentation**: Generated documentation for public API
- **Test Examples**: [`Tests/`](Tests/) - Comprehensive test examples
- **Azure OpenAI Docs**: [Official Azure OpenAI Documentation](https://docs.microsoft.com/en-us/azure/ai-services/openai/)

## 🤝 Community

- **Issues**: Use GitHub Issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Code Review**: All changes go through PR review process
- **Respectful Communication**: Follow standard open source etiquette

---

Thank you for contributing to SwiftAzureOpenAI! Your contributions help make Azure OpenAI more accessible to the Swift community. 🚀