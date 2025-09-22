import Foundation

/// Protocol for receiving metrics from API requests
public protocol MetricsDelegate: AnyObject {
    /// Called when a request is started
    /// - Parameters:
    ///   - requestId: Unique request identifier
    ///   - endpoint: API endpoint being called
    ///   - method: HTTP method
    ///   - correlationId: Optional correlation ID for tracking
    func requestStarted(
        requestId: String,
        endpoint: String, 
        method: String,
        correlationId: String?
    )
    
    /// Called when a request completes successfully
    /// - Parameters:
    ///   - requestId: Unique request identifier
    ///   - endpoint: API endpoint
    ///   - statusCode: HTTP status code
    ///   - duration: Request duration in seconds
    ///   - responseSize: Response size in bytes
    ///   - correlationId: Optional correlation ID
    func requestCompleted(
        requestId: String,
        endpoint: String,
        statusCode: Int,
        duration: TimeInterval,
        responseSize: Int?,
        correlationId: String?
    )
    
    /// Called when a request fails
    /// - Parameters:
    ///   - requestId: Unique request identifier
    ///   - endpoint: API endpoint
    ///   - error: The error that occurred
    ///   - duration: Request duration in seconds
    ///   - statusCode: HTTP status code if available
    ///   - correlationId: Optional correlation ID
    func requestFailed(
        requestId: String,
        endpoint: String,
        error: Error,
        duration: TimeInterval,
        statusCode: Int?,
        correlationId: String?
    )
    
    /// Called when a retry is attempted
    /// - Parameters:
    ///   - requestId: Unique request identifier
    ///   - endpoint: API endpoint
    ///   - attempt: Retry attempt number (1-based)
    ///   - correlationId: Optional correlation ID
    func retryAttempted(
        requestId: String,
        endpoint: String,
        attempt: Int,
        correlationId: String?
    )
}

/// Request metrics data for aggregation and analysis
public struct RequestMetrics: Codable, Equatable {
    public let requestId: String
    public let endpoint: String
    public let method: String
    public let statusCode: Int?
    public let duration: TimeInterval
    public let responseSize: Int?
    public let error: String?
    public let retryCount: Int
    public let correlationId: String?
    public let timestamp: Date
    
    public init(
        requestId: String,
        endpoint: String,
        method: String,
        statusCode: Int? = nil,
        duration: TimeInterval,
        responseSize: Int? = nil,
        error: String? = nil,
        retryCount: Int = 0,
        correlationId: String? = nil,
        timestamp: Date = Date()
    ) {
        self.requestId = requestId
        self.endpoint = endpoint
        self.method = method
        self.statusCode = statusCode
        self.duration = duration
        self.responseSize = responseSize
        self.error = error
        self.retryCount = retryCount
        self.correlationId = correlationId
        self.timestamp = timestamp
    }
}

/// Metrics collector that aggregates request metrics
public final class MetricsCollector: MetricsDelegate, @unchecked Sendable {
    private var metrics: [RequestMetrics] = []
    private var activeRequests: [String: RequestTracker] = [:]
    private let queue = DispatchQueue(label: "com.swiftazureopenai.metrics", attributes: .concurrent)
    private let maxMetricsCount: Int
    
    /// Initialize metrics collector
    /// - Parameter maxMetricsCount: Maximum number of metrics to retain (default: 1000)
    public init(maxMetricsCount: Int = 1000) {
        self.maxMetricsCount = maxMetricsCount
    }
    
    public func requestStarted(
        requestId: String, 
        endpoint: String, 
        method: String, 
        correlationId: String?
    ) {
        queue.async(flags: .barrier) {
            self.activeRequests[requestId] = RequestTracker(
                endpoint: endpoint,
                method: method,
                correlationId: correlationId,
                startTime: Date(),
                retryCount: 0
            )
        }
    }
    
    public func requestCompleted(
        requestId: String, 
        endpoint: String, 
        statusCode: Int, 
        duration: TimeInterval, 
        responseSize: Int?, 
        correlationId: String?
    ) {
        queue.async(flags: .barrier) {
            guard let tracker = self.activeRequests.removeValue(forKey: requestId) else { return }
            
            let metric = RequestMetrics(
                requestId: requestId,
                endpoint: endpoint,
                method: tracker.method,
                statusCode: statusCode,
                duration: duration,
                responseSize: responseSize,
                retryCount: tracker.retryCount,
                correlationId: correlationId
            )
            
            self.addMetric(metric)
        }
    }
    
    public func requestFailed(
        requestId: String, 
        endpoint: String, 
        error: Error, 
        duration: TimeInterval, 
        statusCode: Int?, 
        correlationId: String?
    ) {
        queue.async(flags: .barrier) {
            guard let tracker = self.activeRequests.removeValue(forKey: requestId) else { return }
            
            let metric = RequestMetrics(
                requestId: requestId,
                endpoint: endpoint,
                method: tracker.method,
                statusCode: statusCode,
                duration: duration,
                error: error.localizedDescription,
                retryCount: tracker.retryCount,
                correlationId: correlationId
            )
            
            self.addMetric(metric)
        }
    }
    
    public func retryAttempted(
        requestId: String, 
        endpoint: String, 
        attempt: Int, 
        correlationId: String?
    ) {
        queue.async(flags: .barrier) {
            self.activeRequests[requestId]?.retryCount = attempt
        }
    }
    
    /// Get aggregated metrics
    public func getMetrics() -> [RequestMetrics] {
        return queue.sync {
            return Array(metrics)
        }
    }
    
    /// Get metrics summary
    public func getMetricsSummary() -> MetricsSummary {
        return queue.sync {
            return MetricsSummary(metrics: metrics)
        }
    }
    
    /// Clear all metrics
    public func clearMetrics() {
        queue.async(flags: .barrier) {
            self.metrics.removeAll()
        }
    }
    
    private func addMetric(_ metric: RequestMetrics) {
        metrics.append(metric)
        
        // Keep only the most recent metrics
        if metrics.count > maxMetricsCount {
            metrics.removeFirst(metrics.count - maxMetricsCount)
        }
    }
}

/// Summary of collected metrics
public struct MetricsSummary: Codable, Equatable {
    public let totalRequests: Int
    public let successfulRequests: Int
    public let failedRequests: Int
    public let averageDuration: TimeInterval
    public let averageResponseSize: Double
    public let statusCodeDistribution: [Int: Int]
    public let endpointDistribution: [String: Int]
    public let errorDistribution: [String: Int]
    public let totalRetries: Int
    
    public var successRate: Double {
        return totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) : 0.0
    }
    
    public var averageRetries: Double {
        return totalRequests > 0 ? Double(totalRetries) / Double(totalRequests) : 0.0
    }
    
    internal init(metrics: [RequestMetrics]) {
        self.totalRequests = metrics.count
        
        let successful = metrics.filter { ($0.statusCode ?? 0) >= 200 && ($0.statusCode ?? 0) < 300 }
        self.successfulRequests = successful.count
        self.failedRequests = totalRequests - successfulRequests
        
        self.averageDuration = totalRequests > 0 ? 
            metrics.map(\.duration).reduce(0, +) / Double(totalRequests) : 0.0
        
        let responseSizes = metrics.compactMap(\.responseSize)
        self.averageResponseSize = responseSizes.isEmpty ? 0.0 :
            Double(responseSizes.reduce(0, +)) / Double(responseSizes.count)
        
        // Status code distribution
        var statusCodes: [Int: Int] = [:]
        for metric in metrics {
            if let statusCode = metric.statusCode {
                statusCodes[statusCode, default: 0] += 1
            }
        }
        self.statusCodeDistribution = statusCodes
        
        // Endpoint distribution
        var endpoints: [String: Int] = [:]
        for metric in metrics {
            endpoints[metric.endpoint, default: 0] += 1
        }
        self.endpointDistribution = endpoints
        
        // Error distribution
        var errors: [String: Int] = [:]
        for metric in metrics {
            if let error = metric.error {
                errors[error, default: 0] += 1
            }
        }
        self.errorDistribution = errors
        
        self.totalRetries = metrics.map(\.retryCount).reduce(0, +)
    }
}

/// Tracks active request state
private class RequestTracker {
    let endpoint: String
    let method: String
    let correlationId: String?
    let startTime: Date
    var retryCount: Int
    
    init(endpoint: String, method: String, correlationId: String?, startTime: Date, retryCount: Int) {
        self.endpoint = endpoint
        self.method = method
        self.correlationId = correlationId
        self.startTime = startTime
        self.retryCount = retryCount
    }
}

/// Console metrics delegate that prints metrics to console
public class ConsoleMetricsDelegate: MetricsDelegate {
    private let logger: SAOAILogger
    
    public init(logger: SAOAILogger = ConsoleLogger(minimumLevel: .info)) {
        self.logger = logger
    }
    
    public func requestStarted(requestId: String, endpoint: String, method: String, correlationId: String?) {
        let correlationInfo = correlationId.map { " [correlation: \($0)]" } ?? ""
        logger.log(level: .info, message: "🚀 Request started: \(method) \(endpoint) [id: \(requestId)]\(correlationInfo)", context: LogContext(requestId: requestId, endpoint: endpoint, method: method), error: nil)
    }
    
    public func requestCompleted(
        requestId: String, 
        endpoint: String, 
        statusCode: Int, 
        duration: TimeInterval, 
        responseSize: Int?, 
        correlationId: String?
    ) {
        let durationMs = Int(duration * 1000)
        let sizeInfo = responseSize.map { " (\($0) bytes)" } ?? ""
        let correlationInfo = correlationId.map { " [correlation: \($0)]" } ?? ""
        logger.log(level: .info, message: "✅ Request completed: \(endpoint) [\(statusCode)] in \(durationMs)ms\(sizeInfo) [id: \(requestId)]\(correlationInfo)", context: LogContext(requestId: requestId, endpoint: endpoint, statusCode: statusCode, duration: duration), error: nil)
    }
    
    public func requestFailed(
        requestId: String, 
        endpoint: String, 
        error: Error, 
        duration: TimeInterval, 
        statusCode: Int?, 
        correlationId: String?
    ) {
        let durationMs = Int(duration * 1000)
        let statusInfo = statusCode.map { " [\($0)]" } ?? ""
        let correlationInfo = correlationId.map { " [correlation: \($0)]" } ?? ""
        logger.log(level: .error, message: "❌ Request failed: \(endpoint)\(statusInfo) in \(durationMs)ms - \(error.localizedDescription) [id: \(requestId)]\(correlationInfo)", context: LogContext(requestId: requestId, endpoint: endpoint, statusCode: statusCode, duration: duration), error: error)
    }
    
    public func retryAttempted(requestId: String, endpoint: String, attempt: Int, correlationId: String?) {
        let correlationInfo = correlationId.map { " [correlation: \($0)]" } ?? ""
        logger.log(level: .warn, message: "🔄 Retry attempt #\(attempt): \(endpoint) [id: \(requestId)]\(correlationInfo)", context: LogContext(requestId: requestId, endpoint: endpoint, retryAttempt: attempt), error: nil)
    }
}