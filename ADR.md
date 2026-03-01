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

Use realtime streams as the primary sync mechanism, automatically enter degraded polling when signals fail/stale, and apply platform-aware background policies (desktop tray continuity, mobile hold/fallback strategy). Active message-response streams are preserved (not cancelled) during session navigation to maintain in-flight response continuity. Preserved streams are tracked in a dedicated set and drained on every context switch to prevent connection leaks. A generation counter (`_messageStreamGeneration`) invalidates stale preserved-stream callbacks, preventing cross-session state mutation.

### Rationale

- Realtime provides best UX for active conversations and event-driven prompts.
- Degraded polling prevents hard desync when streams degrade.
- Desktop and mobile need distinct background lifecycle behavior.

### Consequences

- ✅ Maintains near-live UX under normal connectivity.
- ✅ Preserves functional sync under stream degradation.
- ✅ Preserves in-flight AI responses during session navigation, matching OpenCode Web continuity behavior.
- ⚠ Lifecycle orchestration becomes more stateful and timing-sensitive.
- ⚠ Generation-based invalidation is required to prevent stale preserved streams from mutating current session state; all preserved subscriptions must be drained on context switches.
- ❌ Continuous background streaming is not guaranteed on mobile.

**Note** (commits `acce617`, `9dcd773`, `37f0397`): Preserved stream lifecycle, drain-on-context-switch, and generation invalidation added.

**Note** (commit `77592fa`): Fixed stale-persisted-session-ID race condition where `loadSessions()` triggered by global events could read a stale session ID from disk and revert an in-memory session switch. Three defensive guards added: `selectSession()` now invalidates `_sessionsFetchId`, `loadLastSession()` prioritizes in-memory `_currentSession?.id` over persisted ID, and `_restoreLastSessionSnapshotFromCache()` guards against overwriting an already-switched session.

**Note** (commit `1fcf33e`): SSE streams are now served by a dedicated Dio instance (`_sseDio`) with an isolated connection pool, preventing Android HTTP client from evicting SSE connections when regular HTTP requests compete for TCP connections during session switches. See ADR-018.

**Note**: In polling-only background monitoring (when push notifications are unavailable), added a 5-minute tail probe after active sessions end to reduce missed notifications. Implementation uses `kBackgroundTailProbeInterval` (5 minutes) as the constant and `shouldScheduleBackgroundTailProbe()` to determine eligibility based on session state and platform support.

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

**Update (commit `61934e9`)**: Per-send SSE connections were removed entirely from the `prompt_async` path. The server monitors per-send SSE connections and aborts the AI agent when it detects disconnection (e.g. half-open TCP after background resume). Without per-send SSE, `prompt_async` processes fully async — message delivery relies on immediate polling (`startFallbackCompletionWatch` with zero delay) plus provider-level SSE. The dedicated SSE Dio remains in use for provider-level SSE streams.

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
