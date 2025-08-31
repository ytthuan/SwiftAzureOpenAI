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
    
    /// Send a streaming request that returns Server-Sent Events
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
                    
                    // Simulate streaming by processing line-by-line
                    if let responseString = String(data: data, encoding: .utf8) {
                        let lines = responseString.components(separatedBy: .newlines)
                        for line in lines {
                            if !line.isEmpty {
                                // Format each line as a complete SSE chunk for SSEParser
                                let lineData = line.data(using: .utf8)! + "\n\n".data(using: .utf8)!
                                continuation.yield(lineData)
                                
                                // Check for completion signal
                                if SSEParser.isCompletionChunk(lineData) {
                                    continuation.finish()
                                    return
                                }
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
                        
                        var buffer = Data()
                        for try await byte in asyncBytes {
                            buffer.append(byte)
                            
                            // Process complete lines (ending with newline)
                            while let range = buffer.range(of: "\n".data(using: .utf8)!) {
                                let lineData = buffer[..<range.lowerBound]
                                buffer.removeSubrange(..<range.upperBound)
                                
                                if !lineData.isEmpty {
                                    // Format each line as a complete SSE chunk for SSEParser
                                    let lineWithNewline = lineData + "\n\n".data(using: .utf8)!
                                    continuation.yield(lineWithNewline)
                                    
                                    // Check for completion signal
                                    if SSEParser.isCompletionChunk(lineWithNewline) {
                                        continuation.finish()
                                        return
                                    }
                                }
                            }
                        }
                        
                        // Process any remaining data in buffer as a line
                        if !buffer.isEmpty {
                            let lineWithNewline = buffer + "\n\n".data(using: .utf8)!
                            continuation.yield(lineWithNewline)
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
                        
                        // Simulate streaming by processing line-by-line
                        if let responseString = String(data: data, encoding: .utf8) {
                            let lines = responseString.components(separatedBy: .newlines)
                            for line in lines {
                                if !line.isEmpty {
                                    // Format each line as a complete SSE chunk for SSEParser
                                    let lineData = line.data(using: .utf8)! + "\n\n".data(using: .utf8)!
                                    continuation.yield(lineData)
                                    
                                    // Check for completion signal
                                    if SSEParser.isCompletionChunk(lineData) {
                                        continuation.finish()
                                        return
                                    }
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

