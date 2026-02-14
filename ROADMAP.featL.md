# ROADMAP.featL - Compaction Boundary Collapse and Low-Cost Nested History

## Scope

- New task: On manual or automatic compaction, collapse everything before compaction.
- Keep visible only:
  - the compaction response item;
  - all content after compaction.
- Support consistent nested collapses inside collapsed history.
- Ensure collapsed elements consume minimal rendering and memory resources.

## Goal

Transform compaction into a clear conversation boundary that reduces cognitive load and prevents historical bubbles from degrading runtime performance.

## Research Notes

- Flutter long-list and lazy build fundamentals:
  - https://docs.flutter.dev/cookbook/lists/long-lists
  - https://api.flutter.dev/flutter/widgets/ListView-class.html
- Sliver lazy rendering for large timelines:
  - https://api.flutter.dev/flutter/widgets/SliverList-class.html
  - https://docs.flutter.dev/learn/tutorial/slivers
- Expand/collapse behavior and state lifecycle:
  - https://api.flutter.dev/flutter/material/ExpansionTile-class.html
- Visibility caveat (avoid keeping hidden subtrees alive when not needed):
  - https://api.flutter.dev/flutter/widgets/Visibility-class.html

## UX/Behavior Contract

1. Compaction event creates a `CompactionBoundary` marker in timeline state.
2. All messages before boundary are wrapped in one collapsed container by default.
3. Collapsed header shows compact metadata (for example: message count, interval, token estimate).
4. Compaction result message remains always visible immediately below boundary.
5. New messages after boundary render normally.
6. If user expands old history, nested tool/thinking collapses keep existing UI consistency.

## Technical Strategy

1. Add timeline node type `CollapsedHistoryGroup` with:
   - `startMessageId`, `endMessageId`, `messageCount`, `createdAt`, `compactionId`.
2. Build timeline with lazy delegates (`ListView.builder` or sliver builder) so collapsed groups do not instantiate full child trees.
3. Avoid `Visibility`/`Offstage` for large hidden history segments when possible; prefer not building subtree until expanded.
4. On expand action, load/build prior segment on demand and optionally page chunks for very long histories.
5. Keep expansion state local and resettable to prevent memory growth across navigation cycles.

## Performance Requirements

- Collapsed pre-compaction history should contribute near-zero additional frame cost.
- Initial timeline build time must improve for long sessions after compaction.
- Scrolling performance must remain stable after repeated compactions.

## Validation

- Unit tests for compaction boundary reducer and grouping logic.
- Widget tests to ensure only post-boundary items + compaction response are visible by default.
- Performance benchmark/profile test with large session histories and multiple compactions.
- Integration test covering manual and automatic compaction paths.

## Definition of Done

- Manual and automatic compaction both create the same visible boundary behavior.
- Older bubbles are collapsed by default with consistent nested collapse UX.
- Collapsed historical content is lazily built and low cost in render/memory terms.

## Delivery Notes

- [x] Added a compaction boundary timeline entry that collapses all pre-compaction messages by default.
- [x] Kept the compaction response and all post-compaction messages visible.
- [x] Added expand/collapse toggle with session-scoped reset so old history can be inspected on demand.
- [x] Added widget tests for default collapsed state, expand/re-collapse behavior, and expansion reset after session switch.
