import Foundation

/// Represents an item from a streaming event that provides additional context
/// This allows users to access item.type and other properties for branching logic
public struct SAOAIStreamingItem: Codable, Equatable, Sendable {
    /// The type of the item (message, function_call, code_interpreter_call, etc.)
    public let type: SAOAIStreamingItemType?
    
    /// The unique identifier of the item
    public let id: String?
    
    /// The status of the item (e.g., "in_progress", "completed")
    public let status: String?
    
    /// Arguments for function calls or code interpreter calls
    public let arguments: String?
    
    /// Call ID for tool calls
    public let callId: String?
    
    /// Name of the function being called
    public let name: String?
    
    /// Summary information (for reasoning summaries)
    public let summary: [String]?
    
    /// Container ID for code interpreter calls
    public let containerId: String?
    
    public init(
        type: SAOAIStreamingItemType?,
        id: String?,
        status: String?,
        arguments: String?,
        callId: String?,
        name: String?,
        summary: [String]?,
        containerId: String? = nil
    ) {
        self.type = type
        self.id = id
        self.status = status
        self.arguments = arguments
        self.callId = callId
        self.name = name
        self.summary = summary
        self.containerId = containerId
    }
    
    /// Initialize from AzureOpenAIEventItem
    internal init(from azureItem: AzureOpenAIEventItem) {
        self.type = azureItem.type.flatMap { SAOAIStreamingItemType(rawValue: $0) }
        self.id = azureItem.id
        self.status = azureItem.status
        self.arguments = azureItem.arguments
        self.callId = azureItem.callId
        self.name = azureItem.name
        self.summary = azureItem.summary
        self.containerId = azureItem.containerId
    }
    
    /// Initialize from AzureOpenAIEventOutput
    internal init(from azureOutput: AzureOpenAIEventOutput) {
        self.type = azureOutput.type.flatMap { SAOAIStreamingItemType(rawValue: $0) }
        self.id = azureOutput.id
        self.status = azureOutput.status
        self.arguments = azureOutput.arguments
        self.callId = azureOutput.callId
        self.name = azureOutput.name
        self.summary = azureOutput.summary
        self.containerId = azureOutput.containerId
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case status
        case arguments
        case callId = "call_id"
        case name
        case summary
        case containerId = "container_id"
    }
}