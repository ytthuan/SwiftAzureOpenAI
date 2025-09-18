import Foundation

/// Represents a file object from the Azure OpenAI Files API.
public struct SAOAIFile: Codable, Equatable, Sendable {
    /// The file identifier.
    public let id: String
    /// The size of the file in bytes.
    public let bytes: Int?
    /// Unix timestamp when the file was created.
    public let createdAt: Int
    /// Unix timestamp when the file expires (if applicable).
    public let expiresAt: Int?
    /// The name of the file.
    public let filename: String
    /// The object type, should be "file".
    public let object: String
    /// The intended purpose of the file.
    public let purpose: String
    /// The current status of the file.
    public let status: String?
    /// Additional status details if the file failed processing.
    public let statusDetails: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case bytes
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case filename
        case object
        case purpose
        case status
        case statusDetails = "status_details"
    }
    
    /// Initialize a SAOAIFile for testing purposes.
    public init(id: String, bytes: Int?, createdAt: Int, expiresAt: Int?, filename: String, object: String, purpose: String, status: String?, statusDetails: String?) {
        self.id = id
        self.bytes = bytes
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.filename = filename
        self.object = object
        self.purpose = purpose
        self.status = status
        self.statusDetails = statusDetails
    }
}

/// Response for listing files.
public struct SAOAIFileList: Codable, Equatable, Sendable {
    /// The list of files.
    public let data: [SAOAIFile]
    /// Whether there are more files available.
    public let hasMore: Bool
    /// The object type, should be "list".
    public let object: String
    
    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case object
    }
}

/// Response for deleting a file.
public struct SAOAIFileDeleteResponse: Codable, Equatable, Sendable {
    /// Whether the file was successfully deleted.
    public let deleted: Bool
    /// The ID of the deleted file.
    public let id: String
    /// The object type, should be "file".
    public let object: String
}

/// Supported file purposes for Azure OpenAI.
public enum SAOAIFilePurpose: String, Codable, CaseIterable {
    /// Files for use with Assistants (recommended workaround).
    case assistants = "assistants"
    /// Files for fine-tuning.
    case fineTune = "fine-tune"
    /// User data files (currently not supported, use assistants as workaround).
    case userData = "user_data"
}

/// Represents progress events during file upload streaming.
public enum SAOAIFileUploadProgress: Sendable {
    /// Upload progress with percentage (0.0 to 1.0) and status message
    case progress(Double, String)
    /// Upload completed with the final file object
    case completed(SAOAIFile)
    
    /// The progress percentage (0.0 to 1.0), or 1.0 if completed
    public var progressPercentage: Double {
        switch self {
        case .progress(let percentage, _):
            return percentage
        case .completed:
            return 1.0
        }
    }
    
    /// The status message describing the current progress step
    public var statusMessage: String {
        switch self {
        case .progress(_, let message):
            return message
        case .completed:
            return "Upload completed successfully"
        }
    }
    
    /// The final file object if upload is completed
    public var file: SAOAIFile? {
        switch self {
        case .progress:
            return nil
        case .completed(let file):
            return file
        }
    }
}