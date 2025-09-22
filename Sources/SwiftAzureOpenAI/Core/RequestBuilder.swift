import Foundation

/// Central request builder for Azure OpenAI endpoints
public struct AzureRequestBuilder: Sendable {
    private let configuration: SAOAIConfiguration
    
    internal init(configuration: SAOAIConfiguration) {
        self.configuration = configuration
    }
    
    /// Build a URL for a specific Azure OpenAI endpoint
    /// - Parameter endpoint: The API endpoint (e.g., "responses", "embeddings", "files")
    /// - Returns: The complete URL for the endpoint
    public func buildURL(for endpoint: String) -> URL {
        if let azureConfig = configuration as? SAOAIAzureConfiguration {
            return buildAzureURL(endpoint: endpoint, config: azureConfig)
        } else {
            return buildOpenAIURL(endpoint: endpoint)
        }
    }
    
    /// Build an API request with common headers and configuration
    /// - Parameters:
    ///   - method: HTTP method (default: "POST")
    ///   - endpoint: The API endpoint
    ///   - body: Request body data
    ///   - additionalHeaders: Additional headers to merge
    ///   - timeoutInterval: Custom timeout interval
    /// - Returns: Configured APIRequest
    public func buildRequest(
        method: String = "POST",
        endpoint: String,
        body: Data? = nil,
        additionalHeaders: [String: String] = [:],
        timeoutInterval: TimeInterval? = nil
    ) -> APIRequest {
        let url = buildURL(for: endpoint)
        var headers = configuration.headers
        
        // Merge additional headers
        for (key, value) in additionalHeaders {
            headers[key] = value
        }
        
        return APIRequest(
            method: method,
            url: url,
            headers: headers,
            body: body,
            timeoutInterval: timeoutInterval
        )
    }
    
    /// Build a streaming request with appropriate headers
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - body: Request body data
    ///   - timeoutInterval: Custom timeout interval
    /// - Returns: Configured APIRequest for streaming
    public func buildStreamingRequest(
        endpoint: String,
        body: Data? = nil,
        timeoutInterval: TimeInterval? = nil
    ) -> APIRequest {
        let streamingHeaders = [
            "Accept": "text/event-stream",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        ]
        
        return buildRequest(
            method: "POST",
            endpoint: endpoint,
            body: body,
            additionalHeaders: streamingHeaders,
            timeoutInterval: timeoutInterval
        )
    }
    
    // MARK: - Private Methods
    
    private func buildAzureURL(endpoint: String, config: SAOAIAzureConfiguration) -> URL {
        guard var components = URLComponents(string: config.endpoint) else {
            fatalError("Invalid Azure endpoint: \(config.endpoint)")
        }
        
        components.path = "/openai/v1/\(endpoint)"
        components.queryItems = [URLQueryItem(name: "api-version", value: config.apiVersion)]
        
        guard let url = components.url else {
            fatalError("Failed to construct Azure URL for endpoint: \(endpoint)")
        }
        
        return url
    }
    
    private func buildOpenAIURL(endpoint: String) -> URL {
        let baseURL = configuration.baseURL
        return baseURL.deletingLastPathComponent().appendingPathComponent(endpoint)
    }
}

// MARK: - Static Convenience Methods

extension AzureRequestBuilder {
    /// Create a request builder from a configuration
    /// - Parameter configuration: The SAOAI configuration
    /// - Returns: A configured request builder
    public static func create(from configuration: SAOAIConfiguration) -> AzureRequestBuilder {
        return AzureRequestBuilder(configuration: configuration)
    }
}

// MARK: - Common Endpoint Names

extension AzureRequestBuilder {
    /// Predefined endpoint names for consistency
    public enum Endpoint {
        public static let responses = "responses"
        public static let embeddings = "embeddings"
        public static let files = "files"
        public static let completions = "completions"
        public static let chatCompletions = "chat/completions"
        public static let images = "images"
        public static let audio = "audio"
        
        /// Get the endpoint string for a given endpoint type
        /// - Parameter type: The endpoint type
        /// - Returns: The endpoint string
        public static func name(for type: EndpointType) -> String {
            switch type {
            case .responses: return responses
            case .embeddings: return embeddings
            case .files: return files
            case .completions: return completions
            case .chatCompletions: return chatCompletions
            case .images: return images
            case .audio: return audio
            }
        }
    }
    
    /// Supported endpoint types
    public enum EndpointType: CaseIterable, Sendable {
        case responses
        case embeddings
        case files
        case completions
        case chatCompletions
        case images
        case audio
    }
}