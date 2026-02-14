# ROADMAP.featJ - Speech-to-Text and Microphone Platform Matrix

## Scope

- Task 1: Research and deliver desktop speech-to-text strategy for Linux, plus compatibility assessment for macOS/Windows/iOS.

## Goal

Define a practical, cross-platform microphone input roadmap with explicit package/runtime constraints and fallback options.

## Research Notes

- Community STT plugin coverage:
  - https://pub.dev/packages/speech_to_text
  - https://pub.dev/packages/flutter_sound
- Audio capture fundamentals:
  - https://pub.dev/packages/record
- Permissions:
  - https://pub.dev/packages/permission_handler
- Platform capability docs:
  - https://docs.flutter.dev/platform-integration

## Technical Direction

1. Validate native microphone capture support matrix per platform (Linux/macOS/Windows/iOS).
2. If direct plugin support is inconsistent on Linux desktop, use fallback architecture:
   - local capture via `record`;
   - send audio chunks to backend STT service;
   - display transcript streaming in composer.
3. For iOS/macOS/Windows, prefer direct plugin path if stable; keep backend fallback as universal path.
4. Add capability probing and runtime fallback, never presenting unsupported controls as enabled.

## Backend/Contract Considerations

- Define audio upload/chunk API and transcript event schema.
- Handle latency and cancellation semantics to avoid stale transcript inserts.

## Validation

- Capability matrix document (per OS) with tested versions and known caveats.
- Manual microphone smoke tests on Linux + at least one Apple and one Windows target.

## Definition of Done

- Clear STT support table with chosen package/path per platform.
- UX fallback behavior documented and implementation-ready.
