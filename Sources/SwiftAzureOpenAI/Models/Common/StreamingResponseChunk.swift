import Foundation

/// A single chunk of a streaming response.
public struct StreamingResponseChunk<T: Codable>: Codable {
    /// The decoded piece of the streamed payload.
    public let chunk: T
    /// Indicates whether the stream has completed.
    public let isComplete: Bool
    /// Monotonic sequence number for ordering across the stream.
    public let sequenceNumber: Int?

    public init(chunk: T, isComplete: Bool, sequenceNumber: Int?) {
        self.chunk = chunk
        self.isComplete = isComplete
        self.sequenceNumber = sequenceNumber
    }
}

