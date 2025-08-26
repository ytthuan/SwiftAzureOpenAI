import XCTest
@testable import SwiftAzureOpenAI

final class JSONValueTests: XCTestCase {
    func testRoundtrip() throws {
        let original: JSONValue = .object([
            "a": .string("x"),
            "b": .number(1.5),
            "c": .bool(true),
            "d": .array([.null, .string("y")])
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testDecodeUnsupportedThrows() {
        let data = Data("{\"type\":\"unknown\"}".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(InputContentPart.self, from: data))
    }
}