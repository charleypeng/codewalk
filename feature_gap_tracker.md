# Archived Feature Gap Snapshot

**Status**: Archived
**Last reviewed**: 2026-06-15

GitHub Issues are now the canonical tracker for planned work, follow-ups, acceptance criteria, and next tasks. This file remains only as a historical snapshot of the OpenChamber-inspired feature gap planning effort.

## Completed From This Snapshot

| # | Feature | Current state |
|---|---------|---------------|
| 1 | Rich diff review surface | Implemented |
| 2 | Clickable file paths with line jumps | Implemented |
| 3 | Timeline full-text search | Implemented |
| 4 | Session export as Markdown/JSON | Implemented |
| 5 | TTS read-aloud responses | Implemented |
| 6 | Mermaid diagram rendering | Implemented |
| 7 | LaTeX/math rendering | Implemented |
| 8 | Share messages as images | Implemented |

## Remaining Ideas

These are not active commitments in this file. If they are still useful, track them as GitHub Issues with acceptance criteria:

- Session folders and subfolders
- Persistent project notes and user todos
- Snippets with `#` autocomplete
- Git status sidebar and richer Git workflows
- Inline file editing, gated by official write capability
- Plan/build mode
- Inline comment drafts on diffs/plans
- Token/cost breakdown and raw inspector
- Skills catalog and local skill management
- Custom JSON themes
- Multi-agent runs with isolated worktrees

## Current Rules

- ADR-023 remains the compatibility baseline: official OpenCode docs/source override OpenChamber behavior.
- OpenChamber is a useful implementation and UX reference, not a protocol authority.
- Mobile-first responsive UX remains required for every new surface.
- Server-dependent features must be capability-gated and degrade cleanly.
- No credentials should appear in logs, exports, debug UI, or plaintext local storage.
