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
    public let role: SAOAIMessageRole?
    public let content: [SAOAIInputContent]

    public init(role: SAOAIMessageRole?, content: [SAOAIInputContent]) {
        self.role = role
        self.content = content
    }
    
    /// Convenience initializer for simple text messages
    public init(role: SAOAIMessageRole, text: String) {
        self.role = role
        self.content = [.inputText(.init(text: text))]
    }
    
    /// Convenience initializer for function call outputs without role (tool outputs)
    public init(functionCallOutput: SAOAIInputContent.FunctionCallOutput) {
        self.role = nil
        self.content = [.functionCallOutput(functionCallOutput)]
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
    
    /// Convenience initializer for text + file (base64-encoded)
    public init(role: SAOAIMessageRole, text: String, filename: String, base64FileData: String, mimeType: String = "application/pdf") {
        self.role = role
        self.content = [
            .inputText(.init(text: text)),
            .inputFile(.init(filename: filename, base64Data: base64FileData, mimeType: mimeType))
        ]
    }
    
    /// Convenience initializer for text + file ID
    public init(role: SAOAIMessageRole, text: String, fileId: String) {
        self.role = role
        self.content = [
            .inputText(.init(text: text)),
            .inputFile(.init(fileId: fileId))
        ]
    }
}

extension SAOAIMessage {
    enum CodingKeys: String, CodingKey {
        case role
        case content
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try container.decodeIfPresent(SAOAIMessageRole.self, forKey: .role)
        self.content = try container.decode([SAOAIInputContent].self, forKey: .content)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Only encode role if it's not nil
        if let role = role {
            try container.encode(role, forKey: .role)
        }
        
        try container.encode(content, forKey: .content)
    }
}

