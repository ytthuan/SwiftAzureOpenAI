//
//  MetricsDelegate.swift
//  SwiftAzureOpenAI
//
//  Foundation for metrics delegation and correlation ID logging.
//

import Foundation

// MARK: - Metrics Delegate Protocol

/// Protocol for collecting metrics and observability data
public protocol MetricsDelegate: AnyObject {
    /// Called when a request is started
    func requestStarted(_ event: RequestStartedEvent)
    
    /// Called when a request completes successfully
    func requestCompleted(_ event: RequestCompletedEvent)
    
    /// Called when a request fails
    func requestFailed(_ event: RequestFailedEvent)
    
    /// Called for streaming events
    func streamingEvent(_ event: StreamingEvent)
    
    /// Called for cache events
    func cacheEvent(_ event: CacheEvent)
}

// MARK: - Request Events

/// Event fired when a request starts
public struct RequestStartedEvent: Sendable {
    /// Unique correlation ID for the request
    public let correlationId: String
    
    /// Request method (GET, POST, etc.)
    public let method: String
    
    /// Request endpoint
    public let endpoint: String
    
    /// Request timestamp
    public let timestamp: Date
    
    /// Additional metadata
    public let metadata: [String: String]
    
    public init(
        correlationId: String,
        method: String,
        endpoint: String,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.correlationId = correlationId
        self.method = method
        self.endpoint = endpoint
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

/// Event fired when a request completes successfully
public struct RequestCompletedEvent: Sendable {
    /// Correlation ID from the started event
    public let correlationId: String
    
    /// HTTP status code
    public let statusCode: Int
    
    /// Request duration in seconds
    public let duration: TimeInterval
    
    /// Response size in bytes
    public let responseSize: Int
    
    /// Request timestamp
    public let timestamp: Date
    
    /// Response ID from Azure OpenAI (if available)
    public let responseId: String?
    
    /// Additional metadata
    public let metadata: [String: String]
    
    public init(
        correlationId: String,
        statusCode: Int,
        duration: TimeInterval,
        responseSize: Int,
        timestamp: Date = Date(),
        responseId: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.correlationId = correlationId
        self.statusCode = statusCode
        self.duration = duration
        self.responseSize = responseSize
        self.timestamp = timestamp
        self.responseId = responseId
        self.metadata = metadata
    }
}

/// Event fired when a request fails
public struct RequestFailedEvent: Sendable {
    /// Correlation ID from the started event
    public let correlationId: String
    
    /// HTTP status code (if available)
    public let statusCode: Int?
    
    /// Request duration in seconds
    public let duration: TimeInterval
    
    /// Error that caused the failure
    public let error: Error
    
    /// Request timestamp
    public let timestamp: Date
    
    /// Retry attempt number (0 for first attempt)
    public let retryAttempt: Int
    
    /// Additional metadata
    public let metadata: [String: String]
    
    public init(
        correlationId: String,
        statusCode: Int?,
        duration: TimeInterval,
        error: Error,
        timestamp: Date = Date(),
        retryAttempt: Int = 0,
        metadata: [String: String] = [:]
    ) {
        self.correlationId = correlationId
        self.statusCode = statusCode
        self.duration = duration
        self.error = error
        self.timestamp = timestamp
        self.retryAttempt = retryAttempt
        self.metadata = metadata
    }
}

// MARK: - Streaming Events

/// Event fired for streaming operations
public struct StreamingEvent: Sendable {
    /// Correlation ID for the streaming request
    public let correlationId: String
    
    /// Type of streaming event
    public let eventType: StreamingEventType
    
    /// Event timestamp
    public let timestamp: Date
    
    /// Additional data specific to the event type
    public let data: [String: String]  // Use String instead of Any for Sendable
    
    public init(
        correlationId: String,
        eventType: StreamingEventType,
        timestamp: Date = Date(),
        data: [String: String] = [:]
    ) {
        self.correlationId = correlationId
        self.eventType = eventType
        self.timestamp = timestamp
        self.data = data
    }
}

public enum StreamingEventType: Sendable {
    case streamStarted
    case chunkReceived(size: Int)
    case streamCompleted
    case streamError(Error)
    case parsingEvent(eventType: String)
}

// MARK: - Cache Events

/// Event fired for cache operations
public struct CacheEvent: Sendable {
    /// Type of cache event
    public let eventType: CacheEventType
    
    /// Cache key involved in the event
    public let key: String
    
    /// Event timestamp
    public let timestamp: Date
    
    /// Additional metadata
    public let metadata: [String: String]
    
    public init(
        eventType: CacheEventType,
        key: String,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.eventType = eventType
        self.key = key
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

public enum CacheEventType: Sendable {
    case hit
    case miss
    case set
    case eviction
    case expiration
}

// MARK: - Correlation ID Generator

/// Utility for generating correlation IDs
public struct CorrelationIdGenerator {
    /// Generate a new correlation ID
    public static func generate() -> String {
        return UUID().uuidString
    }
    
    /// Generate a short correlation ID (8 characters)
    public static func generateShort() -> String {
        return String(UUID().uuidString.prefix(8))
    }
    
    /// Generate a correlation ID with custom prefix
    public static func generate(prefix: String) -> String {
        return "\(prefix)-\(generateShort())"
    }
}

// MARK: - Default Metrics Implementations

/// Simple console-based metrics delegate for debugging
public final class ConsoleMetricsDelegate: MetricsDelegate {
    private let logLevel: LogLevel
    
    public enum LogLevel: Comparable {
        case minimal    // Only errors
        case normal     // Errors + completion
        case verbose    // All events
    }
    
    public init(logLevel: LogLevel = .normal) {
        self.logLevel = logLevel
    }
    
    public func requestStarted(_ event: RequestStartedEvent) {
        guard logLevel == .verbose else { return }
        print("🚀 Request started [\(event.correlationId)] \(event.method) \(event.endpoint)")
    }
    
    public func requestCompleted(_ event: RequestCompletedEvent) {
        guard logLevel >= .normal else { return }
        let duration = String(format: "%.3fs", event.duration)
        print("✅ Request completed [\(event.correlationId)] \(event.statusCode) (\(duration))")
        if let responseId = event.responseId {
            print("   Response ID: \(responseId)")
        }
    }
    
    public func requestFailed(_ event: RequestFailedEvent) {
        let duration = String(format: "%.3fs", event.duration)
        let status = event.statusCode.map { " \($0)" } ?? ""
        let retry = event.retryAttempt > 0 ? " (retry \(event.retryAttempt))" : ""
        print("❌ Request failed [\(event.correlationId)]\(status) (\(duration))\(retry)")
        print("   Error: \(event.error.localizedDescription)")
    }
    
    public func streamingEvent(_ event: StreamingEvent) {
        guard logLevel == .verbose else { return }
        switch event.eventType {
        case .streamStarted:
            print("🌊 Stream started [\(event.correlationId)]")
        case .chunkReceived(let size):
            print("📦 Chunk received [\(event.correlationId)] \(size) bytes")
        case .streamCompleted:
            print("🏁 Stream completed [\(event.correlationId)]")
        case .streamError(let error):
            print("💥 Stream error [\(event.correlationId)] \(error.localizedDescription)")
        case .parsingEvent(let eventType):
            print("🔍 Parsing event [\(event.correlationId)] \(eventType)")
        }
    }
    
    public func cacheEvent(_ event: CacheEvent) {
        guard logLevel == .verbose else { return }
        let icon = switch event.eventType {
        case .hit: "🎯"
        case .miss: "❓"
        case .set: "💾"
        case .eviction: "🗑️"
        case .expiration: "⏰"
        }
        print("\(icon) Cache \(event.eventType) [\(event.key)]")
    }
}

// MARK: - Aggregating Metrics Delegate

/// Metrics delegate that collects statistics
public final class AggregatingMetricsDelegate: MetricsDelegate, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.swiftazureopenai.metrics", attributes: .concurrent)
    private var _statistics = MetricsStatistics()
    
    public var statistics: MetricsStatistics {
        return queue.sync { _statistics }
    }
    
    public func requestStarted(_ event: RequestStartedEvent) {
        queue.async(flags: .barrier) {
            self._statistics.totalRequests += 1
            self._statistics.activeRequests += 1
        }
    }
    
    public func requestCompleted(_ event: RequestCompletedEvent) {
        queue.async(flags: .barrier) {
            self._statistics.activeRequests -= 1
            self._statistics.successfulRequests += 1
            self._statistics.totalDuration += event.duration
            self._statistics.recordStatusCode(event.statusCode)
        }
    }
    
    public func requestFailed(_ event: RequestFailedEvent) {
        queue.async(flags: .barrier) {
            self._statistics.activeRequests -= 1
            self._statistics.failedRequests += 1
            self._statistics.totalDuration += event.duration
            if let statusCode = event.statusCode {
                self._statistics.recordStatusCode(statusCode)
            }
        }
    }
    
    public func streamingEvent(_ event: StreamingEvent) {
        queue.async(flags: .barrier) {
            self._statistics.streamingEvents += 1
        }
    }
    
    public func cacheEvent(_ event: CacheEvent) {
        queue.async(flags: .barrier) {
            switch event.eventType {
            case .hit:
                self._statistics.cacheHits += 1
            case .miss:
                self._statistics.cacheMisses += 1
            default:
                break
            }
        }
    }
    
    public func reset() {
        queue.async(flags: .barrier) {
            self._statistics = MetricsStatistics()
        }
    }
}

// MARK: - Metrics Statistics

/// Collected metrics statistics
public struct MetricsStatistics {
    public var totalRequests: Int = 0
    public var activeRequests: Int = 0
    public var successfulRequests: Int = 0
    public var failedRequests: Int = 0
    public var totalDuration: TimeInterval = 0
    public var streamingEvents: Int = 0
    public var cacheHits: Int = 0
    public var cacheMisses: Int = 0
    public var statusCodes: [Int: Int] = [:]
    
    public var successRate: Double {
        let completed = successfulRequests + failedRequests
        guard completed > 0 else { return 0.0 }
        return Double(successfulRequests) / Double(completed)
    }
    
    public var averageRequestDuration: TimeInterval {
        let completed = successfulRequests + failedRequests
        guard completed > 0 else { return 0.0 }
        return totalDuration / TimeInterval(completed)
    }
    
    public var cacheHitRate: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0.0 }
        return Double(cacheHits) / Double(total)
    }
    
    mutating func recordStatusCode(_ code: Int) {
        statusCodes[code, default: 0] += 1
    }
}

// MARK: - Usage Example

/*
Example usage:

```swift
// Create a metrics delegate
let metricsDelegate = ConsoleMetricsDelegate(logLevel: .verbose)

// Configure client with metrics delegate
let client = SAOAIResponsesClient(
    configuration: config,
    metricsDelegate: metricsDelegate
)

// Requests will automatically generate correlation IDs and emit metrics events
let response = try await client.responses.create(...)

// Use aggregating delegate for statistics
let aggregatingDelegate = AggregatingMetricsDelegate()
// ... make requests ...

let stats = aggregatingDelegate.statistics
print("Success rate: \(Int(stats.successRate * 100))%")
print("Average duration: \(String(format: "%.3fs", stats.averageRequestDuration))")
print("Cache hit rate: \(Int(stats.cacheHitRate * 100))%")
```
*/