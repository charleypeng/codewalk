# CodeWalk - OpenChamber Feature Gap Final Plan

**Status**: In progress
**Generated**: 2026-05-24
**Last updated**: 2026-05-25
**Scope**: Verified planner suggestions against the current CodeWalk codebase and ordered all valid missing or partially implemented OpenChamber-inspired features.

---

## How to Use This Tracker

- Each feature has its own detailed plan file under `final_plan/`.
- Mark progress by changing the status checkbox: `[ ]` → `[~]` (in progress) → `[x]` (done).
- Update the commit hash column when a feature is completed.
- Cross-cutting requirements and verification matrix remain in this file for quick reference.

---

## Progress Summary

| Phase | Features | Done | In Progress | Remaining |
|-------|----------|------|-------------|-----------|
| 1 — UX Foundations | 4 | 4 | 0 | 0 |
| 2 — Rich Output | 4 | 2 | 0 | 2 |
| 3 — Organization | 3 | 0 | 0 | 3 |
| 4 — Workspace Control | 4 | 0 | 0 | 4 |
| 5 — Advanced | 4 | 0 | 0 | 4 |
| **Total** | **19** | **6** | **0** | **13** |

---

## Feature Tracker

### Phase 1 — High-Impact, Low-Protocol-Risk UX Foundations

These features are mostly client-side and build directly on current CodeWalk surfaces.

| # | Feature | Priority | Status | Commit | Plan |
|---|---------|----------|--------|--------|------|
| 1 | Rich Diff Review Surface | P0 | [x] | fe145fa, 9dbca9d, 5267a91 | [01_rich_diff_review.md](final_plan/01_rich_diff_review.md) |
| 2 | Clickable File Paths with Line Jumps | P0 | [x] | 7741b58, 80e5d53, d1bf168, 54ba44d, cfe775f | [02_clickable_file_paths.md](final_plan/02_clickable_file_paths.md) |
| 3 | Timeline Full-Text Search | P1 | [x] | plan ee9cdd2, implementation 502c3d8, reviewer fix b7d51ba | [03_timeline_search.md](final_plan/03_timeline_search.md) |
| 4 | Session Export as Markdown/JSON | P1 | [x] | plan a8b42ea, impl 200dfb4, fix 79d90dd, release v1.80.0 | [04_session_export.md](final_plan/04_session_export.md) |

**Phase completion**:

- [x] All 4 features implemented
- [x] All validations passing
- [x] `make check` clean

---

### Phase 2 — Rich Chat Output and Mobile Accessibility

Client-side rendering or platform-service additions that improve comprehension and accessibility.

| # | Feature | Priority | Status | Commit | Plan |
|---|---------|----------|--------|--------|------|
| 5 | TTS Read-Aloud Responses | P1 | [x] | plan 5a868d81, implementation bb06528..277b697, reviewer fixes 9581904 16805ed, release v1.81.0 (8e5643f) | [05_tts_read_aloud.md](final_plan/05_tts_read_aloud.md) |
| 6 | Mermaid Diagram Rendering | P1 | [x] | plan 349649c, implementation e955581..8230a4b, tests 11dee9b, reviewer fix 07a80c2, release v1.82.0 (6ad07c7) | [06_mermaid_rendering.md](final_plan/06_mermaid_rendering.md) |
| 7 | LaTeX/Math Rendering | P2 | [ ] | — | [07_latex_rendering.md](final_plan/07_latex_rendering.md) |
| 8 | Share Messages as Images | P2 | [ ] | — | [08_share_messages_as_images.md](final_plan/08_share_messages_as_images.md) |

**Phase completion**:

- [x] Feature #6 implemented (Phase 2 — 2/4 done)
- [ ] All 4 features implemented
- [ ] All validations passing
- [ ] `make check` clean

---

### Phase 3 — Organization and Local Productivity

Mostly client-local features that should preserve server contract isolation.

| # | Feature | Priority | Status | Commit | Plan |
|---|---------|----------|--------|--------|------|
| 9 | Session Folders and Subfolders | P2 | [ ] | — | [09_session_folders.md](final_plan/09_session_folders.md) |
| 10 | Persistent Project Notes and User Todos | P2 | [ ] | — | [10_project_notes_todos.md](final_plan/10_project_notes_todos.md) |
| 11 | Snippets with `#` Autocomplete | P2 | [ ] | — | [11_snippets_autocomplete.md](final_plan/11_snippets_autocomplete.md) |

**Phase completion**:

- [ ] All 3 features implemented
- [ ] All validations passing
- [ ] `make check` clean

---

### Phase 4 — Workspace Control Layer

High-value but capability-gated features that must be verified against official OpenCode contracts before implementation.

| # | Feature | Priority | Status | Commit | Plan | Gate |
|---|---------|----------|--------|--------|------|------|
| 12 | Git Status Sidebar MVP | P3 | [ ] | — | [12_git_status_sidebar.md](final_plan/12_git_status_sidebar.md) | Verify `/vcs` endpoint |
| 13 | Inline File Editing | P3 | [ ] | — | [13_inline_file_editing.md](final_plan/13_inline_file_editing.md) | Verify file-write endpoint |
| 14 | Plan/Build Mode | P3 | [ ] | — | [14_plan_build_mode.md](final_plan/14_plan_build_mode.md) | — |
| 15 | Inline Comment Drafts on Diffs/Plans | P3 | [ ] | — | [15_inline_comment_drafts.md](final_plan/15_inline_comment_drafts.md) | Depends on 1 + 14 |

**Phase completion**:

- [ ] All 4 features implemented (or gated with verified fallback)
- [ ] All validations passing
- [ ] `make check` clean
- [ ] ADR-023 compliance verified for all gated features

---

### Phase 5 — Advanced and Experimental Features

These should be planned only after the foundation above is complete.

| # | Feature | Priority | Status | Commit | Plan | Gate |
|---|---------|----------|--------|--------|------|------|
| 16 | Token/Cost Breakdown and Raw Inspector | P4 | [ ] | — | [16_token_cost_breakdown.md](final_plan/16_token_cost_breakdown.md) | — |
| 17 | Skills Catalog and Local Skill Management | P4 | [ ] | — | [17_skills_catalog.md](final_plan/17_skills_catalog.md) | Official skill/config API |
| 18 | Custom JSON Themes | P4 | [ ] | — | [18_custom_json_themes.md](final_plan/18_custom_json_themes.md) | — |
| 19 | Multi-Agent Runs with Isolated Worktrees | P5 | [ ] | — | [19_multi_agent_runs.md](final_plan/19_multi_agent_runs.md) | Worktree API stability |

**Phase completion**:

- [ ] All 4 features implemented (or gated with verified fallback)
- [ ] All validations passing
- [ ] `make check` clean

---

### Deferred

| # | Feature | Decision |
|---|---------|----------|
| 20 | Multi-Window Support | Defer — requires larger app-state isolation work, lower cross-platform/mobile value |
| 21 | Cloudflare Tunnel / QR Onboarding | Defer unless remote-access product direction changes |

### Not Scheduled as Standalone Work

| Feature | Reason |
|---------|--------|
| File-Type Icons | Already implemented via `_fileIconForPath()`; polish opportunistically |
| Session Forking / Branchable Timeline | Fork support exists (`fork_chat_session.dart`); richer inline UX is a subtask of session organization |
| Shell Mode via `!` | Composer shell mode already exists; only a faster `!command` shortcut is missing — low priority |

---

## Decision Summary

The consensus stage was intentionally skipped. Instead, the planner suggestions were evaluated against CodeWalk's actual implementation in `lib/`, `BEHAVIOR.md`, `CODEBASE.md`, `ADR.md`, and the OpenChamber README feature set.

The valid work is split into three categories:

1. **Missing**: No implementation exists in CodeWalk today.
2. **Partial**: CodeWalk has foundational pieces, but not the OpenChamber-level feature.
3. **Already present or not valid now**: Do not schedule as feature work unless later requirements change.

Primary finding: CodeWalk is very strong as a mobile-first OpenCode chat client, but it is still missing much of OpenChamber's workspace/productivity layer: rich diff review, Git/GitHub workflow UI, inline file editing, project notes, session organization, rich rendering, and export/share utilities.

---

## Verification Matrix

| Feature Suggested by Planners | CodeWalk Status | Evidence | Plan Decision |
| --- | --- | --- | --- |
| Rich diff viewer with stacked/inline modes | Done | `session_diff_viewer.dart` rewritten with 3 view modes (summary/unified/split), line gutters, syntax highlighting, lazy hunk collapse, `onFileTap` jump | Completed in v1.77.0 |
| Clickable file paths in chat messages | Done | `FilePathDetector` regex utility, `FilePathSyntax`/`FilePathBuilder` markdown extensions, `onFileTap` wired through `ChatMessageWidget` and all 3 `SessionDiffViewer` call sites, `scrollToLine` in file viewer, i18n snackbar feedback | Completed in v1.78.0 |
| Git sidebar and Git workflows | Missing | No Git provider/sidebar/staging/commit UI found; only VCS/worktree foundations exist | Valid, gated by API verification |
| Inline file editing | Missing | File viewer is read-only; `BEHAVIOR.md` says file explorer is read-only | Valid, gated by write API verification |
| Plan/Build mode | Missing | No `PlanView`, plan mode, or dedicated plan surface found | Valid |
| TTS read-aloud responses | Missing | No TTS implementation; only STT stack exists | Valid |
| Mermaid rendering | Missing | No Mermaid implementation found | Valid |
| LaTeX/math rendering | Missing | No LaTeX/math rendering implementation found | Valid |
| Share messages as images | Missing | No `toImage`, message image share, or RepaintBoundary export flow found | Valid |
| Session export as Markdown/JSON | Done | `SessionExportService` serializes to Markdown and JSON; export actions in session menu; file_picker save with Clipboard fallback; local_user_* IDs omitted (ADR-023); paginated message guard | Completed in v1.80.0 (a8b42ea, 200dfb4, 79d90dd) |
| Session folders/subfolders | Missing | No session folder model/provider/UI found | Valid |
| Persistent project notes/todos | Missing | No project note/todo model/provider/UI found; current task list is agent-controlled only | Valid |
| Timeline full-text search | Done | `ChatSearchBar`, `ChatSearchWidget`, search provider/scoped state, filter-as-you-type, fuzzy highlight in timeline, session-scoped scrolled search, all-origins popup for server results, keyboard-friendly navigation | Completed in v1.79.0 (ee9cdd2, 502c3d8, b7d51ba) |
| Token/cost breakdown panel | Partial | ADR-029 provider quota exists; `StepFinishPart` displays tokens/cost inline, but no dedicated per-session breakdown/raw inspector | Valid |
| Snippets with `#` autocomplete | Partial | Canned answers exist in composer extras, but no snippet catalog or `#` autocomplete trigger | Valid |
| Shell mode via leading `!` | Partial | Composer shell mode exists; missing only simple normal-mode `!command` shortcut | Valid, low priority |
| Skills catalog/local skill management | Missing | No skills catalog/browser found | Valid, gated by official API verification |
| Multi-agent runs from one prompt | Missing | No multi-agent/multi-run orchestration found | Valid, but large and experimental |
| Custom JSON themes | Missing | CodeWalk has OpenCode presets and Material You dynamic color, but no user JSON theme loader | Valid, lower priority |
| Multi-window support | Missing | `window_manager` is used for current window/tray lifecycle only, not multiple app windows | Defer |
| Cloudflare tunnel/QR onboarding | Missing | No tunnel implementation; only Cloudflare provider icon recognition | Defer |
| File-type icons | Already present | `_fileIconForPath()` exists in file runtime/viewer | Do not schedule |
| Session fork/branchability | Partial/already present | `fork_chat_session.dart` and repository fork support exist | Subtask of session organization |

---

## Cross-Cutting Requirements

Every implementation must preserve these constraints:

- **ADR-023 first**: official OpenCode docs/source override OpenChamber behavior.
- **OpenChamber is inspiration, not protocol authority**.
- **Mobile-first UI**: every feature must have compact/mobile behavior, not just desktop layout.
- **Capability-gated server features**: Git, file write, skills, worktrees, and any non-core endpoint must degrade cleanly when unsupported.
- **No credential leaks**: GitHub/Git/token-related features must never expose credentials in logs, exports, or UI.
- **No passive scroll regressions**: search, diff, comments, and message rendering must not fight chat scroll ownership.
- **No file mutations without explicit user action**: inline editing and Git operations must be clearly user-initiated.

---

## Recommended Execution Order

1. Rich diff review surface → [plan](final_plan/01_rich_diff_review.md)
2. Clickable file paths with line jumps → [plan](final_plan/02_clickable_file_paths.md)
3. Timeline full-text search → [plan](final_plan/03_timeline_search.md)
4. Session export as Markdown/JSON → [plan](final_plan/04_session_export.md)
5. TTS read-aloud responses → [plan](final_plan/05_tts_read_aloud.md)
6. Mermaid diagram rendering → [plan](final_plan/06_mermaid_rendering.md)
7. LaTeX/math rendering → [plan](final_plan/07_latex_rendering.md)
8. Share messages as images → [plan](final_plan/08_share_messages_as_images.md)
9. Session folders/subfolders → [plan](final_plan/09_session_folders.md)
10. Persistent project notes/user todos → [plan](final_plan/10_project_notes_todos.md)
11. Snippets with `#` autocomplete → [plan](final_plan/11_snippets_autocomplete.md)
12. Git status sidebar MVP → [plan](final_plan/12_git_status_sidebar.md)
13. Inline file editing → [plan](final_plan/13_inline_file_editing.md)
14. Plan/Build mode → [plan](final_plan/14_plan_build_mode.md)
15. Inline comment drafts on diffs/plans → [plan](final_plan/15_inline_comment_drafts.md)
16. Token/cost breakdown and raw inspector → [plan](final_plan/16_token_cost_breakdown.md)
17. Skills catalog/local skill management → [plan](final_plan/17_skills_catalog.md)
18. Custom JSON themes → [plan](final_plan/18_custom_json_themes.md)
19. Multi-agent runs with isolated worktrees → [plan](final_plan/19_multi_agent_runs.md)

---

## Immediate Next Task

Features #1–#6 are complete. Phase 1 is done. Phase 2 is 2/4 done. Next: **LaTeX/Math Rendering** (#7) — first P2 item in Phase 2.
