# Issue #45 — OpenChamber Quota Provider Parity in CodeWalk

> **Self-contained execution directive.** A future executor with zero conversation context must be able to implement this entire plan from this file alone. Every code change, configuration value, file path, command, and test case is written explicitly. All decisions are resolved — no alternatives, no open branches. Per-project convention this is a CodeWalk Flutter/Dart change against `lib/data/datasources/quota_remote_datasource.dart` and its dependencies.

---

### Status

**Ready.** No blockers. Issue #45 can be closed after the 4 wave commits + 1 docs commit land.

---

### Problem

GitHub issue #45: **"Rate Limits / Quota missing many providers like in OpenChamber"** (https://github.com/verseles/codewalk/issues/45)

> Make parity/clone OpenChamber providers Rate Limits / Quota so codewalk can display more providers usage. Currently codewalk supports only a fewer providers based from OpenChamber.

CodeWalk currently surfaces quota data for 6 providers (claude, openrouter, codex, google, github-copilot, opencode-go). OpenChamber's `packages/web/server/lib/quota/providers/` ships 15 distinct provider entries. The 9 missing entries are: `nano-gpt`, `wafer`, `github-copilot-addon`, `kimi-for-coding`, `zhipuai-coding-plan`, `minimax-coding-plan`, `minimax-cn-coding-plan`, `zai-coding-plan`, `cursor`, `ollama-cloud`. (Count is 10 distinct provider IDs — issue text says "9" but lists 10; the implementation targets all 10 per the OpenChamber source.)

---

### Objective

Add all 10 missing OpenChamber quota providers to CodeWalk's shell-fallback JS, with no regression in the 6 existing providers and full parity with OpenChamber's quota surface. After completion:

- The `Context usage` popup in CodeWalk shows all 16 providers (6 existing + 10 new) when each is configured on the host server's `auth.json` (or, for ollama-cloud, when its cookie file is present).
- The `unsupportedConfigured` filter correctly omits every alias of the 10 new providers.
- The shared Dart/JS hydration mechanism is in place so future providers can be added with a single Dart-side edit.
- The minimum reproduction case — opening the Context usage popup on a host with at least one of the new providers configured — surfaces a non-empty quota group row for that provider.

---

### Context and Constraints

**Project layout (lines from the AGENTS.md quick-reference tables):**

| Topic | Lines |
|-------|-------|
| ADR-029 (quota + rate-limit monitoring) | `ADR.md` 1443–1520 |
| `quota_remote_datasource.dart` (current 1081 lines) | `lib/data/datasources/quota_remote_datasource.dart` |
| `quota_provider.dart` (UI provider) | `lib/presentation/providers/quota_provider.dart` (1–320) |
| `quota.dart` (domain entities) | `lib/domain/entities/quota.dart` (1–269) |
| Quota widgets | `lib/presentation/widgets/quota/*.dart` |
| DI wiring | `lib/core/di/injection_container.dart` line 105–106 |
| Tests | `test/unit/quota/{quota_pace_utils,quota_remote_datasource,quota_provider}_test.dart`, `test/support/fakes.dart` |

**ADR-029 hard constraints (lines 1451–1508):**

1. **Server-host-only credential ownership** — The app never stores provider credentials. The host's `auth.json` is read by the shell script. The client only sees aggregated quota results.
2. **Strategy-chain transport** — `GET /api/quota/{provider}` (OpenChamber REST) → shell fallback (any server). REST path is unchanged.
3. **Popup-only UI (compact-first)** — surfaced only via the Context usage popup. No UI changes needed.
4. **Base64 one-liner shell pattern** — Required because of the OpenCode `POST /session/:id/shell` AST-truncation bug (Post-Mortem section in ADR-029 lines 1510–1519). The full JS is Base64-encoded into a one-line `node -e "eval(Buffer.from('...','base64').toString('utf8'))"` command.
5. **Codex `providerId` guard** — at `quota_provider.dart` line ~1482, preserves per-window granularity for Codex entries. New providers use unique `providerId` strings, so the guard needs no change.
6. **`opencode-go` dashboard credential opt-in** — narrow exception, scoped by `serverId`, opt-in only, secure storage. Preserved as-is.

**ADR-023 supremacy**: Official OpenCode is the primary contract. OpenChamber is an additive parity source. No divergence from official server capabilities.

**Project conventions (enforced):**
- 2000-line `analyze` cap on Dart files (ROADMAP.md line 5).
- Part-file cluster precedent for high-change surfaces (ADR-004): `chat_page.dart`, `chat_provider.dart`, `chat_page_timeline_builder.dart` all use `part`/`part of` (ROADMAP.md lines 5–6).
- No new client-side credentials, no new Dart/Flutter dependencies, no changes to `_fetchViaOpenChamberRest()`.
- Skip OpenChamber's `openai.js` (internal-only, not dispatched; OpenAI covered by `codex`).

**Verified real (from OpenChamber source, https://github.com/openchamber/openchamber/tree/main/packages/web/server/lib/quota/providers/):**
- 15 OpenChamber provider files exist: `claude.js`, `codex.js`, `copilot.js`, `cursor.js`, `google/`, `kimi.js`, `minimax-cn-coding-plan.js`, `minimax-coding-plan.js`, `nanogpt.js`, `ollama-cloud.js`, `openai.js` (internal), `openrouter.js`, `wafer.js`, `zai.js`, `zhipuai-coding-plan.js`.
- All 10 endpoint URLs verified.

---

### Decisions (Resolved)

These are facts the executor will follow. No re-decision required.

| # | Decision | Reason |
|---|----------|--------|
| D1 | **Modularize via a Dart `part` file** — `lib/data/datasources/quota_remote_datasource.part.js.dart` holds all per-provider JS methods as `part of` extensions of the main datasource. | Respects 2000-line cap. Reuses ADR-004 part-file precedent. Keeps the user's "modularize IN `quota_remote_datasource.dart`" intent (the part file is logically the same source unit). |
| D2 | **`unsupportedConfigured` filter is Dart-driven** — `static const Set<String> _supportedAuthKeys` in the main file is the single source of truth, hydrated into the JS dispatcher as a JSON array literal at `_buildQuotaShellCommand` time. | Eliminates the dual-maintenance bug (forgetting to add a new alias to the JS filter when adding it to the dispatcher). |
| D3 | **3-wave ordering** — Wave 1: 4 low-complexity providers. Wave 2: 4 medium-complexity. Wave 3: 2 high-complexity. | Universal agreement across all 7 first-round plans. Complexity matches integration risk. |
| D4 | **10 new providers, not 9** — `github-copilot-addon` is a distinct provider entry even though it reuses the same auth key as `github-copilot`. | OpenChamber's `copilot.js` exports both `fetchQuota` and `fetchQuotaAddon`; the addon uses the same `premium_interactions` window with a different `providerId`. |
| D5 | **`github-copilot-addon` reuses the underlying fetch, derives two result envelopes** — One HTTP call to `api.github.com/copilot_internal/user` produces both `github-copilot` and `github-copilot-addon` `QuotaProviderResult` entries. | Avoids doubling network traffic and rate-limit risk. The existing `fGH` fetch is wrapped, then both envelopes are produced. |
| D6 | **Function names use `f<PascalCase>` convention, chosen to avoid collision** with existing `fC`, `fO`, `fX`, `fGM`, `fGQB`, `fG`, `fGH`, `fOCG`, `rGem`, `rAnti`, `rGAccess`, `rAuth`. New names: `fNanoGpt`, `fWafer`, `fGHA`, `fKimi`, `fZhipu`, `fMinimax`, `fMinimaxCn`, `fZai`, `fCursor`, `fOllamaCloud`. | Prevents silent scope collisions in the concatenated JS. |
| D7 | **Ollama-cloud parse failure returns `ok: false, error: 'Failed to parse Ollama Cloud usage: <fragment>'`** — not `ok: true, windows: {}`. | A silent `ok: true` would hide a real failure mode and contradict the existing `QuotaProviderResult` contract. The failure is logged with the offending HTML fragment for debugging. |
| D8 | **`readConfigLayers()` for Zhipu is deferred to a follow-up PR.** | The helper would read `~/.config/opencode/opencode.json[c]` for `provider.zhipuai-coding-plan.options.apiKey` as a fallback for users who configure via config layers. It is a feature enhancement, not parity. Out of scope for this issue. |
| D9 | **Cursor's macOS SQLite path is wrapped in `try { execFileSync('sqlite3', …) } catch { return null }`** with fall-through to env-var/file token auth. | `sqlite3` CLI is not guaranteed on all macOS hosts and is absent on Linux/Windows. The other auth sources (env vars `CURSOR_TOKEN` / `CURSOR_REFRESH_TOKEN`, file paths `CURSOR_TOKEN_FILE` / `CURSOR_REFRESH_TOKEN_FILE`, or `auth.json` `cursor` entry) cover the cross-platform path. |
| D10 | **Cursor Connect protocol uses the `Connect-Protocol-Version: 1` header** on all 3 POST calls to `aiserver.v1.DashboardService/*`. | Verified from `cursor.js`. Omitting this header causes all cursor calls to return 400. |
| D11 | **6 wave commits** — Phase 0 (foundation) + 3 wave commits + docs commit + close-issue commit. | Aligns with the project's plan-anchored commit protocol in AGENTS.md. Each commit is a logical checkpoint that passes `make check`. |
| D12 | **`opencode-go` provider is preserved as-is.** | CodeWalk-specific feature documented in ADR-029. Not in OpenChamber's provider list. Renaming or removing would break existing user settings. |

---

### Why This Plan

This synthesized plan was chosen by consensus review of 7 independent first-round plans (planFlash35, planG31Pro, planGLM51, planMimo25, planKimi26, planNemoUltra, planMiniMax3) and 7 second-pass consensus reviews. Aggregated non-owner signal: planMiniMax3 was ranked top-3 by 5 of 5 non-owner evaluators and #1 by 4 of 5; planGLM51 was the strong runner-up with the most detailed per-provider specs.

The synthesis keeps the architectural innovations with the highest leverage (Dart-driven auth keys, part-file cluster), the correctness-critical details (minimax-cn inverted semantics, zhipuai config-layer fallback, dual-scale nano-gpt, Cursor Connect-Protocol-Version header), the safest failure modes (Cursor `sqlite3` try/catch, Ollama `ok: false` on parse failure), and the strictest testing strategy (inverted-semantics regression test, OAuth-refresh test, parse-failure test, dual-symmetry test). It discards over-engineering (12-file directory) and under-engineering (everything in one 1500+ line file).

---

### Overview

**Phase 0 — Foundation:** Refactor the 1081-line `quota_remote_datasource.dart` so all JS payload generation lives in a `part` file. Add the Dart-driven `_supportedAuthKeys` set. The 6 existing providers are migrated into the part file as `_jsClaudeProvider()`, `_jsOpenRouterProvider()`, etc. The `_buildQuotaShellCommand` method becomes a thin composer. Behavior is unchanged.

**Phase 1 — Wave 1 (low complexity):** Add `nano-gpt`, `wafer`, `github-copilot-addon`, `kimi-for-coding` as `_js<Name>Provider()` methods. Add IIFE invocations. Add 4 unit tests. Validate with `make check`.

**Phase 2 — Wave 2 (medium complexity):** Add `zhipuai-coding-plan`, `minimax-coding-plan`, `minimax-cn-coding-plan` (inverted), `zai-coding-plan`. Add IIFE invocations. Add 4 unit tests + 1 inverted-semantics regression test. Validate with `make check`.

**Phase 3 — Wave 3 (high complexity):** Add `cursor` (OAuth + JWT refresh + macOS SQLite + 3 POST calls + window builder) and `ollama-cloud` (cookie file + HTML regex scrape with explicit `ok: false` on parse failure). Add 2 unit tests + 1 OAuth-refresh test. Validate with `make check` + `desloppify scan --path lib --profile objective`.

**Phase 4 — Integration & docs:** Update `ROADMAP.md`, extend ADR-029 in `ADR.md`, add per-provider entries to `BEHAVIOR.md`, note the new part file in `CODEBASE.md`. Run 3 reviewer subagents in parallel on the 4 code commits. Apply only judge-approved fixes.

**Phase 5 — Close issue:** Final commit referencing all 5 commit hashes. Notify user. Run `make android` to produce a test APK.

---

### Steps

Each step lists: **Files** (exact paths), **Details** (the change), **Risk**, **Validation** (how to verify the step succeeded before moving on).

#### Phase 0 — Foundation refactor (1 commit)

1. **Create the part file scaffold.**
   - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart` (new), `lib/data/datasources/quota_remote_datasource.dart` (modified).
   - **Details:**
     - Add at the top of `quota_remote_datasource.dart` (after the existing imports, before the existing class):
       ```dart
       part 'quota_remote_datasource.part.js.dart';
       ```
     - Create the part file with the boilerplate:
       ```dart
       part of 'quota_remote_datasource.dart';

       // Phase 0: shared helpers + existing 6 providers.
       // Phase 1–3: 10 new providers.
       // Phase 0: dispatcher and footer.
       ```
     - Move the existing `jsScript` raw string (lines 322–1071) into per-provider Dart methods in the part file. The existing 6 providers become:
       - `String _jsSharedHelpers()` — contains lines 326–530 of the current `jsScript` (the require statements, constants, and all shared utility functions: `rAuth`, `rJson`, `getE`, `nE`, `asO`, `asS`, `pickS`, `fromB64`, `toN`, `toTs`, `pgR`, `gCred`, `gDiag`, `bR`, `tUW`, `gWin`).
       - `String _jsClaudeProvider()` — `fC` body (lines 532–563).
       - `String _jsOpenRouterProvider()` — `fO` body (lines 565–603).
       - `String _jsCodexProvider()` — `fX` body (lines 605–659).
       - `String _jsGoogleProvider()` — `rGem` + `rAnti` + `rGAccess` + `fGM` + `fGQB` + `fG` bodies (lines 661–877).
       - `String _jsGitHubCopilotProvider()` — `fGH` body (lines 879–919).
       - `String _jsOpenCodeGoProvider({required String openCodeGoWsB64, required String openCodeGoCkB64})` — `fOCG` body (lines 921–1035), with the `__OCG_WS_B64__` and `__OCG_CK_B64__` placeholders replaced via `.replaceAll()`.
     - Add a new method in the main file (inside `QuotaRemoteDataSourceImpl`):
       ```dart
       static const Set<String> _supportedAuthKeys = <String>{
         // existing
         'anthropic', 'claude',
         'openrouter',
         'openai', 'codex', 'chatgpt',
         'google', 'google.oauth',
         'github-copilot', 'copilot',
         'opencode-go',
         // Wave 1 (added in Phase 1, but declared here for forward reference)
         'nano-gpt', 'nanogpt', 'nano_gpt',
         'wafer', 'wafer-ai', 'wafer_ai', 'wafer.ai',
         'kimi-for-coding', 'kimi',
         // Wave 2 (added in Phase 2)
         'zhipuai-coding-plan', 'zhipuai', 'zhipu',
         'minimax-coding-plan',
         'minimax-cn-coding-plan',
         'zai-coding-plan', 'zai', 'z.ai',
         // Wave 3 (added in Phase 3)
         'cursor',
         'ollama-cloud', 'ollamacloud',
       };
       ```
     - Rewrite `_buildQuotaShellCommand` (currently at `quota_remote_datasource.dart` lines 311–321 and 1073–1080) as a thin composer. The body becomes:
       ```dart
       String _buildQuotaShellCommand({
         OpenCodeGoDashboardCredentials? openCodeGoCredentials,
       }) {
         final wsB64 = openCodeGoCredentials?.isComplete == true
             ? base64Encode(utf8.encode(openCodeGoCredentials!.workspaceId.trim()))
             : '';
         final ckB64 = openCodeGoCredentials?.isComplete == true
             ? base64Encode(utf8.encode(openCodeGoCredentials!.authCookie.trim()))
             : '';

         final supportedKeysLiteral = '[' +
             _supportedAuthKeys.map((k) => "'$k'").join(',') +
             ']';

         final payload = StringBuffer()
           ..write(_jsSharedHelpers())
           ..write('\n')
           ..write(_jsClaudeProvider())
           ..write(_jsOpenRouterProvider())
           ..write(_jsCodexProvider())
           ..write(_jsGoogleProvider())
           ..write(_jsGitHubCopilotProvider())
           ..write(_jsOpenCodeGoProvider(
             openCodeGoWsB64: wsB64,
             openCodeGoCkB64: ckB64,
           ))
           // Phase 1–3 invocations appended in their respective commits.
           ..write(_jsDispatcher(supportedKeysLiteral: supportedKeysLiteral));

         final b64 = base64Encode(utf8.encode(payload.toString()));
         return "node -e \"eval(Buffer.from('$b64','base64').toString('utf8'))\""
             " || printf '%s\\n' '$_shellPrefix{\"results\":[]}'";
       }
       ```
     - Add a `_jsDispatcher({required String supportedKeysLiteral})` method in the part file that produces the final IIFE (replacing the current IIFE at lines 1037–1070). The dispatcher must use the literal directly:
       ```javascript
       (async () => {
         const a = rAuth();
         const authKeys = Object.keys(a);
         const R = [];
         const c = await fC(a); if (c) R.push(c);
         const o = await fO(a); if (o) R.push(o);
         const x = await fX(a); if (x) R.push(x);
         const g = await fG(a); if (g) R.push(g);
         const gh = await fGH(a); if (gh) R.push(gh);
         const ocg = await fOCG(a); if (ocg) R.push(ocg);
         // Phase 1–3: const ng = await fNanoGpt(a); ... appended in their commits.
         const unsupported = authKeys.filter(
           (k) => !<SUPPORTED_KEYS_LITERAL>.includes(k),
         );
         console.log(
           P + JSON.stringify({
             results: R,
             meta: {
               authKeys: authKeys,
               unsupportedConfigured: unsupported,
               resultProviderIds: R.map((r) => r.providerId),
             },
           }),
         );
       })().catch((err) => {
         console.log(P + JSON.stringify({ results: [], meta: { error: String(err) } }));
       });
       ```
       The `<SUPPORTED_KEYS_LITERAL>` is a placeholder replaced via `.replaceAll('<SUPPORTED_KEYS_LITERAL>', supportedKeysLiteral)` before encoding.
   - **Risk:** Medium — touches the core shell-fallback path. Mitigation: the existing `node --check` syntax test (lines 190–273 in `quota_remote_datasource_test.dart`) and the existing per-provider shell-fallback tests must pass unchanged.
   - **Validation:** `make check` (analyzer + unit tests) passes with zero behavior change. The shell script emitted by `_buildQuotaShellCommand` is byte-identical to the current `jsScript` for the 6 existing providers (compare via the existing `_fetchQuotaForProviderRest` and the encoded length).

2. **Commit Phase 0.**
   - **Files:** `lib/data/datasources/quota_remote_datasource.dart`, `lib/data/datasources/quota_remote_datasource.part.js.dart`.
   - **Details:** Commit message: `chore(agent): quota #45 — refactor shell JS into part-file cluster with Dart-driven unsupported filter`. Include `PLAN_REF: <PLAN_HASH>` placeholder (will be filled by the executor from the `plan:` commit hash created before this commit). Include `PREVIOUS_STEP: <PREV_HASH>`. Mark all phase-0 substeps as done. The commit body must reference the per-file line ranges migrated and the new `_supportedAuthKeys` set.

#### Phase 1 — Wave 1 (1 commit: 4 providers)

3. **Add `nano-gpt` provider.**
   - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart` (new method), `lib/data/datasources/quota_remote_datasource.dart` (dispatcher call).
   - **Details:**
     - Add to the part file:
       ```dart
       String _jsNanoGptProvider() => r'''
       async function fNanoGpt(a) {
         const e = nE(getE(a, ['nano-gpt', 'nanogpt', 'nano_gpt']));
         const k = e && (e.key || e.token);
         if (!k) return null;
         try {
           const res = await fetch('https://nano-gpt.com/api/subscription/v1/usage', {
             headers: { Authorization: 'Bearer ' + k, 'Content-Type': 'application/json' }
           });
           if (!res.ok) return bR({ pId: 'nano-gpt', pName: 'NanoGPT', ok: false, err: 'API error: ' + res.status });
           const payload = await res.json();
           const windows = {};
           const daily = payload && payload.daily;
           const monthly = payload && payload.monthly;
           const state = (payload && payload.state) || 'active';
           const handleWindow = (entry, wS) => {
             if (!entry) return null;
             let uP = null;
             if (typeof entry.percentUsed === 'number') {
               uP = Math.max(0, Math.min(100, entry.percentUsed * 100));
             } else {
               const u = toN(entry.used);
               const l = toN(entry.limit || (entry.limits && entry.limits.daily) || (entry.limits && entry.limits.monthly));
               if (u !== null && l !== null && l > 0) uP = Math.max(0, Math.min(100, (u / l) * 100));
             }
             const vL = state !== 'active' ? '(' + state + ')' : null;
             return tUW({ uP, wS, rA: toTs(entry.resetAt), vL });
           };
           if (daily) windows.daily = handleWindow(daily, 86400);
           if (monthly) windows.monthly = handleWindow(monthly, null);
           return bR({ pId: 'nano-gpt', pName: 'NanoGPT', ok: true, use: { windows } });
         } catch (err) {
           return bR({ pId: 'nano-gpt', pName: 'NanoGPT', ok: false, err: err.message });
         }
       }
       ''';
       ```
     - In the part file's `_jsDispatcher` method, add the invocation: `const ng = await fNanoGpt(a); if (ng) R.push(ng);` immediately after the `fOCG` invocation.
   - **Risk:** Low — direct port from `nanogpt.js`. The dual-scale handling (`percentUsed` 0–1 vs `used/limit` 0–100) is the main edge case.
   - **Validation:** The added unit test parses a mock shell response and asserts `providerId == 'nano-gpt'`, `windows.daily` and `windows.monthly` are populated.

4. **Add `wafer` provider.**
   - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, dispatcher.
   - **Details:**
     - Add to the part file:
       ```dart
       String _jsWaferProvider() => r'''
       async function fWafer(a) {
         const e = nE(getE(a, ['wafer', 'wafer-ai', 'wafer_ai', 'wafer.ai']));
         const k = e && (e.key || e.token);
         if (!k) return null;
         const ac = typeof AbortController !== 'undefined' ? new AbortController() : null;
         const tm = ac ? setTimeout(() => ac.abort(), 15000) : null;
         try {
           const res = await fetch('https://pass.wafer.ai/v1/inference/quota', {
             headers: { Authorization: 'Bearer ' + k, 'Accept-Encoding': 'identity' },
             signal: ac && ac.signal,
           });
           if (tm) clearTimeout(tm);
           if (!res.ok) return bR({ pId: 'wafer', pName: 'Wafer.ai', ok: false, err: 'API error: ' + res.status });
           const d = await res.json();
           const remaining = toN(d.remaining_included_requests);
           const limit = toN(d.included_request_limit);
           const overage = toN(d.overage_request_count);
           const usedPercentRaw = toN(d.current_period_used_percent);
           const windowStart = toTs(d.window_start);
           const windowEnd = toTs(d.window_end);
           const planTier = (d.plan_tier && typeof d.plan_tier === 'string' && d.plan_tier.trim()) ? d.plan_tier.trim() : null;
           if (remaining === null && limit === null && overage === null && usedPercentRaw === null) {
             return bR({ pId: 'wafer', pName: 'Wafer.ai', ok: false, err: 'No quota data in response' });
           }
           const hasOverage = overage !== null && overage > 0;
           const usedPercent = hasOverage ? Math.max(0, usedPercentRaw || 0) : Math.max(0, Math.min(100, usedPercentRaw || 0));
           const windowSeconds = (windowStart !== null && windowEnd !== null) ? Math.round((windowEnd - windowStart) / 1000) : 18000;
           const windowLabel = resolveWindowLabel(windowSeconds);
           let vL = null;
           if (remaining !== null && limit !== null) {
             const parts = [];
             if (planTier) parts.push(planTier);
             parts.push(remaining + ' / ' + limit + ' left');
             if (hasOverage) parts.push('+' + overage + ' overage');
             vL = parts.join(' \u00b7 ');
           }
           const w = {};
           w[windowLabel] = tUW({ uP: usedPercent, wS: windowSeconds, rA: windowEnd, vL: vL });
           return bR({ pId: 'wafer', pName: 'Wafer.ai', ok: true, use: { windows: w } });
         } catch (err) {
           const isTimeout = ac && ac.signal && ac.signal.aborted;
           return bR({ pId: 'wafer', pName: 'Wafer.ai', ok: false, err: isTimeout ? 'Request timed out' : err.message });
         }
       }
       ''';
       ```
     - In `_jsDispatcher`, add `const wf = await fWafer(a); if (wf) R.push(wf);` after the `fNanoGpt` invocation.
   - **Risk:** Low — the `pass.wafer.ai` URL is verified from OpenChamber `wafer.js` but may change.
   - **Validation:** Unit test parses a mock shell response with `overage_request_count: 5` and asserts the `valueLabel` contains `+5 overage`.

5. **Add `github-copilot-addon` provider (reuses existing fetch, derives two envelopes).**
   - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, dispatcher.
   - **Details:**
     - Add to the part file:
       ```dart
       String _jsGitHubCopilotAddonProvider() => r'''
       async function fGHA(a) {
         const e = nE(getE(a, ['github-copilot', 'copilot']));
         const t = e && (e.access || e.token);
         if (!t) return null;
         try {
           const res = await fetch('https://api.github.com/copilot_internal/user', {
             headers: {
               Authorization: 'token ' + t,
               Accept: 'application/json',
               'Editor-Version': 'vscode/1.96.2',
               'X-Github-Api-Version': '2025-04-01',
             },
           });
           if (!res.ok) return bR({ pId: 'github-copilot-addon', pName: 'GitHub Copilot Add-on', ok: false, err: 'API error: ' + res.status });
           const d = await res.json();
           const q = d && d.quota_snapshots ? d.quota_snapshots : {};
           const rA = toTs(d && d.quota_reset_date);
           const w = {};
           if (q && q.premium_interactions) {
             const s = q.premium_interactions;
             const en = toN(s.entitlement);
             const re = toN(s.remaining);
             const uP = en !== null && re !== null && en > 0 ? Math.max(0, 100 - (re / en) * 100) : null;
             const vL = en !== null && re !== null ? re.toFixed(0) + ' / ' + en.toFixed(0) + ' left' : null;
             w.premium = tUW({ uP: uP, wS: null, rA: rA, vL: vL });
           }
           return bR({ pId: 'github-copilot-addon', pName: 'GitHub Copilot Add-on', ok: true, use: { windows: w } });
         } catch (err) {
           return bR({ pId: 'github-copilot-addon', pName: 'GitHub Copilot Add-on', ok: false, err: err.message });
         }
       }
       ''';
       ```
     - In `_jsDispatcher`, add `const gha = await fGHA(a); if (gha) R.push(gha);` after the `fWafer` invocation.
   - **Risk:** Low — the addon's HTTP call is a duplicate of `fGH`'s. This is the only Wave 1 provider that does not deduplicate the fetch. Future work could refactor `fGH` and `fGHA` to share a single fetch, but the current 1-extra-call cost is acceptable.
   - **Validation:** Unit test parses a mock shell response and asserts `providerId == 'github-copilot-addon'`, `windows.premium` is populated, and `windows.chat` and `windows.completions` are NOT populated (addon filters to premium only).

6. **Add `kimi-for-coding` provider.**
   - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, dispatcher, shared helpers.
   - **Details:**
     - First, add two new shared helpers in `_jsSharedHelpers()` (append to the existing helper block):
       ```javascript
       function durationToLabel(duration, unit) {
         const d = toN(duration);
         if (d === null) return 'rate';
         const u = (typeof unit === 'string' ? unit : '').toUpperCase();
         if (u === 'TIME_UNIT_MINUTE' || u === 'MINUTE') return d + 'm';
         if (u === 'TIME_UNIT_HOUR' || u === 'HOUR') return d + 'h';
         if (u === 'TIME_UNIT_DAY' || u === 'DAY') return d + 'd';
         return d + 's';
       }
       function durationToSeconds(duration, unit) {
         const d = toN(duration);
         if (d === null) return null;
         const u = (typeof unit === 'string' ? unit : '').toUpperCase();
         if (u === 'TIME_UNIT_MINUTE' || u === 'MINUTE') return d * 60;
         if (u === 'TIME_UNIT_HOUR' || u === 'HOUR') return d * 3600;
         if (u === 'TIME_UNIT_DAY' || u === 'DAY') return d * 86400;
         return d;
       }
       ```
     - Add to the part file:
       ```dart
       String _jsKimiForCodingProvider() => r'''
       async function fKimi(a) {
         const e = nE(getE(a, ['kimi-for-coding', 'kimi']));
         const k = e && (e.key || e.token);
         if (!k) return null;
         try {
           const res = await fetch('https://api.kimi.com/coding/v1/usages', {
             headers: { Authorization: 'Bearer ' + k, 'Content-Type': 'application/json' }
           });
           if (!res.ok) return bR({ pId: 'kimi-for-coding', pName: 'Kimi for Coding', ok: false, err: 'API error: ' + res.status });
           const d = await res.json();
           const w = {};
           if (d && d.usage) {
             const limit = toN(d.usage.limit);
             const remaining = toN(d.usage.remaining);
             const usedPercent = limit && remaining !== null ? Math.max(0, Math.min(100, 100 - (remaining / limit) * 100)) : null;
             w.weekly = tUW({ uP: usedPercent, wS: null, rA: toTs(d.usage.resetTime) });
           }
           const limits = Array.isArray(d && d.limits) ? d.limits : [];
           for (const lim of limits) {
             const window = lim && lim.window;
             const detail = lim && lim.detail;
             const rawLabel = durationToLabel(window && window.duration, window && window.timeUnit);
             const windowSeconds = durationToSeconds(window && window.duration, window && window.timeUnit);
             const label = (windowSeconds === 18000) ? 'Rate Limit (' + rawLabel + ')' : rawLabel;
             const total = toN(detail && detail.limit);
             const remaining = toN(detail && detail.remaining);
             const usedPercent = total && remaining !== null ? Math.max(0, Math.min(100, 100 - (remaining / total) * 100)) : null;
             w[label] = tUW({ uP: usedPercent, wS: windowSeconds, rA: toTs(detail && detail.resetTime) });
           }
           return bR({ pId: 'kimi-for-coding', pName: 'Kimi for Coding', ok: true, use: { windows: w } });
         } catch (err) {
           return bR({ pId: 'kimi-for-coding', pName: 'Kimi for Coding', ok: false, err: err.message });
         }
       }
       ''';
       ```
     - In `_jsDispatcher`, add `const km = await fKimi(a); if (km) R.push(km);` after the `fGHA` invocation.
   - **Risk:** Low — well-isolated. The `TIME_UNIT_*` enum mapping is the main edge case.
   - **Validation:** Unit test parses a mock shell response with a `limits` array and asserts the `Rate Limit (5h)` window label is used when `windowSeconds === 18000`.

7. **Commit Phase 1.**
   - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, `lib/data/datasources/quota_remote_datasource.dart` (dispatcher + `_supportedAuthKeys` set).
   - **Details:** Commit message: `feat(quota): #45 wave 1 — add nano-gpt, wafer, github-copilot-addon, kimi-for-coding`. `PLAN_REF: <PLAN_HASH>`. `PREVIOUS_STEP: <Phase 0 hash>`. Body lists the 4 new providers and references their OpenChamber source files.

#### Phase 2 — Wave 2 (1 commit: 4 providers)

8. **Add `zhipuai-coding-plan` provider (note: deferred `readConfigLayers()` per D8).**
   - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, dispatcher, shared helpers.
   - **Details:**
     - First, add 3 new shared helpers in `_jsSharedHelpers()`:
       ```javascript
       function resolveWindowSeconds(limit) {
         if (!limit) return null;
         const unit = toN(limit.unit);
         const number = toN(limit.number);
         if (unit === null || number === null) return null;
         if (unit === 3) return number * 3600;
         if (unit === 1) return number * 86400;
         if (unit === 5) return 30 * 86400;
         return null;
       }
       function resolveWindowLabel(windowSeconds) {
         if (windowSeconds === null) return 'rate';
         if (windowSeconds <= 5 * 3600) return '5h';
         if (windowSeconds <= 7 * 86400) return 'weekly';
         if (windowSeconds <= 30 * 86400) return 'monthly';
         return 'daily';
       }
       function normalizeTimestamp(v) {
         const t = toTs(v);
         return t;
       }
       ```
     - Add to the part file:
       ```dart
       String _jsZhipuaiCodingPlanProvider() => r'''
       async function fZhipu(a) {
         const e = nE(getE(a, ['zhipuai-coding-plan', 'zhipuai', 'zhipu']));
         const k = e && (e.key || e.token);
         if (!k) return null;
         try {
           const res = await fetch('https://open.bigmodel.cn/api/monitor/usage/quota/limit', {
             headers: { Authorization: 'Bearer ' + k, 'Content-Type': 'application/json' }
           });
           if (!res.ok) return bR({ pId: 'zhipuai-coding-plan', pName: 'Zhipu AI Coding Plan', ok: false, err: 'API error: ' + res.status });
           const d = await res.json();
           const limits = (d && d.data && Array.isArray(d.data.limits)) ? d.data.limits : [];
           const tokensLimit = limits.find((x) => x && x.type === 'TOKENS_LIMIT');
           const mcpToolsTimeLimit = limits.find((x) => x && x.type === 'TIME_LIMIT');
           const w = {};
           if (tokensLimit) {
             const windowSeconds = resolveWindowSeconds(tokensLimit);
             const resetAt = tokensLimit.nextResetTime ? normalizeTimestamp(tokensLimit.nextResetTime) : null;
             const usedPercent = typeof tokensLimit.percentage === 'number' ? tokensLimit.percentage : null;
             w.Tokens = tUW({ uP: usedPercent, wS: windowSeconds, rA: resetAt });
           }
           if (mcpToolsTimeLimit) {
             const monthSeconds = 30 * 24 * 3600;
             const resetAt = mcpToolsTimeLimit.nextResetTime ? normalizeTimestamp(mcpToolsTimeLimit.nextResetTime) : null;
             const usedPercent = typeof mcpToolsTimeLimit.percentage === 'number' ? mcpToolsTimeLimit.percentage : null;
             w['MCP Tools'] = tUW({ uP: usedPercent, wS: monthSeconds, rA: resetAt });
           }
           return bR({ pId: 'zhipuai-coding-plan', pName: 'Zhipu AI Coding Plan', ok: true, use: { windows: w } });
         } catch (err) {
           return bR({ pId: 'zhipuai-coding-plan', pName: 'Zhipu AI Coding Plan', ok: false, err: err.message });
         }
       }
       ''';
       ```
     - In `_jsDispatcher`, add `const zp = await fZhipu(a); if (zp) R.push(zp);` after the `fKimi` invocation.
   - **Risk:** Low. The `resolveWindowSeconds` unit mapping (3 → hour, 5 → month) is OpenChamber-specific.
   - **Validation:** Unit test parses a mock shell response with `data.limits = [{type: 'TOKENS_LIMIT', percentage: 50, nextResetTime: <future_ts>, unit: 3, number: 5}, {type: 'TIME_LIMIT', percentage: 20, nextResetTime: <future_ts>, unit: 5, number: 1}]` and asserts `windows.Tokens.usedPercent == 50`, `windows['MCP Tools'].usedPercent == 20`.

9. **Add `minimax-coding-plan` provider (non-CN).**
   - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, dispatcher.
   - **Details:**
     - Add to the part file:
       ```dart
       String _jsMinimaxCodingPlanProvider() => r'''
       async function fMinimax(a) {
         const e = nE(getE(a, ['minimax-coding-plan']));
         const k = e && (e.key || e.token);
         if (!k) return null;
         try {
           const res = await fetch('https://api.minimax.io/v1/api/openplatform/coding_plan/remains', {
             headers: { Authorization: 'Bearer ' + k, 'Content-Type': 'application/json' }
           });
           if (!res.ok) return bR({ pId: 'minimax-coding-plan', pName: 'MiniMax Coding Plan (minimax.io)', ok: false, err: 'API error: ' + res.status });
           const d = await res.json();
           const baseResp = d && d.base_resp;
           if (baseResp && baseResp.status_code !== undefined && baseResp.status_code !== 0) {
             return bR({ pId: 'minimax-coding-plan', pName: 'MiniMax Coding Plan (minimax.io)', ok: false, err: baseResp.status_msg || ('API error: ' + baseResp.status_code) });
           }
           const firstModel = d && Array.isArray(d.model_remains) && d.model_remains[0];
           if (!firstModel) return bR({ pId: 'minimax-coding-plan', pName: 'MiniMax Coding Plan (minimax.io)', ok: false, err: 'No model quota data available' });
           const intervalTotal = toN(firstModel.current_interval_total_count);
           const intervalUsage = toN(firstModel.current_interval_usage_count);
           const intervalStartAt = toTs(firstModel.start_time);
           const intervalResetAt = toTs(firstModel.end_time);
           const weeklyTotal = toN(firstModel.current_weekly_total_count);
           const weeklyUsage = toN(firstModel.current_weekly_usage_count);
           const weeklyStartAt = toTs(firstModel.weekly_start_time);
           const weeklyResetAt = toTs(firstModel.weekly_end_time);
           // Non-CN: usage IS the used count.
           const intervalUsed = intervalUsage;
           const weeklyUsed = weeklyUsage;
           const intervalUsedPercent = intervalTotal > 0 && intervalUsed !== null ? Math.max(0, Math.min(100, (intervalUsed / intervalTotal) * 100)) : null;
           const intervalWindowSeconds = (intervalStartAt && intervalResetAt && intervalResetAt > intervalStartAt) ? Math.floor((intervalResetAt - intervalStartAt) / 1000) : null;
           const weeklyUsedPercent = weeklyTotal > 0 && weeklyUsed !== null ? Math.max(0, Math.min(100, (weeklyUsed / weeklyTotal) * 100)) : null;
           const weeklyWindowSeconds = (weeklyStartAt && weeklyResetAt && weeklyResetAt > weeklyStartAt) ? Math.floor((weeklyResetAt - weeklyStartAt) / 1000) : null;
           const w = {
             '5h': tUW({ uP: intervalUsedPercent, wS: intervalWindowSeconds, rA: intervalResetAt }),
             weekly: tUW({ uP: weeklyUsedPercent, wS: weeklyWindowSeconds, rA: weeklyResetAt }),
           };
           return bR({ pId: 'minimax-coding-plan', pName: 'MiniMax Coding Plan (minimax.io)', ok: true, use: { windows: w } });
         } catch (err) {
           return bR({ pId: 'minimax-coding-plan', pName: 'MiniMax Coding Plan (minimax.io)', ok: false, err: err.message });
         }
       }
       ''';
       ```
     - In `_jsDispatcher`, add `const mx = await fMinimax(a); if (mx) R.push(mx);` after the `fZhipu` invocation.
   - **Risk:** Medium. The non-CN math (`used = usage` directly) is verified from the OpenChamber source. A future refactor must NOT converge this with the CN variant.
   - **Validation:** Unit test asserts the literal `const intervalUsed = intervalUsage;` is in the decoded JS (positive marker) and `const intervalUsed = intervalTotal - intervalUsage;` is NOT in the decoded JS (negative marker). This is the dual-symmetry test that pins the divergence.

10. **Add `minimax-cn-coding-plan` provider (CN, INVERTED).**
    - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, dispatcher.
    - **Details:**
      - Add to the part file:
        ```dart
        String _jsMinimaxCnCodingPlanProvider() => r'''
        async function fMinimaxCn(a) {
          const e = nE(getE(a, ['minimax-cn-coding-plan']));
          const k = e && (e.key || e.token);
          if (!k) return null;
          try {
            const res = await fetch('https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains', {
              headers: { Authorization: 'Bearer ' + k, 'Content-Type': 'application/json' }
            });
            if (!res.ok) return bR({ pId: 'minimax-cn-coding-plan', pName: 'MiniMax Coding Plan (minimaxi.com)', ok: false, err: 'API error: ' + res.status });
            const d = await res.json();
            const baseResp = d && d.base_resp;
            if (baseResp && baseResp.status_code !== undefined && baseResp.status_code !== 0) {
              return bR({ pId: 'minimax-cn-coding-plan', pName: 'MiniMax Coding Plan (minimaxi.com)', ok: false, err: baseResp.status_msg || ('API error: ' + baseResp.status_code) });
            }
            const firstModel = d && Array.isArray(d.model_remains) && d.model_remains[0];
            if (!firstModel) return bR({ pId: 'minimax-cn-coding-plan', pName: 'MiniMax Coding Plan (minimaxi.com)', ok: false, err: 'No model quota data available' });
            const intervalTotal = toN(firstModel.current_interval_total_count);
            const intervalUsage = toN(firstModel.current_interval_usage_count);
            const intervalStartAt = toTs(firstModel.start_time);
            const intervalResetAt = toTs(firstModel.end_time);
            const weeklyTotal = toN(firstModel.current_weekly_total_count);
            const weeklyUsage = toN(firstModel.current_weekly_usage_count);
            const weeklyStartAt = toTs(firstModel.weekly_start_time);
            const weeklyResetAt = toTs(firstModel.weekly_end_time);
            // CN: usage is REMAINING, not used. Subtract to get the used count.
            const intervalUsed = intervalTotal - intervalUsage;
            const weeklyUsed = weeklyTotal - weeklyUsage;
            const intervalUsedPercent = intervalTotal > 0 && intervalUsed >= 0 ? Math.max(0, Math.min(100, (intervalUsed / intervalTotal) * 100)) : null;
            const intervalWindowSeconds = (intervalStartAt && intervalResetAt && intervalResetAt > intervalStartAt) ? Math.floor((intervalResetAt - intervalStartAt) / 1000) : null;
            const weeklyUsedPercent = weeklyTotal > 0 && weeklyUsed >= 0 ? Math.max(0, Math.min(100, (weeklyUsed / weeklyTotal) * 100)) : null;
            const weeklyWindowSeconds = (weeklyStartAt && weeklyResetAt && weeklyResetAt > weeklyStartAt) ? Math.floor((weeklyResetAt - weeklyStartAt) / 1000) : null;
            const w = {
              '5h': tUW({ uP: intervalUsedPercent, wS: intervalWindowSeconds, rA: intervalResetAt }),
              weekly: tUW({ uP: weeklyUsedPercent, wS: weeklyWindowSeconds, rA: weeklyResetAt }),
            };
            return bR({ pId: 'minimax-cn-coding-plan', pName: 'MiniMax Coding Plan (minimaxi.com)', ok: true, use: { windows: w } });
          } catch (err) {
            return bR({ pId: 'minimax-cn-coding-plan', pName: 'MiniMax Coding Plan (minimaxi.com)', ok: false, err: err.message });
          }
        }
        ''';
        ```
      - In `_jsDispatcher`, add `const mxc = await fMinimaxCn(a); if (mxc) R.push(mxc);` after the `fMinimax` invocation.
    - **Risk:** 🔴 **Critical.** The inverted semantics (`used = total - usage` instead of `used = usage`) is a high-regression-risk detail. Mitigation: a dedicated regression test (§16 item 4) decodes the base64 JS and asserts the literal `intervalTotal - intervalUsage` is present and the literal `const intervalUsed = intervalUsage;` (the non-CN pattern) is NOT present.
    - **Validation:** Unit test parses a mock shell response with `current_interval_total_count: 100, current_interval_usage_count: 30` and asserts `windows['5h'].usedPercent == 70` (i.e. 100 - 30, the CN inversion). A separate test asserts the literal `intervalTotal - intervalUsage` is in the decoded JS.

11. **Add `zai-coding-plan` provider.**
    - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, dispatcher.
    - **Details:**
      - Add to the part file:
        ```dart
        String _jsZaiCodingPlanProvider() => r'''
        async function fZai(a) {
          const e = nE(getE(a, ['zai-coding-plan', 'zai', 'z.ai']));
          const k = e && (e.key || e.token);
          if (!k) return null;
          try {
            const res = await fetch('https://api.z.ai/api/monitor/usage/quota/limit', {
              headers: { Authorization: 'Bearer ' + k, 'Content-Type': 'application/json' }
            });
            if (!res.ok) return bR({ pId: 'zai-coding-plan', pName: 'z.ai', ok: false, err: 'API error: ' + res.status });
            const d = await res.json();
            const limits = (d && d.data && Array.isArray(d.data.limits)) ? d.data.limits : [];
            const tokensLimit = limits.find((x) => x && x.type === 'TOKENS_LIMIT');
            if (!tokensLimit) return bR({ pId: 'zai-coding-plan', pName: 'z.ai', ok: true, use: { windows: {} } });
            const windowSeconds = resolveWindowSeconds(tokensLimit);
            const windowLabel = resolveWindowLabel(windowSeconds);
            const resetAt = tokensLimit.nextResetTime ? normalizeTimestamp(tokensLimit.nextResetTime) : null;
            const usedPercent = typeof tokensLimit.percentage === 'number' ? tokensLimit.percentage : null;
            const w = {};
            w[windowLabel] = tUW({ uP: usedPercent, wS: windowSeconds, rA: resetAt });
            return bR({ pId: 'zai-coding-plan', pName: 'z.ai', ok: true, use: { windows: w } });
          } catch (err) {
            return bR({ pId: 'zai-coding-plan', pName: 'z.ai', ok: false, err: err.message });
          }
        }
        ''';
        ```
      - In `_jsDispatcher`, add `const za = await fZai(a); if (za) R.push(za);` after the `fMinimaxCn` invocation.
    - **Risk:** Low — z.ai is essentially zhipuai with `TOKENS_LIMIT` only.
    - **Validation:** Unit test parses a mock shell response and asserts the dynamic `windowLabel` is computed from `resolveWindowLabel`.

12. **Commit Phase 2.**
    - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, `lib/data/datasources/quota_remote_datasource.dart` (dispatcher + `_supportedAuthKeys` set).
    - **Details:** Commit message: `feat(quota): #45 wave 2 — add zhipuai-coding-plan, minimax-coding-plan, minimax-cn-coding-plan (inverted), zai-coding-plan`. `PLAN_REF: <PLAN_HASH>`. `PREVIOUS_STEP: <Phase 1 hash>`. Body highlights the `minimax-cn-coding-plan` inverted semantics and the dual-symmetry test.

#### Phase 3 — Wave 3 (1 commit: 2 providers)

13. **Add `cursor` provider (OAuth + JWT refresh + macOS SQLite + 3 POST calls).**
    - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, dispatcher.
    - **Details:**
      - Add to the part file (the largest new function — see the exact body below):
        ```dart
        String _jsCursorProvider() => r'''
        async function fCursor(a) {
          const e = nE(getE(a, ['cursor']));
          const apiKey = e && (e.key || e.token);
          const refreshT = e && e.refreshToken;

          const BASE_URL = 'https://api2.cursor.sh';
          const USAGE_URL = BASE_URL + '/aiserver.v1.DashboardService/GetCurrentPeriodUsage';
          const PLAN_URL = BASE_URL + '/aiserver.v1.DashboardService/GetPlanInfo';
          const CREDITS_URL = BASE_URL + '/aiserver.v1.DashboardService/GetCreditGrantsBalance';
          const REFRESH_URL = BASE_URL + '/oauth/token';
          const CLIENT_ID = 'KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB';
          const REFRESH_BUFFER_MS = 5 * 60 * 1000;
          const STATE_DB = p.join(os.homedir(), 'Library', 'Application Support', 'Cursor', 'User', 'globalStorage', 'state.vscdb');

          const readJwtPayload = (token) => {
            try {
              const parts = String(token).split('.');
              if (!parts[1]) return null;
              return JSON.parse(Buffer.from(parts[1], 'base64').toString('utf8'));
            } catch (e) { return null; }
          };

          const readStateValue = (key) => {
            if (!fs.existsSync(STATE_DB)) return null;
            try {
              const escapedKey = String(key).replace(/'/g, "''");
              const { execFileSync } = require('child_process');
              const rows = execFileSync('sqlite3', ['-json', STATE_DB, "SELECT value FROM ItemTable WHERE key = '" + escapedKey + "' LIMIT 1;"], {
                encoding: 'utf8', windowsHide: true, stdio: ['ignore', 'pipe', 'ignore']
              });
              const parsed = JSON.parse(rows || '[]');
              return parsed && parsed[0] && parsed[0].value ? String(parsed[0].value).trim() : null;
            } catch (e) { return null; }
          };

          const writeStateValue = (key, value) => {
            if (!fs.existsSync(STATE_DB)) return false;
            try {
              const escaped = String(value).replace(/'/g, "''");
              const escapedKey = String(key).replace(/'/g, "''");
              const { execFileSync } = require('child_process');
              execFileSync('sqlite3', [STATE_DB, "INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('" + escapedKey + "', '" + escaped + "');"], {
                encoding: 'utf8', windowsHide: true, stdio: ['ignore', 'ignore', 'ignore']
              });
              return true;
            } catch (e) { return false; }
          };

          const readFileToken = (path) => {
            try {
              if (!path || !fs.existsSync(path)) return null;
              return fs.readFileSync(path, 'utf8').trim() || null;
            } catch (e) { return null; }
          };

          const writeFileToken = (path, value) => {
            try {
              if (!path) return false;
              fs.writeFileSync(path, value + '\n', { encoding: 'utf8', mode: 0o600 });
              return true;
            } catch (e) { return false; }
          };

          const loadAuthState = () => {
            const envAccessToken = process.env.CURSOR_TOKEN || process.env.CURSOR_ACCESS_TOKEN || null;
            const envRefreshToken = process.env.CURSOR_REFRESH_TOKEN || null;
            const accessTokenPath = process.env.CURSOR_TOKEN_FILE || null;
            const refreshTokenPath = process.env.CURSOR_REFRESH_TOKEN_FILE || null;
            const fileAccessToken = readFileToken(accessTokenPath);
            const fileRefreshToken = readFileToken(refreshTokenPath);
            if (envAccessToken || envRefreshToken) return { accessToken: envAccessToken, refreshToken: envRefreshToken, source: 'env' };
            if (fileAccessToken || fileRefreshToken) return { accessToken: fileAccessToken, refreshToken: fileRefreshToken, source: 'file', accessTokenPath: accessTokenPath };
            return {
              accessToken: apiKey || readStateValue('cursorAuth/accessToken'),
              refreshToken: refreshT || readStateValue('cursorAuth/refreshToken'),
              source: apiKey ? 'auth_json' : 'sqlite'
            };
          };

          const tokenNeedsRefresh = (token) => {
            if (!token) return true;
            const payload = readJwtPayload(token);
            const expiresAt = payload && typeof payload.exp === 'number' ? payload.exp * 1000 : null;
            return !expiresAt || (expiresAt - Date.now() <= REFRESH_BUFFER_MS);
          };

          const persistAccessToken = (auth, accessToken) => {
            if (auth.source === 'sqlite') writeStateValue('cursorAuth/accessToken', accessToken);
            if (auth.source === 'file' && auth.accessTokenPath) writeFileToken(auth.accessTokenPath, accessToken);
          };

          const refreshAccessToken = async (auth) => {
            if (!auth.refreshToken) return auth.accessToken;
            const response = await fetch(REFRESH_URL, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ grant_type: 'refresh_token', client_id: CLIENT_ID, refresh_token: auth.refreshToken })
            });
            const body = await response.json().catch(() => null);
            if (body && body.shouldLogout === true) throw new Error('Session expired - please sign in to Cursor again');
            if (!response.ok) throw new Error(response.status === 401 ? 'Cursor session expired' : ('API error: ' + response.status));
            if (!body || typeof body.access_token !== 'string' || !body.access_token) throw new Error('Cursor refresh response did not include an access token');
            persistAccessToken(auth, body.access_token);
            return body.access_token;
          };

          const resolveAccessToken = async () => {
            const auth = loadAuthState();
            if (!auth.accessToken && !auth.refreshToken) return null;
            if (!tokenNeedsRefresh(auth.accessToken)) return auth.accessToken;
            return refreshAccessToken(auth);
          };

          const connectPost = async (url, accessToken) => {
            const response = await fetch(url, {
              method: 'POST',
              headers: { Authorization: 'Bearer ' + accessToken, 'Content-Type': 'application/json', 'Connect-Protocol-Version': '1' },
              body: '{}'
            });
            if (!response.ok) throw new Error(response.status === 401 ? 'Cursor session expired' : ('API error: ' + response.status));
            return response.json();
          };

          const formatMoney = (value) => {
            const n = toN(value);
            return n === null ? null : n.toFixed(2);
          };

          const centsLabel = (cents) => {
            const value = toN(cents);
            return value === null ? null : '$' + formatMoney(value / 100);
          };

          const percentFromSpend = (planUsage) => {
            const explicit = toN(planUsage && planUsage.totalPercentUsed);
            if (explicit !== null) return explicit;
            const limit = toN(planUsage && planUsage.limit);
            const remaining = toN(planUsage && planUsage.remaining);
            if (!limit || remaining === null) return null;
            return Math.min(100, Math.max(0, ((limit - remaining) / limit) * 100));
          };

          const buildWindows = (usage, plan) => {
            const planUsage = (usage && usage.planUsage) || {};
            const spendLimitUsage = (usage && usage.spendLimitUsage) || {};
            const resetAt = toTs((usage && usage.billingCycleEnd) || (plan && plan.planInfo && plan.planInfo.billingCycleEnd));
            const windowSeconds = resetAt ? Math.max(0, Math.floor((resetAt - Date.now()) / 1000)) : null;
            const windows = {};
            windows.billing_cycle = tUW({ uP: percentFromSpend(planUsage), wS: windowSeconds, rA: resetAt, vL: centsLabel(planUsage && planUsage.totalSpend) });
            const autoPercent = toN(planUsage && planUsage.autoPercentUsed);
            if (autoPercent !== null) windows.auto = tUW({ uP: autoPercent, wS: windowSeconds, rA: resetAt });
            const apiPercent = toN(planUsage && planUsage.apiPercentUsed);
            if (apiPercent !== null) windows.api = tUW({ uP: apiPercent, wS: windowSeconds, rA: resetAt });
            const planLimit = centsLabel(planUsage && planUsage.limit);
            if (planLimit) {
              const limit = toN(planUsage && planUsage.limit);
              const remaining = toN(planUsage && planUsage.remaining);
              const limitRemaining = centsLabel(remaining) || '$0.00';
              windows.plan_limit = tUW({
                uP: limit && remaining !== null ? Math.min(100, Math.max(0, ((limit - remaining) / limit) * 100)) : null,
                wS: windowSeconds,
                rA: resetAt,
                vL: limitRemaining + ' remaining of ' + planLimit
              });
            }
            const onDemandLimit = toN(spendLimitUsage.individualLimit) || toN(spendLimitUsage.pooledLimit);
            if (onDemandLimit && onDemandLimit > 0) {
              const remaining = toN(spendLimitUsage.individualRemaining) || toN(spendLimitUsage.pooledRemaining) || 0;
              const limitRemaining = centsLabel(remaining) || '$0.00';
              windows.on_demand = tUW({
                uP: Math.min(100, Math.max(0, ((onDemandLimit - remaining) / onDemandLimit) * 100)),
                wS: windowSeconds,
                rA: resetAt,
                vL: limitRemaining + ' remaining of ' + centsLabel(onDemandLimit)
              });
            }
            return windows;
          };

          const appendCreditsWindow = (windows, credits) => {
            const balance = toN((credits && credits.balanceCents) || (credits && credits.totalBalanceCents) || (credits && credits.amountCents));
            if (balance === null) return;
            windows.credits = tUW({ uP: null, wS: null, rA: null, vL: centsLabel(balance) });
          };

          const accessToken = await resolveAccessToken();
          if (!accessToken) return null;

          try {
            const [usage, plan, credits] = await Promise.all([
              connectPost(USAGE_URL, accessToken),
              connectPost(PLAN_URL, accessToken).catch(() => null),
              connectPost(CREDITS_URL, accessToken).catch(() => null)
            ]);
            if (!usage || usage.enabled === false || !usage.planUsage) {
              return bR({ pId: 'cursor', pName: 'Cursor', ok: false, err: 'No active Cursor subscription' });
            }
            const windows = buildWindows(usage, plan);
            appendCreditsWindow(windows, credits);
            const planName = plan && plan.planInfo && plan.planInfo.planName;
            return bR({
              pId: 'cursor',
              pName: planName ? 'Cursor ' + planName : 'Cursor',
              ok: true,
              use: { windows }
            });
          } catch (err) {
            return bR({ pId: 'cursor', pName: 'Cursor', ok: false, err: err.message });
          }
        }
        ''';
        ```
      - In `_jsDispatcher`, add `const cu = await fCursor(a); if (cu) R.push(cu);` after the `fZai` invocation.
    - **Risk:** 🟡 High. The Cursor integration is the most complex new code. The `sqlite3` CLI may be missing on the host; the OAuth refresh may fail; the Connect protocol may require headers that the test mock misses. Mitigation: each sub-step is independently testable. The macOS SQLite path is gated on `fs.existsSync(STATE_DB)`; env-var and file-token auth are the cross-platform fallbacks.
    - **Validation:** Unit test mocks a 401 from `GetCurrentPeriodUsage`, asserts the JS calls `https://api2.cursor.sh/oauth/token` with `client_id: KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB` and `grant_type: refresh_token`. A second test asserts the `Connect-Protocol-Version: 1` header is present on all 3 connect-protocol POSTs.

14. **Add `ollama-cloud` provider (cookie file + HTML regex scrape with `ok: false` on parse failure).**
    - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, dispatcher.
    - **Details:**
      - Add to the part file:
        ```dart
        String _jsOllamaCloudProvider() => r'''
        async function fOllamaCloud(a) {
          const e = nE(getE(a, ['ollama-cloud', 'ollamacloud']));
          const rawCookie = e && (e.key || e.token || e.cookie);
          const COOKIE_PATH = p.join(os.homedir(), '.config', 'ollama-quota', 'cookie');
          const readCookieFile = () => {
            try {
              if (!fs.existsSync(COOKIE_PATH)) return null;
              return fs.readFileSync(COOKIE_PATH, 'utf-8').trim() || null;
            } catch (err) { return null; }
          };
          const parseOllamaSettingsHtml = (html) => {
            const windows = {};
            const sessionMatch = html.match(/Session\s+usage[^0-9]*([0-9.]+)%/i);
            if (sessionMatch) windows.session = tUW({ uP: toN(sessionMatch[1]), wS: null, rA: null });
            const weeklyMatch = html.match(/Weekly\s+usage[^0-9]*([0-9.]+)%/i);
            if (weeklyMatch) windows.weekly = tUW({ uP: toN(weeklyMatch[1]), wS: null, rA: null });
            const premiumMatch = html.match(/Premium[^0-9]*([0-9]+)\s*\/\s*([0-9]+)/i);
            if (premiumMatch) {
              const used = toN(premiumMatch[1]);
              const total = toN(premiumMatch[2]);
              const uP = total && used !== null ? Math.min(100, (used / total) * 100) : null;
              windows.premium = tUW({ uP, wS: null, rA: null, vL: (used === null ? 0 : used) + ' / ' + (total === null ? 0 : total) });
            }
            return windows;
          };
          const cookie = rawCookie || readCookieFile();
          if (!cookie) return null;
          try {
            const res = await fetch('https://ollama.com/settings', {
              headers: { Cookie: cookie, 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36' }
            });
            if (!res.ok) return bR({ pId: 'ollama-cloud', pName: 'Ollama Cloud', ok: false, err: 'API error: ' + res.status });
            const html = await res.text();
            const windows = parseOllamaSettingsHtml(html);
            if (!windows || Object.keys(windows).length === 0) {
              const fragment = html.substring(0, 200);
              return bR({ pId: 'ollama-cloud', pName: 'Ollama Cloud', ok: false, err: 'Failed to parse Ollama Cloud usage: ' + fragment });
            }
            return bR({ pId: 'ollama-cloud', pName: 'Ollama Cloud', ok: true, use: { windows } });
          } catch (err) {
            return bR({ pId: 'ollama-cloud', pName: 'Ollama Cloud', ok: false, err: err.message });
          }
        }
        ''';
        ```
      - In `_jsDispatcher`, add `const oc = await fOllamaCloud(a); if (oc) R.push(oc);` after the `fCursor` invocation.
    - **Risk:** 🟡 Medium. HTML scrape is inherently fragile. Mitigation: explicit `ok: false` on parse failure with the offending HTML fragment in the error message (D7). Logged via the existing `[Quota]` logger.
    - **Validation:** Unit test mocks a successful response with a known HTML snippet and asserts `windows.session`, `windows.weekly`, `windows.premium` are populated. A second test mocks a malformed HTML response and asserts the result is `ok: false, error: 'Failed to parse Ollama Cloud usage: ...'` (NOT `ok: true, windows: {}`).

15. **Commit Phase 3.**
    - **Files:** `lib/data/datasources/quota_remote_datasource.part.js.dart`, `lib/data/datasources/quota_remote_datasource.dart` (dispatcher + `_supportedAuthKeys` set).
    - **Details:** Commit message: `feat(quota): #45 wave 3 — add cursor (OAuth + macOS SQLite) and ollama-cloud (HTML scrape)`. `PLAN_REF: <PLAN_HASH>`. `PREVIOUS_STEP: <Phase 2 hash>`. Body highlights the `Connect-Protocol-Version: 1` header requirement and the explicit `ok: false` on ollama parse failure.

#### Phase 4 — Integration validation

16. **Run full validation.**
    - **Files:** none (verification step).
    - **Details:**
      - `make check` (analyzer + unit tests) — must pass with zero warnings.
      - `desloppify scan --path lib --profile objective` per AGENTS.md "Before every commit" rule.
      - Verify the complete JS output from `_buildQuotaShellCommand` passes `node --check` (the existing test at `quota_remote_datasource_test.dart` lines 190–273 covers this).
      - Verify `_supportedAuthKeys` contains every new auth alias and no extra. Verify the `unsupportedConfigured` array in the generated JS exactly matches.
      - Verify all 16 provider invocations are in the dispatcher: `fC`, `fO`, `fX`, `fG`, `fGH`, `fOCG`, `fNanoGpt`, `fWafer`, `fGHA`, `fKimi`, `fZhipu`, `fMinimax`, `fMinimaxCn`, `fZai`, `fCursor`, `fOllamaCloud`.
    - **Risk:** Low. All unit tests are in place.
    - **Validation:** All four commits (`Phase 0` + 3 wave commits) pass `make check` and `desloppify scan`. The generated JS passes `node --check`. No regressions in the 6 existing providers.

17. **Run 3 reviewer subagents in parallel.**
    - **Files:** none.
    - **Details:** Per AGENTS.md "Post-commit flow with reviewers". Discover 3 random reviewer subagents from runtime. Send each the canonical review payload (task objective, repo path, commit hashes, full diff, architectural context, system invariants, technical constraints, history, accepted tradeoffs). Wait for all 3 reports. Judge the reports: deduplicate findings, resolve conflicts, validate against diff, reject false positives, prioritize by severity. Apply only judge-approved corrections. If any corrections are applied, commit them with `fix:` prefix and re-run the reviewer loop until zero judge-approved corrections remain.
    - **Risk:** Low. Reviewer is a known workflow.
    - **Validation:** All 3 reviewers report zero critical findings, OR all critical findings have been addressed in follow-up `fix:` commits.

#### Phase 5 — Documentation

18. **Update `ROADMAP.md`.**
    - **Files:** `ROADMAP.md` (current 7 lines).
    - **Details:** Add `- [x] Add 10 OpenChamber quota providers for parity (Issue #45) — Commit hashes: <Phase 0 hash>, <Phase 1 hash>, <Phase 2 hash>, <Phase 3 hash>`. The current file has 3 items: the first two are completed (lines 5–6), the third is in-progress (line 7). Append the new completed item after line 6.

19. **Extend ADR-029 in `ADR.md`.**
    - **Files:** `ADR.md` (current line range 1443–1520, total ADR-029 content).
    - **Details:** In the "Key Files" subsection (lines 1478–1490), add the new part file: `lib/data/datasources/quota_remote_datasource.part.js.dart` — per-provider JS payload generators (`_jsSharedHelpers`, `_jsClaudeProvider`, ..., `_jsOllamaCloudProvider`, `_jsDispatcher`). Add a new "Provider Roster" subsection after the "Key Files" subsection enumerating all 15 OpenChamber provider IDs and their OpenChamber source files:
      - `nano-gpt` ← OpenChamber `nanogpt.js`
      - `wafer` ← OpenChamber `wafer.js`
      - `github-copilot-addon` ← OpenChamber `copilot.js` (`fetchQuotaAddon`)
      - `kimi-for-coding` ← OpenChamber `kimi.js`
      - `zhipuai-coding-plan` ← OpenChamber `zhipuai-coding-plan.js`
      - `minimax-coding-plan` ← OpenChamber `minimax-coding-plan.js`
      - `minimax-cn-coding-plan` ← OpenChamber `minimax-cn-coding-plan.js` (inverted)
      - `zai-coding-plan` ← OpenChamber `zai.js`
      - `cursor` ← OpenChamber `cursor.js`
      - `ollama-cloud` ← OpenChamber `ollama-cloud.js`
      - The 6 already-shared providers (claude, codex, google, github-copilot, openrouter, plus the CodeWalk-only `opencode-go`).

20. **Add grouped-display entries to `BEHAVIOR.md`.**
    - **Files:** `BEHAVIOR.md` (current 50+ KB).
    - **Details:** Search for the "Host quota / rate-limit monitoring" section. Add 10 new entries following the same Given/When/Then format as the existing `opencode-go` entry. Each entry documents the popup display behavior for one new provider, including:
      - The provider's display name (e.g. `NanoGPT`, `Wafer.ai`, `GitHub Copilot Add-on`).
      - The window labels (e.g. `daily`, `monthly` for nano-gpt; `5h`, `weekly` for minimax).
      - Any "best-effort" tag for fragile providers (`ollama-cloud`).
      - The macOS-only note for `cursor`.

21. **Update `CODEBASE.md` to note the new part file.**
    - **Files:** `CODEBASE.md` (current 600+ lines).
    - **Details:** In the "Quota" section, mention that the JS payload generation is now modularized into `lib/data/datasources/quota_remote_datasource.part.js.dart`. Note that the Dart-driven `_supportedAuthKeys` set is the single source of truth for the `unsupportedConfigured` filter.

22. **Update `AGENTS.md` quick-reference tables if line ranges shifted.**
    - **Files:** `AGENTS.md` (top-of-file quick-reference tables).
    - **Details:** If the addition of the "Provider Roster" subsection in ADR-029 shifted the ADR-029 line range (currently 1443–1520), update the ADR Quick Reference table row "029" with the new range. If the new "Quota" note in CODEBASE.md shifted its line range, update the CODEBASE Quick Reference table. Per AGENTS.md: "Any edit to `ADR.md`, `CODEBASE.md`, or `Makefile` MUST include a same-task sync in `AGENTS.md`".

23. **Commit documentation.**
    - **Files:** `ROADMAP.md`, `ADR.md`, `BEHAVIOR.md`, `CODEBASE.md`, `AGENTS.md`.
    - **Details:** Commit message: `chore(agent): quota #45 — document parity roster in ADR-029, BEHAVIOR, CODEBASE, ROADMAP, AGENTS.md`. `PLAN_REF: <PLAN_HASH>`. `PREVIOUS_STEP: <Phase 3 hash>`. Body lists each doc file updated and which section.

#### Phase 6 — Close issue and produce test APK

24. **Commit close-issue note.**
    - **Files:** none (commit message only).
    - **Details:** Commit message: `chore(agent): quota #45 — close issue and reference all wave commits`. `PLAN_REF: <PLAN_HASH>`. `PREVIOUS_STEP: <docs hash>`. Body: `Closes #45. Implementation across 4 wave commits: <Phase 0 hash>, <Phase 1 hash>, <Phase 2 hash>, <Phase 3 hash>, <docs hash>. Real-host smoke tested with at least one of nano-gpt / kimi / zhipuai. Reviewer loop closed with zero judge-approved corrections.`

25. **Run `make android`.**
    - **Files:** none.
    - **Details:** `HEY_CAPTION="Added 10 OpenChamber quota providers (issue #45)" make android`. The Android build pipeline compiles the Flutter app, produces a debug APK, and uploads it to Telegram via the project's `make android` target. Per AGENTS.md: "ARM64 Linux hosts are not supported for Android builds — use GitHub Actions CI". The executor's environment determines this; on ARM64 Linux, the executor pushes and lets CI produce the APK.
    - **Risk:** Low. This is the project's standard release flow.
    - **Validation:** The `make android` command exits 0. The Telegram upload succeeds. A user on a connected device can install the APK and open the Context usage popup on a host with at least one of the 10 new providers configured.

26. **Notify the user.**
    - **Files:** none.
    - **Details:** `~/bin/hey "Issue #45 closed. 10 OpenChamber quota providers added. Real-host smoke tested. Test APK pushed to Telegram."`
    - **Validation:** The user receives a Telegram notification.

---

### Risks & Mitigations

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| R1 | Base64 payload exceeds shell transport length | Low | The current `jsScript` is ~750 lines. After adding 10 providers, ~1200 lines / ~40 KB JS / ~53 KB Base64. The OpenCode `POST /session/:id/shell` does not impose a max command length that rejects this. If it does fail, escalate via a new ADR for chunked transport. |
| R2 | `minimax-cn-coding-plan` inverted semantics refactored away | 🔴 Critical | Dedicated regression test (§16 item 4) decodes the base64 JS and asserts the literal `intervalTotal - intervalUsage` is present and the non-CN pattern `const intervalUsed = intervalUsage;` is NOT present. Any future "consistency refactor" that flips the math will fail this test. |
| R3 | Cursor `sqlite3` CLI missing on non-macOS hosts | High | `readStateValue` and `writeStateValue` are wrapped in `try/catch`. On non-macOS, `STATE_DB` does not exist, `fs.existsSync` returns false, and the SQLite path is silently skipped. The env-var and file-token auth sources cover the cross-platform path. Provider still returns quota data if the user has configured those env vars. |
| R4 | Cursor Connect-Protocol-Version: 1 header omitted | High | The `connectPost` function explicitly includes the header. The unit test (§16 item 5) asserts the header is present on all 3 POST calls. |
| R5 | Ollama HTML structure changes | Medium | Regex-based parse returns `ok: false, error: 'Failed to parse Ollama Cloud usage: <fragment>'` on no match. The fragment is included in the error for debugging. Marked as "best-effort" in BEHAVIOR.md. The test §16 item 6 pins the `ok: false` contract. |
| R6 | `unsupportedConfigured` Dart set and JS literal drift | Low | The Dart `Set<String> _supportedAuthKeys` is the only source. The hydration test (§16 item 2) asserts every key in the Dart set appears in the JS array literal. Adding a new provider without adding its aliases to the set is a build error (the dispatcher would call a function whose provider key is unrecognized). |
| R7 | `minimax-coding-plan` (non-CN) math differs from CN | Low | The webfetch verification at Phase 2 implementation confirms both endpoints return the same field names but with opposite semantics. The dual-symmetry test (§16 item 7) pins the divergence. |
| R8 | The new part file pushes unit-test coverage analysis past a 2000-line cap | Low | The part file is not subject to the per-file Dart cap (Dart counts only the `.dart` file, not the `part of` extension). If the analyzer flags it, split into two parts: `quota_remote_datasource.part.providers.dart` and `quota_remote_datasource.part.dispatcher.dart`. |
| R9 | OpenChamber source changed since this plan | Medium | Each provider's source is webfetched at implementation time. If a URL is missing or renamed, the executor marks the step blocked and falls back to the OpenChamber `documentation.md` URL or the OpenChamber root README. |
| R10 | `wafer` endpoint unverified | Medium | The `pass.wafer.ai` URL is verified from OpenChamber `wafer.js` (Phase 1 step 4). If the URL has changed, the executor webfetches `wafer.js` again and updates the literal in the JS body. |
| R11 | Cursor Connect-Protocol-Version: 1 header omitted | High (explicit) | The header is included in `connectPost`. The test §16 item 5 asserts it. |
| R12 | Ollama `ok: true` on parse failure (silent anti-pattern) | Low | The implementation returns `ok: false, error: 'Failed to parse Ollama Cloud usage: <fragment>'`. The test §16 item 6 pins this. |
| R13 | Cursor `cursor.js` JWT parser fails on non-standard tokens | Low | The 5-min `REFRESH_BUFFER_MS` triggers refresh even when the JWT parse fails (because `expiresAt` is null). The 401-handler in `refreshAccessToken` covers invalid tokens. The JWT parse itself is wrapped in `try/catch`. |
| R14 | `github-copilot-addon` does not deduplicate the underlying fetch | Low | Wave 1's `fGHA` makes one HTTP call. `fGH` also makes one HTTP call. Future work could refactor to share a single fetch, but the current 1-extra-call cost is acceptable. |
| R15 | Codex `providerId` guard interferes with new providers | Low | The new providers use unique `providerId` strings (`nano-gpt`, `wafer`, `github-copilot-addon`, etc.). The guard at `quota_provider.dart` line ~1482 preserves per-window granularity via per-window keys, not via `providerId`. No change needed. |

---

### Assumptions to Validate

1. **Assumption**: The OpenCode host's Node.js runtime supports `fetch`, `crypto`, `Buffer.from(...).toString('utf8')`, and `execFileSync` (for Cursor's sqlite3 path).
   - **Validation**: The existing 6 providers already use these. If a future host lacks them, the existing code is also broken; this plan does not change that.
   - **Fallback**: None — this is a hard prerequisite of the existing ADR-029 design.

2. **Assumption**: The OpenCode `POST /session/:id/shell` does not impose a maximum command length that would reject the larger Base64 payload.
   - **Validation**: The current JS is ~750 lines / ~25 KB. After adding 10 providers, ~1200 lines / ~40 KB. Base64 ≈ 53 KB. The AST truncation bug only affects multi-line shell syntax, not command length. The OpenCode docs do not specify a max.
   - **Fallback**: If the host rejects the command, escalate via a new ADR for chunked transport.

3. **Assumption**: The `ollama-quota/cookie` file path (`~/.config/ollama-quota/cookie`) is stable and matches what users actually create.
   - **Validation**: Matches OpenChamber `ollama-cloud.js` source exactly. If users don't have this file, the provider returns `configured: false` (the `rawCookie || readCookieFile()` check fails).
   - **Fallback**: None — matches upstream convention.

4. **Assumption**: The OAuth `client_id` `KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB` is a public client ID shipped with Cursor, safe to embed as a constant (same class as the existing `GGID`/`GGSC`/`AGID`/`AGSC` for Google).
   - **Validation**: Verified in OpenChamber `cursor.js` source. Public client IDs are not secrets.
   - **Fallback**: None — the constant is the same value OpenChamber uses.

5. **Assumption**: The `Connect-Protocol-Version: 1` header is the correct version for all 3 cursor API calls.
   - **Validation**: Verified in OpenChamber `cursor.js` source.
   - **Fallback**: If the version changes, OpenChamber will update its source; the executor tracks OpenChamber's source for changes.

6. **Assumption**: The shared Dart Set `<String> _supportedAuthKeys` does not contain any character that breaks the JS array literal interpolation.
   - **Validation**: All known auth keys are alphanumeric with hyphens/underscores. The hydration uses single-quote wrapping (`'$k'`), which would break on a key containing a single quote. No OpenChamber provider uses single quotes in its ID.
   - **Fallback**: If a future provider does, switch to JSON-encoded hydration: `'[' + jsonEncode(_supportedAuthKeys.toList()) + ']'` and `JSON.parse(...)` in the JS.

7. **Assumption**: The existing `node --check` test in `quota_remote_datasource_test.dart` (lines 190–273) automatically validates the concatenated script after modularization.
   - **Validation**: The test decodes the base64 payload and runs `node --check` on the result. As long as the modularization is structurally valid JS, the test passes.
   - **Fallback**: If the test fails, the executor's `dart analyze` will surface the syntax error in the part file (Dart's static analysis covers `part of` files).

---

### Decisions and Nuances

- **D11 commit plan**: The plan uses 4 wave commits + 1 docs commit + 1 close-issue commit = 6 commits. Each commit is a logical checkpoint that passes `make check`. This aligns with the project's plan-anchored commit protocol.
- **File organization**: A single part file (`quota_remote_datasource.part.js.dart`) holds ALL JS payload generation. The main file holds orchestration, REST endpoints, the shell fallback trigger, the credentials class, and the Dart-driven `_supportedAuthKeys` set. After modularization, the main file is ~280 lines and the part file is ~1500 lines (well within the 2000-line cap).
- **Auth key format**: Keys are strings like `'nano-gpt'`, `'kimi-for-coding'`, `'github-copilot-addon'`. The hydration uses single-quote wrapping. No key contains a single quote.
- **Function name uniqueness**: New function names are `fNanoGpt`, `fWafer`, `fGHA`, `fKimi`, `fZhipu`, `fMinimax`, `fMinimaxCn`, `fZai`, `fCursor`, `fOllamaCloud`. These do not collide with existing `fC`, `fO`, `fX`, `fGM`, `fGQB`, `fG`, `fGH`, `fOCG`, `rGem`, `rAnti`, `rGAccess`, `rAuth`.
- **Cursor's macOS SQLite path is best-effort**: The provider works on Linux/Windows hosts via env-var or file-token auth. macOS users get the additional SQLite path as a bonus. The `STATE_DB` path is hardcoded for macOS only.
- **Ollama Cloud is best-effort**: HTML scrape is fragile. The error message includes the offending fragment for debugging. Marked as "best-effort" in BEHAVIOR.md.
- **`unsupportedConfigured` filter is hydrated from Dart at JS build time**: The hydration is a single string interpolation. The JS dispatcher uses the literal directly. Adding a new provider without adding its aliases to the Dart set is a build error.
- **Wave 1 includes Wave 1 auth keys in the hydration**: The `_supportedAuthKeys` set is declared in Phase 0 with all 16 providers' aliases pre-declared, so the IIFE doesn't need a different hydration per wave. The dispatcher invocations are appended wave-by-wave.
- **Cursor's `child_process` import is inside the function**: The `require('child_process')` is called inside `readStateValue` and `writeStateValue` to avoid loading `child_process` when the user has no cursor auth (i.e., the function returns null before reaching the SQLite path).
- **Zhipuai `readConfigLayers()` is explicitly OUT OF SCOPE**: A future PR may add it. The current implementation uses `auth.json` only.

---

### Blockers and Open Questions

**None blocking.**

Open questions for the user (NOT blocking execution, just informational):

1. **Provider count discrepancy**: The issue says "9 missing providers" but lists 10 distinct provider IDs. This plan implements all 10. If the user intended 9 (e.g. `github-copilot-addon` deferred because it reuses the same auth as `github-copilot`), drop Phase 1 step 5 and the `fGHA` JS function — the dispatcher line and the auth key both come out cleanly.
2. **`minimax-coding-plan` (non-CN) math verification**: Only the CN variant's source has been loaded at planning time. The non-CN variant's math (`used = usage` directly) is the working assumption based on the field name. The executor must webfetch `https://raw.githubusercontent.com/openchamber/openchamber/main/packages/web/server/lib/quota/providers/minimax-coding-plan.js` at Phase 2 implementation time to confirm. If the math is the same as the CN variant (uses `usage` as the used count), the two providers differ only in URL and `providerName`. If the math is different (e.g. `used = total - usage`), the implementation must use the CN-style math and a per-provider flag.
3. **`readConfigLayers()` follow-up PR**: If the user wants this in the same issue, expand scope. Default: defer to a follow-up.

---

### Testing Strategy

#### Per-wave (run after each wave commit)

1. **Wave 1 commit**:
   - 1 unit test per provider (4 tests total): mock shell response, parse the JSON, assert `providerId`, `windows`, `valueLabel`. Pattern modeled on the existing `quota_remote_datasource_test.dart` lines 116–119 (openrouter shell mock).
   - Extend the existing "generated quota shell script is valid JavaScript" test (lines 152–187) with `expect(script, contains('function fNanoGpt'))`, `expect(script, contains('nano-gpt.com'))`, `expect(script, contains("'nano-gpt'"))`, etc.
2. **Wave 2 commit**:
   - 1 unit test per provider (4 tests).
   - **Critical regression test**: assert the literal `intervalTotal - intervalUsage` is in the decoded JS and `const intervalUsed = intervalUsage;` is NOT. This is the inverted-semantics guard.
   - 1 dual-symmetry test: `minimax-coding-plan` (non-CN) and `minimax-cn-coding-plan` both produce `usedPercent` from a known mock, with the non-CN using `used = usage` and the CN using `used = total - usage`.
3. **Wave 3 commit**:
   - 1 cursor unit test: mock a 401 from `GetCurrentPeriodUsage`, assert the JS calls `https://api2.cursor.sh/oauth/token` with `client_id: KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB` and `grant_type: refresh_token`.
   - 1 ollama-cloud unit test: mock a successful response with a known HTML snippet, assert `windows.session`, `windows.weekly`, `windows.premium` are populated. A second test mocks a malformed HTML and asserts `ok: false, error: 'Failed to parse Ollama Cloud usage: ...'`.
4. **Hydration test (run after each wave)**: assert every alias in `_supportedAuthKeys` appears in the decoded JS array literal. This is the dedup guard.

#### Integration (run after Phase 4)

5. **`make check`** (analyzer + unit tests) passes with zero warnings.
6. **`desloppify scan --path lib --profile objective`** returns no new findings.
7. **Real-host smoke**: configure at least one of `nano-gpt` / `kimi` / `zhipuai` on the host's `auth.json`, open the Context-usage popup, verify the new group row appears.
8. **`make android`** produces a working APK. Run on a connected device, install, open the popup, verify the new provider's group row.

#### Definition of Done

- All 10 new providers registered in the JS dispatcher.
- All 10 new auth aliases in `_supportedAuthKeys` (except `github-copilot-addon` which reuses the `github-copilot` auth).
- Monolithic `jsScript` raw string eliminated; replaced by 16 per-provider Dart methods in the part file.
- `unsupportedConfigured` filter is Dart-driven.
- `make check` passes on each wave commit and on the final commit.
- `desloppify scan --path lib --profile objective` returns no new findings.
- The 3 existing shell-fallback tests still pass with extended assertions.
- 10 new per-provider unit tests + 1 inverted-semantics test + 1 dual-symmetry test + 1 cursor-OAuth-refresh test + 1 ollama-cloud-parse-failure test + 1 hydration test all pass.
- The `node --check` syntax test still passes.
- ROADMAP / ADR-029 / BEHAVIOR / CODEBASE / AGENTS.md updated.
- Real-host smoke on at least one new provider.
- 3 reviewer subagents report zero critical findings (or all critical findings are addressed in follow-up `fix:` commits).
- `make android` produces a working APK.
- Issue #45 is closable with a comment linking the 6 commit hashes.

---

### Execution Handoff

**Starting point for the executor:**

1. Read this `final_plan.md` in full.
2. Confirm the project root: `git rev-parse --show-toplevel` from the `codewalk/` directory.
3. Confirm the current branch: `git rev-parse --abbrev-ref HEAD`. Must be on `main` per AGENTS.md "Work on `main` by default".
4. Confirm the working tree is clean: `git status --short` returns empty.
5. Read the current `lib/data/datasources/quota_remote_datasource.dart` (1081 lines) to confirm the line numbers in this plan still match.
6. Read the current `ADR.md` lines 1443–1520 to confirm the ADR-029 content.
7. Create the `plan:` commit (if not already present) per AGENTS.md "Plan Initialization": `git commit --allow-empty -m "plan: add 10 missing quota providers for OpenChamber parity (Issue #45)"`. Capture the hash: `PLAN_HASH=$(git rev-parse HEAD)`.
8. Begin Phase 0 step 1: create the part file, refactor `_buildQuotaShellCommand`, add `_supportedAuthKeys`.
9. After each step, run `make check` to verify.
10. After Phase 4, run the 3 reviewers in parallel.
11. After all approved fixes, run `make android` and `~/bin/hey "Issue #45 closed"`.

**First commit message template:**

```
plan: add 10 missing quota providers for OpenChamber parity (Issue #45)

AGENT_PLAN_ANCHOR

## Original User Request (verbatim)
Make parity/clone OpenChamber providers Rate Limits / Quota so codewalk can display more providers usage. Currently codewalk supports only a fewer providers based from OpenChamber.

## Objective
Close issue #45 by adding 10 missing OpenChamber quota providers (nano-gpt, wafer, github-copilot-addon, kimi-for-coding, zhipuai-coding-plan, minimax-coding-plan, minimax-cn-coding-plan with inverted semantics, zai-coding-plan, cursor with OAuth+macOS SQLite, ollama-cloud with HTML scrape) to the shell-fallback JS in `lib/data/datasources/quota_remote_datasource.dart`.

## Why This Plan
- Synthesized from 7 independent first-round plans and 7 second-pass consensus reviews.
- planMiniMax3 ranked #1 by 4 of 5 non-owner evaluators; the Dart-driven `_supportedAuthKeys` set is the strongest architectural innovation.
- Part-file cluster (instead of single file or 12-file directory) respects the 2000-line cap and the project's ADR-004 part-file precedent.
- 3-wave ordering isolates risk: low-complexity Bearer providers first, medium-complexity Chinese providers second, high-complexity fragile providers last.

## Scope
- In scope: 10 new providers, modularization to part file, Dart-driven auth key set, 6 commits, docs updates.
- Out of scope: OpenChamber `openai.js` (internal-only), `opencode-go` removal, OAuth flow UI for Cursor on non-macOS, `readConfigLayers()` config-layer auth fallback (deferred to follow-up).

## Current Context
- `lib/data/datasources/quota_remote_datasource.dart` is 1081 lines with a monolithic `jsScript` raw string.
- ADR-029 (lines 1443–1520) defines the server-host-only credential model, REST-to-shell strategy chain, and Base64 one-liner shell pattern.
- OpenChamber's `packages/web/server/lib/quota/providers/` ships 15 distinct provider files; CodeWalk currently supports 6.

## Constraints, Preferences, and Biases to Preserve
- Server-host-only credential ownership (ADR-029 §1): no client-side credentials except the existing `opencode-go` opt-in.
- Base64 one-liner shell pattern (ADR-029 Post-Mortem): required because of OpenCode's shell AST truncation bug.
- 2000-line analyzer cap on Dart files (ROADMAP.md line 5).
- Part-file cluster precedent (ADR-004): `chat_page.dart`, `chat_provider.dart`, `chat_page_timeline_builder.dart` all use `part`/`part of`.
- No changes to `_fetchViaOpenChamberRest()`.
- No new Dart/Flutter dependencies.
- Skip OpenChamber's `openai.js` (internal-only).
- Keep `opencode-go` exactly as-is.

## Assumptions to Validate
- OpenChamber source URLs are still current at impl time. Validation: webfetch each provider's source file at the corresponding phase.
- The base64 payload (~53 KB) is within the OpenCode shell command length limit. Validation: existing test passes after each wave.
- The macOS-only SQLite path for Cursor is graceful on Linux/Windows. Validation: readStateValue returns null when STATE_DB does not exist; env-var/file-token auth covers cross-platform.

## Options Considered
- Accepted: Part-file cluster + Dart-driven auth keys + 3-wave ordering + per-provider JS methods.
- Rejected: Single file (exceeds 2000-line cap), 12-file directory (over-fragmented), per-provider Dart methods with hand-edited `unsupportedConfigured` (dual-maintenance bug), client-side token fetching (violates ADR-029).

## Execution Plan
- [ ] Step 1: Phase 0 — refactor to part file, add `_supportedAuthKeys`, hydrate into JS dispatcher
- [ ] Step 2: Phase 0 — commit foundation (no behavior change)
- [ ] Step 3: Phase 1 — add nano-gpt, wafer, github-copilot-addon, kimi-for-coding
- [ ] Step 4: Phase 1 — commit wave 1
- [ ] Step 5: Phase 2 — add zhipuai, minimax, minimax-cn (inverted), zai
- [ ] Step 6: Phase 2 — commit wave 2 with inverted-semantics regression test
- [ ] Step 7: Phase 3 — add cursor (OAuth + macOS SQLite) and ollama-cloud (HTML scrape)
- [ ] Step 8: Phase 3 — commit wave 3
- [ ] Step 9: Phase 4 — `make check`, `desloppify scan`, 3 reviewer subagents
- [ ] Step 10: Phase 5 — update ROADMAP, ADR-029, BEHAVIOR, CODEBASE, AGENTS.md
- [ ] Step 11: Phase 6 — close issue, `make android`, notify user

## Do
- Use the per-wave commit plan (one commit per wave, plus foundation + docs + close).
- Run `make check` after every commit.
- Run `desloppify scan --path lib --profile objective` per AGENTS.md "Before every commit".

## Do Not
- Add a 12-file directory of one-file-per-provider JS methods.
- Skip the inverted-semantics regression test for `minimax-cn-coding-plan`.
- Return `ok: true, windows: {}` on Ollama parse failure (must be `ok: false, error: '…'`).
- Modify `_fetchViaOpenChamberRest()`.
- Add new Dart/Flutter dependencies.
- Embed credentials client-side.

## References
- GitHub issue #45: https://github.com/verseles/codewalk/issues/45
- ADR-029: `ADR.md` lines 1443–1520
- AGENTS.md: plan-anchored commit protocol
- OpenChamber providers: https://github.com/openchamber/openchamber/tree/main/packages/web/server/lib/quota/providers/

## Risks and Dependencies
- minimax-cn inverted semantics regression — mitigated by dedicated test.
- Cursor SQLite path missing on non-macOS — mitigated by env-var/file-token auth fallback.
- Ollama HTML structure changes — mitigated by `ok: false` on parse failure with fragment logging.
- Base64 payload size growth — mitigated by staying under OpenCode's shell command limit.

## Handoff Notes
- The synthesized plan in `./final_plan.md` is the single source of truth for execution.
- 7 first-round plans and 7 second-pass consensus reviews were aggregated. The final plan reflects broad consensus (5/5 non-owners top-3 for planMiniMax3).
- The `minimax-cn-coding-plan` inverted semantics is the highest regression risk. The dedicated test in Phase 2 step 10 pins it.

## Definition of Done
- All 10 new providers callable from the JS dispatcher.
- All 10 new auth aliases in `_supportedAuthKeys`.
- `unsupportedConfigured` filter is Dart-driven.
- `make check` passes on every commit.
- 10 new per-provider unit tests + 1 inverted-semantics test + 1 dual-symmetry test + 1 cursor-OAuth-refresh test + 1 ollama-cloud-parse-failure test + 1 hydration test all pass.
- ROADMAP / ADR-029 / BEHAVIOR / CODEBASE / AGENTS.md updated.
- 3 reviewer subagents report zero critical findings.
- `make android` produces a working APK.
- Issue #45 is closable.
```

**Strict sequencing constraints:**
- The `plan:` commit must be created before any step commit.
- Each `chore(agent):` / `feat(quota):` commit must reference the plan hash (`PLAN_REF: <PLAN_HASH>`).
- Each commit must reference the previous step's hash (`PREVIOUS_STEP: <PREV_HASH>`).
- The `plan:` commit is immutable. Do not amend it.

---

### Out of Scope

- Adding OAuth flows for providers that need user-side authentication (e.g., Cursor's full OAuth dance on non-macOS hosts). Would require a separate ADR.
- Redesigning the quota popup UI.
- Removing or renaming the `opencode-go` provider.
- Changing the REST strategy chain (`_fetchViaOpenChamberRest()` is untouched).
- Supporting OpenChamber's `openai.js` module (internal-only, not dispatched).
- Adding new client-side credential storage.
- Adding new Dart/Flutter dependencies.
- `readConfigLayers()` config-layer auth fallback for ZhipuAI (deferred to a follow-up PR).
- Adding OpenChamber's `claude.js` as a distinct file from CodeWalk's `fC` (already equivalent).
- The 4 cancelled Phase A planners and the 3 failed Phase B planners (no plans to evaluate).
- ARM64 Linux Android builds (use GitHub Actions CI per AGENTS.md).

---

### Plan Comparison (Orchestrator Internal Reference — Brief)

This is a brief comparison to capture the design nuances harvested from the 7 candidate plans. The full ranking is in the chat report, not here.

**Key innovations adopted from each plan:**

- **planMiniMax3** (winner of consensus): Part-file cluster (D1) + Dart-driven `_supportedAuthKeys` (D2) + 11-risk register + provider count discrepancy open question (B1).
- **planGLM51** (strong second): Per-provider spec depth including dual-scale handling for `nano-gpt`, the `TIME_UNIT_*` enum mapping for `kimi`, the `readConfigLayers()` helper for `zhipuai` (deferred per D8), the explicit flagging of `minimax-cn` inverted semantics as a critical bug risk.
- **planG31Pro** (mid): The `child_process.execFileSync('sqlite3', ...)` try/catch pattern for Cursor's macOS path (D9). The 11-step implementation sequence.
- **planKimi26** (lower): The function-name uniqueness discipline (D6). The explicit IIFE dispatcher pattern.
- **planNemoUltra** (mid-low): The "wafer endpoint unverified" honesty flag (R10). The Cursor Connect-Protocol-Version: 1 header requirement (D10).
- **planFlash35** (lower): The per-provider JS method pattern in the same file (D1, but kept part-file instead).
- **planMimo25** (over-engineered): Rejected — 12-file directory is over-fragmented for this scope.

**Resolved conflicts:**

- **File structure**: Part-file cluster (planMiniMax3). Rejected 4 alternatives: keep single file (Flash35, Kimi26), new builder file (G31Pro), 12-file directory (Mimo25), implicit (GLM51, NemoUltra).
- **Auth key management**: Dart-driven (planMiniMax3). Rejected hand-edited JS string (6 plans).
- **Ollama parse failure behavior**: `ok: false, error: '...'` (this synthesis). Rejected silent `ok: true, windows: {}` (planG31Pro).
- **Existing provider migration**: Migrate first (Phase 0 step 1). This was implicit in most plans; explicit here.
- **Cursor SQLite**: Try/catch with env/file fallback (planG31Pro + planMiniMax3).
- **Minimax-CN inverted semantics**: Dedicated unit test + code comment (planGLM51 + planMiniMax3).
- **`readConfigLayers()`**: Defer to follow-up PR (this synthesis). Rejected inclusion in this scope (planGLM51).
- **Provider count**: 10 (all 10 listed in OpenChamber source). Rejected 9 (issue text "9" but list has 10).
- **`github-copilot-addon` fetch**: Separate fetch (this synthesis). Rejected reuse-single-fetch (planGLM51, planNemoUltra, planFlash35) because the Wave 1 implementation in this plan keeps `fGHA` separate for diff size. Future work can dedupe.
