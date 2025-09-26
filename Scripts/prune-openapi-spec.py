#!/usr/bin/env python3
"""
OpenAPI Spec Pruning Script for SwiftAzureOpenAI

This script prunes the full Azure OpenAPI spec to only include the endpoints
and schemas needed for SwiftAzureOpenAI library:
- /responses and related endpoints
- /files and related endpoints  
- /embeddings endpoint

Usage:
    python3 Scripts/prune-openapi-spec.py
"""

import json
import sys
from typing import Dict, Set, Any

def collect_referenced_schemas(spec: Dict[str, Any], paths_to_keep: Set[str]) -> Set[str]:
    """Collect all schema references used by the endpoints we want to keep."""
    referenced_schemas = set()
    
    def extract_refs_from_object(obj):
        """Recursively extract $ref values from an object."""
        if isinstance(obj, dict):
            for key, value in obj.items():
                if key == '$ref' and isinstance(value, str):
                    # Extract schema name from reference like "#/components/schemas/ResponseObject"
                    if value.startswith('#/components/schemas/'):
                        schema_name = value.replace('#/components/schemas/', '')
                        referenced_schemas.add(schema_name)
                else:
                    extract_refs_from_object(value)
        elif isinstance(obj, list):
            for item in obj:
                extract_refs_from_object(item)
    
    # Extract references from all paths we want to keep
    for path in paths_to_keep:
        if path in spec.get('paths', {}):
            extract_refs_from_object(spec['paths'][path])
    
    return referenced_schemas

def expand_schema_dependencies(spec: Dict[str, Any], initial_schemas: Set[str]) -> Set[str]:
    """Expand schema set to include all dependencies (schemas referenced by other schemas)."""
    all_schemas = initial_schemas.copy()
    schemas_component = spec.get('components', {}).get('schemas', {})
    
    # Keep expanding until no new schemas are found
    changed = True
    while changed:
        changed = False
        current_size = len(all_schemas)
        
        # Check each schema we already have for additional references
        for schema_name in list(all_schemas):
            if schema_name in schemas_component:
                schema_def = schemas_component[schema_name]
                # Extract refs from this schema definition
                refs = set()
                
                def extract_refs(obj):
                    if isinstance(obj, dict):
                        for key, value in obj.items():
                            if key == '$ref' and isinstance(value, str):
                                if value.startswith('#/components/schemas/'):
                                    ref_name = value.replace('#/components/schemas/', '')
                                    refs.add(ref_name)
                            else:
                                extract_refs(value)
                    elif isinstance(obj, list):
                        for item in obj:
                            extract_refs(item)
                
                extract_refs(schema_def)
                all_schemas.update(refs)
        
        if len(all_schemas) > current_size:
            changed = True
    
    return all_schemas

def prune_openapi_spec():
    """Main function to prune the OpenAPI specification."""
    input_file = 'Specs/full-openapi.json'
    output_file = 'Specs/pruned-openapi.json'
    
    try:
        # Load the full specification
        with open(input_file, 'r') as f:
            spec = json.load(f)
            
        print(f"Loaded OpenAPI spec with {len(spec.get('paths', {}))} paths")
        
        # Define the paths we want to keep (as per roadmap requirements)
        paths_to_keep = set()
        for path in spec.get('paths', {}):
            if (path.startswith('/responses') or 
                path.startswith('/files') or 
                path.startswith('/embeddings')):
                paths_to_keep.add(path)
        
        print(f"Identified {len(paths_to_keep)} paths to keep:")
        for path in sorted(paths_to_keep):
            print(f"  {path}")
        
        # Collect referenced schemas
        referenced_schemas = collect_referenced_schemas(spec, paths_to_keep)
        print(f"Found {len(referenced_schemas)} directly referenced schemas")
        
        # Expand to include all schema dependencies
        all_schemas = expand_schema_dependencies(spec, referenced_schemas)
        print(f"Expanded to {len(all_schemas)} total schemas (including dependencies)")
        
        # Create pruned specification
        pruned_spec = {
            'openapi': spec['openapi'],
            'info': {
                **spec['info'],
                'title': 'Azure OpenAI API (Pruned for SwiftAzureOpenAI)',
                'description': 'Pruned version containing only responses, files, and embeddings endpoints'
            },
            'servers': spec.get('servers', []),
            'security': spec.get('security', []),
            'paths': {},
            'components': {
                'schemas': {},
                'securitySchemes': spec.get('components', {}).get('securitySchemes', {})
            }
        }
        
        # Add kept paths
        for path in paths_to_keep:
            if path in spec['paths']:
                pruned_spec['paths'][path] = spec['paths'][path]
        
        # Add kept schemas
        original_schemas = spec.get('components', {}).get('schemas', {})
        for schema_name in all_schemas:
            if schema_name in original_schemas:
                pruned_spec['components']['schemas'][schema_name] = original_schemas[schema_name]
        
        # Write pruned specification
        with open(output_file, 'w') as f:
            json.dump(pruned_spec, f, indent=2, sort_keys=True)
        
        print(f"\nPruning complete!")
        print(f"Original: {len(spec.get('paths', {}))} paths, {len(spec.get('components', {}).get('schemas', {}))} schemas")
        print(f"Pruned:   {len(pruned_spec['paths'])} paths, {len(pruned_spec['components']['schemas'])} schemas")
        print(f"Output written to: {output_file}")
        
        # Print summary of kept paths by category
        responses_paths = [p for p in paths_to_keep if p.startswith('/responses')]
        files_paths = [p for p in paths_to_keep if p.startswith('/files')]
        embeddings_paths = [p for p in paths_to_keep if p.startswith('/embeddings')]
        
        print("\nKept paths by category:")
        print(f"  Responses:  {len(responses_paths)} paths")
        print(f"  Files:      {len(files_paths)} paths")
        print(f"  Embeddings: {len(embeddings_paths)} paths")
        
    except FileNotFoundError:
        print(f"Error: Could not find input file: {input_file}")
        print("Please run this script from the repository root directory.")
        sys.exit(1)
    except Exception as e:
        print(f"Error during pruning: {e}")
        sys.exit(1)

if __name__ == '__main__':
    prune_openapi_spec()