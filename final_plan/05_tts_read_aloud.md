# Feature 5: TTS Read-Aloud Responses

**Phase**: 2 — Rich Chat Output and Mobile Accessibility
**Status**: [ ] Not started
**Priority**: P1
**CodeWalk Status**: Missing

## Why Now

CodeWalk already has a strong STT stack. TTS completes the hands-free mobile workflow.

## Target

- Add per-assistant-message read-aloud action.
- Add playback state: play, pause/stop, currently reading indicator.
- Add settings for enabled/disabled, speed, pitch, voice where supported.
- Stop or pause playback safely on session switch, app background, or new send.

## Likely Files

- New `lib/presentation/services/tts_service.dart` with platform abstraction
- `lib/presentation/widgets/chat_message_widget.dart`
- `lib/presentation/widgets/chat_message/chat_message_content.dart`
- `lib/domain/entities/experience_settings.dart`
- `lib/presentation/providers/settings_provider.dart`

## Validation

- Service unit tests with fake TTS backend.
- Widget tests for controls.
- Manual Android and desktop smoke.
