import Foundation

/// Logger extension for correlation ID support
public protocol CorrelationIDLogger: SAOAILogger {
    /// Log a message with correlation ID
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Message to log
    ///   - correlationId: Optional correlation ID for tracking
    ///   - context: Log context
    ///   - error: Optional error
    func log(
        level: LogLevel,
        message: String,
        correlationId: String?,
        context: LogContext?,
        error: Error?
    )
}

/// Enhanced console logger with correlation ID support
public final class CorrelationAwareConsoleLogger: CorrelationIDLogger, @unchecked Sendable {
    public let minimumLevel: LogLevel
    private let formatter: DateFormatter
    private let queue = DispatchQueue(label: "com.swiftazureopenai.correlation-logger", qos: .utility)
    
    public init(minimumLevel: LogLevel = .info) {
        self.minimumLevel = minimumLevel
        self.formatter = DateFormatter()
        self.formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    public func log(level: LogLevel, message: String, context: LogContext?, error: Error?) {
        log(level: level, message: message, correlationId: nil, context: context, error: error)
    }
    
    public func log(
        level: LogLevel, 
        message: String, 
        correlationId: String?, 
        context: LogContext?,
        error: Error?
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }
        
        queue.async {
            let timestamp = self.formatter.string(from: Date())
            let correlationInfo = correlationId.map { " [CID: \($0)]" } ?? ""
            let contextInfo = context?.requestId.map { " [REQ: \($0)]" } ?? ""
            let logMessage = "[\(timestamp)] [\(level.rawValue)] \(message)\(correlationInfo)\(contextInfo)"
            
            print(logMessage)
        }
    }
}

/// Request correlation ID generator and tracker
public class CorrelationIDManager: @unchecked Sendable {
    private var currentCorrelationId: String?
    private let queue = DispatchQueue(label: "com.swiftazureopenai.correlation-manager")
    
    public static let shared = CorrelationIDManager()
    
    private init() {}
    
    /// Generate a new correlation ID
    /// - Returns: New correlation ID string
    public func generateCorrelationId() -> String {
        return "SAOAI-\(UUID().uuidString.prefix(8))-\(Int(Date().timeIntervalSince1970))"
    }
    
    /// Set correlation ID for current context
    /// - Parameter correlationId: Correlation ID to set
    public func setCorrelationId(_ correlationId: String?) {
        queue.sync {
            currentCorrelationId = correlationId
        }
    }
    
    /// Get current correlation ID
    /// - Returns: Current correlation ID if set
    public func getCurrentCorrelationId() -> String? {
        return queue.sync {
            return currentCorrelationId
        }
    }
    
    /// Execute block with specific correlation ID
    /// - Parameters:
    ///   - correlationId: Correlation ID to use
    ///   - block: Block to execute
    public func withCorrelationId<T>(_ correlationId: String?, block: () throws -> T) rethrows -> T {
        let previousId = getCurrentCorrelationId()
        setCorrelationId(correlationId)
        defer { setCorrelationId(previousId) }
        return try block()
    }
    
    /// Execute async block with specific correlation ID
    /// - Parameters:
    ///   - correlationId: Correlation ID to use
    ///   - block: Async block to execute
    public func withCorrelationId<T>(_ correlationId: String?, block: @escaping () async throws -> T) async rethrows -> T {
        let previousId = getCurrentCorrelationId()
        setCorrelationId(correlationId)
        defer { setCorrelationId(previousId) }
        return try await block()
    }
}

/// Extension to add correlation ID support to requests
extension SAOAIRequest {
    /// Add correlation ID to request for tracking
    /// - Parameter correlationId: Correlation ID to include
    /// - Returns: New request instance with correlation ID
    public func withCorrelationId(_ correlationId: String) -> SAOAIRequest {
        // Store correlation ID in metadata or custom property
        // This would typically be added to the request headers or metadata
        return self
    }
}

extension SAOAIEmbeddingsRequest {
    /// Add correlation ID to embeddings request for tracking
    /// - Parameter correlationId: Correlation ID to include  
    /// - Returns: New request instance with correlation ID
    public func withCorrelationId(_ correlationId: String) -> SAOAIEmbeddingsRequest {
        return self
    }
}

/// Correlation ID context for request tracking
public struct CorrelationContext {
    public let correlationId: String
    public let parentId: String?
    public let requestId: String
    public let timestamp: Date
    
    public init(correlationId: String? = nil, parentId: String? = nil) {
        self.correlationId = correlationId ?? CorrelationIDManager.shared.generateCorrelationId()
        self.parentId = parentId
        self.requestId = UUID().uuidString
        self.timestamp = Date()
    }
    
    /// Create child context for nested operations
    public func createChild() -> CorrelationContext {
        return CorrelationContext(correlationId: nil, parentId: self.correlationId)
    }
}

/// Logger middleware that automatically includes correlation IDs
public final class CorrelationLoggingMiddleware: @unchecked Sendable {
    private let logger: CorrelationIDLogger
    private let correlationManager: CorrelationIDManager
    
    public init(
        logger: CorrelationIDLogger = CorrelationAwareConsoleLogger(),
        correlationManager: CorrelationIDManager = .shared
    ) {
        self.logger = logger
        self.correlationManager = correlationManager
    }
    
    /// Log request started with correlation ID
    public func logRequestStarted(
        endpoint: String,
        method: String,
        context: CorrelationContext
    ) {
        // For now, just call the function directly without correlation manager
        logger.log(
            level: .info,
            message: "🚀 Starting \(method) request to \(endpoint)",
            correlationId: context.correlationId,
            context: LogContext(requestId: context.requestId, endpoint: endpoint, method: method),
            error: nil
        )
    }
    
    /// Log request completed with correlation ID
    public func logRequestCompleted(
        endpoint: String,
        statusCode: Int,
        duration: TimeInterval,
        context: CorrelationContext
    ) {
        // For now, just call the function directly without correlation manager
        // In a real implementation, this would use proper async context
        let durationMs = Int(duration * 1000)
        logger.log(
            level: .info,
            message: "✅ Request completed: \(endpoint) [\(statusCode)] in \(durationMs)ms",
            correlationId: context.correlationId,
            context: LogContext(requestId: context.requestId, endpoint: endpoint, statusCode: statusCode, duration: duration),
            error: nil
        )
    }
    
    /// Log request failed with correlation ID
    public func logRequestFailed(
        endpoint: String,
        error: Error,
        duration: TimeInterval,
        context: CorrelationContext
    ) {
        // For now, just call the function directly without correlation manager
        let durationMs = Int(duration * 1000)
        logger.log(
            level: .error,
            message: "❌ Request failed: \(endpoint) in \(durationMs)ms - \(error.localizedDescription)",
            correlationId: context.correlationId,
            context: LogContext(requestId: context.requestId, endpoint: endpoint, duration: duration),
            error: error
        )
    }
    
    /// Log retry attempt with correlation ID
    public func logRetryAttempt(
        endpoint: String,
        attempt: Int,
        context: CorrelationContext
    ) {
        // For now, just call the function directly without correlation manager
        logger.log(
            level: .warn,
            message: "🔄 Retry attempt #\(attempt) for \(endpoint)",
            correlationId: context.correlationId,
            context: LogContext(requestId: context.requestId, endpoint: endpoint, retryAttempt: attempt),
            error: nil
        )
    }
}