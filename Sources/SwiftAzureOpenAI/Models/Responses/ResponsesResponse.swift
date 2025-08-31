import Foundation

/// A single assistant output message with one or more content parts, or a reasoning output.
public struct SAOAIOutput: Codable, Equatable, Sendable {
    public let content: [SAOAIOutputContent]?
    public let role: String?
    
    // Reasoning output fields
    public let id: String?
    public let type: String?
    public let summary: [String]?

    public init(content: [SAOAIOutputContent]? = nil, role: String? = nil, id: String? = nil, type: String? = nil, summary: [String]? = nil) {
        self.content = content
        self.role = role
        self.id = id
        self.type = type
        self.summary = summary
    }
}

/// Top-level Responses API result payload.
public struct SAOAIResponse: Codable, Equatable, Sendable {
    public let id: String?
    public let model: String?
    public let created: Int?
    public let output: [SAOAIOutput]
    public let usage: SAOAITokenUsage?

    public init(
        id: String?,
        model: String?,
        created: Int?,
        output: [SAOAIOutput],
        usage: SAOAITokenUsage?
    ) {
        self.id = id
        self.model = model
        self.created = created
        self.output = output
        self.usage = usage
    }
}

