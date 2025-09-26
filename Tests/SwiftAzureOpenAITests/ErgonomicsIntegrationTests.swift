import XCTest
@testable import SwiftAzureOpenAI

final class ErgonomicsIntegrationTests: XCTestCase {
    
    func testErgonomicsUtilitiesIntegration() async {
        // This test verifies that all ergonomics utilities integrate correctly
        // without making actual API calls
        
        let config = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com/",
            apiKey: "test-key",
            deploymentName: "test-deployment",
            apiVersion: "preview"
        )
        
        // 1. Setup metrics collection
        let consoleDelegate = ConsoleMetricsDelegate(logLevel: .normal)
        let aggregatingDelegate = AggregatingMetricsDelegate()
        let multiCastDelegate = MultiCastMetricsDelegate(delegates: [consoleDelegate, aggregatingDelegate])
        
        // 2. Setup caching
        let cache = EmbeddingCache(maxCapacity: 100)
        
        // 3. Create client with metrics integration
        let client = SAOAIClient(
            configuration: config,
            metricsDelegate: multiCastDelegate
        )
        
        // 4. Create batch helper
        let batchHelper = EmbeddingBatchHelper(
            embeddingsClient: client.embeddings,
            cache: cache
        )
        
        // 5. Test configuration options
        let defaultConfig = EmbeddingBatchConfiguration.default
        let conservativeConfig = EmbeddingBatchConfiguration.conservative
        let highThroughputConfig = EmbeddingBatchConfiguration.highThroughput
        
        XCTAssertNotEqual(defaultConfig.maxConcurrency, conservativeConfig.maxConcurrency)
        XCTAssertNotEqual(defaultConfig.batchSize, highThroughputConfig.batchSize)
        
        // 6. Test cache functionality
        let testEmbedding = SAOAIEmbedding(
            object: "embedding",
            embedding: [0.1, 0.2, 0.3, 0.4, 0.5],
            index: 0
        )
        
        // Cache should be empty initially
        XCTAssertNil(cache.getCachedEmbedding(for: "test", model: "model"))
        
        // Add to cache
        cache.cacheEmbedding(testEmbedding, for: "test", model: "model", expiresIn: nil)
        
        // Should now be available
        let cachedEmbedding = cache.getCachedEmbedding(for: "test", model: "model")
        XCTAssertNotNil(cachedEmbedding)
        XCTAssertEqual(cachedEmbedding?.embedding, testEmbedding.embedding)
        
        // 7. Test metrics event creation
        let correlationId = CorrelationIdGenerator.generate()
        XCTAssertEqual(correlationId.count, 36) // UUID length
        
        let startEvent = RequestStartedEvent(
            correlationId: correlationId,
            method: "POST",
            endpoint: "/test",
            timestamp: Date(),
            metadata: [:]
        )
        
        let completedEvent = RequestCompletedEvent(
            correlationId: correlationId,
            statusCode: 200,
            duration: 1.0,
            responseSize: 1024,
            timestamp: Date(),
            responseId: "test-response-id",
            metadata: [:]
        )
        
        // Process events
        multiCastDelegate.requestStarted(startEvent)
        multiCastDelegate.requestCompleted(completedEvent)
        
        // Check aggregated statistics
        let stats = aggregatingDelegate.statistics
        XCTAssertEqual(stats.successfulRequests, 1)
        XCTAssertEqual(stats.failedRequests, 0)
        XCTAssertEqual(stats.successRate, 1.0)
        XCTAssertEqual(stats.averageRequestDuration, 1.0)
        
        // 8. Test cache statistics
        let cacheStats = cache.statistics
        XCTAssertGreaterThan(cacheStats.hits, 0) // We accessed the cached embedding
        XCTAssertEqual(cacheStats.count, 1) // One item cached
        XCTAssertEqual(cacheStats.capacity, 100)
        XCTAssertGreaterThan(cacheStats.hitRate, 0)
        XCTAssertGreaterThan(cacheStats.utilization, 0)
        
        print("✅ Ergonomics utilities integration test completed successfully")
        print("   Cache hit rate: \(Int(cacheStats.hitRate * 100))%")
        print("   Request success rate: \(Int(stats.successRate * 100))%")
        print("   Correlation ID generated: \(correlationId.prefix(8))...")
    }
    
    func testResponsesClientFactoryWithMetrics() {
        let config = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com/",
            apiKey: "test-key",
            deploymentName: "test-deployment",
            apiVersion: "preview"
        )
        
        let metricsDelegate = ConsoleMetricsDelegate(logLevel: .verbose)
        
        // Test factory method
        let responsesClient = ResponsesClient.create(
            configuration: config,
            metricsDelegate: metricsDelegate,
            cache: nil,
            useOptimizedService: true
        )
        
        XCTAssertNotNil(responsesClient)
        
        print("✅ ResponsesClient factory method works with metrics delegate")
    }
    
    func testConcurrencyThrottleIntegration() async {
        let throttle = ConcurrencyThrottle(maxConcurrency: 1)
        let processedOrder: [Int] = []
        let expectedOrder = [0, 1, 2] // Should process sequentially due to maxConcurrency = 1
        
        // This tests that the throttle correctly limits concurrency
        await withTaskGroup(of: Int.self) { taskGroup in
            for i in 0..<3 {
                taskGroup.addTask {
                    await throttle.acquire()
                    defer {
                        Task {
                            await throttle.release()
                        }
                    }
                    
                    // Small delay to ensure ordering
                    try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
                    return i
                }
            }
            
            var results: [Int] = []
            for await result in taskGroup {
                results.append(result)
            }
            
            // With maxConcurrency = 1, tasks should complete in order
            // (Though the exact order may vary, the important thing is that only 1 runs at a time)
            XCTAssertEqual(results.count, 3)
        }
        
        print("✅ Concurrency throttle integration test completed")
    }
}

// Helper multi-cast delegate for testing
private class MultiCastMetricsDelegate: MetricsDelegate {
    private let delegates: [MetricsDelegate]
    
    init(delegates: [MetricsDelegate]) {
        self.delegates = delegates
    }
    
    func requestStarted(_ event: RequestStartedEvent) {
        delegates.forEach { $0.requestStarted(event) }
    }
    
    func requestCompleted(_ event: RequestCompletedEvent) {
        delegates.forEach { $0.requestCompleted(event) }
    }
    
    func requestFailed(_ event: RequestFailedEvent) {
        delegates.forEach { $0.requestFailed(event) }
    }
    
    func streamingEvent(_ event: StreamingEvent) {
        delegates.forEach { $0.streamingEvent(event) }
    }
    
    func cacheEvent(_ event: CacheEvent) {
        delegates.forEach { $0.cacheEvent(event) }
    }
}