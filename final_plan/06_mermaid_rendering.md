# Feature 6: Mermaid Diagram Rendering

**Phase**: 2 — Rich Chat Output and Mobile Accessibility
**Status**: [ ] Not started
**Priority**: P1
**CodeWalk Status**: Missing

## Why Now

Agents frequently generate architecture diagrams. Rendering them inline improves readability without changing protocol semantics.

## Target

- Detect fenced `mermaid` blocks.
- Render diagram with source fallback.
- Provide copy source and possibly export image actions.
- Avoid blocking chat rendering on renderer failures.

## Likely Files

- `lib/presentation/widgets/chat_message/chat_message_content.dart`
- New `lib/presentation/widgets/mermaid_diagram_widget.dart`
- `pubspec.yaml` if a renderer dependency is selected

## Validation

- Widget tests for fallback path.
- Manual tests with flowchart, sequence, and invalid Mermaid syntax.
