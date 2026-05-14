# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-05-14

### Added
- Configurable menu bar display mode (Settings → „Menüleisten-Anzeige").
  Six options let you show 5h usage, weekly usage, or both — each optionally
  combined with the elapsed-time progress of the corresponding window
  (e.g. `45%/67% | 30%/12%`). Default remains 5h usage only, matching
  previous behaviour.

## [0.3.0] - 2026-05-14

### Changed
- CI and release workflows migrated from `macos-14` (Xcode 15.4) to `macos-15`
  (Xcode 16) to keep the build toolchain current.
- `swift-tools-version` bumped from 5.9 to 5.10.
- `build-app.sh` now derives `CFBundleShortVersionString` and `CFBundleVersion`
  automatically from the latest git tag instead of a hardcoded `1.0`.
- `User-Agent` header updated to reflect the current version.
- Bump `actions/checkout` from 4 to 6.
- Bump `actions/upload-artifact` from 4 to 7.
- Bump `softprops/action-gh-release` from 2 to 3.

### Added
- Dependabot configuration (`.github/dependabot.yml`) for weekly automated
  updates of GitHub Actions and Swift package dependencies.

## [0.2.0] - 2026-04-30

### Added
- Second progress bar below each usage bar showing elapsed time within the
  5h / 7d / 7d-Opus window, so consumption pace can be compared against
  time pace at a glance.

## [0.1.0] - 2026-04-29

### Added
- Initial release: native macOS menu bar app for Claude.ai usage.
- 5-hour session, 7-day weekly, 7-day Opus usage bars with reset countdown.
- Traffic-light menu bar icon (green / yellow / red) based on session usage.
- Secure `sessionKey` storage in macOS Keychain.
- 60-second auto-refresh.
- Ad-hoc signed `.app` bundle via `build-app.sh`.
- GitHub Actions for CI and release builds.

[Unreleased]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/thomashahn623/ClaudeUsage/releases/tag/v0.1.0
