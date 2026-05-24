# Feature 3: Timeline Full-Text Search

**Phase**: 1 — High-Impact, Low-Protocol-Risk UX Foundations
**Status**: [ ] Not started
**Priority**: P1
**CodeWalk Status**: Missing

## Why Now

Long sessions are already supported via cache/SWR, but users cannot search within them. This is fully client-side and benefits mobile users.

## Target

- Add session-local search for user, assistant, tool, and reasoning text.
- Highlight matches and provide next/previous navigation.
- Use cached messages first; work with older-history pagination when content is incomplete.

## Likely Files

- `lib/presentation/providers/chat_provider.dart`
- `lib/presentation/pages/chat_page/chat_page_chrome.dart`
- `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart`
- New widget under `lib/presentation/widgets/`

## Validation

- Unit tests for search indexing/filtering.
- Widget tests for match navigation.
- Regression check that search does not trigger scroll-owner conflicts.
