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
    
    /// Create a function tool (Python-style convenience)
    public static func function(
        name: String,
        description: String,
        parameters: SAOAIJSONValue
    ) -> SAOAITool {
        return SAOAITool(
            type: "function",
            name: name,
            description: description,
            parameters: parameters
        )
    }
}

