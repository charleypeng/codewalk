# Android Session Attention Overlay — Authoritative Correction Plan

## Status

**Ready.** The implementation direction is resolved and requires no additional architectural or product decision before execution.

The only diagnostic distinction that must be recorded during baseline validation is whether black output is visible directly on the Android display or only in screenshots, recordings, or remote mirroring. This distinction does not block the code correction: the current Flutter render surface is factually opaque even though the feature requires transparent composition. Production screenshot protection remains mandatory.

## Problem

CodeWalk release `v1.176.0` introduced the Android session-attention Bubble/Panel overlay. The overlay currently presents either:

- a black square around the Bubble; or
- a large black rectangle around the Panel, often covering most of a phone display.

The Android service creates the overlay with `FlutterView(this)` in `android/app/src/main/kotlin/com/verseles/codewalk/overlay/SessionOverlayService.kt`. In Flutter 3.41.5, that constructor creates `FlutterSurfaceView(context)` with opaque rendering. The outer `TYPE_APPLICATION_OVERLAY` window requests `PixelFormat.TRANSLUCENT`, and the Dart `Scaffold` requests a transparent background, but neither setting changes the opacity of the nested `FlutterSurfaceView`. Transparent Flutter pixels therefore composite as a black native surface.

The native windows also use fixed dimensions of `96×96dp` for Bubble and `360×520dp` for Panel. The large Panel surface amplifies the black-rendering defect, does not reserve consistent edge margins on compact displays, and can leave transparent native window area intercepting touches after alpha is corrected.

A separate diagnostic case exists: production overlays use `WindowManager.LayoutParams.FLAG_SECURE`. Android may intentionally render the protected region black in screenshots, recordings, casting, or remote mirroring. `FLAG_SECURE` does not explain a persistent black region observed directly on the device display and must not be removed to make captures appear transparent.

## Objective

Implement and verify an Android overlay that satisfies all of the following:

1. Bubble renders as a circular Material surface with the underlying application visible through every transparent corner.
2. Panel renders as a compact, readable, scrollable Material surface without an opaque black native background.
3. Bubble uses a `96×96dp` native window.
4. Panel uses a `360×240dp` target native window and is capped to the current usable display bounds with a `16dp` margin on every edge.
5. The overlay remains draggable and clamped after presentation changes, rotation, display-size changes, cutout changes, and system-bar inset changes.
6. The dedicated ADR-049 Android foreground service and Flutter engine remain intact.
7. `FLAG_SECURE` remains enabled in every production path.
8. A render failure cannot leave a blank native window intercepting user input indefinitely.
9. Android instrumentation detects a regression where the overlay is attached but its transparent corners render black.
10. The correction passes focused Flutter checks, Android compilation, the full CodeWalk check gate, and Android runtime instrumentation on APIs 34, 35, and 36.

## Context and Constraints

### Project and architecture

- Workspace: CodeWalk, a Flutter client for OpenCode supporting mobile and desktop.
- Flutter version used by the overlay workflow: `3.41.5`.
- Android package namespace: `com.verseles.codewalk`.
- Overlay service package: `com.verseles.codewalk.overlay`.
- ADR-049 requires Android Bubble/Panel to use a dedicated, non-exported, `specialUse` foreground service that owns a narrow overlay-only `FlutterEngine` and `FlutterView`.
- ADR-023 remains unaffected because this correction changes only client-owned rendering and window geometry. It adds no endpoint, schema, event semantic, authentication behavior, or OpenCode contract.
- Bubble/Panel remains explicit opt-in and default-off. Returning the preference to `Off` remains the user-visible rollback.
- Sensitive session content remains protected from screenshots and non-secure displays by `FLAG_SECURE`.
- No new package or dependency is permitted for this correction.
- The change must work on Android API 34, 35, and 36 and preserve desktop and iOS behavior.

### Relevant implementation files

- `android/app/src/main/kotlin/com/verseles/codewalk/overlay/SessionOverlayService.kt`
  - Owns the dedicated engine, `FlutterView`, `TYPE_APPLICATION_OVERLAY` window, dimensions, flags, drag handling, bounds persistence, and service lifecycle.
  - The opaque construction is currently in `attachOrResizeOverlay()`.
- `lib/presentation/services/session_attention/session_overlay_entrypoint.dart`
  - Runs `sessionOverlayAndroidMain()` and builds a transparent `Scaffold` around `SessionAttentionOverlay`.
- `lib/presentation/widgets/session_attention_overlay/session_attention_overlay.dart`
  - Builds the circular Bubble and rounded, scrollable Panel.
- `android/app/src/androidTest/kotlin/com/verseles/codewalk/overlay/SessionOverlayServiceInstrumentedTest.kt`
  - Covers service lifecycle and snapshot attachment but currently does not prove first-frame delivery or transparent pixel composition.
- `test/widget/session_attention_overlay_test.dart`
  - Existing Flutter widget coverage for the shared Bubble/Panel UI; extend it for the new compact Panel constraints.
- `.github/workflows/session-overlay-prototype.yml`
  - Compiles Android and runs instrumentation on API 34–36, but currently runs only through `workflow_dispatch`.
- `BEHAVIOR.md`
  - Documents current implemented behavior only. Update it after the corrected behavior passes validation.
- `ADR.md`, ADR-049 at the `Cross-Platform Attention Surfaces and Secure Background Continuity` section.
  - Read for invariants; do not change it because this correction preserves the accepted architecture.

### Authoritative Flutter embedding evidence

The local Flutter 3.41.5 embedding source establishes the required API:

- `/home/ubuntu/flutter/engine/src/flutter/shell/platform/android/io/flutter/embedding/android/FlutterView.java`
  - `FlutterView(Context)` delegates to `new FlutterSurfaceView(context)` and defaults to opaque rendering.
  - `FlutterView(Context, FlutterSurfaceView)` is the supported, non-deprecated constructor.
- `/home/ubuntu/flutter/engine/src/flutter/shell/platform/android/io/flutter/embedding/android/FlutterSurfaceView.java`
  - `FlutterSurfaceView(Context, boolean renderTransparently)` is public.
  - Passing `true` invokes `holder.setFormat(PixelFormat.TRANSPARENT)` and `setZOrderOnTop(true)`.

## Decisions (Resolved)

1. **Use an explicitly transparent `FlutterSurfaceView`.** Construct `FlutterSurfaceView(serviceContext, true)` and pass it to the non-deprecated `FlutterView(Context, FlutterSurfaceView)` constructor.
2. **Keep the existing native translucent window.** Retain `PixelFormat.TRANSLUCENT`; it is required but insufficient without the transparent child surface.
3. **Keep `FLAG_SECURE` in production.** Do not remove it, place it behind a user setting, or weaken it for ordinary debug usage.
4. **Use a narrowly guarded instrumentation-only capture bypass.** Permit screenshots only when `BuildConfig.DEBUG` is true and an in-process test hook is explicitly enabled before window creation. Reset the hook when the service is destroyed and in every test teardown.
5. **Keep `FlutterSurfaceView`, not `FlutterTextureView`.** The supported transparent SurfaceView path is the smallest correct fix and preserves rendering performance. TextureView is rejected for this implementation because no device evidence currently proves that SurfaceView fails.
6. **Keep Bubble at `96×96dp`.** The existing Bubble needs room for its circular body, badge, and expand control.
7. **Make Panel compact at `360×240dp`.** The current `520dp` height is disproportionate for the requested floating status surface. The existing `Flexible` plus `ListView.builder` provides scrolling for additional sessions.
8. **Reserve a `16dp` usable-display margin.** Calculate dimensions and movement bounds from current window metrics after system-bar and cutout insets.
9. **Top-align Android overlay content.** Replace Android’s vertical centering with top-center alignment so a content-sized Panel does not create an unnecessary transparent touch-intercepting band above it. Preserve centered desktop layout.
10. **Add a five-second first-frame watchdog.** If the newly attached `FlutterView` has not rendered a frame after five seconds, remove only the overlay window. Keep the foreground service and notification alive; allow a later snapshot to attach a fresh view.
11. **Do not alter snapshot, engine, plugin, transport, persistence, foreground-service, or permission architecture.** These systems are outside the rendering defect and already implement ADR-049 boundaries.
12. **Automate the API 34–36 runtime regression.** Run the existing overlay workflow automatically for pull requests touching the overlay host, shared overlay UI, tests, or workflow.

## Why This Plan

- It fixes the exact native layer proven to be opaque rather than attempting another Dart background-color change.
- It uses Flutter’s supported non-deprecated constructor and introduces no dependency or architecture replacement.
- It preserves the privacy contract instead of treating intentionally protected captures as a reason to remove `FLAG_SECURE`.
- It separates visual alpha correctness, first-frame delivery, and geometry into independently testable concerns.
- It reduces Panel obstruction while preserving the larger, scrollable Panel semantics required by the feature.
- It adds a pixel-level regression test capable of distinguishing “view attached” from “transparent overlay actually composed.”
- It keeps the safest user fallback: if a platform or OEM cannot provide the required overlay behavior, Bubble/Panel remains unavailable or can be returned to `Off`; the implementation does not emulate an overlay through unsupported execution.

## Execution Plan (Synthesized)

### Step 1 — Establish baseline evidence without changing behavior

- **Files**: No source changes.
- **Actions**:
  1. Install or run the current debug build on an API 34–36 emulator or physical device with `SYSTEM_ALERT_WINDOW` granted.
  2. Place a brightly colored, non-black application behind CodeWalk’s overlay.
  3. Trigger a non-empty Bubble snapshot and then expand it to Panel.
  4. Record whether black is visible directly on the display.
  5. Separately attempt an ADB screenshot or screen recording and record whether only the capture is black.
  6. Record the approximate black-region dimensions in density-independent pixels. A `96×96dp` square or `360×520dp` rectangle corroborates the native-surface diagnosis.
  7. Save only non-sensitive observations. Do not capture or retain real session content; use synthetic test data.
- **Risk**: Low. Screenshot output can be misleading because production `FLAG_SECURE` intentionally protects the region.
- **Validation**: The execution notes explicitly state `direct display: black/not black` and `secure capture: black/not black` before code changes begin.

### Step 2 — Replace the opaque Flutter render surface

- **File**: `android/app/src/main/kotlin/com/verseles/codewalk/overlay/SessionOverlayService.kt`
- **Actions**:
  1. Add this import:

     ```kotlin
     import io.flutter.embedding.android.FlutterSurfaceView
     ```

  2. In `attachOrResizeOverlay()`, replace the one-argument `FlutterView(this)` construction with:

     ```kotlin
     val surfaceView = FlutterSurfaceView(this, true)
     val view = FlutterView(this, surfaceView).also {
         it.attachToFlutterEngine(flutterEngine)
     }
     ```

  3. Keep the `WindowManager.LayoutParams` pixel format as:

     ```kotlin
     PixelFormat.TRANSLUCENT
     ```

  4. Do not call `surfaceView.holder.setFormat(...)` or `surfaceView.setZOrderOnTop(...)` manually; `FlutterSurfaceView(this, true)` already performs both operations.
  5. Do not use the deprecated `FlutterView(Context, TransparencyMode)` or `FlutterView(Context, RenderMode)` constructors.
  6. Do not change `FlutterEngine`, plugin registration, Dart entrypoint, method channels, service control surface, or attach/detach ordering beyond what subsequent steps explicitly require.
- **Risk**: Medium. A transparent SurfaceView is separately composed and may expose OEM-specific z-order behavior.
- **Mitigation**: Validate direct rendering on AOSP API 34–36 and at least one physical OEM device before release. Keep the mode `Off` fallback; do not introduce an unproven TextureView switch in this change.
- **Validation**:
  - Android compilation succeeds.
  - Direct display shows the underlying application through Bubble and Panel rounded corners.
  - Flutter icon, text, badge, list, and controls remain above the underlay.

### Step 3 — Make overlay dimensions responsive and compact

- **File**: `android/app/src/main/kotlin/com/verseles/codewalk/overlay/SessionOverlayService.kt`
- **Actions**:
  1. Add these companion constants:

     ```kotlin
     private const val BUBBLE_WIDTH_DP = 96
     private const val BUBBLE_HEIGHT_DP = 96
     private const val PANEL_WIDTH_DP = 360
     private const val PANEL_HEIGHT_DP = 240
     private const val OVERLAY_EDGE_MARGIN_DP = 16
     private const val FIRST_FRAME_TIMEOUT_MS = 5_000L
     ```

  2. Add a private integer DP conversion helper that rounds rather than truncates:

     ```kotlin
     private fun dp(value: Int): Int =
         (value * resources.displayMetrics.density).roundToInt()
     ```

     Add `import kotlin.math.roundToInt`.

  3. Keep `availableBounds()` responsible for obtaining current window metrics and removing system-bar and cutout insets.
  4. Add `overlayMovementBounds()` that returns `availableBounds()` inset by `dp(OVERLAY_EDGE_MARGIN_DP)` on all sides. Clamp each axis so the returned rectangle always has at least one pixel of width and height on unusually small displays.
  5. Add `overlaySize(presentation, bounds)` that chooses Bubble `96×96dp` or Panel `360×240dp`, then caps both values to `bounds.width()` and `bounds.height()`.
  6. Change `attachOrResizeOverlay()` to calculate movement bounds and capped dimensions before creating or updating `WindowManager.LayoutParams`.
  7. Use those same movement bounds for:
     - initial right-edge and vertical placement;
     - restoration from `x_fraction` and `y_fraction`;
     - drag clamping; and
     - normalized-position persistence.
  8. Keep normalized fractions in `[0, 1]`. Use `(bounds.width() - width).coerceAtLeast(1)` and the corresponding height denominator.
  9. When an existing view changes Bubble ↔ Panel, set the new capped dimensions first, then clamp its existing position to current movement bounds before `updateViewLayout()`.
  10. Add:

      ```kotlin
      override fun onConfigurationChanged(newConfig: Configuration) {
          super.onConfigurationChanged(newConfig)
          val snapshot = currentSnapshot ?: return
          val presentation = snapshot["presentation"] as? String ?: return
          @Suppress("UNCHECKED_CAST")
          val items = snapshot["items"] as? List<Map<String, Any?>> ?: emptyList()
          if (presentation != "off" && items.isNotEmpty()) {
              attachOrResizeOverlay(presentation)
          }
      }
      ```

      Add `import android.content.res.Configuration`.

  11. Do not use raw display dimensions or deprecated `Display` APIs on API 30+.
- **Risk**: Medium. Geometry changes can reveal stale positions after rotation or presentation changes.
- **Mitigation**: Use one movement-bounds function for placement, clamp, and persistence; test rotation and expand/collapse in both orientations.
- **Validation**:
  - Bubble layout params equal `96×96dp` unless the usable display is smaller.
  - Panel layout params equal `360×240dp` unless capped by usable bounds.
  - Every edge stays at least `16dp` inside usable bounds on normal-size displays.
  - Dragged normalized position survives detach/reattach and remains visible after rotation.

### Step 4 — Top-align Android content without changing desktop layout

- **File**: `lib/presentation/services/session_attention/session_overlay_entrypoint.dart`
- **Actions**:
  1. Preserve `Scaffold(backgroundColor: Colors.transparent)`.
  2. Replace the unconditional `Center` around `SessionAttentionOverlay` with an `Align` whose alignment is selected only by the existing host identity:

     ```dart
     body: Align(
       alignment: widget.desktopController == null
           ? Alignment.topCenter
           : Alignment.center,
       child: SessionAttentionOverlay(
         // Preserve every existing argument and callback unchanged.
       ),
     ),
     ```

  3. Do not add a platform query. `desktopController == null` is already the authoritative distinction for this dedicated Android host.
  4. Do not change Bubble/Panel colors, typography, actions, ordering, semantics, localization behavior, or state handling.
- **Risk**: Low. Bubble receives tight `96×96dp` constraints, so top-center and center are visually equivalent for its native host.
- **Validation**:
  - Android Panel starts at the top of its compact native window.
  - Desktop remains centered.
  - Existing widget tests outside the Android host remain unchanged except for newly added constraint coverage.

### Step 5 — Remove a window that never renders a first frame

- **File**: `android/app/src/main/kotlin/com/verseles/codewalk/overlay/SessionOverlayService.kt`
- **Actions**:
  1. Add:

     ```kotlin
     private var firstFrameTimeout: Runnable? = null
     ```

  2. Immediately after successfully adding a new `FlutterView` to `WindowManager` and assigning it to `flutterView`, remove any prior timeout and schedule a new one using `FIRST_FRAME_TIMEOUT_MS`.
  3. In the timeout, clear `firstFrameTimeout`. If `flutterView === view` and `view.hasRenderedFirstFrame()` is false:
     - write one non-sensitive warning such as `Session overlay removed: first frame timeout`;
     - call `detachOverlay()`;
     - do not stop the foreground service;
     - do not clear `currentSnapshot`;
     - do not expose any session title, directory, message, or identifier in the log.
  4. In `detachOverlay()`, remove and null `firstFrameTimeout` before detaching the view.
  5. In `onDestroy()`, also remove and null the timeout before engine destruction.
  6. Do not automatically loop or create a timer that repeatedly reattaches the failed view. A later accepted snapshot or normal lifecycle event may call `renderSnapshot()` and perform one fresh attachment.
- **Risk**: Medium. Very slow devices could take longer than five seconds on a cold start.
- **Mitigation**: Five seconds is intentionally larger than the expected local secondary-engine first frame. Validate on the slowest available API 34 emulator and one physical device. If measured valid starts exceed five seconds, increase this single constant based on evidence before release; do not remove the bounded fallback.
- **Validation**:
  - Normal overlays report `hasRenderedFirstFrame() == true` before the timeout.
  - A deliberately broken test entrypoint or equivalent controlled failure removes the native window while the service notification remains active.
  - A subsequent valid snapshot can attach a fresh view.

### Step 6 — Add safe instrumentation accessors and capture control

- **File**: `android/app/src/main/kotlin/com/verseles/codewalk/overlay/SessionOverlayService.kt`
- **Actions**:
  1. Import the generated app BuildConfig:

     ```kotlin
     import com.verseles.codewalk.BuildConfig
     ```

  2. Add this private companion state:

     ```kotlin
     @Volatile
     private var disableSecureForTest = false
     ```

  3. Add these companion test accessors. Return copies or immutable scalar values; never return the live view:

     ```kotlin
     fun hasRenderedFirstFrameForTest(): Boolean =
         instance?.flutterView?.hasRenderedFirstFrame() == true

     fun currentOverlaySizeForTest(): Pair<Int, Int>? =
         instance?.flutterView?.layoutParams
             ?.let { it as? WindowManager.LayoutParams }
             ?.let { it.width to it.height }

     fun currentOverlayFlagsForTest(): Int? =
         instance?.flutterView?.layoutParams
             ?.let { it as? WindowManager.LayoutParams }
             ?.flags

     fun setDisableSecureForTest(disable: Boolean) {
         check(BuildConfig.DEBUG) {
             "Secure overlay capture can only be changed in debug builds"
         }
         disableSecureForTest = disable
     }
     ```

  4. Add a `currentOverlayRectForTest()` accessor that uses `view.getLocationOnScreen(IntArray(2))` and returns a new `Rect(left, top, right, bottom)` based on the actual view width and height. Invoke it from instrumentation on the main thread.
  5. Build window flags in a local mutable integer:

     ```kotlin
     var windowFlags =
         WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
             WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
     if (!BuildConfig.DEBUG || !disableSecureForTest) {
         windowFlags = windowFlags or WindowManager.LayoutParams.FLAG_SECURE
     }
     ```

     Pass `windowFlags` into `WindowManager.LayoutParams`.

  6. Set `disableSecureForTest = false` in `onDestroy()` after the overlay is removed.
  7. Do not expose this switch through intents, method channels, settings, exported components, debug menus, or persistent storage. It must remain an in-process instrumentation hook only.
- **Risk**: High if the test hook leaks into production behavior.
- **Mitigation**: `!BuildConfig.DEBUG` unconditionally adds `FLAG_SECURE`; the setter throws outside debug; no IPC or persisted control exists; instrumentation explicitly verifies normal secure flags before enabling capture.
- **Validation**:
  - A normal debug overlay has `FLAG_SECURE` until the in-process test hook is enabled.
  - A release build always includes `FLAG_SECURE`, regardless of the static field value.
  - Service destruction resets the test field.

### Step 7 — Add exact Android visual and first-frame regression tests

- **File**: `android/app/src/androidTest/kotlin/com/verseles/codewalk/overlay/SessionOverlayServiceInstrumentedTest.kt`
- **Actions**:
  1. Add a `@Before` method that stops any existing service, waits until it is stopped, grants the overlay app-op, and calls `SessionOverlayService.setDisableSecureForTest(false)`.
  2. Extend `tearDown()` to call `setDisableSecureForTest(false)` before and after stopping the service, then wait until the service is stopped.
  3. Change `attentionSnapshot()` to accept a `presentation: String = "bubble"` argument and place that value in the snapshot.
  4. Add `bubbleRendersTransparentCornersAndFirstFrame()`:
     - launch `MainActivity`;
     - on the activity thread replace its content view with a full-screen plain `View` using a deterministic non-black color such as `Color.rgb(0x12, 0xA4, 0x6C)`;
     - take a baseline screenshot through `instrumentation.uiAutomation.takeScreenshot()` before starting the overlay;
     - enable `setDisableSecureForTest(true)`;
     - start the service and send a non-empty Bubble snapshot;
     - wait for attachment and `hasRenderedFirstFrameForTest()`;
     - obtain `currentOverlayRectForTest()` on the main thread;
     - assert the native dimensions equal `96dp` within one pixel of rounding;
     - take a second screenshot;
     - assert a point four pixels inside the top-left overlay corner remains equal to the baseline underlay within a per-channel tolerance of `8`;
     - assert the overlay center differs from the baseline underlay, proving visible Bubble content was rendered.
  5. Add `panelRendersTransparentRoundedCornerAndCompactBounds()` with the same deterministic underlay and capture procedure, but send `presentation = "panel"` and assert:
     - first frame rendered;
     - target dimensions are `360×240dp`, capped to the current movement bounds;
     - the top-left rounded-corner sample matches the baseline;
     - a central Material region differs from the baseline.
  6. Add `normalOverlayRetainsSecureFlag()` without enabling the capture bypass. Attach a Bubble and assert:

     ```kotlin
     val flags = SessionOverlayService.currentOverlayFlagsForTest()
     assertTrue(flags != null && flags and WindowManager.LayoutParams.FLAG_SECURE != 0)
     ```

  7. Add a geometry test that rotates the activity, waits for configuration propagation, and asserts the overlay rectangle remains within current usable bounds and edge margins.
  8. Add expand/collapse coverage that sends Panel then Bubble snapshots and verifies dimensions and first-frame state after each transition.
  9. Use synthetic snapshot data only. Never place credentials, real directories, server URLs, or user messages into screenshots or logs.
  10. Recycle screenshots/bitmaps in `finally` blocks where appropriate and reset the secure bypass even when assertions fail.
- **Risk**: Medium. Pixel tests can be flaky if the underlay animates or coordinates are sampled before composition settles.
- **Mitigation**: Replace the activity content with a static solid color, disable emulator animations as the workflow already does, wait for first frame, read actual on-screen bounds, and use a small channel tolerance instead of exact equality.
- **Validation**:
  - The new tests fail against the original opaque `FlutterView(this)` implementation because corner pixels differ from the underlay.
  - The tests pass after the transparent SurfaceView correction.
  - The secure-flag test passes without the capture bypass.

### Step 8 — Add Flutter constraint and interaction coverage

- **File**: `test/widget/session_attention_overlay_test.dart`
- **Actions**:
  1. Add a Panel test that pumps `SessionAttentionOverlay` in a `SizedBox(width: 360, height: 240)` with at least three synthetic attention items.
  2. Assert `session_attention_panel` exists and no Flutter exception or overflow is reported.
  3. Assert the collapse and stop controls remain visible.
  4. Assert the list is scrollable and the final synthetic item becomes visible after a drag.
  5. Assert Open, Read, and Dismiss callbacks remain callable for an item after scrolling.
  6. Keep an explicit Bubble test under `96×96` constraints and assert its circular Material, badge, and expand control are present without overflow.
  7. Do not alter production widget semantics merely to satisfy the tests.
- **Risk**: Low.
- **Validation**: The focused widget test file passes with no overflow or pending exception.

### Step 9 — Make overlay runtime validation automatic

- **File**: `.github/workflows/session-overlay-prototype.yml`
- **Actions**:
  1. Preserve `workflow_dispatch`.
  2. Add a `pull_request` trigger restricted to:

     ```yaml
     pull_request:
       paths:
         - "android/app/src/main/kotlin/com/verseles/codewalk/overlay/**"
         - "android/app/src/androidTest/kotlin/com/verseles/codewalk/overlay/**"
         - "lib/presentation/services/session_attention/**"
         - "lib/presentation/widgets/session_attention_overlay/**"
         - "test/widget/session_attention_overlay_test.dart"
         - ".github/workflows/session-overlay-prototype.yml"
     ```

  3. Keep Flutter `3.41.5`, Java 17, Android debug APK compilation, Android test APK compilation, and API matrix `[34, 35, 36]` unchanged.
  4. Keep emulator animations disabled and retain the direct instrumentation command.
  5. Do not make screenshots or APKs containing synthetic overlay content public artifacts.
- **Risk**: Low functional risk; medium CI-runtime cost.
- **Mitigation**: Path filtering limits the expensive matrix to changes capable of affecting the overlay.
- **Validation**: A pull request touching `SessionOverlayService.kt` automatically starts compile and API 34–36 runtime jobs.

### Step 10 — Validate the complete change

- **Files**: All changed files.
- **Actions**:
  1. Run the focused widget tests:

     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && \
     flutter test test/widget/session_attention_overlay_test.dart
     ```

  2. Run targeted Dart analysis:

     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && \
     flutter analyze \
       lib/presentation/services/session_attention/session_overlay_entrypoint.dart \
       lib/presentation/widgets/session_attention_overlay/session_attention_overlay.dart \
       test/widget/session_attention_overlay_test.dart
     ```

  3. Compile the app and instrumentation APKs:

     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && \
     flutter pub get && \
     flutter build apk --debug && \
     ./android/gradlew -p android app:assembleDebugAndroidTest
     ```

  4. Run `make check` once after the code is stable:

     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && make check
     ```

  5. Run the session-overlay workflow and require green runtime instrumentation on API 34, 35, and 36.
  6. Perform direct-display manual validation on at least one physical OEM device in portrait and landscape:
     - Bubble over a bright background;
     - Panel over a bright background;
     - expand/collapse;
     - drag to every edge;
     - rotate while Bubble is visible;
     - rotate while Panel is visible;
     - lock/unlock behavior;
     - tap controls;
     - tap the underlying app outside the native overlay rectangle;
     - verify protected screenshot output remains black or omitted as Android policy dictates.
  7. Do not use `make precommit`; CodeWalk requires `make check` and Android validation separately.
  8. Do not run `dart tool/i18n/generate_arb.dart`; this correction adds no localization keys.
- **Risk**: Medium. Emulators cannot prove every OEM compositor behavior.
- **Mitigation**: Require one physical OEM validation in addition to AOSP/API matrix coverage.
- **Validation**: Every command and runtime job passes, and the physical-device checklist has no unresolved rendering, interaction, or privacy failure.

### Step 11 — Review and apply only verified findings

- **Files**: Final implementation diff.
- **Actions**:
  1. Run up to three independent code reviewers after focused and full checks pass.
  2. Give every reviewer the same objective, full diff or commit range, relevant files, ADR-049 constraints, `FLAG_SECURE` invariant, API 34–36 requirement, test results, and accepted `360×240dp` Panel decision.
  3. Reject speculative style changes, architecture rewrites, removal of `FLAG_SECURE`, broad refactors, new dependencies, and TextureView migration without failing device evidence.
  4. Fix every verified correctness, security, lifecycle, rotation, race, or test-reliability issue.
  5. After reviewer fixes, run focused validation for touched files. Rerun `make check` only if a fix affects shared infrastructure, dependencies, generated files, build configuration, or invalidates the prior full check.
  6. Repeat review only when a substantive code correction changes the reviewed behavior.
- **Risk**: Low.
- **Validation**: No judge-approved critical or warning finding remains unresolved.

### Step 12 — Document the delivered behavior

- **File**: `BEHAVIOR.md`
- **Actions**:
  1. Add or update the current Android session-attention behavior to state:
     - Bubble and Panel are opt-in external overlays requiring Android special-access permission;
     - Bubble is compact and Panel is a larger scrollable surface;
     - transparent corners reveal the underlying application;
     - overlays stay within usable display bounds and remain draggable;
     - production screenshots, recording, casting, or mirroring may hide or black out protected overlay content because `FLAG_SECURE` is intentional;
     - failure to render a first frame removes the window while leaving the stoppable foreground service notification available.
  2. Do not document test hooks or internal constructor details as user behavior.
  3. Do not edit ADR-049 because no architectural decision changed.
  4. Do not edit `CODEBASE.md` because no module, directory, or entry point changed.
- **Risk**: Low.
- **Validation**: Documentation describes only behavior proven by the final implementation and tests.

## Git Execution Protocol

This is a multi-step, resumable implementation. Execute it with plan-anchored commits on the current branch; do not create a feature branch unless the user explicitly requests one.

1. Before editing code, inspect `git status`, recent commits, the latest `AGENT_PLAN_ANCHOR`, and any commits carrying its `PLAN_REF`. Do not overwrite or include unrelated user changes.
2. If a different active plan is incomplete, stop and ask whether to finish or supersede it.
3. If no conflicting active plan exists, create an immutable `plan: fix Android session overlay transparency` commit containing `AGENT_PLAN_ANCHOR`. Stage only `final_plan.md` for that commit. Copy the full problem, objective, decisions, constraints, execution steps, risks, validation gates, and definition of done from this file into the commit body so the commit remains self-sufficient.
4. Record the plan commit hash as `PLAN_REF`.
5. Commit implementation in exactly these plan steps after each step’s validation passes:
   - `chore(agent): [Step 1/3] Fix overlay composition and geometry`
   - `chore(agent): [Step 2/3] Add overlay visual regression coverage`
   - `chore(agent): [Step 3/3] Automate validation and document behavior`
6. Put `PLAN_REF` and `PREVIOUS_STEP` in every progress commit body and record completed/remaining steps.
7. Do not amend the immutable plan commit or completed progress commits.
8. Do not push unless the user explicitly requests a push in the implementation conversation.
9. Before any requested push, verify clean intended status, review the complete diff, require the final checks above, and never include credentials or captured real session content.

## Risks & Mitigations

### Critical — Privacy regression from weakening secure-window behavior

- **Risk**: Removing or conditionally disabling `FLAG_SECURE` in production could expose session content through screenshots, recording, casting, or non-secure displays.
- **Mitigation**: Release builds unconditionally add `FLAG_SECURE`. The only bypass requires `BuildConfig.DEBUG`, an in-process static test call, no persistence, no IPC, and reset during teardown/destruction. Instrumentation explicitly tests the normal secure path.

### High — Transparent SurfaceView differs on an OEM compositor

- **Risk**: A physical OEM may mishandle transparent SurfaceView z-order even though AOSP APIs 34–36 pass.
- **Mitigation**: Validate one physical OEM before release. If a tested OEM still renders black after a confirmed first frame, keep Bubble/Panel unavailable or instruct the user to return the mode to `Off`, capture device/API evidence, and open a separate TextureView evaluation. Do not silently ship an unvalidated renderer switch.

### High — Test-only capture switch becomes externally controllable

- **Risk**: An intent, setting, method channel, or persisted preference could accidentally expose the debug bypass.
- **Mitigation**: Implement only the exact in-process companion setter described above. Do not add any external control surface. Keep release behavior unconditional.

### Medium — First-frame timeout removes a valid but slow overlay

- **Risk**: A slow cold start might exceed five seconds.
- **Mitigation**: Measure on the slowest available emulator and a physical device. Increase the constant only with measured evidence. Keep the bounded removal so a non-rendering window cannot intercept touches indefinitely.

### Medium — Transparent but oversized native input region

- **Risk**: Android dispatches touches based on the window rectangle, not Flutter pixel alpha.
- **Mitigation**: Reduce Panel to `360×240dp`, top-align content, reserve edge margins, and test underlying-app interaction outside the actual native rectangle. Do not claim click-through inside transparent pixels that remain inside the native rectangle.

### Medium — Rotation or inset changes leave stale geometry

- **Risk**: Fixed coordinates from the old configuration could place part of the overlay off-screen.
- **Mitigation**: Recompute current metrics in `onConfigurationChanged()`, use one inset movement-bounds function for sizing/clamping/persistence, and test both presentations in portrait and landscape.

### Medium — Secure screenshots create false visual-test failures

- **Risk**: The protected region can appear black even when direct rendering is correct.
- **Mitigation**: Keep direct-device observation authoritative for production behavior. Use only the debug in-process bypass with synthetic data for pixel assertions.

### Low — Shared Dart alignment changes desktop behavior

- **Risk**: Replacing `Center` globally could move the desktop child window content.
- **Mitigation**: Select `Alignment.topCenter` only when `desktopController == null`; preserve `Alignment.center` for desktop and test existing desktop/widget behavior.

## Assumptions to Validate

1. **Flutter 3.41.5 exposes `FlutterSurfaceView(Context, boolean)` and `FlutterView(Context, FlutterSurfaceView)`.**
   - Validation: Compile against the pinned SDK and confirm the local embedding source signatures.
   - If false: Stop implementation and update the plan to the equivalent non-deprecated API in the actually resolved Flutter SDK. Do not use a deprecated constructor merely to bypass verification.

2. **The black surface is observable directly, or the overlay still requires transparent direct composition even if the report came from a capture.**
   - Validation: Complete Step 1’s direct-versus-capture record.
   - If false because direct rendering is already correct: Keep `FLAG_SECURE`, retain the transparent-surface correction because it aligns the implementation with its required alpha contract, and classify capture blackness as expected protected behavior in documentation and acceptance notes.

3. **A `360×240dp` Panel can show one session and scroll additional sessions without overflow.**
   - Validation: Add the exact constrained widget test and manually inspect long localized labels.
   - If false: Fix internal Panel layout spacing or scrolling within the same `360×240dp` window. Do not restore the `520dp` native height or present an architecture alternative.

4. **Five seconds accommodates valid first-frame startup on supported devices.**
   - Validation: Measure cold starts on API 34–36 and one physical OEM device.
   - If false: Set `FIRST_FRAME_TIMEOUT_MS` to the smallest measured-safe value above the slowest valid startup plus a 25% margin, and record the measured value in the implementation commit. Keep the timeout bounded.

5. **The existing `Flexible`/`ListView.builder` Panel scrolls under a finite 240dp constraint.**
   - Validation: The three-item constrained widget test reaches the final item by dragging and reports no overflow.
   - If false: Adjust the Panel’s internal `Column`/`Flexible` constraints while preserving the existing header and actions; do not remove scrolling.

6. **The debug instrumentation process can invoke the target service companion test hooks in-process.**
   - Validation: The existing instrumentation runner successfully calls current companion accessors such as `isRunning()` and `hasAttachedOverlay()`.
   - If false: Move test state behind a package-private debug-only helper compiled into the debug source set. Keep it non-exported, non-persistent, and unreachable through production IPC.

## Decisions and Nuances

- `PixelFormat.TRANSLUCENT` configures the outer WindowManager window; it does not make a nested opaque `SurfaceView` transparent.
- `Scaffold(backgroundColor: Colors.transparent)` is already correct but cannot override native surface opacity.
- The black region matching `96×96dp` or `360×520dp` is evidence that native host bounds are visible, not evidence that the circular/rounded Dart widget itself paints black.
- `FLAG_NOT_TOUCH_MODAL` passes touches outside the native overlay rectangle. It does not guarantee click-through for transparent pixels inside that rectangle.
- `FLAG_SECURE` capture blackness is intentional privacy behavior and must be separated from direct-display rendering acceptance.
- The transparent SurfaceView constructor already applies transparent holder format and z-order. Duplicate calls add no value and make ownership unclear.
- The service Context remains in use. Flutter’s Activity-context warning concerns platform views; this narrow overlay renders ordinary Flutter widgets and currently contains no platform view. Do not redesign the host without a demonstrated platform-view failure.
- First-frame observation is a secondary guard. It does not replace the transparent surface fix.
- The Panel-size correction is intentional product behavior: `240dp` remains a larger scrollable surface than Bubble while avoiding a nearly full-height native window.
- Do not make screenshots part of user-facing functionality. The capture bypass exists solely for synthetic instrumentation.
- Do not add an OEM renderer fallback switch in this change. Gather device evidence first and keep `Off` as the safe fallback.

## Blockers and Open Questions

None.

Any failure discovered during execution must be handled according to the resolved fallbacks above. A physical OEM failure after the transparent-surface correction blocks claiming support for that OEM, but it does not justify weakening privacy, changing server contracts, or silently replacing the renderer.

## Testing Strategy

### Focused Flutter tests

- Bubble under `96×96` constraints:
  - circular Material exists;
  - badge exists;
  - expand action exists;
  - no overflow or exception.
- Panel under `360×240` constraints:
  - rounded Material exists;
  - collapse and stop actions exist;
  - three items are scrollable;
  - Open, Read, and Dismiss callbacks work;
  - no overflow or exception.

### Android instrumentation

- Existing service start/stop, null-intent, revision, permission-revocation, and fallback tests remain green.
- New Bubble pixel test proves transparent corner plus visible center.
- New Panel pixel test proves transparent rounded corner, visible content, and compact dimensions.
- First-frame assertions prove the secondary engine actually displayed Flutter UI.
- Secure-flag assertion proves production-default debug behavior still protects content.
- Rotation and expand/collapse assertions prove geometry is recomputed and clamped.
- The original opaque implementation must fail the new corner-pixel test; this confirms that the test detects the exact regression.

### Static and build checks

- Targeted `flutter analyze` on changed Dart/test files.
- Android debug APK build.
- Android instrumentation APK build.
- Full `make check` after stabilization.

### Runtime matrix

- API 34, 35, and 36 emulator instrumentation through `.github/workflows/session-overlay-prototype.yml`.
- One physical OEM device, direct display, portrait and landscape.
- Protected screenshot/recording behavior confirmed without exposing real content.

## Execution Handoff

The future executor must start here:

1. Read `/home/ubuntu/MEGA/WORK/codewalk/AGENTS.md`, `BEHAVIOR.md`, ADR-049 in `ADR.md`, and this file.
2. Inspect `git status` and the latest `AGENT_PLAN_ANCHOR`; preserve unrelated and in-progress user work.
3. Create the plan-anchor commit described in **Git Execution Protocol** before modifying code.
4. Perform Step 1’s direct-versus-capture baseline with synthetic content.
5. Open these files first:
   - `android/app/src/main/kotlin/com/verseles/codewalk/overlay/SessionOverlayService.kt`
   - `lib/presentation/services/session_attention/session_overlay_entrypoint.dart`
   - `lib/presentation/widgets/session_attention_overlay/session_attention_overlay.dart`
   - `android/app/src/androidTest/kotlin/com/verseles/codewalk/overlay/SessionOverlayServiceInstrumentedTest.kt`
   - `test/widget/session_attention_overlay_test.dart`
   - `.github/workflows/session-overlay-prototype.yml`
6. Implement Steps 2–6 before writing tests so the test accessors and final geometry are stable.
7. Implement Steps 7–9, then run Step 10 exactly in order.
8. Complete review before documentation and the final progress commit.
9. Do not release, tag, or push unless separately requested by the user.

## Out of Scope

- Replacing the dedicated Android foreground service or secondary Flutter engine.
- Merging overlay responsibilities into the existing data-sync service.
- Changing OpenCode endpoints, events, authentication, session semantics, or ADR-023 behavior.
- Changing encrypted snapshot storage, retention, identity scoping, root-session selection, final fetches, Data Saver, OAuth, Tailscale, TTS, or process-death recovery.
- Removing or weakening `SYSTEM_ALERT_WINDOW`, `specialUse` foreground-service requirements, or `FLAG_SECURE`.
- Adding automatic speech or exposing additional session content.
- Migrating to `FlutterTextureView` without reproducible physical-device evidence.
- Implementing per-pixel touch-through inside the native window rectangle.
- Redesigning Bubble/Panel colors, typography, icons, ordering, localization, or actions.
- Changing desktop window architecture or iOS in-app presentation.
- Adding new dependencies.
- Releasing a new version, building a release APK, tagging, pushing, or opening a pull request unless separately requested.

## Definition of Done

The work is complete only when all conditions below are true:

- [ ] Baseline notes distinguish direct-display behavior from protected capture behavior.
- [ ] `SessionOverlayService` constructs `FlutterSurfaceView(this, true)` and passes it to the non-deprecated `FlutterView` constructor.
- [ ] Outer window format remains `PixelFormat.TRANSLUCENT`.
- [ ] Production paths always retain `FLAG_SECURE`.
- [ ] Bubble renders without a black square and uses `96×96dp` target bounds.
- [ ] Panel renders without a black rectangle and uses `360×240dp` target bounds.
- [ ] Transparent corners reveal the underlying app on direct display.
- [ ] Panel content remains readable and scrollable with multiple items.
- [ ] Overlay stays inside usable bounds with `16dp` margins after drag, rotation, and presentation changes.
- [ ] A view that fails to render a first frame is detached after the bounded timeout while the service remains stoppable.
- [ ] Pixel instrumentation fails against the old opaque implementation and passes against the corrected implementation.
- [ ] Secure-window instrumentation passes without the capture bypass.
- [ ] Existing service lifecycle and snapshot tests remain green.
- [ ] Focused widget tests pass.
- [ ] Targeted Dart analysis passes.
- [ ] Android app and instrumentation APKs compile.
- [ ] `make check` passes on the final code state.
- [ ] API 34, 35, and 36 runtime jobs pass.
- [ ] One physical OEM device passes direct-display portrait/landscape validation.
- [ ] No verified reviewer correction remains unresolved.
- [ ] `BEHAVIOR.md` describes the delivered behavior and secure-capture nuance.
- [ ] ADR-049 and ADR-023 invariants remain intact.
- [ ] No credentials, real session content, or unrelated user changes are included.
