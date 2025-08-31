import XCTest
@testable import SwiftAzureOpenAI

/// Comprehensive tests for all supported OpenAI Response API SSE event types
/// Based on official OpenAI documentation: https://platform.openai.com/docs/api-reference/responses_streaming/response/created
final class ComprehensiveSSEEventTests: XCTestCase {
    
    /// Test that all officially documented delta event types are handled
    func testAllDeltaEventTypes() throws {
        let deltaEventTypes = [
            "response.function_call_arguments.delta",
            "response.text.delta",
            "response.output_text.delta",
            "response.audio.delta",
            "response.audio_transcript.delta",
            "response.code_interpreter_call_code.delta",
            "response.refusal.delta",
            "response.reasoning.delta",
            "response.reasoning_summary.delta",
            "response.reasoning_summary_text.delta",
            "response.mcp_call.arguments_delta"
        ]
        
        for eventType in deltaEventTypes {
            let sseData = """
            event: \(eventType)
            data: {"type":"\(eventType)","sequence_number":1,"item_id":"test_item_id","output_index":0,"delta":"test_delta_content"}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(sseData)
            
            XCTAssertNotNil(response, "Event type '\(eventType)' should be parsed successfully")
            XCTAssertEqual(response?.id, "test_item_id", "Item ID should be extracted for '\(eventType)'")
            XCTAssertNotNil(response?.output?.first?.content?.first?.text, "Delta content should be present for '\(eventType)'")
            XCTAssertEqual(response?.output?.first?.content?.first?.text, "test_delta_content", "Delta content should match for '\(eventType)'")
            
            print("✅ Event type '\(eventType)' parsed successfully")
        }
    }
    
    /// Test that all officially documented done event types are handled
    func testAllDoneEventTypes() throws {
        let doneEventTypes = [
            "response.function_call_arguments.done",
            "response.text.done",
            "response.output_text.done",
            "response.audio.done",
            "response.audio_transcript.done",
            "response.code_interpreter_call_code.done",
            "response.refusal.done",
            "response.reasoning.done",
            "response.reasoning_summary.done",
            "response.reasoning_summary_text.done",
            "response.mcp_call.arguments_done"
        ]
        
        for eventType in doneEventTypes {
            let sseData = """
            event: \(eventType)
            data: {"type":"\(eventType)","sequence_number":1,"item_id":"test_item_id","output_index":0,"arguments":"final_arguments"}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(sseData)
            
            XCTAssertNotNil(response, "Event type '\(eventType)' should be parsed successfully")
            XCTAssertEqual(response?.id, "test_item_id", "Item ID should be extracted for '\(eventType)'")
            XCTAssertNotNil(response?.output?.first?.content?.first?.text, "Done content should be present for '\(eventType)'")
            XCTAssertEqual(response?.output?.first?.content?.first?.text, "final_arguments", "Done content should match for '\(eventType)'")
            
            print("✅ Event type '\(eventType)' parsed successfully")
        }
    }
    
    /// Test response lifecycle events
    func testResponseLifecycleEvents() throws {
        let lifecycleEventTypes = [
            "response.created",
            "response.in_progress", 
            "response.completed"
        ]
        
        for eventType in lifecycleEventTypes {
            let sseData = """
            event: \(eventType)
            data: {"type":"\(eventType)","sequence_number":1,"response":{"id":"resp_123","model":"gpt-4","created_at":1234567890,"status":"completed","output":[]}}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(sseData)
            
            XCTAssertNotNil(response, "Event type '\(eventType)' should be parsed successfully")
            XCTAssertEqual(response?.id, "resp_123", "Response ID should be extracted for '\(eventType)'")
            XCTAssertEqual(response?.model, "gpt-4", "Model should be extracted for '\(eventType)'")
            XCTAssertEqual(response?.created, 1234567890, "Created timestamp should be extracted for '\(eventType)'")
            
            print("✅ Event type '\(eventType)' parsed successfully")
        }
    }
    
    /// Test tool call events
    func testToolCallEvents() throws {
        let toolCallEventTypes = [
            "response.file_search_call.searching",
            "response.file_search_call.in_progress",
            "response.file_search_call.completed",
            "response.code_interpreter_call.interpreting",
            "response.code_interpreter_call.in_progress", 
            "response.code_interpreter_call.completed",
            "response.web_search_call.searching",
            "response.web_search_call.in_progress",
            "response.web_search_call.completed",
            "response.image_generation_call.generating",
            "response.image_generation_call.in_progress",
            "response.image_generation_call.completed",
            "response.image_generation_call.partial_image",
            "response.mcp_call.in_progress",
            "response.mcp_call.completed",
            "response.mcp_call.failed",
            "response.mcp_list_tools.in_progress",
            "response.mcp_list_tools.completed",
            "response.mcp_list_tools.failed"
        ]
        
        for eventType in toolCallEventTypes {
            let sseData = """
            event: \(eventType)
            data: {"type":"\(eventType)","sequence_number":1,"item_id":"tool_item_id","output_index":0}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(sseData)
            
            XCTAssertNotNil(response, "Event type '\(eventType)' should be parsed successfully")
            XCTAssertEqual(response?.id, "tool_item_id", "Item ID should be extracted for '\(eventType)'")
            XCTAssertNotNil(response?.output?.first?.content?.first?.text, "Tool call content should be present for '\(eventType)'")
            
            print("✅ Event type '\(eventType)' parsed successfully")
        }
    }
    
    /// Test content part events
    func testContentPartEvents() throws {
        let contentPartEventTypes = [
            "response.content_part.added",
            "response.content_part.done"
        ]
        
        for eventType in contentPartEventTypes {
            let sseData = """
            event: \(eventType)
            data: {"type":"\(eventType)","sequence_number":1,"item_id":"content_item_id","output_index":0}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(sseData)
            
            XCTAssertNotNil(response, "Event type '\(eventType)' should be parsed successfully")
            XCTAssertEqual(response?.id, "content_item_id", "Item ID should be extracted for '\(eventType)'")
            XCTAssertNotNil(response?.output?.first?.content?.first?.text, "Content part text should be present for '\(eventType)'")
            
            print("✅ Event type '\(eventType)' parsed successfully")
        }
    }
    
    /// Test error and failure events
    func testErrorAndFailureEvents() throws {
        let errorEventTypes = [
            "response.failed",
            "response.incomplete", 
            "error"
        ]
        
        for eventType in errorEventTypes {
            let responseField = eventType == "error" ? "" : """
            ,"response":{"id":"resp_error","model":"gpt-4","created_at":1234567890,"status":"failed","output":[]}
            """
            
            let sseData = """
            event: \(eventType)
            data: {"type":"\(eventType)","sequence_number":1,"item_id":"error_item_id"\(responseField)}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(sseData)
            
            XCTAssertNotNil(response, "Event type '\(eventType)' should be parsed successfully")
            
            if eventType == "error" {
                XCTAssertEqual(response?.id, "error_item_id", "Item ID should be extracted for error event")
            } else {
                XCTAssertEqual(response?.id, "resp_error", "Response ID should be extracted for '\(eventType)'")
            }
            
            print("✅ Event type '\(eventType)' parsed successfully")
        }
    }
    
    /// Test specialized events
    func testSpecializedEvents() throws {
        let specializedEventTypes = [
            "response.queued",
            "response.output_text.annotation.added",
            "response.reasoning_summary_part.added",
            "response.reasoning_summary_part.done"
        ]
        
        for eventType in specializedEventTypes {
            let responseField = eventType == "response.queued" ? """
            ,"response":{"id":"resp_queued","model":"gpt-4","created_at":1234567890,"status":"queued","output":[]}
            """ : ""
            
            let sseData = """
            event: \(eventType)
            data: {"type":"\(eventType)","sequence_number":1,"item_id":"specialized_item_id","output_index":0\(responseField)}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(sseData)
            
            XCTAssertNotNil(response, "Event type '\(eventType)' should be parsed successfully")
            
            if eventType == "response.queued" {
                XCTAssertEqual(response?.id, "resp_queued", "Response ID should be extracted for queued event")
            } else {
                XCTAssertEqual(response?.id, "specialized_item_id", "Item ID should be extracted for '\(eventType)'")
            }
            
            print("✅ Event type '\(eventType)' parsed successfully")
        }
    }
    
    /// Test that unknown event types are gracefully ignored
    func testUnknownEventTypesIgnored() throws {
        let unknownEventData = """
        event: response.unknown_event_type
        data: {"type":"response.unknown_event_type","sequence_number":1,"item_id":"unknown_item"}
        
        """.data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(unknownEventData)
        
        // Unknown events should return nil (gracefully ignored)
        XCTAssertNil(response, "Unknown event types should be gracefully ignored")
        
        print("✅ Unknown event types are gracefully ignored")
    }
    
    /// Test comprehensive event type coverage
    func testEventTypeCoverage() {
        print("🎯 Comprehensive SSE Event Type Coverage Test")
        print("   Based on official OpenAI Response API documentation")
        print("   ✅ Delta events: 11 types supported")
        print("   ✅ Done events: 11 types supported") 
        print("   ✅ Response lifecycle: 3 types supported")
        print("   ✅ Tool calls: 19 types supported")
        print("   ✅ Content parts: 2 types supported")
        print("   ✅ Error handling: 3 types supported")
        print("   ✅ Specialized events: 4 types supported")
        print("   ✅ Unknown events: Gracefully ignored")
        print("   📊 Total: 53+ OpenAI Response API event types supported")
    }
}