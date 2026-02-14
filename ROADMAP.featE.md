# ROADMAP.featE - Session Header and Context Controls

## Scope

- Task 11: Android suggestion popover must not cover input with keyboard open.
- Task 12: Embed/local-manage `opencode serve` as optional local server mode.
- Task 13: Make keyboard shortcuts truly reliable.

## Goal

Harden critical interaction points: composer suggestion placement, local-server operability, and keyboard productivity parity.

## Research Notes

- Keyboard insets and safe-area handling:
  - https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery
  - https://api.flutter.dev/flutter/widgets/MediaQueryData/viewInsets.html
- Shortcuts/Actions/Focus system:
  - https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts
  - https://api.flutter.dev/flutter/widgets/Shortcuts-class.html
  - https://api.flutter.dev/flutter/widgets/Actions-class.html
- Process management considerations for local server mode:
  - https://api.dart.dev/stable/dart-io/Process-class.html
  - https://pub.dev/packages/process_run

## Implementation Plan

1. Rework Android suggestion panel anchoring to composer top edge with keyboard-aware max height.
2. Add local server mode abstraction:
   - start/stop/check-health for `opencode serve`;
   - explicit user opt-in and status in UI;
   - robust failure reporting.
3. Normalize shortcut registration at app shell level and focus scopes to avoid route-local breakage.

## Backend/Contract Considerations

- Local mode uses same HTTP/SSE contract as remote server profile.
- Add health-check endpoint usage and timeout policy.

## Validation

- Device validation on Android with Gboard and Samsung Keyboard.
- Shortcut matrix tests across desktop/web/mobile + physical keyboard.
- Integration test for local server lifecycle (start, reconnect, stop).

## Definition of Done

- Suggestion popover never obscures composer input while typing.
- Local server mode can be started/stopped and used safely.
- Keyboard shortcuts trigger consistently in all supported shells.
