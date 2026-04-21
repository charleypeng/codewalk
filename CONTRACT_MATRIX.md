# Contract Matrix

CodeWalk follows ADR-023: official OpenCode docs/source are the primary contract, and OpenChamber is a secondary UX reference only.

## Source Priority

1. `ADR.md` (especially ADR-023 and related ADRs)
2. `BEHAVIOR.md`
3. `ai-docs/opencode_server.md`
4. `ai-docs/opencode_web.md`
5. `ai-docs/opencode_models.md`
6. Official OpenCode docs/source
7. OpenChamber references, only after official confirmation

## Decision Rules

- Follow official OpenCode lifecycle and payload semantics first.
- Keep legacy compatibility fallbacks explicit and temporary.
- Do not introduce protocol behavior from OpenChamber alone.
- Prefer capability-gated UI for official-but-optional server surfaces.
- Treat drift around `prompt_async`, SSE reconciliation, and config mutation as high risk.

## Matrix

| Surface | Official source | CodeWalk current status | Relevant files | Risk if wrong | Next action |
| --- | --- | --- | --- | --- | --- |
| Async session send lifecycle (`/session/:id/prompt_async`) | Official OpenCode contract in `ai-docs/opencode_server.md` | Implemented. Provider intentionally omits `messageId` and relies on server-assigned canonical IDs. | `lib/presentation/providers/chat_provider.dart`, `lib/data/datasources/chat_remote_datasource.dart` | Critical: later turns can silently fail reconciliation. | Keep protected by dedicated contract tests. |
| Optimistic local user ID contract (`local_user_*`) | ADR-023 pitfall guidance plus current CodeWalk behavior | Implemented and load-bearing for duplicate echo suppression. | `lib/presentation/providers/chat_provider.dart`, `lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart` | Critical: optimistic/server echo merge breaks. | Keep explicit in tests and comments; do not normalize to server-like IDs. |
| Global/session realtime semantics (`/event`, `/global/event`) | Official OpenCode contract in `ai-docs/opencode_server.md` | Implemented with provider-level SSE and fallback completion watch. | `lib/data/datasources/chat_remote_datasource.dart`, `lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart`, `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart` | High: stale state, dropped assistant updates, scroll regressions. | Preserve server-authoritative status transitions and extend contract tests around reconciliation. |
| Session status map (`/session/status`) | Official OpenCode contract in `ai-docs/opencode_server.md` | Implemented and used to defer risky config sync while busy. | `lib/data/datasources/chat_remote_datasource.dart`, `lib/presentation/providers/chat_provider/chat_provider_selection_helpers.dart` | High: false aborts and config timing regressions. | Keep selection/config deferral covered by tests. |
| Config sync (`GET/PATCH /config`) | Official OpenCode contract in `ai-docs/opencode_server.md`; timing constrained by ADR-019 | Implemented. PATCH calls are deferred while active processing remains unsafe. | `lib/data/datasources/app_remote_datasource.dart`, `lib/presentation/providers/chat_provider/chat_provider_selection_helpers.dart`, `test/unit/providers/chat_provider_sync_test.dart` | High: server processing can be interrupted. | Keep ADR-019 behavior in the contract test suite. |
| Providers, agents, models, variants (`/provider`, `/agent`, `/config`) | Official OpenCode contract in `ai-docs/opencode_server.md` and `ai-docs/opencode_models.md` | Implemented for provider/model/agent selection and variant sync. | `lib/data/datasources/app_remote_datasource.dart`, `lib/presentation/providers/chat_provider.dart`, `lib/presentation/providers/settings_provider.dart` | Medium: mismatched defaults or unsupported model rendering. | Maintain capability-aware UI and avoid hardcoded assumptions beyond official config. |
| Provider auth and OAuth (`/provider/auth`, OAuth authorize/callback) | Official OpenCode contract in `ai-docs/opencode_server.md` | Not currently consumed by the client. | `lib/data/datasources/app_remote_datasource.dart` | Medium: connection UX remains manual where official auth helpers exist. | Treat as a later capability-gated addition after core contract work. |
| Session action surfaces (`share`, `diff`, `todo`, `revert`, `unrevert`, `init`, `summarize`) | Official OpenCode contract in `ai-docs/opencode_server.md` | Data/domain/provider support is largely present; UI exposure is partial and inconsistent. | `lib/data/datasources/chat_remote_datasource.dart`, `lib/domain/usecases/get_session_diff.dart`, `lib/domain/usecases/get_session_todo.dart`, `lib/domain/usecases/revert_chat_message.dart`, `lib/domain/usecases/unrevert_chat_messages.dart`, `lib/domain/usecases/summarize_chat_session.dart`, `lib/presentation/providers/chat_provider.dart` | Medium: hidden capabilities and fragmented review flow. | Build discoverable UI on top of existing official support before adding new protocol surfaces. |
| Slash command surfaces (`GET /command`, `POST /session/:id/command`) | Official OpenCode contract in `ai-docs/opencode_server.md` | Implemented. Suggestions load from `/command`; sends route to `/session/:id/command`. | `lib/presentation/pages/chat_page/chat_page_command_query.dart`, `lib/data/datasources/chat_remote_datasource.dart` | Medium: drift if command sends fall back to chat payload semantics. | Keep this path explicit and avoid conflating command sends with `prompt_async`. |
| Project, file, search, and VCS (`/project`, `/project/current`, `/file`, `/file/content`, `/find/file`, `/vcs`) | Official OpenCode contract in `ai-docs/opencode_server.md` | Implemented for current project, file listing/reading, fuzzy file search, and VCS detection. | `lib/data/datasources/project_remote_datasource.dart` | Medium: weak search/discovery if capability map is unclear. | Safe base for later UX work; note that `/find` text search, `/find/symbol`, and `/file/status` are still unused. |
| Experimental worktrees (`/experimental/worktree`) | Official OpenCode experimental contract in local docs | Implemented in datasource/domain, with UI opportunities still limited. | `lib/data/datasources/project_remote_datasource.dart`, `lib/data/models/worktree_model.dart` | Medium: experimental surface can drift faster than stable APIs. | Keep behind explicit UX framing and capability checks. |
| PTY / terminal runtime | CodeWalk ADR-027 plus client implementation; not documented in current local OpenCode server snapshot | Implemented in the client, but the local server doc snapshot does not currently list PTY endpoints. | `lib/data/datasources/terminal_remote_datasource.dart`, `lib/presentation/services/codewalk_terminal_socket.dart`, `lib/presentation/widgets/codewalk_terminal_panel.dart` | Medium: doc/source mismatch could hide transport drift. | Verify against live `/doc` or upstream source before broadening terminal UX assumptions. |
| App/path bootstrap (`/path`) with legacy `/app` and `/app/init` fallback | Official OpenCode uses `/path`; legacy compatibility remains in client | Implemented with explicit fallback for older servers. | `lib/data/datasources/app_remote_datasource.dart` | Medium: silent legacy behavior can outlive its support window. | Keep the fallback documented and define supported server window before removing it. |
| Permissions/questions | Official OpenCode docs explicitly list `/session/:id/permissions/:permissionID`; local docs do not describe current question endpoints | CodeWalk currently uses top-level `/permission`, `/question`, `/question/{id}` reply/reject flows. | `lib/data/datasources/chat_remote_datasource.dart`, `lib/presentation/widgets/permission_request_card.dart` | High: likely drift or mixed-version compatibility area. | Verify against live `/doc` and upstream source before changing behavior; keep clearly marked as needs verification. |
| Advanced official surfaces (`/mcp`, `/lsp`, `/formatter`, `/experimental/tool`, `/file/status`, `/find`, `/find/symbol`) | Official OpenCode contract in `ai-docs/opencode_server.md` | Not yet consumed or only weakly represented in the UI. | `lib/data/datasources/app_remote_datasource.dart`, `lib/data/datasources/project_remote_datasource.dart`, settings/UI layers | Medium: missed product value if never surfaced; drift if surfaced without capability gating. | Treat as later capability-gated work after contract hardening and core UX cleanup. |

## Confirmed Safe to Build On

- `prompt_async` plus provider-level SSE remains the correct baseline for CodeWalk.
- Model/provider/agent selection already follows official config-backed surfaces.
- `GET /command` and `POST /session/:id/command` are already aligned in the client.
- Session action APIs are already mostly wired at the data/domain/provider level.
- Project/file/VCS/worktree surfaces are real foundations, not speculative product ideas.

## Needs Contract Hardening First

- `local_user_*` optimistic ID rules and `messageId` omission from `prompt_async`
- SSE reconciliation and session-authoritative status transitions
- Deferred `PATCH /config` behavior while the server is busy
- Permission/question routes where local client behavior may span mixed server generations
- PTY endpoint assumptions that are implemented client-side but under-documented in the local official snapshot

## OpenChamber-Only Inspiration (Non-Authoritative)

These are useful as UX ideas only after official OpenCode compatibility is confirmed:

- richer diff/review surfaces
- quota grouping/provenance clarity
- stronger multi-device continuity affordances
- broader workspace control panels
- advanced Git/GitHub workflows

They must not redefine CodeWalk's protocol or lifecycle assumptions.
