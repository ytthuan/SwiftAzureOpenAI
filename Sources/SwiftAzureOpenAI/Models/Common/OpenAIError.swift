import Foundation

/// Typed errors for SDK consumers, mapping HTTP failures and decoding issues.
public enum OpenAIError: Error, LocalizedError {
    case invalidAPIKey
    case rateLimitExceeded
    case serverError(statusCode: Int)
    case invalidRequest(String)
    case networkError(Error)
    case decodingError(Error)
    case apiError(ErrorResponse)

    /// Creates a common error from a status code, if recognized.
    public static func from(statusCode: Int) -> OpenAIError? {
        switch statusCode {
        case 401: return .invalidAPIKey
        case 429: return .rateLimitExceeded
        case 400: return .invalidRequest("Bad Request")
        case 500...599: return .serverError(statusCode: statusCode)
        default: return nil
        }
    }

    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "The provided API key is invalid."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let statusCode):
            return "Server returned an error with status code: \(statusCode)."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let errorResponse):
            return errorResponse.error.message
        }
    }
}

