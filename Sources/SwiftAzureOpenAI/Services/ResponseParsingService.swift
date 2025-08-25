import Foundation

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
            throw OpenAIError.decodingError(error)
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
            if let specific = OpenAIError.from(statusCode: statusCode) { throw specific }
            if let error = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw OpenAIError.apiError(error)
            }
            throw OpenAIError.serverError(statusCode: statusCode)
        }
    }
}

