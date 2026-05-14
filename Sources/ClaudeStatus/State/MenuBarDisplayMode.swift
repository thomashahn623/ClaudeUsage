import Foundation

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case fiveHourUsage
    case fiveHourUsageAndTime
    case weeklyUsage
    case weeklyUsageAndTime
    case bothUsage
    case bothUsageAndTime

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .fiveHourUsage: return "5h: x%"
        case .fiveHourUsageAndTime: return "5h: x%/y%"
        case .weeklyUsage: return "Woche: x%"
        case .weeklyUsageAndTime: return "Woche: x%/y%"
        case .bothUsage: return "5h + Woche (x% | x%)"
        case .bothUsageAndTime: return "5h + Woche (x%/y% | x%/y%)"
        }
    }
}
