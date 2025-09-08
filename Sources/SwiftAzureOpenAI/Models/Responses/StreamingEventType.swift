import Foundation

/// Enumeration of streaming event types from OpenAI Response API
/// Based on official OpenAI documentation: https://platform.openai.com/docs/api-reference/responses-streaming
public enum SAOAIStreamingEventType: String, CaseIterable, Codable, Sendable {
    
    // MARK: - Response Lifecycle Events
    case responseCreated = "response.created"
    case responseInProgress = "response.in_progress"
    case responseCompleted = "response.completed"
    
    // MARK: - Output Item Events
    case responseOutputItemAdded = "response.output_item.added"
    case responseOutputItemInProgress = "response.output_item.in_progress"
    case responseOutputItemCompleted = "response.output_item.completed"
    case responseOutputItemDone = "response.output_item.done"
    
    // MARK: - Content Part Events
    case responseContentPartAdded = "response.content_part.added"
    case responseContentPartInProgress = "response.content_part.in_progress"
    case responseContentPartCompleted = "response.content_part.completed"
    
    // MARK: - Delta Events (streaming content)
    case responseFunctionCallArgumentsDelta = "response.function_call_arguments.delta"
    case responseTextDelta = "response.text.delta"
    case responseOutputTextDelta = "response.output_text.delta"
    case responseAudioDelta = "response.audio.delta"
    case responseAudioTranscriptDelta = "response.audio_transcript.delta"
    case responseCodeInterpreterCallCodeDelta = "response.code_interpreter_call_code.delta"
    case responseRefusalDelta = "response.refusal.delta"
    case responseReasoningDelta = "response.reasoning.delta"
    case responseReasoningSummaryDelta = "response.reasoning_summary.delta"
    case responseReasoningSummaryTextDelta = "response.reasoning_summary_text.delta"
    case responseMcpCallArgumentsDelta = "response.mcp_call.arguments_delta"
    
    // MARK: - Done Events (completion markers)
    case responseFunctionCallArgumentsDone = "response.function_call_arguments.done"
    case responseTextDone = "response.text.done"
    case responseOutputTextDone = "response.output_text.done"
    case responseAudioDone = "response.audio.done"
    case responseAudioTranscriptDone = "response.audio_transcript.done"
    case responseCodeInterpreterCallCodeDone = "response.code_interpreter_call_code.done"
    case responseRefusalDone = "response.refusal.done"
    case responseReasoningDone = "response.reasoning.done"
    case responseReasoningSummaryDone = "response.reasoning_summary.done"
    case responseReasoningSummaryTextDone = "response.reasoning_summary_text.done"
    case responseMcpCallArgumentsDone = "response.mcp_call.arguments_done"
    
    // MARK: - Tool Call Events
    case responseFileSearchCallCreated = "response.file_search_call.created"
    case responseFileSearchCallInProgress = "response.file_search_call.in_progress"
    case responseFileSearchCallCompleted = "response.file_search_call.completed"
    case responseCodeInterpreterCallCreated = "response.code_interpreter_call.created"
    case responseCodeInterpreterCallInProgress = "response.code_interpreter_call.in_progress"
    case responseCodeInterpreterCallCompleted = "response.code_interpreter_call.completed"
    case responseFunctionCallCreated = "response.function_call.created"
    case responseFunctionCallInProgress = "response.function_call.in_progress"
    case responseFunctionCallCompleted = "response.function_call.completed"
    case responseMcpCallCreated = "response.mcp_call.created"
    case responseMcpCallInProgress = "response.mcp_call.in_progress"
    case responseMcpCallCompleted = "response.mcp_call.completed"
    case responseCallToolResultAdded = "response.call_tool.result.added"
    case responseCallToolResultInProgress = "response.call_tool.result.in_progress"
    case responseCallToolResultCompleted = "response.call_tool.result.completed"
    case responseFileSearchCallResultAdded = "response.file_search_call.result.added"
    case responseFileSearchCallResultInProgress = "response.file_search_call.result.in_progress"
    case responseFileSearchCallResultCompleted = "response.file_search_call.result.completed"
    case responseCodeInterpreterCallResultAdded = "response.code_interpreter_call.result.added"
    case responseCodeInterpreterCallResultInProgress = "response.code_interpreter_call.result.in_progress"
    case responseCodeInterpreterCallResultCompleted = "response.code_interpreter_call.result.completed"
    
    // MARK: - Annotation Events
    case responseOutputTextAnnotationAdded = "response.output_text.annotation.added"
    
    // MARK: - Specialized Events
    case responseQueued = "response.queued"
    case responseReasoningSummaryPartAdded = "response.reasoning_summary_part.added"
    case responseReasoningSummaryPartDone = "response.reasoning_summary_part.done"
    
    // MARK: - Error Events
    case error = "error"
    case responseError = "response.error"
    case responseIncomplete = "response.incomplete"
    
    // MARK: - Helper Properties
    
    /// Whether this is a delta event (streaming incremental content)
    public var isDelta: Bool {
        return rawValue.contains(".delta")
    }
    
    /// Whether this is a done event (completion marker)
    public var isDone: Bool {
        return rawValue.contains(".done")
    }
    
    /// Whether this is a tool call related event
    public var isToolCall: Bool {
        return rawValue.contains("_call")
    }
    
    /// Whether this is an error event
    public var isError: Bool {
        switch self {
        case .error, .responseError, .responseIncomplete:
            return true
        default:
            return false
        }
    }
    
    /// Whether this is a lifecycle event (created, in_progress, completed)
    public var isLifecycle: Bool {
        switch self {
        case .responseCreated, .responseInProgress, .responseCompleted:
            return true
        default:
            return false
        }
    }
}

/// Enumeration of item types that can appear in streaming events
public enum SAOAIStreamingItemType: String, CaseIterable, Codable, Sendable {
    case message = "message"
    case codeInterpreterCall = "code_interpreter_call"
    case functionCall = "function_call"
    case fileSearchCall = "file_search_call"
    case mcpCall = "mcp_call"
    
    /// Human-readable description of the item type
    public var description: String {
        switch self {
        case .message:
            return "Message"
        case .codeInterpreterCall:
            return "Code Interpreter Call"
        case .functionCall:
            return "Function Call"
        case .fileSearchCall:
            return "File Search Call"
        case .mcpCall:
            return "MCP Call"
        }
    }
}