import Foundation

/// Azure OpenAI SSE Event models for the Response API
/// These models handle the event-based SSE format used by Azure OpenAI Response API

/// Base structure for all Azure OpenAI SSE events
public struct AzureOpenAISSEEvent: Codable, Sendable {
    public let type: String
    public let sequenceNumber: Int?
    public let response: AzureOpenAIEventResponse?
    public let outputIndex: Int?
    public let item: AzureOpenAIEventItem?
    public let itemId: String?
    public let delta: String?
    public let arguments: String?
    
    public init(
        type: String,
        sequenceNumber: Int? = nil,
        response: AzureOpenAIEventResponse? = nil,
        outputIndex: Int? = nil,
        item: AzureOpenAIEventItem? = nil,
        itemId: String? = nil,
        delta: String? = nil,
        arguments: String? = nil
    ) {
        self.type = type
        self.sequenceNumber = sequenceNumber
        self.response = response
        self.outputIndex = outputIndex
        self.item = item
        self.itemId = itemId
        self.delta = delta
        self.arguments = arguments
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case sequenceNumber = "sequence_number"
        case response
        case outputIndex = "output_index"
        case item
        case itemId = "item_id"
        case delta
        case arguments
    }
}

/// Response object within Azure OpenAI SSE events
public struct AzureOpenAIEventResponse: Codable, Sendable {
    public let id: String?
    public let object: String?
    public let createdAt: Int?
    public let status: String?
    public let model: String?
    public let output: [AzureOpenAIEventOutput]?
    public let usage: SAOAITokenUsage?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case object
        case createdAt = "created_at"
        case status
        case model
        case output
        case usage
    }
}

/// Output item within Azure OpenAI SSE events
public struct AzureOpenAIEventItem: Codable, Sendable {
    public let id: String?
    public let type: String?
    public let status: String?
    public let arguments: String?
    public let callId: String?
    public let name: String?
    public let summary: [String]?
    public let containerId: String?
    
    public init(
        id: String? = nil,
        type: String? = nil,
        status: String? = nil,
        arguments: String? = nil,
        callId: String? = nil,
        name: String? = nil,
        summary: [String]? = nil,
        containerId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.status = status
        self.arguments = arguments
        self.callId = callId
        self.name = name
        self.summary = summary
        self.containerId = containerId
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case status
        case arguments
        case callId = "call_id"
        case name
        case summary
        case containerId = "container_id"
    }
}

/// Output structure within event response
public struct AzureOpenAIEventOutput: Codable, Sendable {
    public let id: String?
    public let type: String?
    public let status: String?
    public let arguments: String?
    public let callId: String?
    public let name: String?
    public let summary: [String]?
    public let containerId: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case status
        case arguments
        case callId = "call_id"
        case name
        case summary
        case containerId = "container_id"
    }
}