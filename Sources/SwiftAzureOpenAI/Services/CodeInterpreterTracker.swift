import Foundation

/// Container for tracking code interpreter execution state
public struct CodeInterpreterContainer: Sendable {
    public let id: String
    public let itemId: String
    public var accumulatedCode: String
    public var status: CodeInterpreterStatus
    public var outputs: [String]
    
    public init(id: String, itemId: String) {
        self.id = id
        self.itemId = itemId
        self.accumulatedCode = ""
        self.status = .created
        self.outputs = []
    }
    
    mutating func appendCode(_ code: String) {
        accumulatedCode += code
    }
    
    mutating func addOutput(_ output: String) {
        outputs.append(output)
    }
    
    mutating func updateStatus(_ status: CodeInterpreterStatus) {
        self.status = status
    }
}

/// Status of code interpreter execution
public enum CodeInterpreterStatus: String, Sendable {
    case created = "created"
    case inProgress = "in_progress"
    case interpreting = "interpreting"
    case completed = "completed"
    case failed = "failed"
}

/// Service for tracking code interpreter containers and streaming state
public final class CodeInterpreterTracker: Sendable {
    private let containers = ThreadSafeContainer()
    
    public init() {}
    
    private final class ThreadSafeContainer: @unchecked Sendable {
        private let lock = NSLock()
        private var storage: [String: CodeInterpreterContainer] = [:]
        
        func withLock<T>(_ action: (inout [String: CodeInterpreterContainer]) -> T) -> T {
            lock.lock()
            defer { lock.unlock() }
            return action(&storage)
        }
    }
    
    /// Track a new code interpreter container from output_item.added event
    /// - Parameters:
    ///   - itemId: The item ID from the event
    ///   - item: The item details from the event
    /// - Returns: The container ID if this is a code interpreter item
    public func trackContainer(itemId: String, item: AzureOpenAIEventItem) -> String? {
        guard item.type == "code_interpreter_call" else { return nil }
        
        return containers.withLock { containers in
            let containerId = item.id ?? itemId
            var container = CodeInterpreterContainer(id: containerId, itemId: itemId)
            container.updateStatus(.created)
            containers[containerId] = container
            return containerId
        }
    }
    
    /// Add code delta to a container
    /// - Parameters:
    ///   - itemId: The item ID from the delta event
    ///   - code: The code delta to append
    /// - Returns: The updated container if found
    public func appendCodeDelta(itemId: String, code: String) -> CodeInterpreterContainer? {
        return containers.withLock { containers in
            // Find container by item ID
            guard let (containerId, _) = containers.first(where: { $0.value.itemId == itemId }) else {
                return nil
            }
            
            containers[containerId]?.appendCode(code)
            return containers[containerId]
        }
    }
    
    /// Mark code completion for a container
    /// - Parameters:
    ///   - itemId: The item ID from the done event
    ///   - finalCode: Optional final code if provided in the done event
    /// - Returns: The updated container if found
    public func markCodeComplete(itemId: String, finalCode: String? = nil) -> CodeInterpreterContainer? {
        return containers.withLock { containers in
            guard let (containerId, _) = containers.first(where: { $0.value.itemId == itemId }) else {
                return nil
            }
            
            if let finalCode = finalCode {
                containers[containerId]?.accumulatedCode = finalCode
            }
            containers[containerId]?.updateStatus(.interpreting)
            return containers[containerId]
        }
    }
    
    /// Mark container as completed
    /// - Parameter itemId: The item ID from the completed event
    /// - Returns: The final container state if found
    public func markCompleted(itemId: String) -> CodeInterpreterContainer? {
        return containers.withLock { containers in
            guard let (containerId, _) = containers.first(where: { $0.value.itemId == itemId }) else {
                return nil
            }
            
            containers[containerId]?.updateStatus(.completed)
            return containers[containerId]
        }
    }
    
    /// Add output to a container
    /// - Parameters:
    ///   - itemId: The item ID
    ///   - output: The output to add
    /// - Returns: The updated container if found
    public func addOutput(itemId: String, output: String) -> CodeInterpreterContainer? {
        return containers.withLock { containers in
            guard let (containerId, _) = containers.first(where: { $0.value.itemId == itemId }) else {
                return nil
            }
            
            containers[containerId]?.addOutput(output)
            return containers[containerId]
        }
    }
    
    /// Get container by item ID
    /// - Parameter itemId: The item ID to look up
    /// - Returns: The container if found
    public func getContainer(itemId: String) -> CodeInterpreterContainer? {
        return containers.withLock { containers in
            return containers.first(where: { $0.value.itemId == itemId })?.value
        }
    }
    
    /// Get all containers
    /// - Returns: All current containers
    public func getAllContainers() -> [CodeInterpreterContainer] {
        return containers.withLock { containers in
            return Array(containers.values)
        }
    }
    
    /// Clean up completed containers
    public func cleanupCompletedContainers() {
        containers.withLock { containers in
            containers = containers.filter { $0.value.status != .completed }
        }
    }
}