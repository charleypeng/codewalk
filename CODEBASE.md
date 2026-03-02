# Code map of CodeWalk

## Project Snapshot

- Flutter client for OpenCode-compatible servers (ADR-023: contract-first compatibility policy).
- Architecture follows `presentation -> domain -> data` with `get_it` + `provider`.
- Multi-platform targets in repo: Android, Linux, macOS, Windows, Web.
- Chat stack is decomposed into orchestrators plus focused cluster modules.
- Material icon convention in UI/tests now uses `Symbols.*` (`material_symbols_icons`) instead of `Icons.*`.
- Theme system follows Material You (MD3): user-controlled theme mode, dynamic color toggle, AMOLED dark toggle, brand color seeds, contrast level, and responsive window size classes.

## Folder Structure

```text
codewalk/
├── ai-docs/                            # AI docs and engineering artifacts
├── assets/images/                      # Source and generated launcher/tray icon assets used by `make icons`
├── lib/                                # Application source
│   ├── main.dart                       # App bootstrap (DI, providers, shell)
│   ├── core/                           # Config, constants, DI, errors, logging, network
│   ├── data/                           # Data layer: datasources, models, repositories, cache
│   │   └── cache/                      # Hybrid file+memory cache for large chat payloads
│   ├── domain/                         # Domain layer: entities, repository contracts, use cases
│   └── presentation/                   # UI, state providers, runtime services
│       ├── pages/                      # App pages and page-level orchestration
│       │   ├── app_shell_page.dart
│       │   ├── onboarding_wizard_page.dart # First-run onboarding wizard (Welcome → Server Setup → Ready)
│       │   ├── chat_page.dart          # Chat orchestrator/facade
│       │   └── chat_page/              # ChatPage decomposed clusters (18 modules)
│       ├── providers/                  # App/Chat/Project/Settings state orchestration
│       │   ├── chat_provider.dart      # Chat provider orchestrator/facade
│       │   └── chat_provider/          # ChatProvider decomposed clusters (15 modules)
│       ├── widgets/
│       │   ├── chat_message_widget.dart # StatefulWidget with build-skip cache for messages
│       │   ├── chat_input_widget.dart  # Chat input orchestrator/facade
│       │   └── chat_input/             # ChatInput decomposed clusters (8 modules)
│       ├── services/                   # Platform/runtime services (tray, notifications, STT, etc.)
│       ├── utils/                      # Presentation helpers (incl. WindowSizeClass MD3 breakpoints)
│       └── theme/                      # Material You theme: AppTheme, AppShapes, BrandColor seeds
├── test/                               # Unit, widget, integration, presentation, support tests
├── tool/ci/                            # Analyzer budget and coverage gate scripts
├── .github/workflows/                  # CI and release workflows
├── android/ linux/ macos/ web/ windows/ # Platform runners/build configs
├── android/app/src/main/res/drawable-*/ # Android notification small icons (`ic_stat_codewalk.png`)
├── linux/runner/resources/             # Linux launcher icon + desktop entry icon metadata
└── Makefile                            # Main development and validation commands
```

## Entry Points

```text
lib/main.dart                                # Runtime entry; DI, providers, DynamicColorBuilder with user theme prefs; syncs dynamic color availability to SettingsProvider via postFrameCallback
lib/presentation/pages/app_shell_page.dart   # Root shell; gates onboarding wizard, mounts ChatPage and desktop tray behavior; triggers startup update toast via `addPostFrameCallback` + `UpdateCheckResult` when `checkUpdatesOnOpen` is enabled; reacts to `UpdateInstallState` transitions (downloading/done/failed) to show progress snackbars and trigger `startInstall()`
lib/presentation/pages/onboarding_wizard_page.dart # First-run wizard shown when no server is configured
lib/presentation/pages/chat_page.dart         # Main chat/session/file UI entry; uses WindowSizeClass for responsive layout; guards startup logic against no-active-server state; timeline empty state includes CTA to setup wizard
.github/workflows/ci.yml                      # CI workflow entry
.github/workflows/release.yml                 # Release workflow entry
```

## Core Modules

```text
lib/core/di/injection_container.dart              # Registers datasources, repositories, usecases, providers
lib/core/network/dio_client.dart                  # HTTP client config, auth, base URL updates; exposes `dio` (regular) and `sseDio` (dedicated SSE instance with isolated connection pool)
lib/core/network/dio_sse_adapter.dart              # Conditional export: routes to IO or stub adapter
lib/core/network/dio_sse_adapter_io.dart           # IO platforms: configures IOHttpClientAdapter with separate HttpClient for SSE (2h idle, 4 max connections)
lib/core/network/dio_sse_adapter_stub.dart         # Web platform: no-op (browser manages connections natively)
lib/data/datasources/app_remote_datasource.dart   # App bootstrap/config/providers/agents API access
lib/data/datasources/chat_remote_datasource.dart  # Chat/session/message/realtime API access; accepts optional `sseDio` for SSE stream isolation; sendMessage uses polling + provider-level SSE only (no per-send SSE) to prevent server-side abort on disconnect; async completion (`prompt_async`) fallback escalates to polling and uses stricter staleness guards when no-candidate/empty-baseline scenarios occur to prevent early finalization
lib/data/datasources/project_remote_datasource.dart # Project/worktree/file API access
lib/data/datasources/app_local_datasource.dart    # Persistent settings, profiles, cache, credentials, favorite models; uses ChatCachePayloadStore hybrid store with shared_preferences fallback for large payloads
lib/data/cache/chat_cache_payload_store.dart      # Factory with conditional import for platform-specific store
lib/data/cache/chat_cache_payload_store_base.dart # Abstract interface for cache store (read/write/remove/clear)
lib/data/cache/chat_cache_payload_store_io.dart   # IO implementation: hybrid file+LRU memory cache (24 entries) for chat payloads
lib/data/cache/chat_cache_payload_store_stub.dart # Non-IO platforms: disabled payload store (returns null)
lib/data/repositories/*.dart                      # Domain repository implementations
lib/domain/usecases/*.dart                        # Application use cases consumed by providers
lib/presentation/providers/app_provider.dart      # Server profiles, health polling, local runtime state; guards health polling/connection when no active server profile is set
lib/presentation/providers/project_provider.dart  # Project/worktree context selection and persistence
lib/presentation/providers/settings_provider.dart # Experience settings, theme mode, dynamic color, AMOLED dark toggle, brand seed, contrast, composer tips visibility, sounds, update checks, desktop pane widths; exposes `dynamicColorAvailable` (bool) and `updateDynamicColorAvailability()` for runtime platform signal; `setCheckUpdatesOnOpen()` setter and `_performStartupUpdateCheck()` private method drive the startup update toast; `UpdateInstallState` enum (idle/downloading/installing/done/failed) and `startInstall()` manage APK download + install lifecycle via `open_filex`
lib/presentation/theme/brand_colors.dart              # BrandColor enum with 5 seed colors for non-dynamic-color themes
lib/presentation/theme/app_shapes.dart                # AppShapes class with centralized MD3 shape constants
lib/presentation/theme/app_theme.dart                 # Material You theme builder using AppShapes and color scheme
lib/presentation/theme/app_animations.dart            # Animation duration tokens; includes userBubble (130 ms) and assistantBubble (180 ms)
lib/presentation/utils/window_size_class.dart         # WindowSizeClass enum with MD3 breakpoints + BuildContext extension
lib/presentation/services/desktop_tray_service_io.dart # Desktop tray lifecycle; selects tray icon per OS (macOS template PNG, Windows ICO, Linux PNG)
lib/presentation/services/notification_service.dart    # Local notifications; Android uses `@drawable/ic_stat_codewalk` small icon
lib/presentation/services/android_foreground_monitor_service.dart # Android foreground service via MethodChannel; keeps background monitoring active
lib/presentation/services/android_background_alert_worker.dart # WorkManager-based background polling; fast probe (2m) for active sessions, tail probe (5m) after completion
lib/presentation/services/android_background_alert_logic.dart # Pure logic for tail probe scheduling, alert planning, and snapshot state
lib/presentation/services/android_battery_optimization_service.dart # Android battery optimization query/exemption request via MethodChannel
lib/presentation/providers/chat_provider.dart     # Chat state/realtime/session facade; cache-first per-session SWR restore, in-memory LRU message cache, persisted per-session snapshots, microtask coalescing, event dedup buffer, render gate, favorite models; project-switch SWR support via `onProjectScopeChanged(waitForRevalidation: false)` and `loadSessions(backgroundRevalidation: true)`; non-active contexts marked dirty by global events keep cache for immediate restore-on-return, while background revalidation refreshes state; active-session SWR uses limited-tail (delta-like) refresh with overlap merge and full-fetch fallback; includes `loadOlderMessages()` scaffold and keeps loadSessionInsights fire-and-forget on session switch; idle final-message reconcile can bypass abort-suppression only for targeted `session-idle-final-reconcile`; New Chat uses draft-first flow (`beginNewChatDraft`) with lazy session bootstrap on first send, and draft state is now context-scoped inside `_ChatContextSnapshot` to prevent cross-project leakage during fast switches; includes cross-scope helpers `visibleSessionsForScopeId` and `hasSnapshotForScopeId`
lib/presentation/pages/onboarding_wizard_page.dart # 3-step onboarding wizard (Welcome, Server Setup, Ready); uses ServerSetupQuickGuide
lib/presentation/pages/settings/sections/servers_settings_section.dart # Server profile CRUD; exports reusable ServerSetupQuickGuide widget
lib/presentation/pages/chat_page.dart             # Chat UI orchestration facade; WindowListener for desktop lifecycle; guards startup (checkConnection/loadSessions) against no-active-server; holds tool-chain expanded state map; _isSessionSwitchInFlight guard, _sessionCollapseHistoryCache / _sessionCollapseWorkCache per-session collapse maps; top-reach history loading is coordinated with anchor-preserving restore; workspace controller uses fast project-scope switch path
lib/presentation/widgets/chat_input_widget.dart   # Composer/input orchestration facade
lib/presentation/widgets/chat_message_widget.dart # Message bubble with build-skip cache, cached MarkdownStyleSheet; compact (<600dp) collapsed-copy variants for reasoning/tool-chain/tool-content toggles; tool-chain expand/restore callbacks
lib/presentation/widgets/session_todo_list_widget.dart # Session task panel with progress bar and keyboard-aware collapse; compact mobile collapsed summaries use count-first wording (`x/y in progress`, `x/y done`)
lib/presentation/widgets/message_entrance_animation.dart # Entrance animation wrapper; `role` parameter selects user (130 ms) or assistant (180 ms) motion profile from AppAnimations
```

## Chat Architecture

### Orchestrators / Facades

```text
lib/presentation/pages/chat_page.dart
lib/presentation/providers/chat_provider.dart
lib/presentation/widgets/chat_input_widget.dart
```

### `lib/presentation/pages/chat_page/` clusters (current)

```text
chat_page_lifecycle.dart
chat_page_scroll_coordinator.dart                  # Handles top-scroll older-history trigger and viewport anchor restoration after prepend
chat_page_workspace_controller.dart
chat_page_shortcuts.dart
chat_page_status_presenter.dart
chat_page_selector_flow.dart               # ConstrainedBox wrapped in Flexible to prevent overflow at medium breakpoint
chat_page_scaffold.dart                          # Session selection reordered to close-first; _handleSessionSwitch() guard prevents concurrent switches; conversations sidebar includes project groups card with open-project controls and session previews
chat_page_file_explorer_controller.dart
chat_page_file_viewer.dart
chat_page_composer_status.dart
chat_page_command_query.dart
chat_page_runtime_support.dart                   # _syncSessionScrollState saves/restores per-session collapse state via _sessionCollapseHistoryCache / _sessionCollapseWorkCache
chat_page_chrome.dart
chat_page_file_runtime.dart
chat_page_composer_widgets.dart
chat_page_model_selector_runtime.dart        # New Chat action opens draft mode immediately via provider `beginNewChatDraft()`
chat_page_timeline_builder.dart              # Renders empty state with no-server CTA to wizard; passes `role` to MessageEntranceAnimation so each bubble uses the correct motion profile; composer stays enabled during draft-first New Chat (`currentSession != null || isDraftingNewChat`)
chat_page_timeline_runtime.dart              # Tool-chain expanded state key resolution (sessionId::messageId::startPartId)
```

### `lib/presentation/providers/chat_provider/` clusters (current)

```text
chat_provider_core.dart
chat_provider_session_ops.dart
chat_provider_realtime_ops.dart           # Realtime event handling; suppresses `session.idle` events during active send streams to prevent stale idle from closing subsequent turns before completion feedback or final-reconcile can occur
chat_provider_realtime_aux_ops.dart
chat_provider_event_reducer_ops.dart             # Reconcile one-shot guard via _messageStreamGeneration; dedup key composition
chat_provider_message_merge_ops.dart
chat_provider_message_state_ops.dart             # Message state mutations; auto-title scheduling guard skips subsessions
chat_provider_selection_sync_ops.dart
chat_provider_selection_helpers.dart
chat_provider_context_state_ops.dart
chat_provider_preference_ops.dart
chat_provider_auto_title_ops.dart               # Auto-title execution (main/root sessions only); runtime guard in `_runAutoTitlePass` skips subsessions
chat_provider_error_policy.dart
chat_provider_cache_persistence_ops.dart
chat_provider_abort_policy_ops.dart
```

### `lib/presentation/widgets/chat_input/` clusters (current)

```text
chat_input_state_machine.dart
chat_input_history_controller.dart
chat_input_mentions_controller.dart
chat_input_commands_controller.dart
chat_input_suggestion_popover.dart
chat_input_attachment_controller.dart
chat_input_send_controller.dart
chat_input_speech_controller.dart
```

## Data & Domain Layers

```text
lib/domain/entities/       # Core business entities (chat, provider, project, worktree, settings)
lib/domain/repositories/   # Repository contracts
lib/domain/usecases/       # Use case boundaries used by providers
lib/data/models/           # API/storage models and JSON adapters
lib/data/repositories/     # Repository implementations
lib/data/datasources/      # Remote/local IO boundaries
lib/data/cache/            # Hybrid payload cache primitives used by AppLocalDataSource
```

## Key API/DataSource locations

```text
lib/data/datasources/app_remote_datasource.dart
  - /path, /app (fallback), /app/init (fallback), /provider, /agent, /config

lib/data/datasources/chat_remote_datasource.dart
  - /session, /session/{id}, /session/{id}/message, /session/{id}/shell
  - /session/status, /session/{id}/children, /session/{id}/todo, /session/{id}/diff
  - /session/{id}/abort, /session/{id}/revert, /session/{id}/unrevert, /session/{id}/init, /session/{id}/summarize
  - /event (provider-level SSE only; per-send SSE removed), /global/event
  - /permission, /permission/{requestId}/reply
  - /question, /question/{requestId}/reply, /question/{requestId}/reject

lib/data/datasources/project_remote_datasource.dart
  - /project, /project/current
  - /experimental/worktree, /experimental/worktree/reset
  - /file, /file/content, /find/file, /vcs
```

## Main Commands

```bash
make deps
make gen
make icons
make icons-check
make analyze
make test
make coverage
make check
make android
make desktop
make release V=patch|minor|major
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter run -d linux
flutter run -d android
flutter run -d chrome
```

## Testing/Quality Gates

```text
test/unit/                             # Unit tests
test/unit/providers/                   # ChatProvider split tests (7 files, 127 tests, parallelized with -j 12)
  chat_provider_init_test.dart         #   12 tests — initialization, config sync, model/agent selection
  chat_provider_sync_test.dart         #   17 tests — deferred sync, cycle, scope, overrides, variant sync
  chat_provider_messaging_test.dart    #   15 tests — sessions, sendMessage, draft restore; delta-like SWR fallback coverage
  chat_provider_realtime_test.dart     #   21 tests — title gen (main sessions only), SSE, abort, reconciliation
  chat_provider_session_ops_test.dart  #   25 tests — rename/share/fork/delete, insights, idle
  chat_provider_project_test.dart      #   13 tests — permissions, questions, project scope, favorites; project-switch SWR behavior + draft isolation + dirty-context cache retention
  chat_provider_concurrency_test.dart  #   26 tests — render gate, multi-session, abort suppression
  chat_provider_test_support.dart      #   Shared utilities (RecordingDioClient, buildChatProvider, testModel); FakeChatRepository.getSessionsDelay
test/widget/                           # Widget tests (includes icon assertions with Symbols.* and explicit compact/mobile collapsed-copy coverage for chat message and session todo surfaces)
test/integration/                      # Integration tests
test/presentation/                     # Presentation-focused tests (incl. window_size_class_test.dart)
test/support/                          # Test helpers/fakes
tool/ci/check_analyze_budget.sh        # Analyzer issue budget gate (default: 186)
tool/ci/check_coverage.sh              # Coverage threshold gate (default: 35%)
.github/workflows/ci.yml               # CI executes analyze + tests + coverage gate
```

## Notes

- `make android` builds an arm64 APK and sends the artifact with `~/bin/hey`; use `HEY_CAPTION` to override the upload caption.
- Android manifest declares `REQUEST_INSTALL_PACKAGES` permission and a `FileProvider` authority (`com.verseles.codewalk.fileprovider`) required for APK sideload installs via `open_filex`.
- Sensitive server credentials are persisted through `flutter_secure_storage` (v10.0.0) via `AppLocalDataSource`.
- Platform folders currently present: `android/`, `linux/`, `macos/`, `web/`, `windows/`.
- Android build targets Java 17 (`sourceCompatibility`, `targetCompatibility`, `jvmTarget`).
- featM icon migration completed in `lib/presentation/**` and `test/widget/**`: Material icons moved from `Icons.*` to `Symbols.*` (`material_symbols_icons`).

### Queued Send Flow

- **Provider queue state + drain/send-now**: `chat_provider.dart` tracks per-session queued envelopes/local queued IDs and drains them as a merged batch; `sendQueuedNow()` can stop active response and force immediate drain.
- **Composer queued status + action**: `chat_page_composer_status.dart` prioritizes queued-count status, and `chat_page_composer_widgets.dart` renders queued UI with a `Send now` action.
- **Queued message badge**: `chat_message_widget.dart` + `chat_message_content.dart` expose/render `isQueuedUserMessage` with a `Queued` badge in user message bubbles.

### Android Background Monitoring

- **Native foreground service** (`android/app/src/main/kotlin/com/verseles/codewalk/CodeWalkForegroundService.kt`):
  Owns the ongoing Android monitor notification and receives MethodChannel-driven updates.
- **Dart bridge** (`android_foreground_monitor_service.dart`): Calls `codewalk/system`
  channel methods (`updateForegroundNotification`, `stopForegroundService`) and keeps
  service state idempotent from Flutter side.
- **Notification integration** (`notification_service.dart`): Syncs active-session counts
  with the foreground monitor so background alert reliability status remains visible.
- **Battery optimization UX** (`android_battery_optimization_service.dart` +
  `notifications_settings_section.dart`): Queries and requests optimization exemption from
  Settings to reduce background task interruptions on Android.

### Favorite Models

- **Storage key**: `favoriteModelsKey` in `AppConstants` (`app_constants.dart`).
- **Local persistence**: `AppLocalDataSource` exposes `getFavoriteModelsJson` /
  `saveFavoriteModelsJson` (scoped by server + project, same pattern as recent models).
- **Provider state**: `ChatProvider._favoriteModelKeys` list, getter `favoriteModelKeys`,
  query method `isModelFavorite`, and toggle method `toggleModelFavorite` (local-only, no
  remote sync). Loaded and persisted in `chat_provider_preference_ops.dart` alongside
  recents, usage counts, and variant map.
- **Model selector UI** (`chat_page_model_selector_runtime.dart`):
  - `_buildFavoriteModelEntries` builds the "Favorites" section from provider state.
  - `_modelSelectorTrailing` renders a star toggle + checkmark trailing widget for every
    model row (favorites, recents, and provider sections).
  - The bottom sheet shows Favorites > Recent > Provider sections; favorites are excluded
    from recents and provider groups to avoid duplicates.
  - Variant popover auto-fits width using `TextPainter` to measure the longest label.
- **Keyboard shortcut** (`chat_page_shortcuts.dart`): `_cycleRecentModel` now cycles
  favorites first, then recents (deduped), before falling back to the current provider's
  model list.

### Onboarding Wizard

- **Gate**: `AppShellPage` shows `OnboardingWizardPage` when no server profiles exist and
  `skipOnboardingWizard` is false; navigation back to the shell happens automatically via
  `Consumer2` rebuild when a profile is added.
- **Steps**: Welcome (connect or need-help paths) -> Server Setup (optional `ServerSetupQuickGuide`
  + connection form with URL/label/auth/AI-titles) -> Ready (success or retry).
- **`ServerSetupQuickGuide`** (`servers_settings_section.dart`): Reusable stateless widget showing
  quick-start instructions and a copyable `opencode serve` command. Used by both the onboarding
  wizard and the Settings > Servers add/edit dialog.
- **Android loopback mapping**: Both the wizard and the servers section map `localhost`/`127.0.0.1`
  to `10.0.2.2` on Android emulator builds.
- **Skip persistence**: User can skip the wizard with an optional "Don't show again" checkbox,
  which calls `SettingsProvider.setSkipOnboardingWizard(true)`.

### Update Install Flow (Android)

- **`UpdateCheckResult.apkUrl`** (`update_check_service.dart`): GitHub release asset URL for the `.apk`; populated when the release includes an APK asset matching the architecture filter.
- **`UpdateInstallState`** (`settings_provider.dart`): Enum tracking download/install lifecycle — `idle → downloading → installing → done | failed`.
- **`SettingsProvider.startInstall()`**: Downloads the APK to a temp file via Dio `saveFile`, then calls `OpenFilex.open()` to trigger the system installer. Guards against re-entry when already downloading/installing.
- **`AppShellPage` reactions**: Observes `installState` transitions; shows snackbars for downloading, done, and failed states; the startup update toast "Install" action calls `startInstall()`.
- **`AboutSettingsSection` controls**: Renders inline progress indicators and retry/install buttons reflecting `installState`; delegates to `settings.startInstall()`.

### Performance Architecture

- **ChatProvider microtask coalescing**: `_notifyScheduled` / `_scrollScheduled` flags gate
  `scheduleMicrotask` so that multiple state mutations within the same frame produce only one
  `notifyListeners()` / scroll-to-bottom call.
- **Event dedup buffer**: `_recentEventIds` (circular `Queue<String>`) in ChatProvider stores
  recent event keys built by `_composeEventDeduplicationKey` (in `chat_provider_event_reducer_ops.dart`).
  `_isRecentlyProcessedEvent` and `_tryApplyGlobalEventIncremental` use this buffer to skip
  duplicates arriving on the global SSE stream.
- **ChatProvider local message reconciliation**:
  - `ChatProvider` generates optimistic local user IDs with a server-compatible `msg_*` format (replacing the old `local_user_*` prefix).
  - `sendMessage` forwards `ChatInput.messageId` using this optimistic ID to ensure exact client/server message reconciliation.
  - `_shouldSkipLocalUserAppendAsDuplicateEcho` dedupe guard (in `chat_provider_message_merge_ops.dart`) now relies on `_pendingLocalUserMessageIds` tracking membership instead of hardcoded prefix checks.
- **Pending replacement hardening** (`chat_provider_message_state_ops.dart`):
  `_updateOrAddMessage` handles pending-local replacement when a server user message arrives with
  an already-present server ID, preventing local/server duplicate-ID coexistence and preserving a
  single canonical user bubble.
- **Realtime regression coverage** (`test/unit/providers/chat_provider_realtime_test.dart`):
  added guard tests for active-stream refresh reconciliation and the late stream user-update path
  to keep user-message dedup stable under snapshot/stream races.
- **Render gate**: `_hasPendingRenderFlush` in ChatProvider suppresses `notifyListeners()` while
  the app is in background. SSE data keeps accumulating in internal fields, but widgets do not
  rebuild until the app returns to foreground and flushes the pending notification via
  `setForegroundActive(true)`.
- **Desktop window lifecycle**: `_ChatPageState` mixes in `WindowListener` (from `window_manager`)
  to handle focus/blur/minimize/restore on desktop platforms. These events drive
  `_applyForegroundPolicy`, which coordinates with the ChatProvider render gate and
  `_handleReturnToChat` to pause/resume UI rebuilds and SSE refresh on window state changes.
- **App resume reconciliation**: On `AppLifecycleState.resumed` with an active chat route,
  `ChatPage` triggers `provider.refreshActiveSessionView(reason: 'app-lifecycle-resumed')`
  to reconcile missed updates. `_lastResumeRefreshAt` dedupe guard skips immediate
  reconnect-triggered refresh shortly after resume.
- **ChatMessageWidget build-skip cache**: Converted from `StatelessWidget` to `StatefulWidget`;
  completed messages short-circuit `build()` by returning a cached widget tree.
  `MarkdownStyleSheet` is cached in `_cachedMarkdownStyleSheet` and invalidated only on
  brightness change.
- **Tool-call chain expansion persistence**: `_ChatPageState` stores expansion state in
  `_toolChainExpandedStateByKey`, keyed by `sessionId::messageId::startPartId`.
  `ChatMessageWidget` restores and updates this parent-managed state through
  `resolveToolChainExpanded` and `onToolChainExpandedChanged` callbacks, preserving
  collapsed/expanded tool-call chains when switching sessions and revisiting messages.
- **ChatPage (_ChatPageState) derived-data caches**: The page state holds per-build caches that
  skip recomputation when message list identity has not changed:
  - `_cachedTimelineEntries` — timeline entry list (used by `chat_page_timeline_builder.dart`)
  - `_cachedHighlightTheme` / `_cachedHighlightBrightness` — syntax highlight theme
  - `_cachedContextUsage` — session context/token usage snapshot (used by `chat_page_status_presenter.dart`)
  - `_cachedReasoningKeyResult` — reasoning effort key (used by `chat_page_timeline_runtime.dart`)
  - `_cachedProgressStageResult` — assistant progress stage (used by `chat_page_timeline_runtime.dart`)
  - `_cachedSentHistory` — sent message history (used by `chat_page_composer_widgets.dart`)

### Material You Design System

- **Theme control** (`main.dart`): `DynamicColorBuilder` resolves color scheme from platform
  dynamic color (when enabled and available) or from user-selected `BrandColor` seed. User
  preferences (`themeMode`, `useDynamicColor`, `useAmoledDark`, `customColorSeed`, `contrastLevel`,
  `checkUpdatesOnOpen`) are stored in `ExperienceSettings` and exposed via `SettingsProvider`. When `useAmoledDark` is
  enabled, `_applyAmoledDarkScheme()` overrides all surface colors to `Colors.black` in dark theme.
- **BrandColor** (`brand_colors.dart`): Enum with 5 curated seed colors (Indigo, Teal, Rose,
  Amber, Slate) used when dynamic color is unavailable or disabled.
- **AppShapes** (`app_shapes.dart`): Centralized MD3 shape constants consumed by `AppTheme`
  and individual widgets for consistent rounded corners.
- **WindowSizeClass** (`window_size_class.dart`): Enum (`compact`, `medium`, `expanded`,
  `large`, `extraLarge`) derived from MD3 breakpoints. `BuildContext.windowSizeClass` extension
  replaces hardcoded width checks in `ChatPage` and `SettingsPage`.
- **Settings UI** (`appearance_settings_section.dart`): Theme mode, color picker (brand colors
  + dynamic color toggle), contrast level cards, and a Composer tips toggle in the Appearance
  section. `about_settings_section.dart` contains a `SwitchListTile` for the `checkUpdatesOnOpen`
  toggle that controls startup update checks. Dynamic color availability is read from `settingsProvider.dynamicColorAvailable`
  (runtime signal set by `DynamicColorBuilder` in `main.dart`) instead of a heuristic; contrast
  slider is disabled when dynamic color is active. Composer tips visibility is shared with the
  Chat Display popover toggle through `settingsProvider.showComposerTips`.
