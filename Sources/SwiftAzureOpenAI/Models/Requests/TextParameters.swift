import Foundation

/// Text configuration for response generation.
public struct SAOAIText: Codable, Equatable {
    /// The verbosity level for text generation. Typically "low", "medium", or "high".
    public let verbosity: String?
    
    /// Initialize with verbosity
    public init(verbosity: String?) {
        self.verbosity = verbosity
    }
}