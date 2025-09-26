import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Configuration for HTTP client timeouts and retry behavior
public struct HTTPClientConfiguration: Sendable {
    public let maxRetries: Int
    public let globalTimeoutInterval: TimeInterval
    public let shouldRetryOnStatusCode: @Sendable (Int) -> Bool
    
    public init(
        maxRetries: Int = 2,
        globalTimeoutInterval: TimeInterval = 60,
        shouldRetryOnStatusCode: @escaping @Sendable (Int) -> Bool = HTTPClientConfiguration.defaultRetryStrategy
    ) {
        self.maxRetries = maxRetries
        self.globalTimeoutInterval = globalTimeoutInterval
        self.shouldRetryOnStatusCode = shouldRetryOnStatusCode
    }
    
    /// Default retry strategy: retry on 429 (rate limit) and 5xx (server errors)
    public static func defaultRetryStrategy(statusCode: Int) -> Bool {
        return statusCode == 429 || (500...599).contains(statusCode)
    }
}

public struct APIRequest: Sendable {
    public let method: String
    public let url: URL
    public let headers: [String: String]
    public let body: Data?
    public let timeoutInterval: TimeInterval?

    public init(
        method: String = "POST", 
        url: URL, 
        headers: [String: String] = [:], 
        body: Data? = nil,
        timeoutInterval: TimeInterval? = nil
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timeoutInterval = timeoutInterval
    }
}

/// Protocol for HTTP client abstraction to enable testing and different implementations
public protocol HTTPClientProtocol: Sendable {
    func send(_ request: APIRequest) async throws -> (Data, HTTPURLResponse)
    func sendStreaming(_ request: APIRequest) -> AsyncThrowingStream<Data, Error>
}

public final class HTTPClient: HTTPClientProtocol, @unchecked Sendable {
    private let configuration: SAOAIConfiguration
    private let urlSession: URLSession
    private let httpConfig: HTTPClientConfiguration
    private let logger: InternalLogger
    private weak var metricsDelegate: MetricsDelegate?

    /// Primary initializer for backward compatibility
    public init(configuration: SAOAIConfiguration, session: URLSession? = nil, maxRetries: Int = 2) {
        let httpConfig = HTTPClientConfiguration(maxRetries: maxRetries)
        self.configuration = configuration
        self.urlSession = session ?? OptimizedURLSession.shared.urlSession
        self.httpConfig = httpConfig
        self.logger = InternalLogger(config: configuration.loggerConfiguration)
        self.metricsDelegate = nil
    }
    
    /// Advanced initializer with full HTTP configuration
    public init(
        configuration: SAOAIConfiguration, 
        session: URLSession? = nil, 
        httpConfig: HTTPClientConfiguration
    ) {
        self.configuration = configuration
        self.urlSession = session ?? OptimizedURLSession.shared.urlSession
        self.httpConfig = httpConfig
        self.logger = InternalLogger(config: configuration.loggerConfiguration)
        self.metricsDelegate = nil
    }
    
    /// Initializer with metrics delegate support
    public init(
        configuration: SAOAIConfiguration,
        session: URLSession? = nil,
        httpConfig: HTTPClientConfiguration = HTTPClientConfiguration(),
        metricsDelegate: MetricsDelegate? = nil
    ) {
        self.configuration = configuration
        self.urlSession = session ?? OptimizedURLSession.shared.urlSession
        self.httpConfig = httpConfig
        self.logger = InternalLogger(config: configuration.loggerConfiguration)
        self.metricsDelegate = metricsDelegate
    }

    public func send(_ request: APIRequest) async throws -> (Data, HTTPURLResponse) {
        let correlationId = CorrelationIdGenerator.generate()
        let startTime = Date()
        var attempts = 0
        var lastError: Error?
        
        let logContext = LogContext(
            requestId: correlationId,
            endpoint: request.url.absoluteString,
            method: request.method
        )
        
        // Emit request started event
        metricsDelegate?.requestStarted(RequestStartedEvent(
            correlationId: correlationId,
            method: request.method,
            endpoint: request.url.absoluteString,
            timestamp: startTime,
            metadata: [:]
        ))
        
        logger.info("Starting HTTP request", context: logContext)

        while attempts <= httpConfig.maxRetries {
            do {
                let urlRequest = try buildURLRequest(from: request)
                
                if attempts > 0 {
                    let retryContext = LogContext(
                        requestId: correlationId,
                        endpoint: request.url.absoluteString,
                        method: request.method,
                        retryAttempt: attempts
                    )
                    logger.info("Retrying HTTP request", context: retryContext)
                }
                
                let (data, response) = try await urlSession.data(for: urlRequest)
                guard let http = response as? HTTPURLResponse else {
                    throw SAOAIError.networkError(URLError(.badServerResponse))
                }
                
                let duration = Date().timeIntervalSince(startTime)
                let responseContext = LogContext(
                    requestId: correlationId,
                    endpoint: request.url.absoluteString,
                    method: request.method,
                    statusCode: http.statusCode,
                    duration: duration,
                    retryAttempt: attempts > 0 ? attempts : nil
                )
                
                // Check if we should retry based on status code
                if attempts < httpConfig.maxRetries && httpConfig.shouldRetryOnStatusCode(http.statusCode) {
                    logger.warn("HTTP request failed, will retry", context: responseContext)
                    attempts += 1
                    let sleepMs = UInt64(pow(2.0, Double(attempts)) * 200.0)
                    try? await Task.sleep(nanoseconds: sleepMs * 1_000_000)
                    continue
                }
                
                logger.info("HTTP request completed", context: responseContext)
                
                // Emit request completed event
                let responseId = extractResponseId(from: http)
                metricsDelegate?.requestCompleted(RequestCompletedEvent(
                    correlationId: correlationId,
                    statusCode: http.statusCode,
                    duration: duration,
                    responseSize: data.count,
                    timestamp: Date(),
                    responseId: responseId,
                    metadata: [:]
                ))
                
                return (data, http)
            } catch {
                lastError = error
                attempts += 1
                
                let errorContext = LogContext(
                    requestId: correlationId,
                    endpoint: request.url.absoluteString,
                    method: request.method,
                    retryAttempt: attempts
                )
                
                if attempts > httpConfig.maxRetries {
                    logger.error("HTTP request failed after all retries", context: errorContext, error: error)
                    break
                } else {
                    logger.warn("HTTP request failed, will retry", context: errorContext, error: error)
                }
                
                let sleepMs = UInt64(pow(2.0, Double(attempts)) * 200.0)
                try? await Task.sleep(nanoseconds: sleepMs * 1_000_000)
            }
        }
        
        // Emit request failed event
        let finalError = SAOAIError.networkError(lastError ?? URLError(.unknown))
        metricsDelegate?.requestFailed(RequestFailedEvent(
            correlationId: correlationId,
            statusCode: nil,
            duration: Date().timeIntervalSince(startTime),
            error: finalError,
            timestamp: Date(),
            retryAttempt: attempts - 1,
            metadata: [:]
        ))
        
        throw finalError
    }
    
    /// Send a streaming request that returns Server-Sent Events with optimized performance
    public func sendStreaming(_ request: APIRequest) -> AsyncThrowingStream<Data, Error> {
        let configuration = self.configuration
        let urlSession = self.urlSession
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var urlRequest = URLRequest(url: request.url)
                    urlRequest.httpMethod = request.method
                    var finalHeaders = configuration.headers
                    request.headers.forEach { finalHeaders[$0.key] = $0.value }
                    for (key, value) in finalHeaders { urlRequest.setValue(value, forHTTPHeaderField: key) }
                    urlRequest.httpBody = request.body
                    urlRequest.timeoutInterval = request.timeoutInterval ?? httpConfig.globalTimeoutInterval
                    
                    // Add streaming headers if this is a streaming request
                    if request.headers["Accept"] == "text/event-stream" {
                        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                        urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                        urlRequest.setValue("keep-alive", forHTTPHeaderField: "Connection")
                    }
                    
                    #if canImport(FoundationNetworking)
                    // For Linux/FoundationNetworking, use optimized byte-level streaming simulation
                    let (data, response) = try await urlSession.data(for: urlRequest)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: SAOAIError.networkError(URLError(.badServerResponse)))
                        return
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        let error = SAOAIError.from(statusCode: httpResponse.statusCode) ?? SAOAIError.serverError(statusCode: httpResponse.statusCode)
                        continuation.finish(throwing: error)
                        return
                    }
                    
                    // Use byte-level delimiter scanning to reduce string allocations
                    let delimiter = "\n\n".data(using: .utf8)!
                    var buffer = Data()
                    buffer.reserveCapacity(8192) // Pre-allocate larger buffer
                    buffer.append(data)
                    
                    // Process complete chunks using optimized byte scanning
                    while let range = buffer.range(of: delimiter) {
                        let chunkData = buffer[..<range.upperBound]
                        buffer.removeSubrange(..<range.upperBound)
                        
                        if !chunkData.isEmpty {
                            // Use optimized completion check first
                            if OptimizedSSEParser.isCompletionChunkOptimized(chunkData) {
                                continuation.finish()
                                return
                            }
                            
                            continuation.yield(chunkData)
                        }
                    }
                    
                    // Process remaining data if any
                    if !buffer.isEmpty {
                        let finalChunk = buffer + delimiter
                        if OptimizedSSEParser.isCompletionChunkOptimized(finalChunk) {
                            continuation.finish()
                            return
                        }
                        continuation.yield(finalChunk)
                    }
                    
                    continuation.finish()
                    #else
                    // For newer platforms with streaming support
                    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                        let (asyncBytes, response) = try await urlSession.bytes(for: urlRequest)
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            continuation.finish(throwing: SAOAIError.networkError(URLError(.badServerResponse)))
                            return
                        }
                        
                        guard httpResponse.statusCode == 200 else {
                            // Read error response if available
                            var errorData = Data()
                            for try await byte in asyncBytes {
                                errorData.append(byte)
                            }
                            let error = SAOAIError.from(statusCode: httpResponse.statusCode) ?? SAOAIError.serverError(statusCode: httpResponse.statusCode)
                            continuation.finish(throwing: error)
                            return
                        }
                        
                        // Optimized streaming processing for better performance
                        var buffer = Data()
                        buffer.reserveCapacity(8192) // Pre-allocate larger buffer
                        
                        for try await byte in asyncBytes {
                            buffer.append(byte)
                            
                            // Process complete chunks (ending with \n\n) for better efficiency
                            let delimiter = "\n\n".data(using: .utf8)!
                            while let range = buffer.range(of: delimiter) {
                                let chunkData = buffer[..<range.upperBound] // Include delimiter
                                buffer.removeSubrange(..<range.upperBound)
                                
                                if !chunkData.isEmpty {
                                    // Use optimized completion check first
                                    if OptimizedSSEParser.isCompletionChunkOptimized(chunkData) {
                                        continuation.finish()
                                        return
                                    }
                                    
                                    continuation.yield(chunkData)
                                }
                            }
                        }
                        
                        // Process any remaining data in buffer as final chunk
                        if !buffer.isEmpty {
                            let finalChunk = buffer + "\n\n".data(using: .utf8)!
                            continuation.yield(finalChunk)
                        }
                        
                        continuation.finish()
                    } else {
                        // Fallback for older platforms
                        let (data, response) = try await urlSession.data(for: urlRequest)
                        guard let httpResponse = response as? HTTPURLResponse else {
                            continuation.finish(throwing: SAOAIError.networkError(URLError(.badServerResponse)))
                            return
                        }
                        
                        guard httpResponse.statusCode == 200 else {
                            let error = SAOAIError.from(statusCode: httpResponse.statusCode) ?? SAOAIError.serverError(statusCode: httpResponse.statusCode)
                            continuation.finish(throwing: error)
                            return
                        }
                        
                        // Use optimized byte-level streaming for older platforms
                        let delimiter = "\n\n".data(using: .utf8)!
                        var buffer = Data()
                        buffer.reserveCapacity(8192) // Pre-allocate larger buffer
                        buffer.append(data)
                        
                        // Process complete chunks using optimized byte scanning
                        while let range = buffer.range(of: delimiter) {
                            let chunkData = buffer[..<range.upperBound]
                            buffer.removeSubrange(..<range.upperBound)
                            
                            if !chunkData.isEmpty {
                                // Use optimized completion check first
                                if OptimizedSSEParser.isCompletionChunkOptimized(chunkData) {
                                    continuation.finish()
                                    return
                                }
                                
                                continuation.yield(chunkData)
                            }
                        }
                        
                        // Process remaining data if any
                        if !buffer.isEmpty {
                            let finalChunk = buffer + delimiter
                            if OptimizedSSEParser.isCompletionChunkOptimized(finalChunk) {
                                continuation.finish()
                                return
                            }
                            continuation.yield(finalChunk)
                        }
                        continuation.finish()
                    }
                    #endif
                } catch {
                    continuation.finish(throwing: SAOAIError.networkError(error))
                }
            }
        }
    }

    private func buildURLRequest(from request: APIRequest) throws -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        var finalHeaders = configuration.headers
        request.headers.forEach { finalHeaders[$0.key] = $0.value }
        for (key, value) in finalHeaders { urlRequest.setValue(value, forHTTPHeaderField: key) }
        urlRequest.httpBody = request.body
        
        // Use request-specific timeout if provided, otherwise use global timeout
        urlRequest.timeoutInterval = request.timeoutInterval ?? httpConfig.globalTimeoutInterval
        
        // Add streaming headers if this is a streaming request
        if request.headers["Accept"] == "text/event-stream" {
            urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        }
        
        return urlRequest
    }
    
    /// Extract response ID from HTTP response headers for correlation tracking
    private func extractResponseId(from response: HTTPURLResponse) -> String? {
        // Check common headers where response IDs might be found
        return response.value(forHTTPHeaderField: "x-request-id") ??
               response.value(forHTTPHeaderField: "x-ms-request-id") ??
               response.value(forHTTPHeaderField: "request-id")
    }
}

