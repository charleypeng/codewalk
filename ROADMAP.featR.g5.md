---
feature: "featR g5 - Send, Stop, and Queue Parity"
group: "featR.g5"
dependency: "featR.g4"
status: "Pending"
---

# featR g5 - Send, Stop, and Queue Parity

## Objective
Simplify the send lifecycle by removing custom CodeWalk queueing, "Send now" batching, and abort-suppression hacks. Align directly with the official OpenCode Web send/stop contract.

## Why This Group Exists
CodeWalk currently implements a complex "send-while-busy" queue, including the ability to "Send now" (which batches newlines) and various abort-suppression mechanisms. These are local product divergences that add significant state complexity. The official OpenCode Web client uses a much simpler "single active request" or "server-side handled concurrency" model. Removing these local workarounds reduces technical debt and eliminates a major category of "stuck state" bugs.

## Source of Truth / Baseline Hierarchy
1.  **Primary Authority**: OpenCode Web (`packages/app/src/components/prompt-input/submit.ts`, `packages/app/src/pages/session/composer/session-composer-state.ts`).
2.  **Corroboration**: OpenCode CLI TUI component behavior.
3.  **Informative Only**: `BEHAVIOR.md` (Ignore references to "local queueing" or "Send now").

## Dependencies / Execution Order
-   **Dependencies**: **featR.g4** (Stable ID-based reconciliation makes it safe to remove the local queue).
-   **Order**: Land this before g6 to clear the path for realtime lifecycle cleanup.

## In Scope
-   Removing the local `Queued` timeline state and UI indicators.
-   Removing the "Send now" feature and its newline-batching logic.
-   Simplifying the "Stop" button to directly call the server's abort/stop endpoint for the session.
-   Removing abort-suppression "handoff" logic.
-   Aligning the "busy" state with the server's actual session status.

## Out of Scope
-   Changing the polling frequency (see g7).
-   Reworking the realtime event reducer (see g6).

## Primary CodeWalk File Targets
-   `lib/presentation/providers/chat_provider.dart`
-   `lib/presentation/pages/chat_page/chat_page_composer_widgets.dart`
-   `lib/presentation/widgets/chat_input/chat_input_send_controller.dart`
-   `lib/data/datasources/chat_remote_datasource.dart`

## Official OpenCode Reference Targets
-   `packages/app/src/components/prompt-input/submit.ts` (Check what happens when a user sends while the app is already "processing").

## Detailed Implementation Plan
1.  **Deconstruct Local Queue**: Identify all places where `timeline.add(QueuedMessage)` is called. Replace this with a direct "Send or Error" flow that matches the official client.
2.  **Retire "Send now"**: Delete the `Send now` UI action and the associated newline-draining logic in the send controller.
3.  **Abort Contract Alignment**: Map the UI "Stop" action to a clean session-abort call. Remove any local "wait for abort before sending next" heuristics if they aren't source-justified.
4.  **Simplify Lifecycle State**: In `ChatProvider`, reduce the lifecycle to a simple `idle -> sending -> processing -> idle` state machine, leaning on server echoes to drive the timeline rather than local state-keeping.
5.  **Remove Batching**: Delete any logic that tries to combine multiple pending prompts into a single payload.

## Guardrails / Anti-goals
-   **No Backward Compatibility**: Do not keep the old queue "just in case". It is a source of bugs and MUST be deleted.
-   **Delete, Don't Flag**: Favor deleting the code over wrapping it in feature flags.
-   **Fidelity over "Smartness"**: If CodeWalk's current queueing was meant to be "smarter" than the web client, discard that smartness in favor of parity.

## Acceptance Checklist / Definition of Done
-   [ ] No "Queued" messages appear in the timeline; sending while busy either errors or follows official server behavior.
-   [ ] "Send now" is completely removed from the UI and logic.
-   [ ] Stop button reliably terminates the current server-side task.
-   [ ] `make check` passes.

## Validation and Test Plan
-   Use g1 tests to verify that sending multiple prompts follows the new simplified flow without state deadlock.
-   Manual test: Click "Stop" during a long generation; verify the stream terminates and the composer re-enables.

## Docs / ADR / CODEBASE Follow-up
-   Update `CODEBASE.md` to reflect the removal of the queueing module.
-   Update `ADR` if the send lifecycle was previously documented as a custom architecture.

## Mandatory `flow` Execution Block
1.  Implement the change;
2.  Run `make check`;
3.  Commit;
4.  Run reviewer for all code commits in the group;
5.  Fix accepted review findings and repeat reviewer until no accepted findings remain;
6.  Run `HEY_CAPTION="featR g5: simplified send/stop queue parity" make android`;
7.  Only then notify the user with the final report.

## Suggested HEY_CAPTION
"featR g5: Send, Stop, and Queue Parity"
