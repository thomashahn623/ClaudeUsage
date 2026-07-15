import Foundation
import Security

enum KeychainKey: String {
    case credentials = "credentials"
    case sessionKey = "claude_session_key"
    case orgId = "claude_org_id"
    /// Legacy combined Cookie header, retained for a seamless upgrade.
    case codexSessionCookie = "codex_session_cookie"
    case codexSessionCookiePart0 = "codex_session_cookie_part_0"
    case codexSessionCookiePart1 = "codex_session_cookie_part_1"
    case codexIdentityCookie = "codex_identity_cookie"
}

enum KeychainStore {
    private static let service = "de.thomashahn.ClaudeStatus"
    private struct Credentials: Codable {
        var values: [String: String]
    }

    private static var credentials: Credentials?
    private static var didLoadCredentials = false
    private static let cacheLock = NSLock()

    static func set(_ value: String, for key: KeychainKey) {
        cacheLock.lock()
        var current = loadCredentialsLocked()
        current.values[key.rawValue] = value
        saveCredentialsLocked(current)
        cacheLock.unlock()
    }

    static func get(_ key: KeychainKey) -> String? {
        cacheLock.lock()
        let value = loadCredentialsLocked().values[key.rawValue]
        cacheLock.unlock()
        return value
    }

    static func delete(_ key: KeychainKey) {
        cacheLock.lock()
        var current = loadCredentialsLocked()
        current.values.removeValue(forKey: key.rawValue)
        saveCredentialsLocked(current)
        cacheLock.unlock()
    }

    private static func loadCredentialsLocked() -> Credentials {
        if didLoadCredentials { return credentials ?? Credentials(values: [:]) }
        didLoadCredentials = true

        if let data = readData(for: .credentials),
           let decoded = try? JSONDecoder().decode(Credentials.self, from: data) {
            credentials = decoded
            return decoded
        }

        // One-time migration: old app versions stored each secret in a separate
        // keychain item, which could prompt once per value at launch.
        let legacyKeys: [KeychainKey] = [.sessionKey, .orgId, .codexSessionCookie,
                                         .codexSessionCookiePart0, .codexSessionCookiePart1,
                                         .codexIdentityCookie]
        var values: [String: String] = [:]
        for key in legacyKeys {
            if let data = readData(for: key), let value = String(data: data, encoding: .utf8) {
                values[key.rawValue] = value
            }
        }
        let migrated = Credentials(values: values)
        credentials = migrated
        if !values.isEmpty {
            saveCredentialsLocked(migrated)
            legacyKeys.forEach(deleteRaw)
        }
        return migrated
    }

    private static func saveCredentialsLocked(_ value: Credentials) {
        credentials = value
        guard let data = try? JSONEncoder().encode(value) else { return }
        writeData(data, for: .credentials)
    }

    private static func readData(for key: KeychainKey) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    private static func writeData(_ data: Data, for key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private static func deleteRaw(_ key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }
}
