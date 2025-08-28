import Foundation

/// Sender role in a conversation.
public enum SAOAIMessageRole: String, Codable {
    case system
    case user
    case assistant
    case tool
}

/// A message with structured content parts for the Responses API.
public struct SAOAIMessage: Codable, Equatable {
    public let role: SAOAIMessageRole
    public let content: [InputContentPart]

    public init(role: SAOAIMessageRole, content: [InputContentPart]) {
        self.role = role
        self.content = content
    }
    
    /// Convenience initializer for simple text messages
    public init(role: SAOAIMessageRole, text: String) {
        self.role = role
        self.content = [.inputText(.init(text: text))]
    }
    
    /// Convenience initializer for text + image URL
    public init(role: SAOAIMessageRole, text: String, imageURL: String) {
        self.role = role
        self.content = [
            .inputText(.init(text: text)),
            .inputImage(.init(imageURL: imageURL))
        ]
    }
    
    /// Convenience initializer for text + base64 image
    public init(role: SAOAIMessageRole, text: String, base64Image: String, mimeType: String = "image/jpeg") {
        self.role = role
        self.content = [
            .inputText(.init(text: text)),
            .inputImage(.init(base64Data: base64Image, mimeType: mimeType))
        ]
    }
}

// MARK: - Backward Compatibility
@available(*, deprecated, renamed: "SAOAIMessageRole")
public typealias MessageRole = SAOAIMessageRole

@available(*, deprecated, renamed: "SAOAIMessage")
public typealias ResponseMessage = SAOAIMessage

