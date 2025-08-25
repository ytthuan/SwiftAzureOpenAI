import Foundation

/// Output content parts produced by the Responses API.
public enum OutputContentPart: Codable, Equatable {
    case outputText(OutputText)

    /// Text content output.
    public struct OutputText: Codable, Equatable {
        public let type: String = "output_text"
        public let text: String

        public init(text: String) {
            self.text = text
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "output_text":
            self = .outputText(try OutputText(from: decoder))
        default:
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported output content type: \(type)")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .outputText(let value):
            try value.encode(to: encoder)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }
}

