import Foundation

/// Response model for embeddings API
public struct SAOAIEmbeddingsResponse: Codable, Sendable {
    /// The object type (always "list" for embeddings)
    public let object: String
    /// Array of embedding objects
    public let data: [SAOAIEmbedding]
    /// Model used for generating embeddings
    public let model: String
    /// Usage statistics for the request
    public let usage: SAOAIEmbeddingUsage
    
    public init(
        object: String,
        data: [SAOAIEmbedding],
        model: String,
        usage: SAOAIEmbeddingUsage
    ) {
        self.object = object
        self.data = data
        self.model = model
        self.usage = usage
    }
}

/// Individual embedding object
public struct SAOAIEmbedding: Codable, Sendable {
    /// The object type (always "embedding")
    public let object: String
    /// The embedding vector
    public let embedding: [Double]
    /// The index of this embedding in the input array
    public let index: Int
    
    public init(
        object: String,
        embedding: [Double],
        index: Int
    ) {
        self.object = object
        self.embedding = embedding
        self.index = index
    }
    
    /// Convenience getter for the embedding vector
    public var vector: [Double] {
        return embedding
    }
    
    /// Get the dimensionality of the embedding
    public var dimensions: Int {
        return embedding.count
    }
}

/// Usage statistics for embeddings requests
public struct SAOAIEmbeddingUsage: Codable, Sendable {
    /// Number of tokens in the prompt
    public let promptTokens: Int
    /// Total number of tokens used
    public let totalTokens: Int
    
    public init(
        promptTokens: Int,
        totalTokens: Int
    ) {
        self.promptTokens = promptTokens
        self.totalTokens = totalTokens
    }
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Utility Extensions

extension SAOAIEmbedding {
    /// Calculate cosine similarity with another embedding
    /// Returns a value between -1.0 and 1.0, where 1.0 indicates identical vectors
    public func cosineSimilarity(with other: SAOAIEmbedding) -> Double {
        return SAOAIEmbeddingUtilities.cosineSimilarity(self.embedding, other.embedding)
    }
    
    /// Calculate Euclidean distance with another embedding
    /// Returns the L2 distance between vectors (lower values indicate higher similarity)
    public func euclideanDistance(with other: SAOAIEmbedding) -> Double {
        return SAOAIEmbeddingUtilities.euclideanDistance(self.embedding, other.embedding)
    }
    
    /// Calculate dot product with another embedding
    public func dotProduct(with other: SAOAIEmbedding) -> Double {
        return SAOAIEmbeddingUtilities.dotProduct(self.embedding, other.embedding)
    }
}

extension SAOAIEmbeddingsResponse {
    /// Find the most similar embedding to a query embedding
    /// Returns the index and similarity score of the most similar embedding
    public func mostSimilar(to query: SAOAIEmbedding) -> (index: Int, similarity: Double)? {
        guard !data.isEmpty else { return nil }
        
        var maxSimilarity = -1.0
        var bestIndex = 0
        
        for (index, embedding) in data.enumerated() {
            let similarity = query.cosineSimilarity(with: embedding)
            if similarity > maxSimilarity {
                maxSimilarity = similarity
                bestIndex = index
            }
        }
        
        return (index: bestIndex, similarity: maxSimilarity)
    }
    
    /// Get embeddings sorted by similarity to a query embedding (descending)
    public func sortedBySimilarity(to query: SAOAIEmbedding) -> [(embedding: SAOAIEmbedding, similarity: Double)] {
        return data.map { embedding in
            (embedding: embedding, similarity: query.cosineSimilarity(with: embedding))
        }.sorted { $0.similarity > $1.similarity }
    }
}

/// Utility functions for embedding operations
public struct SAOAIEmbeddingUtilities {
    /// Calculate cosine similarity between two vectors
    /// Returns a value between -1.0 and 1.0, where 1.0 indicates identical vectors
    public static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }
        
        let dotProduct = zip(a, b).reduce(0.0) { sum, pair in sum + pair.0 * pair.1 }
        let magnitudeA = sqrt(a.reduce(0.0) { $0 + $1 * $1 })
        let magnitudeB = sqrt(b.reduce(0.0) { $0 + $1 * $1 })
        
        guard magnitudeA > 0.0 && magnitudeB > 0.0 else { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    /// Calculate Euclidean distance between two vectors
    /// Returns the L2 distance (lower values indicate higher similarity)
    public static func euclideanDistance(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return Double.infinity }
        
        let squaredDifferences = zip(a, b).map { ($0 - $1) * ($0 - $1) }
        return sqrt(squaredDifferences.reduce(0.0, +))
    }
    
    /// Calculate dot product between two vectors
    public static func dotProduct(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0.0 }
        
        return zip(a, b).reduce(0.0) { sum, pair in sum + pair.0 * pair.1 }
    }
    
    /// Normalize a vector to unit length
    public static func normalize(_ vector: [Double]) -> [Double] {
        let magnitude = sqrt(vector.reduce(0.0) { $0 + $1 * $1 })
        guard magnitude > 0.0 else { return vector }
        
        return vector.map { $0 / magnitude }
    }
}