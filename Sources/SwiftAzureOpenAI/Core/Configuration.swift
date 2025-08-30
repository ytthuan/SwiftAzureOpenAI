import Foundation

public protocol SAOAIConfiguration: Sendable {
    var baseURL: URL { get }
    var headers: [String: String] { get }
}

public struct SAOAIAzureConfiguration: SAOAIConfiguration, Sendable {
    public let endpoint: String
    public let apiKey: String
    public let deploymentName: String
    public let apiVersion: String

    public init(endpoint: String, apiKey: String, deploymentName: String, apiVersion: String = "preview") {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.deploymentName = deploymentName
        self.apiVersion = apiVersion
    }

    public var baseURL: URL {
        // https://{resource}.openai.azure.com/openai/v1/responses
        // Based on Microsoft docs API Key examples, api-version is not included in URL
        var components = URLComponents(string: endpoint)!
        components.path = "/openai/v1/responses"
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

    public init(apiKey: String, organization: String? = nil) {
        self.apiKey = apiKey
        self.organization = organization
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

