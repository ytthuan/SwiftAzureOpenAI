import Foundation

/// Protocol for in-memory caching of API responses
public protocol InMemoryCacheProtocol {
    /// Store a response in the cache
    /// - Parameters:
    ///   - key: Cache key
    ///   - data: Data to cache
    ///   - expiration: Optional expiration time
    func store<T: Codable>(_ data: T, forKey key: String, expiration: TimeInterval?)
    
    /// Retrieve a response from the cache
    /// - Parameter key: Cache key
    /// - Returns: Cached data if available and not expired
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    
    /// Remove an item from the cache
    /// - Parameter key: Cache key
    func remove(forKey key: String)
    
    /// Clear all cached items
    func clearAll()
    
    /// Get cache statistics
    var statistics: CacheStatistics { get }
}

/// Cache statistics for monitoring
public struct CacheStatistics: Codable, Equatable {
    public let hits: Int
    public let misses: Int
    public let itemCount: Int
    public let memoryUsage: Int // Approximate memory usage in bytes
    
    public var hitRate: Double {
        let total = hits + misses
        return total > 0 ? Double(hits) / Double(total) : 0.0
    }
    
    public init(hits: Int = 0, misses: Int = 0, itemCount: Int = 0, memoryUsage: Int = 0) {
        self.hits = hits
        self.misses = misses
        self.itemCount = itemCount
        self.memoryUsage = memoryUsage
    }
}

/// In-memory cache implementation with TTL and LRU eviction
public final class InMemoryCacheService: InMemoryCacheProtocol, @unchecked Sendable {
    private let maxSize: Int
    private let defaultExpiration: TimeInterval
    private var cache: [String: CacheItem] = [:]
    private var accessOrder: [String] = [] // For LRU eviction
    private let queue = DispatchQueue(label: "com.swiftazureopenai.cache", attributes: .concurrent)
    
    // Statistics
    private var _hits: Int = 0
    private var _misses: Int = 0
    
    /// Initialize the cache service
    /// - Parameters:
    ///   - maxSize: Maximum number of items to cache (default: 1000)
    ///   - defaultExpiration: Default expiration time in seconds (default: 1 hour)
    public init(maxSize: Int = 1000, defaultExpiration: TimeInterval = 3600) {
        self.maxSize = maxSize
        self.defaultExpiration = defaultExpiration
    }
    
    public func store<T: Codable>(_ data: T, forKey key: String, expiration: TimeInterval? = nil) {
        let expirationTime = expiration ?? defaultExpiration
        let expiresAt = Date().addingTimeInterval(expirationTime)
        
        do {
            let encodedData = try JSONEncoder().encode(data)
            let item = CacheItem(
                data: encodedData,
                expiresAt: expiresAt,
                size: encodedData.count
            )
            
            queue.async(flags: .barrier) {
                self.cache[key] = item
                self.updateAccessOrder(key: key)
                self.evictIfNecessary()
            }
        } catch {
            // Silently fail encoding - cache is optional
        }
    }
    
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        return queue.sync {
            guard let item = cache[key] else {
                _misses += 1
                return nil
            }
            
            // Check expiration
            if item.expiresAt < Date() {
                cache.removeValue(forKey: key)
                accessOrder.removeAll { $0 == key }
                _misses += 1
                return nil
            }
            
            // Update access order for LRU
            updateAccessOrder(key: key)
            
            do {
                let decoded = try JSONDecoder().decode(type, from: item.data)
                _hits += 1
                return decoded
            } catch {
                // Remove corrupted data
                cache.removeValue(forKey: key)
                accessOrder.removeAll { $0 == key }
                _misses += 1
                return nil
            }
        }
    }
    
    public func remove(forKey key: String) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
            self.accessOrder.removeAll { $0 == key }
        }
    }
    
    public func clearAll() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
            self.accessOrder.removeAll()
            self._hits = 0
            self._misses = 0
        }
    }
    
    public var statistics: CacheStatistics {
        return queue.sync {
            let memoryUsage = cache.values.reduce(0) { $0 + $1.size }
            return CacheStatistics(
                hits: _hits,
                misses: _misses,
                itemCount: cache.count,
                memoryUsage: memoryUsage
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func updateAccessOrder(key: String) {
        // Remove if already present
        accessOrder.removeAll { $0 == key }
        // Add to front (most recently used)
        accessOrder.insert(key, at: 0)
    }
    
    private func evictIfNecessary() {
        while cache.count > maxSize && !accessOrder.isEmpty {
            let oldestKey = accessOrder.removeLast()
            cache.removeValue(forKey: oldestKey)
        }
    }
}

/// Cache item with expiration and size tracking
private struct CacheItem {
    let data: Data
    let expiresAt: Date
    let size: Int
}

/// Specialized cache for embedding responses
public class EmbeddingCache {
    private let cache: InMemoryCacheProtocol
    private let keyPrefix = "embedding:"
    
    /// Initialize embedding cache
    /// - Parameter cache: Underlying cache implementation
    public init(cache: InMemoryCacheProtocol = InMemoryCacheService(maxSize: 500, defaultExpiration: 7200)) {
        self.cache = cache
    }
    
    /// Cache embeddings for a text input
    /// - Parameters:
    ///   - text: Input text
    ///   - model: Model used
    ///   - embeddings: Embedding response to cache
    ///   - expiration: Cache expiration (default: 2 hours)
    public func store(
        text: String, 
        model: String, 
        embeddings: SAOAIEmbeddingsResponse,
        expiration: TimeInterval? = nil
    ) {
        let key = generateKey(text: text, model: model)
        cache.store(embeddings, forKey: key, expiration: expiration)
    }
    
    /// Retrieve cached embeddings
    /// - Parameters:
    ///   - text: Input text
    ///   - model: Model used
    /// - Returns: Cached embedding response if available
    public func retrieve(text: String, model: String) -> SAOAIEmbeddingsResponse? {
        let key = generateKey(text: text, model: model)
        return cache.retrieve(SAOAIEmbeddingsResponse.self, forKey: key)
    }
    
    /// Cache multiple embeddings
    /// - Parameters:
    ///   - texts: Input texts
    ///   - model: Model used
    ///   - embeddings: Embeddings response to cache
    public func storeBatch(
        texts: [String], 
        model: String, 
        embeddings: SAOAIEmbeddingsResponse
    ) {
        // Cache individual embeddings for future single-text lookups
        for (index, text) in texts.enumerated() {
            if let embedding = embeddings.data[safe: index] {
                let singleResponse = SAOAIEmbeddingsResponse(
                    object: embeddings.object,
                    data: [embedding],
                    model: embeddings.model,
                    usage: SAOAIEmbeddingUsage(promptTokens: 0, totalTokens: 0) // Minimal usage for individual items
                )
                store(text: text, model: model, embeddings: singleResponse)
            }
        }
        
        // Also cache the batch result
        let batchKey = generateBatchKey(texts: texts, model: model)
        cache.store(embeddings, forKey: batchKey, expiration: nil)
    }
    
    /// Clear embedding cache
    public func clearAll() {
        cache.clearAll()
    }
    
    /// Get cache statistics
    public var statistics: CacheStatistics {
        return cache.statistics
    }
    
    // MARK: - Private Methods
    
    private func generateKey(text: String, model: String) -> String {
        let combined = "\(model):\(text)"
        let hash = combined.djb2Hash()
        return "\(keyPrefix)\(hash)"
    }
    
    private func generateBatchKey(texts: [String], model: String) -> String {
        let combined = "\(model):\(texts.joined(separator: "|"))"
        let hash = combined.djb2Hash()
        return "\(keyPrefix)batch:\(hash)"
    }
}

/// Safe array subscript extension
private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

/// Simple hash function for cache keys
private extension String {
    func djb2Hash() -> UInt {
        return self.unicodeScalars.reduce(5381) {
            ($0 << 5) &+ $0 &+ UInt($1.value)
        }
    }
}