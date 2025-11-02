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
    private let metadataExtractor: MetadataExtractor
    
    public init(
        parser: ResponseParser = OptimizedResponseParsingService(),
        validator: ResponseValidator = OptimizedResponseValidator(),
        cache: ResponseCache? = nil
    ) {
        self.parser = parser
        self.validator = validator
        self.cache = cache
        self.metadataExtractor = MetadataExtractor()
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
        
        // Use shared metadata extraction
        let metadata = metadataExtractor.extractMetadata(from: response)
        
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
        return metadataExtractor.extractMetadata(from: response)
    }
}