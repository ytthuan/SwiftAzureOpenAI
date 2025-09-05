import Foundation

/// A single assistant output message with one or more content parts, reasoning output, or function call.
public struct SAOAIOutput: Codable, Equatable, Sendable {
    public let content: [SAOAIOutputContent]?
    public let role: String?
    
    // Common fields
    public let id: String?
    public let type: String?
    
    // Reasoning output fields
    public let summary: [String]?
    
    // Function call output fields (for type: "function_call")
    public let name: String?
    public let callId: String?
    public let arguments: String?
    public let status: String?

    public init(content: [SAOAIOutputContent]? = nil, role: String? = nil, id: String? = nil, type: String? = nil, summary: [String]? = nil, name: String? = nil, callId: String? = nil, arguments: String? = nil, status: String? = nil) {
        self.content = content
        self.role = role
        self.id = id
        self.type = type
        self.summary = summary
        self.name = name
        self.callId = callId
        self.arguments = arguments
        self.status = status
    }
    
    enum CodingKeys: String, CodingKey {
        case content
        case role
        case id
        case type
        case summary
        case name
        case callId = "call_id"
        case arguments
        case status
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case model
        case created = "created_at"
        case output
        case usage
    }
}

