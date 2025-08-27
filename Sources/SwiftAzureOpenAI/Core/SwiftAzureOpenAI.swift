import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class SwiftAzureOpenAI {
    private let configuration: OpenAIConfiguration
    private let httpClient: HTTPClient
    private let responseService: ResponseService
    
    /// Python-style responses client for simplified API access
    public lazy var responses: ResponsesClient = {
        ResponsesClient(httpClient: httpClient, responseService: responseService, configuration: configuration)
    }()

    public init(configuration: OpenAIConfiguration, cache: ResponseCache? = nil) {
        self.configuration = configuration
        self.httpClient = HTTPClient(configuration: configuration)
        self.responseService = ResponseService(cache: cache)
    }

    public func processResponse<T: Codable>(from request: APIRequest) async throws -> APIResponse<T> {
        let (data, http) = try await httpClient.send(request)
        return try await responseService.processResponse(data, response: http, type: T.self)
    }

    public func processStreamingResponse<T: Codable>(from stream: AsyncThrowingStream<Data, Error>, type: T.Type) -> AsyncThrowingStream<StreamingResponseChunk<T>, Error> {
        StreamingResponseService().processStream(stream, type: type)
    }

    public func handleResponse<T: Codable>(data: Data, response: URLResponse) async throws -> APIResponse<T> {
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIError.networkError(URLError(.badServerResponse))
        }
        return try await responseService.processResponse(data, response: http, type: T.self)
    }
}

