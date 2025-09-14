import Foundation

/// Bounded buffer implementation for AsyncThrowingStream to prevent memory spikes
/// Provides backpressure by limiting the buffer size and managing memory efficiently
internal final class BoundedStreamBuffer<Element>: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer: [Element] = []
    private let maxBufferSize: Int
    private var isFinished = false
    
    internal init(maxBufferSize: Int = 32) {
        self.maxBufferSize = maxBufferSize
        buffer.reserveCapacity(maxBufferSize)
    }
    
    internal func append(_ element: Element) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isFinished else { return false }
        
        // Drop oldest element if buffer is full (backpressure)
        if buffer.count >= maxBufferSize && !buffer.isEmpty {
            buffer.removeFirst()
        }
        
        buffer.append(element)
        return true
    }
    
    internal func removeFirst() -> Element? {
        lock.lock()
        defer { lock.unlock() }
        
        guard !buffer.isEmpty else { return nil }
        return buffer.removeFirst()
    }
    
    internal func finish() {
        lock.lock()
        defer { lock.unlock() }
        
        isFinished = true
    }
    
    internal var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return buffer.isEmpty
    }
    
    internal var isFull: Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return buffer.count >= maxBufferSize
    }
    
    internal var count: Int {
        lock.lock()
        defer { lock.unlock() }
        
        return buffer.count
    }
}