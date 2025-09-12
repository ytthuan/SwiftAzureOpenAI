import Foundation

/// Flexible input type for the Responses API that supports both messages and raw input objects
public enum SAOAIInput: Codable, Equatable {
    case message(SAOAIMessage)
    case functionCallOutput(SAOAIInputContent.FunctionCallOutput)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as function call output first (has type field)
        if let functionOutput = try? container.decode(SAOAIInputContent.FunctionCallOutput.self) {
            self = .functionCallOutput(functionOutput)
            return
        }
        
        // Otherwise decode as message
        let message = try container.decode(SAOAIMessage.self)
        self = .message(message)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .message(let message):
            try container.encode(message)
        case .functionCallOutput(let output):
            try container.encode(output)
        }
    }
}

/// Request payload for the Azure/OpenAI Responses API.
public struct SAOAIRequest: Codable, Equatable {
    /// Model or deployment name. For Azure, this is the deployment name.
    public let model: String?
    /// Unified input for the Responses API. Supports both messages and raw input objects.
    public let input: [SAOAIInput]
    /// Maximum number of tokens to generate in the output.
    public let maxOutputTokens: Int?
    /// Sampling temperature.
    public let temperature: Double?
    /// Nucleus sampling parameter.
    public let topP: Double?
    /// Optional tool definitions.
    public let tools: [SAOAITool]?
    /// Previous response ID for chaining responses.
    public let previousResponseId: String?
    /// Reasoning configuration for reasoning models.
    public let reasoning: SAOAIReasoning?
    /// Text configuration for response generation.
    public let text: SAOAIText?
    /// Whether to stream the response using Server-Sent Events (SSE).
    public let stream: Bool?

    public init(
        model: String? = nil,
        input: [SAOAIInput],
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        tools: [SAOAITool]? = nil,
        previousResponseId: String? = nil,
        reasoning: SAOAIReasoning? = nil,
        text: SAOAIText? = nil,
        stream: Bool? = nil
    ) {
        self.model = model
        self.input = input
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
        self.topP = topP
        self.tools = tools
        self.previousResponseId = previousResponseId
        self.reasoning = reasoning
        self.text = text
        self.stream = stream
    }

    enum CodingKeys: String, CodingKey {
        case model
        case input
        case maxOutputTokens = "max_output_tokens"
        case temperature
        case topP = "top_p"
        case tools
        case previousResponseId = "previous_response_id"
        case reasoning
        case text
        case stream
    }
}

/// Minimal request payload for function call outputs to match Python API exactly
public struct SAOAIMinimalRequest: Codable, Equatable {
    /// Model or deployment name. For Azure, this is the deployment name.
    public let model: String
    /// Unified input for the Responses API. Supports both messages and raw input objects.
    public let input: [SAOAIInput]
    /// Whether to stream the response using Server-Sent Events (SSE).
    public let stream: Bool
    /// Previous response ID for chaining responses.
    public var previousResponseId: String?

    public init(
        model: String,
        input: [SAOAIInput],
        stream: Bool,
        previousResponseId: String? = nil
    ) {
        self.model = model
        self.input = input
        self.stream = stream
        self.previousResponseId = previousResponseId
    }

    enum CodingKeys: String, CodingKey {
        case model
        case input
        case stream
        case previousResponseId = "previous_response_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(input, forKey: .input)
        try container.encode(stream, forKey: .stream)
        
        // Only encode previousResponseId if it's not nil
        if let previousResponseId = previousResponseId {
            try container.encode(previousResponseId, forKey: .previousResponseId)
        }
    }
}

