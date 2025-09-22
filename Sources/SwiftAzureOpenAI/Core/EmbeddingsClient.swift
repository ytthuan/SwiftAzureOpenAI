import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A client for embeddings API operations
public final class EmbeddingsClient: @unchecked Sendable {
    private let httpClient: HTTPClient
    private let responseService: ResponseServiceProtocol
    private let requestBuilder: AzureRequestBuilder
    
    internal init(httpClient: HTTPClient, responseService: ResponseServiceProtocol, configuration: SAOAIConfiguration) {
        self.httpClient = httpClient
        self.responseService = responseService
        self.requestBuilder = AzureRequestBuilder.create(from: configuration)
    }
    
    /// Create embeddings for the given input
    /// - Parameter request: The embeddings request containing input text(s) and model configuration
    /// - Returns: The embeddings response with vector representations
    public func create(_ request: SAOAIEmbeddingsRequest) async throws -> SAOAIEmbeddingsResponse {
        let jsonData = try SharedJSONEncoder.shared.encode(request)
        
        let apiRequest = requestBuilder.buildRequest(
            method: "POST",
            endpoint: AzureRequestBuilder.Endpoint.embeddings,
            body: jsonData
        )
        
        let (data, httpResponse) = try await httpClient.send(apiRequest)
        let result: APIResponse<SAOAIEmbeddingsResponse> = try await responseService.processResponse(data, response: httpResponse, type: SAOAIEmbeddingsResponse.self)
        return result.data
    }
    
    /// Convenience method to create embeddings for a single text input
    /// - Parameters:
    ///   - text: The input text to get embeddings for
    ///   - model: The model to use (Azure: deployment name, OpenAI: model name)
    ///   - dimensions: Optional dimensions for the embedding vector
    /// - Returns: The embeddings response
    public func create(
        text: String,
        model: String,
        dimensions: Int? = nil
    ) async throws -> SAOAIEmbeddingsResponse {
        let request = SAOAIEmbeddingsRequest(
            input: .text(text),
            model: model,
            dimensions: dimensions
        )
        return try await create(request)
    }
    
    /// Convenience method to create embeddings for multiple text inputs
    /// - Parameters:
    ///   - texts: Array of input texts to get embeddings for
    ///   - model: The model to use (Azure: deployment name, OpenAI: model name)
    ///   - dimensions: Optional dimensions for the embedding vector
    /// - Returns: The embeddings response
    public func create(
        texts: [String],
        model: String,
        dimensions: Int? = nil
    ) async throws -> SAOAIEmbeddingsResponse {
        let request = SAOAIEmbeddingsRequest(
            input: .texts(texts),
            model: model,
            dimensions: dimensions
        )
        return try await create(request)
    }
}

// MARK: - Utility Extensions for Common Use Cases

extension EmbeddingsClient {
    /// Create embeddings and find the most similar texts to a query
    /// - Parameters:
    ///   - query: The query text to find similarities for
    ///   - candidates: Array of candidate texts to compare against
    ///   - model: The model to use for embeddings
    ///   - topK: Number of top similar results to return (default: 5)
    /// - Returns: Array of tuples containing the candidate text, its index, and similarity score
    public func findSimilar(
        query: String,
        candidates: [String],
        model: String,
        topK: Int = 5
    ) async throws -> [(text: String, index: Int, similarity: Double)] {
        // Create embeddings for query + candidates
        let allTexts = [query] + candidates
        let response = try await create(texts: allTexts, model: model)
        
        guard let queryEmbedding = response.data.first else {
            throw SAOAIError.invalidRequest("Failed to generate query embedding")
        }
        
        let candidateEmbeddings = Array(response.data.dropFirst())
        
        // Calculate similarities and sort
        let similarities = candidateEmbeddings.enumerated().map { (index, embedding) in
            let similarity = queryEmbedding.cosineSimilarity(with: embedding)
            return (text: candidates[index], index: index, similarity: similarity)
        }.sorted { $0.similarity > $1.similarity }
        
        return Array(similarities.prefix(topK))
    }
    
    /// Semantic search: find the most relevant documents for a query
    /// - Parameters:
    ///   - query: The search query
    ///   - documents: Array of documents to search through
    ///   - model: The model to use for embeddings
    ///   - threshold: Minimum similarity threshold (default: 0.7)
    /// - Returns: Array of documents with similarity scores above the threshold, sorted by relevance
    public func semanticSearch(
        query: String,
        documents: [String],
        model: String,
        threshold: Double = 0.7
    ) async throws -> [(document: String, similarity: Double)] {
        let similarities = try await findSimilar(
            query: query,
            candidates: documents,
            model: model,
            topK: documents.count
        )
        
        return similarities
            .filter { $0.similarity >= threshold }
            .map { (document: $0.text, similarity: $0.similarity) }
    }
}