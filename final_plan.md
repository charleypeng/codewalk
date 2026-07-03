# Execution Plan: Fix Windows Speech-to-Text Crash (#43)

## Status

Ready for implementation.

Do not close GitHub issue #43 until a Windows build proves that pressing the microphone button does not terminate the process. Linux-only validation is not enough for final acceptance.

## Problem

Issue #43 reports that CodeWalk closes automatically on Windows when the user activates speech-to-text. The reporter saw this with the Native option and with other STT models such as Whisper/Parakeet.

The current mitigation is incomplete because it disables on-device engines on Windows but leaves Native STT enabled. Independent planner review reinforced that `speech_to_text_windows` itself is a credible native crash surface during `initialize()` or `listen()`, and a Dart `try/catch` cannot reliably recover from a native COM/MediaFoundation process crash.

## Objective

Make Windows voice input safe by removing both known unsafe native plugins from the Windows activation path:

- Do not call `speech_to_text_windows` on Windows.
- Do not call `record_windows` on Windows.
- Add a CodeWalk-owned WASAPI microphone backend for Windows.
- Route Windows on-device STT engines through that WASAPI backend.
- Default Windows STT to a safe on-device engine and show model setup when needed.

Successful behavior: pressing the microphone button on Windows starts on-device STT through CodeWalk's WASAPI backend, opens the model-download flow, or shows an actionable non-crashing setup error. It never terminates the app process.

## Context and Constraints

- Repository: `/home/ubuntu/MEGA/WORK/codewalk`.
- Issue: `https://github.com/verseles/codewalk/issues/43`.
- Flutter project targeting mobile and desktop.
- Relevant dependencies in `pubspec.yaml`: `speech_to_text: 7.3.0`, `sherpa_onnx: ^1.13.2`, `record: ^6.0.0`.
- Existing Dart bridge: `lib/presentation/services/windows_microphone_service.dart` defines MethodChannel `codewalk/windows_microphone`, EventChannel `codewalk/windows_microphone_stream`, `probe()`, `pcmStream()`, and `stopStream()`.
- Existing native backing for that Dart bridge is missing: there is no `windows/runner/windows_microphone_plugin.cpp`.
- Existing audio wrapper: `lib/presentation/services/speech_audio_capture.dart` uses `record` on non-Windows and currently throws on Windows.
- Existing platform policy: `lib/presentation/utils/speech_engine_platform_support.dart` currently enables Native on Windows and disables on-device engines on Windows.
- Existing chat flow: `lib/presentation/widgets/chat_input/chat_input_speech_controller.dart` resolves and starts the selected speech service.
- Existing service owner: `lib/presentation/widgets/chat_input_widget.dart` exposes `_nativeSpeechService`, on-device service getters, `_serviceForEngine`, and `_speechService`.
- Existing settings migration: `lib/presentation/providers/settings_provider.dart` currently migrates Windows on-device selections to Native.
- ADR-038 and ADR-039 document the historical Windows crash mitigation and state that re-enabling on-device engines requires a validated WASAPI backend.
- Do not run `dart tool/i18n/generate_arb.dart`; project rules say that generator is destructive to newer `.arb` keys.
- For Flutter/Dart validation commands, prepend `export PATH="$HOME/flutter/bin:$PATH" && ...`.

## Decisions (Resolved)

1. Disable Native STT on Windows for normal app behavior. Keep `speech_to_text` for non-Windows platforms only.
2. Implement a native Windows WASAPI capture plugin in `windows/runner/` and expose it through the existing `WindowsMicrophoneService` channels.
3. Re-enable Sherpa, Moonshine, Parakeet, and SenseVoice on Windows only through the new WASAPI capture path.
4. Use Parakeet as the Windows default/migration target because it is already the most straightforward multilingual on-device default style in the project.
5. Keep `record` for Linux/macOS capture, but never instantiate `AudioRecorder` on Windows.
6. Add a Windows CI build gate because this fix contains C++ runner code that Linux CI cannot validate.

## Why This Plan

The planner pass improved the diagnosis: the safest correction is not to wrap `speech_to_text.listen()` in Dart, but to avoid `speech_to_text_windows` entirely on Windows. The same applies to `record_windows`. A CodeWalk-owned WASAPI backend is the first implementation path that can make Windows STT work while avoiding both known crash surfaces.

## Overview

Add a Windows native microphone plugin that captures PCM16 mono 16 kHz audio with WASAPI shared-mode capture. Wire `SpeechAudioCapture` to use it on Windows and continue using `record` elsewhere. Flip platform support so Windows uses on-device engines and does not use Native STT. Update migration, settings UI, tests, docs, and CI.

## Steps

### 1. Implement the Windows native microphone backend

- **Files**:
  - Create `windows/runner/windows_microphone_plugin.h`.
  - Create `windows/runner/windows_microphone_plugin.cpp`.
  - Update `windows/runner/flutter_window.h`.
  - Update `windows/runner/flutter_window.cpp`.
  - Update `windows/runner/CMakeLists.txt`.
- **Details**:
  - Implement a `WindowsMicrophonePlugin` class that registers:
    - MethodChannel `codewalk/windows_microphone`.
    - EventChannel `codewalk/windows_microphone_stream`.
  - Supported MethodChannel calls:
    - `probe`: initialize WASAPI enough to validate microphone availability and return exactly one of `allowed`, `denied`, `noInputDevice`, `deviceBusy`, `unknown`, or `notSupported`.
    - `stop`: stop capture and return success.
  - EventChannel behavior:
    - On listen, start a WASAPI shared-mode capture thread.
    - On cancel, stop capture and release resources.
    - Emit `Uint8List` chunks containing little-endian signed PCM16 mono 16 kHz audio.
  - WASAPI rules:
    - Initialize COM on the capture/probe thread with `CoInitializeEx(nullptr, COINIT_MULTITHREADED)`.
    - Use `IMMDeviceEnumerator::GetDefaultAudioEndpoint(eCapture, eConsole, ...)`.
    - Use `IAudioClient` and `IAudioCaptureClient` in shared mode.
    - Map `E_NOTFOUND` and `AUDCLNT_E_DEVICE_INVALIDATED` to `noInputDevice`.
    - Map `AUDCLNT_E_DEVICE_IN_USE` to `deviceBusy`.
    - Map `0x80070005` / access denied to `denied`.
    - Map unknown HRESULTs to `unknown`; never abort the process.
    - Convert float, PCM, and extensible PCM/float mix formats to PCM16 mono 16 kHz.
    - Downmix multi-channel audio by averaging channels.
    - Resample with deterministic linear interpolation and preserve fractional position between packets.
    - Emit silence as zero PCM when WASAPI marks a packet silent.
  - Threading rule:
    - Do not call Flutter `EventSink` directly from the capture thread.
    - Push captured chunks into a mutex-protected queue and call `PostMessage(window, WM_APP + 0x43C, 0, 0)`.
    - Drain the queue and call `event_sink->Success(...)` from `FlutterWindow::MessageHandler` through `WindowsMicrophonePlugin::HandleWindowMessage(...)`.
  - Runner wiring:
    - In `flutter_window.h`, include or forward-declare `WindowsMicrophonePlugin` and add `std::unique_ptr<WindowsMicrophonePlugin> windows_microphone_plugin_;`.
    - In `flutter_window.cpp`, include `windows_microphone_plugin.h`.
    - After `RegisterPlugins(flutter_controller_->engine());`, construct and register the plugin with `flutter_controller_->engine()->messenger()` and `GetHandle()`.
    - In `MessageHandler`, give `windows_microphone_plugin_` the first chance to handle the custom drain message.
    - In `OnDestroy`, call `windows_microphone_plugin_->Stop()` and reset it before resetting `flutter_controller_`.
  - CMake wiring:
    - Add `windows_microphone_plugin.cpp` to the `add_executable(${BINARY_NAME} WIN32 ...)` source list.
    - Link Windows libraries required for WASAPI and COM: `ole32.lib`, `avrt.lib`, and `uuid.lib`.
- **Risk**: High. Native audio code can regress process stability.
- **Validation**: Windows build must compile and a Windows smoke run must prove `probe`, start stream, receive PCM, and stop without crashing.

### 2. Route `SpeechAudioCapture` through WASAPI on Windows

- **Files**:
  - `lib/presentation/services/speech_audio_capture.dart`.
  - `lib/presentation/services/windows_microphone_service.dart`.
- **Details**:
  - Change `SpeechAudioCapture` constructor to accept `WindowsMicrophoneService? windowsMicrophoneService` and default to `const WindowsMicrophoneService()`.
  - On Windows, `hasPermission()` must call `windowsMicrophoneService.probe()` and return `true` only for `WindowsMicrophoneAccessStatus.allowed`.
  - On Windows, `startPcmStream(sampleRate: 16000, numChannels: 1)` must return `windowsMicrophoneService.pcmStream()`.
  - On Windows, reject non-`16000` sample rates and non-`1` channel with a Dart `StateError` before touching native code.
  - On Windows, `stop()` must call `windowsMicrophoneService.stopStream()`.
  - On non-Windows, preserve current `record` behavior and lifecycle cleanup.
  - Keep `MicrophoneBackendUnavailableException` mapping in `WindowsMicrophoneService.pcmStream()` for platform errors.
- **Risk**: Medium.
- **Validation**: Unit tests must prove Windows paths never instantiate `AudioRecorder` and non-Windows paths still use `record`.

### 3. Disable Native STT on Windows and re-enable on-device engines

- **Files**:
  - `lib/presentation/utils/speech_engine_platform_support.dart`.
  - `lib/presentation/services/speech_input_service_stt.dart`.
  - `lib/presentation/services/speech_input_service_moonshine_io.dart`.
  - `lib/presentation/services/speech_input_service_parakeet_io.dart`.
  - `lib/presentation/services/speech_input_service_sensevoice_io.dart`.
  - `lib/presentation/services/speech_input_service_sherpa_io.dart`.
- **Details**:
  - Change `SpeechEnginePlatformSupport.isNativeSupported` so it returns `false` on Windows and Linux, `true` on web and supported Apple/mobile targets.
  - Change `isSherpaSupported` so Windows is supported; keep Android unsupported and web unsupported.
  - Change `isMoonshineSupported`, `isParakeetSupported`, and `isSenseVoiceSupported` so they return `true` on Linux, macOS, and Windows.
  - Update comments to state that Windows on-device support uses CodeWalk WASAPI, not `record_windows`.
  - In `SttSpeechInputService.initialize()`, add an early Windows guard before `_speechToText.initialize(...)`; return `false`, set `_isAvailable = false`, and set an unavailable reason stating that Native Windows STT is disabled because CodeWalk uses on-device WASAPI capture on Windows.
  - Update Moonshine/Parakeet/SenseVoice `_isDesktopSupported` comments and checks to align with the central table. They may include Windows only because `SpeechAudioCapture` now avoids `record_windows` on Windows.
  - Add an explicit platform guard in `SherpaSpeechInputService.initialize()` so direct use is consistent with `SpeechEnginePlatformSupport.isSherpaSupported`.
- **Risk**: Medium.
- **Validation**: Platform-support unit tests must assert Windows Native is false and Windows on-device engines are true.

### 4. Update settings migration and composer fallback

- **Files**:
  - `lib/presentation/providers/settings_provider.dart`.
  - `lib/presentation/widgets/chat_input_widget.dart`.
  - `lib/presentation/widgets/chat_input/chat_input_speech_controller.dart`.
- **Details**:
  - In `SettingsProvider.initialize()`, replace the Windows migration that maps on-device engines to Native.
  - New Windows migration rule: if persisted `speechToTextEngine` is `native`, migrate it to `SpeechToTextEngine.parakeet`; if it is Sherpa, Moonshine, Parakeet, or SenseVoice, preserve it.
  - Keep existing Android/iOS/web slim-build migrations unchanged.
  - In chat input resolution, ensure Windows never falls back to Native because `isNativeSupported` is false.
  - Remove unsafe dependence on `_speechService => _activeSpeechService ?? _nativeSpeechService` for Windows runtime paths. Use the resolved active service directly in start/stop/status/error paths, and do nothing if stop is requested with no active service.
  - Keep model-required status handling for Sherpa/Moonshine/Parakeet/SenseVoice.
- **Risk**: Medium.
- **Validation**: Widget tests must prove a Windows Native persisted setting migrates to Parakeet and the mic path does not instantiate `SttSpeechInputService`.

### 5. Update Settings UI and localization

- **Files**:
  - `lib/presentation/pages/settings/sections/speech_settings_section.dart`.
  - `lib/l10n/app_en.arb` and all locale ARB files under `lib/l10n/`.
  - Generated localization files under `lib/l10n/generated/`.
- **Details**:
  - Replace the Windows message that says Native works when OS speech services are enabled.
  - Add Windows copy explaining that CodeWalk uses local on-device STT through a WASAPI microphone backend on Windows and that Native Windows speech recognition is disabled for stability.
  - Keep buttons for Windows microphone/speech settings only where still useful for microphone privacy troubleshooting.
  - Hide or disable the Native engine radio on Windows with a clear disabled reason.
  - Show model management/download UI for enabled on-device engines on Windows.
  - Add English keys first, copy English fallback values into non-English ARBs, and regenerate Flutter localization output with Flutter's normal localization generation, not `tool/i18n/generate_arb.dart`.
- **Risk**: Low.
- **Validation**: `flutter gen-l10n` or the project's normal build/check flow must leave generated localization files consistent.

### 6. Update ADR and behavior documentation

- **Files**:
  - `ADR.md`.
  - `BEHAVIOR.md`.
  - `CODEBASE.md` if structure descriptions change.
- **Details**:
  - Add a new ADR or update ADR-039 follow-up status to record the final decision: Windows STT uses CodeWalk WASAPI capture plus on-device engines; Native Windows STT is disabled.
  - In `BEHAVIOR.md`, document current implemented behavior only: Windows voice input uses WASAPI capture and on-device models; Native is not used on Windows.
  - In `CODEBASE.md`, document the new `windows_microphone_plugin` runner files and the Dart bridge.
  - Use the project ADR/CODEBASE subagent flow if implementation tooling requires it.
- **Risk**: Low.
- **Validation**: Docs must not claim Native Windows STT is the working path.

### 7. Add tests and CI coverage

- **Files**:
  - `test/unit/presentation/speech_engine_platform_support_test.dart`.
  - `test/unit/providers/settings_provider_test.dart`.
  - `test/unit/services/windows_microphone_service_test.dart`.
  - Add or update tests for `SpeechAudioCapture` Windows behavior.
  - `test/unit/presentation/speech_input_service_stt_test.dart`.
  - `test/widget_test.dart` for chat input voice routing where practical.
  - `.github/workflows/ci.yml`.
- **Details**:
  - Assert Windows platform support:
    - Native unsupported.
    - Sherpa supported.
    - Moonshine supported.
    - Parakeet supported.
    - SenseVoice supported.
  - Assert Windows settings migration:
    - `native` becomes `parakeet`.
    - Existing Sherpa/Moonshine/Parakeet/SenseVoice selections persist.
  - Assert `SttSpeechInputService.initialize()` returns unavailable on Windows without invoking the plugin.
  - Assert `WindowsMicrophoneService.probe()` parses all documented native status strings.
  - Assert `SpeechAudioCapture` on Windows maps `probe()==allowed` to permission true and returns the Windows PCM stream.
  - Add a Windows CI job to `.github/workflows/ci.yml` using `runs-on: windows-latest`, the existing `FLUTTER_VERSION`, `flutter pub get`, and `flutter build windows --debug`.
  - Keep existing Linux quality/test jobs unchanged.
- **Risk**: Medium.
- **Validation**: CI must include a successful Windows build. Manual Windows smoke validation remains required because CI build alone does not exercise microphone hardware.

### 8. Run validation gates

- **Files/Commands**:
  - Analyze touched Dart files:
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze --no-fatal-infos --no-fatal-warnings lib/presentation/services/speech_audio_capture.dart lib/presentation/services/windows_microphone_service.dart lib/presentation/services/speech_input_service_stt.dart lib/presentation/services/speech_input_service_moonshine_io.dart lib/presentation/services/speech_input_service_parakeet_io.dart lib/presentation/services/speech_input_service_sensevoice_io.dart lib/presentation/services/speech_input_service_sherpa_io.dart lib/presentation/utils/speech_engine_platform_support.dart lib/presentation/providers/settings_provider.dart lib/presentation/widgets/chat_input_widget.dart lib/presentation/pages/settings/sections/speech_settings_section.dart`
  - Run focused tests:
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter test --no-pub test/unit/presentation/speech_engine_platform_support_test.dart test/unit/providers/settings_provider_test.dart test/unit/services/windows_microphone_service_test.dart test/unit/presentation/speech_input_service_stt_test.dart test/widget_test.dart`
  - Run full gate:
    - `export PATH="$HOME/flutter/bin:$PATH" && make check`
  - Run Windows build in CI or on Windows host:
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter build windows --debug`
  - Manual Windows smoke test:
    - Launch the Windows debug build.
    - Open Settings > Speech and confirm Native is disabled and Parakeet/on-device setup is visible.
    - Click microphone with no model installed and confirm model setup appears without crash.
    - Install/select a small supported on-device model.
    - Click microphone, speak for at least 5 seconds, stop, and confirm transcription or a non-crashing actionable error.
    - Repeat stop/start three times and confirm the process remains alive.
- **Risk**: Medium.
- **Validation**: All focused tests, `make check`, Windows build, and manual Windows smoke must pass before issue #43 is treated as fixed.

## Risks & Mitigations

- **Critical — native WASAPI bug could still crash Windows**: Keep all native HRESULT paths mapped to errors, release COM resources deterministically, and require Windows smoke testing before closing the issue.
- **High — EventChannel calls from the capture thread could destabilize Flutter**: Marshal captured chunks through `PostMessage` and drain on the Flutter window/UI thread.
- **High — audio format conversion could produce unusable STT input**: Convert to PCM16 mono 16 kHz deterministically, add logging for source format, and validate with a real Windows microphone.
- **Medium — users with Native saved will be surprised by migration**: Migrate to Parakeet and show clear Settings copy explaining Native is disabled on Windows for stability.
- **Medium — CI build does not validate microphone hardware**: Add Windows build CI and keep manual hardware smoke as required acceptance.
- **Low — localization drift**: Update ARBs and generated localization files together; do not run the destructive ARB generator.

## Assumptions to Validate

- **Assumption**: Flutter Windows can compile runner-owned C++ code using WASAPI headers and `ole32.lib`, `avrt.lib`, `uuid.lib`.
  - **Verify**: `flutter build windows --debug` on `windows-latest`.
  - **Fallback**: Fix CMake/library includes until the Windows build passes; do not revert to `record_windows`.
- **Assumption**: On-device STT engines accept PCM16 mono 16 kHz from `SpeechAudioCapture` on Windows exactly like Linux/macOS.
  - **Verify**: Manual Windows smoke with at least one model.
  - **Fallback**: Fix the WASAPI conversion layer; do not fallback to Native Windows STT.
- **Assumption**: Parakeet is the correct default Windows migration target.
  - **Verify**: Settings/model flow works and no model-required dead end appears.
  - **Fallback**: If Parakeet model flow is not available on Windows, use Sherpa as the migration target only after proving its model flow works on Windows.

## Decisions and Nuances

- Native Windows STT is disabled because the suspected crash is native and cannot be made safe by Dart exception handling.
- On-device engines are re-enabled only because the microphone backend changes from `record_windows` to CodeWalk WASAPI.
- The existing `WindowsMicrophoneService` channel names must not change; tests and Dart code already depend on them.
- The Windows C++ plugin must never throw across channel boundaries or abort on HRESULT failures.
- `record_windows` may still be registered by Flutter because `record` is a project dependency, but the Windows voice path must never instantiate or call `AudioRecorder`.

## Blockers and Open Questions

None for implementation.

Final verification is blocked until a Windows build and real microphone smoke test are run. That does not block starting the implementation, but it blocks declaring issue #43 fixed.

## Testing Strategy

Run targeted Dart tests for platform support, settings migration, Windows microphone service parsing, speech audio capture, and Native STT Windows guard. Run `make check` after the code is stable. Add a Windows CI build job. Perform a manual Windows microphone smoke test before closing issue #43.

## Execution Handoff

Start with the native backend: create `windows/runner/windows_microphone_plugin.h/.cpp`, wire it into `flutter_window.*` and `CMakeLists.txt`, and make `flutter build windows --debug` compile. Then wire `SpeechAudioCapture` to the Windows service, flip platform support, update migration/UI/tests/docs, and run the validation gates in the order listed above.

## Out of Scope

- Do not attempt to fix `speech_to_text_windows` upstream in this task.
- Do not use `record_windows` on Windows.
- Do not add MSIX packaging or Windows runtime permission prompts.
- Do not change Linux/macOS capture behavior except where shared abstractions require tests or comments.
- Do not close issue #43 based only on Dart unit tests or Linux CI.
