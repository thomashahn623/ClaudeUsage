import Foundation
import Combine

@MainActor
final class CodexUsageStore: ObservableObject {
    @Published var snapshot: CodexUsageSnapshot?
    @Published var lastError: String?
    @Published var isLoading = false
    @Published var hasCookie = CodexAPIClient.hasSessionCookie

    private let client = CodexAPIClient()
    private var timer: Timer?
    private let interval: TimeInterval = 60

    init() {
        migrateLegacyCookieIfNeeded()
        hasCookie = CodexAPIClient.hasSessionCookie
        startTimer()
        Task { await refresh() }
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    func setSessionCookieParts(_ part0: String, _ part1: String, _ identity: String) async {
        let trimmedPart0 = part0.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPart1 = part1.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIdentity = identity.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPart0.isEmpty || trimmedPart1.isEmpty {
            KeychainStore.delete(.codexSessionCookiePart0)
            KeychainStore.delete(.codexSessionCookiePart1)
            KeychainStore.delete(.codexSessionCookie)
            KeychainStore.delete(.codexIdentityCookie)
            hasCookie = false
            snapshot = nil
            lastError = "Kein ChatGPT-Sitzungs-Cookie für Codex hinterlegt."
            return
        }
        KeychainStore.set(trimmedPart0, for: .codexSessionCookiePart0)
        KeychainStore.set(trimmedPart1, for: .codexSessionCookiePart1)
        KeychainStore.set(trimmedIdentity, for: .codexIdentityCookie)
        KeychainStore.delete(.codexSessionCookie)
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

    func menuBarText(for mode: MenuBarDisplayMode, now: Date = Date()) -> String? {
        guard let snapshot else { return nil }

        let primaryUsage = Int(snapshot.primary.utilization.rounded())
        let primaryTime = timeProgress(for: snapshot.primary, duration: snapshot.primaryWindowDuration, now: now)
        let secondaryUsage = snapshot.secondary.map { Int($0.utilization.rounded()) }
        let secondaryTime = snapshot.secondary.flatMap {
            timeProgress(for: $0, duration: snapshot.secondaryWindowDuration, now: now)
        }

        func combine(_ usage: Int, _ time: Int?) -> String {
            time.map { "\(usage)%/\($0)%" } ?? "\(usage)%"
        }

        switch mode {
        case .codexPrimaryUsage:
            return "\(primaryUsage)%"
        case .codexPrimaryUsageAndTime:
            return combine(primaryUsage, primaryTime)
        case .codexBothUsage:
            return secondaryUsage.map { "\(primaryUsage)% | \($0)%" } ?? "\(primaryUsage)%"
        case .codexBothUsageAndTime:
            return secondaryUsage.map { "\(combine(primaryUsage, primaryTime)) | \(combine($0, secondaryTime))" }
                ?? combine(primaryUsage, primaryTime)
        case .claudeAndCodexUsage, .claudeAndCodexUsageAndTime:
            return nil
        default:
            return nil
        }
    }

    private func timeProgress(for metric: UsageMetric, duration: TimeInterval?, now: Date) -> Int? {
        guard let duration, duration > 0, let reset = metric.resetsAt else { return nil }
        let start = reset.addingTimeInterval(-duration)
        let progress = min(1, max(0, now.timeIntervalSince(start) / duration))
        return Int((progress * 100).rounded())
    }

    private func migrateLegacyCookieIfNeeded() {
        guard KeychainStore.get(.codexSessionCookiePart0) == nil,
              KeychainStore.get(.codexSessionCookiePart1) == nil,
              let legacy = KeychainStore.get(.codexSessionCookie) else { return }

        let pieces = legacy.split(separator: ";", maxSplits: 1).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard pieces.count == 2,
              let part0 = pieces[0].split(separator: "=", maxSplits: 1).dropFirst().first,
              let part1 = pieces[1].split(separator: "=", maxSplits: 1).dropFirst().first else { return }

        KeychainStore.set(String(part0), for: .codexSessionCookiePart0)
        KeychainStore.set(String(part1), for: .codexSessionCookiePart1)
        KeychainStore.delete(.codexSessionCookie)
    }
}
