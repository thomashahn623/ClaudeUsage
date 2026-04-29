import SwiftUI
import AppKit

@main
struct ClaudeStatusApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            PopoverView().environmentObject(store)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .foregroundStyle(store.trafficColor)
                if store.snapshot != nil {
                    Text("\(store.fiveHourPercent)%")
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
