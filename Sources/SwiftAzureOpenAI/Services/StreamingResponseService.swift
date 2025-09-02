import Foundation

public protocol StreamingResponseParser: Sendable {
    func parseChunk<T: Codable>(_ data: Data, as type: T.Type) throws -> T
    func isComplete(_ data: Data) -> Bool
}

public final class DefaultStreamingResponseParser: StreamingResponseParser, Sendable {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func parseChunk<T: Codable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SAOAIError.decodingError(error)
        }
    }

    public func isComplete(_ data: Data) -> Bool {
        // Heuristic: caller should determine completion from protocol (e.g., [DONE] for SSE), default to false.
        return false
    }
}

public final class StreamingResponseService: Sendable {
    private let parser: StreamingResponseParser

    public init(parser: StreamingResponseParser = DefaultStreamingResponseParser()) {
        self.parser = parser
    }

    public func processStream<T: Codable & Sendable>(_ stream: AsyncThrowingStream<Data, Error>, type: T.Type) -> AsyncThrowingStream<StreamingResponseChunk<T>, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var sequenceNumber = 0
                do {
                    for try await chunk in stream {
                        // Check for completion first
                        let isComplete = parser.isComplete(chunk)
                        
                        if isComplete {
                            // This is a completion marker, finish the stream
                            continuation.finish()
                            break
                        } else {
                            // Parse non-completion chunks
                            let parsed = try parser.parseChunk(chunk, as: type)
                            let responseChunk = StreamingResponseChunk(
                                chunk: parsed,
                                isComplete: false,
                                sequenceNumber: sequenceNumber
                            )
                            continuation.yield(responseChunk)
                            sequenceNumber += 1
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

