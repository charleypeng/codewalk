# Feature 10: Persistent Project Notes and User Todos

**Phase**: 3 — Organization and Local Productivity
**Status**: [ ] Not started
**Priority**: P2
**CodeWalk Status**: Missing

## Why Here

Complements the agent-controlled task list without violating server ownership.

## Target

- Local project notes and user todos scoped by `serverId::scopeId`.
- Clear separation from server/agent session todos.
- Markdown-friendly notes and simple checkbox todos.

## Likely Files

- New `lib/domain/entities/project_notes.dart`
- `lib/data/datasources/app_local_datasource.dart`
- `lib/presentation/pages/chat_page/chat_page_scaffold.dart`
- New project notes panel widget

## Validation

- Persistence tests for context isolation.
- Widget tests for notes/todo editing.
