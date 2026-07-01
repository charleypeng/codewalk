# Issue #65 Execution Plan — Split Oversized Dart Files

## Status

Ready.

This plan is ready for implementation of the first PR and provides the decided multi-PR sequence for the rest of issue #65. There are no blockers for the first PR. Later boundary cases are resolved by explicit rules in this plan: do not hand-edit generated output, do not move interface `@override` methods into extensions, and do not move public provider API methods into private extensions.

## Problem

CodeWalk has several Dart source and test files that exceed the maintainability thresholds defined in GitHub issue #65:

- Source files should be under 1500 lines, except justified barrels or explicitly documented exceptions.
- Test files should be under 3000 lines.
- Existing large files make navigation, code review, ownership, debugging, and targeted testing harder.
- The repository already uses Dart `part` / `part of` files in several large modules, and issue #65 asks to extend that pattern while preserving behavior.

The task is to execute the refactor safely as a sequence of small PRs. Each PR must split one file, or one tightly coupled pair, without changing behavior or public APIs.

## Objective

Complete issue #65 through mechanical file splits that preserve the current runtime behavior and public API while reducing oversized files.

The first implementation PR must split `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart` into cohesive part files, keep all external imports unchanged, keep all tests unchanged, and pass targeted provider tests plus final `make check`.

## Context and Constraints

### Project Context

- Repository: `verseles/codewalk`
- Workspace path: `/home/ubuntu/MEGA/WORK/codewalk`
- Stack: Flutter / Dart mobile and desktop client for OpenCode.
- Project-specific rules are in `AGENTS.md`.
- `BEHAVIOR.md` documents implemented behavior only.
- `CODEBASE.md` is the code map and must be updated through the `codemapper` flow when structure changes materially.
- `ADR.md` stores architecture decisions and must be checked/updated through the `adrkeeper` flow when this work confirms or changes architectural constraints.

### Validation Rules

- For all Flutter/Dart commands in non-interactive shells, prepend:
  ```bash
  export PATH="$HOME/flutter/bin:$PATH"
  ```
- Use targeted `flutter analyze <paths>` and `flutter test <paths>` while iterating.
- Use `make check` at final validation gates.
- Do not use `make precommit` for normal CodeWalk validation.
- Do not run `dart tool/i18n/generate_arb.dart`; it is destructive to newer `.arb` keys.
- Do not touch generated files under `lib/l10n/generated/`, `*.g.dart`, or `*.freezed.dart`.
- Do not add dependencies, lint suppressions, public API changes, behavior changes, renames, or broad cleanup.

### Existing Dart Part Pattern

Use the established CodeWalk pattern:

- Keep the public class or module barrel file as the import target.
- Add `part 'subfolder/file.dart';` declarations to the root barrel file.
- Each part file starts with `part of '../root_barrel.dart';` or the correct relative path to the root barrel.
- Move cohesive private helper groups into private extensions on the original class or state type.
- Do not create chained part-file barrels. Dart part files belong to the root library; they do not become independent sub-libraries.

Existing examples:

- `lib/presentation/providers/chat_provider.dart` declares `part 'chat_provider/...';` and uses files under `lib/presentation/providers/chat_provider/` with `part of '../chat_provider.dart';`.
- `lib/presentation/pages/chat_page.dart` declares `part 'chat_page/...';` and uses files under `lib/presentation/pages/chat_page/` with `part of '../chat_page.dart';`.

### Relevant Current Line Counts

The relevant line counts from the planning investigation are:

- `lib/presentation/providers/chat_provider.dart` — 4528 lines, accepted as a multi-part barrel.
- `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart` — 1863 lines, largest current `chat_provider/` part file and the first PR target.
- `lib/presentation/theme/opencode_web_theme_registry.dart` — 2657 lines, generated/boundary case.
- `lib/data/datasources/chat_remote_datasource.dart` — 2401 lines, interface-implementation boundary case.
- `lib/presentation/pages/chat_page.dart` — 2283 lines, barrel.
- `lib/presentation/providers/app_provider.dart` — 1995 lines, public provider API surface.
- `lib/presentation/pages/chat_page/chat_page_chrome.dart` — 1793 lines.
- `lib/data/datasources/app_local_datasource.dart` — 1746 lines.
- `lib/presentation/pages/settings/sections/speech_settings_section.dart` — 1690 lines.
- `lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart` — 1687 lines.
- `lib/presentation/providers/settings_provider.dart` — 1644 lines.
- `lib/presentation/widgets/chat_input_widget.dart` — 1623 lines.
- `lib/presentation/pages/chat_page/chat_page_scaffold.dart` — 1622 lines.

Oversized test files include:

- `test/widget/chat_page_test.dart` — 17919 lines.
- `test/unit/providers/chat_provider_realtime_test.dart` — 4637 lines.
- `test/widget/chat_message_widget_test.dart` — 4124 lines.

## Decisions (Resolved)

1. Start with `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`.
   - It is already a part file in the established `chat_provider` split pattern.
   - It has no direct external import contract.
   - It contains private reducer/helper behavior inside the `chat_provider.dart` library.
   - Splitting it requires no test-file edits and no public API changes.

2. Use flat sibling part files for the first PR.
   - Create new files directly under `lib/presentation/providers/chat_provider/`.
   - Do not create `lib/presentation/providers/chat_provider/event_reducer/` for the first PR.
   - Do not make `chat_provider_event_reducer_ops.dart` into a sub-barrel.

3. Delete `chat_provider_event_reducer_ops.dart` after all content is moved.
   - Replace its single `part` directive in `chat_provider.dart` with three new directives.
   - Do not keep an empty or directive-only intermediate file.

4. Keep public API methods in their class bodies for later provider/data-source splits.
   - Public methods must not be moved into private extensions.
   - Interface `@override` methods must not be moved into extensions.
   - If a later file cannot be brought under the line threshold by moving private helpers only, document it as a justified exception or execute a separate approved delegation/mixin refactor.

5. Treat generated output as generator-owned.
   - Do not manually split `opencode_web_theme_registry.dart` unless the generator is changed in the same PR.
   - Prefer documenting it as a generated-file exception unless the issue owner explicitly wants generator work.

6. Split tests as standalone test files, not production-style `part` files.
   - Extract shared helpers into `test/support/` when needed.
   - Preserve every existing `test` / `testWidgets` name and assertion.

## Why This Plan

This plan starts with the safest high-value split: the largest existing `chat_provider` part file. It avoids the two main correctness traps identified during planning: moving public provider methods into private extensions and moving interface override methods into extensions. It also avoids manual edits to generated files. The first PR is mechanical, test-preserving, and narrow enough for review, while the later sequence handles larger or riskier files only after the team has a validated split pattern from the first PR.

## Overview

Implement issue #65 as a multi-PR refactor. The first PR splits `chat_provider_event_reducer_ops.dart` into helper, session-event, and global-event part files. Subsequent PRs split other oversized source files by increasing risk and complexity, then split oversized tests into standalone files with shared test support. Every PR is behavior-preserving, validates through targeted checks, and ends with `make check`.

## Steps

### 1. Prepare and verify the first PR target

- **Files**: `lib/presentation/providers/chat_provider.dart`, `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
- **Details**:
  1. Confirm the working tree state before editing:
     ```bash
     git status --short
     ```
     If unrelated user changes are present, do not overwrite them; coordinate before editing.
  2. Confirm the current part directive in `chat_provider.dart`:
     ```bash
     grep -n "chat_provider_event_reducer_ops.dart" lib/presentation/providers/chat_provider.dart
     ```
  3. Confirm current method boundaries in the reducer file immediately before editing:
     ```bash
     grep -nE '^  (void|bool|String|Map<|ChatSession|ChatEvent|SessionStatusInfo|\(\{).*\{' lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart
     ```
  4. Use the following current line-range boundaries as the implementation map, then re-verify before moving because line numbers may drift:
     - Helper and feedback parsing methods: lines 4–285.
     - Session-scoped event application: lines 286–1152.
     - Global event reconciliation and inactive snapshot handling: lines 1154–1862.
- **Risk**: Low. This is a read/verification step only.
- **Validation**: Method map exists and the single old part directive is present before editing.

### 2. Create `chat_provider_event_reducer_helpers.dart`

- **Files**: create `lib/presentation/providers/chat_provider/chat_provider_event_reducer_helpers.dart`
- **Details**:
  1. Create the new file with this header:
     ```dart
     part of '../chat_provider.dart';

     extension _ChatProviderEventReducerHelpers on ChatProvider {
       // moved methods go here
     }
     ```
  2. Move the helper/feedback parsing methods from the old extension into this new extension, preserving method bodies exactly and preserving their relative order.
  3. Move these methods from the current reducer file:
     - `_eventInfoContainsAny`
     - `_mergeSessionFromEventInfo`
     - `_eventPayloadOrNested`
     - `_refreshPendingInteractionsForEvent`
     - `_composeEventDeduplicationKey`
     - `_isRecentlyProcessedEvent`
     - `_hasInFlightSendTurnForSession`
     - `_isNonCurrentSessionEvent`
     - `_shouldHandleFeedbackForEvent`
     - `_shouldSuppressAggressiveDataSaverEvent`
     - `_isRootSessionInList`
     - `_feedbackEventForCurrentContext`
     - `_parseStatusForFeedback`
     - `_sessionIdleFeedbackEventFromStatus`
     - `_extractSessionErrorMessageAndCode`
  4. Do not move imports; part files share the root barrel imports.
  5. Do not rename any method.
  6. Do not change any method body.
- **Risk**: Low. These are private library helpers already used inside the same `chat_provider.dart` library.
- **Validation**: New file starts with `part of '../chat_provider.dart';` and contains exactly the helper group.

### 3. Create `chat_provider_event_reducer_session_ops.dart`

- **Files**: create `lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart`
- **Details**:
  1. Create the new file with this header:
     ```dart
     part of '../chat_provider.dart';

     extension _ChatProviderEventReducerSessionOps on ChatProvider {
       // moved methods go here
     }
     ```
  2. Move the session-scoped event application methods into this extension, preserving order and bodies exactly:
     - `_applyChatEvent`
     - `_applyChatEventInner`
  3. Keep the entire `_applyChatEventInner` switch body intact.
  4. Do not split this large switch further in the first PR.
- **Risk**: Medium-low. The event switch is central realtime behavior, but the move is mechanical and remains in the same library.
- **Validation**: The full switch block is present in the new file and no `case` branch is lost or duplicated.

### 4. Create `chat_provider_event_reducer_global_ops.dart`

- **Files**: create `lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart`
- **Details**:
  1. Create the new file with this header:
     ```dart
     part of '../chat_provider.dart';

     extension _ChatProviderEventReducerGlobalOps on ChatProvider {
       // moved methods go here
     }
     ```
  2. Move the global-event and inactive-snapshot reconciliation group into this extension, preserving order and bodies exactly:
     - `_handleGlobalEvent`
     - `_tryApplyGlobalEventIncremental`
     - `_scheduleGlobalFallbackReconcile`
     - `_tryApplyGlobalEventToInactiveSnapshot`
     - `_feedbackEventForInactiveContext`
     - `_dispatchFeedbackForInactiveContextEvent`
     - `_sessionTitleForNotificationInList`
     - `_dismissResolvedInactiveInteractionFeedback`
     - `_scheduleCurrentContextRefresh`
  3. Keep `_scheduleCurrentContextRefresh` in the global file because both direct global handling and session fallback behavior depend on it.
- **Risk**: Medium-low. This group touches global stream reconciliation but remains private and library-local.
- **Validation**: New file includes every method from current lines 1154–1862 and ends with a single closing brace for the extension.

### 5. Replace the old part directive in `chat_provider.dart`

- **Files**: `lib/presentation/providers/chat_provider.dart`
- **Details**:
  1. Replace:
     ```dart
     part 'chat_provider/chat_provider_event_reducer_ops.dart';
     ```
     with:
     ```dart
     part 'chat_provider/chat_provider_event_reducer_helpers.dart';
     part 'chat_provider/chat_provider_event_reducer_session_ops.dart';
     part 'chat_provider/chat_provider_event_reducer_global_ops.dart';
     ```
  2. Keep the new directives near the original reducer directive location so the part list remains easy to scan.
  3. Do not change unrelated part directive ordering.
- **Risk**: Low. Incorrect part paths fail fast in analyzer.
- **Validation**: `grep -n "chat_provider_event_reducer" lib/presentation/providers/chat_provider.dart` shows exactly the three new directives and no old directive.

### 6. Remove the old reducer part file

- **Files**: delete `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
- **Details**:
  1. Delete the old file only after all moved groups are present in the three new files.
  2. Confirm no remaining references to the deleted file:
     ```bash
     grep -R "chat_provider_event_reducer_ops.dart" -n lib test
     ```
     This command must return no matches.
  3. Confirm line counts:
     ```bash
     wc -l \
       lib/presentation/providers/chat_provider/chat_provider_event_reducer_helpers.dart \
       lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart \
       lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart
     ```
     Each new source file must be below 1500 lines.
- **Risk**: Low if the previous validation has confirmed no stale directive remains.
- **Validation**: Old file path no longer exists; three replacement files exist and are below threshold.

### 7. Format and analyze the first PR

- **Files**: first PR touched files only.
- **Details**:
  1. Format the touched files:
     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && dart format \
       lib/presentation/providers/chat_provider.dart \
       lib/presentation/providers/chat_provider/chat_provider_event_reducer_helpers.dart \
       lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart \
       lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart
     ```
  2. Run focused analyzer:
     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && flutter analyze \
       lib/presentation/providers/chat_provider.dart \
       lib/presentation/providers/chat_provider/
     ```
- **Risk**: Low. Analyzer catches part path, duplicate method, missing method, and syntax errors.
- **Validation**: Analyzer passes without new errors attributable to this PR.

### 8. Run focused provider tests for the first PR

- **Files**: no test files should be edited for PR 1.
- **Details**:
  1. Run the highest-value realtime provider test:
     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/providers/chat_provider_realtime_test.dart
     ```
  2. Run related provider tests that exercise messaging, session ops, sync, concurrency, and project behavior:
     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && flutter test \
       test/unit/providers/chat_provider_messaging_test.dart \
       test/unit/providers/chat_provider_session_ops_test.dart \
       test/unit/providers/chat_provider_concurrency_test.dart \
       test/unit/providers/chat_provider_sync_test.dart \
       test/unit/providers/chat_provider_project_test.dart
     ```
  3. If the command runner supports multiple paths poorly, run each listed test file separately.
- **Risk**: Medium. These tests may be slower or may expose unrelated existing instability; capture exact failure output if that occurs.
- **Validation**: All listed tests pass or any unrelated pre-existing failure is documented with evidence and re-run after confirming no reducer split regression.

### 9. Run final validation for the first PR

- **Files**: entire project validation.
- **Details**:
  1. Run final gate:
     ```bash
     export PATH="$HOME/flutter/bin:$PATH" && make check
     ```
  2. Capture final line-count proof for the PR description:
     ```bash
     wc -l \
       lib/presentation/providers/chat_provider/chat_provider_event_reducer_helpers.dart \
       lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart \
       lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart
     ```
  3. Include in the PR description:
     - Old file: `chat_provider_event_reducer_ops.dart` was 1863 lines.
     - New files: list each replacement file and its line count.
     - Public API unchanged.
     - No tests were edited.
     - Targeted provider tests and `make check` passed.
- **Risk**: Medium due to full-suite duration and possible unrelated failures.
- **Validation**: `make check` passes before finalizing the first PR.

### 10. Sync documentation after the first PR code is stable

- **Files**: `CODEBASE.md`, `ADR.md` only through appropriate doc flows.
- **Details**:
  1. Ask `codemapper` to update `CODEBASE.md` for the new `chat_provider_event_reducer_*` part files.
  2. Ask `adrkeeper` whether `ADR.md` needs a note. For this first PR, no architectural decision changes; an ADR update is needed only if the repo already records the file-splitting policy and should mention the reducer split.
  3. Do not manually edit `CODEBASE.md` or `ADR.md` unless the doc subagent flow explicitly hands back an editable patch plan for the main executor.
- **Risk**: Low.
- **Validation**: Documentation changes, if any, are narrowly scoped to the structural split.

### 11. Execute subsequent source splits in this order

- **Files**: one PR per listed file or tightly coupled pair.
- **Details**:
  1. Split `lib/presentation/widgets/chat_input_widget.dart`.
     - Create `chat_input/chat_input_draft_focus_ops.dart` and `chat_input/chat_input_speech_runtime_ops.dart`.
     - Move only private `_ChatInputWidgetState` helpers.
     - Keep `initState`, `dispose`, `didUpdateWidget`, and `build` in the class.
  2. Split `lib/presentation/pages/settings/sections/speech_settings_section.dart`.
     - Create `speech_settings_section/speech_settings_section_cards.dart`, `speech_settings_section_model_ops.dart`, and `speech_settings_section_read_aloud_card.dart`.
     - Move private `_SpeechSettingsSectionState` card builders and model operations only.
  3. Split `lib/presentation/providers/settings_provider.dart`.
     - Extend the existing split pattern.
     - Move private helpers only.
     - Keep public settings API methods in the class.
  4. Split the oversized chat-page part files, one PR each:
     - `lib/presentation/pages/chat_page/chat_page_scaffold.dart`
     - `lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart`
     - `lib/presentation/pages/chat_page/chat_page_chrome.dart`
     - Each new file must point to the root library with the correct `part of '../chat_page.dart';` relative path when placed directly under `chat_page/`.
  5. Split `lib/data/datasources/app_local_datasource.dart`.
     - Verify whether remaining oversized content is private helper logic or public abstract/concrete method surface.
     - Move private helper/entity groups only unless an explicit wrapper/delegation refactor is approved.
  6. Split `lib/presentation/providers/app_provider.dart`.
     - First classify every candidate method as public or private.
     - Keep all public `AppProvider` methods in the class body.
     - Move private runtime, diagnostics, sanitization, and helper clusters into parts.
     - If private-only extraction cannot bring the file under 1500 lines, document a justified exception or create a separate ADR-backed wrapper/delegation plan.
  7. Treat `lib/data/datasources/chat_remote_datasource.dart` as a boundary case.
     - Do not move `@override` methods from `ChatRemoteDataSourceImpl` into extensions.
     - Keep the interface and concrete override signatures in the class.
     - Either document a justified exception or create a separate ADR-backed delegation/mixin refactor if the issue owner requires reducing this file below 1500.
  8. Treat `lib/presentation/theme/opencode_web_theme_registry.dart` as a generated-file boundary case.
     - Do not manually split generated output.
     - If split is required, modify `tool/theme/generate_opencode_web_themes.py` or the relevant generator so it emits multiple part files, then run the repository theme validation target.
     - Otherwise document this as a generated-file exception.
- **Risk**: Medium to high for later provider/data-source/generated cases.
- **Validation**: Every PR repeats the pattern: targeted format, targeted analyze, targeted tests, line-count proof, final `make check`, doc sync if structure changes.

### 12. Split oversized tests after source split pattern is stable

- **Files**: oversized test files.
- **Details**:
  1. Split `test/widget/chat_page_test.dart` first.
     - Extract shared helpers and fakes into `test/support/chat_page_test_support.dart` or another clearly named support file.
     - Split test blocks into feature-scoped files such as sidebar, composer, timeline, chrome, model selector, file/runtime, and responsive behavior.
     - Keep each resulting test file under 3000 lines.
  2. Split `test/unit/providers/chat_provider_realtime_test.dart`.
     - Separate session-stream/global-event/reconnection/degraded-mode tests into files under 3000 lines.
     - Extract shared provider setup into `test/support/` if duplicated.
  3. Split `test/widget/chat_message_widget_test.dart`.
     - Separate text/rendering, tool/reasoning, attachments, and interaction tests.
  4. Before and after every test split, count test declarations:
     ```bash
     grep -R "testWidgets\|test(" -n test/widget/chat_page_test.dart test/widget test/unit/providers | wc -l
     ```
     Use a more targeted before/after command for the specific file being split. The number of tests for the split scope must not decrease.
  5. Preserve every existing test name string exactly.
- **Risk**: High for `chat_page_test.dart` due size and shared setup.
- **Validation**: Each new test file runs individually; the original test group runs through the new files; final `make check` passes.

## Risks & Mitigations

### Critical

- **Risk**: Moving `@override` methods from an interface implementation into extensions breaks the interface contract.
  - **Mitigation**: Do not do this. Keep `ChatRemoteDataSourceImpl` override signatures in the class. Treat `chat_remote_datasource.dart` as a boundary case unless a separate ADR-backed delegation refactor is approved.

- **Risk**: Moving public provider methods into private extensions changes or breaks the public API.
  - **Mitigation**: For provider files, classify every candidate method before moving. Move only underscore-prefixed private helpers in mechanical split PRs. Keep public methods in the class.

- **Risk**: Hand-editing generated files creates changes that will be overwritten by generators.
  - **Mitigation**: Do not manually split `opencode_web_theme_registry.dart`. Change the generator or document a generated-file exception.

### High

- **Risk**: A method block is lost or duplicated while splitting `chat_provider_event_reducer_ops.dart`.
  - **Mitigation**: Move three contiguous groups only, verify method maps before and after, run analyzer, run provider tests, and delete the old file only after replacement files are complete.

- **Risk**: Test splits lose or rename tests.
  - **Mitigation**: Count tests before/after, preserve every test name string, and run new test files individually.

### Medium

- **Risk**: Cross-extension private helper calls fail after splitting.
  - **Mitigation**: This repository already uses cross-extension private helpers in `chat_provider`; still, run analyzer immediately after the split. If a specific helper call fails, keep that helper in the same extension as its caller rather than rewriting broad call sites.

- **Risk**: Later files cannot reach the line threshold through private-helper extraction alone.
  - **Mitigation**: Use the resolved exception path: document a justified exception in CODEBASE/ADR or open a separate ADR-backed delegation refactor. Do not break API to satisfy a line-count target.

### Low

- **Risk**: Incorrect `part of` relative path.
  - **Mitigation**: For first PR replacement files under `lib/presentation/providers/chat_provider/`, use exactly `part of '../chat_provider.dart';`.

## Assumptions to Validate

1. The reducer method ranges still match the current file when implementation starts.
   - **Verify with**: method-boundary grep in Step 1.
   - **Fallback if false**: preserve the same conceptual groups by method name, not by stale line number.

2. No tests directly import `chat_provider_event_reducer_ops.dart`.
   - **Verify with**:
     ```bash
     grep -R "chat_provider_event_reducer_ops.dart" -n test lib
     ```
   - **Fallback if false**: update any direct import to `chat_provider.dart`, because direct imports of part files are invalid architecture for this repo.

3. The first PR does not require behavior documentation in `BEHAVIOR.md`.
   - **Verify with**: confirm that the diff is mechanical movement only.
   - **Fallback if false**: if behavior changes are discovered, stop and treat the change as out of scope for issue #65.

4. The first PR does not require ADR changes.
   - **Verify with**: ask `adrkeeper` after code is stable.
   - **Fallback if false**: let the ADR flow add a narrow note about the established part-file split policy.

## Decisions and Nuances

- The first PR intentionally targets an existing part file, not a new top-level provider/widget split, because it is the lowest-risk high-impact refactor available.
- Flat sibling part files are mandatory for the first PR. Do not introduce nested `event_reducer/` subfolders or chained part barrels.
- `chat_input_widget.dart` and `speech_settings_section.dart` are strong follow-up candidates because their splits are private-state widget/helper extractions.
- `app_provider.dart` and `chat_remote_datasource.dart` require public/private or interface-boundary classification before any split. They are not safe first PRs.
- `opencode_web_theme_registry.dart` is generator-owned. The plan resolves this by generator change or documented exception, not manual output edits.
- Source-file splits and test-file splits are separate workstreams. Do not combine a production source split with a large test-file split in the same PR unless the test split is strictly required by import changes.

## Blockers and Open Questions

None for the first PR.

Later boundary cases are decided, not open:

- `chat_remote_datasource.dart`: do not move interface overrides into extensions; use exception or separate ADR-backed delegation refactor.
- `opencode_web_theme_registry.dart`: do not hand-edit generated output; use generator change or generated-file exception.
- `app_provider.dart`: do not move public methods into private extensions; move private helpers only or document exception.

## Testing Strategy

### First PR Tests

Run after moving the reducer into three part files:

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze \
  lib/presentation/providers/chat_provider.dart \
  lib/presentation/providers/chat_provider/
```

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/providers/chat_provider_realtime_test.dart
```

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter test \
  test/unit/providers/chat_provider_messaging_test.dart \
  test/unit/providers/chat_provider_session_ops_test.dart \
  test/unit/providers/chat_provider_concurrency_test.dart \
  test/unit/providers/chat_provider_sync_test.dart \
  test/unit/providers/chat_provider_project_test.dart
```

Final gate:

```bash
export PATH="$HOME/flutter/bin:$PATH" && make check
```

### Later Source PR Tests

For each later source split:

1. Run `dart format` on touched source files.
2. Run `flutter analyze` on the root barrel and new part folder.
3. Run the narrowest directly related tests.
4. Run `make check` before finalizing the PR.
5. Record before/after line counts in the PR description.

### Later Test PR Tests

For each test split:

1. Count tests before moving blocks.
2. Move complete `group`, `test`, and `testWidgets` blocks only.
3. Extract shared setup into `test/support/` when needed.
4. Run every new test file individually.
5. Run the broader affected test directory.
6. Run `make check` before finalizing the PR.

## Execution Handoff

Start here:

1. Open `lib/presentation/providers/chat_provider.dart` and verify the current `part 'chat_provider/chat_provider_event_reducer_ops.dart';` directive.
2. Open `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart` and verify the three contiguous groups:
   - helpers: methods before `_applyChatEvent`
   - session ops: `_applyChatEvent` and `_applyChatEventInner`
   - global ops: methods from `_handleGlobalEvent` through `_scheduleCurrentContextRefresh`
3. Create the three replacement files in `lib/presentation/providers/chat_provider/`.
4. Move code mechanically with no method renames, no behavior changes, no import changes, and no test edits.
5. Replace the old part directive with the three new directives.
6. Delete the old reducer file.
7. Format, analyze, run focused provider tests, run `make check`, then update CODEBASE/ADR only through the appropriate doc flows if needed.

## Out of Scope

- Implementing any behavior change.
- Renaming methods, classes, variables, files beyond the new part file names, or test names.
- Reordering methods for style.
- Adding dependencies.
- Adding lint suppressions.
- Touching generated code manually.
- Running `dart tool/i18n/generate_arb.dart`.
- Combining multiple unrelated source-file splits into one PR.
- Combining a large test split with the first source split.
- Committing or pushing unless explicitly requested.
