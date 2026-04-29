# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeStatus is a native macOS menu bar app (SwiftUI, Swift Package Manager, no Xcode project file) that polls the unofficial `claude.ai` usage API every 60 seconds and displays the 5-hour rolling session utilization as a traffic-light colored percentage in the menu bar.

Requires macOS 14 Sonoma+, Xcode 15+. There are no tests in this project.

## Build Commands

```bash
# Debug build (for development)
swift build

# Release build (matches CI)
swift build -c release

# Build the full .app bundle with Info.plist and ad-hoc signature
./build-app.sh

# Install locally
./build-app.sh && mv build/ClaudeStatus.app /Applications/
```

CI (`ci.yml`) runs `swift build -c release` on every push/PR to `main` using macOS 14 + Xcode 15.4.

Releases are triggered by pushing a `v*` tag; the release workflow runs `build-app.sh` and publishes a `.zip` + `.sha256` to GitHub Releases.

## Architecture

Data flows in one direction: `ClaudeAPIClient` → `UsageStore` → Views.

**`UsageStore`** (`State/UsageStore.swift`) is the single `@MainActor ObservableObject`. It owns the polling timer (60s), coordinates the two-step API call (fetch org list once, then fetch usage), and caches the org ID in the Keychain. All views receive it via `@EnvironmentObject`.

**`ClaudeAPIClient`** (`Services/ClaudeAPIClient.swift`) is a stateless struct wrapping `URLSession`. It hits two unofficial endpoints:
- `GET https://claude.ai/api/organizations` — to resolve the org UUID (called once, then cached)
- `GET https://claude.ai/api/organizations/{orgId}/usage` — returns the three utilization metrics

The `sessionKey` cookie is read from the Keychain on every request inside the private `get(_:)` method.

**`KeychainStore`** (`Services/KeychainStore.swift`) is a static helper storing two keys under service `de.thomashahn.ClaudeStatus`: `claude_session_key` and `claude_org_id`.

**`UsageSnapshot`** (`Models/UsageSnapshot.swift`) separates the raw API DTO (`UsageResponseDTO` with snake_case fields) from the domain model (`UsageSnapshot`). The `toSnapshot()` method on the DTO handles ISO 8601 date parsing with and without fractional seconds.

**Entry point** (`ClaudeStatusApp.swift`) uses `MenuBarExtra` with `.window` style. The menu bar label shows the traffic-light icon (`chart.bar.fill`, `key.slash`, or `exclamationmark.triangle`) plus the live 5-hour percentage. The settings window (`id: "settings"`) is opened imperatively via `openWindow`.

## Key Conventions

- **UI strings are in German** — all user-visible text, button labels, error messages, and log output use German. Keep this consistent.
- **The API is unofficial** — parse defensively; `UsageResponseDTO` uses optionals for all fields. The `seven_day_opus` metric is only shown when `utilization > 0`.
- **No Dock icon** — `LSUIElement = true` in `Info.plist`. The app has no main window; the only persistent UI surface is the `MenuBarExtra` popover.
- **Ad-hoc signing only** — `build-app.sh` signs with `-` (identity). Do not require a Developer ID or notarization for local builds.
- **`sessionKey` is a browser cookie**, not an API key. It starts with `sk-ant-sid01-`. Treat it as a credential throughout.
