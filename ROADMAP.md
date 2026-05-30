---
feature: "Permission Auto-Approve + Density-Aware Chrome + Compact Sidebar Search"
spec: |
  1. Auto-approve always sends "always" instead of "once" when toggle is enabled.
  2. Top menu and Composer bar respect the user's chosen density setting for margin and padding.
  3. Replace sidebar search field with a compact magnifying glass button next to context/new-chat buttons, saving vertical space.
---

## Task List

### Feature 1: Auto-approve always sends "always" — ✅ Completed

Description: When the "Permission auto-approve" toggle is on, send responses to the server automatically. Additionally, when asked for permissions, always send the "always" option (with remember: true) instead of "once".

Already implemented in code — `permission_auto_approve_runtime.dart` always returns "always" with `remember:true` in both foreground and background paths.

Commits: pre-existing implementation.

- [x] 1.01 Update auto-approve logic to reply with "always" instead of "once" when the toggle is enabled — Commits: pre-existing implementation
- [x] 1.02 Ensure remember: true is sent with every auto-approved permission response — Commits: pre-existing implementation
- [x] 1.03 Update tests to reflect the new always-preferred behavior — Commits: pre-existing implementation
- [x] 1.04 Verify auto-approve behavior in both foreground (composer toggle) and background (Android worker) paths — Commits: pre-existing implementation

### Feature 2: Top menu and Composer bar respect chosen density — ✅ Completed

Description: Make the top menu bar and Composer bar respect the user's chosen density setting, especially regarding margin and padding.

Implemented `AppDensitySpacing` static helper class with semantic spacing methods. Replaced hardcoded spacings in chrome and composer. Zero regression at `AppDensity.normal`.

Commits: 7426c8a1, f29eb542

- [x] 2.01 Audit top menu bar (AppBar) for hardcoded margins/padding that ignore density setting — Commit hash: 7426c8a1
- [x] 2.02 Audit Composer bar for hardcoded margins/padding that ignore density setting — Commit hash: 7426c8a1
- [x] 2.03 Update top menu bar layout to apply density-aware margin and padding — Related commits: 7426c8a1 f29eb542
- [x] 2.04 Update Composer bar layout to apply density-aware margin and padding — Related commits: 7426c8a1 f29eb542
- [x] 2.05 Verify both bars render correctly across all density levels (compact, comfortable, spacious) — Related commits: 7426c8a1 f29eb542

### Feature 3: Search conversations as a magnifying glass button

Description: Replace the search conversations input field with a compact magnifying glass icon button placed next to the conversation context buttons and the new conversation button, saving vertical space in the sidebar sessions menu.

- [ ] 3.01 Audit current sidebar search field layout and identify vertical space usage
- [ ] 3.02 Design compact search icon button placement next to context and new-chat buttons
- [ ] 3.03 Implement search icon button that expands into search input on tap
- [ ] 3.04 Ensure search functionality (filter, results) remains intact after UI change
- [ ] 3.05 Verify layout on compact (mobile) and expanded (desktop/tablet) sidebars

### Feature 4: Session Export as Markdown/JSON

Description: Export chat sessions as Markdown or JSON files via the session actions menu, with paginated message loading, file_picker save flow, Clipboard fallback, and local_user_* ID omission per ADR-023.

Implemented `SessionExportService` with Markdown and JSON serialization, added export actions to both the session chrome menu and timeline builder menu, integrated `file_picker` save dialog with Clipboard fallback on dismiss, and added a paginated message guard that loads older messages before export to prevent truncation. JSON export omits `local_user_*` fields per ADR-023.

Commits: a8b42ea, 200dfb4, 79d90dd

### Feature 8: Share messages as images

Description: Export individual chat messages as PNG images for easy sharing, with text selection support and theme-consistent rendering.

Implemented `MessageImageExportService` for rendering message content to PNG with proper text styling, code block formatting, and theme-aware backgrounds. Added share action to the message context menu with platform-native share integration. Release v1.84.0.

Commits: 37d51df, 3863f7b, 4d7de5a, dd900d8

### Feature 9: Cloudflare Access OAuth Remediation (PR #37)

Description: Added OAuth 2.0 + PKCE support for Cloudflare Access as an optional server-profile auth mode, enabling users who run OpenCode behind Cloudflare Access to authenticate securely. Implemented secure profile-scoped OAuth token storage in `flutter_secure_storage`, isolated OAuth and Basic Auth lifecycle ownership with mutual exclusivity, split the OAuth service into platform-aware implementations (desktop IO vs web-safe), gated Cloudflare OAuth to desktop platforms only (hidden on mobile), hardened the callback against state mismatch and race conditions, and added comprehensive i18n and tests. This is an intentional ADR-023 exception — Cloudflare Access is an external reverse-proxy access layer, not an OpenCode server API replacement.

Commits: 0981549a, c6d07e37, 2e13dc26, 4cfa9786, 1f534c53, ac29f0aa, 5cc357c4, 0acca027, 3c298f49, 2125a074, c3f74ba7

### Feature 6: Reactive notification dismissal on SSE events and session actions

Description: Notifications should auto-dismiss reactively when the triggering event is resolved — not only on manual session switch. Current code only calls `clearNotificationsForSession()` on session switch (`chat_page_runtime_support.dart:470`); permission reply, question reply, and session idle SSE events do not trigger dismissal.

- [ ] 6.01 Dismiss notification when `permission.replied` or `question.replied` SSE event arrives — wire `_applyChatEvent()` in `chat_provider_event_reducer_ops.dart` to call `clearNotificationsForSession()` for the session that owns the replied permission/question
- [ ] 6.02 Dismiss completion notification when user opens the session — `session.idle` creates a notification but does not auto-dismiss it on session open; add explicit dismiss path when the user navigates to the completed session
- [ ] 6.03 Sync background alert dismissal with foreground actions — when the user responds to a permission or opens a session in the foreground, also clear the corresponding notification IDs tracked by `BackgroundAlertSnapshot` (notifiedPermissionRequestIds, notifiedQuestionRequestIds) so background polling does not re-notify about already-handled items
- [ ] 6.04 Reactive dismiss for cross-device/cross-session events — when a `permission.replied` or `question.replied` event arrives for a non-active session (different session), dismiss the notification for that session so stale permission notifications do not linger
- [ ] 6.05 Verify end-to-end: trigger each notification type (permission, question, completion, error) and confirm auto-dismiss works through all paths: foreground SSE, background alert worker, and notification tap open

### Feature 7: Restore agent, model, and variant when opening existing session

Description: When opening an existing session, restore the agent, model, and variant that were last used in that session. CodeWalk currently has `_sessionSelectionOverridesByKey` that saves per-session selection state, but only when the user explicitly changes it — sessions without an override fall back to global defaults instead of reading from authoritative server message metadata. OpenChamber solves this by (1) client-side per-session localStorage maps and (2) ACP `restoreSessionStateFromMessages()` which reads `model.providerID`, `model.modelID`, `model.variant`, and `agent` from the last user message in the server message list.

- [ ] 7.01 Add fallback chain in `_applySessionSelectionOverride()`: when no override exists for the session, fall back to reading the last user message's metadata from the server message list to determine the session's model, agent, and variant
- [ ] 7.02 Parse `AssistantMessage.providerId`, `AssistantMessage.modelId`, `AssistantMessage.variant`, and `ChatInput.mode` from the most recent user message to populate the selection state on session open
- [ ] 7.03 Ensure variant is restored from message metadata — currently variant is only remembered per-model-key (`_selectedVariantByModel`) and per-session-override, but not from message history when no override exists
- [ ] 7.04 Persist the restored selection as an explicit override (`_storeCurrentSessionSelectionOverride()`) so subsequent opens are fast (cache-first, no message parse needed)
- [ ] 7.05 Add OpenChamber-style localStorage persistence as a secondary resilience layer: store per-session agent/model/variant maps that survive context resets and provide an additional fallback before message-level lookup
