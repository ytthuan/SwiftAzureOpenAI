import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class SAOAIClient: @unchecked Sendable {
    private let configuration: SAOAIConfiguration
    private let httpClient: HTTPClient
    private let responseService: ResponseServiceProtocol
    
    /// Python-style responses client for simplified API access
    public lazy var responses: ResponsesClient = {
        ResponsesClient(httpClient: httpClient, responseService: responseService, configuration: configuration)
    }()
    
    /// Files client for Azure OpenAI Files API operations
    public lazy var files: FilesClient = {
        FilesClient(httpClient: httpClient, responseService: responseService, configuration: configuration)
    }()

    public init(configuration: SAOAIConfiguration, cache: ResponseCache? = nil, useOptimizedService: Bool = true) {
        self.configuration = configuration
        self.httpClient = HTTPClient(configuration: configuration)
        
        // Use optimized service by default for better performance
        if useOptimizedService {
            self.responseService = OptimizedResponseService(cache: cache)
        } else {
            self.responseService = ResponseService(cache: cache)
        }
    }

    public func processResponse<T: Codable>(from request: APIRequest) async throws -> APIResponse<T> {
        let (data, http) = try await httpClient.send(request)
        return try await responseService.processResponse(data, response: http, type: T.self)
    }

    public func processStreamingResponse<T: Codable>(from stream: AsyncThrowingStream<Data, Error>, type: T.Type) -> AsyncThrowingStream<StreamingResponseChunk<T>, Error> {
        OptimizedStreamingResponseService().processStreamOptimized(stream, type: type)
    }

    public func handleResponse<T: Codable>(data: Data, response: URLResponse) async throws -> APIResponse<T> {
        guard let http = response as? HTTPURLResponse else {
            throw SAOAIError.networkError(URLError(.badServerResponse))
        }
        return try await responseService.processResponse(data, response: http, type: T.self)
    }
}
