# Feature 2: Clickable File Paths with Line Jumps

**Phase**: 1 — High-Impact, Low-Protocol-Risk UX Foundations
**Status**: [ ] Not started
**Priority**: P0
**CodeWalk Status**: Missing

## Why Next

Low implementation risk and high daily value. It reuses the existing file viewer and makes assistant output actionable.

## Target

- Detect `path/to/file.dart`, `path/to/file.dart:42`, and common `file:line:column` forms in assistant prose.
- Avoid linking URLs and code-block content unless explicitly safe.
- Open existing file viewer and scroll/highlight the target line when present.
- Show clear feedback when a file cannot be resolved in the current project.

## Likely Files

- `lib/presentation/widgets/chat_message/chat_message_content.dart`
- `lib/presentation/widgets/chat_message_widget.dart`
- `lib/presentation/pages/chat_page/chat_page_file_viewer.dart`
- `lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart`

## Validation

- Widget tests for path detection and non-detection cases.
- Manual test from assistant message to file viewer line highlight.
