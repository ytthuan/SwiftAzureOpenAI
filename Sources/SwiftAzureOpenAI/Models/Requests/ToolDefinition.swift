import Foundation

/// Definition of a tool/function that the model can call.
public struct ToolDefinition: Codable, Equatable {
    public let type: String
    public let name: String?
    public let description: String?
    public let parameters: JSONValue?

    public init(type: String, name: String? = nil, description: String? = nil, parameters: JSONValue? = nil) {
        self.type = type
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

