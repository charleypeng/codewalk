---
roadmap: "CodeWalk Solo Migration Roadmap"
created_on: "2026-02-09"
execution_mode: "feature-by-feature"
source_project: "https://github.com/easychen/openMode"
---

## Execution Protocol

1. Trigger command pattern: `implement feat XXX now` (example: `implement feat 006 now`).
2. During execution:
   - mark active tasks as `[~]`,
   - mark completed tasks as `[x]`,
   - mark blocked tasks as `[/]` with blocker reason.
3. Complete all tasks in `ROADMAP.featXXX.md` before moving to the next feature unless a blocker is explicit.
4. After full completion of a feature, summarize implementation in `ROADMAP.md` and keep only necessary long-form notes.

## Task List

Concluded historical features were archived to `ROADMAP.archive.done.md` to keep this file focused on active backlog execution.

## Legend

- [x] Done
- [~] In progress now
- [/] Partially done but blocked
- [!] Won't do (with reason)
- [ ] Not started

## Pending Backlog

### Backlog Execution Packs

- `featQ` - Cross-platform UX and settings polish (tracked inline in this file)

### Next Recommended Feature

- `featQ` - inline in `ROADMAP.md` (NEXT: Cross-platform UX and settings polish)

### Backlog Pack Dependency Order

1. `featQ` in `ROADMAP.md` (Cross-platform UX and settings polish - isolated track, can run anytime)

Notes:
- Features featA through featO have been completed and archived.

### Backlog Pack Execution Checklist

- [~] `featQ` - tracked in `ROADMAP.md` (Cross-platform UX and settings polish)

Use the same status convention from Legend for active execution updates (`[~]`, `[x]`, `[/]`).

Completed backlog items moved to `ROADMAP.archive.done.md` (section: Backlog Wave Completed Items).

### Open Backlog by Pack

#### `featQ` Cross-platform UX and settings polish

- [x] Investigate and fix conversation continuity when switching sessions/projects (hidden response until session switch/retry): implemented async send stale-ID protection and idle final-reconcile bypass during abort suppression. - Related commits: acce617 9dcd773 1581c65 cdee253 1fcf33e 68baebe 61934e9 0ee474c df9ec9e 931d9a8 745c0a8 f1faf4a
- [x] Investigate and fix conversation-open click behavior: double-click freeze and sidebar sync. - Related commits: 204114e 09c1641 eccec6b dfa9754 b5cda81
- [x] Ajustar ciclagem de atalhos para comportamento tipo Alt+Tab: hoje a ciclagem percorre lista de recentes/favoritos sem priorizar o último item anterior. Implementar primeira ação focada no último usado anterior para troca rápida entre dois itens, com avanço sequencial para demais recentes apenas em pressões subsequentes dentro de janela curta (ex.: 2s). DoD: 1) primeira ativação do atalho alterna para o último item anterior usado; 2) segunda/terceira ativações em sequência (janela temporal) avançam na lista de recentes; 3) comportamento consistente para agente, modelo e variante; 4) fallback previsível quando não houver histórico suficiente. - Related commits: 2086730 c19d346
- [ ] Canned answers manager for fast reply
- [x] Substituir ícone lateral por badges flutuantes na lista de sessões: remover o ícone fixo à esquerda de cada sessão/conversa (que consome espaço no mobile) e adotar badges flutuantes compactos. Incluir sistema de badges de estado para indicar sessões que exigem atenção. DoD: 1) ícone lateral removido da lista de sessões no mobile; 2) badges flutuantes compactos sem prejuízo de legibilidade/tap target; 3) badges de atenção para estados relevantes (ex.: nova resposta, question pendente, erro/notificação); 4) estilo alinhado ao Material You (MD3) e consistente entre mobile/desktop. - Related commits: cda2973 06a8194 eae9883
- [x] Exibir badge no menu hambúrguer para sessões fora de foco que exigem atenção: em cenário multi-sessão no mobile, mostrar indicador visual no ícone/menu hambúrguer quando houver sessão não focada com evento pendente (resposta concluída, question aguardando ação, erro/notificação relevante). DoD: 1) badge aparece quando qualquer sessão fora de foco tiver estado de atenção; 2) badge desaparece/atualiza ao consumir o evento ou focar a sessão; 3) diferenciação mínima de tipo de evento (ex.: dot/contador/estado) sem poluir UI; 4) estilo coerente com Material You (MD3) e boa visibilidade em telas pequenas. - Related commits: cda2973 06a8194 eae9883
- [ ] In Settings > Shortcuts, review shortcut coverage and add missing options.
- [ ] Add shortcut to enable/disable STT in Shortcuts.
- [x] In Settings > About, create an independent update system for new versions.
- [x] In About, add "check updates on open" option (default on), with toast and update button.
- [x] Reorganize the "Project Context" screen for a more dynamic visual UX; tapping a project opens it immediately and closes the dialog, removing the need for a separate open button next to trash. - Related commits: ee0b95b 725dda7
- [x] Replace the current project selection dialog with an inline rich select/dropdown component. - Commit hash: 0cc892c
- [x] Investigate and fix chat flicker and intermittent blank history on conversation open/update: stabilized tool-call rendering, fixed empty-session blink, and improved revalidation stability. - Related commits: 26c8448 9351919
- [x] Load older history on top reach: implemented top-scroll trigger to fetch previous message batches. - Commit hash: 8b364fd
- [ ] After returning from background, position the conversation at the start of the most recent message (top of text) instead of at the end.
- [ ] In composer, adjust ArrowUp/ArrowDown without modifiers for multiline behavior before history navigation; with modifiers keep default editor behavior.
- [x] Plan the merge between the project selector and the conversations sidebar, grouping conversations by open projects to speed up navigation. - Commit hash: d9e5ec4
- [ ] Allow pinning sessions in the Conversations sidebar.
- [x] Corrigir o erro ao tentar enviar mensagem após resposta do assistente (hidden response until session switch/retry): implemented async send stale-ID protection and idle final-reconcile bypass during abort suppression. - Related commits: 745c0a8 f1faf4a
- [x] Corrigir a tela principal quando não tem nenhum servidor configurado: a tela pisca rapidamente apresentando erro de conexão, mas não deveria procurar atualização se não há nenhum servidor cadastrado: skipped startup connection checks when no server exists; added no-server empty state + direct setup wizard button. - Commit hash: 6e35dff
- [ ] Suavizar a chegada de tool calls e novas mensagens, bem como o envio de novas mensagens pelo usuário: atualmente tudo aparece de uma vez, mas com animação de deslize a experiência fica mais atraente.
- [x] Restrict session title update service to main sessions only: subsessions do not need and must not use the dynamic title generation system. - Commit hash: 4d9ac2e
- [x] Fix server health inconsistency: in the hamburger menu a red status dot appears, but in Settings the same server is shown as fully healthy. - Commit hash: dbce4a8
- [ ] Verify whether background notifications are working correctly on Android.
- [ ] Shorten text in collapsed boxes for mobile: simplify label phrases, remove subtext, and use shorter show/hide button wording.
- [x] Speed up project switching using session-like caching methods: session switching is already fast, and project switching should follow a similar strategy for near-instant transitions. - Related commits: f432a33 facd736
- [x] Make New Chat open instantly: switched to draft-first flow and deferred remote session creation to first send, with regression coverage across queue/direct/interrupt send paths. - Related commits: 280c8a2 a788a3f
- [x] Fix SWR regression where New Chat draft mode leaked across project switches: draft state is now context-scoped (`serverId::directory`), lazy bootstrap is cleared on context transition, and async session creation ignores stale post-switch results. - Commit hash: 5e45544
- [x] Reduce repeated "Loading project context..." stalls on recently visited projects: fast switch now uses bounded subscription cancellation, preserves inactive-context cache on dirty global events, and applies delta-like tail revalidation with full-fetch fallback for active cached sessions. - Related commits: d34dff5 62cb6e2
