#!/usr/bin/env python3
"""
Swift Model Generation Script for SwiftAzureOpenAI

This script generates Swift models from the pruned OpenAPI specification.
Generated models are placed in Sources/SwiftAzureOpenAI/Generated/

Usage:
    python3 Scripts/generate-swift-models.py
"""

import json
import os
import re
from typing import Dict, List, Any, Optional

class SwiftModelGenerator:
    def __init__(self, spec: Dict[str, Any]):
        self.spec = spec
        self.generated_models = []
        
    def swift_type_from_schema(self, schema: Dict[str, Any], schema_name: Optional[str] = None) -> str:
        """Convert OpenAPI schema to Swift type."""
        if '$ref' in schema:
            ref = schema['$ref']
            if ref.startswith('#/components/schemas/'):
                ref_name = ref.replace('#/components/schemas/', '')
                # Special handling for anyOf schemas - just use String
                if ref_name in self.spec.get('components', {}).get('schemas', {}):
                    ref_schema = self.spec['components']['schemas'][ref_name]
                    if 'anyOf' in ref_schema:
                        return 'String'
                return self.swift_class_name(ref_name)
        
        # Handle anyOf schemas directly
        if 'anyOf' in schema:
            # For anyOf schemas that typically mix string and enum, use String
            return 'String'
        
        schema_type = schema.get('type', 'string')
        schema_format = schema.get('format')
        
        if schema_type == 'string':
            if 'enum' in schema:
                return 'String'  # We'll handle enums separately
            elif schema_format == 'date-time':
                return 'Date'
            elif schema_format == 'uri':
                return 'URL'
            else:
                return 'String'
        elif schema_type == 'integer':
            if schema_format == 'int64':
                return 'Int64'
            else:
                return 'Int'
        elif schema_type == 'number':
            if schema_format == 'float':
                return 'Float'
            else:
                return 'Double'
        elif schema_type == 'boolean':
            return 'Bool'
        elif schema_type == 'array':
            items_schema = schema.get('items', {})
            item_type = self.swift_type_from_schema(items_schema)
            return f'[{item_type}]'
        elif schema_type == 'object':
            if 'properties' in schema:
                # For inline objects, use SAOAIJSONValue which is Codable and Equatable
                return 'SAOAIJSONValue'
            else:
                return 'SAOAIJSONValue'
        
        return 'Any'  # Fallback
    
    def swift_class_name(self, name: str) -> str:
        """Convert OpenAPI schema name to Swift class name."""
        # Remove OpenAI. prefix and make Swift-friendly
        name = name.replace('OpenAI.', '')
        name = name.replace('Azure', '')
        
        # Handle special problematic names first
        if name == 'expires_after':
            return 'GeneratedExpiresAfter'
        elif name == 'error':
            return 'GeneratedError'
        
        # Convert names to PascalCase
        if '.' in name:
            parts = name.split('.')
            name = ''.join(part.capitalize() for part in parts)
        
        # Convert snake_case to PascalCase
        if '_' in name:
            parts = name.split('_')
            name = ''.join(part.capitalize() for part in parts)
        
        # Ensure first letter is capitalized
        if name and name[0].islower():
            name = name[0].upper() + name[1:]
        
        # Handle special cases
        name = name.replace('CreateEmbeddingRequest', 'EmbeddingRequest')
        name = name.replace('CreateEmbeddingResponse', 'EmbeddingResponse')
        name = name.replace('CreateFileRequest', 'FileRequest')
        name = name.replace('CreateResponse', 'ResponseRequest') 
        
        # Ensure it starts with 'Generated'
        if not name.startswith('Generated'):
            name = f'Generated{name}'
            
        return name
    
    def swift_property_name(self, name: str) -> str:
        """Convert property name to Swift camelCase."""
        # Convert snake_case to camelCase
        components = name.split('_')
        if len(components) > 1:
            return components[0] + ''.join(word.capitalize() for word in components[1:])
        return name
    
    def generate_enum(self, name: str, schema: Dict[str, Any]) -> str:
        """Generate Swift enum from OpenAPI enum schema."""
        swift_name = self.swift_class_name(name)
        enum_values = schema.get('enum', [])
        
        lines = [
            f'/// Generated enum for {name}',
            f'public enum {swift_name}: String, Codable, CaseIterable {{',
        ]
        
        for value in enum_values:
            # Create a valid Swift identifier from the enum value
            case_name = value.lower()
            # Replace dots, dashes, and other special characters
            case_name = case_name.replace('.', '_').replace('-', '_').replace(' ', '_')
            # Remove any other non-alphanumeric characters except underscores
            case_name = ''.join(c if c.isalnum() or c == '_' else '_' for c in case_name)
            # Ensure it doesn't start with a number
            if case_name and case_name[0].isdigit():
                case_name = f'case_{case_name}'
            # Handle empty case names
            if not case_name:
                case_name = 'unknown'
            
            lines.append(f'    case {case_name} = "{value}"')
        
        lines.extend([
            '}',
            ''
        ])
        
        return '\n'.join(lines)
    
    def clean_description(self, description: str) -> str:
        """Clean up description text for Swift comments."""
        if not description:
            return ""
        
        # Remove markdown links [text](url) -> text
        import re
        description = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', description)
        
        # Remove standalone markdown links that start lines
        description = re.sub(r'^- `[^`]+`:', '', description, flags=re.MULTILINE)
        
        # Clean up extra whitespace and newlines
        description = ' '.join(description.split())
        
        # Truncate very long descriptions
        if len(description) > 200:
            description = description[:197] + "..."
        
        return description
    
    def generate_struct(self, name: str, schema: Dict[str, Any]) -> str:
        """Generate Swift struct from OpenAPI object schema."""
        swift_name = self.swift_class_name(name)
        properties = schema.get('properties', {})
        required = set(schema.get('required', []))
        
        lines = [
            f'/// Generated model for {name}',
            f'public struct {swift_name}: Codable, Equatable {{',
        ]
        
        # Generate properties
        for prop_name, prop_schema in properties.items():
            swift_prop_name = self.swift_property_name(prop_name)
            swift_type = self.swift_type_from_schema(prop_schema, prop_name)
            
            # Make optional if not required
            if prop_name not in required:
                swift_type = f'{swift_type}?'
            
            description = self.clean_description(prop_schema.get('description', ''))
            if description:
                lines.append(f'    /// {description}')
            lines.append(f'    public let {swift_prop_name}: {swift_type}')
            lines.append('')
        
    def generate_struct(self, name: str, schema: Dict[str, Any]) -> str:
        """Generate Swift struct from OpenAPI object schema."""
        swift_name = self.swift_class_name(name)
        properties = schema.get('properties', {})
        required = set(schema.get('required', []))
        
        # Check if any properties use non-Equatable types (SAOAIJSONValue is Equatable)
        has_non_equatable = any(
            '[String: Any]' in self.swift_type_from_schema(prop_schema, prop_name)
            for prop_name, prop_schema in properties.items()
        )
        
        # Use Codable only if we have non-Equatable types
        conformance = 'Codable' if has_non_equatable else 'Codable, Equatable'
        
        lines = [
            f'/// Generated model for {name}',
            f'public struct {swift_name}: {conformance} {{',
        ]
        
        # Generate properties
        for prop_name, prop_schema in properties.items():
            swift_prop_name = self.swift_property_name(prop_name)
            swift_type = self.swift_type_from_schema(prop_schema, prop_name)
            
            # Make optional if not required
            if prop_name not in required:
                swift_type = f'{swift_type}?'
            
            description = self.clean_description(prop_schema.get('description', ''))
            if description:
                lines.append(f'    /// {description}')
            lines.append(f'    public let {swift_prop_name}: {swift_type}')
            lines.append('')
        
        # Generate CodingKeys if needed
        coding_keys_needed = any(
            self.swift_property_name(prop_name) != prop_name 
            for prop_name in properties.keys()
        )
        
        if coding_keys_needed:
            lines.append('    private enum CodingKeys: String, CodingKey {')
            for prop_name in properties.keys():
                swift_prop_name = self.swift_property_name(prop_name)
                if swift_prop_name != prop_name:
                    lines.append(f'        case {swift_prop_name} = "{prop_name}"')
                else:
                    lines.append(f'        case {swift_prop_name}')
            lines.append('    }')
            lines.append('')
        
        lines.extend([
            '}',
            ''
        ])
        
        return '\n'.join(lines)
    
    def generate_models(self) -> str:
        """Generate all Swift models from the OpenAPI spec."""
        schemas = self.spec.get('components', {}).get('schemas', {})
        
        lines = [
            '// Generated Swift Models from OpenAPI Specification',
            '// DO NOT EDIT: This file is automatically generated',
            '',
            'import Foundation',
            '',
        ]
        
        # Generate enums first
        for name, schema in schemas.items():
            if schema.get('type') == 'string' and 'enum' in schema:
                lines.append(self.generate_enum(name, schema))
            elif 'anyOf' in schema:
                # For anyOf schemas that mix string and enum, just treat as String for simplicity
                # In a more complete implementation, we might generate a proper enum
                continue
        
        # Generate structs
        for name, schema in schemas.items():
            if schema.get('type') == 'object' or 'properties' in schema:
                lines.append(self.generate_struct(name, schema))
        
        return '\n'.join(lines)
    
    def write_generated_models(self):
        """Write generated models to the Generated directory."""
        output_dir = 'Sources/SwiftAzureOpenAI/Generated'
        os.makedirs(output_dir, exist_ok=True)
        
        models_content = self.generate_models()
        
        output_file = os.path.join(output_dir, 'GeneratedModels.swift')
        with open(output_file, 'w') as f:
            f.write(models_content)
        
        print(f"Generated models written to: {output_file}")
        
        # Count generated items
        enum_count = models_content.count('public enum ')
        struct_count = models_content.count('public struct ')
        
        print(f"Generated {enum_count} enums and {struct_count} structs")

def main():
    """Main function to generate Swift models."""
    spec_file = 'Specs/pruned-openapi.json'
    
    try:
        with open(spec_file, 'r') as f:
            spec = json.load(f)
        
        print(f"Loaded pruned OpenAPI spec from {spec_file}")
        
        generator = SwiftModelGenerator(spec)
        generator.write_generated_models()
        
        print("Swift model generation complete!")
        
    except FileNotFoundError:
        print(f"Error: Could not find spec file: {spec_file}")
        print("Please run the pruning script first: python3 Scripts/prune-openapi-spec.py")
        return 1
    except Exception as e:
        print(f"Error during generation: {e}")
        return 1
    
    return 0

if __name__ == '__main__':
    exit(main())