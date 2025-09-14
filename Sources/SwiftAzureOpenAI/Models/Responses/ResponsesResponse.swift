import Foundation

/// Represents a summary entry that can be either a simple string or a structured object
public enum SAOAISummaryEntry: Codable, Equatable, Sendable {
    case text(String)
    case structured(SAOAISummaryObject)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .text(stringValue)
        } else if let structValue = try? container.decode(SAOAISummaryObject.self) {
            self = .structured(structValue)
        } else {
            throw DecodingError.typeMismatch(
                SAOAISummaryEntry.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or SAOAISummaryObject")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let string):
            try container.encode(string)
        case .structured(let object):
            try container.encode(object)
        }
    }
    
    /// Extract text content regardless of the format
    public var textContent: String {
        switch self {
        case .text(let string):
            return string
        case .structured(let object):
            return object.text ?? ""
        }
    }
}

/// Structured summary object for detailed reasoning summaries
public struct SAOAISummaryObject: Codable, Equatable, Sendable {
    public let type: String?
    public let text: String?
    
    public init(type: String? = nil, text: String? = nil) {
        self.type = type
        self.text = text
    }
}

/// A single assistant output message with one or more content parts, reasoning output, or function call.
public struct SAOAIOutput: Codable, Equatable, Sendable {
    public let content: [SAOAIOutputContent]?
    public let role: String?
    
    // Common fields
    public let id: String?
    public let type: String?
    
    // Reasoning output fields - flexible summary format
    public let summary: [SAOAISummaryEntry]?
    
    // Function call output fields (for type: "function_call")
    public let name: String?
    public let callId: String?
    public let arguments: String?
    public let status: String?

    public init(content: [SAOAIOutputContent]? = nil, role: String? = nil, id: String? = nil, type: String? = nil, summary: [SAOAISummaryEntry]? = nil, name: String? = nil, callId: String? = nil, arguments: String? = nil, status: String? = nil) {
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
    
    /// Helper property to get summary as plain text array for backward compatibility
    public var summaryText: [String]? {
        return summary?.map { $0.textContent }
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

