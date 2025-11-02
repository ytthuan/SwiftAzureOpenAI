import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// High-performance response parsing service optimized for non-streaming responses
/// Uses a streamlined parsing approach with minimal overhead
public final class OptimizedResponseParsingService: ResponseParser, @unchecked Sendable {
    
    // MARK: - Shared Decoder Instance
    
    private static let sharedDecoder = JSONDecoder()
    
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder? = nil) {
        // Use shared decoder by default to avoid allocation overhead
        self.decoder = decoder ?? Self.sharedDecoder
    }
    
    // MARK: - High-Performance Parsing Methods
    
    public func parse<T: Codable>(_ data: Data, as type: T.Type) async throws -> T {
        // Streamlined parsing with minimal overhead
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw SAOAIError.decodingError(error)
        }
    }
}

/// Minimal-overhead response validator optimized for performance - now delegates to shared implementation
public final class OptimizedResponseValidator: ResponseValidator, @unchecked Sendable {
    
    private let sharedValidator: SharedResponseValidator
    
    public init() {
        self.sharedValidator = SharedResponseValidator()
    }
    
    public func validate(_ response: HTTPURLResponse, data: Data) throws {
        try sharedValidator.validate(response, data: data)
    }
}