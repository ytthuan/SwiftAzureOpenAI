import Foundation

/// Log levels for structured logging
public enum LogLevel: String, CaseIterable, Comparable, Sendable {
    case trace = "TRACE"
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        let order: [LogLevel] = [.trace, .debug, .info, .warn, .error]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

/// Context information for structured logging
public struct LogContext: Sendable {
    public let requestId: String?
    public let endpoint: String?
    public let method: String?
    public let statusCode: Int?
    public let duration: TimeInterval?
    public let retryAttempt: Int?
    
    public init(
        requestId: String? = nil,
        endpoint: String? = nil,
        method: String? = nil,
        statusCode: Int? = nil,
        duration: TimeInterval? = nil,
        retryAttempt: Int? = nil
    ) {
        self.requestId = requestId
        self.endpoint = endpoint
        self.method = method
        self.statusCode = statusCode
        self.duration = duration
        self.retryAttempt = retryAttempt
    }
}

/// Protocol for pluggable logger implementations
public protocol SAOAILogger: Sendable {
    func log(level: LogLevel, message: String, context: LogContext?, error: Error?)
}

/// Default console logger implementation
public struct ConsoleLogger: SAOAILogger, Sendable {
    public let minimumLevel: LogLevel
    public let includeTimestamp: Bool
    
    public init(minimumLevel: LogLevel = .info, includeTimestamp: Bool = true) {
        self.minimumLevel = minimumLevel
        self.includeTimestamp = includeTimestamp
    }
    
    public func log(level: LogLevel, message: String, context: LogContext?, error: Error?) {
        guard level >= minimumLevel else { return }
        
        var logMessage = ""
        
        if includeTimestamp {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            logMessage += "[\(formatter.string(from: Date()))] "
        }
        
        logMessage += "[\(level.rawValue)] \(message)"
        
        if let context = context {
            var contextParts: [String] = []
            if let requestId = context.requestId { contextParts.append("requestId=\(requestId)") }
            if let endpoint = context.endpoint { contextParts.append("endpoint=\(endpoint)") }
            if let method = context.method { contextParts.append("method=\(method)") }
            if let statusCode = context.statusCode { contextParts.append("statusCode=\(statusCode)") }
            if let duration = context.duration { contextParts.append("duration=\(String(format: "%.3f", duration))s") }
            if let retryAttempt = context.retryAttempt { contextParts.append("retry=\(retryAttempt)") }
            
            if !contextParts.isEmpty {
                logMessage += " [\(contextParts.joined(separator: ", "))]"
            }
        }
        
        if let error = error {
            logMessage += " error=\(error.localizedDescription)"
        }
        
        print(logMessage)
    }
}

/// Silent logger that discards all log messages
public struct SilentLogger: SAOAILogger, Sendable {
    public init() {}
    
    public func log(level: LogLevel, message: String, context: LogContext?, error: Error?) {
        // Discard all log messages
    }
}

/// Global logger configuration
public struct LoggerConfiguration: Sendable {
    public let logger: SAOAILogger
    public let enabled: Bool
    
    public init(logger: SAOAILogger = ConsoleLogger(), enabled: Bool = false) {
        self.logger = logger
        self.enabled = enabled
    }
    
    public static let disabled = LoggerConfiguration(logger: SilentLogger(), enabled: false)
}

/// Internal logging utility
internal struct InternalLogger: Sendable {
    private let config: LoggerConfiguration
    
    init(config: LoggerConfiguration) {
        self.config = config
    }
    
    func trace(_ message: String, context: LogContext? = nil, error: Error? = nil) {
        log(level: .trace, message: message, context: context, error: error)
    }
    
    func debug(_ message: String, context: LogContext? = nil, error: Error? = nil) {
        log(level: .debug, message: message, context: context, error: error)
    }
    
    func info(_ message: String, context: LogContext? = nil, error: Error? = nil) {
        log(level: .info, message: message, context: context, error: error)
    }
    
    func warn(_ message: String, context: LogContext? = nil, error: Error? = nil) {
        log(level: .warn, message: message, context: context, error: error)
    }
    
    func error(_ message: String, context: LogContext? = nil, error: Error? = nil) {
        log(level: .error, message: message, context: context, error: error)
    }
    
    private func log(level: LogLevel, message: String, context: LogContext?, error: Error?) {
        guard config.enabled else { return }
        config.logger.log(level: level, message: message, context: context, error: error)
    }
}