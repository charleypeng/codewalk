# Aggressive Cellular Data Saver: Visible Session + 30-Second Cadence

## Status

Ready.

## Problem

CodeWalk's aggressive cellular data saver mode still consumes too much mobile data. In the current code, aggressive mode uses long and mismatched automatic intervals (`5 min`, `60 s`, `90 s`, `3 min`) while also leaving several automatic foreground/realtime paths broad enough to process or fetch data for inactive sessions, pending interactions outside the visible session, remote selection sync, global status/session refreshes, and route-hidden chat state. The user-requested behavior is: on cellular/mobile transport with aggressive data saver active, automatic realtime/network work must focus only on the chat session the user is currently viewing, background/inactive-context work must be suppressed, and any retained automatic query/poll cadence must be 30 seconds. Manual user actions must remain immediate.

## Objective

After implementation, when `FeatureFlags.cellularDataSaver == true`, `DataSaverLevel.aggressive` is selected, transport is `DataSaverTransport.cellular`, the app is foregrounded, and the chat route has a visible selected session:

- Automatic aggressive data-saver polling/check cadence is exactly `Duration(seconds: 30)`.
- `/global/event` is not subscribed.
- The directory/project `/event` stream is kept only during visible-session activity that benefits from realtime: explicit interactive burst, current-session send/response, or visible-session pending interaction state.
- Visible idle state uses the 30-second automatic visible-session sync instead of keeping the project-scoped event stream open indefinitely.
- Inactive-session events and inactive-context automatic refreshes are ignored or marked dirty without side effects or follow-up HTTP fetches.
- Automatic pending permission/question refreshes apply only to the visible session/thread.
- Automatic remote selection pulls and global session/status refreshes are skipped.
- Manual actions remain immediate and bypass the 30-second automatic cadence.
- Desktop, non-cellular, `standard`, and `off` behaviors remain unchanged.

## Context and Constraints

- Repository root: `/home/ubuntu/MEGA/WORK/codewalk`.
- The workspace has unrelated dirty user changes. Before editing, inspect `git status --short` and diffs for every target file, then preserve unrelated changes.
- CodeWalk is a Flutter/Dart mobile + desktop OpenCode client. Mobile UX and responsive behavior are priority constraints.
- ADR-023 requires official OpenCode contract-first compatibility. This plan changes only client-side scheduling/filtering over existing endpoints and streams; it does not change OpenCode API contracts, event schemas, or server behavior.
- Existing rollback: `FeatureFlags.cellularDataSaver` in `lib/core/config/feature_flags.dart`, disabled with `--dart-define=CODEWALK_CELLULAR_DATA_SAVER=false`.
- Existing data saver setting: `DataSaverLevel` in `lib/domain/entities/experience_settings.dart`.
- Primary implementation files:
  - `lib/presentation/services/cellular_data_saver_service.dart`
  - `lib/presentation/providers/chat_provider.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_lifecycle_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_selection_sync_ops.dart`
  - `lib/presentation/providers/app_provider.dart` for verification/test coverage only unless current code changed before implementation.
  - `BEHAVIOR.md` for documentation after code behavior is implemented.
- Existing code facts to preserve:
  - `CellularDataSaverService.isAggressiveDataSaverActive` already requires the feature flag, an enabled data saver level, cellular transport, and `DataSaverLevel.aggressive`.
  - `allowAutomaticForegroundSync` gates automatic foreground sync only.
  - `noteExplicitUserAction` opens an interactive burst; keep aggressive burst at `45 seconds` because it protects manual responsiveness and is not a polling cadence.
  - `watchChatEvents(directory: directory)` is directory/project-scoped, not proven session-scoped. CodeWalk cannot prevent all inactive-session event bytes while this stream is open. The local mitigation is to close the stream when visible-session realtime is not needed and drop inactive events before side effects when the stream is open.
  - `listPendingPermissions` and `listPendingQuestions` are directory-scoped. CodeWalk cannot fetch only one session with the current known client contract. The local mitigation is to apply only visible-session results and avoid inactive alerts/state.

## Decisions (Resolved)

1. Use one aggressive automatic cadence constant of `Duration(seconds: 30)` and wire all aggressive automatic timers to it.
2. Keep `aggressiveInteractiveBurstDuration` at `Duration(seconds: 45)` because manual-response protection is not a polling/query cadence.
3. Set `aggressiveSyncSignalStaleThreshold` to the same 30-second cadence so an apparently alive but silent/broken visible-session stream falls back to 30-second polling without waiting 3 minutes.
4. Treat a visible aggressive session as: aggressive data saver active, app foregrounded, chat route active, and `_currentSession` has a non-empty id.
5. Keep the project `/event` stream only while visible-session realtime is useful: forced/interactive burst, current send, current session actively responding, or visible-session pending interaction state. Otherwise close the stream and rely on 30-second automatic visible-session sync.
6. Never subscribe `/global/event` while aggressive cellular data saver is active.
7. Do not add new OpenCode endpoints or server-side filtering.
8. Do not add a new feature flag; use existing `FeatureFlags.cellularDataSaver` rollback.
9. Do not globally block manual model/provider/config updates. Suppress only automatic remote selection pulls during aggressive cellular mode.
10. Update `BEHAVIOR.md` after code changes; do not run destructive global i18n generation.

## Why This Plan

This plan saves data more aggressively than simply filtering state after receiving events because it closes the project-scoped event stream while the visible session is idle. It preserves visible-session responsiveness through a 45-second interactive burst, active-response realtime, and 30-second fallback polling. It handles the verified broad fetch paths (`_loadPendingInteractions`, `_syncSelectionFromRemote`, `loadSessions`, `refreshSessionStatusSnapshot`) instead of only changing timer constants. It remains ADR-023 compatible because it uses only existing client-side APIs and the existing feature-flag rollback.

## Overview

Implement a visible-session policy layer inside `ChatProvider` and use it consistently from realtime policy, automatic foreground sync, event reduction, and reconnect/degraded recovery. Change aggressive automatic timing constants to 30 seconds. Filter or skip inactive automatic work before it mutates UI state or launches follow-up network calls. Preserve all user-triggered methods as immediate paths that either bypass the automatic gate directly or open a burst before syncing.

## Steps

1. Protect the dirty worktree before editing.
   - **Files**: no code files yet.
   - **Details**: Run `git status --short`, then inspect diffs for each target before modifying it. Stage or commit nothing unless explicitly requested later. Do not overwrite unrelated user edits.
   - **Risk**: Medium; the context says unrelated dirty changes exist.
   - **Validation**: Confirm every edited hunk belongs to this data-saver change.

2. Centralize aggressive 30-second cadence.
   - **Files**: `lib/presentation/services/cellular_data_saver_service.dart` around the static aggressive duration constants.
   - **Details**: Add a single constant and wire aggressive automatic constants to it:
     ```dart
     static const Duration aggressivePollingCadence = Duration(seconds: 30);
     static const Duration aggressiveAutomaticSyncInterval = aggressivePollingCadence;
     static const Duration aggressiveInteractiveBurstDuration = Duration(
       seconds: 45,
     );
     static const Duration aggressiveSyncHealthCheckInterval = aggressivePollingCadence;
     static const Duration aggressiveSyncSignalStaleThreshold = aggressivePollingCadence;
     static const Duration aggressiveDegradedPollingInterval = aggressivePollingCadence;
     ```
     Keep `automaticSyncInterval` returning `aggressiveAutomaticSyncInterval` when `isAggressiveDataSaverActive`.
   - **Risk**: Medium; reducing stale threshold can increase visible-session fallback polling, but this is required to make the retained automatic cadence actually 30 seconds.
   - **Validation**: Update unit tests to assert every aggressive automatic cadence constant equals `const Duration(seconds: 30)` and the burst remains `const Duration(seconds: 45)`.

3. Add visible-session helpers to `ChatProvider`.
   - **Files**: `lib/presentation/providers/chat_provider.dart` near `_hasPendingThreadInteractions`, `_shouldKeepRealtimeActiveForDataSaver`, and `_isAggressiveDataSaverActive`.
   - **Details**: Add helpers with these exact semantics:
     ```dart
     bool get _hasVisibleAggressiveDataSaverSession {
       final sessionId = _currentSession?.id.trim();
       return _cellularDataSaverService.isAggressiveDataSaverActive &&
           _isForegroundActive &&
           _isChatRouteActive &&
           sessionId != null &&
           sessionId.isNotEmpty;
     }

     bool _isVisibleAggressiveSessionId(String? sessionId) {
       final normalizedSessionId = sessionId?.trim();
       final currentSessionId = _currentSession?.id.trim();
       if (normalizedSessionId == null ||
           normalizedSessionId.isEmpty ||
           currentSessionId == null ||
           currentSessionId.isEmpty) {
         return false;
       }
       if (normalizedSessionId == currentSessionId) {
         return true;
       }
       final parentId = _sessionById(normalizedSessionId)?.parentId?.trim();
       return parentId != null && parentId.isNotEmpty && parentId == currentSessionId;
     }

     bool get _hasPendingVisibleAggressiveThreadInteractions {
       for (final entry in _pendingPermissionsBySession.entries) {
         if (_isVisibleAggressiveSessionId(entry.key) && entry.value.isNotEmpty) {
           return true;
         }
       }
       for (final entry in _pendingQuestionsBySession.entries) {
         if (_isVisibleAggressiveSessionId(entry.key) && entry.value.isNotEmpty) {
           return true;
         }
       }
       return false;
     }
     ```
     Then update `_shouldKeepRealtimeActiveForDataSaver` so its aggressive branch returns false when the visible-session helper is false, returns true during interactive burst/current send/current response, and otherwise returns `_hasPendingVisibleAggressiveThreadInteractions`. Leave non-aggressive behavior unchanged.
   - **Risk**: Low; the helpers are private and feature-gated.
   - **Validation**: Unit tests must cover aggressive + route inactive, aggressive + route active/current session, and aggressive + pending interaction for non-current session.

4. Make chat-route visibility drive aggressive realtime policy.
   - **Files**: `lib/presentation/providers/chat_provider/chat_provider_lifecycle_ops.dart` in `setChatRouteActive`.
   - **Details**: Replace the setter body with idempotent route-change handling:
     ```dart
     void setChatRouteActive(bool isActive) {
       if (_isChatRouteActive == isActive) {
         return;
       }
       _isChatRouteActive = isActive;
       if (_cellularDataSaverService.isDataSaverActive) {
         if (isActive) {
           _cellularDataSaverService.noteExplicitUserAction(
             reason: 'chat-route-active',
           );
         }
         unawaited(
           _syncCellularDataSaverRealtimePolicy(
             reason: isActive ? 'chat-route-active' : 'chat-route-inactive',
             forceBurst: isActive,
           ),
         );
         if (isActive) {
           unawaited(
             _runAutomaticForegroundSyncForDataSaver(
               reason: 'chat-route-active',
               force: true,
             ),
           );
         }
       }
     }
     ```
     Ensure the new `_runAutomaticForegroundSyncForDataSaver(force: true)` signature is added in Step 6 before this compiles.
   - **Risk**: Medium; route changes now trigger sync work when entering chat. It is deliberate manual navigation behavior and remains feature-gated.
   - **Validation**: Test route inactive closes aggressive subscriptions and route active restarts only visible-session/burst behavior.

5. Tighten `_syncCellularDataSaverRealtimePolicy` for aggressive visible-session activity.
   - **Files**: `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart` in `_syncCellularDataSaverRealtimePolicy`.
   - **Details**: Keep existing non-data-saver and standard-data-saver branches unchanged. Replace the aggressive `shouldKeepActive` calculation with:
     ```dart
     final shouldKeepActive = _cellularDataSaverService.isAggressiveDataSaverActive
         ? _hasVisibleAggressiveDataSaverSession &&
             (forceBurst ||
                 _cellularDataSaverService.hasInteractiveBurst ||
                 _state == ChatState.sending ||
                 isCurrentSessionActivelyResponding ||
                 _hasPendingVisibleAggressiveThreadInteractions)
         : (forceBurst || _shouldKeepRealtimeActiveForDataSaver);
     ```
     Preserve the existing stop path that sets `_idleRealtimePausedForDataSaver = true`, sets sync state to connected with a data-saver-idle reason, and stops both subscriptions. Preserve `hasExpectedSubscriptions` so aggressive expects `_eventSubscription != null && _globalEventSubscription == null`. Preserve `_startGlobalRealtimeEventSubscription` early return for aggressive.
   - **Risk**: Medium; visible idle sessions stop realtime and rely on 30-second polling. This is the intended aggressive behavior.
   - **Validation**: Tests assert aggressive visible idle closes the stream, active send/current response/burst keeps the stream, and standard mode behavior remains unchanged.

6. Scope automatic foreground sync and add a forced manual/foreground path.
   - **Files**: `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart` in `_runAutomaticForegroundSyncForDataSaver`; `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart` in `_resumeRealtimeAfterForeground` and `_evaluateSyncHealth`.
   - **Details**: Change the signature to:
     ```dart
     Future<void> _runAutomaticForegroundSyncForDataSaver({
       required String reason,
       bool force = false,
     }) async {
     ```
     At the top, gate only non-forced automatic ticks:
     ```dart
     if (!force &&
         !_cellularDataSaverService.allowAutomaticForegroundSync(reason: reason)) {
       return;
     }
     ```
     Then add an aggressive branch before the standard branch:
     ```dart
     if (_cellularDataSaverService.isAggressiveDataSaverActive) {
       if (!_hasVisibleAggressiveDataSaverSession) {
         await _syncCellularDataSaverRealtimePolicy(reason: '$reason:not-visible');
         return;
       }
       await refreshActiveSessionView(
         reason: 'data-saver:$reason',
         includeStatus: false,
       );
       await _loadPendingInteractions(visibleSessionOnly: true);
       await _syncCellularDataSaverRealtimePolicy(reason: '$reason:post-sync');
       return;
     }
     ```
     Leave the standard data-saver path as: `loadSessions(preserveVisibleState: true)`, `refreshActiveSessionView(includeStatus: true)`, `_loadPendingInteractions()`, `_syncSelectionFromRemote(force: true)`, and policy sync. In `_resumeRealtimeAfterForeground`, pass `force: true` when calling `_runAutomaticForegroundSyncForDataSaver(reason: 'foreground-resume')`. In `_evaluateSyncHealth`, wrap automatic selection sync calls so aggressive data saver does not perform `_syncSelectionFromRemote(reason: 'sync-health-tick')` or `_attemptPendingRemoteSelectionSync(reason: 'sync-health-tick')`; still run stale-signal logic.
   - **Risk**: Medium; active-session status snapshots are skipped during automatic aggressive ticks to avoid global status requests. Manual refresh/foreground force paths still update visible data.
   - **Validation**: Tests assert automatic aggressive sync calls active session message refresh and visible pending interaction load, does not call `loadSessions`, does not call remote selection sync, and does not call session-status snapshot from the automatic path.

7. Filter pending interactions to the visible session/thread.
   - **Files**: `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart` in `_loadPendingInteractions`.
   - **Details**: Change the signature to:
     ```dart
     Future<void> _loadPendingInteractions({bool visibleSessionOnly = false}) async {
     ```
     Compute:
     ```dart
     final restrictToVisible = visibleSessionOnly ||
         _cellularDataSaverService.isAggressiveDataSaverActive;
     if (restrictToVisible && !_hasVisibleAggressiveDataSaverSession) {
       _pendingPermissionsBySession = const {};
       _pendingQuestionsBySession = const {};
       _threadPermissionsVersion++;
       _notifyListeners();
       await _syncCellularDataSaverRealtimePolicy(reason: 'pending-interactions:not-visible');
       return;
     }
     ```
     Inside both permission and question loops, before tombstone checks, skip entries whose `sessionId` is not `_isVisibleAggressiveSessionId(item.sessionId)` when `restrictToVisible` is true. Assign the grouped maps as usual, so inactive pending entries are removed from visible state while aggressive is active. Keep non-aggressive behavior unchanged.
   - **Risk**: Medium; underlying endpoints may still return all pending interactions because no per-session endpoint is known. This plan filters application and UI side effects locally, and documents that server-side/per-session API support would be required to eliminate those bytes.
   - **Validation**: Tests assert active-session permission/question entries remain visible, inactive-session entries are absent, and no active session clears both maps.

8. Suppress inactive events before feedback, state mutation, and fallback fetches.
   - **Files**: `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`.
   - **Details**: Add a private helper near existing event helpers:
     ```dart
     bool _shouldSuppressAggressiveDataSaverEvent(ChatEvent event, String? sessionId) {
       if (!_cellularDataSaverService.isAggressiveDataSaverActive) {
         return false;
       }
       if (event.type == 'server.connected' || event.type == 'server.heartbeat') {
         return false;
       }
       final affectsSession = event.type.startsWith('session.') ||
           event.type.startsWith('message.') ||
           event.type.startsWith('todo.') ||
           event.type.startsWith('permission.') ||
           event.type.startsWith('question.');
       if (!affectsSession) {
         return false;
       }
       if (!_hasVisibleAggressiveDataSaverSession) {
         return true;
       }
       return !_isVisibleAggressiveSessionId(sessionId);
     }
     ```
     In `_applyChatEventInner`, immediately after `_isEphemeralTitleEvent` and dedup registration but before `_feedbackEventForCurrentContext`, compute `eventSessionId` and return early when the helper returns true. On suppression, log the event type/session and add `_activeContextKey` to `_dirtyContextKeys`; do not dispatch feedback, do not call `_refreshPendingInteractionsForEvent`, do not schedule fallback fetches, and do not mutate inactive maps/status. In the `server.connected` case, keep `refreshActiveSessionView` for aggressive but call it with `includeStatus: false`, and skip `_syncSelectionFromRemote` when aggressive is active.
   - **Risk**: Medium; inactive-session completion/permission notifications will be delayed until the user opens that session or leaves aggressive data saver. This is intended by the request.
   - **Validation**: Tests emit inactive `session.status`, `message.updated`, `permission.asked`, and `question.asked` events while aggressive is active and assert no inactive state/feedback/fallback fetch occurs.

9. Harden global-event and debounced-refresh paths for aggressive mode.
   - **Files**: `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`.
   - **Details**: In `_handleGlobalEvent`, add an aggressive branch after `affectsContext` is computed and before incremental inactive snapshot application. The branch must mark the target context dirty when a directory can be resolved, mark the active context dirty when no directory exists, allow same-context visible-session events through `_tryApplyGlobalEventIncremental` only when `_isVisibleAggressiveSessionId(_extractEventSessionId(event.properties))` is true, and otherwise return without inactive snapshot application or fallback reconcile. In `_scheduleCurrentContextRefresh`, under aggressive mode do not call `loadSessions()` and do not call `refreshSessionStatusSnapshot()`. If `shouldRefreshActiveSession` is true, call `refreshActiveSessionView(reason: 'scoped-reconcile:$reason', includeStatus: false)`.
   - **Risk**: Low; global stream should be closed in aggressive, but this prevents stale subscriptions or races from doing broad work.
   - **Validation**: Tests assert aggressive global fallback does not call `loadSessions`, inactive snapshot mutation, or status snapshot refresh.

10. Skip automatic remote selection pulls during aggressive data saver without blocking manual selection writes.
    - **Files**: `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`, `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`, and `lib/presentation/providers/chat_provider/chat_provider_selection_sync_ops.dart` only if needed for a test seam.
    - **Details**: Do not add a blanket early return at the start of `_syncSelectionFromRemote`, because manual/user-driven selection writes and explicit initialization paths must remain immediate. Instead, remove or guard automatic aggressive callers:
      - In `_evaluateSyncHealth`, do not call `_syncSelectionFromRemote` or `_attemptPendingRemoteSelectionSync` when aggressive is active.
      - In `_runAutomaticForegroundSyncForDataSaver`, the aggressive branch must not call `_syncSelectionFromRemote`.
      - In `_applyChatEventInner`, do not call `_syncSelectionFromRemote` for current-session event types or `server.connected` when aggressive is active.
      - In `_runDegradedScopedSync`, aggressive remains routed through the aggressive branch from Step 6.
      Manual provider/model changes that call persistence/push code directly remain unchanged.
    - **Risk**: Low; cross-device model/agent selection may lag in aggressive mode, but visible chat content and manual local choices remain correct.
    - **Validation**: Tests assert automatic aggressive health/event/degraded paths do not call `/config` pull, while manual model/provider update tests still pass.

11. Scope post-reconnect recovery for aggressive cellular mode.
    - **Files**: `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart` in `_runPostReconnectRecovery`.
    - **Details**: At the start of `_runPostReconnectRecovery`, add an aggressive branch:
      ```dart
      if (_cellularDataSaverService.isAggressiveDataSaverActive) {
        try {
          AppLogger.info('post_reconnect_recovery_start mode=aggressive-data-saver');
          await _loadPendingInteractions(visibleSessionOnly: true);
          await refreshActiveSessionView(
            reason: 'post-reconnect-aggressive-data-saver',
            includeStatus: false,
          );
          await _syncCellularDataSaverRealtimePolicy(
            reason: 'post-reconnect-aggressive-data-saver',
          );
          AppLogger.info('post_reconnect_recovery_complete mode=aggressive-data-saver');
        } finally {
          _postReconnectRecoveryInFlight = false;
        }
        return;
      }
      ```
      Leave existing broad recovery unchanged for standard/off/non-cellular modes.
    - **Risk**: Medium; session list recovery is delayed in aggressive mode. This is intended because inactive/background session updates are out of scope for aggressive visible-session mode.
    - **Validation**: Tests assert aggressive post-reconnect recovery refreshes visible session and pending visible interactions only, not sessions list.

12. Ensure session selection starts visible-session burst after `_currentSession` changes.
    - **Files**: `lib/presentation/providers/chat_provider.dart` in `selectSession`.
    - **Details**: Keep the existing `noteExplicitUserAction(reason: 'select-session')`. Add a second policy sync immediately after `_currentSession = session;` so the policy evaluates against the newly selected session:
      ```dart
      if (_cellularDataSaverService.isDataSaverActive) {
        unawaited(
          _syncCellularDataSaverRealtimePolicy(
            reason: 'select-session-visible',
            forceBurst: true,
          ),
        );
      }
      ```
      Do not remove existing user-initiated load/insight calls.
    - **Risk**: Low; policy sync is idempotent.
    - **Validation**: Test aggressive session switch starts the expected visible-session burst after selection and does not start global stream.

13. Audit manual action immediacy and add missing burst notes.
    - **Files**: `lib/presentation/providers/chat_provider.dart` and relevant part files for user-triggered actions.
    - **Details**: Confirm these paths do not call `allowAutomaticForegroundSync` and remain immediate: `sendMessage`, stop/abort, `refresh`, `loadSessions(userInitiated: true)`, `selectSession`, permission reply, question reply, question reject, session delete/share/archive/rename/fork/compact/revert/redo/undo, explicit model/provider selection, and manual server-health refresh. Add `noteExplicitUserAction` before permission/question reply and reject methods if not already present:
      ```dart
      _cellularDataSaverService.noteExplicitUserAction(reason: 'reply-question');
      _cellularDataSaverService.noteExplicitUserAction(reason: 'reject-question');
      ```
      Use analogous reasons for permission replies. Do not delay the API call; the note only opens the burst window.
    - **Risk**: Low; manual burst notes increase responsiveness for user actions.
    - **Validation**: Tests call permission/question reply methods inside a hot 30-second automatic cooldown and assert the use case executes immediately.

14. Verify AppProvider active-server health polling and add a regression test.
    - **Files**: `lib/presentation/providers/app_provider.dart`; app-provider unit test file or new `test/unit/providers/app_provider_data_saver_test.dart`.
    - **Details**: Leave `app_provider.dart` unchanged if it still matches the verified behavior: `_effectiveHealthPollingInterval` returns `cellularDataSaverService.automaticSyncInterval` when `shouldThrottleAutomaticForegroundSync`, and `_startHealthPolling` refreshes only `activeServerId` under throttling. Add a test proving aggressive cellular polling interval is 30 seconds and automatic health refresh targets only the active server. If no suitable app-provider test file exists, create `test/unit/providers/app_provider_data_saver_test.dart` for this regression.
    - **Risk**: Low.
    - **Validation**: App-provider test passes and no production code change is needed unless the current file differs from the verified facts.

15. Update documentation after behavior is implemented.
    - **Files**: `BEHAVIOR.md`.
    - **Details**: Document the implemented behavior only:
      - Standard cellular data saver suppresses background work and uses the existing standard automatic interval.
      - Aggressive cellular data saver uses visible-session-only automatic work, never subscribes `/global/event`, closes project `/event` when visible-session realtime is not needed, runs retained automatic visible-session sync at 30 seconds, filters inactive permissions/questions/events, and keeps manual actions immediate through burst/manual paths.
      - Rollback is `--dart-define=CODEWALK_CELLULAR_DATA_SAVER=false`.
      Do not modify `.arb` files unless UI copy must change. Do not run global ARB generation.
    - **Risk**: Low.
    - **Validation**: Documentation matches code and does not claim server-side/per-session SSE support.

16. Update and add tests.
    - **Files**:
      - `test/unit/presentation/cellular_data_saver_service_test.dart`
      - `test/unit/providers/chat_provider_realtime_test.dart`
      - `test/unit/providers/chat_provider_session_ops_test.dart`
      - `test/unit/providers/app_provider_data_saver_test.dart` if no existing app-provider test file covers this.
    - **Details**: Add or update tests for:
      1. Aggressive automatic sync, sync health check, stale threshold, and degraded polling constants are `30 seconds`.
      2. Aggressive interactive burst remains `45 seconds`.
      3. `allowAutomaticForegroundSync` allows the first automatic tick, blocks within 30 seconds, and allows again at 30 seconds.
      4. Manual `noteExplicitUserAction` opens a burst but does not make automatic cooldown logic the source of manual action execution.
      5. Aggressive + foreground + chat route inactive + selected session closes realtime subscriptions.
      6. Aggressive + visible idle selected session closes project `/event` and relies on 30-second sync.
      7. Aggressive + visible send/current response/interactive burst keeps `/event` and never keeps `/global/event`.
      8. Automatic aggressive sync refreshes only active session messages, loads pending interactions with `visibleSessionOnly`, and skips `loadSessions`, `refreshSessionStatusSnapshot`, and `_syncSelectionFromRemote`.
      9. Inactive `session.status`, `message.updated`, `permission.asked`, and `question.asked` events do not mutate inactive UI state, feedback, or fallback fetches.
      10. Active-session permission/question events still appear and can be replied to immediately.
      11. Foreground resume and chat-route return use `force: true` and are not blocked by a hot automatic cooldown.
      12. AppProvider aggressive health polling uses 30 seconds and active server only.
    - **Risk**: Medium; provider tests may need existing fakes/test seams. Add `@visibleForTesting` read-only counters or debug accessors only when necessary and keep them narrow.
    - **Validation**: All new and updated tests pass.

17. Run focused validation, then the project gate.
    - **Files**: no edits.
    - **Details**: Run:
      ```bash
      flutter test test/unit/presentation/cellular_data_saver_service_test.dart
      flutter test test/unit/providers/chat_provider_realtime_test.dart
      flutter test test/unit/providers/chat_provider_session_ops_test.dart
      flutter test test/unit/providers/app_provider_data_saver_test.dart
      flutter analyze lib/presentation/services/cellular_data_saver_service.dart lib/presentation/providers/chat_provider.dart lib/presentation/providers/chat_provider lib/presentation/providers/app_provider.dart
      make check
      ```
      If the app-provider data-saver test is added to an existing app-provider test file instead, run that exact existing file instead of `app_provider_data_saver_test.dart`.
    - **Risk**: Low.
    - **Validation**: All commands pass. If a command fails for pre-existing unrelated dirty-tree changes, isolate the failure and report it before implementation proceeds further.

## Risks & Mitigations

- **Critical: Project-scoped `/event` cannot be made truly per-session locally.** Mitigation: close `/event` while visible session is idle, never open `/global/event`, filter inactive events before side effects, and document the limitation.
- **High: Directory-scoped permission/question endpoints may still return inactive-session payload bytes.** Mitigation: use visible-session-only application/filtering and avoid inactive UI/notification side effects; per-session server endpoints are out of scope.
- **High: Manual actions could be accidentally throttled.** Mitigation: audit manual paths, keep them off `allowAutomaticForegroundSync`, and add tests that execute manual replies/refreshes during a hot cooldown.
- **Medium: Reducing stale threshold to 30 seconds may enter degraded mode more often.** Mitigation: aggressive mode is opt-in, only visible-session scoped, and fallback polling is exactly the requested 30-second cadence.
- **Medium: Skipping automatic remote selection pulls may delay cross-device model/agent sync.** Mitigation: manual local selection remains immediate; aggressive mode prioritizes cellular data savings over background cross-device selection freshness.
- **Medium: Inactive session notifications are delayed.** Mitigation: this is requested aggressive behavior; opening that session or disabling aggressive data saver reconciles state.
- **Medium: Dirty working tree conflicts.** Mitigation: inspect diffs before edits and preserve unrelated changes.

## Assumptions to Validate

- **Assumption**: `watchChatEvents(directory: directory)` remains directory/project-scoped. **Validate** by checking the datasource/use case and official OpenCode docs. **Fallback if false**: keep event filtering anyway; if a true per-session stream exists, switch the aggressive visible-session stream to that official endpoint only if ADR-023 documents it.
- **Assumption**: No per-session pending permission/question endpoints are available. **Validate** against local official docs and use cases. **Fallback if false**: use the official per-session endpoint in `_loadPendingInteractions(visibleSessionOnly: true)` and remove broad endpoint fetches from aggressive automatic ticks.
- **Assumption**: Existing tests/fakes can observe needed calls. **Validate** before adding broad test seams. **Fallback if false**: add narrow `@visibleForTesting` counters/debug getters only for the changed behavior.
- **Assumption**: AppProvider code still matches the verified active-server throttling behavior. **Validate** before editing tests. **Fallback if false**: update AppProvider so throttled data-saver polling uses only the active server and 30-second aggressive interval.

## Decisions and Nuances

- The final plan intentionally chooses visible idle polling over always-on visible SSE because aggressive cellular data saving is the primary requirement and the stream is not proven per-session.
- The 30-second cadence applies to automatic query/poll/check behavior, not to manual API calls and not to the 45-second interactive burst window.
- `refreshActiveSessionView(includeStatus: false)` is used in automatic aggressive ticks to avoid global status snapshot traffic.
- `BEHAVIOR.md` must describe the local fallback limitation: inactive bytes cannot be eliminated while a directory-scoped stream is open, so the stream is closed except during visible-session realtime need.
- ADR-023 remains satisfied because no API contract changes are made.

## Blockers and Open Questions

None.

## Testing Strategy

Run focused unit/provider tests first, then analyzer on touched paths, then `make check`. The minimum required test evidence is:

- Service tests prove all aggressive automatic cadence constants are 30 seconds and burst remains 45 seconds.
- Realtime/provider tests prove aggressive mode: route hidden closes streams, visible idle closes project stream, visible active/burst keeps only project `/event`, global stream stays null, automatic tick is visible-session scoped, inactive events are suppressed, and manual actions execute inside cooldown.
- AppProvider test proves aggressive health polling interval is 30 seconds and active-server-only.
- Documentation is updated only after code and tests reflect the new behavior.

## Execution Handoff

Start with `git status --short`. Open and edit `lib/presentation/services/cellular_data_saver_service.dart` first, then `chat_provider.dart`, `chat_provider_lifecycle_ops.dart`, `chat_provider_realtime_aux_ops.dart`, `chat_provider_realtime_ops.dart`, `chat_provider_event_reducer_ops.dart`, and only then tests. Keep the implementation feature-gated through existing `CellularDataSaverService.isAggressiveDataSaverActive`. After tests pass, update `BEHAVIOR.md` to document the implemented behavior.

## Out of Scope

- Server-side OpenCode changes.
- New OpenCode endpoints or event schemas.
- A new feature flag.
- Changes to standard/off data saver behavior.
- Desktop/non-cellular behavior changes.
- Global l10n regeneration or broad ARB edits.
- Android APK build unless separately requested.
