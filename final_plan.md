# Issue #98 — Cross-Platform Floating Session Attention

## Status

Ready for execution, with mandatory technical gates in Step 1.

This file is the complete and authoritative implementation directive for GitHub issue [#98](https://github.com/verseles/codewalk/issues/98). Execute it without relying on chat history, planner outputs, or prior context. Do not silently weaken the confirmed product behavior. If a mandatory Android multi-engine or desktop multi-window prototype fails, stop and report the exact blocker instead of substituting an unreviewed package or reducing the feature.

## Problem

CodeWalk tracks work across multiple OpenCode sessions, but users must return to the main window and inspect session lists to discover that an out-of-focus session is still working, requires interaction, failed, is taking unusually long, or completed. Existing notifications and recent-session indicators do not provide a persistent, glanceable, cross-application surface.

Issue #98 requires a configurable floating indicator with three modes:

- `Off`
- compact `Bubble`
- larger `Panel`

The feature must work across Android, desktop, and iOS within each platform’s constraints. It must display only root sessions, aggregate multiple sessions through a highest-priority state plus count, show actual final-response text, navigate to the exact session, and offer direct read-aloud using the user’s configured native, Edge, or OpenAI-compatible TTS provider.

The repository does not currently contain the required infrastructure:

- Android has no `SYSTEM_ALERT_WINDOW` permission, `specialUse` foreground service, overlay window, overlay Flutter engine, or overlay permission flow.
- The existing Android foreground service is temporary, notification-only, and declared as `dataSync`.
- WorkManager polling is best-effort and too sparse to drive a live overlay.
- Existing background snapshots contain status/title/request IDs, not response text, directory scope, explicit dismissal, delayed state, or durable completion state.
- Existing attention aggregation primarily represents the current project context and does not enforce root-only semantics for every attention kind.
- Non-current sessions intentionally avoid full message hydration under ADR-003.
- Existing chat cache content is plaintext and is not an acceptable cross-engine response-text protocol.
- Desktop uses `window_manager` and `tray_manager`, but `window_manager` cannot create a second window.
- Multi-window packages use separate Flutter engines and require explicit IPC and per-engine plugin registration.
- OAuth and Tailscale cannot currently be reconstructed by the Android background worker after process death.
- Cellular data saver currently suppresses all automatic background network work.

## Objective

Deliver a secure, opt-in, cross-platform floating attention system with these observable outcomes:

1. The persisted mode defaults to `Off` for new and existing users.
2. Android Bubble/Panel uses a real `TYPE_APPLICATION_OVERLAY` window over other apps after explicit special-access approval.
3. Android keeps a user-visible, stoppable `specialUse` foreground service active while Bubble/Panel is enabled, including when no session currently needs attention.
4. Desktop uses a separate mini window that is always-on-top where supported and explicitly degrades on Wayland where global topmost cannot be guaranteed.
5. iOS uses the same Bubble/Panel presentation inside CodeWalk because external overlays are unavailable.
6. Only root sessions appear in the count, primary state, and panel list.
7. Priority is deterministic: error → pending interaction → completed → delayed → receiving → active.
8. Multiple sessions produce one primary state plus a total count; Panel lists the ordered sessions.
9. A busy session becomes `delayed` after five minutes of observable busy time, excluding intervals where monitoring is paused by data saver or unavailable transport.
10. Completed sessions remain until the user opens or explicitly dismisses them.
11. Panel shows the real final assistant response, separately bounded for display and speech.
12. Read-aloud runs only after an explicit user action and honors native, Edge, or OpenAI-compatible configuration.
13. Navigation resolves the exact `(serverId, directory, sessionId)` tuple.
14. OAuth/Tailscale after process death preserve the last valid snapshot and show a reopen requirement; background code must not overwrite it with a transport error.
15. Cellular data saver leaves the host and last snapshot visible while suppressing automatic background network work and pausing the delayed timer.
16. Manual Open/Read actions may perform one bounded fetch and cloud TTS on cellular, with a visible data-use indication.

## Context and Constraints

### Repository baseline

- Repository: `verseles/codewalk`
- Baseline when this plan was written: `main`, CodeWalk `1.175.0+1783801279`
- Dart SDK constraint: `^3.8.1`
- Android namespace: `com.verseles.codewalk`
- Java/Kotlin target: 17
- Android NDK: `28.2.13676358`
- Current relevant dependencies:
  - `dio: ^5.9.2`
  - `shared_preferences: ^2.5.5`
  - `flutter_secure_storage: ^10.2.0`
  - `connectivity_plus: ^6.1.5`
  - `flutter_tts: ^4.2.5`
  - `flutter_local_notifications: ^21.0.0`
  - `audioplayers: ^6.6.0`
  - `tray_manager: ^0.5.1`
  - `window_manager: ^0.5.1`
  - `workmanager: ^0.9.0+3`
  - `crypto: ^3.0.6` provides hashes only; it does not provide the required authenticated encryption.
- Add `desktop_multi_window: ^0.3.0` only after the desktop compatibility gate passes.
- Add `cryptography: ^2.7.0` for AES-256-GCM after verifying dependency resolution with the current Flutter/Dart toolchain. Lock the resolved version in `pubspec.lock`.
- Do not add `flutter_overlay_window`, `system_alert_window`, `flutter_screen_overlay`, `overlay_pop_up`, `window_manager_plus`, `multi_window`, `bitsdojo_window`, or an AccessibilityService.

### Existing attention and navigation

- `lib/presentation/providers/chat_provider_types_part.dart` defines `SessionAttentionState` and existing primary priority.
- `lib/presentation/providers/chat_provider/chat_provider_session_attention_ops.dart` owns current/inactive attention readers, unread completion, aggregate count/kind, and attention clearing.
- `lib/presentation/pages/chat_page/chat_page_scaffold.dart` builds recent root-session entries and indicators.
- `lib/presentation/pages/chat_page/chat_page_workspace_controller.dart` performs cross-project context switching.
- `ChatProvider.selectSession()` clears attention and notifications, restores cache, persists selection, and hydrates.
- Existing foreground completion suppression is root-aware, but active/error/pending background counts are not universally root-filtered.
- Existing aggregation is primarily scoped to the current context; the feature needs a root-only aggregate across every cached/open context of the active server.

### Existing background behavior

- `lib/presentation/services/android_background_alert_worker.dart` reconstructs active-server plain/Basic transport, polls status/session/permission/question, and emits notifications.
- `lib/presentation/services/android_background_alert_logic.dart` contains the pure planner and background snapshot schema.
- Existing worker notification payload omits `directory` even though `NotificationTapPayload` supports it.
- Existing worker does not restore OAuth or Tailscale.
- Existing foreground monitor service is `android/app/src/main/kotlin/com/verseles/codewalk/CodeWalkForegroundService.kt`.
- Existing foreground service lifecycle is temporary and tied to active-response monitoring. Do not repurpose it as the new persistent overlay host.
- Existing `BEHAVIOR.md` contract suppresses all Android automatic background network checks while cellular data saver is active.

### Existing TTS architecture

- `lib/presentation/services/read_aloud_service.dart` owns current read-aloud orchestration.
- `lib/presentation/services/tts/tts_backend.dart` defines backend contracts and playback modes.
- `lib/presentation/services/tts/native_tts_backend.dart` wraps `flutter_tts`.
- `lib/presentation/services/tts/edge_experimental_tts_backend.dart` implements experimental direct Edge synthesis under ADR-047.
- `lib/presentation/services/tts/openai_compatible_tts_backend.dart` implements OpenAI-compatible synthesis.
- `lib/presentation/services/tts/generated_tts_audio_player.dart` plays generated audio through `audioplayers`.
- `lib/presentation/services/tts/read_aloud_text_extractor.dart` produces speech-safe text.
- `lib/core/auth/tts_api_key_storage.dart` is the only accepted persistence location for cloud TTS keys.
- ADR-046/ADR-047 require native TTS to remain default, secrets to remain in secure storage, and cloud text disclosure to stay explicit.

### Existing ADR constraints

- ADR-003 makes realtime authoritative, keeps mobile background behavior platform-aware, and prevents full payload hydration for non-current sessions.
- ADR-023 requires official OpenCode contract-first behavior.
- Official local anchors permit `/global/event`, `/session/status`, `/session`, and directory-scoped `/session/:id/message`.
- This feature requires a narrowly documented ADR-003 exception: after a root-session completion signal, fetch only the bounded message window needed to resolve the final completed assistant response.
- No OpenCode endpoint, event schema, lifecycle semantic, or server behavior may be invented.

### Platform constraints

- Android API 26+ overlays use `TYPE_APPLICATION_OVERLAY` and special access `SYSTEM_ALERT_WINDOW`.
- Android 14 requires an accurate foreground-service type and matching permission.
- The overlay service must use `specialUse` with a precise subtype description.
- Android 15 generally requires an already-visible overlay for the SAW background-start exemption. Start the service and attach the initial overlay while CodeWalk is visibly foregrounded after user consent.
- Android force-stop and FGS Task Manager stop cannot be bypassed. Do not promise restart until the user opens CodeWalk again.
- iOS does not allow arbitrary cross-app overlays.
- `window_manager` controls only the current desktop window.
- `desktop_multi_window` creates separate Flutter engines/isolate state and requires per-platform plugin registration and IPC.
- Wayland does not provide a portable guarantee for global always-on-top, absolute placement, or unconditional foreground activation.

## Decisions (Resolved)

1. Track only sessions belonging to the currently active server in the first release. Store `serverId` in every record and hide snapshots from inactive servers until that server becomes active again.
2. Aggregate every cached/open project context for the active server, not only the visible context.
3. Enforce root-only classification before any state, count, panel row, notification, delayed timer, text fetch, or TTS job is created.
4. Keep the new persisted overlay mode separate from `androidBackgroundAlertsEnabled`; the latter currently defaults to true and must not implicitly enable privileged UI.
5. Use a dedicated `SessionOverlayService` on Android. Keep `CodeWalkForegroundService` unchanged for temporary `dataSync` monitoring.
6. Use a dedicated service-owned Flutter engine and `FlutterView` for Android overlay rendering. Kotlin owns service, permission, notification, `WindowManager`, bounds, drag, and engine lifecycle. Dart owns attention coordination, shared UI, bounded message fetch, secure snapshot access, and configured TTS.
7. Register only the plugins required by the service engine. Do not blindly register every Activity-oriented plugin. Required capabilities are shared preferences, secure storage, path provider/application files, flutter_tts, and audioplayers. Pure-Dart Dio/networking needs no Android plugin.
8. Use the main engine as the authoritative producer while it is alive for every transport, including OAuth and Tailscale.
9. Permit the service engine to perform fallback monitoring only for plain/Basic profiles. After process death with OAuth/Tailscale, freeze the last valid snapshot and require reopening CodeWalk.
10. Use global SSE as the preferred service-engine signal when automatic background networking is allowed. Use bounded degraded polling only when SSE is unavailable. WorkManager remains notification fallback, not the live overlay event bus.
11. Keep the Android service alive while mode is Bubble/Panel, even with no attention items. Hide the overlay window when no item exists but retain the persistent notification and host engine.
12. Treat the service as background for data-saver policy even though it is an Android foreground service. An FGS must never bypass `CellularDataSaverService` semantics.
13. Separate overlay-host lifecycle from network-monitor lifecycle. Data saver may stop SSE/polling without stopping the overlay host or its notification.
14. Compute delayed state from accumulated observable busy duration, not wall-clock age. Paused/unobservable intervals add zero duration.
15. Store display text and speech text separately. `displayText` preserves the sanitized final response for rendering; `speechText` uses `ReadAloudTextExtractor`.
16. Cap `displayText` at 4,000 Unicode scalar values and `speechText` at 32,000 Unicode scalar values. Persist `displayTruncated` and `speechTruncated` flags and render a truncation indication.
17. Persist response content only in an encrypted, versioned, atomic snapshot store. Do not reuse the plaintext generic chat cache as the overlay protocol.
18. Completed snapshots do not expire by time. They remain until opened, dismissed, session/profile deletion, app reset, or explicit secure-store recovery cleanup after corruption. Persist only one completion snapshot per root session and replace it when a newer final assistant message completes.
19. Persist a dismissal tombstone keyed by `(serverId, directory, sessionId, assistantMessageId)` so the same completion cannot reappear after worker/service reconciliation.
20. Never speak automatically. Read-aloud requires a user press.
21. Under cellular data saver, explicit Open/Read remains allowed. If Read requires a fetch or cloud TTS, display a concise data-use confirmation/indicator and record an interactive burst through existing data-saver semantics.
22. Use `desktop_multi_window 0.3.0` behind a CodeWalk-owned abstraction if and only if the mandatory prototype passes with current `window_manager`, `tray_manager`, TTS ownership, Windows, macOS, X11, and Wayland behavior.
23. Desktop main engine remains authoritative for state and TTS. Child window never reads API keys, performs network fetches, owns ChatProvider, or plays audio independently.
24. iOS renders the shared widget in CodeWalk’s ChatPage stack and uses existing notifications in background.
25. Do not add automatic boot resurrection in the first release.
26. Do not treat a stale snapshot as an error. Render explicit `Paused`, `Reopen CodeWalk`, or `Last updated` status according to the reason updates are unavailable.

## Data Model

Create the following pure-Dart types under `lib/domain/entities/session_attention_overlay/` or an equivalently focused domain directory.

### `SessionAttentionPresentation`

```dart
enum SessionAttentionPresentation {
  off,
  bubble,
  panel,
}
```

Persist the values `off`, `bubble`, and `panel`. Missing and unknown values decode to `off`.

### `SessionAttentionKind`

```dart
enum SessionAttentionKind {
  error,
  pendingInteraction,
  completed,
  delayed,
  receiving,
  active,
}
```

The declaration order is not the priority contract. Add an explicit priority mapper and test it.

### `SessionAttentionIdentity`

```text
serverId
directory
sessionId
```

Normalize directory using the same project/scope rules used by ChatProvider. Never key durable attention by session ID alone.

### `SessionAttentionItem`

Required fields:

```text
schemaVersion
revision
identity
title
projectLabel
kind
startedAtEpochMs
lastObservedAtEpochMs
observableBusyElapsedMs
assistantMessageId
displayText
speechText
displayTruncated
speechTruncated
completedAtEpochMs
opened
dismissed
transportCapability
pauseReason
contentDigest
```

### `SessionAttentionSummary`

Required fields:

```text
schemaVersion
revision
activeServerId
primaryItem
orderedItems
totalCount
generatedAtEpochMs
monitoringPaused
pauseReason
```

Sort items by priority, then newest meaningful transition, then stable identity.

### `TransportCapability`

```dart
enum SessionAttentionTransportCapability {
  live,
  backgroundPlainOrBasic,
  reopenRequired,
}
```

### `MonitoringPauseReason`

Include at minimum:

```text
none
cellularDataSaver
oauthReopenRequired
tailscaleReopenRequired
offline
permissionRevoked
serviceStopped
```

## Encrypted Snapshot Store

Create `lib/data/session_attention/session_attention_snapshot_store.dart` with a pure interface and IO implementation.

### Storage envelope

Use this versioned envelope:

```text
schemaVersion: 1
keyVersion: 1
nonce: base64
ciphertext: base64
mac: base64
updatedAtEpochMs
```

Use AES-256-GCM:

- 32-byte random key.
- 12-byte random nonce per write.
- Never reuse nonce/key pairs.
- Store the key through `flutter_secure_storage` under `codewalk.session_attention.snapshot.key.v1`.
- Store ciphertext under the platform application-support directory.
- Write to a temporary sibling file, flush, then atomically rename.
- Keep no plaintext backup.
- Serialize only the overlay snapshot schema, not full ChatMessage objects.
- On authentication failure/corruption, delete the unreadable ciphertext, preserve settings, expose a recoverable empty-state warning, and never log ciphertext or plaintext.
- Use a single-writer coordinator per process. Child desktop window receives immutable DTOs through IPC and never opens the store.

Create a separate non-secret dismissal index inside the encrypted payload. Do not put dismissed assistant message IDs in SharedPreferences.

## Execution Plan (Synthesized)

### Step 1 — Create the architecture decision and validate mandatory prototypes

**Allowed documentation:** `ADR.md` through the ADR workflow only.

**Actions:**

1. Create an ADR for cross-platform floating session attention covering:
   - privileged Android overlay permission;
   - persistent `specialUse` FGS;
   - Android service Flutter engine;
   - encrypted response snapshots;
   - direct configured TTS;
   - desktop secondary engine/window;
   - data-saver separation of host and network;
   - OAuth/Tailscale frozen fallback;
   - Wayland and iOS limitations;
   - Play Console declaration and rollback switch.
2. Amend ADR-003 with the bounded root-session completion fetch exception. State that non-current sessions still do not receive continuous full-message hydration, diffs, todos, tool arguments, or partial response payloads.
3. Record ADR-023 compatibility: use only official `/global/event`, `/session/status`, `/session`, and directory-scoped `/session/:id/message` behavior.
4. Build a throwaway, non-product Android prototype proving all of the following on API 34, 35, and 36:
   - request `SYSTEM_ALERT_WINDOW` from visible CodeWalk UI;
   - start a `specialUse` FGS while the Activity is visible;
   - attach/detach a `TYPE_APPLICATION_OVERLAY` FlutterView;
   - render Bubble and Panel sizes;
   - survive Activity destruction;
   - restart service with null intent;
   - stop through notification action;
   - recover cleanly when permission is revoked;
   - initialize only required plugins in the service engine;
   - run native, Edge, and fake OpenAI-compatible TTS in the service engine.
5. Build a throwaway desktop prototype with `desktop_multi_window: ^0.3.0` proving:
   - one reusable child window;
   - IPC in both directions;
   - `window_manager` registered in child engine;
   - passive updates do not steal focus;
   - always-on-top on Windows, macOS, and X11;
   - explicit degraded capability on Wayland;
   - tray close/quit semantics remain correct;
   - child close does not terminate the process;
   - main engine owns TTS.
6. Remove throwaway prototype code after documenting results. Preserve only reusable platform adapters that pass production standards.
7. If Android service-engine plugin registration, API 35/36 lifecycle, or the tri-platform desktop prototype fails, mark implementation blocked and report the failed invariant. Do not replace the architecture without an ADR/user decision.

**User-approved Step 1 exception (2026-07-12):** Hosted API 34–36 emulator execution is not a blocking Step 1 gate. GitHub's standard Linux runners exposed KVM inconsistently, while standard Intel macOS runners started the emulator but never completed guest boot. The prototype workflow must still compile the Android app, service-engine integration, and instrumentation APK (`assembleDebugAndroidTest`), plus all desktop targets. This exception permits broad implementation to proceed; it does not claim that API 34–36 runtime behavior passed, and it does not waive the Step 9 runtime validation required before release.

**Validation gate:** ADR accepted; Android app and instrumentation sources compile; the desktop prototype passes on all three targets; dependency resolution passes; no existing build/test regression. Android API 34–36 runtime validation remains deferred to Step 9 under the explicit exception above.

**Execution result (2026-07-12):** Step 1 passed under the approved exception. ADR-049 is accepted, ADR-003 contains the bounded root-session completion-fetch exception, `cryptography 2.9.0` and `desktop_multi_window 0.3.0` resolve, and GitHub Actions run `29195855387` passed the Android debug app, Android instrumentation APK, Linux, Windows, and macOS compile gates. API 34–36 runtime behavior was not validated and remains explicitly release blocking in Step 9.

### Step 2 — Add persisted settings and capability state

**Files:**

- `lib/domain/entities/experience_settings.dart`
- `lib/presentation/providers/settings_provider.dart`
- `lib/presentation/pages/settings/sections/behavior_settings_section.dart` or the existing notifications section selected according to current settings ownership
- localization ARB/generated files through the project-safe translation workflow
- settings/domain/provider tests

**Actions:**

1. Add `SessionAttentionPresentation` to `ExperienceSettings` constructor, fields, defaults, equality, `copyWith`, JSON encode/decode, and migration tests.
2. Default new settings and missing persisted values to `off`.
3. Do not change `androidBackgroundAlertsEnabled` defaults or semantics.
4. Add `SettingsProvider` getter and async setter. The setter must persist only after native/desktop host activation succeeds. If activation or permission fails, persist `off` and surface the error.
5. Add runtime capability state:
   - Android overlay supported/permission granted/service running;
   - desktop mini-window supported/topmost capability;
   - iOS in-app only;
   - unsupported/web hidden or disabled with explanation.
6. Add settings controls for Off/Bubble/Panel, permission status, open system settings, stop host, and privacy/data-use disclosure.
7. When Android user selects Bubble/Panel:
   - show privacy/FGS/cloud TTS disclosure;
   - request special access by opening `ACTION_MANAGE_OVERLAY_PERMISSION` for the package;
   - resume and re-check `Settings.canDrawOverlays()`;
   - start service and attach initial overlay while Activity is visible;
   - persist selected mode only after success.
8. When mode changes to Off:
   - stop TTS;
   - stop overlay service/mini window;
   - detach UI;
   - retain completed snapshots so re-enabling restores them.
9. Add a visible warning if the user selects Edge/OpenAI-compatible TTS: response text may be sent to the configured third party only after pressing Read.

**Validation gate:** codec/migration/provider/settings widget tests pass; existing users remain Off; background-alert toggle remains independent.

### Step 3 — Implement canonical root-only aggregation

**Files:**

- new domain entities listed above
- `lib/presentation/providers/chat_provider_types_part.dart`
- `lib/presentation/providers/chat_provider/chat_provider_session_attention_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`
- focused provider tests

**Actions:**

1. Add a read-only provider API that enumerates attention candidates across all cached/open contexts for the active server.
2. Resolve parent/root metadata before emitting any candidate.
3. Exclude every child/subagent session from active, receiving, delayed, pending, error, completion, count, and panel output.
4. Exclude the currently visible root session unless it has a pending interaction/error that must remain globally actionable; document and test this exception if existing attention behavior requires it.
5. Emit immutable root candidate DTOs containing full identity, title/project, status, timing, and available completion message identity.
6. Keep existing recent-session and notification behavior intact.
7. Create one explicit priority function and reuse it in foreground aggregate, background planner, Bubble, Panel, desktop, and Android service.
8. Generate monotonically increasing revisions. Consumers must reject lower/equal revisions unless the payload is a requested full resynchronization with a new generation.

**Validation gate:** provider tests prove root-only behavior for every state, cross-context aggregation, active-server filtering, stable ordering, and revision rejection.

### Step 4 — Implement observable delayed time and data-saver pause semantics

**Files:**

- new attention coordinator/repository
- `lib/presentation/services/cellular_data_saver_service.dart`
- Android background logic/worker
- behavior/unit tests

**Actions:**

1. Track `observableBusyElapsedMs` per identity.
2. Advance it only between two valid observations when monitoring was permitted for the entire interval.
3. Do not derive delay from `DateTime.now() - session.updatedAt` alone.
4. Set `delayed` at 300,000 observable milliseconds.
5. Clear delayed state when a new status/event/message observation arrives, while preserving total active duration separately if needed for UI.
6. When cellular data saver is active and CodeWalk is backgrounded:
   - stop service-engine SSE;
   - stop automatic service-engine polling;
   - unregister/suppress worker automatic probes according to current behavior;
   - keep overlay host, notification, and last snapshot visible;
   - set `monitoringPaused=true` and reason `cellularDataSaver`;
   - add zero delayed elapsed time.
7. Do not treat Android FGS lifecycle as app foreground. Use actual main Activity/app lifecycle persisted through an explicit host signal. After process restart, default to background until Activity reports visible.
8. Standard cellular saver while main app is visible uses the existing one-minute automatic window.
9. Aggressive saver while main app is visible refreshes only the visible session and visible interactions at the existing 30-second cadence; out-of-focus overlay entries stay frozen.
10. On Wi-Fi/non-cellular, saver setting has no effect.
11. On transition to Wi-Fi or saver Off, run one generation-guarded reconciliation and resume timing only after a valid observation.
12. Manual Open/Read records `noteExplicitUserAction`. Read may perform one bounded final-message fetch and cloud TTS, with visible data-use feedback. Dismiss/collapse/drag performs no network work.

**Validation gate:** deterministic fake-clock tests prove no false delayed state during paused intervals, correct five-minute accumulation, transition reconciliation, and no automatic cellular background networking.

### Step 5 — Implement encrypted completion snapshots

**Files:**

- new snapshot store/interface/codec
- secure key adapter
- injection container
- unit tests

**Actions:**

1. Add `cryptography` dependency and AES-256-GCM codec.
2. Implement the versioned atomic store exactly as specified above.
3. Normalize identity before every read/write.
4. Persist at most one current completion per root session plus dismissal tombstone for the current assistant message.
5. Generate `displayText` from final assistant text parts while preserving readable content for markdown rendering. Remove secret/tool/reasoning payloads and cap at 4,000 scalars.
6. Generate `speechText` through `ReadAloudTextExtractor`, cap at 32,000 scalars, and persist truncation flags.
7. Store `assistantMessageId`, completion time, digest, identity, and text. Do not store full ChatMessage JSON.
8. Delete snapshot/tombstone on session deletion, profile deletion, app reset, or successful open/dismiss as defined below.
9. Preserve completed records indefinitely until open/dismiss; bound storage by one item per session and bounded text sizes rather than time expiry.
10. Fail closed on key/codec errors. Do not fall back to plaintext.

**Validation gate:** encryption roundtrip, nonce uniqueness, tamper failure, atomic-write recovery, no plaintext grep, identity isolation, truncation, tombstone, deletion, and corruption tests pass.

### Step 6 — Resolve actual final responses without broad hydration

**Files:**

- chat repository/use case/datasource seams only if a bounded query helper is missing
- attention coordinator
- Android service/background coordinator
- ADR-003 tests/contract tests

**Actions:**

1. On root-session completion/idle, request a bounded directory-scoped message window using the official endpoint.
2. Start with `limit=20`. Do not fetch the full transcript automatically.
3. Select the latest completed assistant message whose session/identity matches the candidate.
4. If the event precedes message availability, retry at 500 ms, 1.5 s, and 3 s, then persist a completed item without text and expose a manual Retry/Open action.
5. Deduplicate by `(identity, assistantMessageId, contentDigest)`.
6. Do not fetch partial response text for non-current sessions. `receiving` means status/event activity only.
7. Do not mutate active ChatProvider message lists from this fetch path.
8. Main engine executes this path for all active transports while alive.
9. Service engine executes this path only for plain/Basic after process death.
10. OAuth/Tailscale service fallback must not issue HTTP requests, persist transport errors, clear old text, or advance delayed timers. Mark `reopenRequired` and retain last valid item.

**Validation gate:** exact-response selection, bounded retries, no broad hydration, no provider mutation, auth capability matrix, directory scoping, and deduplication tests pass.

### Step 7 — Refactor TTS into reusable executor/jobs

**Files:**

- `lib/presentation/services/read_aloud_service.dart`
- `lib/presentation/services/tts/*`
- `lib/core/auth/tts_api_key_storage.dart`
- new `TtsConfiguration`, `SpeechJob`, and `TtsExecutor`
- DI and tests

**Actions:**

1. Extract immutable non-secret `TtsConfiguration` from `ExperienceSettings`.
2. Create `SpeechJob` with snapshot ID, identity, text digest, bounded speech text, configuration revision, and job ID.
3. Create one executor contract supporting play, stop, completion, error, and current job state.
4. Keep current ReadAloudService as the main-engine UI controller over the executor.
5. Android service engine constructs its own executor with explicit plugin registration.
6. Resolve OpenAI-compatible API key directly from secure storage inside the owning engine immediately before synthesis. Never send the key through IPC, snapshot, SharedPreferences, notification, intent, or log.
7. Preserve native default and Edge experimental semantics from ADR-047.
8. Never start speech automatically.
9. Enforce one active speech job per process/host. New Play stops the previous job through existing service semantics.
10. Opening/dismissing the spoken snapshot stops its job.
11. Under data saver, native speech over already-stored text remains offline. Cloud speech or a required text fetch proceeds only after explicit Read and visible data-use indication.
12. If text is unavailable because OAuth/Tailscale requires reopen, disable Read and show the reopen action.

**Validation gate:** native/Edge/OpenAI fake executor tests, secure-key boundary, cancellation, repeated taps, truncation, data-saver manual burst, and error recovery pass.

### Step 8 — Build the shared Bubble and Panel UI

**Files:**

- new `lib/presentation/widgets/session_attention_overlay/` widgets/controller
- shared theme/localization files
- widget tests

**Actions:**

1. Build a platform-neutral `SessionAttentionOverlay` driven only by `SessionAttentionSummary` and semantic commands.
2. Bubble requirements:
   - minimum 48×48 logical pixels;
   - primary-state icon/color using Material theme semantics, not hard-coded green/error colors;
   - count badge;
   - semantic label containing primary state and total count;
   - tap opens the primary session;
   - explicit expand control/secondary action opens Panel;
   - Android drag position is owned by the native host but reflected in Flutter UI state.
3. Panel requirements:
   - maximum five visible rows before scrolling;
   - project label, session title, state, duration/last-updated, and display preview;
   - completed check clearly recognizable;
   - Paused/Reopen states visually distinct from Error;
   - Open, Read/Stop, Dismiss actions;
   - Collapse and Stop Overlay controls;
   - no token-by-token announcements or focus stealing on passive revisions.
4. Dismiss removes only the selected item/tombstones the assistant message. It does not abort a session or mark ordinary chat content read.
5. Stop Overlay changes mode to Off, stops TTS/host, and preserves completed snapshots for later re-enable.
6. Render truncation indication when either text cap was applied.
7. Meet keyboard, TalkBack/Narrator/VoiceOver/Orca, 48px target, contrast, font scaling, and logical focus-order requirements.

**Validation gate:** widget golden/semantic/interaction tests cover every state, compact/expanded sizes, multiple items, text scaling, long localized strings, and revision changes without focus loss.

### Step 9 — Implement Android overlay host

**Files:**

- `android/app/src/main/AndroidManifest.xml`
- new Kotlin package under `android/app/src/main/kotlin/com/verseles/codewalk/overlay/`
- `MainActivity.kt` permission/activation bridge
- new Dart service entrypoint and platform adapter
- Android/JVM/instrumentation tests

**Manifest additions:**

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
```

Declare a separate, non-exported service:

```xml
<service
    android:name=".overlay.SessionOverlayService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="specialUse">
    <property
        android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
        android:value="User-enabled persistent cross-app overlay showing CodeWalk session status and response controls" />
</service>
```

**Actions:**

1. Keep existing `CodeWalkForegroundService` and `FOREGROUND_SERVICE_DATA_SYNC` unchanged.
2. Implement permission checks with `Settings.canDrawOverlays()` and foreground-only `ACTION_MANAGE_OVERLAY_PERMISSION` flow.
3. Implement `SessionOverlayService` with a distinct notification channel and stable notification ID.
4. Notification must include visible Open CodeWalk and Stop Overlay actions.
5. Return `START_STICKY`, tolerate null restart intents, reload mode/snapshot, and fail closed if permission is absent.
6. Do not auto-restart after reboot. Do not bypass force-stop or Task Manager stop.
7. Own a dedicated `FlutterEngine`, Dart entrypoint, narrow plugin registrant, MethodChannel, and FlutterView.
8. Attach the FlutterView through `WindowManager` with `TYPE_APPLICATION_OVERLAY`.
9. Use `FLAG_SECURE`; do not set show-when-locked; hide sensitive text when device is locked.
10. Implement drag and clamp position to current display insets. Persist normalized Bubble/Panel bounds, not raw display IDs.
11. Keep service/engine/notification active while mode is enabled. Remove overlay view when there are no items; reattach without restarting the service when items appear.
12. Keep host lifecycle separate from SSE/polling lifecycle.
13. Main engine pushes full revisioned snapshots while alive.
14. Service engine starts plain/Basic fallback monitoring only when main producer heartbeat is stale, network policy allows, and transport capability permits.
15. Use global SSE first and 30-second degraded status polling only while SSE is unavailable. Do not poll in cellular background saver.
16. Add `serverId`, `directory`, `sessionId`, and snapshot ID to activation PendingIntent.
17. On tap, launch/reuse `MainActivity` with `NEW_TASK | CLEAR_TOP | SINGLE_TOP`, then route the payload through the existing notification/session activation path.
18. If permission is revoked, detach immediately, stop service/TTS, persist mode Off, and notify the main app on next connection.

**Validation gate:** Robolectric/JVM tests plus real/emulated API 34/35/36 instrumentation for permission, attach/detach, service restart, Activity destruction, null intent, notification actions, process kill, Task Manager stop, force-stop behavior, rotation, insets, drag, lock screen, TalkBack, and TTS.

### Step 10 — Implement exact navigation and dismissal

**Files:**

- `lib/presentation/services/notification_service.dart`
- `lib/presentation/services/android_background_alert_logic.dart`
- `lib/presentation/services/android_background_alert_worker.dart`
- `lib/presentation/pages/chat_page.dart` activation handler
- workspace/session controllers
- tests

**Actions:**

1. Extend background signal/snapshot/payload to carry normalized directory and server ID.
2. Fix existing worker notification payload omission of directory.
3. Reject payloads whose server ID is not currently display-eligible. Because first release displays active-server items only, ask the main app to activate the recorded server only if the snapshot was already visible and the profile still exists; otherwise show unavailable feedback.
4. Switch directory/project before selecting session.
5. Generation-guard the whole activation so repeated taps or stale window commands cannot revert a newer navigation.
6. After successful selection:
   - mark the matching snapshot opened;
   - delete response text/tombstone as required;
   - dismiss matching notifications;
   - stop matching TTS;
   - publish a new summary revision.
7. Dismiss command:
   - write dismissal tombstone;
   - remove item from presentation;
   - stop matching TTS;
   - do not navigate, abort session, clear unrelated attention, or alter OpenCode data.

**Validation gate:** cross-project exact navigation, stale/deleted target, inactive profile, repeated taps, generation races, per-item dismissal, and notification cleanup tests pass.

### Step 11 — Implement desktop mini window

**Files:**

- `pubspec.yaml` / `pubspec.lock`
- new `SessionMiniWindowHost` abstraction and `desktop_multi_window` adapter
- desktop runner plugin registration on Windows/macOS/Linux
- existing tray/window activation services
- child Dart entrypoint
- platform/integration tests

**Actions:**

1. Add `desktop_multi_window: ^0.3.0` only after Step 1 passes.
2. Hide package-specific window IDs and channels behind `SessionMiniWindowHost`.
3. Create exactly one reusable child engine/window. Reuse/show it instead of creating duplicates.
4. Pass only initial role/version arguments at creation. Exchange immutable full snapshots and semantic commands through versioned IPC.
5. Child rejects stale revisions and requests a full snapshot after creation, reconnect, or revision gap.
6. Register `window_manager` and only UI-required plugins in the child engine.
7. Child must not construct ChatProvider, resolve credentials, access TTS keys, fetch network data, or play audio.
8. Main engine owns aggregation, encrypted store, navigation, and all TTS.
9. Configure Bubble as a compact separate window and Panel as a larger scrollable window. Persist bounds and selected presentation mode.
10. Passive updates must not focus/activate the child.
11. Windows: topmost without activation; deliberate taskbar/tool-window behavior; test minimize/restore ownership.
12. macOS: floating panel semantics, passive non-activation, intentional key focus for controls, preserve Dock/tray lifecycle.
13. Linux/X11: apply topmost/placement hints best effort.
14. Linux/Wayland: expose `topmostGuaranteed=false`, keep the mini window usable, label capability accurately, and preserve tray recovery. Do not pretend the compositor accepted topmost.
15. Clicking Open activates/restores the main window, then sends the exact navigation command. If OS focus transfer is denied, keep the target queued and show feedback.
16. Closing child hides it without quitting the app. Tray Quit closes child and main process.

**Validation gate:** Windows/macOS/X11/Wayland tests for one-window reuse, IPC, stale revisions, topmost capability, focus, taskbar/Dock/tray, close/quit, main activation, TTS ownership, screen readers, and process restart.

### Step 12 — Implement iOS/in-app host

**Files:**

- ChatPage/scaffold stack host
- shared overlay controller/widget
- iOS capability/settings copy
- widget tests

**Actions:**

1. Host `SessionAttentionOverlay` in the persistent ChatPage stack.
2. Bubble and Panel use the same summaries/actions as Android/desktop.
3. Do not request unsupported platform privileges.
4. While app is backgrounded, rely on existing notifications. Do not claim external visibility.
5. On return, run one guarded reconciliation and update the in-app overlay.

**Validation gate:** iOS-targeted/widget tests prove mode persistence, in-app visibility, background limitation copy, exact navigation, TTS, and no unsupported channel calls.

### Step 13 — Complete integration, documentation, and distribution readiness

**Documentation ownership:**

- Update `BEHAVIOR.md` only after behavior is verified.
- Update `ADR.md` through `adrkeeper`/ADR workflow.
- Update `CODEBASE.md` through `codemapper` because new entrypoints/services/platform hosts alter structure.
- Update README/privacy/setup documentation through the documentation flow.

**Actions:**

1. Document Off/Bubble/Panel semantics, root-only scope, active-server scope, retention, delayed timing, navigation, and TTS.
2. Document Android permission, persistent notification, stop behavior, force-stop/reboot limits, and API support.
3. Document data saver behavior exactly:
   - service/host remains;
   - automatic cellular background networking stops;
   - delayed elapsed pauses;
   - last snapshot shows paused/stale state;
   - manual Open/Read may use data after explicit action;
   - Wi-Fi resumes with one reconciliation.
4. Document OAuth/Tailscale reopen-required fallback.
5. Document Windows/macOS/X11 capability and Wayland limitations.
6. Add privacy copy for response text at rest and cloud TTS disclosure.
7. Prepare Google Play `specialUse` FGS declaration, exact feature description, user-benefit explanation, stop controls, and demonstration video. Do not claim Play approval until received.
8. Update release notes only when the feature has passed all platform gates.

## Settings UX Contract

The settings surface must implement this exact behavior:

1. Off is selected by default.
2. Selecting Bubble/Panel on Android first shows disclosure, then opens special-access settings.
3. Returning without permission keeps Off and shows a non-blocking explanation.
4. Granting permission starts the service while CodeWalk is visible and only then persists the mode.
5. Revocation immediately disables the host.
6. Stop from notification and Stop from Settings both persist Off.
7. Desktop mode starts/reuses the child window; startup failure reverts to Off.
8. iOS mode enables in-app UI and explicitly says it cannot appear over other apps.
9. Web/unsupported targets do not expose a nonfunctional selector.
10. Cloud TTS disclosure appears without duplicating or weakening existing speech settings privacy text.

## Attention State Contract

### Active

- Root session is `busy` or `retry` and no stronger state applies.
- Show active duration and project/session title.

### Receiving

- Main engine observed response activity for the root session.
- Do not display partial assistant text for non-current sessions.
- Receiving resets delayed elapsed.

### Delayed

- Root session accumulated 300,000 ms of observable busy time without a meaningful update.
- It is a warning, not an error.
- Paused data-saver/offline/reopen-required intervals contribute zero time.

### Completed

- Final assistant response has been resolved or completion is confirmed with text temporarily unavailable.
- Persist until open/dismiss.
- Check icon is semantically recognizable and theme-derived.

### Pending interaction

- Permission/question belongs to the root session or can be mapped to it.
- Panel can open the session; it does not answer directly in the first release.

### Error

- Server-authoritative session error signal exists for the root session.
- Offline server is not automatically treated as session error, preserving existing behavior.

### Paused/Reopen required

- Presentation modifier, not a stronger attention kind.
- Preserve last known kind/text and show why updates are unavailable.

## Data Saver Contract

### Cellular background

- Keep Android service, notification, Bubble/Panel host, encrypted snapshot, and desktop/iOS equivalents where applicable.
- Stop automatic SSE and polling.
- Suppress worker probes according to existing behavior.
- Pause delayed accumulation.
- Show `Data saver: updates paused` and last-updated time.
- Do not mark items error/delayed due solely to intentional staleness.

### Cellular foreground Standard

- Permit automatic foreground reconciliation only through the existing one-minute cadence.
- Overlay entries update from allowed observations.

### Cellular foreground Aggressive

- Refresh only visible session and visible pending interactions on the existing 30-second cadence.
- Freeze out-of-focus entries and delayed elapsed unless the user explicitly acts.

### Manual Open/Read

- Opening is explicit and may reconcile the selected identity.
- Read may make one bounded final-response fetch and invoke configured cloud TTS.
- Show a concise data-use indication before/while the network action occurs.
- Call existing interactive-burst semantics.
- Do not start background continuous monitoring as a side effect.

### Wi-Fi/non-cellular resume

- Run one generation-guarded reconciliation.
- Resume SSE/monitoring policy.
- Resume delayed accumulation only after first valid observation.

## Risks & Mitigations

### Critical — Google Play rejects `specialUse`/SAW use

**Mitigation:** Explicit opt-in, perceptible ongoing notification, Stop action, no AccessibilityService, accurate subtype, documented user benefit, demonstration video, and remote/compile-time rollback to Off/in-app behavior if distribution blocks the privileged host.

### Critical — Sensitive response text leaks across apps or storage

**Mitigation:** Default Off, disclosure, `FLAG_SECURE`, no lock-screen display, AES-256-GCM store, bounded text, no plaintext payloads/logs/intents/notifications, immediate cleanup on open/dismiss/delete/reset.

### Critical — Wrong session/project opens

**Mitigation:** Mandatory `(serverId, directory, sessionId)` identity, active-server filter, directory-first navigation, generation guards, and stale-target feedback.

### Critical — OAuth/Tailscale fallback corrupts a valid snapshot

**Mitigation:** Explicit transport capability gate; service performs no network/error write for unsupported transport; preserve last valid encrypted snapshot and require reopen.

### High — Service/worker/main engine duplicate events or overwrite revisions

**Mitigation:** Single canonical coordinator contract, monotonic revision/generation, content digest dedupe, source heartbeat, service fallback only when main producer is stale, full resync on gaps.

### High — Cellular saver is bypassed by FGS

**Mitigation:** Treat FGS as background, separate host/network lifecycles, use persisted actual Activity visibility, hard-stop automatic SSE/polling on saver, fake-clock tests.

### High — Desktop package conflicts with current runner/plugins

**Mitigation:** Mandatory prototype, app-owned host abstraction, one child engine, narrow plugin registration, central TTS/state ownership, block instead of silently replacing package.

### High — TTS sends private text unexpectedly

**Mitigation:** No automatic speech, explicit Read, existing provider privacy disclosure, key remains secure, data-use indication on cellular, one bounded speech job, Stop control.

### High — Response fetch violates ADR-003

**Mitigation:** ADR update; root completion only; `limit=20`; no partial/non-current hydration; no ChatProvider mutation; bounded retries and text-only snapshot.

### Medium — Delayed state is false because monitoring was paused

**Mitigation:** Accumulate only observable elapsed milliseconds; pause intervals add zero; resume only after valid observation.

### Medium — Android/OEM kills service

**Mitigation:** `START_STICKY`, durable settings/snapshot, null-intent recovery, visible notification, honest force-stop/reboot limits, physical OEM testing.

### Medium — Wayland ignores topmost/placement

**Mitigation:** Capability flag, accurate copy, usable normal mini window, tray recovery, no false guarantee.

### Medium — Completed snapshots grow indefinitely

**Mitigation:** One bounded item per root session, replace newer completion, cleanup on open/dismiss/session/profile/reset, encrypted size monitoring. Do not violate confirmed retention with time-based expiry.

## Assumptions to Validate

1. **`desktop_multi_window 0.3.0` resolves with Dart `^3.8.1` and current desktop plugins.**
   - Validation: Step 1 dependency/prototype matrix.
   - If false: mark desktop implementation blocked and request an ADR/user decision. Do not silently adopt a newer unverified multi-window package.
2. **`cryptography ^2.7.0` resolves and supports required AES-GCM on every target.**
   - Validation: dependency resolution and per-platform roundtrip tests.
   - If false: select a maintained Dart AES-GCM implementation through a documented dependency review; never fall back to plaintext or unauthenticated encryption.
3. **Required plugins can register safely in the Android service engine.**
   - Validation: native/Edge/OpenAI TTS plus secure storage/audio prototype on API 34–36.
   - If false: block configured-provider TTS in external Android overlay and escalate. Do not substitute native-only TTS against the confirmed requirement.
4. **Main engine can remain authoritative while alive for OAuth/Tailscale.**
   - Validation: background Activity-destruction and service-heartbeat tests.
   - If false: preserve/freeze snapshot and require reopen; do not port interactive auth silently.
5. **Official bounded message endpoint returns final assistant message after idle with eventual consistency.**
   - Validation: local official OpenCode anchors and integration tests with the supported server version.
   - If false: store completion without text and expose Open/Retry; do not fetch unbounded history.
6. **`FLAG_SECURE` and no lock-screen flags prevent intended Android leakage.**
   - Validation: API 34–36 screenshot/lock-screen/instrumentation checks.
   - If false: hide response text in external overlay and show status-only until a secure presentation can be proven.

## Blockers and Open Questions

None at the product-decision level.

Technical execution is blocked if either mandatory Step 1 prototype fails. Record the exact failed invariant and stop before broad implementation.

## Testing Strategy

### Unit tests

- Settings enum default, unknown fallback, codec, copyWith, provider persistence.
- Root-only candidate classification for active/receiving/delayed/completed/pending/error.
- Cross-context active-server aggregation.
- Explicit priority and stable ordering.
- Observable delayed elapsed with fake clock and paused intervals.
- Revision/generation rejection and full resync.
- Data-saver host/network split.
- Plain/Basic vs OAuth/Tailscale capability matrix.
- Bounded completion fetch, retries, response selection, and dedupe.
- Display/speech extraction and truncation.
- AES-GCM key/nonce/envelope/tamper/atomic recovery.
- Dismiss/open tombstones and cleanup.
- TTS configuration, secure-key boundary, job cancellation, and data-use manual action.

### Flutter widget tests

- Off/no candidate.
- Bubble and Panel every state.
- Primary state plus count and ordered rows.
- Root-only and current-session exclusion behavior.
- Paused/Reopen status.
- Open/Read/Stop/Dismiss/Collapse/Stop Overlay.
- Five visible rows plus scrolling.
- Long response and truncation.
- Compact/desktop/iOS layouts.
- Text scale, 48px targets, keyboard, focus, semantics, contrast.
- Passive revisions do not steal focus or spam announcements.
- Settings permission/disclosure/failure rollback.

### Android JVM/Robolectric/instrumentation

- Manifest/service/notification definitions.
- Permission denied/granted/revoked.
- Visible-Activity service start on API 34–36.
- Activity destruction and service survival.
- Process recreation/null intent.
- Force-stop/Task Manager expected non-recovery.
- Stop notification action.
- Window attach/detach/drag/insets/rotation.
- Lock-screen and screenshot protection.
- Main producer heartbeat/fallback handoff.
- Cellular saver stops network but not host.
- Secure store after restart.
- Basic fallback, OAuth/Tailscale freeze.
- Native/Edge/OpenAI fake TTS and cancellation.
- TalkBack and font scaling.

### Desktop integration/manual matrix

- Windows, macOS, Linux X11, GNOME Wayland, KDE Wayland.
- One child window reuse and no orphan engines.
- IPC revisions and reconnect/full snapshot.
- Always-on-top capability, passive focus, taskbar/Dock/tray.
- Main activation and exact navigation.
- Close/hide/recreate/quit/process restart.
- Main-engine-only TTS.
- Narrator, VoiceOver, Orca.

### Existing regression gates

- Notification payload/routing tests.
- Background alert logic/worker tests.
- Chat provider realtime/project/session-attention tests.
- Chat page/session-list tests.
- Read-aloud/backend/key-storage tests.
- Settings tests.
- `make check` after stable integration.
- Reviewer loop until no judge-approved critical/warning findings remain.
- Android builds and API instrumentation through GitHub Actions when local host architecture is unsupported.

## Execution Handoff

1. Read repository `AGENTS.md`, `BEHAVIOR.md`, ADR-003, ADR-023, ADR-046, ADR-047, official local OpenCode anchors, and this file.
2. Inspect `git status`, latest `AGENT_PLAN_ANCHOR`, its `PLAN_REF` commits, and current remote state. Preserve all user changes.
3. Create a new immutable `plan:` commit with `AGENT_PLAN_ANCHOR` containing this full request, decisions, constraints, risks, and step checklist before implementation.
4. Execute Step 1 as a blocking spike/ADR step, applying its explicit compile-only Android exception. Broad source changes may begin only after the ADR, Android app/instrumentation compilation, desktop prototype gates, and dependency checks pass; API 34–36 runtime validation remains Step 9 and release blocking.
5. Use one `chore(agent): [Step X/Y] ...` progress commit per completed implementation step, with `PLAN_REF` and `PREVIOUS_STEP`.
6. Delegate ADR/CODEBASE/documentation changes to their required subagents.
7. Use focused analysis/tests while iterating; run `make check` at the stable gate.
8. Run reviewers after code/tests stabilize and repeat after accepted corrections.
9. Do not generate a local Android release APK on unsupported ARM64 hosts; use GitHub Actions for release artifacts and instrumentation.
10. Do not release or close issue #98 until every platform gate, documentation update, privacy declaration requirement, and CI check is complete.

## Out of Scope

- Child/subagent sessions in the overlay.
- Simultaneous aggregation across multiple active server profiles.
- Answering permission/question prompts directly from the overlay.
- Aborting or steering a running session from the overlay.
- Displaying partial non-current response text token by token.
- Automatic TTS.
- AccessibilityService.
- Android PiP.
- Notification-bubble substitution for the confirmed SAW overlay.
- Auto-start after reboot in the first release.
- Background OAuth login or Tailscale authentication after process death.
- Full transcript storage or unbounded message fetching.
- Guaranteed Wayland global topmost/placement.
- Web floating-window support.
- OpenCode server/API changes.
- Plaintext response snapshot fallback.

## Definition of Done

- Off/Bubble/Panel persists with Off default and independent background-alert setting.
- Android external overlay is opt-in, stoppable, secure, API 34–36 validated, and Play-declaration ready.
- Android host remains while enabled but performs no automatic cellular background network work under saver.
- Desktop separate mini window passes Windows/macOS/X11/Wayland capability matrix.
- iOS in-app Bubble/Panel works without unsupported privileges.
- Every candidate/count/list is root-only and active-server scoped across known contexts.
- Priority and five-minute observable delayed state are deterministic.
- Completed entries remain until open/dismiss and survive process recreation through encrypted storage.
- Actual bounded display text and separate bounded speech text are correct and secure.
- Configured native/Edge/OpenAI TTS works only on explicit Read and never leaks keys.
- OAuth/Tailscale freeze correctly after process death without overwriting snapshots.
- Exact `(serverId, directory, sessionId)` navigation works and stale targets fail safely.
- Data-saver paused/resume/manual-action behavior matches this plan exactly.
- Existing notification, realtime, session, data-saver, TTS, tray, and first-run behavior remains green.
- ADR.md, BEHAVIOR.md, CODEBASE.md, settings/privacy docs, Play declaration materials, tests, `make check`, reviewers, and CI are complete.
