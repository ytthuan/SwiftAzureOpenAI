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
    private let metadataExtractor: MetadataExtractor

    public init(parser: ResponseParser = DefaultResponseParser(), validator: ResponseValidator = DefaultResponseValidator(), cache: ResponseCache? = nil) {
        self.parser = parser
        self.validator = validator
        self.cache = cache
        self.metadataExtractor = MetadataExtractor()
    }

    public func processResponse<T: Codable>(_ data: Data, response: HTTPURLResponse, type: T.Type) async throws -> APIResponse<T> {
        if let cached: APIResponse<T> = await cache?.retrieve(for: data, as: T.self) {
            return cached
        }

        try validator.validate(response, data: data)
        let parsed = try await parser.parse(data, as: type)
        let metadata = metadataExtractor.extractMetadata(from: response)
        let apiResponse = APIResponse(data: parsed, metadata: metadata, statusCode: response.statusCode, headers: response.normalizedHeaders)
        await cache?.store(response: apiResponse, for: data)
        return apiResponse
    }

    public func validateResponse(_ response: HTTPURLResponse) throws {
        if let specific = SAOAIError.from(statusCode: response.statusCode) { throw specific }
    }

    public func extractMetadata(from response: HTTPURLResponse) -> ResponseMetadata {
        return metadataExtractor.extractMetadata(from: response)
    }
}

