import Foundation

/// A single assistant output message with one or more content parts.
public struct ResponseOutput: Codable, Equatable {
    public let content: [OutputContentPart]
    public let role: String?

    public init(content: [OutputContentPart], role: String? = nil) {
        self.content = content
        self.role = role
    }
}

/// Top-level Responses API result payload.
public struct ResponsesResponse: Codable, Equatable {
    public let id: String?
    public let model: String?
    public let created: Int?
    public let output: [ResponseOutput]
    public let usage: TokenUsage?

    public init(
        id: String?,
        model: String?,
        created: Int?,
        output: [ResponseOutput],
        usage: TokenUsage?
    ) {
        self.id = id
        self.model = model
        self.created = created
        self.output = output
        self.usage = usage
    }
}

