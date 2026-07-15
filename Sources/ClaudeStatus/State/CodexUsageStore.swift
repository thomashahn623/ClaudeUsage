import Foundation
import Combine

@MainActor
final class CodexUsageStore: ObservableObject {
    @Published var snapshot: CodexUsageSnapshot?
    @Published var lastError: String?
    @Published var isLoading = false
    @Published var hasCookie = (KeychainStore.get(.codexSessionCookie)?.isEmpty == false)

    private let client = CodexAPIClient()
    private var timer: Timer?
    private let interval: TimeInterval = 60

    init() {
        startTimer()
        Task { await refresh() }
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    func setSessionCookie(_ value: String) async {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainStore.delete(.codexSessionCookie)
            hasCookie = false
            snapshot = nil
            lastError = "Kein ChatGPT-Sitzungs-Cookie für Codex hinterlegt."
            return
        }
        KeychainStore.set(trimmed, for: .codexSessionCookie)
        hasCookie = true
        await refresh()
    }

    func refresh() async {
        guard hasCookie else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            snapshot = try await client.fetchUsage()
            lastError = nil
        } catch let error as CodexAPIError {
            lastError = error.errorDescription
        } catch {
            lastError = error.localizedDescription
        }
    }
}
