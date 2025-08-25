import Foundation

/// Metadata extracted from HTTP responses for diagnostics and governance.
public struct ResponseMetadata: Codable {
    /// Server-provided request identifier, if available (e.g., `x-request-id`).
    public let requestId: String?
    /// The local timestamp when the response was processed.
    public let timestamp: Date
    /// Server-reported processing time, if available.
    public let processingTime: TimeInterval?
    /// Parsed rate limiting information from headers (remaining, reset time, limit).
    public let rateLimit: RateLimitInfo?

    public init(
        requestId: String?,
        timestamp: Date = Date(),
        processingTime: TimeInterval?,
        rateLimit: RateLimitInfo?
    ) {
        self.requestId = requestId
        self.timestamp = timestamp
        self.processingTime = processingTime
        self.rateLimit = rateLimit
    }
}

