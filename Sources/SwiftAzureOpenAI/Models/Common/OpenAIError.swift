import Foundation

/// Enhanced error taxonomy for comprehensive error handling
public enum SAOAIErrorCategory: String, CaseIterable, Sendable {
    case authentication = "authentication"
    case rateLimit = "rate_limit"
    case client = "client"
    case server = "server"
    case network = "network"
    case parsing = "parsing"
    case timeout = "timeout"
    case api = "api"
}

/// Typed errors for SDK consumers, mapping HTTP failures and decoding issues.
public enum SAOAIError: Error, LocalizedError, Equatable {
    case invalidAPIKey
    case rateLimitExceeded
    case serverError(statusCode: Int)
    case invalidRequest(String)
    case networkError(Error)
    case decodingError(Error)
    case apiError(ErrorResponse)
    case timeoutError(TimeInterval)
    case quotaExceeded
    case contentFiltered
    case modelNotFound
    case modelOverloaded

    /// Get the error category for better error handling
    public var category: SAOAIErrorCategory {
        switch self {
        case .invalidAPIKey:
            return .authentication
        case .rateLimitExceeded, .quotaExceeded:
            return .rateLimit
        case .invalidRequest, .contentFiltered, .modelNotFound:
            return .client
        case .serverError, .modelOverloaded:
            return .server
        case .networkError:
            return .network
        case .decodingError:
            return .parsing
        case .timeoutError:
            return .timeout
        case .apiError:
            return .api
        }
    }

    /// Creates a common error from a status code, if recognized.
    public static func from(statusCode: Int) -> SAOAIError? {
        switch statusCode {
        case 401: return .invalidAPIKey
        case 403: return .quotaExceeded
        case 422: return .contentFiltered
        case 429: return .rateLimitExceeded
        case 400: return .invalidRequest("Bad Request")
        case 404: return .modelNotFound
        case 503: return .modelOverloaded
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
        case .quotaExceeded:
            return "API quota exceeded. Please check your billing and usage limits."
        case .contentFiltered:
            return "Content was filtered due to policy violations."
        case .modelNotFound:
            return "The requested model was not found or is not available."
        case .modelOverloaded:
            return "The model is currently overloaded. Please try again later."
        case .timeoutError(let interval):
            return "Request timed out after \(interval) seconds."
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
    
    public static func == (lhs: SAOAIError, rhs: SAOAIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidAPIKey, .invalidAPIKey),
             (.rateLimitExceeded, .rateLimitExceeded),
             (.quotaExceeded, .quotaExceeded),
             (.contentFiltered, .contentFiltered),
             (.modelNotFound, .modelNotFound),
             (.modelOverloaded, .modelOverloaded):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.timeoutError(let lhsInterval), .timeoutError(let rhsInterval)):
            return lhsInterval == rhsInterval
        case (.invalidRequest(let lhsMessage), .invalidRequest(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.apiError(let lhsResponse), .apiError(let rhsResponse)):
            return lhsResponse.error.message == rhsResponse.error.message
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

