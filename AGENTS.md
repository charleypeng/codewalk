# CodeWalk - Project-Specific Rules

> ⚠️ **Base**: All rules from the main `/AGENTS.md` apply. This file contains only CodeWalk-specific items.

## Project Context

CodeWalk is a project that provides access to code agents from anywhere — desktop or mobile.

- **Every implementation must be designed for both mobile and desktop**. Preferably unified and responsive. **Priority: mobile UX, modern look, Material You**.
- After completing a change, verify whether it requires new tests or updates to existing tests.
- For visual adjustments, confirm with the user the exact block/screen referenced before changing; avoid assumptions.

- In this project specifically, we do NOT use `make precommit` directly — prefer splitting into `make check` and `make android`.
- Key base documentation is in ./ai-docs; always run at least one `ls` in that folder to know what exists.

## 📐 ADR Quick Reference (details in `ADR.md`)

> **Mandatory sync**: When creating, updating, or superseding an ADR, the adrkeeper/`adr` skill MUST update this table (description + line ranges). Superseded ADRs get the prefix "⚠️ SUPERSEDED —".

| ADR | What / Why | Lines |
|-----|------------|-------|
| 001 | Multi-server with profiles, scoped persistence, and secure credentials — prevent cross-server leakage | 29–62 |
| 002 | Context isolation `serverId::directory` with serialized transition queue — prevent race conditions on project switch | 64–99 |
| 003 | Realtime-first sync with degraded fallback and platform-aware background policy — maintain live UX without losing offline data | 102–147 |
| 004 | Chat with slim orchestrators and decomposed part-file clusters — maintainability on high-change surfaces | 150–183 |
| 005 | Composer pipeline for multimodal input, triggers (`@!/`) and send/stop — rich composition without breaking flow | 186–219 |
| 006 | Speech input with `SpeechInputService`, Sherpa (Linux) and native STT (Android) — pluggable by platform | 222–257 |
| 007 | Modular settings with typed `SettingsProvider` + `ExperienceSettings` — unified persistence desktop/mobile | 260–294 |
| 008 | Context-scoped file explorer with quick-open and diff-aware refresh — fast navigation without unnecessary reloads | 297–330 |
| 009 | Title generation via internal `title` agent — eliminate external dependency for session titles | 333–364 |
| 010 | Split CI pipeline: quality on push, release on tag, smoke on minor-tag — fast feedback without expensive builds | 367–400 |
| 011 | Unified server setup wizard (onboarding + settings) — guide new users and consolidate setup flow | 403–438 |
| 012 | Migration to Material Symbols via `material_symbols_icons` — broader icon coverage aligned with MD3 | 442–474 |
| 013 | MD3 `WindowSizeClass` with 5 breakpoint tiers — consistent responsive layout without magic numbers | 477–518 |
| 014 | Centralized design tokens (`AppShapes` + `BrandColor`) — MD3 shape scale and fallback colors without scattered hex values | 521–564 |
| 015 | Platform-specific icon pipeline (tray, notification, macOS) via `make icons` — reproducible assets per target | 567–608 |
| 016 | Hybrid file-backed cache for large chat payloads — eliminate SharedPreferences size limits | 611–646 |
| 017 | Android foreground service with `START_STICKY` — reliable monitoring that survives process death | 648–682 |
| 018 | Dedicated Dio instance for SSE with isolated connection pool — prevent stream eviction by regular HTTP requests | 685–734 |
| 019 | Defer `PATCH /config` during active server processing — prevent false abort from `Instance.dispose()` on server | 737–779 |

## 🚀 Project-Specific Flow: Android Build for Testing

- **After completing code changes**: Run `make check` **immediately** (preferably background and async).
- **Critical order**: `make check` must run right after code completion, BEFORE changing .md files or committing.
- **If only static files changed (.md, text)**: `make check` and `make android` are not required.
- **Once the user can test**: Run `make android` as soon as possible — it compiles and sends the APK to Telegram. Run after every task involving code. Preferably background and async.
- **Before commit**: If no code changed since the last check, another `make check` is not needed.

### Mandatory flow when explicitly requested by the user

- When the user explicitly asks, follow this order without skipping steps:
  1. implement the change;
  2. run `make check`;
  3. commit;
  4. call reviewer for the commit;
  5. apply only accepted fixes and repeat reviewer in a loop until no remaining corrections the agent agrees with;
  6. run `HEY_CAPTION="..." make android`;
  7. only then notify the user and send the final report;
  8. suggest the next task (preferably from the current roadmap).
- Avoid intermediate "done" notifications before step 6 is complete.

### Dynamic Caption on Upload

- Always use `HEY_CAPTION="My custom caption" make android`
- **Avoid**: "Latest adjustments made"
- **Prefer**: "Fixed height of Thinking Process box"

## 📦 New Tag / Release

- **Use `make release V=<type>`** for new versions:
  - `make release V=patch` — bump patch (e.g. 1.5.4 → 1.5.5)
  - `make release V=minor` — bump minor (e.g. 1.5.4 → 1.6.0)
  - `make release V=major` — bump major (e.g. 1.5.4 → 2.0.0)
- The command updates `pubspec.yaml` (version + build number), commits, creates tag, and pushes automatically.
- **Before running**: ensure all code changes are committed. `make release` only commits the version bump.
- After push/tag, watch the `@.github/workflows/release.yml` pipeline every 60s and update the user at each status. If background/async is not supported, use sleep command.
- If any step fails, cancel the pipeline entirely, analyze errors, and decide between:
  - fix and repeat the flow;
  - notify the user and wait for instructions.
- If everything passed correctly, review CODEBASE.md and ADR.md for updates required by recent commits.
