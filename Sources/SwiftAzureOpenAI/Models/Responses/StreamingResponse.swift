import Foundation

/// Represents a streaming response chunk from OpenAI/Azure OpenAI API
public struct SAOAIStreamingResponse: Codable, Equatable, Sendable {
    public let id: String?
    public let model: String?
    public let created: Int?
    public let output: [SAOAIStreamingOutput]?
    public let usage: SAOAITokenUsage?
    
    public init(
        id: String?,
        model: String?,
        created: Int?,
        output: [SAOAIStreamingOutput]?,
        usage: SAOAITokenUsage?
    ) {
        self.id = id
        self.model = model
        self.created = created
        self.output = output
        self.usage = usage
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