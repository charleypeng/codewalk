# Architecture Decision Records (Current State)

This document contains only active architectural decisions that represent the current implementation.

## Index

- ADR-001: Multi-Server Orchestration, Scoped Persistence, and Secure Credential Storage
- ADR-002: Context Isolation with `serverId::directory` and Workspace/Worktree Orchestration
- ADR-003: Realtime-First Sync Lifecycle with Degraded Fallback and Platform-Aware Background Policy
- ADR-004: Chat Architecture with Slim Orchestrators and Decomposed Clusters
- ADR-005: Composer Pipeline for Multimodal Input, Prompt Triggers, and Send/Stop Semantics
- ADR-006: Speech Input Architecture with `SpeechInputService` and Platform Policy
- ADR-007: Modular Settings Architecture for Experience, Notifications, Sounds, and Shortcuts
- ADR-008: Context-Scoped File Explorer and Viewer with Quick Open and Diff-Aware Refresh
- ADR-009: Native Session Title Generation via Internal `title` Agent
- ADR-010: Delivery Pipeline Split for CI Quality, Tagged Releases, and Minor-Tag Smoke Checks

---

## ADR-001: Multi-Server Orchestration, Scoped Persistence, and Secure Credential Storage (2026-02-19)

**Status**: Accepted

### Context

CodeWalk must support multiple OpenCode servers with deterministic active/default routing, isolated runtime state, and secure storage for credentials. Flat global persistence causes cross-server leakage and plaintext secrets create unnecessary risk.

### Decision

Adopt a server-profile architecture with active/default selection, health-aware activation, server/context-scoped persistence keys, and secure credential storage migration to `flutter_secure_storage`.

### Rationale

- Multi-environment usage (local/dev/staging/prod) requires first-class server profiles.
- Scoped persistence avoids cache/model/session contamination across server boundaries.
- Credentials must be isolated from plaintext preference payloads.

### Consequences

- ✅ Enables deterministic multi-server operation with isolated state.
- ✅ Reduces credential exposure by moving auth secrets to secure storage.
- ⚠ Adds migration and hydration complexity between secure and non-secure stores.
- ❌ Legacy flat-key paths remain unsupported as a long-term architecture.

### Key Files

- `lib/presentation/providers/app_provider.dart`
- `lib/data/datasources/app_local_datasource.dart`
- `lib/core/constants/app_constants.dart`
- `lib/domain/entities/server_profile.dart`
- `lib/presentation/pages/server_settings_page.dart`

---

## ADR-002: Context Isolation with `serverId::directory` and Workspace/Worktree Orchestration (2026-02-19)

**Status**: Accepted

### Context

Session, selection, and file state must remain isolated per server and per workspace directory. Users also require explicit workspace/worktree operations without losing context integrity.

### Decision

Standardize context identity as `serverId::scopeId` (directory-first, project fallback), and orchestrate project/worktree lifecycle through context-aware provider flows.

### Rationale

- A canonical context key is required for deterministic caching and reconciliation.
- Directory-level isolation matches how OpenCode sessions are scoped in practice.
- Worktree operations are part of active workspace lifecycle, not an external side flow.

### Consequences

- ✅ Prevents cross-context bleed in session/model/selection state.
- ✅ Supports explicit project switching and worktree lifecycle management.
- ⚠ Increases coordination between project and chat providers.
- ❌ Invalid scope keys are rejected instead of silently merged.

### Key Files

- `lib/presentation/providers/project_provider.dart`
- `lib/presentation/providers/chat_provider/chat_provider_context_state_ops.dart`
- `lib/presentation/pages/chat_page/chat_page_workspace_controller.dart`
- `lib/data/datasources/project_remote_datasource.dart`
- `lib/domain/repositories/project_repository.dart`

---

## ADR-003: Realtime-First Sync Lifecycle with Degraded Fallback and Platform-Aware Background Policy (2026-02-19)

**Status**: Accepted

### Context

The app requires realtime-first behavior for session/message coherence, but it must tolerate stream instability and honor platform-specific background constraints.

### Decision

Use realtime streams as the primary sync mechanism, automatically enter degraded polling when signals fail/stale, and apply platform-aware background policies (desktop tray continuity, mobile hold/fallback strategy).

### Rationale

- Realtime provides best UX for active conversations and event-driven prompts.
- Degraded polling prevents hard desync when streams degrade.
- Desktop and mobile need distinct background lifecycle behavior.

### Consequences

- ✅ Maintains near-live UX under normal connectivity.
- ✅ Preserves functional sync under stream degradation.
- ⚠ Lifecycle orchestration becomes more stateful and timing-sensitive.
- ❌ Continuous background streaming is not guaranteed on mobile.

### Key Files

- `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart`
- `lib/presentation/pages/chat_page/chat_page_lifecycle.dart`
- `lib/presentation/pages/app_shell_page.dart`
- `lib/presentation/services/desktop_tray_service.dart`
- `lib/presentation/services/android_background_alert_worker.dart`

---

## ADR-004: Chat Architecture with Slim Orchestrators and Decomposed Clusters (2026-02-19)

**Status**: Accepted

### Context

Core chat surfaces were previously oversized and difficult to evolve safely. The active architecture requires stable orchestrator entry points with decomposed implementation clusters.

### Decision

Keep `chat_page.dart`, `chat_provider.dart`, and `chat_input_widget.dart` as slim orchestrators and move operational concerns into focused part files and clustered subfolders.

### Rationale

- Orchestrator shells preserve clear ownership boundaries.
- Decomposition reduces regression risk and review overhead.
- Clustered parts improve local reasoning and targeted testing.

### Consequences

- ✅ Better maintainability for high-change chat surfaces.
- ✅ Faster iteration on isolated subsystems.
- ⚠ More files and indirection require stronger naming discipline.
- ❌ Monolithic single-file workflows are no longer supported.

### Key Files

- `lib/presentation/pages/chat_page.dart`
- `lib/presentation/pages/chat_page/`
- `lib/presentation/providers/chat_provider.dart`
- `lib/presentation/providers/chat_provider/`
- `lib/presentation/widgets/chat_input_widget.dart`
- `lib/presentation/widgets/chat_input/`

---

## ADR-005: Composer Pipeline for Multimodal Input, Prompt Triggers, and Send/Stop Semantics (2026-02-19)

**Status**: Accepted

### Context

The composer must combine text and attachments, support power triggers (`@`, `!`, `/`), and provide explicit response-stop behavior without breaking input continuity.

### Decision

Implement a state-driven composer pipeline with multimodal submission contracts, mention/slash trigger controllers, shell-mode trigger (`!`), and guarded send/stop interactions.

### Rationale

- Multimodal composition is a core chat capability, not an optional extension.
- Triggered flows reduce friction for file/agent/command actions.
- Stop semantics must be intentional to avoid accidental aborts.

### Consequences

- ✅ Supports rich prompt composition in a single interaction surface.
- ✅ Improves power-user speed via trigger-based flows.
- ⚠ State transitions are denser and require strict event handling.
- ❌ Shell mode and attachments are intentionally mutually exclusive at send time.

### Key Files

- `lib/presentation/widgets/chat_input_widget.dart`
- `lib/presentation/widgets/chat_input/chat_input_state_machine.dart`
- `lib/presentation/widgets/chat_input/chat_input_mentions_controller.dart`
- `lib/presentation/widgets/chat_input/chat_input_commands_controller.dart`
- `lib/presentation/widgets/chat_input/chat_input_attachment_controller.dart`
- `lib/presentation/widgets/chat_input/chat_input_send_controller.dart`

---

## ADR-006: Speech Input Architecture with `SpeechInputService` and Platform Policy (2026-02-19)

**Status**: Accepted

### Context

Speech input must remain pluggable while respecting platform constraints: Linux favors Sherpa on-device flow, while Android uses native STT in slim builds.

### Decision

Use `SpeechInputService` as the abstraction contract, register native and Sherpa implementations behind DI, enforce platform policy in settings/runtime selection, and keep Android artifacts slim by excluding Sherpa native libs.

### Rationale

- A stable service interface isolates UI from backend engine specifics.
- Linux and Android have different practical/runtime constraints.
- Build-size policy must be codified in architecture, not left to manual process.

### Consequences

- ✅ Keeps speech UX stable while allowing backend specialization.
- ✅ Enforces deterministic engine policy per platform.
- ⚠ Feature parity between engines is not guaranteed at all times.
- ❌ Sherpa is unavailable in Android slim build profile.

### Key Files

- `lib/presentation/services/speech_input_service.dart`
- `lib/presentation/services/speech_input_service_stt.dart`
- `lib/presentation/services/speech_input_service_sherpa.dart`
- `lib/presentation/services/speech_input_service_sherpa_io.dart`
- `lib/presentation/providers/settings_provider.dart`
- `lib/presentation/pages/settings/sections/speech_settings_section.dart`
- `lib/core/di/injection_container.dart`
- `android/app/build.gradle.kts`

---

## ADR-007: Modular Settings Architecture for Experience, Notifications, Sounds, and Shortcuts (2026-02-19)

**Status**: Accepted

### Context

Settings include cross-cutting concerns (visual density, notifications, sounds, shortcuts, speech, platform behavior) and require a coherent state/persistence model.

### Decision

Adopt `SettingsProvider` as the orchestration layer over a typed `ExperienceSettings` contract, with modular settings sections and integrated notification/sound/shortcut policies.

### Rationale

- Strongly typed settings reduce drift and migration errors.
- Provider orchestration centralizes persistence and side-effect handling.
- Modular sections keep UX scalable as settings grow.

### Consequences

- ✅ Unified settings lifecycle across desktop/mobile.
- ✅ Predictable persistence and policy application.
- ⚠ Provider complexity grows with cross-cutting preferences.
- ❌ Ad hoc local setting storage outside `ExperienceSettings` is disallowed.

### Key Files

- `lib/presentation/providers/settings_provider.dart`
- `lib/domain/entities/experience_settings.dart`
- `lib/presentation/pages/settings_page.dart`
- `lib/presentation/pages/settings/sections/notifications_settings_section.dart`
- `lib/presentation/pages/settings/sections/shortcuts_settings_section.dart`
- `lib/presentation/services/notification_service.dart`
- `lib/presentation/services/sound_service.dart`

---

## ADR-008: Context-Scoped File Explorer and Viewer with Quick Open and Diff-Aware Refresh (2026-02-19)

**Status**: Accepted

### Context

File browsing and viewing must stay scoped to the active context, support tabbed navigation, offer fast quick-open discovery, and refresh affected nodes when session diffs change.

### Decision

Implement a context-scoped file state model in chat runtime, with tree cache + tab state, ranked quick-open search, and diff-signature-based selective refresh.

### Rationale

- File UX is tightly coupled to active workspace context.
- Quick-open requires deterministic ranking to be useful at scale.
- Diff-aware invalidation avoids full refresh churn.

### Consequences

- ✅ Faster file navigation with scoped caches and quick-open.
- ✅ Reduced unnecessary reloads through selective invalidation.
- ⚠ Requires careful synchronization between file state and chat diff data.
- ❌ Global cross-context file tabs are intentionally not supported.

### Key Files

- `lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart`
- `lib/presentation/pages/chat_page/chat_page_file_viewer.dart`
- `lib/presentation/pages/chat_page/chat_page_file_runtime.dart`
- `lib/presentation/utils/file_explorer_logic.dart`
- `lib/presentation/providers/project_provider.dart`
- `lib/domain/repositories/project_repository.dart`

---

## ADR-009: Native Session Title Generation via Internal `title` Agent (2026-02-19)

**Status**: Accepted

### Context

Session title generation must be server-native and event-safe, without relying on external title services. The flow must avoid polluting user-visible session history while still participating in runtime event streams.

### Decision

Generate titles through an internal ephemeral session flow using OpenCode agent `title`, filter ephemeral lifecycle events from chat state, and apply title updates only after contextual safety checks.

### Rationale

- Internal agent flow removes external dependency and alignment risk.
- Ephemeral session filtering prevents UI/state contamination.
- Context safety checks prevent stale or cross-context title writes.

### Consequences

- ✅ Title generation is now fully native to server capabilities.
- ✅ Eliminates external service coupling for title synthesis.
- ⚠ Adds polling and ephemeral-session handling logic.
- ❌ External title providers are not part of the active architecture.

### Key Files

- `lib/presentation/services/chat_title_generator.dart`
- `lib/presentation/providers/chat_provider/chat_provider_auto_title_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart`
- `lib/presentation/pages/settings/sections/servers_settings_section.dart`

---

## ADR-010: Delivery Pipeline Split for CI Quality, Tagged Releases, and Minor-Tag Smoke Checks (2026-02-19)

**Status**: Accepted

### Context

The project needs fast quality validation on normal development events, full artifact builds only for tagged releases, and targeted smoke validation for minor release tags.

### Decision

Separate workflows by intent: quality-only CI on push/PR, multi-platform release builds on version tags, and OpenCode smoke checks on minor-tag pushes.

### Rationale

- Quality checks should remain fast and always-on for iteration velocity.
- Release artifact generation is expensive and should be tag-triggered.
- Minor-tag smoke runs provide an additional operational safety net.

### Consequences

- ✅ Faster default CI feedback loop for daily development.
- ✅ Deterministic release pipeline with tag-driven artifact generation.
- ⚠ Requires disciplined tag/version management.
- ❌ Full release builds are intentionally not executed on every push/PR.

### Key Files

- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`
- `.github/workflows/opencode-smoke.yml`
- `Makefile`
- `tool/ci/check_analyze_budget.sh`
- `tool/ci/check_coverage.sh`
