import XCTest
@testable import SwiftAzureOpenAI
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Performance evaluation tests for non-streaming response creation
/// These tests compare the original ResponseService with the optimized version
/// 
/// Note: These tests run only on Linux due to issue #95 with macOS CI library issues.
/// The tests measure response creation performance, memory usage, and throughput.
final class NonStreamingPerformanceTests: XCTestCase {
    
    // MARK: - Test Configuration
    
    private let testTimeout: TimeInterval = 60.0
    private let warmupIterations = 10
    private let measurementIterations = 100
    
    // MARK: - Linux Platform Check
    
    private func skipOnMacOS() throws {
        #if os(macOS)
        throw XCTSkip("Performance tests disabled on macOS due to Swift 6.0 concurrency safety issues (issue #95)")
        #endif
    }
    
    // MARK: - Test Data Generation
    
    private func generateResponseTestData(responseCount: Int = 50, contentSize: Int = 1024) -> [Data] {
        var responses: [Data] = []
        
        for i in 0..<responseCount {
            let content = String(repeating: "Test content for response \(i) ", count: contentSize / 32)
            
            let response = SAOAIResponse(
                id: "response_\(i)",
                model: "gpt-4o",
                created: Int(Date().timeIntervalSince1970),
                output: [
                    SAOAIOutput(
                        content: [
                            .outputText(.init(text: content))
                        ],
                        role: "assistant"
                    )
                ],
                usage: SAOAITokenUsage(
                    inputTokens: 100 + i,
                    outputTokens: 200 + i,
                    totalTokens: 300 + (i * 2)
                )
            )
            
            if let jsonData = try? JSONEncoder().encode(response) {
                responses.append(jsonData)
            }
        }
        
        return responses
    }
    
    private func createMockHTTPResponse(statusCode: Int = 200) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://test.openai.azure.com/openai/v1/responses")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "content-type": "application/json",
                "x-request-id": "test-request-id",
                "openai-processing-ms": "150"
            ]
        )!
    }
    
    // MARK: - Performance Measurement Utilities
    
    private func getCurrentTime() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 0.001 {
            return String(format: "%.1fμs", duration * 1_000_000)
        } else if duration < 1.0 {
            return String(format: "%.1fms", duration * 1000)
        } else {
            return String(format: "%.3fs", duration)
        }
    }
    
    private func formatThroughput(_ count: Int, _ duration: TimeInterval) -> String {
        let throughput = Double(count) / duration
        if throughput > 1000 {
            return String(format: "%.1fk ops/sec", throughput / 1000)
        } else {
            return String(format: "%.1f ops/sec", throughput)
        }
    }
    
    // MARK: - Performance Test Cases
    
    func testResponseCreationPerformanceComparison() async throws {
        try skipOnMacOS()
        
        #if !os(macOS)
        let testData = generateResponseTestData(responseCount: 50, contentSize: 2048)
        let httpResponse = createMockHTTPResponse()
        
        print("🚀 Non-Streaming Response Creation Performance Comparison")
        print("   Test data: \(testData.count) responses, ~2KB each")
        
        // Warm up both services
        let originalService = ResponseService()
        let optimizedService = OptimizedResponseService()
        
        // Warmup runs
        for _ in 0..<warmupIterations {
            for data in testData.prefix(5) {
                _ = try? await originalService.processResponse(data, response: httpResponse, type: SAOAIResponse.self)
                _ = try? await optimizedService.processResponse(data, response: httpResponse, type: SAOAIResponse.self)
            }
        }
        
        // Measure original service performance
        let originalStartTime = getCurrentTime()
        var originalProcessedCount = 0
        
        for _ in 0..<measurementIterations {
            for data in testData {
                do {
                    _ = try await originalService.processResponse(data, response: httpResponse, type: SAOAIResponse.self)
                    originalProcessedCount += 1
                } catch {
                    // Continue on parsing errors for performance measurement
                }
            }
        }
        
        let originalDuration = getCurrentTime() - originalStartTime
        
        // Measure optimized service performance
        let optimizedStartTime = getCurrentTime()
        var optimizedProcessedCount = 0
        
        for _ in 0..<measurementIterations {
            for data in testData {
                do {
                    _ = try await optimizedService.processResponse(data, response: httpResponse, type: SAOAIResponse.self)
                    optimizedProcessedCount += 1
                } catch {
                    // Continue on parsing errors for performance measurement
                }
            }
        }
        
        let optimizedDuration = getCurrentTime() - optimizedStartTime
        
        // Calculate performance metrics
        let originalThroughput = Double(originalProcessedCount) / originalDuration
        let optimizedThroughput = Double(optimizedProcessedCount) / optimizedDuration
        let improvement = (optimizedThroughput - originalThroughput) / originalThroughput * 100
        
        print("📊 Performance Results:")
        print("   Original Service:")
        print("     Duration: \(formatDuration(originalDuration))")
        print("     Throughput: \(formatThroughput(originalProcessedCount, originalDuration))")
        print("   Optimized Service:")
        print("     Duration: \(formatDuration(optimizedDuration))")
        print("     Throughput: \(formatThroughput(optimizedProcessedCount, optimizedDuration))")
        print("   Performance Improvement: \(String(format: "%.1f", improvement))%")
        
        // Assertions
        XCTAssertEqual(originalProcessedCount, optimizedProcessedCount, "Both services should process same number of responses")
        XCTAssertGreaterThanOrEqual(improvement, -5.0, "Optimized service should be within 5% of original performance")
        
        // Target: at least parity, ideally improvement
        if improvement > 5.0 {
            print("✅ Significant performance improvement achieved!")
        } else if improvement > 0 {
            print("✅ Performance improvement detected!")
        } else if improvement > -5.0 {
            print("✅ Performance parity maintained (within 5%)")
        } else {
            print("❌ Performance regression detected")
        }
        #endif
    }
    
    func testResponseParsingOptimizationComparison() async throws {
        try skipOnMacOS()
        
        #if !os(macOS)
        let testData = generateResponseTestData(responseCount: 100, contentSize: 512)
        
        print("🔧 Response Parsing Optimization Comparison")
        print("   Test data: \(testData.count) responses, ~512B each")
        
        // Compare parsers directly
        let originalParser = DefaultResponseParser()
        let optimizedParser = OptimizedResponseParsingService()
        
        // Warm up parsers
        for _ in 0..<warmupIterations {
            for data in testData.prefix(5) {
                _ = try? await originalParser.parse(data, as: SAOAIResponse.self)
                _ = try? await optimizedParser.parse(data, as: SAOAIResponse.self)
            }
        }
        
        // Measure original parser
        let originalStartTime = getCurrentTime()
        var originalParsedCount = 0
        
        for _ in 0..<measurementIterations {
            for data in testData {
                do {
                    _ = try await originalParser.parse(data, as: SAOAIResponse.self)
                    originalParsedCount += 1
                } catch {
                    // Continue on parsing errors
                }
            }
        }
        
        let originalDuration = getCurrentTime() - originalStartTime
        
        // Measure optimized parser
        let optimizedStartTime = getCurrentTime()
        var optimizedParsedCount = 0
        
        for _ in 0..<measurementIterations {
            for data in testData {
                do {
                    _ = try await optimizedParser.parse(data, as: SAOAIResponse.self)
                    optimizedParsedCount += 1
                } catch {
                    // Continue on parsing errors
                }
            }
        }
        
        let optimizedDuration = getCurrentTime() - optimizedStartTime
        
        // Calculate metrics
        let originalThroughput = Double(originalParsedCount) / originalDuration
        let optimizedThroughput = Double(optimizedParsedCount) / optimizedDuration
        let improvement = (optimizedThroughput - originalThroughput) / originalThroughput * 100
        
        print("📊 Parsing Performance Results:")
        print("   Original Parser: \(formatThroughput(originalParsedCount, originalDuration))")
        print("   Optimized Parser: \(formatThroughput(optimizedParsedCount, optimizedDuration))")
        print("   Improvement: \(String(format: "%.1f", improvement))%")
        
        // Verify both parsers produce equivalent results
        XCTAssertEqual(originalParsedCount, optimizedParsedCount, "Both parsers should process same number of responses")
        XCTAssertGreaterThanOrEqual(improvement, -5.0, "Optimized parser should be within 5% of original performance")
        #endif
    }
    
    func testEndToEndResponseCreationBenchmark() async throws {
        try skipOnMacOS()
        
        #if !os(macOS)
        print("🎯 End-to-End Response Creation Benchmark")
        
        // Test with realistic response sizes
        let smallResponses = generateResponseTestData(responseCount: 100, contentSize: 256)  // ~256B
        let mediumResponses = generateResponseTestData(responseCount: 50, contentSize: 2048)  // ~2KB
        let largeResponses = generateResponseTestData(responseCount: 10, contentSize: 16384) // ~16KB
        
        let httpResponse = createMockHTTPResponse()
        
        let testCases = [
            ("Small Responses (256B)", smallResponses),
            ("Medium Responses (2KB)", mediumResponses),
            ("Large Responses (16KB)", largeResponses)
        ]
        
        for (testName, testData) in testCases {
            print("\n📋 Testing \(testName):")
            
            let originalService = ResponseService()
            let optimizedService = OptimizedResponseService()
            
            // Measure original
            let originalStart = getCurrentTime()
            var originalCount = 0
            
            for data in testData {
                do {
                    _ = try await originalService.processResponse(data, response: httpResponse, type: SAOAIResponse.self)
                    originalCount += 1
                } catch {
                    // Continue for benchmark
                }
            }
            
            let originalDuration = getCurrentTime() - originalStart
            
            // Measure optimized
            let optimizedStart = getCurrentTime()
            var optimizedCount = 0
            
            for data in testData {
                do {
                    _ = try await optimizedService.processResponse(data, response: httpResponse, type: SAOAIResponse.self)
                    optimizedCount += 1
                } catch {
                    // Continue for benchmark
                }
            }
            
            let optimizedDuration = getCurrentTime() - optimizedStart
            
            let improvement = originalDuration > 0 
                ? (originalDuration - optimizedDuration) / originalDuration * 100 
                : 0
            
            print("   Original:  \(formatDuration(originalDuration)) (\(formatThroughput(originalCount, originalDuration)))")
            print("   Optimized: \(formatDuration(optimizedDuration)) (\(formatThroughput(optimizedCount, optimizedDuration)))")
            print("   Improvement: \(String(format: "%.1f", improvement))%")
            
            XCTAssertEqual(originalCount, optimizedCount, "Both services should process same count for \(testName)")
        }
        #endif
    }
    
    func testOptimizationIntegrationValidation() async throws {
        try skipOnMacOS()
        
        #if !os(macOS)
        print("🧪 Optimization Integration Validation")
        
        // Verify that optimized services produce identical results to original
        let testData = generateResponseTestData(responseCount: 10, contentSize: 1024)
        let httpResponse = createMockHTTPResponse()
        
        let originalService = ResponseService()
        let optimizedService = OptimizedResponseService()
        
        for (index, data) in testData.enumerated() {
            do {
                let originalResult = try await originalService.processResponse(data, response: httpResponse, type: SAOAIResponse.self)
                let optimizedResult = try await optimizedService.processResponse(data, response: httpResponse, type: SAOAIResponse.self)
                
                // Verify identical parsing results
                XCTAssertEqual(originalResult.data.id, optimizedResult.data.id, "Response ID should match for item \(index)")
                XCTAssertEqual(originalResult.data.model, optimizedResult.data.model, "Model should match for item \(index)")
                XCTAssertEqual(originalResult.data.output.count, optimizedResult.data.output.count, "Output count should match for item \(index)")
                XCTAssertEqual(originalResult.statusCode, optimizedResult.statusCode, "Status code should match for item \(index)")
                
                // Verify metadata extraction
                XCTAssertEqual(originalResult.metadata.requestId, optimizedResult.metadata.requestId, "Request ID should match for item \(index)")
                
            } catch {
                XCTFail("Failed to process test data item \(index): \(error)")
            }
        }
        
        print("✅ Integration validation passed - optimized services produce identical results")
        #endif
    }
}