import Foundation

/// Output content parts produced by the Responses API.
public enum SAOAIOutputContent: Codable, Equatable {
    case outputText(OutputText)
    case functionCall(FunctionCall)

    /// Text content output.
    public struct OutputText: Codable, Equatable {
        public let type: String = "output_text"
        public let text: String

        enum CodingKeys: String, CodingKey {
            case type
            case text
        }

        public init(text: String) {
            self.text = text
        }
    }

    /// Function call output.
    public struct FunctionCall: Codable, Equatable {
        public let type: String = "function_call"
        public let callId: String
        public let name: String
        public let arguments: String

        enum CodingKeys: String, CodingKey {
            case type
            case callId = "call_id"
            case name
            case arguments
        }

        public init(callId: String, name: String, arguments: String) {
            self.callId = callId
            self.name = name
            self.arguments = arguments
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "output_text":
            self = .outputText(try OutputText(from: decoder))
        case "function_call":
            self = .functionCall(try FunctionCall(from: decoder))
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
        case .functionCall(let value):
            try value.encode(to: encoder)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }
}

