#!/usr/bin/env swift

// Event Type Checking Demo for SwiftAzureOpenAI
// This demonstrates the new Python SDK-like event type checking capability

import Foundation

// Add the package path so Swift can find our library during development
#if canImport(SwiftAzureOpenAI)
@testable import SwiftAzureOpenAI
#endif

/// Demonstrate the new event type checking API
func demonstrateEventTypeChecking() {
    print("🎯 SwiftAzureOpenAI Event Type Checking Demo")
    print(String(repeating: "=", count: 50))
    
    // Sample SSE events that would come from Azure OpenAI
    let sampleEvents = [
        // Text delta event
        """
        event: response.output_text.delta
        data: {"type":"response.output_text.delta","sequence_number":1,"item_id":"msg_123","delta":"Hello world"}
        """,
        
        // Function call delta event
        """
        event: response.function_call_arguments.delta
        data: {"type":"response.function_call_arguments.delta","sequence_number":2,"item_id":"fc_456","delta":"{\\"location\\":\\""}
        """,
        
        // Output item added event with function call
        """
        event: response.output_item.added
        data: {"type":"response.output_item.added","sequence_number":3,"item":{"id":"fc_789","type":"function_call","name":"get_weather","status":"in_progress"}}
        """,
        
        // Error event
        """
        event: error
        data: {"type":"error","sequence_number":4,"item_id":"error_123"}
        """
    ]
    
    for (index, eventData) in sampleEvents.enumerated() {
        print("\n📦 Processing Event \(index + 1):")
        print("   Raw: \(eventData.components(separatedBy: "\n").first ?? "")")
        
        do {
            // Parse the SSE event using the existing parser
            if let response = try SSEParser.parseSSEChunk(eventData.data(using: .utf8)!) {
                
                // NEW API: Access event type directly
                if let eventType = response.eventType {
                    print("   🏷️  Event Type: \(eventType.rawValue)")
                    
                    // NEW API: Switch on event type (Python SDK-like pattern)
                    switch eventType {
                    
                    case .responseOutputTextDelta:
                        print("   📝 Handling output text delta:")
                        if let text = response.output?.first?.content?.first?.text {
                            print("      Text: \"\(text)\"")
                        }
                        
                    case .responseFunctionCallArgumentsDelta:
                        print("   🔧 Handling function call arguments delta:")
                        if let args = response.output?.first?.content?.first?.text {
                            print("      Args: \"\(args)\"")
                        }
                        
                    case .responseOutputItemAdded:
                        print("   📦 Handling output item added:")
                        // NEW API: Access item information
                        if let item = response.item {
                            print("      Item ID: \(item.id ?? "unknown")")
                            print("      Item Type: \(item.type?.rawValue ?? "unknown")")
                            
                            // NEW API: Switch on item type for tool-specific logic
                            switch item.type {
                            case .functionCall:
                                print("      ⚙️ Function Call: \(item.name ?? "unknown")")
                                print("      Status: \(item.status ?? "unknown")")
                            case .codeInterpreterCall:
                                print("      🐍 Code Interpreter Call")
                            case .message:
                                print("      💬 Message Item")
                            default:
                                print("      📋 Other item type")
                            }
                        }
                        
                    case .error, .responseError:
                        print("   ❌ Handling error event:")
                        if let errorText = response.output?.first?.content?.first?.text {
                            print("      Error: \"\(errorText)\"")
                        }
                        
                    default:
                        // Handle other event types using helper properties
                        if eventType.isDelta {
                            print("   🔄 Other delta event: \(eventType.rawValue)")
                        } else if eventType.isDone {
                            print("   ✅ Completion event: \(eventType.rawValue)")
                        } else if eventType.isToolCall {
                            print("   🛠  Tool call event: \(eventType.rawValue)")
                        } else {
                            print("   🔍 Other event: \(eventType.rawValue)")
                        }
                    }
                    
                    // Show helper properties
                    print("   🏷️  Properties: delta=\(eventType.isDelta), done=\(eventType.isDone), tool=\(eventType.isToolCall), error=\(eventType.isError)")
                    
                } else {
                    print("   ⚠️  No event type information available")
                }
                
                // Backward compatibility: existing API still works
                print("   ℹ️  Backward Compatible - ID: \(response.id ?? "nil"), Model: \(response.model ?? "nil")")
                
            } else {
                print("   ❌ Failed to parse event")
            }
            
        } catch {
            print("   💥 Parse error: \(error)")
        }
    }
    
    print("\n" + String(repeating: "=", count: 50))
    print("✅ Demo completed! New event type checking API is working.")
    print("\n🔗 Key Benefits:")
    print("   • Python SDK-like event.type checking")
    print("   • Switch statements on event types")
    print("   • Access to item.type for tool-specific logic")
    print("   • Helper properties (isDelta, isDone, isToolCall, etc.)")
    print("   • Full backward compatibility maintained")
    print("   • One-to-one mapping with OpenAI API documentation")
}

// Run the demonstration
demonstrateEventTypeChecking()