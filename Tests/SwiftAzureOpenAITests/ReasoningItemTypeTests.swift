import XCTest
@testable import SwiftAzureOpenAI

/// Test that reasoning item types are properly recognized and handled
final class ReasoningItemTypeTests: XCTestCase {
    
    /// Test that reasoning item type enum now includes reasoning case
    func testReasoningItemTypeExists() {
        // Test that reasoning case exists in the enum
        let reasoningType = SAOAIStreamingItemType.reasoning
        XCTAssertEqual(reasoningType.rawValue, "reasoning")
        XCTAssertEqual(reasoningType.description, "Reasoning")
        
        // Test that it's included in all cases
        XCTAssertTrue(SAOAIStreamingItemType.allCases.contains(.reasoning))
        
        print("✅ Reasoning item type properly defined")
    }
    
    /// Test that actual SSE event with reasoning item type can be parsed
    func testReasoningSSEEventParsing() throws {
        // This is the exact SSE event from the captured API response
        let reasoningSSEData = """
        event: response.output_item.added
        data: {"type":"response.output_item.added","sequence_number":2,"output_index":0,"item":{"id":"rs_68c0238360f88197a71913759ad921c90c352bf34ca331c7","type":"reasoning","summary":[]}}
        
        """.data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(reasoningSSEData)
        
        XCTAssertNotNil(response, "Reasoning SSE event should be parsed")
        XCTAssertEqual(response?.eventType, .responseOutputItemAdded, "Event type should be correct")
        
        // The key test: verify that the item type is now recognized as reasoning
        XCTAssertNotNil(response?.item, "Event should have an item")
        XCTAssertEqual(response?.item?.type, .reasoning, "Item type should be recognized as reasoning")
        XCTAssertEqual(response?.item?.id, "rs_68c0238360f88197a71913759ad921c90c352bf34ca331c7", "Item ID should be preserved")
        XCTAssertNotNil(response?.item?.summary, "Summary array should be present (even if empty)")
        
        print("✅ Reasoning SSE event properly parsed with item type recognized")
    }
    
    /// Test that reasoning completion event can be parsed
    func testReasoningCompletionSSEEventParsing() throws {
        // This is the completion event from the captured API response
        let reasoningDoneSSEData = """
        event: response.output_item.done
        data: {"type":"response.output_item.done","sequence_number":3,"output_index":0,"item":{"id":"rs_68c0238360f88197a71913759ad921c90c352bf34ca331c7","type":"reasoning","summary":[]}}
        
        """.data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(reasoningDoneSSEData)
        
        XCTAssertNotNil(response, "Reasoning completion SSE event should be parsed")
        XCTAssertEqual(response?.eventType, .responseOutputItemDone, "Event type should be correct")
        XCTAssertEqual(response?.item?.type, .reasoning, "Item type should be recognized as reasoning")
        
        print("✅ Reasoning completion SSE event properly parsed")
    }
    
    /// Test all existing item types still work
    func testExistingItemTypesStillWork() {
        let existingTypes: [SAOAIStreamingItemType] = [
            .message,
            .codeInterpreterCall,
            .functionCall,
            .fileSearchCall,
            .mcpCall
        ]
        
        for itemType in existingTypes {
            XCTAssertTrue(SAOAIStreamingItemType.allCases.contains(itemType), "Existing item type \(itemType) should still be available")
        }
        
        // Verify total count includes the new reasoning type
        XCTAssertEqual(SAOAIStreamingItemType.allCases.count, 6, "Should have 6 item types total including reasoning")
        
        print("✅ All existing item types still work correctly")
    }
}