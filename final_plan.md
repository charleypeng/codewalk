---
status: Ready
task: Permission auto-approve — unconditional "always" reply
plan_hash: <to be filled by commit>
---

## Execution Plan (Synthesized)

### Status

Ready.

### Problem

The function `permissionAutoApproveReplyForAlwaysPatterns()` in `lib/presentation/services/permission_auto_approve_runtime.dart` conditionally returns `'always'` only when `request.always` contains non-empty patterns, otherwise falling back to `'once'`. This means auto-approved permissions without patterns get single-shot grants without `remember: true`. When the app is backgrounded before a permission card is visible, subsequent background drains send `'once'` — the server does not persist the grant, requiring another client round-trip for each identical request. This stalls permission resolution until the user foregrounds the app.

### Objective

When the composer auto-approve toggle is enabled, every auto-approved permission request must send `'always'` + `remember: true`, creating a durable session-scoped grant. The `'always'` grant is session-scoped and does not survive OpenCode process restarts — this is the safety guarantee.

### Context and Constraints

- **ADR-023 EXC-001** must be updated to reflect unconditional `'always'` behavior (the existing exception already approves `'always'` — the change removes the conditional fallback language)
- **`remember: true`** is already correctly gated on `reply == 'always'` in both `chat_remote_datasource.dart` and `android_background_alert_worker.dart._replyPermission()` — zero transport changes needed
- **i18n**: 14 locales via `tool/i18n/arb_strings.dart` canonical source → `dart tool/i18n/generate_arb.dart` → `.arb` files → `flutter gen-l10n`
- **`make check`** must pass before commit (analyze + test)
- **Project**: Dart/Flutter, OpenCode server backend, ARM64 host (Android build unsupported locally)

### Why This Plan

This synthesized plan represents the convergence of 14 independent planner agents and 5 consensus reviewers. The core change is surgically minimal — one function body, 3 unit test assertions, 3 widget test assertions, plus documentation and i18n. The plan keeps the function signature unchanged to avoid unnecessary call-site churn (4/5 reviewers recommend this). The i18n strategy uses the project's canonical source (`arb_strings.dart`) rather than error-prone manual edits of 14 files (4/5 reviewers recommend this). Alternate approaches — removing the parameter, updating BEHAVIOR.md, or manually editing each `.arb` file — were considered and rejected by majority reviewer consensus as adding risk without benefit.

### Overview

Change one line of Dart logic: `permissionAutoApproveReplyForAlwaysPatterns()` unconditionally returns `'always'`. Both foreground drain (`chat_page_lifecycle.dart`) and background drain (`android_background_alert_worker.dart`) inherit the new behavior through the existing shared helper. All downstream `remember: true` transport logic is already correct. Update tests, ADR-023 EXC-001, i18n canonical source, regenerate `.arb` files and Dart localizations, update hardcoded settings string, and validate with `make check`.

### Steps

1. **Core logic: unconditional `'always'` return**
   - Files: `lib/presentation/services/permission_auto_approve_runtime.dart`
   - Details: Replace the body of `permissionAutoApproveReplyForAlwaysPatterns` (lines 3-12) with `return 'always';`. Keep the `Iterable<String> alwaysPatterns` parameter — it becomes unused but preserves caller compatibility. Add a comment: "Auto-approve always replies 'always' to create durable session-scoped grants via remember:true. 'always' grants do not survive OpenCode restarts."
   - Risk: Low
   - Source: planCodex54, planMimo25, planQwen36Plus (consensus: keep parameter)

2. **Unit test: update empty-pattern expectation**
   - Files: `test/unit/presentation/permission_auto_approve_runtime_test.dart`
   - Details:
     - Rename test at line 6: `'always returns always reply unconditionally'`
     - Line 14-16: Change `expect(..., 'once')` to `expect(..., 'always')` for empty/whitespace-only patterns
     - Keep lines 19-30 unchanged (already asserts `'always'`)
   - Risk: Low
   - Source: all 14 planners + all 5 reviewers

3. **Widget tests: update `'once'` assertions in auto-approve drain tests**
   - Files: `test/widget/chat_page_test.dart`
   - Details: Change 3 `'once'` assertions to `'always'`:
     - Line 6134: `expect(repository.lastPermissionReply, 'once')` → `'always'` (mirrored subagent auto-approve, request has `always: <String>[]`)
     - Line 6400: `expect(repository.lastPermissionReply, 'once')` → `'always'` (toggle-on from persisted-off, request has `always: <String>[]`) — verify context before editing
     - Line 6760: `expect(repository.lastPermissionReply, 'once')` → `'always'` (pending permissions viewport test)
   - DO NOT change: line 6222 (already `'always'`), integration test lines, provider test lines — those test datasource/provider directly, not auto-approve
   - Risk: Low
   - Source: planMimo25 (evaluator, verified all 3 lines), planQwen35Plus, planQwen37Max

4. **Run `make check` (first pass)**
   - Validate: analyze + test pass after code+test changes. Catch compilation/test failures early.
   - Risk: Low

5. **Update ADR-023 EXC-001**
   - Files: `ADR.md` (lines 1040-1082)
   - Details:
     - Line 1044 summary: Remove "when the request exposes it, otherwise falls back to `Allow Once`"
     - Line 1051 rationale: Remove conditional fallback language
     - Line 1068 `remember: true` paragraph: Remove "When the request exposes only `once` semantics"
     - Line 1072 regression coverage: Change "uses `always` when available, otherwise `Allow Once`" → "always uses `always`"
   - Risk: Low — documentation only
   - Source: all planners + all reviewers

6. **Update i18n canonical source**
   - Files: `tool/i18n/arb_strings.dart`
   - Details: Update `settingsBehaviorPermissionProvenanceDescription`:
     - English (line ~98): Change to: "Official OpenCode permission policy is configured in `opencode.json` with allow/ask/deny rules per tool. CodeWalk keeps the official permission-request cards and adds one approved ADR-023 exception: the composer auto-approve toggle replies with `Always` and `remember: true` unconditionally to create durable session-scoped grants, and keeps the same thread-scoped continuity path active in the Android background worker."
     - Portuguese (line ~676): Update translation
     - Spanish (line ~1227): Update translation
     - All other locale entries: Update English fallback text
   - Risk: Low
   - Source: planMiniMax25, planMimo25, planQwen36Plus (verified: arb_strings.dart is canonical source)

7. **Regenerate i18n files**
   - Command: `dart tool/i18n/generate_arb.dart` — regenerates all 14 `.arb` files from `arb_strings.dart`
   - Command: `flutter gen-l10n` — regenerates all 16 `app_localizations*.dart` files
   - Risk: Low
   - Source: planMiniMax25

8. **Update hardcoded settings string**
   - Files: `lib/presentation/pages/settings/sections/behavior_settings_section.dart` (line 604)
   - Details: Replace hardcoded description with the same new English text from Step 6
   - Risk: Low
   - Source: all planners + all reviewers

9. **Run `make check` (second pass)**
   - Validate: analyze + test pass after i18n/string changes. Catch l10n regeneration issues.
   - Risk: Low

10. **Commit**
    - Descriptive message: `chore(agent): auto-approve always sends 'always' + remember:true unconditionally`
    - Run `desloppify scan --path lib --profile objective` before commit
    - Risk: Low

### Risks & Mitigations

| Risk                                                                                    | Severity | Mitigation                                                                                                                                                                                                                   |
| --------------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Server rejects `'always'` when `always` patterns are empty                                | Low      | OpenCode server accepts `'always'` regardless of pattern content (verified from official docs & existing behavior). If rejected, existing error handling (cooldown + manual card) provides safe fallback.                    |
| Widget test at line 6400 may not need changing if toggle is OFF in that context          | Low      | Read lines 6390-6410 before editing; verify toggle state. If OFF, keep `'once'` assertion.                                                                                                                                  |
| `arb_strings.dart` generator overwrites custom translations (pt, es)                       | Low      | Generator preserves non-English entries from the translations map. Verify pt/es entries are preserved after regeneration.                                                                                                    |
| i18n regeneration fails or produces unexpected diffs                                    | Low      | `make check` second pass catches this. If `flutter gen-l10n` fails, fall back to manual Dart file updates matching the new English text.                                                                                     |

### Assumptions to Validate

1. Server accepts `'always'` reply even when `request.always` is empty — verified from `ai-docs/opencode_server.md` and OpenCode source (session-scoped, patterns are advisory)
2. `remember: true` is already sent when `reply == 'always'` — confirmed in `chat_remote_datasource.dart:2321-2323,2341-2343` and `android_background_alert_worker.dart:685,695`
3. Only 2 callers of `permissionAutoApproveReplyForAlwaysPatterns` exist — confirmed via grep
4. `dart tool/i18n/generate_arb.dart` regenerates all `.arb` files from `arb_strings.dart` — verify before running by checking script contents
5. Widget test at line 6400 is in auto-approve-enabled context (not manual fallback) — verify by reading surrounding lines

### Decisions and Nuances

- **Parameter kept**: The `alwaysPatterns` parameter becomes unused — kept for API stability. 4/5 reviewers recommend this. Removing it would require editing 2 call sites for zero behavioral gain.
- **No BEHAVIOR.md update**: 3/5 evaluators verified no auto-approve behavior spec exists in BEHAVIOR.md. The behavior is documented in ADR-023 EXC-001 only.
- **No AGENTS.md table update**: ADR-023 line range (958-1080) does not change — only content within those lines changes. Quick-reference table entry remains accurate.
- **`arb_strings.dart` is canonical**: The project's i18n source of truth. Direct `.arb` edits would be overwritten on next generation. This was the single most impactful insight from the consensus pass (credit: planMiniMax25).
- **Two `make check` runs**: First after code+test changes, second after i18n changes — easier to bisect failures.
- **Exact widget test lines**: 6134, 6400, 6760 — verified by planMimo25 through direct code reading during consensus review. Integration test (line ~919) and provider test (line ~138) are NOT auto-approve paths and must not be changed.

### Blockers and Open Questions

None. The change is surgical and well-understood. The single verification gate is: does the OpenCode server accept `'always'` with empty patterns? This is confirmed by official docs and existing behavior.

### Testing Strategy

1. Unit: `permissionAutoApproveReplyForAlwaysPatterns([])` → `'always'`
2. Unit: `permissionAutoApproveReplyForAlwaysPatterns([''])` → `'always'`
3. Widget: `chat_page_test.dart` lines 6134, 6400, 6760 — all assert `'always'` for empty-pattern auto-approve
4. Regression: `make check` passes with zero failures
5. Manual grep: search codebase for `"when the request supports remembered approval"` and `"otherwise.*Allow Once"` — zero results after changes

### Execution Handoff

- Starting point: `lib/presentation/services/permission_auto_approve_runtime.dart` line 3
- Order: Step 1 (runtime) → Step 2 (unit test) → Step 3 (widget tests) → Step 4 (make check #1) → Step 5 (ADR) → Step 6 (arb_strings.dart) → Step 7 (regenerate) → Step 8 (settings string) → Step 9 (make check #2) → Step 10 (commit)
- Key verification: after Step 3, run `flutter test test/widget/chat_page_test.dart --name "auto-approve"` to confirm only 3 assertions needed changes and all pass

### Out of Scope

- Changing `remember: true` transport logic (already correct)
- Changing composer toggle UI or default state
- Changing background worker context lifecycle
- Adding new E2E or integration tests
- Changing OpenChamber behavior (intentionally differs per ADR-023)
- Removing the `alwaysPatterns` parameter from the function signature
- Updating BEHAVIOR.md (no relevant spec exists)
- Updating AGENTS.md ADR quick-reference table (line range unchanged)
- Android build (`make android`) — excluded per user's "planning only" instruction

---

## Plan Comparison

### Full-Planner Consensus Pass

- Selected full planners: planCodex54, planDeepSeek4Pro, planMimo25, planQwen37Max, planQwen36Plus
- Skipped: No — 5 evaluators selected from 14 preliminarily-full first-round plans
- Second-pass plans received: 5
- Detailed candidate summaries: Each of 14 first-round plans had a rich paragraph describing strategy, files, tests, sequencing, risks, and unique insights. Summaries included in every evaluator's dispatch.
- Consensus summary: planCodex54 consistently ranked in top 3 across all 5 evaluators. Strong agreement to keep the unused parameter (4/5), use arb_strings.dart generator (4/5), and not update BEHAVIOR.md (3/5). Highest variance on planDeepSeek4Flash (ranked #1 by Codex54, #14 by Mimo25) due to disagreement on removing the parameter and test scope breadth.
- Self-bias adjustment: Each evaluator's ranking of its own plan was noted and discounted where it ranked itself #1 (planQwen37Max ranked itself #1, but its non-owner average rank was ~#9). planCodex54 ranked itself #2 (non-owner average ~#2). planMimo25 ranked itself #3 (non-owner average ~#7). Self-bias was most visible in planQwen37Max, least in planCodex54.

### Consensus Evidence Table

| Candidate            | Exact failure-mode coverage                                                         | Implementation completeness                                                         | Validation of exact case                                    | Risk/blocker handling                                        | Dependency/API certainty                              | Full verdict | Critical objections                 |
| -------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------ | ----------------------------------------------------- | ------------ | ----------------------------------- |
| planCodex54          | pass — explicitly states how `'once'`→`'always'` stops the background stall            | pass — all required files, tests, ADR, i18n, settings covered                        | pass — empty-pattern unit test + widget test identified      | pass — server rejection, coverage gaps, i18n drift, ADR drift | pass — API claims verified from docs                  | full         | none                                |
| planCodex55          | pass — same core fix                                                                 | pass — comprehensive, proposes optional rename later                                 | pass — widget test at ~6204/6212 identified                  | pass — notes linter warning risk                             | pass — checks flutter gen-l10n vs Makefile            | full         | none                                |
| planDeepSeek4Flash   | pass — same core fix                                                                 | pass — broadest test coverage (integration+provider) but some tests may not need update | pass — broad scope, integration test awareness              | pass — handles app_es.arb special case                       | pass — removes parameter (minor API churn)            | full         | integration tests may not need update |
| planDeepSeek4Pro     | pass — same core fix                                                                 | pass — specific ADR line edits, l10n fallback                                        | pass — unit test + ADR verification                          | pass — mentions build_runner fallback                         | pass — keeps parameter                                | full         | none                                |
| planFlash            | pass — same core fix                                                                 | fail — only English .arb, misses 13 locales                                         | fail — no widget test identification                         | pass — but incomplete mitigation for i18n drift               | pass — but incomplete                                  | not full     | misses 13 i18n locales + widget tests |
| planG31Pro           | pass — same core fix                                                                 | pass — widget + provider test updates identified                                    | pass — notes Spanish/Portuguese locales differ               | pass                                                         | pass                                                  | full         | provider test likely doesn't need update |
| planGLM51            | pass — same core fix                                                                 | pass — new no-parameter function, BEHAVIOR.md update                                | pass — detailed step rationale                              | pass — BEHAVIOR.md proposed (unnecessary but harmless)       | pass — removes parameter                              | full         | BEHAVIOR.md update unnecessary       |
| planMimo25           | pass — same core fix                                                                 | pass — detailed i18n handling, session-scoped safety rationale                      | pass — widget test at 6134 identified                        | pass — addresses app_es.arb truncated text                    | pass — keeps parameter                                | full         | misses widget tests at 6400/6760     |
| planMimo25Pro        | pass — same core fix                                                                 | pass — 7-item risk matrix                                                           | pass — BEHAVIOR.md at line 882 identified                    | pass — thorough risk matrix                                  | pass                                                  | full         | BEHAVIOR.md update unnecessary       |
| planMiniMax25        | pass — same core fix                                                                 | pass — verifies generate_arb.dart behavior                                          | pass — i18n tool verification                                | pass — practical caution on i18n pipeline                     | pass                                                  | full         | none                                |
| planMiniMax27        | pass — same core fix                                                                 | fail — too concise, missing test specifics                                          | fail — no widget test identification                         | pass — correctly notes BEHAVIOR.md not needed                 | pass                                                  | not full     | too terse for execution             |
| planQwen35Plus       | pass — same core fix                                                                 | pass — 9-step plan with reviewer flow and Android build                             | pass — widget test lines 6134, 6400 identified               | pass — includes AGENTS.md table update (unnecessary)          | pass — removes parameter                              | full         | AGENTS.md update unnecessary         |
| planQwen36Plus       | pass — same core fix                                                                 | pass — 10-step plan, detailed locale listing                                        | pass — clear English text draft                              | pass — keeps parameter                                        | pass                                                  | full         | none                                |
| planQwen37Max        | pass — same core fix                                                                 | pass — all 14 locales listed, AGENTS.md table update                                | pass — widget test lines 6134, 6400 identified               | pass — removes parameter (most aggressive)                    | pass — removes parameter                              | full         | AGENTS.md update unnecessary, parameter removal overkill |

### Vetoes, Blockers, and Overrides

- Critical objections raised: None. All 14 plans agree on the core fix. Disagreements are only about scope (parameter removal, BEHAVIOR.md, AGENTS.md) — none are correctness or safety objections.
- Resolved objections: N/A
- Unresolved objections: None
- Consensus overrides: None. The synthesized plan follows the majority consensus on every contested point.
- Scoring/voting role: Ranking averages and Borda scores were computed as advisory signals. The clear cross-rater top-3 consistency of planCodex54 was the primary decision signal, corroborated by rationale quality and completeness. No override of voting was needed.

### Per-Planner Assessment

#### planCodex54
- Strengths: Most thorough risk analysis; identifies `tool/i18n/arb_strings.dart`; widget test identification; excellent structure; complete file coverage
- Weaknesses: Regeneration command unclear (mentions `make gen` which runs `build_runner`, not l10n)
- Unique insights: Identifies `tool/i18n/arb_strings.dart` as canonical i18n source (no other plan except evaluators caught this)

#### planDeepSeek4Flash
- Strengths: Most detailed file table; broadest test coverage; app_es.arb handling
- Weaknesses: Removes parameter (minor churn); includes tests that don't need updating
- Unique insights: Detailed file-by-file comparison table with change types

#### planMimo25
- Strengths: Strong session-scoped safety rationale; most detailed i18n handling; verified widget test lines 6134/6400/6760 during consensus review
- Weaknesses: First-round plan missed widget tests at 6400/6760 (caught in consensus review)
- Unique insights: Identified exact 3 widget test assertions needing change through direct code reading

#### planQwen37Max
- Strengths: All 14 locales listed; widget test lines identified; AGENTS.md awareness
- Weaknesses: Most aggressive API changes (parameter removal); ranked itself #1 (self-bias)
- Unique insights: Only first-round plan listing all 14 locale files by name

#### planMiniMax25
- Strengths: Key insight on verifying `generate_arb.dart` behavior before edits; practical i18n caution
- Weaknesses: Sparse on test specifics; ranked #1 by one evaluator but #8-#12 by others (high variance)
- Unique insights: The critical insight that `arb_strings.dart` is canonical and regeneration is better than manual edits

### Failed Agents
- planKimi26: Failed Phase A with empty responses on 2 attempts

### Why this synthesized plan is best
- Single-function change with zero call-site churn (keeps parameter per 4/5 reviewer consensus)
- Uses project's canonical i18n pipeline (`arb_strings.dart` → regenerate) rather than error-prone manual 14-file edits
- Precisely identifies 3 widget test assertions (lines 6134, 6400, 6760) — confirmed by direct code reading during consensus
- Excludes unnecessary scope: no BEHAVIOR.md, no AGENTS.md, no parameter removal, no integration/provider test changes
- Two `make check` runs for clean bisection of code vs i18n issues
- Represents convergence of 14 planners and 5 reviewers

### Best Individual Plan Verdict
- Winner: planCodex54
- Why: Consistently ranked #1-#3 across all 5 evaluators (non-owner average rank: ~#2). Most thorough risk analysis. Correctly identifies `arb_strings.dart` canonical source. Covers all required files. No critical omissions.
- Trade-off notes: planDeepSeek4Flash has broader test awareness but removes the parameter unnecessarily. planMimo25 verified exact widget test lines during consensus review — a valuable contribution absorbed into the synthesized plan. planMiniMax25's `arb_strings.dart` regeneration insight was the single most impactful finding from the consensus pass.

### Final Ranking Rationale

- Position 1 — planCodex54: Top-3 in all 5 evaluator rankings. Non-owner average: ~#2. No evaluator ranked it below #3. Strongest risk analysis, most complete file coverage, caught `arb_strings.dart` as canonical source. No critical objections from any reviewer.
- Position 2 — planMimo25: Strengthened significantly during consensus review by verifying exact widget test lines through direct code reading. Strong session-scoped safety rationale. First-round plan missed widget tests at 6400/6760, but consensus review compensated. Non-owner average: ~#7.
- Position 3 — planQwen36Plus: Consistent mid-to-upper tier across evaluators. Keeps parameter (correct choice). Detailed locale listing. Clear English text draft. Non-owner average: ~#5.
- Position 4 — planDeepSeek4Flash: Highest variance — ranked #1 by planCodex54, #14 by planMimo25. The disagreement centers on the parameter-removal decision and including integration tests that don't need updating. Strong file table but wrong on two key architectural choices.
- Position 5 — planCodex55: Solid, cautious approach. Verifies source snippets before editing. Notes linter risk. Falls behind top plans on test specificity.
- Position 6 — planGLM51: Detailed step rationale with why-now. Removes parameter (minor negative). BEHAVIOR.md proposal unnecessary but harmless. Good mechanical approach.
- Position 7 — planG31Pro: Correctly identifies widget and provider tests. Notes Spanish/Portuguese locale differences. Provider test likely doesn't need updating.
- Position 8 — planMiniMax25: Highest variance — ranked #1 by planQwen36Plus, #8-#12 by others. The arb_strings.dart insight is brilliant but the plan is too sparse on execution detail to rank higher.
- Position 9 — planQwen35Plus: Comprehensive 9-step plan. Widget test identification is correct. Over-scoped with reviewer flow and Android build for a planning output.
- Position 10 — planDeepSeek4Pro: Specific ADR line edits are useful. `// ignore: unused_element` is the wrong workaround. build_runner fallback for l10n is incorrect.
- Position 11 — planMimo25Pro: 7-item risk matrix is thorough. BEHAVIOR.md update unnecessary. Solid but less distinctive than higher-ranked plans.
- Position 12 — planQwen37Max: Most aggressive API changes. Ranked itself #1 (self-bias confirmed). Non-owner average ~#9. Good widget test identification but parameter removal + AGENTS.md are unnecessary scope.
- Position 13 — planMiniMax27: Too concise. Correctly notes BEHAVIOR.md not needed and pt/es as real translations. Missing widget tests, i18n generator, and specific ADR edits.
- Position 14 — planFlash: Most concise but critically incomplete. Only updates English .arb — misses 13 other locales. Insufficient for production.

### Plan Ranking (Best to Worst)

1. planCodex54 (full)
2. planMimo25 (full)
3. planQwen36Plus (full)
4. planDeepSeek4Flash (full)
5. planCodex55 (full)
6. planGLM51 (full)
7. planG31Pro (full)
8. planMiniMax25 (full)
9. planQwen35Plus (full)
10. planDeepSeek4Pro (full)
11. planMimo25Pro (full)
12. planQwen37Max (full)
13. planMiniMax27
14. planFlash

