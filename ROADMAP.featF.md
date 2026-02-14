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
