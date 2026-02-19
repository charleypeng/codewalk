# File Line Comments — Technical Plan

> **Status**: Planning (not yet implemented)
> **Feature**: featC / Task 30
> **Scope**: Client-side line-level annotations on viewed files

---

## 1. Overview

Allow users to attach text comments to specific lines in files opened through the file explorer panel. Comments are scoped per session and persisted locally (no server-side API exists for this).

---

## 2. Data Model

```dart
class FileComment {
  final String id;            // UUID v4
  final String sessionId;     // scoped to the session that created it
  final String filePath;      // normalized file path
  final int lineNumber;       // 1-based line index
  final String lineContent;   // snapshot of the line text at creation time
  final String text;          // user comment body
  final DateTime createdAt;
  final String authorRole;    // 'user' (future: 'assistant')
}
```

**Key**: `(sessionId, filePath, lineNumber)` — one comment per line per session (latest wins on conflict).

---

## 3. Persistence

### Current state

The OpenCode server API (`/file`, `/file/content`, `/file/status`, `/find`) is **read-only** and exposes **no comment/annotation endpoints**.

### Strategy

| Layer | Mechanism |
|-------|-----------|
| Runtime | `Map<String, List<FileComment>>` keyed by `sessionId` in `ChatProvider` or a dedicated `FileCommentProvider` |
| Local persistence | `SharedPreferences` JSON blob keyed by `(serverId, scopeId, sessionId)` |
| Remote sync (future) | Piggyback on the `config` agent options pattern (same as model favorites) — `codewalk.fileComments` namespace |

### Future server endpoints (proposal)

```
POST   /session/:id/file-comment          { filePath, lineNumber, lineContent, text }
GET    /session/:id/file-comments          ?path=<filePath>
DELETE /session/:id/file-comment/:commentId
```

Until these exist, the feature is 100% client-side with local persistence.

---

## 4. UI Design

### 4.1 Gutter indicator

- In the file viewer (`chat_page_file_viewer.dart`), add a narrow gutter column to the left of line numbers.
- Lines with comments show a small comment icon (`Symbols.comment_rounded`, 14px, theme primary color).
- Lines without comments show nothing (no interaction affordance until hover/tap).

### 4.2 Add comment interaction

- **Desktop**: hover over gutter area reveals a faded `+` icon; click opens a popover anchored to the line.
- **Mobile**: tap the line number area opens the popover.
- Popover contains:
  - Read-only display of the line content (1 line, monospace, truncated).
  - `TextField` for comment text (multiline, max 500 chars).
  - Save / Cancel buttons.

### 4.3 View existing comments

- **Tap comment icon** in gutter → opens same popover pre-filled with existing comment text (editable).
- **Tooltip on hover** (desktop only) shows comment preview (first 80 chars).

### 4.4 Comments list panel

- Optional collapsible section below the file tree in the file explorer panel.
- Shows all comments for the current session, grouped by file path.
- Tap navigates to the file and scrolls to the line.

---

## 5. Optimistic Update

- Save to in-memory map immediately on "Save" press.
- Persist to SharedPreferences asynchronously (fire-and-forget with error logging).
- No server roundtrip needed (local-only).

---

## 6. Orphaned Comments

When a file changes (detected by comparing `lineContent` snapshot with current file content):

- Comment is marked as **orphaned** (visual indicator: warning icon + muted text).
- Orphaned comments still display but show a "Line content has changed" warning.
- User can dismiss (delete) or re-anchor (update `lineNumber` + `lineContent`).

Detection: compare stored `lineContent` against the actual line content when the file is loaded/refreshed.

---

## 7. Architecture Alignment

| ADR | Alignment |
|-----|-----------|
| ADR-004 (slim orchestrators) | Comment state lives in a dedicated provider or as a subset of ChatProvider, not in widget state |
| ADR-007 (settings arch) | Persistence follows the same SharedPreferences pattern as other local state |
| ADR-003 (realtime) | No realtime sync needed — comments are local-only for now |

---

## 8. Implementation Sequence (when ready)

1. Create `FileComment` entity in `domain/entities/`
2. Create `FileCommentProvider` (or extend `ChatProvider`) with in-memory store + SharedPreferences persistence
3. Add gutter column to file viewer widget
4. Implement popover for add/edit comment
5. Add orphan detection logic
6. Add comments list section in file explorer panel
7. Unit tests for provider CRUD + orphan detection
8. Integration test for popover flow

---

## 9. Open Questions

- Should comments survive session deletion? (Current proposal: no — scoped to session lifecycle)
- Should assistant-generated comments be supported? (Future: yes, via tool-use annotation)
- Priority of server-side persistence vs. local-only? (Depends on OpenCode API roadmap)
