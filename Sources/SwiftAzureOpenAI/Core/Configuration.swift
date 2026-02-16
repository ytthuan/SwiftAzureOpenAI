import Foundation

public protocol SAOAIConfiguration: Sendable {
    var baseURL: URL { get }
    var headers: [String: String] { get }
    var sseLoggerConfiguration: SSELoggerConfiguration { get }
    var loggerConfiguration: LoggerConfiguration { get }
}

public struct SAOAIOpenAIConfiguration: SAOAIConfiguration, Sendable {
    public let apiKey: String
    public let organization: String?
    public let sseLoggerConfiguration: SSELoggerConfiguration
    public let loggerConfiguration: LoggerConfiguration

    public init(
        apiKey: String,
        organization: String? = nil,
        sseLoggerConfiguration: SSELoggerConfiguration = .disabled,
        loggerConfiguration: LoggerConfiguration = .disabled
    ) {
        self.apiKey = apiKey
        self.organization = organization
        self.sseLoggerConfiguration = sseLoggerConfiguration
        self.loggerConfiguration = loggerConfiguration
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

