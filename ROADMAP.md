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

- `ROADMAP.featQ.md` - Cross-platform UX and settings polish

### Next Recommended Feature

- `featQ` - `ROADMAP.featQ.md` (NEXT: Cross-platform UX and settings polish)

### Backlog Pack Dependency Order

1. `ROADMAP.featQ.md` (Cross-platform UX and settings polish - isolated track, can run anytime)

Notes:
- Features featA through featO have been completed and archived.

### Backlog Pack Execution Checklist

- [~] `featQ` - `ROADMAP.featQ.md` (Cross-platform UX and settings polish)

Use the same status convention from Legend for active execution updates (`[~]`, `[x]`, `[/]`).

Completed backlog items moved to `ROADMAP.archive.done.md` (section: Backlog Wave Completed Items).

### Open Backlog by Pack

#### `featQ` Cross-platform UX and settings polish

- [ ] Investigate and fix conversation continuity when switching sessions/projects... - Related commits: acce617 9dcd773 1581c65 cdee253 1fcf33e 68baebe 61934e9 0ee474c df9ec9e 931d9a8
- [ ] Investigate and fix conversation-open click behavior: double-click freeze and sidebar sync. - Commit hash: 204114e
- [~] Ajustar ciclagem de atalhos para comportamento tipo Alt+Tab: hoje a ciclagem percorre lista de recentes/favoritos sem priorizar o último item anterior. Implementar primeira ação focada no último usado anterior para troca rápida entre dois itens, com avanço sequencial para demais recentes apenas em pressões subsequentes dentro de janela curta (ex.: 2s). DoD: 1) primeira ativação do atalho alterna para o último item anterior usado; 2) segunda/terceira ativações em sequência (janela temporal) avançam na lista de recentes; 3) comportamento consistente para agente, modelo e variante; 4) fallback previsível quando não houver histórico suficiente.
- [ ] Canned answers manager for fast reply
- [x] Substituir ícone lateral por badges flutuantes na lista de sessões: remover o ícone fixo à esquerda de cada sessão/conversa (que consome espaço no mobile) e adotar badges flutuantes compactos. Incluir sistema de badges de estado para indicar sessões que exigem atenção. DoD: 1) ícone lateral removido da lista de sessões no mobile; 2) badges flutuantes compactos sem prejuízo de legibilidade/tap target; 3) badges de atenção para estados relevantes (ex.: nova resposta, question pendente, erro/notificação); 4) estilo alinhado ao Material You (MD3) e consistente entre mobile/desktop. - Related commits: cda2973 06a8194 eae9883
- [x] Exibir badge no menu hambúrguer para sessões fora de foco que exigem atenção: em cenário multi-sessão no mobile, mostrar indicador visual no ícone/menu hambúrguer quando houver sessão não focada com evento pendente (resposta concluída, question aguardando ação, erro/notificação relevante). DoD: 1) badge aparece quando qualquer sessão fora de foco tiver estado de atenção; 2) badge desaparece/atualiza ao consumir o evento ou focar a sessão; 3) diferenciação mínima de tipo de evento (ex.: dot/contador/estado) sem poluir UI; 4) estilo coerente com Material You (MD3) e boa visibilidade em telas pequenas. - Related commits: cda2973 06a8194 eae9883
- [ ] In Settings > Shortcuts, review shortcut coverage and add missing options.
- [ ] Add shortcut to enable/disable STT in Shortcuts.
- [ ] Reorganize the "Project Context" screen for a more dynamic visual UX; tapping a project opens it immediately and closes the dialog, removing the need for a separate open button next to trash.
- [ ] Replace the current project selection dialog with an inline rich select/dropdown component.
- [ ] Investigate and fix intermittent blank history on conversation open: chat can appear empty until pull/scroll, likely due to auto-scroll overscroll leaving the viewport outside the content.
- [ ] After returning from background, position the conversation at the start of the most recent message (top of text) instead of at the end.
- [ ] In composer, adjust ArrowUp/ArrowDown without modifiers for multiline behavior before history navigation; with modifiers keep default editor behavior.
- [ ] Plan the merge between the project selector and the conversations sidebar, grouping conversations by open projects to speed up navigation.
- [ ] Allow pinning sessions in the Conversations sidebar.
