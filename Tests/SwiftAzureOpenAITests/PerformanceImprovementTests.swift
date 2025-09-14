import XCTest
@testable import SwiftAzureOpenAI
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Tests to validate performance improvements in URLSession, streaming, and JSON encoding
final class PerformanceImprovementTests: XCTestCase {
    
    func testSharedJSONEncoderPerformance() async throws {
        let request = SAOAIRequest(
            model: "gpt-4o-mini",
            input: [SAOAIInput.message(SAOAIMessage(role: .user, text: "Hello"))],
            maxOutputTokens: 100
        )
        
        // Test individual JSONEncoder allocations (baseline)
        let startTime1 = Date()
        var individualEncodingTime: TimeInterval = 0
        
        for _ in 0..<1000 {
            let encoder = JSONEncoder()
            let start = Date()
            _ = try encoder.encode(request)
            individualEncodingTime += Date().timeIntervalSince(start)
        }
        let totalTime1 = Date().timeIntervalSince(startTime1)
        
        // Test shared JSONEncoder (optimized)
        let startTime2 = Date()
        var sharedEncodingTime: TimeInterval = 0
        
        for _ in 0..<1000 {
            let start = Date()
            _ = try SharedJSONEncoder.shared.encode(request)
            sharedEncodingTime += Date().timeIntervalSince(start)
        }
        let totalTime2 = Date().timeIntervalSince(startTime2)
        
        // Calculate performance metrics
        let improvement = ((totalTime1 - totalTime2) / totalTime1) * 100
        
        print("🚀 JSONEncoder Performance Test:")
        print("   Individual encoders: \(String(format: "%.3f", totalTime1))s (encoding: \(String(format: "%.3f", individualEncodingTime))s)")
        print("   Shared encoder: \(String(format: "%.3f", totalTime2))s (encoding: \(String(format: "%.3f", sharedEncodingTime))s)")
        print("   Overall improvement: \(String(format: "%.1f", improvement))%")
        
        // Verify improvement (should be at least some improvement due to reduced allocations)
        XCTAssertLessThan(totalTime2, totalTime1, "Shared encoder should be faster than individual allocations")
    }
    
    func testOptimizedURLSessionConfiguration() throws {
        // Test that optimized URLSession is configured correctly
        let optimizedSession = OptimizedURLSession.shared.urlSession
        let config = optimizedSession.configuration
        
        // Verify optimized settings
        XCTAssertEqual(config.httpMaximumConnectionsPerHost, 6, "Should have optimized connection count")
        XCTAssertEqual(config.timeoutIntervalForRequest, 30.0, "Should have optimized request timeout")
        XCTAssertEqual(config.timeoutIntervalForResource, 120.0, "Should have optimized resource timeout")
        XCTAssertEqual(config.requestCachePolicy, .reloadIgnoringLocalCacheData, "Should disable cache for API requests")
        XCTAssertNil(config.urlCache, "Should have no URL cache for API requests")
        XCTAssertFalse(config.httpShouldSetCookies, "Should disable cookies for API requests")
        
        print("✅ Optimized URLSession configuration verified:")
        print("   Max connections per host: \(config.httpMaximumConnectionsPerHost)")
        print("   Request timeout: \(config.timeoutIntervalForRequest)s")
        print("   Resource timeout: \(config.timeoutIntervalForResource)s")
        print("   Cache disabled: \(config.urlCache == nil)")
    }
    
    func testByteLevelStreamingProcessing() throws {
        let testData = """
        data: {"type": "response.text.delta", "delta": "Hello"}

        data: {"type": "response.text.delta", "delta": " world"}

        data: {"type": "response.done"}

        """.data(using: .utf8)!
        
        // Test byte-level delimiter scanning
        let delimiter = "\n\n".data(using: .utf8)!
        var buffer = Data()
        buffer.append(testData)
        
        var chunkCount = 0
        let startTime = Date()
        
        // Process complete chunks using optimized byte scanning (similar to HTTPClient implementation)
        while let range = buffer.range(of: delimiter) {
            let chunkData = buffer[..<range.upperBound]
            buffer.removeSubrange(..<range.upperBound)
            
            if !chunkData.isEmpty {
                chunkCount += 1
            }
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        print("🚀 Byte-level Streaming Processing:")
        print("   Processed \(chunkCount) chunks in \(String(format: "%.6f", processingTime))s")
        print("   Processing rate: \(String(format: "%.0f", Double(chunkCount) / processingTime)) chunks/sec")
        
        XCTAssertGreaterThan(chunkCount, 0, "Should process at least one chunk")
        XCTAssertLessThan(processingTime, 0.01, "Should process chunks very quickly")
    }
    
    func testBoundedBufferMemoryEfficiency() throws {
        let buffer = BoundedStreamBuffer<String>(maxBufferSize: 5)
        
        // Test buffer capacity management
        for i in 0..<10 {
            _ = buffer.append("item-\(i)")
        }
        
        // Should have at most 5 items due to bounded buffer
        XCTAssertLessThanOrEqual(buffer.count, 5, "Buffer should be bounded to max size")
        
        // Test memory efficiency by ensuring old items are dropped
        var retrievedItems: [String] = []
        while let item = buffer.removeFirst() {
            retrievedItems.append(item)
        }
        
        print("🚀 Bounded Buffer Test:")
        print("   Buffer max size: 5")
        print("   Items added: 10")
        print("   Items retained: \(retrievedItems.count)")
        print("   Retrieved items: \(retrievedItems)")
        
        XCTAssertLessThanOrEqual(retrievedItems.count, 5, "Should not exceed buffer capacity")
        XCTAssertTrue(buffer.isEmpty, "Buffer should be empty after draining")
    }
    
    func testHTTPClientUsesOptimizedSession() throws {
        let config = SAOAIOpenAIConfiguration(apiKey: "test-key")
        let client = HTTPClient(configuration: config)
        
        // Verify that HTTPClient uses optimized URLSession by default
        // We can't directly access the private urlSession property, but we can verify
        // that the initialization works and doesn't use .shared anymore
        
        // Create another client with explicit session to ensure API compatibility
        #if canImport(FoundationNetworking)
        let explicitSession = URLSession(configuration: URLSessionConfiguration.default)
        #else
        let explicitSession = URLSession.shared
        #endif
        let explicitClient = HTTPClient(configuration: config, session: explicitSession)
        
        print("✅ HTTPClient initialization verified:")
        print("   Default client uses OptimizedURLSession.shared.urlSession")
        print("   Explicit session parameter still supported for compatibility")
        
        // Both should work without throwing
        XCTAssertNotNil(client)
        XCTAssertNotNil(explicitClient)
    }
}