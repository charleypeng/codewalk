# Synthesized Plan — Fix Composer Stuck Stop After Final Response

## Execution Plan (Synthesized)

### Status

Ready.

### Problem

In some CodeWalk conversations/sessions, the composer primary action remains in Stop mode after the final assistant response has already arrived and is visible. The concrete bad state is an empty composer showing `Symbols.stop_rounded` / "Stop response" even though the latest assistant message is completed and contains revealable final content. This is most likely when the latest completed assistant message includes both revealable content (for example text/reasoning) and tool/patch parts, while `/session/status` or `session.status` still reports `busy`/`retry`.

### Objective

After the final assistant response is locally completed and revealable, the active-session composer must return from Stop to Send unless there is genuine local evidence of an abortable turn for that same session. Legitimate Stop behavior must remain for active streams, `ChatState.sending`, incomplete assistant messages, latest-user busy tails, and completed tool-only busy tails.

### Context and Constraints

- CodeWalk is a Flutter/Dart OpenCode client using Provider and Dio.
- ADR-023 requires official OpenCode contract-first compatibility. Official status/events remain authoritative data; OpenChamber is only a secondary design reference.
- Relevant paths:
  - `lib/presentation/providers/chat_provider.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
  - `lib/presentation/utils/chat_assistant_settlement.dart`
  - `lib/presentation/widgets/chat_input_widget.dart`
  - `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart`
  - `test/unit/providers/chat_provider_messaging_test.dart`
  - `test/widget/chat_page_test.dart`
- Current chain: `ChatInputWidget.showStopAction = widget.isResponding && !hasSendPayload`; chat page passes `chatProvider.canAbortActiveResponse`; provider delegates to `isCurrentSessionActivelyResponding`.
- Current risky predicate: if current session has `busy/retry` and latest assistant contains any `ToolPart`/`PatchPart`, `isSessionActivelyResponding` returns true even if the assistant is completed and also has final text.
- Existing helper `hasCompletedRevealableAssistantMessage` treats a latest completed assistant as revealable when it has any part that is not `ToolPart` or `PatchPart`.
- Existing one-shot `_sseSettledToIdleSessionIds` REST guard should remain narrow; do not replace it with broad or indefinite busy suppression.
- User explicitly allowed multiple tests at once during execution.

### Why This Plan

The safest fix is to separate raw server busy status from the local composer abort affordance. Server status may remain busy because of delayed events, stale REST snapshots, prompt_async quirks, or other-client/resumed work; the composer Stop button should only represent a locally abortable current turn. This preserves ADR-023 by not rewriting OpenCode lifecycle semantics while fixing the exact UI failure.

Rejected alternatives:
- Broadly coerce `busy` to `idle` in REST/event handlers whenever a revealable assistant exists: risks hiding legitimate later work.
- Add TTL/timestamp settlement heuristics: unnecessary for the exact bug and introduces timing policy.
- Require `hasToolSurfacePart && hasActiveStream`: risks breaking intentional completed tool-only busy behavior.

### Overview

Implement a predicate-first fix in `ChatProvider.isSessionActivelyResponding`: preserve high-confidence active signals, but for current-session busy/retry fallback classify the latest tail precisely. Completed revealable assistant tails hide Stop; completed tool-only tails keep Stop. Add targeted provider and widget tests, including an SSE busy-after-final regression, without mutating raw server status in the first implementation.

### Steps

1. Add or expose a revealable-content helper.
   - Files: `lib/presentation/utils/chat_assistant_settlement.dart`
   - Details: Prefer adding `bool hasRevealableAssistantContent(AssistantMessage message)` that uses the existing predicate: any part that is not `ToolPart` and not `PatchPart`. Update `hasCompletedRevealableAssistantMessage` to call the shared helper. Keep `isToolOnlyAssistantMessage`.
   - Risk: Low.
   - Source: planCodex55, planMiniMax27, planQwen36Plus, planCodex54, planFlash.

2. Refine `isSessionActivelyResponding` current-session busy fallback.
   - Files: `lib/presentation/providers/chat_provider.dart`
   - Details:
     - Keep existing early true cases: active same-session stream, `_state == ChatState.sending`, any incomplete assistant for the session.
     - Keep non-current behavior unchanged: status-backed busy/retry.
     - Under current-session busy/retry, inspect latest session message:
       - no latest message → false;
       - latest `UserMessage` → true;
       - latest non-assistant → true;
       - latest incomplete `AssistantMessage` → true;
       - latest completed assistant with revealable content → false;
       - latest completed assistant that is tool-only/patch-only → true.
   - Risk: Medium-low because it is central UI state, but cases are explicit and testable.
   - Source: planCodex55, planMiniMax27, planQwen36Plus, planCodex54.

3. Do not mutate raw status in the first fix.
   - Files: `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`, `lib/presentation/providers/chat_provider.dart`
   - Details: Leave existing `session.status`, `loadSessionInsights`, and `refreshSessionStatusSnapshot` status storage mostly unchanged. The predicate should make composer Stop resilient to stale busy from REST or SSE. Add an event-reducer guard only later if tests reveal a separate user-facing busy indicator regression outside the composer.
   - Risk: Low; avoids hiding legitimate work.
   - Source: planCodex55, planMiniMax27, planQwen36Plus.

4. Add provider regression tests for exact behavior.
   - Files: `test/unit/providers/chat_provider_messaging_test.dart`
   - Details:
     - Update existing mixed tool+text final under stale busy test to expect `isCurrentSessionActivelyResponding == false` and `canAbortActiveResponse == false`.
     - Add explicit test: completed assistant with `TextPart` + `ToolPart`/`PatchPart`, status busy, no active stream → false.
     - Add explicit test: `session.status: busy` SSE after completed mixed final does not re-enable `canAbortActiveResponse`.
     - Preserve/add test: completed tool-only assistant + busy → true.
     - Preserve/add test: incomplete assistant before busy → true.
     - Preserve/add test: active stream after previous settled response → true.
     - Preserve/add test: latest user + busy → true.
   - Risk: Low.
   - Source: all full plans, especially planCodex55, planMiniMax27, planDeepSeek4Flash.

5. Add widget-level exact stuck Stop validation.
   - Files: `test/widget/chat_page_test.dart` or a focused composer/provider widget test if full ChatPage setup is too heavy.
   - Details: Build a state representing current session with completed mixed final and busy status, empty composer. Assert `Symbols.stop_rounded` and `Stop response` semantics are absent; send/disabled-send state is present.
   - Risk: Low-medium depending on harness complexity.
   - Source: planCodex54, planCodex55, planDeepSeek4Flash.

6. Run validation.
   - Commands: targeted provider/widget tests; then `make check`; after implementation and review, `HEY_CAPTION="Fixed stuck Stop after final assistant response" make android` if following full project flow.
   - Risk: Low.
   - Source: project rules and user instruction allowing multiple tests.

### Risks & Mitigations

- Critical: Hiding legitimate active tool work.
  - Mitigation: Preserve true for active stream, sending, incomplete assistant, latest user busy, and completed tool-only busy.
- High: Misclassifying structural parts as revealable.
  - Mitigation: Centralize revealability helper and verify part types used in tests; defaulting non-tool/non-patch to revealable matches existing utility.
- Medium: Raw status still shows busy elsewhere while composer shows Send.
  - Mitigation: This is intentional separation. Only address other UI surfaces if a concrete regression is reported.
- Medium: 409 busy-preserve paths.
  - Mitigation: Add/keep tests ensuring failed follow-up/409 does not regress draft recovery and does not incorrectly keep Stop after already settled previous final unless new local in-flight evidence appears.

### Assumptions to Validate

- `AssistantMessage.isCompleted` reliably indicates final local settlement.
  - Verify via existing message model/tests and new regression.
  - If false: adjust helper to use `completedTime`/message completion semantics already used elsewhere.
- Existing `hasCompletedRevealableAssistantMessage` semantics match rendered revealable content.
  - Verify part classes and widget output expectations.
  - If false: refine helper to exclude additional structural-only parts.
- Predicate fix alone handles SSE busy reintroduction for the composer.
  - Verify with direct SSE regression test.
  - If false: add a narrowly gated event guard: current session only, no active send turn, completed revealable assistant present.

### Decisions and Nuances

- Final plan deliberately does not implement TTL or durable settlement timestamps.
- Final plan deliberately does not continuously coerce REST busy to idle.
- OpenChamber insight is preserved only as a pattern: separate raw session status from active streaming/abort affordance.
- The best individual plans converge on predicate refinement; event/status suppression plans are useful for tests and fallback but not primary.

### Blockers and Open Questions

None blocking. Optional verification: whether any non-tool/non-patch assistant parts are structural-only and should not count as revealable.

### Testing Strategy

- Provider unit tests for exact mixed completed final + busy → Stop false.
- Provider unit test for SSE `session.status: busy` after final mixed response → Stop false.
- Provider unit tests for tool-only busy, incomplete assistant, active stream, latest user busy.
- Widget test for exact empty composer stuck Stop visual/semantic state.
- Full `make check`.
- Android build for manual test when implementing.

### Execution Handoff

Start by opening:
1. `lib/presentation/providers/chat_provider.dart` around `isSessionActivelyResponding`.
2. `lib/presentation/utils/chat_assistant_settlement.dart`.
3. `test/unit/providers/chat_provider_messaging_test.dart` around existing stale busy/tool-only tests.
4. `test/widget/chat_page_test.dart` around existing Stop/incomplete draft test.

Recommended implementation order: tests for provider predicate → helper refactor → provider predicate change → widget regression → targeted tests → `make check`.

### Out of Scope

- Server-side OpenCode changes.
- Replacing `prompt_async`.
- OpenChamber integration.
- Broad busy-to-idle suppression.
- TTL/cooldown stuck-session heuristics.
- Composer visual redesign.
- Abort endpoint behavior changes.

---

## Plan Comparison

### Full-Planner Consensus Pass

- Selected full planners: planCodex54, planCodex55, planDeepSeek4Flash.
- Skipped: no for full-planner pass; only these passed the strict preliminary full gate and participated.
- Second-pass plans received: 3 — planCodex54, planCodex55, planDeepSeek4Flash.
- Detailed candidate summaries: yes, each candidate plan sent into Stage 2.2 had a rich paragraph covering strategy, files/modules/tests, sequencing, risks, validation, unique insights, and omissions.
- Consensus summary: All second-pass plans ranked predicate-first/local abortability refinement at or near the top. planCodex55, planMiniMax27, and planQwen36Plus consistently ranked high. Event-guard plans were valued for test ideas but penalized when they mutated raw status. TTL/continuous-suppression plans were consistently downgraded.
- Self-bias adjustment: planCodex54 and planCodex55 ranked their own plans high, but non-owner rankings and rationale were used as primary signal. planDeepSeek4Flash ranked itself sixth. Cross-rater consensus favored planCodex55/MiniMax27/Qwen36Plus over more invasive event/TTL approaches.

### Consensus Evidence Table

| Candidate | Exact failure-mode coverage | Implementation completeness | Validation of exact case | Risk/blocker handling | Dependency/API certainty | Full verdict | Critical objections |
|-----------|-----------------------------|-----------------------------|--------------------------|-----------------------|--------------------------|--------------|---------------------|
| planCodex54 | Pass: mixed completed final + busy explicitly hidden | Pass: helper + predicate + tests + optional state safety net | Pass: provider/widget exact tests | Pass: avoids broad suppression | Pass: no new deps | full | Optional `_updateOrAddMessage` safety net may be unnecessary |
| planCodex55 | Pass: direct predicate fix for exact Stop state | Pass: clear files and cases | Pass: exact provider/widget tests | Pass: strong avoidance of broad suppression | Pass: no new deps | full | None material |
| planDeepSeek4Flash | Pass: exact SSE/REST stale busy and mixed final | Pass: predicate + event guard + tests | Pass: exact SSE race tests | Pass but event suppression has some risk | Pass: no new deps | full | Event status mutation may hide brief legitimate other-client busy |
| planDeepSeek4Pro | Pass | Pass but broad | Pass | Mixed: TTL/state heuristic risk | Pass | not full | Time-based suppression unnecessary and risky |
| planFlash | Pass | Mostly pass, minimal | Partial: unit only | Partial: limited edge coverage | Pass | not full | Underexplored active/SSE/widget validation |
| planG31Pro | Pass | Mostly pass | Partial | Partial | Pass | not full | Thin validation |
| planGLM51 | Pass | Pass | Pass | Mixed: event coercion risk | Pass | full | More invasive than needed |
| planKimi26 | Pass | Pass | Pass | Fail: continuous busy suppression risk | Pass | not full | Could hide legitimate later busy/resumed work |
| planMimo25Pro | Pass | Pass | Pass | Mixed: event guard insufficiently gated | Pass | full | Some status mutation risk |
| planMiniMax25 | Pass | Mostly pass | Partial | Partial | Pass | not full | Less comprehensive and minor conceptual ambiguity |
| planMiniMax27 | Pass | Pass | Pass: SSE regression included | Pass: raw status untouched | Pass | full | Raw busy may remain in non-composer UI, acceptable |
| planPickle | Pass | Pass | Pass | Mixed: event guard depends on one-shot flag | Pass | full | Secondary guard fragile but predicate works |
| planQwen36Plus | Pass | Pass | Pass provider; less widget | Pass | Pass | full | Less direct widget validation |
| planQwen35Plus retry partial | Partial | Fail: risky activeStream requirement | Partial | Fail: breaks tool-only busy risk | Pass | not full | Unsafe main predicate; timeout needs ADR |
| planGPToss | Fail: empty | Fail | Fail | Fail | Unknown | not full | No plan |

### Vetoes, Blockers, and Overrides

- Critical objections raised:
  - Broad/continuous busy suppression can hide legitimate other-client/resumed work (against Kimi26, DeepSeek4Pro TTL direction).
  - Requiring active stream for tool-only busy can break intentional completed tool-only busy behavior (against Qwen35Plus retry partial).
  - Event reducer status mutation is more invasive than needed for a composer-only bug (against several dual plans as primary strategy).
- Resolved objections:
  - Final plan keeps raw status untouched in first implementation and fixes local abortability predicate.
  - Tool-only busy remains true explicitly.
  - SSE busy is tested through predicate resilience rather than suppressed broadly.
- Unresolved objections: none.
- Consensus overrides: The final plan follows broad consensus for predicate refinement. It overrides some second-pass support for event guards by making them fallback-only because raw-status mutation risk is avoidable.
- Scoring/voting role: Rankings/top placements were advisory only; critical safety concerns about suppression and tool-only regression controlled final synthesis.

### Per-Planner Assessment

### planCodex54

- Strengths: Comprehensive helper/classifier idea, exact provider/widget validation, risk-aware, OpenChamber separation insight.
- Weaknesses: `_updateOrAddMessage` safety net may be speculative without failing test evidence.
- Unique insights: Explicitly frames Stop as “locally abortable turn” rather than raw busy.

### planCodex55

- Strengths: Safest narrow predicate-first fix, excellent case breakdown, avoids status mutation, implementation-ready.
- Weaknesses: Less explicit on SSE regression than MiniMax27.
- Unique insights: Strong raw-status vs abort-affordance separation.

### planDeepSeek4Flash

- Strengths: Best SSE race analysis, strong tests for event path, exact failure sequencing.
- Weaknesses: Primary event suppression is more invasive than necessary.
- Unique insights: Identified how event busy can bypass one-shot REST guard.

### planDeepSeek4Pro

- Strengths: Thorough concurrent-consumer/TTL analysis and tests.
- Weaknesses: Overengineered time-based settlement; unnecessary state and suppression risk.
- Unique insights: Multiple REST consumers can consume/lose one-shot protection.

### planFlash

- Strengths: Minimal correct core code change.
- Weaknesses: Under-specified validation and edge cases.
- Unique insights: `isToolOnlyAssistantMessage` may be the cleanest primitive.

### planG31Pro

- Strengths: Focused local fix, raw status untouched.
- Weaknesses: Thin tests and less complete edge handling.
- Unique insights: Clear simple implementation snippet.

### planGLM51

- Strengths: Strong two-layer diagnosis, test set, identifies buggy existing expectation.
- Weaknesses: Event status coercion risk.
- Unique insights: Explicitly discusses other-client busy race.

### planKimi26

- Strengths: Highlights missing status-event and REST non-one-shot coverage.
- Weaknesses: Broad continuous busy suppression conflicts with constraints.
- Unique insights: Useful warning that one-shot guards do not cover all refreshes.

### planMimo25Pro

- Strengths: Implementation-ready helper exposure + predicate + tests.
- Weaknesses: Event guard needs tighter active-turn gating.
- Unique insights: Makes revealable helper public to avoid duplication.

### planMiniMax25

- Strengths: Focused predicate-only plan likely sufficient for UI symptom.
- Weaknesses: Less complete validation and some conceptual ambiguity.
- Unique insights: Keeps event processing out of scope.

### planMiniMax27

- Strengths: Strongest predicate-only explanation, direct SSE-after-onDone test, raw status preserved.
- Weaknesses: Does not address other UI surfaces if raw busy remains.
- Unique insights: Predicate can be resilient to stale busy from any source.

### planPickle

- Strengths: Balanced predicate primary + narrow event fallback.
- Weaknesses: Event fallback depends on one-shot flag and may miss late busy.
- Unique insights: Use one-shot presence only as a defensive guard, not broad suppression.

### planQwen36Plus

- Strengths: Clear persistent predicate defense, preserves all major paths.
- Weaknesses: Less direct widget validation.
- Unique insights: Explicitly notes subsequent REST busy is handled by predicate.

### planQwen35Plus

- Strengths: Mentions 409 path as worth validating.
- Weaknesses: Unsafe active-stream requirement; timeout requires ADR review; non-full.
- Unique insights: Validate 409 busy preservation during implementation.

### Failed Agents (if any)

- planGPToss: returned empty twice.
- planQwen35Plus initial attempt: returned empty; retry partial was non-full and risky.

### Why this synthesized plan is best

- Fixes the exact composer Stop failure without changing OpenCode status semantics.
- Preserves tool-only busy, active stream, incomplete assistant, latest-user busy, and sub-conversation behavior.
- Converts broad planner consensus into a minimal, testable implementation.
- Avoids risky TTL/continuous suppression/event mutation unless a test proves it is required.

### Best Individual Plan Verdict

- Winner: planCodex55
- Why this plan ranked first:
  - Directly fixes the predicate causing the composer bug.
  - Keeps raw server status untouched and ADR-compatible.
  - Fully preserves legitimate Stop paths.
  - Provides actionable tests and files.
- Trade-off notes: planMiniMax27 supplied the strongest SSE regression idea; planCodex54 supplied stronger helper/test breadth; planDeepSeek4Flash supplied event-race analysis.
- Note: final synthesized plan combines strengths from multiple planners.

### Final Ranking Rationale

- Position 1 — planCodex55: Best cross-planner-supported safe plan; predicate-first, no broad suppression, full enough.
- Position 2 — planMiniMax27: Excellent raw-status separation and SSE regression; slightly less helper/widget breadth.
- Position 3 — planQwen36Plus: Strong simple predicate defense; less validation detail.
- Position 4 — planCodex54: Comprehensive and full; slightly broader than needed with optional state safety net.
- Position 5 — planGLM51: Full and insightful; event coercion risk keeps it below predicate-only plans.
- Position 6 — planDeepSeek4Flash: Full and strong race analysis; event mutation risk.
- Position 7 — planMimo25Pro: Full and executable; event guard needs tighter gating.
- Position 8 — planPickle: Full hybrid; one-shot event guard less robust.
- Position 9 — planFlash: Correct core idea but underexplored.
- Position 10 — planG31Pro: Correct local fix but thin.
- Position 11 — planMiniMax25: Correct direction but weaker validation.
- Position 12 — planDeepSeek4Pro: Full but overengineered and timing-based.
- Position 13 — planKimi26: Useful but unsafe broad suppression.
- Position 14 — planQwen35Plus: Non-full and risky.
- Position 15 — planGPToss: Empty/failed.

### Plan Ranking (Best to Worst)

1. planCodex55 (full)
2. planMiniMax27 (full)
3. planQwen36Plus (full)
4. planCodex54 (full)
5. planGLM51 (full)
6. planDeepSeek4Flash (full)
7. planMimo25Pro (full)
8. planPickle (full)
9. planFlash
10. planG31Pro
11. planMiniMax25
12. planDeepSeek4Pro
13. planKimi26
14. planQwen35Plus
15. planGPToss
