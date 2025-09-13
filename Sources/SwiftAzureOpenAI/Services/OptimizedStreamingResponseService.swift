import Foundation

/// High-performance streaming response service with optimized buffering and reduced allocations
public final class OptimizedStreamingResponseService: Sendable {
    private let parser: StreamingResponseParser
    private let bufferSize: Int
    private let enableBatching: Bool
    
    public init(
        parser: StreamingResponseParser = OptimizedStreamingResponseParser(),
        bufferSize: Int = 8192,
        enableBatching: Bool = true
    ) {
        self.parser = parser
        self.bufferSize = bufferSize
        self.enableBatching = enableBatching
    }
    
    /// Process stream with optimized buffering and batching
    public func processStreamOptimized<T: Codable & Sendable>(
        _ stream: AsyncThrowingStream<Data, Error>, 
        type: T.Type
    ) -> AsyncThrowingStream<StreamingResponseChunk<T>, Error> {
        AsyncThrowingStream { continuation in
            Task {
                await processStreamInternal(stream, type: type, continuation: continuation)
            }
        }
    }
    
    /// Internal stream processing with performance optimizations
    private func processStreamInternal<T: Codable & Sendable>(
        _ stream: AsyncThrowingStream<Data, Error>,
        type: T.Type,
        continuation: AsyncThrowingStream<StreamingResponseChunk<T>, Error>.Continuation
    ) async {
        var sequenceNumber = 0
        var buffer = Data()
        buffer.reserveCapacity(bufferSize)
        
        var batchedChunks: [StreamingResponseChunk<T>] = []
        if enableBatching {
            batchedChunks.reserveCapacity(16) // Pre-allocate for common batch sizes
        }
        
        do {
            for try await chunk in stream {
                // Append to buffer for efficient processing
                buffer.append(chunk)
                
                // Process complete chunks from buffer
                let processedChunks = try processBufferedData(
                    buffer: &buffer,
                    type: type,
                    sequenceNumber: &sequenceNumber
                )
                
                if enableBatching {
                    // Batch chunks for better throughput
                    batchedChunks.append(contentsOf: processedChunks)
                    
                    // Yield batch when it reaches optimal size or has completion
                    if batchedChunks.count >= 8 || batchedChunks.contains(where: \.isComplete) {
                        yieldBatch(batchedChunks, to: continuation)
                        batchedChunks.removeAll(keepingCapacity: true)
                    }
                } else {
                    // Yield chunks immediately for low-latency scenarios
                    for chunk in processedChunks {
                        continuation.yield(chunk)
                        if chunk.isComplete {
                            continuation.finish()
                            return
                        }
                    }
                }
            }
            
            // Process any remaining data in buffer
            let finalChunks = try processFinalBuffer(
                buffer: &buffer,
                type: type,
                sequenceNumber: &sequenceNumber
            )
            
            if enableBatching {
                batchedChunks.append(contentsOf: finalChunks)
                if !batchedChunks.isEmpty {
                    yieldBatch(batchedChunks, to: continuation)
                }
            } else {
                for chunk in finalChunks {
                    continuation.yield(chunk)
                }
            }
            
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }
    
    /// Process buffered data and return completed chunks
    private func processBufferedData<T: Codable & Sendable>(
        buffer: inout Data,
        type: T.Type,
        sequenceNumber: inout Int
    ) throws -> [StreamingResponseChunk<T>] {
        var chunks: [StreamingResponseChunk<T>] = []
        
        // Look for complete SSE chunks (ending with \n\n)
        let delimiter = "\n\n".data(using: .utf8)!
        
        while let range = buffer.range(of: delimiter) {
            let chunkData = buffer[..<range.lowerBound]
            buffer.removeSubrange(..<range.upperBound)
            
            // Skip empty chunks
            guard !chunkData.isEmpty else { continue }
            
            // Check for completion first
            let isComplete = parser.isComplete(chunkData)
            
            if isComplete {
                // This is a completion marker, stop processing
                break
            } else {
                // Parse non-completion chunks using optimized parser
                do {
                    let parsed = try parser.parseChunk(chunkData, as: type)
                    
                    let responseChunk = StreamingResponseChunk(
                        chunk: parsed,
                        isComplete: false,
                        sequenceNumber: sequenceNumber
                    )
                    
                    chunks.append(responseChunk)
                    sequenceNumber += 1
                } catch {
                    // Log error but continue processing for resilience
                    continue
                }
            }
        }
        
        return chunks
    }
    
    /// Process any remaining data in buffer at end of stream
    private func processFinalBuffer<T: Codable & Sendable>(
        buffer: inout Data,
        type: T.Type,
        sequenceNumber: inout Int
    ) throws -> [StreamingResponseChunk<T>] {
        guard !buffer.isEmpty else { return [] }
        
        do {
            let parsed = try parser.parseChunk(buffer, as: type)
            let isComplete = parser.isComplete(buffer)
            
            let responseChunk = StreamingResponseChunk(
                chunk: parsed,
                isComplete: isComplete,
                sequenceNumber: sequenceNumber
            )
            
            sequenceNumber += 1
            return [responseChunk]
        } catch {
            return []
        }
    }
    
    /// Yield a batch of chunks efficiently
    private func yieldBatch<T: Codable & Sendable>(
        _ chunks: [StreamingResponseChunk<T>],
        to continuation: AsyncThrowingStream<StreamingResponseChunk<T>, Error>.Continuation
    ) {
        for chunk in chunks {
            continuation.yield(chunk)
            if chunk.isComplete {
                continuation.finish()
                return
            }
        }
    }
}

/// Performance-optimized streaming response parser that uses the optimized SSE parser
public final class OptimizedStreamingResponseParser: StreamingResponseParser, Sendable {
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    public func parseChunk<T: Codable>(_ data: Data, as type: T.Type) throws -> T {
        // For SSE data, try optimized parsing first
        if T.self == SAOAIStreamingResponse.self {
            if let optimizedResponse = try OptimizedSSEParser.parseSSEChunkOptimized(data) {
                return optimizedResponse as! T
            }
            // Fallback to original SSE parser if optimized parser returns nil
            if let fallbackResponse = try SSEParser.parseSSEChunk(data) {
                return fallbackResponse as! T
            }
            // If both SSE parsers return nil, check if this is a completion marker
            let dataString = String(data: data, encoding: .utf8) ?? ""
            if dataString.contains("data: [DONE]") {
                // This is a completion marker - the streaming service should handle this appropriately
                throw SAOAIError.decodingError(NSError(domain: "SSEParser", code: -999, userInfo: [NSLocalizedDescriptionKey: "Completion marker"]))
            }
            // For other cases where SSE parsers return nil, throw a more informative error
            throw SAOAIError.decodingError(NSError(domain: "SSEParser", code: -998, userInfo: [NSLocalizedDescriptionKey: "Unable to parse SSE data"]))
        }
        
        // Fallback to standard JSON decoding for non-SSE types
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SAOAIError.decodingError(error)
        }
    }
    
    public func isComplete(_ data: Data) -> Bool {
        // Use optimized completion check
        return OptimizedSSEParser.isCompletionChunkOptimized(data)
    }
}

/// High-performance streaming metrics for monitoring
public struct StreamingPerformanceMetrics: Sendable {
    public let chunksProcessed: Int
    public let totalLatency: TimeInterval
    public let averageChunkSize: Int
    public let throughputMBps: Double
    public let startTime: Date
    public let endTime: Date
    
    public var processingDuration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    public var chunksPerSecond: Double {
        Double(chunksProcessed) / processingDuration
    }
}

/// Performance monitoring wrapper for streaming services
public final class StreamingPerformanceMonitor: @unchecked Sendable {
    private let lock = NSLock()
    private var _metrics: StreamingPerformanceMetrics?
    
    public func startMonitoring() {
        lock.withLock {
            _metrics = StreamingPerformanceMetrics(
                chunksProcessed: 0,
                totalLatency: 0,
                averageChunkSize: 0,
                throughputMBps: 0,
                startTime: Date(),
                endTime: Date()
            )
        }
    }
    
    public func recordChunk(size: Int, latency: TimeInterval) {
        lock.withLock {
            guard let metrics = _metrics else { return }
            
            let newCount = metrics.chunksProcessed + 1
            let newTotalLatency = metrics.totalLatency + latency
            let newAverageSize = (metrics.averageChunkSize * metrics.chunksProcessed + size) / newCount
            
            _metrics = StreamingPerformanceMetrics(
                chunksProcessed: newCount,
                totalLatency: newTotalLatency,
                averageChunkSize: newAverageSize,
                throughputMBps: metrics.throughputMBps,
                startTime: metrics.startTime,
                endTime: Date()
            )
        }
    }
    
    public func finishMonitoring() -> StreamingPerformanceMetrics? {
        lock.withLock {
            guard let metrics = _metrics else { return nil }
            
            let totalBytes = Double(metrics.chunksProcessed * metrics.averageChunkSize)
            let totalMB = totalBytes / (1024 * 1024)
            let throughput = totalMB / metrics.processingDuration
            
            let finalMetrics = StreamingPerformanceMetrics(
                chunksProcessed: metrics.chunksProcessed,
                totalLatency: metrics.totalLatency,
                averageChunkSize: metrics.averageChunkSize,
                throughputMBps: throughput,
                startTime: metrics.startTime,
                endTime: Date()
            )
            
            _metrics = nil
            return finalMetrics
        }
    }
}

extension NSLock {
    func withLock<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}