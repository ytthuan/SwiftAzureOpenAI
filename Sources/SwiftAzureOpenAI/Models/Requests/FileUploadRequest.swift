import Foundation

/// Request model for uploading a file to Azure OpenAI.
public struct SAOAIFileUploadRequest: Codable {
    /// The file content as Data
    public let file: Data
    /// The purpose of the uploaded file.
    public let purpose: String
    /// The original filename
    public let filename: String
    
    public init(file: Data, purpose: String, filename: String) {
        self.file = file
        self.purpose = purpose  
        self.filename = filename
    }
}