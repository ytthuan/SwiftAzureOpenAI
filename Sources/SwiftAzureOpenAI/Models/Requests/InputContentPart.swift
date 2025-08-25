import Foundation

/// Supported input content parts for the Responses API.
public enum InputContentPart: Codable, Equatable {
    case inputText(InputText)
    case inputImage(InputImage)

    /// Text content input.
    public struct InputText: Codable, Equatable {
        public let type: String = "input_text"
        public let text: String

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
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "input_text":
            self = .inputText(try InputText(from: decoder))
        case "input_image":
            self = .inputImage(try InputImage(from: decoder))
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
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }
}

