import Foundation

/// Rate limiting information parsed from response headers.
public struct RateLimitInfo: Codable {
    /// Remaining number of requests or tokens before throttling.
    public let remaining: Int?
    /// When the limit resets.
    public let resetTime: Date?
    /// Max limit in the current window.
    public let limit: Int?

    public init(remaining: Int?, resetTime: Date?, limit: Int?) {
        self.remaining = remaining
        self.resetTime = resetTime
        self.limit = limit
    }
}

