---
feature: "featR g5 - Send, Stop, and Queue Parity"
group: "featR.g5"
dependency: "featR.g4"
status: "Completed"
---

# featR g5 - Send, Stop, and Queue Parity

## Objective
Align CodeWalk's send/stop behavior with official OpenCode semantics: preserve the convenience of sending while busy only when it matches server-authoritative queueing, while removing all client-invented queue lifecycle, local batching, and handoff hacks.

## Why This Group Exists
CodeWalk currently implements a complex local "send-while-busy" queue, including the ability to "Send now" (which batches newlines) and various abort-suppression mechanisms. These client-side inventions add significant state complexity and diverge from the server-authoritative model. By removing local queue orchestration and batching hacks while preserving real server-backed queueing, we reduce technical debt and align with the official OpenCode contract without losing the core convenience of the "send while busy" flow.

## Source of Truth / Baseline Hierarchy
1.  **Primary Authority**: ADR-023 and official OpenCode references (OpenCode Web/CLI).
2.  **Corroboration**: OpenCode Web (`packages/app/src/components/prompt-input/submit.ts`, `packages/app/src/pages/session/composer/session-composer-state.ts`).
3.  **Informative Only**: `BEHAVIOR.md` (Ignore references to local queueing hacks or "Send now").

## Dependencies / Execution Order
-   **Dependencies**: **featR.g4** (Delivered safe reconciliation baseline and ADR-023-compliant optimistic replay contract).
-   **Order**: Land this before g6 to clear the path for realtime lifecycle cleanup.

## In Scope
-   Removing local "Queued" timeline state placeholders and client-only queue orchestration.
-   Removing the "Send now" feature and all associated newline-draining/prompt-batching logic.
-   Mapping the "Stop" button directly to the official session abort contract (no local heuristics).
-   Simplifying the chat lifecycle so busy/idle/processing/queued UI comes directly from server events.
-   Preserving send-while-busy behavior ONLY if/when handled by the server's authoritative queue.

## Out of Scope
-   Changing the polling frequency (see g7).
-   Reworking the realtime event reducer (see g6).

## Primary CodeWalk File Targets
-   `lib/presentation/providers/chat_provider.dart`
-   `lib/presentation/pages/chat_page/chat_page_composer_widgets.dart`
-   `lib/presentation/widgets/chat_input/chat_input_send_controller.dart`
-   `lib/data/datasources/chat_remote_datasource.dart`

## Official OpenCode Reference Targets
-   `packages/app/src/components/prompt-input/submit.ts` (Verify how the server handles prompts sent while "busy").

## Detailed Implementation Plan
1.  **Remove Local Queue Orchestration**: Identify and remove all logic where the client invents its own "Queued" state or manages a local queue timeline.
2.  **Delete "Send now" and Batching**: Remove the `Send now` UI action and any logic that drains newlines or batches multiple prompts into a single local payload.
3.  **Map Stop to Server Abort**: Simplify the "Stop" action to call the official session abort endpoint directly. Do not locally discard queued work unless upstream behavior requires it.
4.  **Simplify Lifecycle to Server Events**: Drive the UI (busy, idle, processing, queued) using official server status transitions and events rather than custom client bookkeeping or handoff hacks.
5.  **Validate Server-Authoritative Queueing**: Ensure that if a prompt is accepted by the server while busy, its state in CodeWalk reflects the actual server-side pending/queued status.

## Guardrails / Anti-goals
-   **No Client-Side Invention**: The client must not invent lifecycle states that don't exist in the server contract.
-   **Fidelity over "Smartness"**: Discard any local "smart" batching or queueing hacks in favor of official contract parity.
-   **Strict ADR-023 Compliance**: Every behavior change must be verified against the official contract to prevent semantic drift.

## Acceptance Checklist / Definition of Done
- [x] Sending while busy follows official server-authoritative queue behavior.
- [x] Local "queued" placeholders and client-only queue orchestration are removed.
- [x] "Send now" is completely removed from the UI and logic.
- [x] Stop button reliably aborts only the active server-side task.
- [x] Chat lifecycle UI is driven by server events, not custom client bookkeeping.
- [x] `make check` passes.

## Validation and Test Plan
-   Regression coverage for send-while-busy, stop/abort, and queue visibility behavior.
-   Verify that sending multiple prompts follows the server's real queueing model without local state drift.
-   Manual test: Trigger a long generation, send a follow-up, and verify the UI correctly reflects the server-side queue status.

## Docs / ADR / CODEBASE Follow-up
-   Update `CODEBASE.md` to reflect the simplified send/lifecycle architecture.
-   Ensure any custom send-lifecycle documentation in `ADR.md` is updated or superseded.

## Mandatory `flow` Execution Block
1.  Implement the change;
2.  Run `make check`;
3.  Commit;
4.  Run reviewer for all code commits in the group;
5.  Fix accepted review findings and repeat reviewer until no accepted findings remain;
6.  Run `HEY_CAPTION="featR g5: server-authoritative send/stop/queue parity" make android`;
7.  Only then notify the user with the final report.

## Suggested HEY_CAPTION
"featR g5: Server-Authoritative Send, Stop, and Queue Parity"
