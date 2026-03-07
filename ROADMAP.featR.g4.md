---
feature: "featR g4 - Optimistic Message IDs and Reconciliation"
group: "featR.g4"
dependency: "featR.g1"
status: "Pending"
---

# featR g4 - Optimistic Message IDs and Reconciliation

## Objective
Align optimistic send IDs and message reconciliation logic with the official OpenCode/Web contract. Eliminate local heuristics like `local_user_*` in favor of official `messageId` handling.

## Why This Group Exists
CodeWalk currently uses custom prefixes and signature-based heuristics to match a local user bubble with the subsequent server echo. This is brittle and diverges from the official contract. By adopting the official `messageId` path, we ensure that reconciliation is deterministic, eliminating duplicated messages or "lost" user prompts during rapid-send scenarios. This is a critical prerequisite for simplifying the send queue in g5.

## Source of Truth / Baseline Hierarchy
1.  **Primary Authority**: OpenCode Web (`packages/app/src/components/prompt-input/submit.ts`, `packages/app/src/context/sync.tsx`).
2.  **Corroboration**: OpenCode CLI/TUI sync logic.
3.  **Informative Only**: `BEHAVIOR.md` (Discard any "local-only" ID generation advice if it conflicts with official `messageId` usage).

## Dependencies / Execution Order
-   **Dependencies**: **featR.g1** (Absolute reliance on the regression harness for merge logic).
-   **Order**: MUST land before g5 and g6. Reconciliation stability is the foundation for lifecycle cleanup.

## In Scope
-   Transitioning the `prompt_async` (or equivalent) payload to use official-style `messageId`.
-   Updating `ChatProvider` merge logic to prioritize ID-based reconciliation over content-based heuristics.
-   Ensuring that server echoes cleanly replace optimistic local bubbles.
-   Explicitly defining chronological ordering and merge rules in the reducer.
-   Deleting obsolete `local_user_*` prefix hacks and signature-based matching.

## Out of Scope
-   Removing the local send queue (see g5).
-   Changing how SSE streams are opened.

## Primary CodeWalk File Targets
-   `lib/presentation/providers/chat_provider.dart`
-   `lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart`
-   `lib/data/datasources/chat_remote_datasource.dart`

## Official OpenCode Reference Targets
-   `packages/app/src/context/sync.tsx` (Search for message reconciliation/merge logic).
-   `packages/app/src/components/prompt-input/submit.ts` (Check how the initial message ID is generated and sent).

## Detailed Implementation Plan
1.  **ID Audit**: Trace how a message ID is currently generated in CodeWalk. Compare this to the official `uuid()` or counter-based approach in OpenCode Web.
2.  **Contract Alignment**: Modify the outgoing prompt payload to include the `messageId` in the exact format the official server expects for optimistic tracking.
3.  **Reducer Rework**: Refactor `chat_provider_message_merge_ops.dart` to use a Map-like lookup for `messageId` during reconciliation. If a server message arrives with a matching `messageId`, it MUST replace the optimistic one, not append to it.
4.  **Deterministic Ordering**: Implement a strict sort by `createdAt` or server-provided sequence index to ensure the timeline never "jumps" during high-latency reconciliation.
5.  **Heuristic Deletion**: Once ID-based merging is verified, delete all code that checks for "local_user_" or performs fuzzy string matching to reconcile messages.

## Guardrails / Anti-goals
-   **No Dual Paths**: Do not keep the old heuristic as a "fallback". If the ID-based path fails, fix the ID generation, don't fall back to fuzzy matching.
-   **No Stale Workarounds**: The future agent must not preserve any "signature-based" matching just because it exists today.
-   **Fidelity First**: If the official contract requires a specific ID format (e.g., client-generated UUID), use it exactly.

## Acceptance Checklist / Definition of Done
-   [ ] Messages are reconciled via `messageId` only.
-   [ ] Rapid-fire sending does not result in duplicated bubbles.
-   [ ] `local_user_*` logic is completely removed from the codebase.
-   [ ] `make check` (with g1 replay tests) passes 100%.

## Validation and Test Plan
-   Use the g1 harness to simulate: `Local Prompt (ID: A)` -> `Server Echo (ID: A)` -> `Server Stream (ID: A)`.
-   Verify that at the end, exactly ONE message with content from the stream exists in the timeline.
-   Manual test on Android: Spam the send button with 3 prompts; verify no duplicates appear when echoes return.

## Docs / ADR / CODEBASE Follow-up
-   Update `CODEBASE.md` to reflect the new ID-based reconciliation flow.
-   Create/Update `ADR` if this changes the core message model.

## Mandatory `flow` Execution Block
1.  Implement the change;
2.  Run `make check`;
3.  Commit;
4.  Run reviewer for all code commits in the group;
5.  Fix accepted review findings and repeat reviewer until no accepted findings remain;
6.  Run `HEY_CAPTION="featR g4: optimistic message reconciliation parity" make android`;
7.  Only then notify the user with the final report.

## Suggested HEY_CAPTION
"featR g4: Optimistic Message IDs and Reconciliation"
