import Foundation

/// Request model for embeddings API
public struct SAOAIEmbeddingsRequest: Codable, Sendable {
    /// The input text or array of texts to get embeddings for
    public let input: SAOAIEmbeddingsInput
    /// The model to use for generating embeddings (Azure: deployment name, OpenAI: model name)
    public let model: String
    /// Optional encoding format for the embeddings (default: float)
    public let encodingFormat: SAOAIEmbeddingEncodingFormat?
    /// Optional dimensions for the embedding vector (model-dependent)
    public let dimensions: Int?
    /// Optional user identifier for tracking
    public let user: String?
    
    public init(
        input: SAOAIEmbeddingsInput,
        model: String,
        encodingFormat: SAOAIEmbeddingEncodingFormat? = nil,
        dimensions: Int? = nil,
        user: String? = nil
    ) {
        self.input = input
        self.model = model
        self.encodingFormat = encodingFormat
        self.dimensions = dimensions
        self.user = user
    }
    
    enum CodingKeys: String, CodingKey {
        case input
        case model
        case encodingFormat = "encoding_format"
        case dimensions
        case user
    }
}

/// Input types for embeddings requests
public enum SAOAIEmbeddingsInput: Codable, Sendable {
    case single(String)
    case multiple([String])
    case tokens([Int])
    case multipleTokens([[Int]])
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let text):
            try container.encode(text)
        case .multiple(let texts):
            try container.encode(texts)
        case .tokens(let tokens):
            try container.encode(tokens)
        case .multipleTokens(let tokenArrays):
            try container.encode(tokenArrays)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let text = try? container.decode(String.self) {
            self = .single(text)
        } else if let texts = try? container.decode([String].self) {
            self = .multiple(texts)
        } else if let tokens = try? container.decode([Int].self) {
            self = .tokens(tokens)
        } else if let tokenArrays = try? container.decode([[Int]].self) {
            self = .multipleTokens(tokenArrays)
        } else {
            throw DecodingError.typeMismatch(
                SAOAIEmbeddingsInput.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid input format")
            )
        }
    }
}

/// Encoding formats for embeddings
public enum SAOAIEmbeddingEncodingFormat: String, Codable, CaseIterable, Sendable {
    case float = "float"
    case base64 = "base64"
}

extension SAOAIEmbeddingsInput {
    /// Convenience initializer for single text input
    public static func text(_ text: String) -> SAOAIEmbeddingsInput {
        return .single(text)
    }
    
    /// Convenience initializer for multiple text inputs
    public static func texts(_ texts: [String]) -> SAOAIEmbeddingsInput {
        return .multiple(texts)
    }
    
    /// Get the count of input items
    public var count: Int {
        switch self {
        case .single:
            return 1
        case .multiple(let texts):
            return texts.count
        case .tokens:
            return 1
        case .multipleTokens(let tokenArrays):
            return tokenArrays.count
        }
    }
}