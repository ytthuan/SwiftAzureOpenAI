import Foundation

public protocol StreamingResponseParser {
    func parseChunk<T: Codable>(_ data: Data, as type: T.Type) throws -> T
    func isComplete(_ data: Data) -> Bool
}

public final class DefaultStreamingResponseParser: StreamingResponseParser {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func parseChunk<T: Codable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw OpenAIError.decodingError(error)
        }
    }

    public func isComplete(_ data: Data) -> Bool {
        // Heuristic: caller should determine completion from protocol (e.g., [DONE] for SSE), default to false.
        return false
    }
}

public final class StreamingResponseService {
    private let parser: StreamingResponseParser

    public init(parser: StreamingResponseParser = DefaultStreamingResponseParser()) {
        self.parser = parser
    }

    public func processStream<T: Codable>(_ stream: AsyncThrowingStream<Data, Error>, type: T.Type) -> AsyncThrowingStream<StreamingResponseChunk<T>, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var sequenceNumber = 0
                do {
                    for try await chunk in stream {
                        let parsed = try parser.parseChunk(chunk, as: type)
                        let responseChunk = StreamingResponseChunk(
                            chunk: parsed,
                            isComplete: parser.isComplete(chunk),
                            sequenceNumber: sequenceNumber
                        )
                        continuation.yield(responseChunk)
                        sequenceNumber += 1
                        if responseChunk.isComplete {
                            continuation.finish()
                            break
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

