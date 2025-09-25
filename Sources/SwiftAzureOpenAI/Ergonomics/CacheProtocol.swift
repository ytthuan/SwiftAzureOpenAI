//
//  CacheProtocol.swift
//  SwiftAzureOpenAI
//
//  Foundation for in-memory caching protocols.
//

import Foundation

// MARK: - Cache Protocol

/// Protocol for caching arbitrary data with expiration support
public protocol CacheProtocol {
    associatedtype Key: Hashable
    associatedtype Value
    
    /// Store a value with optional expiration
    func set(_ value: Value, forKey key: Key, expiresIn duration: TimeInterval?)
    
    /// Retrieve a value by key
    func get(_ key: Key) -> Value?
    
    /// Remove a value by key
    func remove(_ key: Key)
    
    /// Clear all cached values
    func clear()
    
    /// Get cache statistics
    var statistics: CacheStatistics { get }
}

// MARK: - Cache Statistics

/// Statistics for cache performance monitoring
public struct CacheStatistics {
    /// Total number of cache hits
    public let hits: Int
    
    /// Total number of cache misses
    public let misses: Int
    
    /// Current number of cached items
    public let count: Int
    
    /// Maximum capacity of the cache
    public let capacity: Int
    
    /// Cache hit rate (0.0 to 1.0)
    public var hitRate: Double {
        let total = hits + misses
        guard total > 0 else { return 0.0 }
        return Double(hits) / Double(total)
    }
    
    /// Cache utilization (0.0 to 1.0)
    public var utilization: Double {
        guard capacity > 0 else { return 0.0 }
        return Double(count) / Double(capacity)
    }
    
    public init(hits: Int, misses: Int, count: Int, capacity: Int) {
        self.hits = hits
        self.misses = misses
        self.count = count
        self.capacity = capacity
    }
}

// MARK: - Embedding Cache Protocol

/// Specialized cache protocol for embeddings
public protocol EmbeddingCacheProtocol: CacheProtocol where Key == String, Value == SAOAIEmbedding {
    /// Cache an embedding with automatic key generation from text and model
    func cacheEmbedding(_ embedding: SAOAIEmbedding, for text: String, model: String, expiresIn duration: TimeInterval?)
    
    /// Retrieve a cached embedding
    func getCachedEmbedding(for text: String, model: String) -> SAOAIEmbedding?
    
    /// Generate cache key from text and model
    func cacheKey(for text: String, model: String) -> String
}

// MARK: - Cache Entry with Expiration

/// Internal cache entry that supports expiration
struct CacheEntry<T> {
    let value: T
    let expirationDate: Date?
    let createdAt: Date
    
    init(value: T, expiresIn duration: TimeInterval?) {
        self.value = value
        self.createdAt = Date()
        self.expirationDate = duration.map { Date().addingTimeInterval($0) }
    }
    
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
    
    var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }
}

// MARK: - In-Memory Cache Implementation

/// Thread-safe in-memory cache with LRU eviction and expiration support
public class InMemoryCache<Key: Hashable, Value>: CacheProtocol {
    private let queue = DispatchQueue(label: "com.swiftazureopenai.cache", attributes: .concurrent)
    private var storage: [Key: CacheEntry<Value>] = [:]
    private var accessOrder: [Key] = []
    private let maxCapacity: Int
    private var hitCount: Int = 0
    private var missCount: Int = 0
    
    public init(maxCapacity: Int = 1000) {
        self.maxCapacity = maxCapacity
    }
    
    public func set(_ value: Value, forKey key: Key, expiresIn duration: TimeInterval? = nil) {
        queue.async(flags: .barrier) {
            let entry = CacheEntry(value: value, expiresIn: duration)
            self.storage[key] = entry
            
            // Update access order for LRU
            if let index = self.accessOrder.firstIndex(of: key) {
                self.accessOrder.remove(at: index)
            }
            self.accessOrder.append(key)
            
            // Evict if over capacity
            self.evictIfNeeded()
        }
    }
    
    public func get(_ key: Key) -> Value? {
        return queue.sync {
            guard let entry = storage[key] else {
                missCount += 1
                return nil
            }
            
            // Check expiration
            if entry.isExpired {
                storage.removeValue(forKey: key)
                accessOrder.removeAll { $0 == key }
                missCount += 1
                return nil
            }
            
            // Update access order for LRU
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
            accessOrder.append(key)
            
            hitCount += 1
            return entry.value
        }
    }
    
    public func remove(_ key: Key) {
        queue.async(flags: .barrier) {
            self.storage.removeValue(forKey: key)
            self.accessOrder.removeAll { $0 == key }
        }
    }
    
    public func clear() {
        queue.async(flags: .barrier) {
            self.storage.removeAll()
            self.accessOrder.removeAll()
            self.hitCount = 0
            self.missCount = 0
        }
    }
    
    public var statistics: CacheStatistics {
        return queue.sync {
            return CacheStatistics(
                hits: hitCount,
                misses: missCount,
                count: storage.count,
                capacity: maxCapacity
            )
        }
    }
    
    private func evictIfNeeded() {
        // Remove expired entries first
        let now = Date()
        let expiredKeys = storage.compactMap { key, entry in
            entry.isExpired ? key : nil
        }
        
        for key in expiredKeys {
            storage.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
        }
        
        // Evict least recently used if still over capacity
        while storage.count > maxCapacity && !accessOrder.isEmpty {
            let lruKey = accessOrder.removeFirst()
            storage.removeValue(forKey: lruKey)
        }
    }
}

// MARK: - Embedding Cache Implementation

/// Specialized in-memory cache for embeddings
public final class EmbeddingCache: InMemoryCache<String, SAOAIEmbedding>, EmbeddingCacheProtocol {
    
    public func cacheEmbedding(
        _ embedding: SAOAIEmbedding,
        for text: String,
        model: String,
        expiresIn duration: TimeInterval? = nil
    ) {
        let key = cacheKey(for: text, model: model)
        set(embedding, forKey: key, expiresIn: duration)
    }
    
    public func getCachedEmbedding(for text: String, model: String) -> SAOAIEmbedding? {
        let key = cacheKey(for: text, model: model)
        return get(key)
    }
    
    public func cacheKey(for text: String, model: String) -> String {
        // Create a deterministic cache key
        let combined = "\(model):\(text)"
        return combined.sha256
    }
}

// MARK: - String SHA256 Extension

extension String {
    /// Simple SHA256 hash for cache keys
    var sha256: String {
        let data = self.data(using: .utf8) ?? Data()
        let hash = data.withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Note: CC_SHA256 would need to be imported from CommonCrypto
// For now, using a simple hash alternative
extension String {
    var simpleHash: String {
        return String(self.hashValue)
    }
}

// MARK: - Usage Example

/*
Example usage:

```swift
// Create an embedding cache
let cache = EmbeddingCache(maxCapacity: 10000)

// Cache an embedding
let embedding = SAOAIEmbedding(embedding: [0.1, 0.2, 0.3], index: 0)
cache.cacheEmbedding(
    embedding,
    for: "Hello, world!",
    model: "text-embedding-ada-002",
    expiresIn: 3600  // 1 hour
)

// Retrieve cached embedding
if let cachedEmbedding = cache.getCachedEmbedding(
    for: "Hello, world!",
    model: "text-embedding-ada-002"
) {
    print("Cache hit! Embedding: \(cachedEmbedding.embedding.prefix(3))")
}

// Check cache statistics
let stats = cache.statistics
print("Hit rate: \(Int(stats.hitRate * 100))%")
print("Cache utilization: \(Int(stats.utilization * 100))%")
```
*/