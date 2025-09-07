import Foundation

/// Parser for OpenAI/Azure OpenAI Server-Sent Events (SSE) streaming format
public final class SSEParser: Sendable {
    
    /// Parse SSE data chunks and extract JSON payload
    public static func parseSSEChunk(_ data: Data) throws -> SAOAIStreamingResponse? {
        guard let string = String(data: data, encoding: .utf8) else {
            throw SAOAIError.decodingError(NSError(domain: "SSEParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 data"]))
        }
        
        let lines = string.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for completion signal
            if trimmedLine == "data: [DONE]" {
                return nil // Signals completion
            }
            
            // Parse data lines
            if trimmedLine.hasPrefix("data: ") {
                let jsonString = String(trimmedLine.dropFirst(6)) // Remove "data: " prefix
                
                // Skip empty data lines
                if jsonString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continue
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    continue
                }
                
                do {
                    let decoder = JSONDecoder()
                    
                    // First try to parse as Azure OpenAI event format
                    if let azureEvent = try? decoder.decode(AzureOpenAISSEEvent.self, from: jsonData) {
                        // Convert Azure OpenAI event to streaming response
                        return convertAzureEventToStreamingResponse(azureEvent)
                    }
                    
                    // Fallback to direct streaming response format (for backward compatibility)
                    let response = try decoder.decode(SAOAIStreamingResponse.self, from: jsonData)
                    return response
                } catch {
                    // Skip malformed JSON chunks
                    continue
                }
            }
        }
        
        return nil
    }
    
    /// Convert Azure OpenAI SSE event to streaming response format
    private static func convertAzureEventToStreamingResponse(_ event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        // Handle different types of Azure OpenAI SSE events based on official OpenAI Response API documentation
        switch event.type {
        
        // MARK: - Delta Events (streaming content)
        case "response.function_call_arguments.delta":
            return handleDeltaEvent(event: event, contentType: "function_call_arguments")
            
        case "response.text.delta", "response.output_text.delta":
            return handleDeltaEvent(event: event, contentType: "text")
            
        case "response.audio.delta":
            return handleDeltaEvent(event: event, contentType: "audio")
            
        case "response.audio_transcript.delta":
            return handleDeltaEvent(event: event, contentType: "audio_transcript")
            
        case "response.code_interpreter_call_code.delta":
            return handleDeltaEvent(event: event, contentType: "code_interpreter_code")
            
        case "response.refusal.delta":
            return handleDeltaEvent(event: event, contentType: "refusal")
            
        case "response.reasoning.delta":
            return handleDeltaEvent(event: event, contentType: "reasoning")
            
        case "response.reasoning_summary.delta":
            return handleDeltaEvent(event: event, contentType: "reasoning_summary")
            
        case "response.reasoning_summary_text.delta":
            return handleDeltaEvent(event: event, contentType: "reasoning_summary_text")
            
        case "response.mcp_call.arguments_delta":
            return handleDeltaEvent(event: event, contentType: "mcp_call_arguments")
            
        // MARK: - Done Events (completion markers)
        case "response.function_call_arguments.done":
            return handleDoneEvent(event: event, contentType: "function_call_arguments")
            
        case "response.text.done", "response.output_text.done":
            return handleDoneEvent(event: event, contentType: "text")
            
        case "response.audio.done":
            return handleDoneEvent(event: event, contentType: "audio")
            
        case "response.audio_transcript.done":
            return handleDoneEvent(event: event, contentType: "audio_transcript")
            
        case "response.code_interpreter_call_code.done":
            return handleDoneEvent(event: event, contentType: "code_interpreter_code")
            
        case "response.refusal.done":
            return handleDoneEvent(event: event, contentType: "refusal")
            
        case "response.reasoning.done":
            return handleDoneEvent(event: event, contentType: "reasoning")
            
        case "response.reasoning_summary.done":
            return handleDoneEvent(event: event, contentType: "reasoning_summary")
            
        case "response.reasoning_summary_text.done":
            return handleDoneEvent(event: event, contentType: "reasoning_summary_text")
            
        case "response.mcp_call.arguments_done":
            return handleDoneEvent(event: event, contentType: "mcp_call_arguments")
            
        // MARK: - Response Lifecycle Events
        case "response.created", "response.in_progress", "response.completed":
            return handleResponseLifecycleEvent(event: event)
            
        case "response.failed", "response.incomplete":
            return handleResponseFailureEvent(event: event)
            
        case "response.queued":
            return handleResponseQueuedEvent(event: event)
            
        // MARK: - Content Part Events
        case "response.content_part.added":
            return handleContentPartAddedEvent(event: event)
            
        case "response.content_part.done":
            return handleContentPartDoneEvent(event: event)
            
        // MARK: - Output Item Events
        case "response.output_item.added", "response.output_item.done":
            return handleOutputItemEvent(event: event)
            
        // MARK: - Tool Call Events
        case "response.file_search_call.searching", "response.file_search_call.in_progress", "response.file_search_call.completed":
            return handleToolCallEvent(event: event, toolType: "file_search")
            
        case "response.code_interpreter_call.interpreting", "response.code_interpreter_call.in_progress", "response.code_interpreter_call.completed":
            return handleToolCallEvent(event: event, toolType: "code_interpreter")
            
        case "response.web_search_call.searching", "response.web_search_call.in_progress", "response.web_search_call.completed":
            return handleToolCallEvent(event: event, toolType: "web_search")
            
        case "response.image_generation_call.generating", "response.image_generation_call.in_progress", "response.image_generation_call.completed", "response.image_generation_call.partial_image":
            return handleToolCallEvent(event: event, toolType: "image_generation")
            
        case "response.mcp_call.in_progress", "response.mcp_call.completed", "response.mcp_call.failed":
            return handleToolCallEvent(event: event, toolType: "mcp_call")
            
        case "response.mcp_list_tools.in_progress", "response.mcp_list_tools.completed", "response.mcp_list_tools.failed":
            return handleToolCallEvent(event: event, toolType: "mcp_list_tools")
            
        // MARK: - Annotation Events  
        case "response.output_text.annotation.added":
            return handleAnnotationEvent(event: event)
            
        case "response.reasoning_summary_part.added", "response.reasoning_summary_part.done":
            return handleReasoningSummaryPartEvent(event: event)
            
        // MARK: - Error Events
        case "error":
            return handleErrorEvent(event: event)
            
        default:
            // Skip unknown event types - log for debugging but don't fail
            return nil
        }
    }
    
    // MARK: - Event Handler Methods
    
    /// Handle delta events containing incremental streaming content
    private static func handleDeltaEvent(event: AzureOpenAISSEEvent, contentType: String) -> SAOAIStreamingResponse? {
        guard let delta = event.delta else { return nil }
        
        let content = SAOAIStreamingContent(type: contentType, text: delta, index: event.outputIndex ?? 0)
        let output = SAOAIStreamingOutput(content: [content], role: "assistant")
        
        // Convert event type to enum
        let eventType = SAOAIStreamingEventType(rawValue: event.type)
        
        // Convert item if present
        let item = event.item.map { SAOAIStreamingItem(from: $0) }
        
        return SAOAIStreamingResponse(
            id: event.itemId, // Use item_id for delta events
            model: nil,
            created: nil,
            output: [output],
            usage: nil,
            eventType: eventType,
            item: item
        )
    }
    
    /// Handle done events indicating completion of streaming content
    private static func handleDoneEvent(event: AzureOpenAISSEEvent, contentType: String) -> SAOAIStreamingResponse? {
        // For done events, use arguments if available, otherwise use empty text to avoid displaying "[DONE]" to users
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
    
    /// Handle response lifecycle events (created, in_progress, completed)
    private static func handleResponseLifecycleEvent(event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
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
    
    /// Handle response failure events
    private static func handleResponseFailureEvent(event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        guard let response = event.response else { return nil }
        
        let content = SAOAIStreamingContent(type: "error", text: "Response \(event.type)", index: 0)
        let output = SAOAIStreamingOutput(content: [content], role: "assistant")
        
        return SAOAIStreamingResponse(
            id: response.id,
            model: response.model,
            created: response.createdAt,
            output: [output],
            usage: response.usage
        )
    }
    
    /// Handle response queued events
    private static func handleResponseQueuedEvent(event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        guard let response = event.response else { return nil }
        
        let content = SAOAIStreamingContent(type: "status", text: "Response queued", index: 0)
        let output = SAOAIStreamingOutput(content: [content], role: "assistant")
        
        // Convert event type to enum
        let eventType = SAOAIStreamingEventType(rawValue: event.type)
        
        // Convert item if present
        let item = event.item.map { SAOAIStreamingItem(from: $0) }
        
        return SAOAIStreamingResponse(
            id: response.id,
            model: response.model,
            created: response.createdAt,
            output: [output],
            usage: response.usage,
            eventType: eventType,
            item: item
        )
    }
    
    /// Handle content part events
    private static func handleContentPartAddedEvent(event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        // Content part added is a status event - create response without user-visible text
        let content = SAOAIStreamingContent(type: "status", text: "", index: event.outputIndex ?? 0)
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
    
    /// Handle content part done events
    private static func handleContentPartDoneEvent(event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        // Content part done is a status event - create response without user-visible text
        let content = SAOAIStreamingContent(type: "status", text: "", index: event.outputIndex ?? 0)
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
    
    /// Handle output item events
    private static func handleOutputItemEvent(event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        guard let item = event.item else { return nil }
        
        // Create content based on item type
        let content: SAOAIStreamingContent
        if item.type == "function_call", let name = item.name {
            content = SAOAIStreamingContent(type: "function_call", text: "Function call: \(name)", index: 0)
        } else if item.type == "reasoning" {
            // Keep reasoning content but without debug text
            content = SAOAIStreamingContent(type: "reasoning", text: "", index: 0)
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
    
    /// Handle tool call events (file search, code interpreter, etc.)
    private static func handleToolCallEvent(event: AzureOpenAISSEEvent, toolType: String) -> SAOAIStreamingResponse? {
        let statusText = event.type.components(separatedBy: ".").last ?? "in_progress"
        let content = SAOAIStreamingContent(type: toolType, text: "\(toolType.capitalized): \(statusText)", index: event.outputIndex ?? 0)
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
    
    /// Handle annotation events
    private static func handleAnnotationEvent(event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        let content = SAOAIStreamingContent(type: "annotation", text: "Text annotation added", index: event.outputIndex ?? 0)
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
    
    /// Handle reasoning summary part events
    private static func handleReasoningSummaryPartEvent(event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        let statusText = event.type.contains("added") ? "added" : "done"
        let content = SAOAIStreamingContent(type: "reasoning_summary_part", text: "Reasoning summary part \(statusText)", index: event.outputIndex ?? 0)
        let output = SAOAIStreamingOutput(content: [content], role: "assistant")
        
        return SAOAIStreamingResponse(
            id: event.itemId,
            model: nil,
            created: nil,
            output: [output],
            usage: nil
        )
    }
    
    /// Handle error events
    private static func handleErrorEvent(event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        // For error events, create an error response
        let content = SAOAIStreamingContent(type: "error", text: "Error occurred", index: 0)
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
    
    /// Convert Azure OpenAI output to streaming output format
    private static func convertAzureOutputToStreamingOutput(_ azureOutput: [AzureOpenAIEventOutput]?) -> [SAOAIStreamingOutput]? {
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
    
    /// Check if SSE chunk indicates completion
    public static func isCompletionChunk(_ data: Data) -> Bool {
        guard let string = String(data: data, encoding: .utf8) else {
            return false
        }
        
        return string.trimmingCharacters(in: .whitespacesAndNewlines).contains("data: [DONE]")
    }
}