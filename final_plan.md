# SessionDiffViewer — Fix Empty Diff Display

## Status

Ready

## Problem

In the "Review changes" feature (`SessionDiffViewer`), the list of modified files during a session is displayed correctly, but when selecting any file, the diff shown is essentially empty for ALL files — only `--- filename.ext`, `+++ filename.ext`, `@@`, `-`, `+` appears.

**Root cause**: `_buildUnifiedDiff()` (session_diff_viewer.dart:265-275) builds a "diff" by naively prefixing **every** line of `before` with `-` and **every** line of `after` with `+`, then joining them. When `before`/`after` are empty strings (server returns no file snapshots), `''.split('\n')` produces `['']`, yielding the observed phantom `-`/`+` output. Even when content IS present, the output is a useless wall of red/green with no context lines, not a real unified diff.

## Objective

When a user selects a modified file in "Review changes", the widget must display:
1. Actual added/removed/context lines when server provides `before`/`after` content
2. A clear fallback message when content is unavailable (instead of phantom `-`/`+`)
3. Proper unified-diff format with hunk headers and context windows

## Context and Constraints

- **Project**: CodeWalk — Flutter/Dart client for OpenCode server
- **Official contract**: OpenCode SDK `FileDiff` type = `{ file, before, after, additions, deletions }` — `before`/`after` contain full file content at session start/end
- **ADR-023**: Contract-first compatibility — no schema changes, no speculative field additions
- **Mobile-first UX**: Viewer works on both compact and expanded layouts
- **No external dependencies**: Fix stays within Dart SDK (`dart:math` only)

### Key files
- `lib/presentation/widgets/session_diff_viewer.dart` — **`_buildUnifiedDiff()` (lines 265-275)** and `_buildDiffPreview()` (228-263)
- `lib/presentation/utils/diff_parser.dart` — `parseDiffLines()`, `DiffLine`, `DiffLineType`
- `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart` — SSE `session.diff` handler (lines 308-328)
- `lib/data/models/session_lifecycle_model.dart` — `SessionDiffModel.fromJson()`
- `test/widget/session_diff_viewer_test.dart`, `test/presentation/utils/diff_parser_test.dart`

## Why This Plan

Synthesized from 6 full-planner consensus reviews and 14 first-round plans. The consensus strongly converged on:
- Custom LCS-based diff engine (no external dependency)
- Direct `List<DiffLine>` output (no wasteful string round-trip) — adopted from planPickle
- Graceful empty-state fallback UI — adopted from planDeepSeek4Pro
- SSE ingestion hardening — adopted from planCodex54/55 as defense-in-depth
- Rejecting speculative server-schema-change plans (planMimo25Pro, planFlash, planG31Pro)

## Overview

Three coordinated layers:
**A** — Replace `_buildUnifiedDiff()` with `computeDiffLines()` that outputs `List<DiffLine>` directly via LCS-based line diff
**B** — Add graceful empty-state fallback when server provides no content
**C** — Harden SSE diff ingestion to prevent empty payloads from overwriting REST-loaded content

All within `diff_parser.dart` and `session_diff_viewer.dart`. Zero dependencies. Zero schema changes.

## Steps

### Step 1: Add `computeDiffLines()` to `diff_parser.dart`
- **Files**: `lib/presentation/utils/diff_parser.dart` — add new function
- **Signature**: `List<DiffLine> computeDiffLines(String before, String after, String filename)`
- **Algorithm**: LCS (Longest Common Subsequence) DP table on line arrays, ~80 lines self-contained
  - Normalize line endings: split on `\r\n|\r|\n`
  - Handle `''` as `[]` (no phantom empty line)
  - Edge: both empty → `[DiffLine('--- $filename\n+++ $filename\n@@\n', DiffLineType.metadata)]`
  - Edge: `before` empty, `after` non-empty → all `DiffLineType.add`, `/dev/null` header
  - Edge: `after` empty, `before` non-empty → all `DiffLineType.remove`, `/dev/null` header
  - Edge: identical → single hunk with context lines only
  - Normal: LCS DP → edit script → hunks with 3-line context → `@@ -a,b +c,d @@` headers
  - Guard: if `before.lines × after.lines > 4_000_000` → fall back to degenerative whole-file diff
- **Risk**: medium — core algorithm; must handle edge cases correctly
- **Source**: planPickle (direct output), planDeepSeek4Pro (large-file guard), planCodex55 (line normalization)

### Step 2: Rewrite `_buildDiffPreview()` in `session_diff_viewer.dart`
- **Files**: `lib/presentation/widgets/session_diff_viewer.dart`
- **Changes**:
  - Delete `_buildUnifiedDiff()` method entirely (lines 265-275)
  - In `_buildDiffPreview()`: call `computeDiffLines(diff.before, diff.after, diff.file)` directly
  - If result has ≤2 metadata-only lines (both before/after were empty) → render fallback widget:
    - Icon + bold filename + `"+${diff.additions} lines added  −${diff.deletions} lines removed"` + caption `"File content not captured by the server"`
  - Otherwise → use returned `List<DiffLine>` in existing `ListView.builder` (unchanged rendering loop)
- **Risk**: low — rendering loop unchanged; only input source changes
- **Source**: planPickle (delete `_buildUnifiedDiff`, direct call), planDeepSeek4Pro (fallback widget)

### Step 3: Harden SSE `session.diff` ingestion
- **Files**: `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart` (lines 308-328)
- **Changes**:
  - Replace manual `SessionDiff(...)` construction with `SessionDiffModel.fromJson(...).toDomain()` to unify REST + SSE parsing
  - Add merge guard: if incoming SSE item has empty `before` and empty `after`, preserve existing non-empty stored content for same file
  - If entire incoming SSE diff list is empty and existing list is non-empty, skip overwrite
- **Risk**: low — additive guard; normal payloads unchanged
- **Source**: planCodex54, planCodex55

### Step 4: Update tests
- **Files**: `test/widget/session_diff_viewer_test.dart` — add: both-empty fallback, multi-line with context, new file, deleted file, identical content
- **Files**: `test/presentation/utils/diff_parser_test.dart` — add `computeDiffLines` test group covering all edge cases
- **Risk**: low
- **Source**: planCodex54, planQwen36Plus

### Step 5: Run `make check` and `make android`
- Validate all tests pass, no regressions
- Build APK for mobile verification

## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Server consistently returns empty `before`/`after` | High | Fallback UI shows stats + explanation; user still sees file list and counts |
| Large-file LCS O(n×m) memory on mobile | Medium | Guard at 4M cells (~2000×2000 lines) → degenerative fallback |
| SSE merge may preserve stale content | Low | Only preserves when existing is non-empty AND new is empty; intentional clear = send data with zero stats |
| Trailing newline produces phantom empty diff line | Low | Explicit `\r\n\|\r\|\n` split with empty-string filtering |
| ADR-023 compliance | None | No contract changes; `FileDiff` fields consumed as-is |

## Assumptions to Validate

| Assumption | Verification | If false |
|------------|-------------|----------|
| Server returns `before`/`after` as full file content per official SDK | Inspect live REST response from `/session/:id/diff` | Fallback UI already handles empty case gracefully |
| Server does NOT return a pre-computed `diff`/`patch` field | Same inspection | If it does, consider adding additive `patch` support as follow-up |
| SSE and REST both produce identical `SessionDiff` structure | Existing tests pass; both paths parse same fields | Handled by Step 3 unification |

## Decisions and Nuances

- **Direct `List<DiffLine>` output over string round-trip**: Eliminates `_buildUnifiedDiff()` → string → `parseDiffLines()` pipeline. Fewer transformations = fewer bugs. planPickle identified this; consensus supported it strongly.
- **No external dependency**: `diff_match_patch` (planQwen35Plus) and `deviation` (planDeepSeek4Flash) both add risk for a ~80-line algorithm. Custom LCS avoids pubspec changes, version drift, and platform compatibility concerns.
- **Rejected server-schema-change approaches**: planMimo25Pro (replace `before`/`after` with `patch`), planFlash and planG31Pro (add speculative `diff`/`patch` field) contradict the official SDK type and would violate ADR-023.
- **SSE merge guard included as defense-in-depth**: Not strictly needed today (both paths produce empty data), but prevents silent data loss in future server versions.
- **Keep `parseDiffLines()` intact**: Still used by `chat_message_tool_part.dart` for tool-output diff rendering.

## Blockers and Open Questions

None. Plan is implementation-ready.

## Testing Strategy

1. **Unit**: `computeDiffLines()` tested for all edge cases (identical, empty, new file, deleted file, multi-line, multi-hunk, large-file guard)
2. **Widget**: `SessionDiffViewer` tested with: populated content (proper hunks), empty content (fallback), file switching, compact + expanded layouts
3. **Provider/SSE**: SSE merge guard tested — non-empty existing data preserved when incoming event has empty fields
4. **Integration**: `make check` passes full suite
5. **Visual**: Android APK manual verification

## Execution Handoff

1. Open `lib/presentation/utils/diff_parser.dart` — add `computeDiffLines()` function
2. Open `lib/presentation/widgets/session_diff_viewer.dart` — delete `_buildUnifiedDiff()`, rewrite `_buildDiffPreview()`, add fallback widget
3. Open `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart` — unify SSE parsing, add merge guard
4. Update test files
5. Run `make check`
6. Run `HEY_CAPTION="Fixed Review changes diff rendering" make android`

## Out of Scope

- Server-side changes (snapshot enablement, diff endpoint behavior)
- Adding external dependencies
- Changing `SessionDiff` entity or `SessionDiffModel` fields
- Replacing `parseDiffLines()` for tool-part rendering
- Caching computed diffs (premature optimization)
- Side-by-side diff view

---

## Plan Comparison

### Full-Planner Consensus Pass

- **Selected full planners**: planCodex54, planCodex55, planDeepSeek4Pro, planGLM51, planPickle, planQwen36Plus
- **Skipped**: No
- **Second-pass plans received**: 6 (all selected planners returned; planCodex55 needed one retry)
- **Detailed candidate summaries**: Each candidate plan sent into Stage 2.2 had a rich paragraph covering strategy, likely files, sequencing, risks, validation, unique insights, and omissions.
- **Consensus summary**: PlanPickle's direct `List<DiffLine>` approach was consistently top-ranked across non-owner reviews. PlanCodex54's two-layer fix (diff engine + ingestion hardening) also placed high. External-dependency plans (deviation, diff_match_patch) and server-schema-change plans (patch/diff fields) were consistently ranked lowest and rejected. All six reviewers converged on custom LCS diff + fallback UI + no external dependency.
- **Self-bias adjustment**: planCodex54 ranked itself #2 (Codex55 #1); planCodex55 ranked itself #2 (Codex54 #1); planDeepSeek4Pro ranked itself #7; planGLM51 ranked itself #6; planPickle ranked itself #2 (DeepSeek4Pro #1); planQwen36Plus ranked itself #3 (Pickle #1). Self-rankings were excluded from cross-rater consensus calculations. Non-owner top-3 frequency was the primary signal: Pickle appeared in non-owner top-3 for 4 of 5 possible reviewers (strongest), Codex54 in 3 of 5, Codex55 in 3 of 5, Qwen36Plus in 2 of 5.

### Consensus Evidence Table

| Candidate | Exact failure-mode coverage | Implementation completeness | Validation of exact case | Risk/blocker handling | Dependency/API certainty | Full verdict | Critical objections |
|-----------|----------------------------|----------------------------|--------------------------|----------------------|--------------------------|--------------|---------------------|
| planCodex54 | pass — explicit fallback for empty before/after, prevents SSE overwrite | pass — LCS diff + merge guard + caching | pass — provider SSE + widget + integration tests | pass — addresses data-loss risk | pass — no new dependencies | full | None |
| planCodex55 | pass — explicit empty fallback, line normalization | pass — LCS diff builder + SSE unification | pass — multi-line, empty, add-only, delete-only | pass — large-file LCS noted | pass — no new dependencies | full | Minor: SSE unification is partially redundant (both paths already parse same fields) |
| planDeepSeek4Pro | pass — fallback widget with icon + stats | pass — DP-table LCS + large-file guard | pass — widget + unit tests | pass — explicit 4M-cell memory guard | pass — no new dependencies | full | None |
| planGLM51 | pass — covers snapshot-disabled, new, deleted | pass — Myers/LCS + edge cases | pass — widget + provider + mock server | pass — large-file risk noted | fail — hedges on diff_match_patch option | not full | Ambiguous dependency; optional package suggestion weakens certainty |
| planPickle | pass — both-empty handled with placeholder | pass — direct DiffLine output, ~60 lines | pass — widget tests for all edge cases | pass — O(n*m) memory noted | pass — no new dependencies | full | Minor: no large-file guard threshold specified |
| planQwen36Plus | pass — fallback indicator with stats | pass — LCS diff + comprehensive tests | pass — multi-line, empty, new, deleted | pass — large-file performance noted | pass — no new dependencies | full | Minor: no line-ending normalization, no SSE unification |
| planDeepSeek4Flash | pass — /dev/null headers for new/deleted | pass — Myers diff via deviation package | pass — widget + unit tests | pass — new/deleted/identical handled | fail — depends on deviation package without fallback | not full | Unnecessary dependency (deviation v0.1.0) for bounded problem |
| planQwen35Plus | pass — handles new/deleted/empty | pass — diff_match_patch library | pass — widget tests | pass — large-file noted | fail — heavy dependency for line-level diff, needs output wrapping | not full | Wrong tool (character-level lib for line-level task); dependency risk |
| planFlash | fail — assumes server has diff/patch field | not full — naive fallback left in place | not full — no tests for non-empty case | fail — speculative field assumption contradicts SDK | fail — depends on unverified field | not full | ADR-023 violation; assumes undocumented server field |
| planG31Pro | fail — same speculative diffText assumption | not full — entity bloat with unused field | not full — no real diff algorithm | fail — same as planFlash | fail — same field assumption | not full | Same ADR-023 violation as planFlash |
| planMimo25Pro | fail — removes before/after based on false claim | fail — breaks all existing data flow | fail — would regress working paths | fail — highest risk plan | fail — contradicts official SDK type | not full | Actively harmful; claims schema changed (false); would break backward compatibility |
| planMiniMax25 | fail — only handles empty case, not non-empty | fail — diagnostic + message only | fail — no diff algorithm test | fail — leaves core bug unfixed | pass — none | not full | Incomplete; even non-empty before/after would still show broken diff |
| planMiniMax27 | fail — diagnostic-first, no concrete fix | not full — heuristic approach without specificity | fail — instrumentation, not validation | fail — wastes time on known problem | pass — none | not full | Diagnostic-only; "heuristic detection" is too vague |
| planKimi26 | pass — LCS diff + edge cases | pass — dedicated diff_generator | pass — unit + widget tests | pass — large-file noted | pass — no new dependencies | full | Minor: new file unnecessary; could fit in existing diff_parser.dart |

### Vetoes, Blockers, and Overrides

- **Critical objections raised**: planMimo25Pro — claims server schema changed (contradicts official SDK); planFlash, planG31Pro — assume undocumented diff/patch field (ADR-023 violation). All three are rejected.
- **Resolved objections**: planGLM51's optional dependency ambiguity — resolved by not including it in synthesis; planDeepSeek4Flash's deviation dependency — replaced with custom LCS in synthesis; planQwen35Plus's diff_match_patch — replaced with custom LCS.
- **Unresolved objections**: None.
- **Consensus overrides**: None needed. The synthesized plan follows the clear consensus: custom LCS, direct DiffLine output, fallback UI, SSE merge guard, no external dependency.
- **Scoring/voting role**: Non-owner top-3 frequency, cross-rater rankings, and full/not-full judgments were used as advisory signals. The clear critical objections (schema-change plans) acted as unconditional vetoes. The synthesis direction was chosen by evidence convergence, not by counting first-place votes.

### Per-Planner Assessment

#### planCodex54
- **Strengths**: Most architecturally complete — ingestion hardening + diff engine + caching + comprehensive tests. Unique emphasis on SSE overwrite risk.
- **Weaknesses**: Caching is premature optimization; slightly less concrete on low-level builder details.
- **Unique insights**: SSE merge guard to prevent empty payloads from destroying REST-loaded data.

#### planCodex55
- **Strengths**: Clean diff builder, explicit empty-string handling, line-ending normalization, SSE unification.
- **Weaknesses**: SSE unification is partially redundant; new file for diff builder not strictly necessary.
- **Unique insights**: Explicit `''` → `[]` guard to prevent phantom empty lines.

#### planDeepSeek4Pro
- **Strengths**: Custom DP-table LCS, explicit large-file guard (4M cells), graceful fallback widget, ADR-023 verification.
- **Weaknesses**: Puts generation in diff_parser.dart which mixes concerns slightly; retains string round-trip.
- **Unique insights**: Large-file memory guard with degenerative fallback; styled fallback widget with icon.

#### planGLM51
- **Strengths**: Broad edge-case taxonomy, /dev/null headers for new/deleted files, mock server updates.
- **Weaknesses**: Hedges on dependency choice (custom or package); less focused; unnecessary mock server scope.
- **Unique insights**: /dev/null header convention for new and deleted files.

#### planPickle
- **Strengths**: Elegant — direct `List<DiffLine>` output eliminates string round-trip entirely. Minimal footprint (~60 lines). Keeps parseDiffLines intact for tool-parts.
- **Weaknesses**: Lacks large-file guard; no SSE unification; no explicit line-ending normalization.
- **Unique insights**: Direct output pattern — provably simpler with fewer failure modes.

#### planQwen36Plus
- **Strengths**: Clean LCS with hunk headers, 3-line context, comprehensive widget test matrix, fallback indicator with stats.
- **Weaknesses**: Retains string round-trip; lacks line-ending normalization and SSE unification.
- **Unique insights**: Fallback shows stats alongside message — most user-friendly empty state.

### Failed Agents (if any)

- **planGPToss**: Empty response on both attempts (first-round and retry).

### Why this synthesized plan is best

- Combines planPickle's direct `List<DiffLine>` output (cleanest architecture) with planDeepSeek4Pro's large-file guard and fallback widget, planCodex54's SSE merge guard, planCodex55's line-ending normalization, and planQwen36Plus's comprehensive test matrix.
- No external dependency — custom LCS ~80 lines in pure Dart avoids pubspec changes, version drift, and platform risk.
- Rejects speculative server-schema-change approaches that violate ADR-023.
- Handles the exact reported failure mode with both a proper diff engine AND a graceful fallback for the empty-content case.
- Defense-in-depth: SSE merge guard prevents silent data loss even though it's not the primary bug cause today.

### Best Individual Plan Verdict

- **Winner**: planPickle
- **Why**: The most architecturally elegant solution. Direct `List<DiffLine>` output eliminates an entire class of bugs by removing the `_buildUnifiedDiff` → `parseDiffLines` string round-trip. Strongest cross-rater consensus (non-owner top-3 in 4 of 5 reviews).
- **Trade-off notes**: planCodex54 has better ingestion hardening (SSE merge guard) and planDeepSeek4Pro has explicit large-file guards — both adopted into the synthesis. planPickle alone lacks these but forms the core architecture that everything else builds on.
- **Note**: Final synthesized plan combines planPickle's direct-output architecture + planDeepSeek4Pro's guards + planCodex54's SSE hardening + planCodex55's normalization.

### Final Ranking Rationale

**Position 1 — planPickle**: Highest non-owner top-3 frequency (4 of 5). Architecturally cleanest: direct `List<DiffLine>` eliminates round-trip. No dependency. Self-contained. Even reviewers who did not rank it #1 acknowledged its elegance. Weaknesses (no large-file guard, no SSE merge) are filled by synthesis.

**Position 2 — planCodex54**: Strong non-owner consensus (top-3 in 3 of 5). Most complete plan: ingestion, diff engine, caching, comprehensive tests. Unique SSE merge guard. Slightly over-scoped but defensively correct. Own plan ranked itself #2; non-owner consensus at #1-2 range confirms quality.

**Position 3 — planCodex55**: Clean diff builder, explicit edge handling, line normalization. Narrowly behind Codex54 on ingestion depth. Non-owner top-3 in 3 of 5 reviews.

**Position 4 — planQwen36Plus**: Solid LCS approach, best test matrix. Non-owner top-3 in 2 of 5. Lacks some refinements present in top 3 (line normalization, merge guard).

**Position 5 — planDeepSeek4Pro**: Strong technical plan with large-file guard and fallback widget. Non-owner top-3 in 2 of 5. Self-ranked conservatively (#7). Valuable guard adopted into synthesis.

**Position 6 — planKimi26**: Clean separation, good edge cases. Misses top-tier refinements. Non-owner ranked #4-#5 range. Full but less polished.

**Position 7 — planGLM51**: Broad coverage but hedges on implementation. Optional dependency ambiguity cost it full status. Non-owner ranked #5-#7.

**Position 8 — planDeepSeek4Flash**: Correct direction ruined by unnecessary dependency. Non-owner ranked #7-#8. Architecturally right, tool wrong.

**Position 9 — planQwen35Plus**: Same problem as #8 with more dependency complexity. Character-level library for line-level task.

**Position 10 — planMiniMax27**: Diagnostic, not a fix. Could support investigation but not standalone.

**Position 11 — planMiniMax25**: Only fixes empty case, leaves non-empty broken. Incomplete.

**Position 12 — planFlash**: Speculative field assumption violates ADR-023. Critical objection upheld.

**Position 13 — planG31Pro**: Same ADR-023 violation as #12. Speculative.

**Position 14 — planMimo25Pro**: Based on false factual claim. Would break existing data flow. Most dangerous plan.

### Plan Ranking (Best to Worst)

1. planPickle (full)
2. planCodex54 (full)
3. planCodex55 (full)
4. planQwen36Plus (full)
5. planDeepSeek4Pro (full)
6. planKimi26 (full)
7. planGLM51
8. planDeepSeek4Flash
9. planQwen35Plus
10. planMiniMax27
11. planMiniMax25
12. planFlash
13. planG31Pro
14. planMimo25Pro
