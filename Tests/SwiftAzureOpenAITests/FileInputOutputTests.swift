import XCTest
@testable import SwiftAzureOpenAI

/// Comprehensive tests for file input and output functionality.
class FileInputOutputTests: XCTestCase {

    // MARK: - InputFile Struct Tests

    func testInputFileWithBase64Data() {
        let filename = "test.pdf"
        let base64Data = "dGVzdCBwZGYgZGF0YQ=="
        let mimeType = "application/pdf"
        
        let inputFile = SAOAIInputContent.InputFile(filename: filename, base64Data: base64Data, mimeType: mimeType)
        
        XCTAssertEqual(inputFile.type, "input_file")
        XCTAssertEqual(inputFile.filename, filename)
        XCTAssertEqual(inputFile.fileData, "data:\(mimeType);base64,\(base64Data)")
        XCTAssertNil(inputFile.fileId)
    }
    
    func testInputFileWithFileData() {
        let filename = "test.pdf"
        let fileData = "data:application/pdf;base64,dGVzdCBwZGYgZGF0YQ=="
        
        let inputFile = SAOAIInputContent.InputFile(filename: filename, fileData: fileData)
        
        XCTAssertEqual(inputFile.type, "input_file")
        XCTAssertEqual(inputFile.filename, filename)
        XCTAssertEqual(inputFile.fileData, fileData)
        XCTAssertNil(inputFile.fileId)
    }
    
    func testInputFileWithFileId() {
        let fileId = "assistant-KaVLJQTiWEvdz8yJQHHkqJ"
        
        let inputFile = SAOAIInputContent.InputFile(fileId: fileId)
        
        XCTAssertEqual(inputFile.type, "input_file")
        XCTAssertNil(inputFile.filename)
        XCTAssertNil(inputFile.fileData)
        XCTAssertEqual(inputFile.fileId, fileId)
    }

    // MARK: - InputFile Encoding Tests

    func testInputFileEncodingWithBase64Data() throws {
        let inputFile = SAOAIInputContent.InputFile(
            filename: "test.pdf",
            base64Data: "dGVzdCBwZGYgZGF0YQ==",
            mimeType: "application/pdf"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(inputFile)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        XCTAssertEqual(json["type"] as? String, "input_file")
        XCTAssertEqual(json["filename"] as? String, "test.pdf")
        XCTAssertEqual(json["file_data"] as? String, "data:application/pdf;base64,dGVzdCBwZGYgZGF0YQ==")
        XCTAssertNil(json["file_id"])
    }
    
    func testInputFileEncodingWithFileId() throws {
        let inputFile = SAOAIInputContent.InputFile(fileId: "assistant-123456789")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(inputFile)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        XCTAssertEqual(json["type"] as? String, "input_file")
        XCTAssertEqual(json["file_id"] as? String, "assistant-123456789")
        XCTAssertNil(json["filename"])
        XCTAssertNil(json["file_data"])
    }

    // MARK: - InputFile Decoding Tests

    func testInputFileDecodingWithBase64Data() throws {
        let json = """
        {
            "type": "input_file",
            "filename": "test.pdf",
            "file_data": "data:application/pdf;base64,dGVzdCBwZGYgZGF0YQ=="
        }
        """
        
        let decoder = JSONDecoder()
        let data = json.data(using: .utf8)!
        let inputFile = try decoder.decode(SAOAIInputContent.InputFile.self, from: data)
        
        XCTAssertEqual(inputFile.type, "input_file")
        XCTAssertEqual(inputFile.filename, "test.pdf")
        XCTAssertEqual(inputFile.fileData, "data:application/pdf;base64,dGVzdCBwZGYgZGF0YQ==")
        XCTAssertNil(inputFile.fileId)
    }
    
    func testInputFileDecodingWithFileId() throws {
        let json = """
        {
            "type": "input_file",
            "file_id": "assistant-123456789"
        }
        """
        
        let decoder = JSONDecoder()
        let data = json.data(using: .utf8)!
        let inputFile = try decoder.decode(SAOAIInputContent.InputFile.self, from: data)
        
        XCTAssertEqual(inputFile.type, "input_file")
        XCTAssertNil(inputFile.filename)
        XCTAssertNil(inputFile.fileData)
        XCTAssertEqual(inputFile.fileId, "assistant-123456789")
    }

    // MARK: - SAOAIInputContent Integration Tests

    func testInputContentWithInputFile() throws {
        let inputFile = SAOAIInputContent.InputFile(fileId: "assistant-123456789")
        let inputContent = SAOAIInputContent.inputFile(inputFile)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(inputContent)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        XCTAssertEqual(json["type"] as? String, "input_file")
        XCTAssertEqual(json["file_id"] as? String, "assistant-123456789")
    }
    
    func testInputContentDecodingWithInputFile() throws {
        let json = """
        {
            "type": "input_file",
            "file_id": "assistant-123456789"
        }
        """
        
        let decoder = JSONDecoder()
        let data = json.data(using: .utf8)!
        let inputContent = try decoder.decode(SAOAIInputContent.self, from: data)
        
        switch inputContent {
        case .inputFile(let inputFile):
            XCTAssertEqual(inputFile.fileId, "assistant-123456789")
            XCTAssertNil(inputFile.filename)
            XCTAssertNil(inputFile.fileData)
        default:
            XCTFail("Expected inputFile case")
        }
    }

    // MARK: - SAOAIMessage Convenience Initializer Tests

    func testMessageWithBase64File() {
        let message = SAOAIMessage(
            role: .user,
            text: "Summarize this PDF",
            filename: "test.pdf",
            base64FileData: "dGVzdCBwZGYgZGF0YQ==",
            mimeType: "application/pdf"
        )
        
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content.count, 2)
        
        // Check text content
        switch message.content[0] {
        case .inputText(let textContent):
            XCTAssertEqual(textContent.text, "Summarize this PDF")
        default:
            XCTFail("Expected inputText as first content")
        }
        
        // Check file content
        switch message.content[1] {
        case .inputFile(let fileContent):
            XCTAssertEqual(fileContent.filename, "test.pdf")
            XCTAssertEqual(fileContent.fileData, "data:application/pdf;base64,dGVzdCBwZGYgZGF0YQ==")
            XCTAssertNil(fileContent.fileId)
        default:
            XCTFail("Expected inputFile as second content")
        }
    }
    
    func testMessageWithFileId() {
        let message = SAOAIMessage(
            role: .user,
            text: "Analyze this document",
            fileId: "assistant-123456789"
        )
        
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content.count, 2)
        
        // Check text content
        switch message.content[0] {
        case .inputText(let textContent):
            XCTAssertEqual(textContent.text, "Analyze this document")
        default:
            XCTFail("Expected inputText as first content")
        }
        
        // Check file content
        switch message.content[1] {
        case .inputFile(let fileContent):
            XCTAssertNil(fileContent.filename)
            XCTAssertNil(fileContent.fileData)
            XCTAssertEqual(fileContent.fileId, "assistant-123456789")
        default:
            XCTFail("Expected inputFile as second content")
        }
    }

    // MARK: - Real-world Usage Example Tests

    func testCompleteFileInputWorkflowWithBase64() throws {
        // Simulate a complete workflow
        let base64Data = "dGVzdCBwZGYgZGF0YQ=="
        let filename = "sample.pdf"
        
        // Create message with file
        let message = SAOAIMessage(
            role: .user,
            text: "Please analyze this PDF document",
            filename: filename,
            base64FileData: base64Data,
            mimeType: "application/pdf"
        )
        
        // Create request
        let request = SAOAIRequest(
            model: "gpt-4o",
            input: [.message(message)],
            maxOutputTokens: 1000,
            temperature: 0.7
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        
        // Verify the request can be decoded back
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedRequest = try decoder.decode(SAOAIRequest.self, from: data)
        
        XCTAssertEqual(decodedRequest.model, "gpt-4o")
        XCTAssertEqual(decodedRequest.input.count, 1)
    }
    
    func testCompleteFileInputWorkflowWithFileId() throws {
        // Simulate uploaded file workflow
        let fileId = "assistant-KaVLJQTiWEvdz8yJQHHkqJ"
        
        // Create message with file ID
        let message = SAOAIMessage(
            role: .user,
            text: "Summarize the uploaded document",
            fileId: fileId
        )
        
        // Create request
        let request = SAOAIRequest(
            model: "gpt-4o-mini",
            input: [.message(message)]
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        
        // Parse JSON to verify structure
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let inputArray = json["input"] as! [[String: Any]]
        let inputMessage = inputArray[0]
        let content = inputMessage["content"] as! [[String: Any]]
        
        XCTAssertEqual(content.count, 2)
        XCTAssertEqual(content[0]["type"] as? String, "input_text")
        XCTAssertEqual(content[1]["type"] as? String, "input_file")
        XCTAssertEqual(content[1]["file_id"] as? String, fileId)
    }

    // MARK: - Edge Case Tests

    func testInputFileEquality() {
        let file1 = SAOAIInputContent.InputFile(fileId: "test-123")
        let file2 = SAOAIInputContent.InputFile(fileId: "test-123")
        let file3 = SAOAIInputContent.InputFile(fileId: "test-456")
        
        XCTAssertEqual(file1, file2)
        XCTAssertNotEqual(file1, file3)
    }
    
    func testInputContentEquality() {
        let content1 = SAOAIInputContent.inputFile(.init(fileId: "test-123"))
        let content2 = SAOAIInputContent.inputFile(.init(fileId: "test-123"))
        let content3 = SAOAIInputContent.inputFile(.init(fileId: "test-456"))
        
        XCTAssertEqual(content1, content2)
        XCTAssertNotEqual(content1, content3)
    }

    // MARK: - JSON Format Verification Tests

    func testJSONFormatMatchesAzureDocumentation() throws {
        // Test Base64 file format matches Azure docs
        let base64Message = SAOAIMessage(
            role: .user,
            text: "Summarize this PDF",
            filename: "test.pdf",
            base64FileData: "dGVzdCBwZGYgZGF0YQ==",
            mimeType: "application/pdf"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(base64Message)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        // Verify top-level structure
        XCTAssertEqual(json["role"] as? String, "user")
        let content = json["content"] as! [[String: Any]]
        XCTAssertEqual(content.count, 2)
        
        // Verify text content
        XCTAssertEqual(content[0]["type"] as? String, "input_text")
        XCTAssertEqual(content[0]["text"] as? String, "Summarize this PDF")
        
        // Verify file content matches Azure format
        XCTAssertEqual(content[1]["type"] as? String, "input_file")
        XCTAssertEqual(content[1]["filename"] as? String, "test.pdf")
        XCTAssertEqual(content[1]["file_data"] as? String, "data:application/pdf;base64,dGVzdCBwZGYgZGF0YQ==")
        XCTAssertNil(content[1]["file_id"])
    }
    
    func testFileIDFormatMatchesAzureDocumentation() throws {
        // Test file ID format matches Azure docs
        let fileIdMessage = SAOAIMessage(
            role: .user,
            text: "Analyze this document",
            fileId: "assistant-KaVLJQTiWEvdz8yJQHHkqJ"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(fileIdMessage)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        let content = json["content"] as! [[String: Any]]
        XCTAssertEqual(content.count, 2)
        
        // Verify file content matches Azure format  
        XCTAssertEqual(content[1]["type"] as? String, "input_file")
        XCTAssertEqual(content[1]["file_id"] as? String, "assistant-KaVLJQTiWEvdz8yJQHHkqJ")
        XCTAssertNil(content[1]["filename"])
        XCTAssertNil(content[1]["file_data"])
    }
}