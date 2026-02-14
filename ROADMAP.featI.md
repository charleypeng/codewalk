# ROADMAP.featI - Agent, Shortcut, and Productivity Parity

## Scope

- Task 10: Background behavior settings (mobile persistent notification, desktop tray).
- Task 14: Show `Shortcuts` section on mobile when physical keyboard is connected.
- Task 15: Check updates via public GitHub Releases API.
- Task 23: Add todo tooling support (`todowrite`, `todoread`, related flows).
- Task 24: Move context button to session title side.
- Task 25: Remove redundant pencil beside title; keep click-to-rename path.
- Task 26: Use clearer Files button icon (tree-like).
- Task 37: One-line tips while waiting for first server tokens.
- Backlog follow-up: Increase desktop project selector width to reduce early ellipsis in top header.

## Goal

Increase productivity and discoverability with stronger keyboard/background behavior, update awareness, and clearer session-header ergonomics.

## Research Notes

- GitHub Releases API (latest/version compare):
  - https://docs.github.com/en/rest/releases/releases#get-the-latest-release
- App version retrieval:
  - https://pub.dev/packages/package_info_plus
- Notifications and tray:
  - https://pub.dev/packages/flutter_local_notifications
  - https://pub.dev/packages/system_tray
- Keyboard presence/input modality:
  - https://docs.flutter.dev/ui/adaptive-responsive/input
- Timed tip rotation:
  - https://api.dart.dev/stable/dart-async/Timer-class.html

## Implementation Plan

1. Add background execution policy setting by platform capabilities.
2. Detect physical keyboard and conditionally expose shortcuts section on mobile.
3. Poll GitHub latest release in settings/about with semver compare and dismissible update banner.
4. Define todo domain models + UI surface integration for todo read/write actions.
5. Refactor session header controls (context button position, pencil cleanup, better Files icon).
6. Add waiting-state rotating tip line before first token arrives.
7. Widen desktop project selector and tune responsive min/max widths to reduce premature ellipsis.

## Backend/Contract Considerations

- Todo support must align with upstream event/part schemas.
- Update check must be rate-limited and resilient to offline mode.

## Validation

- Unit tests for semantic version comparison and update availability states.
- Widget tests for conditional shortcuts visibility with hardware keyboard flag.
- Integration tests for todo action rendering and header control behavior.

## Definition of Done

- Background behavior is configurable and platform-correct.
- Update checks are reliable and non-intrusive.
- Todo functionality and header ergonomics improve day-to-day flow.
- Desktop project selector is readable on large layouts without wasting compact-space behavior.
