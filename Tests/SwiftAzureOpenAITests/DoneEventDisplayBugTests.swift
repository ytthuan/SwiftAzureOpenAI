import XCTest
@testable import SwiftAzureOpenAI

/// Test that reproduces and verifies the fix for the [DONE] text display bug
/// Issue: SDK returns "[DONE]" at the end of stream data which gets displayed to users
final class DoneEventDisplayBugTests: XCTestCase {
    
    /// Test that reproduces the bug: done events without arguments generate "[DONE]" text
    /// that would be displayed in the chatbot
    /// NOTE: This test validates the fix - it used to fail before the fix was applied
    func testDoneEventWithoutArgumentsNoLongerGeneratesDoneText() throws {
        // Simulate a done event without arguments (this is when the bug occurred)
        let doneEventData = """
        event: response.text.done
        data: {"type":"response.text.done","sequence_number":5,"item_id":"msg_123","output_index":0}
        
        """.data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(doneEventData)
        
        XCTAssertNotNil(response, "Done event should be parsed")
        
        // After fix: should not generate "[DONE]" text
        let content = response?.output?.first?.content?.first
        XCTAssertEqual(content?.text, "", "Fixed behavior: returns empty text instead of [DONE]")
        XCTAssertEqual(content?.type, "text", "Content type should still match the event type")
        
        // Verify this would NOT be displayed by the chatbot (gets filtered out due to empty text)
        let wouldBeDisplayed = shouldChatbotDisplayContent(content!)
        XCTAssertFalse(wouldBeDisplayed, "FIXED: Empty text is filtered out and not displayed to users")
        
        print("✅ Fixed: Done event without arguments generates empty text that gets filtered out")
    }
    
    /// Test that done events with arguments work correctly
    func testDoneEventWithArgumentsWorksCorrectly() throws {
        // Done event with arguments should preserve the arguments as content
        let doneEventWithArgsData = """
        event: response.text.done
        data: {"type":"response.text.done","sequence_number":5,"item_id":"msg_123","output_index":0,"arguments":"Final response content"}
        
        """.data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(doneEventWithArgsData)
        
        XCTAssertNotNil(response, "Done event with arguments should be parsed")
        XCTAssertEqual(response?.output?.first?.content?.first?.text, "Final response content", "Arguments should be preserved as content")
        XCTAssertEqual(response?.output?.first?.content?.first?.type, "text", "Content type should match the event type")
        
        print("✅ Done events with arguments work correctly")
    }
    
    /// Test the fix: done events without arguments should not generate visible text
    func testFixedDoneEventWithoutArgumentsGeneratesNoVisibleText() throws {
        // This test will initially fail, then pass after the fix is applied
        let doneEventData = """
        event: response.text.done
        data: {"type":"response.text.done","sequence_number":5,"item_id":"msg_123","output_index":0}
        
        """.data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(doneEventData)
        
        XCTAssertNotNil(response, "Done event should be parsed")
        
        let content = response?.output?.first?.content?.first
        
        // After fix: should not generate visible text
        let wouldBeDisplayed = shouldChatbotDisplayContent(content!)
        XCTAssertFalse(wouldBeDisplayed, "Fixed: Done event should not generate visible text")
        
        // The content should either be empty or marked as status
        let hasEmptyText = content?.text?.isEmpty == true
        let isStatusType = content?.type == "status"
        XCTAssertTrue(hasEmptyText || isStatusType, "Done event should have empty text or be marked as status")
        
        print("✅ Fixed: Done events without arguments do not generate visible text")
    }
    
    /// Helper function that mimics the AdvancedConsoleChatbot's filtering logic
    private func shouldChatbotDisplayContent(_ content: SAOAIStreamingContent) -> Bool {
        // This is the exact condition used in AdvancedConsoleChatbot
        guard let text = content.text, !text.isEmpty, content.type != "status" else {
            return false
        }
        return true
    }
    
    /// Test multiple done event types to ensure consistent behavior
    func testAllDoneEventTypesHandleNoArgumentsConsistently() throws {
        let doneEventTypes = [
            "response.function_call_arguments.done",
            "response.text.done",
            "response.output_text.done",
            "response.audio.done",
            "response.audio_transcript.done",
            "response.reasoning.done"
        ]
        
        for eventType in doneEventTypes {
            let sseData = """
            event: \(eventType)
            data: {"type":"\(eventType)","sequence_number":1,"item_id":"test_item_id","output_index":0}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(sseData)
            XCTAssertNotNil(response, "Event type '\(eventType)' should be parsed")
            
            let content = response?.output?.first?.content?.first
            let wouldBeDisplayed = shouldChatbotDisplayContent(content!)
            
            // After fix, none of these should generate visible text for users
            XCTAssertFalse(wouldBeDisplayed, "Done event '\(eventType)' should not generate visible text")
        }
        
        print("✅ All done event types handle missing arguments consistently")
    }
}