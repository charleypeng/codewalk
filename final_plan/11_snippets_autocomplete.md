# Feature 11: Snippets with `#` Autocomplete

**Phase**: 3 — Organization and Local Productivity
**Status**: [ ] Not started
**Priority**: P2
**CodeWalk Status**: Partial

## Why Here

CodeWalk already has canned answers. This is an incremental composer productivity upgrade.

## Current CodeWalk

- Canned answers in the composer extras menu.
- Global/project scope and insertion modes already exist.

## Target

- Treat canned answers as snippets or add a compatible snippet layer.
- Add `#` trigger in composer suggestions.
- Support project/global scoping and optional labels.
- Avoid conflict with Markdown headings when cursor context is not a trigger context.

## Likely Files

- `lib/presentation/widgets/chat_input/chat_input_mentions_controller.dart`
- `lib/presentation/widgets/chat_input/chat_input_suggestion_popover.dart`
- Existing canned-answer storage/provider code

## Validation

- Widget tests for `#` trigger and insertion.
- Regression tests for existing `@` and `/` triggers.
