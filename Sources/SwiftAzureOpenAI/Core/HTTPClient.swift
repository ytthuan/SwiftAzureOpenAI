import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct APIRequest: Sendable {
    public let method: String
    public let url: URL
    public let headers: [String: String]
    public let body: Data?

    public init(method: String = "POST", url: URL, headers: [String: String] = [:], body: Data? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

public final class HTTPClient: @unchecked Sendable {
    private let configuration: SAOAIConfiguration
    private let urlSession: URLSession
    private let maxRetries: Int

    public init(configuration: SAOAIConfiguration, session: URLSession = .shared, maxRetries: Int = 2) {
        self.configuration = configuration
        self.urlSession = session
        self.maxRetries = maxRetries
    }

    public func send(_ request: APIRequest) async throws -> (Data, HTTPURLResponse) {
        var attempts = 0
        var lastError: Error?

        while attempts <= maxRetries {
            do {
                let urlRequest = try buildURLRequest(from: request)
                let (data, response) = try await urlSession.data(for: urlRequest)
                guard let http = response as? HTTPURLResponse else {
                    throw SAOAIError.networkError(URLError(.badServerResponse))
                }
                return (data, http)
            } catch {
                lastError = error
                attempts += 1
                if attempts > maxRetries { break }
                let sleepMs = UInt64(pow(2.0, Double(attempts)) * 200.0)
                try? await Task.sleep(nanoseconds: sleepMs * 1_000_000)
            }
        }
        throw SAOAIError.networkError(lastError ?? URLError(.unknown))
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
                    urlRequest.timeoutInterval = 60
                    
                    // Add streaming headers if this is a streaming request
                    if request.headers["Accept"] == "text/event-stream" {
                        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                        urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                        urlRequest.setValue("keep-alive", forHTTPHeaderField: "Connection")
                    }
                    
                    #if canImport(FoundationNetworking)
                    // For Linux/FoundationNetworking, use data(for:) and simulate streaming
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
                    
                    // Optimized streaming simulation for better performance
                    if let responseString = String(data: data, encoding: .utf8) {
                        // Use optimized line processing
                        let lines = responseString.components(separatedBy: .newlines)
                        var buffer = Data()
                        buffer.reserveCapacity(4096) // Pre-allocate buffer
                        
                        for line in lines {
                            if !line.isEmpty {
                                // Use optimized completion check first
                                let lineData = line.data(using: .utf8)! + "\n\n".data(using: .utf8)!
                                if OptimizedSSEParser.isCompletionChunkOptimized(lineData) {
                                    continuation.finish()
                                    return
                                }
                                
                                continuation.yield(lineData)
                            }
                        }
                    } else {
                        continuation.yield(data)
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
                        
                        // Optimized fallback streaming for older platforms
                        if let responseString = String(data: data, encoding: .utf8) {
                            let lines = responseString.components(separatedBy: .newlines)
                            var buffer = Data()
                            buffer.reserveCapacity(4096) // Pre-allocate buffer
                            
                            for line in lines {
                                if !line.isEmpty {
                                    let lineData = line.data(using: .utf8)! + "\n\n".data(using: .utf8)!
                                    
                                    // Use optimized completion check first
                                    if OptimizedSSEParser.isCompletionChunkOptimized(lineData) {
                                        continuation.finish()
                                        return
                                    }
                                    
                                    continuation.yield(lineData)
                                }
                            }
                        } else {
                            continuation.yield(data)
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
        urlRequest.timeoutInterval = 60
        
        // Add streaming headers if this is a streaming request
        if request.headers["Accept"] == "text/event-stream" {
            urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        }
        
        return urlRequest
    }
}

