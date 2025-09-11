import Foundation

/// Reasoning configuration for reasoning models.
public struct SAOAIReasoning: Codable, Equatable {
    /// The effort level for reasoning models. Typically "low", "medium", or "high".
    public let effort: String
    /// The summary type for reasoning output. Typically "auto", "concise", or "detailed".
    public let summary: String?
    
    /// Initialize with effort only (backward compatibility)
    public init(effort: String) {
        self.effort = effort
        self.summary = nil
    }
    
    /// Initialize with effort and summary
    public init(effort: String, summary: String?) {
        self.effort = effort
        self.summary = summary
    }
}