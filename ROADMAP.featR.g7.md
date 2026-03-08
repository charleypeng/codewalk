---
feature: "featR g7 - Ancillary Parity Cleanup and Final Convergence Sweep"
group: "featR.g7"
dependency: "featR.g1-g6"
status: "Completed"
---

# featR g7 - Ancillary Parity Cleanup and Final Convergence Sweep

## Objective
Finalize the convergence wave by fixing the remaining post-g6 chat regressions: idle viewport yanks, disappearing optimistic user turns, grouped tool-progress visibility, stale inactive session previews, and recoverable long-idle refresh failures.

## Why This Group Exists
This group started as a small cleanup bucket, but the real post-g6 repro sweep showed a final cluster of load-bearing regressions that crossed provider reconciliation, viewport policy, grouped tool-progress UI, and inactive snapshot freshness. The group therefore became the symptom-oriented convergence sweep for the remaining user-visible chat issues instead of a low-risk housekeeping pass.

## Source of Truth / Baseline Hierarchy
1.  **Primary Authority**: OpenCode Web (Final comparison).
2.  **Corroboration**: OpenCode CLI/TUI.
3.  **Informative Only**: `BEHAVIOR.md` (Update it if it contains stale CodeWalk-specific descriptions).

## Dependencies / Execution Order
-   **Dependencies**: **featR.g1 through g6**.
-   **Order**: MUST be the absolute final group.

## In Scope
-   Preserve optimistic user bubbles across refresh replay, including repeated same-text turns that arrive before canonical echo reconciliation settles.
-   Keep busy latest-user and tool-only turns visibly active while `message.part.updated` deltas settle locally.
-   Reduce safe rebuild churn in stable message widgets during background updates and typing.
-   Refresh inactive session snapshots from global session events so cross-device project previews stay fresh.
-   Keep recoverable current-session refresh failures scoped to the current chat surface instead of escalating to the old full-screen retry takeover.
-   Stop idle and status-only resume/route-return viewport yanks.
-   Keep collapsed grouped tool runs visibly active while work is still running or queued.

## Out of Scope
-   Introducing unrelated new product features outside the reported regressions.
-   Server/API contract changes or any ADR-023 exception.
-   Broad architecture rewrites beyond the proven symptom clusters.

## Primary CodeWalk File Targets
-   `lib/presentation/providers/chat_provider.dart`
-   `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
-   `lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart`
-   `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart`
-   `lib/presentation/pages/chat_page.dart`
-   `lib/presentation/pages/chat_page/chat_page_lifecycle.dart`
-   `lib/presentation/pages/chat_page/chat_page_runtime_support.dart`
-   `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart`
-   `lib/presentation/widgets/chat_message_widget.dart`
-   `lib/presentation/widgets/chat_message/chat_message_part_dispatch.dart`
-   `BEHAVIOR.md`

## Official OpenCode Reference Targets
-   `ai-docs/opencode_server.md`
-   `ai-docs/opencode_web.md`
-   `ai-docs/opencode_models.md`

## Delivered Steps
1.  `14d4c04` — preserve optimistic user turns across refresh replay.
2.  `aad66fa` — keep busy turns active while delta updates settle.
3.  `fa67fd8` — reduce stable message rebuild churn during background updates.
4.  `00d331b` — refresh inactive session snapshots from global events.
5.  `2b9460a` — keep recoverable refresh failures inside the current session.
6.  `6b9464f` — stop idle and status-only viewport yanks.
7.  `9db5d9e` — keep active tool work visible inside grouped messages.
8.  `2c5802c` — preserve repeated identical optimistic turns during refresh replay after review.

## Guardrails / Anti-goals
-   **ADR-023 First**: Keep `local_user_*`, no-`messageId` send semantics, and contract-first reconciliation intact.
-   **No Culprit Forcing**: Fix only the symptom clusters proven by tests, traces, or direct repro.
-   **Scoped Recovery**: Preserve visible session state whenever the current session can recover without a blocking reset.

## Acceptance Checklist / Definition of Done
-   [x] Idle/status-only jumps no longer yank the viewport during resume/return without new content.
-   [x] Optimistic user turns survive refresh replay and repeated same-text reconciliation cases.
-   [x] Busy tool-only and latest-user turns remain visibly active while local deltas settle.
-   [x] Inactive session previews/counts refresh from global events.
-   [x] Recoverable current-session refresh failures stay scoped to the session surface.
-   [x] Grouped tool work shows active collapsed progress while still running.
-   [x] `make check` passes.

## Validation and Test Plan
-   Focused provider regressions for optimistic reconciliation, busy-state semantics, delta merge behavior, inactive snapshot patching, and ambiguous same-text overlap.
-   Focused widget regressions for scoped recovery UI, idle resume/route-return stability, and grouped tool-progress visibility.
-   Full `make check` before each code checkpoint and again before the final review-fix commit.

## Docs / ADR / CODEBASE Follow-up
-   `ROADMAP.md` and `BEHAVIOR.md` updated to reflect the delivered chat behavior.
-   `ADR.md` unchanged because no architectural decision changed.
-   `CODEBASE.md` unchanged because the work did not alter structure or ownership boundaries.

## Mandatory `flow` Execution Block
1.  Implement the change;
2.  Run `make check`;
3.  Commit;
4.  Run reviewer for all code commits in the group;
5.  Fix accepted review findings and repeat reviewer until no accepted findings remain;
6.  Run `HEY_CAPTION="featR g7: final convergence sweep and cleanup" make android`;
7.  Only then notify the user with the final report.

## Suggested HEY_CAPTION
"featR g7: stabilize chat jumps, optimistic replay, and grouped tool progress"
