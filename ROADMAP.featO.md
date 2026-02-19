# ROADMAP.featO - Code Health & Technical Debt

## Scope

Systematic elimination of bugs, security gaps, performance issues, dead code, and architectural violations identified through deep codebase analysis. See `ROADMAP.featO.research.md` for detailed findings, code snippets, and line references.

### Group 1 — Bug fixes (critical, localized changes) `[ ]`

**2026-02-17 Regression Fixes Batch** - Commit: 00583f0
- [x] 1.1: Auto-follow only disables on real manual scroll intent (not programmatic scrolls or momentum) - Commit: 00583f0
- [x] 1.2: Foreground resume catches up to latest when user is not browsing older history - Commit: 00583f0
- [x] 1.3: Rejected/failed send restores composer draft automatically for retry - Commit: 00583f0
- [x] 1.4: Stop/send state no longer stays stuck on Stop after session becomes idle/stream ends - Commit: 00583f0

**Follow-up after v1.10.1** - Commit: beb5265
- [x] 1.3.1: Rejected draft restore should NOT repopulate composer when user returns to chat later (only immediate retry within same session) - Commit hash: beb5265

- [x] 1.5: Change `registerFactory` to `registerLazySingleton` for `AppProvider` and `ChatProvider` in `injection_container.dart` (resource leak: multiple polling timers, concurrent health checks, unmanaged state) - Closed after necessity review.
- [ ] 1.6: Move state mutation out of `build()` in `chat_page.dart` (`_wasCompactingContext` and `_frozenCompactionBoundaryId` mutated during build phase via `_buildMessageTimelineEntries`)
- [x] 1.7: Add `_disposed` guard to `ChatProvider.dispose()` to prevent `notifyListeners()` on a disposed provider (async cancellation outlives `super.dispose()`) - Closed after necessity review.
- [ ] 1.8: Add concurrency guard to health polling in `AppProvider` (timer fires every 10s but sequential health checks can exceed 10s, causing concurrent `_serverHealthById` mutation)
- [ ] 1.9: Implement Markdown link tap handler in `chat_message_widget.dart` (currently a TODO with empty body, links silently ignored)
- [x] 1.10: Remove dead `SessionRepository` interface (`lib/domain/repositories/session_repository.dart` — no implementation, no import, no test, no fake) - Closed after necessity review.

### Group 2 — Security hardening `[ ]`
- [ ] 2.1: Migrate credentials from `SharedPreferences` to `flutter_secure_storage` (`apiKey`, `basicAuthPassword`, `basicAuthUsername` stored as plaintext in `app_local_datasource.dart`)
- [x] 2.2: Use streaming SHA-256 instead of `readAsBytes()` in `local_opencode_server_runtime_io.dart` (loads entire binary release ~50-200MB into RAM before hashing) - Closed after necessity review.

### Group 3 — Performance `[ ]`
- [x] 3.1: Cache shortcut/action maps outside of `build()` in `chat_page.dart` (two maps with 8+ entries each allocated fresh on every rebuild) - Closed after necessity review.
- [x] 3.2: Memoize `_collectSentMessageHistory` in `chat_page.dart` (iterates all messages on every rebuild, called from a `Builder` inside `build()`) - Closed after necessity review.
- [x] 3.3: Reuse or properly close Dio instances in health check (`app_provider.dart` creates a new `Dio()` per profile per 10s timer, never closed) - Closed after necessity review.
- [ ] 3.4: Convert `ChatSessionList` to use `ListView.builder` with cached tree structure (currently builds all tiles eagerly without virtualization)

### Group 4 — Code cleanup `[x]`
- [x] 4.1: Remove dead constants from `app_constants.dart` and `api_constants.dart` (9+ unused constants including `appVersion`, `appDescription`, `storageSchemaVersionKey`, `migrationV1ToV2CompletedKey`, error message strings, HTTP verb constants, endpoint paths) - Closed after necessity review.
- [x] 4.2: Replace hardcoded values with existing constants (59+ occurrences of literal `16`, `8`, `24` where `AppConstants.defaultPadding/smallPadding/largePadding` exist; hardcoded host/port where `ApiConstants.defaultHost/defaultPort` exist) - Closed after necessity review.
- [x] 4.3: Extract shared error handling wrapper in repository implementations (104 repetitive try/catch clauses in `chat_repository_impl.dart` alone, identical pattern across 3 repos) - Closed after necessity review.
- [x] 4.4: Extract `queryParams` helper in datasources (28+ repetitions of `directory != null` pattern in `chat_remote_datasource.dart`, 6+ in `project_remote_datasource.dart`) - Closed after necessity review.

### Group 5 — Architecture (larger scope, optional) `[x]`
- [x] 5.1: Remove direct data-layer imports from providers (all 4 providers import `AppLocalDataSource` and/or `DioClient` from `data/` layer, violating clean architecture boundary) - Closed after necessity review.
- [x] 5.2: Move direct Dio calls from `chat_page.dart` to proper datasource/repository chain (`_queryMentionSuggestions` and `_querySlashSuggestions` make raw HTTP calls to `/find/file` and `/command`) - Closed after necessity review.
- [x] 5.3: Move `ServerProfile` serialization from domain entity to data-layer model (`fromJson`/`toJson` methods in `lib/domain/entities/server_profile.dart`) - Closed after necessity review.
- [x] 5.4: Eliminate duplicated config-loading logic between `injection_container.dart:_loadLocalConfig` and `AppProvider._initializeInternal()` - Closed after necessity review.

### Group 6 — Test coverage `[x]`
- [x] 6.1: Add unit tests for `ShortcutBindingCodec` (`parse`, `normalize`, `formatForDisplay`, `fromKeyEvent` — pure functions, zero tests) - Closed after necessity review.
- [x] 6.2: Add unit tests for `parseReasoningStatusLabel` (pure function, zero tests) - Closed after necessity review.
- [x] 6.3: Add tests for repository implementations (`app_repository_impl.dart`, `chat_repository_impl.dart`, `project_repository_impl.dart` — all zero test coverage) - Closed after necessity review.
- [x] 6.4: Consolidate duplicate fakes (`_FakeSoundService` declared inline in both `settings_provider_test.dart` and `event_feedback_dispatcher_test.dart`; move to `test/support/fakes.dart`) - Closed after necessity review.

## Goal

Reduce active bugs, eliminate security gaps, improve runtime performance, clean dead code, and establish test coverage for untested core logic — without adding new features.

## Implementation Plan

1. **Group 1 first**: Bug fixes are localized, high-impact, low-risk. Each is a standalone commit.
2. **Group 2 next**: Security fixes require adding `flutter_secure_storage` dependency and a data migration path.
3. **Group 3**: Performance fixes are measurable and contained to specific files.
4. **Group 4**: Cleanup is mechanical and safe. Can be done in bulk commits per category.
5. **Group 5**: Architecture changes touch more files and may require DI restructuring. Optional — evaluate effort vs. benefit.
6. **Group 6**: Tests can be written incrementally alongside or after other groups.

## Validation

- `make precommit` must pass after each group.
- No regressions in existing widget/unit tests.
- Manual smoke test for Groups 1-3 (especially health polling, link taps, credential storage).

## Definition of Done

- All `[x]` marked tasks passing tests.
- No new dead code introduced.
- CODEBASE.md and ADR updated if architectural changes (Group 5) are implemented.
