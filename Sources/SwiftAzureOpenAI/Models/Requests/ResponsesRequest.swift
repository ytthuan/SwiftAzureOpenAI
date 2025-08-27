import Foundation

/// Request payload for the Azure/OpenAI Responses API.
public struct ResponsesRequest: Codable, Equatable {
    /// Model or deployment name. For Azure, this is the deployment name.
    public let model: String?
    /// Unified input for the Responses API. Typically an array of messages with content parts.
    public let input: [ResponseMessage]
    /// Maximum number of tokens to generate in the output.
    public let maxOutputTokens: Int?
    /// Sampling temperature.
    public let temperature: Double?
    /// Nucleus sampling parameter.
    public let topP: Double?
    /// Optional tool definitions.
    public let tools: [ToolDefinition]?
    /// Previous response ID for chaining responses.
    public let previousResponseId: String?

    public init(
        model: String? = nil,
        input: [ResponseMessage],
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        tools: [ToolDefinition]? = nil,
        previousResponseId: String? = nil
    ) {
        self.model = model
        self.input = input
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
        self.topP = topP
        self.tools = tools
        self.previousResponseId = previousResponseId
    }

    enum CodingKeys: String, CodingKey {
        case model
        case input
        case maxOutputTokens = "max_output_tokens"
        case temperature
        case topP = "top_p"
        case tools
        case previousResponseId = "previous_response_id"
    }
}

