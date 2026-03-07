---
feature: "featR g6 - Realtime Lifecycle and Pending Interaction Convergence"
group: "featR.g6"
dependency: "featR.g5"
status: "Completed"
---

# featR g6 - Realtime Lifecycle and Pending Interaction Convergence

## Objective
Align CodeWalk's realtime lifecycle and "Pending Interaction" (permissions/questions) logic with the official OpenCode Web upstream source. This roadmap is based on confirmed upstream behavior—not speculation—and treats OpenCode Web as the authoritative target for contract compliance.

## Why This Group Exists (Intent & Proof)
We have identified that CodeWalk currently employs several local heuristics (session cleanup suppression, deferred idle reconciliation) that do not exist in the reference implementation. Upstream source analysis proves that the official client manages state transitions and interaction scoping strictly by `sessionID` without these "stability" layers. Aligning now ensures we don't drift into a collection of idiosyncratic workarounds that break when the official contract evolves.

## Source of Truth
1.  **Authoritative Target**: OpenCode Web (`packages/app/src/context/global-sync/event-reducer.ts`, `packages/app/src/context/global-sync/bootstrap.ts`).
2.  **Corroboration**: OpenCode CLI (`packages/opencode/src/cli/cmd/tui/context/sync.tsx`).
3.  **Caveat**: `BEHAVIOR.md` and ADR-019-style config-sync deferral are separate concerns. **Keep ADR-019 logic** unless upstream config-sync behavior specifically proves it unnecessary.

## Upstream Proof & Evidence
Confirmed findings from OpenCode Web source code:
- **Session Scoping**: `packages/app/src/context/global-sync/event-reducer.ts` stores `session.status` and state strictly by `sessionID`.
- **Interaction Storage**: `permission.asked` and `question.asked` events are stored in the reducer state indexed by `sessionID`.
- **Immediate Cleanup**: `permission.replied`, `question.replied`, and `question.rejected` events trigger the immediate removal of their respective items from the session-scoped store.
- **Initial Sync**: `packages/app/src/context/global-sync/bootstrap.ts` loads existing permissions/questions via list APIs and groups them by `sessionID` during client initialization.
- **No Suppression**: The upstream reducer does **not** contain any logic for deferred-idle transitions or suppression of current-session error/idle lifecycle cleanup.

## In Scope
- Align `session.status` and pending interaction ownership with the upstream session-scoped store model.
- Remove local reducer-level deferred-idle and current-session lifecycle-suppression behavior where the upstream reducer has no equivalent.
- Verify whether CodeWalk's current interaction presentation across parent/child sessions still matches upstream intent before preserving it.
- Audit `message.part.updated` / `delta` handling against upstream event ordering before changing it.

## Out of Scope
- Removing ADR-019 config-sync deferral (preserved as a separate lifecycle concern).
- Visual UI tweaks not required by the logic alignment.

## Detailed Implementation Plan
1.  **Strict Session Scoping**: Update `ChatProvider` and its auxiliary ops to ensure `session.status` and pending interactions are managed in a map-like structure keyed by `sessionID`, matching `event-reducer.ts`.
2.  **Interaction Lifecycle Alignment**: Refactor the event handlers for `permission.*` and `question.*` to match the upstream logic of immediate removal upon reply/rejection.
3.  **Bootstrap Sync**: Update the initial loading logic (likely in `chat_remote_datasource.dart` or `ChatProvider` init) to group retrieved interactions by `sessionID`.
4.  **Heuristic Removal**: Identify and delete any CodeWalk-specific code that implements "fake" idle delays or suppresses current-session error/idle lifecycle cleanup at the reducer level when that behavior is not present upstream.
5.  **Contract-First Verification**: Perform a line-by-line comparison of our event processing loop against the upstream `event-reducer.ts` to ensure identical transition triggers.

## Guardrails / Anti-goals
- **No Blind Removal**: Do not remove the ADR-019-style `PATCH /config` deferral logic without specific upstream evidence regarding config-sync.
- **Contract-First**: If the official reducer is simpler, our reducer must become simpler.
- **Precision**: Scoping must be strictly by `sessionID`, as proven by upstream.

## Acceptance Checklist / Definition of Done
- [x] Realtime lifecycle and interaction state are strictly keyed by `sessionID`.
- [x] Permissions and questions are removed immediately on reply/rejection.
- [x] `bootstrap.ts` grouping logic is implemented for initial sync.
- [x] Reducer-level deferred-idle and non-upstream lifecycle-suppression logic are removed.
- [x] `make check` passes.

## Validation and Test Plan
- **Interaction Loop**: Trigger a permission request, reply to it, and verify it is removed from the local store immediately without a full refresh.
- **Session Isolation**: Start a stream in Session A, switch to Session B, and verify interactions for Session A do not appear in Session B's view (and vice versa).
- **Lifecycle Cleanup**: Simulate the upstream current-session termination/error sequence that applies to the active turn and verify the client clears responding state immediately without local suppression delays.

## Mandatory `flow` Execution Block
1.  Implement the change;
2.  Run `make check`;
3.  Commit;
4.  Run reviewer for all code commits in the group;
5.  Fix accepted review findings and repeat reviewer until no accepted findings remain;
6.  Run `HEY_CAPTION="featR g6: upstream-aligned lifecycle convergence" make android`;
7.  Only then notify the user with the final report.

## Suggested HEY_CAPTION
"featR g6: upstream-aligned lifecycle convergence"
