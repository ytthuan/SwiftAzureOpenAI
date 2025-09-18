import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A client for Azure OpenAI Files API operations.
public final class FilesClient: @unchecked Sendable {
    private let httpClient: HTTPClient
    private let responseService: ResponseServiceProtocol
    private let configuration: SAOAIConfiguration
    
    internal init(httpClient: HTTPClient, responseService: ResponseServiceProtocol, configuration: SAOAIConfiguration) {
        self.httpClient = httpClient
        self.responseService = responseService
        self.configuration = configuration
    }
    
    /// Helper to construct the files endpoint URL.
    private func filesEndpointURL() throws -> URL {
        var filesURL = configuration.baseURL
        if filesURL.absoluteString.contains("/openai/v1/responses") {
            let urlString = filesURL.absoluteString.replacingOccurrences(of: "/openai/v1/responses", with: "/openai/v1/files")
            guard let newURL = URL(string: urlString) else {
                throw SAOAIError.invalidRequest("Failed to construct files endpoint URL")
            }
            filesURL = newURL
        } else {
            filesURL = filesURL.appendingPathComponent("files")
        }
        return filesURL
    }

    /// Upload a file to Azure OpenAI.
    /// - Parameters:
    ///   - file: The file data to upload
    ///   - filename: The name of the file
    ///   - purpose: The purpose of the file (use .assistants as workaround for user_data)
    /// - Returns: The uploaded file object
    public func create(file: Data, filename: String, purpose: SAOAIFilePurpose) async throws -> SAOAIFile {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = Self.createMultipartFormData(file: file, filename: filename, purpose: purpose.rawValue, boundary: boundary)
        
        // Use the helper to construct the files endpoint URL
        let filesURL = try filesEndpointURL()
        
        var headers = configuration.headers
        headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        
        let request = APIRequest(
            method: "POST",
            url: filesURL,
            headers: headers,
            body: body
        )
        
        let (data, httpResponse) = try await httpClient.send(request)
        let result: APIResponse<SAOAIFile> = try await responseService.processResponse(data, response: httpResponse, type: SAOAIFile.self)
        return result.data
    }
    
    /// List all files.
    /// - Returns: A list of files
    public func list() async throws -> SAOAIFileList {
        // Construct the files endpoint URL
        var filesURL = configuration.baseURL
        
        // Replace the responses path with files path
        if filesURL.absoluteString.contains("/openai/v1/responses") {
            let urlString = filesURL.absoluteString.replacingOccurrences(of: "/openai/v1/responses", with: "/openai/v1/files")
            guard let newURL = URL(string: urlString) else {
                throw SAOAIError.invalidRequest("Failed to construct files endpoint URL")
            }
            filesURL = newURL
        } else {
            filesURL = filesURL.appendingPathComponent("files")
        }
        
        let request = APIRequest(
            method: "GET",
            url: filesURL,
            headers: configuration.headers
        )
        
        let (data, httpResponse) = try await httpClient.send(request)
        let result: APIResponse<SAOAIFileList> = try await responseService.processResponse(data, response: httpResponse, type: SAOAIFileList.self)
        return result.data
    }
    
    /// Retrieve a specific file by ID.
    /// - Parameter fileId: The ID of the file to retrieve
    /// - Returns: The file object
    public func retrieve(_ fileId: String) async throws -> SAOAIFile {
        // Construct the files endpoint URL
        var filesURL = configuration.baseURL
        
        // Replace the responses path with files path
        if filesURL.absoluteString.contains("/openai/v1/responses") {
            let urlString = filesURL.absoluteString.replacingOccurrences(of: "/openai/v1/responses", with: "/openai/v1/files")
            guard let newURL = URL(string: urlString) else {
                throw SAOAIError.invalidRequest("Failed to construct files endpoint URL")
            }
            filesURL = newURL
        } else {
            filesURL = filesURL.appendingPathComponent("files")
        }
        
        filesURL = filesURL.appendingPathComponent(fileId)
        
        let request = APIRequest(
            method: "GET",
            url: filesURL,
            headers: configuration.headers
        )
        
        let (data, httpResponse) = try await httpClient.send(request)
        let result: APIResponse<SAOAIFile> = try await responseService.processResponse(data, response: httpResponse, type: SAOAIFile.self)
        return result.data
    }
    
    /// Delete a file.
    /// - Parameter fileId: The ID of the file to delete
    /// - Returns: The delete response
    public func delete(_ fileId: String) async throws -> SAOAIFileDeleteResponse {
        // Construct the files endpoint URL
        var filesURL = configuration.baseURL
        
        // Replace the responses path with files path
        if filesURL.absoluteString.contains("/openai/v1/responses") {
            let urlString = filesURL.absoluteString.replacingOccurrences(of: "/openai/v1/responses", with: "/openai/v1/files")
            guard let newURL = URL(string: urlString) else {
                throw SAOAIError.invalidRequest("Failed to construct files endpoint URL")
            }
            filesURL = newURL
        } else {
            filesURL = filesURL.appendingPathComponent("files")
        }
        
        filesURL = filesURL.appendingPathComponent(fileId)
        
        let request = APIRequest(
            method: "DELETE",
            url: filesURL,
            headers: configuration.headers
        )
        
        let (data, httpResponse) = try await httpClient.send(request)
        let result: APIResponse<SAOAIFileDeleteResponse> = try await responseService.processResponse(data, response: httpResponse, type: SAOAIFileDeleteResponse.self)
        return result.data
    }
    
    // MARK: - Streaming Methods
    
    /// Retrieve file content as a streaming download for large files.
    /// - Parameter fileId: The ID of the file to retrieve content for
    /// - Returns: An AsyncThrowingStream of Data chunks representing the file content
    public func streamContent(_ fileId: String) -> AsyncThrowingStream<Data, Error> {
        // Capture needed values outside the stream to avoid concurrency issues
        let configuration = self.configuration
        let httpClient = self.httpClient
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Construct the files content endpoint URL
                    var filesURL = configuration.baseURL
                    if filesURL.absoluteString.contains("/openai/v1/responses") {
                        let urlString = filesURL.absoluteString.replacingOccurrences(of: "/openai/v1/responses", with: "/openai/v1/files")
                        guard let newURL = URL(string: urlString) else {
                            continuation.finish(throwing: SAOAIError.invalidRequest("Failed to construct files endpoint URL"))
                            return
                        }
                        filesURL = newURL
                    } else {
                        filesURL = filesURL.appendingPathComponent("files")
                    }
                    filesURL = filesURL.appendingPathComponent(fileId).appendingPathComponent("content")
                    
                    let request = APIRequest(
                        method: "GET",
                        url: filesURL,
                        headers: configuration.headers
                    )
                    
                    let stream = httpClient.sendStreaming(request)
                    
                    for try await chunk in stream {
                        continuation.yield(chunk)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Create multipart form data for file upload.
    private static func createMultipartFormData(file: Data, filename: String, purpose: String, boundary: String) -> Data {
        var body = Data()
        
        // Add purpose field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"purpose\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(purpose)\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(file)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}