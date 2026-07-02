# Final Plan — Fix Desktop Composer Selection Stutter

## Status

Ready.

## Problem

On Windows and Linux desktop builds, changing the composer selection can cause a brief visible UI freeze/stutter. The affected actions are changing the composer Agent, Model, or Variant from the chip row by mouse selector or by keyboard shortcut cycling. The same kind of selection flow is reported smooth on Android.

## Objective

Make desktop composer selection changes update only the UI subtrees that actually depend on the selected agent/model/variant, while preserving the current provider/model/agent/variant behavior and persistence semantics. After implementation, desktop selection changes must no longer rebuild the full multi-pane desktop body, and all existing selection, shortcut cycling, favorites/recent models, and provider/model filtering behavior must continue to pass tests.

## Context and Constraints

- Project: CodeWalk Flutter/Dart app.
- Repository root: `/home/ubuntu/MEGA/WORK/codewalk`.
- Canonical task source: GitHub issue #60, plus follow-up issue #94.
- Current relevant behavior:
  - Composer provider/model/variant selection lives on the chat page.
  - Desktop layout can show multiple panes: conversation sidebar, file pane, chat pane, utility pane.
  - Android/mobile layout is narrower and does not render the same full desktop multi-pane body.
  - Selection setters in `ChatProvider` update current selection, record recency/memory, notify listeners, and schedule selection persistence.
  - `make check` is the required broad validation gate for CodeWalk; Android build is not required for this correction unless explicitly requested later.
- Relevant files:
  - `lib/presentation/pages/chat_page.dart`
  - `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart`
  - `lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart`
  - `lib/presentation/pages/chat_page/chat_page_status_presenter.dart`
  - `lib/presentation/pages/chat_page/chat_page_shortcuts.dart`
  - `lib/presentation/pages/chat_page/chat_page_scaffold.dart`
  - `lib/presentation/providers/chat_provider.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_selection_helpers.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_shortcut_cycle_ops.dart`
  - `test/widget/chat_page_test.dart`
- Existing instrumentation already available when logging + performance logging are enabled in the Logs page:
  - `selection_set_provider`
  - `selection_set_model`
  - `selection_set_agent`
  - `selection_set_variant`
  - `selection_cycle_model_shortcut`
  - `selection_cycle_agent_shortcut`
  - `selection_cycle_variant_shortcut`
  - `chat_notify_listeners`
  - `selection_persistence_flush`
  - `selection_persist_*`
- Important project rules:
  - Preserve existing behavior and style.
  - Prefer the smallest correct change.
  - Do not use `make precommit`; use targeted Flutter tests and `make check`.
  - For Flutter/Dart shell commands, prepend `export PATH="$HOME/flutter/bin:$PATH" && ...`.

## Decisions

1. Fix the desktop stutter by narrowing `ChatProvider` rebuild scope first.
2. Keep selection persistence behavior unchanged in the first correction pass.
3. Keep existing performance instrumentation unchanged, and use it for before/after validation.
4. Keep the message viewport guarded by its existing `Selector<ChatProvider, _ViewportBuildKey>`.
5. Introduce a small immutable selector/view-model for composer model controls so the chip row rebuilds only when fields it displays actually change.
6. Remove the broad `Consumer<ChatProvider>` from the desktop body path in `chat_page.dart`; read `ChatProvider` only where needed with `context.read`, `Consumer`, or `Selector`.
7. Do not rework storage/persistence until after rebuild fan-out is reduced and measured.

## Why This Plan

Independent planner review converged on the same primary cause: selection changes call `ChatProvider.notifyListeners`, and `chat_page.dart` currently wraps the desktop `Scaffold.body` in a broad `Consumer<ChatProvider>`. On desktop that rebuilds a much larger multi-pane tree than Android. Persistence and context-usage scans are credible secondary amplifiers, but the broad rebuild is the clearest desktop-vs-Android difference and should be fixed first.

## Overview

This change narrows `ChatProvider` listening in the chat page. The desktop shell and panes stay structurally stable while selection-only changes rebuild the composer controls and any small dependent widgets. The fix preserves the current selection setters, shortcut behavior, persistence behavior, and provider/model filtering. Validation focuses on widget tests proving desktop shortcut cycling still works and selection-only changes no longer force broad rebuilds.

## Steps

### 1. Create a composer selection view model

- **Files**: `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart` or a nearby `part` file already included by `chat_page.dart`.
- **Details**:
  - Add a private immutable class, for example `_ComposerSelectionBuildKey`, extending `Equatable` or implementing stable `==`/`hashCode`.
  - Include only fields required by `_buildModelControls` and its immediate composer selection UI:
    - `String? selectedProviderId`
    - `String? selectedModelId`
    - `String? selectedVariantId`
    - `String selectedVariantLabel`
    - `String? selectedAgentName`
    - `int providersVersion` if an existing provider-catalog version exists; otherwise use stable derived primitives such as provider count, selected provider model count, and provider refresh state.
    - `int agentsLength`
    - `int availableVariantsLength`
    - `int favoriteModelKeysLength`
    - `int recentModelKeysLength`
    - `int currentThreadPermissionRequestsLength` if the chip row reads permission request state.
    - `ProvidersRefreshState providersRefreshState` or its primitive equivalent.
  - Do not include full `List<Provider>`, `List<Agent>`, or `List<ModelVariant>` objects in equality unless their equality is already cheap and stable. Prefer primitive version/count/selected IDs.
  - Add a helper selector function in the same file:
    - `selector: (_, p) => _ComposerSelectionBuildKey.fromProvider(p)`.
- **Risk**: Medium — missing a dependency can cause the chip row to not rebuild when it should.
- **Validation**: Add tests in later steps that change model, agent, and variant and verify visible chip text updates.

### 2. Replace the composer controls `Consumer<ChatProvider>` with a narrow `Selector`

- **Files**: `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart` around the existing composer controls block.
- **Details**:
  - Replace the current broad composer controls consumer:
    - Existing area: `Consumer<ChatProvider>(builder: (_, cp, __) => _buildModelControls(cp, ...))`.
  - Use `Selector<ChatProvider, _ComposerSelectionBuildKey>`.
  - Inside the builder, call `_buildModelControls(context.read<ChatProvider>(), isSubConversation: isSubConversation)`.
  - Keep `_buildModelControls` signature unchanged in this pass to reduce risk.
  - Ensure selector equality causes rebuilds for all visible chip state changes:
    - selected model label changes;
    - selected agent label changes;
    - selected variant label changes;
    - provider refresh state changes;
    - provider/model catalog changes;
    - favorites/recent changes that alter model selector affordances.
- **Risk**: Medium — if the selector key is too broad the performance gain is smaller; if too narrow the UI can become stale.
- **Validation**: Run `flutter test test/widget/chat_page_test.dart --plain-name "desktop shortcuts cycle recent model and variant"` after this step.

### 3. Remove broad desktop body dependency on `ChatProvider`

- **Files**: `lib/presentation/pages/chat_page.dart` around the `Scaffold.body` builder.
- **Details**:
  - Replace `body: Consumer<ChatProvider>(builder: (context, chatProvider, child) { ... })` with a non-listening `Builder` or direct body builder that obtains `final chatProvider = context.read<ChatProvider>();` only for initial parameter passing.
  - Ensure desktop pane structure is driven by `SettingsProvider`, layout constraints, and local state, not by full `ChatProvider` listening.
  - Keep the mobile branch behavior equivalent by placing narrower consumers/selectors inside `_buildChatContent`, `_buildSessionPanel`, and composer controls where needed.
  - Do not remove existing internal consumers that are already scoped:
    - Keep `Selector<ChatProvider, _ViewportBuildKey>` for message viewport.
    - Keep the session panel consumer if it is responsible for session list updates.
    - Keep app bar consumers for undo/redo if they are already small.
  - Ensure `_buildDesktopFilePane` and `_buildDesktopUtilityPane` do not require the full outer body to rebuild on selection-only changes. If they need chat data, add their own narrow selectors inside those panes instead of passing a listening provider from the outer body.
- **Risk**: High — this is the main behavioral refactor and can accidentally prevent legitimate state changes from rebuilding the body.
- **Validation**:
  - Existing chat page widget tests must pass.
  - Add rebuild-probe tests in Step 5.

### 4. Keep context-usage recalculation scoped and avoid unnecessary invalidation

- **Files**: `lib/presentation/pages/chat_page/chat_page_status_presenter.dart`, `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart`.
- **Details**:
  - Leave `_resolveSessionContextUsage` functionally equivalent.
  - Confirm it is invoked only from a subtree that actually needs status/context usage, not from a broad desktop body rebuild.
  - Adjust its cache key only if needed after Step 3 shows selection-only changes still force full message scans:
    - Keep `messages.length` and `lastMessage.id` in the key.
    - Keep selected provider/model only when no assistant message with token/model data exists.
    - Do not invalidate the cache on variant-only changes.
  - Do not change quota fetching behavior in this pass.
- **Risk**: Medium — context usage must remain accurate after model/provider changes.
- **Validation**: Add or update a small unit/widget test only if cache behavior is changed. Otherwise rely on existing chat page tests plus manual performance logs.

### 5. Add a widget rebuild regression test

- **Files**: `test/widget/chat_page_test.dart`.
- **Details**:
  - Add a desktop-sized widget test near `desktop shortcuts cycle recent model and variant`.
  - Set a large desktop surface size with `tester.binding.setSurfaceSize(const Size(1200, 900))` and reset it in `addTearDown`.
  - Build a chat page with:
    - one session;
    - at least two selectable models;
    - one model with variants;
    - at least two agents.
  - Add a small test-only probe widget or counter in a stable desktop pane subtree if the existing architecture allows injection. Use the least invasive test hook available in current code. If no safe injection exists, assert the functional proxy instead:
    - model chip changes after shortcut;
    - variant chip changes after shortcut;
    - message viewport content remains stable;
    - session list remains stable;
    - no extra messages are added or lost.
  - The test must fail before the narrow-selector refactor if a practical rebuild counter can be inserted; if not practical, it must at least protect the behavior while the refactor is performed.
- **Risk**: Medium — rebuild-count tests can become brittle.
- **Validation**: Run the new test directly and the existing shortcut test.

### 6. Run targeted validation

- **Files**: no edits unless tests fail.
- **Details**:
  - Run these commands:
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "desktop shortcuts cycle recent model and variant"`
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "model selector"`
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/presentation/pages/chat_page.dart lib/presentation/pages/chat_page/chat_page_timeline_builder.dart lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart test/widget/chat_page_test.dart`
  - Fix any analyzer issues or test failures before continuing.
- **Risk**: Low.
- **Validation**: All targeted commands pass.

### 7. Run broad validation

- **Files**: no edits unless failures are directly related.
- **Details**:
  - Run:
    - `export PATH="$HOME/flutter/bin:$PATH" && make check`
  - Run `desloppify scan --path lib --profile objective` only if the repository has no active desloppify queue. If desloppify reports an existing queue and warns that scanning mid-cycle resets triage, do not force rescan; record the blocker in the final report.
- **Risk**: Low.
- **Validation**: `make check` passes.

### 8. Measure before/after with existing performance logs

- **Files**: no code edits required.
- **Details**:
  - In a desktop debug/profile run, open Logs.
  - Enable logging and `Measure performance`.
  - Filter by performance logs.
  - Reproduce:
    - mouse model selection;
    - keyboard model cycling;
    - keyboard variant cycling;
    - keyboard agent cycling.
  - Capture the slowest entries for:
    - `selection_set_model`
    - `selection_set_agent`
    - `selection_set_variant`
    - `selection_cycle_model_shortcut`
    - `selection_cycle_agent_shortcut`
    - `selection_cycle_variant_shortcut`
    - `chat_notify_listeners`
    - `selection_persistence_flush`
    - `selection_persist_*`
  - Confirm the `chat_notify_listeners` duration improves after the rebuild-scope refactor.
  - If `selection_persistence_flush` remains the largest duration after the rebuild fix, create a follow-up issue to debounce/coalesce or field-diff selection persistence.
- **Risk**: Low.
- **Validation**: Performance logs show reduced notify/rebuild cost or clearly identify persistence as the remaining bottleneck.

## Risks & Mitigations

- **High: stale UI after narrowing selectors** — Include all visible selection dependencies in `_ComposerSelectionBuildKey`; add tests for model, agent, and variant label updates.
- **High: desktop panes stop updating for legitimate chat/session changes** — Keep scoped consumers/selectors inside the panes that own those updates; do not remove the session panel's own consumer unless replacing it with an equivalent selector.
- **Medium: rebuild-count tests become brittle** — Prefer functional assertions unless a stable test hook already exists.
- **Medium: context usage becomes inaccurate after cache tuning** — Change cache keys only if measurement proves the scan remains costly after rebuild narrowing.
- **Medium: persistence still causes stutter after UI refactor** — Use existing performance logs to verify; defer persistence optimization to a separate follow-up if it remains dominant.
- **Low: performance logging itself adds overhead** — Use it only for diagnostic runs, not as a production behavior assumption.

## Assumptions to Validate

- **Assumption**: The broad desktop `Consumer<ChatProvider>` is the dominant cost.  
  **Validate**: Compare `chat_notify_listeners` logs and visible stutter before/after Step 3.  
  **Fallback**: If notify time remains high, inspect `selection_persistence_flush` and context usage scan timings next.

- **Assumption**: Existing scoped selectors already protect the message viewport from selection-only rebuilds.  
  **Validate**: Confirm `Selector<ChatProvider, _ViewportBuildKey>` remains in place and widget tests show message content stable during selection changes.  
  **Fallback**: If message viewport still rebuilds, add stricter selector keys or rebuild probes around `_buildMessageViewport`.

- **Assumption**: Selection persistence should not be changed in the first fix.  
  **Validate**: Performance logs after rebuild narrowing show persistence is not the dominant visible stall.  
  **Fallback**: If persistence dominates, implement a second focused fix that coalesces rapid selection writes and writes only changed fields.

## Decisions and Nuances

- Keep the implementation focused on rebuild scope, because this is the only cause that clearly explains why desktop is worse than Android.
- Do not remove the current performance logging. It is already valuable and directly supports this issue.
- Do not optimize `QuotaPopupSection` first. It watches `QuotaProvider`, not `ChatProvider`, and is a secondary suspect only when mounted under a broad rebuild.
- Do not redesign the whole desktop layout. Stabilize the existing layout by moving listeners down to smaller subtrees.
- Do not change selection behavior, shortcuts, favorites, recents, provider/model filtering, or multi-device sync semantics in this pass.

## Blockers and Open Questions

None for implementation.

Desktop DevTools traces on Windows/Linux and Android comparison remain useful validation artifacts, but they are not blockers for the first code correction because the code-level rebuild fan-out is clear and testable.

## Testing Strategy

Run, in order:

1. `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "desktop shortcuts cycle recent model and variant"`
2. `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "model selector"`
3. `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/presentation/pages/chat_page.dart lib/presentation/pages/chat_page/chat_page_timeline_builder.dart lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart test/widget/chat_page_test.dart`
4. `export PATH="$HOME/flutter/bin:$PATH" && make check`

Manual/performance validation on desktop:

1. Run a desktop debug/profile build.
2. Enable logging and performance logging from the Logs page.
3. Open a session with messages.
4. Change model by mouse.
5. Cycle model by keyboard.
6. Cycle variant by keyboard.
7. Cycle agent by keyboard.
8. Compare slowest performance entries before/after for `chat_notify_listeners`, `selection_set_*`, and `selection_persistence_flush`.

## Execution Handoff

Start in `lib/presentation/pages/chat_page.dart` at the `Scaffold.body` `Consumer<ChatProvider>` around line 2030. The first concrete goal is to remove full-body listening from the desktop branch while preserving scoped listening in the chat content and composer controls. Then move to `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart` and replace the composer controls `Consumer<ChatProvider>` with a narrow `Selector` based on a small immutable selection build key. Validate after each change with the targeted widget tests.

## Out of Scope

- Rewriting the desktop layout architecture.
- Changing the public API of `setSelectedAgent`, `setSelectedModelByProvider`, `setSelectedVariant`, `cycleRecentModelShortcut`, `cycleVariant`, or `cycleAgent`.
- Changing provider/model filtering behavior.
- Changing persistence semantics in the first correction pass.
- Changing quota loading behavior.
- Generating or uploading an Android build.
