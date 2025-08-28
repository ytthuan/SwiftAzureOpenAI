import Foundation

/// A single assistant output message with one or more content parts.
public struct SAOAIOutput: Codable, Equatable {
    public let content: [SAOAIOutputContent]
    public let role: String?

    public init(content: [SAOAIOutputContent], role: String? = nil) {
        self.content = content
        self.role = role
    }
}

/// Top-level Responses API result payload.
public struct SAOAIResponse: Codable, Equatable {
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

