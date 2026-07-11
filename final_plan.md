# Issue #95 — Simplify the First-Run Welcome Screen

## Status

Ready.

This plan is complete and authoritative. Execute it as written without relying on prior chat history. Before editing, complete the execution preflight in the final section. If another `AGENT_PLAN_ANCHOR` is still active, finish or explicitly pause that work before starting this issue.

## Problem

CodeWalk currently presents a visually dense first-run Welcome screen before server setup. The screen gives similar prominence to three setup paths, always emphasizes “Connect to a running server,” places an explanatory card before the actions, and renders the managed-local option as a disabled full-size card on unsupported platforms.

This conflicts with the intended beginner experience for GitHub issue [#95](https://github.com/verseles/codewalk/issues/95): the first post-install screen must be simpler, welcoming, mobile-first, responsive on desktop, Material You aligned, and centered on one obvious next action.

The managed-local path has an additional correctness problem that becomes critical when promoted to the primary desktop action. Its final `Continue` button currently calls `_complete()` even when no local server is running. It does not set `_connectionSuccess`, does not pass through the `Ready` step, and therefore does not arm `pendingPostOnboardingChatTour` after a successful first-run setup.

## Objective

Deliver a first-run Welcome screen with one capability-appropriate primary action:

- On runtimes where `AppProvider.localServerSupported` is `true`, prioritize managed local OpenCode setup.
- On runtimes where `AppProvider.localServerSupported` is `false`, prioritize the guided OpenCode setup path.
- Keep connection to an existing server available as a secondary action on every platform.
- Do not show a disabled managed-local action on unsupported platforms.
- Preserve the complete setup chooser when the shared wizard is opened from Settings.
- Require a healthy running managed local server before first-run completion.
- Route successful first-run managed setup through the existing `Ready` step and arm the post-onboarding chat tour on final completion.
- Add regression coverage for capability adaptation, first-run/settings isolation, managed-local completion, accessibility, and compact layouts.

## Context and Constraints

### Product constraints

- CodeWalk is a mobile and desktop OpenCode client. Prioritize touch/mobile usability while retaining complete desktop, pointer, and keyboard behavior.
- Use Material You / Material 3 components and the existing theme. Do not introduce a custom palette, hard-coded card colors, or a new design system.
- Base setup priority on runtime capability (`localServerSupported`), not viewport width or a phone/desktop heuristic. A narrow desktop window must still prioritize managed local setup; a wide web/mobile viewport must not expose it.
- Keep the first-run wizard intentionally linear and compatible with ADR-011.
- Do not change OpenCode API, event, provider, model, or session semantics. This client-only UI change remains compatible with ADR-023 and requires no ADR exception.
- Reuse existing localization keys. Do not introduce English-only strings and do not run the destructive global ARB generation script.
- Do not redesign chat empty states, server failure recovery, authentication, local runtime internals, or the post-onboarding tour itself.

### Existing implementation

- `lib/presentation/pages/app_shell_page.dart:83-117` gates first run. It shows `OnboardingWizardPage` when no server profile exists, `skipOnboardingWizard` is false, and the wizard has not been dismissed for the current session.
- `lib/presentation/pages/onboarding_wizard_page.dart:23-129` defines `SetupWizardInitialFlow`, widget parameters, wizard state, and initial-flow selection.
- `lib/presentation/pages/onboarding_wizard_page.dart:232-253` completes the wizard. `_complete()` arms `pendingPostOnboardingChatTour` only when `_connectionSuccess`, `showSkipAction`, and a non-edit flow are all true.
- `lib/presentation/pages/onboarding_wizard_page.dart:255-287` defines `_goToConnectServer`, `_goToNeedHelp`, and `_goToLocalManagedSetup`. These callbacks record setup-debug events and must remain the entry points for their respective flows.
- `lib/presentation/pages/onboarding_wizard_page.dart:596-683` builds the shell and selects the current step.
- `lib/presentation/pages/onboarding_wizard_page.dart:687-919` builds the current Welcome step.
- `lib/presentation/pages/onboarding_wizard_page.dart:1398-1749` builds managed local setup.
- `lib/presentation/pages/onboarding_wizard_page.dart:1808-1963` builds successful and failed `Ready` states.
- `lib/presentation/providers/app_provider.dart:1281-1370` starts the local server. A successful `startLocalServer()` health-checks the process, creates/activates the managed local server profile through `_ensureLocalServerProfileActive()`, sets `LocalServerRuntimeStatus.running`, and returns `true`.
- `lib/presentation/pages/settings_page.dart:356-364` and `lib/presentation/pages/settings/sections/servers_settings_section.dart:568-580` open the shared wizard with `showSkipAction: false`.
- `lib/presentation/pages/chat_page/chat_page_timeline_viewport.dart:245-264` opens the wizard directly in `connectServer` flow from the no-server chat state; this call bypasses Welcome and must remain unchanged.
- `test/widget/onboarding_wizard_test.dart` contains the primary wizard widget tests and reusable fake providers/runtimes.
- `test/widget/app_shell_page_test.dart` protects first-run shell gating.
- `test/widget/chat_page_test.dart` protects the post-onboarding tour and no-server chat behavior.
- `test/unit/providers/app_provider_test.dart:406-477` already verifies managed local profile creation and launch failures at provider level.
- `BEHAVIOR.md:43-161` documents current onboarding, CodeWalk/OpenCode explanation, Ready behavior, tour handoff, health failure recovery, and no-server behavior.
- `ADR.md:457-492` is ADR-011, the unified linear server setup wizard decision.
- `ADR.md:998-1051` is ADR-023, the official OpenCode contract-first policy.

### Existing state that must remain authoritative

- `skipOnboardingWizard` controls persistent first-run wizard suppression.
- `_wizardDismissedThisSession` controls temporary dismissal in `AppShellPage`.
- `pendingPostOnboardingChatTour` controls the tour handoff after successful first-run setup.
- Server profiles and `AppProvider.localServerStatus` determine whether a managed local server is available and running.
- Do not add `welcomeSeen`, `firstRunWelcomeSeen`, `onboardingVariant`, or any equivalent state field.

## Decisions (Resolved)

1. Change only the first-run Welcome presentation. Preserve the complete current chooser used by Settings and server management.
2. Detect the first-run wizard context explicitly from existing widget inputs; do not add a new public constructor parameter or persisted state.
3. Use `AppProvider.localServerSupported` as the sole primary-action capability signal.
4. Keep a single-column, maximum-width-560 layout on all sizes. Do not introduce a desktop multi-column layout; it would add complexity without improving the core decision.
5. Replace equal-weight actionable cards with one full-width `FilledButton`, one full-width `OutlinedButton`, and one optional low-emphasis `TextButton`.
6. Keep the CodeWalk/OpenCode relationship visible as concise inline text. Keep the detailed “What is OpenCode?” explanation available in a compact expansion placed after the setup actions.
7. Hide managed-local setup completely when unsupported. Do not render it disabled.
8. Reuse `_goToLocalManagedSetup`, `_goToNeedHelp`, and `_goToConnectServer` so setup-debug events and existing flow semantics remain intact.
9. On first run, require `LocalServerRuntimeStatus.running` before leaving managed local setup.
10. After first-run managed local setup succeeds, transition to the existing successful `Ready` step with `_connectionSuccess = true`; call `_complete()` only from `Ready`.
11. Preserve Settings-mode managed setup behavior and labels. Settings completion must not arm the post-onboarding tour.
12. Reuse existing localization strings and generated localization code. Add no new ARB keys unless compilation proves an existing key cannot express an explicitly required label; this plan expects no new keys.
13. Keep the existing AppBar Skip behavior unchanged and visually secondary.

## Why This Plan

This plan reduces the first decision to one recommended action without removing valid alternatives. It uses an existing capability signal instead of device or viewport guesses, protects the shared Settings wizard from first-run-specific changes, and avoids unnecessary state migration. It also resolves the managed-local completion asymmetry before that path becomes the desktop default, preventing users from exiting setup without a running server and preserving the established Ready/tour handoff.

## Execution Plan (Synthesized)

### Step 1 — Establish a first-run-only Welcome branch

**Files:**

- `lib/presentation/pages/onboarding_wizard_page.dart`

**Changes:**

1. Add a private computed getter to `_OnboardingWizardPageState`:

```dart
bool get _isFirstRunFlow =>
    widget.showSkipAction &&
    widget.initialFlow == SetupWizardInitialFlow.choose &&
    widget.initialServerProfile == null;
```

2. Keep `_buildStep()` unchanged: step `0` must continue calling `_buildWelcomeStep()`.
3. Refactor `_buildWelcomeStep()` into a dispatcher. Read `localServerSupported` once with the existing `context.select<AppProvider, bool>`, then return either the new first-run presentation or the preserved full chooser:

```dart
Widget _buildWelcomeStep() {
  final supportsLocalManaged = context.select<AppProvider, bool>(
    (provider) => provider.localServerSupported,
  );
  if (_isFirstRunFlow) {
    return _buildFirstRunWelcomeStep(supportsLocalManaged);
  }
  return _buildSetupChooserStep(supportsLocalManaged);
}
```

4. Move the existing Welcome implementation into `_buildSetupChooserStep(bool supportsLocalManaged)` without changing its labels, order, callbacks, card rendering, key `step_welcome`, or Settings behavior.
5. Ensure only one widget in each branch owns `const ValueKey('step_welcome')`.

**Risk:** Medium. The wizard is shared across first-run, Settings, server management, and direct initial flows.

**Mitigation:** Gate the new presentation with `_isFirstRunFlow` and add explicit tests for `showSkipAction: false` and non-`choose` initial flows.

**Validation:** Run the existing onboarding widget tests before changing assertions. Confirm the Settings chooser still contains all three current options and its existing title/subtitle.

### Step 2 — Build the simplified first-run Welcome presentation

**Files:**

- `lib/presentation/pages/onboarding_wizard_page.dart`

**Changes:**

1. Add `_buildFirstRunWelcomeStep(bool supportsLocalManaged)`.
2. Return `SingleChildScrollView(key: const ValueKey('step_welcome'))` containing a centered `Column` with `crossAxisAlignment: CrossAxisAlignment.stretch`.
3. Keep the outer scaffold’s existing 560-pixel maximum width and default padding. Do not add a new breakpoint or multi-column layout.
4. Render the existing `Symbols.code_rounded` icon at 56 pixels, centered, using `colorScheme.primary`.
5. Render `onboardingWelcomeTo(AppConstants.appName)` with `headlineSmall`, centered.
6. Render `onboardingNeedsOpenCodeServer(AppConstants.appName)` with `bodyMedium`, centered, using `onSurfaceVariant`.
7. Render `onboardingCodeWalkAppOpenCode` directly below it with `bodySmall`, centered, using `onSurfaceVariant`. This makes the CodeWalk-client/OpenCode-engine relationship visible without requiring expansion.
8. Use vertical spacing of 24 pixels after the icon, 8 pixels between text blocks, and 24 pixels before the primary action.
9. Add stable keys for tests:

```dart
const ValueKey('first_run_primary_setup_action')
const ValueKey('first_run_connect_server_action')
const ValueKey('first_run_guided_setup_action')
```

10. When `supportsLocalManaged` is `true`, render actions in this exact order:

```text
FilledButton.icon: onboardingLetCodeWalkSet → _goToLocalManagedSetup
OutlinedButton.icon: onboardingConnectRunningServer → _goToConnectServer
TextButton.icon: onboardingShowSetupSteps → _goToNeedHelp
```

11. Use `Symbols.computer`, `Symbols.dns_rounded`, and `Symbols.help_outline_rounded` respectively.
12. When `supportsLocalManaged` is `false`, render actions in this exact order:

```text
FilledButton.icon: onboardingShowSetupSteps → _goToNeedHelp
OutlinedButton.icon: onboardingConnectRunningServer → _goToConnectServer
```

13. Do not render `onboardingLetCodeWalkSet`, `onboardingAvailableOnlyDesktop`, or a disabled managed-local control when unsupported.
14. Make the filled and outlined actions full-width through the stretched column. Apply `minimumSize: const Size.fromHeight(48)` through local button styles if the default theme does not guarantee a 48-pixel target.
15. Insert 12 pixels between high- and medium-emphasis actions and 4–8 pixels before a tertiary text action.
16. Place a compact `ExpansionTile` after the actions, separated by 16 pixels. Preserve `const ValueKey('what_is_opencode_tile')`, use `onboardingOpenCode` as its title, and show `onboardingOpenCodeRunsLocally` in its children.
17. Do not wrap the first-run expansion in a full-size `Card`. Do not repeat `onboardingCodeWalkAppOpenCode` as the expansion subtitle because it is already visible above.
18. Use theme typography, shapes, colors, focus, hover, splash, and disabled behavior from standard Material controls. Add no custom gesture detector or custom semantic wrapper unless an accessibility test proves it necessary.
19. Keep the AppBar title and Skip action unchanged.

**Risk:** Medium. Localization length and large text can expand the vertical layout.

**Mitigation:** Keep the screen scrollable, use full-width controls, avoid fixed heights other than minimum touch targets, and test at 360×640 with 2.0 text scale.

**Validation:** Verify action type, label, order, callback destination, absence of unsupported controls, keyboard focus, and no render overflow.

### Step 3 — Harden first-run managed local completion

**Files:**

- `lib/presentation/pages/onboarding_wizard_page.dart`

**Changes:**

1. Add a private transition method:

```dart
void _goToReadyFromManagedLocal() {
  if (!mounted) return;
  setState(() {
    _connectionSuccess = true;
    _connectionError = null;
    _step = 2;
  });
}
```

2. Add a private async start method that calls `AppProvider.startLocalServer()` and preserves current error reporting:

```dart
Future<void> _startManagedLocalServer() async {
  final appProvider = context.read<AppProvider>();
  final ok = await appProvider.startLocalServer();
  if (!mounted) return;
  if (!ok) {
    _showMessage(appProvider.errorMessage);
    return;
  }
  if (_isFirstRunFlow) {
    _goToReadyFromManagedLocal();
  }
}
```

3. Replace the inline `startLocalServer()` closure in `_buildLocalSetupStep()` with `() => unawaited(_startManagedLocalServer())`. Preserve its busy/running disable conditions, icon, label, diagnostics, and failure messaging.
4. In the final action region of `_buildLocalSetupStep()`, branch by `_isFirstRunFlow`:

- In first-run flow, render no completion button while `isRunning` is false.
- In first-run flow, when `isRunning` is true, render `FilledButton.icon` with `onboardingContinue`, `Symbols.arrow_forward_rounded`, and `_goToReadyFromManagedLocal`.
- In non-first-run/Settings flow, preserve the existing `FilledButton.icon` that labels itself `onboardingDone` and calls `_complete()`.

5. Do not call `_complete()` directly from managed local setup during first run.
6. Do not set `_connectionSuccess` before `startLocalServer()` returns `true` or before an already-running status is observed.
7. Keep launch/install failures on the local setup step. Preserve logs, diagnostics, setup-debug navigation, Start/Stop actions, and error messages.
8. Let the existing successful `Ready` button call `_complete()`. Because `_connectionSuccess` and `showSkipAction` are true, `_complete()` will set `pendingPostOnboardingChatTour` before invoking `onComplete`.
9. Leave `_complete()`, `AppShellPage`, `SettingsProvider`, `ExperienceSettings`, and `AppProvider.startLocalServer()` unchanged.

**Risk:** High. Incorrect completion sequencing can exit onboarding without a usable server or suppress the post-onboarding tour.

**Mitigation:** Require `running`, route through `Ready`, test both fresh start and already-running cases, and verify the pending tour flag before and after final completion.

**Validation:** Confirm failed start remains on step 3, successful start reaches `step_ready_success`, the tour flag remains false before final Ready completion, and becomes true after the user completes Ready.

### Step 4 — Add focused widget regression tests

**Files:**

- `test/widget/onboarding_wizard_test.dart`
- `test/widget/app_shell_page_test.dart` only if existing shell-gate coverage cannot assert the new first-run entry without duplicating setup
- `test/widget/chat_page_test.dart` only for running existing targeted tour tests; do not edit unless a real uncovered regression requires it

**Changes:**

1. Extend the test builder only as needed to inject `FakeLocalOpencodeServerRuntime`, `localServerHealthProbe`, and platform capability deterministically.
2. Add a compact unsupported-capability test using a 360×640 test surface and an `AppProvider` whose fake local runtime reports `supported: false`. Assert:

- `first_run_primary_setup_action` is a `FilledButton` containing `Show me the setup steps`.
- `first_run_connect_server_action` is an `OutlinedButton` containing `Connect to a running server`.
- `Let CodeWalk set it up locally` and `Available only on desktop` are absent.
- `What is OpenCode?` remains available.
- No overflow exception occurs.

3. Add a supported-capability test using a fake local runtime with `supported: true`. Assert:

- `first_run_primary_setup_action` is a `FilledButton` containing `Let CodeWalk set it up locally`.
- `first_run_connect_server_action` is secondary.
- `first_run_guided_setup_action` is present as the tertiary guide action.

4. Run the supported-capability test on a narrow surface as well. Assert managed local remains primary. This proves capability, not width, controls priority.
5. Add callback destination tests:

- Unsupported primary opens `step_server_setup` with the Quick setup guide visible.
- Existing-server secondary opens `step_server_setup` without initially showing the Quick setup guide.
- Supported primary opens `step_local_setup` and schedules diagnostics.

6. Add a Settings isolation test with `showSkipAction: false` and `initialFlow: choose`. Assert the preserved chooser still shows all existing setup options, uses the Settings title/subtitle, has no Skip action, and does not use the first-run primary-action keys.
7. Add a non-`choose` initial-flow test proving `connectServer`, `guidedServerSetup`, and `managedLocalServer` continue entering their target steps directly.
8. Add a first-run managed-local success test with:

- Fake local runtime `supported: true`.
- Successful runtime start result.
- `localServerHealthProbe` returning `ServerHealthStatus.healthy`.
- A completion callback flag.

Assert this exact sequence:

```text
Open first-run Welcome.
Tap first_run_primary_setup_action.
Wait for local diagnostics.
Tap Start.
Wait for start and health completion.
Observe step_ready_success.
Confirm a managed local server profile exists and is active.
Confirm pendingPostOnboardingChatTour is false before final completion.
Tap Start using CodeWalk.
Confirm pendingPostOnboardingChatTour is true.
Confirm onComplete was called.
```

9. Add a first-run managed-local failure test. Configure the fake runtime start result with `ok: false` and a deterministic error. Assert the wizard remains on `step_local_setup`, displays the failure, creates no active managed profile, does not arm the tour, and does not call completion.
10. Add an already-running first-run test. Start the fake managed server successfully before entering or simulate a running provider state, open managed local setup, assert `Continue` is enabled, tap it, and verify the successful Ready step.
11. Add a Settings managed-local regression test. With `showSkipAction: false`, verify `Done` preserves the existing close behavior and never arms `pendingPostOnboardingChatTour`.
12. Add a large-text test at a 360×640 surface and 2.0 text scale. Pump the first-run Welcome, scroll to the last control, and assert no `RenderFlex` overflow or uncaught framework exception.
13. Add accessibility assertions using Flutter’s available guidelines:

- Android tap target guideline for at least 48×48 controls.
- Labeled tappable controls.
- Logical focus order matching visual action order.

14. Update the original “shows beginner-friendly welcome options” test to assert the new first-run hierarchy rather than only text presence.
15. Preserve all existing skip, connection, failed-health recovery, duplicate-profile, OAuth, and setup-debug tests.

**Risk:** Medium. Platform overrides and async managed-runtime tests can leak state between tests.

**Mitigation:** Reset `debugDefaultTargetPlatformOverride`, test surface size, device pixel ratio, and text scale in `addTearDown`; use fake runtime and health-probe seams instead of real processes or network calls.

**Validation:** Run the onboarding test file independently until stable, then run the related shell and tour tests.

### Step 5 — Update current-behavior documentation

**Files:**

- `BEHAVIOR.md`

**Changes:**

1. Update only the first-run onboarding section after the implementation and tests pass.
2. Document that first-run Welcome uses a capability-adaptive primary action:

- Managed local setup is primary when the current runtime supports it.
- Guided setup is primary when managed local setup is unsupported.
- Existing-server connection remains available as the secondary path.
- Unsupported managed-local setup is not shown.

3. Document that Settings retains the complete unified setup chooser.
4. Document that successful first-run managed local setup reaches the same Ready completion and post-onboarding tour handoff as successful server connection.
5. Preserve all existing documentation for skip behavior, failed health checks, setup-debug visibility, no-server fallback, and the chat tour.
6. Do not modify `ADR.md`; the implementation remains within ADR-011 and ADR-023.
7. Do not modify `CODEBASE.md`; no module, entry point, or structural map changes.

**Risk:** Low.

**Validation:** Compare the updated statements with widget behavior and tests. Do not document planned or unimplemented behavior.

### Step 6 — Validate and review the completed change

**Files:** All changed source, tests, and behavior documentation.

**Commands:**

Run focused formatting first:

```bash
export PATH="$HOME/flutter/bin:$PATH" && \
dart format \
  lib/presentation/pages/onboarding_wizard_page.dart \
  test/widget/onboarding_wizard_test.dart
```

Run focused analysis:

```bash
export PATH="$HOME/flutter/bin:$PATH" && \
flutter analyze \
  lib/presentation/pages/onboarding_wizard_page.dart \
  test/widget/onboarding_wizard_test.dart
```

Run focused wizard and shell tests:

```bash
export PATH="$HOME/flutter/bin:$PATH" && \
flutter test \
  test/widget/onboarding_wizard_test.dart \
  test/widget/app_shell_page_test.dart
```

Run the existing post-onboarding tour regressions from `test/widget/chat_page_test.dart` using their exact test names or the smallest matching name filter. Include at minimum:

```text
pending tour flag survives startup retries
passive tour dismiss keeps the pending flag armed
explicit skip clears the pending tour flag
finishing the tour clears the pending flag
pending tour renders desktop intro overlay on startup
```

Run the provider managed-local tests:

```bash
export PATH="$HOME/flutter/bin:$PATH" && \
flutter test test/unit/providers/app_provider_test.dart \
  --plain-name "startLocalServer"
```

Run the repository validation gate after focused checks pass:

```bash
export PATH="$HOME/flutter/bin:$PATH" && make check
```

Do not run `make precommit` for CodeWalk. Do not run `dart tool/i18n/generate_arb.dart`; it is destructive to newer ARB keys.

After tests pass, run the project reviewer loop for the final code diff. Give reviewers the issue objective, the first-run-only scope, the capability-based decision, the managed-local Ready/tour invariant, relevant ADRs, changed files, and test evidence. Fix only technically valid findings, run focused validation for reviewer micro-fixes, and rerun `make check` only if a fix invalidates the prior full check.

Build an Android artifact only when explicitly requested and supported:

```bash
export PATH="$HOME/flutter/bin:$PATH" && \
HEY_CAPTION="Simplified first-run setup for issue 95" make android
```

Android APK builds are unreliable on ARM64 Linux; use GitHub Actions when the current host is ARM64.

## Risks & Mitigations

### High — First-run managed setup exits without a running server

**Cause:** The current local step’s final button always calls `_complete()`.

**Mitigation:** Suppress first-run completion unless the status is running, route success through `_connectionSuccess = true` and `Ready`, and verify profile/tour state in widget tests.

### High — Shared wizard regression in Settings

**Cause:** Welcome is reused by first-run and Settings.

**Mitigation:** Gate the simplified screen with `_isFirstRunFlow`, preserve the current chooser in a separate helper, and test `showSkipAction: false` explicitly.

### Medium — Primary action selected from viewport instead of capability

**Cause:** Responsive UI work may incorrectly infer platform from width.

**Mitigation:** Use only `localServerSupported`; test a narrow supported desktop-capability provider and a wide unsupported provider.

### Medium — Post-onboarding tour is not armed

**Cause:** `_complete()` checks `_connectionSuccess`.

**Mitigation:** Set `_connectionSuccess` only after confirmed local success, transition to Ready, and assert the flag changes only after final Ready completion.

### Medium — Localization overflow

**Cause:** Existing translations vary significantly in length.

**Mitigation:** Keep controls full-width and scrollable, use no fixed text height, test compact width with 2.0 scaling, and avoid new copy.

### Medium — Accessibility hierarchy differs from visual hierarchy

**Cause:** Reordered actions may retain an unexpected focus/semantic order.

**Mitigation:** Keep widget order identical to visual order, use standard Material buttons, preserve 48-pixel targets, and run accessibility guidelines.

### Low — Diagnostic and observability regression

**Cause:** Replacing callbacks could bypass setup-debug events.

**Mitigation:** Reuse the existing `_goTo*` callbacks without changing their event recording.

### Low — Scope expansion into chat onboarding or server internals

**Cause:** “Initial screen” can be interpreted broadly.

**Mitigation:** Restrict edits to first-run Welcome, managed first-run completion, its tests, and `BEHAVIOR.md`.

## Assumptions to Validate

1. **Assumption:** `AppProvider.localServerSupported` is a stable runtime capability signal.
   **Validation:** Inspect the injected local runtime in tests and verify supported/unsupported fakes drive the Welcome hierarchy independently of viewport.
   **Fallback:** If the signal can change during startup, keep the UI reactive through `context.select`; do not replace it with platform constants or width checks.

2. **Assumption:** Successful `startLocalServer()` creates and activates the managed local profile.
   **Validation:** Preserve and run `app_provider_test.dart` coverage at lines 406-432 and assert profile state in the new widget test.
   **Fallback:** If the provider test fails, fix the existing provider contract before allowing Ready transition; do not synthesize a profile in the page.

3. **Assumption:** Existing localization keys are sufficient.
   **Validation:** Compile every referenced key and inspect English and Portuguese rendering at compact width.
   **Fallback:** Add the smallest required key to the canonical ARB workflow, translate all supported locales through the project’s safe missing-key/merge-back process, and never run the destructive global generator.

4. **Assumption:** Settings users still need the complete chooser.
   **Validation:** Confirm all current Settings entry points pass `showSkipAction: false` and add the isolation test.
   **Fallback:** If a new entry point does not fit either context, add an explicit non-persisted presentation-mode parameter only after documenting the call-site contract; do not overload viewport or server-profile state.

5. **Assumption:** The existing 560-pixel max width remains appropriate.
   **Validation:** Manually inspect compact, medium, and expanded windows and run no-overflow tests.
   **Fallback:** Change only the Welcome max width to a single documented constant if controls or translations are visibly cramped; do not introduce a multi-pane layout.

## Decisions and Nuances

- Treat `showSkipAction` as more than a visual flag: it affects back behavior, skip behavior, completion, title/subtitle, and tour handoff. Use `_isFirstRunFlow` only for presentation and managed-first-run completion; preserve all other semantics.
- Keep the first-run and Settings views in the same widget to honor ADR-011, but give them separate private presentation helpers to prevent accidental scope leakage.
- Keep “Connect to a running server” as the secondary action because OpenCode can run locally, remotely, or elsewhere on the network. Do not imply a fixed localhost endpoint in Welcome copy.
- Keep “What is OpenCode?” discoverable because `BEHAVIOR.md` requires the relationship to be explained. Reduce visual weight rather than removing it.
- Keep Skip unchanged. Skipping without “Don’t show again” remains session-only; selecting “Don’t show again” remains persistent.
- Do not auto-start managed local setup merely because the Welcome primary action was tapped. Continue to show diagnostics and let the user explicitly start/install OpenCode.
- Auto-transition to Ready only after an explicit Start succeeds. If the server is already running, require the user to tap Continue.
- Never arm the chat tour from Settings or profile-edit flows.
- Do not change `AppProvider.startLocalServer()` because its provider contract and unit tests already establish healthy profile creation.
- Preserve all setup-debug events and diagnostic navigation.
- Do not use planner rankings or candidate comparisons during implementation; this file is the sole execution directive.

## Blockers and Open Questions

None in the product or technical design.

The execution preflight is mandatory. If another plan-anchored sequence remains active, do not begin implementation until it is completed or explicitly paused. Do not overwrite, restore, stage, or commit pre-existing user changes.

## Testing Strategy

The implementation is complete only when all of the following are true:

1. Unsupported capability shows guided setup as the only filled primary action.
2. Supported capability shows managed local setup as the only filled primary action.
3. Existing-server connection remains an outlined secondary action in both cases.
4. Unsupported managed local setup is absent, not disabled.
5. Narrow width does not change capability-based priority.
6. Settings retains the complete chooser and does not render first-run keys.
7. Direct initial flows continue to bypass Welcome correctly.
8. First-run managed local setup cannot complete while stopped or failed.
9. Successful managed local start creates/activates a profile and displays Ready.
10. The tour flag is false before Ready completion and true afterward.
11. Settings completion never arms the tour.
12. Existing skip behavior remains unchanged.
13. Existing failed-health recovery remains unchanged.
14. The screen has no overflow at 360×640 with 2.0 text scale.
15. Tappable actions meet 48×48 guidance and have readable labels/focus order.
16. Focused analysis, focused tests, provider tests, tour regressions, and `make check` all pass.
17. Reviewer findings contain no unresolved judge-approved critical or warning issue.

## Execution Handoff

Perform these actions in order before implementation:

1. Run `git status --short --branch` and record every pre-existing change. Do not modify, stage, restore, or include unrelated deleted files.
2. Recover the latest plan anchor:

```bash
PLAN_HASH=$(git log --grep="AGENT_PLAN_ANCHOR" -n 1 --pretty=format:%H)
git show "$PLAN_HASH"
git log --grep="PLAN_REF: $PLAN_HASH" --oneline
```

3. If that anchor still has an incomplete step, finish it or obtain explicit instruction to pause it. Do not create a competing plan sequence silently.
4. Re-read `AGENTS.md`, `BEHAVIOR.md`, ADR-011, ADR-023, and the exact source/test regions listed in this file.
5. Create an immutable `plan:` commit containing `AGENT_PLAN_ANCHOR` and a self-contained execution brief derived from this file before editing code, because this is multi-step resumable work.
6. Implement each numbered execution step as a separate `chore(agent): [Step X/Y] ...` progress commit that references the plan hash through `PLAN_REF` and the previous step through `PREVIOUS_STEP`.
7. Begin code work in `lib/presentation/pages/onboarding_wizard_page.dart`. Do not start in `AppShellPage`, providers, persistence, chat UI, or localization.
8. Add and run focused tests immediately after the widget change and managed completion change.
9. Update `BEHAVIOR.md` only after implementation behavior is verified.
10. Run all validation and reviewer gates before declaring delivery complete.

## Out of Scope

- Redesigning the chat empty state, session list, composer, or post-onboarding tour UI.
- Adding a carousel, marketing page, demo session, starter prompts, or illustration assets.
- Changing the AppShell first-run gate.
- Changing skip persistence or reset-app behavior.
- Adding first-use persistence or migrations.
- Changing server URL defaults, authentication, OAuth, Tailscale, or health-check behavior.
- Changing managed local installation/runtime internals in `AppProvider` or runtime services.
- Changing OpenCode API, event, provider, model, or session contracts.
- Changing the complete Settings setup chooser beyond moving its existing implementation into a private helper.
- Introducing responsive multi-column Welcome layouts.
- Rewriting localization copy or regenerating all ARB files.
- Updating `ADR.md` or `CODEBASE.md` without a separate, evidence-based need discovered during implementation.
- Committing or restoring unrelated pre-existing workspace changes.

## Definition of Done

- The first-run Welcome screen presents one capability-appropriate filled primary action and one existing-server secondary action.
- Unsupported managed local setup is absent.
- The Settings chooser remains functionally and visually equivalent to its pre-change behavior.
- First-run managed local setup cannot complete without a running healthy server.
- Successful managed local setup reaches Ready and arms the post-onboarding tour only after final completion.
- No new persistence, ADR exception, OpenCode contract change, or unrelated UI redesign is introduced.
- All targeted tests, provider tests, tour regressions, `make check`, and reviewer gates pass.
- `BEHAVIOR.md` describes only the verified delivered behavior.
