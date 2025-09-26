//
//  GeneratedAdapters.swift
//  SwiftAzureOpenAI
//
//  Created by automated code generation.
//

import Foundation

// MARK: - Hybrid Model Adapter Protocol

/// Protocol for adapting between manual and generated models
public protocol ModelAdapter {
    associatedtype ManualModel
    associatedtype GeneratedModel
    
    static func toGenerated(_ manual: ManualModel) -> GeneratedModel
    static func fromGenerated(_ generated: GeneratedModel) -> ManualModel
}

// MARK: - Unknown Field Retention Strategy

/// Strategy for handling unknown fields during model conversion
public enum UnknownFieldStrategy {
    case ignore
    case preserve(in: String)  // Store in a specific property
    case error                 // Throw error on unknown fields
}

/// Container for preserving unknown JSON fields
public struct UnknownFieldsContainer: Codable, Equatable {
    public let fields: [String: SAOAIJSONValue]
    
    public init(fields: [String: SAOAIJSONValue] = [:]) {
        self.fields = fields
    }
    
    public var isEmpty: Bool {
        fields.isEmpty
    }
}

// MARK: - Base Adapter with Unknown Field Support

/// Base class for model adapters that support unknown field retention
open class BaseModelAdapter {
    
    /// Extract unknown fields from JSON data during decoding
    public static func extractUnknownFields(
        from data: Data,
        knownKeys: Set<String>
    ) throws -> UnknownFieldsContainer {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let unknownFields = json.compactMapValues { value -> SAOAIJSONValue? in
            return SAOAIJSONValue.from(any: value)
        }.filter { key, _ in
            !knownKeys.contains(key)
        }
        
        return UnknownFieldsContainer(fields: unknownFields)
    }
    
    /// Merge unknown fields back into JSON data during encoding
    public static func mergeUnknownFields(
        into data: Data,
        unknownFields: UnknownFieldsContainer
    ) throws -> Data {
        guard !unknownFields.isEmpty else { return data }
        
        var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        for (key, value) in unknownFields.fields {
            json[key] = value.toAny()
        }
        
        return try JSONSerialization.data(withJSONObject: json)
    }
}

// MARK: - Adapter Registry

/// Registry for managing model adapters
@MainActor
public final class ModelAdapterRegistry {
    private static var adapters: [String: Any] = [:]
    
    /// Register an adapter for a specific model type
    public static func register<A: ModelAdapter>(_ adapter: A.Type, for key: String) {
        adapters[key] = adapter
    }
    
    /// Get an adapter for a specific model type
    public static func adapter<A: ModelAdapter>(for key: String, as type: A.Type) -> A.Type? {
        return adapters[key] as? A.Type
    }
    
    /// Initialize default adapters
    public static func initializeDefaults() {
        // Future adapters will be registered here
    }
}

// MARK: - SAOAIJSONValue Extensions for Adapter Support

extension SAOAIJSONValue {
    /// Create SAOAIJSONValue from Any
    static func from(any value: Any) -> SAOAIJSONValue? {
        switch value {
        case let string as String:
            return .string(string)
        case let bool as Bool:
            return .bool(bool)
        case let number as NSNumber:
            return .number(number.doubleValue)
        case let array as [Any]:
            let converted = array.compactMap { SAOAIJSONValue.from(any: $0) }
            return .array(converted)
        case let dict as [String: Any]:
            let converted = dict.compactMapValues { SAOAIJSONValue.from(any: $0) }
            return .object(converted)
        case is NSNull:
            return .null
        default:
            return nil
        }
    }
    
    /// Convert SAOAIJSONValue to Any
    func toAny() -> Any {
        switch self {
        case .string(let string):
            return string
        case .number(let number):
            return number
        case .bool(let bool):
            return bool
        case .array(let array):
            return array.map { $0.toAny() }
        case .object(let object):
            return object.mapValues { $0.toAny() }
        case .null:
            return NSNull()
        }
    }
}