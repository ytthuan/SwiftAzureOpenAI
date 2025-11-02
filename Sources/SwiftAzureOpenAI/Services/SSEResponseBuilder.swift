import Foundation

/// Shared utility for building SSE streaming responses
/// Eliminates code duplication between SSEParser and OptimizedSSEParser
public struct SSEResponseBuilder: Sendable {
    
    public init() {}
    
    /// Create a delta response for streaming content
    public func createDeltaResponse(
        event: AzureOpenAISSEEvent,
        contentType: String
    ) -> SAOAIStreamingResponse? {
        guard let delta = event.delta else { return nil }
        
        let content = SAOAIStreamingContent(type: contentType, text: delta, index: event.outputIndex ?? 0)
        let output = SAOAIStreamingOutput(content: [content], role: "assistant")
        
        // Convert event type to enum
        let eventType = SAOAIStreamingEventType(rawValue: event.type)
        
        // Convert item if present, or create minimal item from itemId for delta events
        let item: SAOAIStreamingItem? = {
            if let eventItem = event.item {
                return SAOAIStreamingItem(from: eventItem)
            } else if let itemId = event.itemId {
                // Create minimal streaming item for delta events that only have itemId
                return SAOAIStreamingItem(
                    type: nil,
                    id: itemId,
                    status: nil,
                    arguments: nil,
                    callId: nil,
                    name: nil,
                    summary: nil,
                    containerId: nil
                )
            } else {
                return nil
            }
        }()
        
        return SAOAIStreamingResponse(
            id: event.itemId,
            model: nil,
            created: nil,
            output: [output],
            usage: nil,
            eventType: eventType,
            item: item
        )
    }
    
    /// Create a done response indicating completion of streaming content
    public func createDoneResponse(
        event: AzureOpenAISSEEvent,
        contentType: String
    ) -> SAOAIStreamingResponse? {
        // For done events, use arguments if available, otherwise use empty text
        let finalContent = event.arguments ?? ""
        
        let content = SAOAIStreamingContent(type: contentType, text: finalContent, index: event.outputIndex ?? 0)
        let output = SAOAIStreamingOutput(content: [content], role: "assistant")
        
        // Convert event type to enum
        let eventType = SAOAIStreamingEventType(rawValue: event.type)
        
        // Convert item if present
        let item = event.item.map { SAOAIStreamingItem(from: $0) }
        
        return SAOAIStreamingResponse(
            id: event.itemId,
            model: nil,
            created: nil,
            output: [output],
            usage: nil,
            eventType: eventType,
            item: item
        )
    }
    
    /// Create a lifecycle response (created, in_progress, completed)
    public func createLifecycleResponse(
        event: AzureOpenAISSEEvent
    ) -> SAOAIStreamingResponse? {
        guard let response = event.response else { return nil }
        
        let streamingOutput = convertAzureOutputToStreamingOutput(response.output)
        
        // Convert event type to enum
        let eventType = SAOAIStreamingEventType(rawValue: event.type)
        
        // Convert item if present
        let item = event.item.map { SAOAIStreamingItem(from: $0) }
        
        return SAOAIStreamingResponse(
            id: response.id,
            model: response.model,
            created: response.createdAt,
            output: streamingOutput,
            usage: response.usage,
            eventType: eventType,
            item: item
        )
    }
    
    /// Create an output item response
    public func createOutputItemResponse(
        event: AzureOpenAISSEEvent
    ) -> SAOAIStreamingResponse? {
        guard let item = event.item else { return nil }
        
        // Create content based on item type
        let content: SAOAIStreamingContent
        if item.type == "function_call" {
            // For function call items, don't create text content as this should be handled by event processing
            content = SAOAIStreamingContent(type: "status", text: "", index: 0)
        } else if item.type == "reasoning" {
            // Keep reasoning content but without debug text
            content = SAOAIStreamingContent(type: "reasoning", text: "", index: 0)
        } else if item.type == "code_interpreter_call" {
            // Enhanced code interpreter status tracking
            let statusText = event.type == "response.output_item.added" ? "Code interpreter started" : "Code interpreter completed"
            content = SAOAIStreamingContent(type: "code_interpreter_status", text: statusText, index: 0)
        } else if event.type == "response.output_item.added" || event.type == "response.output_item.done" {
            // For pure status events like added/done, create status content with empty text
            content = SAOAIStreamingContent(type: "status", text: "", index: 0)
        } else {
            // For other item types, preserve the type but with empty text
            content = SAOAIStreamingContent(type: item.type ?? "output_item", text: "", index: 0)
        }
        
        let output = SAOAIStreamingOutput(content: [content], role: "assistant")
        
        // Convert event type to enum
        let eventType = SAOAIStreamingEventType(rawValue: event.type)
        
        // Convert item
        let streamingItem = SAOAIStreamingItem(from: item)
        
        return SAOAIStreamingResponse(
            id: item.id,
            model: nil,
            created: nil,
            output: [output],
            usage: nil,
            eventType: eventType,
            item: streamingItem
        )
    }
    
    /// Create a reasoning summary part response
    public func createReasoningSummaryPartResponse(
        event: AzureOpenAISSEEvent
    ) -> SAOAIStreamingResponse? {
        let statusText = event.type.contains("added") ? "added" : "done"
        let content = SAOAIStreamingContent(type: "reasoning_summary_part", text: "Reasoning summary part \(statusText)", index: event.outputIndex ?? 0)
        let output = SAOAIStreamingOutput(content: [content], role: "assistant")
        
        let eventType = SAOAIStreamingEventType(rawValue: event.type)
        let item = event.item.map { SAOAIStreamingItem(from: $0) }
        
        return SAOAIStreamingResponse(
            id: event.itemId,
            model: nil,
            created: nil,
            output: [output],
            usage: nil,
            eventType: eventType,
            item: item
        )
    }
    
    // MARK: - Private Helper Methods
    
    /// Convert Azure OpenAI output to streaming output format
    private func convertAzureOutputToStreamingOutput(_ azureOutput: [AzureOpenAIEventOutput]?) -> [SAOAIStreamingOutput]? {
        guard let azureOutput = azureOutput, !azureOutput.isEmpty else {
            return nil
        }
        
        return azureOutput.compactMap { output in
            // For function calls, create content with the function call data
            if output.type == "function_call", let name = output.name {
                let functionCallText = "Function call: \(name)"
                let content = SAOAIStreamingContent(type: "function_call", text: functionCallText, index: 0)
                return SAOAIStreamingOutput(content: [content], role: "assistant")
            }
            
            // For reasoning outputs, create content with reasoning indicator
            if output.type == "reasoning" {
                let reasoningText = "Reasoning step"
                let content = SAOAIStreamingContent(type: "reasoning", text: reasoningText, index: 0)
                return SAOAIStreamingOutput(content: [content], role: "assistant")
            }
            
            return nil
        }
    }
}
