import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: UsageStore
    @Environment(\.dismiss) private var dismiss
    @State private var sessionKey: String = KeychainStore.get(.sessionKey) ?? ""

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
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Abbrechen") { dismiss() }
                Button("Speichern") {
                    Task {
                        await store.setSessionKey(sessionKey)
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
