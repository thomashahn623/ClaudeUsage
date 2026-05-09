import Foundation

enum ClaudeAPIError: LocalizedError {
    case missingCookie
    case unauthorized
    case noOrganizations
    case http(Int)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .missingCookie:    return "Kein sessionKey hinterlegt. Bitte in den Einstellungen eintragen."
        case .unauthorized:     return "Cookie ungültig oder abgelaufen. Bitte sessionKey erneuern."
        case .noOrganizations:  return "Keine Organisation gefunden."
        case .http(let code):   return "HTTP-Fehler \(code)."
        case .decoding(let e):  return "Antwort konnte nicht gelesen werden: \(e.localizedDescription)"
        case .transport(let e): return "Netzwerkfehler: \(e.localizedDescription)"
        }
    }
}

struct ClaudeAPIClient {
    private let session: URLSession
    private let userAgent = "ClaudeStatus/0.3.0 (macOS; SwiftUI)"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchOrganizations() async throws -> [OrganizationDTO] {
        let url = URL(string: "https://claude.ai/api/organizations")!
        let data = try await get(url)
        do {
            return try JSONDecoder().decode([OrganizationDTO].self, from: data)
        } catch {
            throw ClaudeAPIError.decoding(error)
        }
    }

    func fetchUsage(orgId: String) async throws -> UsageSnapshot {
        let url = URL(string: "https://claude.ai/api/organizations/\(orgId)/usage")!
        let data = try await get(url)
        do {
            let dto = try JSONDecoder().decode(UsageResponseDTO.self, from: data)
            return dto.toSnapshot()
        } catch {
            throw ClaudeAPIError.decoding(error)
        }
    }

    private func get(_ url: URL) async throws -> Data {
        guard let cookie = KeychainStore.get(.sessionKey), !cookie.isEmpty else {
            throw ClaudeAPIError.missingCookie
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("sessionKey=\(cookie)", forHTTPHeaderField: "Cookie")
        req.setValue("https://claude.ai/", forHTTPHeaderField: "Referer")

        let (data, resp): (Data, URLResponse)
        do {
            (data, resp) = try await session.data(for: req)
        } catch {
            throw ClaudeAPIError.transport(error)
        }
        guard let http = resp as? HTTPURLResponse else { throw ClaudeAPIError.http(-1) }
        switch http.statusCode {
        case 200..<300: return data
        case 401, 403: throw ClaudeAPIError.unauthorized
        default:       throw ClaudeAPIError.http(http.statusCode)
        }
    }
}
