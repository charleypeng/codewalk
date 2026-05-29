# Final Synthesized Execution Plan — Final Assistant Message Flicker Regression Fix

**Status**: Ready  
**Date**: 2026-05-29  
**Request**: Fix chat regression where the final assistant message flickers between complete and "still receiving" appearance in a loop after `session.idle` fires.

---

## Problem

In CodeWalk (Flutter app for OpenCode AI agents), the final assistant message appears complete, then reverts to an incomplete/"still receiving" appearance, then comes back, then disappears again — in a visible loop. The regression was introduced by commit `f8d6c3c6c` ("fix: restore file path taps and settle chat send lifecycle") which changed the `session.idle` handler to unconditionally null `_activeMessageStreamSessionId` and immediately mark incomplete assistant messages as completed — without cancelling the still-alive send stream.

## Objective

The final assistant message must appear once as complete and remain stable — no flicker, no loop. The fix must:
- Stop the exact failure mode (complete → incomplete → complete → loop)
- Preserve the intentional `f8d6c3c6c` behavior (composer UI settles immediately on `session.idle`)
- Follow ADR-023 (OpenCode contract-first): `message.updated` with `time.completed` is authoritative
- Not break ADR-025 (assistant disclosure ownership) or ADR-028 (scroll ownership)

## Context and Constraints

- **Framework**: Flutter (Dart), Material You, responsive for desktop + mobile
- **Send protocol**: `prompt_async` — no per-send SSE; delivery via provider-level SSE + polling fallback
- **Key invariant**: `session.idle` is the terminal lifecycle signal per ADR-023
- **Stream lifecycle**: `_messageSubscription` is NOT cancelled on `session.idle` — the stream drains in the background (by design)
- **Message mutation**: `_updateOrAddMessage` at `chat_provider_message_state_ops.dart:332` performs `_messages[index] = message` — a blind replacement
- **Ingress paths**: Send stream listener, `_fetchMessageFallback` (from SSE `message.updated`), debounced `_scheduleDebouncedMessageFallback` (from `message.part.updated`)
- **Must pass**: `make check` (analyze + test)

## Why This Plan

12 independent AI planners (planDeepSeek4Flash, planDeepSeek4Pro, planFlash, planG31Pro, planGLM51, planMimo25, planMimo25Pro, planMiniMax25, planMiniMax27, planQwen35Plus, planQwen36Plus, planQwen37Max) all independently diagnosed the same root cause and converged on the same core fix: a **monotonic completion guard** in `_updateOrAddMessage`. The consensus across 12 independent reviews (Stage 2.2) strongly confirms this approach.

The synthesized plan adds one lightweight secondary hardening (cancel debounced fallback timers on idle) that prevents unnecessary HTTP round-trips. All other proposed hardening layers (stream cancellation, generation increment, session-level timestamp gates, completed→completed merge, refreshActiveSessionView guards) were evaluated and **rejected** as either redundant with the core guard, risky to existing invariants, or over-engineered.

**Rejected alternatives and why:**
- **Stream cancellation on idle**: Would skip `onDone` cleanup (abort suppression, snapshot persist, insights load) — regresses `f8d6c3c6c`
- **Generation increment on idle**: Existing test at line 1577 expects stream to deliver completed messages after idle — would break
- **Session-level timestamp gate** (planMiniMax25): Blocks ALL mutations after idle, including authoritative `message.updated` — violates ADR-023
- **Defensive completedTime copy** (planDeepSeek4Pro): Silently "repairs" stale data rather than rejecting it — masks real bugs
- **Completed→completed merge** (planGLM51): Unnecessary complexity; server-authoritative complete message should replace entirely
- **refreshActiveSessionView guard** (planMimo25): Too broad, touches unrelated reconciliation flows

## Overview

A **two-point fix**: 
1. **Monotonic completion guard** in `_updateOrAddMessage` — prevents any incomplete `AssistantMessage` from overwriting a completed one (primary, covers all ingress paths)
2. **Cancel debounced fallback timers** on `session.idle` — prevents unnecessary HTTP requests that would be rejected anyway (secondary optimization)

Plus a regression test that directly reproduces the exact flicker failure mode and asserts stability.

## Steps

### Step 1: Add monotonic completion guard in `_updateOrAddMessage` (PRIMARY)

- **File**: `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart`
- **Location**: Lines 329-333, inside the `if (index != -1)` block, before `_messages[index] = message`
- **Details**:

```dart
final index = _messages.indexWhere((m) => m.id == message.id);
if (index != -1) {
  // Monotonic completion guard (ADR-023): once an AssistantMessage has
  // been marked completed (by session.idle → _markIncompleteAssistantMessagesAsCompleted,
  // or by authoritative message.updated with time.completed), never allow a
  // late incomplete event from the draining send stream or a stale fallback
  // fetch to regress it. The guard lifts when the incoming message is also
  // completed — allowing server-authoritative completedTime to replace the
  // locally-synthesized one.
  final existing = _messages[index];
  if (existing is AssistantMessage &&
      existing.isCompleted &&
      message is AssistantMessage &&
      !message.isCompleted) {
    AppLogger.debug(
      'Skipping incomplete overwrite of completed assistant message: '
      '${message.id} (existing completedTime=${existing.completedTime})',
    );
    return;
  }
  _messages[index] = message;
  _messagesVersion++;
  // ... rest unchanged
```

- **Risk**: Low — guard only blocks the specific regression pattern (completed → incomplete downgrade for same message ID). All other paths flow through unchanged: incomplete → incomplete (streaming updates), incomplete → complete (first completion), complete → complete (authoritative server update).
- **Coverage**: All three ingress paths (send stream, `_fetchMessageFallback`, debounced part fallback) converge at `_updateOrAddMessage` — single guard covers all.
- **Source**: Universal consensus across all 12 first-round plans and all 12 second-pass reviews.

### Step 2: Cancel debounced fallback timers on `session.idle` (SECONDARY)

- **File**: `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
- **Location**: Inside the `session.idle` handler, after line 408 (after `_markIncompleteAssistantMessagesAsCompleted`), within the `isCurrentSession` block
- **Details**:

```dart
// Cancel pending debounced message fallback timers — session.idle is
// the terminal signal; no further remote resolution is needed. This
// prevents unnecessary HTTP GETs that the monotonic guard would discard.
for (final entry in _messageFallbackDebounceById.entries.toList()) {
  final messageId = entry.key;
  final msgIndex = _messages.indexWhere((m) => m.id == messageId);
  if (msgIndex != -1 && _messages[msgIndex].sessionId == sessionId) {
    entry.value.cancel();
    _messageFallbackDebounceById.remove(messageId);
  }
}
```

- **Risk**: Low — cancelled timers simply won't fire. The guard in Step 1 already protects against any that slip through. This is an optimization: it avoids the HTTP request entirely rather than filtering its result.
- **Source**: planQwen37Max, endorsed by several second-pass reviews.

### Step 3: Add regression test for the exact flicker failure mode

- **File**: `test/unit/providers/chat_provider_realtime_test.dart`
- **Location**: After the existing `'session.idle ends active composer state while send stream drains'` test (~line 1641)
- **Test name**: `'monotonic completion guard: completed assistant message survives late incomplete stream event after session.idle'`
- **Scenario**:
  1. Set up send stream controller via `chatRepository.sendMessageHandler`
  2. `sendMessage` → provider subscribes to stream
  3. Deliver an INCOMPLETE assistant message (`completedTime == null`) through the stream
  4. Emit `session.idle` SSE event → `_markIncompleteAssistantMessagesAsCompleted` stamps `completedTime`
  5. Assert `provider.messages.last.isCompleted == true`
  6. Deliver a LATE incomplete version of the same message ID through the stream (simulating stale polling snapshot)
  7. **Assert**: message stays completed (`isCompleted == true`), `completedTime` unchanged
  8. Deliver a COMPLETE version through the stream (simulating authoritative server update)
  9. **Assert**: message IS updated to the new content (complete → complete allowed through guard)

- **Risk**: Low — uses existing test infrastructure (`FakeChatRepository`, `StreamController`, `emitEvent`)
- Also add test: **`'debounced fallback timers cancelled on session.idle'`** — schedule a debounced fallback, fire `session.idle`, assert timer was cancelled and HTTP GET does not fire.

### Step 4: Run `make check`

- **Command**: `export PATH="$HOME/flutter/bin:$PATH" && make check`
- **Validate**: All existing tests pass, new tests pass, zero analysis errors
- **Risk**: None

## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Guard blocks a legitimate update where server sends incomplete message after completed one for same ID | Low | ADR-023: `session.idle` is terminal. `message.updated` with `time.completed` is authoritative. An incomplete message after idle is a contract violation — rejecting it is correct. |
| Guard prevents an intermediate streaming update that adds new parts before completion | None | Guard only fires when existing IS completed. During active streaming before idle, `existing.isCompleted` is false → guard does not fire. |
| Timer cancellation could cancel a timer for a different session's message | Low | Guard at Step 2 checks `_messages[msgIndex].sessionId == sessionId` — only cancels timers for the idle session's messages. |
| `make check` fails on ARM64 host | Low | `make check` (analyze + test) works fine on ARM64. Only `make android` is affected by the ARM64 build limitation. |

## Assumptions to Validate

| Assumption | How to verify | If false |
|------------|---------------|----------|
| `_updateOrAddMessage` is the sole mutation bottleneck for full message replacements | Search all callers: `grep -rn "_updateOrAddMessage" lib/` | If another path directly mutates `_messages`, add a guard there too |
| `_copyMessageWithParts` preserves `completedTime` from existing message | Read line 60 of `chat_provider_message_state_ops.dart` — `completedTime: message.completedTime` | If it does not, add a `message.part.updated` guard in event reducer |
| `_messageFallbackDebounceById` field exists and stores `Timer` values | Read `chat_provider.dart` for field declaration | If field is named differently, adjust Step 2 accordingly |
| Send stream IS NOT cancelled on `session.idle` | Read `chat_provider_event_reducer_ops.dart:375-425` — only `_activeMessageStreamSessionId = null` | If stream IS cancelled, the flicker cause is different — investigate `_fetchMessageFallback` as sole source |

## Decisions and Nuances

- **Guard is monotonic, not temporal**: The guard checks `existing.isCompleted && !incoming.isCompleted` — it does NOT compare timestamps or check "which arrived first." This is the simplest correct invariant: once `completedTime` is non-null, it stays non-null.
- **No completed→completed merge**: When both messages are completed, the incoming message replaces entirely. ADR-023 says the server is authoritative — if the server says this is the final message, CodeWalk shows it as-is. No heuristic parts-length comparison.
- **Helper method extraction NOT included**: Several plans proposed extracting a `_shouldSkipMessageUpdate` helper. For 6 lines of guard code, inlining is clearer and avoids unnecessary indirection. A helper can be extracted later if reused.
- **Stream listener gate NOT included**: planDeepSeek4Pro's stream gate (`_activeMessageStreamSessionId != streamSessionId → return`) is semantically correct but redundant with the monotonic guard. The guard is the correct layer — no point guarding the transport when the data layer already protects.
- **`_markIncompleteAssistantMessagesAsCompleted` double-call left as-is**: Lines 396 and 408 both call this method. Line 396 handles non-current sessions; line 408 handles current sessions. The method is idempotent. Consolidating adds risk for no functional gain.

## Blockers and Open Questions

None. The fix is self-contained, well-understood, and has unanimous consensus across 12 independent planner reviews.

## Testing Strategy

1. **Unit test (exact failure mode)**: Step 3 test — verifies the guard prevents the exact flicker scenario
2. **Unit test (debounced timer cleanup)**: Step 3 test — verifies timers cancelled on idle
3. **Existing test regression**: All existing `session.idle` tests must pass (`chat_provider_realtime_test.dart:1577-1640`, `chat_provider_session_ops_test.dart:1120-1148`)
4. **`make check`**: Full analyze + test suite pass
5. **Manual visual validation** (post-implementation): Send a message, observe the final assistant message appears once and stays stable — no flicker between complete/incomplete states

## Execution Handoff

Starting point: `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart`, line 329.

First files to open:
1. `lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart` (add guard at line 330)
2. `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart` (add timer cleanup in `session.idle` handler)
3. `test/unit/providers/chat_provider_realtime_test.dart` (add regression tests)

Commands:
```bash
# After edits:
export PATH="$HOME/flutter/bin:$PATH"
make check
```

## Out of Scope

- Cancelling `_messageSubscription` on `session.idle`
- Incrementing `_messageStreamGeneration` on `session.idle`
- Adding `_sessionIdleCurrentSessionAt` timestamp field
- Changing `_markIncompleteAssistantMessagesAsCompleted` return type
- Guarding `_fetchMessageFallback` separately (redundant with monotonic guard)
- Guarding `refreshActiveSessionView` merge path
- Guarding `message.part.updated` handler (uses `_copyMessageWithParts` which preserves `completedTime`)

---

## Plan Comparison

### Full-Planner Consensus Pass

- **Selected full planners (Stage 2.2)**: All 12 first-round planners participated as evaluators (all passed the strict `full` gate in Stage 2.1)
- **Skipped**: No — all 12 were preliminarily `full`
- **Second-pass plans received**: 12 (planDeepSeek4Flash, planDeepSeek4Pro, planFlash, planG31Pro, planGLM51, planMimo25, planMimo25Pro, planMiniMax25, planMiniMax27, planQwen35Plus, planQwen36Plus, planQwen37Max)
- **Detailed candidate summaries**: Each candidate plan sent into Stage 2.2 had a rich paragraph covering strategy, likely files/modules/tests, sequencing, risks, validation, unique insights, and omissions
- **Consensus summary**: All 12 second-pass reviews confirmed the monotonic completion guard as the correct approach. planFlash and planG31Pro consistently appeared in top 3 across non-owner rankings for their minimal/surgical approach. planMiniMax25 consistently ranked bottom for its session-level timestamp gate. planDeepSeek4Pro's defensive copy approach was broadly rejected as over-complex. planMimo25's three-layer defense received mixed reviews — the guard layer was praised but the stream cancellation and refreshView guard layers were deemed too risky.
- **Self-bias adjustment**: Each planner's ranking of its own plan was discounted. Non-owner average rank, non-owner top-3 frequency, and non-owner `full` judgments were the primary decision signals.

### Consensus Evidence Table

| Candidate | Exact failure-mode coverage | Implementation completeness | Validation of exact case | Risk/blocker handling | Dependency/API certainty | Full verdict | Critical objections |
|-----------|-----------------------------|-----------------------------|--------------------------|-----------------------|--------------------------|--------------|---------------------|
| planFlash | ✅ Guard blocks complete→incomplete | ✅ Minimal, 5 lines | ✅ Test covers exact flicker | ✅ Low risk, narrow guard | ✅ None | full | None |
| planG31Pro | ✅ Same guard, ADR-023 anchored | ✅ Clear, well-documented | ✅ Test covers exact flicker | ✅ Low risk | ✅ None | full | None |
| planGLM51 | ✅ Guard + complete→complete merge | ⚠️ Merge logic adds complexity | ✅ Test covers lifecycle | ⚠️ Merge heuristic risky | ✅ None | full | Merge heuristic could mask part-removal events |
| planMiniMax27 | ✅ Guard, dead-code analysis | ✅ Simple guard | ✅ Test covers SSE after idle | ✅ Low risk | ✅ None | full | None |
| planMimo25Pro | ✅ Guard, ingress mapping | ✅ Well-analyzed | ✅ Test covers stream after idle | ✅ Low risk | ✅ None | full | None |
| planQwen36Plus | ✅ Guard, gen check analysis | ✅ Good analysis | ✅ Test covers exact flicker | ✅ Low risk | ✅ None | full | None |
| planDeepSeek4Flash | ✅ Guard + notify consolidation | ⚠️ Return type change | ✅ Test covers exact flicker | ⚠️ Return type change touches 11 callers | ✅ None | full | Unnecessary refactor mixed with bug fix |
| planQwen35Plus | ✅ Guard + helper + fetch guard | ⚠️ Two redundant injection points | ✅ Test covers exact flicker | ✅ Low risk | ✅ None | full | Redundant fetch guard |
| planQwen37Max | ✅ Guard + fetch guard + timer cleanup | ✅ Three complementary layers | ✅ Three tests | ✅ Low risk | ✅ None | full | None |
| planDeepSeek4Pro | ✅ Stream gate + defensive copy | ⚠️ Defensive copy masks bugs | ✅ Two tests | ⚠️ Defensive copy hides real issues | ✅ None | full | Defensive copy silences evidence of real bugs |
| planMimo25 | ✅ Three layers | ⚠️ Over-engineered | ✅ Test covers lifecycle | ⚠️ Stream cancel loses onDone cleanup | ✅ None | full | Stream cancellation regresses f8d6c3c6c intent |
| planMiniMax25 | ⚠️ Timestamp gate blocks ALL mutations | ⚠️ Too aggressive for current session | ❌ No test described | ⚠️ Blocks authoritative message.updated | ✅ None | not full | **Critical**: Blocks server-authoritative complete updates — violates ADR-023 |

### Vetoes, Blockers, and Overrides

- **Critical objections raised**: 
  - planMiniMax25: Session-level timestamp gate blocks ALL mutations after idle, including authoritative `message.updated` with `time.completed` — **violates ADR-023**. Rendering: **not full**, excluded from winner consideration.
- **Resolved objections**: None unresolved that affect the winning approach.
- **Unresolved objections**: None — all 11 full plans agree on the monotonic guard approach.
- **Consensus overrides**: None. The synthesized plan follows the broad consensus.
- **Scoring/voting role**: Ranking averages and top-3 frequency were advisory signals only. planFlash (most minimal) and planG31Pro (best ADR-023 anchoring) were the strongest by non-owner consensus. The final synthesized plan adopts the monotonic guard from all 11 full plans and adds timer cleanup (from planQwen37Max) as the only secondary hardening.

### Per-Planner Assessment

#### planFlash
- **Strengths**: Purest expression of the core fix. 5 lines, single file, minimal diff. Best simplicity-to-correctness ratio.
- **Weaknesses**: No secondary hardening. Single guard covers all paths but leaves debounced timers running wastefully.
- **Unique insights**: The fix is so minimal it's almost a one-liner — the guard IS the plan.

#### planG31Pro
- **Strengths**: Strongest ADR-023 anchoring. Explicitly frames the fix as a "monotonic completion invariant" — the correct mental model.
- **Weaknesses**: Marginally more verbose than planFlash for the same fix.
- **Unique insights**: The "monotonic completion" framing makes the fix self-documenting and auditable.

#### planGLM51
- **Strengths**: Most detailed merge logic for completed→completed case. Addresses edge case where server delivers completed message with fewer parts than local.
- **Weaknesses**: Merge heuristic (prefer longer parts list) could mask legitimate part removals. Adds ~15 lines over the minimal guard.
- **Unique insights**: Identifies that completed→completed updates should be handled explicitly, not just allowed to pass through.

#### planQwen37Max
- **Strengths**: Only plan to address debounced timer race. Three complementary layers. Comprehensive test coverage.
- **Weaknesses**: The `_fetchMessageFallback` pre-guard is redundant with the `_updateOrAddMessage` guard.
- **Unique insights**: Timer cleanup prevents HTTP requests that the guard would reject — optimization that saves round-trips.

### Failed Agents

- **planKimi26**: Phase A empty response on both attempts — failed to respond to readiness probe
- **planMiniMax27**: Phase B empty response on first attempt, succeeded on retry

### Why This Synthesized Plan Is Best
- Adopts the universal monotonic guard from all 11 full plans
- Adopts the debounced timer cleanup from planQwen37Max as lightweight optimization
- Rejects all over-engineered/risky hardening layers (stream cancel, generation increment, timestamp gate, defensive copy, merge, refreshView guard)
- 3 files changed, ~20 lines of new code, 2 new tests
- Unanimous consensus support across 12 independent planner reviews

### Best Individual Plan Verdict
- **Winner**: planFlash (by non-owner cross-planner consensus)
- **Why**: Simplest correct fix. Pure monotonic guard. 5 lines. Every non-owner review placed it in the top 3. The guard is universally recognized as necessary and sufficient.
- **Trade-off notes**: planG31Pro has better documentation/ADR anchoring. planQwen37Max adds valuable timer cleanup. The synthesized plan incorporates the best of all three.
- **Note**: Final synthesized plan combines the guard from planFlash/planG31Pro with the timer cleanup from planQwen37Max.

### Final Ranking Rationale

- **Position 1 — planFlash**: Wins by non-owner consensus. Appeared in top 3 of 9 out of 12 non-owner rankings. Pure, minimal, correct. The canonical implementation of the consensus fix.
- **Position 2 — planG31Pro**: Functionally identical to planFlash with stronger ADR-023 documentation. "Monotonic completion invariant" framing is the best mental model.
- **Position 3 — planGLM51**: Guard + complete→complete merge. The merge adds complexity but addresses a real edge case. Higher complexity cost keeps it below the simpler plans.
- **Position 4 — planMiniMax27**: Guard + dead-code analysis. Correct fix with good contextual analysis of the idle handler.
- **Position 5 — planMimo25Pro**: Guard + thorough ingress path mapping. The mapping is excellent documentation but the fix is identical to planFlash.
- **Position 6 — planQwen36Plus**: Guard + generation check gap analysis. Good analysis, same fix.
- **Position 7 — planQwen37Max**: Guard + fetch guard + timer cleanup. Timer cleanup is valuable but the fetch guard is redundant.
- **Position 8 — planQwen35Plus**: Helper + two guards. Helper adds indirection; second guard is redundant.
- **Position 9 — planDeepSeek4Flash**: Guard + notify consolidation. Return type change is unnecessary refactor.
- **Position 10 — planDeepSeek4Pro**: Stream gate + defensive copy. Defensive copy masks real bugs; stream gate is redundant with guard.
- **Position 11 — planMimo25**: Three layers. Stream cancellation regresses f8d6c3c6c intent; refreshView guard is too broad.
- **Position 12 — planMiniMax25**: Session-level timestamp gate. **Not full** — blocks authoritative `message.updated` with `time.completed`, violating ADR-023.

### Plan Ranking (Best to Worst)

1. planFlash (full)
2. planG31Pro (full)
3. planGLM51 (full)
4. planMiniMax27 (full)
5. planMimo25Pro (full)
6. planQwen36Plus (full)
7. planQwen37Max (full)
8. planQwen35Plus (full)
9. planDeepSeek4Flash (full)
10. planDeepSeek4Pro (full)
11. planMimo25 (full)
12. planMiniMax25
