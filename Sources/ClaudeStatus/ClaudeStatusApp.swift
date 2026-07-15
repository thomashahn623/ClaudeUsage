import SwiftUI
import AppKit

@main
struct ClaudeStatusApp: App {
    @StateObject private var store = UsageStore()
    @StateObject private var codexStore = CodexUsageStore()
    @AppStorage("menuBarDisplayMode") private var displayModeRaw: String = MenuBarDisplayMode.fiveHourUsage.rawValue
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(store)
                .environmentObject(codexStore)
        } label: {
            MenuBarLabel(store: store,
                         displayModeRaw: displayModeRaw,
                         shouldShowOnboarding: !onboardingCompleted && !store.hasCookie)
        }
        .menuBarExtraStyle(.window)

        Window("ClaudeStatus Einstellungen", id: "settings") {
            SettingsView()
                .environmentObject(store)
                .environmentObject(codexStore)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 320)

        Window("ClaudeStatus Verlauf", id: "history") {
            HistorySheetView().environmentObject(store)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 420)

        Window("Willkommen bei ClaudeStatus", id: "onboarding") {
            OnboardingView().environmentObject(store)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 540, height: 460)
    }
}

private struct MenuBarLabel: View {
    @ObservedObject var store: UsageStore
    let displayModeRaw: String
    let shouldShowOnboarding: Bool

    @Environment(\.openWindow) private var openWindow
    @State private var didTriggerOnboarding = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundStyle(store.menuBarColor)
            if let text = store.menuBarText(for: MenuBarDisplayMode(rawValue: displayModeRaw) ?? .fiveHourUsage) {
                Text(text)
                    .monospacedDigit()
            }
        }
        .onAppear {
            guard !didTriggerOnboarding, shouldShowOnboarding else { return }
            didTriggerOnboarding = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "onboarding")
            }
        }
    }

    private var iconName: String {
        guard store.hasCookie else { return "key.slash" }
        if store.lastError != nil { return "exclamationmark.triangle" }
        return "chart.bar.fill"
    }
}
