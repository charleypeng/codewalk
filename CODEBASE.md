# Code map of CodeWalk

## Project Snapshot

- Flutter client for OpenCode-compatible servers.
- Architecture follows `presentation -> domain -> data` with `get_it` + `provider`.
- Multi-platform targets in repo: Android, Linux, macOS, Windows, Web.
- Chat stack is decomposed into orchestrators plus focused cluster modules.
- Material icon convention in UI/tests now uses `Symbols.*` (`material_symbols_icons`) instead of `Icons.*`.
- Theme system follows Material You (MD3): user-controlled theme mode, dynamic color toggle, brand color seeds, contrast level, and responsive window size classes.

## Folder Structure

```text
codewalk/
├── ai-docs/                            # AI docs and engineering artifacts
├── lib/                                # Application source
│   ├── main.dart                       # App bootstrap (DI, providers, shell)
│   ├── core/                           # Config, constants, DI, errors, logging, network
│   ├── data/                           # Data layer: datasources, models, repositories
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
└── Makefile                            # Main development and validation commands
```

## Entry Points

```text
lib/main.dart                                # Runtime entry; DI, providers, DynamicColorBuilder with user theme prefs; syncs dynamic color availability to SettingsProvider via postFrameCallback
lib/presentation/pages/app_shell_page.dart   # Root shell; gates onboarding wizard, mounts ChatPage and desktop tray behavior
lib/presentation/pages/onboarding_wizard_page.dart # First-run wizard shown when no server is configured
lib/presentation/pages/chat_page.dart         # Main chat/session/file UI entry; uses WindowSizeClass for responsive layout
.github/workflows/ci.yml                      # CI workflow entry
.github/workflows/release.yml                 # Release workflow entry
```

## Core Modules

```text
lib/core/di/injection_container.dart              # Registers datasources, repositories, usecases, providers
lib/core/network/dio_client.dart                  # HTTP client config, auth, and base URL updates
lib/data/datasources/app_remote_datasource.dart   # App bootstrap/config/providers/agents API access
lib/data/datasources/chat_remote_datasource.dart  # Chat/session/message/realtime API access
lib/data/datasources/project_remote_datasource.dart # Project/worktree/file API access
lib/data/datasources/app_local_datasource.dart    # Persistent settings, profiles, cache, credentials, and favorite models
lib/data/repositories/*.dart                      # Domain repository implementations
lib/domain/usecases/*.dart                        # Application use cases consumed by providers
lib/presentation/providers/app_provider.dart      # Server profiles, health polling, local runtime state
lib/presentation/providers/project_provider.dart  # Project/worktree context selection and persistence
lib/presentation/providers/settings_provider.dart # Experience settings, theme mode, dynamic color, brand seed, contrast, sounds, update checks, desktop pane widths; exposes `dynamicColorAvailable` (bool) and `updateDynamicColorAvailability()` for runtime platform signal
lib/presentation/theme/brand_colors.dart              # BrandColor enum with 5 seed colors for non-dynamic-color themes
lib/presentation/theme/app_shapes.dart                # AppShapes class with centralized MD3 shape constants
lib/presentation/theme/app_theme.dart                 # Material You theme builder using AppShapes and color scheme
lib/presentation/utils/window_size_class.dart         # WindowSizeClass enum with MD3 breakpoints + BuildContext extension
lib/presentation/providers/chat_provider.dart     # Chat state/realtime/session facade; microtask coalescing, event dedup buffer, render gate, favorite models
lib/presentation/pages/onboarding_wizard_page.dart # 3-step onboarding wizard (Welcome, Server Setup, Ready); uses ServerSetupQuickGuide
lib/presentation/pages/settings/sections/servers_settings_section.dart # Server profile CRUD; exports reusable ServerSetupQuickGuide widget
lib/presentation/pages/chat_page.dart             # Chat UI orchestration facade; WindowListener for desktop lifecycle
lib/presentation/widgets/chat_input_widget.dart   # Composer/input orchestration facade
lib/presentation/widgets/chat_message_widget.dart # Message bubble with build-skip cache, cached MarkdownStyleSheet
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
chat_page_scroll_coordinator.dart
chat_page_workspace_controller.dart
chat_page_shortcuts.dart
chat_page_status_presenter.dart
chat_page_selector_flow.dart               # ConstrainedBox wrapped in Flexible to prevent overflow at medium breakpoint
chat_page_scaffold.dart
chat_page_file_explorer_controller.dart
chat_page_file_viewer.dart
chat_page_timeline_builder.dart
chat_page_composer_status.dart
chat_page_command_query.dart
chat_page_runtime_support.dart
chat_page_chrome.dart
chat_page_file_runtime.dart
chat_page_composer_widgets.dart
chat_page_model_selector_runtime.dart
chat_page_timeline_runtime.dart
```

### `lib/presentation/providers/chat_provider/` clusters (current)

```text
chat_provider_core.dart
chat_provider_session_ops.dart
chat_provider_realtime_ops.dart
chat_provider_realtime_aux_ops.dart
chat_provider_event_reducer_ops.dart
chat_provider_message_merge_ops.dart
chat_provider_message_state_ops.dart
chat_provider_selection_sync_ops.dart
chat_provider_selection_helpers.dart
chat_provider_context_state_ops.dart
chat_provider_preference_ops.dart
chat_provider_auto_title_ops.dart
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
```

## Key API/DataSource locations

```text
lib/data/datasources/app_remote_datasource.dart
  - /path, /app (fallback), /app/init (fallback), /provider, /agent, /config

lib/data/datasources/chat_remote_datasource.dart
  - /session, /session/{id}, /session/{id}/message, /session/{id}/shell
  - /session/status, /session/{id}/children, /session/{id}/todo, /session/{id}/diff
  - /session/{id}/abort, /session/{id}/revert, /session/{id}/unrevert, /session/{id}/init, /session/{id}/summarize
  - /event, /global/event
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
test/widget/                           # Widget tests (includes icon assertions with Symbols.*)
test/integration/                      # Integration tests
test/presentation/                     # Presentation-focused tests (incl. window_size_class_test.dart)
test/support/                          # Test helpers/fakes
tool/ci/check_analyze_budget.sh        # Analyzer issue budget gate (default: 186)
tool/ci/check_coverage.sh              # Coverage threshold gate (default: 35%)
.github/workflows/ci.yml               # CI executes analyze + tests + coverage gate
```

## Notes

- `make android` builds an arm64 APK and sends the artifact with `~/bin/hey`; use `HEY_CAPTION` to override the upload caption.
- Sensitive server credentials are persisted through `flutter_secure_storage` (v10.0.0) via `AppLocalDataSource`.
- Platform folders currently present: `android/`, `linux/`, `macos/`, `web/`, `windows/`.
- Android build targets Java 17 (`sourceCompatibility`, `targetCompatibility`, `jvmTarget`).
- featM icon migration completed in `lib/presentation/**` and `test/widget/**`: Material icons moved from `Icons.*` to `Symbols.*` (`material_symbols_icons`).

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

### Performance Architecture

- **ChatProvider microtask coalescing**: `_notifyScheduled` / `_scrollScheduled` flags gate
  `scheduleMicrotask` so that multiple state mutations within the same frame produce only one
  `notifyListeners()` / scroll-to-bottom call.
- **Event dedup buffer**: `_recentEventIds` (circular `Queue<String>`) in ChatProvider stores
  recent event keys built by `_composeEventDeduplicationKey` (in `chat_provider_event_reducer_ops.dart`).
  `_isRecentlyProcessedEvent` and `_tryApplyGlobalEventIncremental` use this buffer to skip
  duplicates arriving on the global SSE stream.
- **Render gate**: `_hasPendingRenderFlush` in ChatProvider suppresses `notifyListeners()` while
  the app is in background. SSE data keeps accumulating in internal fields, but widgets do not
  rebuild until the app returns to foreground and flushes the pending notification via
  `setForegroundActive(true)`.
- **Desktop window lifecycle**: `_ChatPageState` mixes in `WindowListener` (from `window_manager`)
  to handle focus/blur/minimize/restore on desktop platforms. These events drive
  `_applyForegroundPolicy`, which coordinates with the ChatProvider render gate and
  `_handleReturnToChat` to pause/resume UI rebuilds and SSE refresh on window state changes.
- **ChatMessageWidget build-skip cache**: Converted from `StatelessWidget` to `StatefulWidget`;
  completed messages short-circuit `build()` by returning a cached widget tree.
  `MarkdownStyleSheet` is cached in `_cachedMarkdownStyleSheet` and invalidated only on
  brightness change.
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
  preferences (`themeMode`, `useDynamicColor`, `customColorSeed`, `contrastLevel`) are stored
  in `ExperienceSettings` and exposed via `SettingsProvider`.
- **BrandColor** (`brand_colors.dart`): Enum with 5 curated seed colors (Indigo, Teal, Rose,
  Amber, Slate) used when dynamic color is unavailable or disabled.
- **AppShapes** (`app_shapes.dart`): Centralized MD3 shape constants consumed by `AppTheme`
  and individual widgets for consistent rounded corners.
- **WindowSizeClass** (`window_size_class.dart`): Enum (`compact`, `medium`, `expanded`,
  `large`, `extraLarge`) derived from MD3 breakpoints. `BuildContext.windowSizeClass` extension
  replaces hardcoded width checks in `ChatPage` and `SettingsPage`.
- **Settings UI** (`appearance_settings_section.dart`): Theme mode, color picker (brand colors
  + dynamic color toggle), and contrast level cards added to the Appearance section. Dynamic
  color availability is read from `settingsProvider.dynamicColorAvailable` (runtime signal set
  by `DynamicColorBuilder` in `main.dart`) instead of a heuristic; contrast slider is disabled
  when dynamic color is active.
