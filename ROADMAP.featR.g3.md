---
feature: "featR g3 - Child Thread Composer Parity"
group: "featR.g3"
dependency: "featR.g1 (g2 preferred)"
status: "Pending"
---

# featR g3 - Child Thread Composer Parity

## Objective
Enable the full chat composer in child/sub-conversation sessions, removing the "view-only" restriction to match OpenCode Web capabilities.

## Why This Group Exists
CodeWalk currently treats sub-conversations (threads) as read-only views. However, the official OpenCode Web client allows users to fully interact with these threads, including sending prompts, using slash commands, and attaching files. This group removes an artificial product divergence that limits the app's power.

## Source of Truth / Baseline Hierarchy
1.  **Primary Authority**: OpenCode Web (`packages/app/src/pages/session/composer/session-composer-region.tsx`).
2.  **Corroboration**: OpenCode CLI/TUI sub-thread behavior.
3.  **Informative Only**: `BEHAVIOR.md` (Ignore if it describes sub-threads as "view-only").

## Dependencies / Execution Order
-   **Dependencies**: **featR.g1**.
-   **Order**: Completing g2 first is preferred to ensure that if a thread contains tool calls, the UI is already stable.

## In Scope
-   Removing the conditional check that hides/disables the composer in sub-sessions.
-   Rendering the full `ChatInputWidget` within child session views.
-   Ensuring slash commands (`/`), attachments (`@`), and voice input target the *active* child session ID.
-   Verifying that sending a message in a child thread correctly triggers the "busy" state for that thread.
-   Ensuring the "Back" navigation from a child thread to the parent is preserved and functional.

## Out of Scope
-   Changes to the server-side thread creation logic.
-   Refactoring the main send queue (see g5).

## Primary CodeWalk File Targets
-   `lib/presentation/pages/chat_page/chat_page_composer_widgets.dart`
-   `lib/presentation/widgets/chat_input_widget.dart`
-   `lib/presentation/providers/chat_provider.dart`

## Official OpenCode Reference Targets
-   `packages/app/src/pages/session/message-timeline.tsx` (Check how sub-sessions are rendered and if they contain a composer).

## Detailed Implementation Plan
1.  **Locate "View-Only" Guards**: Search `ChatPage` and `ChatProvider` for logic that disables the composer when `activeSessionId != rootSessionId`.
2.  **Enable Component Injection**: Ensure the composer widget is injected into the child thread view.
3.  **Targeting Verification**: In `ChatProvider`, ensure the `sendPrompt` (or equivalent) method uses the `currentSessionId` (which might be the child) instead of hardcoding the root ID.
4.  **UI Feedback**: Ensure that when a message is sent in a child thread, the "thinking" indicator appears correctly for that thread.
5.  **Navigation Check**: Verify that using the composer doesn't break the ability to swipe back or click the "back" arrow to return to the parent session.

## Guardrails / Anti-goals
-   **No Root Leakage**: A message sent in a child thread must NOT appear in the parent thread unless the server explicitly echoes it there.
-   **Preserve Navigation**: Do not remove the back button or navigation history when opening the composer.
-   **No Lifecycle Hacks**: Avoid adding temporary "wait for thread" hacks; rely on the existing provider lifecycle.

## Acceptance Checklist / Definition of Done
-   [ ] Opening a sub-conversation shows the full chat input bar.
-   [ ] Sending a prompt in a sub-conversation works and receives a stream.
-   [ ] Attachments and voice input work correctly in the sub-conversation.
-   [ ] Navigating back to the parent session works after sending a message in a child session.

## Validation and Test Plan
-   Manual test: Open a thread, send "/help", verify the response appears *inside* the thread.
-   Manual test: Navigate back to parent, verify parent timeline is unchanged.
-   Regression: Verify main session composer still works as expected.

## Docs / ADR / CODEBASE Follow-up
-   Update `CODEBASE.md` to note that the composer is now session-agnostic.

## Mandatory `flow` Execution Block
1.  Implement the change;
2.  Run `make check`;
3.  Commit;
4.  Run reviewer for all code commits in the group;
5.  Fix accepted review findings and repeat reviewer until no accepted findings remain;
6.  Run `HEY_CAPTION="featR g3: child thread composer parity" make android`;
7.  Only then notify the user with the final report.

## Suggested HEY_CAPTION
"featR g3: Child Thread Composer Parity"
