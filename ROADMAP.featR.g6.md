---
feature: "featR g6 - Realtime Lifecycle and Pending Interaction Convergence"
group: "featR.g6"
dependency: "featR.g5"
status: "Pending"
---

# featR g6 - Realtime Lifecycle and Pending Interaction Convergence

## Objective
Clean up remaining local lifecycle heuristics and align realtime event processing (SSE/Global Events) and "Pending Interaction" (questions/permissions) loading with the official OpenCode contract.

## Why This Group Exists
After the major send/reconciliation changes in g4 and g5, many CodeWalk-specific lifecycle guards (like abort suppression, deferred idle reconciliation, and stream preservation on session switch) will become obsolete or even harmful. This group performs the final "infrastructure deep clean" to ensure our realtime engine is a faithful implementation of the OpenCode contract, not a collection of workarounds.

## Source of Truth / Baseline Hierarchy
1.  **Primary Authority**: OpenCode Web (`packages/app/src/context/global-sync/event-reducer.ts`, `packages/app/src/context/global-sync/bootstrap.ts`).
2.  **Corroboration**: OpenCode CLI (`packages/opencode/src/cli/cmd/tui/context/sync.tsx`).
3.  **Informative Only**: `BEHAVIOR.md` (Discard if it suggests custom idle/abort-handling logic).

## Dependencies / Execution Order
-   **Dependencies**: **featR.g5** (Requires simplified send/stop logic).
-   **Order**: This is the final "heavy lifting" logic group before the g7 cleanup sweep.

## In Scope
-   Reducing/removing leftover logic for abort suppression and deferred idle reconciliation.
-   Aligning `message.part.delta` and event-reducer logic with official Web patterns.
-   Correcting the scope of "Pending Interactions" (e.g., whether permissions/questions are aggregated across root vs child threads).
-   Removing extra "dedup" heuristics that are redundant after g4's safe reconciliation baseline.
-   Auditing and simplifying the SSE (Dio) infrastructure to ensure it is contract-equivalent.

## Out of Scope
-   Changing `10s` health polling (see g7).
-   UI-only visual tweaks.

## Primary CodeWalk File Targets
-   `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
-   `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`
-   `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart`
-   `lib/data/datasources/chat_remote_datasource.dart`

## Official OpenCode Reference Targets
-   `packages/app/src/context/global-sync/event-reducer.ts` (Mandatory: read this to understand official event priority).
-   `packages/app/src/context/global-sync/bootstrap.ts` (Check session lifecycle/sync startup).

## Detailed Implementation Plan
1.  **Lifecycle Heuristic Audit**: Search for "workaround" comments or complex conditional guards in the realtime ops files. Verify if they still serve a purpose after g4/g5 and delete them if they don't exist in the official reducer.
2.  **Event-Reducer Refactor**: Align the `ChatProvider`'s event processing loop with the official `event-reducer.ts`. Ensure that "idle" and "busy" transitions are driven by the exact same event types as the web client.
3.  **Pending Interaction Scope**: Verify if official OpenCode shows questions from a child thread in the main session view. Align CodeWalk's loading logic to match this aggregation (or isolation).
4.  **Simplify Stream Infrastructure**: If CodeWalk maintains complex stream-preservation logic during session switches that the web client doesn't, simplify it. Lean on the "re-subscribe on switch" model if that is the official contract.
5.  **Clean Abort Flow**: Ensure that a server-sent "abort" event resets the client state immediately, without waiting for local timeouts or suppressed handlers.

## Guardrails / Anti-goals
-   **No "Heuristic Bloat"**: Prefer deleting obsolete heuristics rather than adding "improved" ones.
-   **Contract-First**: If the official reducer is simpler, our reducer must become simpler.
-   **Ignore "Stability" Hacks**: Do not preserve local "stability" hacks (like fake idle delays) if the contract doesn't use them.

## Acceptance Checklist / Definition of Done
-   [ ] Realtime lifecycle logic matches official event-reducer behavior.
-   [ ] Pending interactions (permissions/questions) appear exactly where the official client shows them.
-   [ ] All "deferred idle" and "abort suppression" code is removed.
-   [ ] `make check` passes.

## Validation and Test Plan
-   Simulate a complex SSE sequence: `Busy` -> `Stream` -> `Server Abort` -> `Idle`. Verify the client reaches `Idle` exactly when the event arrives.
-   Manual test: Switch sessions rapidly during a stream; verify the app re-syncs correctly without "ghost" stream markers.

## Docs / ADR / CODEBASE Follow-up
-   Update `CODEBASE.md` to reflect the simplified realtime architecture.

## Mandatory `flow` Execution Block
1.  Implement the change;
2.  Run `make check`;
3.  Commit;
4.  Run reviewer for all code commits in the group;
5.  Fix accepted review findings and repeat reviewer until no accepted findings remain;
6.  Run `HEY_CAPTION="featR g6: realtime lifecycle convergence" make android`;
7.  Only then notify the user with the final report.

## Suggested HEY_CAPTION
"featR g6: Realtime Lifecycle Convergence"
