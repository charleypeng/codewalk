# ROADMAP.featP - Giant File Decomposition & Orchestrator Architecture

## Scope

Refactor oversized presentation files into cohesive, testable modules while preserving behavior, UX flows, and public APIs consumed across the app. The focus is to transform current "god files" into orchestration layers that delegate to extracted domain-focused builders, controllers, and helper units.

The work targets:

- `lib/presentation/pages/chat_page.dart`
- `lib/presentation/providers/chat_provider.dart`
- `lib/presentation/widgets/chat_input_widget.dart`

## Why now

- Current file size makes review, onboarding, and bug isolation expensive.
- Merge conflicts are frequent in high-churn files, slowing delivery.
- Localized testing is hard because concerns are mixed (UI build, orchestration, side effects, parsing, state transitions).
- Upcoming backlog features (`featF`, `featG`, `featN`) will compound risk if architecture remains concentrated.
- Technical debt has reached a point where small changes require broad context loading and increase regression probability.

## Current baseline (line counts)

- `lib/presentation/pages/chat_page.dart` ~8009
- `lib/presentation/providers/chat_provider.dart` ~5835
- `lib/presentation/widgets/chat_input_widget.dart` ~2013

## Post-execution snapshot (2026-02-19)

- `lib/presentation/pages/chat_page.dart` 4635 (from ~8009, -3374)
- `lib/presentation/providers/chat_provider.dart` 3886 (from ~5835, -1949)
- `lib/presentation/widgets/chat_input_widget.dart` 1148 (from ~2013, -865)
- New extracted modules:
  - `lib/presentation/pages/chat_page/` (12 part modules)
  - `lib/presentation/providers/chat_provider/` (10 part modules)
  - `lib/presentation/widgets/chat_input/` (8 part modules)

## Current decomposition state (already done before featP execution)

The following preparatory splits are already present and should be treated as the starting point:

- `lib/presentation/pages/chat_page_types_part.dart`
- `lib/presentation/providers/chat_provider_types_part.dart`
- `lib/presentation/providers/chat_provider_draft_part.dart`
- `lib/presentation/widgets/chat_input_widget_types_part.dart`

Execution must continue from this baseline (do not re-discover or re-plan these extractions).

## No-discovery extraction inventory (executor handoff)

Use this as the authoritative extraction map so the executing agent does not need exploratory search.

### `chat_page.dart` extraction clusters (anchor ranges)

- **Lifecycle, foreground, route activity, auto-follow** (~L261-L840)
  - Anchors: `_handleSettingsChanged`, `_applyForegroundPolicy`, `_handleServerScopeChange`, `_handleReturnToChat`, `_handleScrollChanged`, `_syncChatRouteActivity`, `_runScrollToBottom`.
  - Destination: `chat_page_scroll_coordinator.dart` + `chat_page_lifecycle.dart`.
- **Workspace/project operations** (~L846-L1161)
  - Anchors: `_switchProjectContext`, `_closeProjectContext`, `_reopenProjectContext`, `_archiveClosedProjectContext`, `_createWorkspace`, `_openDirectoryPicker`, `_resetWorkspace`, `_deleteWorkspace`.
  - Destination: `chat_page_workspace_controller.dart`.
- **Keyboard shortcuts + command dispatch** (~L1185-L1514)
  - Anchors: `_focusInput`, `_activeShortcutActions`, `_handleGlobalShortcutKeyEvent`, `_invokeShortcutAction`, `_handleEscape`, `_requestStopActiveResponse`, `_cycleRecentModel`.
  - Destination: `chat_page_shortcuts.dart`.
- **Server/context status and popovers** (~L1984-L2382)
  - Anchors: `_compactCurrentSession`, `_resolveSessionContextUsage`, `_buildContextUsageControl`, `_buildContextUsagePopover`, `_syncStatusLabel`, `_serverStatusLabel`, `_buildServerStatusControl`.
  - Destination: `chat_page_status_presenter.dart`.
- **Selectors, session panel, navigation chrome** (~L2509-L3397)
  - Anchors: `_buildProjectSelectorTitle`, `_openProjectSelectorDialog`, `_buildProjectSelectorDialogContent`, `_buildSessionDrawer`, `_buildSidebarNavigation`, `_buildSessionPanel`, `_buildDesktopUtilityPane`.
  - Destination: `chat_page_scaffold.dart` + `chat_page_selector_flow.dart`.
- **Files explorer and file viewer stack** (~L3397-L5153)
  - Anchors: `_buildDesktopFilePane`, `_resolveFileContextState`, `_loadDirectoryNodes`, `_openQuickFileDialog`, `_openFileInTab`, `_buildFileExplorerPanel`, `_buildFileViewerPanel`.
  - Destination: `chat_page_file_explorer_controller.dart` + `chat_page_file_viewer.dart`.
- **Timeline/composer/model controls** (~L5184-L7475)
  - Anchors: `_buildChatContent`, `_buildMessageViewport`, `_buildMessageList`, `_buildMessageTimelineEntries`, `_scheduleCompactionStateSync`, `_resolveComposerStatusTarget`, `_queryMentionSuggestions`, `_querySlashSuggestions`, `_handleBuiltinSlashCommand`.
  - Destination: `chat_page_timeline_builder.dart` + `chat_page_composer_status.dart` + `chat_page_command_query.dart`.
- **Data/type declarations at tail** (~L7512-EOF)
  - Anchors: `_FileTabViewState`, `_TimelineEntry` subclasses, `_ComposerStatusPresentation`, `_DirectoryPickerSheet`.
  - Destination: keep in dedicated type files; avoid growing orchestrator file.

### `chat_provider.dart` extraction clusters (anchor ranges)

- **Core state/error policy helpers** (~L567-L703)
  - Anchors: `_setState`, `_setProvidersRefreshState`, `_setError`, `_isAbortSuppressionActiveForSession`, `_isRemoteAbortError`, `_shouldSuppressAbortError`.
  - Destination: `chat_provider_error_policy.dart`.
- **Remote selection synchronization** (~L703-L1402)
  - Anchors: `_parseRemoteChatSelection`, `_loadRemoteChatSelection`, `_syncSelectionFromRemote`, `_buildSelectionSyncPayload`, `_syncSelectedModelToRemoteConfig`, `_runSelectionSyncTransaction`.
  - Destination: `chat_provider_selection_sync_ops.dart`.
- **Session override/context persistence** (~L1495-L1873)
  - Anchors: `_composeContextKey`, `_sessionOverridesForContext`, `_parseRemoteSessionSelectionOverrides`, `_persistSessionSelectionOverridesState`, `_applySessionSelectionOverride`.
  - Destination: `chat_provider_context_state_ops.dart`.
- **Local preference/cache/model usage** (~L1877-L2126)
  - Anchors: `_storeCurrentContextSnapshot`, `_restoreContextSnapshot`, `_loadModelPreferenceState`, `_persistModelPreferenceState`, `_recordModelUsage`.
  - Destination: `chat_provider_preference_ops.dart`.
- **Realtime and degraded-mode orchestration** (~L2174-L2479)
  - Anchors: `_cancelActiveMessageSubscription`, `_setSyncState`, `_startSyncHealthMonitor`, `_evaluateSyncHealth`, `_runDegradedScopedSync`, `_startRealtimeEventSubscription`, `_resumeRealtimeAfterForeground`.
  - Destination: `chat_provider_realtime_ops.dart`.
- **Chat/global event application** (~L2552-L3105)
  - Anchors: `_applyChatEvent`, `_handleGlobalEvent`, `_tryApplyGlobalEventIncremental`, `_scheduleGlobalFallbackReconcile`, `_scheduleCurrentContextRefresh`.
  - Destination: `chat_provider_event_reducer_ops.dart`.
- **Auto-title pipeline and message fallback/merge** (~L3176-L3458)
  - Anchors: `_buildAutoTitleSnapshot`, `_isAutoTitleEnabledForActiveServer`, `_processAutoTitleQueue`, `_runAutoTitlePass`, `_fetchMessageFallback`, `_mergeServerMessagesWithPendingLocalUsers`.
  - Destination: `chat_provider_auto_title_ops.dart` + `chat_provider_message_merge_ops.dart`.
- **Session/message public flows & persistence tails** (~L3781-EOF)
  - Anchors: `_initializeProvidersInternal`, `_switchContext`, `_loadSessions`, `sendMessage` flow helpers (`_setActiveSendDraft`, `_stashRejectedDraftForRetry`, `_clearActiveSendDraft`), snapshot/cache persistence helpers.
  - Destination: split by session/message/context ops but preserve public API entry points in `chat_provider_core.dart`.

### `chat_input_widget.dart` extraction clusters (anchor ranges)

- **Send/text mode and composer state transitions** (~L375-L584)
  - Anchors: `_handleSendMessage`, `_handleTextChanged`, `_normalizeShellPayload`, `_refreshComposerMode`, `_scheduleSuggestionQuery`, `_refreshSuggestions`.
  - Destination: `chat_input_state_machine.dart`.
- **History navigation/caret handling** (~L723-L828)
  - Anchors: `_navigateHistoryUp`, `_navigateHistoryDown`, `_applyHistoryMessage`, `_applyTextValue`, `_moveCaretToBoundary`, `_exitHistoryNavigation`.
  - Destination: `chat_input_history_controller.dart`.
- **Mentions/slash suggestions and popover rendering** (~L838-L1511)
  - Anchors: `_applyActiveSuggestion`, `_applyMentionSuggestion`, `_applySlashSuggestion`, `_extractMentionTokens`, `_buildSuggestionPopover`, `_popoverMaxHeight`.
  - Destination: `chat_input_mentions_controller.dart` + `chat_input_commands_controller.dart` + `chat_input_suggestion_popover.dart`.
- **Attachments flow** (~L1511-L1653)
  - Anchors: `_showAttachmentOptions`, `_pickImages`, `_pickPdf`, `_appendAttachments`, `_isMimeAllowed`, `_resolveAttachmentUrl`, `_resolveImageMime`.
  - Destination: `chat_input_attachments_panel.dart` + `chat_input_attachment_controller.dart`.
- **Send-button gesture semantics** (~L1676-L1711)
  - Anchors: `_handleSendButtonTap`, `_handleSendButtonPressStart`, `_handleSendButtonPressEnd`, `_insertComposerNewline`.
  - Destination: `chat_input_send_controller.dart`.
- **Voice/STT lifecycle** (~L1739-EOF)
  - Anchors: `_toggleVoiceInput`, `_resolveSpeechServiceForStart`, `_startListening`, `_stopListening`, `_onSpeechResult`, `_onSpeechStatus`, `_onSpeechError`, `_showSherpaDownloadDialog`.
  - Destination: `chat_input_speech_controller.dart`.

## Objectives

- Reduce main files and keep them managerial/orchestrator-oriented.
- Separate responsibilities into stable, discoverable modules.
- Preserve functional behavior (refactor only, no product-level behavior change).
- Increase testability through narrower units and explicit boundaries.
- Make future feature work cheaper by reducing cognitive load and blast radius.

## Non-goals

- No redesign of product UX or interaction model.
- No protocol/API contract changes with backend services.
- No migration to a different state management library.
- No broad domain-layer rewrite unrelated to decomposition boundaries.
- No speculative abstractions that are not justified by concrete extraction needs.

## Design principles

- Orchestrator-first: primary files coordinate flows; they do not own heavy implementation logic.
- Responsibility slicing by behavior cluster, not by arbitrary line count.
- Preserve external signatures until explicitly planned migration steps are introduced.
- Prefer pure, side-effect-free helpers for formatting/parsing/derivation logic.
- Isolate async side effects behind dedicated coordinators/services inside presentation layer where needed.
- Keep dependencies directional and explicit (avoid circular imports and hidden cross-module coupling).
- Validate each extraction with targeted tests/smoke checks before next batch.
- Atomic commits by cluster to keep bisectability and rollback safety.

## Target architecture

### 1) `chat_page.dart` (target: orchestration shell)

Extract from monolith into feature-focused modules under `lib/presentation/pages/chat_page/`:

- `chat_page_scaffold.dart`: top-level scaffold/layout composition.
- `chat_page_header_controller.dart`: header actions, session title editing hooks, toolbar coordination.
- `chat_page_timeline_builder.dart`: message list construction, timeline entry adaptation, boundaries.
- `chat_page_scroll_coordinator.dart`: auto-follow, jump controls, scroll intent detection, visibility/focus reactions.
- `chat_page_shortcuts.dart`: keyboard shortcut maps, command dispatch wiring.
- `chat_page_message_actions.dart`: copy/retry/edit/delete and message-level callbacks.
- `chat_page_async_handlers.dart`: async UI workflows (dialogs, snackbars, transient flows).
- `chat_page_view_state.dart`: derived view-only state calculators (pure helpers where possible).
- `chat_page_constants.dart`: local constants/enums specific to page orchestration.

Expected end-state: `chat_page.dart` retains route entry, dependency wiring, and orchestration; rendering and behavior clusters are delegated.

### 2) `chat_provider.dart` (target: state orchestrator + composed capabilities)

Extract into `lib/presentation/providers/chat_provider/`:

- `chat_provider_core.dart`: canonical provider class shell, public API surface, lifecycle.
- `chat_provider_session_ops.dart`: session creation/switching/loading flows.
- `chat_provider_message_ops.dart`: send/edit/retry/stream append/finalization routines.
- `chat_provider_sync_ops.dart`: sync, polling cadence, remote adoption reconciliation.
- `chat_provider_selection_ops.dart`: agent/model/context selection state transitions.
- `chat_provider_compaction_ops.dart`: compaction-related transitions and guards.
- `chat_provider_attachments_ops.dart`: upload/download attachment workflows.
- `chat_provider_error_policy.dart`: error classification, retry semantics, user-facing state mapping.
- `chat_provider_state_models.dart`: internal immutable slices/value objects where helpful.
- `chat_provider_reducers.dart`: pure state transition helpers for deterministic updates.

Expected end-state: central provider remains the single integration point but delegates operational concerns to composed units/extensions.

### 3) `chat_input_widget.dart` (target: composable input surface)

Extract into `lib/presentation/widgets/chat_input/`:

- `chat_input_widget.dart` (thin facade): public widget API + high-level composition.
- `chat_input_text_field.dart`: text area rendering, selection hooks, keyboard actions.
- `chat_input_toolbar.dart`: send/stop/attach/mic controls, status indicators.
- `chat_input_mentions_controller.dart`: mention parsing + suggestion trigger orchestration.
- `chat_input_commands_controller.dart`: slash command trigger + command list lifecycle.
- `chat_input_attachments_panel.dart`: pending attachments view and actions.
- `chat_input_focus_coordinator.dart`: focus node policies across mobile/desktop.
- `chat_input_format_helpers.dart`: pure input formatting and tokenization utilities.

Expected end-state: top-level widget coordinates child components; behavior-specific logic lives in dedicated components/controllers.

## Execution plan (phases)

### Group 1: Baseline & guardrails

- [x] P1.01 Capture baseline metrics (line counts, file complexity hotspots, TODO markers) and store in task notes.
- [x] P1.02 Create target folder/module scaffolds for page/provider/widget decomposition with naming conventions locked.
- [x] P1.03 Define extraction contract map (what stays in orchestrator vs what moves) for each giant file.
- [x] P1.04 Add/adjust smoke tests around chat open/send/scroll/session switch critical paths.
- [x] P1.05 Introduce temporary characterization tests for fragile flows (streaming state, retry draft restore, selection persistence).
- [x] P1.06 Establish lint/import guardrails to prevent circular references in new module folders.
- [x] P1.07 Record rollback anchor commit and branch strategy before first major extraction batch.

Atomic commit criteria (Group 1):

- [x] P1.C1 One commit for structure/scaffold only (no behavior impact).
- [x] P1.C2 One commit for tests/guardrails only.
- [x] P1.C3 One commit for baseline documentation snapshots.

### Group 2: ChatPage decomposition

- [x] P2.01 Extract page-local constants/enums/helpers from `chat_page.dart` into dedicated module(s).
- [x] P2.02 Extract shortcut map creation and keyboard dispatch handlers.
- [x] P2.03 Extract scroll coordination logic (auto-follow, boundary jumps, manual intent detection).
- [x] P2.04 Extract timeline entry building and adapter logic.
- [x] P2.05 Extract message action handlers into dedicated action module.
- [x] P2.06 Extract dialog/snackbar/transient async flows into async handler module.
- [x] P2.07 Consolidate page composition in scaffold/builder module and keep original file as orchestrator.
- [x] P2.08 Remove dead private methods left behind after extraction.
- [x] P2.09 Validate no behavior drift across mobile/desktop navigation and composer interactions.

Atomic commit criteria (Group 2):

- [x] P2.C1 Commit by behavior slice (shortcuts, scroll, timeline, actions, async UI), not by mixed edits.
- [x] P2.C2 Each commit must keep app compiling and tests passing.
- [x] P2.C3 No commit should include more than one risky side-effect cluster.

### Group 3: ChatProvider decomposition

- [x] P3.01 Create provider module boundaries and move pure state models/helpers first.
- [x] P3.02 Extract session operations (load/switch/create) into dedicated unit.
- [x] P3.03 Extract message operations (send/stream/finalize/retry) with unchanged public provider API.
- [x] P3.04 Extract sync/polling operations and isolate scheduling semantics.
- [x] P3.05 Extract selection/context operations (agent/model/context state).
- [x] P3.06 Extract compaction operations and guards.
- [x] P3.07 Extract attachment-related operations.
- [x] P3.08 Extract error policy mapping/classification into a dedicated module.
- [x] P3.09 Introduce reducer-style pure transition helpers for complex state updates.
- [x] P3.10 Validate lifecycle correctness (dispose, timer cancellation, stream closure) after decomposition.

Atomic commit criteria (Group 3):

- [x] P3.C1 Commit one operational domain per batch (session, message, sync, selection, compaction, attachments, errors).
- [x] P3.C2 Public provider method signatures remain stable unless an explicit migration commit is documented.
- [x] P3.C3 Each batch includes focused tests or characterization checks for moved logic.

### Group 4: ChatInputWidget decomposition

- [x] P4.01 Extract text-field core rendering and interaction policies.
- [x] P4.02 Extract toolbar/status/action controls into dedicated child widget.
- [x] P4.03 Extract mention trigger and suggestion orchestration.
- [x] P4.04 Extract slash command orchestration and suggestion lifecycle.
- [x] P4.05 Extract attachments panel and action callbacks.
- [x] P4.06 Extract focus coordination logic for desktop/mobile parity.
- [x] P4.07 Move formatting/tokenization helpers to pure utility module.
- [x] P4.08 Ensure facade `chat_input_widget.dart` remains concise and orchestration-only.

Atomic commit criteria (Group 4):

- [x] P4.C1 Split UI extraction commits from controller extraction commits.
- [x] P4.C2 Keep widget constructor/public API stable while internals are migrated.
- [x] P4.C3 Run targeted widget tests/smoke flows after each extraction pair.

### Group 5: Safety net & test hardening

- [x] P5.01 Add regression tests for orchestrator delegation boundaries.
- [x] P5.02 Add unit tests for extracted pure helpers/reducers/controllers.
- [x] P5.03 Expand provider tests for session/message/sync decomposition paths.
- [x] P5.04 Add widget tests for input controls, mention/command triggers, attachments panel behavior.
- [x] P5.05 Add focused integration smoke script checklist for end-to-end chat flows.
- [x] P5.06 Remove temporary characterization tests that become redundant after stable coverage replacement.

Atomic commit criteria (Group 5):

- [x] P5.C1 Test additions committed separately from structural refactors whenever possible.
- [x] P5.C2 Every removed temporary test must have explicit replacement coverage.

### Group 6: Docs and follow-up cleanup

- [x] P6.01 Update CODEBASE map to include new module folders and entry points.
- [x] P6.02 Update ADR(s) if decomposition introduces architectural constraints worth recording.
- [x] P6.03 Update ROADMAP progress notes with final commit chain and condensed implementation notes.
- [x] P6.04 Remove obsolete comments/TODOs made unnecessary by decomposition.
- [x] P6.05 Final pass for naming consistency and import hygiene.
- [x] P6.06 Produce final "before vs after" line-count snapshot for the three orchestrator files.

Atomic commit criteria (Group 6):

- [x] P6.C1 Documentation commits are isolated from code changes.
- [x] P6.C2 Cleanup commit includes no behavior changes.

## Zero-research execution protocol

Follow this exact order to avoid rediscovery loops:

1. Start from clean branch head and run baseline checks.
2. Execute Group 1 fully before touching major extraction files.
3. Execute Groups 2, 3, and 4 in this fixed order (`chat_page` -> `chat_provider` -> `chat_input_widget`).
4. Run Group 5 after each major group and as final hardening.
5. Finish with Group 6 documentation and line-count snapshot.

### Commit message templates (recommended)

- `refactor(featP-g1): establish decomposition scaffolds and guardrails`
- `refactor(featP-g2): extract chat page <cluster-name> module`
- `refactor(featP-g3): extract chat provider <cluster-name> operations`
- `refactor(featP-g4): extract chat input <cluster-name> component`
- `test(featP-g5): harden decomposition regression coverage`
- `docs(featP-g6): finalize decomposition roadmap and architecture notes`

### Hard constraints for each commit

- No mixed behavior + architecture change in the same commit.
- Every commit compiles and passes the focused test set for touched clusters.
- Public API signatures stay stable unless the commit explicitly documents migration steps.

## Validation strategy

- Group 1 baseline:
  - `flutter analyze`
  - `flutter test test/unit/providers/chat_provider_test.dart`
  - `flutter test test/widget/chat_page_test.dart`
- Group 2 (`chat_page`) after each cluster extraction:
  - `flutter test test/widget/chat_page_test.dart`
  - `flutter test test/widget/chat_message_widget_test.dart`
  - `flutter test test/widget/chat_session_list_test.dart`
- Group 3 (`chat_provider`) after each cluster extraction:
  - `flutter test test/unit/providers/chat_provider_test.dart`
  - `flutter test test/unit/providers/app_provider_test.dart`
  - `flutter test test/unit/datasources/app_local_datasource_impl_test.dart`
- Group 4 (`chat_input_widget`) after each cluster extraction:
  - `flutter test test/widget_test.dart`
  - `flutter test test/widget/chat_page_test.dart --plain-name "keeps input editable while responding and stop aborts session"`
  - `flutter test test/widget/chat_page_test.dart --plain-name "restores composer draft automatically when send is rejected"`
- Group 5 hardening:
  - run all focused suites above
  - add/adjust targeted tests for each extracted module
- Project-level gate before each milestone close and final completion:
  - `make check`
- Device-ready validation when user should test behavior:
  - `TDL_CAPTION="featP batch <id>: giant file decomposition" make android`
- Manual smoke checklist (mobile + desktop):
  - open session
  - send message and receive streamed response
  - stop and retry flow
  - switch session and project/workspace
  - mention/slash command flow
  - attachments add/remove/send flow
  - scroll to latest/first and auto-follow behavior

## Risks and mitigations

- Risk: hidden behavior drift in tightly coupled private methods.
  - Mitigation: characterization tests before extraction; one behavior cluster per commit.
- Risk: circular imports between new modules.
  - Mitigation: folder boundary conventions + analyze checks each batch.
- Risk: incomplete lifecycle cleanup (timers/streams/listeners).
  - Mitigation: explicit dispose/lifecycle validation checklist in Group 3.
- Risk: merge conflict amplification while files are in transition.
  - Mitigation: short-lived extraction branches and frequent rebase cadence.
- Risk: regressions in platform-specific input behavior.
  - Mitigation: Group 4 mobile/desktop smoke matrix after each pair of extractions.

## Definition of Done

- Main giant files are converted to orchestration shells with significantly reduced size.
- Extracted modules are organized by responsibility and pass static analysis.
- No user-visible functional regressions in chat flow, provider lifecycle, or input interactions.
- `make check` passes on final branch state.
- Android artifact can be generated with contextual caption via `make android` when needed.
- ROADMAP/CODEBASE/ADR documentation updated to reflect final architecture.

## Rollback strategy

- Maintain atomic commit series per group to allow selective revert without full feature rollback.
- If a batch introduces unstable behavior, revert the specific extraction commit(s) and keep guardrail tests.
- Preserve baseline orchestrator snapshots (pre-extraction anchors) to quickly restore critical paths.
- Use staged rollout: stop after any group if stability criteria fail, fix forward or revert that group only.
