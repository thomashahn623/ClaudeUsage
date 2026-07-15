import Foundation

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case fiveHourUsage
    case fiveHourUsageAndTime
    case weeklyUsage
    case weeklyUsageAndTime
    case bothUsage
    case bothUsageAndTime
    case codexPrimaryUsage
    case codexPrimaryUsageAndTime
    case codexBothUsage
    case codexBothUsageAndTime
    case claudeAndCodexUsage
    case claudeAndCodexUsageAndTime

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .fiveHourUsage: return "5h: x%"
        case .fiveHourUsageAndTime: return "5h: x%/y%"
        case .weeklyUsage: return "Woche: x%"
        case .weeklyUsageAndTime: return "Woche: x%/y%"
        case .bothUsage: return "5h + Woche (x% | x%)"
        case .bothUsageAndTime: return "5h + Woche (x%/y% | x%/y%)"
        case .codexPrimaryUsage: return "Codex primär: x%"
        case .codexPrimaryUsageAndTime: return "Codex primär: x%/y%"
        case .codexBothUsage: return "Codex primär + sekundär (x% | x%)"
        case .codexBothUsageAndTime: return "Codex primär + sekundär (x%/y% | x%/y%)"
        case .claudeAndCodexUsage: return "Claude + Codex Woche (x% | y%)"
        case .claudeAndCodexUsageAndTime: return "Claude + Codex Woche (x%/y% | x%/y%)"
        }
    }

    var showsCodex: Bool {
        switch self {
        case .codexPrimaryUsage, .codexPrimaryUsageAndTime, .codexBothUsage, .codexBothUsageAndTime:
            return true
        default:
            return false
        }
    }

    var showsClaudeAndCodex: Bool {
        self == .claudeAndCodexUsage || self == .claudeAndCodexUsageAndTime
    }
}
