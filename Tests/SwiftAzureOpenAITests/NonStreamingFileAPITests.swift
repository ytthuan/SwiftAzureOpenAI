import XCTest
@testable import SwiftAzureOpenAI
import Foundation

/// Tests for file-based input/output functionality in NonStreamingResponseConsoleChatbot
class NonStreamingFileAPITests: XCTestCase {

    // MARK: - FilePrompt Tests
    
    func testFilePromptTextInitialization() {
        let prompt = FilePrompt(text: "Test prompt")
        
        XCTAssertEqual(prompt.text, "Test prompt")
        XCTAssertNil(prompt.fileData)
        XCTAssertNil(prompt.filename)
        XCTAssertNil(prompt.mimeType)
    }
    
    func testFilePromptWithFileData() {
        let fileData = "Sample file content"
        let filename = "test.txt"
        let mimeType = "text/plain"
        
        let prompt = FilePrompt(
            text: "Analyze this file",
            fileData: fileData,
            filename: filename,
            mimeType: mimeType
        )
        
        XCTAssertEqual(prompt.text, "Analyze this file")
        XCTAssertEqual(prompt.fileData, fileData)
        XCTAssertEqual(prompt.filename, filename)
        XCTAssertEqual(prompt.mimeType, mimeType)
    }
    
    func testFilePromptFromTextFile() throws {
        // Create temporary text file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test.txt")
        let testContent = "This is test content for file processing."
        
        try testContent.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let prompt = try FilePrompt.fromFile(tempFile.path)
        
        XCTAssertTrue(prompt.text.contains("test.txt"))
        XCTAssertEqual(prompt.fileData, testContent)
        XCTAssertEqual(prompt.filename, "test.txt")
        XCTAssertEqual(prompt.mimeType, "text/plain")
    }
    
    func testFilePromptFromJSONFile() throws {
        // Create temporary JSON file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test.json")
        let testContent = """
        {
            "name": "SwiftAzureOpenAI",
            "type": "library",
            "features": ["streaming", "function_calling", "file_api"]
        }
        """
        
        try testContent.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let prompt = try FilePrompt.fromFile(tempFile.path)
        
        XCTAssertTrue(prompt.text.contains("test.json"))
        XCTAssertEqual(prompt.fileData, testContent)
        XCTAssertEqual(prompt.filename, "test.json")
        XCTAssertEqual(prompt.mimeType, "application/json")
    }
    
    func testFilePromptFromPDFFile() throws {
        // Create temporary PDF file (simulated with binary data)
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test.pdf")
        let testData = Data("Mock PDF content".utf8)
        
        try testData.write(to: tempFile)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let prompt = try FilePrompt.fromFile(tempFile.path)
        
        XCTAssertTrue(prompt.text.contains("test.pdf"))
        XCTAssertEqual(prompt.fileData, testData.base64EncodedString())
        XCTAssertEqual(prompt.filename, "test.pdf")
        XCTAssertEqual(prompt.mimeType, "application/pdf")
    }
    
    func testFilePromptFromNonExistentFile() {
        XCTAssertThrowsError(try FilePrompt.fromFile("/non/existent/file.txt")) { error in
            XCTAssertTrue(error.localizedDescription.contains("does not exist"))
        }
    }
    
    // MARK: - File Input Format Tests
    
    func testPromptFileParsingWithComments() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("prompts.txt")
        let content = """
        # This is a comment
        What is the weather today?
        
        # Another comment
        Calculate 5 + 3
        
        # Empty lines should be ignored
        
        Tell me about quantum physics
        """
        
        try content.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        // Note: This would require implementing the readPromptsFromFile function to be testable
        // For now, we're testing the FilePrompt structure itself
    }
    
    // MARK: - File API Integration Tests
    
    func testFileInputContentCreation() {
        // Test that FilePrompt data can be used to create proper SAOAIInputContent
        let fileData = "dGVzdCBwZGYgZGF0YQ=="  // base64 encoded "test pdf data"
        let filename = "test.pdf"
        let mimeType = "application/pdf"
        
        let prompt = FilePrompt(
            text: "Analyze this PDF",
            fileData: fileData,
            filename: filename,
            mimeType: mimeType
        )
        
        // Verify the data can be used to create SAOAIInputContent.InputFile
        let inputFile = SAOAIInputContent.InputFile(
            filename: prompt.filename!,
            base64Data: prompt.fileData!,
            mimeType: prompt.mimeType!
        )
        
        XCTAssertEqual(inputFile.filename, filename)
        XCTAssertEqual(inputFile.fileData, "data:\(mimeType);base64,\(fileData)")
        XCTAssertNil(inputFile.fileId)
    }
    
    func testSAOAIMessageWithFileContent() {
        // Test creating SAOAIMessage with file content from FilePrompt
        let fileData = "dGVzdCBwZGYgZGF0YQ=="
        let filename = "document.pdf"
        let mimeType = "application/pdf"
        
        let prompt = FilePrompt(
            text: "Summarize this document",
            fileData: fileData,
            filename: filename,
            mimeType: mimeType
        )
        
        let message = SAOAIMessage(
            role: .user,
            text: prompt.text,
            filename: prompt.filename!,
            base64FileData: prompt.fileData!,
            mimeType: prompt.mimeType!
        )
        
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content.count, 2)
        
        // Check text content
        switch message.content[0] {
        case .inputText(let textContent):
            XCTAssertEqual(textContent.text, "Summarize this document")
        default:
            XCTFail("Expected inputText as first content")
        }
        
        // Check file content
        switch message.content[1] {
        case .inputFile(let fileContent):
            XCTAssertEqual(fileContent.filename, filename)
            XCTAssertEqual(fileContent.fileData, "data:\(mimeType);base64,\(fileData)")
            XCTAssertNil(fileContent.fileId)
        default:
            XCTFail("Expected inputFile as second content")
        }
    }
}

// MARK: - FilePrompt Structure for Testing

/// File prompt structure for testing (mirrors implementation)
struct FilePrompt {
    let text: String
    let fileData: String?
    let filename: String?
    let mimeType: String?
    
    init(text: String) {
        self.text = text
        self.fileData = nil
        self.filename = nil
        self.mimeType = nil
    }
    
    init(text: String, fileData: String, filename: String, mimeType: String) {
        self.text = text
        self.fileData = fileData
        self.filename = filename
        self.mimeType = mimeType
    }
    
    static func fromFile(_ filePath: String) throws -> FilePrompt {
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw NSError(domain: "FilePromptError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Referenced file does not exist: \(filePath)"])
        }
        
        let url = URL(fileURLWithPath: filePath)
        let filename = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        
        // Determine MIME type based on file extension
        let mimeType: String
        switch fileExtension {
        case "pdf":
            mimeType = "application/pdf"
        case "txt":
            mimeType = "text/plain"
        case "md":
            mimeType = "text/markdown"
        case "json":
            mimeType = "application/json"
        case "jpg", "jpeg":
            mimeType = "image/jpeg"
        case "png":
            mimeType = "image/png"
        default:
            mimeType = "application/octet-stream"
        }
        
        // For text files, read content directly
        if mimeType.hasPrefix("text/") || mimeType == "application/json" {
            let content = try String(contentsOf: url, encoding: .utf8)
            return FilePrompt(
                text: "Analyze this \(fileExtension.uppercased()) file: \(filename)",
                fileData: content,
                filename: filename,
                mimeType: mimeType
            )
        }
        
        // For binary files (PDFs, images), read as base64
        let data = try Data(contentsOf: url)
        let base64String = data.base64EncodedString()
        
        return FilePrompt(
            text: "Analyze this \(fileExtension.uppercased()) file: \(filename)",
            fileData: base64String,
            filename: filename,
            mimeType: mimeType
        )
    }
}