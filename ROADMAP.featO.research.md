# ROADMAP.featO Research — Code Health & Technical Debt

Detailed findings with file paths, line numbers, code snippets, and proposed fixes for each item in `ROADMAP.featO.md`.

---

## Group 1 — Bug Fixes

### 1.1 `registerFactory` for stateful providers (DI resource leak)

**File:** `lib/core/di/injection_container.dart:138-181`

```dart
sl.registerFactory(         // line 138 — AppProvider
  () => AppProvider(...),
);
sl.registerFactory(         // line 147 — ChatProvider
  () => ChatProvider(...),
);
```

`AppProvider` holds persistent timers (`_healthTimer`), stream subscriptions (`_localServerStdoutSubscription`), and initialization state (`_initFuture`, `_initialized`). `ChatProvider` is similarly stateful with event subscriptions, polling timers, and generation counters.

Using `registerFactory` creates a **new instance** every time `sl<AppProvider>()` is called. Result: multiple polling timers running concurrently, none disposed by the DI container.

For reference, `ProjectProvider` (line 182) and `SettingsProvider` are correctly registered as `registerLazySingleton`.

**Fix:** Change both to `registerLazySingleton`.

---

### 1.2 State mutation inside `build()`

**File:** `lib/presentation/pages/chat_page.dart:6818-6841`

```dart
List<_TimelineEntry> _buildMessageTimelineEntries(...) {
  if (isCompactingContext && !_wasCompactingContext) {
    _frozenCompactionBoundaryId = ...;       // STATE MUTATION
  } else if (!isCompactingContext && _wasCompactingContext) {
    _frozenCompactionBoundaryId = null;      // STATE MUTATION
  }
  _wasCompactingContext = isCompactingContext; // STATE MUTATION
```

`_buildMessageTimelineEntries` is called from `_buildMessageList` which is called from `build()`. Mutates `_wasCompactingContext` and `_frozenCompactionBoundaryId` during the build phase. Flutter may call `build()` multiple times (during layout, hot reload, testing) causing unpredictable state.

Also in `lib/presentation/pages/settings_page.dart:182`:

```dart
@override
Widget build(BuildContext context) {
  final visibleSections = _visibleSections;
  if (!visibleSections.any((item) => item.id == _selectedSectionId)) {
    _selectedSectionId = visibleSections.first.id;  // direct mutation, no setState
  }
```

`_selectedSectionId` is directly mutated inside `build()` without `setState()`. Violates Flutter's rendering contract — the mutation won't schedule a rebuild and bypasses dirty-marking.

**Fix:** Move compaction transition detection to `didChangeDependencies` or use `WidgetsBinding.instance.addPostFrameCallback`. For settings_page, wrap the fallback assignment in `WidgetsBinding.instance.addPostFrameCallback` with `setState`.

---

### 1.3 `dispose()` without async guard

**File:** `lib/presentation/providers/chat_provider.dart:5852-5866`

```dart
@override
void dispose() {
  unawaited(
    _cancelActiveMessageSubscription(
      reason: 'dispose',
      invalidateGeneration: true,
    ),
  );
  _eventStreamGeneration += 1;
  _eventSubscription?.cancel();
  _globalEventSubscription?.cancel();
  _globalRefreshDebounce?.cancel();
  _syncHealthTimer?.cancel();
  _degradedPollingTimer?.cancel();
  super.dispose();
}
```

`_cancelActiveMessageSubscription` is async with a 2-second timeout internally. Called with `unawaited`, so `dispose()` returns while background cancellation still runs. The async callback may call `notifyListeners()` after `super.dispose()`, which throws in debug mode.

**Fix:** Introduce a `_disposed` boolean flag. Guard `notifyListeners()` calls:

```dart
bool _disposed = false;

@override
void dispose() {
  _disposed = true;
  // ... existing cleanup
  super.dispose();
}

// In methods that call notifyListeners():
if (_disposed) return;
notifyListeners();
```

---

### 1.4 Race condition in health polling

**File:** `lib/presentation/providers/app_provider.dart:817-830, 979`

```dart
Future<void> refreshServerHealth({String? serverId}) async {
  await initialize();
  for (final profile in targets) {
    _serverHealthById[profile.id] = await _checkServerHealth(profile);
  }
  notifyListeners();
}

// line 979:
Timer.periodic(const Duration(seconds: 10), (_) {
  unawaited(refreshServerHealth());  // no guard against concurrent execution
})
```

Health checks run sequentially per profile (3s timeout x 2 endpoints x N profiles). If total exceeds 10s, the timer fires again before the first invocation finishes, causing concurrent mutation of `_serverHealthById`.

Additionally, `_checkServerHealth` at line 832 creates a new `Dio` instance per call (see 3.3).

**Fix:**

```dart
bool _healthCheckInFlight = false;

Future<void> refreshServerHealth({String? serverId}) async {
  if (_healthCheckInFlight) return;
  _healthCheckInFlight = true;
  try {
    // ... existing logic
  } finally {
    _healthCheckInFlight = false;
  }
}
```

---

### 1.5 Markdown link tap not implemented

**File:** `lib/presentation/widgets/chat_message_widget.dart:460`

```dart
onTapLink: (text, href, title) {
  if (href != null) {
    // TODO: Implement link navigation
  }
},
```

Links in rendered Markdown are silently ignored. `url_launcher` is already in `pubspec.yaml`.

**Fix:**

```dart
onTapLink: (text, href, title) {
  if (href != null) {
    final uri = Uri.tryParse(href);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
},
```

---

### 1.6 `SessionRepository` dead code

**File:** `lib/domain/repositories/session_repository.dart`

Interface defined with methods like `getSessions`, `sendMessage`, `revertMessage` — but never imported anywhere in `lib/`. No implementation class, no fake in `test/support/fakes.dart`, no test file. The API overlaps entirely with `ChatRepository`.

**Fix:** Delete the file.

---

## Group 2 — Security

### 2.1 Credentials in SharedPreferences (plaintext)

**File:** `lib/data/datasources/app_local_datasource.dart:354-365, 919-951`

```dart
// API Key — plaintext SharedPreferences
Future<String?> getApiKey({String? serverId}) async {
  return sharedPreferences.getString(
    _scopedKey(AppConstants.apiKeyKey, serverId: serverId),
  );
}

// Basic Auth password — plaintext SharedPreferences
Future<String?> getBasicAuthPassword({String? serverId}) async {
  return sharedPreferences.getString(
    _scopedKey(AppConstants.basicAuthPasswordKey, serverId: serverId),
  );
}
```

On Android, `SharedPreferences` stores data in unencrypted XML (`/data/data/com.app/shared_prefs/`). Accessible on rooted devices. Three sensitive fields affected: `apiKey`, `basicAuthPassword`, `basicAuthUsername`.

`flutter_secure_storage` is **not** in `pubspec.yaml` currently.

**Fix:**
1. Add `flutter_secure_storage` to `pubspec.yaml`.
2. Create a `SecureCredentialStorage` wrapper.
3. Migrate existing plaintext credentials on first launch after update.
4. Clear old SharedPreferences keys after migration.

**References:**
- https://pub.dev/packages/flutter_secure_storage
- Uses Keychain on iOS, Android Keystore on Android

---

### 2.2 SHA-256 with `readAsBytes()` (OOM risk)

**File:** `lib/presentation/services/local_opencode_server_runtime_io.dart:851-855`

```dart
Future<String> _computeSha256(File file) async {
  final bytes = await file.readAsBytes();  // entire file loaded into RAM
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

The file being hashed is a downloaded binary release archive (e.g., `opencode-linux-x64.tar.gz`) which can be 50-200+ MB. Loads entirely into memory before hashing. Risky on mobile devices with limited RAM.

**Fix:**

```dart
Future<String> _computeSha256(File file) async {
  final output = AccumulatorSink<Digest>();
  final input = sha256.startChunkedConversion(output);
  await for (final chunk in file.openRead()) {
    input.add(chunk);
  }
  input.close();
  return output.events.single.toString();
}
```

---

## Group 3 — Performance

### 3.1 Shortcut/action maps rebuilt in `build()`

**File:** `lib/presentation/pages/chat_page.dart:1302-1410`

```dart
@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final settingsProvider = context.watch<SettingsProvider>();
      // ...
      final shortcutMap = <ShortcutActivator, Intent>{};  // NEW MAP EVERY BUILD
      void addShortcut(ShortcutAction action, Intent intent) { ... }
      addShortcut(ShortcutAction.newChat, const _NewSessionIntent());
      // ... 8+ more entries

      final actionMap = <Type, Action<Intent>>{            // NEW MAP EVERY BUILD
        _NewSessionIntent: CallbackAction<_NewSessionIntent>(...),
        // ... 8+ more entries
      };
      return Shortcuts(shortcuts: shortcutMap, child: Actions(actions: actionMap, ...));
    },
  );
}
```

Both maps with 8+ entries allocated fresh on every rebuild. Since `context.watch<SettingsProvider>()` is called in `build()`, any settings change triggers full re-allocation.

**Fix:** Move to instance variables. Rebuild only in `didChangeDependencies` when `settingsProvider.bindingFor(...)` actually changes.

---

### 3.2 `_collectSentMessageHistory` without memoization

**File:** `lib/presentation/pages/chat_page.dart:5280, 5848-5865`

```dart
// line 5280 — called inside a Builder inside build() on every frame
final sentMessageHistory = _collectSentMessageHistory(chatProvider.messages);

// line 5848 — iterates all messages on every call
List<String> _collectSentMessageHistory(List<ChatMessage> messages) {
  final history = <String>[];
  for (final message in messages) {
    if (message.role != MessageRole.user) continue;
    final text = message.parts
        .whereType<TextPart>()
        .map((p) => p.text)
        .join('\n')
        .trim();
    if (text.isEmpty) continue;
    history.add(text);
  }
  return List<String>.unmodifiable(history);
}
```

Iterates all messages, filters `TextPart`, maps, joins — on every rebuild. `ChatProvider` has 64+ `notifyListeners()` calls, meaning this runs very frequently during active chat.

**Fix:** Memoize based on message list identity. Only recompute when `chatProvider.messages` reference changes.

---

### 3.3 New `Dio` per health check, never closed

**File:** `lib/presentation/providers/app_provider.dart:832-871`

```dart
Future<ServerHealthStatus> _checkServerHealth(ServerProfile profile) async {
  final dio = Dio(           // NEW Dio instance created every health check
    BaseOptions(
      baseUrl: profile.url,
      connectTimeout: const Duration(seconds: 3),
      // ...
    ),
  );
  // ... uses dio for two requests
  // dio is NEVER closed
}
```

Called every 10 seconds per server profile. Creates a new `Dio` instance (with its own connection pool) every time, then discards it without calling `dio.close()`. Prevents connection reuse, wastes memory, creates socket churn.

Also in `update_check_service.dart:89`: `final dio = _dio ?? Dio();` — ephemeral instance never closed.

**Fix:** Cache a `Dio` per profile URL, or call `dio.close()` in a `try/finally` block.

---

### 3.4 `ChatSessionList` without `ListView.builder`

**File:** `lib/presentation/widgets/chat_session_list.dart:79-119`

```dart
@override
Widget build(BuildContext context) {
  final sessionById = <String, ChatSession>{        // Rebuilt every time O(n)
    for (final session in widget.sessions) session.id: session,
  };
  final childrenByParent = <String, List<ChatSession>>{};  // Rebuilt every time
  final roots = <ChatSession>[];
  for (final session in widget.sessions) {
    // Full O(n) tree construction each build
  }
  final rows = <Widget>[];
  for (final root in roots) {
    rows.addAll(...);  // ALL tiles built eagerly
  }
  return ListView(children: rows);  // No virtualization
}
```

All tiles created upfront without virtualization. Tree construction is O(n) on every build even when the session list hasn't changed.

**Fix:** Cache tree structure. Use `ListView.builder` with a pre-computed flat list for lazy rendering.

---

## Group 4 — Code Cleanup

### 4.1 Dead constants (placeholder comments removed from scope — only 1 genuine TODO found, already covered by item 1.5)

**File:** `lib/core/constants/app_constants.dart`

| Constant | Line | Value | Status |
|----------|------|-------|--------|
| `appVersion` | 6 | `'1.0.0'` | Never referenced (`about_settings_section.dart` uses `PackageInfo.fromPlatform()`) |
| `appDescription` | 7 | `'CodeWalk - Mobile client for OpenCode'` | Never referenced |
| `storageSchemaVersionKey` | 15 | `'storage_schema_version'` | Never referenced |
| `migrationV1ToV2CompletedKey` | 16 | `'migration_v1_to_v2_completed'` | Never referenced |
| `networkError` | 67 | `'Network connection error'` | Never referenced (repos hardcode identical strings) |
| `serverError` | 68 | `'Server error'` | Never referenced |
| `unknownError` | 69 | `'Unknown error'` | Never referenced |
| `connectionTimeout` | 70 | `'Connection timeout'` | Never referenced |
| `invalidResponse` | 71 | `'Invalid response'` | Never referenced |

**File:** `lib/core/constants/api_constants.dart`

- HTTP verb constants (`get`, `post`, `put`, `patch`, `delete`) lines 22-27 — never used.
- All endpoint path constants (`projectEndpoint`, `providerEndpoint`, `sessionEndpoint`, etc.) lines 9-19 — never used; endpoints are hardcoded inline in datasource files.

**Fix:** Remove dead constants. Then decide: centralize endpoint paths (use the constants) or delete them entirely (keep inline, consistent with current usage).

---

### 4.2 Hardcoded values vs. existing constants

**59 occurrences** of literal padding/spacing values across 14 files where `AppConstants` already defines the same value:

| Constant | Value | Literal occurrences |
|----------|-------|-------------------|
| `AppConstants.defaultPadding` | `16.0` | 19x in `chat_page.dart`, 9x in `servers_settings_section.dart`, 7x in `home_page.dart`, etc. |
| `AppConstants.smallPadding` | `8.0` | Throughout widget files |
| `AppConstants.largePadding` | `24.0` | Settings sections |

Also: `servers_settings_section.dart:711,725` hardcodes `'http://127.0.0.1:4096'` and `'opencode serve --hostname 127.0.0.1 --port 4096'` where `ApiConstants.defaultHost` and `ApiConstants.defaultPort` already exist.

**Fix:** Replace literal values with constants where semantically appropriate.

---

### 4.3 Duplicated error handling in repositories

**File:** `lib/data/repositories/chat_repository_impl.dart` — 104 repetitive try/catch clauses

```dart
// This exact pattern repeats 18+ times with only the success body and error messages changing:
try {
  final result = await dataSource.someMethod(...);
  return Right(result);
} on NotFoundException {
  return const Left(NotFoundFailure('Failed to...'));
} on ServerException {
  return const Left(ServerFailure('Server error'));
} on NetworkException {
  return const Left(NetworkFailure('Network connection failed'));
} catch (_) {
  return const Left(UnknownFailure('Unknown error'));
}
```

With 693 lines total, the file would shrink by ~70% with a generic wrapper.

**Fix:**

```dart
Future<Either<Failure, T>> _safeCall<T>(
  Future<T> Function() call, {
  String context = 'operation',
}) async {
  try {
    return Right(await call());
  } on NotFoundException {
    return Left(NotFoundFailure('$context not found'));
  } on ServerException {
    return const Left(ServerFailure('Server error'));
  } on NetworkException {
    return const Left(NetworkFailure('Network connection failed'));
  } catch (_) {
    return const Left(UnknownFailure('Unknown error'));
  }
}
```

Also, `app_repository_impl.dart` uses a different pattern with `DioException` + `_handleDioException()` — same wrapper approach applies.

---

### 4.4 Duplicated `queryParams` in datasources

**File:** `lib/data/datasources/chat_remote_datasource.dart` — 28 repetitions

```dart
// This exact block appears 28 times:
final queryParams = <String, String>{};
if (directory != null) {
  queryParams['directory'] = directory;
}
// ... later:
queryParameters: queryParams.isNotEmpty ? queryParams : null,
```

Some variants also include `.trim().isNotEmpty` guard — the inconsistency itself is a bug surface.

Also appears 6+ times in `project_remote_datasource.dart`.

**Fix:**

```dart
Map<String, String>? _directoryParams(String? directory) {
  if (directory == null || directory.trim().isEmpty) return null;
  return {'directory': directory};
}
```

---

## Group 5 — Architecture

### 5.1 Providers importing data layer

All 4 providers import directly from `lib/data/`:

| Provider | File | Data-layer imports |
|----------|------|--------------------|
| `ChatProvider` | `chat_provider.dart:10-13` | `AppLocalDataSource`, `ChatMessageModel`, `ChatRealtimeModel`, `ChatSessionModel` |
| `AppProvider` | `app_provider.dart:11-12` | `AppLocalDataSource`, `DioClient` |
| `SettingsProvider` | `settings_provider.dart:10` | `AppLocalDataSource`, `DioClient` |
| `ProjectProvider` | `project_provider.dart:8` | `AppLocalDataSource` |

In clean architecture, the presentation layer should depend only on domain abstractions (repositories, use cases, entities). Direct data-layer access bypasses the domain boundary.

**Fix:** Create domain-level port interfaces (`LocalSettingsPort`, `NetworkConfigPort`, etc.) that abstract the data-layer specifics. Inject through DI.

---

### 5.2 Direct Dio calls in `chat_page.dart`

**File:** `lib/presentation/pages/chat_page.dart:7109, 7225`

```dart
// line 7109 — _queryMentionSuggestions
final dio = di.sl<DioClient>().dio;
final response = await dio.get('/find/file', queryParameters: {...});

// line 7225 — _querySlashSuggestions
final dio = di.sl<DioClient>().dio;
final response = await dio.get('/command');
```

Two methods make raw HTTP calls from a widget, bypassing datasource/repository/use case layers entirely. No corresponding endpoints exist in any datasource class.

**Fix:** Add `findFile` and `getCommands` methods to `ChatRemoteDataSource` and expose through the repository chain.

---

### 5.3 `ServerProfile` serialization in domain entity

**File:** `lib/domain/entities/server_profile.dart:5-18, 49-61`

```dart
factory ServerProfile.fromJson(Map<String, dynamic> json) { ... }  // lines 5-18
Map<String, dynamic> toJson() { ... }                                // lines 49-61
```

Also `lib/domain/entities/experience_settings.dart:313-338, 340+`:

```dart
Map<String, dynamic> toJson() { ... }
static ExperienceSettings fromJson(Map<String, dynamic> json) { ... }
```

Domain entities should not know about persistence format. If storage format changes, domain entities must be modified.

**Fix:** Create `ServerProfileModel` and `ExperienceSettingsModel` in the data layer with serialization logic. Domain entities remain pure.

---

### 5.4 Duplicated config-loading logic

**File:** `lib/core/di/injection_container.dart:208-274`

`_loadLocalConfig()` reimplements profile selection logic (parsing profiles JSON, finding active server, setting basic auth) that `AppProvider._initializeInternal()` and `AppProvider._applyActiveServerToClient()` also implement. The two must be kept in sync manually.

**Fix:** Extract to a shared service or let `AppProvider` be the sole owner of config initialization (remove `_loadLocalConfig` from DI setup).

---

## Group 6 — Test Coverage

### 6.1 `ShortcutBindingCodec`

**Source:** `lib/presentation/utils/shortcut_binding_codec.dart`

Public static methods: `parse`, `normalize`, `formatForDisplay`, `fromKeyEvent`. All are pure functions with deterministic input/output. Zero test files found.

**Suggested tests:**
- Parse valid bindings: `"ctrl+shift+n"` → correct activator
- Normalize: `"CTRL+N"` → `"ctrl+n"`
- Format for display: OS-aware labels (Cmd on macOS, Ctrl on others)
- Edge cases: empty string, single key, unknown key names

---

### 6.2 `parseReasoningStatusLabel`

**Source:** `lib/presentation/utils/reasoning_status_parser.dart`

Parses `**Label**` at the start of a reasoning chunk to extract status labels. Pure function. Zero unit tests.

**Suggested tests:**
- `"**Thinking** about the problem"` → `("Thinking", "about the problem")`
- `"No bold label here"` → `(null, "No bold label here")`
- Empty string, only bold markers, multiple bolds

---

### 6.3 Repository implementations

All three repository impl files have **zero dedicated test files**:

| File | Lines | Test coverage |
|------|-------|--------------|
| `lib/data/repositories/app_repository_impl.dart` | ~100 | 0 tests |
| `lib/data/repositories/chat_repository_impl.dart` | ~693 | 0 tests |
| `lib/data/repositories/project_repository_impl.dart` | ~150 | 0 tests |

Use cases are tested via fakes (e.g., `test/unit/usecases/chat_usecases_test.dart`), but the actual implementation code — data mapping, DioException handling, response parsing — has no coverage.

**Suggested approach:** Create `test/unit/repositories/` directory with test files for each impl. Mock the datasources, verify Failure mapping.

---

### 6.4 Duplicate fakes

`_FakeSoundService` is declared inline in both:
- `test/widget/settings_provider_test.dart`
- `test/unit/event_feedback_dispatcher_test.dart`

**Fix:** Move to `test/support/fakes.dart` as a shared `FakeSoundService`.

Also missing from `fakes.dart`:
- `FakeUpdateCheckService` (needed by `SettingsProvider` and `AboutSettingsSection` tests)
- Fakes for remote datasources (`AppRemoteDataSource`, `ChatRemoteDataSource`, `ProjectRemoteDataSource`)

---

## Additional Findings (lower priority)

### Silent error swallowing

60+ instances of `catch (_) {}` or `catch (e) { /* e never used */ }`:
- `chat_title_generator.dart:89` — delete of ephemeral session silently fails
- `chat_provider.dart` lines 1027, 1310, 1361, 1398, 1437 — JSON parsing failures silently discarded
- `chat_repository_impl.dart` throughout — `catch (e)` where `e` is never logged

### `NotificationService` never disposes StreamController

**File:** `lib/presentation/services/notification_service.dart:52-53`

`_tapController` (broadcast StreamController) and `_webTapSubscription` are never closed/cancelled. No `dispose()` method. Any test that instantiates leaks.

### `SettingsProvider` bypasses DI for `UpdateCheckService`

**File:** `lib/presentation/providers/settings_provider.dart:25`

```dart
_updateCheckService = updateCheckService ?? UpdateCheckService();
```

`UpdateCheckService` is registered as singleton in DI (line 88), but the fallback creates an unregistered fresh instance — silently bypassing the singleton.
