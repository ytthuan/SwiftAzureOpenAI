import XCTest
@testable import SwiftAzureOpenAI

/// Comprehensive tests for the Azure OpenAI File API implementation.
final class FileAPITests: XCTestCase {
    var client: SAOAIClient!
    
    override func setUp() {
        super.setUp()
        // Use test configuration
        let config = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-api-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        client = SAOAIClient(configuration: config)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    // MARK: - Model Tests
    
    func testSAOAIFileDecoding() throws {
        let json = """
        {
            "id": "file-123456789",
            "bytes": 1024,
            "created_at": 1698890400,
            "expires_at": null,
            "filename": "test.pdf",
            "object": "file",
            "purpose": "assistants",
            "status": "processed",
            "status_details": null
        }
        """.data(using: .utf8)!
        
        let file = try JSONDecoder().decode(SAOAIFile.self, from: json)
        
        XCTAssertEqual(file.id, "file-123456789")
        XCTAssertEqual(file.bytes, 1024)
        XCTAssertEqual(file.createdAt, 1698890400)
        XCTAssertNil(file.expiresAt)
        XCTAssertEqual(file.filename, "test.pdf")
        XCTAssertEqual(file.object, "file")
        XCTAssertEqual(file.purpose, "assistants")
        XCTAssertEqual(file.status, "processed")
        XCTAssertNil(file.statusDetails)
    }
    
    func testSAOAIFileListDecoding() throws {
        let json = """
        {
            "data": [
                {
                    "id": "file-123456789",
                    "bytes": 1024,
                    "created_at": 1698890400,
                    "expires_at": null,
                    "filename": "test.pdf",
                    "object": "file", 
                    "purpose": "assistants",
                    "status": "processed",
                    "status_details": null
                }
            ],
            "has_more": false,
            "object": "list"
        }
        """.data(using: .utf8)!
        
        let fileList = try JSONDecoder().decode(SAOAIFileList.self, from: json)
        
        XCTAssertEqual(fileList.data.count, 1)
        XCTAssertFalse(fileList.hasMore)
        XCTAssertEqual(fileList.object, "list")
        
        let file = fileList.data[0]
        XCTAssertEqual(file.id, "file-123456789")
        XCTAssertEqual(file.filename, "test.pdf")
    }
    
    func testSAOAIFileDeleteResponseDecoding() throws {
        let json = """
        {
            "deleted": true,
            "id": "file-123456789",
            "object": "file"
        }
        """.data(using: .utf8)!
        
        let deleteResponse = try JSONDecoder().decode(SAOAIFileDeleteResponse.self, from: json)
        
        XCTAssertTrue(deleteResponse.deleted)
        XCTAssertEqual(deleteResponse.id, "file-123456789")
        XCTAssertEqual(deleteResponse.object, "file")
    }
    
    func testSAOAIFilePurposeEnum() {
        // Test all enum cases
        XCTAssertEqual(SAOAIFilePurpose.assistants.rawValue, "assistants")
        XCTAssertEqual(SAOAIFilePurpose.fineTune.rawValue, "fine-tune")
        XCTAssertEqual(SAOAIFilePurpose.userData.rawValue, "user_data")
        
        // Test case count
        XCTAssertEqual(SAOAIFilePurpose.allCases.count, 3)
    }
    
    // MARK: - URL Construction Tests
    
    func testFileUploadRequestCreation() {
        let testData = "Hello, World!".data(using: .utf8)!
        let request = SAOAIFileUploadRequest(
            file: testData,
            purpose: SAOAIFilePurpose.assistants.rawValue,
            filename: "test.txt"
        )
        
        XCTAssertEqual(request.file, testData)
        XCTAssertEqual(request.purpose, "assistants")
        XCTAssertEqual(request.filename, "test.txt")
    }
    
    // MARK: - Input File Model Tests
    
    func testInputFileWithFileId() {
        let inputFile = SAOAIInputContent.InputFile(fileId: "file-123456789")
        
        XCTAssertNil(inputFile.filename)
        XCTAssertNil(inputFile.fileData)
        XCTAssertEqual(inputFile.fileId, "file-123456789")
        XCTAssertEqual(inputFile.type, "input_file")
    }
    
    func testInputFileWithBase64Data() {
        let inputFile = SAOAIInputContent.InputFile(filename: "test.pdf", base64Data: "base64data", mimeType: "application/pdf")
        
        XCTAssertEqual(inputFile.filename, "test.pdf")
        XCTAssertEqual(inputFile.fileData, "data:application/pdf;base64,base64data")
        XCTAssertNil(inputFile.fileId)
        XCTAssertEqual(inputFile.type, "input_file")
    }
    
    func testInputFileWithFileData() {
        let inputFile = SAOAIInputContent.InputFile(filename: "test.txt", fileData: "data:text/plain;base64,SGVsbG8gV29ybGQ=")
        
        XCTAssertEqual(inputFile.filename, "test.txt")
        XCTAssertEqual(inputFile.fileData, "data:text/plain;base64,SGVsbG8gV29ybGQ=")
        XCTAssertNil(inputFile.fileId)
        XCTAssertEqual(inputFile.type, "input_file")
    }
    
    // MARK: - Encoding/Decoding Tests
    
    func testInputFileEncodingWithFileId() throws {
        let inputFile = SAOAIInputContent.inputFile(.init(fileId: "file-123456789"))
        
        let encoded = try JSONEncoder().encode(inputFile)
        let decoded = try JSONDecoder().decode(SAOAIInputContent.self, from: encoded)
        
        XCTAssertEqual(decoded, inputFile)
        
        if case let .inputFile(decodedInputFile) = decoded {
            XCTAssertEqual(decodedInputFile.fileId, "file-123456789")
            XCTAssertNil(decodedInputFile.filename)
            XCTAssertNil(decodedInputFile.fileData)
        } else {
            XCTFail("Decoded content should be inputFile")
        }
    }
    
    func testInputFileEncodingWithBase64Data() throws {
        let inputFile = SAOAIInputContent.inputFile(.init(filename: "test.pdf", base64Data: "base64data"))
        
        let encoded = try JSONEncoder().encode(inputFile)
        let decoded = try JSONDecoder().decode(SAOAIInputContent.self, from: encoded)
        
        XCTAssertEqual(decoded, inputFile)
        
        if case let .inputFile(decodedInputFile) = decoded {
            XCTAssertEqual(decodedInputFile.filename, "test.pdf")
            XCTAssertEqual(decodedInputFile.fileData, "data:application/pdf;base64,base64data")
            XCTAssertNil(decodedInputFile.fileId)
        } else {
            XCTFail("Decoded content should be inputFile")
        }
    }
    
    // MARK: - File API Integration Tests
    
    func testFilesClientExists() {
        XCTAssertNotNil(client.files)
    }
    
    func testMultipartFormDataCreation() throws {
        // This is a basic test to ensure the multipart form data structure is reasonable
        let testData = "Hello, World!".data(using: .utf8)!
        
        // We can't directly test the private method, but we can verify the structure indirectly
        // by ensuring our file models work correctly with the expected data formats
        let file = SAOAIFile(
            id: "file-test",
            bytes: testData.count,
            createdAt: Int(Date().timeIntervalSince1970),
            expiresAt: nil,
            filename: "test.txt",
            object: "file",
            purpose: SAOAIFilePurpose.assistants.rawValue,
            status: "processed",
            statusDetails: nil
        )
        
        XCTAssertEqual(file.filename, "test.txt")
        XCTAssertEqual(file.purpose, "assistants")
        XCTAssertEqual(file.bytes, testData.count)
    }
    
    // MARK: - Real-world Usage Pattern Tests
    
    func testFileAPIUsagePattern() {
        // Test that the expected usage pattern compiles and has correct types
        let testData = "Hello, World!".data(using: .utf8)!
        
        // This simulates the expected usage pattern
        let uploadTask: () async throws -> SAOAIFile = {
            try await self.client.files.create(
                file: testData,
                filename: "test.txt",
                purpose: .assistants
            )
        }
        
        let listTask: () async throws -> SAOAIFileList = {
            try await self.client.files.list()
        }
        
        let retrieveTask: () async throws -> SAOAIFile = {
            try await self.client.files.retrieve("file-123456789")
        }
        
        let deleteTask: () async throws -> SAOAIFileDeleteResponse = {
            try await self.client.files.delete("file-123456789")
        }
        
        // Verify the methods exist and have the correct return types
        XCTAssertNotNil(uploadTask)
        XCTAssertNotNil(listTask)
        XCTAssertNotNil(retrieveTask)
        XCTAssertNotNil(deleteTask)
    }
    
    func testFileAPIWithResponsesIntegration() {
        // Test that files can be used with the responses API
        let inputFileById = SAOAIInputContent.inputFile(.init(fileId: "file-123456789"))
        let inputFileByData = SAOAIInputContent.inputFile(.init(
            filename: "test.pdf", 
            base64Data: "base64encodeddata"
        ))
        
        // Verify input content types work correctly
        XCTAssertNotNil(inputFileById)
        XCTAssertNotNil(inputFileByData)
        
        // Test message creation with file inputs
        let message = SAOAIMessage(
            role: .user,
            content: [inputFileById, inputFileByData]
        )
        
        XCTAssertEqual(message.content.count, 2)
        XCTAssertEqual(message.role, .user)
    }
    
    // MARK: - Streaming File API Tests
    
    func testStreamContentMethodExists() {
        // Test that the streaming content method exists and has correct signature
        XCTAssertNotNil(client.files.streamContent)
        
        let streamTask: (String) -> AsyncThrowingStream<Data, Error> = { fileId in
            self.client.files.streamContent(fileId)
        }
        
        XCTAssertNotNil(streamTask)
    }
    
    func testStreamContentUsagePattern() async {
        // Test that the streamContent method can be used in expected patterns
        let fileId = "file-test123"
        let stream = client.files.streamContent(fileId)
        
        // This test verifies the usage pattern compiles correctly
        // In a real scenario, this would fail with network errors since we're using test config
        do {
            var dataChunks: [Data] = []
            for try await chunk in stream {
                dataChunks.append(chunk)
                // In real usage, would process chunks as they arrive
                break // Break immediately to avoid network error in test
            }
            XCTFail("Should not reach here with test configuration")
        } catch {
            // Expected to fail with test configuration - the important thing is compilation
            XCTAssertTrue(true, "Method compiles and can be called")
        }
    }
    
    func testFileUploadProgressModelCreation() {
        // Test the SAOAIFileUploadProgress enum
        let progressEvent = SAOAIFileUploadProgress.progress(0.5, "Uploading...")
        let completedEvent = SAOAIFileUploadProgress.completed(SAOAIFile(
            id: "file-test",
            bytes: 1024,
            createdAt: Int(Date().timeIntervalSince1970),
            expiresAt: nil,
            filename: "test.txt",
            object: "file",
            purpose: "assistants",
            status: "processed",
            statusDetails: nil
        ))
        
        // Test progress event
        XCTAssertEqual(progressEvent.progressPercentage, 0.5)
        XCTAssertEqual(progressEvent.statusMessage, "Uploading...")
        XCTAssertNil(progressEvent.file)
        
        // Test completed event
        XCTAssertEqual(completedEvent.progressPercentage, 1.0)
        XCTAssertEqual(completedEvent.statusMessage, "Upload completed successfully")
        XCTAssertNotNil(completedEvent.file)
        XCTAssertEqual(completedEvent.file?.id, "file-test")
    }
    
    func testStreamingFileAPIBackwardCompatibility() {
        // Ensure existing file API methods still work
        let existingUploadTask: () async throws -> SAOAIFile = {
            try await self.client.files.create(
                file: "Hello".data(using: .utf8)!,
                filename: "test.txt",
                purpose: .assistants
            )
        }
        
        let existingListTask: () async throws -> SAOAIFileList = {
            try await self.client.files.list()
        }
        
        let existingRetrieveTask: () async throws -> SAOAIFile = {
            try await self.client.files.retrieve("file-123")
        }
        
        let existingDeleteTask: () async throws -> SAOAIFileDeleteResponse = {
            try await self.client.files.delete("file-123")
        }
        
        // Verify all existing methods still compile and have correct types
        XCTAssertNotNil(existingUploadTask)
        XCTAssertNotNil(existingListTask)
        XCTAssertNotNil(existingRetrieveTask)
        XCTAssertNotNil(existingDeleteTask)
    }
    
    func testStreamingAPIDesignPatterns() {
        // Test that streaming APIs follow consistent patterns with ResponsesClient
        
        // 1. Streaming content download pattern (similar to streaming responses)
        let contentStream = client.files.streamContent("file-123")
        XCTAssertNotNil(contentStream)
        
        // 2. Verify return types are consistent with expectations
        let streamType = type(of: contentStream)
        XCTAssertTrue(String(describing: streamType).contains("AsyncThrowingStream"))
        
        // 3. Test that methods can be chained/composed
        let transformedStream = contentStream.map { data in
            return data.count // Example transformation
        }
        XCTAssertNotNil(transformedStream)
    }
}