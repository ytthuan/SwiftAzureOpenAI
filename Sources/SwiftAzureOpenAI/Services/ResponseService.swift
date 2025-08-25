import Foundation

public protocol ResponseServiceProtocol {
    func processResponse<T: Codable>(_ data: Data, response: HTTPURLResponse, type: T.Type) async throws -> APIResponse<T>
    func validateResponse(_ response: HTTPURLResponse) throws
    func extractMetadata(from response: HTTPURLResponse) -> ResponseMetadata
}

public final class ResponseService: ResponseServiceProtocol {
    private let parser: ResponseParser
    private let validator: ResponseValidator

    public init(parser: ResponseParser = DefaultResponseParser(), validator: ResponseValidator = DefaultResponseValidator()) {
        self.parser = parser
        self.validator = validator
    }

    public func processResponse<T: Codable>(_ data: Data, response: HTTPURLResponse, type: T.Type) async throws -> APIResponse<T> {
        try validateResponse(response)
        let parsed = try await parser.parse(data, as: type)
        let metadata = extractMetadata(from: response)
        let apiResponse = APIResponse(data: parsed, metadata: metadata, statusCode: response.statusCode, headers: response.allHeaderFields as? [String: String] ?? [:])
        return apiResponse
    }

    public func validateResponse(_ response: HTTPURLResponse) throws {
        // Minimal validator requires body, but here we call underlying validator with empty data; callers use processResponse.
        // For header-only validation use this guard.
        if let specific = OpenAIError.from(statusCode: response.statusCode) { throw specific }
    }

    public func extractMetadata(from response: HTTPURLResponse) -> ResponseMetadata {
        let headers = response.allHeaderFields as? [String: Any] ?? [:]
        let requestId = headers["x-request-id"] as? String

        let processingTimeMs: TimeInterval? = {
            if let v = headers["x-processing-ms"] as? String, let ms = Double(v) { return ms / 1000.0 }
            if let v = headers["x-processing-ms"] as? NSNumber { return v.doubleValue / 1000.0 }
            return nil
        }()

        let rateLimit = RateLimitInfo(
            remaining: (headers["x-ratelimit-remaining"] as? NSString)?.integerValue,
            resetTime: nil,
            limit: (headers["x-ratelimit-limit"] as? NSString)?.integerValue
        )

        return ResponseMetadata(
            requestId: requestId,
            timestamp: Date(),
            processingTime: processingTimeMs,
            rateLimit: rateLimit
        )
    }
}

