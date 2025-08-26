import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol ResponseServiceProtocol {
    func processResponse<T: Codable>(_ data: Data, response: HTTPURLResponse, type: T.Type) async throws -> APIResponse<T>
    func validateResponse(_ response: HTTPURLResponse) throws
    func extractMetadata(from response: HTTPURLResponse) -> ResponseMetadata
}

public final class ResponseService: ResponseServiceProtocol {
    private let parser: ResponseParser
    private let validator: ResponseValidator
    private let cache: ResponseCache?

    public init(parser: ResponseParser = DefaultResponseParser(), validator: ResponseValidator = DefaultResponseValidator(), cache: ResponseCache? = nil) {
        self.parser = parser
        self.validator = validator
        self.cache = cache
    }

    public func processResponse<T: Codable>(_ data: Data, response: HTTPURLResponse, type: T.Type) async throws -> APIResponse<T> {
        if let cached: APIResponse<T> = await cache?.retrieve(for: data, as: T.self) {
            return cached
        }

        try validator.validate(response, data: data)
        let parsed = try await parser.parse(data, as: type)
        let metadata = extractMetadata(from: response)
        let apiResponse = APIResponse(data: parsed, metadata: metadata, statusCode: response.statusCode, headers: response.normalizedHeaders)
        await cache?.store(response: apiResponse, for: data)
        return apiResponse
    }

    public func validateResponse(_ response: HTTPURLResponse) throws {
        if let specific = OpenAIError.from(statusCode: response.statusCode) { throw specific }
    }

    public func extractMetadata(from response: HTTPURLResponse) -> ResponseMetadata {
        let headers = response.normalizedHeaders

        let requestId = headers["x-request-id"] ?? headers["x-ms-request-id"]

        let processingTimeSeconds: TimeInterval? = {
            if let msString = headers["x-processing-ms"] ?? headers["openai-processing-ms"], let ms = Double(msString) {
                return ms / 1000.0
            }
            return nil
        }()

        let remaining: Int? = {
            if let v = headers["x-ratelimit-remaining"] ?? headers["x-ratelimit-remaining-requests"], let i = Int(v) { return i }
            return nil
        }()

        let limit: Int? = {
            if let v = headers["x-ratelimit-limit"] ?? headers["x-ratelimit-limit-requests"], let i = Int(v) { return i }
            return nil
        }()

        let resetTime: Date? = {
            guard let resetStr = headers["x-ratelimit-reset"] ?? headers["x-ratelimit-reset-requests"], let value = Double(resetStr) else { return nil }
            // Heuristic: treat large numbers as epoch seconds, small as seconds-from-now
            if value > 1_000_000_000 {
                return Date(timeIntervalSince1970: value)
            } else {
                return Date().addingTimeInterval(value)
            }
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

