# Feature 12: Git Status Sidebar MVP

**Phase**: 4 — Workspace Control Layer
**Status**: [ ] Not started
**Priority**: P3
**CodeWalk Status**: Missing
**Gate**: Capability-gated — verify `/vcs` endpoint availability before implementation

## Why Before Full Git

Planners ranked Git highly, but full staging/commit/push may not be official-server complete. Start with read-only/capability-gated Git status and changed-file review.

## Target MVP

- Current branch and repository status.
- Changed file list with additions/deletions.
- Open file diff in the rich diff viewer.
- Capability-gated UI if `/vcs` data is unavailable.

## Later Expansion

- Stage/unstage.
- Commit message generation.
- Commit, push, pull, branch switch.
- PR creation and checks only after GitHub auth/API story is verified.

## Likely Files

- `lib/data/datasources/project_remote_datasource.dart`
- New `lib/data/datasources/git_remote_datasource.dart` if endpoints warrant separation
- New Git provider/widgets under `lib/presentation/widgets/git/`
- `lib/presentation/pages/chat_page/chat_page_scaffold.dart`

## Validation

- Contract tests for `/vcs` payloads.
- UI gracefully hides or disables when unsupported.
