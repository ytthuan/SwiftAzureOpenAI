#!/usr/bin/env swift

/*
 * ErgonomicsUtilitiesExample.swift
 * SwiftAzureOpenAI
 *
 * Example demonstrating the ergonomics and observability utilities:
 * - EmbeddingBatchHelper for batch processing embeddings with concurrency control
 * - EmbeddingCache for caching embeddings with TTL and size limits
 * - MetricsDelegate for observability and correlation ID logging
 * - Integration of all utilities for production-ready embedding workflows
 */

import Foundation
import SwiftAzureOpenAI

@main
struct ErgonomicsUtilitiesExample {
    static func main() async {
        // Configuration from environment variables
        guard let endpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"] else {
            print("❌ AZURE_OPENAI_ENDPOINT environment variable is required")
            exit(1)
        }
        
        let apiKey = ProcessInfo.processInfo.environment["AZURE_OPENAI_API_KEY"] ??
                    ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"] ??
                    "your-api-key"
        
        let deploymentName = ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] ?? "text-embedding-ada-002"
        
        // Create configuration
        let config = SAOAIAzureConfiguration(
            endpoint: endpoint,
            apiKey: apiKey,
            deploymentName: deploymentName,
            apiVersion: "preview"
        )
        
        print("🚀 SwiftAzureOpenAI Ergonomics Utilities Example")
        print("   Endpoint: \(endpoint)")
        print("   Deployment: \(deploymentName)")
        print()
        
        await runExample(with: config)
    }
    
    static func runExample(with config: SAOAIConfiguration) async {
        // 1. Setup observability with metrics delegate
        print("📊 Setting up metrics delegate...")
        let metricsDelegate = ConsoleMetricsDelegate(logLevel: .normal)
        let aggregatingDelegate = AggregatingMetricsDelegate()
        
        // Create a multi-cast delegate that logs to console and aggregates metrics
        let multiCastDelegate = MultiCastMetricsDelegate(delegates: [metricsDelegate, aggregatingDelegate])
        
        // 2. Setup caching
        print("💾 Setting up embedding cache...")
        let cache = EmbeddingCache(maxCapacity: 1000)
        
        // 3. Create client with metrics delegation
        print("🔧 Creating client with metrics integration...")
        let client = SAOAIClient(
            configuration: config,
            cache: nil,
            useOptimizedService: true,
            metricsDelegate: multiCastDelegate
        )
        
        // 4. Create batch helper
        print("⚡ Creating embedding batch helper...")
        let batchHelper = EmbeddingBatchHelper(
            embeddingsClient: client.embeddings,
            cache: cache
        )
        
        // 5. Prepare test data
        let texts = [
            "SwiftAzureOpenAI is a Swift package for Azure OpenAI integration.",
            "It provides ergonomic APIs for responses, files, and embeddings.",
            "The package includes utilities for batch processing and caching.",
            "Observability features include metrics delegation and correlation IDs.",
            "All APIs are designed to be Swift-native and async/await compatible.",
            "The package supports both Azure OpenAI and OpenAI API endpoints.",
            "Caching helps reduce API calls and improve performance.",
            "Batch processing enables efficient handling of large datasets.",
            "Metrics help monitor API usage and troubleshoot issues.",
            "The Swift concurrency model provides safe concurrent operations."
        ]
        
        print("📝 Processing \(texts.count) texts for embeddings...")
        print()
        
        // 6. Process embeddings with different configurations
        await demonstrateBatchProcessing(batchHelper: batchHelper, texts: texts, deploymentName: deploymentName)
        
        // 7. Demonstrate caching benefits
        await demonstrateCaching(batchHelper: batchHelper, cache: cache, texts: Array(texts.prefix(3)), deploymentName: deploymentName)
        
        // 8. Show metrics results
        await demonstrateMetrics(aggregatingDelegate: aggregatingDelegate, cache: cache)
        
        print("✅ Example completed successfully!")
    }
    
    // MARK: - Batch Processing Demo
    
    static func demonstrateBatchProcessing(
        batchHelper: EmbeddingBatchHelper,
        texts: [String],
        deploymentName: String
    ) async {
        print("🔄 Demonstrating batch processing with different configurations...")
        
        // Test different configurations
        let configurations = [
            ("Default", EmbeddingBatchConfiguration.default),
            ("Conservative", EmbeddingBatchConfiguration.conservative),
            ("High Throughput", EmbeddingBatchConfiguration.highThroughput)
        ]
        
        for (name, config) in configurations {
            print("\n📋 Testing \(name) configuration:")
            print("   Max Concurrency: \(config.maxConcurrency)")
            print("   Batch Size: \(config.batchSize)")
            print("   Delay Between Batches: \(config.delayBetweenBatches)s")
            
            let startTime = Date()
            
            do {
                let result = try await batchHelper.processEmbeddings(
                    texts: texts,
                    model: deploymentName,
                    configuration: config
                ) { progress in
                    let percentage = Int(progress * 100)
                    print("   Progress: \(percentage)%")
                }
                
                let duration = Date().timeIntervalSince(startTime)
                
                print("   ✅ Results:")
                print("      Successfully processed: \(result.embeddings.count)/\(texts.count)")
                print("      Failed: \(result.failures.count)")
                print("      Success rate: \(Int(result.successRate * 100))%")
                print("      Duration: \(String(format: "%.2fs", duration))")
                print("      Throughput: \(String(format: "%.1f", result.statistics.throughput(for: texts.count))) items/second")
                print("      Batches processed: \(result.statistics.batchCount)")
                print("      Retries: \(result.statistics.retryCount)")
                
                if !result.failures.isEmpty {
                    print("   ❌ Failures:")
                    for failure in result.failures.prefix(3) {
                        print("      Index \(failure.index): \(failure.error.localizedDescription)")
                    }
                }
                
            } catch {
                print("   ❌ Batch processing failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Caching Demo
    
    static func demonstrateCaching(
        batchHelper: EmbeddingBatchHelper,
        cache: EmbeddingCache,
        texts: [String],
        deploymentName: String
    ) async {
        print("\n💾 Demonstrating caching benefits...")
        
        // First run - cache misses
        print("\n🔍 First run (cache misses expected):")
        let firstRunStart = Date()
        
        do {
            let result1 = try await batchHelper.processEmbeddings(
                texts: texts,
                model: deploymentName,
                configuration: .default
            )
            let firstRunDuration = Date().timeIntervalSince(firstRunStart)
            
            print("   Duration: \(String(format: "%.2fs", firstRunDuration))")
            print("   Processed: \(result1.embeddings.count) embeddings")
        } catch {
            print("   ❌ Failed: \(error.localizedDescription)")
            return
        }
        
        // Second run - cache hits expected
        print("\n🎯 Second run (cache hits expected):")
        let secondRunStart = Date()
        
        do {
            let result2 = try await batchHelper.processEmbeddings(
                texts: texts,
                model: deploymentName,
                configuration: .default
            )
            let secondRunDuration = Date().timeIntervalSince(secondRunStart)
            
            print("   Duration: \(String(format: "%.2fs", secondRunDuration))")
            print("   Processed: \(result2.embeddings.count) embeddings")
            
            let speedup = firstRunDuration / secondRunDuration
            print("   Speedup: \(String(format: "%.1fx", speedup))")
        } catch {
            print("   ❌ Failed: \(error.localizedDescription)")
        }
        
        // Show cache statistics
        let cacheStats = cache.statistics
        print("\n📈 Cache Statistics:")
        print("   Hit rate: \(Int(cacheStats.hitRate * 100))%")
        print("   Utilization: \(Int(cacheStats.utilization * 100))%")
        print("   Items cached: \(cacheStats.count)/\(cacheStats.capacity)")
        print("   Total hits: \(cacheStats.hits)")
        print("   Total misses: \(cacheStats.misses)")
    }
    
    // MARK: - Metrics Demo
    
    static func demonstrateMetrics(
        aggregatingDelegate: AggregatingMetricsDelegate,
        cache: EmbeddingCache
    ) async {
        print("\n📊 Metrics Summary:")
        
        let stats = aggregatingDelegate.statistics
        
        print("\n🚀 Request Statistics:")
        print("   Successful requests: \(stats.successfulRequests)")
        print("   Failed requests: \(stats.failedRequests)")
        print("   Success rate: \(Int(stats.successRate * 100))%")
        print("   Average duration: \(String(format: "%.3fs", stats.averageRequestDuration))")
        
        print("\n📋 Status Code Distribution:")
        for (statusCode, count) in stats.statusCodes.sorted(by: { $0.key < $1.key }) {
            let emoji = statusCode == 200 ? "✅" : (statusCode >= 400 ? "❌" : "ℹ️")
            print("   \(emoji) \(statusCode): \(count) requests")
        }
        
        print("\n💾 Cache Performance:")
        let cacheStats = cache.statistics
        print("   Cache hit rate: \(Int(cacheStats.hitRate * 100))%")
        print("   Items in cache: \(cacheStats.count)")
        print("   Cache utilization: \(Int(cacheStats.utilization * 100))%")
    }
}

// MARK: - Multi-Cast Metrics Delegate

/// Utility class to broadcast metrics events to multiple delegates
class MultiCastMetricsDelegate: MetricsDelegate {
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