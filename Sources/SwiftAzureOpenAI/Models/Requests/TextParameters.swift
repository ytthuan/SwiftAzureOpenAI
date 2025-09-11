import Foundation

/// Text configuration for response generation.
public struct SAOAIText: Codable, Equatable {
    /// The verbosity level for text generation. Typically "low", "medium", or "high".
    public let verbosity: String?
    
    /// Initialize with verbosity.
    /// - Parameter verbosity: The verbosity level for text generation. Pass "low", "medium", "high", or nil.
    ///   If nil, the default verbosity will be used.
    public init(verbosity: String?) {
        self.verbosity = verbosity
    }

    /// Convenience initializer for low verbosity.
    public static func low() -> SAOAIText {
        return SAOAIText(verbosity: "low")
    }

    /// Convenience initializer for medium verbosity.
    public static func medium() -> SAOAIText {
        return SAOAIText(verbosity: "medium")
    }

    /// Convenience initializer for high verbosity.
    public static func high() -> SAOAIText {
        return SAOAIText(verbosity: "high")
    }
}