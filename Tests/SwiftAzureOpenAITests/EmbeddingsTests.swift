import XCTest
@testable import SwiftAzureOpenAI

final class EmbeddingsTests: XCTestCase {
    
    func testEmbeddingsRequestSingleText() {
        let request = SAOAIEmbeddingsRequest(
            input: .text("Hello, world!"),
            model: "text-embedding-ada-002"
        )
        
        XCTAssertEqual(request.model, "text-embedding-ada-002")
        XCTAssertEqual(request.input.count, 1)
        XCTAssertNil(request.dimensions)
        XCTAssertNil(request.user)
    }
    
    func testEmbeddingsRequestMultipleTexts() {
        let texts = ["First text", "Second text", "Third text"]
        let request = SAOAIEmbeddingsRequest(
            input: .texts(texts),
            model: "text-embedding-ada-002",
            dimensions: 1536
        )
        
        XCTAssertEqual(request.model, "text-embedding-ada-002")
        XCTAssertEqual(request.input.count, 3)
        XCTAssertEqual(request.dimensions, 1536)
    }
    
    func testEmbeddingsInputCoding() throws {
        let singleInput = SAOAIEmbeddingsInput.text("Hello")
        let multipleInput = SAOAIEmbeddingsInput.texts(["Hello", "World"])
        
        // Test encoding/decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let singleData = try encoder.encode(singleInput)
        let decodedSingle = try decoder.decode(SAOAIEmbeddingsInput.self, from: singleData)
        
        let multipleData = try encoder.encode(multipleInput)
        let decodedMultiple = try decoder.decode(SAOAIEmbeddingsInput.self, from: multipleData)
        
        XCTAssertEqual(decodedSingle.count, 1)
        XCTAssertEqual(decodedMultiple.count, 2)
    }
    
    func testEmbeddingResponse() {
        let embedding = SAOAIEmbedding(
            object: "embedding",
            embedding: [0.1, 0.2, 0.3, 0.4],
            index: 0
        )
        
        XCTAssertEqual(embedding.dimensions, 4)
        XCTAssertEqual(embedding.vector, [0.1, 0.2, 0.3, 0.4])
        XCTAssertEqual(embedding.index, 0)
    }
    
    func testCosineSimilarity() {
        let embedding1 = SAOAIEmbedding(
            object: "embedding",
            embedding: [1.0, 0.0, 0.0],
            index: 0
        )
        
        let embedding2 = SAOAIEmbedding(
            object: "embedding",
            embedding: [1.0, 0.0, 0.0],
            index: 1
        )
        
        let embedding3 = SAOAIEmbedding(
            object: "embedding",
            embedding: [0.0, 1.0, 0.0],
            index: 2
        )
        
        // Identical vectors should have similarity of 1.0
        let similarity1 = embedding1.cosineSimilarity(with: embedding2)
        XCTAssertEqual(similarity1, 1.0, accuracy: 0.001)
        
        // Orthogonal vectors should have similarity of 0.0
        let similarity2 = embedding1.cosineSimilarity(with: embedding3)
        XCTAssertEqual(similarity2, 0.0, accuracy: 0.001)
    }
    
    func testEuclideanDistance() {
        let embedding1 = SAOAIEmbedding(
            object: "embedding",
            embedding: [0.0, 0.0, 0.0],
            index: 0
        )
        
        let embedding2 = SAOAIEmbedding(
            object: "embedding",
            embedding: [3.0, 4.0, 0.0],
            index: 1
        )
        
        // Distance should be 5.0 (3-4-5 triangle)
        let distance = embedding1.euclideanDistance(with: embedding2)
        XCTAssertEqual(distance, 5.0, accuracy: 0.001)
    }
    
    func testDotProduct() {
        let embedding1 = SAOAIEmbedding(
            object: "embedding",
            embedding: [1.0, 2.0, 3.0],
            index: 0
        )
        
        let embedding2 = SAOAIEmbedding(
            object: "embedding",
            embedding: [4.0, 5.0, 6.0],
            index: 1
        )
        
        // Dot product: 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
        let dotProduct = embedding1.dotProduct(with: embedding2)
        XCTAssertEqual(dotProduct, 32.0, accuracy: 0.001)
    }
    
    func testEmbeddingUtilities() {
        let vectorA = [1.0, 2.0, 3.0]
        let vectorB = [4.0, 5.0, 6.0]
        
        // Test cosine similarity
        let similarity = SAOAIEmbeddingUtilities.cosineSimilarity(vectorA, vectorB)
        XCTAssertGreaterThan(similarity, 0.0)
        XCTAssertLessThanOrEqual(similarity, 1.0)
        
        // Test Euclidean distance
        let distance = SAOAIEmbeddingUtilities.euclideanDistance(vectorA, vectorB)
        XCTAssertGreaterThan(distance, 0.0)
        
        // Test dot product
        let dotProduct = SAOAIEmbeddingUtilities.dotProduct(vectorA, vectorB)
        XCTAssertEqual(dotProduct, 32.0, accuracy: 0.001)
        
        // Test normalization
        let normalized = SAOAIEmbeddingUtilities.normalize(vectorA)
        let magnitude = sqrt(normalized.reduce(0.0) { $0 + $1 * $1 })
        XCTAssertEqual(magnitude, 1.0, accuracy: 0.001)
    }
    
    func testEmbeddingsResponseSorting() {
        let queryEmbedding = SAOAIEmbedding(
            object: "embedding",
            embedding: [1.0, 0.0, 0.0],
            index: 0
        )
        
        let embeddings = [
            SAOAIEmbedding(object: "embedding", embedding: [0.9, 0.1, 0.0], index: 0), // High similarity
            SAOAIEmbedding(object: "embedding", embedding: [0.0, 1.0, 0.0], index: 1), // Low similarity
            SAOAIEmbedding(object: "embedding", embedding: [0.8, 0.2, 0.0], index: 2), // Medium similarity
        ]
        
        let response = SAOAIEmbeddingsResponse(
            object: "list",
            data: embeddings,
            model: "text-embedding-ada-002",
            usage: SAOAIEmbeddingUsage(promptTokens: 10, totalTokens: 10)
        )
        
        let sorted = response.sortedBySimilarity(to: queryEmbedding)
        
        // Should be sorted by similarity (descending)
        XCTAssertGreaterThan(sorted[0].similarity, sorted[1].similarity)
        XCTAssertGreaterThan(sorted[1].similarity, sorted[2].similarity)
        
        // First should be the most similar (index 0)
        XCTAssertEqual(sorted[0].embedding.index, 0)
    }
    
    func testEmbeddingsResponseMostSimilar() {
        let queryEmbedding = SAOAIEmbedding(
            object: "embedding",
            embedding: [1.0, 0.0, 0.0],
            index: 0
        )
        
        let embeddings = [
            SAOAIEmbedding(object: "embedding", embedding: [0.5, 0.5, 0.0], index: 0),
            SAOAIEmbedding(object: "embedding", embedding: [0.9, 0.1, 0.0], index: 1), // Most similar
            SAOAIEmbedding(object: "embedding", embedding: [0.0, 1.0, 0.0], index: 2),
        ]
        
        let response = SAOAIEmbeddingsResponse(
            object: "list",
            data: embeddings,
            model: "text-embedding-ada-002",
            usage: SAOAIEmbeddingUsage(promptTokens: 10, totalTokens: 10)
        )
        
        let mostSimilar = response.mostSimilar(to: queryEmbedding)
        XCTAssertNotNil(mostSimilar)
        XCTAssertEqual(mostSimilar?.index, 1) // Index 1 should be most similar
        XCTAssertGreaterThan(mostSimilar?.similarity ?? 0, 0.8)
    }
    
    func testEmbeddingsClientInitialization() {
        let config = TestableConfiguration()
        let httpClient = HTTPClient(configuration: config)
        let responseService = OptimizedResponseService()
        
        let embeddingsClient = EmbeddingsClient(
            httpClient: httpClient,
            responseService: responseService,
            configuration: config
        )
        
        XCTAssertNotNil(embeddingsClient)
    }
    
    func testEncodingFormats() {
        XCTAssertEqual(SAOAIEmbeddingEncodingFormat.float.rawValue, "float")
        XCTAssertEqual(SAOAIEmbeddingEncodingFormat.base64.rawValue, "base64")
        
        let allCases = SAOAIEmbeddingEncodingFormat.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.float))
        XCTAssertTrue(allCases.contains(.base64))
    }
}

// MARK: - Test Configuration

private struct TestableConfiguration: SAOAIConfiguration {
    var baseURL: URL { URL(string: "https://192.0.2.1/openai/v1/responses")! }
    var headers: [String: String] { ["Authorization": "Bearer test"] }
    var sseLoggerConfiguration: SSELoggerConfiguration { .disabled }
    var loggerConfiguration: LoggerConfiguration { .disabled }
}