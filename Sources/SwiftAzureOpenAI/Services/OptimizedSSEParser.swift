import Foundation

/// High-performance SSE parser optimized for streaming performance
/// Uses byte-level parsing and buffer pooling to minimize allocations
public final class OptimizedSSEParser: Sendable {
    
    // MARK: - Buffer Pool for Memory Optimization
    
    /// Thread-safe buffer pool to reuse Data instances and reduce allocations
    private static let bufferPool = BufferPool()
    
    /// Buffer pool implementation for memory optimization
    private final class BufferPool: @unchecked Sendable {
        private let lock = NSLock()
        private var buffers: [Data] = []
        private let maxPoolSize = 8
        private let bufferSize = 4096
        
        func acquire() -> Data {
            lock.lock()
            defer { lock.unlock() }
            
            if !buffers.isEmpty {
                return buffers.removeLast()
            }
            return Data(capacity: bufferSize)
        }
        
        func release(_ buffer: Data) {
            lock.lock()
            defer { lock.unlock() }
            
            guard buffers.count < maxPoolSize else { return }
            
            var cleanBuffer = buffer
            cleanBuffer.removeAll(keepingCapacity: true)
            buffers.append(cleanBuffer)
        }
    }
    
    // MARK: - Optimized Parsing Constants
    
    private static let dataPrefix = "data: ".data(using: .utf8)!
    private static let eventPrefix = "event: ".data(using: .utf8)!
    private static let doneMarker = "[DONE]".data(using: .utf8)!
    private static let newline = "\n".data(using: .utf8)![0]
    private static let carriageReturn = "\r".data(using: .utf8)![0]
    
    // MARK: - High-Performance Parsing Methods
    
    /// Parse SSE chunk using optimized byte-level processing
    public static func parseSSEChunkOptimized(_ data: Data, logger: SSELogger? = nil) throws -> SAOAIStreamingResponse? {
        let buffer = bufferPool.acquire()
        defer { bufferPool.release(buffer) }
        
        // Log raw chunk if logger is provided
        logger?.logRawChunk(data)
        
        return try parseLines(from: data, using: buffer, logger: logger)
    }
    
    /// Parse lines from SSE data using byte-level processing
    private static func parseLines(from data: Data, using buffer: Data, logger: SSELogger? = nil) throws -> SAOAIStreamingResponse? {
        var currentPos = 0
        let dataCount = data.count
        
        while currentPos < dataCount {
            // Find next line ending
            let lineStart = currentPos
            while currentPos < dataCount && 
                  data[currentPos] != newline && 
                  data[currentPos] != carriageReturn {
                currentPos += 1
            }
            
            // Extract line data
            guard lineStart < currentPos else {
                // Skip empty lines
                currentPos += 1
                continue
            }
            
            let lineData = data.subdata(in: lineStart..<currentPos)
            
            // Skip line ending characters
            while currentPos < dataCount && 
                  (data[currentPos] == newline || data[currentPos] == carriageReturn) {
                currentPos += 1
            }
            
            // Fast check for completion signal
            if lineData.starts(with: dataPrefix) {
                let jsonStart = dataPrefix.count
                if jsonStart < lineData.count {
                    let jsonData = lineData.subdata(in: jsonStart..<lineData.count)
                    
                    // Fast check for [DONE] marker
                    if jsonData.starts(with: doneMarker) {
                        return nil // Completion signal
                    }
                    
                    // Try to parse JSON directly from subdata to avoid copying
                    if let response = try parseJSONFast(jsonData, logger: logger) {
                        return response
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Fast JSON parsing with minimal allocations
    private static func parseJSONFast(_ jsonData: Data, logger: SSELogger? = nil) throws -> SAOAIStreamingResponse? {
        // Skip empty JSON data
        guard !jsonData.isEmpty else { return nil }
        
        // Use cached decoder for better performance
        let decoder = CachedJSONDecoder.shared
        
        do {
            // Try Azure OpenAI event format first (most common)
            if let azureEvent = try? decoder.decode(AzureOpenAISSEEvent.self, from: jsonData) {
                // Log the event if logger is provided
                logger?.logEvent(azureEvent, rawData: jsonData)
                
                return convertAzureEventToStreamingResponseOptimized(azureEvent)
            }
            
            // Fallback to direct streaming response format
            return try decoder.decode(SAOAIStreamingResponse.self, from: jsonData)
        } catch {
            // Skip malformed JSON silently to maintain streaming performance
            return nil
        }
    }
    
    /// Optimized conversion from Azure event to streaming response
    private static func convertAzureEventToStreamingResponseOptimized(_ event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        // Fast path for most common delta events
        switch event.type {
        case "response.text.delta", "response.output_text.delta":
            return createDeltaResponse(event: event, contentType: "text")
        case "response.function_call_arguments.delta":
            return createDeltaResponse(event: event, contentType: "function_call_arguments")
        case "response.created", "response.in_progress", "response.completed":
            return createLifecycleResponse(event: event)
        default:
            // Use the SSE parser helper for less common events  
            return SSEParser.convertLifecycleEvent(event)
        }
    }
    
    /// Fast delta response creation for common cases
    private static func createDeltaResponse(event: AzureOpenAISSEEvent, contentType: String) -> SAOAIStreamingResponse? {
        guard let delta = event.delta else { return nil }
        
        let content = SAOAIStreamingContent(type: contentType, text: delta, index: event.outputIndex ?? 0)
        let output = SAOAIStreamingOutput(content: [content], role: "assistant")
        
        return SAOAIStreamingResponse(
            id: event.itemId,
            model: nil,
            created: nil,
            output: [output],
            usage: nil
        )
    }
    
    /// Fast lifecycle response creation
    private static func createLifecycleResponse(event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        guard let response = event.response else { return nil }
        
        return SAOAIStreamingResponse(
            id: response.id,
            model: response.model,
            created: response.createdAt,
            output: response.output?.compactMap { convertOutputOptimized($0) },
            usage: response.usage
        )
    }
    
    /// Optimized output conversion
    private static func convertOutputOptimized(_ output: AzureOpenAIEventOutput) -> SAOAIStreamingOutput? {
        switch output.type {
        case "function_call":
            let content = SAOAIStreamingContent(type: "function_call", text: output.name ?? "", index: 0)
            return SAOAIStreamingOutput(content: [content], role: "assistant")
        default:
            return nil
        }
    }
    
    /// Fast completion check using byte-level comparison
    public static func isCompletionChunkOptimized(_ data: Data) -> Bool {
        // Look for "data: [DONE]" pattern efficiently
        guard data.count >= dataPrefix.count + doneMarker.count else { return false }
        
        var pos = 0
        let dataCount = data.count
        
        while pos < dataCount - (dataPrefix.count + doneMarker.count) {
            if data[pos..<pos + dataPrefix.count].elementsEqual(dataPrefix) {
                let jsonStart = pos + dataPrefix.count
                if data[jsonStart..<jsonStart + doneMarker.count].elementsEqual(doneMarker) {
                    return true
                }
            }
            pos += 1
        }
        
        return false
    }
}

/// Thread-safe cached JSON decoder for performance
private final class CachedJSONDecoder: @unchecked Sendable {
    static let shared = CachedJSONDecoder()
    
    private let decoder: JSONDecoder
    
    private init() {
        self.decoder = JSONDecoder()
        // Pre-configure decoder for optimal performance
        self.decoder.dateDecodingStrategy = .secondsSince1970
    }
    
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        return try decoder.decode(type, from: data)
    }
}

// MARK: - Extensions for compatibility

extension SSEParser {
    /// Helper method to access the conversion method for lifecycle events
    static func convertLifecycleEvent(_ event: AzureOpenAISSEEvent) -> SAOAIStreamingResponse? {
        guard let response = event.response else { return nil }
        
        // Convert Azure OpenAI output to streaming output format (simplified)
        let streamingOutput: [SAOAIStreamingOutput]? = response.output?.compactMap { output in
            if output.type == "function_call", let name = output.name {
                let content = SAOAIStreamingContent(type: "function_call", text: name, index: 0)
                return SAOAIStreamingOutput(content: [content], role: "assistant")
            }
            return nil
        }
        
        return SAOAIStreamingResponse(
            id: response.id,
            model: response.model,
            created: response.createdAt,
            output: streamingOutput,
            usage: response.usage
        )
    }
}