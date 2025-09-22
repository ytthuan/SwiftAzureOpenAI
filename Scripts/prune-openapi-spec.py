#!/usr/bin/env python3
"""
OpenAPI Spec Pruning Script for SwiftAzureOpenAI

This script prunes the Azure OpenAI API specification to include only the endpoints
required by SwiftAzureOpenAI: /responses, /files, and /embeddings.

As outlined in the roadmap, this approach:
1. Keeps only required endpoints for the focused scope
2. Removes extraneous schemas and security definitions 
3. Avoids overwriting hand-written high-level API
4. Enables selective code generation for DTOs only

Usage:
    python Scripts/prune-openapi-spec.py

Input: Specs/azure-openai-full.json
Output: Specs/pruned-openapi.json
"""

import json
import sys
from pathlib import Path
from typing import Dict, Any, Set


def load_spec(input_path: Path) -> Dict[str, Any]:
    """Load the OpenAPI specification from file."""
    try:
        with open(input_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_path} not found.")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {input_path}: {e}")
        sys.exit(1)


def get_required_endpoints() -> Set[str]:
    """Return the set of endpoint paths to keep in pruned spec."""
    return {
        "/responses",
        "/embeddings", 
        "/files",
        "/files/{file_id}"
    }


def collect_referenced_schemas(spec: Dict[str, Any], paths_to_keep: Set[str]) -> Set[str]:
    """
    Collect all schema references that are used by the kept endpoints.
    This ensures we include all required schemas in the pruned spec.
    """
    referenced_schemas = set()
    
    def extract_refs_from_obj(obj: Any) -> None:
        """Recursively extract $ref values from an object."""
        if isinstance(obj, dict):
            if "$ref" in obj:
                # Extract schema name from reference like "#/components/schemas/ResponsesRequest"
                ref_path = obj["$ref"]
                if ref_path.startswith("#/components/schemas/"):
                    schema_name = ref_path.replace("#/components/schemas/", "")
                    referenced_schemas.add(schema_name)
            else:
                for value in obj.values():
                    extract_refs_from_obj(value)
        elif isinstance(obj, list):
            for item in obj:
                extract_refs_from_obj(item)
    
    # Extract refs from kept paths
    paths = spec.get("paths", {})
    for path, path_obj in paths.items():
        if path in paths_to_keep:
            extract_refs_from_obj(path_obj)
    
    # Recursively collect schemas referenced by other schemas
    schemas = spec.get("components", {}).get("schemas", {})
    schemas_to_process = list(referenced_schemas)
    
    while schemas_to_process:
        schema_name = schemas_to_process.pop()
        if schema_name in schemas:
            schema_obj = schemas[schema_name]
            old_count = len(referenced_schemas)
            extract_refs_from_obj(schema_obj)
            # Add newly found schemas to processing queue
            new_schemas = referenced_schemas - set(schemas_to_process) - {schema_name}
            if len(referenced_schemas) > old_count:
                schemas_to_process.extend(list(new_schemas))
    
    return referenced_schemas


def prune_spec(spec: Dict[str, Any]) -> Dict[str, Any]:
    """
    Prune the OpenAPI specification to keep only required endpoints and schemas.
    
    Roadmap constraints:
    - Only keep /responses, /files, /embeddings endpoints
    - Remove extraneous schemas & security definitions  
    - Preserve core OpenAPI structure for code generation
    """
    print("🔧 Pruning OpenAPI specification...")
    
    # Keep basic OpenAPI structure
    pruned = {
        "openapi": spec.get("openapi", "3.0.1"),
        "info": spec.get("info", {}),
        "servers": spec.get("servers", [])
    }
    
    # Filter paths to keep only required endpoints
    required_endpoints = get_required_endpoints()
    original_paths = spec.get("paths", {})
    
    pruned_paths = {}
    for path, path_obj in original_paths.items():
        if path in required_endpoints:
            pruned_paths[path] = path_obj
            print(f"✅ Keeping endpoint: {path}")
        else:
            print(f"❌ Removing endpoint: {path}")
    
    pruned["paths"] = pruned_paths
    
    # Collect and keep only referenced schemas
    referenced_schemas = collect_referenced_schemas(spec, required_endpoints)
    original_schemas = spec.get("components", {}).get("schemas", {})
    
    pruned_schemas = {}
    for schema_name, schema_obj in original_schemas.items():
        if schema_name in referenced_schemas:
            pruned_schemas[schema_name] = schema_obj
            print(f"✅ Keeping schema: {schema_name}")
        else:
            print(f"❌ Removing schema: {schema_name}")
    
    # Keep essential components but prune security schemes
    pruned["components"] = {
        "schemas": pruned_schemas
    }
    
    # Keep minimal security for Azure OpenAI (API key authentication)
    original_security_schemes = spec.get("components", {}).get("securitySchemes", {})
    if "ApiKeyAuth" in original_security_schemes:
        pruned["components"]["securitySchemes"] = {
            "ApiKeyAuth": original_security_schemes["ApiKeyAuth"]
        }
        pruned["security"] = [{"ApiKeyAuth": []}]
        print("✅ Keeping ApiKeyAuth security scheme")
    
    return pruned


def save_spec(spec: Dict[str, Any], output_path: Path) -> None:
    """Save the pruned specification to file."""
    try:
        with open(output_path, 'w') as f:
            json.dump(spec, f, indent=2, sort_keys=True)
        print(f"✅ Pruned specification saved to: {output_path}")
    except Exception as e:
        print(f"Error: Failed to save pruned spec: {e}")
        sys.exit(1)


def print_summary(original_spec: Dict[str, Any], pruned_spec: Dict[str, Any]) -> None:
    """Print summary of pruning operation."""
    original_paths = len(original_spec.get("paths", {}))
    pruned_paths = len(pruned_spec.get("paths", {}))
    
    original_schemas = len(original_spec.get("components", {}).get("schemas", {}))
    pruned_schemas = len(pruned_spec.get("components", {}).get("schemas", {}))
    
    print(f"\n📊 Pruning Summary:")
    print(f"   Endpoints: {original_paths} → {pruned_paths} ({pruned_paths/original_paths*100:.1f}% kept)")
    print(f"   Schemas: {original_schemas} → {pruned_schemas} ({pruned_schemas/original_schemas*100:.1f}% kept)")
    print(f"\n🎯 Focus: Responses API, Embeddings API, and Files API only")
    print(f"🚀 Ready for selective code generation in Sources/SwiftAzureOpenAI/Generated/")


def main():
    """Main entry point for the pruning script."""
    print("🔍 SwiftAzureOpenAI OpenAPI Spec Pruning Tool")
    print("=" * 50)
    
    # Define paths
    script_dir = Path(__file__).parent
    root_dir = script_dir.parent
    input_path = root_dir / "Specs" / "azure-openai-full.json"
    output_path = root_dir / "Specs" / "pruned-openapi.json"
    
    print(f"📖 Input: {input_path}")
    print(f"📝 Output: {output_path}")
    print()
    
    # Load, prune, and save specification
    original_spec = load_spec(input_path)
    pruned_spec = prune_spec(original_spec)
    save_spec(pruned_spec, output_path)
    
    # Print summary
    print_summary(original_spec, pruned_spec)
    
    print(f"\n✨ Pruning complete! Next steps:")
    print(f"   1. Review {output_path}")
    print(f"   2. Generate Swift models using your preferred code generator")
    print(f"   3. Place generated models in Sources/SwiftAzureOpenAI/Generated/")


if __name__ == "__main__":
    main()