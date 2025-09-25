# Contributing to SwiftAzureOpenAI

Thank you for your interest in contributing to SwiftAzureOpenAI! This guide covers the development workflow, including our code generation system.

## Development Setup

### Prerequisites

- Swift 6.0+ (currently using Swift 6.2)
- Python 3.6+ (for code generation scripts)
- Git

### Getting Started

1. Fork and clone the repository
2. Run tests to ensure everything works: `swift test --parallel`
3. Build the project: `swift build`

## Code Generation System

SwiftAzureOpenAI uses automated code generation to maintain models that stay in sync with the Azure OpenAPI specification.

### Generated Models

The code generation system creates Swift models from the Azure OpenAPI specification for the endpoints we support:

- **Responses API** (`/responses` endpoints)
- **Files API** (`/files` endpoints)  
- **Embeddings API** (`/embeddings` endpoint)

Generated models are located in `Sources/SwiftAzureOpenAI/Generated/` and should **never be edited manually**.

### Code Generation Scripts

#### `Scripts/prune-openapi-spec.py`

Downloads and prunes the full Azure OpenAPI specification to include only the endpoints we need:

```bash
python3 Scripts/prune-openapi-spec.py
```

This script:
- Downloads the spec from: https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/ai/data-plane/OpenAI.v1/azure-v1-v1-generated.json
- Keeps only `/responses`, `/files`, and `/embeddings` paths
- Analyzes schema dependencies recursively
- Outputs the pruned spec to `Specs/pruned-openapi.json`

#### `Scripts/generate-swift-models.py`

Generates Swift models from the pruned OpenAPI specification:

```bash
python3 Scripts/generate-swift-models.py
```

This script:
- Reads `Specs/pruned-openapi.json`
- Generates Swift enums and structs
- Uses `Generated` prefix to avoid naming conflicts
- Handles Codable conformance and CodingKeys automatically
- Uses `SAOAIJSONValue` for complex inline objects

### Regenerating Models

**Before committing changes that might affect model structure, always regenerate models:**

```bash
# 1. Prune the OpenAPI spec (downloads latest)
python3 Scripts/prune-openapi-spec.py

# 2. Generate Swift models
python3 Scripts/generate-swift-models.py

# 3. Test the build
swift build

# 4. Run tests
swift test --parallel
```

### Generated Model Guidelines

Generated models follow these conventions:

- **Naming**: All generated types use the `Generated` prefix (e.g., `GeneratedEmbeddingRequest`)
- **Properties**: Use camelCase with appropriate CodingKeys for snake_case mapping
- **Types**: Use Swift-native types (String, Int, Bool, etc.) and `SAOAIJSONValue` for complex objects
- **Conformance**: Implement `Codable, Equatable` where possible
- **Documentation**: Include cleaned descriptions from the OpenAPI spec

Example generated model:
```swift
/// Generated model for AzureCreateEmbeddingRequest
public struct GeneratedEmbeddingRequest: Codable, Equatable {
    /// The number of dimensions the resulting output embeddings should have.
    public let dimensions: Int?
    
    /// Input text to embed, encoded as a string.
    public let input: String
    
    /// The model to use for the embedding request.
    public let model: String
    
    private enum CodingKeys: String, CodingKey {
        case dimensions
        case input  
        case model
    }
}
```

## Automated Workflows

### Nightly Regeneration (Coming Soon)

A GitHub Actions workflow will:
- Run nightly to check for OpenAPI specification changes
- Regenerate models if changes are detected
- Create pull requests with the updated models
- Report differences for review

## Manual Models vs Generated Models

### When to Use Manual Models

Use manual models for:
- High-level, user-facing APIs
- Complex business logic
- Custom Swift ergonomics
- Models that need special handling

### When to Use Generated Models

Use generated models for:
- Low-level DTOs (Data Transfer Objects)
- Raw API request/response structures
- Models that change frequently with the API
- Standard CRUD operations

### Bridging Manual and Generated Models

Use the adapter pattern to bridge between manual and generated models:

```swift
// Manual high-level model
public struct EmbeddingRequest {
    public let input: String
    public let model: String
    public let dimensions: Int?
    
    // Convert to generated model for API calls
    func toGenerated() -> GeneratedEmbeddingRequest {
        return GeneratedEmbeddingRequest(
            dimensions: dimensions,
            input: input,
            model: model
        )
    }
}
```

## Pull Request Guidelines

### For Regular Changes

1. Create a feature branch from `main`
2. Make your changes
3. Run tests: `swift test --parallel`
4. Build: `swift build`
5. Submit a pull request

### For Changes Affecting Models

If your changes might affect the API models (new endpoints, parameter changes, etc.):

1. **Regenerate models first**:
   ```bash
   python3 Scripts/prune-openapi-spec.py
   python3 Scripts/generate-swift-models.py
   ```

2. **Test thoroughly**:
   ```bash
   swift build
   swift test --parallel
   ```

3. **Include regenerated files in your commit**
4. **Mention model regeneration in your PR description**

### Commit Message Format

Use conventional commit format:

- `feat:` new features
- `fix:` bug fixes  
- `docs:` documentation changes
- `refactor:` code refactoring
- `test:` test additions/changes
- `chore:` maintenance tasks
- `codegen:` model regeneration

Examples:
- `feat: add embedding batch processing`
- `fix: handle empty responses correctly`
- `codegen: regenerate models for API v2024-01-15`

## Testing

### Test Categories

- **Unit Tests**: Test individual components
- **Integration Tests**: Test API interactions (when environment variables set)
- **Generated Model Tests**: Verify Codable conformance and serialization

### Running Tests

```bash
# All tests
swift test --parallel

# Without live API tests (faster)
unset AZURE_OPENAI_ENDPOINT
swift test --parallel

# With live API tests (requires environment variables)
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
export AZURE_OPENAI_API_KEY="your-api-key"
export AZURE_OPENAI_DEPLOYMENT="your-deployment"
swift test --parallel
```

## Architecture Principles  

1. **Zero Dependencies**: No external dependencies
2. **Forward Compatibility**: Unknown JSON fields must not break decoding
3. **Swift-Friendly APIs**: Leverage Swift's type system and async/await
4. **Selective Code Generation**: Generate only what's needed
5. **Strong Typing**: Prefer compile-time safety over runtime flexibility

## Getting Help

- **Issues**: Report bugs and request features via GitHub Issues
- **Discussions**: Ask questions in GitHub Discussions
- **Documentation**: Check the comprehensive docs in the `docs/` directory

## Code of Conduct

Please be respectful and inclusive in all interactions. This project follows standard open source community guidelines.

---

For questions about the code generation system or contributing guidelines, please open a GitHub Discussion or Issue.