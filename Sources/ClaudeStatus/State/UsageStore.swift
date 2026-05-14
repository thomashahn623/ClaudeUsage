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

    let history = HistoryStore()

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
            self.history.append(snap)
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
    var sevenDayPercent: Int {
        Int((snapshot?.sevenDay.utilization ?? 0).rounded())
    }

    func forecast(for metric: MetricKind, now: Date = Date()) -> ForecastResult? {
        guard let snap = snapshot else { return nil }
        let usageMetric: UsageMetric?
        switch metric {
        case .fiveHour: usageMetric = snap.fiveHour
        case .sevenDay: usageMetric = snap.sevenDay
        case .sevenDayOpus: usageMetric = snap.sevenDayOpus
        }
        guard let current = usageMetric else { return nil }
        return ForecastEngine.compute(
            samples: history.samples,
            metric: metric,
            currentMetric: current,
            now: now
        )
    }
    var trafficColor: Color {
        let p = fiveHourPercent
        if p >= 85 { return .red }
        if p >= 60 { return .yellow }
        return .green
    }

    static func timeProgress(for metric: UsageMetric, windowDuration: TimeInterval, now: Date = Date()) -> Double? {
        guard let reset = metric.resetsAt, windowDuration > 0 else { return nil }
        let start = reset.addingTimeInterval(-windowDuration)
        let elapsed = now.timeIntervalSince(start)
        return min(max(elapsed / windowDuration, 0), 1)
    }

    func menuBarText(for mode: MenuBarDisplayMode, now: Date = Date()) -> String? {
        guard let snap = snapshot else { return nil }

        let fiveUsage = Int(snap.fiveHour.utilization.rounded())
        let weekUsage = Int(snap.sevenDay.utilization.rounded())
        let fiveTime = Self.timeProgress(for: snap.fiveHour, windowDuration: 5 * 3600, now: now)
            .map { Int(($0 * 100).rounded()) }
        let weekTime = Self.timeProgress(for: snap.sevenDay, windowDuration: 7 * 24 * 3600, now: now)
            .map { Int(($0 * 100).rounded()) }

        func combine(_ usage: Int, _ time: Int?) -> String {
            if let time { return "\(usage)%/\(time)%" }
            return "\(usage)%"
        }

        switch mode {
        case .fiveHourUsage:
            return "\(fiveUsage)%"
        case .fiveHourUsageAndTime:
            return combine(fiveUsage, fiveTime)
        case .weeklyUsage:
            return "\(weekUsage)%"
        case .weeklyUsageAndTime:
            return combine(weekUsage, weekTime)
        case .bothUsage:
            return "\(fiveUsage)% | \(weekUsage)%"
        case .bothUsageAndTime:
            return "\(combine(fiveUsage, fiveTime)) | \(combine(weekUsage, weekTime))"
        }
    }
}
