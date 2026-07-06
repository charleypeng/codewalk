# CodeWalk Chat Stability Fix — Authoritative Execution Plan

## Status

Ready.

This plan is self-contained and authoritative. It is written so a future executor can implement the correction without reading the original chat, planner outputs, or hidden context.

## Problem

CodeWalk users observe two related chat stability failures:

1. Final assistant messages frequently disappear and then reappear about one second later. The visible UI behaves as if stale HTTP refreshes, SSE events, or fallback fetches are competing, allowing an older/incomplete state to invalidate a newer visible state.
2. When opening a conversation or returning from background/desktop restore, the chat timeline jumps repeatedly as events, refreshes, or status updates arrive even though the user is not actively interacting, making reading difficult.

The fix must preserve the invariant that a newer visible assistant response must not be regressed by an older event, fallback fetch, or refresh snapshot, and passive refresh/resume work must not steal the viewport from the reader.

## Objective

After implementation:

- A completed or locally newer assistant message never disappears, loses visible text/tool/reasoning content, or regresses to incomplete because of a stale fallback fetch, limited-tail refresh, reconnect recovery, foreground resume refresh, or server snapshot.
- Opening a cached conversation and returning from background/desktop restore performs at most one intentional viewport restoration and does not keep jumping as passive events arrive.
- Passive refreshes, status-only events, reconnect recovery, and resume-time reconciliation update content in place without starting competing auto-scroll owners.
- Active sending/streaming behavior remains responsive: when the user is already following the bottom, live assistant deltas stay anchored; when the user scrolls away, updates surface via the existing “Go to latest” affordance instead of yanking the viewport.
- The change remains ADR-023 compatible: no OpenCode API contract changes, no new server fields, no custom event semantics, no server-side assumptions beyond the existing official event and HTTP snapshot streams.

## Context and Constraints

### Project context

- Repository: `/home/ubuntu/MEGA/WORK/codewalk`.
- Product: CodeWalk, a Flutter mobile/desktop client for OpenCode-compatible servers.
- Architecture: `presentation -> domain -> data`, using `provider` and `get_it`.
- Relevant platforms: Android, Linux, macOS, Windows, Web. Mobile UX and responsive layouts matter.
- Prior `AGENT_PLAN_ANCHOR` in git history belongs to a completed file-editor task and is not an active plan for this work.

### Project rules to obey

- Before code changes for this multi-step fix, create a plan-anchored git commit if the execution mode uses the repository’s agent workflow. The plan commit must include `AGENT_PLAN_ANCHOR`; subsequent step commits must reference it with `PLAN_REF` and `PREVIOUS_STEP`.
- Do not use `make precommit`; CodeWalk prefers targeted Flutter checks during iteration and `make check` at stable validation gates.
- For Flutter/Dart commands in non-interactive shells, prepend `export PATH="$HOME/flutter/bin:$PATH" && ...`.
- Do not run destructive i18n generation.
- Do not change OpenCode server contracts or add an ADR-023 exception. This fix is client-side reconciliation and viewport ownership hardening only.

### Existing behavior/specification to preserve

`BEHAVIOR.md` already specifies the desired behavior:

- Session reopening is cache-first; cached messages render immediately and SWR revalidates in the background.
- Long-session revalidation updates in place without clearing to skeletons.
- Returning from background/focus with no new chat content restores a settled cached session to the latest assistant response and an active cached session to bottom without a second jump.
- If refreshed settled content arrives during resume revalidation, the queued cached restore waits for refresh and reveals the newest assistant response once.
- Passive refreshes, realtime part updates, and status-only busy/retry reconciliation must not start a second auto-scroll owner while active turn handling already owns the viewport.
- Transient idle pulses must not settle a current session while a send is still initializing or an assistant message remains incomplete locally.
- Unsupported/global `message.*` fallback reconcile should refresh the visible timeline only when the event explicitly targets the current session.

### ADR and contract context

- `ADR.md` ADR-023 requires official OpenCode contract-first compatibility. This plan does not require a new ADR exception because it changes only client-side merge, dedupe, and scroll ownership logic.
- `ADR.md` ADR-041 defines existing chat stability invariants: monotonic local delta versioning, stale fallback completion/metadata-only merge, 16 ms delta notification batching, non-regressive completed snapshots, final reveal policy, and older-history prepend anchor restoration.
- `ai-docs/opencode_server.md` documents `/event` and `/global/event` as SSE streams. OpenCode event ordering is not strengthened by this plan; CodeWalk must remain robust when HTTP snapshots and SSE events arrive out of order.

### Primary files to edit

- `lib/presentation/providers/chat_provider/chat_provider_lifecycle_ops.dart`
  - `refreshActiveSessionView(...)`
- `lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart`
  - `_fetchMessageFallback(...)`
  - `_mergeServerTailWithCachedMessages(...)`
  - `_mergeServerMessagesWithActiveLocalTail(...)`
  - new helper(s) for non-regressive refresh/list merge
- `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart`
  - `_mergeAssistantMessageUpdate(...)`
  - `_mergeCompletedAssistantUpdate(...)`
  - `_mergeCompletionStatusOnly(...)`
  - `_markIncompleteAssistantMessagesAsCompleted(...)`
  - `_updateOrAddMessage(...)`
- `lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart`
  - `session.status`
  - `session.idle`
  - `message.created` / `message.updated`
  - `message.part.updated` / `message.part.delta`
- `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`
  - `_resumeRealtimeAfterForeground(...)`
- `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart`
  - `_markRealtimeSignal(...)`
  - `_runPostReconnectRecovery(...)`
  - `_runAutomaticForegroundSyncForDataSaver(...)`
- `lib/presentation/pages/chat_page.dart`
  - `didChangeAppLifecycleState(...)`
  - `onWindowRestore(...)`
  - `onWindowFocus(...)`
  - `_requestPassiveScrollToBottom(...)`
- `lib/presentation/pages/chat_page/chat_page_lifecycle.dart`
  - `_handleChatProviderChangedBody(...)`
  - `_syncChatRouteActivity(...)`
  - `_handleReturnToChat(...)`
- `lib/presentation/pages/chat_page/chat_page_runtime_support.dart`
  - `_handleScrollMetricsChanged(...)`
  - `_queueCachedViewportRestore(...)`
  - `_consumeQueuedCachedViewportRestore(...)`
  - `_scheduleQueuedDesktopViewportRestore(...)`
  - `_syncSessionScrollState(...)`
  - `_syncResponseViewportPolicyBody(...)`
  - `_revealLatestMessageForCachedRestore(...)`
  - `_scheduleLatestMessageReturnReveal(...)`
  - `_runLatestMessageReturnReveal(...)`
  - `_scheduleFinalAssistantReveal(...)`
  - `_revealFinalAssistantMessageStart(...)`
  - `_finalizeFinalAssistantReveal(...)`
- `lib/presentation/pages/chat_page/chat_page_scroll_coordinator.dart`
  - `_hasUserScrollPriority(...)`
  - `_runScrollToBottom(...)`
- `lib/presentation/pages/chat_page/chat_page_timeline_viewport.dart`
  - Timeline build/key stability should remain unchanged unless tests prove key churn is part of the regression.

### Primary tests to edit/add

- `test/unit/providers/chat_provider_realtime_test.dart`
- `test/unit/providers/chat_provider_session_ops_test.dart`
- `test/unit/providers/chat_provider_messaging_test.dart`
- `test/widget/chat_page_test.dart`

## Decisions (Resolved)

1. Fix this as one coupled client-side stability bug: message reconciliation regressions and viewport ownership races share the same resume/reconnect/passive-refresh window.
2. Preserve local visible assistant state non-regressively during all refresh/list merge paths, not only during single-message `_updateOrAddMessage(...)` paths.
3. Do not publish a limited/truncated server tail if it removes the current session’s newest visible local assistant response or active/local tail. Publish a non-regressive merged view and run the existing full-fetch recovery in the background.
4. Use existing assistant merge helpers as the canonical merge rules. Extend them if needed; do not create a second incompatible merge policy.
5. Remove provider-side auto-scroll scheduling from passive settled refreshes. Resume/open viewport movement belongs to the page-side restore owner, not to `refreshActiveSessionView(...)`.
6. During foreground resume, make exactly one viewport owner responsible for final placement: the post-refresh cached viewport restore. Suppress intermediate passive scroll requests and metrics-triggered jumps while resume restoration is pending.
7. Preserve user reading intent. If the user has scrolled away or the page is in a reading/paused mode, passive events must not force bottom scrolling; they must surface unread/new content through the existing FAB behavior.
8. Keep active live streaming anchored when the user is already following bottom. Do not disable streaming follow behavior for active sends.
9. Treat desktop restore/focus as the same class of resume problem. Deduplicate restore/focus viewport scheduling so a restore followed by a focus event cannot cause two jumps.
10. Do not update ADR or BEHAVIOR unless implementation discovers the desired behavior is not already documented. The existing behavior spec and ADR-041 already describe the target.

## Why This Plan

The strongest evidence points to stale HTTP refreshes, fallback fetches, reconnect recovery, and resume refreshes replacing newer local/SSE state at the list level, bypassing the existing per-message non-regression guards. The same windows trigger multiple scroll owners: passive provider scroll, cached restore, final reveal, metrics changes, post-reconnect recovery, and desktop/app lifecycle handlers. The safest correction is to make all refresh/fallback merges monotonic and to serialize/suppress viewport owners during passive resume/reconnect work.

## Overview

Add regression tests that reproduce stale refresh/fallback and resume viewport races. Then harden provider message merging so refresh snapshots and fallback fetches cannot remove or regress visible assistant content. Finally, make page-side scroll ownership explicit during resume/open/reconnect windows so passive events cannot repeatedly claim the viewport. Validate with targeted provider/widget tests and `make check` after the focused suite passes.

## Steps

### 1. Create failing provider regressions for non-regressive refresh/list merge

- **Files**:
  - `test/unit/providers/chat_provider_realtime_test.dart`
  - `test/unit/providers/chat_provider_session_ops_test.dart`
  - `test/unit/providers/chat_provider_messaging_test.dart`
- **Details**:
  - Add a test where the current session has a locally visible completed `AssistantMessage` with non-empty `TextPart` and/or terminal `ToolPart`, then `refreshActiveSessionView(includeStatus: false, preferDelta: true)` receives a limited server tail that does not contain that latest local message. Assert that the latest local assistant remains visible immediately after refresh and after the full-fetch fallback completes.
  - Add a test where the current session has a completed assistant message and a refresh/fallback returns the same message id with `completedTime == null` and shorter or empty text. Assert that the local completed message remains completed and keeps the longer visible text/parts.
  - Add a test where `refreshActiveSessionView(...)` receives an overlapping server message with the same id but fewer parts or non-terminal tool state. Assert that `_mergeAssistantMessageUpdate(...)` semantics preserve visible text/reasoning and terminal tool state.
  - Update the existing provider test that currently expects passive refresh latest-message changes to schedule scroll. The new expected behavior is no provider scroll request for settled passive refreshes.
- **Risk**: Low. Tests encode already documented behavior.
- **Validation**:
  - Run targeted test files after adding tests and before implementation to confirm at least one relevant regression fails:
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/providers/chat_provider_realtime_test.dart test/unit/providers/chat_provider_session_ops_test.dart test/unit/providers/chat_provider_messaging_test.dart`

### 2. Create failing widget regressions for resume/open viewport stability

- **Files**:
  - `test/widget/chat_page_test.dart`
- **Details**:
  - Add a resume test for a settled cached session with no new chat content. Record `Scrollable.position.pixels` after initial cached restore; simulate `inactive` then `resumed`; emit status-only `session.status` busy/idle and/or no-op `message.updated` events; assert the viewport remains within 1 px of the pre-event reading position after all frames settle.
  - Add a resume test where new final content arrives while backgrounded. Assert the page reveals the newest assistant response once, then subsequent status-only/passive refresh events do not cause additional pixel changes.
  - Add a desktop restore/focus test where `onWindowRestore()` and `onWindowFocus()` happen in quick succession. Assert there is only one viewport restore and no second jump.
  - Add or update a test for manual user scroll before passive refresh. Assert that passive refresh preserves `pixels` and shows the “Go to latest” affordance when new content is below.
- **Risk**: Medium. Widget tests around scrolling can be timing-sensitive.
- **Validation**:
  - Run the focused widget file after adding tests and before implementation to confirm relevant failures:
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "resume"`
  - If `--plain-name "resume"` misses nearby tests, run the full widget file once after implementation.

### 3. Make refresh/list reconciliation non-regressive

- **Files**:
  - `lib/presentation/providers/chat_provider/chat_provider_lifecycle_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart`
- **Details**:
  - Add a single canonical helper in `chat_provider_message_merge_ops.dart`, for example `_mergeServerMessagesWithVisibleLocalState(...)`, that merges a server-derived list into the current visible list for one session without regressing assistant messages.
  - The helper must perform these exact rules:
    1. Build a current-session local list from `_messages` before refresh assignment.
    2. Build a base list from the server-derived messages produced by `_mergeServerTailWithCachedMessages(...)` or full fetch.
    3. For each server message whose id exists locally:
       - If both are `AssistantMessage`, replace the server message with `_mergeAssistantMessageUpdate(localAssistant, serverAssistant)` so local visible text/tool/reasoning/completion state is preserved when the server snapshot is older or shorter.
       - If both are `UserMessage`, keep the existing optimistic/user reconciliation behavior from `_mergeServerMessagesWithPendingLocalUsers(...)` and `_removeDuplicateOptimisticLocalUserEcho(...)`.
       - For other same-id cases, prefer the server message only when it is not regressive by role/type; otherwise keep local.
    4. Append a bounded local tail for the current session when missing from the base list. Use the existing active-tail cap concept (`maxTailMessagesWithoutAnchor = 12`) and preserve at minimum:
       - pending optimistic local user messages still in `_pendingLocalUserMessageIds`;
       - assistant messages that are locally completed and absent from the server list;
       - assistant messages with visible non-empty text/reasoning parts or terminal tool states that are absent from the server list;
       - messages after the last safe overlap when no explicit removal event has been received.
    5. Do not append duplicate server echoes of local optimistic user messages; reuse the existing content-signature duplicate checks.
    6. Sort the final list by `time` while preserving stable order for equal timestamps.
    7. Deduplicate by `id`, keeping the non-regressive merged instance.
  - In `refreshActiveSessionView(...)`, call this helper before assigning `_messages`. Do not directly assign the raw `serverMessagesForMerge` or a raw `cachedPrefix + serverTail` result to `_messages` for the current session.
  - When `_mergeServerTailWithCachedMessages(...)` returns `requiresFullFetch: true` / `usedGapRecovery: true`, publish only the non-regressive merge. Do not publish a truncated server tail that drops the latest visible local assistant. Keep `_hasMoreOldMessages = true` and continue to schedule the existing full-fetch fallback.
  - Apply the same non-regressive merge when the full-fetch fallback returns. A full fetch is authoritative for older history breadth, but it still must not regress currently visible completed assistant content unless an explicit `message.removed` event removed it.
  - Keep the existing `_messagesVersion != refreshStartVersion` guard. Strengthen it by ensuring that if `_messagesVersion` changed while refresh was in flight, the refresh result is ignored or merged against the new current `_messages`, never blindly assigned over newer local state.
- **Risk**: High. This is the core correctness change and can affect optimistic echo reconciliation, older-history gap recovery, and cache persistence.
- **Validation**:
  - Provider tests from Step 1 pass.
  - Existing optimistic echo tests in `test/unit/providers/chat_provider_realtime_test.dart` continue to pass.
  - Existing older-history/no-overlap fallback tests in `test/unit/providers/chat_provider_messaging_test.dart` continue to pass.

### 4. Harden fallback fetch against stale assistant snapshots

- **Files**:
  - `lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart`
- **Details**:
  - In `_fetchMessageFallback(...)`, before applying a fetched message to the current session, inspect the existing local message with the same id.
  - If existing and incoming are both `AssistantMessage`, apply `_mergeAssistantMessageUpdate(existing, incoming)` instead of passing incoming directly to `_updateOrAddMessage(...)` when the incoming snapshot is incomplete, shorter, missing visible parts, or older than local delta state.
  - If the existing assistant is completed and the incoming assistant is incomplete, do not replace content. Merge completion metadata only when incoming is completed; otherwise ignore the incoming content and leave the local message unchanged.
  - If `_messageLocalDeltaVersion(message.id)` is greater than the fallback’s scheduled version, preserve current content and merge completion metadata only, matching ADR-041.
  - Cancel or ignore pending debounced fallback timers for the current session’s final assistant when `session.idle` has marked incomplete assistant messages completed and no visible gaps remain.
  - Keep fallback fetch useful for missing messages/parts. It must still add a message when the current session has no local message with that id.
- **Risk**: Medium. Overly aggressive rejection could hide valid authoritative server corrections.
- **Validation**:
  - Add/confirm a test where a valid completed authoritative server snapshot with more complete content still updates local content non-regressively.
  - Add/confirm a test where an incomplete stale fallback after idle cannot remove completion or shorten text.

### 5. Deduplicate and serialize resume/reconnect refreshes

- **Files**:
  - `lib/presentation/providers/chat_provider/chat_provider_lifecycle_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart`
  - `lib/presentation/pages/chat_page.dart`
- **Details**:
  - Convert `_activeSessionRefreshInFlight` from a drop-only guard into a join/reuse guard or add a separate `Future<void>? _activeSessionRefreshTask` so concurrent resume/reconnect callers share one active refresh instead of independently racing.
  - Keep exactly one active-session refresh for a foreground resume cycle. The refreshes from these paths must not independently publish competing snapshots for the same session within the same resume window:
    - `didChangeAppLifecycleState(...resumed...)` page call with reason `app-lifecycle-resumed`;
    - provider `_resumeRealtimeAfterForeground(...)` with reason `foreground-resume`;
    - `_runPostReconnectRecovery(...)` after first signal;
    - `server.connected` event refresh.
  - Add a short-lived provider-side suppression marker after a foreground-resume refresh completes for the current session. Use it to skip the next post-reconnect recovery refresh for the same session if it occurs immediately and has no additional required work beyond status/pending interactions.
  - Preserve pending-interaction loading and session-list loading from reconnect recovery. Suppress only redundant active-session message refresh publication for the same session in the same resume/reconnect window.
  - Ensure all refresh completions re-check `_currentSession?.id` before publishing and before scheduling any page callback.
- **Risk**: Medium. Reconnect recovery exists to recover lost events; do not disable recovery globally.
- **Validation**:
  - Add/confirm a test that two quick resume/reconnect refresh triggers produce one effective active-session message publication.
  - Confirm pending permissions/questions still reload after reconnect.

### 6. Remove provider-side passive scroll from settled refreshes

- **Files**:
  - `lib/presentation/providers/chat_provider/chat_provider_lifecycle_ops.dart`
  - `lib/presentation/providers/chat_provider.dart`
  - `lib/presentation/pages/chat_page.dart`
- **Details**:
  - In `refreshActiveSessionView(...)`, remove the default `_scheduleScrollToBottom(reason: 'refresh-active-session-view')` behavior for settled/passive refreshes.
  - Add an explicit optional parameter only if needed by existing call sites, named `allowPassiveScrollOnLatestChange`, defaulting to `false`. Do not set it to true for resume, reconnect, server.connected, data-saver, degraded sync, manual refresh, or SWR refresh.
  - Keep scroll behavior for active sends and live streaming through existing event reducer/message update paths, subject to page-side user-priority gates.
  - Update tests that expected passive refresh to scroll. The new expected behavior is content update without viewport theft.
- **Risk**: Medium. Some prior behavior may have used passive refresh to follow new settled content. The page-side cached restore and explicit user FAB must own that behavior now.
- **Validation**:
  - Provider scroll-callback tests assert zero scroll requests for settled passive refresh.
  - Widget tests assert manual user scroll position stays stable across passive refresh.

### 7. Make resume/open viewport ownership single-owner and generation-safe

- **Files**:
  - `lib/presentation/pages/chat_page.dart`
  - `lib/presentation/pages/chat_page/chat_page_lifecycle.dart`
  - `lib/presentation/pages/chat_page/chat_page_runtime_support.dart`
  - `lib/presentation/pages/chat_page/chat_page_scroll_coordinator.dart`
- **Details**:
  - Treat `_resumeRefreshViewportRestorePending` as a hard viewport-owner gate.
  - In `_handleReturnToChat(...)`, keep non-scroll side effects such as tour flushing, auto-approve drain scheduling, and background context sync. Then, if `_resumeRefreshViewportRestorePending == true` and `reason != 'app-resumed-refresh-complete'`, return before `_queueCachedViewportRestore(...)` or any bottom scroll. Log/trace this as a deferred restore.
  - Only `app-resumed-refresh-complete` may queue/consume the resume cached viewport restore after the refresh settles.
  - In `_requestPassiveScrollToBottom(...)`, if `_resumeRefreshViewportRestorePending == true`, suppress all passive scroll requests and mark unread content below when appropriate. Do not call `_consumeQueuedCachedViewportRestore(...)` from passive scroll while resume refresh is pending.
  - In `_handleScrollMetricsChanged(...)`, return without jumping when `_resumeRefreshViewportRestorePending == true`, `_isReturnRevealInFlight == true`, `_olderMessagesAnchorRestoreInFlight == true`, `_responseSettleFramesRemaining > 0`, `_hasUserScrollPriority() == true`, or `_scrollFollowMode == _ScrollFollowMode.reading`.
  - Increment `_returnRevealGeneration` at the start of app resume and desktop restore/focus viewport scheduling so any stale post-frame return reveal callbacks from a prior generation cannot run.
  - Ensure `_runLatestMessageReturnReveal(...)` and final reveal callbacks continue to check generation/session id before scrolling.
  - If `_scrollFollowMode == _ScrollFollowMode.pausedByUser` or recent user scroll priority exists, do not restore to bottom/latest on resume. Preserve the pixel position and show the existing “Go to latest” affordance for new content.
  - For a settled session with no user scroll priority and no new content, allow at most one cached latest-response restore on session open/resume. Do not repeat it on status-only events.
  - For a session with new final content while backgrounded, reveal the newest assistant response once after refresh completes. Subsequent passive/status events must not move the viewport.
- **Risk**: High. Scroll behavior is user-visible and widget tests can be brittle.
- **Validation**:
  - Widget resume/open tests from Step 2 pass.
  - Existing final assistant reveal tests still pass.
  - Existing active streaming follow-to-bottom tests still pass.

### 8. Deduplicate desktop restore/focus viewport scheduling

- **Files**:
  - `lib/presentation/pages/chat_page.dart`
  - `lib/presentation/pages/chat_page/chat_page_lifecycle.dart`
  - `lib/presentation/pages/chat_page/chat_page_runtime_support.dart`
- **Details**:
  - Add or reuse a short debounce signature for desktop restore/focus viewport restoration that ignores the reason string difference between `window-restore` and `window-focus` when both happen within 500 ms for the same session/message/follow mode.
  - If `onWindowRestore()` sets `_isAppInForeground = true` and schedules return/restore, then a following `onWindowFocus()` must not schedule another viewport restore for the same session unless the message signature changed due to real new chat content.
  - Keep foreground policy and notification cleanup behavior intact. Deduplicate only viewport restore/scroll scheduling.
- **Risk**: Low to medium. Desktop lifecycle ordering differs by platform.
- **Validation**:
  - Desktop widget test for restore followed by focus passes.
  - Existing desktop active cached session focus test still passes.

### 9. Audit event dedupe only for message/part update loss

- **Files**:
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_helpers.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart`
- **Details**:
  - Inspect `_composeEventDeduplicationKey(...)` and the global/session event dedupe flow.
  - Ensure `message.part.delta`, `message.part.updated`, `message.updated`, and `message.created` events are not deduped solely by event type plus message/part id when their payload, delta text, completion state, or update time differs.
  - Change dedupe keys for these event types to include a stable payload identity: delta text for delta events, part payload hash for part updates, message completion/time/part count for message updates, and exact event source identifiers when available.
  - Keep dedupe protection against exact duplicate cross-stream events from session/global SSE; do not disable dedupe entirely.
- **Risk**: Medium. Incorrect dedupe can either drop legitimate updates or re-apply duplicates.
- **Validation**:
  - Add a unit test with two `message.part.delta` events for the same message/part id but different delta text. Assert both apply.
  - Add a unit test with exact duplicate global/session events. Assert only one application occurs.

### 10. Keep session idle completion idempotent and non-disruptive

- **Files**:
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart`
- **Details**:
  - In `session.idle` handling, ensure `_markIncompleteAssistantMessagesAsCompleted(sessionId: sessionId)` is invoked once per idle event path for the current session unless a second call is proven no-op before notification.
  - Keep `_markIncompleteAssistantMessagesAsCompleted(...)` idempotent: if no messages changed, it must not increment `_messagesVersion` and must not notify listeners.
  - Do not let a stale busy/retry status after terminal idle re-enter active-response viewport policy unless there is evidence of a newer turn. Evidence of a newer turn means a new user message, new assistant message id, or server status that corresponds to a new message after the completed assistant.
- **Risk**: Medium. Status handling affects notifications and unread completion markers.
- **Validation**:
  - Existing `session.idle` tests pass.
  - Add a test where idle finalizes a message, then a stale busy status arrives without new messages. Assert the completed assistant remains settled and viewport policy does not re-enter active responding.

### 11. Validate focused suites, then full project gate

- **Files**:
  - No code edits unless tests reveal failures.
- **Details**:
  - Run targeted provider tests:
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/providers/chat_provider_realtime_test.dart test/unit/providers/chat_provider_session_ops_test.dart test/unit/providers/chat_provider_messaging_test.dart`
  - Run targeted widget tests by names used/added for this fix:
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "resume"`
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "passive refresh"`
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "final assistant"`
  - Run analyzer for touched files if the project uses targeted analyze successfully:
    - `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/presentation/providers/chat_provider.dart lib/presentation/pages/chat_page.dart test/unit/providers/chat_provider_realtime_test.dart test/unit/providers/chat_provider_session_ops_test.dart test/unit/providers/chat_provider_messaging_test.dart test/widget/chat_page_test.dart`
  - Run the full validation gate after focused checks pass:
    - `export PATH="$HOME/flutter/bin:$PATH" && make check`
- **Risk**: Medium. Full widget suite may expose unrelated timing fragility; do not weaken assertions to hide the bug.
- **Validation**:
  - All targeted tests pass.
  - `make check` passes before final code commit/report.

## Risks & Mitigations

- **Critical — hiding authoritative server corrections**: Non-regressive local preservation could keep stale local content if the server legitimately retracts content. Mitigation: still honor explicit `message.removed` / `message.part.removed` events and full server messages that are clearly non-regressive; preserve local only against incomplete/shorter/missing snapshots without explicit removal.
- **High — breaking optimistic user echo reconciliation**: Local tail preservation could duplicate pending user bubbles. Mitigation: reuse existing `_pendingLocalUserMessageIds`, `_shouldSkipLocalUserAppendAsDuplicateEcho(...)`, and `_removeDuplicateOptimisticLocalUserEcho(...)` logic for any preserved tail.
- **High — reconnect recovery regression**: Suppressing duplicate active-session refreshes could miss events lost during SSE reconnect. Mitigation: suppress only redundant active-session message publication inside a short same-session resume window; keep pending interactions, statuses, session list, and a later full refresh path intact.
- **High — scroll behavior changes are visible and timing-sensitive**: Widget tests may pass while real devices still show jitter. Mitigation: keep existing trace logs (`CW_TRACE_FINAL`) and add narrowly scoped trace points around resume restore suppression, passive scroll suppression, and non-regressive refresh merge.
- **Medium — older history gap recovery**: Preserving a local tail during no-overlap tail refresh could mix server tail with local older cache in the wrong order. Mitigation: use stable time sorting, mark `_hasMoreOldMessages = true`, and complete the existing full-fetch fallback before persisting broad history snapshots.
- **Medium — desktop lifecycle event ordering**: Linux/macOS/Windows may deliver restore/focus differently. Mitigation: dedupe restore/focus viewport scheduling by session/message signature and time, not by platform-specific event order.
- **Low — logs/noise**: Extra trace logs could be noisy. Mitigation: use existing `AppLogger` trace style and keep logs concise; do not enable logging by default.

## Assumptions to Validate

- **Assumption**: The disappearing final message is caused by stale fallback/refresh/list replacement, not by Flutter widget key loss alone.
  - **Validation**: Provider tests reproduce message loss without rendering widgets.
  - **Fallback behavior if false**: Keep provider non-regression changes and add a focused widget-key fix in `chat_page_timeline_entries.dart` / `chat_page_timeline_viewport.dart` so the same message id keeps stable entry keys across collapse/reveal transitions.
- **Assumption**: Existing ADR-041 behavior remains authoritative and no ADR update is required.
  - **Validation**: Implementation does not add APIs, server fields, or new lifecycle semantics.
  - **Fallback behavior if false**: Stop implementation and document the required ADR-023 exception before proceeding.
- **Assumption**: Passive refresh auto-scroll is not required for correct UX.
  - **Validation**: Existing and new widget tests confirm active streaming follows bottom, explicit FAB works, and resume with new content reveals once.
  - **Fallback behavior if false**: Reintroduce passive refresh scroll only behind a page-side gate that proves the user was already at bottom and no resume/return/final reveal owner is active.
- **Assumption**: Duplicate resume/reconnect refreshes can be coalesced without missing permission/question events.
  - **Validation**: Existing pending interaction tests and reconnect tests pass.
  - **Fallback behavior if false**: Coalesce only active-session message publication while still running pending interaction/session status loads independently.

## Decisions and Nuances

- A completed assistant message is locally sticky against incomplete snapshots. It can receive more complete server metadata/content, but it cannot become incomplete or lose visible content without explicit removal.
- A limited server tail is not safe to publish by itself when it loses the latest local visible assistant message. Publish a non-regressive merge, mark older history incomplete, then full-fetch.
- HTTP refreshes and SSE events are peer inputs with different latency; neither is globally newer by transport alone. Compare message ids, completion state, local delta versions, visible parts, and explicit removal events.
- `session.idle` is terminal for the current turn but may race with stale status events. Do not allow stale busy/retry pulses to re-own viewport policy after a completed assistant is settled unless a newer turn exists.
- Page-side viewport restoration is the only owner during resume completion. Provider-side passive scroll requests during resume are suppressed, not queued.
- Active send/stream follows bottom only when the user is already following. User scroll priority always wins.
- Desktop restore/focus duplicate events are normal platform behavior and must not produce duplicate viewport restores.
- Manual refresh is still passive for viewport purposes. It updates content but does not force bottom unless the user explicitly uses the “Go to latest” action.

## Blockers and Open Questions

None.

## Testing Strategy

1. Add failing provider tests for:
   - completed assistant preserved across stale/incomplete refresh;
   - visible assistant tail preserved when delta refresh has no safe overlap;
   - fallback fetch cannot regress a completed or locally newer assistant;
   - settled passive refresh does not call the scroll callback;
   - stale busy/retry after idle does not re-enter active-response behavior without a newer turn.
2. Add failing widget tests for:
   - resume with no new content and status/no-op events does not move viewport repeatedly;
   - resume with new final content reveals once and then remains stable;
   - desktop restore followed by focus does not double-restore;
   - user-scrolled reading position survives passive refresh and shows FAB for new content.
3. Run targeted suites repeatedly during implementation:
   - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/providers/chat_provider_realtime_test.dart test/unit/providers/chat_provider_session_ops_test.dart test/unit/providers/chat_provider_messaging_test.dart`
   - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "resume"`
   - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "passive refresh"`
   - `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "final assistant"`
4. Run targeted analyzer:
   - `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/presentation/providers/chat_provider.dart lib/presentation/pages/chat_page.dart test/unit/providers/chat_provider_realtime_test.dart test/unit/providers/chat_provider_session_ops_test.dart test/unit/providers/chat_provider_messaging_test.dart test/widget/chat_page_test.dart`
5. Run final gate:
   - `export PATH="$HOME/flutter/bin:$PATH" && make check`

## Execution Handoff

Start here:

1. Inspect current git state:
   - `rtk git status --short`
2. If using the repository’s agent workflow for implementation, create a `plan:` commit containing this plan and `AGENT_PLAN_ANCHOR` before editing code.
3. Open these files first:
   - `lib/presentation/providers/chat_provider/chat_provider_lifecycle_ops.dart`
   - `lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart`
   - `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart`
   - `lib/presentation/pages/chat_page.dart`
   - `lib/presentation/pages/chat_page/chat_page_lifecycle.dart`
   - `lib/presentation/pages/chat_page/chat_page_runtime_support.dart`
   - `lib/presentation/pages/chat_page/chat_page_scroll_coordinator.dart`
4. Add tests before code changes. Confirm at least one new regression fails.
5. Implement provider non-regressive merge first. Do not touch scroll code until provider tests pass.
6. Implement fallback fetch hardening second.
7. Implement resume/passive scroll single-owner behavior third.
8. Implement event dedupe and idle/status refinements only after the core provider and viewport regressions are covered.
9. Run targeted tests after each logical change.
10. Run `make check` after all focused tests pass.

Strict sequencing constraints:

- Do not remove existing ADR-041 guards.
- Do not replace local/SSE-visible assistant content with raw server snapshots in any current-session refresh path.
- Do not let refresh/reconnect/resume code schedule scroll-to-bottom directly during passive settled refresh.
- Do not change server API calls, request schemas, or OpenCode event semantics.

## Out of Scope

- No OpenCode server changes.
- No new REST endpoints, SSE fields, or protocol extensions.
- No ADR-023 exception.
- No broad ChatPage rewrite.
- No new scroll physics package or list virtualization migration.
- No redesign of the chat UI, composer, sidebar ordering, or session list sorting beyond preventing viewport jumps in the active conversation.
- No documentation updates unless implementation changes current documented behavior.
