import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Dictionary where Key == String, Value == Any {
    func stringValue(forHeader key: String) -> String? {
        if let v = self[key] as? String { return v }
        if let v = self[key] as? NSString { return v as String }
        return nil
    }
}

extension HTTPURLResponse {
    var normalizedHeaders: [String: String] {
        (allHeaderFields as? [String: Any] ?? [:]).reduce(into: [String: String]()) { result, pair in
            result[pair.key.lowercased()] = String(describing: pair.value)
        }
    }
}

