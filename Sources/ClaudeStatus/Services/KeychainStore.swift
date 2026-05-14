import Foundation
import Security

enum KeychainKey: String {
    case sessionKey = "claude_session_key"
    case orgId = "claude_org_id"
}

enum KeychainStore {
    private static let service = "de.thomashahn.ClaudeStatus"
    private static var cache: [KeychainKey: String?] = [:]
    private static let cacheLock = NSLock()

    static func set(_ value: String, for key: KeychainKey) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        SecItemAdd(attrs as CFDictionary, nil)
        cacheLock.lock()
        cache[key] = value
        cacheLock.unlock()
    }

    static func get(_ key: KeychainKey) -> String? {
        cacheLock.lock()
        if let cached = cache[key] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        let value: String?
        if status == errSecSuccess,
           let data = item as? Data,
           let s = String(data: data, encoding: .utf8) {
            value = s
        } else {
            value = nil
        }
        cacheLock.lock()
        cache[key] = value
        cacheLock.unlock()
        return value
    }

    static func delete(_ key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
        cacheLock.lock()
        cache[key] = .some(nil)
        cacheLock.unlock()
    }
}
