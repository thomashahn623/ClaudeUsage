import Foundation

struct HistorySample: Codable, Equatable {
    let timestamp: Date
    let fiveHour: Double
    let sevenDay: Double
    let sevenDayOpus: Double?
    let fiveHourResetsAt: Date?
    let sevenDayResetsAt: Date?
    let sevenDayOpusResetsAt: Date?

    init(snapshot: UsageSnapshot) {
        self.timestamp = snapshot.fetchedAt
        self.fiveHour = snapshot.fiveHour.utilization
        self.sevenDay = snapshot.sevenDay.utilization
        self.sevenDayOpus = snapshot.sevenDayOpus?.utilization
        self.fiveHourResetsAt = snapshot.fiveHour.resetsAt
        self.sevenDayResetsAt = snapshot.sevenDay.resetsAt
        self.sevenDayOpusResetsAt = snapshot.sevenDayOpus?.resetsAt
    }
}

enum MetricKind: String, CaseIterable, Identifiable {
    case fiveHour
    case sevenDay
    case sevenDayOpus

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fiveHour: return "5-Stunden-Session"
        case .sevenDay: return "7-Tage-Limit"
        case .sevenDayOpus: return "7-Tage-Opus"
        }
    }
}

extension HistorySample {
    func utilization(for metric: MetricKind) -> Double? {
        switch metric {
        case .fiveHour: return fiveHour
        case .sevenDay: return sevenDay
        case .sevenDayOpus: return sevenDayOpus
        }
    }

    func resetsAt(for metric: MetricKind) -> Date? {
        switch metric {
        case .fiveHour: return fiveHourResetsAt
        case .sevenDay: return sevenDayResetsAt
        case .sevenDayOpus: return sevenDayOpusResetsAt
        }
    }
}

struct CycleSummary: Identifiable, Equatable {
    let id: Date
    let resetsAt: Date
    let metric: MetricKind
    let peak: Double
    let averageVelocityPerHour: Double?
    let sampleCount: Int
    let firstSampleAt: Date
    let lastSampleAt: Date
}
