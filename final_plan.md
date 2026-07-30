# Issue #113: Recent Session Tabs Execution Plan

## Status

Ready for implementation.

No production code has been changed for issue #113. This plan supersedes the
completed issue #122 plan that previously occupied this file.

- Delivery branch: `main`.
- Temporary execution branch: `agent/issue-113-session-tabs-20260730`.
- Current version before execution: `1.179.0+1785246142`; requested minor
  release target: `1.180.0` (build number remains release-tool owned).

## Work Item

- Issue: https://github.com/verseles/codewalk/issues/113
- Title: `Adicionar abas de sessoes recentes com indicadores de estado`
- Objective: add a browser-like strip for switching quickly among open or
  recently active root sessions without requiring the Conversations sidebar.
- Before implementation, compare the plan against the recently added official
  OpenCode Desktop session-tab implementation. OpenCode is the primary product
  and lifecycle reference; OpenChamber remains a secondary community reference.
- Product decisions confirmed during planning:
  - show tabs only for the active server;
  - allow root sessions only, not child/subagent sessions;
  - preserve stable tab order and append newly opened/reopened tabs;
  - closing the active tab selects the right neighbor, then the left neighbor;
  - place the strip across the entire content width below the app bar, above
    conversations, files, chat, and utility panes on desktop;
  - keep the strip usable on mobile when explicitly enabled.

## Definition of Done

- Tabs use normalized server + project scope + session identity and never use
  title or visual position as identity.
- Only non-archived root sessions belonging to the active server are eligible.
- Eligibility uses the later of authoritative `ChatSession.time` and local
  `lastOpenedAt`, with a rolling three-hour cutoff.
- The selected session and busy/retry sessions are protected from automatic
  expiry, but an explicit close still removes them.
- Tabs restore in stable persisted order, never duplicate, and do not reorder
  when selected, renamed, updated, or alerted.
- Closing a tab is local only. It never archives, deletes, or mutates an
  OpenCode session.
- A user-closed tab stays closed across ordinary refresh/replay. A successful
  explicit reopen or a strictly newer authoritative session interaction makes
  it eligible again and appends it at the end.
- Closing the active tab selects the right neighbor, then the left neighbor.
  Closing the sole active tab enters the existing local New Chat draft flow.
- Cross-project activation uses the existing cache-first project switch and
  `ChatProvider.selectSession()` path.
- The normal leading slot is `ProjectIcon` with the existing folder fallback.
- Unseen attention uses error > question > completed priority. A busy/retry
  sync indicator is rendered independently beside the leading slot.
- Viewing a session marks current tab attention as seen without answering or
  rejecting a pending OpenCode question.
- A later completion, question, or error can become unseen again.
- Long titles ellipsize visually while retaining the full title in tooltip and
  semantics.
- Horizontal overflow scrolls instead of shrinking click/touch targets without
  bound, and the active tab is kept visible.
- Close controls work with mouse, keyboard, and touch and do not activate the
  underlying tab accidentally.
- Fresh native desktop installs default to visible; fresh Android/iOS installs
  default to hidden; web uses its initial viewport class. Explicit preference
  always wins and survives restart, resize, and rotation.
- Focused unit/widget tests, targeted analysis, and one stable `make check`
  validation gate pass.
- `BEHAVIOR.md` documents the implemented behavior and `CODEBASE.md` is updated
  if the implementation adds the planned provider part/widget files.
- After requested delivery, remote CI is successful and issue #113 receives an
  evidence comment and is closed.
- The completed implementation is released as minor version `1.180.0`; release
  CI reaches a final successful state and `hey` notifies the user only after
  that successful CI conclusion.

## Scope

### In Scope

- Active-server root-session tab collection across open/cached project scopes.
- Versioned, server-scoped local persistence for order, recency, close
  suppression, cached display metadata, and tab attention viewing state.
- Three-hour reconciliation and active/busy exceptions.
- Cross-project tab activation and deterministic local close fallback.
- Responsive tab strip, project icons, attention indicators, busy indicator,
  accessibility, localization, and display preference.
- Direct source comparison with the official OpenCode Desktop tabs at a pinned
  revision, preserving applicable behavior while documenting deliberate
  CodeWalk-specific differences.
- Focused unit/widget tests and project documentation after implementation.

### Out of Scope

- Tabs from multiple servers in one strip.
- Child/subagent sessions.
- OpenCode endpoint, schema, event, or lifecycle changes.
- A new server-wide session discovery request or undocumented `/session` query
  parameters. The first cut uses sessions already known through active/cached
  contexts plus persisted tab metadata.
- Making close archive or delete a session.
- Drag-and-drop/manual reordering.
- OpenCode Desktop parity features outside issue #113, including cross-server
  tabs, explicit reopen-closed history, draft tabs in the strip, numeric/cycle
  shortcuts, and tab renaming.
- Middle-click close as a release blocker.
- The OpenChamber 48-hour recency window.
- Persisting live busy, retry, error, question, or completion booleans as if
  they were server state.
- Changing project icon discovery or adding an icon field to OpenCode payloads.

## Architectural Alignment

### ADR-023

The feature is client-owned navigation and presentation. OpenCode remains
authoritative for sessions, timestamps, status, questions, errors, and events.
The implementation consumes the existing official session/event paths and does
not add or reinterpret a server contract. No ADR-023 exception is required.

### ADR-002, ADR-020, ADR-021, and ADR-022

- Context identity remains `serverId::scopeId`.
- Cross-project activation switches context before selecting the session.
- Session reopening remains cache-first/SWR through the existing provider path.
- Draft state remains isolated per project scope.
- The tab strip adds another navigation surface; it does not become a second
  owner for the active OpenCode session.

### ADR-040

Tabs reuse `ProjectIcon` and local project icon metadata. Open/active projects
may follow existing render-triggered discovery. Closed project tabs use cached
icon data without introducing background filesystem scans. Missing/unresolved
projects use the existing `Symbols.folder_open` fallback.

### ADR Decision

Do not add or update an ADR for this feature unless implementation discovers a
new architecture boundary or a required behavior that conflicts with the ADRs
above. The current design is an additive application of accepted decisions.

## Official OpenCode Desktop Reference

The official OpenCode repository is the primary implementation reference for
this feature. Initial anchor-time inspection used revision
`1e17856ba4b5b052650c8115060852f3f023844e`; re-check the current `dev` revision
before writing production code and record any behaviorally relevant changes in
the first progress commit.

Applicable upstream evidence:

- `packages/app/src/context/tabs.tsx` owns persisted ordered session/draft tab
  identity, cached title/directory metadata, atomic navigation transitions,
  server/session cleanup, and local close behavior without deleting a session.
- `packages/app/src/context/closed-tabs.ts` proves deterministic active-close
  fallback to the right neighbor and then the left neighbor.
- `packages/app/src/components/titlebar-tab-strip.tsx` resolves sessions through
  their server context, retains cached labels, scrolls horizontally, separates
  close gestures from navigation, and covers keyboard/overflow behavior.
- `packages/app/src/components/titlebar-session-events.ts` removes tabs only
  from explicit session-removal evidence instead of treating missing context as
  authoritative deletion.

Deliberate CodeWalk differences remain binding unless the deeper source review
finds a correctness issue:

- CodeWalk issue #113 is active-server-only and keys by normalized server,
  project scope/directory, and root-session ID.
- CodeWalk auto-collects recent sessions with a rolling three-hour window;
  OpenCode Desktop models explicitly opened tabs and drafts.
- CodeWalk keeps stable append order and does not add upstream drag-and-drop,
  reopen-closed history, cross-server tabs, draft tabs, or renaming in this cut.
- CodeWalk retains its mobile-first visibility preference and Material You
  composition rather than copying the desktop titlebar presentation.
- Official source informs local client behavior but does not override ADR-023,
  CodeWalk's existing provider ownership, or the issue's accepted decisions.

## Current Code Anchors

- Session cache, selection, context snapshots, status, and attention:
  - `lib/presentation/providers/chat_provider.dart`
  - `lib/presentation/providers/chat_provider_types_part.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_preference_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_session_attention_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_session_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart`
- Cross-project navigation:
  - `lib/presentation/pages/chat_page/chat_page_workspace_controller.dart`
  - `lib/presentation/pages/chat_page/chat_page_scaffold.dart`
- Responsive page composition:
  - `lib/presentation/pages/chat_page.dart`
- Display toggles:
  - `lib/domain/entities/experience_settings.dart`
  - `lib/presentation/providers/settings_provider.dart`
  - `lib/presentation/pages/chat_page/chat_page_chrome.dart`
  - `lib/presentation/pages/chat_page/chat_page_mobile_overflow.dart`
- Persistence:
  - `lib/core/constants/app_constants.dart`
  - `lib/data/datasources/app_local_datasource.dart`
  - `lib/data/datasources/app_local_datasource_storage_helpers.dart`
- Visual reuse:
  - `lib/presentation/widgets/project_icon.dart`
  - `lib/presentation/widgets/chat_session_list.dart`
  - `lib/presentation/widgets/sidebar_selection_indicator.dart`
  - `lib/presentation/pages/chat_page/chat_page_file_viewer.dart`

## Resolved State Design

### Ownership

Keep tab metadata in a dedicated `ChatProvider` part, for example
`chat_provider_session_tab_ops.dart`, with small immutable types in
`chat_provider_types_part.dart` or a narrowly named adjacent model file.

This is the smallest boundary because `ChatProvider` already owns:

- active server and project context transitions;
- active/cached session snapshots;
- successful session selection;
- realtime session updates/deletions;
- scoped status, question, error, and completion attention;
- route visibility needed to determine whether attention is being viewed;
- local session navigation preferences and `AppLocalDataSource`.

Do not create a page-only tab authority that must independently replay provider
events. Do not put tab records in `ExperienceSettings`; that model stores a
global visibility preference, not server-scoped runtime navigation state.

### Identity

Reuse the normalization semantics of `SessionAttentionIdentity` where practical:

```text
serverId + normalized project directory/scope + rootSessionId
```

The tab model may hold `SessionAttentionIdentity` directly because this feature
is root-only, or use an equally normalized tab identity without changing wire
models. Never key by title, project label, list index, or session ID alone.

### Persisted Payload

Add a versioned JSON payload under a new `AppConstants` key, scoped by
`serverId` through the existing `_scopedKey` helper and not by `scopeId`:

```json
{
  "version": 1,
  "open": [
    {
      "directory": "/project",
      "projectId": "project-id",
      "sessionId": "ses_123",
      "title": "Cached title",
      "lastOpenedAtMs": 0,
      "serverUpdatedAtMs": 0,
      "seenQuestionIds": [],
      "seenCompletionToken": null,
      "seenErrorToken": null
    }
  ],
  "closed": [
    {
      "directory": "/project",
      "sessionId": "ses_123",
      "closedAtMs": 0,
      "observedServerUpdatedAtMs": 0
    }
  ]
}
```

Exact field names may follow repository conventions, but preserve these rules:

- array order is display order;
- title/project ID are cache-only display/navigation fallbacks;
- `ChatSession.time` replaces cached server time when fresher;
- attention viewing tokens contain server/event-owned IDs or deterministic
  fingerprints, never fabricated OpenCode state;
- live status/attention booleans are always derived from `ChatProvider`;
- malformed/unknown-version entries are ignored safely without blocking chat;
- writes are serialized so late saves cannot restore a closed/reordered record.

No hard visible-tab count is introduced in the first cut. The three-hour window
bounds normal records, while closed tombstones are pruned after they can no
longer suppress an otherwise eligible stale record.

## Eligibility and Reconciliation

Use an injectable/current clock in pure reconciliation helpers so boundaries
are deterministic in tests.

For every root session known from the active context, cached context snapshots,
or persisted open records:

```text
effectiveRecentAt = max(ChatSession.time, lastOpenedAt)
eligible = effectiveRecentAt >= now - 3 hours
           || selected in the active context
           || busy/retry in its cached/active context
```

Apply these rules in order:

1. Normalize identity and reject empty server, directory, or session values.
2. Restrict output to the active server.
3. Exclude child sessions and archived root sessions.
4. Deduplicate by normalized identity, preserving the first persisted position.
5. Refresh cached title/project/server timestamp without moving the tab.
6. Append newly eligible identities to the end.
7. Keep selected and busy/retry tabs through cutoff expiry.
8. Prune stale, non-selected, non-busy entries during restore/reconciliation.
9. Remove a session after authoritative remote deletion or confirmed local API
   deletion. Do not treat an unloaded/offline scope as deletion.
10. Remove project references only after explicit project-history/context
    removal, not merely because a project is currently closed.

### Close Suppression and Reopening

- Closing writes a tombstone before/with removing the visible record.
- Snapshot refreshes, status replays, and unchanged session timestamps do not
  resurrect a tombstoned tab.
- Successful explicit navigation to that session clears the tombstone, updates
  `lastOpenedAt`, and appends the tab.
- A strictly newer authoritative session timestamp than the version observed at
  close also clears the tombstone and appends the tab.
- Busy/retry state alone does not immediately undo an explicit close.
- Expiry pruning is not a user close and needs no tombstone; later interaction
  naturally makes the session eligible again.

### Interaction and Seen Semantics

- Update `lastOpenedAt` only after the target session successfully becomes the
  visible current session, regardless of whether navigation originated in the
  sidebar, recent sessions, notification, fork result, or the tab strip.
- Failed/aborted selection attempts do not refresh recency.
- While the chat route and selected session are visible, current attention is
  considered viewed. If the route is inactive or another session is selected,
  new attention remains unseen.
- Completion and error viewing may reuse existing provider clear behavior.
- Pending questions remain server-owned and unresolved after viewing. Persist a
  fingerprint/set of seen pending question IDs so the question icon can clear
  while the request remains pending and reappear for a later question.
- If existing `SessionAttentionState` cannot distinguish questions from generic
  pending permissions, extend it narrowly or expose a scoped pending-question
  accessor. Do not label all permissions as questions accidentally.
- Use deterministic event/message/request fingerprints so a replay is not new
  attention and a genuinely later event can alert again.

## Preference and Defaults

Add nullable `showSessionTabsOverride` to `ExperienceSettings`:

- `null` means no explicit user choice;
- `true` or `false` is persisted explicit intent.

Effective default when the override is null:

- Linux, macOS, and Windows: `true`;
- Android and iOS: `false`;
- web: capture the initial `WindowSizeClass` once; non-compact is `true` and
  compact is `false`.

Do not persist the computed default as an explicit choice. Do not recompute the
web default after resize/rotation within the same app run. The first toggle
stores the opposite of the current effective value, after which that explicit
value always wins.

Add the setting to both existing Display Toggles surfaces with localized label,
tooltip/description, and tests. Do not couple it to `showRecentSessions`.

## Navigation and Close Flow

### Activate Tab

1. Ignore a duplicate activation already in flight for the same identity.
2. If the tab project is closed, reopen it with `makeActive: true`; otherwise
   switch through the existing serialized project-scope transition.
3. Let `ChatProvider.onProjectScopeChanged(waitForRevalidation: false)` restore
   cache/SWR state.
4. Resolve the session from the restored/loaded target scope.
5. Call the existing `selectSession()` path.
6. Only after success, mark the tab selected/viewed and update `lastOpenedAt`.
7. On failure, retain the prior active selection/tab and surface the existing
   bounded navigation error behavior.

The project transition overlay covers the full body, including the tab strip,
so users cannot start competing transitions from another tab.

### Close Tab

1. Stop close-button pointer/tap handling from activating the tab.
2. Persist local close suppression and remove the tab immediately.
3. If the closed tab was inactive, keep the current session unchanged.
4. If active, select the right neighbor from the pre-close order; if absent,
   select the left neighbor.
5. If no neighbor exists, enter the existing New Chat local draft flow without
   creating a remote session until first send.
6. If neighbor activation fails, restore a coherent prior tab/selection rather
   than leaving the visible session and active-tab identity mismatched.

Never call `deleteSession`, `DELETE /session/:id`, archive, or another remote
mutation from this flow.

## Responsive UI

Create a focused widget such as
`lib/presentation/widgets/session_tab_strip.dart` and compose it in
`ChatPage` immediately below the app bar and above the complete body content.

Desktop/web expanded structure:

```text
Scaffold body
  Column
    SessionTabStrip (when enabled and non-empty)
    Expanded
      Row
        Conversations pane
        Files pane
        Chat
        Utility pane
```

Mobile/compact uses the same full-width strip above chat content. The drawer
remains unchanged.

Each tab contains:

- leading project/attention slot;
- truncated session title;
- separate busy/retry sync indicator when applicable;
- close button with localized tooltip/semantic label.

Visual priority:

```text
error > unseen pending question > unseen completion > ProjectIcon/folder
```

The busy/retry indicator never replaces that slot. Use the existing
`Symbols.sync_rounded` treatment and retry semantics where available.

Interaction/accessibility requirements:

- horizontal scroll with desktop scrollbar/touch drag and no unbounded tab
  compression;
- selected tab auto-scrolls into view after activation/restore/resize;
- `Semantics(selected: true)` and full title/status announcements;
- visible hover, focus, pressed, selected, and attention states in light/dark
  themes without color-only meaning;
- Material minimum hit targets, including close on mobile;
- keyboard activation and close focus behavior;
- text direction and horizontal scroll behavior remain valid for RTL locales;
- middle-click may be added only if local and low-risk after required behavior
  is complete.

## Implementation Sequence

### Step 1: Preference and Persisted Tab Metadata

- Re-check the official OpenCode Desktop tab implementation on current `dev`,
  compare it with the pinned files above and OpenChamber, and record which
  lifecycle, identity, navigation, close, overflow, and test patterns are
  adopted or deliberately rejected before finalizing local types.
- Add nullable visibility override to `ExperienceSettings`, JSON/copy/equality,
  `SettingsProvider`, and both Display Toggles surfaces.
- Add the server-scoped versioned tab-state key and datasource interface/impl.
- Extend test fakes.
- Add round-trip, missing-key, corrupt JSON, unknown-version, native default,
  mobile default, web initial-viewport, explicit override, and resize tests.
- Use the safe ARB translation workflow; never run the destructive global
  `dart tool/i18n/generate_arb.dart` path.
- Focused validation: relevant settings/datasource tests and targeted analysis.
- Review gate: run the Reviewer Loop and apply only judge-approved corrections.

### Step 2: Tab State, Recency, and Attention Viewing

- Add immutable identity/record/snapshot types and provider tab-state part.
- Load tab state atomically when active server changes, with generation guards
  so late reads/writes cannot leak across servers.
- Implement pure eligibility, deduplication, stable order, append, tombstone,
  expiry, active/busy exception, and seen-fingerprint helpers.
- Reconcile active and cached context sessions without new network contracts.
- Hook successful selection, session create/update/delete, confirmed local
  deletion, server switch, and explicit project-history removal.
- Add scoped status/question access needed by the tab UI without changing
  existing attention semantics for sidebar/notifications.
- Focused validation: new tab-state tests plus provider project/session/event
  tests and targeted analysis.
- Review gate: run the Reviewer Loop and apply only judge-approved corrections.

### Step 3: Navigation and Responsive Tab Strip

- Generalize/reuse the current cross-project session opening path for tab
  activation.
- Implement right-then-left close fallback and sole-tab New Chat behavior.
- Add the full-width strip below the app bar and above all body panes.
- Reuse `ProjectIcon`, existing status/attention sources, Material tokens, and
  existing close/overflow/accessibility patterns.
- Add localization and widget keys/semantics needed for deterministic tests.
- Add widget/integration tests for desktop, web compact/expanded, mobile opt-in,
  cross-project activation, close behavior, status combinations, project icon
  fallback, overflow, active visibility, keyboard, touch, and semantics.
- Focused validation: tab/widget/chat-page tests and targeted analysis.
- Stable gate: run `make check` once after focused checks are green.
- Review gate: run the Reviewer Loop and apply only judge-approved corrections;
  use focused revalidation for micro-fixes unless they invalidate `make check`.

### Step 4: Documentation and Delivery

- Update `BEHAVIOR.md` only after behavior is implemented and verified.
- Update `CODEBASE.md` through the codebase documentation flow if new provider
  part/widget files create a durable structural entry point.
- Keep `ADR.md` unchanged unless execution discovers a real new decision or
  ADR-023 conflict.
- Inspect final diff and status; run any final focused check invalidated by docs
  or reviewer fixes.
- Consolidate the reviewed execution-branch progress commits onto `main` while
  preserving the immutable anchor and verifying identical trees.
- Push the consolidated `main`, monitor its CI to a final successful result,
  and resolve any judge-approved failure before release.
- Delegate `make release V=minor` to the release flow, producing `v1.180.0`,
  then monitor release/tag CI through `cimonitor` until final success.
- After release CI succeeds, run `~/bin/hey` with a specific Portuguese message
  saying that CodeWalk `v1.180.0` and its CI completed successfully. Do not send
  the completion notification while release CI is pending or failed.
- Post a Portuguese evidence comment on issue #113 with tests and behavior
  delivered, then close the issue only after successful CI and acceptance gates.

## Test Plan

### Unit Coverage

- normalized triple identity and cross-project/session collision resistance;
- root-only and non-archived filtering;
- exact three-hour boundary;
- `max(server time, lastOpenedAt)`;
- selected and busy/retry expiry exceptions;
- explicit close overriding active/busy retention;
- stable order, deduplication, append-on-new, and append-on-reopen;
- close tombstone surviving ordinary refresh/replay;
- strictly newer interaction clearing close suppression;
- right neighbor, left neighbor, and sole-tab fallback;
- malformed/versioned persistence and serialized write races;
- active-server switch generation isolation;
- seen question IDs/fingerprints and new-question re-alert;
- deterministic error > question > completion priority;
- active route viewed versus inactive route unseen behavior;
- authoritative delete versus unloaded/offline context behavior;
- nullable visibility preference and platform/web defaults.

### Widget Coverage

- strip absent when disabled or empty;
- desktop default visible and mobile default hidden;
- explicit mobile enable and explicit desktop disable;
- web initial compact/expanded defaults remain stable after resize;
- full-width placement above all desktop body panes;
- project icon and folder fallback;
- title ellipsis with complete tooltip/semantics;
- active selection and ensure-visible behavior;
- independent busy indicator with project/error/question/completion slot;
- light/dark attention contrast and non-color semantics;
- horizontal overflow at narrow widths with no RenderFlex overflow;
- mouse, keyboard, and touch close without accidental activation;
- cross-project cache-first activation and failed-navigation recovery.

### Candidate Test Files

- `test/unit/domain/experience_settings_test.dart`
- `test/unit/providers/settings_provider_test.dart`
- `test/unit/datasources/app_local_datasource_impl_test.dart`
- `test/unit/providers/chat_provider_session_ops_test.dart`
- `test/unit/providers/chat_provider_project_test.dart`
- `test/unit/providers/chat_provider_concurrency_test.dart`
- new focused provider/helper tests for tab reconciliation
- new `test/widget/session_tab_strip_test.dart`
- `test/widget/chat_page_test.dart`
- `test/support/fakes.dart`

### Validation Commands

Use the narrowest relevant commands while iterating, always with Flutter on PATH:

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter test <focused test files>
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze <changed Dart paths>
```

When stable:

```bash
make check
```

Run `make android` only if the user requests a testable APK and the current host
supports it. Android packaging is not required merely to complete planning.

## Risks and Mitigations

- Risk: a closed tab reappears on the next provider notification.
  - Mitigation: persisted version-aware tombstone cleared only by successful
    explicit reopen or strictly newer authoritative interaction.
- Risk: stale async storage work leaks tab state between servers.
  - Mitigation: active-server generation tokens and serialized writes.
- Risk: cross-project activation targets the old project/session.
  - Mitigation: reuse serialized workspace transition, resolve after hydration,
    and update recency only after successful selection.
- Risk: pending questions never clear because they remain server-side.
  - Mitigation: persist seen request IDs/fingerprints independently from request
    resolution; never mutate the OpenCode question.
- Risk: generic pending permissions are mislabeled as questions.
  - Mitigation: expose question-specific state instead of relying only on the
    combined `hasPendingInteraction` flag.
- Risk: inactive cached contexts have stale status.
  - Mitigation: display only best-known provider state, never fabricate state,
    and reconcile authoritatively when the project becomes active.
- Risk: a missing snapshot is mistaken for remote deletion.
  - Mitigation: prune only after explicit/authoritative deletion or explicit
    local project-history removal.
- Risk: many tabs create rebuild/jank pressure.
  - Mitigation: three-hour pruning, immutable selected slices/keys, per-tab
    selectors where practical, bounded title width, and focused performance
    inspection before introducing an unspecified hard cap.
- Risk: web resize changes an implicit default unexpectedly.
  - Mitigation: capture initial web size class once; explicit nullable override
    remains authoritative.

## Rejected Alternatives

- Global tabs across all configured servers: rejected for the first cut because
  inactive-server realtime/status would be stale and switching transport/auth
  broadens scope.
- Child/subagent tabs: rejected because current recent-session and attention
  surfaces are root-oriented; nested navigation remains a separate concern.
- Dynamic MRU reordering: rejected because moving tabs on every activation is
  visually unstable and unlike the confirmed browser-style behavior.
- Page-only tab controller: rejected because it would duplicate provider event,
  route visibility, server lifecycle, and persistence coordination.
- Storing tab records in `ExperienceSettings`: rejected because tab state is
  active-server runtime navigation metadata, not a global preference.
- New server-wide session scan or undocumented query parameters: rejected to
  preserve ADR-023 and the issue's client-side scope.
- Hard tab count in the first cut: rejected because acceptance requires all
  three-hour-eligible sessions and overflow is already required.
- Reusing `deleteSession` for close: rejected because it is destructive server
  mutation and directly violates the issue.
- Updating ADR.md preemptively: rejected because accepted ADRs already cover the
  design and no exception/new boundary is currently required.

## References

- https://github.com/verseles/codewalk/issues/113
- `BEHAVIOR.md`, Sessions section
- `ADR.md`: ADR-002, ADR-020, ADR-021, ADR-022, ADR-023, ADR-040
- `ai-docs/opencode_server.md`: `/session`, `/session/status`, `/event`, and
  `/global/event` contracts
- `ai-docs/opencode_web.md`: sessions shared across clients
- https://github.com/openchamber/openchamber/blob/main/packages/ui/src/components/layout/ContextPanel.tsx
- https://github.com/openchamber/openchamber/blob/main/packages/ui/src/components/ui/sortable-tabs-strip.tsx
- https://github.com/openchamber/openchamber/blob/main/packages/ui/src/components/session/sidebar/activitySections.ts
- https://github.com/anomalyco/opencode/blob/1e17856ba4b5b052650c8115060852f3f023844e/packages/app/src/context/tabs.tsx
- https://github.com/anomalyco/opencode/blob/1e17856ba4b5b052650c8115060852f3f023844e/packages/app/src/context/closed-tabs.ts
- https://github.com/anomalyco/opencode/blob/1e17856ba4b5b052650c8115060852f3f023844e/packages/app/src/components/titlebar-tab-strip.tsx
- https://github.com/anomalyco/opencode/blob/1e17856ba4b5b052650c8115060852f3f023844e/packages/app/src/components/titlebar-session-events.ts

## Handoff Notes

- Execution of this file must begin with the required immutable
  `AGENT_PLAN_ANCHOR` commit and use one reviewed progress commit per step.
- Preserve unrelated worktree changes and never recreate `ROADMAP.md`.
- Build tests alongside each implementation step, not as a final retrofit.
- Reviewer findings are advisory; apply only judge-validated corrections.
- Treat official OpenCode Desktop as the primary UI/lifecycle reference and
  OpenChamber as secondary; copy neither implementation mechanically.
- The final delivery is not complete at the feature push: release minor version
  `1.180.0`, wait for release CI success, notify through `hey`, then post issue
  evidence and close issue #113.
- Do not close issue #113 before remote CI and all applicable acceptance gates
  are successful.
