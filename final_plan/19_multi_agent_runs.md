# Feature 19: Multi-Agent Runs with Isolated Worktrees

**Phase**: 5 — Advanced and Experimental Features
**Status**: [ ] Not started
**Priority**: P5
**CodeWalk Status**: Missing

## Why Advanced

High complexity, experimental worktree dependency, and significant UI/state design.

## Target

- Only after worktree API stability and Git/diff foundations are mature.
- Launch multiple sessions/agents from one prompt with clear isolation labels.
- Compare results without auto-merging.

## Likely Files

- `lib/data/datasources/project_remote_datasource.dart`
- `lib/presentation/providers/chat_provider.dart`
- New multi-agent provider/widgets

## Validation

- Requires a dedicated ADR and extensive integration tests.
