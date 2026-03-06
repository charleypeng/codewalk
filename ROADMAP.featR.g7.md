---
feature: "featR g7 - Ancillary Parity Cleanup and Final Convergence Sweep"
group: "featR.g7"
dependency: "featR.g1-g6"
status: "Pending"
---

# featR g7 - Ancillary Parity Cleanup and Final Convergence Sweep

## Objective
Finalize the convergence wave by cleaning up minor drifts, removing all dead code/stale comments from the transition, and updating project documentation to reflect the new aligned state.

## Why This Group Exists
This is the "housekeeping" group that ensures no technical debt remains from the featR transition. It closes the loop on low-priority drifts and explicitly validates that items we *chose* not to change (like polling frequency) remain correct. It also ensures that a future developer reading the code won't be confused by stale comments referencing "local queueing" or other removed features.

## Source of Truth / Baseline Hierarchy
1.  **Primary Authority**: OpenCode Web (Final comparison).
2.  **Corroboration**: OpenCode CLI/TUI.
3.  **Informative Only**: `BEHAVIOR.md` (Update it if it contains stale CodeWalk-specific descriptions).

## Dependencies / Execution Order
-   **Dependencies**: **featR.g1 through g6**.
-   **Order**: MUST be the absolute final group.

## In Scope
-   A final audit of minor UI drifts (status icons, retry button placement, etc.).
-   Removing all remaining "workaround" code, stale comments (`// TODO: convergence`, etc.), and obsolete feature flags.
-   Explicitly validating that `10s` health polling is correct/aligned.
-   Updating `ADR.md` and `CODEBASE.md` to remove any mention of the removed architectures (queueing, heuristic reconciliation).
-   Deleting unused settings or flags introduced for the transition.

## Out of Scope
-   Introducing any new features or product behavior.
-   Fundamental architectural changes.

## Primary CodeWalk File Targets
-   Any file touched in g1-g6 that still contains "transition" notes.
-   `lib/presentation/providers/app_provider.dart`
-   `ADR.md`
-   `CODEBASE.md`
-   `BEHAVIOR.md`

## Official OpenCode Reference Targets
-   OpenCode Web (Global final check).

## Detailed Implementation Plan
1.  **Gap Audit**: Perform a final side-by-side check of CodeWalk vs OpenCode Web for minor visual or behavioral inconsistencies. Fix any remaining low-risk items.
2.  **Stale Comment Sweep**: Run a codebase-wide `grep` for "workaround", "local", "convergence", "parity", and "featR". Delete or update comments to reflect the new permanent reality.
3.  **Confirm Alignment Items**: Explicitly check the `10s` polling interval. If it matches the server's expected health check frequency, document it as "Aligned - Do Not Change".
4.  **Documentation Sync**: Delegate to `adrkeeper` and `codemapper` to update their respective files, ensuring all architectural descriptions match the post-convergence state.
5.  **Final Cleanup**: Delete any dead code (methods, classes, constants) that were left orphaned by the removal of the send queue or heuristic reconciliation.

## Guardrails / Anti-goals
-   **No "Golden Hammer"**: Do not change things that are already aligned just for the sake of "cleaning".
-   **Deletion Preference**: If a comment or flag is questionable, DELETE IT.
-   **Docs Integrity**: Ensure `ADR.md` and `CODEBASE.md` are 100% accurate before finishing.

## Acceptance Checklist / Definition of Done
-   [ ] All major and minor parity gaps identified in the featR plan are closed.
-   [ ] Codebase is free of stale transition comments and feature flags.
-   [ ] `ADR.md` and `CODEBASE.md` are fully updated and accurate.
-   [ ] `make check` passes.

## Validation and Test Plan
-   Final full manual pass of the app on Android and Desktop.
-   Final run of the g1 test harness to ensure zero regressions after cleanup.

## Docs / ADR / CODEBASE Follow-up
-   This group *is* the follow-up. Ensure all docs are synchronized.

## Mandatory `flow` Execution Block
1.  Implement the change;
2.  Run `make check`;
3.  Commit;
4.  Run reviewer for all code commits in the group;
5.  Fix accepted review findings and repeat reviewer until no accepted findings remain;
6.  Run `HEY_CAPTION="featR g7: final convergence sweep and cleanup" make android`;
7.  Only then notify the user with the final report.

## Suggested HEY_CAPTION
"featR g7: Final Convergence Sweep and Cleanup"
