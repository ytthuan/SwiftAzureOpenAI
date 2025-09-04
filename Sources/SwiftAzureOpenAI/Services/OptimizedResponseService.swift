import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// High-performance response service optimized for non-streaming responses
/// Eliminates unnecessary overhead while maintaining functionality
public final class OptimizedResponseService: ResponseServiceProtocol, @unchecked Sendable {
    
    private let parser: ResponseParser
    private let validator: ResponseValidator
    private let cache: ResponseCache?
    
    public init(
        parser: ResponseParser = OptimizedResponseParsingService(),
        validator: ResponseValidator = OptimizedResponseValidator(),
        cache: ResponseCache? = nil
    ) {
        self.parser = parser
        self.validator = validator
        self.cache = cache
    }
    
    public func processResponse<T: Codable>(_ data: Data, response: HTTPURLResponse, type: T.Type) async throws -> APIResponse<T> {
        // Check cache first
        if let cached: APIResponse<T> = await cache?.retrieve(for: data, as: T.self) {
            return cached
        }
        
        // Validate response
        try validator.validate(response, data: data)
        
        // Parse data
        let parsed = try await parser.parse(data, as: type)
        
        // Streamlined metadata extraction
        let metadata = extractMetadataStreamlined(from: response)
        
        // Create response
        let apiResponse = APIResponse(
            data: parsed,
            metadata: metadata,
            statusCode: response.statusCode,
            headers: response.normalizedHeaders
        )
        
        // Store in cache
        await cache?.store(response: apiResponse, for: data)
        
        return apiResponse
    }
    
    public func validateResponse(_ response: HTTPURLResponse) throws {
        if let specific = SAOAIError.from(statusCode: response.statusCode) { 
            throw specific 
        }
    }
    
    public func extractMetadata(from response: HTTPURLResponse) -> ResponseMetadata {
        return extractMetadataStreamlined(from: response)
    }
    
    /// Streamlined metadata extraction with minimal overhead
    private func extractMetadataStreamlined(from response: HTTPURLResponse) -> ResponseMetadata {
        let headers = response.normalizedHeaders
        
        // Simple, direct header lookups
        let requestId = headers["x-request-id"] ?? headers["x-ms-request-id"]
        
        let processingTimeSeconds: TimeInterval? = {
            if let msString = headers["openai-processing-ms"] ?? headers["x-processing-ms"],
               let ms = Double(msString) {
                return ms / 1000.0
            }
            return nil
        }()
        
        // Simple rate limit extraction
        let remaining = headers["x-ratelimit-remaining-requests"]
            .flatMap(Int.init) ?? headers["x-ratelimit-remaining"].flatMap(Int.init)
        let limit = headers["x-ratelimit-limit-requests"]
            .flatMap(Int.init) ?? headers["x-ratelimit-limit"].flatMap(Int.init)
        
        let resetTime: Date? = {
            if let resetStr = headers["x-ratelimit-reset-requests"] ?? headers["x-ratelimit-reset"],
               let value = Double(resetStr) {
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