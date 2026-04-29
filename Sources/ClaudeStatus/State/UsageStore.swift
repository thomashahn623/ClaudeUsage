import Foundation
import SwiftUI
import Combine

@MainActor
final class UsageStore: ObservableObject {
    @Published var snapshot: UsageSnapshot?
    @Published var lastError: String?
    @Published var isLoading: Bool = false
    @Published var orgId: String? = KeychainStore.get(.orgId)
    @Published var hasCookie: Bool = (KeychainStore.get(.sessionKey)?.isEmpty == false)

    private let client = ClaudeAPIClient()
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

    func setSessionKey(_ value: String) async {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainStore.delete(.sessionKey)
            KeychainStore.delete(.orgId)
            orgId = nil
            hasCookie = false
            snapshot = nil
            lastError = "Kein sessionKey hinterlegt."
            return
        }
        KeychainStore.set(trimmed, for: .sessionKey)
        hasCookie = true
        // Org neu ermitteln
        KeychainStore.delete(.orgId)
        orgId = nil
        await refresh()
    }

    func refresh() async {
        guard hasCookie else {
            lastError = "Kein sessionKey hinterlegt."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            if orgId == nil {
                let orgs = try await client.fetchOrganizations()
                guard let first = orgs.first else { throw ClaudeAPIError.noOrganizations }
                KeychainStore.set(first.uuid, for: .orgId)
                orgId = first.uuid
            }
            guard let id = orgId else { return }
            let snap = try await client.fetchUsage(orgId: id)
            self.snapshot = snap
            self.lastError = nil
        } catch let err as ClaudeAPIError {
            self.lastError = err.errorDescription
        } catch {
            self.lastError = error.localizedDescription
        }
    }
}

extension UsageStore {
    var fiveHourPercent: Int {
        Int((snapshot?.fiveHour.utilization ?? 0).rounded())
    }
    var trafficColor: Color {
        let p = fiveHourPercent
        if p >= 85 { return .red }
        if p >= 60 { return .yellow }
        return .green
    }
}
