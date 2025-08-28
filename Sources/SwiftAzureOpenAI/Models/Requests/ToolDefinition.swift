import Foundation

/// Definition of a tool/function that the model can call.
public struct SAOAITool: Codable, Equatable {
    public let type: String
    public let name: String?
    public let description: String?
    public let parameters: SAOAIJSONValue?

    public init(type: String, name: String? = nil, description: String? = nil, parameters: SAOAIJSONValue? = nil) {
        self.type = type
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

// MARK: - Backward Compatibility
@available(*, deprecated, renamed: "SAOAITool")
public typealias ToolDefinition = SAOAITool

