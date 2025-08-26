import XCTest
@testable import SwiftAzureOpenAI

final class StreamingResponseServiceTests: XCTestCase {
    func testProcessStreamYieldsChunksWithSequenceNumbers() async throws {
        struct Part: Codable, Equatable { let value: Int }
        let service = StreamingResponseService()

        // Build a stream that yields three JSON parts
        let stream = AsyncThrowingStream<Data, Error> { continuation in
            let parts = [1, 2, 3].map { try! JSONEncoder().encode(Part(value: $0)) }
            for p in parts { continuation.yield(p) }
            continuation.finish()
        }

        var collected: [StreamingResponseChunk<Part>] = []
        for try await c in service.processStream(stream, type: Part.self) {
            collected.append(c)
        }

        XCTAssertEqual(collected.count, 3)
        XCTAssertEqual(collected[0].sequenceNumber, 0)
        XCTAssertEqual(collected[1].sequenceNumber, 1)
        XCTAssertEqual(collected[2].sequenceNumber, 2)
        XCTAssertEqual(collected.map { $0.chunk.value }, [1, 2, 3])
    }
}