# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.1] - 2026-05-14

### Changed
- Forecast velocity window now scales per metric: the 5-hour session keeps
  the 30-minute regression window, while the 7-day and 7-day Opus metrics
  use a 6-hour window. Extrapolating a 30-minute burst across five-plus
  days produced misleading "200 % at reset" warnings; the longer window
  averages out short bursts and idle gaps for the long cycle.
- The popover's forecast line is no longer coloured solely by the projected
  utilisation. A sanity gate now requires both an *over-budget* burn rate
  (`utilization > elapsed cycle time`) and a projection of `>= 100 %` before
  the line turns red. Low-confidence forecasts remain greyed out as before.
- The menu bar icon now reflects actual overrun risk via a new
  `menuBarColor`: red when any metric is critical (over budget *and*
  projected to overflow, or already at 100 %), yellow when any metric is
  over budget, green otherwise. The previous logic only watched the 5-hour
  utilisation and flipped to red at 85 %, which fired even when the time
  window had plenty of headroom left.

## [0.5.0] - 2026-05-14

### Added
- Local usage history is now persisted to
  `~/Library/Application Support/ClaudeStatus/history.json`. Every successful
  60-second snapshot is appended, with debounced writes to keep IO low.
- Forecast line below each usage bar in the popover, showing the projected
  utilisation at reset and the current velocity in `% / hour`. Uses linear
  regression over the last 30 minutes (with fallback to the entire current
  cycle when fewer than three samples are available). Confidence is shown
  through colour: secondary for low-confidence, orange when the forecast
  crosses 85 %, red at 100 %.
- New "Verlauf" window (opened from the popover) lists past cycles per
  metric (5h / 7d / Opus) with peak utilisation, average velocity and
  sample range.

### Changed
- `KeychainStore` now caches values in memory after the first read, so each
  app session triggers at most one Keychain prompt per stored item instead
  of one per refresh.
- `build-app.sh` automatically picks the most stable code-signing identity
  available (Developer ID > Apple Development > Apple Distribution > local
  self-signed cert) and falls back to ad-hoc when none is found. CI runs
  (`CI=true`, e.g. GitHub Actions) always force ad-hoc, so released `.app`
  bundles contain no personal Apple ID, team ID or signer name. Override
  via `SIGN_IDENTITY=...` or `FORCE_AD_HOC=1`.

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

[Unreleased]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/thomashahn623/ClaudeUsage/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/thomashahn623/ClaudeUsage/releases/tag/v0.1.0
