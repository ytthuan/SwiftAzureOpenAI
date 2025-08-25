import Foundation

/// A generic wrapper for API responses containing the decoded data and rich metadata.
public struct APIResponse<T: Codable>: Codable {
    /// The decoded response body as the requested type.
    public let data: T
    /// Derived metadata from the HTTP response (request id, rate limits, etc.).
    public let metadata: ResponseMetadata
    /// HTTP status code returned by the server.
    public let statusCode: Int
    /// All response headers normalized to `[String: String]`.
    public let headers: [String: String]

    public init(
        data: T,
        metadata: ResponseMetadata,
        statusCode: Int,
        headers: [String: String]
    ) {
        self.data = data
        self.metadata = metadata
        self.statusCode = statusCode
        self.headers = headers
    }
}

