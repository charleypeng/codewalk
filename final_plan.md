# Final Execution Plan: Safely Remediate PR #37 While Preserving Contributor Credit

## Purpose

This document is a complete, self-contained execution plan for correcting PR #37 before merge. It assumes no previous chat context is available.

PR #37 adds OAuth 2.0 + PKCE support for Cloudflare Access in CodeWalk. The feature is valuable for users who run OpenCode remotely behind Cloudflare Access, but the current implementation needs security, platform, documentation, i18n, and test corrections before it can be merged safely.

The goal is to apply the corrections directly on top of the contributor's PR branch, while preserving the original contributor's commits and credit.

## Important Decision

ADR-023 compatibility should not block this feature. Treat Cloudflare Access OAuth as an intentional ADR-023 exception.

The exception rationale is:

- Official OpenCode server authentication remains unchanged: OpenCode still supports Basic Auth through `OPENCODE_SERVER_PASSWORD`.
- Cloudflare Access OAuth is not an OpenCode server API replacement. It is an external access layer in front of the OpenCode server.
- CodeWalk can support this reverse-proxy authentication layer as an optional server-profile mode.
- The exception must be documented explicitly so future maintainers do not confuse Cloudflare Access OAuth with official OpenCode server auth.

## Credit Policy

Preserve the original PR author's credit.

Do this by:

- Keeping the contributor's existing commits intact.
- Adding maintainer remediation commits on top of the PR branch.
- Avoiding squash merge unless the final merge message explicitly preserves authorship and co-authorship.
- Prefer merge commit or rebase-and-merge if the repository policy allows it, because both preserve visible commit authorship better than a squash.
- If a squash is unavoidable, include the original author in the squash body using `Co-authored-by: charleypeng <charleypeng@gmail.com>` and mention PR #37 in the final message.

Existing contributor commits in PR #37:

- `a6d8604bd5b0362ef82e79f8f5faf560e4583e44` — `feat(auth): add OAuth 2.0 + PKCE support for Cloudflare Access`
- `26367e6cc9504a84fe382eab1a9fb7b5abd165bd` — `fix(ui): wrap onboarding form in SingleChildScrollView to prevent overflow`

## PR Metadata

- PR number: #37
- Contributor: `charleypeng` / Peng Lei
- Contributor fork branch: `charleypeng/codewalk:main`
- Base branch: `verseles/codewalk:main`
- Maintainers can modify PR branch: `true`
- Original change size: 9 files, approximately +875 / -11 lines
- Main feature: optional Cloudflare Access Managed OAuth authentication for server profiles

## Current Risk Summary

The PR must not be merged as-is because it currently has these issues:

- OAuth callback accepts authorization codes even when `state` mismatches.
- OAuth tokens can be written to plaintext file fallback storage.
- Shared auth code imports `dart:io` directly, risking web build failure.
- Loopback redirect is desktop-oriented and does not work as-is on Android/iOS.
- Several UI strings are hardcoded and bypass localization.
- `DioClient.setOAuthToken(null)` can remove `Authorization`, risking Basic Auth regressions.
- OAuth cached-token activation is incomplete.
- `HttpClient` instances are created without systematic cleanup.
- DCR `client_uri` points to the contributor fork instead of the official project.
- There are no meaningful tests for the new OAuth service/storage/network behavior.

## Mandatory Local Anchors

Before implementation, read these files in the target checkout:

- `AGENTS.md`
- `ADR.md`
- `BEHAVIOR.md`
- `CODEBASE.md`
- `ai-docs/opencode_server.md`
- `ai-docs/opencode_web.md`
- `ai-docs/opencode_config.md`
- `Makefile`
- `pubspec.yaml`

Key local facts that must guide implementation:

- `ai-docs/opencode_server.md` documents official OpenCode server auth as Basic Auth via `OPENCODE_SERVER_PASSWORD`.
- ADR-001 requires secure, server-scoped credential storage.
- ADR-023 requires contract-first compatibility, but this plan intentionally creates a documented exception for Cloudflare Access as an external access layer.
- `BEHAVIOR.md` says tokens and credentials must never appear in logs, errors, exports, or user-visible surfaces.
- CodeWalk must prioritize mobile UX while preserving desktop behavior.
- The project uses Material You / MD3 style and localization for UI copy.

## External References To Use

Use these references during implementation and code review:

- RFC 7636: OAuth 2.0 PKCE, S256 challenge method.
- RFC 8252: OAuth 2.0 for native apps, loopback redirect guidance for desktop/native clients.
- RFC 9700: OAuth 2.0 Security Best Current Practice.
- Cloudflare Access Managed OAuth docs: Managed OAuth, OAuth metadata, DCR, and PKCE behavior.
- OpenChamber repository: `https://github.com/openchamber/openchamber`

OpenChamber findings relevant to this plan:

- No direct Cloudflare Access OAuth implementation was found.
- OpenChamber does include Cloudflare tunnel and remote relay concepts.
- Useful patterns from OpenChamber include outbound-only connectivity, short-lived enrollment tokens, revocable agent secrets, same-origin proxying, explicit failure states, and stripping `cookie`, `authorization`, and UI session headers before forwarding requests.
- These patterns should inform CodeWalk's threat model and future remote/tunnel architecture, but they should not be copied blindly into the OAuth PR.

Useful OpenChamber files to inspect during implementation:

- `docs/PREVIEW_REMOTE_RELAY.md`
- `packages/web/server/lib/tunnels/providers/cloudflare.js`
- `packages/web/server/lib/opencode/tunnel-auth.js`
- `packages/web/server/lib/tunnels/routes.js`
- `packages/web/server/lib/preview/proxy-runtime.js`
- `packages/web/server/lib/ui-auth/ui-auth.js`

## Isolated Workspace Setup

Use an isolated worktree so local changes on `main` are not mixed with PR remediation.

Recommended commands:

```bash
cd /home/ubuntu/MEGA/WORK/codewalk
git fetch origin pull/37/head:pr-37-remediation
git worktree add /tmp/opencode/codewalk-pr37 pr-37-remediation
cd /tmp/opencode/codewalk-pr37
git status --short --branch
git log --oneline -5
```

If the local branch already exists:

```bash
cd /home/ubuntu/MEGA/WORK/codewalk
git fetch origin pull/37/head
git branch -f pr-37-remediation FETCH_HEAD
git worktree add /tmp/opencode/codewalk-pr37 pr-37-remediation
```

Before pushing corrections back to the contributor branch, configure a remote for the contributor fork:

```bash
cd /tmp/opencode/codewalk-pr37
git remote add charleypeng https://github.com/charleypeng/codewalk.git || true
git fetch charleypeng main
```

Only push after checks and reviews pass:

```bash
git push charleypeng HEAD:main
```

## Plan Commit Protocol

Because this is a multi-step remediation, start with an empty plan commit in the isolated PR worktree before code changes.

Suggested subject:

```text
plan: remediate PR 37 Cloudflare Access OAuth
```

The body must include `AGENT_PLAN_ANCHOR`, the objective, constraints, phases, validation gates, and a note that contributor commits must remain intact.

Do not amend this plan commit after execution begins.

## Phase 1: Document The ADR-023 Exception

Create a new ADR for Cloudflare Access OAuth support.

Required ADR content:

- Title: Cloudflare Access OAuth for remote OpenCode servers.
- Status: Accepted or Proposed until final approval.
- Context: users run OpenCode remotely and protect it with Cloudflare Access.
- Decision: CodeWalk supports Cloudflare Access Managed OAuth as an optional server-profile auth mode.
- ADR-023 exception: this intentionally extends client behavior for a reverse-proxy access layer while preserving official OpenCode server API semantics.
- Non-goal: do not claim OpenCode server natively supports OAuth.
- Basic Auth remains first-class and unchanged.
- OAuth and Basic Auth are mutually exclusive per server profile.
- Security requirements: PKCE S256, strict state validation, secure storage only, no plaintext fallback, no token logging.
- Platform policy: desktop loopback supported first; mobile must be disabled or implemented via app links/custom scheme; web must compile safely and not import `dart:io`.
- Rollback: disable OAuth mode and keep Basic Auth profiles working.
- Tests required before merge.

Documentation files that may need updates:

- `ADR.md`
- `AGENTS.md` ADR quick reference table and line ranges
- `BEHAVIOR.md`
- `CODEBASE.md` if new auth modules remain

Important: use the project's ADR/doc workflow. Do not directly edit ADR/CODEBASE if the active agent system requires subagents for those files.

Completion criteria:

- The exception is explicit and reviewable.
- Future maintainers can understand why this does not replace OpenCode Basic Auth.
- Rollback and platform limits are documented.

## Phase 2: Fix OAuth Security

### 2.1 Reject State Mismatch

Current risk:

- The PR accepts an authorization code even when `returnedState != state`.
- This weakens CSRF protection.

Required change:

- If provider returns `error`, fail the flow.
- If `code` exists and `returnedState == state`, accept the code.
- If `code` exists and `returnedState != state`, reject the callback and do not exchange the code.
- If state is missing, reject.
- Do not log full callback URLs containing code or state.

Tests:

- Matching state succeeds.
- Mismatched state fails.
- Missing state fails.
- Provider error fails.

### 2.2 Remove Plaintext Token Fallback

Current risk:

- `OAuthTokenStorage` writes token JSON files under app support storage.
- Access tokens and refresh tokens must not be persisted in plaintext fallback files.

Required change:

- Store OAuth credentials only in `flutter_secure_storage` or an existing project-approved secure credential abstraction.
- If secure storage is unavailable, fail gracefully and require re-authentication.
- Do not silently downgrade to plaintext token persistence.
- Delete legacy plaintext OAuth files as cleanup if they may have been created during development, without logging token contents.

Tests:

- Secure save/load/delete works.
- Server URL key scoping works.
- Secure-storage failure does not create files.
- Corrupt/missing storage returns null safely.

### 2.3 Redact Logs And User Errors

Audit every OAuth log.

Required behavior:

- Never log access tokens.
- Never log refresh tokens.
- Never log authorization codes.
- Never log full callback URLs with query strings.
- Never show protocol payloads in snackbars or error UI.
- Log endpoint hosts and high-level status only.

### 2.4 Fix DCR Client Metadata

Current issue:

- `client_uri` points to `https://github.com/charleypeng/codewalk`.

Required change:

- Use the official CodeWalk repository URL, or omit `client_uri` if no official URL should be registered.

Completion criteria for Phase 2:

- OAuth cannot complete with invalid state.
- No plaintext token storage remains.
- No sensitive token/code material is logged or displayed.
- DCR metadata no longer points to the contributor fork.

## Phase 3: Fix Platform Architecture

### 3.1 Remove Direct `dart:io` From Shared Auth Code

Current risk:

- `oauth_service.dart` imports `dart:io` directly.
- This can break web builds and violates the project's platform split style.

Required architecture:

- Shared interface/helpers in `oauth_service.dart` or equivalent.
- IO implementation in `oauth_service_io.dart` or equivalent.
- Web-safe implementation in `oauth_service_web.dart` or equivalent.
- Conditional import/export if needed.

Rules:

- Shared/core files must not import `dart:io`.
- Web build/analyze path must remain safe.
- Unsupported platform behavior must be explicit and user-safe.

### 3.2 Choose Mobile Strategy Deliberately

Recommended for this PR: desktop-first OAuth, mobile disabled until a proper mobile redirect strategy exists.

Reason:

- Loopback `127.0.0.1` callback is not a correct Android/iOS strategy.
- Proper mobile support needs Android App Links / iOS Universal Links or a project-owned custom scheme.
- That is a separate platform feature with manifests, callbacks, and tests.

Required behavior if mobile is deferred:

- Hide or disable the OAuth toggle on Android/iOS.
- Explain that Cloudflare Access OAuth is currently desktop-only.
- Keep Basic Auth available on mobile.
- Add tests for unsupported mobile UI state where possible.

Alternative future path:

- Implement mobile redirect using verified app links/universal links or a custom scheme.
- Register platform manifests.
- Add platform callback handling.
- Add mobile manual validation steps.

### 3.3 Harden Desktop Loopback Redirect

Required behavior:

- Bind only to `127.0.0.1`.
- Use an ephemeral port selected before auth URL construction.
- Use a callback path like `/oauth/callback` instead of the bare origin.
- Verify request path exactly.
- Accept only the first terminal callback.
- Close the server after success, error, timeout, or launch failure.
- Use strict state validation.

### 3.4 Close Network Resources

Current risk:

- Multiple `HttpClient()` instances are created without systematic cleanup.

Required behavior:

- Close every `HttpClient` in `finally`, or replace one-off `HttpClient` usage with a managed helper/client.
- Ensure timeout paths also clean up.

Completion criteria for Phase 3:

- Web-safe compile path.
- Mobile does not expose a broken OAuth path.
- Desktop callback behavior is hardened.
- No network resource leaks remain.

## Phase 4: Fix Auth State And Network Integration

### 4.1 Separate Basic Auth And OAuth Ownership

Current risk:

- `setOAuthToken(null)` removes `Authorization`, which can break Basic Auth.

Required behavior:

- Clearing OAuth removes only the OAuth header owned by OAuth.
- Basic Auth is cleared only by existing profile switching or explicit Basic Auth clear logic.
- HTTP Dio and SSE Dio remain consistent.

Tests:

- Basic Auth survives OAuth clear when Basic Auth profile is active.
- OAuth header is applied to HTTP and SSE clients.
- Switching OAuth to Basic Auth results in only Basic Auth.
- Switching Basic Auth to OAuth results in only OAuth.

### 4.2 Load Cached OAuth Credentials On Profile Activation

Current issue:

- `_applyProfileAuth` does not actually load valid cached OAuth credentials.

Required behavior:

- When OAuth-enabled server profile becomes active, load valid secure credential.
- If token is valid, apply it before health checks and SSE calls.
- If expired and refresh token exists, refresh safely.
- If missing/invalid, surface authentication-required state and avoid retry loops.

Tests:

- Valid cached token is applied.
- Expired token attempts refresh.
- Missing token does not mark OAuth authenticated.

### 4.3 Challenge Detection Must Be Scoped

Required behavior:

- Only trigger OAuth challenge handling for OAuth-enabled profiles.
- Do not treat normal OpenCode Basic Auth failures as OAuth challenges.
- Store challenge metadata server-scoped.
- Clear challenge metadata after success, profile removal, or explicit clear.

Tests:

- Basic Auth 401 does not start OAuth.
- Cloudflare Access challenge starts OAuth only on OAuth profile.
- Challenge state is cleared after success/clear.

Completion criteria for Phase 4:

- Existing Basic Auth behavior is non-regressed.
- OAuth token lifecycle works across app restart/profile activation.
- Challenge handling cannot hijack unrelated server errors.

## Phase 5: Apply OpenChamber-Inspired Safety Patterns

Do not copy OpenChamber code directly. Use the architectural lessons that fit CodeWalk.

Relevant OpenChamber concepts:

- Explicit trust boundary for remote access.
- Short-lived enrollment/auth initiation material.
- Revocable long-lived secret where applicable.
- Same-origin/proxy behavior when browsers are involved.
- Strip sensitive forwarding headers such as `authorization` and `cookie` when proxying to a different trust boundary.
- Explicit failure states instead of silent hangs.
- Avoid public-internet exposure of local services.

How to apply to PR #37:

- Treat Cloudflare Access OAuth as a profile-scoped trust boundary.
- Keep OAuth tokens scoped to one server URL/profile.
- Never forward OAuth credentials to non-matching base URLs.
- Ensure redirects and metadata discovery cannot leak tokens to arbitrary hosts.
- Surface clear states: needs authentication, authentication failed, unsupported platform, token cleared.
- Do not add a tunnel/proxy feature in this PR.

Completion criteria:

- The ADR mentions OpenChamber as a non-official reference and explains what patterns were adopted.
- Code ensures tokens are scoped to the active server base URL.
- No general-purpose proxy/tunnel behavior is introduced.

## Phase 6: UX And Localization

### 6.1 Localize All User-Facing Strings

Replace hardcoded strings with project i18n.

Minimum strings:

- `Use OAuth (Cloudflare Access)`
- `Opens browser for authentication. Requires Managed OAuth on the server.`
- `OAuth`
- `Re-authenticate`
- `Clear OAuth`
- `OAuth authentication failed`
- Desktop-only / unsupported-platform explanation
- Authentication-required copy

Update all ARB/localization files required by the project.

### 6.2 Improve Onboarding Copy

Required UX:

- Basic Auth remains labeled as the official OpenCode server auth option.
- Cloudflare Access OAuth is described as an optional remote/proxy auth option.
- Mutual exclusivity between Basic Auth and OAuth remains obvious.
- Unsupported platforms do not show a broken toggle.
- Mobile layout remains usable with keyboard and compact height.

### 6.3 Improve Settings Copy And Actions

Required UX:

- Show auth mode clearly: None, Basic Auth, or Cloudflare Access.
- Show Re-authenticate only when relevant.
- Clear OAuth should explain that it clears local credentials only.
- Avoid showing raw provider/challenge technical details to users.

Completion criteria:

- No new OAuth UI copy is hardcoded.
- Desktop and mobile layouts are reviewed.
- Users can distinguish OpenCode Basic Auth from Cloudflare Access OAuth.

## Phase 7: Tests

Add tests before merge.

Required unit coverage:

- `OAuthCredential`
  - JSON round-trip
  - expiration threshold behavior
  - empty token invalid behavior

- `OAuthTokenStorage`
  - secure save/load/delete
  - server URL scoping
  - secure-storage failure behavior
  - no plaintext fallback creation

- `OAuthService` or split platform service
  - challenge detection
  - metadata parsing
  - Cloudflare domain extraction if kept
  - PKCE verifier/challenge format
  - state mismatch rejection
  - unsupported platform behavior

- `DioClient`
  - OAuth header injection for HTTP
  - OAuth header injection for SSE
  - Basic Auth and OAuth header separation
  - OAuth clear does not clear Basic Auth accidentally

- `AppProvider`
  - OAuth profile activation with cached credential
  - OAuth challenge state tracking
  - OAuth clear behavior
  - Basic Auth profile behavior remains unchanged

Required widget coverage:

- Onboarding auth mode selection:
  - Basic Auth and OAuth are mutually exclusive.
  - Unsupported platform state is safe.
  - Localized labels are used.

- Server settings actions:
  - OAuth badge/action visibility is correct.
  - Clear OAuth action calls provider path.
  - Re-authenticate action is available only when valid.

Manual validation matrix:

- Desktop Linux: OAuth happy path behind Cloudflare Access.
- Desktop Linux: provider error path.
- Desktop Linux: state mismatch path.
- Desktop Linux: expired token refresh path if refresh is implemented.
- Android: OAuth hidden/disabled if deferred; Basic Auth still works.
- Web: analyze/build path does not fail due to `dart:io`.
- Existing Basic Auth OpenCode server: connect, health check, chat/SSE still work.

## Phase 8: Quality Gates

Run checks incrementally.

Recommended sequence after implementation:

```bash
flutter pub get
make check
```

Run targeted tests as they are added, for example:

```bash
flutter test test/unit/auth
flutter test test/unit/providers/app_provider_test.dart
flutter test test/unit/network
flutter test test/widget
```

Before every commit, follow project rules:

```bash
desloppify scan --path lib --profile objective
```

For Android:

- Do not rely on local Android APK builds on ARM64 Linux.
- Use GitHub Actions for final Android APK validation if needed.

Reviewer loop after implementation commits:

- Prepare a canonical review payload covering all remediation commits.
- Run both reviewer agents in parallel.
- Judge findings critically.
- Apply only accepted fixes.
- Repeat until no accepted findings remain.

## Suggested Maintainer Commit Breakdown

Use small, auditable commits on top of the contributor commits.

Suggested order:

1. `plan: remediate PR 37 Cloudflare Access OAuth`
2. `docs: document Cloudflare Access OAuth exception`
3. `fix(auth): enforce strict OAuth callback state validation`
4. `fix(auth): remove plaintext OAuth token fallback`
5. `refactor(auth): split OAuth flow by platform`
6. `fix(network): isolate Basic Auth and OAuth headers`
7. `fix(auth): load cached OAuth credentials for active profiles`
8. `fix(ui): localize Cloudflare Access OAuth settings`
9. `test(auth): cover OAuth credential and PKCE behavior`
10. `test(network): cover auth header ownership`
11. `test(ui): cover OAuth onboarding and server settings`
12. `docs: sync behavior and codebase references`

If a phase is too large, split it further. Do not batch unrelated fixes.

## Merge Readiness Checklist

The PR is merge-ready only when every item is complete:

- [ ] Contributor commits remain intact.
- [ ] Maintainer remediation commits are on top of the PR branch.
- [ ] ADR documents Cloudflare Access OAuth as an ADR-023 exception.
- [ ] Official OpenCode Basic Auth contract remains unchanged.
- [ ] No plaintext OAuth token fallback remains.
- [ ] OAuth callback rejects missing or mismatched `state`.
- [ ] OAuth sensitive data is not logged or displayed.
- [ ] DCR metadata does not reference the contributor fork.
- [ ] Shared auth code does not import `dart:io` directly.
- [ ] Web analyze/build path is safe.
- [ ] Mobile does not expose a broken OAuth flow.
- [ ] Desktop loopback redirect is hardened.
- [ ] `HttpClient` resources are cleaned up.
- [ ] Basic Auth and OAuth headers are isolated.
- [ ] Cached OAuth credentials are loaded on OAuth profile activation.
- [ ] OAuth challenge detection is scoped to OAuth-enabled profiles.
- [ ] OpenChamber-inspired safety patterns are captured in ADR/threat model.
- [ ] All new UI strings are localized.
- [ ] Unit tests cover OAuth credential/storage/service behavior.
- [ ] Network tests cover header ownership.
- [ ] Widget tests cover onboarding/settings OAuth states.
- [ ] `make check` passes.
- [ ] Reviewer loop finds no accepted blocking findings.

## Rollback Strategy

If the remediation becomes too large or risky:

1. Stop direct PR changes.
2. Do not merge PR #37.
3. Ask the contributor to split the feature into smaller PRs:
   - ADR and behavior documentation.
   - Secure OAuth credential storage and tests.
   - Desktop-only Cloudflare Access OAuth behind platform gating.
   - Mobile redirect support in a later PR.
4. Keep Basic Auth as the only supported authentication mode until the split PRs pass review.

## Final Recommendation

Proceed slowly and correct PR #37 directly only if the team accepts Cloudflare Access OAuth as a first-class CodeWalk feature with an explicit ADR-023 exception.

The correct path is to preserve the original contributor's work, add maintainer commits on top, validate thoroughly, and only then merge.
