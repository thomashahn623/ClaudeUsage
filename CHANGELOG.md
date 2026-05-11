# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-05-11

### Changed
- CI and release workflows upgraded from `macos-14` (Xcode 15.4) to `macos-15`
  (Xcode 16), keeping the build toolchain current.
- Removed hard-coded `xcode-select` path in favour of the runner default.
- `build-app.sh` now reads `APP_VERSION` to write the correct
  `CFBundleShortVersionString` / `CFBundleVersion` into `Info.plist` instead
  of the previous static `1.0`.
- Added Dependabot configuration for automatic weekly GitHub Actions updates.

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

[Unreleased]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/thomashahn623/ClaudeUsage/releases/tag/v0.1.0
