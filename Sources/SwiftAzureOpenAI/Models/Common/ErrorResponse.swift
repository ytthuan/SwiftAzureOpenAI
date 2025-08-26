import Foundation

/// Structured error payload returned by the API.
public struct ErrorResponse: Codable, Error {
    /// The underlying error detail.
    public let error: APIErrorDetail

    /// Detailed error information.
    public struct APIErrorDetail: Codable, Sendable {
        /// Human-readable message explaining the error.
        public let message: String
        /// Error type, if provided by the server.
        public let type: String?
        /// Error code, if provided by the server.
        public let code: String?
        /// The parameter related to the error, if applicable.
        public let param: String?
    }
}

