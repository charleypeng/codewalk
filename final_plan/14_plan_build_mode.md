# Feature 14: Plan/Build Mode

**Phase**: 4 — Workspace Control Layer
**Status**: [ ] Not started
**Priority**: P3
**CodeWalk Status**: Missing

## Why Here

Valuable, but needs careful product definition to avoid inventing server semantics.

## Target MVP

- Local plan panel that extracts or pins plan-like assistant content.
- User can comment/refine and send feedback as normal chat messages.
- No claim that client can reorder the server agent's internal task execution unless official API supports it.

## Likely Files

- `lib/presentation/providers/chat_provider.dart`
- `lib/presentation/widgets/session_todo_list_widget.dart` for visual patterns only
- New `lib/presentation/widgets/plan_view.dart`

## Validation

- Widget tests for plan extraction/pinning.
- Regression: no interference with server-owned session todo list.
