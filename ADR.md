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
- ADR-011: Unified Server Setup Wizard (Onboarding and Settings)
- ADR-012: Material Symbols Migration via `material_symbols_icons`
- ADR-013: MD3 WindowSizeClass Responsive Breakpoint Strategy
- ADR-014: Centralized MD3 Design Tokens for Shapes and Brand Colors
- ADR-015: Platform-Specific Icon Asset Pipeline for Tray, Android Notifications, and macOS Launcher Masking
- ADR-016: Hybrid File-Backed Cache for Large Chat Payloads
- ADR-017: Android Foreground Service for Reliable Background Monitoring
- ADR-018: Dedicated SSE Dio Instance for Connection Pool Isolation
- ADR-019: Defer Config-Mutating API Calls During Active Server Processing
- ADR-020: Session-Level SWR Cache with Persisted LRU Snapshots
- ADR-021: Context-Scoped Draft State for Project-Switch SWR
- ADR-022: Unified Project Context Controls with Sidebar Session Previews
- ADR-023: Official OpenCode Contract-First Compatibility Policy
- ADR-024: Modal Enter Keyboard Policy for Safe Dialogs
- ADR-025: Settled Assistant-Work Disclosure Ownership
- ADR-026: Cross-Platform Terminal Workspace with Local PTY Shell ⚠️ SUPERSEDED by ADR-027
- ADR-027: Server-Hosted PTY Terminal with Embedded Client Rendering
- ADR-028: Unified Scroll Ownership Model for Chat Timeline
- ADR-029: Host-Discovered Quota and Rate-Limit Monitoring for OpenChamber Parity
- ADR-030: OpenChamber-Driven Realtime Hardening and Permission Continuity
- ADR-031: Historical Inline Revert via OpenCode Session Revert Endpoint
- ADR-032: LaTeX Math Rendering with flutter_math_fork and Custom Markdown Delimiters
- ADR-033: Cloudflare Access OAuth as Optional Desktop Reverse-Proxy Auth (ADR-023 Exception)

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

Standardize context identity as `serverId::scopeId` (directory-first, project fallback), and orchestrate project/worktree lifecycle through context-aware provider flows. Project scope transitions (project switches, workspace create/delete, project close/reopen) are serialized through a single-flight queue (`_runProjectScopeTransition`) with `Completer`-based tracking to prevent race conditions from rapid user actions.

### Rationale

- A canonical context key is required for deterministic caching and reconciliation.
- Directory-level isolation matches how OpenCode sessions are scoped in practice.
- Worktree operations are part of active workspace lifecycle, not an external side flow.

### Consequences

- ✅ Prevents cross-context bleed in session/model/selection state.
- ✅ Supports explicit project switching and worktree lifecycle management.
- ⚠ Increases coordination between project and chat providers.
- ⚠ All scope-changing operations must flow through the serialization queue; bypassing it risks concurrent state corruption.
- ❌ Invalid scope keys are rejected instead of silently merged.

**Note** (commits `cb324c4`, `785eee8`): Scope transition serialization queue added.

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

Use realtime streams as the primary sync mechanism, automatically enter degraded polling when signals fail/stale, and apply platform-aware background policies (desktop tray continuity, mobile hold/fallback strategy). Active message-response streams are preserved (not cancelled) during session navigation to maintain in-flight response continuity. Preserved streams are tracked in a dedicated set and drained on every context switch to prevent connection leaks. A generation counter (`_messageStreamGeneration`) invalidates stale preserved-stream callbacks, preventing cross-session state mutation. Session lifecycle remains server-authoritative: follow-up prompts ride the standard async send path, and the client does not invent local queued/batched send phases.

### Rationale

- Realtime provides best UX for active conversations and event-driven prompts.
- Degraded polling prevents hard desync when streams degrade.
- Desktop and mobile need distinct background lifecycle behavior.

### Consequences

- ✅ Maintains near-live UX under normal connectivity.
- ✅ Preserves functional sync under stream degradation.
- ✅ Preserves in-flight AI responses during session navigation, matching OpenCode Web continuity behavior.
- ✅ Keeps busy/idle/send lifecycle aligned with upstream server events instead of local queue orchestration.
- ⚠ Lifecycle orchestration becomes more stateful and timing-sensitive.
- ⚠ Generation-based invalidation is required to prevent stale preserved streams from mutating current session state; all preserved subscriptions must be drained on context switches.
- ❌ Continuous background streaming is not guaranteed on mobile.

**Note** (commits `acce617`, `9dcd773`, `37f0397`): Preserved stream lifecycle, drain-on-context-switch, and generation invalidation added.

**Note** (commit `77592fa`): Fixed stale-persisted-session-ID race condition where `loadSessions()` triggered by global events could read a stale session ID from disk and revert an in-memory session switch. Three defensive guards added: `selectSession()` now invalidates `_sessionsFetchId`, `loadLastSession()` prioritizes in-memory `_currentSession?.id` over persisted ID, and `_restoreLastSessionSnapshotFromCache()` guards against overwriting an already-switched session.

**Note** (commit `1fcf33e`): SSE streams are now served by a dedicated Dio instance (`_sseDio`) with an isolated connection pool, preventing Android HTTP client from evicting SSE connections when regular HTTP requests compete for TCP connections during session switches. See ADR-018.

**Note**: In polling-only background monitoring (when push notifications are unavailable), added a 5-minute tail probe after active sessions end to reduce missed notifications. Implementation uses `kBackgroundTailProbeInterval` (5 minutes) as the constant and `shouldScheduleBackgroundTailProbe()` to determine eligibility based on session state and platform support.

**Note** (commit `161b9ce`): Tightened current-session active-turn detection — incomplete `assistant`/`current` sending state remains active even if idle status arrives early, preventing premature turn completion detection. Also narrowed unsupported global `message.*` fallback reconcile — only the visible current session can trigger active-session refresh when no active local stream/compaction guard is in effect.

### Key Files

- `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart`
- `lib/presentation/pages/chat_page/chat_page_lifecycle.dart`
- `lib/presentation/pages/app_shell_page.dart`
- `lib/presentation/services/desktop_tray_service.dart`
- `lib/presentation/services/android_background_alert_worker.dart`
- `lib/presentation/providers/chat_provider/chat_provider_session_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_cache_persistence_ops.dart`

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

Implement a state-driven composer pipeline with multimodal submission contracts, mention/slash trigger controllers, shell-mode trigger (`!`), and guarded send/stop interactions. Busy-session follow-up prompts use the same direct async send path as normal turns; the composer does not maintain a client-side queued/send-now subsystem, and `Stop` remains a separate explicit abort action when no draft is ready to send.

### Rationale

- Multimodal composition is a core chat capability, not an optional extension.
- Triggered flows reduce friction for file/agent/command actions.
- Stop semantics must be intentional to avoid accidental aborts.

### Consequences

- ✅ Supports rich prompt composition in a single interaction surface.
- ✅ Improves power-user speed via trigger-based flows.
- ✅ Allows direct follow-up sends during active responses without coupling them to implicit aborts or local batching.
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

Speech input must remain pluggable while respecting platform constraints: Linux favors downloadable on-device engines, desktop can expose Moonshine, Parakeet V3 (sherpa_onnx offline NeMo transducer), or SenseVoice (sherpa_onnx offline recognition) through the existing sherpa_onnx stack, while Android uses native STT in slim builds. Linux now defaults to Parakeet for new installs; existing native selections are migrated to Parakeet because native STT is disabled on Linux.

### Decision

Use `SpeechInputService` as the abstraction contract, register native, Sherpa, desktop Moonshine, desktop Parakeet (offline NeMo transducer via sherpa_onnx), and desktop SenseVoice (sherpa_onnx offline recognition) implementations behind DI, enforce platform policy in settings/runtime selection (Linux defaults to Parakeet with automatic migration from native), and keep Android artifacts slim by excluding sherpa_onnx native libs from Android builds.

### Rationale

- A stable service interface isolates UI from backend engine specifics.
- Linux and Android have different practical/runtime constraints.
- Build-size policy must be codified in architecture, not left to manual process.

### Consequences

- ✅ Keeps speech UX stable while allowing backend specialization.
- ✅ Enforces deterministic engine policy per platform.
- ✅ SenseVoice adds a strong desktop option for Chinese, Cantonese, Japanese, Korean, and English via sherpa_onnx offline recognition.
- ✅ Linux default to Parakeet with automatic migration prevents broken native-engine state on new installs.
- ⚠ Feature parity between engines is not guaranteed at all times.
- ❌ Sherpa/Moonshine/Parakeet/SenseVoice are unavailable in Android slim build profile.

### Key Files

- `lib/presentation/services/speech_input_service.dart`
- `lib/presentation/services/speech_input_service_stt.dart`
- `lib/presentation/services/speech_input_service_sherpa.dart`
- `lib/presentation/services/speech_input_service_sherpa_io.dart`
- `lib/presentation/services/speech_input_service_moonshine_io.dart`
- `lib/presentation/services/speech_input_service_parakeet.dart`
- `lib/presentation/services/speech_input_service_parakeet_io.dart`
- `lib/presentation/services/speech_input_service_sensevoice.dart`
- `lib/presentation/services/speech_input_service_sensevoice_io.dart`
- `lib/presentation/services/speech_input_service_sensevoice_stub.dart`
- `lib/presentation/services/moonshine_model_manager_io.dart`
- `lib/presentation/services/parakeet_model_manager.dart`
- `lib/presentation/services/parakeet_model_manager_io.dart`
- `lib/presentation/services/sensevoice_model_manager_io.dart`
- `lib/presentation/widgets/sensevoice_model_download_dialog.dart`
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

---

## ADR-011: Unified Server Setup Wizard (Onboarding and Settings) (2026-02-19)

**Status**: Accepted

### Context

The app had no first-run experience; it opened directly to ChatPage with connection errors when no server was configured, leaving new users without guidance.

### Decision

Gate the main shell in `AppShellPage` via `Consumer2` checks on `serverProfiles` and `skipOnboardingWizard` flag. Introduce `OnboardingWizardPage` with a 3-step flow (Welcome, Server Setup, Ready). Persist the skip flag in `ExperienceSettings`. The wizard is also surfaced at the top of Server Settings as the canonical server setup entry point, consolidating the previously separate inline setup form into the same wizard flow used during onboarding.

### Rationale

- New users need guided setup to configure at least one server before using the app.
- Gating at the shell level ensures no partial UI is shown before configuration is complete.
- A persistent flag allows existing users to bypass the wizard entirely.

### Consequences

- ✅ New users see a guided setup flow that prevents unconfigured-state errors.
- ✅ Existing users are unaffected; the wizard is skipped when profiles already exist.
- ✅ "Reset app" in About allows returning to the wizard state for re-onboarding.
- ⚠ Adds a gating layer in `AppShellPage` that must stay synchronized with profile state.
- ✅ Server setup consolidated into a single wizard flow, reducing code duplication and ensuring consistent setup UX across first-run and settings contexts.
- ❌ The wizard flow is intentionally linear; non-linear onboarding is not supported.

### Key Files

- `lib/presentation/pages/app_shell_page.dart`
- `lib/presentation/pages/onboarding_wizard_page.dart`
- `lib/domain/entities/experience_settings.dart`
- `lib/presentation/providers/settings_provider.dart`
- `lib/presentation/pages/settings/sections/servers_settings_section.dart`

**Note** (commit `bd12170`): The wizard was unified to serve both first-run onboarding and settings-page server setup. The previous inline server setup form in `servers_settings_section.dart` was replaced with the wizard flow, consolidating 613 lines of duplicated setup logic.

---

## ADR-012: Material Symbols Migration via `material_symbols_icons` (2026-02-20)

**Status**: Accepted

### Context

The codebase used Flutter `Icons.*` references broadly, but feature requirements introduced symbols that are only available in Material Symbols (for example, panel-specific close icons). The project also needs broader icon coverage and a future-proof path aligned with Google's current design direction.

Related: See `featM` in `ROADMAP.md` (commit `e05d2fb`).

### Decision

Standardize icon usage on `Symbols.*` from `material_symbols_icons` and migrate existing `Icons.*` references to symbol equivalents, keeping static symbol constants in code paths to preserve Flutter tree-shaking behavior.

### Rationale

- Material Symbols provides broader coverage than legacy Material Icons and unblocks missing-icon cases.
- The package tracks Material Symbols updates and aligns with the ecosystem direction, reducing migration risk later.
- Static references keep icon fonts optimizable during build, avoiding unnecessary asset growth from dynamic lookups.

### Consequences

- ✅ Access to the Material Symbols catalog and consistent icon language across mobile and desktop.
- ✅ Future-friendly alignment with Google's symbol-first direction for new UI work.
- ⚠ Naming adjustments are required (`Icons.*` to `Symbols.*`), including variant suffix differences in some cases.
- ⚠ Visual style parity must be reviewed case-by-case where Symbols metrics/appearance differ from previous Icons usage.
- ❌ Dynamic or computed icon indirection is intentionally discouraged to preserve static references and tree-shaking efficiency.

### Key Files

- `pubspec.yaml`
- `lib/`

---

## ADR-013: MD3 WindowSizeClass Responsive Breakpoint Strategy (2026-02-20)

**Status**: Accepted

### Context

The UI layer relied on hardcoded pixel breakpoints (e.g. `_isMobileViewport` checks against arbitrary widths) scattered across multiple widgets and pages. This made responsive behavior inconsistent and difficult to reason about, especially when distinguishing phone, tablet, and desktop layouts. The `featN` Material You revamp required a systematic approach aligned with MD3 guidelines.

Related: See `featN` in `ROADMAP.md`.

### Decision

Introduce a `WindowSizeClass` enum with five tiers matching MD3 Window Size Classes: Compact (<600dp), Medium (600–839dp), Expanded (840–1199dp), Large (1200–1599dp), ExtraLarge (≥1600dp). Provide convenience getters (`isCompact`, `isAtLeastExpanded`, etc.) and use `WindowSizeClass.fromWidth()` as the single source of truth for responsive decisions. Replace all hardcoded breakpoint checks with `WindowSizeClass` queries.

Additionally, redefine the mobile-viewport guard: the previous `_isMobileViewport` (which only checked `isCompact`) was replaced with `!isAtLeastExpanded` to ensure mobile-oriented gestures and layouts also apply on Medium/tablet breakpoints, not just phone-sized screens.

### Rationale

- MD3 Window Size Classes are the canonical responsive framework for Material-based apps.
- A single enum centralizes all breakpoint logic, eliminating scattered magic numbers.
- The `!isAtLeastExpanded` guard correctly captures the intent: mobile gestures should work on any viewport smaller than desktop-class, including tablets in the Medium range.
- Convenience getters improve readability and reduce error-prone raw comparisons.

### Consequences

- ✅ Consistent responsive behavior across all UI surfaces via a single canonical breakpoint model.
- ✅ Mobile gesture/layout guard (`!isAtLeastExpanded`) correctly includes tablet/medium viewports.
- ✅ Aligns with MD3 specification, reducing drift as Material guidelines evolve.
- ⚠ All existing breakpoint checks must be migrated to `WindowSizeClass` queries.
- ❌ Arbitrary per-widget breakpoint overrides are intentionally discouraged; deviations must use `WindowSizeClass` tiers.

**Note** (commit `f9efd1b`): A RenderFlex overflow in the medium-breakpoint directory selector was fixed as a direct consequence of this breakpoint model — constrained Medium-width layouts require explicit flex/overflow handling that Compact and Expanded layouts did not expose.

### Key Files

- `lib/presentation/utils/window_size_class.dart`
- `lib/presentation/pages/chat_page.dart`
- `lib/presentation/pages/home_page.dart`
- `lib/presentation/pages/settings_page.dart`
- `lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart`
- `lib/presentation/widgets/chat_message_widget.dart`

---

## ADR-014: Centralized MD3 Design Tokens for Shapes and Brand Colors (2026-02-20)

**Status**: Accepted

### Context

Shape values (border radii) were scattered across 15+ widgets as magic `BorderRadius.circular(...)` literals with no consistent scale. Color seed selection for non-dynamic-color scenarios had no structured fallback. The `featN` Material You revamp required centralizing these design tokens to align with MD3 specifications.

Related: See `featN` in `ROADMAP.md`.

### Decision

1. **AppShapes**: Introduce a centralized shape constants class implementing the MD3 shape scale — None (0), ExtraSmall (4), Small (8), Medium (12), Large (16), ExtraLarge (28), Full (999) — as static `BorderRadius` constants. Replace all scattered magic border-radius values with `AppShapes.*` references.

2. **BrandColor**: Introduce an enum providing 5 curated seed colors as a deterministic fallback palette when dynamic color (`DynamicColorBuilder`) is unavailable or disabled by the user.

3. **Touch target policy**: Global `materialTapTargetSize: MaterialTapTargetSize.padded` was evaluated and rejected because it caused cascading Row overflow issues in tight layouts. Touch target enforcement is scoped only to specific widgets that need it (e.g., model selector), rather than applied globally via theme.

### Rationale

- MD3 defines a canonical shape scale; centralizing it eliminates visual inconsistency and makes future scale adjustments atomic.
- A brand-color enum provides predictable theming when platform dynamic color is absent, without hardcoding hex values at call sites.
- Scoped tap-target enforcement avoids layout regressions while still meeting accessibility goals where they matter most.

### Consequences

- ✅ Single source of truth for shape tokens; changing the scale updates all surfaces atomically.
- ✅ Brand color fallback is explicit and testable, decoupled from dynamic color availability.
- ✅ Avoids global tap-target padding regressions in constrained layouts.
- ⚠ All existing `BorderRadius.circular(...)` literals must be migrated to `AppShapes.*` references.
- ⚠ Adding new shape tiers requires updating `AppShapes` and verifying downstream usage.
- ❌ Global `materialTapTargetSize: padded` is intentionally rejected; per-widget scoping is the accepted pattern.

**Note** (commit `f9efd1b`): Dynamic color availability detection was upgraded from a static platform heuristic (`_supportsDynamicColor()`) to runtime detection via `DynamicColorBuilder`, propagated through `SettingsProvider.dynamicColorAvailable`. As a consequence, the contrast slider is now disabled when dynamic color is active, since contrast adjustment only applies to `ColorScheme.fromSeed` (seed-based) themes.

### Key Files

- `lib/presentation/theme/app_shapes.dart`
- `lib/presentation/theme/brand_colors.dart`
- `lib/presentation/theme/app_theme.dart`
- `lib/presentation/pages/settings/sections/appearance_settings_section.dart`
- `lib/presentation/widgets/chat_input_widget.dart`
- `lib/presentation/widgets/chat_message_widget.dart`

---

## ADR-015: Platform-Specific Icon Asset Pipeline for Tray, Android Notifications, and macOS Launcher Masking (2026-02-20)

**Status**: Accepted

### Context

The app now relies on platform-specific icon constraints for desktop tray rendering and Android notification visibility. A single generic source icon does not produce consistent results across Linux/macOS/Windows tray surfaces, and Android status-bar notifications require a dedicated monochrome small icon resource. macOS launcher icons also need rounded-corner masking in generation to match expected platform appearance.

### Decision

Standardize `make icons` as the canonical image pipeline using ImageMagick to generate:

- OS-specific tray assets (`tray_icon_linux.png`, `tray_icon_macos_template.png`, `tray_icon_windows.ico`) from a shared monochrome master.
- Android notification small icons as `ic_stat_codewalk` in `android/app/src/main/res/drawable-*`.
- macOS launcher source with rounded-corner mask before generating app icon sizes.

Enforce runtime usage through platform services: Android notifications use `@drawable/ic_stat_codewalk` in `AndroidNotificationDetails`, and desktop tray service loads OS-specific tray assets.

### Rationale

- Platform-specific icon rendering rules differ and require explicit per-target outputs.
- A generated pipeline prevents manual asset drift and keeps outputs reproducible.
- Dedicated Android small-icon resources improve status-bar legibility and consistency.
- Rounded macOS launcher source aligns generated icons with native visual expectations.

### Consequences

- ✅ Predictable, reproducible icon generation for tray, notification, and launcher targets.
- ✅ Better notification icon clarity on Android via dedicated `ic_stat_codewalk` resources.
- ✅ Correct tray appearance per desktop OS using target-specific assets.
- ⚠ `make icons` now depends on ImageMagick availability in contributor/build environments.
- ❌ Ad hoc manual replacement of generated icon outputs is intentionally discouraged.

### Key Files

- `Makefile`
- `lib/presentation/services/notification_service.dart`
- `lib/presentation/services/desktop_tray_service_io.dart`
- `android/app/src/main/res/drawable-*/ic_stat_codewalk.png`
- `assets/images/tray_icon_*.png`, `assets/images/tray_icon_windows.ico`
- `assets/images/macos_appicon_source.png`

---

## ADR-016: Hybrid File-Backed Cache for Large Chat Payloads (2026-02-20)

**Status**: Accepted

### Context

SharedPreferences has platform-specific size limits and performance degradation for large JSON payloads (session lists, full session snapshots). On some Android devices, payloads exceeding a few hundred KB cause observable write delays and risk silent data truncation.

### Decision

Introduce a two-tier cache architecture: large chat payloads are written to a file-backed store (`ChatCachePayloadStore`) in the app support directory (`chat_cache_v1/`), while metadata and small values remain in SharedPreferences. The file store uses SHA-1 key hashing for deterministic filenames and maintains a 24-entry LRU in-memory read cache. Transparent lazy migration moves existing large values from SharedPreferences to the file store on first access, tracked by a `_migratedLargeCacheKeys` set. Platform-conditional imports provide a no-op stub on web.

### Rationale

- SharedPreferences is designed for small key-value pairs; using it for multi-hundred-KB JSON blobs violates platform contracts.
- A file-backed store removes size limits and improves write performance for large payloads.
- Lazy migration avoids a blocking startup cost while ensuring data is progressively moved.
- Full fallback to SharedPreferences on file-store failure ensures the app never breaks due to storage layer issues.

### Consequences

- ✅ Eliminates payload size limits and improves write performance for large session data.
- ✅ Transparent migration requires no user action; existing data is preserved.
- ✅ Full fallback to SharedPreferences ensures resilience against file-store failures.
- ⚠ Adds platform-conditional compilation paths (io vs. stub) and migration tracking state.
- ❌ Web platform uses stub (no file store); large payloads remain in SharedPreferences on web.

### Key Files

- `lib/data/cache/chat_cache_payload_store.dart`
- `lib/data/cache/chat_cache_payload_store_base.dart`
- `lib/data/cache/chat_cache_payload_store_io.dart`
- `lib/data/cache/chat_cache_payload_store_stub.dart`
- `lib/data/datasources/app_local_datasource.dart`

---

## ADR-017: Android Foreground Service for Reliable Background Monitoring (2026-02-20)

**Status**: Accepted

### Context

Android aggressively kills background processes and restricts background execution. The app's background alert monitoring requires a reliable mechanism to survive Android process management and deliver timely notifications even when the app is not in the foreground.

### Decision

Implement a native Kotlin foreground service (`CodeWalkForegroundService`) with `START_STICKY` restart policy, bridged to Dart via `MethodChannel('codewalk/system')`. The Dart-side orchestrator (`AndroidForegroundMonitorService`) provides idempotent `sync()` calls that always invoke the native bridge without count-based deduplication, ensuring the service is restarted if Android killed it while Dart statics were stale. The service uses a dedicated low-priority notification channel (`codewalk_background_monitor_v2`, `IMPORTANCE_MIN`) for the persistent monitoring notification, separate from the alert notification channel which uses default importance for audible alerts.

### Rationale

- `START_STICKY` ensures Android restarts the service after process death, maintaining monitoring continuity.
- Idempotent sync (always calling the native bridge) avoids stale Dart state from masking a killed native service.
- A dedicated low-priority notification channel keeps the mandatory foreground notification silent and non-intrusive.
- Separate alert and monitor channels allow users to configure notification preferences independently.
- `@Volatile` on the companion `instance` field ensures thread-safe access from the MethodChannel handler.

### Consequences

- ✅ Background monitoring survives Android process management via `START_STICKY`.
- ✅ Idempotent sync prevents stale-state gaps between Dart and native service lifecycle.
- ✅ Silent monitor notification with separate alert channel preserves notification UX quality.
- ⚠ Requires maintaining native Kotlin code alongside the Dart implementation.
- ⚠ `START_STICKY` restart is not guaranteed on all OEM Android variants with aggressive battery optimization.
- ❌ The foreground notification is mandatory while monitoring is active (Android OS requirement).

### Key Files

- `android/app/src/main/kotlin/com/verseles/codewalk/CodeWalkForegroundService.kt`
- `lib/presentation/services/android_foreground_monitor_service.dart`
- `lib/presentation/services/android_background_alert_worker.dart`

---

## ADR-018: Dedicated SSE Dio Instance for Connection Pool Isolation (2026-02-22)

**Status**: Accepted

**Related**: ADR-003 (Realtime-First Sync Lifecycle)

### Context

The shared Dio singleton's HTTP connection pool on Android drops per-send SSE long-lived connections when `selectSession` triggers regular HTTP requests (`loadMessages`, selection sync). The Android HTTP client aggressively reuses TCP connections; when the shared pool needs a connection for a regular request, it closes the least-recently-used connection — which is the SSE stream. The server detects the disconnection and sends `MessageAbortedError`, causing a false abort visible to the user.

Confirmed via `curl` that the server does NOT abort concurrent sessions when SSE connections stay alive — the problem is 100% client-side connection pool eviction.

### Decision

Create a second Dio instance (`_sseDio`) in `DioClient` with its own `IOHttpClientAdapter` and `HttpClient`, dedicated exclusively to SSE streams. Use conditional imports (`dio_sse_adapter.dart` → `dio_sse_adapter_io.dart` / `dio_sse_adapter_stub.dart`) for IO/web platform compatibility. The SSE `HttpClient` is configured with `idleTimeout: 2h` and `maxConnectionsPerHost: 4`.

`ChatRemoteDataSourceImpl` accepts an optional `sseDio` parameter with fallback to the regular `dio` (for tests and web). Provider-level SSE connections (`/event`, `/global/event`) route through `sseDio`. `baseUrl` and auth configuration are mirrored to both Dio instances in `updateBaseUrl()`, `setBasicAuth()`, and `clearAuth()`.

**Update (commit `61934e9`)**: Per-send SSE connections were removed entirely from the `prompt_async` path. The server monitors per-send SSE connections and aborts the AI agent when it detects disconnection (e.g. half-open TCP after background resume). Without per-send SSE, `prompt_async` processes fully async — message delivery relies on immediate polling (`startFallbackCompletionWatch` with zero delay) plus provider-level SSE. Some recent servers (e.g., OpenChamber or newer OpenCode builds) may return the completed assistant payload directly in the `200 OK` response; CodeWalk accepts this authoritative payload immediately, bypassing the fallback polling path. The dedicated SSE Dio remains in use for provider-level SSE streams.

### Rationale

- A separate `HttpClient` with its own connection pool eliminates TCP connection contention between regular HTTP requests and long-lived SSE streams entirely.
- Conditional imports follow the same pattern used by `ChatCachePayloadStore` (ADR-016), providing a no-op stub on web where browsers manage connections natively.
- Optional `sseDio` injection maintains backward compatibility with all existing tests without requiring mock changes.
- Mirroring auth/baseUrl in both instances keeps configuration synchronized without requiring a shared interceptor chain.

### Consequences

- ✅ Eliminates false abort on concurrent session switch caused by connection pool eviction.
- ✅ SSE streams are never evicted by regular HTTP requests competing for connections.
- ✅ Eliminates server-side abort triggered by dead per-send SSE connections after background resume.
- ✅ Web platform is unaffected (no-op stub; browser manages connections natively).
- ⚠ Two Dio instances must stay synchronized for `baseUrl` and auth changes — all config methods in `DioClient` must update both.
- ⚠ No `dispose()` exists for either Dio instance; acceptable since `DioClient` is a `registerLazySingleton` with app-lifetime scope.
- ✅ Selection sync deferral during abort suppression eliminates server-side Instance disposal during active multi-step processing.
- ⚠ The 8s abort suppression window must be longer than typical inter-step gaps; very long tool executions may need the SSE busy-status fallback.
- ❌ Slightly higher memory footprint from the second connection pool (negligible for mobile/desktop).

**Note**: The app's selection sync (`PATCH /config`) triggers `Config.update()` on the OpenCode server, which calls `Instance.dispose()`. Instance disposal runs cleanup handlers that abort ALL active session `AbortController`s — killing any multi-step processing in progress. This was the root cause of false aborts on complex prompts (tool-calls with multiple steps). Fix: defer selection sync during the 8-second abort suppression window post-send, so `PATCH /config` never arrives while the server is still processing multi-step loops. After the window, the existing `hasBusyStatus` check (based on SSE session status) prevents premature sync. See ADR-019 for the full decision on config-mutating call deferral.

### Key Files

- `lib/core/network/dio_client.dart`
- `lib/core/network/dio_sse_adapter.dart`
- `lib/core/network/dio_sse_adapter_io.dart`
- `lib/core/network/dio_sse_adapter_stub.dart`
- `lib/data/datasources/chat_remote_datasource.dart`
- `lib/core/di/injection_container.dart`

---

## ADR-019: Defer Config-Mutating API Calls During Active Server Processing (2026-02-22)

**Status**: Accepted

**Related**: ADR-018 (Dedicated SSE Dio Instance), ADR-003 (Realtime-First Sync Lifecycle)

### Context

The app syncs user selections (model, provider, system prompt) to the OpenCode server via `PATCH /config`. On the server side, `Config.update()` calls `Instance.dispose()`, which runs cleanup handlers that abort ALL active session `AbortController`s. When the user sends a complex prompt that triggers multi-step processing (tool-calls with multiple steps), a selection sync fired during processing would kill the in-flight session — causing false aborts that appeared as server-side failures but were actually client-initiated lifecycle disruption.

This was confirmed as the root cause of false aborts on complex prompts: the client's selection sync arrived while the server was between tool-call steps, triggering Instance disposal and aborting the entire session.

### Decision

Defer all config-mutating API calls (`PATCH /config`) during the post-send abort suppression window (8 seconds). The deferral uses two complementary guards:

1. **Abort suppression window (time-based)**: For the first 8 seconds after `prompt_async` send, selection sync is suppressed entirely. This covers the critical startup phase where SSE session status may not yet reflect "busy" state.
2. **SSE busy-status check (state-based)**: After the 8s window expires, the existing `hasBusyStatus` check (derived from SSE session status events) prevents sync while the server reports an active session. This covers long-running tool executions that extend beyond the initial window.

Selection changes made during suppression are not lost — they are applied on the next eligible sync cycle once both guards clear.

### Rationale

- `PATCH /config` is the only client-initiated API call that triggers server-side `Instance.dispose()`, making it the sole vector for client-caused session abortion.
- The 8s time-based guard is necessary because SSE status events have propagation delay — the server may be processing before the client receives a "busy" status update.
- The state-based `hasBusyStatus` fallback ensures protection extends beyond the fixed window for long-running operations.
- Two-layer deferral (time + state) provides defense-in-depth without requiring server-side changes.

### Consequences

- ✅ Eliminates client-caused false aborts during multi-step server processing (tool-calls, complex prompts).
- ✅ Selection changes are preserved and applied after processing completes — no user input is lost.
- ✅ No server-side changes required; fix is entirely client-side.
- ⚠ The 8s abort suppression window must be longer than typical inter-step gaps; if the server takes longer than 8s between steps AND SSE status has not yet propagated, a race condition is theoretically possible (mitigated by the SSE busy-status fallback).
- ⚠ Selection sync latency increases by up to 8s after sending a prompt — user sees the old selection on the server briefly.
- ❌ Immediate selection sync during active processing is intentionally prohibited; this is a correctness tradeoff over responsiveness.

### Key Files

- `lib/presentation/providers/chat_provider/chat_provider_send_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`
- `lib/data/datasources/chat_remote_datasource.dart`

---

## ADR-020: Session-Level SWR Cache with Persisted LRU Snapshots (2026-02-26)

**Status**: Accepted

**Related**: ADR-016 (Hybrid File-Backed Cache), ADR-003 (Realtime-First Sync Lifecycle)

### Context

Long conversations were reloading from scratch on every session switch. The provider cleared `_messages` before loading remote data, so switching to a large session frequently showed a blank/loading state and caused perceived stutter. Existing durable cache only restored a single "last session snapshot", which did not help when moving between multiple active sessions.

The "project-switch fast cache-first SWR path" (commits `f432a33`, `facd736`) optimizes the workspace transition by allowing immediate UI restoration from the per-session cache while revalidation occurs in the background.

Server APIs currently expose full message list reads (with optional `limit`) and single-message fetch, but no dedicated delta cursor/etag endpoint for historical chat synchronization.

### Decision

Adopt a cache-first SWR policy per session:

1. Add an in-memory per-session LRU message cache in `ChatProvider` (20 entries).
2. Persist recent per-session message snapshots using ADR-016 file-backed storage (`ChatCachePayloadStore`) plus SharedPreferences metadata for recency and timestamps.
3. On `selectSession`, restore cached messages immediately when available and trigger background `loadMessages(...preserveVisibleState: true)` revalidation.
4. Project Switch Fast-Path: During workspace/project transitions (`serverId::directory`), prioritize restoring the last known session snapshot for that context from cache immediately, bypassing the full "loading" state if valid data exists.
5. Keep full-fetch correctness path, but incrementally patch non-current session caches on `message.created` / `message.updated` via single-message fallback fetch.
6. Virtual History Loading: Implement top-scroll pagination by plumbing optional `limit` through the message read stack and adding a `loadOlderMessages()` flow. The UI maintains scroll anchor position across history injections to prevent layout shifts.

### Rationale

- Cache-first restore removes unnecessary blank reloads for recently visited long sessions.
- SWR keeps correctness by still revalidating against server state.
- Project-switch fast-path specifically targets the latency-sensitive workspace transition, where waiting for network before showing *any* chat history creates high friction.
- Per-session persistence extends ADR-016 beyond one snapshot and keeps cache useful across app restarts.
- Event-assisted patching improves freshness for background sessions even without a server delta endpoint.
- Top-scroll pagination enables browsing long histories without high initial memory/latency costs.
- Anchor restoration ensures a smooth reading experience when prepending messages.

### Consequences

- ✅ Session switching is significantly faster and more stable for long conversations.
- ✅ Background revalidation keeps data fresh without forcing full UI reset.
- ✅ Cache durability now covers multiple recent sessions, not only the last one.
- ✅ Support for seamless top-scroll pagination with stable scroll anchoring.
- ✅ Workspace transitions (project switches) feel instantaneous when cached session data exists.
- ⚠ Cache metadata/key management is more complex (LRU list + per-session timestamps).
- ⚠ Scroll anchor restoration logic adds complexity to the ChatPage list controller.
- ❌ No true server-side delta endpoint yet; full-fetch fallback remains necessary for correctness.

### Key Files

- `lib/presentation/providers/chat_provider.dart`
- `lib/presentation/providers/chat_provider/chat_provider_cache_persistence_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart`
- `lib/presentation/pages/chat_page/chat_page_scroll_coordinator.dart`
- `lib/data/datasources/app_local_datasource.dart`
- `lib/data/datasources/chat_remote_datasource.dart`
- `lib/domain/usecases/get_chat_messages.dart`
- `lib/presentation/providers/chat_provider/chat_provider_context_state_ops.dart`

---

## ADR-021: Context-Scoped Draft State for Project-Switch SWR (2026-02-28)

**Status**: Accepted

**Related**: ADR-002 (Context Isolation), ADR-020 (Session-Level SWR Cache)

### Context

After adopting draft-first New Chat with lazy session bootstrap, project-switch fast-path (`waitForRevalidation: false`) could carry draft-only state into another `serverId::directory` context. In this leaked state, `loadLastSession()` could incorrectly short-circuit for the target context, leaving it in an empty draft flow instead of restoring that context's session/snapshot via SWR.

### Decision

Treat draft-related composer/session bootstrap state as context-scoped snapshot data:

1. `_ChatContextSnapshot` now includes `isNewChatDraftActive`, `activeSendDraft`, and `rejectedDraft`.
2. `_storeCurrentContextSnapshot()` persists this draft state per active context key.
3. `_restoreContextSnapshot()` restores draft state for known contexts and resets to non-draft for new contexts.
4. `_switchContext()` clears transient `_lazySessionBootstrapTask` to avoid in-flight bootstrap futures crossing context boundaries.
5. `createNewSession()` guards against post-await context changes and discards stale results from old contexts.

### Rationale

- Project scope in CodeWalk is `serverId::directory`; draft state must follow the same isolation boundary as sessions and selections.
- Fast project switching must remain cache-first and non-blocking without letting ephemeral draft flags block target-context restore.
- Async session bootstrap must not write stale results after a context switch.

### Consequences

- ✅ Prevents cross-project draft leakage during fast project switches.
- ✅ Preserves draft-first UX inside the originating context while restoring normal SWR behavior in other contexts.
- ✅ Adds regression coverage for project-switch + draft round-trip behavior.
- ⚠ Snapshot payload grows slightly with draft-related fields.
- ❌ Draft bootstrap tasks are intentionally not resumed across context switches.

### Key Files

- `lib/presentation/providers/chat_provider_types_part.dart`
- `lib/presentation/providers/chat_provider/chat_provider_preference_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_session_ops.dart`
- `lib/presentation/providers/chat_provider.dart`
- `test/unit/providers/chat_provider_project_test.dart`

---

## ADR-022: Unified Project Context Controls with Sidebar Session Previews (2026-03-01)

**Status**: Accepted

**Related**: ADR-002 (Context Isolation), ADR-020 (Session-Level SWR Cache), ADR-021 (Context-Scoped Draft State)

### Context

Project context controls and conversations navigation were split across separate UI surfaces (project selector in the app bar and sessions in the sidebar). This separation increased navigation friction, especially on mobile. Users needed a unified navigation point that keeps project switching and conversation access together while preserving strict context isolation.

### Decision

1. Merge project context controls into the conversations sidebar for both mobile drawer and desktop sidebar layouts.
2. Add per-project conversation previews in the sidebar using active context sessions plus cached snapshots from previously visited contexts.
3. Keep session ownership and active state strictly scoped by `serverId::scopeId`; selecting a conversation from another project always triggers context switch first.
4. Reuse existing context-switch fast path and background revalidation strategy; no change to server API contracts.

### Rationale

- A single navigation surface reduces context-switch cognitive overhead.
- Snapshot-backed previews improve perceived speed when moving between projects.
- Preserving `serverId::scopeId` ownership avoids cross-project state leakage and protects existing invariants.
- Reusing existing SWR/cache behavior minimizes migration risk.

### Consequences

- ✅ Faster project/session navigation from one sidebar workflow.
- ✅ Better mobile/desktop consistency for context controls.
- ✅ No architectural break in context isolation semantics.
- ⚠ Sidebar UI/state management becomes more complex (project rows + previews + actions).
- ⚠ Preview availability depends on existing snapshots for non-active contexts.

### Key Files

- `lib/presentation/pages/chat_page/chat_page_scaffold.dart`
- `lib/presentation/providers/chat_provider.dart`
- `lib/presentation/pages/chat_page/chat_page_workspace_controller.dart`
- `test/widget/chat_page_test.dart`

---

## ADR-023: Official OpenCode Contract-First Compatibility Policy (2026-03-02)

**Status**: Accepted

### Context

CodeWalk's behavior must stay synchronized with official OpenCode server API and event semantics to prevent regressions and fragmentation. Lifecycle drift in areas like `prompt_async`, session state (`idle`/`busy`), and configuration mutation timing often causes subtle bugs that are difficult to debug when the client deviates from standard server expectations.

### Decision

1. **Contract First**: CodeWalk must follow official OpenCode server API/event semantics as the primary development constraint.
2. **Core Compatibility**: Client behavior must remain compatible with official OpenCode CLI and Web for core chat lifecycle semantics before adding app-specific behavior.
3. **Explicit Divergence**: Any intentional divergence from official semantics requires an explicit ADR exception including rationale, risk analysis, feature flag/rollback plan, and comprehensive tests.
4. **CI Enforcement**: Contract-breaking changes must be blocked in CI (hard fail) unless a documented ADR exception is approved.
5. **Evolution Policy**: Prefer additive and non-breaking evolution of the contract. Any removals or breaking semantic changes require a coordinated migration plan.

### Rationale

- **Regression Prevention**: Standardizing on the official contract reduces regressions caused by client/server lifecycle drift (e.g., `prompt_async` handling, session status transitions).
- **Ecosystem Alignment**: Ensures CodeWalk remains a first-class citizen in the OpenCode ecosystem, supporting features like cross-client session continuity.
- **Predictability**: Developers can rely on documented server behavior instead of guessing app-specific side effects.
- **Stability**: Hard-failing CI for contract breaks prevents accidental drift in high-velocity development.

### Consequences

- ✅ Significantly reduces regressions stemming from client-side lifecycle assumptions.
- ✅ Ensures long-term compatibility with official OpenCode server updates.
- ✅ Simplifies debugging by aligning client state transitions with server-authoritative events.
- ⚠️ May introduce friction when implementing app-specific optimizations that require non-standard API usage.
- ❌ Increases maintenance overhead for contract validation and CI enforcement.

### Reference Sources

These references are the first source of truth before implementing client behavior changes.

- **Local Docs**:
  - `ai-docs/opencode_server.md`
  - `ai-docs/opencode_web.md`
  - `ai-docs/opencode_models.md`
- **Official Docs**:
  - https://opencode.ai/docs/server/
  - https://opencode.ai/docs/web/
  - https://opencode.ai/docs/cli/
- **GitHub Sources (Canonical Behavior)**:
  - https://github.com/anomalyco/opencode
  - https://github.com/anomalyco/opencode/tree/dev/packages/opencode
  - https://github.com/anomalyco/opencode/tree/dev/packages/opencode/src/cli
  - https://github.com/anomalyco/opencode/blob/dev/packages/opencode/src/server/server.ts
  - https://github.com/anomalyco/opencode/tree/dev/packages/app
  - https://github.com/anomalyco/opencode/tree/dev/packages/opencode/src/cli/cmd/tui
- **Community / Non-Official Reference**:
  - https://github.com/openchamber/openchamber — community project, NOT an official OpenCode resource. Must never override official OpenCode docs/source. May be investigated as a secondary source for implementation details, working patterns, and bug/feature investigation ideas.

Related: ADR-003, ADR-018, ADR-019, ADR-022.

### Known Pitfalls

#### Pitfall P-001: Optimistic user message ID format (regression `b0660a2`, 2026-03-02)

**Summary**: Using a server-format ID (e.g. `msg_*`) for the optimistic user bubble, or forwarding `messageId` in the `prompt_async` send payload, breaks SSE event stream reconciliation for all conversation turns after the first — the UI update is silently discarded even though audio/notifications fire normally.

**Status (g4 update)**: g4 delivery maintains the provider-side `local_user_*` optimistic ID contract and does not forward `messageId` in `prompt_async`. This is the ADR-023-compliant baseline for CodeWalk until/unless a future ADR exception or upstream proof justifies official provider-side ID parity. Commits `5cabcf0` and `a066026` added regression coverage protecting refresh/reconcile from hiding active tool/work UI during optimistic echo replay.

**Symptom**: The app plays the "response completed" sound and notification for turns 2+, but the UI stays stuck on the previous state (e.g. "Reasoning...") — the new assistant response is received by the SSE stream but the UI update is silently discarded during merge. The session recovers only after a manual switch and return.

**Root cause**: The SSE merge logic uses the `local_user_*` prefix to identify optimistic bubbles that are candidates for duplicate-echo suppression. When the optimistic ID looks like a server message (`msg_*`), the prefix check short-circuits to `false` and the bubble is treated as a confirmed server message. On the next server event, the merge finds a conflict between the retained "server-looking" local message and the real server echo, causing the UI update for subsequent turns to be silently discarded.

**Invariant — do not violate**:
1. Optimistic user message IDs MUST use the `local_user_<timestamp>_<seq>` format.
2. The `messageId` field MUST NOT be forwarded in the `prompt_async` send payload.
3. Duplicate detection MUST use content-signature matching gated by the `local_user_` prefix check.

**Code locations** (see comments in source for details):
- `lib/presentation/providers/chat_provider.dart`:
  - `_nextLocalUserMessageId()`
  - `sendMessage()` → `ChatInput` construction (no `messageId` field)
- `lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart` → `_shouldSkipLocalUserAppendAsDuplicateEcho()`

**See also**: BEHAVIOR.md § "Optimistic user message ID uses local prefix — never server format".

### Exception EXC-001: Composer Permission Auto-Approve Toggle

**Status**: Approved ADR-023 exception.

**Summary**: CodeWalk exposes a composer-level toggle to the left of the agent selector that defaults to enabled, persists user opt-out, and auto-approves permission requests with `always` semantics when the request exposes it, otherwise falls back to `Allow Once`. Question prompts remain manual. The auto-approve behavior extends to the Android background worker continuity path, enabling pending permission resolution when the app resumes from background.

**Deviation from official behavior**: Official OpenCode currently keeps runtime permission-mode controls outside the composer and does not inherit permissive behavior across subagents/subsessions. CodeWalk intentionally extends auto-approval to the visible thread, including mirrored descendant/subsession permission requests surfaced in the root session, and prefers `always` when available to reduce repeated prompts. The Android background worker continuity path further extends this to background-collected permission requests when the app is resumed.

**Rationale**:
- Reduce repeated approval friction during active coding sessions.
- Keep the user in the root conversation while descendant permission prompts are mirrored there.
- Prefer `always` for durable permission grants when the request supports it; fall back to `Allow Once` for single-shot grants.
- Question prompts intentionally remain manual to preserve user control over non-permission decisions.
- Android background worker continuity: when the app returns from background, pending permissions collected during background status probes can be auto-approved without requiring the user to manually revisit each session, while still respecting the same `always`/`once` preference and cooldown logic.
- Background auto-approve uses the same drain coordinator semantics as foreground, ensuring consistent behavior across both paths.

**Risk analysis**:
- Medium UX/safety risk (foreground): mirrored descendant prompts can be approved without a second explicit tap in the child session.
- Medium UX/safety risk (background): the background worker may approve permissions for sessions that were active when the app entered background, even if the user has since switched contexts — mitigated by scoping the auto-approve context to the exact session/thread hierarchy present at prime time and requiring the same `composerAutoApprovePermissions` toggle.
- Low contract risk: the server still receives a normal permission reply payload (`always` or `once`), and question prompts keep the official manual path in both foreground and background paths.
- Low data-risk: the background context is cleared when the chat screen is left, when the toggle is disabled, or when the device switches away from the active server.

**Rollback / feature-flag plan**:
- Immediate rollback (foreground): user disables the composer toggle locally.
- Immediate rollback (background): user disables the composer toggle locally — the background context is cleared on the next lifecycle event.
- Product rollback: revert the composer toggle and drain coordinator commits; the background context key (`codewalk.android.background.permission_auto_approve.v1`) is removed from SharedPreferences on clear.
- Safe fallback: existing inline permission cards remain available as the manual approval path in both foreground and background flows.

**`remember: true` with `always` permission replies**: When CodeWalk auto-approves a permission request using the `always` response type, it sends `remember: true` in the permission reply body per the documented OpenCode permission reply contract. This ensures the server persists the grant so that future identical permission requests from the same session hierarchy are automatically approved server-side, reducing repeated auto-approve round-trips. When the request exposes only `once` semantics, `remember` is omitted (or `false`), keeping the single-shot grant behavior.

**Regression coverage**:
- Widget coverage verifies default-on behavior, persisted opt-out, mirrored subsession auto-approval, and non-regression for question prompts.
- The drain coordinator uses `always` when available, otherwise `Allow Once`, and cools down requests that throw during auto-approval.
- Background worker tests verify that auto-approve is scoped to primed session IDs, respects 404 as success (already resolved), and correctly clears context on lifecycle changes.

**Code locations**:
- `lib/domain/entities/experience_settings.dart` — `composerAutoApprovePermissions` toggle entity
- `lib/presentation/providers/settings_provider.dart` — toggle state and persistence
- `lib/presentation/services/permission_auto_approve_runtime.dart` — shared `permissionAutoApproveReplyForAlwaysPatterns`, `PermissionAutoApproveBackgroundContext`, `collectThreadSessionIds`, `resolveThreadSessionIdsForBackgroundContext`
- `lib/presentation/services/android_background_alert_worker.dart` — background auto-approve execution via `_runPermissionAutoApproveDrain`; context prime/clear via `primePermissionAutoApproveContext`/`clearPermissionAutoApproveContext`; feature flag key `codewalk.android.background.permission_auto_approve.v1`
- `lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart` — toggle UI widget
- `lib/presentation/pages/chat_page/chat_page_lifecycle.dart` — `_backgroundPermissionAutoApproveContextSignature` lifecycle management, `_scheduleAutoApprovePermissionDrain` coordinator

---

## ADR-024: Modal Enter Keyboard Policy (2026-03-25)

**Status**: Accepted

### Context

Users expect to confirm simple, non-destructive dialogs with the Enter key
without reaching for the mouse or tapping the primary button. CodeWalk already
implements this pattern locally in Quick Open, but the behavior was not
consistent across other safe dialogs.

The app also includes modal surfaces where Enter-confirmation is inappropriate:

- destructive confirmations should require deliberate confirmation;
- shortcut-capture dialogs must receive raw Enter keystrokes;
- multiline canned-answer editing needs Enter for line breaks; and
- picker/search/selector bottom sheets use Enter for navigation or selection.

### Decision

Non-destructive dialogs with **a single, unambiguous primary action** may
respond to `Enter` and `NumpadEnter` to trigger that action.

The following modal categories are explicitly excluded from this policy:

- **Destructive confirmations** — delete/reset/eject style dialogs must not map
  Enter to the irreversible action by default.
- **Shortcut-capture dialogs** — dialogs that record keyboard shortcuts must not
  intercept Enter before capture is completed intentionally.
- **Multiline canned-answer editing** — dialogs where Enter is part of text
  editing must preserve newline behavior.
- **Picker/search/selector bottom sheets** — sheets that use Enter for item
  navigation or selection remain manual unless redesigned for keyboard-first
  confirmation.

### Key Files

- `lib/presentation/widgets/modal_primary_action_shortcuts.dart`

### Rationale

- **Ergonomics**: desktop and external-keyboard users can confirm safe dialogs
  faster.
- **Clarity**: the rule is easy to apply - safe single-action dialogs may opt
  in, excluded categories stay manual.
- **Consistency**: the reusable wrapper keeps the keyboard behavior explicit and
  centralized.
- **Safety**: the exclusion list prevents accidental destructive confirmations
  or conflicts with text editing and key capture.

### Consequences

- Eligible dialogs can opt into Enter/NumpadEnter confirmation with a single
  reusable wrapper.
- New modal surfaces must be evaluated against the exclusion list before adding
  Enter support.
- Destructive confirmations, shortcut capture, multiline canned-answer editing,
  and picker/search/selector bottom sheets remain manual until a future ADR
  changes the policy.

### ADR-023 Compatibility

This policy is additive and local to Flutter keyboard routing. It does not
change OpenCode server behavior, API contracts, realtime lifecycle, or model
semantics, so no ADR-023 exception is required.

### Code Locations

- `lib/presentation/widgets/modal_primary_action_shortcuts.dart`
- `lib/presentation/pages/chat_page/chat_page_workspace_controller.dart`
- `lib/presentation/widgets/chat_session_list.dart`
- `lib/presentation/pages/onboarding_wizard_page.dart`
- `lib/presentation/widgets/moonshine_model_download_dialog.dart`
- `lib/presentation/widgets/sherpa_model_download_dialog.dart`

## ADR-025: Settled Assistant-Work Disclosure Ownership (2026-04-01)

### Status

Accepted

### Context

Repeated regressions have shown that BEHAVIOR.md invariants alone are insufficient to prevent open/close thrash of the latest assistant-work group. Repeated scroll jumps and final-message unreadability on both mobile and desktop indicate a need for architectural ownership of disclosure state — not just behavioral documentation.

Scope is limited to **client-side disclosure ownership** for the latest settled assistant-work group in chat.

### Decision

1. **Settled disclosure ownership** belongs to the latest assistant-work group that has been explicitly revealed or collapsed by the user or by a structural visibility change.

2. **Passive data inputs only**: `session.status`, background refresh, and revalidation are data inputs only. They must **not** by themselves reopen or re-collapse a settled latest assistant-work group.

3. **On session return**, settled disclosure ownership must be **reconstructed from the currently visible message structure** before any passive busy pulse can influence viewport or collapse policy.

4. **Only the following may clear settled ownership**:
   - A newer revealable assistant message
   - A newer user turn
   - A structural visibility change that removes the group

### Rationale

- Prevents repeated open/close thrash during passive refresh cycles.
- Ensures final-message readability by stabilizing the latest group state.
- Eliminates scroll jumps on both mobile and desktop during session return.
- Architectural ownership is more robust than invariant documentation for this class of regression.

### Consequences

- ✅ Positive: Stable disclosure behavior across session return, background refresh, and revalidation cycles.
- ✅ Positive: Eliminates thrash and scroll jumps for the latest assistant-work group.
- ⚠️ Warning: Any new passive data pipeline that influences viewport must be audited against this rule.
- ⚠️ Warning: Structural visibility changes (e.g., group removal) must explicitly clear ownership — no implicit side effects.
- ❌ Trade-off: Older groups do not receive this protection; only the latest settled group is scoped.

### ADR-023 Compatibility

This ADR is fully compatible with ADR-023 and official OpenCode lifecycle semantics. It introduces no server contract change, no custom busy protocol, and no deviation from the OpenCode message lifecycle. All state is client-side reconstruction from existing message structure.

**Note** (commit `9284223`): Session return and app-resume restore behavior refined for cached sessions:
1. **Cached settled session switch/return** — reveals the latest assistant response (disclosure ownership preserved, viewport positioned on final message).
2. **Cached active session switch/return** — lands at bottom to follow ongoing streaming activity.
3. **App-resume restore waits for refresh completion** — scroll/restore consumption is deferred until background refresh finishes, preventing stale viewport reconstruction.
4. **Passive refresh callbacks promote queued latest-response restore** — instead of defaulting to bottom-following, the passive refresh callback promotes the previously queued latest-response reveal, ensuring the user sees the most recent settled content.

---

## ADR-026: Cross-Platform Terminal Workspace with Local PTY Shell (2026-04-03) ⚠️ SUPERSEDED by ADR-027

**Status**: Superseded

### Context

CodeWalk provides a chat-based UI for interacting with OpenCode servers, but some workflows benefit from direct shell access in the active project directory. Users on both desktop and mobile need a way to open a local PTY terminal without leaving the chat workspace. The feature must preserve ADR-023 parity by remaining entirely client-side — no server contract changes, no new endpoints, and no deviation from OpenCode lifecycle semantics.

### Decision

1. **Cross-platform local PTY shell**: On all supported platforms (Linux, macOS, Windows, Android), CodeWalk spawns a local PTY shell process rooted in the active project directory, displayed in an embedded terminal panel within the chat workspace.
2. **No server API changes**: The terminal is a purely local shell — it does not invoke `opencode attach` or any OpenCode CLI command. No new endpoints, events, or server-side behavior changes are required.
3. **Project directory integration**: The shell launches in the active project's working directory (the `scopeId` from the current `serverId::scopeId` context), giving users immediate access to the files and tools relevant to their conversation.
4. **Panel lifecycle with explicit actions**:
   - **Stop**: fully closes the terminal panel and terminates the running PTY process.
   - **Hide**: minimizes the panel without stopping the shell — the session persists and can be restored.
   - **Maximize/Restore**: toggles the terminal between a compact inline panel and a maximized full-workspace view.
5. **Composer visibility on compact/mobile**: On compact and mobile layouts, the composer input area is hidden while the terminal panel is open, freeing vertical space for the embedded shell. The composer reappears when the terminal is hidden or stopped.
6. **Local shell prerequisite**: The terminal uses the platform's default shell (`$SHELL` on Unix, PowerShell/CMD on Windows). No external command path configuration is required.

### Rationale

- Direct shell access in the project directory supports workflows like git operations, build commands, file inspection, and quick edits that complement the AI-driven chat conversation.
- Launching from within the chat workspace keeps the terminal discoverable and close to the conversation that is driving the work.
- A local PTY shell is simpler and more general-purpose than `opencode attach` — it works without requiring the OpenCode CLI to be installed locally and gives users full shell capability.
- No server API changes means zero contract risk and full ADR-023 compliance.
- Keeping the terminal panel client-owned preserves a simple boundary: CodeWalk manages PTY lifecycle locally while the OpenCode server remains the source of truth for shared sessions and state.
- Extending to mobile/compact layouts follows the project's mobile-first UX principle — users deserve the same embedded shell capability regardless of device, with layout-adaptive behavior (composer hide, maximize/restore) to fit smaller viewports.
- Explicit stop vs. hide semantics prevent ambiguity: users know whether they are closing the session or just minimizing it.

### Consequences

- ✅ All platforms (desktop + Android) get a local shell in the active project directory without leaving CodeWalk.
- ✅ Zero server API changes — fully compatible with ADR-023 contract-first policy.
- ✅ No external CLI dependency — uses the platform's default shell.
- ✅ Hide/restore preserves the current shell session during the active chat screen lifetime.
- ✅ Stop provides a clean, unambiguous way to fully close the panel and kill the process.
- ✅ Maximize/restore gives flexible viewport control on all screen sizes.
- ✅ Composer auto-hide on compact/mobile layouts prevents cramped UX and maximizes terminal space.
- ⚠ The shell runs with the user's local environment and permissions — CodeWalk does not sandbox or restrict shell access.
- ⚠ Long-running background processes in the shell are not managed by CodeWalk lifecycle and may outlive the chat session.
- ⚠ Mobile/compact layouts sacrifice composer visibility while the terminal is open — users must hide/stop the terminal to resume chat composition.
- ❌ None — previous mobile informational fallback has been replaced with full embedded terminal support.

### Key Files

- `lib/presentation/services/codewalk_terminal_controller.dart`
- `lib/presentation/services/codewalk_terminal_process.dart`
- `lib/presentation/services/codewalk_terminal_process_io.dart`
- `lib/presentation/widgets/codewalk_terminal_panel.dart`
- `lib/presentation/pages/chat_page/chat_page_terminal_runtime.dart`
- `lib/presentation/providers/project_provider.dart` (active project directory access)

### ADR-023 Compatibility

This feature is fully compatible with ADR-023. It introduces no server contract changes, no new API endpoints, and no deviation from OpenCode lifecycle semantics. It is a purely client-side terminal surface that spawns a local PTY shell in the active project directory, leaving session/state ownership entirely with the official OpenCode server.

---

## ADR-027: Server-Hosted PTY Terminal with Embedded Client Rendering (2026-04-03)

**Status**: Accepted

**Supersedes**: ADR-026 (Cross-Platform Terminal Workspace with Local PTY Shell)

### Context

ADR-026 specified a local PTY shell spawned on the client device using `flutter_pty`. This approach has fundamental limitations: it requires native PTY libraries on every platform (including Android), ties terminal availability to the client's local environment, and cannot leverage the OpenCode server's project directory context. The architecture has been rewritten to use a server-hosted PTY that runs on the OpenCode host in the active project directory, with the client rendering terminal output via an embedded terminal panel over a streaming transport.

### Decision

1. **Server-hosted PTY**: The PTY shell process runs on the OpenCode server host, rooted in the active project directory. The client no longer spawns local shell processes.
2. **Client rendering via embedded terminal panel**: The Flutter client renders terminal output using an embedded terminal panel (xterm.js-compatible rendering), receiving streaming data from the server over WebSocket/SSE transport.
3. **Local `flutter_pty` shell removed**: All `flutter_pty` dependencies, platform-specific PTY spawning code, and local shell lifecycle management are removed from the client codebase.
4. **Panel lifecycle semantics preserved**:
   - **Close**: terminates the server-side PTY session and removes the panel.
   - **Minimize**: hides the panel without terminating the server-side session — can be restored.
   - **Maximize**: toggles between compact inline panel and full-workspace view.
5. **Composer auto-hide on compact/mobile**: On compact and mobile layouts, the composer input area is hidden while the terminal panel is open. The composer reappears when the terminal is minimized or closed.
6. **Project directory integration**: The server-side PTY launches in the active project's working directory (the `scopeId` from the current `serverId::scopeId` context), ensuring the shell operates in the same workspace the chat conversation is about.
7. **No server API contract changes**: The terminal transport reuses existing OpenCode streaming infrastructure (WebSocket or SSE). No new dedicated terminal endpoints are introduced — the server exposes PTY data through the established event stream contract.

### Rationale

- **Server-hosted PTY matches the OpenCode model**: The server already owns the project directory context, environment, and toolchain. Running the shell there eliminates client-side environment variability and ensures the terminal operates in the same context as the AI agent.
- **Removes native dependency burden**: `flutter_pty` requires platform-specific native compilation (C libraries, NDK for Android, etc.). Server-hosted PTY shifts this complexity to the server, which already has a full POSIX environment.
- **Unified experience across all clients**: Desktop, mobile, and web clients all get the same terminal capability without platform-specific code paths or feature parity gaps.
- **Preserves UX semantics**: Close/minimize/maximize and composer auto-hide behaviors from ADR-026 are retained — only the execution location changes.
- **ADR-023 alignment**: By reusing existing OpenCode streaming transport rather than introducing new endpoints, this decision stays within the contract-first policy. The server's PTY is an extension of its existing workspace management, not a new API surface.

### Consequences

- ✅ Terminal works identically on all client platforms (desktop, mobile, web) with no platform-specific native dependencies.
- ✅ Server-side PTY runs in the correct project environment with full toolchain access.
- ✅ Removes `flutter_pty` native compilation complexity from the client build pipeline.
- ✅ Close/minimize/maximize semantics and composer auto-hide on compact/mobile are preserved.
- ✅ No new server API endpoints — reuses existing streaming transport, maintaining ADR-023 compliance.
- ⚠ Terminal availability depends on the OpenCode server supporting PTY sessions — clients connecting to servers without this capability must show a graceful fallback.
- ⚠ Network latency affects terminal responsiveness compared to local PTY — acceptable for interactive use but may feel less snappy than ADR-026's local shell.
- ⚠ Server resource usage increases (one PTY process per active terminal session per client).
- ❌ Offline terminal access is no longer possible — the terminal requires an active server connection.

### Key Files

- `lib/presentation/services/codewalk_terminal_controller.dart` — client-side terminal lifecycle and state orchestration
- `lib/data/datasources/terminal_remote_datasource.dart` — remote PTY session API calls
- `lib/data/models/pty_session_model.dart` — PTY session data model and serialization
- `lib/presentation/services/codewalk_terminal_socket.dart` — WebSocket transport contract
- `lib/presentation/services/codewalk_terminal_socket_io.dart` — IO platform WebSocket implementation
- `lib/presentation/services/codewalk_terminal_socket_stub.dart` — web/no-op stub
- `lib/presentation/services/codewalk_terminal_url.dart` — terminal endpoint URL resolution
- `lib/presentation/widgets/codewalk_terminal_panel.dart` — embedded terminal panel UI
- `lib/presentation/pages/chat_page/chat_page_terminal_runtime.dart` — chat page terminal integration
- `lib/presentation/providers/project_provider.dart` (active project directory access)

### ADR-023 Compatibility

This feature is fully compatible with ADR-023. It reuses existing OpenCode streaming transport (WebSocket/SSE) for terminal I/O rather than introducing new API endpoints or contract changes. The server-side PTY is an extension of the server's workspace management, and the client acts purely as a rendering surface — session/state ownership remains entirely with the official OpenCode server. No divergence from official OpenCode CLI/Web lifecycle semantics is introduced.

---

## ADR-028: Unified Scroll Ownership Model for Chat Timeline (2026-04-04)

**Status**: Accepted

### Context

The chat timeline experienced recurrent scroll jumping across three trigger scenarios: user sending a message, app returning from background, and scrolling to load older messages. Multiple targeted fixes over time addressed individual scroll paths but the bug kept returning because each fix addressed one scroll owner without coordinating across all competing scroll sources. Five concurrent scroll owners (`_handleScrollMetricsChanged` snap, `_runScrollToBottom`, `_revealLatestMessageReturnReveal`, `_loadOlderMessagesAndRestoreAnchor`, and provider `_scheduleScrollToBottom`) raced against each other without a unified priority system.

### Decision

1. **Unified scroll ownership via `_ScrollOwner` enum** — `none`, `userDrag`, `paginationRestore`, `newMessage`, `streaming`, `returnReveal`, `contentShrinkSnap` replacing scattered boolean coordination
2. **Hardened `_handleScrollMetricsChanged` content-shrink snap gates** — blocks on return reveal in-flight, pagination restore in-flight, and any non-none scroll owner
3. **Serialized background resume scroll actions** — `_handleReturnToChat` defers reveal via `addPostFrameCallback` with mounted guard to avoid racing with provider-triggered scrolls
4. **`_runScrollToBottom` gates on `_currentScrollOwner == userDrag`** for non-force scrolls, preventing scroll hijacking during user drag
5. **`_lastKnownMaxScrollExtent` update moved to end of handler** to avoid false "content grew" detection during transitions
6. **Timeline cache invalidation logging** for future diagnosis of unnecessary repaints

### Rationale

- A single source of truth for scroll ownership eliminates race conditions between competing scroll sources
- The enum approach is more maintainable than scattered boolean flags because it makes the ownership model explicit and prevents future regressions from new scroll paths being added without coordination
- PostFrameCallback deferral ensures the widget tree is stable before initiating scroll animations on background resume
- Force scrolls (user message send, FAB tap) bypass all gates to maintain responsiveness for explicit user actions

### Consequences

- ✅ Scroll jumping eliminated across all three trigger scenarios (send message, return from background, load older messages)
- ✅ Unified `_ScrollOwner` enum replaces scattered boolean coordination
- ✅ User drag always takes priority — programmatic scrolls defer until user releases
- ✅ Force scrolls (user message send, FAB tap) bypass all gates
- ✅ Timeline cache survives passive refresh pulses without invalidation
- ✅ Widget regression tests cover all identified race conditions
- ⚠ `_isProgrammaticScrollInFlight` and `_isReturnRevealInFlight` booleans kept for backward compatibility with final assistant reveal path — should be migrated to enum in future cleanup
- ⚠ Debug logging for owner transitions not yet added — would help trace ownership handoffs during scroll races

**Note** (commits `d1cb997`, `1395955`, `042705a`): Practical guardrails tightened around four scroll-race surfaces without changing the architectural contract:
1. **Passive provider scroll suppression** — provider-triggered scroll-to-bottom requests are now suppressed when the user is actively reading near the bottom edge, preventing viewport jumps from background SSE pulses.
2. **Manual follow pause near bottom** — when the user manually scrolls near the bottom (within a small threshold), auto-follow is paused to avoid fighting intentional user positioning.
3. **Response-settle shrink-snap suppression** — content-shrink snap is suppressed during the response-settle window after a streaming response completes, preventing the viewport from jumping when the message bubble collapses from streaming to settled layout.
4. **Duplicate return-to-chat debounce scoping** (`042705a`) — the return-to-chat debounce was narrowed to deduplicate only identical signatures (same trigger source + same timestamp window), preventing unrelated return-to-chat calls from being incorrectly coalesced.

**Note** (commit `9284223`): Cached session restore now uses a single queued restore target instead of an unconditional reopen bottom snap:
1. **Settled cached restore reveals the latest assistant response** — cached session switch/return restores directly to the latest revealable assistant response instead of always snapping to bottom.
2. **Active cached restore still lands at bottom** — cached sessions that are still processing keep bottom-follow behavior.
3. **Resume restore waits for refresh completion** — app-resume restore consumption is deferred until resume revalidation finishes, so refreshed settled content is revealed once instead of bottom-snapping before the newer tail appears.
4. **Passive refresh promotion respects queued latest-response restore** — passive refresh callbacks promote a queued latest-response restore for that same session instead of requesting a competing bottom-follow scroll.

**Note** (commit `161b9ce`): Passive background reconcile now keeps the active-turn lock and scopes unsupported message fallback more narrowly:
1. **Current-session active-turn detection resists transient idle pulses** — a current-session send in progress or incomplete assistant message keeps the session in responding mode even if `session.status` briefly reports `idle` first.
2. **Unsupported global `message.*` fallback only refreshes the visible session when explicitly targeted** — active-context fallback reconcile for unsupported message events is now scoped to the current session id, and it is suppressed while a local stream or compaction guard is active.
3. **Passive latest-message signal remains semantic, not a settle override** — settled passive refreshes may still report a latest-message change for unread/latest affordances, but they no longer depend on transient idle status to unlock final reveal or collapse.

**Note** (commits `81edb30`, `4aa9a00`): Active-turn follow and final reveal were simplified for the remaining live-turn jitter/reveal bugs:
1. **Passive provider re-entry is suppressed during active response while still preserving unread/latest affordances after manual follow pause** — active turns no longer perform visible per-tool-call bottom corrections when the user is already passively following.
2. **Growth-time bottom snap keeps active turns visually pinned** — streamed tool/reasoning/text growth uses a runtime bottom snap while actively responding instead of repeated animated correction churn.
3. **Final assistant reveal uses a single reading-mode reveal** — the extra corrective final reveal pass was removed, and long final answers now enter reading mode instead of remaining pinned to bottom.
4. **Final reveal skips when the whole answer already fits and otherwise targets the clarified mid-screen contract** — the viewport math only runs when the full final message would not already be fully visible.
5. **Final reveal viewport math is guarded by mounted/hasSize checks** (`4aa9a00`) — fast navigation/unmount races now reschedule instead of touching invalid render contexts.

**Note** (commits `80ad3a5`, `49c0f7d`): Active-turn assistant work rendering now defers synthetic tool-only merge until settlement:
1. **Raw tool-call bubbles remain visible during the active turn** — consecutive tool-only assistant messages are rendered as separate entries while the current run is still responding.
2. **Synthetic tool-only merge now happens only after settlement** — merged tool-run bubbles remain a settled/history presentation and are no longer used as a live-turn optimization.
3. **Active-turn assistant entrance animation suppression is scoped to tool-only bubbles** (`49c0f7d`) — the final assistant text response may still animate normally once the turn settles.
4. **Active-turn structural shrink is treated as a forbidden regression source** — live tool-only merge/replacement during the active run is no longer allowed because it can shorten the rendered list above the viewport, create a temporary bottom vacuum, and amplify typing/repaint churn.

**Note** (commit `0b1e5a6`): Active-turn shrink healing now closes the remaining bottom-vacuum gap without fighting manual reading:
1. **Passive-follow active turns may heal shrink immediately** — when the user is still passively following the active turn, a non-animated bottom-anchor heal may run on content shrink to remove a temporary blank vacuum.
2. **Manual scroll-away still wins** — the active-turn shrink heal is gated behind auto-follow/manual-pause state so it does not yank the viewport back after the user leaves the bottom.
3. **Active-turn tool-chain size animation is disabled** — the tool-chain body no longer uses `AnimatedSize` while the session is actively responding, reducing shrink/reflow churn and typing lag.

### Key Files

- `lib/presentation/pages/chat_page.dart` — `_ScrollOwner` enum definition, `_currentScrollOwner` state field, `_setScrollOwner()` helper
- `lib/presentation/pages/chat_page/chat_page_runtime_support.dart` — `_handleScrollMetricsChanged` hardened gates, `_runLatestMessageReturnReveal` owner integration
- `lib/presentation/pages/chat_page/chat_page_scroll_coordinator.dart` — `_handleScrollChanged` user drag detection, `_runScrollToBottom` owner gates, `_loadOlderMessagesAndRestoreAnchor` owner integration
- `lib/presentation/pages/chat_page/chat_page_lifecycle.dart` — `_handleReturnToChat` PostFrameCallback deferral with mounted guard
- `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart` — cache invalidation logging
- `test/widget/chat_page_test.dart` — 2 new regression tests for scroll stability and cache reuse

---

## ADR-029: Host-Discovered Quota and Rate-Limit Monitoring for OpenChamber Parity (2026-04-09)

**Status**: Accepted

### Context

CodeWalk requires visibility into model quotas and rate-limits to prevent silent task failures due to exhausted provider balances. While official OpenCode (ADR-023) provides the core agent contract, it does not currently expose a unified real-time quota/rate-limit API for all backend providers. OpenChamber, as a community-driven server implementation, provides extended REST endpoints for this purpose. CodeWalk aims for functional parity with OpenChamber's monitoring capabilities while maintaining strict adherence to official OpenCode contracts as the primary source of truth.

### Decision

1. **Server-Host-Only Quota Ownership** — The app never manages or stores provider credentials for quota checking. It relies entirely on the connected host's environment and discovered provider configurations.
2. **Strategy-Chain Transport** — Quota data is fetched using a tiered discovery strategy:
    - **OpenChamber REST** — Use `GET /api/v1/quota` and related endpoints when detected.
    - **Hidden Shell Fallback** — Fall back to execution of provider-specific CLI tools (e.g., `openai-quota`, `anthropic-limit`) via the existing server-hosted PTY transport (ADR-027) when REST endpoints are missing.
3. **Popup-Only UI (Compact-First)** — The monitoring interface is restricted to the "Context usage" popup. It is hidden by default in compact/mobile layouts to preserve composer real-estate, appearing only on explicit user invocation.
4. **Grouped Providers with Pace/Progress Semantics** — UI displays providers grouped by parent organization (OpenAI, Anthropic, etc.) using progress bars that reflect both absolute remaining quota and "Pace" (usage rate over time) to warn of imminent rate-limiting.
5. **Explicit Feature-by-Feature Parity Opt-in** — Future OpenChamber features will not be auto-adopted. Each parity addition must be explicitly evaluated, documented via ADR, and gated behind feature-specific capability checks.

### Rationale

- **ADR-023 Priority** — Official OpenCode remains the primary contract. OpenChamber parity is additive and must never conflict with official lifecycle or API semantics.
- **Security** — By enforcing server-host ownership, the client avoids the risk of credential leakage and maintains the security boundaries established in ADR-001.
- **Resilience** — The strategy-chain ensures monitoring works across both official servers (via shell fallback) and OpenChamber-enhanced servers (via REST).
- **UX** — Grouping and Pace semantics provide actionable insights rather than just raw numbers, helping users manage long-running agent tasks.

### Consequences

- ✅ Real-time visibility into provider limits prevents unexpected agent stalls.
- ✅ Near-zero-credential client simplifies onboarding and improves security (narrow opt-in exception for `opencode-go` dashboard cookie only).
- ✅ Graceful degradation between OpenChamber REST and official shell-only hosts.
- ⚠️ Potential performance impact when using shell fallback (process spawn overhead on server).
- ⚠️ UI density in the Context popup increases; requires careful MD3/Material You spacing.
- ❌ No offline quota visibility; requires active server connection.
- ⚠️ `opencode-go` dashboard credential opt-in stores an auth cookie client-side; mitigated by opt-in gate, `serverId` scoping, quota-probe-only use, and UI removability.

### Key Files

- `lib/data/datasources/quota_remote_datasource.dart` — Strategy-chain implementation (OpenChamber REST → shell fallback)
- `lib/domain/entities/quota.dart` — Domain entities: `QuotaSnapshot`, `UsageWindow`, `PaceInfo`, `QuotaEntry`, `QuotaProviderGroup`
- `lib/presentation/providers/quota_provider.dart` — Polling, TTL cache, server-scoped state, and provider grouping
- `lib/presentation/utils/quota_pace_utils.dart` — Pure Dart pace calculation, window label inference, and formatting
- `lib/presentation/widgets/quota/quota_popup_section.dart` — Root quota widget embedded in the Context usage popup
- `lib/presentation/widgets/quota/quota_provider_group_row.dart` — Grouped provider expand/collapse row
- `lib/presentation/widgets/quota/quota_entry_row.dart` — Individual quota entry with severity color progress bar
- `lib/presentation/widgets/quota/pace_label.dart` — Desktop tooltip / mobile snackbar pace explanation
- `lib/presentation/pages/chat_page/chat_page_status_presenter.dart` — Hosts `_buildContextUsagePopover` which includes `QuotaPopupSection`
- `lib/core/di/injection_container.dart` — DI wiring for `QuotaRemoteDataSource` and `QuotaProvider`

### Exception: OpenCode Go Dashboard Credential Opt-In

OpenCode Go does not expose a quota API usable via the standard OpenCode Go API key. When `opencode-go` is detected as the server type, the strategy-chain (Decision §2) has no REST or shell endpoint to probe for dashboard quota data. To preserve the user's ability to monitor quotas on OpenCode Go hosts, a narrow explicit exception is added:

1. **Opt-In Only** — When `opencode-go` is detected, the app presents a one-time opt-in prompt explaining that the OpenCode Go dashboard workspace ID and auth cookie are required for quota probing. The user must explicitly consent; nothing is stored without consent.
2. **Minimal Credential Set** — Only two values are stored: the OpenCode Go dashboard workspace ID and the dashboard auth cookie. No passwords, tokens, or other secrets.
3. **Existing Secure Storage** — Credentials are stored in CodeWalk's existing secure credential storage (ADR-001), scoped by `serverId` to prevent cross-server leakage. No new storage mechanism is introduced.
4. **Quota-Probe Only** — The stored workspace ID and auth cookie are used exclusively for quota probing against the OpenCode Go dashboard. They are never transmitted to any other endpoint, never logged, and never included in error reports or analytics.
5. **UI Removability** — The user can clear the stored credentials at any time via the existing server settings UI. Removal immediately disables quota probing for that server.
6. **No Logging** — The auth cookie and workspace ID are treated as secrets at the same level as server API keys. They are excluded from all log output, crash reports, and debug surfaces.

**Rationale**: The OpenCode Go API key does not grant access to dashboard quota data. Without this exception, `opencode-go` users would have zero quota visibility — a functional regression vs. OpenChamber and shell-fallback hosts. The opt-in gate, minimal scope, existing secure storage, and removability ensure this exception does not erode the security posture established by ADR-001 and ADR-023.

### ADR-023 Compatibility

This feature is compliant with ADR-023. Official OpenCode remains the primary source for all agent contracts and core app behavior. OpenChamber is used exclusively as an optional parity source for the quota/rate-limit feature. In the absence of OpenChamber REST endpoints, the app falls back to a hidden ephemeral shell probe without PTY process lifecycle changes, ensuring no divergence from official server capabilities.

**Exception for `opencode-go`**: The OpenCode Go Dashboard Credential Opt-In (above) stores a dashboard auth cookie and workspace ID in existing secure credential storage, scoped by `serverId`, used exclusively for quota probing. This is a narrow, opt-in exception to the server-host-only credential ownership rule (Decision §1). It does not alter any OpenCode agent contract, lifecycle, or API semantic. The cookie is never forwarded to any OpenCode endpoint beyond the dashboard's quota probe path, preserving ADR-023's non-regression guarantee.

### Post-Mortem: Shell Transport Truncation & API Proxying

During the implementation of the shell fallback, a critical flaw was discovered in the OpenCode `POST /session/:id/shell` endpoint. When multiline scripts using bash heredocs (`node <<'NODE' ... NODE`) or conditional blocks (`if ... fi`) were sent, the shell evaluation engine prematurely truncated the payload. This resulted in `unexpected end of file` or `SyntaxError` failures.

**Evolution of the Solution:**
1. **Initial Approach:** A full Node.js script was sent as a heredoc script to read `auth.json` and make `fetch()` HTTP calls to provider APIs (Anthropic, OpenRouter). Result: The script was truncated mid-way through.
2. **First Attempted Fix (Minimal JS):** The JavaScript was aggressively minimized into a one-liner without any `fetch()` logic, simply parsing `auth.json` and returning `usage: null` to prove the transport worked. Result: The transport worked (returned 5 raw results), but `QuotaProviderResult.hasVisibleData` relies on the `usage` object to group and display the providers. Because all providers returned `usage: null`, the interface showed "0 visible groups" and rendered nothing.
3. **Final Solution (Base64 One-Liner):** To restore the critical API-fetching logic without triggering the shell truncation bug, the full multi-provider JavaScript implementation was retained but minified aggressively. The entire JS string is now encoded into Base64 within Dart at compile time. The executed shell command is a strict one-liner:
   `node -e "eval(Buffer.from('BASE64_PAYLOAD','base64').toString())"`
   Result: The payload executes reliably on the host, properly queries remote provider APIs, formats the `hasVisibleData` structure, and bypasses the shell's AST parsing constraints entirely.

---

## ADR-030: OpenChamber-Driven Realtime Hardening and Permission Continuity (2026-04-18)

**Status**: Accepted

**Related**: ADR-003 (Realtime-First Sync), ADR-023 (OpenCode Contract), EXC-001 (Permission Auto-Approve)

### Context

High-latency or unstable connections during OpenChamber-driven sessions revealed edge cases in permission handling and session synchronization. Specifically, pending question/permission refreshes could race with active streams, user mutations (sends/deletes) were possible during confirmed realtime reconnect failures (risking state divergence), and pinned-session pruning occurred before authoritative session lists were fully loaded.

### Decision

1. **Safe Refresh Consolidation**: Merge pending question and permission refreshes into a single atomic lifecycle step that respects the active turn lock.
2. **Mutation Guard during Reconnect Failures**: Block user-initiated state mutations (send message, delete session, rename) when the realtime transport is in a confirmed `reconnecting` or `failed` state and the fallback polling path has not yet established a verified authoritative bridge.
3. **Authoritative Pruning Delay**: Delay the pruning of pinned or cached session references until the `loadSessions()` authoritative response is fully processed.
4. **Bounded One-Shot Reconnect Helpers**: Bounded the set of one-shot reconnect helpers to prevent memory growth during extended disconnection periods.

### Rationale

- Atomic refreshes prevent UI flickering and race conditions between competing permission/question events.
- Blocking mutations during confirmed disconnects prevents "ghost" state where the client accepts a change that the server never receives, protecting ADR-023 contract integrity.
- Authoritative pruning prevents "flickering" sessions where a pinned item disappears and reappears because the local cache was cleaned before the server confirmation arrived.
- Bounded helper sets ensure long-term stability in degraded network conditions.

### Consequences

- ✅ Improved stability during OpenChamber-driven high-latency sessions.
- ✅ Stronger ADR-023 compliance by preventing un-syncable local mutations.
- ✅ Eliminates UI flickering of pinned sessions during revalidation.
- ⚠️ Users see explicit "Connection unstable - actions disabled" state during reconnect failures.
- ❌ Mutation-only offline mode is intentionally not supported to preserve contract parity.

### Key Files

- `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_session_ops.dart`
- `lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart`

### ADR-023 Compatibility

This hardening is fully compliant with ADR-023. It enforces server-authoritative state by blocking local mutations when transport integrity is lost and ensures the client waits for authoritative server lists before modifying local visibility of pinned items.

---

## ADR-031: Historical Inline Revert via OpenCode Session Revert Endpoint (2026-05-21)

**Status**: Accepted

**Related**: ADR-023 (Official OpenCode Contract-First Compatibility Policy), ADR-020 (Session-Level SWR Cache), ADR-028 (Unified Scroll Ownership)

### Context

Users need the ability to rewind a conversation to a specific historical user message — undoing all subsequent turns (assistant responses, tool calls, follow-ups) and restoring the session state as it existed at that point. Without this capability, the only way to "undo" a conversation branch is to create a new session and re-prompt, losing all prior context and work.

OpenCode provides `POST /session/:id/revert` with a `messageID` body field. CodeWalk already used that endpoint for latest-turn Undo. Historical inline rewind extends the same official endpoint to any older server-confirmed user message, keeping the server authoritative for the revert boundary while reusing the existing refresh/reconcile path.

Key challenges:
- **In-flight operation protection**: Repeated rewind taps must not dispatch overlapping revert requests.
- **Local optimistic message guard**: Messages with `local_user_*` IDs are client-only artifacts that the server does not know about. They must not be exposed as rewind targets or sent to the server.
- **Composer draft restoration**: After a revert, the composer should restore the text that was present at the reverted-to user turn, enabling the user to continue from that point.
- **ADR-023 compliance**: The revert uses the official session revert endpoint; local visibility updates are an immediate reflection of the server revert boundary, not a replacement protocol.

### Decision

1. **Server-authoritative revert via `revertToTurn(messageId)`**: `ChatProvider.revertToTurn(String messageId)` calls the existing `RevertChatMessage` use case, which sends `POST /session/:id/revert` with the selected server-confirmed user `messageID`. The provider then applies `SessionRevert(messageId: messageId)`, queues composer draft restoration, refreshes the active session view, and reloads session insights.

2. **Inline historical user-message rewind trigger**: Each historical, server-confirmed user message in the chat timeline exposes a dedicated inline rewind action. The latest revertible user message keeps the existing inline Undo action. Assistant messages, non-user messages, and optimistic local user messages do not expose historical rewind.

3. **`_historyRevertInFlight` guard**: A boolean flag `_historyRevertInFlight` serializes calls to `revertToTurn`. While one revert call is in flight, subsequent `revertToTurn` requests return `false` without dispatching another server request. This narrowly prevents repeated-tap duplicate reverts without changing unrelated send, realtime, or revalidation behavior.

4. **`local_user_*` message guard**: The timeline builder only wires `onInlineRevertToHere` when the message is a `UserMessage`, is not the latest revertible message, and does not start with `local_user_`. The provider also rejects `local_user_*` IDs at the `revertToTurn` entry point so future callers cannot bypass the UI guard.

5. **Composer draft restoration**: After a successful revert, the provider restores the selected user message into the pending history composer sync via `_buildComposerDraftFromUserMessage`. The composer can then show the reverted prompt so the user can edit and resend from that point.

6. **Widget ownership**: `ChatMessageWidget` exposes an optional `onInlineRevertToHere` callback, includes that callback in its build-skip cache invalidation, and renders a distinct `settings_backup_restore` action labeled `Rewind and edit from here` when the callback is present and the latest Undo action is not shown.

7. **Permission remember companion fix**: For permission replies using `always`, CodeWalk sends `remember: true` in both the documented session-scoped reply body and the existing top-level legacy fallback. This implements ADR-023 EXC-001's durable-grant intent without changing question flows or non-`always` permission semantics.

### Rationale

- **Server-authoritative revert** follows ADR-023 contract-first policy by reusing `POST /session/:id/revert` instead of inventing client-only history truncation.
- **`_historyRevertInFlight`** prevents duplicate requests from repeated taps while keeping the change narrow and low risk.
- **`local_user_*` guard** is necessary because optimistic IDs are client-only artifacts. Sending them to the server would violate ADR-023 Pitfall P-001's ownership boundary.
- **Composer draft restoration** is a natural UX expectation: after rewinding, the user wants to continue from that point, not start from an empty composer.
- **Distinct inline action** avoids conflating latest-turn Undo with historical branch/rewind semantics.

### Consequences

- ✅ Users can rewind conversations to historical server-confirmed user messages through the official session revert endpoint.
- ✅ ADR-023 compliance maintained: the server owns the revert boundary and the client refreshes from that authoritative state.
- ✅ `_historyRevertInFlight` guard prevents duplicate historical revert requests.
- ✅ `local_user_*` messages are excluded in both UI wiring and provider entry-point validation.
- ✅ Composer draft restoration enables seamless continuation after rewind.
- ⚠ The revert operation is network-dependent; offline or disconnected sessions cannot be rewound until connectivity is restored.
- ⚠ `_historyRevertInFlight` adds another state flag to the chat provider; it must remain tightly scoped to revert dispatch unless a future ADR expands history-action serialization.
- ❌ Local-only message truncation (client-side rewind without server) is intentionally not supported to preserve ADR-023 contract integrity.

### ADR-023 Compatibility

This feature is fully compliant with ADR-023. The revert uses the official OpenCode `POST /session/:id/revert` endpoint as the server-authoritative history operation. The client never introduces a separate local-only rewind protocol. The `local_user_*` ID guard (Pitfall P-001) is respected in both timeline wiring and provider validation. No new API endpoints or contract deviations are introduced.

### Key Files

- `lib/presentation/providers/chat_provider.dart` — `revertToTurn`, `_historyRevertInFlight`, `local_user_*` guard, composer draft restoration, and refresh/insights reload after revert
- `lib/domain/usecases/revert_chat_message.dart` — use case boundary for `POST /session/:id/revert`
- `lib/data/datasources/chat_remote_datasource.dart` — session revert API call and permission `remember: true` reply payloads
- `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart` — historical server-confirmed user-message callback wiring
- `lib/presentation/widgets/chat_message_widget.dart` — optional `onInlineRevertToHere` callback and rebuild cache invalidation
- `lib/presentation/widgets/chat_message/chat_message_content.dart` — inline rewind action rendering

---

## ADR-032: LaTeX Math Rendering with flutter_math_fork and Custom Markdown Delimiters (2026-05-26)

**Status**: Accepted

**Related**: ADR-007 (Modular Settings Architecture), ADR-004 (Chat Architecture with Slim Orchestrators and Decomposed Clusters)

### Context

CodeWalk v1.83.0 introduced LaTeX math rendering so that mathematical expressions in chat messages render as properly typeset formulas instead of raw LaTeX source text. This is essential for users working with LLMs on math-heavy topics (physics, engineering, statistics, formal methods).

Key challenges:
- **Library selection**: Most Dart math rendering libraries are either unmaintained, platform-dependent (WebView-based), or have limited LaTeX coverage. A pure-Dart solution is preferred to avoid WebView overhead and ensure consistent behavior across desktop and mobile.
- **Markdown delimiter integration**: Chat messages are parsed as Markdown. Math delimiters (`$...$` for inline, `$$...$$` for display) must be recognized before or alongside standard Markdown parsing without conflicting with existing syntax (code spans, emphasis, etc.).
- **Graceful fallback**: When rendering fails (unsupported LaTeX command, malformed input), the user should see a styled fallback rather than a broken widget or crash.
- **User toggle**: Math rendering is a visual preference. Some users prefer raw LaTeX for copy-paste or screen-reader compatibility. A toggle must exist in experience settings.
- **Performance**: Math rendering is computationally heavier than plain text. It must not block the chat timeline scroll or cause jank on long sessions with many expressions.

### Decision

1. **`flutter_math_fork` as the rendering engine**: Use the `flutter_math_fork` package — a pure-Dart port of KaTeX — for all LaTeX math rendering. This avoids WebView dependencies, works identically on all Flutter platforms, and provides broad LaTeX coverage aligned with KaTeX's well-tested subset.

2. **Custom Markdown delimiters**: Extend the Markdown parser to recognize `$...$` (inline math) and `$$...$$` (display/block math) as custom syntax elements. These delimiters are extracted before standard Markdown processing to prevent conflicts with code spans (`` ` ``) and emphasis (`*`/`_`). Inline math renders within the text flow; display math renders as a centered block.

3. **`MathExpressionWidget` with styled fallback**: A dedicated `MathExpressionWidget` wraps the `flutter_math_fork` render call. On successful parse, it renders the typeset formula. On parse failure, it displays the raw LaTeX source in a monospaced, subtly styled container (e.g., with a light background tint) so the user can still read and copy the expression without UI breakage.

4. **`showMathRendering` toggle in `ExperienceSettings`**: Add a boolean `showMathRendering` field to `ExperienceSettings` (ADR-007). When disabled, math delimiters are not parsed and `$...$` / `$$...$$` content renders as plain text. This gives users control over rendering overhead and raw-LaTeX visibility. The toggle persists via the existing `SettingsProvider` infrastructure.

### Rationale

- **`flutter_math_fork` over WebView-based solutions**: Pure-Dart rendering avoids the memory and latency overhead of embedding a WebView per math expression. It also works offline and on all Flutter targets (Android, iOS, macOS, Linux, Windows) without requiring an embedded browser engine.
- **Pre-extraction of delimiters**: Parsing math delimiters before standard Markdown prevents ambiguity (e.g., `$a_b$` must not trigger emphasis parsing on the underscore). This is the same strategy used by GitHub and MathJax integrations.
- **Styled fallback over silent failure**: Showing raw LaTeX in a styled container is better than a blank space, a red error box, or a crash. It preserves the information while signaling that rendering was not possible.
- **Toggle as experience setting**: Math rendering is a display preference (like font size or theme), not a data-layer concern. `ExperienceSettings` (ADR-007) is the natural home for this toggle.

### Consequences

- ✅ Users see properly typeset LaTeX math in chat messages, improving readability for math-heavy conversations.
- ✅ Pure-Dart rendering works on all Flutter platforms without WebView or network dependencies.
- ✅ Styled fallback ensures malformed LaTeX degrades gracefully instead of breaking the UI.
- ✅ `showMathRendering` toggle gives users control over rendering behavior and raw-LaTeX visibility.
- ⚠ `flutter_math_fork` is a community-maintained fork; if it becomes unmaintained, a migration path to another KaTeX/MathJax port or a WebView fallback may be needed.
- ⚠ Complex LaTeX expressions (e.g., TikZ, chemfig) outside KaTeX's subset will fall back to raw source. Users expecting full LaTeX coverage will see limitations.
- ⚠ Math rendering adds CPU cost per expression; on very long sessions with hundreds of formulas, scroll performance may need monitoring and possible lazy-render optimization.
- ❌ Does not support LaTeX rendering in code blocks or file previews — only in chat message Markdown content.

### Key Files

- `lib/presentation/widgets/math_expression_widget.dart` — `MathExpressionWidget` with `flutter_math_fork` rendering and styled fallback
- `lib/presentation/widgets/chat_message/` — integration of math delimiter parsing into chat message Markdown pipeline
- `lib/domain/settings/experience_settings.dart` — `showMathRendering` toggle field
- `lib/presentation/providers/settings_provider.dart` — toggle persistence and access via `SettingsProvider`

---

## ADR-033: Cloudflare Managed OAuth as Optional Desktop Reverse-Proxy Auth (ADR-023 Exception) (2026-05-27)

**Status**: Accepted

**Related**: ADR-023 (Official OpenCode Contract-First Compatibility Policy), ADR-001 (Multi-Server Orchestration and Secure Credential Storage), ADR-007 (Modular Settings Architecture)

### Context

Some CodeWalk desktop users deploy OpenCode behind a Cloudflare Access reverse proxy that requires Cloudflare Managed OAuth identity verification before any traffic reaches the OpenCode server. This is a deployment-specific authentication layer that is invisible to the OpenCode server itself — the server only sees the standard `Authorization: Basic <creds>` header after the reverse proxy has already validated the user's identity.

Currently, CodeWalk only supports official OpenCode Basic Auth (username/password via `Authorization: Basic` header). Users behind Cloudflare Access receive HTTP 401/403 responses from the proxy before reaching the server, with no mechanism in the app to complete the OAuth dance. This blocks them from using CodeWalk entirely unless they pre-authenticate in a browser and somehow transfer session tokens — a fragile, unsupported workflow.

Official OpenCode does not define a reverse-proxy authentication mechanism. The server is unaware of any upstream proxy auth; it only expects Basic Auth. Adding Cloudflare Managed OAuth support is therefore a client-side concern that does not modify any server API contract, but it does introduce a secondary auth layer that is not part of the official OpenCode specification — triggering ADR-023 review.

### Decision

1. **Optional Cloudflare Managed OAuth flow**: Add an opt-in Cloudflare Managed OAuth authentication capability for desktop platforms only. When enabled per server profile, CodeWalk performs the Cloudflare Managed OAuth authorization code flow with PKCE S256 in a system browser. The resulting access token is sent as `Authorization: Bearer <access_token>` on requests whose origin matches the OAuth-enabled profile only. When a `registration_endpoint` is available, Dynamic Client Registration (DCR) is performed to obtain client credentials automatically.

2. **Profile-scoped configuration**: Each `ServerProfile` (ADR-001) gains an `oauthEnabled` (bool, default `false`) field. This single toggle controls whether the profile uses Cloudflare Managed OAuth or standard Basic Auth — the two modes are mutually exclusive within a profile. This preserves OpenCode Basic Auth for non-OAuth profiles without interference.

3. **Conditional export architecture**: The `OAuthService` is implemented via Dart conditional exports: `oauth_service_io.dart` provides the real desktop implementation (system browser launch, local redirect server, token exchange), and `oauth_service_stub.dart` provides a no-op stub for mobile platforms. The conditional export pattern ensures compile-time platform resolution without runtime checks.

4. **Desktop-only gating**: The Cloudflare Managed OAuth flow is gated behind `AppProvider.supportsCloudflareAccessOAuth`. On mobile platforms (Android/iOS), the feature is hidden from UI and the code path is the no-op stub. Rationale: reverse-proxy deployments are desktop/server environments; mobile users connect directly or via VPN. This prevents unnecessary complexity on mobile and avoids the browser-redirect UX challenges on small screens.

5. **Secure credential storage via `OAuthTokenStorage`**: Access and refresh tokens are stored through `OAuthTokenStorage` backed by `flutter_secure_storage`, with keys scoped by `profileId + serverUrl`. No OAuth credentials are ever written to SharedPreferences, log output, or debug surfaces. `OAuthCredential` encapsulates the token pair and expiry.

6. **Bearer token propagation**: Requests to the OAuth-enabled profile's origin include `Authorization: Bearer <access_token>` via the Dio interceptor. The interceptor matches the request origin against the OAuth profile's server URL — only matching requests receive the Bearer header. On profile switch or when `oauthEnabled` is false, the interceptor is removed. Cross-origin requests never include the OAuth token.

7. **OAuth callback flow**: The callback path is `/oauth/callback`. The flow validates `state` parameter integrity, rejects duplicate callback invocations, and passes the authorization code + PKCE verifier to the token endpoint. On failure, the user sees a clear error and can retry or disable `oauthEnabled` for that profile.

8. **Health checks and OAuth challenge detection**: Health check requests load cached OAuth tokens and record OAuth challenges (e.g., 401/403 from the proxy) to trigger re-authentication when needed.

9. **Mutual exclusivity of auth modes**: OAuth and Basic Auth are mutually exclusive profile modes in this PR. An OAuth-enabled profile uses Bearer token auth exclusively; a non-OAuth profile uses standard Basic Auth. This prevents auth-header conflicts and keeps each profile's auth boundary clean.

### ADR-023 Exception Declaration

This ADR constitutes an explicit ADR-023 exception per section 3 ("Explicit Divergence") of ADR-023.

**Deviation from official behavior**: Official OpenCode defines only Basic Auth for server authentication. Cloudflare Managed OAuth introduces a secondary, pre-Basic-Auth authentication layer that is not part of the official OpenCode API contract. The client sends a Bearer token for matching-origin requests that is consumed by an upstream reverse proxy, transparent to the OpenCode server.

**Why this is acceptable**:
- The OpenCode server contract is unchanged — CodeWalk still sends the standard `Authorization: Basic` header on non-OAuth profiles and follows all server API semantics.
- The OAuth Bearer token is consumed by an upstream reverse proxy, transparent to the OpenCode server.
- No new server endpoints, no modified request/response schemas, no altered lifecycle semantics.
- The feature is opt-in and profile-scoped; servers without Cloudflare Managed OAuth are completely unaffected.
- OAuth and Basic Auth are mutually exclusive per profile — no auth-header conflicts.

### Rationale

- **Reverse-proxy auth is a deployment reality**: Enterprise and self-hosted users commonly place services behind Cloudflare Access. CodeWalk must support this to be usable in those environments.
- **Cloudflare Managed OAuth (authorization code + PKCE S256)**: This is the standard Cloudflare Access OAuth mechanism — not cookie-based auth. Authorization code flow with PKCE S256 provides the strongest security guarantees for native/desktop applications (no client secret in the app, code verifier prevents interception).
- **DCR when available**: Dynamic Client Registration automates client credential provisioning when the Cloudflare IdP exposes a `registration_endpoint`, removing manual client ID entry.
- **Conditional export pattern**: Using Dart's conditional export (`oauth_service_io.dart` / `oauth_service_stub.dart`) provides compile-time platform resolution — cleaner than runtime platform checks scattered across call sites.
- **Desktop-only scoping via `AppProvider`**: `AppProvider.supportsCloudflareAccessOAuth` centralizes platform capability detection, consistent with the app's provider architecture.
- **Profile-scoped mutual exclusivity**: Tying the feature to `oauthEnabled` on the server profile (ADR-001) and making OAuth/Basic Auth mutually exclusive prevents accidental activation and keeps the auth boundary clean per-server.
- **Secure storage alignment**: `OAuthTokenStorage` following ADR-001's `flutter_secure_storage` pattern with `profileId + serverUrl` scoped keys prevents the same class of credential-exposure issues that ADR-001 solved for Basic Auth.

### Consequences

- ✅ Desktop users behind Cloudflare Access can authenticate and use CodeWalk normally.
- ✅ No impact on servers without Cloudflare Managed OAuth — feature is fully opt-in and profile-scoped.
- ✅ OpenCode server contract is fully preserved on non-OAuth profiles — Basic Auth is always sent.
- ✅ Secure storage via `OAuthTokenStorage` prevents OAuth credential leakage via plaintext persistence.
- ✅ Desktop-only gating via `AppProvider.supportsCloudflareAccessOAuth` avoids mobile UX complexity and unsupported deployment patterns.
- ✅ Mutual exclusivity of OAuth/Basic Auth per profile prevents auth-header conflicts.
- ✅ PKCE S256 protects against authorization code interception attacks.
- ⚠ Adds a second auth layer to the connection flow for OAuth-enabled profiles, increasing time-to-first-message (browser redirect + code exchange).
- ⚠ Requires maintaining a local HTTP redirect server (for the `/oauth/callback`) on desktop platforms; port conflicts are possible in rare cases.
- ⚠ OAuth access token expiration requires re-authentication; health checks detect proxy challenges and re-trigger the flow gracefully.
- ❌ Mobile platforms will not support Cloudflare Managed OAuth; users in proxied environments must use desktop or VPN on mobile.
- ❌ Cloudflare Managed OAuth configuration is specific to Cloudflare — other reverse-proxy solutions (Authelia, Tailscale, etc.) are not covered by this ADR and would require separate exceptions if needed.

### Risk Analysis

- **Medium auth-layer risk**: If the OAuth access token expires mid-session, requests will fail with 401/403 from the proxy. Mitigation: health checks load cached OAuth tokens and record OAuth challenges; the app detects proxy 401/403 responses (distinct from OpenCode 401), re-triggers the OAuth flow with a user-visible prompt, and replays the failed request after re-auth.
- **Low contract risk**: The OpenCode server API is unmodified. The Dio interceptor adds a Bearer token for matching-origin requests only, consumed upstream. Non-OAuth profiles are completely unaffected. If a future OpenCode version adds its own Bearer-based auth, the OAuth interceptor is scoped to the profile origin and will not conflict.
- **Low data-risk**: OAuth tokens are stored in `flutter_secure_storage` with keys scoped by `profileId + serverUrl`. Clearing a server profile removes all associated OAuth credentials.
- **Low port-conflict risk**: The local redirect server binds to a random available port; collision probability is low on desktop. If binding fails, the user receives an error with a retry option.

### Rollback / Feature-Flag Plan

- **Immediate user rollback**: Disable `oauthEnabled` in the server profile settings. The app immediately falls back to Basic Auth only for that profile. Clear stored OAuth credentials for the profile.
- **Product rollback**: Remove `oauthEnabled` from `ServerProfile`, the Dio Bearer interceptor, and the OAuth flow code. `OAuthTokenStorage` keys are cleaned up on next profile load when `oauthEnabled` is absent.
- **Feature flag**: `oauthEnabled` per-profile IS the feature flag. There is no global toggle — each server profile controls its own OAuth state independently.

### Regression Tests

- **Basic Auth non-regression**: Existing Basic Auth connection tests under `test/unit/network` must pass unchanged when `oauthEnabled` is `false` (default).
- **Profile isolation**: Enabling OAuth on profile A must not affect profile B's connection or credential state.
- **Interceptor scoping**: The Bearer token interceptor must only attach `Authorization: Bearer` to requests matching the OAuth profile's origin; cross-origin requests must not include the OAuth token.
- **Secure storage boundary**: OAuth credentials must not appear in SharedPreferences, log output, or debug surfaces. Keys must be scoped by `profileId + serverUrl`.
- **Mobile no-op**: On mobile platforms, `OAuthService` (stub) must be a no-op and `AppProvider.supportsCloudflareAccessOAuth` must return false; UI must not expose OAuth configuration.
- **State/callback validation**: The `/oauth/callback` flow must validate the `state` parameter, reject duplicate callbacks, and handle PKCE verifier mismatches gracefully.
- **Health check OAuth awareness**: Health checks must load cached OAuth tokens and record OAuth challenges for re-auth triggering.
- **Profile deletion cleanup**: Deleting a server profile must remove all associated OAuth credentials from `OAuthTokenStorage`.
- **Mutual exclusivity**: An OAuth-enabled profile must not send Basic Auth headers, and a non-OAuth profile must not send Bearer OAuth tokens.

### Key Files

- `lib/core/auth/oauth_service.dart` — `OAuthService` public API with conditional export
- `lib/core/auth/oauth_service_io.dart` — desktop implementation: Cloudflare Managed OAuth authorization code + PKCE S256, DCR when `registration_endpoint` available, system browser launch, `/oauth/callback` handling with state/path/duplicate rejection, token exchange
- `lib/core/auth/oauth_service_stub.dart` — no-op stub for mobile platforms
- `lib/core/auth/oauth_service_result.dart` — `OAuthServiceResult` type for flow outcomes
- `lib/core/auth/oauth_token_storage.dart` — `OAuthTokenStorage` backed by `flutter_secure_storage`, keys scoped by `profileId + serverUrl`
- `lib/core/auth/oauth_credential.dart` — `OAuthCredential` encapsulating access/refresh tokens and expiry
- `lib/core/network/dio_client.dart` — Bearer token interceptor management for matching OAuth profile origin, proxy-401/403 detection
- `lib/core/providers/app_provider.dart` — `supportsCloudflareAccessOAuth` desktop-only gating
- Onboarding and settings pages — `oauthEnabled` toggle and configuration UI
- Tests under `test/unit/auth` — OAuth service, token storage, credential, PKCE, DCR, callback validation
- Tests under `test/unit/network` — Bearer interceptor scoping, health check OAuth challenge detection, Basic Auth non-regression
