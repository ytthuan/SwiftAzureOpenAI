import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Shared response validator eliminating duplication between DefaultResponseValidator and OptimizedResponseValidator
public final class SharedResponseValidator: ResponseValidator, @unchecked Sendable {
    
    // Shared error decoder to avoid repeated allocations
    private static let sharedErrorDecoder = JSONDecoder()
    
    public init() {}
    
    public func validate(_ response: HTTPURLResponse, data: Data) throws {
        let statusCode = response.statusCode
        
        // Fast path for successful responses (most common case)
        if (200..<300).contains(statusCode) { return }
        
        // Try to decode structured error first
        if let error = try? Self.sharedErrorDecoder.decode(ErrorResponse.self, from: data) {
            throw SAOAIError.apiError(error)
        }
        
        // Fall back to known status code errors
        if let specific = SAOAIError.from(statusCode: statusCode) {
            throw specific
        }
        
        // Finally, generic server error
        throw SAOAIError.serverError(statusCode: statusCode)
    }
}
