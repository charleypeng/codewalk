# ROADMAP.featF - Files Navigation and Drafting UX

## Scope

- Task 31: Plan basic dev editor for opened Files.
- Task 32: Fix duplicate sent messages bug.
- Task 33: Double-click assistant response should copy full message.

## Goal

Increase editing/navigation reliability and remove high-friction interaction bugs in message and files workflows.

## Research Notes

- Text editing foundations in Flutter:
  - https://api.flutter.dev/flutter/widgets/EditableText-class.html
  - https://api.flutter.dev/flutter/material/TextField-class.html
- Clipboard APIs:
  - https://api.flutter.dev/flutter/services/Clipboard-class.html
- Gesture conflict handling (double tap vs selection):
  - https://api.flutter.dev/flutter/widgets/GestureDetector-class.html
  - https://api.flutter.dev/flutter/widgets/SelectionArea-class.html

## Implementation Plan

1. Produce dev-editor planning doc (MVP): syntax highlight strategy, dirty-state guard, save/revert model, and diff preview.
2. Trace duplicate-send root cause in composer/send pipeline and SSE reconciliation; add message dedupe key.
3. Implement assistant-message double-click copy priority over word selection, preserving long-press selection on touch.

## Backend/Contract Considerations

- Ensure send dedupe uses stable client-generated id echoed through backend lifecycle.
- Editor plan includes conflict policy for stale writes.

## Validation

- Unit tests for dedupe reducer and idempotent message insertion.
- Widget tests for double-click copy and touch long-press selection coexistence.
- Manual desktop validation for copy gesture consistency.

## Definition of Done

- Duplicate sent-message bug is reproducibly fixed.
- Double-click copies full assistant message reliably.
- Dev-editor plan is actionable with API/UI dependencies listed.

## Task Status

- [x] F.01 Files viewer with syntax highlight delivered as phase target; full remote write editor deferred for now due to current server Files API limitations. - Commit hash: 840bd75
- [x] F.02 Optimistic message deduplication fixed for attachment flows, including reconciliation when local and remote URLs differ. - Commit hash: 840bd75
- [x] F.03 Copy gesture flow revised: desktop double-click now reliably copies full assistant message; single-tap on markdown code copies snippet; links continue opening normally. - Related commits: 20e9d17 0cb2854

## Decision and Limitations

- Full remote file editor intentionally postponed in this phase.
- Current delivery scope is Files viewing with syntax highlighting while waiting for server Files API write support.

## Conclusion

featF concluded with Files UX stabilization and copy/dedup reliability improvements, prioritizing compatible delivery with current backend constraints and deferring remote write editing to a future phase.

Commits: 840bd75, 20e9d17, 0cb2854

## Performance Fixes (post-conclusion)

Completed performance fixes: microtask batching (_notifyListeners/scroll coalescing), event dedup buffer (circular 64-entry), timeline entries cache, highlight theme cache, ChatMessageWidget converted to StatefulWidget with build-skip, cached MarkdownStyleSheet per widget, cached O(N) scans (context usage, reasoning key, progress stage, sent history), lazy copy text. - Commit hash: 00b326f

## Dependency Upgrades (post-conclusion)

Upgraded flutter_secure_storage 9.2.4 → 10.0.0 (resolves deprecated-literal-operator warnings, bumps Java target 11 → 17, flutter_secure_storage_linux 1.2.3 → 3.0.0). - Commit hash: 547da29
