import SwiftUI
import AppKit

@main
struct ClaudeStatusApp: App {
    @StateObject private var store = UsageStore()
    @AppStorage("menuBarDisplayMode") private var displayModeRaw: String = MenuBarDisplayMode.fiveHourUsage.rawValue

    var body: some Scene {
        MenuBarExtra {
            PopoverView().environmentObject(store)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .foregroundStyle(store.trafficColor)
                if let text = store.menuBarText(for: MenuBarDisplayMode(rawValue: displayModeRaw) ?? .fiveHourUsage) {
                    Text(text)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)

        Window("ClaudeStatus Einstellungen", id: "settings") {
            SettingsView().environmentObject(store)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 320)
    }

    private var iconName: String {
        guard store.hasCookie else { return "key.slash" }
        if store.lastError != nil { return "exclamationmark.triangle" }
        return "chart.bar.fill"
    }
}
