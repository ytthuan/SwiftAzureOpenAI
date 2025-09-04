import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// High-performance response parsing service optimized for non-streaming responses
/// Uses a streamlined parsing approach with minimal overhead
public final class OptimizedResponseParsingService: ResponseParser, @unchecked Sendable {
    
    // MARK: - Shared Decoder Instance
    
    private static let sharedDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // Use the most efficient settings for JSON parsing
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
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
        
        // Fastest path: successful responses
        if (200..<300).contains(statusCode) { return }
        
        // Fast error handling with minimal allocations
        if data.count > 10 {  // Only parse if there's meaningful content
            if let error = try? Self.sharedErrorDecoder.decode(ErrorResponse.self, from: data) {
                throw SAOAIError.apiError(error)
            }
        }
        
        // Pre-computed error handling
        if let specific = SAOAIError.from(statusCode: statusCode) { 
            throw specific 
        }
        
        throw SAOAIError.serverError(statusCode: statusCode)
    }
}