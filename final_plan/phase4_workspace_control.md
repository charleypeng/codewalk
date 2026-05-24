# Phase 4: Workspace Control Layer

High-value but capability-gated features that must be verified against official OpenCode contracts before implementation.

## Features

| # | Feature | Priority | Status | Plan | Gate |
|---|---------|----------|--------|------|------|
| 12 | Git Status Sidebar MVP | P3 | [ ] | [12_git_status_sidebar.md](12_git_status_sidebar.md) | Verify `/vcs` endpoint |
| 13 | Inline File Editing | P3 | [ ] | [13_inline_file_editing.md](13_inline_file_editing.md) | Verify file-write endpoint |
| 14 | Plan/Build Mode | P3 | [ ] | [14_plan_build_mode.md](14_plan_build_mode.md) | — |
| 15 | Inline Comment Drafts on Diffs/Plans | P3 | [ ] | [15_inline_comment_drafts.md](15_inline_comment_drafts.md) | Depends on 1 + 14 |

## Phase Completion

- [ ] All 4 features implemented (or gated with verified fallback)
- [ ] All validations passing
- [ ] `make check` clean
- [ ] ADR-023 compliance verified for all gated features
