import XCTest
@testable import SwiftAzureOpenAI

/// Test that verifies the code interpreter tool container field fix
final class CodeInterpreterToolContainerTests: XCTestCase {
    
    /// Test that the code interpreter tool includes the required container field
    func testCodeInterpreterToolIncludesContainer() {
        // Create a code interpreter tool using the convenience method
        let codeInterpreterTool = SAOAITool.codeInterpreter()
        
        // Verify it has the correct type
        XCTAssertEqual(codeInterpreterTool.type, "code_interpreter")
        
        // Verify it has the container field
        XCTAssertNotNil(codeInterpreterTool.container)
        
        // Verify the container is properly structured with type "auto"
        if case let .object(containerObj) = codeInterpreterTool.container {
            if case let .string(containerType) = containerObj["type"] {
                XCTAssertEqual(containerType, "auto")
            } else {
                XCTFail("Container type should be a string with value 'auto'")
            }
        } else {
            XCTFail("Container should be an object with type field")
        }
        
        print("✅ Code interpreter tool correctly includes container field with type 'auto'")
    }
    
    /// Test that the tool can be properly encoded to JSON with container field
    func testCodeInterpreterToolJSONEncoding() throws {
        let codeInterpreterTool = SAOAITool.codeInterpreter()
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(codeInterpreterTool)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Verify the JSON contains the container field
        XCTAssertTrue(jsonString.contains("\"container\""))
        XCTAssertTrue(jsonString.contains("\"type\":\"auto\""))
        XCTAssertTrue(jsonString.contains("\"type\":\"code_interpreter\""))
        
        print("✅ Code interpreter tool JSON encoding includes container field")
        print("📄 Generated JSON: \(jsonString)")
    }
    
    /// Test that function tools don't have container fields (to ensure we didn't break existing functionality)
    func testFunctionToolsDoNotHaveContainer() {
        let functionTool = SAOAITool.function(
            name: "test_function",
            description: "A test function",
            parameters: .object([:])
        )
        
        // Verify function tools don't have container
        XCTAssertNil(functionTool.container)
        XCTAssertEqual(functionTool.type, "function")
        XCTAssertEqual(functionTool.name, "test_function")
        
        print("✅ Function tools correctly omit container field")
    }
    
    /// Test JSON output format matches expected API format
    func testJSONOutputMatchesAPIFormat() throws {
        let codeInterpreterTool = SAOAITool.codeInterpreter()
        let functionTool = SAOAITool.function(
            name: "get_weather",
            description: "Get weather information",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("Location to get weather for")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        )
        
        let tools = [functionTool, codeInterpreterTool]
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let toolsJSON = try encoder.encode(tools)
        let jsonString = String(data: toolsJSON, encoding: .utf8)!
        
        // Verify the structure matches expected API format
        XCTAssertTrue(jsonString.contains("\"type\" : \"function\""))
        XCTAssertTrue(jsonString.contains("\"type\" : \"code_interpreter\""))
        XCTAssertTrue(jsonString.contains("\"container\""))
        XCTAssertTrue(jsonString.contains("\"type\" : \"auto\""))
        
        // Ensure function tool doesn't have container but code interpreter does
        let functionToolJSON = try encoder.encode(functionTool)
        let functionString = String(data: functionToolJSON, encoding: .utf8)!
        XCTAssertFalse(functionString.contains("\"container\""))
        
        let codeInterpreterToolJSON = try encoder.encode(codeInterpreterTool)
        let codeInterpreterString = String(data: codeInterpreterToolJSON, encoding: .utf8)!
        XCTAssertTrue(codeInterpreterString.contains("\"container\""))
        
        print("✅ JSON output matches expected API format")
        print("📄 Tools JSON:\n\(jsonString)")
    }
}