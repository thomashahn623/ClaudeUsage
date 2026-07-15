import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: UsageStore
    @EnvironmentObject var codexStore: CodexUsageStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @State private var sessionKey: String = KeychainStore.get(.sessionKey) ?? ""
    @State private var codexSessionCookie: String = KeychainStore.get(.codexSessionCookie) ?? ""
    @AppStorage("menuBarDisplayMode") private var displayModeRaw: String = MenuBarDisplayMode.fiveHourUsage.rawValue
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Einstellungen").font(.title2).bold()

            Text("sessionKey aus claude.ai")
                .font(.subheadline)

            SecureField("sk-ant-sid01-…", text: $sessionKey)
                .textFieldStyle(.roundedBorder)

            DisclosureGroup("Wie komme ich an den sessionKey?") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("1. claude.ai im Browser öffnen und einloggen.")
                    Text("2. DevTools öffnen (Cmd+Option+I).")
                    Text("3. Tab Application → Cookies → https://claude.ai.")
                    Text("4. Eintrag sessionKey markieren, Value kopieren.")
                    Text("5. Hier einfügen und speichern.")
                    Button("Geführtes Onboarding erneut öffnen") {
                        onboardingCompleted = false
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "onboarding")
                    }
                    .buttonStyle(.link)
                    .padding(.top, 4)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            Text("Codex / ChatGPT-Sitzungs-Cookie")
                .font(.subheadline)
            SecureField("__Secure-next-auth.session-token=…", text: $codexSessionCookie)
                .textFieldStyle(.roundedBorder)
            Text("In ChatGPT DevTools unter Application → Cookies für chatgpt.com den vollständigen Cookie-Eintrag einfügen. Er wird nur lokal im Schlüsselbund gespeichert.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Text("Menüleisten-Anzeige").font(.subheadline)
            Picker("Anzeige in der Menüleiste", selection: $displayModeRaw) {
                ForEach(MenuBarDisplayMode.allCases) { mode in
                    Text(mode.localizedTitle).tag(mode.rawValue)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()

            HStack {
                Spacer()
                Button("Abbrechen") { dismiss() }
                Button("Speichern") {
                    Task {
                        await store.setSessionKey(sessionKey)
                        await codexStore.setSessionCookie(codexSessionCookie)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
