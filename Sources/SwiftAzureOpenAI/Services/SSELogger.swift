import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Configuration for SSE event logging
public struct SSELoggerConfiguration: Sendable {
    public let isEnabled: Bool
    public let logFilePath: String?
    public let includeTimestamp: Bool
    public let includeSequenceNumber: Bool
    
    /// Default configuration with logging disabled
    public static let disabled = SSELoggerConfiguration(
        isEnabled: false,
        logFilePath: nil,
        includeTimestamp: false,
        includeSequenceNumber: false
    )
    
    /// Configuration for enabled logging
    /// - Parameters:
    ///   - logFilePath: Path to the log file. If nil, logs to default location
    ///   - includeTimestamp: Whether to include timestamps in log entries
    ///   - includeSequenceNumber: Whether to include sequence numbers in log entries
    public static func enabled(
        logFilePath: String? = nil,
        includeTimestamp: Bool = true,
        includeSequenceNumber: Bool = true
    ) -> SSELoggerConfiguration {
        SSELoggerConfiguration(
            isEnabled: true,
            logFilePath: logFilePath,
            includeTimestamp: includeTimestamp,
            includeSequenceNumber: includeSequenceNumber
        )
    }
    
    public init(isEnabled: Bool, logFilePath: String?, includeTimestamp: Bool, includeSequenceNumber: Bool) {
        self.isEnabled = isEnabled
        self.logFilePath = logFilePath
        self.includeTimestamp = includeTimestamp
        self.includeSequenceNumber = includeSequenceNumber
    }
}

/// Logger for SSE events to help with diagnostics and debugging
public final class SSELogger: Sendable {
    private let configuration: SSELoggerConfiguration
    private let fileHandle: FileHandle?
    private let logQueue = DispatchQueue(label: "SSELogger", qos: .utility)
    
    public init(configuration: SSELoggerConfiguration) {
        self.configuration = configuration
        
        if configuration.isEnabled {
            let logPath = configuration.logFilePath ?? Self.defaultLogPath()
            
            // Ensure directory exists
            let logURL = URL(fileURLWithPath: logPath)
            let directoryURL = logURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            // Create or append to log file
            if !FileManager.default.fileExists(atPath: logPath) {
                _ = FileManager.default.createFile(atPath: logPath, contents: nil)
            }
            
            self.fileHandle = FileHandle(forWritingAtPath: logPath)
            
            // Write session header
            if let handle = fileHandle {
                let header = "=== SSE Event Log Session Started: \(Date()) ===\n"
                if let headerData = header.data(using: .utf8) {
                    handle.seekToEndOfFile()
                    handle.write(headerData)
                }
            }
        } else {
            self.fileHandle = nil
        }
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    /// Log an SSE event
    /// - Parameters:
    ///   - event: The Azure OpenAI SSE event to log
    ///   - rawData: Optional raw data for additional context
    public func logEvent(_ event: AzureOpenAISSEEvent, rawData: Data? = nil) {
        guard configuration.isEnabled, let fileHandle = fileHandle else { return }
        
        logQueue.async { [weak self] in
            self?.writeLogEntry(event: event, rawData: rawData, fileHandle: fileHandle)
        }
    }
    
    /// Log raw SSE chunk data
    /// - Parameter data: Raw SSE data chunk
    public func logRawChunk(_ data: Data) {
        guard configuration.isEnabled, let fileHandle = fileHandle else { return }
        
        logQueue.async { [weak self] in
            self?.writeRawChunkEntry(data: data, fileHandle: fileHandle)
        }
    }
    
    private func writeLogEntry(event: AzureOpenAISSEEvent, rawData: Data?, fileHandle: FileHandle) {
        var logEntry = ""
        
        // Add timestamp if configured
        if configuration.includeTimestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            logEntry += "[\(formatter.string(from: Date()))] "
        }
        
        // Add sequence number if configured and available
        if configuration.includeSequenceNumber, let sequenceNumber = event.sequenceNumber {
            logEntry += "[#\(sequenceNumber)] "
        }
        
        // Add event type
        logEntry += "EVENT: \(event.type)"
        
        // Add item info if available
        if let itemId = event.itemId {
            logEntry += " | ITEM_ID: \(itemId)"
        }
        
        if let item = event.item {
            if let itemType = item.type {
                logEntry += " | ITEM_TYPE: \(itemType)"
            }
            if let status = item.status {
                logEntry += " | STATUS: \(status)"
            }
        }
        
        // Add output index if available
        if let outputIndex = event.outputIndex {
            logEntry += " | OUTPUT_IDX: \(outputIndex)"
        }
        
        // Add delta content if available
        if let delta = event.delta {
            let truncatedDelta = delta.count > 100 ? String(delta.prefix(100)) + "..." : delta
            logEntry += " | DELTA: \"\(truncatedDelta)\""
        }
        
        // Add arguments if available
        if let arguments = event.arguments {
            let truncatedArgs = arguments.count > 200 ? String(arguments.prefix(200)) + "..." : arguments
            logEntry += " | ARGS: \(truncatedArgs)"
        }
        
        logEntry += "\n"
        
        // Add raw data if provided and event is code interpreter related
        if let rawData = rawData, event.type.contains("code_interpreter") {
            if let rawString = String(data: rawData, encoding: .utf8) {
                let truncatedRaw = rawString.count > 300 ? String(rawString.prefix(300)) + "..." : rawString
                logEntry += "    RAW: \(truncatedRaw.replacingOccurrences(of: "\n", with: "\\n"))\n"
            }
        }
        
        if let logData = logEntry.data(using: .utf8) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(logData)
        }
    }
    
    private func writeRawChunkEntry(data: Data, fileHandle: FileHandle) {
        guard let rawString = String(data: data, encoding: .utf8) else { return }
        
        var logEntry = ""
        
        if configuration.includeTimestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            logEntry += "[\(formatter.string(from: Date()))] "
        }
        
        logEntry += "RAW_CHUNK: \(rawString.replacingOccurrences(of: "\n", with: "\\n"))\n"
        
        if let logData = logEntry.data(using: .utf8) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(logData)
        }
    }
    
    private static func defaultLogPath() -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let logFileName = "sse_events_\(Date().timeIntervalSince1970).log"
        return tempDir.appendingPathComponent(logFileName).path
    }
}