import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Shared utility for extracting response metadata from HTTP headers
/// Eliminates code duplication between ResponseService and OptimizedResponseService
public struct MetadataExtractor: Sendable {
    
    public init() {}
    
    /// Extract metadata from HTTP response headers
    public func extractMetadata(from response: HTTPURLResponse) -> ResponseMetadata {
        let headers = response.normalizedHeaders
        
        // Extract request ID
        let requestId = headers["x-request-id"] ?? headers["x-ms-request-id"]
        
        // Extract processing time
        let processingTimeSeconds: TimeInterval? = {
            if let msString = headers["x-processing-ms"] ?? headers["openai-processing-ms"],
               let ms = Double(msString) {
                return ms / 1000.0
            }
            return nil
        }()
        
        // Extract rate limit info
        let remaining = headers["x-ratelimit-remaining-requests"]
            .flatMap(Int.init) ?? headers["x-ratelimit-remaining"].flatMap(Int.init)
        let limit = headers["x-ratelimit-limit-requests"]
            .flatMap(Int.init) ?? headers["x-ratelimit-limit"].flatMap(Int.init)
        
        let resetTime: Date? = {
            if let resetStr = headers["x-ratelimit-reset-requests"] ?? headers["x-ratelimit-reset"],
               let value = Double(resetStr) {
                // Heuristic: treat large numbers as epoch seconds, small as seconds-from-now
                return value > 1_000_000_000
                    ? Date(timeIntervalSince1970: value)
                    : Date().addingTimeInterval(value)
            }
            return nil
        }()
        
        let rateLimit = RateLimitInfo(remaining: remaining, resetTime: resetTime, limit: limit)
        
        return ResponseMetadata(
            requestId: requestId,
            timestamp: Date(),
            processingTime: processingTimeSeconds,
            rateLimit: rateLimit
        )
    }
}
