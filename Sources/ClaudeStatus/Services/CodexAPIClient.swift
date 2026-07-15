import Foundation

enum CodexAPIError: LocalizedError {
    case missingCookie
    case sessionUnauthorized
    case usageUnauthorized
    case http(Int)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .missingCookie: return "Kein ChatGPT-Sitzungs-Cookie für Codex hinterlegt."
        case .sessionUnauthorized: return "ChatGPT-Sitzung konnte nicht aus dem Cookie gelesen werden. Bitte beide Cookie-Werte in den Einstellungen erneut speichern."
        case .usageUnauthorized: return "ChatGPT hat den Codex-Usage-Abruf abgelehnt. Bitte die Cookie-Werte in den Einstellungen erneut speichern."
        case .http(let code): return "Codex-HTTP-Fehler \(code)."
        case .decoding(let error): return "Codex-Antwort konnte nicht gelesen werden: \(error.localizedDescription)"
        case .transport(let error): return "Codex-Netzwerkfehler: \(error.localizedDescription)"
        }
    }
}

struct CodexAPIClient {
    private let session: URLSession
    private let userAgent = "AIUsage/0.7.0 (macOS; SwiftUI)"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUsage() async throws -> CodexUsageSnapshot {
        guard let cookie = Self.sessionCookieHeader else {
            throw CodexAPIError.missingCookie
        }

        let accessToken = try await fetchAccessToken(cookie: cookie)
        var request = URLRequest(url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(cookie, forHTTPHeaderField: "Cookie")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("https://chatgpt.com/", forHTTPHeaderField: "Referer")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw CodexAPIError.transport(error)
        }
        guard let http = response as? HTTPURLResponse else { throw CodexAPIError.http(-1) }
        switch http.statusCode {
        case 200..<300:
            do {
                return try JSONDecoder().decode(CodexUsageResponseDTO.self, from: data).toSnapshot()
            } catch {
                throw CodexAPIError.decoding(error)
            }
        case 401, 403: throw CodexAPIError.usageUnauthorized
        default: throw CodexAPIError.http(http.statusCode)
        }
    }

    /// The session cookie authorizes obtaining the short-lived bearer token that
    /// the Codex usage endpoint requires. The token is deliberately not stored.
    private func fetchAccessToken(cookie: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://chatgpt.com/api/auth/session")!)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(cookie, forHTTPHeaderField: "Cookie")
        request.setValue("https://chatgpt.com/", forHTTPHeaderField: "Referer")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw CodexAPIError.transport(error)
        }
        guard let http = response as? HTTPURLResponse else { throw CodexAPIError.http(-1) }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 { throw CodexAPIError.sessionUnauthorized }
            throw CodexAPIError.http(http.statusCode)
        }
        guard let session = try? JSONDecoder().decode(ChatGPTSessionDTO.self, from: data),
              !session.accessToken.isEmpty else {
            throw CodexAPIError.sessionUnauthorized
        }
        return session.accessToken
    }

    static var hasSessionCookie: Bool { sessionCookieHeader != nil }

    private static var sessionCookieHeader: String? {
        let part0 = normalizedCookieValue(KeychainStore.get(.codexSessionCookiePart0), named: "__Secure-next-auth.session-token.0")
        let part1 = normalizedCookieValue(KeychainStore.get(.codexSessionCookiePart1), named: "__Secure-next-auth.session-token.1")
        let identity = normalizedCookieValue(KeychainStore.get(.codexIdentityCookie), named: "__Secure-oai-is")
        if !part0.isEmpty, !part1.isEmpty {
            var cookies = [
                "__Secure-next-auth.session-token.0=\(part0)",
                "__Secure-next-auth.session-token.1=\(part1)"
            ]
            if !identity.isEmpty { cookies.append("__Secure-oai-is=\(identity)") }
            return cookies.joined(separator: "; ")
        }

        // Supports a value saved by the first release of this integration.
        let legacy = KeychainStore.get(.codexSessionCookie)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return legacy.isEmpty ? nil : legacy
    }

    /// Accepts either a raw value or a complete `name=value` fragment pasted
    /// from a browser inspector, without ever persisting a transformed value.
    private static func normalizedCookieValue(_ rawValue: String?, named name: String) -> String {
        let raw = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else { return "" }
        let value: String
        if let range = raw.range(of: name) {
            // Safari's inspector may copy either `name=value` or the complete
            // table row (`name <tab> value <tab> domain …`). Accept both forms.
            var remainder = raw[range.upperBound...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if remainder.first == "=" { remainder.removeFirst() }
            value = remainder
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .split(whereSeparator: { $0 == ";" || $0.isWhitespace })
                .first
                .map(String.init) ?? ""
        } else {
            value = raw
        }
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "\\\"' "))
    }
}

private struct ChatGPTSessionDTO: Decodable {
    let accessToken: String
}
