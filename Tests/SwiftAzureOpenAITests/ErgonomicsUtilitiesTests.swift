import XCTest
@testable import SwiftAzureOpenAI

final class ErgonomicsUtilitiesTests: XCTestCase {
    
    // MARK: - EmbeddingBatchHelper Tests
    
    func testEmbeddingBatchConfiguration() {
        // Test default configuration
        let defaultConfig = EmbeddingBatchConfiguration.default
        XCTAssertEqual(defaultConfig.maxConcurrency, 5)
        XCTAssertEqual(defaultConfig.batchSize, 100)
        XCTAssertEqual(defaultConfig.delayBetweenBatches, 0.1)
        XCTAssertEqual(defaultConfig.maxRetries, 3)
        XCTAssertEqual(defaultConfig.retryDelay, 1.0)
        
        // Test high throughput configuration
        let highThroughputConfig = EmbeddingBatchConfiguration.highThroughput
        XCTAssertEqual(highThroughputConfig.maxConcurrency, 10)
        XCTAssertEqual(highThroughputConfig.batchSize, 200)
        XCTAssertEqual(highThroughputConfig.delayBetweenBatches, 0.05)
        
        // Test conservative configuration
        let conservativeConfig = EmbeddingBatchConfiguration.conservative
        XCTAssertEqual(conservativeConfig.maxConcurrency, 2)
        XCTAssertEqual(conservativeConfig.batchSize, 50)
        XCTAssertEqual(conservativeConfig.delayBetweenBatches, 0.5)
        
        // Test custom configuration
        let customConfig = EmbeddingBatchConfiguration(
            maxConcurrency: 3,
            batchSize: 25,
            delayBetweenBatches: 0.2,
            maxRetries: 2,
            retryDelay: 0.5
        )
        XCTAssertEqual(customConfig.maxConcurrency, 3)
        XCTAssertEqual(customConfig.batchSize, 25)
        XCTAssertEqual(customConfig.delayBetweenBatches, 0.2)
        XCTAssertEqual(customConfig.maxRetries, 2)
        XCTAssertEqual(customConfig.retryDelay, 0.5)
    }
    
    func testEmbeddingBatchResult() {
        let embedding1 = SAOAIEmbedding(
            object: "embedding",
            embedding: [0.1, 0.2, 0.3],
            index: 0
        )
        let embedding2 = SAOAIEmbedding(
            object: "embedding", 
            embedding: [0.4, 0.5, 0.6],
            index: 1
        )
        
        let embeddings = [(index: 0, embedding: embedding1), (index: 1, embedding: embedding2)]
        let failures = [(index: 2, error: SAOAIError.serverError(statusCode: 500))]
        let statistics = EmbeddingBatchStatistics(totalDuration: 1.5, batchCount: 1, retryCount: 0)
        
        let result = EmbeddingBatchResult(
            embeddings: embeddings,
            failures: failures,
            statistics: statistics
        )
        
        XCTAssertEqual(result.embeddings.count, 2)
        XCTAssertEqual(result.failures.count, 1)
        XCTAssertEqual(result.totalProcessed, 3)
        XCTAssertEqual(result.successRate, 2.0/3.0, accuracy: 0.001)
    }
    
    func testEmbeddingBatchStatistics() {
        let statistics = EmbeddingBatchStatistics(
            totalDuration: 10.0,
            batchCount: 5,
            retryCount: 2
        )
        
        XCTAssertEqual(statistics.totalDuration, 10.0)
        XCTAssertEqual(statistics.batchCount, 5)
        XCTAssertEqual(statistics.retryCount, 2)
        XCTAssertEqual(statistics.averageBatchTime, 2.0)
        XCTAssertEqual(statistics.throughput(for: 100), 10.0)
        
        // Test zero division handling
        let emptyStats = EmbeddingBatchStatistics(totalDuration: 0, batchCount: 0, retryCount: 0)
        XCTAssertEqual(emptyStats.averageBatchTime, 0)
        XCTAssertEqual(emptyStats.throughput(for: 100), 0)
    }
    
    // MARK: - Cache Protocol Tests
    
    func testEmbeddingCache() {
        let cache = EmbeddingCache(maxCapacity: 10)
        
        let embedding = SAOAIEmbedding(
            object: "embedding",
            embedding: [0.1, 0.2, 0.3],
            index: 0
        )
        
        // Test cache miss
        XCTAssertNil(cache.getCachedEmbedding(for: "test", model: "model"))
        
        // Test cache set and hit
        cache.cacheEmbedding(embedding, for: "test", model: "model", expiresIn: nil)
        let cachedEmbedding = cache.getCachedEmbedding(for: "test", model: "model")
        XCTAssertNotNil(cachedEmbedding)
        XCTAssertEqual(cachedEmbedding?.embedding, embedding.embedding)
        
        // Test cache key generation
        let key1 = cache.cacheKey(for: "text1", model: "model1")
        let key2 = cache.cacheKey(for: "text2", model: "model1")
        let key3 = cache.cacheKey(for: "text1", model: "model2")
        
        XCTAssertNotEqual(key1, key2)
        XCTAssertNotEqual(key1, key3)
        XCTAssertNotEqual(key2, key3)
    }
    
    func testCacheStatistics() {
        let cache = EmbeddingCache(maxCapacity: 5)
        let embedding = SAOAIEmbedding(
            object: "embedding",
            embedding: [0.1, 0.2, 0.3],
            index: 0
        )
        
        // Initial statistics
        let initialStats = cache.statistics
        XCTAssertEqual(initialStats.hits, 0)
        XCTAssertEqual(initialStats.misses, 0)
        XCTAssertEqual(initialStats.count, 0)
        XCTAssertEqual(initialStats.capacity, 5)
        XCTAssertEqual(initialStats.hitRate, 0.0)
        XCTAssertEqual(initialStats.utilization, 0.0)
        
        // Add some embeddings
        cache.cacheEmbedding(embedding, for: "text1", model: "model", expiresIn: nil)
        cache.cacheEmbedding(embedding, for: "text2", model: "model", expiresIn: nil)
        
        // Test access (should increase hits)
        _ = cache.getCachedEmbedding(for: "text1", model: "model")
        _ = cache.getCachedEmbedding(for: "text1", model: "model")
        _ = cache.getCachedEmbedding(for: "nonexistent", model: "model")
        
        let finalStats = cache.statistics
        XCTAssertGreaterThan(finalStats.hits, 0)
        XCTAssertGreaterThan(finalStats.misses, 0)
        XCTAssertEqual(finalStats.count, 2)
        XCTAssertEqual(finalStats.utilization, 0.4) // 2/5
    }
    
    func testCacheExpiration() async {
        let cache = EmbeddingCache(maxCapacity: 5)
        let embedding = SAOAIEmbedding(
            object: "embedding",
            embedding: [0.1, 0.2, 0.3],
            index: 0
        )
        
        // Cache with short expiration
        cache.cacheEmbedding(embedding, for: "test", model: "model", expiresIn: 0.1)
        
        // Should be available immediately
        XCTAssertNotNil(cache.getCachedEmbedding(for: "test", model: "model"))
        
        // Wait for expiration
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        
        // Should be expired now
        XCTAssertNil(cache.getCachedEmbedding(for: "test", model: "model"))
    }
    
    // MARK: - Metrics Delegate Tests
    
    func testCorrelationIdGenerator() {
        let id1 = CorrelationIdGenerator.generate()
        let id2 = CorrelationIdGenerator.generate()
        let shortId = CorrelationIdGenerator.generateShort()
        let prefixedId = CorrelationIdGenerator.generate(prefix: "test")
        
        XCTAssertNotEqual(id1, id2)
        XCTAssertEqual(id1.count, 36) // UUID length
        XCTAssertEqual(shortId.count, 8)
        XCTAssertTrue(prefixedId.hasPrefix("test-"))
        XCTAssertEqual(prefixedId.count, 13) // "test-" + 8 chars
    }
    
    func testConsoleMetricsDelegate() {
        let delegate = ConsoleMetricsDelegate(logLevel: .verbose)
        
        let startEvent = RequestStartedEvent(
            correlationId: "test-123",
            method: "POST",
            endpoint: "/test",
            timestamp: Date(),
            metadata: [:]
        )
        
        let completedEvent = RequestCompletedEvent(
            correlationId: "test-123",
            statusCode: 200,
            duration: 1.5,
            responseSize: 1024,
            timestamp: Date(),
            responseId: "resp-123",
            metadata: [:]
        )
        
        let failedEvent = RequestFailedEvent(
            correlationId: "test-123",
            statusCode: 429,
            duration: 0.5,
            error: SAOAIError.rateLimitExceeded,
            timestamp: Date(),
            retryAttempt: 1,
            metadata: [:]
        )
        
        // These should not throw
        XCTAssertNoThrow(delegate.requestStarted(startEvent))
        XCTAssertNoThrow(delegate.requestCompleted(completedEvent))
        XCTAssertNoThrow(delegate.requestFailed(failedEvent))
    }
    
    func testAggregatingMetricsDelegate() {
        let delegate = AggregatingMetricsDelegate()
        
        let startEvent = RequestStartedEvent(
            correlationId: "test-123",
            method: "POST", 
            endpoint: "/test",
            timestamp: Date(),
            metadata: [:]
        )
        
        let completedEvent = RequestCompletedEvent(
            correlationId: "test-123",
            statusCode: 200,
            duration: 1.5,
            responseSize: 1024,
            timestamp: Date(),
            responseId: "resp-123",
            metadata: [:]
        )
        
        let failedEvent = RequestFailedEvent(
            correlationId: "test-456",
            statusCode: 429,
            duration: 0.5,
            error: SAOAIError.rateLimitExceeded,
            timestamp: Date(),
            retryAttempt: 1,
            metadata: [:]
        )
        
        // Process some events
        delegate.requestStarted(startEvent)
        delegate.requestCompleted(completedEvent)
        delegate.requestFailed(failedEvent)
        
        let stats = delegate.statistics
        XCTAssertEqual(stats.successfulRequests, 1)
        XCTAssertEqual(stats.failedRequests, 1)
        XCTAssertEqual(stats.successRate, 0.5)
        XCTAssertEqual(stats.averageRequestDuration, 1.0) // (1.5 + 0.5) / 2
        XCTAssertEqual(stats.statusCodes[200], 1)
        XCTAssertEqual(stats.statusCodes[429], 1)
    }
    
    // MARK: - Integration Tests
    
    func testConcurrencyThrottle() async {
        let throttle = ConcurrencyThrottle(maxConcurrency: 2)
        let trackingActor = ConcurrencyTracker()
        
        // Start multiple tasks
        await withTaskGroup(of: Void.self) { taskGroup in
            for _ in 0..<5 {
                taskGroup.addTask {
                    await throttle.acquire()
                    
                    // Track concurrent execution
                    await trackingActor.taskStarted()
                    
                    // Simulate work
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    
                    await trackingActor.taskEnded()
                    await throttle.release()
                }
            }
        }
        
        // Should never exceed the concurrency limit
        let maxConcurrent = await trackingActor.maxConcurrentTasks
        XCTAssertLessThanOrEqual(maxConcurrent, 2)
    }
}

// Helper actor for thread-safe concurrency tracking
private actor ConcurrencyTracker {
    private var activeTasks = 0
    private(set) var maxConcurrentTasks = 0
    
    func taskStarted() {
        activeTasks += 1
        maxConcurrentTasks = max(maxConcurrentTasks, activeTasks)
    }
    
    func taskEnded() {
        activeTasks -= 1
    }
}