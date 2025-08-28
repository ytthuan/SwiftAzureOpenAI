import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct APIRequest: Sendable {
    public let method: String
    public let url: URL
    public let headers: [String: String]
    public let body: Data?

    public init(method: String = "POST", url: URL, headers: [String: String] = [:], body: Data? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

public final class HTTPClient {
    private let configuration: SAOAIConfiguration
    private let urlSession: URLSession
    private let maxRetries: Int

    public init(configuration: SAOAIConfiguration, session: URLSession = .shared, maxRetries: Int = 2) {
        self.configuration = configuration
        self.urlSession = session
        self.maxRetries = maxRetries
    }

    public func send(_ request: APIRequest) async throws -> (Data, HTTPURLResponse) {
        var attempts = 0
        var lastError: Error?

        while attempts <= maxRetries {
            do {
                let urlRequest = try buildURLRequest(from: request)
                let (data, response) = try await urlSession.data(for: urlRequest)
                guard let http = response as? HTTPURLResponse else {
                    throw SAOAIError.networkError(URLError(.badServerResponse))
                }
                return (data, http)
            } catch {
                lastError = error
                attempts += 1
                if attempts > maxRetries { break }
                let sleepMs = UInt64(pow(2.0, Double(attempts)) * 200.0)
                try? await Task.sleep(nanoseconds: sleepMs * 1_000_000)
            }
        }
        throw SAOAIError.networkError(lastError ?? URLError(.unknown))
    }

    private func buildURLRequest(from request: APIRequest) throws -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        var finalHeaders = configuration.headers
        request.headers.forEach { finalHeaders[$0.key] = $0.value }
        for (key, value) in finalHeaders { urlRequest.setValue(value, forHTTPHeaderField: key) }
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = 60
        return urlRequest
    }
}

