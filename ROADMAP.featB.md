# ROADMAP.featB - Realtime Read Flow and Session Rendering

## Scope

- Task 4: Group agents/subagents as sub-conversations (collapsible under parent chat).
- Task 5: Auto-scroll to latest when returning to chat unless user manually scrolled up.
- Task 7: Long conversation slowdown; adopt virtual scrolling strategy.
- Task 8: Remote abort should be soft toast with retry, not blocking full-screen error.

## Goal

Make realtime reading behavior resilient and calm: scalable list rendering, sensible auto-follow rules, and non-blocking error communication.

## Research Notes

- Flutter long list and lazy rendering guidance:
  - https://docs.flutter.dev/cookbook/lists/long-lists
  - https://docs.flutter.dev/perf/best-practices
- Sliver architecture for large dynamic feeds:
  - https://api.flutter.dev/flutter/widgets/CustomScrollView-class.html
  - https://api.flutter.dev/flutter/widgets/SliverList-class.html
- Scroll control and preserving user intent:
  - https://api.flutter.dev/flutter/widgets/ScrollController-class.html
  - https://api.flutter.dev/flutter/widgets/ScrollPosition-class.html
- Non-blocking transient feedback:
  - https://api.flutter.dev/flutter/material/SnackBar-class.html

## Implementation Plan

1. Convert message timeline to sliver-backed lazy list with stable message keys.
2. Track `isUserDetachedFromBottom` based on scroll delta threshold.
3. On app resume/view return:
   - if detached, keep position;
   - if attached, jump/animate to last message.
4. Model agent/subagent messages as hierarchical groups with collapsible children.
5. Replace full-screen abort error with 4s toast + retry action for non-fatal remote aborts.

## Backend/Contract Considerations

- Ensure event payload keeps parent-child relation metadata for subagents.
- Distinguish true errors from user-initiated abort in event codes.

## Validation

- Widget tests for auto-follow behavior after resume and route changes.
- Performance profile test with 5k+ messages and long thinking/tool streams.
- Integration test: abort from device A appears as soft toast on device B.

## Definition of Done

- Chat remains responsive with long histories.
- Auto-scroll respects explicit user scroll intent.
- Subagent interactions are grouped and collapsible.
- Abort UX is informative and lightweight.
