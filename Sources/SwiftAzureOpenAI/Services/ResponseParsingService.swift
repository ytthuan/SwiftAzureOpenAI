import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol ResponseParser {
    func parse<T: Codable>(_ data: Data, as type: T.Type) async throws -> T
}

public final class DefaultResponseParser: ResponseParser {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func parse<T: Codable>(_ data: Data, as type: T.Type) async throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SAOAIError.decodingError(error)
        }
    }
}

public protocol ResponseValidator {
    func validate(_ response: HTTPURLResponse, data: Data) throws
}

public final class DefaultResponseValidator: ResponseValidator {
    public init() {}

    public func validate(_ response: HTTPURLResponse, data: Data) throws {
        let statusCode = response.statusCode
        guard (200..<300).contains(statusCode) else {
            // Try to decode structured error first
            if let error = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw SAOAIError.apiError(error)
            }
            // Fall back to known status code errors
            if let specific = SAOAIError.from(statusCode: statusCode) { throw specific }
            // Finally, generic server error
            throw SAOAIError.serverError(statusCode: statusCode)
        }
    }
}

