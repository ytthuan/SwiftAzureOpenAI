import Foundation

/// Token usage statistics returned by the Responses API.
public struct SAOAITokenUsage: Codable, Equatable, Sendable {
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let totalTokens: Int?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
    }

    public init(inputTokens: Int?, outputTokens: Int?, totalTokens: Int?) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
    }
}

