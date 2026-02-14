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

- `ROADMAP.featA.md` - Sync hardening and remote config safety (tasks 2, 3, 9)
- `ROADMAP.featB.md` - Realtime read flow and session rendering (tasks 4, 5, 7, 8)
- `ROADMAP.featC.md` - Long conversation performance and files planning (tasks 6, 28, 30)
- `ROADMAP.featD.md` - Thinking/tool UX polish (tasks 16, 17, 21, 27, 29)
- `ROADMAP.featE.md` - Session header and context controls (tasks 11, 12, 13)
- `ROADMAP.featF.md` - Files navigation and drafting UX (tasks 31, 32, 33)
- `ROADMAP.featG.md` - Model favorites and variant selector ergonomics (tasks 34, 35)
- `ROADMAP.featH.md` - Settings/onboarding/operation polish (tasks 18, 19, 20, 22, 38)
- `ROADMAP.featI.md` - Agent/shortcut/productivity parity (tasks 10, 14, 15, 23, 24, 25, 26, 37 + desktop selector width follow-up)
- `ROADMAP.featJ.md` - Speech-to-text platform matrix and Linux strategy (task 1)
- `ROADMAP.featK.md` - First-run onboarding wizard (task 36)
- `ROADMAP.featL.md` - Post-compaction historical bubbles collapse and lazy nested rendering (new task)

### Backlog Pack Dependency Order

1. `ROADMAP.featA.md` (sync hardening baseline)
2. `ROADMAP.featB.md` (realtime read/render foundation)
3. `ROADMAP.featL.md` (compaction boundary + pre-boundary collapse)
4. `ROADMAP.featD.md` (thinking/tool UX controls)
5. `ROADMAP.featH.md` (startup/settings/tool-surface polish)
6. `ROADMAP.featE.md` (composer popover/local server/shortcuts reliability)
7. `ROADMAP.featI.md` (agent/shortcut/productivity parity)
8. `ROADMAP.featF.md` (files drafting UX + duplicate/copy interaction fixes)
9. `ROADMAP.featG.md` (favorites and variant selector ergonomics)
10. `ROADMAP.featC.md` (focus/visibility render gate + files planning)
11. `ROADMAP.featJ.md` (speech-to-text platform matrix)
12. `ROADMAP.featK.md` (first-run onboarding wizard)

Notes:
- Prefer this order by default to reduce regression risk in timeline/sync behavior.
- If needed, `featJ` and `featK` can run earlier as mostly isolated tracks.

### Backlog Pack Execution Checklist

- [x] `featA` - `ROADMAP.featA.md` (sync hardening baseline)
- [x] `featB` - `ROADMAP.featB.md` (realtime read/render foundation)
- [x] `featL` - `ROADMAP.featL.md` (compaction boundary + pre-boundary collapse)
- [x] `featD` - `ROADMAP.featD.md` (thinking/tool UX controls)
- [ ] `featH` - `ROADMAP.featH.md` (startup/settings/tool-surface polish)
- [ ] `featE` - `ROADMAP.featE.md` (composer popover/local server/shortcuts reliability)
- [ ] `featI` - `ROADMAP.featI.md` (agent/shortcut/productivity parity)
- [ ] `featF` - `ROADMAP.featF.md` (files drafting UX + duplicate/copy interaction fixes)
- [ ] `featG` - `ROADMAP.featG.md` (favorites and variant selector ergonomics)
- [ ] `featC` - `ROADMAP.featC.md` (focus/visibility render gate + files planning)
- [ ] `featJ` - `ROADMAP.featJ.md` (speech-to-text platform matrix)
- [ ] `featK` - `ROADMAP.featK.md` (first-run onboarding wizard)

Use the same status convention from Legend for active execution updates (`[~]`, `[x]`, `[/]`).

Completed backlog items moved to `ROADMAP.archive.done.md` (section: Backlog Wave Completed Items).

### Open Backlog by Pack

#### `featA` Sync hardening and remote config safety ✅

**Status**: Completed (2026-02-14)

Implemented namespaced selection sync transaction system with explicit state phases (`idle -> pendingRemote -> appliedRemote -> failed`) to prevent abort during active requests. Deferred remote flush until session lifecycle reaches safe idle/busy state. Migrated sync persistence to app-namespaced storage (`agent.__codewalk.options.codewalk.selection`) eliminating workspace `config.json` side effects. Added reasoning status parser to extract `**...**` status lines, hide thinking bubbles, and display latest status in progress indicator. Extended composer status with unified lifecycle model featuring 1s delayed show/hide behavior to prevent UI flashing.

**Commits**: f7c6d0d, 1d5f0be, 6a7ea2a
**ADR**: ADR-026

#### `featB` Realtime read flow and session rendering ✅

**Status**: Completed (2026-02-14)

Implemented multi-pass scroll-to-bottom algorithm (up to 6 passes with 1px epsilon threshold) to reliably reach conversation end with dynamic message heights. Added dual FAB navigation system (jump-to-latest + jump-to-first) for instant boundary navigation in long conversations. Restructured session list into hierarchical parent/child tree with collapsible sub-conversations for agent/subagent grouping. Implemented route-aware auto-follow behavior that preserves user scroll intent while auto-scrolling to latest on app resume. Reclassified remote abort events from blocking full-screen errors to non-blocking dismissible snackbar with retry action.

**Commits**: a5b4b9d, 73f3f26
**ADR**: ADR-028

#### `featC` Focus/visibility gate and Files planning

- [ ] Quando a janela perder foco, continuar recebendo pooling mas não renderizar novas mensagens até a tela ganhar foco novamente para evitar desgaste de eficiencia. Porém somente quando estiver fora e foco e nao visivel pois o usuario pode estar olhando mesmo sem foco (desktop, tablets etc)
- [ ] Na barra 'Files' tem um ícone de olho cortado pra ocultar a barra, trocar para algo mais intuitivo como um ícone estilo <| (encontre um ícone nativo)
- [ ] Criar planejamento para os arquivos abertos em Files permitir comentar linhas igual no OpenCode web

#### `featD` Thinking and tool UX polish

- [x] Inserir botão de fácil acesso para exibir/ocultar Thinking/Tool bubbles (toggle global no topo com popover)
- [x] Adicionar opção em Settings para escolher densidade de todos os elementos do app (denso, normal, espaçoso)
- [x] Limitar altura ao expandir conteúdo de uma tool call (max-height responsivo com teto de 300px)
- [x] Personalizar título das tool calls mais comuns, e tratar respostas para aparência mais suave visando UX
- [x] Substituir destaque visual do status ao lado do título por efeito transitório na linha de status do composer (mantendo knob de contexto atual)

#### `featE` Session header/context controls

- [ ] Ajustar popover de sugestões no Android para nunca cobrir o input com teclado aberto em todos os teclades/dispositivos (validar em device real com Gboard e Samsung Keyboard)
- [ ] Emular `opencode serve` internamente como opção de servidor local (permitir ao CodeWalk iniciar e gerenciar um servidor OpenCode embutido sem depender de instância externa)
- [ ] Fazer atalhos de teclado funcionarem de verdade

#### `featF` Files navigation and drafting UX

- [ ] Planejar criar um editor dev básico para arquivos abertos de Files
- [ ] Corrigir bug que algumas mensagens enviadas aparecem duas vezes seguidas
- [ ] Duplo click em respostas do assistente deveria copiar tudo pra clipboard, mas com frequencia seleciona uma palavra do texto, mas isso deveria ser comportamento de tocar e segurar (apenas pra mensagens do assistente/servidor)

#### `featG` Model favorites and variant selector ergonomics

- [ ] Adicionar suporte a modelos favoritos
- [ ] Reduzir a largura do popover do select de variant

#### `featH` Settings/onboarding/operation polish

- [ ] Refresh providers/model em background de forma assíncrona ao abrir o app
- [ ] Adicionar instruções básicas de como instalar e executar um servidor OpenCode na tela de adicionar servidor
- [ ] Condensar as chamas de tool calls em um collapsable quando a resposta final do assistente chegar
- [ ] Tornar bolha de thinking em uma caixa de no máximo 4 linhas, o texto vai subindo suavemente assim que chega, somente se clicar em show more expande um pouco mais mas com altura limitada ativando barra de rolagem interna se necessário

#### `featI` Agent/shortcut/productivity parity

- [ ] Opções em Settings para decidir se app fica em background. Mobile: persistente notification, desktop: tray
- [ ] Exibir seção `Shortcuts` no mobile quando houver teclado físico conectado
- [ ] Verificar atualizações baseadas nos releases do GitHub usando a API pública do GitHub
- [ ] Adicionar suporte a todowrite, todoread e tudo relacionado a to-do
- [ ] Mudar botão de contexto para o lado do título da sessão
- [ ] Remover botão lápis do lado do título da sessão, deixando apenas em outros lugares e clica no título (já é assim)
- [ ] Mudar o ícone do botão 'Files' para algo mais intuitivo, talvez ícone de tree
- [ ] Aumentar o espaço/largura do select no topo para o projeto atual quando no desktop. A largura atual está colocando ellipsis muito rápido com o espaço todo de uma tela grande (desktop)
- [ ] Criar lista de dicas de uma frase para mostrar enquanto aguarda respostas do servidor mas nada chegou ainda

#### `featJ` Speech-to-text platform matrix

- [ ] No desktop, pesquisar como usar microfone speech-to-text no linux. Pesquisar também se a API atual já funciona no mac/windows/iOS

#### `featK` First-run onboarding wizard

- [ ] Wizard/onboarding quando abrir o app pela primeira vez: dialog central perguntando qual servidor cadastrar/usar e toggle do serviço do ch.at

#### `featL` Compaction boundary and low-cost nested history ✅

**Status**: Completed (2026-02-14)

Implemented compaction boundary timeline entry that collapses all pre-compaction messages by default, keeping only compaction response and post-compaction messages visible. Added lazy pre-boundary rendering with session-scoped expansion reset to minimize memory/render cost. Extended boundary detection to handle summary assistant messages as fallback when `CompactionPart` markers are absent. Added selection neutrality guard to prevent compaction-related messages from overriding user-selected agents/models during sync adoption.

**Commits**: fd3ce04, 4af9f01
**ADR**: ADR-027
