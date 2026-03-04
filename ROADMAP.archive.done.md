---
archive: "CodeWalk Completed Features Archive"
archived_on: "2026-03-03"
source_file: "ROADMAP.md"
---

## Archived Completed Features

### Feature 001: Baseline Audit, Safety Rails, and Deletion Policy
Description: Build an objective baseline of the current fork (code, docs, endpoints, tests, platform support) and define hard safety rails before touching implementation.

Completed baseline inventory, deletion/retention policies, rollback checkpoints, and dependency governance for subsequent features.
Commits: b9de67f, 7d7e6f6, 3640fb2, d307731, c96f53c

### Feature 002: Licensing Migration to AGPLv3 + Commercial (>1M Revenue)
Description: Replace MIT with a compliant AGPLv3 setup and add a separate commercial license track for organizations above the revenue threshold.

Completed legal migration to AGPLv3 with commercial license track, notices, and dependency license validation.
Commits: 2b51dd3, f0bc342, 898889f, b5e1719, a25cb31

### Feature 003: Rebrand OpenMode -> CodeWalk (Code, Package IDs, Metadata)
Description: Rename all product-facing and package-level identifiers from OpenMode/open_mode to CodeWalk/codewalk across app runtime, build metadata, and distribution assets.

Completed rebrand across app metadata, source imports, Android namespace/applicationId, and web manifest/title references.
Commits: 9483801, ede3939, a519f8f, 63549d4

### Feature 004: Full English Standardization (UI, Code Comments, Docs)
Description: Translate all remaining non-English content to English, including user-facing strings, comments, logs, and technical documentation.

Completed UI/runtime/comment English standardization; automated language regression checks intentionally marked as wont-do.
Commits: 1bc9184

### Feature 005: Documentation Restructure and Markdown Pruning
Description: Remove unnecessary markdown files, consolidate surviving docs, and rewrite README with explicit origin attribution to OpenMode.

Completed markdown triage, consolidation into `CODEBASE.md`, README rewrite with attribution, and redundant-doc pruning.
Commits: 8562850, 7c72e70, b219a2b, d02f486

### Feature 006: OpenCode Server Mode API Refresh and Documentation Update
Description: Align the client and internal API docs with the latest OpenCode Server Mode endpoints/schemas and close compatibility gaps.

Completed Server Mode compatibility refresh, schema-aligned models/use cases, and live validation against target server.
Commits: e994f39, bbadbe4, 78acc18, ad6470c

### Feature 007: Cross-Platform Desktop Enablement and Responsive UX
Description: Expand project target platforms beyond mobile and deliver a true cross experience for desktop/web/mobile with adaptive layouts and desktop-native interactions.

- [x] 7.01 Add desktop platforms (Windows/macOS/Linux) to Flutter project - Enabled desktop flags and generated `linux/`, `macos/`, `windows/` via Flutter tooling
- [x] 7.02 Implement responsive layout breakpoints (mobile drawer vs desktop split view) - `ChatPage` now adapts with mobile drawer (`<840`), split desktop (`>=840`), and large-desktop utility panel (`>=1200`)
- [x] 7.03 Add desktop input ergonomics (shortcuts, hover/focus polish, resize behavior) - Added `Ctrl/Cmd+N`, `Ctrl/Cmd+R`, `Ctrl/Cmd+L`, `Esc`; external input focus control; desktop hover/cursor polish in session list
- [/] 7.04 Validate build/run on each target and document platform-specific caveats - Linux/web validation passed (`flutter test`, `flutter build linux`, `flutter build web`, Linux runtime smoke). Blocked for full target matrix by host OS constraint (`flutter build windows` requires Windows host, `flutter build macos` requires macOS host)

### Feature 008: Manual QA Campaign and Stability Hardening
Description: Execute a structured manual test campaign across supported platforms and critical user journeys, then fix high-impact defects before automation is expanded.

Completed QA matrix execution, fixed P1 defects, and published release-readiness artifacts.
Commits: da2940b, cc5c78f

### Feature 009: Automated Test Suite and CI Quality Gates
Description: Build comprehensive automated tests (unit, widget, integration) and enforce quality gates in CI so future changes remain stable.

Completed baseline unit/widget/integration coverage, CI quality gates, coverage thresholds, and SSE race-condition stabilization.
Commits: 5125edd

### Feature 010: OpenCode Upstream Parity Baseline and Contract Freeze
Description: Consolidate the latest OpenCode Server/API/Desktop/Web behavior into a single compatibility contract for CodeWalk implementation planning.

Completed upstream parity contract freeze, Required/Optional scope matrix, and persisted-state migration strategy.

### Feature 011: Multi-Server Management and Health Orchestration
Description: Implement first-class support for multiple OpenCode servers (desktop/mobile parity), including active/default server routing and health-aware switching.

Completed multi-server profile orchestration with scoped persistence and switching coverage across unit/widget/integration tests.

### Feature 012: Model/Provider Switching and Variant (Reasoning Effort) Controls
Description: Bring model control parity with OpenCode Desktop/Web, including current-model changes and model variant/reasoning-effort changes.

Completed provider/model selector, variant handling and payload parity, plus scoped model-history persistence and tests.

### Feature 013: Event Stream and Message-Part Parity (Messages, Thinking, Tools, Questions, Permissions)
Description: Expand real-time event handling to match OpenCode v2 event/part taxonomy and reliably render message lifecycle details.

Completed resilient SSE/reducer parity, expanded part rendering, permission/question interactions, send-path fixes, and fallback/watchdog stabilization.

### Feature 014: Advanced Session Lifecycle Management
Description: Upgrade session operations beyond basic CRUD to parity-level management for active and historical work.

Completed rename/archive/share/unshare/delete/fork/status/todo/diff flows with optimistic updates, reconciliation, and lifecycle test coverage.

### Feature 015: Project/Workspace Context Parity
Description: Support multi-project and workspace/worktree workflows using directory-aware API/event orchestration.

Completed directory-scoped context orchestration, project/worktree UX, global event sync, and context-isolation test coverage.

### Feature 016: Reliability Hardening, QA, and Release Readiness for Parity Wave
Description: Validate and harden all parity features with measurable quality gates before production rollout.

Completed parity hardening, QA matrix validation, release docs updates, and chat-composer enhancements (attachments/voice/progress/selectors/settings refinements).
Commits: d568f22, 47ecddb, 3081b2e, b65f7f6, afb63be

### Feature 017: Realtime-First Refreshless UX
Description: Remove manual refresh interactions and keep UI state continuously updated through SSE-driven sync with lifecycle-aware efficiency controls.

Completed SSE-first refreshless orchestration with lifecycle-aware fallback polling and validated no-manual-refresh behavior.
Commits: f190e02

### Feature 018: Prompt Power Features Parity (`@`, `!`, `/`)
Description: Replicar no composer os gatilhos de produtividade do OpenCode Web: menção de arquivos/agentes com `@`, modo shell com `!` no início, e catálogo de comandos por `/` no começo do input.
Status: [x] Concluída

Concluída a paridade de `@`/`!`/`/` com navegação por teclado, shell payload dedicado e estabilização UX mobile/desktop do painel de sugestões.
Commits: e97544b, 094057a, 8be2d81, ef0a1e7, 53da769, 7ff7b71, 6d0ebe8, dfbda1b

### Feature 019: File Explorer and Viewer Parity
Description: Entregar navegação completa de arquivos com ícones, busca rápida, abertura em abas e visualização de conteúdo diretamente na UI, alinhado ao OpenCode Web.

Concluída a paridade de árvore/quick-open/viewer com integração de `/file`, `/find/file`, `/file/content`, estado de abas e cobertura automatizada.

### Feature 020: Agent Selector in Composer (Model/Thinking Bar)
Description: Incluir seletor explícito de agente (Build, Plan e demais permitidos) ao lado de provider/model e thinking, com persistência por contexto e integração de envio.

Concluída a entrega do seletor de agente com persistência por escopo, payload de prompt (`agent`), atalhos e cobertura de testes.
Commits: bf20bde, c75df1d

### Feature 021: Session Title Visibility and Quick Rename Parity
Description: Melhorar a UX de sessão para sempre exibir título de conversa de forma clara e permitir renomeação rápida/inline sem fricção.

Concluída a exibição consistente de título da sessão ativa com rename inline otimista, rollback e cobertura automatizada.

### Feature 022: Settings Parity (Notifications, Sounds, Shortcuts)
Description: Expandir configurações para incluir notificações e sons por categoria (agente/permissões/erros) e uma tela dedicada de atalhos com busca e detecção de conflito.

Concluída a paridade de Settings com notificações/som por categoria, atalhos pesquisáveis com conflito, deep-link de notificação e refinamentos UX.

### Feature 023: Critical Code Issues Resolution (2026-02-11)
Description: Corrigir problemas críticos de código identificados via análise estática e padrões, focando em APIs deprecated e anti-patterns que afetam compatibilidade e maintainability.

Concluída a remoção dos problemas-alvo de deprecação/compatibilidade, com validação por `flutter analyze`, testes completos e build Android.

### Feature featP: Giant file decomposition and orchestrator architecture
Status: [x] Concluída

Concluída a decomposição de arquivos gigantes em módulos e orchestrators para reduzir risco de orquestração e melhorar manutenibilidade sem mudança funcional.
Commits: 5ebdc23

## Historical Dependency Order (Features 001-022)

1. Feature 001 -> blocks all other features (baseline + safety rails)
2. Feature 002 -> should finish before publishing docs/release artifacts
3. Feature 003 -> should happen before broad documentation rewrites
4. Feature 004 -> should happen before final markdown pruning
5. Feature 005 -> should happen before API documentation refresh
6. Feature 006 -> should happen before desktop/manual/automation validation
7. Feature 007 -> should happen before full manual QA campaign
8. Feature 008 -> should happen before final CI quality thresholds
9. Feature 009 -> provides regression safety net for parity expansion
10. Feature 010 -> defines parity contract and scope boundaries for all upcoming implementation
11. Feature 011 -> depends on 010 and establishes server orchestration foundation
12. Feature 012 -> depends on 010/011 for model persistence and active-server context
13. Feature 013 -> depends on 010 and should land before advanced session UX
14. Feature 014 -> depends on 013 event fidelity and 012 model controls
15. Feature 015 -> depends on 011 + 013 to safely support multi-context orchestration
16. Feature 016 -> final hardening/release gate for features 011-015
17. Feature 017 -> depends on 013 + 015 + 016 to safely remove manual refresh controls
18. Feature 018 -> depends on 012 + 015 + 017 to add advanced prompt triggers over stable scoped context and realtime sync
19. Feature 019 -> depends on 015 + 017 + 018 for refreshless file navigation integrated with prompt/file-open flows
20. Feature 020 -> depends on 012 + 018 to align agent selection with model/thinking controls and prompt command grammar
21. Feature 021 -> depends on 014 + 017 to deliver consistent session-title UX over stable lifecycle and sync behavior
22. Feature 022 -> depends on 018 + 020 to expose complete command/agent-driven settings and shortcut management

## Historical Acceptance Gates (Features 001-022)

| Feature | Entry Gate | Exit Gate |
|---------|-----------|-----------|
| 001 | None | CODEBASE.md + Makefile + doc classification + ADR + gates defined |
| 002 | 001 complete | LICENSE AGPLv3 + LICENSE-COMMERCIAL.md + NOTICE + dep compatibility verified |
| 003 | 002 complete | All IDs renamed + `flutter analyze` no new errors + smoke test build |
| 004 | 003 complete | Zero CJK strings in `lib/` + `flutter analyze` clean |
| 005 | 004 complete | README rewritten + docs consolidated + no orphan MD files |
| 006 | 005 complete | Gap matrix closed + models updated + validated against real server |
| 007 | 006 complete | Desktop builds OK + responsive layout + keyboard shortcuts working |
| 008 | 007 complete | Test matrix executed + P0/P1 fixed + readiness report published |
| 009 | 008 complete | Unit/widget/integration tests + CI pipeline + coverage thresholds |
| 010 | 009 complete | Signed parity contract + endpoint/event/UX gap matrix + migration checklist |
| 011 | 010 complete | Multi-server profile management + active/default switching + server-scoped state isolation |
| 012 | 010, 011 complete | User can switch model/provider + switch variant/reasoning effort + payload parity validated |
| 013 | 010 complete | Stable SSE/event engine + expanded part rendering + interactive question/permission handling |
| 014 | 012, 013 complete | Session lifecycle parity (rename/archive/share/fork/etc.) with passing API/UI tests |
| 015 | 011, 013 complete | Reliable project/workspace context switching with directory-isolated state |
| 016 | 011-015 complete | QA signoff + docs/ADR/CODEBASE updates + release checklist complete |
| 017 | 013, 015, 016 complete | Refreshless UX with SSE-first sync, lifecycle-aware fallback, and validated no-manual-refresh flows |
| 018 | 012, 015, 017 complete | Composer supports `@` mentions + leading `!` shell mode + leading `/` slash commands with tested keyboard/mouse flows |
| 019 | 015, 017, 018 complete | File tree + fuzzy open + file viewer available with stable state sync and passing navigation/render tests |
| 020 | 012, 018 complete | Agent selector is first-class beside model/thinking, persisted per context, and reflected in outbound prompts |
| 021 | 014, 017 complete | Active session title is always visible and rename-inline flow updates state/UI reliably with rollback safety |
| 022 | 018, 020 complete | Settings include notification/sound categories and searchable shortcut management with persistence/conflict checks |

## Backlog Wave Completed Items

Items moved from `ROADMAP.md` pending backlog to reduce active-file noise.

- [x] Manter o modelo selecionado sincronizado, atualmente o modelo selecionado no desktop, não é o mesmo selecionado no app mobile, o servidor backend deve passar essa informação
- [x] Sincronizar agente selecionado entre desktop/mobile via `/config.default_agent` com reconciliação ativa enquanto o app estiver aberto
- [x] Sincronizar variant/thinking em tempo real entre dispositivos via namespace do app em `/config.agent.<agent>.options.codewalk.variantByModel`
- [x] Sincronizar model/agent/variant entre apps abertos sem depender de envio de nova mensagem (reconcile periódico em foreground)
- [x] Evitar abort de resposta ativa ao trocar selects (sync remoto diferido e flush automático quando sessão volta para idle)
- [x] Aplicar prioridade de seleção por sessão no cliente ativo (conversa > projeto/local do contexto)
- [x] Persistir overrides de seleção por sessão para sobreviver restart (local por escopo + remoto em `/config.agent.__codewalk.options.codewalk.sessionSelections`)
- [x] Aplicar ícones de app para Linux (GNOME/Freedesktop) e alinhar equivalentes para os demais OS (Windows/macOS)
- [x] A tool apply_patch deve ter cores apropriadas para linhas removidas (vermelho) e linhas adicionadas (verde)
- [x] Restaurar ação de compactar contexto (`/summarize`) com botão dedicado ao lado de `New Chat` e comando builtin `/compact`
- [x] Restaurar cabeçalho das tool calls sem prefixo redundante, exibir comando de entrada (`Command/Input`) e aplicar status responsivo (desktop: ícone + texto; mobile/tela compacta: apenas ícone)
- [x] Evoluir controle de compactação para knob único com percentual dentro do próprio círculo e popover (uso %, tokens e custo) mantendo ação `Compact now` com ícone de colapso
- [x] Retirar o fundo diferente do input do composer ao passar o mouse no desktop (hover)
- [x] Aplicar cores de +, - e +- em tool calls como apply_patch e outros, bem como cores de fundo pra mostrar o diff
- [x] Tornar o botão de attach (anexar) sem fundo e mais discreto no composer
- [x] Investigate and fix conversation continuity when switching sessions/projects (hidden response until session switch/retry): implemented async send stale-ID protection and idle final-reconcile bypass during abort suppression. - Related commits: acce617 9dcd773 1581c65 cdee253 1fcf33e 68baebe 61934e9 0ee474c df9ec9e 931d9a8 745c0a8 f1faf4a 4074734
- [x] Investigate and fix conversation-open click behavior: double-click freeze and sidebar sync. - Related commits: 204114e 09c1641 eccec6b dfa9754 b5cda81
- [x] Ajustar ciclagem de atalhos para comportamento tipo Alt+Tab: hoje a ciclagem percorre lista de recentes/favoritos sem priorizar o último item anterior. Implementar primeira ação focada no último usado anterior para troca rápida entre dois itens, com avanço sequencial para demais recentes apenas em pressões subsequentes dentro de janela curta (ex.: 2s). DoD: 1) primeira ativação do atalho alterna para o último item anterior usado; 2) segunda/terceira ativações em sequência (janela temporal) avançam na lista de recentes; 3) comportamento consistente para agente, modelo e variante; 4) fallback previsível quando não houver histórico suficiente. - Related commits: 2086730 c19d346
- [x] Substituir ícone lateral por badges flutuantes na lista de sessões: remover o ícone fixo à esquerda de cada sessão/conversa (que consome espaço no mobile) e adotar badges flutuantes compactos. Incluir sistema de badges de estado para indicar sessões que exigem atenção. DoD: 1) ícone lateral removido da lista de sessões no mobile; 2) badges flutuantes compactos sem prejuízo de legibilidade/tap target; 3) badges de atenção para estados relevantes (ex.: nova resposta, question pendente, erro/notificação); 4) estilo alinhado ao Material You (MD3) e consistente entre mobile/desktop. - Related commits: cda2973 06a8194 eae9883
- [x] Exibir badge no menu hambúrguer para sessões fora de foco que exigem atenção: em cenário multi-sessão no mobile, mostrar indicador visual no ícone/menu hambúrguer quando houver sessão não focada com evento pendente (resposta concluída, question aguardando ação, erro/notificação relevante). DoD: 1) badge aparece quando qualquer sessão fora de foco tiver estado de atenção; 2) badge desaparece/atualiza ao consumir o evento ou focar a sessão; 3) diferenciação mínima de tipo de evento (ex.: dot/contador/estado) sem poluir UI; 4) estilo coerente com Material You (MD3) e boa visibilidade em telas pequenas. - Related commits: cda2973 06a8194 eae9883
- [x] In Settings > About, create an independent update system for new versions.
- [x] In About, add "check updates on open" option (default on), with toast and update button.
- [x] Reorganize the "Project Context" screen for a more dynamic visual UX; tapping a project opens it immediately and closes the dialog, removing the need for a separate open button next to trash. - Related commits: ee0b95b 725dda7
- [x] Replace the current project selection dialog with an inline rich select/dropdown component. - Commit hash: 0cc892c
- [x] Investigate and fix chat flicker and intermittent blank history on conversation open/update: stabilized tool-call rendering, fixed empty-session blink, and improved revalidation stability. - Related commits: 26c8448 9351919 4074734
- [x] Load older history on top reach: implemented top-scroll trigger to fetch previous message batches. - Commit hash: 8b364fd
- [x] After returning from background, position the conversation at the start of the most recent message (top of text) instead of at the end. - Related commits: 440c7d9 59584d4
- [x] Quando a tool call bubble for do tipo task, oferecer botão para pular para a subconversa, e na subconversa, mostrar um botão para retornar para a conversa principal: implemented open-subconversation actions on `SubtaskPart` + `task` bubbles, read-only child thread with return CTA, and deterministic child-session resolution fallback hardened for mixed/reordered anchors. - Related commits: 900f3f6 37d9e3e b86256f 9a15889 2d5438a
- [x] Plan the merge between the project selector and the conversations sidebar, grouping conversations by open projects to speed up navigation. - Commit hash: d9e5ec4
- [x] Corrigir o erro ao tentar enviar mensagem após resposta do assistente (hidden response until session switch/retry): implemented async send stale-ID protection and idle final-reconcile bypass during abort suppression. - Related commits: 745c0a8 f1faf4a 4074734 5156e1f f0fda55 92656f3 6443d2e f6376f6 617380f 0bd4c8d
- [x] Corrigir a tela principal quando não tem nenhum servidor configurado: a tela pisca rapidamente apresentando erro de conexão, mas não deveria procurar atualização se não há nenhum servidor cadastrado: skipped startup connection checks when no server exists; added no-server empty state + direct setup wizard button. - Commit hash: 6e35dff
- [x] Suavizar a chegada de tool calls e novas mensagens, bem como o envio de novas mensagens pelo usuário: message/tool arrivals now animate progressively (tail stagger + in-bubble streamed part entrance, reduced-motion respected). - Related commits: 1d41261 cd6ee19
- [x] Restrict session title update service to main sessions only: subsessions do not need and must not use the dynamic title generation system. - Commit hash: 4d9ac2e
- [x] Fix server health inconsistency: in the hamburger menu a red status dot appears, but in Settings the same server is shown as fully healthy. - Commit hash: dbce4a8
- [x] Shorten text in collapsed boxes for mobile: simplify label phrases, remove subtext, and use shorter show/hide button wording. - Commit hash: 98af822
- [x] Speed up project switching using session-like caching methods: session switching is already fast, and project switching should follow a similar strategy for near-instant transitions. - Related commits: f432a33 facd736
- [x] Make New Chat open instantly: switched to draft-first flow and deferred remote session creation to first send, with regression coverage across queue/direct/interrupt send paths. - Related commits: 280c8a2 a788a3f
- [x] Fix SWR regression where New Chat draft mode leaked across project switches: draft state is now context-scoped (`serverId::directory`), lazy bootstrap is cleared on context transition, and async session creation ignores stale post-switch results. - Related commits: 5e45544 4074734
- [x] Reduce repeated "Loading project context..." stalls on recently visited projects: fast switch now uses bounded subscription cancellation, preserves inactive-context cache on dirty global events, and applies delta-like tail revalidation with full-fetch fallback for active cached sessions. - Related commits: d34dff5 62cb6e2
- [x] Revert bad regression (b0660a2) that silently dropped assistant responses after turn 1: rolled back `msg_*` optimistic ID and `messageId` forwarding, restored `local_user_*` prefix and prefix-based duplicate detection. Persisted as permanent guard rails: BEHAVIOR.md spec corrected, ADR-023 Known Pitfalls (P-001), and INVARIANT comments in chat_provider.dart and chat_provider_message_merge_ops.dart. - Related commits: 22a5bb1 0e79a26
- [x] Analisar como reduzir o consumo de dados do App em conexões limitadas como 5G: bounded message-tail fetches, reduced prompt_async fallback polling cadence, bounded/invalidated assistant-id cache, regression test coverage - Related commits: 710efc3 9ae1b1d
- [x] Fix involuntary collapse of expanded tool-call groups while reading: completed tool chains now stay expanded across ordinary parent rebuilds, and shrink auto-snap only jumps when the viewport is near bottom to avoid forced scroll-to-bottom while users review expanded content. - Related commits: 9e31a02 554f7f0 36b621c


### Feature featA: Sync hardening and remote config safety
**Status**: Completed (2026-02-14)

Implemented namespaced selection sync transaction system with explicit state phases (`idle -> pendingRemote -> appliedRemote -> failed`) to prevent abort during active requests. Deferred remote flush until session lifecycle reaches safe idle/busy state. Migrated sync persistence to app-namespaced storage (`agent.__codewalk.options.codewalk.selection`) eliminating workspace `config.json` side effects. Added reasoning status parser to extract `**...**` status lines, hide thinking bubbles, and display latest status in progress indicator. Extended composer status with unified lifecycle model featuring 1s delayed show/hide behavior to prevent UI flashing.
**Commits**: f7c6d0d, 1d5f0be, 6a7ea2a
**ADR**: ADR-026

### Feature featB: Realtime read flow and session rendering
**Status**: Completed (2026-02-14)

Implemented multi-pass scroll-to-bottom algorithm (up to 6 passes with 1px epsilon threshold) to reliably reach conversation end with dynamic message heights. Added dual FAB navigation system (jump-to-latest + jump-to-first) for instant boundary navigation in long conversations. Restructured session list into hierarchical parent/child tree with collapsible sub-conversations for agent/subagent grouping. Implemented route-aware auto-follow behavior that preserves user scroll intent while auto-scrolling to latest on app resume. Reclassified remote abort events from blocking full-screen errors to non-blocking dismissible snackbar with retry action.
**Commits**: a5b4b9d, 73f3f26
**ADR**: ADR-028

### Feature featC: Focus/visibility gate and Files planning
**Status**: Completed (2026-02-19)

Render gate implemented: `_notifyListeners` suppresses rebuilds while app in background, flush on foreground return, SSE stays alive, desktop window focus/blur handlers added. Files bar icons replaced: `visibility_off` → `left_panel_close_rounded` / `right_panel_close_rounded` (Symbols). File comments planning doc created: `ROADMAP.featC.comments-plan.md`.
**Commits**: pending-commit, 96949cb, 51edd51, b97f915, f6d4e43

### Feature featD: Thinking and tool UX polish
**Status**: Completed

Implemented easy-access toggle for Thinking/Tool bubbles, global density settings (compact/normal/spacious), max-height limits (300px) for tool calls with internal scrolling, customized titles for common tool calls, and transitioned header status display to a smooth sweep effect in the composer status line.
**Commits**: (Implicit in ROADMAP.md task markings)

### Feature featE: Session header/context controls
**Status**: Completed (2026-02-15)

Implemented desktop local-server wizard with runtime checks for `opencode serve` availability, installer path detection (binary/npm/bun), and CI multi-OS OpenCode smoke test coverage via GitHub Actions.
**Commits**: 5dc1f31, 01f91bf, 7e2732c, 074dcd2

### Feature featF: Files navigation and drafting UX
**Status**: Completed (2026-02-19)

Delivered phase F focused on files/chat UX stability: replaced the original full remote editor target with a Files viewer that now supports syntax highlighting (full write editor intentionally deferred due to current server Files API limitations), fixed optimistic-message deduplication for attachment messages including local-vs-remote URL mismatch reconciliation, and revised copy gestures so desktop double-click reliably copies the full assistant message while single-tap on markdown code copies only the snippet and links remain openable.
**Commits**: 840bd75, 20e9d17, 0cb2854

### Feature featG: Model favorites and variant selector ergonomics
**Status**: Completed (2026-02-19)

Model favorites: star toggle in model selector, persisted locally via SharedPreferences (scoped per server+project), "Favorites" section above "Recent" in selector, mod+m cycles favorites+recents. Variant popover auto-fit: replaced fixed 220px width with TextPainter-measured width + padding for compact, content-aware sizing.
**Commits**: af0b5ed

### Feature featH: Settings/onboarding/operation polish
**Status**: Completed

Implemented background async provider/model refresh on startup, added OpenCode server installation guides to the setup screen, automated tool-call condensation after assistant response, and transformed thinking bubbles into 4-line auto-scrolling boxes with "show more" expansion.
**Commits**: 4a037f9, 3b931c5

### Feature featI: Agent/shortcut/productivity parity
**Status**: Completed

Full parity implementation: consolidated header layout (context/rename/Files icons), responsive Shortcut panel for mobile keyboards, support for to-do operations, status-line tips, image/attachment previews in chat bubbles, native 'title' agent integration, GitHub-based update checks, background/tray policy controls, and advanced notification rules with sound selection and session grouping.
**Commits**: d2fd909, 51d6195, 20c5dc6, fb6e118, 7e2732c

### Feature featJ: Speech-to-text platform matrix
**Status**: Completed (2026-02-18)

Abstracted `SpeechInputService` for cross-platform STT, implemented native Android/iOS/macOS drivers with auto-punctuation and silence detection, and added Sherpa-ONNX on-device engine for Linux with model management.
**Commits**: e73f15e, 52a35e7, 86b8162, 0347e88, 148b650, 1f4677c, a8a5d96, 889ea9a, 317f02e, addc1ac, f4108fe

### Feature featK: First-run onboarding wizard
**Status**: Completed (2026-02-19)

Implemented OnboardingWizardPage with 3-step flow (Welcome, Server Setup, Ready). Added `skipOnboardingWizard` flag in ExperienceSettings with gate in AppShellPage via Consumer2. Extracted ServerSetupQuickGuide as reusable widget. Moved Servers to first position in Settings. Added reset app button in About and Setup Wizard button in Servers section.
**Commits**: 92fa47e

### Feature featL: Compaction boundary and low-cost nested history
**Status**: Completed (2026-02-14)

Implemented compaction boundary timeline entry that collapses all pre-compaction messages by default, keeping only compaction response and post-compaction messages visible. Added lazy pre-boundary rendering with session-scoped expansion reset to minimize memory/render cost. Extended boundary detection to handle summary assistant messages as fallback when `CompactionPart` markers are absent. Added selection neutrality guard to prevent compaction-related messages from overriding user-selected agents/models during sync adoption.
**Commits**: fd3ce04, 4af9f01

### Feature featM: Icons to Material Symbols migration
**Status**: Completed (2026-02-20)

Completed full migration of icon usage from `Icons.*` to `Symbols.*` using `material_symbols_icons`, aligning the UI with Material Symbols across mobile and desktop.
**Commits**: e05d2fb

### Feature featN: Material You design system revamp
**Status**: Completed (2026-02-20)

Full Material You design system revamp across four phases: dynamic color engine, adaptive 5-breakpoint layout, M3 component normalization, and accessibility compliance.
**Commits**: b408373, e50f6fc, 27834b2, fd67dd6, a72dc74, a718e57, 2b8e75d, 48cb6cb, f477d6f, c818e5a, 5e2c349, d5cf05c

### Feature featO: Code health & technical debt
**Status**: Completed

Resolved all prioritized technical debt: regression fixes, scope guards, draft UX restoration, dead code elimination (~210 lines removed), and analyzer warning cleanup (0 warnings).
**Commits**: 00583f0, 4aa38ca, beb5265, 70bcbc6, 51757e8
