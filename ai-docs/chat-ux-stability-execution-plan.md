# Chat UX Stability and Motion Plan

## 1) Executive summary

This document defines a full execution plan to stabilize chat UX after recent fixes, eliminate returning regressions, and add polished message entrance motion without harming performance.

Primary goals:

1. Mobile session switching must feel instant and predictable:
   - close drawer immediately after tap,
   - show loading until conversation messages are ready,
   - avoid "frozen drawer" while large sessions hydrate.
2. Ensure final assistant response is always rendered when it arrives (no need to switch sessions to see it).
3. Preserve recently fixed behavior:
   - final assistant response is revealed from message start,
   - reveal alignment remains slightly upper-centered (not bottom-pinned),
   - auto-follow behavior remains correct:
     - if user is at bottom, keep following,
     - if user is reading history, show unread/jump affordance only.
4. Preserve per-session collapsed state for history/tool work groups and tool chains.
5. Add smooth, subtle entrance animations:
   - tool and assistant bubbles: gentle fade + lift,
   - user bubble: fast, elegant "from composer" launch.

This plan is intentionally deterministic and test-first to prevent additional regressions.

---

## 2) Current issues and why they happen

### A) Session switch on mobile closes late for large chats

Observed symptom:
- user taps session in drawer,
- large conversation loading starts,
- drawer remains open for too long,
- perceived lag and blocked workflow.

Likely reason:
- UI transition (drawer close) is coupled to async data load path.
- Non-critical load work may be in the same await chain as critical message hydration.

Needed behavior:
- close drawer first (immediate visual acknowledgment),
- then show loading overlay while content hydrates.

### B) Final assistant response occasionally exists but does not appear until session switch

Observed symptom:
- completion/notification event happens,
- response is already available in backend state,
- current view fails to paint final message reliably,
- switching sessions and returning forces refresh and message appears.

Likely reason:
- race between realtime event ordering (`message.updated`, `session.idle`, stream finalization) and local merge/render lifecycle.
- occasionally timeline does not re-enter a reveal/render path for final content.

Needed behavior:
- deterministic one-shot reconcile when terminal event arrives but final visible content is missing.

### C) Collapsed state memory consistency

Observed symptom:
- users want already collapsed groups to remain collapsed when returning.

Likely reason:
- collapse/expand state can be local-to-widget or reset on session switch.

Needed behavior:
- store UI collapse state per session and rehydrate on return.

### D) Motion polish and no-regression requirement

Observed requirement:
- add elegant motion but do not re-break scroll/follow/final reveal guarantees.

Needed behavior:
- one-shot lightweight animations only for newly added tail items.
- no animation replay on rebuild of existing history.

---

## 3) Non-negotiable behavior contract

These rules are locked and must remain true after implementation.

1. Final response reveal rule
   - When assistant final response becomes available and user is not reading history,
     reveal from start of final message,
     alignment slightly upper-centered (`~0.2`).
2. Follow rule
   - If user is at bottom: keep auto-follow during streaming/tool processing.
   - If user scrolls up: do not force snap; show jump/unread affordance.
3. Post-send invalidation rule
   - Any pending reveal from previous assistant completion is invalidated when user sends a new message.
4. Session switch mobile rule
   - Drawer closes immediately on session tap,
   - loading indicator shown until message hydration completes.
5. Collapse persistence rule
   - previously collapsed groups remain collapsed when user returns to that session.

---

## 4) State model (source of truth)

### 4.1 Session switch state

`idle -> switching(sessionId) -> ready(sessionId)`

Data fields in page state:
- `bool _isSessionSwitchLoading`
- `String? _sessionSwitchTargetId`

Rules:
- Enter `switching` immediately after tap (after drawer close intent).
- Exit `switching` only when message hydration for selected session resolves.
- Ignore duplicated taps while already switching.

### 4.2 Response viewport state

Keep existing lifecycle with explicit intent guards:
- `streaming`
- `finalizing`
- `settled`

Additional invariant:
- `reveal intent` only applies to current completion cycle and is cleared by new user send.

### 4.3 Per-session UI cache state

Cache key:
- `sessionId`

Cached values:
- expanded/collapsed history group id
- expanded/collapsed assistant work group id
- tool-chain expanded states by stable chain key

Rules:
- restore on session activation,
- prune invalid keys when timeline shape changes.

---

## 5) Detailed workstreams

## Workstream 1: Mobile session switch responsiveness

### Why
Immediate feedback on tap is critical on mobile. Waiting for load before closing drawer feels broken.

### What to change

1. In session selection handler:
   - close drawer immediately,
   - then set switching/loading state,
   - then await `selectSession`.
2. Show overlay while switching:
   - block interactions,
   - keep visual continuity,
   - include stable test key.
3. Ensure only conversation message hydration is blocking criterion.
   - move session insights/background extras out of critical path.

### Candidate files
- `lib/presentation/pages/chat_page.dart`
- `lib/presentation/pages/chat_page/chat_page_scaffold.dart`
- `lib/presentation/pages/chat_page/chat_page_chrome.dart`
- `lib/presentation/providers/chat_provider.dart`

### Risks
- race with existing route transitions.
- accidental duplicate selections.

### Mitigation
- re-entry guard + `finally` cleanup.

---

## Workstream 2: Collapse-state persistence and cache validation

### Why
Users expect conversation organization choices to persist per session.

### What to change

1. Add per-session UI cache map in page state.
2. On expand/collapse toggles, update map.
3. On session switch, restore map values for target session.
4. Add pruning step in timeline rebuild:
   - remove cache keys for groups/chains no longer present.

### Candidate files
- `lib/presentation/pages/chat_page.dart`
- `lib/presentation/pages/chat_page/chat_page_runtime_support.dart`
- `lib/presentation/pages/chat_page/chat_page_timeline_runtime.dart`
- `lib/presentation/widgets/chat_message_widget.dart`
- `lib/presentation/widgets/chat_message/chat_message_part_dispatch.dart`

### Risks
- stale ids causing impossible expanded states.

### Mitigation
- strict prune each timeline recompute.

---

## Workstream 3: Final assistant visibility deterministic reconcile

### Why
Event order can be nondeterministic. We need a guaranteed fallback when final visible content is missing despite completion.

### What to change

1. Add guarded reconcile trigger after terminal events for current session:
   - `session.idle`, stream completion, or completion-like transitions.
2. Reconcile only if final visible content is missing/incomplete:
   - latest assistant has no visible text,
   - tool-only terminal surface without final text,
   - incomplete message left at idle.
3. Use one-shot token + debounce + generation guard:
   - prevent loops,
   - ignore stale responses.

### Candidate files
- `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart`
- `lib/presentation/providers/chat_provider.dart`

### Risks
- reconcile loops,
- stale overwrite.

### Mitigation
- one-shot per turn/session, explicit cooldown and guard checks.

---

## Workstream 4: Motion design for new bubbles

### Why
New motion should improve perceived quality and readability without introducing jank.

### Motion profiles

1. User bubble (`from composer`)
   - Duration: very short (`~120-160ms`)
   - Curve: ease-out
   - Motion: small upward translation + subtle scale in (`0.98 -> 1.0`) + fade (`0 -> 1`)
   - Visual intent: feels launched from composer.

2. Assistant final and tool bubbles
   - Duration: short (`~140-200ms`)
   - Curve: ease-out-cubic
   - Motion: gentle fade + slight lift (`6-10px`) no scale pop.
   - Visual intent: calm and readable.

### Performance constraints
- Animate only newly inserted tail entries.
- Never replay animations for historical preload or rebuild-only updates.
- Avoid per-frame expensive layout operations.

### Candidate files
- `lib/presentation/widgets/message_entrance_animation.dart`
- `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart`
- `lib/presentation/theme/app_animations.dart` (or equivalent tokens)

### Risks
- animation replay on rebuild,
- scroll jitter in long lists.

### Mitigation
- one-shot animation ledger keyed by stable message identity.

---

## Workstream 5: Regression lock for current guarantees

### Why
Recent fixes are valuable and must remain untouched.

### Locked guarantees to preserve

1. Final reveal starts at beginning of final assistant text.
2. Reveal alignment remains around upper-center (`~0.2`).
3. Auto-follow remains active when at bottom.
4. History reading mode does not force snaps; only indicators appear.
5. Sending a new user message invalidates previous completion reveal intent.

### Candidate files
- `lib/presentation/pages/chat_page/chat_page_runtime_support.dart`
- `lib/presentation/pages/chat_page/chat_page_scroll_coordinator.dart`

---

## 6) File-level change matrix

## Core page and lifecycle
- `lib/presentation/pages/chat_page.dart`
  - add switch-loading state fields
  - add per-session collapse cache container
  - add animation gate bookkeeping for new entries

- `lib/presentation/pages/chat_page/chat_page_chrome.dart`
  - session select flow: close drawer first, then start async switch

- `lib/presentation/pages/chat_page/chat_page_scaffold.dart`
  - overlay host integration for switch loading

- `lib/presentation/pages/chat_page/chat_page_runtime_support.dart`
  - restore/persist session-scoped collapse state
  - preserve reveal/follow invariants

- `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart`
  - apply role-specific entrance animation wrappers
  - ensure final reveal anchor remains stable

## Provider and reconciliation
- `lib/presentation/providers/chat_provider.dart`
  - split critical message hydration vs non-critical extras
  - refine queue/retry interaction with session switch lifecycle

- `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
  - deterministic final-content reconcile trigger

- `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart`
  - keep render/update sequencing consistent with reconcile path

## Message widget and part rendering
- `lib/presentation/widgets/chat_message_widget.dart`
- `lib/presentation/widgets/chat_message/chat_message_part_dispatch.dart`
  - externalize tool-chain expanded state read/write hooks

## Animation utilities
- `lib/presentation/widgets/message_entrance_animation.dart`
- `lib/presentation/theme/app_animations.dart`
  - define profiles and tune durations/curves

---

## 7) Test plan (mandatory)

## Unit tests

1. Session switch readiness semantics
   - `selectSession` resolves after messages, not blocked by non-critical insights.
2. Final reconcile one-shot
   - on idle with missing visible final text, reconcile runs once and fills final message.
3. No reconcile loop
   - repeated idle events do not trigger infinite refresh.

## Widget tests

1. Mobile drawer close immediate
   - tap session in drawer -> drawer closes before large session completes.
2. Session loading overlay lifecycle
   - overlay appears during switch and disappears when messages are ready.
3. Collapse persistence per session
   - collapse history/work/tool chain -> switch away/back -> state preserved.
4. Final reveal placement
   - when final message completes while at bottom, viewport shows start of message near upper-center.
5. Follow behavior
   - at bottom: auto-follow remains.
   - reading history: no forced snap, jump affordance visible.
6. New bubble animation smoke
   - user bubble uses composer-launch profile.
   - assistant/tool bubbles use gentle profile.
   - historical preloaded entries do not animate again.

## Manual QA checklist

1. Large session switch on mobile
   - expected: drawer closes instantly, overlay appears, no blank freeze.
2. Final message hidden regression repro path
   - expected: final message appears without needing session switch.
3. History reading behavior
   - expected: unread indicator only, no forced jump.
4. Short final response
   - expected: no unnecessary jump FAB if already at bottom.
5. Immediate follow-up user send
   - expected: no jump back to prior final response start.

---

## 8) Rollout and safety strategy

Use feature flags for safe progressive enablement:

1. `chatSessionSwitchOverlayV1`
2. `chatFinalReconcileV1`
3. `chatBubbleMotionV1`
4. `chatSessionUiStateCacheV1`

Recommended rollout order:

1. Enable switch overlay + critical path split.
2. Enable final reconcile.
3. Enable session-scoped collapse cache.
4. Enable bubble motion.

At each phase:
- run `make check`,
- run focused widget/provider tests,
- run mobile manual checklist.

Rollback policy:
- if any critical regression appears, disable most recent flag and keep previous stable set.

---

## 9) Implementation order (execution sequence)

Phase 1 - Session switch responsiveness
1. drawer-first close behavior
2. loading overlay
3. decouple non-critical loads
4. tests for switch flow

Phase 2 - Final response visibility hardening
1. one-shot reconcile path
2. guard/debounce/generation protections
3. provider tests + race scenarios

Phase 3 - Session-scoped UI state persistence
1. group/tool-chain cache model
2. restore + prune logic
3. switch-away/switch-back tests

Phase 4 - Bubble motion polish
1. profile definitions
2. one-shot animation gating
3. visual tuning + performance validation

Phase 5 - Regression lock and final QA
1. run full `make check`
2. run manual checklist on mobile
3. verify no drift in final reveal, follow, and unread rules

---

## 10) Commands and verification routine

Required routine per phase:

1. Focused tests first.
2. `make check`.
3. If mobile-verifiable change, build APK:
   - `HEY_CAPTION="<phase-specific summary>" make android`

Suggested focused commands:

```bash
flutter test --no-pub test/widget/chat_page_test.dart
flutter test --no-pub test/unit/providers/chat_provider_realtime_test.dart
flutter test --no-pub test/unit/providers/chat_provider_session_ops_test.dart
```

---

## 11) Acceptance criteria mapped to user request

1. Session switch with large chat
   - Drawer closes immediately on tap.
   - Loading indicator shown until conversation messages fully render.
   - No delayed drawer hide.

2. Cache and collapsed state
   - Previously collapsed groups remain collapsed when returning.
   - No stale/invalid collapse entries after timeline changes.

3. Final response visibility
   - Final assistant response appears in current session without navigation workaround.
   - No intermittent "arrived but not shown" behavior.

4. Motion polish
   - Tools and assistant finals enter smoothly.
   - User bubble appears as if launched from composer.
   - Motion remains subtle, fast, and stable.

5. No regression from recent fixes
   - Final response shown from beginning and slightly upper-centered.
   - Auto-follow/unread behavior remains correct.
   - No reintroduction of previous scroll/FAB regressions.

---

## 12) Risks and fallback decisions

Risk: reconcile causes extra refresh traffic
- Fallback: increase debounce and only reconcile on specific terminal signatures.

Risk: per-session UI cache grows too much
- Fallback: prune aggressively on session eviction and invalid ids.

Risk: motion causes subtle jank on low-end devices
- Fallback: reduce duration and disable scale component; keep fade+lift only.

Risk: overlay conflicts with existing project loading overlays
- Fallback: explicit z-order and mutual exclusion policy.

---

## 13) Definition of done

Done means all are true:

1. All acceptance criteria in section 11 pass.
2. `make check` passes.
3. Mobile manual checklist passes.
4. No new regressions in known sensitive areas:
   - final reveal,
   - follow/unread,
   - FAB visibility,
   - draft restore and queued retry behavior.
5. Behavior docs remain consistent with shipped behavior.

---

## 14) Notes for implementation discipline

1. Keep each phase as an atomic commit group.
2. Add tests in the same phase as behavior change.
3. Avoid broad refactors during hotfix-like stabilization work.
4. Prefer deterministic state transitions over implicit timing assumptions.

This plan is designed to maximize UX correctness first, then visual polish, while preserving all recently recovered behavior.
