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

/// Minimal-overhead response validator optimized for performance
public final class OptimizedResponseValidator: ResponseValidator, @unchecked Sendable {
    
    // Shared error decoder to avoid repeated allocations
    private static let sharedErrorDecoder = JSONDecoder()
    
    public init() {}
    
    public func validate(_ response: HTTPURLResponse, data: Data) throws {
        let statusCode = response.statusCode
        
        // Fast path for successful responses (most common case)
        if (200..<300).contains(statusCode) { return }
        
        // Error handling - same as original but with shared decoder
        if let error = try? Self.sharedErrorDecoder.decode(ErrorResponse.self, from: data) {
            throw SAOAIError.apiError(error)
        }
        
        if let specific = SAOAIError.from(statusCode: statusCode) { 
            throw specific 
        }
        
        throw SAOAIError.serverError(statusCode: statusCode)
    }
}