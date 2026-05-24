# Feature 15: Inline Comment Drafts on Diffs/Plans

**Phase**: 4 — Workspace Control Layer
**Status**: [ ] Not started
**Priority**: P3
**CodeWalk Status**: Missing

## Why After Rich Diff and Plan Mode

It depends on both surfaces.

## Target

- Local draft comments anchored to diff file/line or plan step.
- Batch send all comments as a structured follow-up message.
- Persist drafts per session until sent or cleared.

## Likely Files

- Rich diff widgets from Phase 1
- Plan view widgets from Phase 4
- New local comment draft model/provider

## Validation

- Tests for draft persistence, delete, and send composition.
