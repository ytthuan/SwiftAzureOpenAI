import Foundation

/// Definition of a tool/function that the model can call.
public struct SAOAITool: Codable, Equatable, Sendable {
    public let type: String
    public let name: String?
    public let description: String?
    public let parameters: SAOAIJSONValue?
    public let container: SAOAIJSONValue?

    public init(type: String, name: String? = nil, description: String? = nil, parameters: SAOAIJSONValue? = nil, container: SAOAIJSONValue? = nil) {
        self.type = type
        self.name = name
        self.description = description
        self.parameters = parameters
        self.container = container
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
    
    /// Create a code interpreter tool (Python-style convenience)
    public static func codeInterpreter() -> SAOAITool {
        return SAOAITool(
            type: "code_interpreter",
            container: .object(["type": .string("auto")])
        )
    }
}

