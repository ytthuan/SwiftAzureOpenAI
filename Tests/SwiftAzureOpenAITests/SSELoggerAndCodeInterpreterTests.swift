import XCTest
@testable import SwiftAzureOpenAI

/// Tests for the enhanced SSE logging and code interpreter tracking functionality
final class SSELoggerAndCodeInterpreterTests: XCTestCase {
    
    private var tempLogDirectory: URL!
    
    override func setUp() {
        super.setUp()
        // Create a temporary directory for test logs
        tempLogDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("sse_test_logs_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempLogDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempLogDirectory)
        super.tearDown()
    }
    
    // MARK: - SSE Logger Tests
    
    /// Test SSE logger configuration
    func testSSELoggerConfiguration() {
        // Test disabled configuration
        let disabledConfig = SSELoggerConfiguration.disabled
        XCTAssertFalse(disabledConfig.isEnabled)
        XCTAssertNil(disabledConfig.logFilePath)
        XCTAssertFalse(disabledConfig.includeTimestamp)
        XCTAssertFalse(disabledConfig.includeSequenceNumber)
        
        // Test enabled configuration
        let logPath = tempLogDirectory.appendingPathComponent("test.log").path
        let enabledConfig = SSELoggerConfiguration.enabled(logFilePath: logPath, includeTimestamp: true, includeSequenceNumber: true)
        XCTAssertTrue(enabledConfig.isEnabled)
        XCTAssertEqual(enabledConfig.logFilePath, logPath)
        XCTAssertTrue(enabledConfig.includeTimestamp)
        XCTAssertTrue(enabledConfig.includeSequenceNumber)
        
        print("✅ SSE logger configuration tests passed")
    }
    
    /// Test SSE logger event logging
    func testSSELoggerEventLogging() {
        let logPath = tempLogDirectory.appendingPathComponent("sse_events.log").path
        let config = SSELoggerConfiguration.enabled(logFilePath: logPath)
        let logger = SSELogger(configuration: config)
        
        // Create a test event
        let testEvent = AzureOpenAISSEEvent(
            type: "response.code_interpreter_call_code.delta",
            sequenceNumber: 1,
            response: nil,
            outputIndex: 0,
            item: AzureOpenAIEventItem(id: "test_item", type: "code_interpreter_call", status: "in_progress", arguments: nil, callId: nil, name: nil, summary: nil),
            itemId: "test_item_id",
            delta: "print('Hello, World!')",
            arguments: nil
        )
        
        // Log the event
        logger.logEvent(testEvent)
        
        // Give logger time to write (it's async)
        let expectation = XCTestExpectation(description: "Log file written")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify log file was created and contains expected content
        XCTAssertTrue(FileManager.default.fileExists(atPath: logPath))
        
        if let logContent = try? String(contentsOfFile: logPath, encoding: .utf8) {
            XCTAssertTrue(logContent.contains("response.code_interpreter_call_code.delta"))
            XCTAssertTrue(logContent.contains("test_item_id"))
            XCTAssertTrue(logContent.contains("print('Hello, World!')"))
            print("✅ SSE logger event logging test passed")
            print("📄 Log content sample: \(logContent.prefix(200))...")
        } else {
            XCTFail("Could not read log file content")
        }
    }
    
    /// Test SSE logger with disabled configuration
    func testSSELoggerDisabled() {
        let logger = SSELogger(configuration: .disabled)
        
        let testEvent = AzureOpenAISSEEvent(
            type: "response.text.delta",
            sequenceNumber: 1,
            response: nil,
            outputIndex: 0,
            item: nil,
            itemId: "test_id",
            delta: "test content",
            arguments: nil
        )
        
        // Should not crash or create files when disabled
        logger.logEvent(testEvent)
        
        print("✅ SSE logger disabled test passed")
    }
    
    /// Test SSE logging integration in OptimizedSSEParser
    func testSSELoggingIntegrationInOptimizedParser() async {
        print("🧪 Testing SSE logging integration in OptimizedSSEParser...")
        
        let logPath = tempLogDirectory.appendingPathComponent("integration_test.log").path
        let config = SSELoggerConfiguration.enabled(logFilePath: logPath)
        let logger = SSELogger(configuration: config)
        
        // Create test SSE data that would be parsed
        let testData = """
        data: {"type":"response.text.delta","sequenceNumber":1,"outputIndex":0,"itemId":"test_item","delta":"Hello, World!"}
        
        """.data(using: .utf8)!
        
        // Test the optimized parser with logger
        do {
            let response = try OptimizedSSEParser.parseSSEChunkOptimized(testData, logger: logger)
            
            XCTAssertNotNil(response, "Parser should return a valid response")
            
            // Give logger time to write (it's async)
            let expectation = XCTestExpectation(description: "Log file written")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
            await fulfillment(of: [expectation], timeout: 1.0)
            
            // Check if log file was created and contains expected content
            XCTAssertTrue(FileManager.default.fileExists(atPath: logPath))
            
            if let logContent = try? String(contentsOfFile: logPath, encoding: .utf8) {
                XCTAssertTrue(logContent.contains("response.text.delta"))
                XCTAssertTrue(logContent.contains("Hello, World!"))
                XCTAssertTrue(logContent.contains("RAW_CHUNK:"))
                print("✅ SSE logging integration test passed")
                print("📄 Log content: \(logContent.prefix(200))...")
            } else {
                XCTFail("Could not read log file content")
            }
            
        } catch {
            XCTFail("Error during test: \(error)")
        }
    }
    
    // MARK: - Code Interpreter Tracker Tests
    
    /// Test code interpreter container tracking
    func testCodeInterpreterContainerTracking() {
        let tracker = CodeInterpreterTracker()
        
        // Test tracking a new container
        let item = AzureOpenAIEventItem(
            id: "container_123",
            type: "code_interpreter_call",
            status: "created",
            arguments: nil,
            callId: nil,
            name: nil,
            summary: nil
        )
        
        let containerId = tracker.trackContainer(itemId: "item_456", item: item)
        XCTAssertEqual(containerId, "container_123")
        
        // Verify container was created
        let container = tracker.getContainer(itemId: "item_456")
        XCTAssertNotNil(container)
        XCTAssertEqual(container?.id, "container_123")
        XCTAssertEqual(container?.itemId, "item_456")
        XCTAssertEqual(container?.status, .created)
        XCTAssertEqual(container?.accumulatedCode, "")
        
        print("✅ Code interpreter container tracking test passed")
    }
    
    /// Test code interpreter delta accumulation
    func testCodeInterpreterDeltaAccumulation() {
        let tracker = CodeInterpreterTracker()
        
        // Set up a container
        let item = AzureOpenAIEventItem(id: "container_123", type: "code_interpreter_call", status: "created", arguments: nil, callId: nil, name: nil, summary: nil)
        _ = tracker.trackContainer(itemId: "item_456", item: item)
        
        // Add code deltas
        let updatedContainer1 = tracker.appendCodeDelta(itemId: "item_456", code: "import numpy as np\n")
        XCTAssertNotNil(updatedContainer1)
        XCTAssertEqual(updatedContainer1?.accumulatedCode, "import numpy as np\n")
        
        let updatedContainer2 = tracker.appendCodeDelta(itemId: "item_456", code: "print('Hello, World!')\n")
        XCTAssertNotNil(updatedContainer2)
        XCTAssertEqual(updatedContainer2?.accumulatedCode, "import numpy as np\nprint('Hello, World!')\n")
        
        print("✅ Code interpreter delta accumulation test passed")
    }
    
    /// Test code interpreter completion tracking
    func testCodeInterpreterCompletionTracking() {
        let tracker = CodeInterpreterTracker()
        
        // Set up a container
        let item = AzureOpenAIEventItem(id: "container_123", type: "code_interpreter_call", status: "created", arguments: nil, callId: nil, name: nil, summary: nil)
        _ = tracker.trackContainer(itemId: "item_456", item: item)
        
        // Add some code
        _ = tracker.appendCodeDelta(itemId: "item_456", code: "print('test')")
        
        // Mark code complete
        let completedContainer = tracker.markCodeComplete(itemId: "item_456", finalCode: "print('final version')")
        XCTAssertNotNil(completedContainer)
        XCTAssertEqual(completedContainer?.accumulatedCode, "print('final version')")
        XCTAssertEqual(completedContainer?.status, .interpreting)
        
        // Mark fully completed
        let finalContainer = tracker.markCompleted(itemId: "item_456")
        XCTAssertNotNil(finalContainer)
        XCTAssertEqual(finalContainer?.status, .completed)
        
        print("✅ Code interpreter completion tracking test passed")
    }
    
    /// Test tracking non-code-interpreter items
    func testNonCodeInterpreterItemTracking() {
        let tracker = CodeInterpreterTracker()
        
        // Test with function call item (should not be tracked)
        let functionItem = AzureOpenAIEventItem(
            id: "func_123",
            type: "function_call",
            status: "created",
            arguments: nil,
            callId: nil,
            name: "test_function",
            summary: nil
        )
        
        let containerId = tracker.trackContainer(itemId: "item_789", item: functionItem)
        XCTAssertNil(containerId)
        
        // Verify no container was created
        let container = tracker.getContainer(itemId: "item_789")
        XCTAssertNil(container)
        
        print("✅ Non-code-interpreter item tracking test passed")
    }
    
    // MARK: - Enhanced SSE Parser Tests
    
    /// Test enhanced SSE parsing with code interpreter tracking
    func testEnhancedSSEParsingWithCodeInterpreter() throws {
        let tracker = CodeInterpreterTracker()
        let config = SSELoggerConfiguration.enabled(logFilePath: tempLogDirectory.appendingPathComponent("parser_test.log").path)
        let logger = SSELogger(configuration: config)
        
        // Test output_item.added event for code interpreter
        let outputItemAddedData = """
        event: response.output_item.added
        data: {"type":"response.output_item.added","item_id":"item_123","item":{"id":"container_456","type":"code_interpreter_call","status":"created"}}
        
        """.data(using: .utf8)!
        
        let outputItemResponse = try SSEParser.parseSSEChunk(outputItemAddedData, logger: logger, codeInterpreterTracker: tracker)
        XCTAssertNotNil(outputItemResponse)
        XCTAssertEqual(outputItemResponse?.id, "container_456")
        
        // Verify container was tracked
        let container = tracker.getContainer(itemId: "item_123")
        XCTAssertNotNil(container)
        XCTAssertEqual(container?.id, "container_456")
        
        // Test code delta event
        let codeDeltaData = """
        event: response.code_interpreter_call_code.delta
        data: {"type":"response.code_interpreter_call_code.delta","item_id":"item_123","delta":"print('Hello')"}
        
        """.data(using: .utf8)!
        
        let deltaResponse = try SSEParser.parseSSEChunk(codeDeltaData, logger: logger, codeInterpreterTracker: tracker)
        XCTAssertNotNil(deltaResponse)
        XCTAssertEqual(deltaResponse?.output?.first?.content?.first?.text, "print('Hello')")
        
        // Verify code was accumulated
        let updatedContainer = tracker.getContainer(itemId: "item_123")
        XCTAssertEqual(updatedContainer?.accumulatedCode, "print('Hello')")
        
        print("✅ Enhanced SSE parsing with code interpreter test passed")
    }
    
    /// Test backward compatibility of SSE parser
    func testSSEParserBackwardCompatibility() throws {
        // Test that the original parseSSEChunk method still works
        let simpleData = """
        event: response.text.delta
        data: {"type":"response.text.delta","delta":"Hello, World!"}
        
        """.data(using: .utf8)!
        
        let response = try SSEParser.parseSSEChunk(simpleData)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.output?.first?.content?.first?.text, "Hello, World!")
        
        print("✅ SSE parser backward compatibility test passed")
    }
    
    /// Test configuration integration
    func testConfigurationIntegration() {
        // Test Azure configuration with SSE logger
        let azureConfig = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "test-deployment",
            sseLoggerConfiguration: .enabled(logFilePath: "/tmp/test.log")
        )
        
        XCTAssertTrue(azureConfig.sseLoggerConfiguration.isEnabled)
        XCTAssertEqual(azureConfig.sseLoggerConfiguration.logFilePath, "/tmp/test.log")
        
        // Test OpenAI configuration with SSE logger
        let openaiConfig = SAOAIOpenAIConfiguration(
            apiKey: "test-key",
            sseLoggerConfiguration: .disabled
        )
        
        XCTAssertFalse(openaiConfig.sseLoggerConfiguration.isEnabled)
        
        print("✅ Configuration integration test passed")
    }
}