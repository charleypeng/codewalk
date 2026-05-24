# Feature 4: Session Export as Markdown/JSON

**Phase**: 1 — High-Impact, Low-Protocol-Risk UX Foundations
**Status**: [ ] Not started
**Priority**: P1
**CodeWalk Status**: Missing

## Why Now

Low protocol risk and useful for sharing, archival, and debugging.

## Target

- Export current session as Markdown.
- Optionally export raw JSON for debugging behind a clear developer/debug affordance.
- Preserve roles, timestamps, code blocks, tool summaries, and attachments references where possible.

## Likely Files

- `lib/presentation/providers/chat_provider.dart`
- Session actions menu surface in `chat_page` modules
- New export service under `lib/presentation/services/` or `lib/domain/usecases/`

## Validation

- Unit tests for message-to-Markdown serialization.
- Manual platform share/save test.
