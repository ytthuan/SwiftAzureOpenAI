import Foundation

public protocol ResponseCache: Sendable {
    func store<T: Codable>(response: APIResponse<T>, for key: Data) async
    func retrieve<T: Codable>(for key: Data, as type: T.Type) async -> APIResponse<T>?
}

public final class InMemoryResponseCache: ResponseCache {
    private actor Storage {
        private var box: [Data: Data] = [:]

        func set(_ data: Data, for key: Data) { box[key] = data }
        func get(for key: Data) -> Data? { box[key] }
    }

    private let storage = Storage()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(encoder: JSONEncoder? = nil, decoder: JSONDecoder? = nil) {
        // Use shared encoder by default for better performance
        if let encoder = encoder {
            self.encoder = encoder
        } else {
            // Create a lightweight encoder if none provided
            let sharedEncoder = JSONEncoder()
            sharedEncoder.outputFormatting = []
            sharedEncoder.dateEncodingStrategy = .iso8601
            self.encoder = sharedEncoder
        }
        
        // Use shared decoder by default for better performance
        if let decoder = decoder {
            self.decoder = decoder
        } else {
            // Create a lightweight decoder if none provided
            let sharedDecoder = JSONDecoder()
            sharedDecoder.dateDecodingStrategy = .iso8601
            self.decoder = sharedDecoder
        }
    }

    public func store<T: Codable>(response: APIResponse<T>, for key: Data) async {
        do {
            let data = try encoder.encode(response)
            await storage.set(data, for: key)
        } catch {
            // Ignore caching failures silently to avoid impacting the main flow
        }
    }

    public func retrieve<T: Codable>(for key: Data, as type: T.Type) async -> APIResponse<T>? {
        guard let data = await storage.get(for: key) else { return nil }
        do {
            return try decoder.decode(APIResponse<T>.self, from: data)
        } catch {
            return nil
        }
    }
}