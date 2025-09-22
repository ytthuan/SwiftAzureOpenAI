import Foundation

// MARK: - Generated Models from OpenAPI Specification
// This file is generated from the pruned OpenAPI specification.
// Only includes models for /responses, /embeddings, and /files endpoints.

/// Generated request model for responses endpoint
public struct GeneratedResponsesRequest: Codable, Equatable {
    public let model: String
    public let input: [GeneratedInputMessage]
    public let maxOutputTokens: Int?
    public let temperature: Double?
    public let stream: Bool?
    
    public init(
        model: String,
        input: [GeneratedInputMessage],
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        stream: Bool? = nil
    ) {
        self.model = model
        self.input = input
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
        self.stream = stream
    }
    
    enum CodingKeys: String, CodingKey {
        case model, input, temperature, stream
        case maxOutputTokens = "max_output_tokens"
    }
}

/// Generated input message model
public struct GeneratedInputMessage: Codable, Equatable {
    public let role: String
    public let content: [GeneratedContentPart]
    
    public init(role: String, content: [GeneratedContentPart]) {
        self.role = role
        self.content = content
    }
}

/// Generated content part model
public struct GeneratedContentPart: Codable, Equatable {
    public let type: String
    public let text: String?
    public let inputText: String?
    
    public init(type: String, text: String? = nil, inputText: String? = nil) {
        self.type = type
        self.text = text
        self.inputText = inputText
    }
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case inputText = "input_text"
    }
}

/// Generated response model for responses endpoint  
public struct GeneratedResponsesResponse: Codable, Equatable {
    public let id: String?
    public let object: String?
    public let created: Int?
    public let model: String?
    public let choices: [GeneratedResponseChoice]?
    
    public init(
        id: String? = nil,
        object: String? = nil,
        created: Int? = nil,
        model: String? = nil,
        choices: [GeneratedResponseChoice]? = nil
    ) {
        self.id = id
        self.object = object
        self.created = created
        self.model = model
        self.choices = choices
    }
}

/// Generated response choice model
public struct GeneratedResponseChoice: Codable, Equatable {
    public let index: Int?
    public let message: GeneratedResponseMessage?
    public let finishReason: String?
    
    public init(
        index: Int? = nil,
        message: GeneratedResponseMessage? = nil,
        finishReason: String? = nil
    ) {
        self.index = index
        self.message = message
        self.finishReason = finishReason
    }
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

/// Generated response message model
public struct GeneratedResponseMessage: Codable, Equatable {
    public let role: String?
    public let content: [GeneratedOutputContentPart]?
    
    public init(role: String? = nil, content: [GeneratedOutputContentPart]? = nil) {
        self.role = role
        self.content = content
    }
}

/// Generated output content part model
public struct GeneratedOutputContentPart: Codable, Equatable {
    public let type: String?
    public let text: String?
    
    public init(type: String? = nil, text: String? = nil) {
        self.type = type
        self.text = text
    }
}

/// Generated embeddings request model
public struct GeneratedEmbeddingsRequest: Codable, Equatable {
    public let model: String
    public let input: EmbeddingInput
    public let dimensions: Int?
    public let encodingFormat: String?
    public let user: String?
    
    public init(
        model: String,
        input: EmbeddingInput,
        dimensions: Int? = nil,
        encodingFormat: String? = nil,
        user: String? = nil
    ) {
        self.model = model
        self.input = input
        self.dimensions = dimensions
        self.encodingFormat = encodingFormat
        self.user = user
    }
    
    enum CodingKeys: String, CodingKey {
        case model, input, dimensions, user
        case encodingFormat = "encoding_format"
    }
}

/// Input can be string or array of strings
public enum EmbeddingInput: Codable, Equatable {
    case single(String)
    case multiple([String])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .single(string)
        } else if let array = try? container.decode([String].self) {
            self = .multiple(array)
        } else {
            throw DecodingError.typeMismatch(
                EmbeddingInput.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected string or array of strings")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let string):
            try container.encode(string)
        case .multiple(let array):
            try container.encode(array)
        }
    }
}

/// Generated embeddings response model
public struct GeneratedEmbeddingsResponse: Codable, Equatable {
    public let object: String?
    public let data: [GeneratedEmbedding]?
    public let model: String?
    public let usage: GeneratedTokenUsage?
    
    public init(
        object: String? = nil,
        data: [GeneratedEmbedding]? = nil,
        model: String? = nil,
        usage: GeneratedTokenUsage? = nil
    ) {
        self.object = object
        self.data = data
        self.model = model
        self.usage = usage
    }
}

/// Generated embedding model
public struct GeneratedEmbedding: Codable, Equatable {
    public let object: String?
    public let index: Int?
    public let embedding: [Double]?
    
    public init(
        object: String? = nil,
        index: Int? = nil,
        embedding: [Double]? = nil
    ) {
        self.object = object
        self.index = index
        self.embedding = embedding
    }
}

/// Generated file upload request model  
public struct GeneratedFileUploadRequest: Codable, Equatable {
    public let file: Data
    public let purpose: String
    
    public init(file: Data, purpose: String) {
        self.file = file
        self.purpose = purpose
    }
}

/// Generated file response model
public struct GeneratedFileResponse: Codable, Equatable {
    public let id: String?
    public let object: String?
    public let bytes: Int?
    public let createdAt: Int?
    public let filename: String?
    public let purpose: String?
    
    public init(
        id: String? = nil,
        object: String? = nil,
        bytes: Int? = nil,
        createdAt: Int? = nil,
        filename: String? = nil,
        purpose: String? = nil
    ) {
        self.id = id
        self.object = object
        self.bytes = bytes
        self.createdAt = createdAt
        self.filename = filename
        self.purpose = purpose
    }
    
    enum CodingKeys: String, CodingKey {
        case id, object, bytes, filename, purpose
        case createdAt = "created_at"
    }
}

/// Generated file list response model
public struct GeneratedFileListResponse: Codable, Equatable {
    public let object: String?
    public let data: [GeneratedFileResponse]?
    
    public init(object: String? = nil, data: [GeneratedFileResponse]? = nil) {
        self.object = object
        self.data = data
    }
}

/// Generated delete response model
public struct GeneratedDeleteResponse: Codable, Equatable {
    public let id: String?
    public let object: String?
    public let deleted: Bool?
    
    public init(id: String? = nil, object: String? = nil, deleted: Bool? = nil) {
        self.id = id
        self.object = object
        self.deleted = deleted
    }
}

/// Generated token usage model
public struct GeneratedTokenUsage: Codable, Equatable {
    public let promptTokens: Int?
    public let totalTokens: Int?
    
    public init(promptTokens: Int? = nil, totalTokens: Int? = nil) {
        self.promptTokens = promptTokens
        self.totalTokens = totalTokens
    }
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case totalTokens = "total_tokens"
    }
}