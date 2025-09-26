//
//  EmbeddingBatchHelper.swift
//  SwiftAzureOpenAI
//
//  Foundation for embedding batch processing with concurrency throttling.
//

import Foundation

// MARK: - Batch Processing Configuration

/// Configuration for embedding batch processing
public struct EmbeddingBatchConfiguration: Sendable {
    /// Maximum number of concurrent requests
    public let maxConcurrency: Int
    
    /// Batch size for each request
    public let batchSize: Int
    
    /// Delay between batches (in seconds)
    public let delayBetweenBatches: TimeInterval
    
    /// Maximum retries for failed requests
    public let maxRetries: Int
    
    /// Retry delay (in seconds)
    public let retryDelay: TimeInterval
    
    public init(
        maxConcurrency: Int = 5,
        batchSize: Int = 100,
        delayBetweenBatches: TimeInterval = 0.1,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self.maxConcurrency = maxConcurrency
        self.batchSize = batchSize
        self.delayBetweenBatches = delayBetweenBatches
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
    
    /// Default configuration for most use cases
    public static let `default` = EmbeddingBatchConfiguration()
    
    /// High-throughput configuration for large datasets
    public static let highThroughput = EmbeddingBatchConfiguration(
        maxConcurrency: 10,
        batchSize: 200,
        delayBetweenBatches: 0.05
    )
    
    /// Conservative configuration for rate-limited scenarios
    public static let conservative = EmbeddingBatchConfiguration(
        maxConcurrency: 2,
        batchSize: 50,
        delayBetweenBatches: 0.5
    )
}

// MARK: - Batch Processing Result

/// Result of a batch embedding operation
public struct EmbeddingBatchResult {
    /// Successfully processed embeddings with their original indices
    public let embeddings: [(index: Int, embedding: SAOAIEmbedding)]
    
    /// Failed requests with their errors and original indices
    public let failures: [(index: Int, error: Error)]
    
    /// Processing statistics
    public let statistics: EmbeddingBatchStatistics
    
    public init(
        embeddings: [(index: Int, embedding: SAOAIEmbedding)],
        failures: [(index: Int, error: Error)],
        statistics: EmbeddingBatchStatistics
    ) {
        self.embeddings = embeddings
        self.failures = failures
        self.statistics = statistics
    }
    
    /// Total number of items processed
    public var totalProcessed: Int {
        embeddings.count + failures.count
    }
    
    /// Success rate (0.0 to 1.0)
    public var successRate: Double {
        guard totalProcessed > 0 else { return 0.0 }
        return Double(embeddings.count) / Double(totalProcessed)
    }
}

// MARK: - Batch Processing Statistics

/// Statistics for batch embedding operations
public struct EmbeddingBatchStatistics {
    /// Total processing time
    public let totalDuration: TimeInterval
    
    /// Number of batches processed
    public let batchCount: Int
    
    /// Number of retries performed
    public let retryCount: Int
    
    /// Average time per batch
    public var averageBatchTime: TimeInterval {
        guard batchCount > 0 else { return 0 }
        return totalDuration / TimeInterval(batchCount)
    }
    
    /// Items processed per second
    public func throughput(for itemCount: Int) -> Double {
        guard totalDuration > 0 else { return 0 }
        return Double(itemCount) / totalDuration
    }
    
    public init(
        totalDuration: TimeInterval,
        batchCount: Int,
        retryCount: Int
    ) {
        self.totalDuration = totalDuration
        self.batchCount = batchCount
        self.retryCount = retryCount
    }
}

// MARK: - Embedding Batch Helper Protocol

/// Protocol for embedding batch processing
public protocol EmbeddingBatchHelperProtocol {
    /// Process a batch of texts for embeddings
    func processEmbeddings(
        texts: [String],
        model: String,
        configuration: EmbeddingBatchConfiguration,
        progressHandler: ((Double) -> Void)?
    ) async throws -> EmbeddingBatchResult
}

// MARK: - Embedding Batch Helper Implementation

/// Production implementation of embedding batch processing with concurrency throttling
public final class EmbeddingBatchHelper: EmbeddingBatchHelperProtocol {
    private let embeddingsClient: EmbeddingsClient
    private let cache: EmbeddingCache?
    
    public init(embeddingsClient: EmbeddingsClient, cache: EmbeddingCache? = nil) {
        self.embeddingsClient = embeddingsClient
        self.cache = cache
    }
    
    public func processEmbeddings(
        texts: [String],
        model: String,
        configuration: EmbeddingBatchConfiguration = .default,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> EmbeddingBatchResult {
        let startTime = Date()
        let throttle = ConcurrencyThrottle(maxConcurrency: configuration.maxConcurrency)
        var embeddings: [(index: Int, embedding: SAOAIEmbedding)] = []
        var failures: [(index: Int, error: Error)] = []
        var processedCount = 0
        var batchCount = 0
        var retryCount = 0
        
        // Group texts into batches
        let batches = texts.chunked(into: configuration.batchSize)
        let totalBatches = batches.count
        
        // Process all batches concurrently with throttling
        await withTaskGroup(of: BatchResult.self) { taskGroup in
            for (batchIndex, batch) in batches.enumerated() {
                // Capture needed values for the task
                let embeddingsClient = self.embeddingsClient
                let cache = self.cache
                
                taskGroup.addTask {
                    await throttle.acquire()
                    defer {
                        Task {
                            await throttle.release()
                        }
                    }
                    
                    return await Self.processBatch(
                        batch: batch,
                        batchIndex: batchIndex,
                        model: model,
                        configuration: configuration,
                        embeddingsClient: embeddingsClient,
                        cache: cache
                    )
                }
            }
            
            // Collect results
            for await result in taskGroup {
                embeddings.append(contentsOf: result.embeddings)
                failures.append(contentsOf: result.failures)
                processedCount += result.processedCount
                batchCount += 1
                retryCount += result.retryCount
                
                // Report progress
                let progress = Double(batchCount) / Double(totalBatches)
                progressHandler?(progress)
                
                // Add delay between batch completions if configured
                if batchCount < totalBatches && configuration.delayBetweenBatches > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(configuration.delayBetweenBatches * 1_000_000_000))
                }
            }
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        let statistics = EmbeddingBatchStatistics(
            totalDuration: totalDuration,
            batchCount: batchCount,
            retryCount: retryCount
        )
        
        return EmbeddingBatchResult(
            embeddings: embeddings.sorted { $0.index < $1.index },
            failures: failures.sorted { $0.index < $1.index },
            statistics: statistics
        )
    }
    
    // MARK: - Private Methods
    
    private static func processBatch(
        batch: [(index: Int, text: String)],
        batchIndex: Int,
        model: String,
        configuration: EmbeddingBatchConfiguration,
        embeddingsClient: EmbeddingsClient,
        cache: EmbeddingCache?
    ) async -> BatchResult {
        var embeddings: [(index: Int, embedding: SAOAIEmbedding)] = []
        var failures: [(index: Int, error: Error)] = []
        var retryCount = 0
        
        for (originalIndex, text) in batch {
            // Check cache first
            if let cache = cache, let cachedEmbedding = cache.getCachedEmbedding(for: text, model: model) {
                embeddings.append((index: originalIndex, embedding: cachedEmbedding))
                continue
            }
            
            // Process with retries
            var attempt = 0
            var lastError: Error?
            
            while attempt <= configuration.maxRetries {
                do {
                    let request = SAOAIEmbeddingsRequest(
                        input: .text(text),
                        model: model
                    )
                    
                    let response = try await embeddingsClient.create(request)
                    if let firstEmbedding = response.data.first {
                        // Create embedding with original index
                        let embedding = SAOAIEmbedding(
                            object: firstEmbedding.object,
                            embedding: firstEmbedding.embedding,
                            index: originalIndex
                        )
                        embeddings.append((index: originalIndex, embedding: embedding))
                        
                        // Cache the result
                        cache?.cacheEmbedding(embedding, for: text, model: model, expiresIn: nil)
                    }
                    break // Success
                } catch {
                    lastError = error
                    attempt += 1
                    retryCount += 1
                    
                    if attempt <= configuration.maxRetries {
                        // Wait before retry
                        try? await Task.sleep(nanoseconds: UInt64(configuration.retryDelay * 1_000_000_000))
                    }
                }
            }
            
            if let error = lastError {
                failures.append((index: originalIndex, error: error))
            }
        }
        
        return BatchResult(
            embeddings: embeddings,
            failures: failures,
            processedCount: batch.count,
            retryCount: retryCount
        )
    }
}

// MARK: - Helper Types

private struct BatchResult {
    let embeddings: [(index: Int, embedding: SAOAIEmbedding)]
    let failures: [(index: Int, error: Error)]
    let processedCount: Int
    let retryCount: Int
}

// MARK: - Array Extension for Chunking

private extension Array {
    func chunked(into size: Int) -> [[(index: Int, text: Element)]] {
        guard size > 0 else { return [] }
        
        var chunks: [[(index: Int, text: Element)]] = []
        var currentChunk: [(index: Int, text: Element)] = []
        
        for (index, element) in self.enumerated() {
            currentChunk.append((index: index, text: element))
            
            if currentChunk.count == size {
                chunks.append(currentChunk)
                currentChunk = []
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
}

// MARK: - Concurrency Throttle Helper

/// Helper for managing concurrent operations with throttling
actor ConcurrencyThrottle {
    private let maxConcurrency: Int
    private var currentCount: Int = 0
    private var waitingTasks: [CheckedContinuation<Void, Never>] = []
    
    init(maxConcurrency: Int) {
        self.maxConcurrency = maxConcurrency
    }
    
    /// Acquire a slot for concurrent execution
    func acquire() async {
        if currentCount < maxConcurrency {
            currentCount += 1
        } else {
            await withCheckedContinuation { continuation in
                waitingTasks.append(continuation)
            }
        }
    }
    
    /// Release a slot and notify waiting tasks
    func release() {
        currentCount -= 1
        if !waitingTasks.isEmpty {
            let continuation = waitingTasks.removeFirst()
            currentCount += 1
            continuation.resume()
        }
    }
}

// MARK: - Usage Example

/*
Example usage (to be implemented):

```swift
let batchHelper = EmbeddingBatchHelper(client: embeddingsClient)

let texts = ["Hello world", "How are you?", "Swift is great!"]
let config = EmbeddingBatchConfiguration.default

let result = try await batchHelper.processEmbeddings(
    texts: texts,
    model: "text-embedding-ada-002",
    configuration: config
) { progress in
    print("Progress: \(Int(progress * 100))%")
}

print("Processed \(result.embeddings.count) embeddings successfully")
print("Failed: \(result.failures.count)")
print("Success rate: \(Int(result.successRate * 100))%")
print("Throughput: \(result.statistics.throughput(for: texts.count)) items/second")
```
*/