import Foundation

// MARK: - Lightweight JSON value representation

public enum SAOAIJSONValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: SAOAIJSONValue])
    case array([SAOAIJSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let object = try? container.decode([String: SAOAIJSONValue].self) {
            self = .object(object)
        } else if let array = try? container.decode([SAOAIJSONValue].self) {
            self = .array(array)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let dict):
            try container.encode(dict)
        case .array(let values):
            try container.encode(values)
        case .null:
            try container.encodeNil()
        }
    }
}

// MARK: - Backward Compatibility
@available(*, deprecated, renamed: "SAOAIJSONValue")
public typealias JSONValue = SAOAIJSONValue

