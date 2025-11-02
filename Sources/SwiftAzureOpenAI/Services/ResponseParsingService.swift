import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol ResponseParser {
    func parse<T: Codable>(_ data: Data, as type: T.Type) async throws -> T
}

/// Default response parser - now uses shared implementation
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

/// Default response validator - now delegates to shared implementation
public final class DefaultResponseValidator: ResponseValidator {
    private let sharedValidator: SharedResponseValidator
    
    public init() {
        self.sharedValidator = SharedResponseValidator()
    }

    public func validate(_ response: HTTPURLResponse, data: Data) throws {
        try sharedValidator.validate(response, data: data)
    }
}

