import Foundation

/// Reasoning configuration for reasoning models.
public struct Reasoning: Codable, Equatable {
    /// The effort level for reasoning models. Typically "low", "medium", or "high".
    public let effort: String
    
    public init(effort: String) {
        self.effort = effort
    }
}