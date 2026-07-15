import Foundation

struct CodexUsageSnapshot: Equatable {
    let primary: UsageMetric
    let secondary: UsageMetric?
    let primaryWindowDuration: TimeInterval?
    let secondaryWindowDuration: TimeInterval?
    let fetchedAt: Date
}

/// Response shape used by the Codex usage dashboard. The endpoint is not public
/// API surface, so decoding is deliberately limited to the values the UI needs.
struct CodexUsageResponseDTO: Decodable {
    struct RateLimit: Decodable {
        struct Window: Decodable {
            let used_percent: Double?
            let reset_at: Double?
            let limit_window_seconds: Double?
        }

        let primary_window: Window?
        let secondary_window: Window?
    }

    let rate_limit: RateLimit?

    func toSnapshot() -> CodexUsageSnapshot {
        func metric(_ window: RateLimit.Window?) -> UsageMetric? {
            guard let window else { return nil }
            return UsageMetric(
                utilization: window.used_percent ?? 0,
                resetsAt: window.reset_at.map { Date(timeIntervalSince1970: $0) }
            )
        }

        return CodexUsageSnapshot(
            primary: metric(rate_limit?.primary_window) ?? UsageMetric(utilization: 0, resetsAt: nil),
            secondary: metric(rate_limit?.secondary_window),
            primaryWindowDuration: rate_limit?.primary_window?.limit_window_seconds,
            secondaryWindowDuration: rate_limit?.secondary_window?.limit_window_seconds,
            fetchedAt: Date()
        )
    }
}
