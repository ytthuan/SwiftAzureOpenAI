import Foundation

public protocol SAOAIConfiguration: Sendable {
    var baseURL: URL { get }
    var headers: [String: String] { get }
    var sseLoggerConfiguration: SSELoggerConfiguration { get }
}

public struct SAOAIAzureConfiguration: SAOAIConfiguration, Sendable {
    public let endpoint: String
    public let apiKey: String
    public let deploymentName: String
    public let apiVersion: String
    public let sseLoggerConfiguration: SSELoggerConfiguration

    public init(endpoint: String, apiKey: String, deploymentName: String, apiVersion: String = "preview", sseLoggerConfiguration: SSELoggerConfiguration = .disabled) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.deploymentName = deploymentName
        self.apiVersion = apiVersion
        self.sseLoggerConfiguration = sseLoggerConfiguration
    }

    public var baseURL: URL {
        // https://{resource}.openai.azure.com/openai/v1/responses?api-version=preview
        var components = URLComponents(string: endpoint)!
        components.path = "/openai/v1/responses"
        components.queryItems = [URLQueryItem(name: "api-version", value: apiVersion)]
        return components.url!
    }

    public var headers: [String: String] {
        [
            "api-key": apiKey,
            "Content-Type": "application/json"
        ]
    }
}

public struct SAOAIOpenAIConfiguration: SAOAIConfiguration, Sendable {
    public let apiKey: String
    public let organization: String?
    public let sseLoggerConfiguration: SSELoggerConfiguration

    public init(apiKey: String, organization: String? = nil, sseLoggerConfiguration: SSELoggerConfiguration = .disabled) {
        self.apiKey = apiKey
        self.organization = organization
        self.sseLoggerConfiguration = sseLoggerConfiguration
    }

    public var baseURL: URL {
        URL(string: "https://api.openai.com/v1/responses")!
    }

    public var headers: [String: String] {
        var headers: [String: String] = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        if let organization {
            headers["OpenAI-Organization"] = organization
        }
        return headers
    }
}

