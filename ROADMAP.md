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

- [ ] `featA` - `ROADMAP.featA.md` (sync hardening baseline)
- [ ] `featB` - `ROADMAP.featB.md` (realtime read/render foundation)
- [ ] `featL` - `ROADMAP.featL.md` (compaction boundary + pre-boundary collapse)
- [ ] `featD` - `ROADMAP.featD.md` (thinking/tool UX controls)
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

#### `featA` Sync hardening and remote config safety

- [ ] Mudar agent/model/variant está causando abort na requisição em andamento, parece ser um bug do sistema de sync que criamos recentemente
- [ ] Mudar agent/model/variant está criando um arquivo config.json no workspace em uso, o que é um problema porque não faz parte do trabalho do usuario, parece ser um efeito colateral do sistema de sync que criamos recentemente
- [ ] Muitas das bolhas tem uma bolha interna chamada "Thinking Process" que dentro mostra o thinking mas as vezes é o status do que esta sendo feito naquele momento. Se o backend não informa isso de forma clara basta identificar o padrão: quando é uma mensagem de status a primeira linha desse thinking é envolvida por **, exemplo: **Pesquisando melhores formas** ou **Editando arquivo README.md**, etc. Neste caso, ocultar a bolha de thinking process e mostrar no lugar do texto fixo 'Receiving response...', sempre o ultimo recebido desse tipo.

#### `featB` Realtime read flow and session rendering

- [ ] Tratar exibição de agents/subagents, atualmente é exibido como se fosse uma sessão/conversa extra, mas deveria ser agrupado como subconversa, talvez um collapsable na conversa atual
- [ ] Ao retomar uma conversa ou voltar pra tela, se o usuario nao subiu a barra de rolagem manualmente, deve avancar pra ultima mensagem recebida automaticamente
- [ ] Quando a conversa fica muito longa acaba deixando o app lento, pesquisar sobre virtual scrolling
- [ ] Quando um aparelho manda abort, outro aparelho conectado mostra um erro que cobre toda a conversa com um botão Retry, quando na verdade deveria ser apenas um toast de 4 segundos com botão Retry. Mas só nos casos de erros reais, abort geralmente significa que o usuário parou para informar algo diferente do pedido original, atualmente existe uma bolha que mostra mas é bem vermelha e agressiva precisa ser um pouco mais suave com uma mensagem um pouco mais amigável algo como 'O que gostaria de fazer diferente'

#### `featC` Focus/visibility gate and Files planning

- [ ] Quando a janela perder foco, continuar recebendo pooling mas não renderizar novas mensagens até a tela ganhar foco novamente para evitar desgaste de eficiencia. Porém somente quando estiver fora e foco e nao visivel pois o usuario pode estar olhando mesmo sem foco (desktop, tablets etc)
- [ ] Na barra 'Files' tem um ícone de olho cortado pra ocultar a barra, trocar para algo mais intuitivo como um ícone estilo <| (encontre um ícone nativo)
- [ ] Criar planejamento para os arquivos abertos em Files permitir comentar linhas igual no OpenCode web

#### `featD` Thinking and tool UX polish

- [ ] Inserir botão de fácil acesso para exibir/ocultar o Thinking (toggle rápido no header da mensagem ou área do composer)
- [ ] Adicionar opção em Settings para escolher densidade de todos os elementos do app (denso, normal, espaçoso)
- [ ] Limitar altura ao expandir conteúdo de uma tool call
- [ ] Personalizar título das tool calls mais comuns, e tratar respostas para aparência mais suave visando UX
- [ ] Remover o ícone ao lado do título da sessão (ao lado do lápis), o ícone que mostra o status atual, recebendo resposta etc. Mudar para algo mais elegante como transformar o botão knob de contexto em um loading girando enquanto vem resposta

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

#### `featL` Compaction boundary and low-cost nested history

- [ ] Ao ocorrer compactação manual ou automática, colapsar tudo que veio antes da compactação, mantendo visível apenas a resposta da compactação e o que vier depois; adotar padrão de aninhamento para colapsos internos e garantir custo de renderização/memória mínimo para conteúdo encolhido
