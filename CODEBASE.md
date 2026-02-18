# CodeWalk - Codebase Baseline Snapshot

> Captured: 2026-02-17
> Git baseline: `20d4fd4 release: cut v1.8.0` (main)
> Flutter: 3.41.0 (stable)

## Delta Update (2026-02-18) - STT Platform Abstraction & Runtime Engine Selection (Feat J)

- **SpeechInputService abstraction** (`lib/presentation/services/speech_input_service.dart`): Abstract interface decoupling voice input from any single STT backend. Platform implementations selected via engine preference.
- **Speech Engine Selection**: STT backend is now runtime-configurable via `ExperienceSettings.speechToTextEngine` (`native` vs `sherpa`).
- **SttSpeechInputService** (`speech_input_service_stt.dart`): Unified implementation for iOS/macOS/Web/Windows and Android (fallback) via `speech_to_text` package.
- **SherpaSpeechInputService** (`speech_input_service_sherpa_io.dart`): Offline STT via `sherpa_onnx` + `record`. It is the **default engine for Linux**, where Native STT is disabled in the UI. Available on other supported IO platforms as an optional engine. Sherpa remains optional on other supported desktop/mobile IO where enabled, but is **NOT offered on Android** due to size-optimized build policy.
- **Speech Input Interaction**: Chat input microphone has an immediate loading state (static hourglass icon, `_isStartingListening`) and a delayed start yield (~10ms) to ensure UI responsiveness during heavy initialization (`ChatInputWidget._startListening`).
- **SherpaModelManager** (`sherpa_model_manager_io.dart`): HuggingFace model download and local cache management for Kroko Sherpa ONNX models.
- **Settings: Speech to text**: New dedicated settings section for engine selection, silence timeout (2-10s), and Sherpa language/model management. Native engine is hidden/disabled for Linux.
- **Android native bridge cleanup**: Removed custom Android speech channel/backend in favor of unified `SpeechInputService` pattern with `SttSpeechInputService` (native) and `SherpaSpeechInputService` (offline) runtime selection.
- **Kroko model manifest** (`assets/sherpa_models.json`): 7 multilingual model definitions (de/en/es/fr/it/pt/tr).
- **DI registration** (`lib/core/di/injection_container.dart`): `SttSpeechInputService` and `SherpaSpeechInputService` registered as lazy singletons.
- **ChatInputWidget refactor** (`lib/presentation/widgets/chat_input_widget.dart`): Voice input engine resolved at runtime based on settings; consumes `SpeechInputService` implementations via DI.

## Delta Update (2026-02-17) - Draft Restore Lifecycle Scoping

- **Draft restore lifecycle/session scoping** (`chat_provider.dart` + `chat_page.dart`): Rejected draft stash is now bound to current session (`_rejectedDraftSessionId`) and only created while app/provider are foreground-active. Composer restore is consumed only for the active session while the UI is in error state. Includes TTL (2 minutes) to prevent stale restores after delayed returns.
- **Rejected draft clearance**: Draft stash clears on session switch or new successful send, preventing cross-session draft leakage.
- **Provider unit tests**: Added tests for foreground/background restore behavior and session-binding guards in `chat_provider_test.dart`.

## Delta Update (2026-02-17) - Chat Regression Fixes

- **Auto-follow scroll intent** (`chat_page.dart`): Auto-follow now disables only on real manual scroll intent (`userScrollDirection != idle`), not on content-size changes (new messages, collapsed/expanded bubbles). Prevents premature FAB appearance during streaming.
- **Foreground active-session refresh** (`chat_provider.dart`): `refreshActiveSessionView` now invokes `scrollToBottomCallback` after message refresh (unless compacting), ensuring scroll-to-latest when appropriate.
- **Composer draft restore on rejection** (`chat_provider.dart` + `chat_input_widget.dart`): Draft text is stashed before send and restored to composer with focus recovery when send is rejected (no provider, rate-limited, stream error). SnackBar message updated to "Failed to send message. Draft kept for retry."
- **Stale stop/send state reset** (`chat_provider.dart`): `_activeSendDraftText` cleared on session idle, abort completion, stream done; `isResponding`/`canAbort` correctly reset when `session.idle` event arrives during active stream.
- **Regression tests**: Added 3 test cases — `chat_provider_test.dart` (session.idle clears stale activity, refreshActiveSessionView scroll callback), `chat_page_test.dart` (draft restore on rejected send).

## Delta Update (2026-02-17) - Android Background Alert Fallback

- **Android background alert worker** (new `android_background_alert_worker.dart` + logic): Background polling service for Android that detects actionable events (session completion, errors, permission requests, questions) when app is in background. Uses `workmanager` for periodic (15min) + one-off task scheduling.
  - `android_background_alert_worker.dart`: Main worker entry point, Workmanager registration, task execution runner
  - `android_background_alert_logic.dart`: Planner that computes alert signals from polling state diffs, handles snapshot persistence
- **`scheduleProbe` scheduling** (`android_background_alert_worker.dart` lines 78-109): Dual-schedule strategy combining:
  - Periodic task (15min interval, `ExistingPeriodicWorkPolicy.keep`)
  - One-off probe (configurable `initialDelay`, default 1min) scheduled on app background to catch imminent events quickly
- **ChatPage background integration** (`chat_page.dart` lines 327-334): When mobile app enters background with active response and `keepMobileRealtimeForShortPeriod` enabled, schedules Android probe to run after hold duration + 1min buffer to ensure continuity
- **Baseline-first alert emission** (`android_background_alert_logic.dart` lines 198-258): First poll run (`!previous.hasHistory`) emits actionable alerts immediately for:
  - Retry/error status sessions
  - Pending permission requests
  - Pending question requests
  - Subsequent runs only emit on state transitions (busy→idle for completion, new permission/question ids)
- **New test file**: `test/unit/presentation/android_background_alert_logic_test.dart` (7 tests covering baseline emission, transition detection, notification category filtering)

## Delta Update (2026-02-16)

- **Physical keyboard detection on mobile** (`settings_page.dart`): Settings page now detects physical keyboard events via `HardwareKeyboard` handler and dynamically shows the Shortcuts section on Android/iOS when a physical keyboard is connected (desktop/web always show shortcuts, no regression).
- **Rotating tips in composer status** (`chat_page.dart`): "Receiving response..." replaced by rotating tips (10 app/productivity hints) during response reception. Tips rotate every 8 seconds with `auto_awesome` icon and lantern shimmer animation. Dynamic reasoning status retains priority over tips. Added `tip` type to `_ComposerStatusType` enum. Wrapped `_ComposerStatusLanternText` in `Flexible` to prevent overflow with longer tip text.
- **Session todo list widget** (new `session_todo_list_widget.dart`): Visual todo list showing tasks from `todowrite`/`todoread` tool calls with status icons (checkbox for completed, spinner for in-progress, blank for pending), strikethrough for completed items, and priority dots (red/primary/muted). Auto-hides 3s after all tasks complete. Supports collapsed summary line ("Task 2/6 Write API endpoints" or "Tasks 3/5 completed"). Scrollbar with auto-scroll to in-progress item when exceeding `maxVisibleItems` (5 mobile, 10 desktop). Collapse state persisted globally via `ExperienceSettings.taskListCollapsed`.
- **Todo tool call hiding** (`chat_message_widget.dart`): `todowrite` and `todoread` tool calls are filtered from conversation rendering at three levels: chain grouping exclusion, individual part skip, and empty assistant bubble suppression via `_shouldRenderPart`.
- **Display toggle menu** (`chat_page.dart`): Renamed "Message Bubbles" header to "Display". Added "Task list" toggle to show/hide the session todo widget entirely. Persisted via `ExperienceSettings.showTaskList`.
- **Foreground resume todo refresh** (`chat_provider.dart`): Added `loadSessionInsights` call in `_resumeRealtimeAfterForeground` to refresh todo list when app returns from background.
- **Desktop todo placement**: Todo widget appears in utility sidebar (max 10 items); when sidebar is hidden, falls back to inline card below session header (max 5 items, same as mobile).
- **Gradle build optimization** (`android/gradle.properties`): Added `org.gradle.caching=true` and `org.gradle.parallel=true` for faster Android builds.
- **New test files**: `test/widget/session_todo_list_widget_test.dart` (9 tests), updated `chat_message_widget_test.dart` (todo hiding), `chat_page_test.dart` (tip assertion), `settings_provider_test.dart` (task list persistence).

## Delta Update 2 (2026-02-16) - Desktop Tray & Background Behavior

- **Desktop tray service** (new `desktop_tray_service.dart` + implementations): Platform-aware desktop tray integration using `tray_manager` and `window_manager` packages. Provides system tray icon, context menu (Open/Quit), and window close-to-tray behavior.
  - `desktop_tray_service.dart`: Platform-aware factory (exports IO on desktop, stub on mobile/web)
  - `desktop_tray_service_types.dart`: Abstract `DesktopTrayService` interface
  - `desktop_tray_service_io.dart`: Desktop implementation (Linux/macOS/Windows)
  - `desktop_tray_service_stub.dart`: Non-desktop stub (mobile/web)
- **Background preference fields** (`ExperienceSettings`): Two new boolean fields:
  - `keepDesktopRunningInTray`: Keep app running in system tray on desktop when window closes (default: `true`)
  - `keepMobileRealtimeForShortPeriod`: Keep realtime active briefly on mobile after backgrounding during active response (default: `true`)
- **Chat foreground policy** (`chat_page.dart`): New `_applyForegroundPolicy()` method implementing platform-specific background behavior:
  - **Desktop**: If `keepDesktopRunningInTray` is enabled, keeps realtime active when app is in background (tray mode)
  - **Mobile**: If `keepMobileRealtimeForShortPeriod` is enabled and session is actively responding, temporarily holds realtime for a short duration before pausing (avoids persistent background service, better battery)
  - Logs policy decisions at debug level with mode indicators: `active`, `desktop-tray`, `mobile-hold`, `mobile-hold-expired`, `paused`
- **Settings UI** (`notifications_settings_section.dart`): Two new platform-specific toggles:
  - Desktop: "Close to tray" switch to hide to system tray on window close
  - Mobile: "Keep alerts live for X min" switch to keep realtime briefly after leaving app
- **New dependencies** (`pubspec.yaml`):
  - `tray_manager: ^0.5.1` - System tray integration
  - `window_manager: ^0.5.1` - Desktop window control
- **AppShellPage integration** (`app_shell_page.dart`): Initializes and configures `DesktopTrayService` based on `keepDesktopRunningInTray` setting, with listener for setting changes.

## Previous Delta (2026-02-16)

- Moved context usage knob from AppBar actions to compact session header card (alongside title), reduced knob size to 20px with 1.5px stroke for visual alignment with title text.
- Removed pencil edit button from session title inline editor; title rename now activates on single-tap (was double-tap + pencil icon).
- Changed mobile Files button icon from `folder_open_outlined` to `account_tree_outlined` for clearer tree-navigation semantics.
- Increased desktop project selector width from fixed 240px to responsive 300px (normal) / 400px (large desktop) to reduce premature ellipsis truncation.
- Updated tests for removed edit button key, relocated context control, and new Files icon.

## Previous Delta 2 (2026-02-15)

- Added keyboard shortcut system: 3 new shortcut actions (`openSettings` with default `mod+,`, `cycleRecentModels` with default `mod+m`, `cycleVariant` with default `mod+t`), global shortcut handler in ChatPage using `HardwareKeyboard`, and comma key (`,`) support in `ShortcutBindingCodec`.
- Added desktop local OpenCode setup wizard in Server Settings section (`servers_settings_section.dart`) with environment diagnostics (platform, OpenCode/Node/npm/Bun/WSL availability, network access, install directory writability), installation recommendations, and one-click install/upgrade via multiple methods.
- Added runtime installer services for local OpenCode server management: `local_opencode_server_runtime.dart` (abstract interface), `local_opencode_server_runtime_types.dart` (types/models), `local_opencode_server_runtime_io.dart` (desktop implementation), `local_opencode_server_runtime_stub.dart` (non-desktop stub). Supports install methods: download binary, npm global, bun global, bun bootstrap then install.
- Added `opencode-smoke` CI job (lines 188-251 in ci.yml) validating OpenCode CLI installation across 5 matrix combinations: ubuntu/npm, ubuntu/bun, macos/npm, macos/bun, windows/npm.
- Separated CI and Release workflows (ADR-034): CI runs on push/PR, Release triggers on version tags (`v*`) or manual dispatch. Added `make release V=patch|minor|major` target for automated version bump, commit, tag, and push.
- Hardened compaction UX: frozen pre-compaction boundary during active compaction, post-compaction `ChatState.error` reset, incomplete assistant message cleanup, and auto-scroll suppression during compaction streaming.

## Project Structure

```
codewalk/
├── android/           # Android platform (Kotlin)
│   ├── app/
│   ├── build.gradle.kts
│   ├── gradle/
│   └── settings.gradle.kts
├── assets/
│   ├── images/        # App icons and images
│   └── sherpa_models.json  # Kroko Sherpa ONNX model manifest (7 languages: de/en/es/fr/it/pt/tr)
├── lib/
│   ├── core/
│   │   ├── config/    # Feature flags and runtime rollout switches
│   │   ├── constants/ # API and app constants
│   │   ├── di/        # Dependency injection (get_it)
│   │   ├── errors/    # Exception and failure classes
│   │   ├── logging/   # Centralized logging with token sanitization
│   │   └── network/   # Dio HTTP client setup
│   ├── data/
│   │   ├── datasources/ # Remote and local data sources
│   │   ├── models/      # JSON-serializable models (.g.dart generated)
│   │   └── repositories/ # Repository implementations
│   ├── domain/
│   │   ├── entities/    # Core business entities
│   │   ├── repositories/ # Repository interfaces
│   │   └── usecases/    # Application use cases
│   ├── presentation/
│   │   ├── pages/       # App Shell, Chat, Home, Logs, Server Settings
│   │   ├── providers/   # State management (Provider, ChatProvider, SettingsProvider, etc.)
│   │   ├── services/    # UI services (ChatTitleGenerator, SoundService, EventFeedbackDispatcher, LocalOpenCodeServerRuntime, FilePartActionService, DesktopTrayService, SpeechInputService, SherpaModelManager)
│   │   ├── theme/       # App theme configuration
│   │   ├── utils/       # UI utilities (SessionTitleFormatter, FileExplorerLogic, ShortcutBindingCodec)
│   │   └── widgets/     # Chat input, message, session list, interaction cards
│   └── main.dart
├── test/
│   ├── widget_test.dart        # Original widget test
│   ├── unit/                   # Unit tests (models, providers, usecases)
│   ├── widget/                 # Widget-specific tests
│   ├── integration/            # Integration tests with mock server
│   └── support/                # Fakes and mocks
├── tool/
│   └── ci/                     # CI validation scripts
│       ├── check_analyze_budget.sh
│       └── check_coverage.sh
├── .github/
│   └── workflows/
│       └── ci.yml              # CI/CD pipeline (quality, builds)
├── linux/             # Linux desktop runner
├── macos/             # macOS desktop runner
├── web/               # Web platform
│   ├── index.html
│   └── manifest.json
├── windows/           # Windows desktop runner
├── pubspec.yaml
├── analysis_options.yaml
├── dart_test.yaml     # Test tags configuration
├── .lcovrc            # LCOV coverage configuration
├── codecov.yml        # Codecov integration config
├── CONTRIBUTING.md    # Contribution guidelines
├── QA.feat016.release-readiness.md # Feature 016 parity QA matrix and defect triage
├── RELEASE_NOTES.md   # Release signoff notes and known limitations
├── install.sh         # Unix installer script
├── install.ps1        # Windows installer script
├── uninstall.sh       # Unix uninstaller script
├── uninstall.ps1      # Windows uninstaller script
├── SECURITY.md        # Security policy and responsible disclosure
└── Makefile           # Build automation and packaging gates
```

## File Counts

| Type | Count | Notes |
|------|-------|-------|
| `.dart` (source) | 122 | Under `lib/` (excluding generated); +11 from STT platform abstraction (Feat J) |
| `.g.dart` (generated) | 4 | JSON serialization models |
| `.dart` (tests) | 27 | Test files (unit, widget, integration, support) |
| `.dart` (total) | 153 | Repository files excluding build artifacts |
| `.md` (markdown) | 21 | Docs + roadmap + release artifacts + SECURITY.md |
| `.sh` (scripts) | 2 | Unix installer/uninstaller scripts |
| `.ps1` (scripts) | 2 | Windows PowerShell installer/uninstaller scripts |

## Legacy Naming References

All runtime/build/config references to `open_mode`/`OpenMode` were renamed to `codewalk`/`CodeWalk` in Feature 003. Remaining references exist only in historical documentation files (NOTICE, ADR.md, ROADMAP files) as intentional attribution to the original project.

`easychen/openMode` is considered a legacy source and is outdated for current implementation decisions. Do not use it as a technical reference; use OpenCode official docs and the upstream OpenCode repository listed below.

## API Endpoints

Extracted from `lib/data/datasources/*.dart`. Server base URL is configurable.
Aligned with OpenCode Server Mode API (source: `ai-docs/opencode_server.md`, SDK: `anomalyco/opencode-sdk-js`).

### AppRemoteDataSource (`app_remote_datasource.dart`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/path` | Fetch runtime path info (primary app bootstrap endpoint) |
| GET | `/app` | Fetch app info (legacy fallback for older servers) |
| POST | `/app/init` | Legacy initialization fallback (`/path` is primary readiness probe) |
| GET | `/provider` | Get providers (`{all, default, connected}`) |
| GET | `/config` | Fetch config info |
| GET | `/global/health` | Server health probe used by multi-server orchestration (with `/path` fallback) |

### ChatRemoteDataSource (`chat_remote_datasource.dart`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/session` | List sessions (`directory`, `search`, `roots`, `start`, `limit`) |
| GET | `/session/{id}` | Get session details |
| POST | `/session` | Create session |
| PATCH | `/session/{id}` | Update session |
| DELETE | `/session/{id}` | Delete session |
| POST | `/session/{id}/share` | Share session |
| DELETE | `/session/{id}/share` | Unshare session |
| POST | `/session/{id}/fork` | Fork session (`{messageID?}`) |
| GET | `/session/status` | Snapshot status map for all sessions |
| GET | `/session/{id}/children` | List forked child sessions |
| GET | `/session/{id}/todo` | List session todo items |
| GET | `/session/{id}/diff` | List session diff files (`messageID?`) |
| GET | `/session/{id}/message` | List messages |
| GET | `/session/{id}/message/{messageId}` | Get specific message |
| POST | `/session/{id}/message` | Send message (streaming via SSE) |
| POST | `/session/{id}/shell` | Execute shell-mode prompt command |
| GET | `/event` | SSE event stream |
| GET | `/global/event` | Global SSE event stream (cross-context sync) |
| GET | `/permission` | List pending permission requests |
| POST | `/permission/{requestId}/reply` | Reply to permission request (`once`, `always`, `reject`) |
| GET | `/question` | List pending question requests |
| POST | `/question/{requestId}/reply` | Submit question answers |
| POST | `/question/{requestId}/reject` | Reject question request |
| POST | `/session/{id}/abort` | Abort session |
| POST | `/session/{id}/revert` | Revert message (`{messageID, partID?}`) |
| POST | `/session/{id}/unrevert` | Unrevert messages |
| POST | `/session/{id}/init` | Initialize session (`{messageID, providerID, modelID}`) |
| POST | `/session/{id}/summarize` | Summarize session (`{providerID, modelID}`) |

### ProjectRemoteDataSource (`project_remote_datasource.dart`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/project` | List all projects |
| GET | `/project/current` | Get current project |
| PATCH | `/project/{id}` | Set current project |
| GET | `/experimental/worktree` | List worktrees |
| POST | `/experimental/worktree` | Create worktree |
| DELETE | `/experimental/worktree` | Delete worktree (`id` query) |
| POST | `/experimental/worktree/reset` | Reset worktree (`id` payload) |

**Total: 41 endpoint operations used by client (including legacy fallbacks)**

### Feature 010 Parity Contract Baseline (Locked 2026-02-09)

- Upstream lock: `anomalyco/opencode@24fd8c1` (`dev`)
- OpenAPI lock: `packages/sdk/openapi.json` (82 route paths at lock time)
- Source references:
  - `ai-docs/opencode_server.md`
  - `ai-docs/opencode_models.md`
  - `ai-docs/opencode_web.md`

Reference policy:

- `easychen/openMode` is historical attribution only (non-reference).
- Canonical references for implementation are OpenCode docs + OpenCode upstream.

Compatibility tiers:

- Fully supported: servers compatible with locked v2 route/event schemas.
- Fallback compatible: legacy server-mode responses that still satisfy core bootstrap/session paths (`/path` or `/app`, `/provider`, `/project/current`, `/session`, `/session/{id}/message`, `/event`).
- Unsupported: missing core paths or incompatible payload shapes for core entities.

### Route Taxonomy (v2 Contract)

| Family | Current client | Required in parity wave (Features 011-015) | Optional post-wave |
|---|---|---|---|
| App bootstrap/config | Partial | `/path`, `/provider`, `/config`, `/project`, `/project/current` (+ `/app` fallback) | `/global/config`, `/global/dispose` |
| Core sessions/messages | Implemented | `/session`, `/session/{id}`, `/session/{id}/message`, `/session/{id}/message/{messageId}`, `/event`, `/global/event` | Extended global orchestration routes not used by mobile client |
| Session lifecycle advanced | Implemented (Feature 014) | `/session/status`, `/session/{id}/children`, `/session/{id}/fork`, `/session/{id}/todo`, `/session/{id}/diff`, plus existing share/revert/abort/init/summarize paths | `/session/{id}/command`, `/session/{id}/shell`, `/session/{id}/permissions/{permissionID}` |
| Interactive flows | Implemented (Feature 013) | `/permission`, `/permission/{requestID}/reply`, `/question`, `/question/{requestID}/reply`, `/question/{requestID}/reject` | Extended decision workflows not covered by app parity tests |
| Tooling/context | Partial | `/find/file`, `/file/*`, `/vcs`, `/mcp/*` (priority subset) + `/experimental/worktree*` | `/lsp`, `/pty*` |

### Feature 013 Realtime Architecture (2026-02-09)
Resilient SSE-based realtime event reducer for `session.*`, `message.*`, `permission.*`, `question.*` with interactive cards and fallback fetch.
📋 **Arquitetura**: Ver [ADR-012: Realtime Event Reducer](#adr-012-realtime-event-reducer-and-interactive-prompt-orchestration)
📁 **Módulos**: `chat_realtime.dart`, `watch_chat_events.dart`, interaction cards

### Feature 014 Session Lifecycle Architecture (2026-02-10)
Advanced session lifecycle operations (rename/archive/share/fork/delete) with optimistic mutations, rollback, and insight hydration (status/children/todo/diff).
📋 **Arquitetura**: Ver [ADR-013: Session Lifecycle Orchestration](#adr-013-session-lifecycle-orchestration-with-optimistic-mutations-and-insight-hydration)
📁 **Módulos**: lifecycle use cases, `session_lifecycle_model.dart`, session list action menu

### Feature 015 Project/Workspace Context Architecture (2026-02-10)
Project/workspace context orchestration with deterministic `serverId::directory` isolation, worktree lifecycle (create/reset/delete/open), and global event sync.
📋 **Arquitetura**: Ver [ADR-014: Project/Workspace Context Orchestration](#adr-014-projectworkspace-context-orchestration-with-global-event-sync)
📁 **Módulos**: `worktree.dart`, `watch_global_chat_events.dart`, `ProjectProvider`, context snapshots
🔧 **UX**: workspace creation with directory browser/Git validation, telemetry for workspace operations

### Feature 016 Reliability and Release-Readiness Architecture (2026-02-10)
Parity-wave release gate with evidence contract (automated coverage + QA matrix `PAR-001`..`PAR-008` + platform smoke + known limitations).
📋 **Arquitetura**: Ver [ADR-015: Parity Wave Release Gate](#adr-015-parity-wave-release-gate-and-qa-evidence-contract)
📁 **Artefatos**: `QA.feat016.release-readiness.md`, `RELEASE_NOTES.md`

### Feature 017 Realtime-First Refreshless Architecture (2026-02-10)
Refreshless SSE-first sync with lifecycle-aware streams (background suspend, foreground reconcile), degraded fallback (30s scoped polling), and sync state UI.
📋 **Arquitetura**: Ver [ADR-018: Refreshless Realtime Sync](#adr-018-refreshless-realtime-sync-with-lifecycle-and-degraded-fallback)
📁 **Módulos**: `feature_flags.dart` (CODEWALK_REFRESHLESS_ENABLED), sync state machine, `/config` reconcile
🔧 **UX**: removed manual refresh, sync status indicator (Connected/Reconnecting/Delayed)

### Feature 019 File Explorer and Viewer Parity (2026-02-11)
File explorer/viewer with tree navigation, quick-open search, tab management, and diff-aware refresh in Files surface (desktop pane + mobile dialog).
📋 **Arquitetura**: Ver [ADR-020: File Explorer State](#adr-020-file-explorer-state-and-context-scoped-viewer-orchestration) + [ADR-021: Files-Centered Viewer](#adr-021-responsive-dialog-sizing-standard-and-files-centered-viewer-surface)
📁 **Módulos**: `file_node.dart`, `file_explorer_logic.dart`, `session_title_formatter.dart`, presentation services
🔧 **Endpoints**: `/file`, `/find/file`, `/file/content`
🎯 **UX**: context-keyed explorer state, `N open files` dialog (responsive ~70% viewport), builtin `/open`

### Feature 018 Prompt Power Composer Architecture (2026-02-10)
Composer power triggers (`@` mentions, `!` shell mode, `/` slash commands) with inline popovers, keyboard navigation, and shell-mode routing.
📋 **Arquitetura**: Ver [ADR-019: Prompt Power Composer Triggers](#adr-019-prompt-power-composer-triggers)
📁 **Módulos**: `ChatInputWidget` state machine, contextual suggestion fetching, `/session/{id}/shell` routing
🔧 **UX**: inline suggestions (3x input height cap), mention chips, builtin slash handlers

### Feature 023 Deprecated API Migration (2026-02-11)
Flutter API modernization (color/form field/async context/web interop/markdown package) with analyzer issue reduction.
📋 **Arquitetura**: Ver [ADR-023: Deprecated API Modernization](#adr-023-deprecated-api-modernization-and-web-interop-migration)
🔧 **Migrações**: `withOpacity→withValues`, `dart:html→package:web`, `flutter_markdown→flutter_markdown_plus`

### ChatInput Schema

`POST /session/{id}/message` body:

```
{ model: { providerID, modelID }, variant?, parts: [{type, text}|{type, mime, url}], agent?, system?, tools?, messageID?, noReply? }
```

> **Note:** Current server schema expects `agent`; client domain field `mode` is mapped to `agent` at request serialization. `mode='shell'` is still reserved for shell route handling.

### MessageTokens Schema

```
{ input: int, output: int, reasoning: int, cache: { read: int, write: int } }
```

### SSE Event Taxonomy (`/event`)

| Event group | Current handling state | Parity contract classification |
|---|---|---|
| `message.created`, `message.updated`, `message.part.updated` | Handled with reducer + fallback fetch for partial payloads | Required |
| `message.removed`, `message.part.removed` | Fully handled in reducer | Required |
| `session.error`, `session.idle` | Fully handled in reducer | Required |
| `session.created`, `session.updated`, `session.deleted`, `session.status` | Fully handled in reducer | Required |
| `permission.asked`, `permission.updated`, `permission.replied` | Fully handled with pending queue sync | Required |
| `question.asked`, `question.updated`, `question.replied`, `question.rejected` | Fully handled with pending queue sync | Required |
| `todo.updated`, `session.diff` | Fully handled in reducer (session insight maps) | Required |
| `vcs.branch.updated`, `worktree.ready`, `worktree.failed` | Not handled | Required |
| Other diagnostic/low-impact events | Ignored | Optional |

### Message Part Taxonomy

| Part type | Current handling state | Parity contract classification |
|---|---|---|
| `text`, `file`, `tool`, `reasoning`, `patch` | Implemented | Required |
| `step-start`, `step-finish`, `snapshot` | Parsed; details accessible via assistant info menu | Required |
| `agent`, `subtask`, `retry`, `compaction` | Parsed + rendered as structured info blocks | Required |
| Unknown/future part types | Ignored defensively | Optional |

### API Endpoints Not Yet Implemented (Prioritized)

Required for parity wave:

- `/find/*` (except `/find/file`)
- `/mcp/*`

Deferred/optional after parity wave:

- `/global/config`
- `/global/dispose`
- `/session/:id/permissions/:id`
- `/session/:id/command`
- `/lsp`
- `/pty*`
- `/mode`
- `/log`
- `/formatter`
- `/instance/dispose`
- `/provider/auth`
- `/provider/:id/oauth/*`
- `PATCH /config`
- `/doc`
- TUI control routes

## Non-English Content (CJK)

14 files under `lib/` contain Chinese comments and/or string literals:

| Layer | File |
|-------|------|
| core | `core/constants/api_constants.dart` |
| core | `core/errors/exceptions.dart` |
| core | `core/errors/failures.dart` |
| core | `core/network/dio_client.dart` |
| data | `data/datasources/app_local_datasource.dart` |
| data | `data/datasources/app_remote_datasource.dart` |
| data | `data/datasources/chat_remote_datasource.dart` |
| data | `data/datasources/project_remote_datasource.dart` |
| data | `data/models/chat_session_model.dart` |
| data | `data/models/project_model.dart` |
| data | `data/models/provider_model.dart` |
| data | `data/repositories/app_repository_impl.dart` |
| data | `data/repositories/chat_repository_impl.dart` |
| data | `data/repositories/project_repository_impl.dart` |

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android | Present | Kotlin, full build config |
| Web | Present | PWA manifest, index.html |
| iOS | Absent | No `ios/` directory |
| Windows | Present | Runner/CMake files generated; builds only on Windows host |
| macOS | Present | Runner/Xcode files generated; builds only on macOS host |
| Linux | Present | Runner/CMake files generated; local build validated |

## Quality Baseline

### flutter analyze

- **Total issues: ~83** (28 lint rules active)
  - Errors: 0
  - Warnings: 1 (`unnecessary_non_null_assertion`)
  - Info: ~82 (mostly `unnecessary_underscores` in test parameter naming, plus a few `unawaited_futures` and `cancel_subscriptions` false positives)
- **Lint rules:** 28 rules in 3 categories (error prevention, code quality, consistency) beyond `flutter_lints` defaults
- **CI Budget:** 186 issues maximum (enforced via `tool/ci/check_analyze_budget.sh` with separate error-first detection)

### flutter test

- **Result: 283 tests, all passed** (latest full run with coverage)
- **Coverage: 35% minimum** (enforced via `tool/ci/check_coverage.sh`)
- **Test structure:**
  - Unit: providers/usecases/models with migration, server/context-scope assertions, lifecycle optimistic-rollback, and project/worktree orchestration
  - Widget: responsive shell, app shell navigation, server settings, interaction cards, and session lifecycle action menu
  - Integration: mock-server coverage for SSE reconnect + permission/question flows + lifecycle/worktree endpoints + server-switch/context isolation
- **Test tags:** `requires_server`, `hardware` (defined in dart_test.yaml)

## CI/CD and Automation

### GitHub Actions Workflows

`codewalk` uses two GitHub Actions workflows:

1. `.github/workflows/ci.yml` for continuous integration on pushes/PRs.
2. `.github/workflows/release.yml` for automated GitHub Releases on version tags (`v*`) or manual dispatch.

`ci.yml` implements a complete CI/CD validation pipeline with 5 parallel jobs:

| Job | Platform | Timeout | Description |
|-----|----------|---------|-------------|
| **quality** | ubuntu-latest | 35min | Static analysis, tests with coverage, Codecov upload |
| **build-linux** | ubuntu-latest | 25min | Linux desktop release build |
| **build-web** | ubuntu-latest | 20min | Web release build |
| **build-android** | ubuntu-latest | 30min | APK arm64-only release build with signing; optimized to ~22MB by excluding Sherpa/ONNX native libs and forcing Native STT engine |
| **opencode-smoke** | ubuntu-latest/macos-15/windows-latest | 20min | OpenCode CLI install validation (npm/bun matrix) |
| **ci-status** | ubuntu-latest | 5min | Aggregate status reporter |

`release.yml` publishes installable artifacts and a GitHub Release with parallel matrix jobs:

| Job | Platform | Timeout | Description |
|-----|----------|---------|-------------|
| **build-linux** | ubuntu-latest | 30min | Linux x64 release builds (arm64 removed: unsupported runner) |
| **build-windows** | windows-latest | 35min | Windows x64 release builds (arm64 removed: unsupported runner) |
| **build-macos** | macos-15 + macos-15-intel | 35min | macOS arm64 + x64 release builds (separate jobs) |
| **build-android** | ubuntu-latest | 35min | Android arm64 release APK |
| **create-release** | ubuntu-latest | 10min | Downloads artifacts and publishes GitHub Release |

**Release workflow notes:**
- macOS builds split into separate jobs (arm64 on `macos-15`, x64 on `macos-15-intel`) to avoid cross-compilation issues
- macOS Podfile pins CocoaPods deployment target to 11.0 to satisfy plugin minimum requirements (notably `speech_to_text`)
- Linux and Windows arm64 desktop runners removed after GitHub Actions compatibility issues (ubuntu-24.04-arm, windows-11-arm unavailable)
- All release artifact uploads use `retention-days: 2`
- Flutter SDK setup uses `subosito/flutter-action@v2` with `cache: true` and pinned version (`3.41.0`) for consistent cache hits
- Release triggered on version tags (`v*`) or manual workflow dispatch

### Quality Gates

**Static Analysis (check_analyze_budget.sh):**
- Fails immediately on any `error •` lines regardless of budget (with `::error::` GitHub Actions annotations)
- Maximum 186 info/warning issues allowed
- Parses `flutter analyze` output
- Fails build if budget exceeded

**Code Coverage (check_coverage.sh):**
- Minimum 35% line coverage required
- Filters generated files (*.g.dart, generated_plugin_registrant.dart)
- Uses LCOV with branch coverage disabled (.lcovrc)
- Integrates with Codecov (codecov.yml: project 35%, patch 30%)

**Generated Code Verification:**
- Ensures `build_runner` output is committed
- Prevents drift between generated and versioned code

### Makefile Automation

Makefile with 15 targets and TTY-aware output suppression (verbose output redirected to log in non-interactive mode, shown on failure only):

| Target | Description |
|--------|-------------|
| `help` | Show available targets (default) |
| `deps` | Install Flutter dependencies (`flutter pub get`) |
| `gen` | Run code generation (`dart run build_runner`) |
| `icons` | Regenerate app icons for all supported platforms, including Linux Freedesktop metadata |
| `icons-check` | Validate icon assets, expected dimensions, and Linux desktop entry fields |
| `analyze` | Static analysis with budget check (186 max) |
| `test` | Run all tests |
| `coverage` | Generate coverage report with threshold check (35% min) |
| `smoke` | Run integration smoke test against live OpenCode server |
| `check` | Full validation chain: deps → gen → analyze → test |
| `desktop` | Build desktop binary for current host OS |
| `android` | Build APK (arm64-only, split-per-abi) + optional Telegram upload (tdl). Picks `app-arm64-v8a-release.apk`. |
| `precommit` | Complete pre-commit validation: check + android |
| `release` | Bump version (patch/minor/major), commit, tag, and push |
| `clean` | Clean build artifacts and reinstall dependencies |

**Telegram Integration:**
- If `tdl` is available, uploads APK to VerselesBot channel
- APK renamed to `codewalk.apk` before upload
- Caption is dynamic by default (latest commit subject) and can be overridden via `TDL_CAPTION`

### Installation Scripts

| Script | Platform | Features |
|--------|----------|----------|
| `install.sh` | Linux/macOS | Arch detection, idempotent install/update/reinstall, desktop entry (Linux), app bundle (macOS), version marker persistence |
| `install.ps1` | Windows | Arch detection, PATH integration, Start Menu shortcut, version marker persistence |
| `uninstall.sh` | Linux/macOS | Complete removal: binary, symlink, desktop entry (Linux), app bundle (macOS) |
| `uninstall.ps1` | Windows | Complete removal: binary, Start Menu shortcut, PATH cleanup |

**Detalhes completos**: Ver scripts inline ou `--help` flags
**Idempotência**: todos os installers detectam fresh install vs update vs reinstall via `.version` marker

## Dependencies

### Runtime

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | SDK | Framework |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| dio | ^5.4.0 | HTTP client |
| provider | ^6.1.1 | State management |
| shared_preferences | ^2.2.2 | Local storage |
| flutter_markdown_plus | ^1.0.7 | Markdown rendering |
| flutter_highlight | ^0.7.0 | Code syntax highlighting |
| file_picker | ^10.3.10 | File picker |
| path_provider | ^2.1.5 | File system paths for attachment saving |
| speech_to_text | ^7.3.0 | Voice input dictation |
| url_launcher | ^6.2.2 | URL launcher |
| package_info_plus | ^9.0.0 | App version info |
| json_annotation | ^4.8.1 | JSON serialization annotations |
| equatable | ^2.0.5 | Value equality |
| dartz | ^0.10.1 | Functional programming (Either) |
| get_it | ^9.2.0 | Dependency injection |
| web | ^1.1.1 | Web API interop for browser notification bridge |
| dynamic_color | ^1.8.1 | Material You dynamic color schemes |
| flutter_local_notifications | ^20.0.0 | Cross-platform local notifications |
| audioplayers | ^6.5.1 | Sound playback for notification audio |
| material_symbols_icons | ^4.2906.0 | Material Symbols icon set |
| simple_icons | git (381d0cb) | Simple Icons brand icons |
| crypto | ^3.0.3 | SHA256 checksum verification for runtime installer |
| tray_manager | ^0.5.1 | Desktop system tray integration |
| window_manager | ^0.5.1 | Desktop window control (close-to-tray) |
| workmanager | ^0.9.0+3 | Android background periodic task for alerts |

### Dev

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_test | SDK | Testing framework |
| flutter_lints | ^6.0.0 | Lint rules |
| json_serializable | ^6.7.1 | JSON code generation |
| build_runner | ^2.4.7 | Code generation runner |
| flutter_launcher_icons | ^0.14.4 | App icon generation |

## Architecture

The project follows **Clean Architecture** with three layers:

1. **Domain** — entities, repository interfaces, use cases
2. **Data** — models (with JSON serialization), data sources (remote/local), repository implementations
3. **Presentation** — pages, providers (ChangeNotifier), widgets, theme

Dependency injection via `get_it`. HTTP via `dio`. State management via `provider`.

## Module Overview

### Logging System
Centralized structured logging via `AppLogger` with severity levels and token redaction.
📋 **Decisão**: Ver [ADR-005: Centralized Structured Logging](#adr-005-centralized-structured-logging)
📁 **Localização**: `lib/core/logging/app_logger.dart`

### Keyboard Shortcuts
- **ShortcutBindingCodec** (`lib/presentation/utils/shortcut_binding_codec.dart`): Parses keyboard shortcut bindings from string format (e.g., `mod+n`, `ctrl+shift+j`) to `SingleActivator`. Supports `mod` platform-aware modifier (Ctrl on desktop, Cmd on macOS), comma key (`,`), and bidirectional parsing (key event to binding string).
- **Global shortcuts in ChatPage**: Uses `HardwareKeyboard.instance.addHandler` to intercept global key events when chat screen is active. Matches against user-configured bindings from `ExperienceSettings` and invokes corresponding actions (newChat, focusInput, quickOpen, openSettings, cycleRecentModels, cycleVariant, cycleAgent, escape).
📁 **Localização**: `lib/presentation/pages/chat_page.dart` (lines 1090-1148)

### Desktop Tray Service
Platform-aware desktop system tray integration for Linux/macOS/Windows using `tray_manager` and `window_manager` packages.
📁 **Localização**: `lib/presentation/services/desktop_tray_service.dart` (platform factory), `desktop_tray_service_types.dart` (interface), `desktop_tray_service_io.dart` (desktop impl), `desktop_tray_service_stub.dart` (mobile/web stub)
🔧 **Features**: System tray icon with context menu (Open/Quit), close-to-tray behavior controlled by `ExperienceSettings.keepDesktopRunningInTray`, window show/hide/focus management
🔔 **Integration**: Initialized in `AppShellPage` based on user preference; listens for setting changes to update tray behavior dynamically

### Chat Foreground Policy
Platform-specific background behavior controlling when realtime sync stays active vs pauses.
📁 **Localização**: `lib/presentation/pages/chat_page.dart` (`_applyForegroundPolicy()` method)
🔧 **Policy modes**:
- **Desktop tray**: If `keepDesktopRunningInTray` enabled, keeps SSE realtime active when window is hidden (tray mode)
- **Mobile hold**: If `keepMobileRealtimeForShortPeriod` enabled and session is actively responding, temporarily holds realtime for short duration before pausing (battery-friendly alternative to persistent background service)
- **Paused**: Default behavior, realtime pauses when app goes to background
🎯 **UX**: Debug logging shows policy decisions with mode indicators (`active`, `desktop-tray`, `mobile-hold`, `mobile-hold-expired`, `paused`)

### Android Background Alert Worker
Android background polling service for detecting actionable events when app is not in foreground.
📁 **Localização**: `lib/presentation/services/android_background_alert_worker.dart` (main worker), `android_background_alert_logic.dart` (planning logic)
🔧 **Scheduling**: Dual strategy using `workmanager`:
  - Periodic task: 15min interval, keeps running persistently
  - One-off probe: Short delay (default 1min) scheduled on app background for quick catch-up
📡 **Polling endpoints**: `/session/status`, `/permission`, `/question`, `/session` (for titles)
🔔 **Alert categories**:
  - **Completion**: Session transitions from busy→idle (agent finished)
  - **Error**: Session enters retry state
  - **Permission**: New pending tool permission request
  - **Question**: New pending tool question request
🎯 **Baseline behavior**: First poll run emits actionable alerts immediately for existing retry status/permission/question items (no need to wait for transition). Subsequent runs emit only on state transitions.
💾 **Persistence**: Snapshot stored per-server in SharedPreferences (`codewalk.android.background.alert.snapshot.v1::<serverId>`)
🔔 **Integration**: ChatPage calls `scheduleProbe()` when mobile background with active response + hold duration + 1min buffer

### STT Platform Abstraction & Runtime Engine Selection (Feat J)
Cross-platform speech-to-text input via a unified `SpeechInputService` interface with runtime engine selection (`native` vs `sherpa`).
📁 **Localização**: `lib/presentation/services/speech_input_service*.dart`
🔧 **Implementations**:
- **SttSpeechInputService** (`speech_input_service_stt.dart`): iOS/macOS/Web/Windows/Android via `speech_to_text` package. This is the **exclusive engine for Android** (size-optimized). Native engine is hidden/disabled on Linux.
- **SherpaSpeechInputService** (`speech_input_service_sherpa_io.dart`): Offline STT via `sherpa_onnx` + `record`. It is the **default engine for Linux**, where Native STT is disabled in the UI. Sherpa remains optional on other supported desktop/mobile IO, but is **NOT offered on Android**.
- **Speech Input Interaction**: Chat input microphone has an immediate loading state (static hourglass icon, `_isStartingListening`) and a delayed start yield (~10ms) to ensure UI responsiveness during heavy initialization (`ChatInputWidget._startListening`).
📦 **Model management**: `SherpaModelManager` (`sherpa_model_manager_io.dart`) downloads and caches Kroko ONNX models from HuggingFace
🗂️ **Model manifest**: `assets/sherpa_models.json` — 7 multilingual Kroko model definitions (de/en/es/fr/it/pt/tr)
🔌 **DI**: `SttSpeechInputService` and `SherpaSpeechInputService` registered in `injection_container.dart`; `ChatInputWidget` resolves engine from settings and consumes it via DI
⚙️ **Settings**: Engine selection, silence timeout, and language/model management in dedicated settings section. Native engine is hidden/disabled on Linux.

### Authentication and Server Config
- Multi-server profile management (`ServerProfile`) with active/default selection
- Per-server basic auth configuration and URL normalization
- Health-aware activation (`/global/health`, fallback `/path`)
- Legacy migration creates a profile only when legacy server/auth keys exist; clean installs now keep an empty server list until the user adds one

### Session Module
Session lifecycle orchestration with server/directory-scoped cache isolation, optimistic mutations (create/delete/rename/archive/share/fork), auto-title generation via ch.at API, and insight hydration (status/children/todo/diff).
📋 **Arquitetura**: Ver [ADR-013: Session Lifecycle Orchestration](#adr-013-session-lifecycle-orchestration-with-optimistic-mutations-and-insight-hydration) + [ADR-025: Auto Session Titles](#adr-025-automatic-session-title-generation-via-chat-api)
🔧 **Features**: SWR cache, title formatter, search/filter/sort, rollback on failure
🎯 **Auto-titles**: per-server privacy toggle, platform-aware word limits (4 mobile/6 desktop), consolidation guard

### Chat Module
SSE-first realtime sync with event reducer, composer power triggers (@/!/), multimodal input (image/PDF/voice), file explorer/viewer parity, context compaction UX, and stop/abort flow.
📋 **Arquiteturas principais**:
  - [ADR-012: Realtime Event Reducer](#adr-012-realtime-event-reducer-and-interactive-prompt-orchestration)
  - [ADR-016: Chat-First Navigation](#adr-016-chat-first-navigation-architecture)
  - [ADR-017: Multimodal Input](#adr-017-composer-multimodal-input-pipeline)
  - [ADR-018: Refreshless Sync](#adr-018-refreshless-realtime-sync-with-lifecycle-and-degraded-fallback)
  - [ADR-019: Prompt Power Composer](#adr-019-prompt-power-composer-triggers)
  - [ADR-024: Stop/Abort Flow](#adr-024-desktop-composerpane-interaction-and-active-response-abort-semantics)
🔧 **Componentes**: `ChatProvider` (reducer + optimistic updates), tool diff rendering, thinking/output collapse
🎯 **UX**: responsive shell, chat-first navigation, desktop shortcuts (Enter/Shift+Enter), global keyboard shortcuts for chat navigation (newChat/focusInput/quickOpen/settings/model cycling), mobile auto-scroll, collapsible panes

### Settings Module
Modular settings hub with responsive navigation (mobile list-to-detail, desktop split layout), notification/sound/shortcut preferences, and server management.
📋 **Arquitetura**: Ver [ADR-022: Modular Settings Hub](#adr-022-modular-settings-hub-and-experience-preference-orchestration)
🔧 **Componentes**: `SettingsPage`, `SettingsProvider`, `ExperienceSettings`
🔔 **Features**: per-category notifications/sounds (agent/permissions/errors), Speech to text (engine selection, 2-10s silence timeout, Sherpa model management on Linux/supported IO, Native engine disabled on Linux, **Android restricted to Native engine**), 11 shortcut bindings (desktop/web): newChat/mod+n, refresh/mod+r, focusInput/mod+l, quickOpen/mod+p, openSettings/mod+,, cycleRecentModels/mod+m, cycleVariant/mod+t, cycleAgentForward/mod+j, cycleAgentBackward/mod+shift+j, escape, desktop pane visibility, server config sync (`/config`)
📱 **Background preferences**: `keepDesktopRunningInTray` (desktop close-to-tray), `keepMobileRealtimeForShortPeriod` (mobile temporary hold during active response)
📱 **Adapters**: `flutter_local_notifications` (Android/Linux/macOS/Windows), browser Notification API (Web)

## Chat System Details

### Core Entities
- `ChatMessage`: supports user and assistant messages with typed parts (`TextPart`, `FilePart`, `ToolPart`, `ReasoningPart`, `PatchPart`, `AgentPart`, `StepStartPart`, `StepFinishPart`, `SnapshotPart`, `SubtaskPart`, `RetryPart`, `CompactionPart`)
- `ChatSession`: session identity, parent/directory linkage, archive/share metadata, optional summary and path info
- `SessionTodo` / `SessionDiff`: session insight entities used by lifecycle panel and reducer updates
- `MessageTokens`: includes `input`, `output`, `reasoning`, `cacheRead`, `cacheWrite`
- `ProvidersResponse`: includes `providers`, `defaultModels`, `connected`
- `Model`: includes optional `variants` metadata used for reasoning-effort controls
- `ChatEvent`: typed realtime event wrapper with session status and interactive request payloads

### Streaming Flow
- Uses SSE events (`/event`) for incremental message updates
- Uses `/global/event` for cross-context invalidation signals
- Send flow forwards active `directory` scope to `/event` and message fallback fetch
- `ChatRemoteDataSource.subscribeEvents()` maintains reconnect/backoff loop
- `ChatProvider` applies reducer transitions per event type
- Client merges event deltas with full message fetch when needed
- Send path records release-visible lifecycle logs (`info`/`warn`) for stream connect/fallback/poll completion diagnostics in `LogsPage`
- Send path includes watchdog polling fallback when stream is connected but no per-message events are emitted
- Provider startup guards cancel stale realtime subscriptions to avoid duplicate `/event` streams
- Subscription teardown uses bounded timeout to avoid server-switch deadlocks
- Standard prompt sends omit `messageID`; that field is reserved for explicit message-targeted workflows
- Provider send setup is wrapped with stage logs and non-blocking selection persistence so local storage issues cannot prevent network send dispatch
- Selection sync is config-backed across devices: `/config.model`, `/config.default_agent`, and app-scoped variant map at `/config.agent.<agent>.options.codewalk.variantByModel`
- Realtime reconcile applies remote selection while app is open (sync health tick, `server.connected`, foreground resume, degraded sync pass)
- Reconcile tick for model/agent/variant runs in foreground even when refreshless fallback logic is disabled, so select sync does not depend on sending a new message
- Select changes during active response are queued for remote sync and flushed on idle to avoid unintended abort/regression while preserving cross-device convergence
- Session-level override persistence is applied on session switch (`conversation > context/project local`) so each conversation keeps its own select trio across runtime and restart
- Session override state is persisted locally per `serverId + scopeId` and mirrored remotely at `/config.agent.__codewalk.options.codewalk.sessionSelections`
- Remote session override merges use per-session `updatedAt` timestamp precedence to reduce cross-device clobbering
- Recent-model preference restoration keeps mutable lists for model-usage updates, avoiding fixed-length list mutation crashes during send setup
- Handles transient errors and stale subscription generation guards

## Test Infrastructure

### Test Organization

```
test/
├── widget_test.dart                          # Original ChatInputWidget test (12 tests)
├── unit/
│   ├── models/
│   │   ├── chat_message_model_test.dart      # Message model serialization
│   │   ├── chat_session_model_test.dart      # Session model serialization
│   │   └── provider_model_test.dart          # Provider model serialization
│   ├── providers/
│   │   ├── app_provider_test.dart            # AppProvider state management + migration/health/switch rules
│   │   ├── chat_provider_test.dart           # ChatProvider state + server/context-scoped cache behavior
│   │   ├── project_provider_test.dart        # ProjectProvider context/worktree orchestration
│   │   └── settings_provider_test.dart       # Experience settings persistence + shortcut conflict logic
│   │   ├── utils/
│   │   │   └── file_explorer_logic_test.dart     # Quick-open ranking and file-tab reducer behavior
│   │   └── presentation/
│   │       └── android_background_alert_logic_test.dart # Background alert planner baseline/transition logic
│   └── usecases/
│       └── chat_usecases_test.dart           # ChatUseCases domain logic
├── widget/
│   ├── chat_page_test.dart                   # ChatPage responsive shell
│   ├── app_shell_page_test.dart              # Chat-first shell and sidebar Logs/Settings back-navigation flow
│   ├── chat_session_list_test.dart           # Session lifecycle menu actions (rename/share/archive/delete)
│   ├── interaction_cards_test.dart           # Permission/question UI action dispatch
│   ├── server_settings_page_test.dart        # Servers section rendering and unhealthy-switch guard through Settings route
│   └── settings_page_test.dart               # Modular Settings sections navigation and rendering
├── integration/
│   └── opencode_server_integration_test.dart # Mock server SSE/global-event flow + interaction/lifecycle/worktree endpoints + server-switch cache isolation
└── support/
    ├── fakes.dart                             # Fake implementations for testing
    └── mock_opencode_server.dart              # Shelf-based mock OpenCode API server
```

### Test Support Infrastructure

**mock_opencode_server.dart:**
- In-process `dart:io` HTTP server emulating OpenCode API
- Supports `/session`, `/session/{id}/message` endpoints
- Supports advanced lifecycle routes (`/session/status`, `/children`, `/todo`, `/diff`, `/fork`, `/share`, `PATCH /session/{id}`)
- Supports `/permission*` and `/question*` interaction endpoints
- Supports `/global/health` for server-health orchestration tests
- Supports `/global/event` and `/experimental/worktree*` routes for context/workspace parity tests
- SSE event stream simulation for real-time updates and reconnect scenarios
- Controllable error injection for fault testing
- Captures outbound send payload for integration assertions (`variant`, etc.)

**fakes.dart:**
- `FakeAppLocalDataSource`: In-memory SharedPreferences simulation
- `FakeAppRemoteDataSource`: Hardcoded app/path/provider responses
- `FakeChatRemoteDataSource`: In-memory session/message management
- `FakeProjectRemoteDataSource`: Static project list
- Used for isolated unit testing without network dependencies

**tool/qa/smoke_test.sh (integration smoke):**
- Permanent integration test suite for validating OpenCode server compatibility
- Default test server (shared): `http://100.68.105.54:4096`
- API reference (complete JSON): `http://100.68.105.54:4096/doc`
- Configurable via arguments and environment variables (provider, model, variant, server URL)
- Verifies critical endpoints: `/provider`, `/session`, `/event`, and message flow (two sequential turns)
- Tests complete session lifecycle: create → send → poll → verify → delete
- Uses preferred defaults (`openai` + `gpt-5.1-codex-mini`, variant `low`) with automatic fallback
- Generates detailed test artifacts in `/tmp/codewalk_smoke/` with pass/fail report
- Usage: `./tool/qa/smoke_test.sh [BASE_URL] [OUT_DIR]`
- Non-destructive by design; safe to run against shared verification servers

### Test Tags (dart_test.yaml)

- `requires_server`: Tests needing live OpenCode server connection
- `hardware`: Tests depending on specific device/platform features

Run specific tags: `flutter test --tags requires_server`

### Coverage Configuration

**.lcovrc:**
```ini
lcov_branch_coverage=0  # Disable branch coverage, focus on line coverage
```

**codecov.yml:**
- Project coverage target: 35% (±3% threshold)
- Patch coverage target: 30% (±10% threshold)
- Ignores: test/**, *.g.dart, generated_plugin_registrant.dart, lib/l10n/**

**Current coverage:** 65.11% in latest local CI-equivalent run (`7693/11816`), with 35% minimum enforced by CI

## Contribution Standards (CONTRIBUTING.md)

### Workflow
1. Create feature branch from `main`
2. Run `make check` locally before committing
3. Submit PR with descriptive title and body
4. All CI checks must pass (quality, builds)

### Commit Convention
- Follow Conventional Commits specification
- Format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- Examples:
  - `feat(chat): add message retry on network error`
  - `fix(provider): prevent null state on load failure`
  - `docs(readme): update installation instructions`

### Coding Guidelines
- **Use `AppLogger`** instead of `print()` for all logging
- **No direct print() calls** in production code (deprecated)
- Run `make precommit` before every commit
- Ensure generated code (*.g.dart) is committed after changes
- Follow Clean Architecture layer separation
- Write tests for new features and bug fixes

### Quality Requirements
- Static analysis: max 186 issues (enforced by CI)
- Test coverage: minimum 35% (enforced by CI)
- All tests must pass
- Generated code must be up-to-date

### Issue Reporting
- Use descriptive titles
- Include reproduction steps for bugs
- Provide environment details (Flutter version, platform, device)
- Attach logs with sanitized credentials

## Version and Release

**Current version:** `1.8.0+16` (defined in pubspec.yaml)
- Version format: `MAJOR.MINOR.PATCH+BUILD`
- Android: versionName = 1.8.0, versionCode = 16
- Build artifacts uploaded via CI on successful builds
- Release artifacts published via automated GitHub Release workflow on version tags

**Release artifacts:**
- Linux: tarball with binary
- Web: static site bundle
- Android: signed APK (arm64-v8a)

**Release documentation:**
- `RELEASE_NOTES.md` tracks parity-wave release signoff and known limitations.
- `QA.feat016.release-readiness.md` records executed QA matrix evidence.

## Configuration Files Summary

| File | Purpose |
|------|---------|
| `analysis_options.yaml` | Flutter/Dart linter configuration (28 rules in 3 categories) |
| `dart_test.yaml` | Test tags (requires_server, hardware) |
| `.lcovrc` | LCOV coverage options (branch coverage disabled) |
| `codecov.yml` | Codecov integration (35% project, 30% patch) |
| `pubspec.yaml` | Dependency and version management |
| `Makefile` | Build automation (15 targets, TTY-aware output suppression) |
| `.github/workflows/ci.yml` | CI/CD pipeline (5 jobs) |
| `.github/workflows/release.yml` | GitHub Release automation (5 jobs: Linux/Windows/macOS/Android builds + release creation) |
| `CONTRIBUTING.md` | Contribution guidelines and standards |
| `QA.feat016.release-readiness.md` | Feature 016 QA matrix, platform smoke, and defect triage |
| `RELEASE_NOTES.md` | Release signoff checklist and known limitations |
| `SECURITY.md` | Security policy and responsible disclosure guidelines |

## Recent Changes Since Previous Baseline

**Feature 009 (commits 5125edd, da2940b, cc5c78f):**
- Added comprehensive test suite (27 tests: unit, widget, integration)
- Implemented CI/CD pipeline with GitHub Actions
- Created quality gates (analyze budget 186, coverage 35%)
- Added centralized logging system (AppLogger)
- Expanded Makefile from 8 to 67 lines
- Created cross-platform installation scripts
- Added CONTRIBUTING.md with coding standards
- Reduced static analysis issues from 178 to 136

**Infrastructure improvements:**
- Mock OpenCode server for integration testing
- Fake data sources for isolated unit tests
- Coverage reporting with Codecov integration
- Automated APK builds with Telegram upload and dynamic caption defaults
- Generated code verification in CI

**Quality metrics evolution:**
- Tests: 1 → 27 (+2600%)
- Analyze issues: 178 → 136 (-24%)
- Coverage enforcement: none → 35% minimum
- CI jobs: none → 5 parallel jobs

**Feature 011 (completed):**
- Added multi-server persistence model with legacy migration from `server_host`/`server_port`.
- Added active/default server orchestration with health checks and safe-switch constraints.
- Refactored local persistence and chat provider state to server-scoped keys.
- Added server manager UX and app-bar quick switcher.
- Expanded tests for migration/switching/isolation and raised total passing tests to 35.

**Feature 012 (completed):**
- Replaced split provider/model controls with a single searchable model selector grouped by provider (bottom sheet), while keeping server-scoped selection persistence.
- Added selector UX refinements: provider groups are alphabetically ordered and up to 3 recent models are surfaced first on open; reasoning effort uses a separate anchored quick selector.
- Added typed model-variant parsing from `/provider` and variant-cycle UX for reasoning effort.
- Added `variant` serialization in outbound chat payloads for parity with OpenCode v2 prompt schema.
- Added server-scoped recent/frequent model usage tracking and restoration across launches.
- Expanded unit/widget/integration coverage for variant parsing, cycling, persistence, and payload assertions (40 tests passing).

**Feature 013 (completed):**
- Added resilient realtime reducer architecture for `session.*`, `message.*`, `permission.*`, `question.*`.
- Added interactive permission/question flows and message fallback fetch for partial event payloads.
- Hardened send-path diagnostics, directory-forwarding for stream/message fetch, and watchdog fallback for stalled event flows.

**Feature 014 (completed):**
- Added advanced session lifecycle operations (rename/archive/share/unshare/fork/delete) with optimistic updates + rollback.
- Added session insight hydration (`status`, `children`, `todo`, `diff`) and richer session list controls (search/filter/sort/load-more).

**Feature 015 (completed):**
- Added project/workspace context orchestration with deterministic `serverId::directory` snapshot isolation.
- Added worktree operations (`create/reset/delete/open`) and current-project switching via `/project` + `/experimental/worktree*`.
- Added explicit base-directory input when creating workspaces to avoid implicit folder targeting.
- Added dynamic directory picker and Git preflight validation to reduce create-workspace 400 errors on non-git paths.
- Added explicit git-only guidance in the picker and stronger auto-open behavior for newly created workspace contexts.
- Added explicit app-log telemetry for workspace lifecycle operations to improve production debugging from mobile.
- Added `/global/event` subscription for cross-context invalidation and resilient subscription teardown during server switches.
- Expanded tests for project/worktree/global-event/context isolation and raised total passing tests to 66.

**Feature 016 (completed):**
- Expanded parity regression coverage across unit/widget/integration suites (including server-scoped model restore and reject-question flows).
- Executed QA matrix `PAR-001..PAR-008` with artifacts in `/tmp/codewalk_feat016/20260210_022919`.
- Added release-readiness report (`QA.feat016.release-readiness.md`) and release notes (`RELEASE_NOTES.md`).
- Validated final release gates via `make precommit` and CI-equivalent local checks (coverage + Linux/Web builds), with logs in `/tmp/codewalk_feat016_gate/20260210_024416_precommit` and `/tmp/codewalk_feat016_gate/20260210_024255_ci`.
- Documented one reproducible host-environment limitation (Android emulator startup `-6`) with mitigation via build/artifact validation and APK upload path.
- Added post-release chat composer attachment flow (image/PDF), including model-capability-based button visibility and payload parity for `file` parts (`mime` + `url`).
- Refined post-release attachment UX so image/PDF options are filtered independently by model input modalities instead of relying only on generic attachment support.
- Added post-release voice input support with `speech_to_text`, including microphone button UX in the composer and Android manifest updates for speech recognition availability.
- Refined microphone UX feedback so the button switches to a red visual state while voice capture is actively listening.
- Added post-release secondary send-button behavior: hold for 300ms inserts newline and shows a corner indicator icon for this non-send action.
- Restored staged assistant progress feedback in chat list using provider realtime state (`ChatState.sending`, `session.status`, and in-progress `AssistantMessage` parts) to render `Thinking...`, `Receiving response...`, and `Retrying model request...` indicators until completion.
- Removed inline `Step started`/`Step finished` render blocks from assistant message body and exposed their details through the assistant header info menu (`Icons.info_outline`) to reduce visual noise.
- Enabled selectable message content for both assistant and user messages via a shared `SelectionArea`, removed inline `Copy` buttons, changed full-message copy to trigger only from double-tap/double-click on bubble background (text double-click keeps native word selection), and disabled in-app copy snackbar on Android in favor of native clipboard feedback.
- Updated top bar project-context selector visual hierarchy: removed rounded border container and moved the selector from right-side actions to the left-aligned app-bar title slot.
- Reworked project selector interaction into an adaptive dialog (`Dialog.fullscreen` on compact screens, centered `Dialog` on larger layouts) with top-level persistent actions and list-item close controls beside each project entry.

**Feature 021 (completed):**
- Added a shared session-title formatting contract (`SessionTitleFormatter`) to unify explicit title/fallback rendering across list and active-session surfaces.
- Replaced ambiguous relative-only fallback titles with relative + absolute date format (e.g. `Today HH:mm (M/D/YYYY)`), and reused the same strategy when creating new sessions.
- Added inline rename UX in active conversation headers (mobile + desktop) with single-tap activation, keyboard support (`Enter` save, `Esc` cancel), save/loading feedback, and inline validation/error state.
- Hardened rename synchronization in `ChatProvider`: no-op rename now succeeds without error noise, optimistic rename tracks pending local intent, stale/conflicting `session.updated` events are ignored while rename is pending, and rollback remains intact on API failure.
- Expanded tests with new unit/widget coverage for formatter behavior, inline editor interactions, header fallback rendering, inline rename flow, and pending-rename conflict handling in provider realtime events.
- Validation executed: targeted feature test matrix (`flutter test` on formatter/editor/provider/chat_page), full regression suite (`flutter test`), and static analysis (`flutter analyze --no-fatal-infos --no-fatal-warnings`).

**Feature 022 (completed):**
- Added modular settings hub with responsive navigation (mobile list-to-detail, desktop split layout).
- Implemented `SettingsProvider` and `ExperienceSettings` entity for notification/sound/shortcut/pane preferences.
- Added per-category notification controls (`agent`, `permissions`, `errors`) with server config sync when available.
- Added per-category sound preferences with preview, generated WAV tone playback, and split `Notify`/`Sound` toggles.
- Added searchable shortcut bindings with conflict validation, reset, and persistence (desktop/web only).
- Added desktop pane visibility preferences for collapsible sidebar state persistence.
- Integrated deep-link notification payload with `sessionId` for tap-to-session navigation.

**Feature 023 (completed):**
- Migrated deprecated Flutter color APIs across app UI (`withOpacity` -> `withValues`, `surfaceVariant` -> `surfaceContainerHighest`, `background` -> `surface`, `onBackground` -> `onSurface`).
- Migrated deprecated form-field initialization API in settings (`DropdownButtonFormField.value` -> `initialValue`).
- Fixed asynchronous `BuildContext` usage hotspots in `ChatPage` (`use_build_context_synchronously`).
- Reworked web notification bridge from deprecated `dart:html` to `package:web` + JS interop and removed window-focus compile error path.
- Replaced deprecated markdown package (`flutter_markdown`) with `flutter_markdown_plus`.
- Validation executed: `flutter analyze` (targeted issues removed), full tests (`make test`), and Android build/upload (`make android`).

**Backlog UX batch (completed, 2026-02-11):**
- Desktop composer shortcut behavior now sends on `Enter` and inserts newline on `Shift+Enter` without breaking mention/slash popover keyboard flows.
- On mobile, composer submit now uses keyboard `send` action and automatically hides keyboard focus after a successful send to maximize visible message area.
- Desktop sidebars (`Conversations`, `Files`, `Utility`) now support user-driven collapse/restore with persisted visibility via `ExperienceSettings.desktopPanes`.
- Composer input remains editable while assistant response is in progress; send stays blocked until completion.
- **Stop/abort flow (`AbortChatSession` use case):**
  - Send action switches to `Stop` while response is active and triggers `/session/{id}/abort` through `ChatProvider`.
  - Stop/abort suppresses expected cancelation errors from realtime/session stream, preventing full-screen `Retry` fallback when user intentionally interrupted response.
  - Post-stop send-path stability: provider keeps message list mutable after abort completion and ignores stale send-stream callbacks via generation guards, preventing transient `Failed to start message send` / `retry` fallback when sending immediately after `Stop`.
- Project context dialog now exposes archive action for closed project entries (local curation), independent of `worktree` APIs.
- `ProjectProvider` now persists archived closed-project IDs per server and filters them from the "Closed projects" section while keeping normal reopen/switch flows for active contexts.
- Expanded automated coverage for desktop shortcut send/newline behavior, persisted sidebar visibility toggles, stop/abort success path, and stop failure snackbar fallback.

**Context compaction restoration (2026-02-13, commit 98cf446):**
- Restored context compaction UX with dedicated `SummarizeChatSession` use case wired to `/session/{id}/summarize`.
- Knob control in compact session header card displays usage percentage inside circle (mirrors OpenCode usage semantics).
- Popover shows detailed metrics: usage %, tokens, cost, and context limit.
- Manual `Compact now` action available with collapse icon for explicit context summarization.
- Integrated with current provider/model selection for summarization request.
- Compaction boundary freeze: during active compaction the pre-compaction boundary is frozen by message ID so the timeline does not collapse prematurely while the summary streams in; the new boundary only takes effect after `isCompactingContext` returns to `false`.
- Post-compaction state cleanup: `ChatState.error` set by SSE events during the async compaction window is reset to `loaded` on success, and incomplete assistant messages are marked completed to prevent stale in-progress guards.
- Auto-scroll suppression: `_scrollToBottomCallback` is skipped on `message.part.updated` and `_updateOrAddMessage` while compacting to avoid visual scroll jumps from rapid part streaming.

**Tool diff rendering hardening (2026-02-13, commits b6f8d7f..082ea92):**
- `ToolState` parsing now normalizes non-string `output` payloads (map/list/scalar) into displayable text and extracts common diff keys (`diff`, `patch`, `unified_diff`).
- Tool output UI now falls back to structured tool `input` when `output` is empty, including direct `patch/diff` extraction for `apply_patch`.
- `edit` tool calls with `old_string`/`new_string` now generate a synthetic unified diff when upstream does not return textual output.
- Tool call status chip is now responsive: desktop keeps icon + text (`Completed`, `Running`, etc.), while compact/mobile layouts render icon-only status at the right edge.
- Chat session header compact control now mirrors OpenCode usage semantics as a single knob (percentage rendered inside the circle) with popover metrics (usage %, tokens, cost, limit), retaining manual `Compact now` action with collapse icon.
- Added regression coverage for parser normalization and input-fallback diff rendering in widget/unit tests.
- Fixed missing `color` field in Agent entity and model (commit 63d6155).
- Added colorized diff rendering in tool outputs with accessible text scaling (commit 52c6e8b).
- Consolidated feature roadmaps and improved diff text scaling accessibility (commit 082ea92).

**Auto-generated session titles via ch.at API (2026-02-12, commit 8c49591):**
- Integrated `ChatAtTitleGenerator` for automatic session title generation using first 3 user + 3 assistant text messages
- Per-server privacy toggle `Enable AI generated titles` (default off) in Settings > Servers
- Platform-aware word limits: 4 words on mobile, 6 on desktop
- Background generation with consolidation guard and stale-guard to prevent overwrites on context switches
- Expanded provider/widget/integration test coverage

**Desktop/mobile UX improvements batch (2026-02-11..2026-02-13):**
- Collapsed thinking blocks: latest block stays expanded, older blocks auto-collapse
- Collapsed tool outputs: initial 2-line display with expand affordance
- Hold-to-reuse send button: 300ms hold inserts newline with corner indicator
- Desktop pane collapse: user-driven sidebar visibility with persistence
- Server status relocated from chat header to sidebar with health badge
- Simplified title bar and session header layouts
- Tightened mobile header spacing and removed composer divider
- Stabilized composer button size and input bubble clipping
- Refreshed composer surface tone and hint contrast
- Increased hamburger menu alert grace period to 10s
- IM-style auto-scroll behavior finalization
- Provider/file icon mapping finalized with `simple_icons` integration

**Release infrastructure enhancements (2026-02-13, commits dcfc792..711f019):**
- Automated GitHub Release publication workflow (`release.yml`)
- Per-architecture parallel desktop builds (Linux x64, Windows x64, macOS arm64/x64)
- macOS deployment target enforcement (11.0) in Podfile for plugin compatibility
- Unified icon pipeline across all platforms with validation gate
- Installer scripts with update/reinstall detection and uninstall support
- Flutter SDK version pinned to 3.41.0 in release workflow for cache consistency
