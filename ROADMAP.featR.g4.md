---
feature: "featR g4 - Optimistic Message IDs and Reconciliation"
group: "featR.g4"
dependency: "featR.g1"
status: "Delivered"
---

# featR g4 - Optimistic Message IDs and Reconciliation

## Objective
Align optimistic send IDs and message reconciliation logic with the delivered safe baseline, ensuring ADR-023 compliance.

## Why This Group Exists
This group ensures that CodeWalk's message reconciliation respects the official contract (ADR-023) while avoiding the pitfalls of premature parity (Pitfall P-001). By keeping `local_user_*` IDs and preserving tool-visibility during turns-in-flight, we maintain a stable UX that doesn't "blink" or hide work-in-progress during background refreshes. This fulfills the BEHAVIOR's optimistic-ID/tool-visibility contract.

## Source of Truth / Baseline Hierarchy
1.  **ADR-023**: Contract-first compatibility and Pitfall P-001 (Optimistic ID mismatch).
2.  **BEHAVIOR.md**: Optimistic ID and tool-visibility contract.
3.  **OpenCode Web**: Referenced for reconciliation logic but superseded by ADR-023 for ID generation at this stage.

## Dependencies / Execution Order
-   **Dependencies**: **featR.g1** (Regression harness).
-   **Order**: MUST land before g5 and g6. Reconciliation stability is the foundation for lifecycle cleanup.

## In Scope
-   Keep `local_user_*` optimistic IDs in the provider to avoid ID collisions and double-bubbles.
-   Do NOT forward `messageId` in provider `prompt_async` sends (preserving server-side ID assignment).
-   Preserve active tool/work visibility during refresh/reconcile while the turn is still in flight.
-   Add regression coverage that protects refresh/reconcile from hiding tool-call UI before the final response.
-   Stabilize the baseline for g5/g6 without changing queue removal or realtime cleanup yet.

## Delivery Status
-   **make check**: Passed
-   **Android Build**: Produced
-   **Caption**: `featR g4: safe optimistic reconcile coverage`
-   **Commit**: `5cabcf0`, `a066026`
-   **Review**: `LGTM after follow-up fixes`

## Acceptance Checklist / Definition of Done
-   [x] `local_user_*` IDs are preserved and used for reconciliation.
-   [x] `prompt_async` does not forward `messageId`.
-   [x] Tool/work visibility is preserved during turn-in-flight refresh.
-   [x] Regression tests protect against hiding tool-call UI.

## Validation and Test Plan
-   Use the g1 harness to simulate: `Local Prompt (ID: local_user_*)` -> `Server Echo` -> `Server Stream`.
-   Verify that tool calls remain visible during the entire "turn-in-flight" period, even if a refresh occurs.
-   Manual test on Android: Verify no flickering or disappearance of "Thinking..." or tool UI during message arrival.
