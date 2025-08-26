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

    public init(encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
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