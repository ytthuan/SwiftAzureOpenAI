import XCTest
@testable import SwiftAzureOpenAI

/// Tests for streaming event type checking functionality
/// Validates the new API pattern that allows users to branch logic based on event types
final class StreamingEventTypeTests: XCTestCase {
    
    /// Test that streaming responses include event type information
    func testStreamingResponseIncludesEventType() throws {
        let deltaEventData = """
        event: response.output_text.delta
        data: {"type":"response.output_text.delta","sequence_number":1,"item_id":"test_item_id","output_index":0,"delta":"Hello world"}
        
        """.data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(deltaEventData)
        
        XCTAssertNotNil(response, "Response should be parsed successfully")
        XCTAssertNotNil(response?.eventType, "Response should include event type")
        XCTAssertEqual(response?.eventType, .responseOutputTextDelta, "Event type should match expected value")
        
        print("✅ Streaming response includes event type: \(response?.eventType?.rawValue ?? "nil")")
    }
    
    /// Test event type checking for delta events
    func testDeltaEventTypeChecking() throws {
        let eventTypes: [(String, SAOAIStreamingEventType)] = [
            ("response.function_call_arguments.delta", .responseFunctionCallArgumentsDelta),
            ("response.text.delta", .responseTextDelta),
            ("response.output_text.delta", .responseOutputTextDelta),
            ("response.audio.delta", .responseAudioDelta),
            ("response.code_interpreter_call_code.delta", .responseCodeInterpreterCallCodeDelta),
            ("response.reasoning.delta", .responseReasoningDelta)
        ]
        
        for (eventTypeString, expectedEventType) in eventTypes {
            let eventData = """
            event: \(eventTypeString)
            data: {"type":"\(eventTypeString)","sequence_number":1,"item_id":"test_item","delta":"test content"}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(eventData)
            
            XCTAssertNotNil(response, "Response should be parsed for \(eventTypeString)")
            XCTAssertEqual(response?.eventType, expectedEventType, "Event type should match for \(eventTypeString)")
            
            // Test that it's identified as a delta event
            XCTAssertTrue(response?.eventType?.isDelta == true, "\(eventTypeString) should be identified as delta event")
        }
        
        print("✅ Delta event type checking works correctly")
    }
    
    /// Test event type checking for done events
    func testDoneEventTypeChecking() throws {
        let eventTypes: [(String, SAOAIStreamingEventType)] = [
            ("response.function_call_arguments.done", .responseFunctionCallArgumentsDone),
            ("response.text.done", .responseTextDone),
            ("response.output_text.done", .responseOutputTextDone),
            ("response.audio.done", .responseAudioDone),
            ("response.reasoning.done", .responseReasoningDone)
        ]
        
        for (eventTypeString, expectedEventType) in eventTypes {
            let eventData = """
            event: \(eventTypeString)
            data: {"type":"\(eventTypeString)","sequence_number":1,"item_id":"test_item","arguments":"final content"}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(eventData)
            
            XCTAssertNotNil(response, "Response should be parsed for \(eventTypeString)")
            XCTAssertEqual(response?.eventType, expectedEventType, "Event type should match for \(eventTypeString)")
            
            // Test that it's identified as a done event
            XCTAssertTrue(response?.eventType?.isDone == true, "\(eventTypeString) should be identified as done event")
        }
        
        print("✅ Done event type checking works correctly")
    }
    
    /// Test item type checking for output items
    func testItemTypeChecking() throws {
        let itemTypes: [(String, SAOAIStreamingItemType)] = [
            ("message", .message),
            ("function_call", .functionCall),
            ("code_interpreter_call", .codeInterpreterCall),
            ("file_search_call", .fileSearchCall)
        ]
        
        for (itemTypeString, expectedItemType) in itemTypes {
            let eventData = """
            event: response.output_item.added
            data: {"type":"response.output_item.added","sequence_number":1,"item":{"id":"item_123","type":"\(itemTypeString)","status":"in_progress"}}
            
            """.data(using: .utf8)!
            
            let response = try SSEParser.parseSSEChunk(eventData)
            
            XCTAssertNotNil(response, "Response should be parsed for item type \(itemTypeString)")
            XCTAssertNotNil(response?.item, "Response should include item information")
            XCTAssertEqual(response?.item?.type, expectedItemType, "Item type should match for \(itemTypeString)")
            
            print("✅ Item type \(itemTypeString) mapped correctly to \(expectedItemType)")
        }
        
        print("✅ Item type checking works correctly")
    }
    
    /// Test the target API usage pattern with switch statements
    func testEventTypeSwitchPattern() throws {
        let testEvents: [(String, String)] = [
            ("response.output_text.delta", "delta content"),
            ("response.function_call_arguments.delta", "function args"),
            ("response.output_item.added", ""),
            ("error", "")
        ]
        
        for (eventTypeString, content) in testEvents {
            var eventData: Data
            
            if eventTypeString.contains("delta") {
                eventData = """
                event: \(eventTypeString)
                data: {"type":"\(eventTypeString)","sequence_number":1,"item_id":"test_item","delta":"\(content)"}
                
                """.data(using: .utf8)!
            } else if eventTypeString == "response.output_item.added" {
                eventData = """
                event: \(eventTypeString)
                data: {"type":"\(eventTypeString)","sequence_number":1,"item":{"id":"item_123","type":"function_call","name":"get_weather"}}
                
                """.data(using: .utf8)!
            } else {
                eventData = """
                event: \(eventTypeString)
                data: {"type":"\(eventTypeString)","sequence_number":1,"item_id":"error_item"}
                
                """.data(using: .utf8)!
            }
            
            let response = try SSEParser.parseSSEChunk(eventData)
            XCTAssertNotNil(response, "Response should be parsed for \(eventTypeString)")
            
            // Test the switch pattern similar to Python SDK
            guard let eventType = response?.eventType else {
                XCTFail("Event type should be present")
                continue
            }
            
            var handledCorrectly = false
            
            switch eventType {
            case .responseOutputTextDelta:
                handledCorrectly = eventTypeString == "response.output_text.delta"
                print("   📝 Handled output text delta event")
                
            case .responseFunctionCallArgumentsDelta:
                handledCorrectly = eventTypeString == "response.function_call_arguments.delta"
                print("   🔧 Handled function call arguments delta event")
                
            case .responseOutputItemAdded:
                handledCorrectly = eventTypeString == "response.output_item.added"
                if let item = response?.item {
                    switch item.type {
                    case .functionCall:
                        print("   ⚙️ Handled function call item added: \(item.name ?? "unknown")")
                    case .codeInterpreterCall:
                        print("   🐍 Handled code interpreter call item")
                    case .message:
                        print("   💬 Handled message item")
                    default:
                        print("   📦 Handled other item type: \(item.type?.rawValue ?? "unknown")")
                    }
                }
                
            case .error, .responseError:
                handledCorrectly = eventTypeString == "error"
                print("   ❌ Handled error event")
                
            default:
                if eventType.isDelta {
                    print("   🔄 Handled generic delta event: \(eventType.rawValue)")
                    handledCorrectly = true
                } else if eventType.isDone {
                    print("   ✅ Handled generic done event: \(eventType.rawValue)")
                    handledCorrectly = true
                } else {
                    print("   🔍 Handled other event: \(eventType.rawValue)")
                    handledCorrectly = true
                }
            }
            
            XCTAssertTrue(handledCorrectly, "Event \(eventTypeString) should be handled correctly by switch statement")
        }
        
        print("✅ Event type switch pattern works correctly")
    }
    
    /// Test event type helper properties
    func testEventTypeHelperProperties() throws {
        // Test delta event properties
        let deltaEvent = SAOAIStreamingEventType.responseOutputTextDelta
        XCTAssertTrue(deltaEvent.isDelta, "Delta events should be identified as delta")
        XCTAssertFalse(deltaEvent.isDone, "Delta events should not be identified as done")
        XCTAssertFalse(deltaEvent.isError, "Delta events should not be identified as error")
        
        // Test done event properties  
        let doneEvent = SAOAIStreamingEventType.responseOutputTextDone
        XCTAssertFalse(doneEvent.isDelta, "Done events should not be identified as delta")
        XCTAssertTrue(doneEvent.isDone, "Done events should be identified as done")
        XCTAssertFalse(doneEvent.isError, "Done events should not be identified as error")
        
        // Test error event properties
        let errorEvent = SAOAIStreamingEventType.error
        XCTAssertFalse(errorEvent.isDelta, "Error events should not be identified as delta")
        XCTAssertFalse(errorEvent.isDone, "Error events should not be identified as done")
        XCTAssertTrue(errorEvent.isError, "Error events should be identified as error")
        
        // Test tool call event properties
        let toolCallEvent = SAOAIStreamingEventType.responseFunctionCallCreated
        XCTAssertTrue(toolCallEvent.isToolCall, "Function call events should be identified as tool call")
        
        // Test lifecycle event properties
        let lifecycleEvent = SAOAIStreamingEventType.responseCreated
        XCTAssertTrue(lifecycleEvent.isLifecycle, "Response created should be identified as lifecycle")
        
        print("✅ Event type helper properties work correctly")
    }
    
    /// Test backward compatibility - existing code should still work
    func testBackwardCompatibility() throws {
        let deltaEventData = """
        event: response.output_text.delta
        data: {"type":"response.output_text.delta","sequence_number":1,"item_id":"test_item_id","output_index":0,"delta":"Hello world"}
        
        """.data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(deltaEventData)
        
        // Test that existing properties still work
        XCTAssertNotNil(response, "Response should be parsed")
        XCTAssertEqual(response?.id, "test_item_id", "ID should be extracted")
        XCTAssertNotNil(response?.output?.first?.content?.first?.text, "Text content should be present")
        XCTAssertEqual(response?.output?.first?.content?.first?.text, "Hello world", "Text content should match")
        
        // Test that new properties are also available
        XCTAssertNotNil(response?.eventType, "Event type should be present")
        XCTAssertEqual(response?.eventType, .responseOutputTextDelta, "Event type should be correct")
        
        print("✅ Backward compatibility maintained")
    }
}