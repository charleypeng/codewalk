# Code map of CodeWalk

## Project Snapshot

- Flutter client for OpenCode-compatible servers (ADR-023: contract-first compatibility policy).
- Architecture follows `presentation -> domain -> data` with `get_it` + `provider`.
- Multi-platform targets in repo: Android, Linux, macOS, Windows, Web.
- Chat stack is decomposed into orchestrators plus focused cluster modules.
- Material icon migration in UI is complete on `Symbols.*` (`material_symbols_icons`).
- Theme system follows Material You (MD3): user-controlled theme mode, dynamic color toggle, AMOLED dark toggle, brand color seeds, contrast level, and responsive window size classes.
- LaTeX math rendering (`$...$` and `$$...$$`) supported in chat messages via `flutter_math_fork` with custom markdown syntaxes and styled fallback on parse failure.

## Folder Structure

```text
codewalk/
├── ai-docs/                            # AI docs and engineering artifacts
│   └── implement.md                    # Synthesized upstream alignment plan (OpenCode v1.14.x - v1.15.0)
├── assets/
│   ├── images/                           # Source and generated launcher/tray icon assets used by `make icons`
│   ├── parakeet_models.json              # Parakeet STT model catalog (id, label, download URL, lang)
│   └── sensevoice_models.json            # SenseVoice STT model catalog (id, label, download URL, lang)
├── lib/                                # Application source
│   ├── main.dart                       # App bootstrap (DI, providers, shell)
│   ├── core/                           # Config, constants, DI, errors, logging, network
│   │   ├── auth/                        # OAuth module: conditional OAuthService (IO/stub), OAuthCredential model, OAuthTokenStorage secure backend, OAuthFlowResult model
│   │   ├── i18n/                        # Locale registry, context bridge, localization helpers
│   │   ├── tailscale/                    # Tailscale transport: service (IO/stub), node state, Dio adapter
│   │   └── utils/                       # Core utilities (path, timeline search)
│   ├── data/                           # Data layer: datasources, search models, repositories, cache
│   │   └── cache/                      # Hybrid file+memory cache for large chat payloads
│   ├── domain/                         # Domain layer: entities, repository contracts, use cases
│   ├── l10n/                           # Flutter gen_l10n ARB files (14 locales) and generated delegates
│   │   ├── app_en.arb                  # English source ARB (~200 UI keys with metadata)
│   │   ├── app_*.arb                   # Translation ARBs (ar, bn, de, es, fr, hi, it, ja, ko, pt, ru, ur, zh)
│   │   └── generated/                  # Auto-generated AppLocalizations classes via flutter gen-l10n
│   └── presentation/                   # UI, state providers, runtime services
│       ├── pages/                      # App pages and page-level orchestration
│       │   ├── app_shell_page.dart
│       │   ├── onboarding_wizard_page.dart # First-run onboarding wizard (Welcome → Server Setup → Ready)
│       │   ├── chat_page.dart          # Chat orchestrator/facade
│       │   ├── chat_page_types_part.dart # Shared intents, configurations, and keys (including _ViewportBuildKey)
│       │   └── chat_page/              # ChatPage decomposed clusters (21 modules)
│       ├── providers/                  # App/Chat/Project/Settings state orchestration
│       │   ├── chat_provider.dart      # Chat provider orchestrator/facade
│       │   └── chat_provider/          # ChatProvider decomposed clusters (16 modules)
│       ├── widgets/
│       │   ├── chat_message_widget.dart # StatefulWidget with build-skip cache for messages
│       │   ├── chat_input_widget.dart  # Chat input orchestrator/facade
│       │   ├── chat_input/             # ChatInput decomposed clusters (8 modules)
│       │   └── math_expression_widget.dart # LaTeX math renderer with parse-failure styled fallback
│       ├── services/                   # Platform/runtime services (tray, notifications, STT, terminal, etc.)
│   ├── utils/ # Presentation helpers (incl. WindowSizeClass MD3 breakpoints, diff parser, file path detector, file path markdown, math markdown)
│       └── theme/                      # Material You theme: AppTheme, AppShapes, BrandColor seeds, AppSemanticColors
├── test/                               # Unit, widget, integration, presentation, support tests
├── tool/ci/                            # Analyzer budget and coverage gate scripts
├── tool/i18n/                          # ARB generation and code migration tooling
├── .github/workflows/                  # CI and release workflows
├── .opencode/agents/                  # Repo-local OpenCode agents
├── android/ linux/ macos/ web/ windows/ # Platform runners/build configs
├── android/app/src/main/res/drawable-*/ # Android notification small icons (`ic_stat_codewalk.png`)
├── linux/runner/resources/             # Linux launcher icon + desktop entry icon metadata
├── third_party/                         # Vendored Dart packages (path dependencies)
│   ├── tailscale/                        # Userspace Tailscale networking; Go native build hook via `hook/build.dart`
│   └── xterm/                            # xterm.js terminal emulator Dart port (customized with Windows-only printable hardware-key fallback and AltGr support)
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
lib/core/di/injection_container.dart              # Registers datasources, repositories, usecases, providers, TailscaleService; wires tailscaleService into AppProvider factory; _loadLocalConfig applies tailscaleEnabled on active profile
lib/core/i18n/app_locales.dart                     # Locale registry: 14 supported locales, resolution callback, native-name metadata, PT_BR normalization
lib/core/i18n/l10n_context.dart                    # BuildContext extension: `context.l10n` shorthand for AppLocalizations access
lib/core/i18n/l10n_bridge.dart                     # Static L10nBridge for context-free localization (tray, background services)
lib/core/utils/timeline_search_service.dart         # Client-side full-text search over timeline messages: extracts TextPart.text and ReasoningPart.text, performs case-insensitive matching with occurrence counting, and returns results ordered by message age
lib/core/network/dio_client.dart                  # HTTP client config, auth, base URL updates, Tailscale adapter swap; exposes `dio` (regular) and `sseDio` (dedicated SSE instance with isolated connection pool); Tailscale transport via applyTailscaleAdapter/removeTailscaleAdapter; createHealthCheckDio propagates active adapter to ephemeral Dio instances; OAuth auth ownership via setOAuthToken/clearOAuthToken/clearAuth with Basic Auth coexistence and header restoration
lib/core/network/dio_sse_adapter.dart              # Conditional export: routes to IO or stub adapter
lib/core/network/dio_sse_adapter_io.dart           # IO platforms: configures IOHttpClientAdapter with separate HttpClient for SSE (2h idle, 4 max connections)
lib/core/network/dio_sse_adapter_stub.dart         # Web platform: no-op (browser manages connections natively)
lib/core/tailscale/tailscale_service.dart          # Conditional export barrel: routes to IO or stub TailscaleService via `export if (dart.library.io)`; re-exports TailscaleState
lib/core/tailscale/tailscale_service_io.dart       # IO implementation: per-profile Tailscale node lifecycle (up/down/state), state change broadcast via StreamController, wraps `tailscale` Dart package; isolates per-profile state dir, builds hostname from profile label
lib/core/tailscale/tailscale_service_stub.dart     # Non-IO platforms: TailscaleService stub (state=unsupported, hasClient=false, httpClient/down throw UnsupportedError)
lib/core/tailscale/tailscale_state.dart            # TailscaleNodeState enum (disconnected/connecting/connected/needsLogin/needsMachineAuth/error/unsupported) + TailscaleState Equatable model with authUrl, message, isConnected, requiresUserLogin
lib/core/tailscale/tailscale_http_adapter.dart     # Dio HttpClientAdapter bridging Tailscale's http.Client to Dio; implements fetch() delegating to http.StreamedRequest; handles cancelFuture, body streaming, redirect policy; used by applyTailscaleAdapter to swap default transport
lib/core/auth/oauth_service.dart                   # Conditional export barrel: re-exports oauth_service_result.dart, routes to IO or stub via `export if (dart.library.io)`
lib/core/auth/oauth_service_io.dart                # OAuthService IO implementation (desktop + Android): Cloudflare Access Managed OAuth with PKCE (S256); desktop uses local HttpServer callback, Android uses flutter_appauth Chrome Custom Tab; credential caching/refresh, OAuth metadata discovery, trusted endpoint validation, callback URL validation
lib/core/auth/oauth_service_stub.dart              # Non-IO platforms: OAuthService stub (isOAuthChallenge returns false, all other methods throw "not supported on this platform")
lib/core/auth/oauth_service_result.dart            # OAuthFlowResult model: ok/token/error/needsConsent/log fields for flow completion tracking
lib/core/auth/oauth_token_storage.dart             # Secure OAuth credential persistence: OAuthTokenStorageBackend interface, FlutterSecureOAuthTokenStorageBackend (flutter_secure_storage), OAuthTokenStorage with save/load/delete/hasValidCredential, cross-profile key scoping, OAuthTokenStorageException
lib/core/auth/oauth_credential.dart                # OAuthCredential model: accessToken, refreshToken, expiresAt, isExpired/isValid check (5-min buffer), JSON serialization (fromJson/toJson)
lib/data/datasources/app_remote_datasource.dart   # App bootstrap/config/providers/agents API access; app discovery retries scoped `/provider`, `/agent`, and `/config` calls with `directory`-only and then unscoped fallbacks when workspace-scoped queries fail; `/agent` parsing tolerates multiple upstream payload shapes; scoped discovery/config calls forward both `directory` and `workspace` when a project directory is active
lib/data/datasources/chat_remote_datasource.dart  # Chat/session/message/realtime API access; accepts optional `sseDio` for SSE stream isolation; sendMessage uses polling + provider-level SSE only (no per-send SSE) to prevent server-side abort on disconnect; provider `prompt_async` sends intentionally do not forward `messageId`; async completion fallback escalates to polling and uses stricter staleness guards when no-candidate/empty-baseline scenarios occur to prevent early finalization; bounds message-list tail fetches (`limit=120`); uses bounded per-session assistant-id cache (64-session cap + invalidation on unresolved completion); handles session-scoped permission replies with legacy fallback, sends `remember: true` for `always` replies, and preserves typed upstream error names/codes/details in surfaced failures; SSE backoff loop fix — streamAliveStart enforces 5-second threshold before resetting reconnect counter, ±20% jitter to prevent thundering-herd
lib/data/datasources/project_remote_datasource.dart # Project/worktree/file API access; file-name search (`/find/file`), file-content search (`/find?pattern=`), and workspace symbol search (`/find/symbol`)
lib/data/datasources/app_local_datasource.dart    # Persistent settings, profiles, cache, credentials, favorite models, session composer drafts, and per-agent selection memory; uses ChatCachePayloadStore hybrid store with shared_preferences fallback for large payloads
lib/data/cache/chat_cache_payload_store.dart      # Factory with conditional import for platform-specific store
lib/data/cache/chat_cache_payload_store_base.dart # Abstract interface for cache store (read/write/remove/clear)
lib/data/cache/chat_cache_payload_store_io.dart   # IO implementation: hybrid file+LRU memory cache (24 entries) for chat payloads
lib/data/cache/chat_cache_payload_store_stub.dart # Non-IO platforms: disabled payload store (returns null)
lib/data/repositories/*.dart                      # Domain repository implementations
lib/data/datasources/quota_remote_datasource.dart # Strategy-chain quota discovery: tries OpenChamber REST (`GET /api/quota/providers`) then falls back to a hidden ephemeral shell probe (`CW_QUOTA_JSON:`) for vanilla OpenCode hosts
lib/domain/usecases/*.dart                        # Application use cases consumed by providers
lib/domain/entities/quota.dart                    # Quota domain entities: `QuotaSnapshot`, `UsageWindow`, `PaceInfo`, `QuotaEntry`, `QuotaProviderGroup`
lib/presentation/providers/app_provider.dart      # Server profiles, health polling, local runtime state, OAuth challenge lifecycle, Tailscale transport orchestration; supportsTailscale (Android/iOS/Linux/macOS), _applyTailscaleTransport() drives per-profile Tailscale node lifecycle (upForProfile/auth URL launch/down), swaps Dio adapter via TailscaleHttpAdapter, propagates active adapter to health-check Dio via createHealthCheckDio; tailscaleEnabled in addServerProfile/updateServerProfile CRUD; exposes reactive Tailscale state getters: tailscaleState, tailscaleNodeState, tailscaleAuthUrl, tailscaleMessage, tailscaleNeedsAuth, tailscaleNeedsMachineAuth, and authenticateTailscale() method; guards health polling/connection when no active server profile is set; includes setup-debug state (SetupDebugEntry, SetupDebugSeverity) for OpenCode installation diagnostics with recordSetupDebugEvent(), exportSetupDebugReport(), clearSetupDebugData(); OAuth challenge tracking via hasOAuthChallenge/getOAuthChallengeHeaders, handleOAuthChallenge (creates OAuthService, runs PKCE flow, sets Dio token, verifies connection), clearOAuthCredential, isOAuthAuthenticated, and oauthEnabled cache-on-activate; supportsCloudflareAccessOAuth includes desktop (macOS/Windows/Linux) and Android, gates iOS out
lib/presentation/providers/project_provider.dart  # Project/worktree context selection and persistence; exposes file-name, file-content, and workspace-symbol search for Quick Open and composer mentions
lib/presentation/providers/settings_provider.dart # Experience settings, theme mode, dynamic color, AMOLED dark toggle, brand seed, contrast, composer tips visibility, sounds, update checks, and complete OpenCode shared settings coverage (default model, default agent, small model, autoupdate, share, username, snapshot); exposes `dynamicColorAvailable` (bool) and `updateDynamicColorAvailability()` for runtime platform signal; `setCheckUpdatesOnOpen()` now controls startup + hourly automatic checks via `_configureAutomaticUpdateChecks()` and `_performStartupUpdateCheck()`; `UpdateInstallState` enum (idle/downloading/installing/done/failed), `startInstall()`, and `restartDesktopApp()` manage APK/desktop install lifecycle
lib/presentation/providers/quota_provider.dart # Host-discovered quota state: polls `QuotaRemoteDataSource`, TTL-based cache (60s) scoped per `serverId`, normalises raw data into `QuotaProviderGroup` list ordered by severity; `ensureLoaded()` for lazy UI-triggered fetch; Codex single-window label preserved using provider name instead of raw API label (guarded by `result.providerId != 'codex'`)
lib/presentation/utils/quota_pace_utils.dart # Pure Dart pace helpers: `predictedFinalPercent`, `PaceStatus` enum, window/label inference, and formatted `Pace xx%` / time-left strings
lib/presentation/widgets/settings_provenance_chip.dart # Shared provenance badge widget for `OpenCode-backed`, `CodeWalk-local`, and `CodeWalk exception` labels used by Behavior, Notifications, and Shortcuts settings surfaces
lib/presentation/widgets/searchable_dropdown_form_field.dart # Reusable FormField<T> searchable dropdown with modal bottom sheet picker; used by servers, speech, notifications, appearance, and behavior settings sections
lib/presentation/theme/opencode_web_theme_registry.dart # Generated local mirror of the official OpenCode Web built-in theme registry with 37 theme definitions (light/dark palette + overrides); regenerate via `tool/theme/generate_opencode_web_themes.py`
lib/presentation/theme/opencode_theme_presets.dart     # Theme registry bridge from OpenCode Web ids to Flutter `ColorScheme` plus `OpenCodeThemeTokens` ThemeExtension for markdown and syntax-aware surfaces
lib/presentation/theme/opencode_highlight_theme.dart   # Converts active `OpenCodeThemeTokens` into `flutter_highlight` TextStyle maps for chat code fences and the file viewer
lib/presentation/theme/brand_colors.dart              # BrandColor enum with 5 seed colors for non-dynamic-color themes
lib/presentation/theme/app_shapes.dart                # AppShapes class with centralized MD3 shape constants
lib/presentation/theme/app_theme.dart                 # Material You theme builder using AppShapes and color scheme; also houses AppDensitySpacing (density-aware spacing for chrome/composer)
lib/presentation/theme/app_animations.dart            # Animation duration tokens; includes userBubble (130 ms) and assistantBubble (180 ms)
lib/presentation/utils/window_size_class.dart         # WindowSizeClass enum with MD3 breakpoints + BuildContext extension
lib/presentation/utils/diff_parser.dart # Diff parser: DiffHunk model, groupIntoHunks(), annotateLineNumbers(), resolveDiffHighlightLanguage(), kDefaultCollapseThreshold
lib/presentation/utils/file_path_detector.dart # Regex-based file path detector: ~90 known extensions, :line:col suffix parsing, code-block exclusion, URL exclusion, Windows absolute paths
lib/presentation/utils/file_path_markdown.dart # Custom flutter_markdown_plus InlineSyntax (FilePathSyntax) and MarkdownElementBuilder (FilePathBuilder) for clickable file path spans
lib/presentation/utils/math_markdown.dart # Custom markdown syntaxes (InlineMathSyntax, BlockMathSyntax, SingleLineBlockMathSyntax) and builders (InlineMathBuilder, BlockMathBuilder) for `$...$` and `$$...$$` LaTeX math expressions
lib/presentation/services/desktop_tray_service_io.dart # Desktop tray lifecycle; selects tray icon per OS (macOS template PNG, Windows ICO, Linux PNG)
lib/presentation/services/notification_service.dart    # Local notifications; Android uses `@drawable/ic_stat_codewalk` small icon and no longer drives foreground monitor state; exposes `clearNotificationsForSession()` for per-session notification dismissal
lib/presentation/services/event_feedback_dispatcher.dart  # Routes chat events to notification + sound feedback; includes `dismissForSession()` for reactive foreground notification cleanup when permissions/questions are resolved or sessions become idle
lib/presentation/services/android_foreground_monitor_service.dart # Android foreground service via MethodChannel; active only during temporary live monitoring for known background work
lib/presentation/services/android_background_alert_worker.dart # WorkManager-based background polling; 3m active probes, 5m tail probe, and low-data title-cached notification fetches; includes `removeNotifiedRequestIds()` static method to clear replied permission/question IDs from the persisted background snapshot
lib/presentation/services/android_background_alert_logic.dart # Pure logic for tail probe scheduling, alert planning, and snapshot state
lib/presentation/services/android_battery_optimization_service.dart # Android battery optimization query/exemption request via MethodChannel
lib/presentation/services/permission_auto_approve_runtime.dart # Background permission auto-approve context and session ID resolution for Android background continuity
lib/presentation/services/read_aloud_service.dart                # ReadAloudService: ChangeNotifier wrapping flutter_tts with idle/playing/paused state, speak/stop/pause methods, platform capability queries, error recovery, per-message tracking
lib/presentation/services/session_export_service.dart # SessionExportService: serializes session history to Markdown and JSON for local export; omits local_user_* IDs from JSON per ADR-023
lib/presentation/services/message_image_export_service.dart # MessageImageExportService: captures a RepaintBoundary widget as a PNG and invokes the platform share sheet; MessageImageExportResult enum (shared, tooTall, notLaidOut, failed); uses RenderRepaintBoundary.toImage() with _capturePixelRatio=2.5, capped at _maxCaptureHeight=4096 logical px
lib/presentation/services/moonshine_model_manager_io.dart # Desktop Moonshine model download/extract/delete flow using sherpa-onnx release archives + Silero VAD asset
lib/presentation/services/speech_input_service_moonshine_io.dart # Desktop Moonshine dictation backend; uses sherpa_onnx OfflineRecognizer + VoiceActivityDetector for on-device utterance recognition
lib/presentation/services/speech_input_service_stt.dart # STT abstraction backend (speech_to_text package) for iOS, macOS, Web, and Windows
lib/presentation/services/speech_input_service_parakeet.dart # Conditional export: routes to IO or stub Parakeet STT adapter
lib/presentation/services/speech_input_service_parakeet_io.dart # Desktop Parakeet STT backend; NeMo transducer for on-device transcription
lib/presentation/services/speech_input_service_parakeet_stub.dart # Non-IO platforms: no-op Parakeet stub
lib/presentation/services/parakeet_model_manager.dart # Conditional export: routes to IO or stub Parakeet model manager
lib/presentation/services/parakeet_model_manager_io.dart # Desktop Parakeet model download/extract/delete flow using NeMo release archives
lib/presentation/services/parakeet_model_manager_stub.dart # Non-IO platforms: disabled Parakeet model manager
lib/presentation/widgets/parakeet_model_download_dialog.dart # Parakeet model download/setup dialog shown when Parakeet is selected without a downloaded model
lib/presentation/services/speech_input_service_sensevoice.dart # Conditional export: routes to IO or stub SenseVoice STT adapter
lib/presentation/services/speech_input_service_sensevoice_io.dart # Desktop SenseVoice STT backend; sherpa_onnx offline recognizer for on-device transcription (strongest option for CJK + English)
lib/presentation/services/speech_input_service_sensevoice_stub.dart # Non-IO platforms: no-op SenseVoice stub
lib/presentation/services/sensevoice_model_manager.dart # Conditional export: routes to IO or stub SenseVoice model manager
lib/presentation/services/sensevoice_model_manager_io.dart # Desktop SenseVoice model download/extract/delete flow using sherpa_onnx archives
lib/presentation/services/sensevoice_model_manager_stub.dart # Non-IO platforms: disabled SenseVoice model manager
lib/presentation/widgets/sensevoice_model_download_dialog.dart # SenseVoice model download/setup dialog shown when SenseVoice is selected without a downloaded model
lib/presentation/providers/chat_provider.dart     # Chat state/realtime/session facade; cache-first per-session SWR restore, in-memory LRU message cache, persisted per-session snapshots, microtask coalescing, event dedup buffer, render gate, favorite models; drives timeline visibility, undo/redo availability, rejected-draft restoration, persisted per-session composer drafts, and per-agent provider/model/variant memory; project-switch SWR support via `onProjectScopeChanged(waitForRevalidation: false)` and `loadSessions(backgroundRevalidation: true)`; non-active contexts marked dirty by global events keep cache for immediate restore-on-return, while background revalidation refreshes state; active-session SWR uses limited-tail (delta-like) refresh with overlap merge and full-fetch fallback; message merge / refresh behavior has regression coverage protecting active tool/work visibility during optimistic echo replay and refresh/reconcile; includes `loadOlderMessages()` scaffold and keeps loadSessionInsights fire-and-forget on session switch; idle final-message reconcile can bypass abort-suppression only for targeted `session-idle-final-reconcile`; New Chat uses draft-first flow (`beginNewChatDraft`) with lazy session bootstrap on first send, and draft state is now context-scoped inside `_ChatContextSnapshot` to prevent cross-project leakage during fast switches; keeps provider-side optimistic user IDs on the local `local_user_*` contract for `prompt_async` sends and rejects them in `revertToTurn`; exposes guarded historical revert via `_historyRevertInFlight`; includes cross-scope helpers `visibleSessionsForScopeId` and `hasSnapshotForScopeId`
lib/presentation/pages/onboarding_wizard_page.dart # 3-step onboarding wizard (Welcome, Server Setup, Ready); uses ServerSetupQuickGuide; includes a Tailscale toggle (`_tailscaleEnabled`) and Tailscale auth panel (`_buildTailscaleAuthPanel()`) rendering per-state UI (needsLogin → auth button, needsMachineAuth → admin approval message, connected → success); includes navigation to OpenCodeSetupDebugPage for troubleshooting
lib/presentation/pages/opencode_setup_debug_page.dart # OpenCode setup debug surface for installation/diagnostics troubleshooting; displays environment report, setup timeline, captured logs, and exportable debug report
lib/presentation/pages/settings/sections/servers_settings_section.dart # Server profile CRUD; exports reusable ServerSetupQuickGuide widget; includes a Tailscale status card (`_buildTailscaleStatusCard()`) within the active-server details area, showing connection state with authenticate action and auth URL; includes navigation to OpenCodeSetupDebugPage
lib/presentation/pages/chat_page.dart             # Chat UI orchestration facade; WindowListener for desktop lifecycle; guards startup (checkConnection/loadSessions) against no-active-server; holds scroll state (follow mode, current scroll owner, viewport restore targets); holds tool-chain expanded state map; _isSessionSwitchInFlight guard, _sessionCollapseHistoryCache / _sessionCollapseWorkCache per-session collapse maps; top-reach history loading is coordinated with anchor-preserving restore; workspace controller uses fast project-scope switch path
lib/presentation/widgets/chat_input_widget.dart   # Composer/input orchestration facade; accepts appDensity parameter for density-aware spacing; speech controller resolves Native, Sherpa, Moonshine, Parakeet, and SenseVoice backends and routes model-required setup dialogs accordingly
lib/presentation/widgets/chat_message_widget.dart # Message bubble with build-skip cache, cached MarkdownStyleSheet; compact (<600dp) collapsed-copy variants for reasoning/tool-chain/tool-content toggles; completed tool-chain groups preserve user expansion through ordinary parent rebuilds (no involuntary collapse-on-scroll); includes `SubtaskPart`/`task` navigation callbacks, inline latest-turn undo, historical `onInlineRevertToHere`, stable rebuild gating keyed by callback identity, `onFileTap` for clickable file paths with line jumps, and `onMermaidCode` callback routing mermaid fenced blocks to MermaidDiagramWidget
lib/presentation/widgets/mermaid_diagram_widget.dart # Renders ```mermaid fenced code blocks as visual diagrams via flutter_mermaid; copy-source button; styled source fallback on parse error via errorBuilder; horizontal scroll only (no vertical scroll); responsive layout
lib/presentation/widgets/math_expression_widget.dart # Renders `$...$` and `$$...$$` LaTeX math via flutter_math_fork with styled raw-source fallback on parse failure; inline and block display modes
lib/presentation/widgets/session_diff_viewer.dart # Rich diff review surface: DiffViewMode enum (summary/unified/split), 3 view toggles, line number gutters, per-line syntax highlighting, lazy hunk collapse/expand, onFileTap jump action (wired at all 3 call sites)
lib/presentation/widgets/session_todo_list_widget.dart # Session task panel with progress bar and keyboard-aware collapse; compact mobile collapsed summaries use count-first wording (`x/y in progress`, `x/y done`)
lib/presentation/widgets/chat_session_list.dart    # Chat session list widget; uses responsive vertical tile padding (1 on desktop, 3 on mobile) for information density
lib/presentation/widgets/message_entrance_animation.dart # Entrance animation wrapper; `role` parameter selects user (130 ms) or assistant (180 ms) motion profile from AppAnimations
lib/presentation/widgets/chat_tour_showcase.dart   # Shared showcase wrapper for the first-use chat tour; provides MD3-compliant tooltip styling with consistent surface, shape, and action hierarchy using `showcaseview` package
lib/presentation/widgets/modal_primary_action_shortcuts.dart # Reusable keyboard shortcut wrapper for modal dialogs; maps Enter/NumpadEnter to a configurable primary action; used by model download dialogs, onboarding wizard, workspace controller, and session list
lib/presentation/widgets/quota/quota_popup_section.dart      # Root quota section embedded at the bottom of the Context usage popup; silent no-op when no data is available
lib/presentation/widgets/quota/quota_provider_group_row.dart # Expandable provider-group row showing critical entry bar + Pace chip; Codex-specific rendering branch (`providerId == 'codex'`) renders provider name header + iterates all entries (defensive iteration) and defaults to expanded state via initState/didUpdateWidget
lib/presentation/widgets/quota/quota_entry_row.dart          # Individual quota entry: label, severity-colored progress bar, remaining/limit figures
lib/presentation/widgets/quota/pace_label.dart               # Pace % chip: desktop tooltip, mobile snackbar explanation
```

## Chat Architecture

### Orchestrators / Facades

```text
lib/presentation/pages/chat_page.dart
lib/presentation/pages/chat_page_types_part.dart   # Shared intents, configurations, and keys including `_ViewportBuildKey`
lib/presentation/providers/chat_provider.dart
lib/presentation/widgets/chat_input_widget.dart
```

### `lib/presentation/pages/chat_page/` clusters (current)

```text
chat_page_lifecycle.dart
chat_page_scroll_coordinator.dart                  # Unified scroll ownership via `_ScrollOwner` enum (none, userDrag, paginationRestore, newMessage, streaming, returnReveal, contentShrinkSnap, searchResult); handles top-scroll older-history trigger and viewport anchor restoration; gates programmatic scrolls against user drag priority
chat_page_workspace_controller.dart
chat_page_shortcuts.dart
chat_page_status_presenter.dart                    # Simplified active-server status presentation (`Online` / `Delayed` / `Offline`) and context-usage controls
chat_page_selector_flow.dart               # ConstrainedBox wrapped in Flexible to prevent overflow at medium breakpoint
chat_page_scaffold.dart                          # Session selection reordered to close-first; _handleSessionSwitch() guard prevents concurrent switches; conversations sidebar includes project groups card with open-project controls and session previews; applies compact desktop spacing and passes responsive row spacing to ChatSessionList
chat_page_file_explorer_controller.dart        # File explorer plus Quick Open; supports Names and Contents modes backed by `/find/file` and `/find?pattern=`
chat_page_file_viewer.dart
chat_page_composer_status.dart                    # Resolves the fixed composer live-progress surface for latest busy tool/patch/reasoning activity using composer-specific compact labels via toolResolveComposerDescriptionLabel
chat_page_command_query.dart                   # Composer slash and mention query source; `@` suggestions merge files, workspace symbols, and agents while preserving agent suggestions when remote search fails
chat_page_runtime_support.dart                   # Content-shrink snap hardened against competing scroll owners; _handleScrollMetricsChanged gates on return reveal, pagination restore, and scroll owner enum; per-session collapse state cache via _sessionCollapseHistoryCache
chat_page_chrome.dart
chat_page_file_runtime.dart
chat_page_terminal_runtime.dart              # Terminal panel toggle, attach/detach lifecycle, mobile info sheet, and panel height management
chat_page_composer_widgets.dart                   # Reserved-height composer progress slot with in-place slide/fade updates so busy status changes do not move the timeline
chat_page_model_selector_runtime.dart        # New Chat action opens draft mode immediately via provider `beginNewChatDraft()`; child-thread selector labels are memoized and locked to sub-conversation metadata (model shown, variant shown only when explicit)
chat_page_timeline_builder.dart              # Renders empty state with no-server CTA to wizard; passes `role` to MessageEntranceAnimation so each bubble uses the correct motion profile; composer stays enabled during draft-first New Chat (`currentSession != null || isDraftingNewChat`) and in sub-conversation sessions; sub-conversation model/agent selection remains session-context aware/locked; child-thread footer keeps `Return to main conversation` visible (stop behavior managed by composer); wires latest inline undo and historical server-confirmed user-message rewind while excluding `local_user_*` optimistic IDs
chat_page_timeline_runtime.dart              # Tool-chain expanded state key resolution (sessionId::messageId::startPartId)
chat_page_search.dart                   # Timeline full-text search: inline AppBar input with 300ms debounce, case-insensitive text/reasoning matching, message-level next/previous navigation, and transient TextSpan highlighting; uses dedicated _ScrollOwner.searchResult for scroll coordination
chat_page_mobile_overflow.dart                    # Renders pinned and overflow actions for mobile app bar, including display toggles, search, and terminal panel trigger
```

### Chat message widgets

```text
lib/presentation/widgets/chat_message/chat_message_tool_part.dart   # Renders long tool outputs in a bounded internal scroll viewport; large diffs use lazy rendering so tool growth does not destabilize the outer chat timeline; task bubbles are compact, navigate to child thread via full-bubble tap, hide the task-only details row, prefer latest child-tool progress labels with command fallback while running, and show `N tool calls` when completed if child-session totals are available
lib/presentation/widgets/chat_message/chat_message_content.dart     # Message bubble layout, copy/hold layers, latest inline undo, historical inline rewind button, and read-aloud button in assistant message header (volume_up/stop icon, ListenableBuilder, markdown stripping)
lib/presentation/widgets/chat_message/chat_message_text_part.dart   # Markdown renderer with code block tap builder; detects `language=="mermaid"` and routes to MermaidDiagramWidget via onMermaidCode callback; renders standard code blocks with syntax highlighting and copy action; wires math syntaxes (InlineMathSyntax, BlockMathSyntax, SingleLineBlockMathSyntax) and builders (InlineMathBuilder, BlockMathBuilder) when showMathRendering is enabled
lib/presentation/widgets/chat_message/chat_message_part_dispatch.dart # Reorders contiguous visible `task` tool runs so unfinished task bubbles stay last within each run while non-task grouping remains unchanged
lib/presentation/utils/tool_presentation.dart                      # Shared tool label/icon formatting reused by chat bubbles and the fixed composer live-progress surface
```

### `lib/presentation/providers/chat_provider/` clusters (current)

```text
chat_provider_core.dart
chat_provider_session_ops.dart           # Implements undo/redo turn logic, guarded historical `revertToTurn`, revert boundary advancement, and composer draft restoration
chat_provider_realtime_ops.dart           # Realtime event handling; defers stale `session.idle` reconciliation until the active send stream settles so server-driven lifecycle stays authoritative across follow-up sends
chat_provider_realtime_aux_ops.dart                # Post-reconnect recovery with _postReconnectRecoveryInFlight guard; degraded mode preservation across background/foreground transitions
chat_provider_event_reducer_ops.dart             # Reconcile one-shot guard via _messageStreamGeneration; dedup key composition; reactive notification dismissal — calls `dismissForSession()` on `permission.replied`, `question.replied`, `question.rejected`, and `session.idle` (current session) + `removeNotifiedRequestIds()` to sync background alert snapshot
chat_provider_message_merge_ops.dart
chat_provider_message_state_ops.dart             # Message state mutations; auto-title scheduling guard skips subsessions
chat_provider_draft_part.dart                    # Loads/persists per-session composer drafts and manages rejected-draft envelopes; unconditional draft preservation across background transitions (removed foreground guards from _stashRejectedDraftForRetry)
chat_provider_selection_sync_ops.dart
chat_provider_selection_helpers.dart       # Selection helpers including `_restoreSelectionFromMessages()` — scans cached messages for the last non-summary AssistantMessage and restores its providerId/modelId/mode as the current selection; `_storeCurrentSessionSelectionOverride()` with `isExplicit` flag preservation
chat_provider_context_state_ops.dart        # Context-scoped override application; `_applySessionSelectionOverride()` delegates to message-derived fallback (`_restoreSelectionFromMessages()`) when no override exists, when override is stale, or when override is non-explicit (Feature 7)
chat_provider_preference_ops.dart                # Persists favorites/recent usage plus per-agent provider/model/variant memory
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
chat_input_suggestion_popover.dart             # Mention/slash/canned popover; renders file, workspace-symbol, and agent badges/icons
chat_input_attachment_controller.dart
chat_input_send_controller.dart
chat_input_speech_controller.dart
```

### Terminal Workspace

```text
lib/data/datasources/terminal_remote_datasource.dart    # Server-side PTY datasource: createPty (POST /pty), resizePty (PUT /pty/:id), deletePty (DELETE /pty/:id); directory-scoped calls to server /pty contract
lib/data/models/pty_session_model.dart                  # PTY session model (id, title, command, args, cwd, status, pid) from server createPty response
lib/presentation/services/codewalk_terminal_controller.dart   # Owns xterm Terminal state, server-side PTY lifecycle (startShell/stop), WebSocket connect/disconnect, resize debouncing, cursor tracking, process-token concurrency guards, and teardown; `supportsRemoteTerminal` gates to IO-only (!kIsWeb)
lib/presentation/services/codewalk_terminal_socket.dart         # Conditional export: abstract `CodewalkTerminalSocketConnection` interface + `openCodewalkTerminalSocket()` factory
lib/presentation/services/codewalk_terminal_socket_io.dart      # IO implementation: `dart:io` WebSocket.connect with binary frame support (List<int> output stream)
lib/presentation/services/codewalk_terminal_socket_stub.dart    # Non-IO platforms: throws UnsupportedError
lib/presentation/services/codewalk_terminal_url.dart            # WebSocket URL builder: converts HTTP(S) base URL to ws(s):// + `/pty/{ptyId}/connect` with directory and cursor query params
lib/presentation/widgets/codewalk_terminal_panel.dart           # Resizable terminal panel with reconnect/close/minimize/maximize controls, terminal-generation view rebinding, and fallback state (icon + "Try again" when not running); configures `TerminalView` with mobile `deleteDetection` for backspace input support on Android/iOS
lib/presentation/pages/chat_page/chat_page_terminal_runtime.dart # ChatPage extension for terminal toggle flow, project-scoped shell start, close/minimize/maximize actions, persisted panel height/maximize handling, and fallback info sheet when terminal is unsupported
lib/presentation/pages/chat_page/chat_page_timeline_builder.dart # Main chat workspace layout: renders terminal full-width below the constrained chat column and hides composer-adjacent controls on compact/mobile while terminal is visible
lib/domain/entities/experience_settings.dart                    # Persisted terminal visibility, height, maximize state, and read-aloud settings (readAloudEnabled, readAloudRate, readAloudPitch, readAloudVoice) inside shared experience settings
lib/presentation/providers/settings_provider.dart               # In-memory + persisted mutators for terminal visibility, height, and maximize state
```

## Data & Domain Layers

```text
lib/domain/entities/       # Core business entities (chat, provider, project, worktree, settings, server_profile.dart with tailscaleEnabled/oauthEnabled flags, and `chat_composer_draft.dart` for persisted session drafts)
lib/domain/repositories/   # Repository contracts
lib/domain/usecases/       # Use case boundaries used by providers
lib/data/models/           # API/storage models and JSON adapters
lib/data/repositories/     # Repository implementations (includes chat_repository.dart, reply_question.dart, reject_question.dart); sessionId removed from replyQuestion/rejectQuestion (ADR-023 contract compliance)
lib/data/datasources/      # Remote/local IO boundaries
lib/data/cache/            # Hybrid payload cache primitives used by AppLocalDataSource
```

## Key API/DataSource locations

```text
lib/data/datasources/app_remote_datasource.dart
  - /path, /app (fallback), /app/init (fallback), /provider, /agent, /config; scoped discovery/config calls add both directory and workspace query params; implements directory-only and unscoped retries for discovery contracts; `/agent` parsing handles multiple upstream response formats

lib/data/datasources/chat_remote_datasource.dart
  - /session, /session/{id}, /session/{id}/message, /session/{id}/shell
  - /session/status, /session/{id}/children, /session/{id}/todo, /session/{id}/diff
  - /session/{id}/abort, /session/{id}/revert, /session/{id}/unrevert, /session/{id}/init, /session/{id}/summarize
  - /event (provider-level SSE only; per-send SSE removed), /global/event
  - /permission, /permission/{requestId}/reply (legacy fallback), /session/{id}/permissions/{permissionId} (canonical, `remember: true` for `always` replies)
  - /question, /question/{requestId}/reply, /question/{requestId}/reject (replyQuestion/rejectQuestion no longer send sessionID query parameter — ADR-023 contract compliance)

lib/data/datasources/project_remote_datasource.dart
  - /project, /project/current
  - /experimental/worktree, /experimental/worktree/reset
  - /file, /file/content, /find/file, /find?pattern=, /find/symbol, /vcs
```

## Main Commands

```bash
make deps
make gen
make theme-sync
make theme-sync-check
make icons
make icons-check
make analyze
make test
make coverage
make check
dart tool/i18n/generate_arb.dart && flutter gen-l10n  # Regenerate all 14 locale ARBs and localization delegates
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
test/unit/auth/                        # OAuth auth unit tests
test/unit/auth/oauth_service_io_test.dart # OAuth IO service tests: Cloudflare Managed OAuth flow, PKCE S256 challenge/verifier generation, local callback server lifecycle, credential caching/refresh, isOAuthChallenge detection, trusted endpoint validation, cross-profile isolation
test/unit/auth/oauth_token_storage_test.dart # OAuth token storage tests: save/load/delete credential, hasValidCredential, OAuthTokenStorageException backend error handling, cross-profile key isolation
test/unit/network/dio_client_auth_test.dart # Dio auth ownership tests: setOAuthToken/clearOAuthToken interaction with Basic Auth, clearAuth clears both, header restoration on OAuth clear preserves Basic Auth
test/unit/providers/                   # ChatProvider split tests (8 files, parallelized with -j 12)
  chat_provider_init_test.dart         #   12 tests — initialization, config sync, model/agent selection
  chat_provider_sync_test.dart         #   17 tests — deferred sync, cycle, scope, overrides, variant sync
  chat_provider_messaging_test.dart    #   15 tests — sessions, sendMessage, draft restore; delta-like SWR fallback coverage
  chat_provider_realtime_test.dart     #   21 tests — title gen (main sessions only), SSE, abort, reconciliation
  chat_provider_session_ops_test.dart  #   27 tests — rename/share/fork/delete, insights, undo/redo/revertToTurn parity (regression coverage), idle
  chat_provider_project_test.dart      #   13 tests — permissions, questions, project scope, favorites; project-switch SWR behavior + draft isolation + dirty-context cache retention
  chat_provider_concurrency_test.dart  #   26 tests — render gate, multi-session, abort suppression
  chat_provider_selection_fallback_test.dart # Message-derived selection fallback tests (Feature 7): override isExplicit semantics, _restoreSelectionFromMessages() recovery paths, stale override → message fallback, non-explicit override → message fallback precedence
  chat_provider_test_support.dart      #   Shared utilities (RecordingDioClient, buildChatProvider, testModel); FakeChatRepository.getSessionsDelay
test/unit/quota/                        # Quota/rate-limit unit tests (provider groups, TTL cache validation, shell fallback, pace utility)
test/unit/services/                     # Platform and runtime service unit tests:
  codewalk_terminal_controller_test.dart #   Terminal controller: server-side PTY lifecycle, WebSocket connectivity, resize debouncing, cursor tracking
  codewalk_terminal_url_test.dart        #   WebSocket terminal URL construction
  read_aloud_service_test.dart           #   Text-to-speech service lifecycle, options (pitch/rate/voice), and message tracking
test/widget/                           # Widget tests (includes icon assertions with Symbols.*, explicit compact/mobile collapsed-copy coverage for chat message and session todo surfaces, historical rewind action coverage, desktop/mobile spacing for ChatSessionList, toolbar undo/redo, slash-command parity, terminal mobile backspace simulation, Windows printable hardware key forwarding, and Windows AltGr printable forwarding)
test/integration/                      # Integration tests; includes data-usage optimization and permission `remember` contract coverage in `opencode_server_integration_test.dart`
test/presentation/                     # Presentation-focused tests (incl. window_size_class_test.dart)
test/support/                          # Test helpers/fakes; `mock_opencode_server.dart` includes extra counters for usage optimization tracking; `pump_localized_app.dart` wraps widgets with all l10n delegates for locale-aware tests
test/contract/                         # Contract tests; `chat_event_contract_test.dart` covers 43 SSE event dispatch contract tests
tool/ci/check_analyze_budget.sh        # Analyzer issue budget gate (default: 186)
tool/ci/check_coverage.sh              # Coverage threshold gate (default: 35%)
.github/workflows/ci.yml               # CI executes analyze + tests + coverage gate; includes Go setup (actions/setup-go@v5) in quality, test_shards, and coverage jobs for Tailscale dep
```

## Internationalization (i18n)

- Comprehensive localization with 14 supported languages: English (template), Arabic, Bengali, German, Spanish, French, Hindi, Italian, Japanese, Korean, Portuguese (Brazil), Russian, Urdu, and Chinese (Simplified).
- ARB source files live in `lib/l10n/` (14 locales), with English as the template (`app_en.arb`, ~205 keys).
- Generated `AppLocalizations` classes in `lib/l10n/generated/` provide type-safe translation accessors.
- UI code uses `context.l10n.keyName` via the `L10nContext` extension (`lib/core/i18n/l10n_context.dart`).
- Context-free services (tray, background tasks, notification planning) use the stabilized `L10nBridge.current` pattern (`lib/core/i18n/l10n_bridge.dart`) for context-free access to translations.
- The locale registry (`lib/core/i18n/app_locales.dart`) defines the 14 supported locales, RTL metadata, resolution callback, and PT_BR normalization.
- `L10nBridge.current` is set at app boot and on locale change via `LocaleProvider` in `lib/main.dart`, ensuring consistent translation availability across the entire application lifecycle.
- Non-translatable invariants: OpenCode wire event types, permission keys, tool state discriminators, REST paths, config key names, and `prompt_async` contract fields.
- To add new strings: edit `tool/i18n/arb_strings.dart` (+ per-locale translation maps), run `dart tool/i18n/generate_arb.dart && flutter gen-l10n`.
- To migrate remaining hardcoded strings: follow the `context.l10n` pattern; use `tool/i18n/migrate_code_v2.dart` as reference.

## Notes

- `make android` builds an arm64 APK, uses a monotonic installable build number aligned with release versioning (so repeated local uploads replace the previous installation without making later releases look like downgrades), and sends the artifact with `~/bin/hey`; use `HEY_CAPTION` to override the upload caption.
- Android manifest declares `REQUEST_INSTALL_PACKAGES` permission and a `FileProvider` authority (`com.verseles.codewalk.fileprovider`) required for APK sideload installs via `open_filex`.
- Sensitive server credentials are persisted through `flutter_secure_storage` (v10.0.0) via `AppLocalDataSource`.
- Platform folders currently present: `android/`, `linux/`, `macos/`, `web/`, `windows/`.
- Linux keeps native STT disabled; new installs default to Parakeet while Sherpa, Moonshine, Parakeet, and SenseVoice remain explicit desktop-selectable alternatives.
- Android build targets Java 17 (`sourceCompatibility`, `targetCompatibility`, `jvmTarget`).
- featM icon migration is largely complete in `lib/presentation/**` and `test/widget/**`; one notifications settings widget still uses `Icons.*` while the rest has moved to `Symbols.*` (`material_symbols_icons`).
- Cloudflare Access OAuth now supported on Android via `flutter_appauth` (Chrome Custom Tab + manifest-verified loopback redirect) in addition to desktop (local HTTP redirect server).`
- `package:tailscale` (`third_party/tailscale/`, path dependency in `pubspec.yaml`) provides embedded userspace Tailscale networking via a Go native build hook (`hook/build.dart`). The hook skips Windows native asset registration to keep the package importable while runtime Tailscale support remains stubbed on Windows — preserving Windows release builds. Supports Android, iOS, Linux, macOS; excluded from Web/Windows platform declarations.

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
- **Permission auto-approve context** (`permission_auto_approve_runtime.dart` +
  `chat_page_lifecycle.dart`): Primes/clears `PermissionAutoApproveBackgroundContext` via
  `AndroidBackgroundAlertWorker.primePermissionAutoApproveContext()` /
  `clearPermissionAutoApproveContext()` to maintain permission continuity when app goes to
  background; controlled by `composerAutoApprovePermissions` setting; auto-drains visible
  permission requests with cooldown tracking and respects `isRespondingInteraction` guard.

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
  + connection form with URL/label/auth/AI-titles, plus a Tailscale toggle `_tailscaleEnabled` and
  Tailscale auth panel `_buildTailscaleAuthPanel()`) -> Ready (success or retry). The wizard stays
  visible through the Ready step and can persist a pending post-onboarding chat tour handoff.
- **Tailscale auth panel** (`_buildTailscaleAuthPanel()`): Renders per-state UI — `needsLogin`
  shows an authenticate button, `needsMachineAuth` shows an admin approval message, `connected`
  shows a success state. The toggle enables/disables Tailscale for the connecting server profile.
- **`ServerSetupQuickGuide`** (`servers_settings_section.dart`): Reusable stateless widget showing
  quick-start instructions and a copyable `opencode serve` command. Used by both the onboarding
  wizard and the Settings > Servers add/edit dialog.
- **Android loopback mapping**: Both the wizard and the servers section map `localhost`/`127.0.0.1`
  to `10.0.2.2` on Android emulator builds.
- **Skip persistence**: User can skip the wizard with an optional "Don't show again" checkbox,
  which calls `SettingsProvider.setSkipOnboardingWizard(true)`.

### Post-Onboarding Chat Tour

- **Purpose**: First-use showcase tour that activates after successful onboarding completion,
  guiding users through key UI elements before their first interaction.
- **Persistence**: `SettingsProvider.pendingPostOnboardingChatTour` flag controls handoff state;
  set during onboarding completion and cleared only after tour finishes or is dismissed.
- **Auto-start scheduling**: Tour auto-start is queued from settings changes and chat-route return
  (`didChangeDependencies` / `didPushNext` lifecycle) instead of being scheduled from every chat build.
- **Phases**: Two-phase tour flow (`intro` → `composer`) managed in `ChatPage` via
  `_PostOnboardingTourPhase` enum.
- **Tour targets**:
  - **Intro phase**: Drawer access (mobile), project context (sidebar), desktop sidebar menu,
    and New Chat button (`chat_page_chrome.dart`)
  - **Composer phase**: Chat input field and Send button (`chat_input_widget.dart`)
- **Implementation**: Uses `showcaseview` package with `ShowCaseWidget` wrapper in `ChatPage`;
  tour keys are `GlobalKey` instances passed to target widgets; responsive copy adapts to
  mobile/desktop layouts. Retries are run-token guarded so stale callbacks do not double-trigger
  after replay. Shared `ChatTourShowcase` widget provides MD3-compliant tooltip styling across
  all tour steps.
- **Replay action**:
  - **Primary**: Main Settings landing page includes a clearly reachable `Replay chat tour` action.
  - **Secondary**: Settings > About still offers the replay action as an alternative path.

### OpenCode Setup Debug Flow

- **Setup Debug State** (`app_provider.dart`): `SetupDebugSeverity` enum, `SetupDebugEntry` class,
  and provider state `_setupDebugEntries`, `_localSetupLogs`, `_localSetupInProgress`,
  `_localSetupMessage` capture installation/diagnostics events.
- **Recording**: `recordSetupDebugEvent()` captures events with source, message, severity, and
  timestamp; `exportSetupDebugReport()` generates a sanitized text report for clipboard sharing.
- **Navigation Entry Points**:
  - Onboarding wizard (step 1 quick-guide and step 3 local setup): "View setup debug" button
    opens `OpenCodeSetupDebugPage` via `_openSetupDebugPage()`.
  - Settings > Servers section: "Setup Debug" button in Local OpenCode Server card opens
    the debug page for troubleshooting managed local server issues.
- **Debug Page** (`opencode_setup_debug_page.dart`): Displays current status, environment
  diagnostics (OpenCode, Node.js, npm, Bun, WSL availability), timeline of setup events,
  captured logs, and manual troubleshooting tips; supports copy-to-clipboard and clear actions.

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
  - **Instant reopen restore targets**: Reopening a cached session restores to the latest revealable assistant response for settled sessions, or anchors to the bottom for active sessions.

- **Chat Entrance Animations**:
  - **Staggered Message Entrance**: Tail message entrance is coordinated via `chat_page_timeline_builder.dart` and `message_entrance_animation.dart`.
  - **In-bubble Part Entrance**: Streamed part entrance is handled in-bubble via `chat_message_widget.dart`, `chat_message_part_dispatch.dart`, and `PartEntranceAnimation`.
  - **Animation tokens**: `AppAnimations` defines userBubble (130 ms) and assistantBubble (180 ms) motion profiles.
  - **Regression Coverage**: `test/widget/chat_message_widget_test.dart` ensures stable animation behavior and part-dispatch logic.

### OpenCode Custom Agents

- `.opencode/agents/opencodeNews.md` is a repo-local agent invoked via `@opencodeNews` to analyze OpenCode release impact on CodeWalk.

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

### LaTeX Math Rendering (v1.83.0)

- **New dependency**: `flutter_math_fork ^0.7.4` — pure Dart port of KaTeX for client-side math rendering.
- **Custom markdown syntaxes** (`lib/presentation/utils/math_markdown.dart`):
  - `InlineMathSyntax` — matches `$...$` inline expressions (requires at least one LaTeX token to reject currency and shell variables).
  - `BlockMathSyntax` — matches `$$...$$` block expressions on separate lines.
  - `SingleLineBlockMathSyntax` — matches `$$...$$` on a single line.
  - `InlineMathBuilder` / `BlockMathBuilder` — `MarkdownElementBuilder` implementations that render math via `MathExpressionWidget`.
- **Math rendering widget** (`lib/presentation/widgets/math_expression_widget.dart`): Renders LaTeX via `flutter_math_fork`'s `Math.tex`; falls back to styled monospace source view on parse failure. Supports inline (`MathStyle.text`, baseline-aligned) and block (`MathStyle.display`, centered in a Card) modes.
- **Setting**: `showMathRendering` (`ExperienceSettings`) with `setShowMathRendering()` on `SettingsProvider`; defaults to `true`. Toggle UI in Appearance settings (`settings_toggle_math_rendering`).
- **Chat pipeline integration** (`chat_message_text_part.dart`): Conditionally wires math syntaxes and builders into the markdown rendering chain when `showMathRendering` is enabled.

### Session Export Service

- **`SessionExportService`** (`lib/presentation/services/session_export_service.dart`): Serializes
  a full session timeline to Markdown and JSON for local export. The Markdown export renders
  messages with role headers, text content, tool calls, and reasoning blocks. The JSON export
  omits `local_user_*` IDs from user messages to comply with ADR-023 (contract-first compatibility).
  The service is scoped to the `presentation/services/` layer and consumed directly from provider-level
  export triggers or UI actions.
