# Feature 16: Token/Cost Breakdown and Raw Message Inspector

**Phase**: 5 — Advanced and Experimental Features
**Status**: [ ] Not started
**Priority**: P4
**CodeWalk Status**: Partial

## Why Later

CodeWalk already has provider quota monitoring and inline step token/cost display. A dedicated inspector is useful but not as core as review/navigation.

## Target

- Per-session token/cost summary where available.
- Raw message/part inspector for debugging.
- Clear distinction between actual server usage data and client-estimated costs.

## Likely Files

- `lib/presentation/widgets/quota/`
- `lib/domain/entities/quota.dart`
- `lib/domain/entities/chat_message.dart`
- New raw inspector widget

## Validation

- Tests for absent/partial usage fields.
