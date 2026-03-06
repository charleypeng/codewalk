---
roadmap: "CodeWalk Solo Migration Roadmap"
created_on: "2026-02-09"
execution_mode: "feature-by-feature"
source_project: "https://github.com/easychen/openMode"
---

## Execution Protocol

1. Trigger command pattern: `implement feat XXX now` (example: `implement feat 006 now`).
2. During execution:
   - mark active tasks as `[~]`,
   - mark completed tasks as `[x]`,
   - mark blocked tasks as `[/]` with blocker reason.
3. Complete all tasks in `ROADMAP.featXXX.md` before moving to the next feature unless a blocker is explicit.
4. After full completion of a feature, summarize implementation in `ROADMAP.md` and keep only necessary long-form notes.

## Task List

Concluded historical features were archived to `ROADMAP.archive.done.md` to keep this file focused on active backlog execution.

## Legend

- [x] Done
- [~] In progress now
- [/] Partially done but blocked
- [!] Won't do (with reason)
- [ ] Not started

## Pending Backlog

### Backlog Execution Packs

- `featQ` - Cross-platform UX and settings polish (tracked inline in this file)

### Next Recommended Feature

- `featQ` - inline in `ROADMAP.md` (NEXT: Cross-platform UX and settings polish)

### Backlog Pack Dependency Order

1. `featQ` in `ROADMAP.md` (Cross-platform UX and settings polish - isolated track, can run anytime)

Notes:
- Features featA through featO have been completed and archived.

### Backlog Pack Execution Checklist

- [~] `featQ` - tracked in `ROADMAP.md` (Cross-platform UX and settings polish)

Use the same status convention from Legend for active execution updates (`[~]`, `[x]`, `[/]`).

Completed backlog items moved to `ROADMAP.archive.done.md` (section: Backlog Wave Completed Items).

### Open Backlog by Pack

#### `featQ` Cross-platform UX and settings polish

- [x] Canned answers manager for fast reply - Related commits: 8cf00e0 4fe89be
- [ ] In Settings > Shortcuts, review shortcut coverage and add missing options.
- [x] Add shortcut to enable/disable STT in Shortcuts. - Related commits: 0f69c4a af8ac74
- [x] In composer, adjust ArrowUp/ArrowDown without modifiers for multiline behavior before history navigation; with modifiers keep default editor behavior. - Related commits: c9cd435
- [x] Allow pinning sessions in the Conversations sidebar. - Commit hash: unknown
- [ ] Verify whether background notifications are working correctly on Android.
- [x] Reduce spacing in the Conversations list on desktop - Related commits: d2b084e, 0574884
