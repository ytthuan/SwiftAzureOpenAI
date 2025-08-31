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
        // Handle different types of Azure OpenAI SSE events
        switch event.type {
        case "response.function_call_arguments.delta":
            // Handle delta events - these contain incremental text content
            guard let delta = event.delta else { return nil }
            
            let content = SAOAIStreamingContent(type: "function_call_arguments", text: delta, index: event.outputIndex ?? 0)
            let output = SAOAIStreamingOutput(content: [content], role: "assistant")
            
            return SAOAIStreamingResponse(
                id: event.itemId, // Use item_id for delta events
                model: nil,
                created: nil,
                output: [output],
                usage: nil
            )
            
        case "response.text.delta":
            // Handle text delta events
            guard let delta = event.delta else { return nil }
            
            let content = SAOAIStreamingContent(type: "text", text: delta, index: event.outputIndex ?? 0)
            let output = SAOAIStreamingOutput(content: [content], role: "assistant")
            
            return SAOAIStreamingResponse(
                id: event.itemId,
                model: nil,
                created: nil,
                output: [output],
                usage: nil
            )
            
        case "response.created", "response.in_progress", "response.completed":
            // Handle events that contain complete response data
            guard let response = event.response else {
                return nil
            }
            
            // Map Azure OpenAI event response to streaming response format
            let streamingOutput = convertAzureOutputToStreamingOutput(response.output)
            
            return SAOAIStreamingResponse(
                id: response.id,
                model: response.model,
                created: response.createdAt,
                output: streamingOutput,
                usage: response.usage
            )
            
        case "response.output_item.added", "response.output_item.done":
            // Handle item events
            guard let item = event.item else { return nil }
            
            // Create content based on item type
            let content: SAOAIStreamingContent
            if item.type == "function_call", let name = item.name {
                content = SAOAIStreamingContent(type: "function_call", text: "Function call: \(name)", index: 0)
            } else if item.type == "reasoning" {
                content = SAOAIStreamingContent(type: "reasoning", text: "Reasoning step", index: 0)
            } else {
                return nil
            }
            
            let output = SAOAIStreamingOutput(content: [content], role: "assistant")
            
            return SAOAIStreamingResponse(
                id: item.id,
                model: nil,
                created: nil,
                output: [output],
                usage: nil
            )
            
        default:
            // Skip unknown event types
            return nil
        }
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