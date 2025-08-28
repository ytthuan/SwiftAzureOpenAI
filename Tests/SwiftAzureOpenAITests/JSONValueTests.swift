import XCTest
@testable import SwiftAzureOpenAI

final class SAOAIJSONValueTests: XCTestCase {
    func testRoundtrip() throws {
        let original: SAOAIJSONValue = .object([
            "a": .string("x"),
            "b": .number(1.5),
            "c": .bool(true),
            "d": .array([.null, .string("y")])
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SAOAIJSONValue.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testDecodeUnsupportedThrows() {
        let data = Data("{\"type\":\"unknown\"}".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SAOAIInputContent.self, from: data))
    }
}