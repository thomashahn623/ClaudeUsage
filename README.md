# ClaudeStatus

Native macOS-Statusleisten-App, die deine aktuelle Claude.ai-Subscription-Auslastung anzeigt:

- 5-Stunden-Session in Prozent (Ampelfarbe in der Menüleiste)
- 7-Tage-Wochenlimit
- 7-Tage-Opus-Limit (nur wenn genutzt)
- Reset-Countdown je Limit

## Voraussetzungen

- macOS 14 Sonoma oder neuer
- Xcode Command Line Tools (`xcode-select --install`)
- Aktives Claude.ai Pro- oder Max-Abo

## Bauen und installieren

```bash
cd ClaudeStatus
./build-app.sh
mv build/ClaudeStatus.app /Applications/
open /Applications/ClaudeStatus.app
```

Das Skript baut eine Release-Version und packt sie in ein `.app`-Bundle mit `LSUIElement = true`, damit kein Dock-Icon erscheint. Die Ad-hoc-Signatur reicht für lokalen Eigenbetrieb.

Beim ersten Start fragt macOS einmal nach der Erlaubnis, weil die App nicht notarisiert ist. Falls Gatekeeper blockiert: `Systemeinstellungen → Datenschutz & Sicherheit → "Trotzdem öffnen"`.

## sessionKey eintragen

Beim ersten Start zeigt das Menüleisten-Icon einen durchgestrichenen Schlüssel. Klick darauf, dann **Einstellungen**, dann den `sessionKey` aus claude.ai einfügen.

So kommst du an den `sessionKey`:

1. https://claude.ai im Browser öffnen, eingeloggt sein.
2. DevTools öffnen (`Cmd + Option + I`).
3. Tab **Application** (Chrome) bzw. **Storage** (Safari) → **Cookies** → `https://claude.ai`.
4. Eintrag `sessionKey` markieren, **Value** kopieren (langer String, beginnt mit `sk-ant-sid01-…`).
5. In der App in das Settings-Feld einfügen, speichern.

Der Cookie wird im macOS-Keychain abgelegt. Er hält typischerweise einige Wochen. Wenn das Icon ein Warndreieck zeigt, ist er abgelaufen — Schritte oben wiederholen.

## Autostart bei Login

Bis ein dedizierter Settings-Toggle existiert: in `Systemeinstellungen → Allgemein → Anmeldeobjekte → +` die `ClaudeStatus.app` hinzufügen.

## Was die App nicht tut

- Keine Kostenschätzung in EUR (die Datenquelle liefert keine Token-Counts, eine Schätzung wäre zu wackelig).
- Kein Zugriff auf Claude-Code-CLI-Daten oder Anthropic-Console.
- Kein Verlauf, keine Diagramme, keine Push-Benachrichtigungen.

## Hinweise

Der genutzte Endpoint `https://claude.ai/api/organizations/{org}/usage` ist **inoffiziell**. Anthropic kann ihn jederzeit ändern. Bei Schema-Brüchen zeigt die App eine Fehlermeldung und parst defensiv.

Behandle den `sessionKey` wie ein Passwort. Wer ihn besitzt, ist als du bei Claude.ai eingeloggt. Die App speichert ihn ausschließlich lokal im Keychain und überträgt ihn nur in den Cookie-Header von Anfragen an `claude.ai`.

## Projektstruktur

```
ClaudeStatus/
├── Package.swift
├── build-app.sh            # baut .app-Bundle mit LSUIElement
└── Sources/ClaudeStatus/
    ├── ClaudeStatusApp.swift     # @main, MenuBarExtra
    ├── Models/UsageSnapshot.swift
    ├── Services/
    │   ├── ClaudeAPIClient.swift # URLSession-Wrapper
    │   └── KeychainStore.swift   # Cookie & Org-ID im Keychain
    ├── State/UsageStore.swift    # ObservableObject, 60s-Polling
    └── Views/
        ├── PopoverView.swift
        └── SettingsView.swift
```
