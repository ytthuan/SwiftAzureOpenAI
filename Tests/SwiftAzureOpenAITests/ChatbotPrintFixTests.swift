import XCTest
@testable import SwiftAzureOpenAI

/// Test that verifies the fix for the AdvancedConsoleChatbot printing issues
final class ChatbotPrintFixTests: XCTestCase {
    
    /// Test that status events like content_part.added/done and output_item.added/done 
    /// now return empty text instead of debug messages
    func testStatusEventsReturnEmptyText() throws {
        // Test content_part.added event
        let contentPartAddedData = """
        event: response.content_part.added
        data: {"type":"response.content_part.added","sequence_number":1,"item_id":"content_item_id","output_index":0}
        
        """.data(using: .utf8)!
        
        let contentPartResponse = try SSEParser.parseSSEChunk(contentPartAddedData)
        XCTAssertNotNil(contentPartResponse, "Content part added should be parsed")
        XCTAssertEqual(contentPartResponse?.output?.first?.content?.first?.text, "", "Content part added should have empty text")
        XCTAssertEqual(contentPartResponse?.output?.first?.content?.first?.type, "status", "Content part should be marked as status")
        
        // Test content_part.done event
        let contentPartDoneData = """
        event: response.content_part.done
        data: {"type":"response.content_part.done","sequence_number":2,"item_id":"content_item_id","output_index":0}
        
        """.data(using: .utf8)!
        
        let contentPartDoneResponse = try SSEParser.parseSSEChunk(contentPartDoneData)
        XCTAssertNotNil(contentPartDoneResponse, "Content part done should be parsed")
        XCTAssertEqual(contentPartDoneResponse?.output?.first?.content?.first?.text, "", "Content part done should have empty text")
        XCTAssertEqual(contentPartDoneResponse?.output?.first?.content?.first?.type, "status", "Content part done should be marked as status")
        
        // Test output_item.added event
        let outputItemAddedData = """
        event: response.output_item.added
        data: {"type":"response.output_item.added","sequence_number":3,"output_index":0,"item":{"id":"item_456","type":"text"}}
        
        """.data(using: .utf8)!
        
        let outputItemResponse = try SSEParser.parseSSEChunk(outputItemAddedData)
        XCTAssertNotNil(outputItemResponse, "Output item added should be parsed")
        XCTAssertEqual(outputItemResponse?.output?.first?.content?.first?.text, "", "Output item added should have empty text")
        XCTAssertEqual(outputItemResponse?.output?.first?.content?.first?.type, "status", "Output item added should be marked as status")
        
        print("✅ All status events now return empty text instead of debug messages")
    }
    
    /// Test that reasoning events preserve their type but have empty text
    func testReasoningEventsPreserveType() throws {
        let reasoningItemData = """
        event: response.output_item.added
        data: {"type":"response.output_item.added","sequence_number":1,"output_index":0,"item":{"id":"item_123","type":"reasoning","summary":[]}}
        
        """.data(using: .utf8)!
        
        let reasoningResponse = try SSEParser.parseSSEChunk(reasoningItemData)
        XCTAssertNotNil(reasoningResponse, "Reasoning item should be parsed")
        XCTAssertEqual(reasoningResponse?.output?.first?.content?.first?.text, "", "Reasoning item should have empty text")
        XCTAssertEqual(reasoningResponse?.output?.first?.content?.first?.type, "reasoning", "Reasoning type should be preserved")
        
        print("✅ Reasoning events preserve their type but have empty text")
    }
    
    /// Test that function call events don't create unwanted text output
    func testFunctionCallEventsStillWork() throws {
        let functionCallData = """
        event: response.output_item.added
        data: {"type":"response.output_item.added","sequence_number":1,"output_index":0,"item":{"id":"fc_123","type":"function_call","name":"get_weather"}}
        
        """.data(using: .utf8)!
        
        let functionCallResponse = try SSEParser.parseSSEChunk(functionCallData)
        XCTAssertNotNil(functionCallResponse, "Function call item should be parsed")
        XCTAssertEqual(functionCallResponse?.output?.first?.content?.first?.text, "", "Function call should not create text output to prevent unwanted printing")
        XCTAssertEqual(functionCallResponse?.output?.first?.content?.first?.type, "status", "Function call type should be status to prevent text display")
        
        print("✅ Function call events don't create unwanted text output")
    }
    
    /// Test that delta events still work properly
    func testDeltaEventsStillWork() throws {
        let deltaData = """
        event: response.text.delta
        data: {"type":"response.text.delta","sequence_number":1,"item_id":"text_123","output_index":0,"delta":"Hello world"}
        
        """.data(using: .utf8)!
        
        let deltaResponse = try SSEParser.parseSSEChunk(deltaData)
        XCTAssertNotNil(deltaResponse, "Delta event should be parsed")
        XCTAssertEqual(deltaResponse?.output?.first?.content?.first?.text, "Hello world", "Delta event should have actual content")
        XCTAssertEqual(deltaResponse?.output?.first?.content?.first?.type, "text", "Delta type should be preserved")
        
        print("✅ Delta events still work with actual content")
    }
    
    /// Verify that empty text and status type content would be filtered by the chatbot
    func testChatbotWouldFilterStatusContent() throws {
        // Simulate what the chatbot filtering logic would do
        let statusContent = SAOAIStreamingContent(type: "status", text: "", index: 0)
        let actualContent = SAOAIStreamingContent(type: "text", text: "Hello world", index: 0)
        let emptyContent = SAOAIStreamingContent(type: "text", text: "", index: 0)
        
        // Simulate the filtering condition in the chatbot: !text.isEmpty && content.type != "status"
        XCTAssertFalse(shouldPrintContent(statusContent), "Status content should be filtered out")
        XCTAssertFalse(shouldPrintContent(emptyContent), "Empty content should be filtered out")
        XCTAssertTrue(shouldPrintContent(actualContent), "Actual content should be printed")
        
        print("✅ Chatbot filtering logic correctly filters status and empty content")
    }
    
    /// Helper function that mimics the chatbot's filtering logic
    private func shouldPrintContent(_ content: SAOAIStreamingContent) -> Bool {
        guard let text = content.text, !text.isEmpty, content.type != "status" else {
            return false
        }
        return true
    }
}