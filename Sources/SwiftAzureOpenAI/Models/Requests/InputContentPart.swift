import Foundation

/// Supported input content parts for the Responses API.
public enum SAOAIInputContent: Codable, Equatable {
    case inputText(InputText)
    case inputImage(InputImage)
    case functionCallOutput(FunctionCallOutput)

    /// Text content input.
    public struct InputText: Codable, Equatable {
        public let type: String = "input_text"
        public let text: String

        enum CodingKeys: String, CodingKey {
            case type
            case text
        }

        public init(text: String) {
            self.text = text
        }
    }

    /// Image content input by URL.
    public struct InputImage: Codable, Equatable {
        public let type: String = "input_image"
        public let imageURL: String

        enum CodingKeys: String, CodingKey {
            case type
            case imageURL = "image_url"
        }

        public init(imageURL: String) {
            self.imageURL = imageURL
        }
        
        /// Create an InputImage with a base64-encoded image
        public init(base64Data: String, mimeType: String = "image/jpeg") {
            self.imageURL = "data:\(mimeType);base64,\(base64Data)"
        }
    }

    /// Function call output result.
    public struct FunctionCallOutput: Codable, Equatable {
        public let type: String = "function_call_output"
        public let callId: String
        public let output: String

        enum CodingKeys: String, CodingKey {
            case type
            case callId = "call_id"
            case output
        }

        public init(callId: String, output: String) {
            self.callId = callId
            self.output = output
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "input_text":
            self = .inputText(try InputText(from: decoder))
        case "input_image":
            self = .inputImage(try InputImage(from: decoder))
        case "function_call_output":
            self = .functionCallOutput(try FunctionCallOutput(from: decoder))
        default:
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported input content type: \(type)")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .inputText(let value):
            try value.encode(to: encoder)
        case .inputImage(let value):
            try value.encode(to: encoder)
        case .functionCallOutput(let value):
            try value.encode(to: encoder)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }
}

