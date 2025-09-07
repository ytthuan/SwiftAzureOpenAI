import Foundation

/// Represents a streaming response chunk from OpenAI/Azure OpenAI API
public struct SAOAIStreamingResponse: Codable, Equatable, Sendable {
    public let id: String?
    public let model: String?
    public let created: Int?
    public let output: [SAOAIStreamingOutput]?
    public let usage: SAOAITokenUsage?
    
    /// The type of streaming event (e.g., .outputTextDelta, .functionCallArgumentsDelta)
    /// This enables users to branch logic based on event type like Python SDK
    public let eventType: SAOAIStreamingEventType?
    
    /// Item information for events that include item details
    /// Allows access to item.type for tool-specific logic
    public let item: SAOAIStreamingItem?
    
    public init(
        id: String?,
        model: String?,
        created: Int?,
        output: [SAOAIStreamingOutput]?,
        usage: SAOAITokenUsage?,
        eventType: SAOAIStreamingEventType? = nil,
        item: SAOAIStreamingItem? = nil
    ) {
        self.id = id
        self.model = model
        self.created = created
        self.output = output
        self.usage = usage
        self.eventType = eventType
        self.item = item
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case model
        case created
        case output
        case usage
        case eventType = "event_type"
        case item
    }
}

/// Streaming output content for a single message chunk
public struct SAOAIStreamingOutput: Codable, Equatable, Sendable {
    public let content: [SAOAIStreamingContent]?
    public let role: String?
    
    public init(content: [SAOAIStreamingContent]?, role: String?) {
        self.content = content
        self.role = role
    }
}

/// Streaming content part that represents incremental content
public struct SAOAIStreamingContent: Codable, Equatable, Sendable {
    public let type: String?
    public let text: String?
    public let index: Int?
    
    public init(type: String?, text: String?, index: Int?) {
        self.type = type
        self.text = text
        self.index = index
    }
}