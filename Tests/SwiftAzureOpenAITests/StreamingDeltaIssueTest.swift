import XCTest
@testable import SwiftAzureOpenAI

/// Test that reproduces the exact streaming issue from the GitHub issue
final class StreamingDeltaIssueTest: XCTestCase {
    
    /// Test that reproduces the actual issue: delta events not being decoded
    func testAzureOpenAIDeltaEventsNotDecodedProperly() async throws {
        // This is the exact SSE data from the debug logs in the issue
        let realAzureSSEData = """
event: response.created
data: {"type":"response.created","sequence_number":0,"response":{"id":"resp_68b42ea133f0819fa47fb3089111e62109a57c08f5ed8ae2","object":"response","created_at":1756638881,"status":"in_progress","background":false,"content_filters":null,"error":null,"incomplete_details":null,"instructions":null,"max_output_tokens":null,"max_tool_calls":null,"model":"gpt-5-nano","output":[],"parallel_tool_calls":true,"previous_response_id":null,"prompt_cache_key":null,"reasoning":{"effort":"medium","summary":null},"safety_identifier":null,"service_tier":"auto","store":true,"temperature":1.0,"text":{"format":{"type":"text"}},"tool_choice":"auto","tools":[{"type":"function","description":"Get current weather information for a specified location","name":"get_weather","parameters":{"properties":{"location":{"description":"The city and state/country, e.g. 'San Francisco, CA' or 'London, UK'","type":"string"},"unit":{"description":"Temperature unit preference","enum":["celsius","fahrenheit"],"type":"string"}},"required":["location"],"type":"object"},"strict":true}],"top_p":1.0,"truncation":"disabled","usage":null,"user":null,"metadata":{}}}

event: response.function_call_arguments.delta
data: {"type":"response.function_call_arguments.delta","sequence_number":5,"item_id":"fc_68b42ea2d094819fa31194caa8418e2209a57c08f5ed8ae2","output_index":1,"delta":"{\\""}

event: response.function_call_arguments.delta
data: {"type":"response.function_call_arguments.delta","sequence_number":6,"item_id":"fc_68b42ea2d094819fa31194caa8418e2209a57c08f5ed8ae2","output_index":1,"delta":"location"}

event: response.function_call_arguments.delta
data: {"type":"response.function_call_arguments.delta","sequence_number":7,"item_id":"fc_68b42ea2d094819fa31194caa8418e2209a57c08f5ed8ae2","output_index":1,"delta":"\\":\\""}

event: response.function_call_arguments.delta
data: {"type":"response.function_call_arguments.delta","sequence_number":8,"item_id":"fc_68b42ea2d094819fa31194caa8418e2209a57c08f5ed8ae2","output_index":1,"delta":"London"}

event: response.function_call_arguments.delta
data: {"type":"response.function_call_arguments.delta","sequence_number":9,"item_id":"fc_68b42ea2d094819fa31194caa8418e2209a57c08f5ed8ae2","output_index":1,"delta":","}

event: response.function_call_arguments.delta
data: {"type":"response.function_call_arguments.delta","sequence_number":10,"item_id":"fc_68b42ea2d094819fa31194caa8418e2209a57c08f5ed8ae2","output_index":1,"delta":" UK"}

event: response.completed
data: {"type":"response.completed","sequence_number":19,"response":{"id":"resp_68b42ea133f0819fa47fb3089111e62109a57c08f5ed8ae2","object":"response","created_at":1756638881,"status":"completed","background":false,"content_filters":null,"error":null,"incomplete_details":null,"instructions":null,"max_output_tokens":null,"max_tool_calls":null,"model":"gpt-5-nano","output":[{"id":"rs_68b42ea18e6c819fab53072169fe623d09a57c08f5ed8ae2","type":"reasoning","summary":[]},{"id":"fc_68b42ea2d094819fa31194caa8418e2209a57c08f5ed8ae2","type":"function_call","status":"completed","arguments":"{\\"location\\":\\"London, UK\\",\\"unit\\":\\"celsius\\"}","call_id":"call_qAXJJvw9i1cCryXdRKsychuv","name":"get_weather"}],"parallel_tool_calls":true,"previous_response_id":null,"prompt_cache_key":null,"reasoning":{"effort":"medium","summary":null},"safety_identifier":null,"service_tier":"default","store":true,"temperature":1.0,"text":{"format":{"type":"text"}},"tool_choice":"auto","tools":[{"type":"function","description":"Get current weather information for a specified location","name":"get_weather","parameters":{"properties":{"location":{"description":"The city and state/country, e.g. 'San Francisco, CA' or 'London, UK'","type":"string"},"unit":{"description":"Temperature unit preference","enum":["celsius","fahrenheit"],"type":"string"}},"required":["location"],"type":"object"},"strict":true}],"top_p":1.0,"truncation":"disabled","usage":{"input_tokens":91,"input_tokens_details":{"cached_tokens":0},"output_tokens":219,"output_tokens_details":{"reasoning_tokens":192},"total_tokens":310},"user":null,"metadata":{}}}

""".data(using: .utf8)!
        
        let lines = String(data: realAzureSSEData, encoding: .utf8)!.components(separatedBy: .newlines)
        var parsedResponses: [SAOAIStreamingResponse] = []
        var deltaContent = ""
        
        print("🐛 Testing actual Azure OpenAI SSE data from issue...")
        
        for line in lines {
            if !line.isEmpty {
                // Format the line as HTTPClient would do
                let lineData = line.data(using: .utf8)! + "\n\n".data(using: .utf8)!
                
                do {
                    if let response = try SSEParser.parseSSEChunk(lineData) {
                        parsedResponses.append(response)
                        print("📦 Chunk \(parsedResponses.count): id=\(response.id ?? "nil"), model=\(response.model ?? "nil"), output=\(response.output?.isEmpty != false ? "empty/nil" : "has data")")
                        
                        // Check if there's streaming content
                        if let output = response.output?.first, let content = output.content?.first, let text = content.text {
                            deltaContent += text
                            print("   📝 Content: '\(text)'")
                        }
                    }
                } catch {
                    print("❌ Failed to parse line: \(error)")
                }
            }
        }
        
        print("🔍 Total parsed responses: \(parsedResponses.count)")
        print("🔍 Accumulated delta content: '\(deltaContent)'")
        
        // The issue is demonstrated here: we should get streaming content from delta events
        // Currently, only 2 responses are parsed (response.created and response.completed)
        // but the 6 delta events are ignored, resulting in no streaming content
        
        // Expected: Delta events should produce streaming responses with text content
        // Actual: Delta events are ignored, parsedResponses.count is only 2, deltaContent is empty
        XCTAssertGreaterThan(parsedResponses.count, 2, "Should parse delta events as streaming responses")
        XCTAssertFalse(deltaContent.isEmpty, "Should accumulate streaming content from delta events")
    }
    
    /// Test individual delta event parsing
    func testIndividualDeltaEventParsing() throws {
        let deltaEventData = """
event: response.function_call_arguments.delta
data: {"type":"response.function_call_arguments.delta","sequence_number":8,"item_id":"fc_68b42ea2d094819fa31194caa8418e2209a57c08f5ed8ae2","output_index":1,"delta":"London"}

""".data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(deltaEventData)
        
        // Currently this returns nil because the event has no 'response' field
        // After fix, it should return a SAOAIStreamingResponse with content
        print("🔍 Delta event parsed as: \(String(describing: response))")
        
        XCTAssertNotNil(response, "Delta event should parse into streaming response")
        XCTAssertNotNil(response?.output?.first?.content?.first?.text, "Delta event should contain text content")
        XCTAssertEqual(response?.output?.first?.content?.first?.text, "London", "Delta content should match delta field")
    }
}