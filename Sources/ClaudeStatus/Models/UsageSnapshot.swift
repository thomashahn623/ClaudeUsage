import Foundation

struct UsageMetric: Codable, Equatable {
    let utilization: Double
    let resetsAt: Date?
}

struct UsageSnapshot: Equatable {
    let fiveHour: UsageMetric
    let sevenDay: UsageMetric
    let sevenDayOpus: UsageMetric?
    let fetchedAt: Date
}

struct UsageResponseDTO: Decodable {
    struct Metric: Decodable {
        let utilization: Double?
        let resets_at: String?
    }
    let five_hour: Metric?
    let seven_day: Metric?
    let seven_day_opus: Metric?

    func toSnapshot() -> UsageSnapshot {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoNoFrac = ISO8601DateFormatter()
        isoNoFrac.formatOptions = [.withInternetDateTime]

        func parse(_ m: Metric?) -> UsageMetric {
            guard let m else { return UsageMetric(utilization: 0, resetsAt: nil) }
            let date: Date? = m.resets_at.flatMap { iso.date(from: $0) ?? isoNoFrac.date(from: $0) }
            return UsageMetric(utilization: m.utilization ?? 0, resetsAt: date)
        }

        return UsageSnapshot(
            fiveHour: parse(five_hour),
            sevenDay: parse(seven_day),
            sevenDayOpus: seven_day_opus.map { _ in parse(seven_day_opus) },
            fetchedAt: Date()
        )
    }
}

struct OrganizationDTO: Decodable {
    let uuid: String
    let name: String?
}
