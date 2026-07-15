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
                         codexStore: codexStore,
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
    @ObservedObject var codexStore: CodexUsageStore
    let displayModeRaw: String
    let shouldShowOnboarding: Bool

    @Environment(\.openWindow) private var openWindow
    @State private var didTriggerOnboarding = false

    var body: some View {
        let mode = MenuBarDisplayMode(rawValue: displayModeRaw) ?? .fiveHourUsage
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundStyle(menuBarColor(for: mode))
            if let text = menuBarText(for: mode) {
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
        let mode = MenuBarDisplayMode(rawValue: displayModeRaw) ?? .fiveHourUsage
        if mode.showsCodex {
            guard codexStore.hasCookie else { return "key.slash" }
            if codexStore.lastError != nil { return "exclamationmark.triangle" }
            return "chart.bar.fill"
        }
        guard store.hasCookie else { return "key.slash" }
        if store.lastError != nil { return "exclamationmark.triangle" }
        return "chart.bar.fill"
    }

    private func menuBarText(for mode: MenuBarDisplayMode) -> String? {
        if mode.showsClaudeAndCodex {
            return combinedProviderText(withTime: mode == .claudeAndCodexUsageAndTime)
        }
        return mode.showsCodex ? codexStore.menuBarText(for: mode) : store.menuBarText(for: mode)
    }

    private func menuBarColor(for mode: MenuBarDisplayMode) -> Color {
        if mode.showsClaudeAndCodex {
            let codexUsage = codexStore.snapshot?.primary.utilization ?? 0
            if codexUsage >= 100 { return .red }
            if codexUsage >= 85 { return .yellow }
            return store.menuBarColor
        }
        guard mode.showsCodex else { return store.menuBarColor }
        guard let usage = codexStore.snapshot?.primary.utilization else { return .secondary }
        if usage >= 100 { return .red }
        if usage >= 85 { return .yellow }
        return .green
    }

    private func combinedProviderText(withTime: Bool) -> String? {
        guard let claude = store.snapshot, let codex = codexStore.snapshot else { return nil }
        let claudeUsage = Int(claude.sevenDay.utilization.rounded())
        let codexUsage = Int(codex.primary.utilization.rounded())
        guard withTime else { return "C \(claudeUsage)% | X \(codexUsage)%" }

        let claudeTime = UsageStore.timeProgress(for: claude.sevenDay, windowDuration: 7 * 24 * 3600)
            .map { Int(($0 * 100).rounded()) }
        let codexTime = codex.primaryWindowDuration.flatMap { duration -> Int? in
            guard let reset = codex.primary.resetsAt, duration > 0 else { return nil }
            let start = reset.addingTimeInterval(-duration)
            return Int((min(1, max(0, Date().timeIntervalSince(start) / duration)) * 100).rounded())
        }
        func format(_ usage: Int, _ time: Int?) -> String {
            time.map { "\(usage)%/\($0)%" } ?? "\(usage)%"
        }
        return "C \(format(claudeUsage, claudeTime)) | X \(format(codexUsage, codexTime))"
    }
}
