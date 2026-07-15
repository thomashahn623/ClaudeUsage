import SwiftUI
import AppKit

struct OnboardingView: View {
    @EnvironmentObject var store: UsageStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false

    @State private var step: Int = 0
    @State private var sessionKey: String = KeychainStore.get(.sessionKey) ?? ""
    @State private var isSaving: Bool = false

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 28)
                .padding(.top, 28)

            Divider()

            footer
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
        }
        .frame(width: 540, height: 460)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: welcomeStep
        case 1: openBrowserStep
        case 2: devToolsStep
        case 3: pasteKeyStep
        default: welcomeStep
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Willkommen bei AI Usage")
                .font(.title).bold()
            Text("AI Usage zeigt dir in der Menüleiste, wie viel deines Claude- und Codex-Kontingents bereits verbraucht ist – inkl. Forecast, Verlauf und Reset-Countdown.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Damit die App deine Nutzung lesen kann, braucht sie einmalig deinen `sessionKey`-Cookie von claude.ai. Er wird ausschließlich lokal in deinem macOS-Schlüsselbund gespeichert.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var openBrowserStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(number: 1, title: "claude.ai im Browser öffnen")
            Text("Öffne claude.ai in einem Browser deiner Wahl und melde dich mit dem Account an, dessen Nutzung du beobachten möchtest.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                if let url = URL(string: "https://claude.ai") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("claude.ai öffnen", systemImage: "safari")
            }
            .controlSize(.large)

            Text("Tipp: Nutze den Browser, in dem du sowieso bei claude.ai eingeloggt bist – dann musst du dich nicht noch einmal anmelden.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private var devToolsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepHeader(number: 2, title: "sessionKey-Cookie kopieren")
            instructionRow(icon: "wrench.and.screwdriver",
                           text: "DevTools öffnen: **⌘ + ⌥ + I** (Safari erst aktivieren via *Safari → Einstellungen → Erweitert → Entwicklermenü*).")
            instructionRow(icon: "folder",
                           text: "Tab **Application** (Chrome/Arc/Edge) bzw. **Storage** (Safari/Firefox) wählen.")
            instructionRow(icon: "doc.text.magnifyingglass",
                           text: "Links **Cookies → https://claude.ai** auswählen.")
            instructionRow(icon: "key",
                           text: "Eintrag **sessionKey** suchen, in der Spalte *Value* doppelklicken und kopieren (beginnt mit `sk-ant-sid01-…`).")

            HStack(spacing: 6) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.secondary)
                Text("Der Key bleibt lokal – er geht nur an api.claude.ai, nie an Dritte.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
    }

    private var pasteKeyStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepHeader(number: 3, title: "sessionKey einfügen")
            Text("Füge den kopierten Wert hier ein. Du kannst ihn jederzeit in den Einstellungen ändern.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            SecureField("sk-ant-sid01-…", text: $sessionKey)
                .textFieldStyle(.roundedBorder)
                .disabled(isSaving)

            if let err = store.lastError, !sessionKey.isEmpty {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal")
                    .foregroundStyle(.green)
                Text("Sobald du speicherst, lädt AI Usage die erste Auswertung. Die Menüleisten-Anzeige aktualisiert sich automatisch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
    }

    private func stepHeader(number: Int, title: String) -> some View {
        HStack(spacing: 10) {
            Text("Schritt \(number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.accentColor))
            Text(title)
                .font(.title3).bold()
        }
    }

    private func instructionRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(.tint)
            Text(LocalizedStringKey(text))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Circle()
                        .fill(i == step ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }

            Spacer()

            Button("Überspringen") {
                onboardingCompleted = true
                closeWindow()
            }
            .buttonStyle(.borderless)

            if step > 0 {
                Button("Zurück") { step -= 1 }
            }

            if step < totalSteps - 1 {
                Button(step == 0 ? "Los geht's" : "Weiter") { step += 1 }
                    .keyboardShortcut(.defaultAction)
            } else {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Speichern & starten")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(sessionKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        await store.setSessionKey(sessionKey)
        isSaving = false
        onboardingCompleted = true
        closeWindow()
    }

    private func closeWindow() {
        for window in NSApp.windows where window.identifier?.rawValue == "onboarding" {
            window.close()
        }
        dismiss()
    }
}
