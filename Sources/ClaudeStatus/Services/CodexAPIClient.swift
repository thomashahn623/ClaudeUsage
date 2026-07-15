import Foundation

enum CodexAPIError: LocalizedError {
    case missingCookie
    case unauthorized
    case http(Int)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .missingCookie: return "Kein ChatGPT-Sitzungs-Cookie für Codex hinterlegt."
        case .unauthorized: return "Codex-Sitzung ungültig oder abgelaufen. Bitte den Cookie erneuern."
        case .http(let code): return "Codex-HTTP-Fehler \(code)."
        case .decoding(let error): return "Codex-Antwort konnte nicht gelesen werden: \(error.localizedDescription)"
        case .transport(let error): return "Codex-Netzwerkfehler: \(error.localizedDescription)"
        }
    }
}

struct CodexAPIClient {
    private let session: URLSession
    private let userAgent = "ClaudeStatus/0.6.0 (macOS; SwiftUI)"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUsage() async throws -> CodexUsageSnapshot {
        guard let cookie = KeychainStore.get(.codexSessionCookie), !cookie.isEmpty else {
            throw CodexAPIError.missingCookie
        }

        var request = URLRequest(url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!)
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
        switch http.statusCode {
        case 200..<300:
            do {
                return try JSONDecoder().decode(CodexUsageResponseDTO.self, from: data).toSnapshot()
            } catch {
                throw CodexAPIError.decoding(error)
            }
        case 401, 403: throw CodexAPIError.unauthorized
        default: throw CodexAPIError.http(http.statusCode)
        }
    }
}
