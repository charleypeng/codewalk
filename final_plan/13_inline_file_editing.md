# Feature 13: Inline File Editing

**Phase**: 4 — Workspace Control Layer
**Status**: [ ] Not started
**Priority**: P3
**CodeWalk Status**: Missing
**Gate**: Verify official file-write endpoint before implementation

## Why After Git/Diff MVP

Editing without strong diff/review and write-contract verification is risky.

## Target

- Read/edit mode toggle in file viewer.
- Dirty state, save, discard, conflict warning.
- Markdown preview for Markdown files.
- Capability-gated based on official file-write support.

## Likely Files

- `lib/presentation/pages/chat_page/chat_page_file_viewer.dart`
- `lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart`
- `lib/data/datasources/project_remote_datasource.dart`
- New file editor widget/service

## Validation

- Verify official write endpoint first.
- Tests for dirty/discard/save flow.
- Manual conflict test when file changes externally.
