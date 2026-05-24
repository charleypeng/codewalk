# Feature 8: Share Messages as Images

**Phase**: 2 — Rich Chat Output and Mobile Accessibility
**Status**: [ ] Not started
**Priority**: P2
**CodeWalk Status**: Missing

## Why Here

Low protocol risk and useful once rich rendering is improved.

## Target

- Export a single message as a themed image.
- Support share sheet where available.
- Handle long messages with a safe height cap or multi-image strategy.

## Likely Files

- `lib/presentation/widgets/chat_message_widget.dart`
- New `lib/presentation/services/message_image_exporter.dart`

## Validation

- Widget/image export test where feasible.
- Manual Android and desktop share smoke.
