# ROADMAP.featJ - Speech-to-Text and Microphone Platform Matrix

## Scope

- Task J.01: Research and deliver desktop speech-to-text strategy for Linux, plus compatibility assessment for macOS/Windows/iOS.
- Task J.02: Implement custom Android SpeechRecognizer platform channel with `EXTRA_ENABLE_PUNCTUATION` support.
- Task J.03: Integrate `sherpa_onnx` for Linux desktop on-device STT.
- Task J.04: Configure Apple platform permissions (macOS Info.plist + entitlements).

## Goal

Define a practical, cross-platform microphone input roadmap with explicit package/runtime constraints and fallback options. Implement a service abstraction layer for STT with platform-specific backends: `speech_to_text` (iOS/macOS/Web/Windows), custom Android channel (with auto-punctuation), and `sherpa_onnx` (Linux on-device).

---

## Research Session — 2026-02-18

### 1. Library Evaluation: `speech_to_text` vs Alternatives

**Conclusion: keep `speech_to_text ^7.3.0` as primary lib for iOS/macOS/Web/Windows.**

Rationale: the current use case (short phrases/commands in the composer) fits exactly the documented scope of the package. It is the most widely adopted Flutter STT lib, with a stable API and multi-platform support.

Alternatives evaluated and why they were not chosen as primary:

| Package | Verdict | Reason not chosen |
|---|---|---|
| Picovoice Cheetah | Strong candidate for streaming | Requires paid API key; overkill for current use case |
| `sherpa_onnx` | Best for Linux desktop | More complex setup; chosen specifically for Linux |
| Whisper / whisper.cpp | Good accuracy | Resource-heavy; designed for server-side; latency too high for real-time input |
| Google Cloud STT API | High accuracy with punctuation | Paid, requires backend, adds infra complexity |

Sources:
- https://pub.dev/packages/speech_to_text
- https://fluttergems.dev/ai-voice-assistant/
- https://picovoice.ai/blog/streaming-speech-to-text-in-flutter/
- https://copyprogramming.com/howto/flutter-dart-speech-to-text-offline-and-continuous-for-any-language

---

### 2. Platform Support Matrix (confirmed via research)

| Platform | Status | Notes |
|---|---|---|
| Android | ✅ Works | Native `RecognitionService`; `RECORD_AUDIO` permission already in manifest |
| iOS | ✅ Works | Missing `NSSpeechRecognitionUsageDescription` + `NSMicrophoneUsageDescription` in `Info.plist`; no `ios/` folder in repo yet |
| macOS | ✅ Works | Plugin registered; `Info.plist` keys missing; entitlements lack `com.apple.security.device.audio-input` |
| Windows | ⚠️ Beta | Beta support via `speech_to_text`; not yet production-ready |
| Linux | ❌ Not supported | `speech_to_text` has no Linux implementation; `sherpa_onnx` chosen as replacement |
| Web | ⚠️ Limited | Works on Chrome; Firefox and Brave on Linux lack proper Web Speech API implementation |

---

### 3. Customizations Implemented (commit 921854c)

Changes applied to `lib/presentation/widgets/chat_input_widget.dart`:

**a) `pauseFor: Duration(seconds: 5)`**
- Gives the user a 5-second silence window before the session auto-stops
- Motivation: users need time to pause mid-thought without losing the session
- Caveat: Android enforces a system minimum of 1–3s that cannot be overridden; `pauseFor` only extends above that floor
- iOS/macOS: no floor, works as configured

**b) `autoPunctuation: supportsAutoPunctuation` (iOS and macOS only)**
- Apple's Speech API uses acoustic cues (rising pitch, pause duration, intensity) to infer punctuation
- Conditional: `defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS`
- Android: `autoPunctuation` in `SpeechListenOptions` is iOS-only in the plugin — has no effect on Android

Sources:
- https://pub.dev/documentation/speech_to_text/latest/speech_to_text/SpeechListenOptions-class.html
- https://pub.dev/documentation/speech_to_text/latest/speech_to_text/SpeechToText/listen.html

---

### 4. Android Auto-Punctuation Research

Android's native `SpeechRecognizer` supports a proprietary Google extra `EXTRA_ENABLE_PUNCTUATION` that triggers the on-device ML model to add punctuation based on acoustic cues (pauses, pitch).

**Why `speech_to_text` cannot be used for this:**
The plugin passes a `RecognizerIntent` internally in its Android implementation. There is no public API to inject additional extras into that intent. The `autoPunctuation` field in `SpeechListenOptions` is iOS-only in the current plugin code.

**Caveat:** `EXTRA_ENABLE_PUNCTUATION` is a proprietary Google extra, not part of the standard Android API. It only works on devices with Google Play Services installed. Devices without Google (certain Huawei, custom ROMs) will silently ignore it — STT continues working normally, just without auto-punctuation. No fallback needed; degradation is graceful by design of the API.

**Options evaluated:**

| Option | Complexity | Maintenance | Notes |
|---|---|---|---|
| A — Fork `speech_to_text` | Low (~20-30 lines Kotlin) | High | Must manually port every upstream update |
| B — Custom platform channel in `MainActivity.kt` | Medium (~100 lines Kotlin + ~30 lines Flutter) | Low | Clean; no fork dependency |

**Decision: Option B — Custom platform channel.**

Justification: the project already has a `MethodChannel` in `MainActivity.kt` (`codewalk/system_sounds`), so the infrastructure and pattern are familiar. A custom channel avoids the long-term maintenance burden of a plugin fork and keeps the dependency graph clean.

Sources:
- https://developer.android.com/reference/android/speech/SpeechRecognizer
- https://cloud.google.com/speech-to-text/docs/automatic-punctuation
- https://picovoice.ai/blog/automatic-punctuation-capitalization-speech-to-text/

---

### 5. Linux Desktop Strategy (Updated)

**Previous plan:** use `record` package for audio capture + send chunks to a backend STT service.

**Updated plan: use `sherpa_onnx` directly on-device.**

Justification:
- `sherpa_onnx` is fully offline and proven by Flutter desktop developers as the best solution for Linux STT
- Eliminates the need for a backend STT service, reducing infra complexity and latency
- Supports speech-to-text, VAD (voice activity detection), and speaker diarization
- Uses ONNX runtime with next-gen Kaldi models; no internet required after model download
- Package `sherpa_onnx: ^1.12.25` available on pub.dev with Linux x64/arm64 support
- Uses `OnlineRecognizer` for streaming ASR with partial results

Sources:
- https://pub.dev/packages/sherpa_onnx
- https://pub.dev/packages/sherpa_onnx_linux
- https://github.com/k2-fsa/sherpa-onnx
- https://medium.com/@khlebobul/voice-control-in-flutter-how-to-add-local-speech-recognition-to-your-app-4bcd96bfd896

### 6. macOS Permissions Gap (discovered during planning)

macOS entitlements are missing microphone access:
- `macos/Runner/DebugProfile.entitlements`: has `app-sandbox` + `allow-jit` + `network.server`, but no `device.audio-input`
- `macos/Runner/Release.entitlements`: has only `app-sandbox`, no `device.audio-input`
- `macos/Runner/Info.plist`: no `NSSpeechRecognitionUsageDescription` or `NSMicrophoneUsageDescription`

Without these, speech recognition will silently fail in sandboxed macOS builds.

---

## Architecture Decision: SpeechInputService Abstraction

**Decision:** Create an abstract `SpeechInputService` interface with 3 platform-specific implementations, registered via `get_it` DI.

**Justification:** The current STT logic lives inline in `_ChatInputWidgetState` (lines 208-1828 of `chat_input_widget.dart`) with no abstraction. Supporting 3 different backends (speech_to_text, Android channel, sherpa_onnx) requires a clean interface so the widget stays platform-agnostic.

**Pattern precedent:** Follows `NotificationSoundSourceService` (`notification_sound_source_service_types.dart:20`) — abstract class with platform-specific implementations.

### File Structure

```
lib/presentation/services/
├── speech_input_service.dart               # Abstract interface
├── speech_input_service_stt.dart           # speech_to_text (iOS/macOS/Web/Windows)
├── speech_input_service_android.dart       # Custom platform channel (Android)
└── speech_input_service_sherpa.dart        # sherpa_onnx (Linux)
```

### Interface Contract

```dart
abstract class SpeechInputService {
  Future<bool> initialize();
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function() onError,
    Duration? pauseFor,
    String? localeId,
  });
  Future<void> stopListening();
  bool get isListening;
  bool get isAvailable;
}
```

### DI Registration (injection_container.dart)

```dart
sl.registerLazySingleton<SpeechInputService>(() {
  if (Platform.isAndroid) return AndroidSpeechInputService();
  if (Platform.isLinux) return SherpaSpeechInputService();
  return SttSpeechInputService(); // iOS, macOS, Web, Windows
});
```

---

## Android Custom Channel — Implementation Sketch

### Kotlin Side (`MainActivity.kt`)

Channels:
- `EventChannel("codewalk/speech")` — streams partial/final results as `Map<String, dynamic>` with fields `text` (String) and `isFinal` (Boolean)
- `MethodChannel("codewalk/speech_control")` — receives `start` (with optional `localeId` arg) and `stop` commands

Key code:
```kotlin
// RecognizerIntent with punctuation extra
val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
    putExtra("android.speech.extra.ENABLE_PUNCTUATION", true)
}

// RecognitionListener callbacks to implement:
// onReadyForSpeech, onBeginningOfSpeech, onRmsChanged, onBufferReceived,
// onEndOfSpeech, onResults, onPartialResults, onError
```

Estimated: ~120 lines of Kotlin.

### Flutter Side (`speech_input_service_android.dart`)

```dart
class AndroidSpeechInputService implements SpeechInputService {
  static const _controlChannel = MethodChannel('codewalk/speech_control');
  static const _eventChannel = EventChannel('codewalk/speech');

  // Listen to _eventChannel.receiveBroadcastStream() for results
  // Call _controlChannel.invokeMethod('start'/'stop') for commands
}
```

---

## Implementation Plan

### Step 1 — Create `SpeechInputService` interface
- **Create** `lib/presentation/services/speech_input_service.dart`
- Abstract class with `initialize()`, `startListening()`, `stopListening()`, `isListening`, `isAvailable`

### Step 2 — Create `SttSpeechInputService` (iOS/macOS/Web/Windows)
- **Create** `lib/presentation/services/speech_input_service_stt.dart`
- Move all `speech_to_text` logic from `chat_input_widget.dart` into this service
- Keep: `autoPunctuation` conditional (iOS/macOS), `pauseFor`, `listenMode: dictation`, lazy init with reentrance guard

### Step 3 — Register in DI + refactor widget
- **Edit** `lib/core/di/injection_container.dart` — register `SpeechInputService` with platform factory
- **Edit** `lib/presentation/widgets/chat_input_widget.dart`:
  - Remove `speech_to_text` imports
  - Remove fields: `_speechToText`, `_isInitializingSpeech`, `_isSpeechEnabled`
  - Get service via `sl<SpeechInputService>()`
  - Simplify `_startListening`/`_stopListening`/`_initializeSpeech` to delegate to service
  - Keep: `_isListening`, `_speechPrefix`, `_onSpeechResult` (text composition), mic button UI
- **Verify**: `make precommit` passes, existing behavior unchanged

### Step 4 — Create `AndroidSpeechInputService` + Kotlin channels
- **Create** `lib/presentation/services/speech_input_service_android.dart`
- **Edit** `android/app/src/main/kotlin/com/verseles/codewalk/MainActivity.kt`:
  - Add `EventChannel("codewalk/speech")` with `StreamHandler`
  - Add `MethodChannel("codewalk/speech_control")` with `start`/`stop`
  - Implement `RecognitionListener` with all callbacks
  - Pass `EXTRA_ENABLE_PUNCTUATION` in `RecognizerIntent`
- **Verify**: test on Android device — dictate question with rising intonation → expect `?`

### Step 5 — Configure macOS permissions
- **Edit** `macos/Runner/Info.plist`:
  - Add `NSSpeechRecognitionUsageDescription`: "Voice input uses speech recognition to convert your spoken words to text"
  - Add `NSMicrophoneUsageDescription`: "Microphone access is needed for voice input in the message composer"
- **Edit** `macos/Runner/DebugProfile.entitlements`:
  - Add `com.apple.security.device.audio-input: true`
- **Edit** `macos/Runner/Release.entitlements`:
  - Add `com.apple.security.device.audio-input: true`
- **Verify**: macOS build runs, permission dialog appears on first mic use

### Step 6 — Integrate `sherpa_onnx` for Linux
- **Edit** `pubspec.yaml` — add `sherpa_onnx: ^1.12.25`
- **Create** `lib/presentation/services/speech_input_service_sherpa.dart`
- Use `OnlineRecognizer` for streaming ASR on-device
- Handle model download on first use (streaming multilingual model)
- Audio capture via system microphone
- **Verify**: Linux build runs, STT transcribes speech with model downloaded

### Step 7 — Tests
- **Edit** `test/widget_test.dart` — ensure existing mic button tests pass
- **Create** `test/unit/presentation/speech_input_service_stt_test.dart` — test autoPunctuation platform logic
- **Create** `test/unit/presentation/speech_input_service_android_test.dart` — test channel communication (mock MethodChannel)

### Step 8 — Documentation
- Update CODEBASE.md (via codemapper): new services folder entries
- Update ADR.md (via adrkeeper): ADR for SpeechInputService abstraction decision
- Update this file (ROADMAP.featJ.md): mark tasks complete with hashes

---

## Execution Order

1. Steps 1-3 (interface + STT impl + refactor widget) → atomic commit, `make precommit`
2. Step 4 (Android channel) → atomic commit, manual test on device
3. Step 5 (macOS permissions) → atomic commit, verify macOS build
4. Step 6 (sherpa_onnx Linux) → atomic commit, verify Linux build
5. Steps 7-8 (tests + docs) → final commits

---

## Files to Create/Modify

| File | Action |
|---|---|
| `lib/presentation/services/speech_input_service.dart` | **Create** — interface |
| `lib/presentation/services/speech_input_service_stt.dart` | **Create** — impl iOS/macOS/Web/Windows |
| `lib/presentation/services/speech_input_service_android.dart` | **Create** — impl Android channel |
| `lib/presentation/services/speech_input_service_sherpa.dart` | **Create** — impl Linux sherpa_onnx |
| `lib/presentation/widgets/chat_input_widget.dart` | **Edit** — refactor to use service |
| `lib/core/di/injection_container.dart` | **Edit** — register SpeechInputService |
| `android/app/src/main/kotlin/com/verseles/codewalk/MainActivity.kt` | **Edit** — add Kotlin channels (~120 lines) |
| `macos/Runner/Info.plist` | **Edit** — add speech/mic permission descriptions |
| `macos/Runner/DebugProfile.entitlements` | **Edit** — add audio-input entitlement |
| `macos/Runner/Release.entitlements` | **Edit** — add audio-input entitlement |
| `pubspec.yaml` | **Edit** — add sherpa_onnx dependency |
| `test/widget_test.dart` | **Edit** — ensure existing tests pass |
| `test/unit/presentation/speech_input_service_stt_test.dart` | **Create** — unit tests |
| `test/unit/presentation/speech_input_service_android_test.dart` | **Create** — unit tests |

## Codebase Patterns to Follow

- Abstract class + implementation: `NotificationSoundSourceService` in `notification_sound_source_service_types.dart:20`
- Static MethodChannel const: `_androidChannel` in `notification_sound_source_service_io.dart:17`
- DI via get_it: `injection_container.dart:55` (`sl = GetIt.instance`)
- Platform detection: `defaultTargetPlatform == TargetPlatform.*` (used in ~15 files across project)

---

## Task List

### Feature J: STT Platform Matrix

- [ ] J.01 Create `SpeechInputService` interface + `SttSpeechInputService` implementation + refactor `chat_input_widget.dart` to use service via DI
- [ ] J.02 Implement `AndroidSpeechInputService` with custom platform channel (`codewalk/speech` EventChannel + `codewalk/speech_control` MethodChannel) and `EXTRA_ENABLE_PUNCTUATION` in `MainActivity.kt`
- [ ] J.03 Integrate `sherpa_onnx ^1.12.25` for Linux desktop — `SherpaSpeechInputService` with `OnlineRecognizer` streaming ASR on-device
- [ ] J.04 Configure macOS permissions — `Info.plist` (speech + mic descriptions) + entitlements (`device.audio-input`) in both Debug and Release profiles

---

## Definition of Done

- `SpeechInputService` abstraction in place with 3 implementations registered via get_it.
- Android auto-punctuation working via custom channel on Google Play Services devices.
- Linux STT working via `sherpa_onnx` on-device (model downloaded on first use).
- macOS permissions configured — dialog appears on first mic use in sandboxed build.
- All existing tests passing + new unit tests for service implementations.
- UX fallback behavior (snackbar on unsupported platforms) remains in place.
- Documentation updated (CODEBASE.md, ADR.md, ROADMAP.md).
