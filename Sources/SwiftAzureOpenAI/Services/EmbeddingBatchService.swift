import Foundation

/// Service for processing embeddings in batches with concurrency throttling
public final class EmbeddingBatchService: @unchecked Sendable {
    private let client: EmbeddingsClient
    private let concurrencyLimit: Int
    private let batchSize: Int
    private let delayBetweenBatches: TimeInterval
    
    /// Initialize the embedding batch service
    /// - Parameters:
    ///   - client: The embeddings client to use for requests
    ///   - concurrencyLimit: Maximum number of concurrent requests (default: 3)
    ///   - batchSize: Number of texts to process in each batch (default: 100)
    ///   - delayBetweenBatches: Delay between batches in seconds (default: 0.1)
    public init(
        client: EmbeddingsClient,
        concurrencyLimit: Int = 3,
        batchSize: Int = 100,
        delayBetweenBatches: TimeInterval = 0.1
    ) {
        self.client = client
        self.concurrencyLimit = concurrencyLimit
        self.batchSize = batchSize
        self.delayBetweenBatches = delayBetweenBatches
    }
    
    /// Process a large collection of texts in batches with concurrency throttling
    /// - Parameters:
    ///   - texts: Array of texts to embed
    ///   - model: Model to use for embeddings
    ///   - progressCallback: Optional callback to track progress
    /// - Returns: Array of embeddings corresponding to input texts
    public func processBatch(
        texts: [String],
        model: String,
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async throws -> [SAOAIEmbedding] {
        guard !texts.isEmpty else { return [] }
        
        // Split texts into batches
        let batches = texts.chunked(into: batchSize)
        var allEmbeddings: [SAOAIEmbedding] = []
        allEmbeddings.reserveCapacity(texts.count)
        
        // Process batches with concurrency limit using controlled task spawning
        return try await withThrowingTaskGroup(of: (Int, [SAOAIEmbedding]).self) { group in
            var processedCount = 0
            var batchResults: [(Int, [SAOAIEmbedding])] = []
            var nextBatchIndex = 0
            let totalBatches = batches.count
            
            // Add initial tasks up to concurrency limit
            while nextBatchIndex < totalBatches && nextBatchIndex < concurrencyLimit {
                let batchIndex = nextBatchIndex
                let batch = batches[batchIndex]
                
                group.addTask {
                    // Add delay between batches to avoid rate limiting
                    if batchIndex > 0 {
                        try await Task.sleep(nanoseconds: UInt64(self.delayBetweenBatches * 1_000_000_000))
                    }
                    
                    let response = try await self.client.create(texts: batch, model: model)
                    return (batchIndex, response.data)
                }
                nextBatchIndex += 1
            }
            
            // Process completed tasks and add new ones
            for try await (batchIndex, embeddings) in group {
                batchResults.append((batchIndex, embeddings))
                processedCount += embeddings.count
                progressCallback?(processedCount, texts.count)
                
                // Add next batch if available
                if nextBatchIndex < totalBatches {
                    let newBatchIndex = nextBatchIndex
                    let newBatch = batches[newBatchIndex]
                    
                    group.addTask {
                        // Add delay between batches to avoid rate limiting
                        if newBatchIndex > 0 {
                            try await Task.sleep(nanoseconds: UInt64(self.delayBetweenBatches * 1_000_000_000))
                        }
                        
                        let response = try await self.client.create(texts: newBatch, model: model)
                        return (newBatchIndex, response.data)
                    }
                    nextBatchIndex += 1
                }
            }
            
            // Sort by batch index to maintain order
            batchResults.sort { $0.0 < $1.0 }
            for (_, embeddings) in batchResults {
                allEmbeddings.append(contentsOf: embeddings)
            }
            
            return allEmbeddings
        }
    }
    
    /// Process embeddings with retry logic for failed batches
    /// - Parameters:
    ///   - texts: Array of texts to embed
    ///   - model: Model to use for embeddings
    ///   - maxRetries: Maximum number of retries per batch (default: 2)
    ///   - progressCallback: Optional callback to track progress
    /// - Returns: Array of embeddings corresponding to input texts
    public func processBatchWithRetry(
        texts: [String],
        model: String,
        maxRetries: Int = 2,
        progressCallback: ((Int, Int, Int) -> Void)? = nil
    ) async throws -> [SAOAIEmbedding] {
        guard !texts.isEmpty else { return [] }
        
        let batches = texts.chunked(into: batchSize)
        var allEmbeddings: [SAOAIEmbedding] = []
        allEmbeddings.reserveCapacity(texts.count)
        
        var processedCount = 0
        
        try await withThrowingTaskGroup(of: (Int, [SAOAIEmbedding]).self) { group in
            var batchResults: [(Int, [SAOAIEmbedding])] = []
            var nextBatchIndex = 0
            let totalBatches = batches.count
            
            // Add initial tasks up to concurrency limit
            while nextBatchIndex < totalBatches && nextBatchIndex < concurrencyLimit {
                let batchIndex = nextBatchIndex
                let batch = batches[batchIndex]
                
                group.addTask {
                    var attempts = 0
                    var lastError: Error?
                    
                    while attempts <= maxRetries {
                        do {
                            // Add delay for retries and between batches
                            if attempts > 0 || batchIndex > 0 {
                                let delay = attempts > 0 ? 
                                    self.delayBetweenBatches * Double(attempts + 1) : 
                                    self.delayBetweenBatches
                                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            }
                            
                            let response = try await self.client.create(texts: batch, model: model)
                            return (batchIndex, response.data)
                        } catch {
                            lastError = error
                            attempts += 1
                            
                            // Only retry for certain types of errors
                            if !self.shouldRetry(error: error) {
                                break
                            }
                        }
                    }
                    
                    throw lastError ?? SAOAIError.timeoutError(30.0)
                }
                nextBatchIndex += 1
            }
            
            // Process completed tasks and add new ones
            for try await (batchIndex, embeddings) in group {
                batchResults.append((batchIndex, embeddings))
                processedCount += embeddings.count
                progressCallback?(processedCount, texts.count, 0)
                
                // Add next batch if available
                if nextBatchIndex < totalBatches {
                    let newBatchIndex = nextBatchIndex
                    let newBatch = batches[newBatchIndex]
                    
                    group.addTask {
                        var attempts = 0
                        var lastError: Error?
                        
                        while attempts <= maxRetries {
                            do {
                                // Add delay for retries and between batches
                                if attempts > 0 || newBatchIndex > 0 {
                                    let delay = attempts > 0 ? 
                                        self.delayBetweenBatches * Double(attempts + 1) : 
                                        self.delayBetweenBatches
                                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                                }
                                
                                let response = try await self.client.create(texts: newBatch, model: model)
                                return (newBatchIndex, response.data)
                            } catch {
                                lastError = error
                                attempts += 1
                                
                                // Only retry for certain types of errors
                                if !self.shouldRetry(error: error) {
                                    break
                                }
                            }
                        }
                        
                        throw lastError ?? SAOAIError.timeoutError(30.0)
                    }
                    nextBatchIndex += 1
                }
            }
            
            // Sort and combine results
            batchResults.sort { $0.0 < $1.0 }
            for (_, embeddings) in batchResults {
                allEmbeddings.append(contentsOf: embeddings)
            }
        }
        
        return allEmbeddings
    }
    
    private func shouldRetry(error: Error) -> Bool {
        if let openAIError = error as? SAOAIError {
            switch openAIError {
            case .rateLimitExceeded, .serverError, .timeoutError:
                return true
            default:
                return false
            }
        }
        return false
    }
}

/// Async semaphore for controlling concurrency (removed - use DispatchSemaphore)

/// Helper extension for chunking arrays
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}