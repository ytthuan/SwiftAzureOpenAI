import XCTest
@testable import SwiftAzureOpenAI

final class ResponseParsingServiceTests: XCTestCase {
    
    func testDefaultResponseParserSuccessfulParsing() async throws {
        let parser = DefaultResponseParser()
        
        struct TestModel: Codable, Equatable {
            let name: String
            let value: Int
        }
        
        let testData: [String: Any] = ["name": "test", "value": 42]
        let data = try JSONSerialization.data(withJSONObject: testData)
        
        let result = try await parser.parse(data, as: TestModel.self)
        
        XCTAssertEqual(result.name, "test")
        XCTAssertEqual(result.value, 42)
    }
    
    func testDefaultResponseParserWithInvalidJSON() async throws {
        let parser = DefaultResponseParser()
        let invalidData = Data("invalid json".utf8)
        
        struct TestModel: Codable {
            let name: String
        }
        
        do {
            _ = try await parser.parse(invalidData, as: TestModel.self)
            XCTFail("Expected decodingError to be thrown")
        } catch let error as SAOAIError {
            if case .decodingError = error {
                // Expected error type
            } else {
                XCTFail("Expected decodingError, got: \(error)")
            }
        }
    }
    
    func testDefaultResponseParserWithMissingFields() async throws {
        let parser = DefaultResponseParser()
        
        struct TestModel: Codable {
            let name: String
            let required: String  // This field will be missing
        }
        
        let testData: [String: Any] = ["name": "test"] // Missing "required" field
        let data = try JSONSerialization.data(withJSONObject: testData)
        
        do {
            _ = try await parser.parse(data, as: TestModel.self)
            XCTFail("Expected decodingError to be thrown")
        } catch let error as SAOAIError {
            if case .decodingError = error {
                // Expected error type
            } else {
                XCTFail("Expected decodingError, got: \(error)")
            }
        }
    }
    
    func testDefaultResponseParserWithCustomDecoder() async throws {
        let customDecoder = JSONDecoder()
        customDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let parser = DefaultResponseParser(decoder: customDecoder)
        
        struct TestModel: Codable, Equatable {
            let fullName: String  // Will map from "full_name"
        }
        
        let testData: [String: Any] = ["full_name": "John Doe"]
        let data = try JSONSerialization.data(withJSONObject: testData)
        
        let result = try await parser.parse(data, as: TestModel.self)
        
        XCTAssertEqual(result.fullName, "John Doe")
    }
}