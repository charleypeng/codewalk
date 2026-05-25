---
feature: "Permission Auto-Approve + Density-Aware Chrome + Compact Sidebar Search"
spec: |
  1. Auto-approve always sends "always" instead of "once" when toggle is enabled.
  2. Top menu and Composer bar respect the user's chosen density setting for margin and padding.
  3. Replace sidebar search field with a compact magnifying glass button next to context/new-chat buttons, saving vertical space.
---

## Task List

### Feature 1: Auto-approve always sends "always"

Description: When the "Permission auto-approve" toggle is on, send responses to the server automatically. Additionally, when asked for permissions, always send the "always" option (with remember: true) instead of "once".

- [ ] 1.01 Update auto-approve logic to reply with "always" instead of "once" when the toggle is enabled
- [ ] 1.02 Ensure remember: true is sent with every auto-approved permission response
- [ ] 1.03 Update tests to reflect the new always-preferred behavior
- [ ] 1.04 Verify auto-approve behavior in both foreground (composer toggle) and background (Android worker) paths

### Feature 2: Top menu and Composer bar respect chosen density

Description: Make the top menu bar and Composer bar respect the user's chosen density setting, especially regarding margin and padding.

- [ ] 2.01 Audit top menu bar (AppBar) for hardcoded margins/padding that ignore density setting
- [ ] 2.02 Audit Composer bar for hardcoded margins/padding that ignore density setting
- [ ] 2.03 Update top menu bar layout to apply density-aware margin and padding
- [ ] 2.04 Update Composer bar layout to apply density-aware margin and padding
- [ ] 2.05 Verify both bars render correctly across all density levels (compact, comfortable, spacious)

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
