# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/thomashahn623/ClaudeUsage/releases/tag/v0.1.0
