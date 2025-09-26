# SwiftAzureOpenAI Code Generation Scripts

This directory contains Python scripts for automated Swift model generation from Azure OpenAPI specifications.

## Quick Start

```bash
# Generate Swift models from latest Azure OpenAPI spec
python3 Scripts/prune-openapi-spec.py
python3 Scripts/generate-swift-models.py

# Verify generated code
swift build && swift test --parallel
```

## Scripts

### 🔄 `prune-openapi-spec.py`

Downloads and filters the Azure OpenAPI specification to include only relevant endpoints.

**What it does**:
- Downloads from: `https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/ai/data-plane/OpenAI.v1/azure-v1-v1-generated.json`
- Keeps only: `/responses`, `/files`, `/embeddings` endpoints
- Reduces: 399 schemas → 36 schemas (91% reduction)
- Analyzes: Dependencies recursively to ensure completeness

**Output**:
- `Specs/full-openapi.json` - Complete downloaded spec
- `Specs/pruned-openapi.json` - Filtered spec for SwiftAzureOpenAI

**Example output**:
```
Loaded OpenAPI spec with 39 paths
Identified 7 paths to keep:
  /embeddings
  /files
  /files/{file_id}
  /files/{file_id}/content
  /responses
  /responses/{response_id}
  /responses/{response_id}/input_items
Found 13 directly referenced schemas
Expanded to 36 total schemas (including dependencies)

Pruning complete!
Original: 39 paths, 399 schemas
Pruned:   7 paths, 36 schemas
```

### 🏗️ `generate-swift-models.py`

Generates Swift models (structs and enums) from the pruned OpenAPI specification.

**What it does**:
- Reads: `Specs/pruned-openapi.json`
- Generates: Swift structs and enums with proper typing
- Handles: Complex schemas, arrays, optionals, and `anyOf` patterns
- Creates: Codable conformance with appropriate CodingKeys

**Output**:
- `Sources/SwiftAzureOpenAI/Generated/GeneratedModels.swift`

**Example output**:
```
Loaded pruned OpenAPI spec from Specs/pruned-openapi.json
Generated models written to: Sources/SwiftAzureOpenAI/Generated/GeneratedModels.swift
Generated 8 enums and 24 structs
Swift model generation complete!
```

## Generated Swift Code Examples

### Struct Example
```swift
/// Generated model for AzureCreateEmbeddingRequest
public struct GeneratedEmbeddingRequest: Codable, Equatable {
    /// The number of dimensions the resulting output embeddings should have
    public let dimensions: Int?
    
    /// Input text to embed, encoded as a string
    public let input: String
    
    /// The model to use for the embedding request
    public let model: String
    
    private enum CodingKeys: String, CodingKey {
        case dimensions
        case input
        case model
    }
}
```

### Enum Example
```swift
/// Generated enum for OpenAI.ItemContentType
public enum GeneratedItemContentType: String, Codable, CaseIterable {
    case input_text = "input_text"
    case input_audio = "input_audio"
    case input_image = "input_image"
    case output_text = "output_text"
    case refusal = "refusal"
}
```

## Requirements

- **Python**: 3.6 or later
- **Swift**: 6.0 or later
- **Internet**: For downloading OpenAPI specifications

## Integration

### Manual Usage
Run scripts manually when you need to update models:

```bash
# Update models with latest API changes
./Scripts/update-models.sh
```

### Automated Usage  
Scripts are integrated into GitHub Actions for nightly updates:

```yaml
# .github/workflows/nightly-codegen.yml
- name: Update OpenAPI spec and regenerate models
  run: |
    python3 Scripts/prune-openapi-spec.py
    python3 Scripts/generate-swift-models.py
```

## Benefits

| Benefit | Impact |
|---------|--------|
| **Automatic Sync** | Always up-to-date with Azure OpenAI API |
| **Size Reduction** | 91% fewer schemas (399 → 36) |
| **Type Safety** | Full Swift compile-time validation |
| **Zero Maintenance** | No manual model updates required |
| **Swift Ergonomics** | Native Swift types and conventions |

## Troubleshooting

### Script Fails
```bash
# Check Python version
python3 --version  # Should be 3.6+

# Check internet connectivity
curl -I https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/ai/data-plane/OpenAI.v1/azure-v1-v1-generated.json
```

### Generated Code Doesn't Compile
```bash
# Check Swift version
swift --version  # Should be 6.0+

# Clean and rebuild
swift package clean
swift build
```

### Need Help?
- 📖 **Full Documentation**: [`docs/CODE_GENERATION.md`](../docs/CODE_GENERATION.md)
- 🤝 **Contributing**: [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/ytthuan/SwiftAzureOpenAI/discussions)
- 🐛 **Issues**: [GitHub Issues](https://github.com/ytthuan/SwiftAzureOpenAI/issues)

## Development

### Script Architecture

```
prune-openapi-spec.py
├── collect_referenced_schemas()    # Find all schema dependencies
├── expand_schema_dependencies()    # Recursive dependency resolution
└── prune_openapi_spec()           # Main pruning logic

generate-swift-models.py  
├── SwiftModelGenerator
│   ├── swift_type_from_schema()   # OpenAPI → Swift type mapping
│   ├── generate_enum()            # Enum generation
│   ├── generate_struct()          # Struct generation
│   └── swift_property_name()      # camelCase conversion
└── main()                         # Script entry point
```

### Extending the Scripts

To add support for new OpenAPI features:

1. **Update Type Mapping**: Modify `swift_type_from_schema()` in `generate-swift-models.py`
2. **Add Schema Patterns**: Update schema collection logic in `prune-openapi-spec.py`  
3. **Test Generation**: Run scripts and verify Swift compilation
4. **Update Tests**: Add test cases for new model types

### Contributing

1. Fork the repository
2. Create a feature branch
3. Modify scripts in `Scripts/` directory
4. Test with `python3 Scripts/script-name.py`
5. Verify Swift compilation with `swift build`
6. Submit pull request

---

These scripts power SwiftAzureOpenAI's automated model generation system, ensuring the Swift SDK stays perfectly synchronized with Azure OpenAI API updates while maintaining excellent Swift ergonomics and type safety.