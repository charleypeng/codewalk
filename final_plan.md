# Archived Issue #45 Plan

**Status**: Archived after implementation
**Last reviewed**: 2026-06-15

This file used to contain the execution plan for GitHub issue #45, "Rate Limits / Quota missing many providers like in OpenChamber." It is no longer an active handoff plan.

## Current State

The quota implementation now uses the active architecture documented in ADR-029:

- REST first: `GET /api/quota/providers`, then `GET /api/quota/{providerId}` when the host exposes OpenChamber-compatible quota APIs.
- Shell fallback second: a hidden ephemeral OpenCode session runs a Base64-encoded Node probe through `POST /session/:id/shell`, parses `CW_QUOTA_JSON:`, and deletes the helper session.
- Provider credentials remain on the OpenCode host. CodeWalk only receives aggregated quota data, except for the existing opt-in OpenCode Go dashboard credential exception.

Implemented shell fallback probes currently cover:

- `anthropic` / `claude`
- `openrouter`
- `openai` / `codex` / `chatgpt`
- `google` / `google.oauth`
- `github-copilot` / `copilot`
- `github-copilot-addon`
- `opencode-go`
- `nano-gpt`
- `wafer`
- `kimi-for-coding`
- `zhipuai-coding-plan`
- `minimax-coding-plan`
- `minimax-cn-coding-plan`
- `zai-coding-plan`
- `cursor`
- `ollama-cloud`

The auth-key diagnostics also recognize newer REST-visible provider aliases such as Snowflake Cortex, Grok/xAI, and Cohere North so they are not shown as unknown shell-fallback config.

## Maintenance Notes

- Planned work and follow-ups belong in GitHub Issues, not this file.
- `ROADMAP.md` was intentionally removed and must not be recreated.
- Current implemented behavior belongs in `BEHAVIOR.md`.
- Architecture decisions belong in `ADR.md`.
- Structural maps and command references belong in `CODEBASE.md`.
