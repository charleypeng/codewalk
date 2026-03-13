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

## Group 3.02: Settings Ownership and Sync Boundaries

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

## Group 3.03: Theme Preset Parity Foundation

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

## Group 3.04: Theme UX, Persistence, and Migration Safety

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

## Group 3.05: Verified Shared Settings Parity After Theme Slice

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
