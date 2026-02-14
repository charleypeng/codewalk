# ROADMAP.featA - Sync Hardening and Remote Config Safety

## Status

- [x] Completed (2026-02-14)
- [x] Task 2 - Selection changes no longer trigger abort on active requests.
- [x] Task 3 - Remote sync now uses app namespace payloads only (no workspace `config.json` side effect path).
- [x] Task 9 - `**...**` reasoning status lines now drive progress label and hide the reasoning bubble.

## Scope

- Task 2: Changing agent/model/variant aborts in-flight request (sync regression).
- Task 3: Sync creates `config.json` inside user workspace (side effect).
- Task 9: Thinking/status interpretation mismatch in "Thinking Process" bubble.

## Goal

Stabilize cross-device sync without interrupting active generation, stop workspace file side effects, and improve thinking/status rendering semantics so sync changes are safe and predictable.

## Research Notes

- OpenCode config and runtime behavior (do not write into user workspace as a side effect of UI state):
  - https://github.com/opencode-ai/opencode
- Flutter state isolation and immutable updates (prevents accidental side effects):
  - https://docs.flutter.dev/data-and-backend/state-mgmt/options
- Dart zones/async flow to separate UI updates from request lifecycle:
  - https://api.dart.dev/stable/dart-async/Future-class.html
- Debounce/throttle patterns for sync reconciliation:
  - https://pub.dev/packages/rxdart
- Safe optimistic update + rollback patterns:
  - https://docs.flutter.dev/app-architecture/guide

## Implementation Plan

1. Introduce a `SelectionSyncTransaction` state machine with phases: `idle -> pending_remote -> applied_remote -> failed`.
2. While a response is streaming, queue remote selection flush and apply only after message lifecycle reaches idle.
3. Ensure sync persistence target is app-owned storage only (server namespace + local app cache), never workspace filesystem.
4. Add parser rule for thinking/status lines:
   - If first line starts and ends with `**...**`, treat as status.
   - Replace "Receiving response..." with latest parsed status text.

## Backend/Contract Considerations

- Keep server keys under app namespace only (for example `/config.agent.__codewalk...`).
- Preserve compatibility with desktop/web key schema.
- Add contract tests to verify no outbound write request targets project path.

## Validation

- Unit tests for transaction state machine and queue/flush semantics.
- Widget tests for status-line parsing behavior.
- Integration tests with two simulated clients to confirm no abort and no workspace write.

## Definition of Done

- Selection changes never abort active request.
- No new `config.json` appears in user workspace from sync flow.
- Status-thinking substitution works on mobile and desktop.
