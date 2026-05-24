# Feature 7: LaTeX/Math Rendering

**Phase**: 2 — Rich Chat Output and Mobile Accessibility
**Status**: [ ] Not started
**Priority**: P2
**CodeWalk Status**: Missing

## Why After Mermaid

Similar rendering pipeline, narrower audience.

## Target

- Render inline `$...$` and block `$$...$$` math where safe.
- Provide fallback to raw source when parsing fails.
- Avoid corrupting currency values or shell snippets.

## Likely Files

- `lib/presentation/widgets/chat_message/chat_message_content.dart`
- New math renderer widget
- `pubspec.yaml` if a dependency is selected

## Validation

- Tests for math detection and false positives.
