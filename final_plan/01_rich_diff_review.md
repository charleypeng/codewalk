# Feature 1: Rich Diff Review Surface

**Phase**: 1 — High-Impact, Low-Protocol-Risk UX Foundations
**Status**: [ ] Not started
**Priority**: P0
**CodeWalk Status**: Partial

## Why First

It is the strongest planner convergence point and directly improves review of AI-generated code. It also becomes the foundation for inline comments, file path navigation, and later Git UI.

## Current CodeWalk

- `SessionDiffViewer` exists.
- Expanded mode already has a file-tree navigator.
- Preview is still a bounded patch viewer rather than a full review surface.

## Target

- Add true view modes: compact summary, unified/inline diff, and wide stacked/split diff where feasible.
- Add syntax-aware line styling and line-number gutters.
- Add lazy/collapsed rendering for large diffs.
- Add file jump actions from diff rows to file viewer.
- Keep compact mobile readable; default mobile to unified/stacked single-column rather than side-by-side.

## Likely Files

- `lib/presentation/widgets/session_diff_viewer.dart`
- `lib/presentation/utils/diff_parser.dart`
- `lib/presentation/pages/chat_page/chat_page_file_viewer.dart`
- `lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart`
- `test/widget/session_diff_viewer_test.dart` or equivalent new tests

## Validation

- Widget tests for compact and wide layouts.
- Tests for multi-file, nested-path, deleted/added, malformed, and large diffs.
- Manual check on mobile viewport and desktop wide viewport.
