# Code map of CodeWalk

## Project Snapshot

- Flutter client for OpenCode-compatible servers.
- Architecture follows `presentation -> domain -> data` with `get_it` + `provider`.
- Multi-platform targets in repo: Android, Linux, macOS, Windows, Web.
- Chat stack is decomposed into orchestrators plus focused cluster modules.

## Folder Structure

```text
codewalk/
├── lib/                                # Application source
│   ├── main.dart                       # App bootstrap (DI, providers, shell)
│   ├── core/                           # Config, constants, DI, errors, logging, network
│   ├── data/                           # Data layer: datasources, models, repositories
│   ├── domain/                         # Domain layer: entities, repository contracts, use cases
│   └── presentation/                   # UI, state providers, runtime services
│       ├── pages/                      # App pages and page-level orchestration
│       │   ├── app_shell_page.dart
│       │   ├── chat_page.dart          # Chat orchestrator/facade
│       │   └── chat_page/              # ChatPage decomposed clusters (18 modules)
│       ├── providers/                  # App/Chat/Project/Settings state orchestration
│       │   ├── chat_provider.dart      # Chat provider orchestrator/facade
│       │   └── chat_provider/          # ChatProvider decomposed clusters (15 modules)
│       ├── widgets/
│       │   ├── chat_input_widget.dart  # Chat input orchestrator/facade
│       │   └── chat_input/             # ChatInput decomposed clusters (8 modules)
│       ├── services/                   # Platform/runtime services (tray, notifications, STT, etc.)
│       ├── utils/                      # Presentation helpers
│       └── theme/                      # Material theme and style configuration
├── test/                               # Unit, widget, integration, presentation, support tests
├── tool/ci/                            # Analyzer budget and coverage gate scripts
├── .github/workflows/                  # CI and release workflows
├── android/ linux/ macos/ web/ windows/ # Platform runners/build configs
└── Makefile                            # Main development and validation commands
```

## Entry Points

```text
lib/main.dart                                # Runtime entry; initializes bindings, DI, providers
lib/presentation/pages/app_shell_page.dart   # Root shell; mounts ChatPage and desktop tray behavior
lib/presentation/pages/chat_page.dart         # Main chat/session/file UI entry
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
lib/data/datasources/app_local_datasource.dart    # Persistent settings, profiles, cache, and credentials
lib/data/repositories/*.dart                      # Domain repository implementations
lib/domain/usecases/*.dart                        # Application use cases consumed by providers
lib/presentation/providers/app_provider.dart      # Server profiles, health polling, local runtime state
lib/presentation/providers/project_provider.dart  # Project/worktree context selection and persistence
lib/presentation/providers/settings_provider.dart # Experience settings, sounds, and update checks
lib/presentation/providers/chat_provider.dart     # Chat state/realtime/session orchestration facade
lib/presentation/pages/chat_page.dart             # Chat UI orchestration facade
lib/presentation/widgets/chat_input_widget.dart   # Composer/input orchestration facade
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
chat_page_selector_flow.dart
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
test/widget/                           # Widget tests
test/integration/                      # Integration tests
test/presentation/                     # Presentation-focused tests
test/support/                          # Test helpers/fakes
tool/ci/check_analyze_budget.sh        # Analyzer issue budget gate (default: 186)
tool/ci/check_coverage.sh              # Coverage threshold gate (default: 35%)
.github/workflows/ci.yml               # CI executes analyze + tests + coverage gate
```

## Notes

- `make android` builds an arm64 APK and sends the artifact with `~/bin/hey`; use `HEY_CAPTION` to override the upload caption.
- Sensitive server credentials are persisted through `flutter_secure_storage` via `AppLocalDataSource`.
- Platform folders currently present: `android/`, `linux/`, `macos/`, `web/`, `windows/`.
