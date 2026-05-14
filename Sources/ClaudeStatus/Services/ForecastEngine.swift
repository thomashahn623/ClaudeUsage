import Foundation

struct ForecastResult: Equatable {
    enum Confidence { case low, medium, high }

    let velocityPerHour: Double
    let projectedAtReset: Double
    let confidence: Confidence
    let sampleCount: Int
}

enum ForecastEngine {
    static func defaultWindowDuration(for metric: MetricKind) -> TimeInterval {
        switch metric {
        case .fiveHour: return 30 * 60
        case .sevenDay, .sevenDayOpus: return 6 * 3600
        }
    }

    static func compute(samples: [HistorySample],
                        metric: MetricKind,
                        currentMetric: UsageMetric,
                        windowDuration: TimeInterval? = nil,
                        now: Date = Date()) -> ForecastResult? {
        let windowDuration = windowDuration ?? defaultWindowDuration(for: metric)
        guard let resetsAt = currentMetric.resetsAt, resetsAt > now else { return nil }

        let cycleSamples = samples
            .filter { sample in
                guard let r = sample.resetsAt(for: metric) else { return false }
                return abs(r.timeIntervalSince(resetsAt)) < 1
            }
            .sorted { $0.timestamp < $1.timestamp }

        let windowStart = now.addingTimeInterval(-windowDuration)
        let windowSamples = cycleSamples.filter { $0.timestamp >= windowStart }

        let basis: [HistorySample]
        if windowSamples.count >= 3 {
            basis = windowSamples
        } else if cycleSamples.count >= 2 {
            basis = cycleSamples
        } else {
            return nil
        }

        guard let velocity = linearRegressionSlopePerHour(samples: basis, metric: metric) else {
            return nil
        }

        let hoursToReset = resetsAt.timeIntervalSince(now) / 3600
        let projected = currentMetric.utilization + velocity * hoursToReset
        let clamped = min(max(projected, 0), 200)

        let confidence: ForecastResult.Confidence
        if windowSamples.count >= 10 { confidence = .high }
        else if windowSamples.count >= 5 { confidence = .medium }
        else { confidence = .low }

        return ForecastResult(
            velocityPerHour: velocity,
            projectedAtReset: clamped,
            confidence: confidence,
            sampleCount: basis.count
        )
    }

    private static func linearRegressionSlopePerHour(samples: [HistorySample], metric: MetricKind) -> Double? {
        let points: [(x: Double, y: Double)] = samples.compactMap { sample in
            guard let y = sample.utilization(for: metric) else { return nil }
            return (sample.timestamp.timeIntervalSinceReferenceDate / 3600, y)
        }
        guard points.count >= 2 else { return nil }

        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumXX = points.reduce(0) { $0 + $1.x * $1.x }

        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else { return nil }

        return (n * sumXY - sumX * sumY) / denominator
    }
}
