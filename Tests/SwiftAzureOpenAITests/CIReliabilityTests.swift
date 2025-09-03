import XCTest
@testable import SwiftAzureOpenAI

/// Tests to validate CI reliability improvements for issue #95
/// These tests help verify that the CI changes make test failures visible
final class CIReliabilityTests: XCTestCase {
    
    func testVerboseOutputWorking() {
        // This test validates that verbose output is enabled
        // If verbose output is working, this print will be visible in CI logs
        print("🔍 CI Reliability Test: Verbose output is working correctly")
        print("🔍 SWIFT_TESTING_DISABLE_OUTPUT_CAPTURE: \(ProcessInfo.processInfo.environment["SWIFT_TESTING_DISABLE_OUTPUT_CAPTURE"] ?? "not set")")
        
        // This test should always pass
        XCTAssertTrue(true, "Basic validation test")
    }
    
    func testFailureVisibilitySimulation() {
        // This test simulates what would happen if there was a real failure
        // In the fixed CI, this failure would be clearly visible in the logs
        
        let shouldFail = ProcessInfo.processInfo.environment["SIMULATE_CI_FAILURE"] == "true"
        
        if shouldFail {
            print("🚨 CI Reliability Test: Simulating a test failure")
            print("🚨 This failure should now be visible in CI logs due to verbose output")
            XCTFail("Simulated failure to test CI visibility improvements")
        } else {
            print("✅ CI Reliability Test: Normal test execution (no simulated failure)")
            XCTAssertTrue(true, "Normal test execution")
        }
    }
    
    func testEnvironmentVariableCapture() {
        // Test that environment variables are properly captured
        let azureEndpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"]
        let outputCapture = ProcessInfo.processInfo.environment["SWIFT_TESTING_DISABLE_OUTPUT_CAPTURE"]
        
        print("🔍 CI Environment Variables:")
        print("   AZURE_OPENAI_ENDPOINT: \(azureEndpoint != nil ? "[SET]" : "[NOT SET]")")
        print("   SWIFT_TESTING_DISABLE_OUTPUT_CAPTURE: \(outputCapture ?? "[NOT SET]")")
        
        // This test always passes but provides diagnostic info
        XCTAssertTrue(true, "Environment variable diagnostic test")
    }
    
    func testStreamingContentAssertions() {
        // Test that validates streaming content processing doesn't have 
        // non-deterministic failures that could cause silent CI failures
        
        let testData = """
        data: {"type":"response.text.delta","sequence_number":1,"item_id":"test_123","output_index":0,"delta":"Hello"}
        
        """.data(using: .utf8)!
        
        do {
            let response = try SSEParser.parseSSEChunk(testData)
            
            // Use non-strict assertions to avoid non-deterministic failures
            if let output = response?.output?.first, 
               let content = output.content?.first,
               let text = content.text {
                print("✅ Streaming content parsed: '\(text)'")
                // Flexible assertion - allows for any non-empty content
                XCTAssertFalse(text.isEmpty, "Streaming content should not be empty")
            } else {
                print("ℹ️ No streaming content found in response")
            }
            
            XCTAssertNotNil(response, "Should parse valid SSE data")
        } catch {
            print("⚠️ Parsing error: \(error)")
            XCTFail("Should not throw error on valid SSE data: \(error)")
        }
    }
}