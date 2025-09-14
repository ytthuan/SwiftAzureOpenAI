import Foundation

/// Shared JSON encoder instance to reduce allocations and improve performance
/// Thread-safe singleton that provides optimized encoding for all API requests
public final class SharedJSONEncoder: @unchecked Sendable {
    public static let shared = SharedJSONEncoder()
    
    private let encoder: JSONEncoder
    
    private init() {
        encoder = JSONEncoder()
        // Optimize for API usage - no pretty printing needed
        encoder.outputFormatting = []
        encoder.dateEncodingStrategy = .iso8601
    }
    
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        return try encoder.encode(value)
    }
}

/// Cached JSON decoder for response parsing performance
public final class CachedJSONDecoder: @unchecked Sendable {
    public static let shared = CachedJSONDecoder()
    
    private let decoder: JSONDecoder
    
    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        return try decoder.decode(type, from: data)
    }
}