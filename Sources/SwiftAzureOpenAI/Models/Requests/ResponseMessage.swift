import Foundation

/// Sender role in a conversation.
public enum MessageRole: String, Codable {
    case system
    case user
    case assistant
    case tool
}

/// A message with structured content parts for the Responses API.
public struct ResponseMessage: Codable, Equatable {
    public let role: MessageRole
    public let content: [InputContentPart]

    public init(role: MessageRole, content: [InputContentPart]) {
        self.role = role
        self.content = content
    }
    
    /// Convenience initializer for simple text messages
    public init(role: MessageRole, text: String) {
        self.role = role
        self.content = [.inputText(.init(text: text))]
    }
}

