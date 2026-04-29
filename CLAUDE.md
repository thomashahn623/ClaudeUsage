# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build a release .app bundle (output: build/ClaudeStatus.app)
./build-app.sh

# Build debug binary only (faster iteration)
swift build

# Build release binary only
swift build -c release

# Run directly from SPM (no .app bundle, no Dock suppression)
swift run
```

There are no tests in this project — CI only validates that `swift build -c release` succeeds.

## Release Process

Push a `v*` tag to trigger the Release workflow, which builds `build-app.sh`, zips the `.app`, and publishes a GitHub Release with the zip and its SHA-256. `workflow_dispatch` on the Release workflow produces a `dev-<sha>` artifact without creating a release.

## Architecture

The app is a SwiftUI **MenuBarExtra** (menu-bar-only, `LSUIElement = true`). There is no Xcode project — only a Swift Package (`Package.swift`), requiring Swift 5.9+ / macOS 14.

### Data flow

```
KeychainStore ──read──► UsageStore (@MainActor ObservableObject)
                              │
                    ClaudeAPIClient (URLSession wrapper)
                              │
                 claude.ai/api/organizations         → [OrganizationDTO]
                 claude.ai/api/organizations/{id}/usage → UsageResponseDTO → UsageSnapshot
                              │
                    @Published snapshot / lastError / isLoading
                              │
            ┌─────────────────┴──────────────────┐
       PopoverView                          SettingsView
  (MenuBarExtra content)              (Window id: "settings")
```

`UsageStore` is instantiated once in `ClaudeStatusApp` as `@StateObject` and injected into all views via `.environmentObject(store)`.

### Key conventions

- **DTO vs domain model**: API responses are decoded into `*DTO` structs (`UsageResponseDTO`, `OrganizationDTO`), then converted to domain types (`UsageSnapshot`, `UsageMetric`) via `.toSnapshot()`. Never add business logic to DTOs.
- **Keychain access**: Always go through `KeychainStore.get/set/delete` with a typed `KeychainKey` case (`sessionKey`, `orgId`). The Keychain service identifier is `de.thomashahn.ClaudeStatus`.
- **Error handling**: `ClaudeAPIClient` throws `ClaudeAPIError` (a `LocalizedError` enum). `UsageStore` catches it and writes `lastError: String?`. Views display `store.lastError`.
- **UI language**: All user-facing strings are in **German**. Keep new UI text in German.
- **Polling**: `UsageStore` polls every 60 seconds via a `Timer`. `PopoverView` has its own 30-second `Timer` only to recompute the relative reset-time label without re-fetching.
- **Traffic-light color**: `UsageStore.trafficColor` maps `fiveHourPercent` to green/yellow/red and is used both in the menu bar label and in `PopoverView`.
