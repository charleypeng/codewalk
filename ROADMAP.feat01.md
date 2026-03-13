# ROADMAP.feat01.md — OpenCode Settings Parity (featS)

> Detailed execution plan for Feature 3: OpenCode settings parity

## WHY This Feature Matters

- **ADR-023 Compliance**: Prevents drift from official OpenCode contract
- **User Expectation**: Settings behavior should match web/CLI experience
- **Maintenance**: Clear ownership boundaries prevent technical debt accumulation

## Execution Order Rationale

The order is intentional:
1. **Contract first** — Verify what belongs where before implementing
2. **Ownership second** — Define clear boundaries to prevent mixing local/shared config
3. **Theme vertical slice** — Biggest verified gap, safest first implementation
4. **Theme UX/migration** — Must be usable and safe for existing users
5. **Shared settings after theme** — Only implement with proven upstream ownership
6. **Permissions/shortcuts** — Overlapping but distinct from themes
7. **Regression/docs** — Ensure non-regression and document exceptions

---

## Group 3.01: Contract and Parity Matrix

### Why
- Prevent ADR-023 drift
- Separate real parity work from undocumented guesses

### How
1. **Inventory current CodeWalk settings**
   - Review `ExperienceSettings`, `SettingsProvider`, and related classes
   - List all configurable options (theme, model, agent, shortcuts, permissions)

2. **Compare against official OpenCode**
   - Use `ai-docs/opencode_web.md` and `ai-docs/opencode_models.md` as anchors
   - Search official OpenCode documentation for settings parity

3. **Classification matrix**
   - **Local app/device**: Settings that belong only to Flutter (e.g., dynamic color, AMOLED mode)
   - **Shared OpenCode-backed**: Settings that should match web/CLI behavior
   - **Out-of-scope**: Server-only or TUI-only controls

4. **Record verification gaps**
   - Document settings where parity status is unknown
   - Flag for follow-up investigation

### Output
- Classification document or table in this file
- List of confirmed shared settings
- List of confirmed local-only settings
- List of items requiring further research

---

### Evidence-Backed Parity Matrix

| Setting | Category | Evidence |
|---------|----------|----------|
| Theme (preset selection) | Flutter-local / CodeWalk-local | `tui.json` contains theme definitions; local client presentation, not shared |
| Keybinds / Shortcuts | Flutter-local / CodeWalk-local | Defined in `tui.json`, client-side only |
| Dynamic color, AMOLED, contrast | Flutter-local / CodeWalk-local | Flutter-only rendering preferences |
| Seed color picker | Flutter-local / CodeWalk-local | Flutter-only Material You customization |
| Thinking visibility, tool visibility | Flutter-local / CodeWalk-local | UI state preferences |
| Composer visibility, auto-approve | Flutter-local / CodeWalk-local | Composer UI preferences |
| Density, desktop panes/widths | Flutter-local / CodeWalk-local | Desktop layout preferences |
| Short background realtime | Flutter-local / CodeWalk-local | Mobile-only background behavior |
| Android background alerts | Flutter-local / CodeWalk-local | Platform-specific |
| **Notifications (scope/enabled)** | **OpenCode-shared candidate** | `SettingsProvider` already syncs notification flags/categories with `/config`; proven overlap |
| Model (default) | OpenCode-shared candidate | `opencode.json`/`/config` contains `model`, `small_model` |
| Default agent | OpenCode-shared candidate | Defined in `/config` as shared server config |
| Permissions (allow/ask/deny) | OpenCode-shared candidate | Server/shared config; applies to all clients |
| Reasoning/variant settings | OpenCode-shared candidate | Server-side model configuration |
| Server-only runtime flags | Out-of-scope / server-only | Internal server behavior |
| TUI-only keybindings | Out-of-scope / TUI-only | TUI-specific, no Flutter equivalent |
| Local-only UI polish | Out-of-scope / TUI-only | Visual tweaks not shared |

---

### Evidence-Backed Decisions

- **Themes are a parity target but currently local presentation parity, not `/config` parity.** OpenCode stores themes in `tui.json` as client-local configuration. The parity opportunity is visual alignment with OpenCode's named presets (e.g., `tokyonight`, `nord`), not syncing theme data to the server.

- **Keybind parity is local/client-side parity, not shared config parity.** Shortcuts are defined in `tui.json` and do not sync to the server. CodeWalk should offer matching shortcut defaults but treat them as local-only preferences.

- **Notifications (enabled flags/categories) are the proven current shared settings overlap already wired to `/config`.** `SettingsProvider.syncNotificationsFromServerConfig()` and `_syncNotificationToServer()` prove overlap for notification enabled flags and categories. Notification sound preferences remain CodeWalk-local today unless later evidence shows an official shared mapping.

- **Model, default agent, and permissions are shared-config candidates for later groups.** These appear in `opencode.json` and `/config`, but Flutter surface decisions (UI placement, default values, conflict handling) must be resolved before implementation. Group 3.05 covers these.

---

### Verification Gaps to Close in Later Groups

- **OpenCode Web settings UI organization is not fully documented in local anchors.** We have `ai-docs/opencode_web.md` but need to verify whether all web settings sections are captured. Group 3.02/3.05 should re-audit before treating any additional setting as shared.

- **Need source-proof before treating any setting as shared or mirroring Web section layout.** The matrix above reflects current evidence. Adding new shared settings requires citing `ai-docs/opencode_models.md` or official OpenCode documentation as the source of truth.

---

### ✅ Completed: Group 3.01 — Commit 0d700be

Delivered evidence-backed parity matrix documenting:
- Local-only settings (themes, keybinds, UI preferences)
- Proven shared settings (notifications enabled flags)
- Shared-config candidates for later groups (model, agent, permissions)
- Verification gaps requiring source-proof before expanding

---

## Group 3.02: Settings Ownership and Sync Boundaries

### 📥 Inputs Inherited from 3.01

- **Themes/keybinds are local/client parity, not shared `/config` parity** — visual alignment with OpenCode named presets, not server sync
- **Notifications enabled flags are the proven current `/config` overlap** — already wired in `SettingsProvider`
- **Model/default agent/permissions remain shared-config candidates** — requires Flutter surface decisions before implementation (covered in Group 3.05)
- **Undocumented Web settings layout still requires proof** — do not mirror UI structure without citing official sources

### Current Ownership Touchpoints

| Component | Role | Sync Scope |
|-----------|------|------------|
| `ExperienceSettings` | Local app/device preferences entity | Local-only |
| `SettingsProvider` | Unified persistence layer | Local + partial `/config` |
| `SettingsProvider.syncNotificationsFromServerConfig()` | Sync notification flags/categories from server | `/config` overlap |
| `SettingsProvider._syncNotificationToServer()` | Push notification changes to server | `/config` overlap |
| `AppRemoteDataSource.getConfig()` | Generic remote config read entry point | `/config` read-only |
| `chat_provider_selection_sync_ops.dart` | ChatProvider selection sync operations | Session-scoped |
| `chat_provider_selection_helpers.dart` | Selection sync helpers for model/agent/variant | Session-scoped |

> **Note**: ChatProvider selection sync files are existing shared-config touchpoints under the CodeWalk namespace. They handle model/agent/variant sync for active sessions but are not yet generalized for settings parity.

### Explicit CodeWalk Exceptions Already Approved

| Exception ID | Description | Approval |
|--------------|-------------|----------|
| EXC-001 | Composer permission auto-approve toggle | ADR-023 approved exception — local/product behavior, not shared-permission parity |

> This exception is **local/product behavior only** and must not be mistaken for official OpenCode shared-permission parity. It is documented as an ADR-023 approved exception.

---

### Ownership Matrix by Setting Family

| Setting Family | CodeWalk Owner | OpenCode Owner | Boundary Rule |
|----------------|----------------|-----------------|---------------|
| Themes and theme presets | CodeWalk | Local (`tui.json`) | Visual alignment only; no `/config` sync |
| Keybinds / shortcuts | CodeWalk | Local (`tui.json`) | Local-only; no server sync |
| Appearance-only Flutter (dynamic color, AMOLED, seed, contrast, density, visibility toggles) | CodeWalk | N/A | Pure client preferences; never shared |
| Notifications enabled flags/categories | CodeWalk | Shared (`/config`) | **Proven overlap**; synced to server |
| Notification sound preferences | CodeWalk | Local | Local-only unless proven otherwise |
| Default model / small model | CodeWalk | Shared (`/config`) | Candidate for future parity |
| Default agent | CodeWalk | Shared (`/config`) | Candidate for future parity |
| Variant / reasoning / model options | CodeWalk | Shared (`/config`) | Candidate for future parity |
| Permissions (allow/ask/deny) | CodeWalk | Shared (`/config`) | Candidate for future parity |
| Tools / commands / MCP / formatter / watcher / server runtime | CodeWalk | Server-only | Out-of-scope for Flutter parity |
| Speech / desktop panes / Android background / update checks / onboarding | CodeWalk | N/A | Pure client/device settings |

---

### Shared vs Local Sync Rules

- **Only settings owned by official OpenCode shared config are candidates for `/config` parity.**
- `tui.json` concerns stay client-local even if CodeWalk mirrors the user-facing capability.
- CodeWalk may keep local UX/device settings even when OpenCode has no equivalent.
- Existing CodeWalk namespaced selection sync is not blanket proof that arbitrary settings belong in shared config.
- Notification enabled flags are proven current overlap; notification sounds remain local unless proven otherwise.

---

### Exception Inventory

| Exception ID | Boundary Note |
|--------------|----------------|
| EXC-001 | Local product behavior, not official shared permission parity |

---

### Unresolved Contract Questions

- Does OpenCode Web expose or group shared settings differently from raw docs?
- Should any additional shared GUI-relevant config beyond model/default_agent/permissions be mirrored?
- Does variant/reasoning belong in settings UI or remain in model-selection flow?

---

### 3.02 Deliverables

- **Ownership matrix by setting family** — classify each setting family as local, shared, or excluded
- **Shared/local/excluded sync rules** — document what syncs where and under what conditions
- **Exception inventory** — all approved CodeWalk exceptions with rationale
- **Unresolved contract questions** — list of questions to verify before Groups 3.03/3.05 proceed

### Why
- Prevent mixing local app/device preferences with shared OpenCode config
- Avoid unsafe `/config` assumptions

### How
1. **Define ownership boundaries**
   - `ExperienceSettings`: Local app preferences
   - `SettingsProvider`: Unified persistence layer
   - Remote config access: Shared OpenCode config
   - Chat selection sync: Current session context

2. **Preserve CodeWalk-only exceptions**
   - Document explicit divergences (e.g., composer auto-approve)
   - Mark these as "CodeWalk exception" rather than fake parity

3. **Sync boundary contracts**
   - What gets synced to OpenCode backend?
   - What stays local only?
   - How to handle conflicts?

### Output
- Ownership matrix in this file
- Explicit list of CodeWalk exceptions
- Sync boundary documentation

---

### ✅ Completed: Group 3.02 — Commit 29f553f

Recorded ownership matrix, sync rules, exception inventory, and unresolved contract questions:
- Ownership matrix by setting family (themes, keybinds, appearance, notifications, model/agent/permissions, server-only, device-only)
- Shared vs local sync rules document what syncs where
- Exception inventory documents EXC-001 (composer auto-approve) as ADR-023 approved
- Unresolved contract questions flagged for verification before Groups 3.03/3.05

---

## Group 3.03: Theme Preset Parity Foundation

### 📥 Inputs Inherited from 3.02

- **Themes are local/client presentation parity, not `/config` parity** — visual alignment with OpenCode named presets (e.g., `tokyonight`, `nord`), not server sync
- **Keybinds remain local and are not part of the theme slice** — shortcuts are defined in `tui.json`, client-side only
- **Notification/shared-config work is outside the theme-foundation step** — notifications already have proven overlap in Group 3.02; focus on themes only
- **EXC-001 is unrelated and must not leak into theme ownership decisions** — composer auto-approve is a CodeWalk exception unrelated to theme parity

### 3.03 Guardrails (Theme Foundation Non-Goals)

- **Do not add `/config` theme sync unless new proof appears** — themes are `tui.json` client-local; no server endpoint exists
- **Do not add custom JSON theme import in the first foundation slice** — defer until preset parity is stable
- **Do not rewrite existing classic Material You controls out of the app** — preserve dynamic color, AMOLED, seed picker, contrast
- **Do not mirror undocumented OpenCode Web layout blindly** — only implement with evidence-backed sources

### Expected 3.03 Outputs

- Named preset enum/model (system, tokyonight, everforest, ayu, catppuccin, catppuccin-macchiato, gruvbox, kanagawa, nord, matrix, one-dark)
- Theme bridge/mapping layer (OpenCode name → Flutter theme)
- Settings/provider integration points
- Tests/migration targets to prepare for 3.04

### Why
- Themes are the biggest verified settings gap
- Safest first vertical slice for implementation

### How
1. **Add named OpenCode preset support**
   - `system`, `tokyonight`, `everforest`, `ayu`, `catppuccin`, `catppuccin-macchiato`, `gruvbox`, `kanagawa`, `nord`, `matrix`, `one-dark`

2. **Flutter theme bridge**
   - Create mapping from OpenCode theme names to Flutter themes
   - Preserve current Material You / classic mode toggle

3. **Defer custom JSON themes**
   - Wait until preset parity is stable
   - Document as future work

### Output
- Theme preset enum/mapping implementation
- Theme bridge class
- Integration with existing appearance settings

---

### ✅ Completed: Group 3.03 — Commit dd4a9b5

Implemented theme preset foundation:
- Added `OpenCodeThemePreset` enum with 11 named presets (system, tokyonight, everforest, ayu, catppuccin, catppuccin-macchiato, gruvbox, kanagawa, nord, matrix, one-dark)
- Created `lib/presentation/theme/opencode_theme_presets.dart` for runtime preset → Flutter theme mapping
- Integrated preset resolution in `lib/main.dart` before passing schemes into `AppTheme.lightFrom` / `AppTheme.darkFrom`
- Preset storage remains local via `ExperienceSettings.themePreset` and `SettingsProvider.themePreset`

---

## Group 3.04: Theme UX, Persistence, and Migration Safety

### 📥 Inputs Inherited from 3.03

- **Preset storage is local and defaults to the classic path** — `ExperienceSettings.themePreset` persists preset choice locally; no `/config` sync
- **Runtime theme resolution already supports preset-aware mapping** — `lib/presentation/theme/opencode_theme_presets.dart` resolves preset palettes in `lib/main.dart` before they flow into `AppTheme.lightFrom` / `AppTheme.darkFrom`
- **Preset palette mapping exists but UI selection is still missing** — Presets are available programmatically; user-facing selector UI is the 3.04 deliverable
- **Custom JSON themes and config sync remain deferred/out of scope** — Custom theme import and server-side theme storage are not part of 3.04

### 3.04 Guardrails

- **Preserve current classic Material You controls in the Appearance UI** — Keep dynamic color, AMOLED, seed picker, contrast toggles functional
- **Add preset selection UX without reclassifying themes as shared config** — Theme presets remain local-only; do not introduce `/config` sync for themes
- **Treat migration safety and backward compatibility as first-class concerns** — Existing theme preferences must survive the preset upgrade; test on user profiles with classic settings
- **Avoid expanding into keybinds/permissions/shared settings during 3.04** — Scope is strictly theme UX; other setting families are out-of-bounds

### Why
- Preset system must be usable on mobile and desktop
- Safe for existing users (no data loss)

### How
1. **Extend Appearance settings UI**
   - Clear mode/preset selection flow
   - Visual preview of presets

2. **Preserve CodeWalk-classic path**
   - Keep dynamic color controls
   - Keep AMOLED toggle
   - Keep seed color picker
   - Keep contrast controls

3. **Persistence + migration**
   - Add migration for existing theme settings
   - Ensure backward compatibility
   - Test on existing user profiles

4. **Manual parity verification**
   - Compare Flutter rendering with web/CLI for each preset
   - Document any visual differences

### Output
- Updated Appearance settings screen
- Migration code for theme settings
- Verification checklist

---

### ✅ Completed: Group 3.04 — Commit 1441f2c

Delivered preset-selection UX while preserving the classic path:
- Added theme family selection and preset chips inside the appearance settings section
- Preset selection persists locally via `ExperienceSettings.themePreset` and `SettingsProvider.themePreset`
- Classic Material You controls (dynamic color, AMOLED, seed picker, contrast) remain functional and are not evidence of shared config
- Theme presets remain fully local/user-selectable; no `/config` sync introduced
- Existing users without a preset stay on the classic path because `themePreset` defaults to null

---

## Group 3.05: Verified Shared Settings Parity After Theme Slice

### 📥 Inputs Inherited from 3.04

- **Theme presets are now fully local and user-selectable in CodeWalk** — stored in `ExperienceSettings.themePreset`, persisted via `SettingsProvider.themePreset`, no server involvement
- **Classic Material You controls remain intact and are not evidence of shared config** — dynamic color, AMOLED, seed picker, contrast are pure Flutter/local preferences; their presence does not imply `/config` parity
- **Shared-settings work should not revisit theme ownership unless new proof appears** — themes are confirmed local-only; do not add `/config` sync for themes without citing new official OpenCode documentation
- **Theme JSON import and shared theme sync remain out of scope unless re-planned** — custom theme import and server-side theme storage were explicitly deferred in 3.03/3.04; do not reopen without explicit roadmap update

### 3.05 Guardrails

- **Focus only on verified shared settings families** — model, default agent, permissions (allow/ask/deny), variant/reasoning — where upstream ownership is proven in `/config`
- **Do not reopen local theme decisions without new evidence** — themes are confirmed local-only; ignore any pressure to treat them as shared config
- **Require source proof before adding shared GUI settings** — cite `ai-docs/opencode_models.md` or official OpenCode docs; do not assume undocumented settings are shared
- **Keep Flutter-only settings out of shared parity work** — dynamic color, AMOLED, seed picker, contrast, density, desktop panes, Android background alerts remain CodeWalk-local

### Why
- Only implement shared parity after upstream ownership is proven

### How
1. **Audit official behavior**
   - Settings like default model, default agent, variant/reasoning
   - Any overlapping configuration options

2. **Implementation criteria**
   - Must have strong source evidence
   - Must have clear Flutter relevance
   - No TUI-only or server-only controls

3. **Implementation approach**
   - Add each setting with clear OpenCode-backed label
   - Sync with remote config where applicable

### Output
- List of implemented shared settings
- Source evidence for each
- Integration with settings UI

---

## Group 3.06: Overlapping Permissions/Shortcuts Parity and Provenance Labeling

### Why
- Align overlapping settings without importing TUI-only controls
- Make future maintenance easier with explicit provenance

### How
1. **Permissions parity**
   - Only overlapping permissions that apply to Flutter UI
   - Match web/CLI permission labels

2. **Shortcuts parity**
   - Keyboard shortcuts that apply to Flutter
   - Match web/CLI where applicable

3. **Provenance labeling**
   - Add metadata: `Local`, `OpenCode-backed`, `CodeWalk exception`
   - Display in settings UI where helpful

### Output
- Permission settings implementation
- Shortcuts implementation with provenance
- UI labels for provenance

---

## Group 3.07: Regression Coverage, Behavior/Docs Handoff, and Divergence Record

### Why
- Future sessions must resume from roadmap alone
- Non-regression mandatory under ADR-023

### How
1. **Extend unit/widget coverage**
   - Test new settings slices
   - Test migration paths

2. **Update BEHAVIOR.md**
   - Document implemented behavior
   - Note any deviations from OpenCode

3. **ADR documentation**
   - Update only if explicit divergence/exception required
   - Reference ADR-023 compliance

4. **Record non-goals**
   - List accepted exclusions
   - Document why certain items are out of scope

### Output
- Test coverage report
- Updated BEHAVIOR.md
- Divergence record (if any)
- Non-goals documentation

---

## Likely File Targets

- `lib/domain/entities/experience_settings.dart` — Settings entity
- `lib/presentation/providers/settings_provider.dart` — Settings provider
- `lib/presentation/pages/settings_page.dart` — Settings page
- `lib/presentation/pages/settings/sections/appearance_settings_section.dart` — Appearance UI
- `lib/presentation/pages/settings/sections/behavior_settings_section.dart` — Behavior UI
- `lib/presentation/pages/settings/sections/shortcuts_settings_section.dart` — Shortcuts UI
- `lib/presentation/theme/app_theme.dart` — Theme bridge
- `lib/data/datasources/app_remote_datasource.dart` — Remote config access
- `BEHAVIOR.md` — Behavior documentation
- `ADR.md` — Only if explicit divergence required

## Dependencies

- `ai-docs/opencode_web.md` — Official OpenCode web settings
- `ai-docs/opencode_models.md` — Model/settings references
- Existing `ExperienceSettings` and `SettingsProvider` implementation
