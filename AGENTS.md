# CodeWalk - Project-Specific Rules

> ⚠️ **Base**: All rules from the main `/AGENTS.md` apply. This file contains only CodeWalk-specific items. In case on conflict, this file is priority.

## Project Context

CodeWalk is a project that provides access to code agents from anywhere — desktop or mobile.

- **Every implementation must be designed for both mobile and desktop**. Preferably unified and responsive. **Priority: mobile UX, modern look, Material You**.
- After completing a change, verify whether it requires new tests or updates to existing tests.
- For visual adjustments, confirm with the user the exact block/screen referenced before changing; avoid assumptions.
- **Every completed work step MUST have a very descriptive commit message** so the change is easy to track, audit, and revert without guessing. If the user already authorized the work itself, create that commit automatically without waiting for an extra confirmation.

- In this project specifically, we do NOT use `make precommit` directly — prefer splitting into `make check` and `make android`.
- Key base documentation is in ./ai-docs; always run at least one `ls` in that folder to know what exists.
- `BEHAVIOR.md` MUST be read before creating any execution plan.

## 🛡 Supreme Rule: ADR-023 Compliance First

This rule is **supreme** for any app behavior change and overrides conflicting local guidance.

- Any behavior modification must first verify alignment with **ADR-023** and official OpenCode references (docs and source), using `ai-docs/opencode_server.md`, `ai-docs/opencode_web.md`, and `ai-docs/opencode_models.md` as mandatory local anchors.
- If full alignment is not possible, the change is blocked unless there is an explicit ADR exception with rationale, risk analysis, rollback/feature-flag plan, and regression tests.
- Every behavior change must prove non-regression: it must not introduce regressions in the modified flow or in related core flows of the app.

## 📐 ADR Quick Reference (details in `ADR.md`)

> **Mandatory sync**: When creating, updating, or superseding an ADR, the adrkeeper/`adr` skill MUST update this table (description + line ranges). Superseded ADRs get the prefix "⚠️ SUPERSEDED —".

| ADR | What / Why | Lines |
|-----|------------|-------|
| 001 | Multi-server with profiles, scoped persistence, and secure credentials — prevent cross-server leakage | 35–69 |
| 002 | Context isolation `serverId::directory` with serialized transition queue — prevent race conditions on project switch | 70–107 |
| 003 | Realtime-first sync with degraded fallback and platform-aware background policy — maintain live UX without losing offline data | 108–156 |
| 004 | Chat with slim orchestrators and decomposed part-file clusters — maintainability on high-change surfaces | 157–192 |
| 005 | Composer pipeline for multimodal input, triggers (`@!/`) and send/stop — rich composition without breaking flow | 193–229 |
| 006 | Speech input with `SpeechInputService`, Sherpa (Linux) and native STT (Android) — pluggable by platform | 230–267 |
| 007 | Modular settings with typed `SettingsProvider` + `ExperienceSettings` — unified persistence desktop/mobile | 268–304 |
| 008 | Context-scoped file explorer with quick-open and diff-aware refresh — fast navigation without unnecessary reloads | 305–340 |
| 009 | Title generation via internal `title` agent — eliminate external dependency for session titles | 341–374 |
| 010 | Split CI pipeline: quality on push, release on tag, smoke on minor-tag — fast feedback without expensive builds | 375–410 |
| 011 | Unified server setup wizard (onboarding + settings) — guide new users and consolidate setup flow | 411–449 |
| 012 | Migration to Material Symbols via `material_symbols_icons` — broader icon coverage aligned with MD3 | 450–484 |
| 013 | MD3 `WindowSizeClass` with 5 breakpoint tiers — consistent responsive layout without magic numbers | 485–528 |
| 014 | Centralized design tokens (`AppShapes` + `BrandColor`) — MD3 shape scale and fallback colors without scattered hex values | 529–574 |
| 015 | Platform-specific icon pipeline (tray, notification, macOS) via `make icons` — reproducible assets per target | 575–618 |
| 016 | Hybrid file-backed cache for large chat payloads — eliminate SharedPreferences size limits | 619–655 |
| 017 | Android foreground service with `START_STICKY` — reliable monitoring that survives process death | 656–692 |
| 018 | Dedicated Dio instance for SSE with isolated connection pool — prevent stream eviction by regular HTTP requests | 693–744 |
| 019 | Defer `PATCH /config` during active server processing — prevent false abort from `Instance.dispose()` on server | 745–789 |
| 020 | Session-level SWR cache with persisted LRU snapshots — instant reopen of long sessions with background revalidation | 790–849 |
| 021 | Context-scoped New Chat draft state — prevent cross-project draft leakage during fast SWR switches | 850–893 |
| 022 | Unified project context controls with sidebar session previews — integrated navigation while preserving `serverId::scopeId` ownership | 894–934 |
| 023 | Official OpenCode contract-first compatibility policy — prevent regressions from lifecycle/API semantic drift across app vs server/CLI/web | 935–1011 |

## 🗺 CODEBASE Quick Reference (details in `CODEBASE.md`)

> **Mandatory sync**: When sections are added/removed/renamed in `CODEBASE.md`, update this table in the same change (title + line ranges).

| CODEBASE Topic | Lines |
|----------------|-------|
| Project Snapshot | 3–11 |
| Folder Structure | 12–48 |
| Entry Points | 49–59 |
| Core Modules | 60–102 |
| Chat Architecture | 103–174 |
| Data & Domain Layers | 176–187 |
| Key API/DataSource locations | 188–207 |
| Main Commands | 208–228 |
| Testing/Quality Gates | 229–250 |
| Notes | 251–358 |

## ⚙️ Makefile Quick Reference (details in `Makefile`)

> **Mandatory sync**: When `Makefile` targets are added/removed/renamed/reordered, update this table in the same change (topic + line ranges).

| Makefile Topic | Lines |
|----------------|-------|
| Help and command index (`help`) | 20–46 |
| Dependencies and codegen (`deps`, `gen`) | 47–55 |
| Tray template preparation (`tray-prepare`) | 56–68 |
| Platform tray icons (`icons-tray`) | 69–91 |
| App icon generation (`icons-app`) | 92–136 |
| Icon validation checks (`icons-check`) | 137–208 |
| Analyze and test flows (`analyze`, `test*`, `coverage`, `smoke`) | 209–248 |
| Desktop build and delivery (`desktop`) | 249–267 |
| Android build and Telegram upload (`android`) | 268–302 |
| Release/version flow (`release`) | 303–326 |
| Cleanup (`clean`) | 327–329 |

## 📌 Line-Scoped Read Policy (`ADR.md`, `CODEBASE.md`, and `Makefile`)

- For requests tied to architecture, code map, or build-command topics, use the quick-reference tables in this file first and read only the mapped line range(s) from `ADR.md`, `CODEBASE.md`, or `Makefile`.
- If multiple topics are needed, read only the union of the relevant ranges instead of scanning full files.
- Only read full `ADR.md`, `CODEBASE.md`, or `Makefile` when the requested subject is missing from the tables or the line map is known to be stale.
- Any edit to `ADR.md`, `CODEBASE.md`, or `Makefile` MUST include a same-task sync in `AGENTS.md` to keep topic titles and line ranges accurate.

## 🚀 Project-Specific Flow: Android Build for Testing

- **After completing code changes**: Run `make check` **immediately** (preferably background and async).
- **Critical order**: `make check` must run right after code completion, BEFORE changing .md files or committing.
- **If only static files changed (.md, text)**: `make check` and `make android` are not required.
- **Once the user can test**: Run `make android` as soon as possible — it compiles and sends the APK to Telegram. Run after every task involving code. Preferably background and async.
- **Before commit**: If no code changed since the last check, another `make check` is not needed.

### Mandatory flow when explicitly requested by the user OR the user just say "flow"

- When the user explicitly asks, follow this order without skipping steps:
  1. implement the change;
  2. run `make check`;
  3. commit;
  4. call reviewer for the commit;
  5. apply only accepted fixes and repeat reviewer in a loop until no remaining corrections the agent agrees with;
  6. run `HEY_CAPTION="..." make android`;
  7. only then notify the user and send the final report;
  8. suggest the next task (preferably from the current roadmap).
- Avoid intermediate "done" notifications before step 6 is complete.

### Dynamic Caption on Upload

- Always use `HEY_CAPTION="My custom caption" make android`
- **Avoid**: "Latest adjustments made"
- **Prefer**: "Fixed height of Thinking Process box"

## 📦 New Tag / Release

- **Use `make release V=<type>`** for new versions:
  - `make release V=patch` — bump patch (e.g. 1.5.4 → 1.5.5)
  - `make release V=minor` — bump minor (e.g. 1.5.4 → 1.6.0)
  - `make release V=major` — bump major (e.g. 1.5.4 → 2.0.0)
- The command updates `pubspec.yaml` (version + build number), commits, creates tag, and pushes automatically.
- **Before running**: ensure all code changes are committed. `make release` only commits the version bump.
- After push/tag, watch the `@.github/workflows/release.yml` pipeline every 60s and update the user at each status. If background/async is not supported, use sleep command.
- If any step fails, cancel the pipeline entirely, analyze errors, and decide between:
  - fix and repeat the flow;
  - notify the user and wait for instructions.
- If everything passed correctly, review CODEBASE.md and ADR.md for updates required by recent commits.

<!-- desloppify-begin -->
<!-- desloppify-skill-version: 1 -->
---
name: desloppify
description: >
  Codebase health scanner and technical debt tracker. Use when the user asks
  about code quality, technical debt, dead code, large files, god classes,
  duplicate functions, code smells, naming issues, import cycles, or coupling
  problems. Also use when asked for a health score, what to fix next, or to
  create a cleanup plan. Supports 28 languages.
allowed-tools: Bash(desloppify *)
---

# Desloppify

## 1. Your Job

**Improve code quality by fixing findings and maximizing strict score honestly.**
Never hide debt with suppression patterns just to improve lenient score. After
every scan, show the user ALL scores:

| What | How |
|------|-----|
| Overall health | lenient + strict |
| 5 mechanical dimensions | File health, Code quality, Duplication, Test health, Security |
| 7 subjective dimensions | Naming Quality, Error Consistency, Abstraction Fit, Logic Clarity, AI Generated Debt, Type Safety, Contract Coherence |

Never skip scores. The user tracks progress through them.

## 2. Core Loop

```
scan → follow the tool's strategy → fix or wontfix → rescan
```

1. `desloppify scan --path .` — the scan output ends with **INSTRUCTIONS FOR AGENTS**. Follow them. Don't substitute your own analysis.
2. Fix the issue the tool recommends.
3. `desloppify resolve fixed "<id>"` — or if it's intentional/acceptable:
   `desloppify resolve wontfix "<id>" --note "reason why"`
4. Rescan to verify.

**Wontfix is not free.** It lowers the strict score. The gap between lenient and strict IS wontfix debt. Call it out when:
- Wontfix count is growing — challenge whether past decisions still hold
- A dimension is stuck 3+ scans — suggest a different approach
- Auto-fixers exist for open findings — ask why they haven't been run

## 3. Commands

```bash
desloppify scan --path src/               # full scan
desloppify scan --path src/ --reset-subjective  # reset subjective baseline to 0, then scan
desloppify next --count 5                  # top priorities
desloppify show <pattern>                  # filter by file/detector/ID
desloppify plan                            # prioritized plan
desloppify fix <fixer> --dry-run           # auto-fix (dry-run first!)
desloppify move <src> <dst> --dry-run      # move + update imports
desloppify resolve open|fixed|wontfix|false_positive "<pat>"   # classify/reopen findings
desloppify review --run-batches --runner codex --parallel --scan-after-import  # preferred blind review path
desloppify review --run-batches --runner codex --parallel --scan-after-import --retrospective  # include historical issue context for root-cause loop
desloppify review --prepare                # generate subjective review data (cloud/manual path)
desloppify review --external-start --external-runner claude  # recommended cloud durable path
desloppify review --external-submit --session-id <id> --import review_result.json  # submit cloud session output with canonical provenance
desloppify review --import file.json       # import review results
desloppify review --validate-import file.json  # validate payload/mode without mutating state
```

## 4. Subjective Reviews (biggest score lever)

Score = 40% mechanical + 60% subjective. Subjective starts at 0% until reviewed.

1. Preferred local path: `desloppify review --run-batches --runner codex --parallel --scan-after-import`.
   This prepares blind packets, runs isolated subagent batches, merges, imports, and rescans in one flow.

2. **Review each dimension independently.** For best results, review dimensions in
   isolation so scores don't bleed across concerns. If your agent supports parallel
   execution, use it — your agent-specific overlay (appended below, if installed)
   has the optimal approach. Each reviewer needs:
   - The codebase path and the dimensions to score
   - What each dimension means (from `query.json`'s `dimension_prompts`)
   - The output format (below)
   - Nothing else — let them decide what to read and how

3. Cloud/manual path: run `desloppify review --prepare`, perform isolated reviews,
   merge assessments (average scores if multiple reviewers cover the same dimension)
   and findings, then import:
   ```bash
   desloppify review --import findings.json
   ```
   Import is fail-closed by default: if any finding is invalid/skipped, import aborts.
   Use `--allow-partial` only for explicit exceptions.
   External imports ingest findings by default. For durable cloud-subagent scores,
   prefer the session flow:
   `desloppify review --external-start --external-runner claude` then use the generated
   `claude_launch_prompt.md` + `review_result.template.json`, and run the printed
   `desloppify review --external-submit --session-id <id> --import <file>` command.
   Legacy durable import remains available via
   `--attested-external --attest "I validated this review was completed without awareness of overall score and is unbiased."`
   (with valid blind packet provenance in the payload).
   Use `desloppify review --validate-import findings.json ...` to preflight schema
   and import mode before mutating state.
   Manual override cannot be combined with `--allow-partial`, and those manual
   assessment scores are provisional: they expire on the next `scan` unless
   replaced by trusted internal or attested-external imports.

   Required output format per reviewer:
   ```json
   {
     "session": { "id": "<session_id_from_template>", "token": "<session_token_from_template>" },
     "assessments": { "naming_quality": 75.0, "logic_clarity": 82.0 },
     "findings": [{
       "dimension": "naming_quality",
       "identifier": "short_id",
       "summary": "one line",
       "related_files": ["path/to/file.py"],
       "evidence": ["specific observation"],
       "suggestion": "concrete action",
       "confidence": "high|medium|low"
     }]
   }
   ```
   For non-session legacy imports (`review --import ... --attested-external`), `session` may be omitted.

4. **Fix findings via the core loop.** After importing, findings become tracked state
   entries. Fix each one in code, then resolve:
   ```bash
   desloppify issues                    # see the work queue
   # ... fix the code ...
   desloppify resolve fixed "<id>"      # mark as fixed
   desloppify scan --path .             # verify
   ```

**Do NOT fix findings before importing.** Import creates tracked state entries that
let desloppify correlate fixes to findings, track resolution history, and verify fixes
on rescan. If you fix code first and then import, the findings arrive as orphan issues
with no connection to the work already done.

Need a clean subjective rerun from zero? Run `desloppify scan --path src/ --reset-subjective` before preparing/importing fresh review data.

Even moderate scores (60-80) dramatically improve overall health.

Integrity safeguard:
- If one subjective dimension lands exactly on the strict target, the scanner warns and asks for re-review.
- If two or more subjective dimensions land on the strict target in the same scan, those dimensions are auto-reset to 0 for that scan and must be re-reviewed/imported.
- Reviewers should score from evidence only (not from target-seeking).

## 5. Quick Reference

- **Tiers**: T1 auto-fix, T2 quick manual, T3 judgment call, T4 major refactor
- **Zones**: production/script (scored), test/config/generated/vendor (not scored). Fix with `zone set`.
- **Auto-fixers** (TS only): `unused-imports`, `unused-vars`, `debug-logs`, `dead-exports`, etc.
- **query.json**: After any command, has `narrative.actions` with prioritized next steps.
- `--skip-slow` skips duplicate detection for faster iteration.
- `--lang python`, `--lang typescript`, or `--lang csharp` to force language.
- C# defaults to `--profile objective`; use `--profile full` to include subjective review.
- Score can temporarily drop after fixes (cascade effects are normal).

## 6. Escalate Tool Issues Upstream

When desloppify itself appears wrong or inconsistent:

1. Capture a minimal repro (`command`, `path`, `expected`, `actual`).
2. Open a GitHub issue in `peteromallet/desloppify`.
3. If you can fix it safely, open a PR linked to that issue.
4. If unsure whether it is tool bug vs user workflow, issue first, PR second.

## Prerequisite

`command -v desloppify >/dev/null 2>&1 && echo "desloppify: installed" || echo "NOT INSTALLED — run: pip install --upgrade git+https://github.com/peteromallet/desloppify.git"`

<!-- desloppify-end -->

## Codex Overlay

This is the canonical Codex overlay used by the README install command.

1. Prefer first-class batch runs: `desloppify review --run-batches --runner codex --parallel --scan-after-import`.
2. The command writes immutable packet snapshots under `.desloppify/review_packets/holistic_packet_*.json`; use those for reproducible retries.
3. Keep reviewer input scoped to the immutable packet and the source files named in each batch.
4. Do not use prior chat context, score history, narrative summaries, issue labels, or target-threshold anchoring while scoring.
5. Assess every dimension listed in `query.dimensions`; never drop a requested dimension. If evidence is weak/mixed, score lower and explain uncertainty in findings.
6. Return machine-readable JSON only for review imports. For Claude session submit (`--external-submit`), include `session` from the generated template:

```json
{
  "session": {
    "id": "<session_id_from_template>",
    "token": "<session_token_from_template>"
  },
  "assessments": {
    "<dimension_from_query>": 0
  },
  "findings": [
    {
      "dimension": "<dimension_from_query>",
      "identifier": "short_id",
      "summary": "one-line defect summary",
      "related_files": ["relative/path/to/file.py"],
      "evidence": ["specific code observation"],
      "suggestion": "concrete fix recommendation",
      "confidence": "high|medium|low"
    }
  ]
}
```

7. `findings` MUST match `query.system_prompt` exactly (including `related_files`, `evidence`, and `suggestion`). Use `"findings": []` when no defects are found.
8. Import is fail-closed by default: if any finding is invalid/skipped, `desloppify review --import` aborts unless `--allow-partial` is explicitly passed.
9. Assessment scores are auto-applied from trusted internal run-batches imports, or via Claude cloud session imports (`desloppify review --external-start --external-runner claude` then printed `--external-submit`). Legacy attested external import via `--attested-external` remains supported.
10. Manual override is safety-scoped: you cannot combine it with `--allow-partial`, and provisional manual scores expire on the next `scan` unless replaced by trusted internal or attested-external imports.
11. If a batch fails, retry only that slice with `desloppify review --run-batches --packet <packet.json> --only-batches <idxs>`.

<!-- desloppify-overlay: codex -->
<!-- desloppify-end -->
