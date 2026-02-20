# ROADMAP.featC - Long Conversation Performance and Files Planning

**Status**: Completed (2026-02-19)
**Commits**: pending-commit, 51edd51

## Scope

- [x] Task 6: Keep polling when unfocused but defer rendering until visible/focused according to visibility rules.
  - Render gate implemented: `_notifyListeners` suppresses rebuilds while app in background, flush on foreground return, SSE stays alive, desktop window focus/blur handlers added.
- [x] Task 28: Replace Files bar hide icon with intuitive native icon.
  - Icons replaced: `visibility_off` → `left_panel_close_rounded` / `right_panel_close_rounded` (Symbols).
- [x] Task 30: Plan line comments for opened files (OpenCode web parity planning).
  - Planning doc created: `ROADMAP.featC.comments-plan.md`.
- [x] File Line References: gutter line numbers with tap/shift-tap selection, selection action bar, FileInputPart context chips in chat input, and send pipeline integration. - Commit: 96949cb
  - Fix (51edd51): full-line click area, full-width selection highlight covers gutter+code, dialog closes and focuses composer after "Add to chat", context items sent as inline fenced code blocks instead of FileInputPart attachments to avoid raw XML in response bubbles.

## Goal

Reduce rendering cost in background scenarios, improve Files navigation affordance, and produce implementation-ready plan for file comments.

## Research Notes

- App lifecycle and visibility observers:
  - https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html
  - https://api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html
- Route visibility and render gating patterns:
  - https://api.flutter.dev/flutter/widgets/Visibility-class.html
- Desktop/mobile platform checks:
  - https://api.flutter.dev/flutter/foundation/defaultTargetPlatform.html
- Material symbols/iconography consistency:
  - https://fonts.google.com/icons

## Implementation Plan

1. Implement `RenderGatePolicy` combining app lifecycle + route visibility + window focus signal.
2. Keep network reconcile/polling active while gate is closed, but batch UI mutations and flush on visible resume.
3. Swap Files hide icon to directional panel-collapse icon (`first_page`/`last_page` equivalent by side).
4. Deliver technical design doc for file comments:
   - data model for inline comments;
   - API contract proposals;
   - UI anchors for line-level threads;
   - optimistic update and conflict strategy.

## Backend/Contract Considerations

- Polling pipeline remains server-compatible and does not drop events.
- Comments planning includes permissions and audit metadata requirements.

## Validation

- Lifecycle integration tests for visibility/focus combinations.
- Widget tests for delayed render flush correctness.
- UX snapshot checks for Files icon replacement.

## Definition of Done

- Background polling continues without aggressive rerender while hidden.
- Files hide/show affordance is clearer on desktop/mobile.
- File comments planning is implementation-ready and linked from roadmap.
