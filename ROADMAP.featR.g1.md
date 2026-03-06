---
feature: "featR g1 - Contract Safety Net and Test Harness"
group: "featR.g1"
dependency: "None (Base group)"
status: "Pending"
---

# featR g1 - Contract Safety Net and Test Harness

## Objective
Build a robust regression harness that anchors CodeWalk's behavior to the official OpenCode contract before any logic is modified. This group creates the deterministic safety net that all later convergence groups (g2-g7) depend on.

## Why This Group Exists
Later groups will fundamentally change the send lifecycle, optimistic reconciliation, child-thread composition, and tool-call UI. Without dedicated replay/provider/widget coverage that mirrors the official contract's edge cases, regressions in message ordering, state flickers, and stream handling will be easy to introduce and extremely hard to localize.

## Source of Truth / Baseline Hierarchy
1.  **Primary Authority**: OpenCode Web source code (`packages/app/src/context/global-sync/event-reducer.ts`, `packages/app/src/pages/session/message-timeline.tsx`, etc.).
2.  **Corroboration**: OpenCode CLI/TUI behavior and source.
3.  **Informative Only**: `BEHAVIOR.md` (Not authoritative if it conflicts with official Web/contract parity).

## Dependencies / Execution Order
-   **Dependencies**: None.
-   **Order**: This is the **Safety Base**. It MUST be completed first. No behavior-changing groups should start until this harness is verified.

## In Scope
-   Expansion of `ChatProvider` replay tests to cover complex event sequences.
-   Creation of deterministic test seams in the provider and message reducers.
-   Widget-level integration tests for `ChatMessageWidget` and tool-call rendering.
-   Test helpers for simulating SSE streams, optimistic user messages, and server echoes.
-   Coverage for "send-while-busy" transitions (to capture current behavior before we simplify it).

## Out of Scope
-   Any change to runtime behavior, send logic, or UI appearance.
-   Removal of any legacy workarounds (save that for g4-g7).

## Primary CodeWalk File Targets
-   `lib/presentation/providers/chat_provider.dart`
-   `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
-   `lib/presentation/widgets/chat_message_widget.dart`
-   `lib/presentation/widgets/chat_message/chat_message_tool_part.dart`
-   `test/presentation/providers/chat_provider_test.dart`
-   `test/presentation/widgets/chat_message_widget_test.dart`

## Official OpenCode Reference Targets
-   `packages/app/src/context/sync.tsx`
-   `packages/app/src/context/global-sync/event-reducer.ts`

## Detailed Implementation Plan
1.  **Analyze Current Gaps**: Audit `test/` to identify where message merging, tool-call expansion state, and rapid-send transitions lack coverage.
2.  **Deterministic Test Seams**: If the current provider logic is too opaque for testing, add tiny, injectable seams (e.g., exposing an internal reducer or allowing a mock `EventSource`).
3.  **Implement Replay Harness**: Create a test suite that feeds the provider a sequence of "Optimistic User Message" followed by "Server Echo" and "Stream Delta" events, asserting final timeline state matches OpenCode Web expectations.
4.  **Widget State Persistence Test**: Create a widget test for `ChatMessageToolPart` that verifies expansion state is preserved when the underlying message object is replaced by a "newer" version with the same content/ID.
5.  **Integration Smoke Test**: Ensure a full "prompt to response" cycle is covered by a test that can detect if message parts are dropped or duplicated.

## Guardrails / Anti-goals
-   **No Semantic Drift**: If a test fails because CodeWalk's current behavior is "wrong" compared to the contract, do NOT fix the behavior yet. Document it as a known gap and keep the test as a "current baseline" or skip it with a note.
-   **No UI Refactoring**: Do not clean up widget code unless strictly necessary for testability.
-   **No Polling Changes**: Keep the `10s` health polling exactly as it is.

## Acceptance Checklist / Definition of Done
-   [ ] `make check` passes with new tests.
-   [ ] Provider replay tests cover optimistic replacement and stream appending.
-   [ ] Widget tests cover tool-call expansion state preservation.
-   [ ] Test seams do not expose private state to production logic unnecessarily.

## Validation and Test Plan
-   Run `flutter test test/presentation/providers/chat_provider_test.dart`.
-   Run `flutter test test/presentation/widgets/chat_message_widget_test.dart`.
-   Verify that manually breaking the provider's merge logic triggers a test failure.

## Docs / ADR / CODEBASE Follow-up
-   Update `CODEBASE.md` only after the reviewer loop to reflect any new test infrastructure or seams.

## Mandatory `flow` Execution Block
1.  Implement the change;
2.  Run `make check`;
3.  Commit;
4.  Run reviewer for all code commits in the group;
5.  Fix accepted review findings and repeat reviewer until no accepted findings remain;
6.  Run `HEY_CAPTION="featR g1: regression safety harness" make android`;
7.  Only then notify the user with the final report.

## Suggested HEY_CAPTION
"featR g1: Contract Safety Net and Test Harness"
