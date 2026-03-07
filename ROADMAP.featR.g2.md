---
feature: "featR g2 - Tool Call UI Stabilization and Parity"
group: "featR.g2"
dependency: "featR.g1"
status: "Delivered"
---

# featR g2 - Tool Call UI Stabilization and Parity

## Objective
Remove flicker and unstable expansion behavior in tool-call rendering while converging toward OpenCode Web semantics. Ensure tool-call blocks are closed by default and respect manual user state.

## Why This Group Exists
The current tool-call UI suffers from "jumping" or flickering when stream updates arrive. This happens because the widget tree often rebuilds and loses the expansion state, or because the logic tries to auto-expand/collapse during streaming. Stabilizing this is a prerequisite for a professional UX and aligns with the official client's "closed by default" philosophy.

## Source of Truth / Baseline Hierarchy
1.  **Primary Authority**: OpenCode Web (`packages/app/src/pages/session/message-timeline.tsx`).
2.  **Corroboration**: OpenCode CLI/TUI tool-call blocks.
3.  **Informative Only**: `BEHAVIOR.md` (Ignore if it suggests auto-expanding tool calls).

## Dependencies / Execution Order
-   **Dependencies**: **featR.g1** (Requires the regression harness to ensure no message parts are lost during UI refactor).
-   **Order**: Land this before g3 to ensure a stable foundation for more complex composer changes.

## In Scope
-   Stabilizing tool-call part identity to preserve `Expandable` state.
-   Enforcing "closed-by-default" for all tool-call blocks.
-   Disabling auto-expansion during `pending` or `running` statuses.
-   Ensuring manual user toggle (expand/collapse) is strictly preserved across stream chunks.
-   Eliminating visual flicker during incremental content updates.

## Out of Scope
-   Message ordering or reconciliation changes (see g4).
-   Reworking the "stop" button behavior (see g5).
-   Changes to the main composer.

## Primary CodeWalk File Targets
-   `lib/presentation/widgets/chat_message_widget.dart`
-   `lib/presentation/widgets/chat_message/chat_message_part_dispatch.dart`
-   `lib/presentation/widgets/chat_message/chat_message_tool_part.dart`

## Official OpenCode Reference Targets
-   `packages/app/src/pages/session/message-timeline.tsx` (Search for tool rendering logic).

## Detailed Implementation Plan
1.  **Audit Widget Identity**: Verify if `ChatMessageToolPart` uses a stable `Key` derived from the tool-call ID. If not, implement it to prevent state loss on rebuild.
2.  **Set Default State**: Modify the tool-call widget to initialize as collapsed.
3.  **Preserve Manual State**: Introduce a local state or provider-backed state that tracks manual user expansion, ensuring that incoming stream deltas do NOT overwrite this boolean.
4.  **No-Stream Auto-Toggle**: Explicitly remove any logic that automatically toggles expansion based on message status (e.g., don't open it just because it's "running").
5.  **Refine Content Updates**: Ensure that when the tool's `stdout` or `stderr` is updated via stream chunks, only the text sub-widget updates, preventing the entire tool block header from flickering.

## Guardrails / Anti-goals
-   **No Backward Compatibility**: If current CodeWalk code has a "workaround" to auto-open tools, delete it.
-   **Stability over Dynamicism**: If a choice exists between a "cool" auto-animation and a stable static block, choose the stable block.
-   **No Flicker**: The primary goal is 0px of unexpected layout shift.

## Acceptance Checklist / Definition of Done
-   [x] Tool calls are closed by default on app launch and session switch.
-   [x] Expanding a tool call manually stays expanded even as new messages arrive in the timeline.
-   [x] 0 flicker or layout shift during active tool-call streaming.
-   [x] `make check` passes.

## Validation and Test Plan
-   Use the g1 test harness to simulate a tool call receiving 10 incremental `stdout` chunks.
-   Verify (via widget test) that the expansion boolean remains `false` throughout the process.
-   Manual verification on Android/Desktop to confirm "smoothness".

## Docs / ADR / CODEBASE Follow-up
-   Update `CODEBASE.md` if tool-call state management was moved to a more central location.

## Mandatory `flow` Execution Block
1.  Implement the change;
2.  Run `make check`;
3.  Commit;
4.  Run reviewer for all code commits in the group;
5.  Fix accepted review findings and repeat reviewer until no accepted findings remain;
6.  Run `HEY_CAPTION="featR g2: tool-call UI stabilization" make android`;
7.  Only then notify the user with the final report.

## Suggested HEY_CAPTION
"featR g2: Tool Call UI Stabilization and Parity"
