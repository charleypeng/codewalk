# Code map of CodeWalk

## Project Snapshot

- Flutter client for OpenCode-compatible servers (ADR-023: contract-first compatibility policy).
- Architecture follows `presentation -> domain -> data` with `get_it` + `provider`.
- Multi-platform targets in repo: Android, Linux, macOS, Windows, Web.
- Chat stack is decomposed into orchestrators plus focused cluster modules.
- Material icon migration in UI/tests is mostly on `Symbols.*` (`material_symbols_icons`), with a small remaining `Icons.*` usage in notifications settings UI.
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
│       │   └── chat_provider/          # ChatProvider decomposed clusters (16 modules)
│       ├── widgets/
│       │   ├── chat_message_widget.dart # StatefulWidget with build-skip cache for messages
│       │   ├── chat_input_widget.dart  # Chat input orchestrator/facade
│       │   └── chat_input/             # ChatInput decomposed clusters (8 modules)
│       ├── services/                   # Platform/runtime services (tray, notifications, STT, etc.)
│       ├── utils/                      # Presentation helpers (incl. WindowSizeClass MD3 breakpoints)
│       └── theme/                      # Material You theme: AppTheme, AppShapes, BrandColor seeds, AppSemanticColors
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
lib/presentation/pages/app_shell_page.dart   # Root shell; gates onboarding wizard, mounts ChatPage and desktop tray behavior; triggers startup/hourly update toast via `addPostFrameCallback` + `UpdateCheckResult` when `checkUpdatesOnOpen` is enabled; reacts to `UpdateInstallState` transitions with platform-aware snackbars (Android downloading progress, desktop installing spinner, done/retry states) and triggers `startInstall()`
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
lib/data/datasources/chat_remote_datasource.dart  # Chat/session/message/realtime API access; accepts optional `sseDio` for SSE stream isolation; sendMessage uses polling + provider-level SSE only (no per-send SSE) to prevent server-side abort on disconnect; provider `prompt_async` sends intentionally do not forward `messageId`; async completion fallback escalates to polling and uses stricter staleness guards when no-candidate/empty-baseline scenarios occur to prevent early finalization; bounds message-list tail fetches (`limit=120`); uses bounded per-session assistant-id cache (64-session cap + invalidation on unresolved completion); reduced idle/fallback polling cadence
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
lib/presentation/providers/settings_provider.dart # Experience settings, theme mode, dynamic color, AMOLED dark toggle, brand seed, contrast, composer tips visibility, sounds, update checks, desktop pane widths; exposes `dynamicColorAvailable` (bool) and `updateDynamicColorAvailability()` for runtime platform signal; `setCheckUpdatesOnOpen()` now controls startup + hourly automatic checks via `_configureAutomaticUpdateChecks()` and `_performStartupUpdateCheck()`; `UpdateInstallState` enum (idle/downloading/installing/done/failed), `startInstall()`, and `restartDesktopApp()` manage APK/desktop install lifecycle
lib/presentation/theme/brand_colors.dart              # BrandColor enum with 5 seed colors for non-dynamic-color themes
lib/presentation/theme/app_shapes.dart                # AppShapes class with centralized MD3 shape constants
lib/presentation/theme/app_theme.dart                 # Material You theme builder using AppShapes and color scheme
lib/presentation/theme/app_animations.dart            # Animation duration tokens; includes userBubble (130 ms) and assistantBubble (180 ms)
lib/presentation/utils/window_size_class.dart         # WindowSizeClass enum with MD3 breakpoints + BuildContext extension
lib/presentation/services/desktop_tray_service_io.dart # Desktop tray lifecycle; selects tray icon per OS (macOS template PNG, Windows ICO, Linux PNG)
lib/presentation/services/notification_service.dart    # Local notifications; Android uses `@drawable/ic_stat_codewalk` small icon and no longer drives foreground monitor state
lib/presentation/services/android_foreground_monitor_service.dart # Android foreground service via MethodChannel; active only during temporary live monitoring for known background work
lib/presentation/services/android_background_alert_worker.dart # WorkManager-based background polling; 3m active probes, 5m tail probe, and low-data title-cached notification fetches
lib/presentation/services/android_background_alert_logic.dart # Pure logic for tail probe scheduling, alert planning, and snapshot state
lib/presentation/services/android_battery_optimization_service.dart # Android battery optimization query/exemption request via MethodChannel
lib/presentation/providers/chat_provider.dart     # Chat state/realtime/session facade; cache-first per-session SWR restore, in-memory LRU message cache, persisted per-session snapshots, microtask coalescing, event dedup buffer, render gate, favorite models; drives timeline visibility, undo/redo availability, and composer draft restoration from the SessionRevert boundary; project-switch SWR support via `onProjectScopeChanged(waitForRevalidation: false)` and `loadSessions(backgroundRevalidation: true)`; non-active contexts marked dirty by global events keep cache for immediate restore-on-return, while background revalidation refreshes state; active-session SWR uses limited-tail (delta-like) refresh with overlap merge and full-fetch fallback; message merge / refresh behavior has regression coverage protecting active tool/work visibility during optimistic echo replay and refresh/reconcile; includes `loadOlderMessages()` scaffold and keeps loadSessionInsights fire-and-forget on session switch; idle final-message reconcile can bypass abort-suppression only for targeted `session-idle-final-reconcile`; New Chat uses draft-first flow (`beginNewChatDraft`) with lazy session bootstrap on first send, and draft state is now context-scoped inside `_ChatContextSnapshot` to prevent cross-project leakage during fast switches; keeps provider-side optimistic user IDs on the local `local_user_*` contract for `prompt_async` sends; includes cross-scope helpers `visibleSessionsForScopeId` and `hasSnapshotForScopeId`
lib/presentation/pages/onboarding_wizard_page.dart # 3-step onboarding wizard (Welcome, Server Setup, Ready); uses ServerSetupQuickGuide
lib/presentation/pages/settings/sections/servers_settings_section.dart # Server profile CRUD; exports reusable ServerSetupQuickGuide widget
lib/presentation/pages/chat_page.dart             # Chat UI orchestration facade; WindowListener for desktop lifecycle; guards startup (checkConnection/loadSessions) against no-active-server; holds tool-chain expanded state map; _isSessionSwitchInFlight guard, _sessionCollapseHistoryCache / _sessionCollapseWorkCache per-session collapse maps; top-reach history loading is coordinated with anchor-preserving restore; workspace controller uses fast project-scope switch path
lib/presentation/widgets/chat_input_widget.dart   # Composer/input orchestration facade
lib/presentation/widgets/chat_message_widget.dart # Message bubble with build-skip cache, cached MarkdownStyleSheet; compact (<600dp) collapsed-copy variants for reasoning/tool-chain/tool-content toggles; completed tool-chain groups preserve user expansion through ordinary parent rebuilds (no involuntary collapse-on-scroll); includes `SubtaskPart`/`task` navigation callbacks and stable rebuild gating keyed by callback identity
lib/presentation/widgets/session_todo_list_widget.dart # Session task panel with progress bar and keyboard-aware collapse; compact mobile collapsed summaries use count-first wording (`x/y in progress`, `x/y done`)
lib/presentation/widgets/chat_session_list.dart    # Chat session list widget; uses responsive vertical tile padding (1 on desktop, 3 on mobile) for information density
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
chat_page_scroll_coordinator.dart                  # Handles top-scroll older-history trigger (requires real active user scroll activity so layout shrink/collapse cannot falsely load older history) and viewport anchor restoration after prepend
chat_page_workspace_controller.dart
chat_page_shortcuts.dart
chat_page_status_presenter.dart
chat_page_selector_flow.dart               # ConstrainedBox wrapped in Flexible to prevent overflow at medium breakpoint
chat_page_scaffold.dart                          # Session selection reordered to close-first; _handleSessionSwitch() guard prevents concurrent switches; conversations sidebar includes project groups card with open-project controls and session previews; applies compact desktop spacing and passes responsive row spacing to ChatSessionList
chat_page_file_explorer_controller.dart
chat_page_file_viewer.dart
chat_page_composer_status.dart                    # Resolves the fixed composer live-progress surface for latest busy tool/patch/reasoning activity using composer-specific compact labels via toolResolveComposerDescriptionLabel
chat_page_command_query.dart
chat_page_runtime_support.dart                   # _syncSessionScrollState saves/restores per-session collapse state via _sessionCollapseHistoryCache / _sessionCollapseWorkCache; shrink auto-snap only runs when viewport remains near bottom to avoid forced jumps while reading expanded history; coordinates scroll state with revert-boundary transitions
chat_page_chrome.dart
chat_page_file_runtime.dart
chat_page_composer_widgets.dart                   # Reserved-height composer progress slot with in-place slide/fade updates so busy status changes do not move the timeline
chat_page_model_selector_runtime.dart        # New Chat action opens draft mode immediately via provider `beginNewChatDraft()`; child-thread selector labels are memoized and locked to sub-conversation metadata (model shown, variant shown only when explicit)
chat_page_timeline_builder.dart              # Renders empty state with no-server CTA to wizard; passes `role` to MessageEntranceAnimation so each bubble uses the correct motion profile; composer stays enabled during draft-first New Chat (`currentSession != null || isDraftingNewChat`) and in sub-conversation sessions; sub-conversation model/agent selection remains session-context aware/locked; child-thread footer keeps `Return to main conversation` visible (stop behavior managed by composer)
chat_page_timeline_runtime.dart              # Tool-chain expanded state key resolution (sessionId::messageId::startPartId)
```

### Chat message widgets

```text
lib/presentation/widgets/chat_message/chat_message_tool_part.dart   # Renders long tool outputs in a bounded internal scroll viewport; large diffs use lazy rendering so tool growth does not destabilize the outer chat timeline
lib/presentation/widgets/chat_message/chat_message_part_dispatch.dart # Reorders contiguous visible `task` tool runs so unfinished task bubbles stay last within each run while non-task grouping remains unchanged
lib/presentation/utils/tool_presentation.dart                      # Shared tool label/icon formatting reused by chat bubbles and the fixed composer live-progress surface
```

### `lib/presentation/providers/chat_provider/` clusters (current)

```text
chat_provider_core.dart
chat_provider_session_ops.dart           # Implements undo/redo turn logic (revert latest user message, advance revert boundary, and restore composer drafts)
chat_provider_realtime_ops.dart           # Realtime event handling; defers stale `session.idle` reconciliation until the active send stream settles so server-driven lifecycle stays authoritative across follow-up sends
chat_provider_realtime_aux_ops.dart
chat_provider_event_reducer_ops.dart             # Reconcile one-shot guard via _messageStreamGeneration; dedup key composition
chat_provider_message_merge_ops.dart
chat_provider_message_state_ops.dart             # Message state mutations; auto-title scheduling guard skips subsessions
chat_provider_selection_sync_ops.dart
chat_provider_selection_helpers.dart
chat_provider_context_state_ops.dart
chat_provider_preference_ops.dart
chat_provider_shortcut_cycle_ops.dart
chat_provider_auto_title_ops.dart               # Auto-title execution (main/root sessions only); runtime guard in `_runAutoTitlePass` skips subsessions
chat_provider_error_policy.dart
chat_provider_cache_persistence_ops.dart
chat_provider_abort_policy_ops.dart
```

### `lib/presentation/widgets/chat_input/` clusters (current)

```text
chat_input_state_machine.dart
chat_input_history_controller.dart             # Local command/prompt history and external draft restoration/clear support for undo/redo parity
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
test/unit/providers/                   # ChatProvider split tests (7 files, 129 tests, parallelized with -j 12)
  chat_provider_init_test.dart         #   12 tests — initialization, config sync, model/agent selection
  chat_provider_sync_test.dart         #   17 tests — deferred sync, cycle, scope, overrides, variant sync
  chat_provider_messaging_test.dart    #   15 tests — sessions, sendMessage, draft restore; delta-like SWR fallback coverage
  chat_provider_realtime_test.dart     #   21 tests — title gen (main sessions only), SSE, abort, reconciliation
  chat_provider_session_ops_test.dart  #   25 tests — rename/share/fork/delete, insights, undo/redo parity (regression coverage), idle
  chat_provider_project_test.dart      #   13 tests — permissions, questions, project scope, favorites; project-switch SWR behavior + draft isolation + dirty-context cache retention
  chat_provider_concurrency_test.dart  #   26 tests — render gate, multi-session, abort suppression
  chat_provider_test_support.dart      #   Shared utilities (RecordingDioClient, buildChatProvider, testModel); FakeChatRepository.getSessionsDelay
test/widget/                           # Widget tests (includes icon assertions with Symbols.* and explicit compact/mobile collapsed-copy coverage for chat message and session todo surfaces, plus desktop/mobile spacing coverage for ChatSessionList; includes toolbar undo/redo and slash-command parity coverage)
test/integration/                      # Integration tests; includes data-usage optimization coverage in `opencode_server_integration_test.dart`
test/presentation/                     # Presentation-focused tests (incl. window_size_class_test.dart)
test/support/                          # Test helpers/fakes; `mock_opencode_server.dart` includes extra counters for usage optimization tracking
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
- featM icon migration is largely complete in `lib/presentation/**` and `test/widget/**`; one notifications settings widget still uses `Icons.*` while the rest has moved to `Symbols.*` (`material_symbols_icons`).

### Direct Follow-up Send Flow

- **Provider send path**: `chat_provider.dart` routes new and follow-up turns through the same `sendMessage()` / `prompt_async` path; local queued-envelope drain and `Send now` orchestration were removed in featR g5.
- **Composer action swap**: `chat_input_widget.dart` shows `Stop` only when the session is responding and the composer has no sendable draft; once text/attachments exist, the primary action switches back to direct send.
- **Server-backed feedback**: `chat_page_composer_status.dart` and `chat_page_composer_widgets.dart` present reasoning/receiving/retrying state from the active turn without inventing a client-side queued lifecycle.

### Android Background Monitoring

- **Native foreground service** (`android/app/src/main/kotlin/com/verseles/codewalk/CodeWalkForegroundService.kt`):
  Owns the ongoing Android monitor notification and receives MethodChannel-driven updates.
- **Dart bridge** (`android_foreground_monitor_service.dart`): Calls `codewalk/system`
  channel methods (`updateForegroundNotification`, `stopForegroundService`) and keeps
  service state idempotent from Flutter side.
- **Runtime policy** (`settings_provider.dart` + `chat_page_lifecycle.dart`): Gates Android
  monitoring behind the master setting and known active work; disabling it cancels probes and stops the monitor notification.
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

### Update Install Flow (Android + Desktop)

- **`UpdateCheckResult.apkUrl`** (`update_check_service.dart`): GitHub release asset URL for the `.apk`; populated when the release includes an APK asset matching the architecture filter.
- **`UpdateInstallState`** (`settings_provider.dart`): Enum tracking download/install lifecycle — `idle → downloading → installing → done | failed`.
- **Automatic checks while open** (`settings_provider.dart`): `checkUpdatesOnOpen` runs a silent startup check and schedules an hourly `Timer.periodic` check while the app stays open.
- **`SettingsProvider.startInstall()`**: Android downloads the APK to a temp file via Dio `saveFile`, then calls `OpenFilex.open()` to trigger the system installer; desktop runs the install script and marks `done|failed`. Guards against re-entry when already downloading/installing.
- **`SettingsProvider.restartDesktopApp()`**: Desktop-only relaunch helper used by snackbar action; attempts detached relaunch and then exits current process.
- **`AppShellPage` reactions**: Observes `installState` transitions; shows Android downloading progress snackbar, desktop installing indefinite snackbar, done snackbar with desktop `Restart` action, and failed retry snackbar; the update toast "Install" action calls `startInstall()`.
- **`AboutSettingsSection` controls**: Renders inline progress indicators and retry/install buttons reflecting `installState`; delegates to `settings.startInstall()`.

### Performance & Animations

- **Performance Architecture**:
  - **ChatProvider microtask coalescing**: `_notifyScheduled` / `_scrollScheduled` flags gate `scheduleMicrotask` so that multiple state mutations within the same frame produce only one `notifyListeners()` / scroll-to-bottom call.
  - **Event dedup buffer**: `_recentEventIds` (circular `Queue<String>`) in ChatProvider stores recent event keys built by `_composeEventDeduplicationKey`.
  - **Render gate**: `_hasPendingRenderFlush` in ChatProvider suppresses `notifyListeners()` while the app is in background.
  - **ChatMessageWidget build-skip cache**: Converted from `StatelessWidget` to `StatefulWidget`; completed messages short-circuit `build()` by returning a cached widget tree.
  - **Per-session hydrated timeline cache**: ChatPage keeps `_sessionTimelineEntriesCache` to store grouped timeline presentation per session, enabling instant reopen without full visual rebuild.
  - **Instant reopen bottom anchoring**: Reopening a cached session scrolls directly to bottom instead of using animated settle scrolling.

- **Chat Entrance Animations**:
  - **Staggered Message Entrance**: Tail message entrance is coordinated via `chat_page_timeline_builder.dart` and `message_entrance_animation.dart`.
  - **In-bubble Part Entrance**: Streamed part entrance is handled in-bubble via `chat_message_widget.dart`, `chat_message_part_dispatch.dart`, and `PartEntranceAnimation`.
  - **Animation tokens**: `AppAnimations` defines userBubble (130 ms) and assistantBubble (180 ms) motion profiles.
  - **Regression Coverage**: `test/widget/chat_message_widget_test.dart` ensures stable animation behavior and part-dispatch logic.

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
