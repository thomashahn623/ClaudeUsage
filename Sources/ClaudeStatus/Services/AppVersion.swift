import Foundation

/// Versionsangaben aus dem App-Bundle. Der User-Agent wird daraus abgeleitet,
/// damit er beim Release nicht mehr von Hand nachgezogen werden muss.
enum AppVersion {
    static var short: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    static var userAgent: String {
        "AIUsage/\(short) (macOS; SwiftUI)"
    }
}
