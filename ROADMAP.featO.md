# ROADMAP.featO - Code Health & Technical Debt

## Scope

Systematic elimination of bugs, security gaps, performance issues, dead code, and architectural violations identified through deep codebase analysis. See `ROADMAP.featO.research.md` for detailed findings, code snippets, and line references.

### Group 1 — Bug fixes (critical, localized changes) `[ ]`
- [ ] 1.1: Change `registerFactory` to `registerLazySingleton` for `AppProvider` and `ChatProvider` in `injection_container.dart` (resource leak: multiple polling timers, concurrent health checks, unmanaged state)
- [ ] 1.2: Move state mutation out of `build()` in `chat_page.dart` (`_wasCompactingContext` and `_frozenCompactionBoundaryId` mutated during build phase via `_buildMessageTimelineEntries`)
- [ ] 1.3: Add `_disposed` guard to `ChatProvider.dispose()` to prevent `notifyListeners()` on a disposed provider (async cancellation outlives `super.dispose()`)
- [ ] 1.4: Add concurrency guard to health polling in `AppProvider` (timer fires every 10s but sequential health checks can exceed 10s, causing concurrent `_serverHealthById` mutation)
- [ ] 1.5: Implement Markdown link tap handler in `chat_message_widget.dart` (currently a TODO with empty body, links silently ignored)
- [ ] 1.6: Remove dead `SessionRepository` interface (`lib/domain/repositories/session_repository.dart` — no implementation, no import, no test, no fake)

### Group 2 — Security hardening `[ ]`
- [ ] 2.1: Migrate credentials from `SharedPreferences` to `flutter_secure_storage` (`apiKey`, `basicAuthPassword`, `basicAuthUsername` stored as plaintext in `app_local_datasource.dart`)
- [ ] 2.2: Use streaming SHA-256 instead of `readAsBytes()` in `local_opencode_server_runtime_io.dart` (loads entire binary release ~50-200MB into RAM before hashing)

### Group 3 — Performance `[ ]`
- [ ] 3.1: Cache shortcut/action maps outside of `build()` in `chat_page.dart` (two maps with 8+ entries each allocated fresh on every rebuild)
- [ ] 3.2: Memoize `_collectSentMessageHistory` in `chat_page.dart` (iterates all messages on every rebuild, called from a `Builder` inside `build()`)
- [ ] 3.3: Reuse or properly close Dio instances in health check (`app_provider.dart` creates a new `Dio()` per profile per 10s timer, never closed)
- [ ] 3.4: Convert `ChatSessionList` to use `ListView.builder` with cached tree structure (currently builds all tiles eagerly without virtualization)

### Group 4 — Code cleanup `[ ]`
- [ ] 4.1: Remove dead constants from `app_constants.dart` and `api_constants.dart` (9+ unused constants including `appVersion`, `appDescription`, `storageSchemaVersionKey`, `migrationV1ToV2CompletedKey`, error message strings, HTTP verb constants, endpoint paths)
- [ ] 4.2: Replace hardcoded values with existing constants (59+ occurrences of literal `16`, `8`, `24` where `AppConstants.defaultPadding/smallPadding/largePadding` exist; hardcoded host/port where `ApiConstants.defaultHost/defaultPort` exist)
- [ ] 4.3: Extract shared error handling wrapper in repository implementations (104 repetitive try/catch clauses in `chat_repository_impl.dart` alone, identical pattern across 3 repos)
- [ ] 4.4: Extract `queryParams` helper in datasources (28+ repetitions of `directory != null` pattern in `chat_remote_datasource.dart`, 6+ in `project_remote_datasource.dart`)

### Group 5 — Architecture (larger scope, optional) `[ ]`
- [ ] 5.1: Remove direct data-layer imports from providers (all 4 providers import `AppLocalDataSource` and/or `DioClient` from `data/` layer, violating clean architecture boundary)
- [ ] 5.2: Move direct Dio calls from `chat_page.dart` to proper datasource/repository chain (`_queryMentionSuggestions` and `_querySlashSuggestions` make raw HTTP calls to `/find/file` and `/command`)
- [ ] 5.3: Move `ServerProfile` serialization from domain entity to data-layer model (`fromJson`/`toJson` methods in `lib/domain/entities/server_profile.dart`)
- [ ] 5.4: Eliminate duplicated config-loading logic between `injection_container.dart:_loadLocalConfig` and `AppProvider._initializeInternal()`

### Group 6 — Test coverage `[ ]`
- [ ] 6.1: Add unit tests for `ShortcutBindingCodec` (`parse`, `normalize`, `formatForDisplay`, `fromKeyEvent` — pure functions, zero tests)
- [ ] 6.2: Add unit tests for `parseReasoningStatusLabel` (pure function, zero tests)
- [ ] 6.3: Add tests for repository implementations (`app_repository_impl.dart`, `chat_repository_impl.dart`, `project_repository_impl.dart` — all zero test coverage)
- [ ] 6.4: Consolidate duplicate fakes (`_FakeSoundService` declared inline in both `settings_provider_test.dart` and `event_feedback_dispatcher_test.dart`; move to `test/support/fakes.dart`)

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
