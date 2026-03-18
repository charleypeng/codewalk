---
feature: "Session Management Improvements"
spec: |
  Bug fixes and improvements related to session archiving and hierarchical session handling.
---

## Task List

### Feature 1: Session Archiving & Subsession Handling

Description: Fix issues where archived sessions leave orphaned subsessions visible in the list

- [x] 1.01 Ao arquivar uma sessão, as subsessões deveriam ser ocultas também, percebi que em algumas situações elas ficam orfãs na lista como se fossem sessões principais - Commit hash: 931ca32
- [x] 1.02 Ocultar additions: e deletions: da lista lateral de sessões - Commit hash: 931ca32
- [x] 1.03 Quando uma sessão principal com menos de uma horas atrás não foi lida ainda após receber uma resposta final mudar a cor dela para destaque, respeitando as cores do tema atual. O objetivo é sinalizar novidade. Se passou de uma hora não destacar mais. - Commit hash: 931ca32
- [x] 1.04 Em 'Display Toggles' adicionar opção 'Recent sessions' que quando ativada mostrar as 5 sessões mais recentes acima dos grupos de projetos em 'Conversations', a ideia é acesso rápido às 5 sessoes primarias mais recentes independente do projeto. Cada item deve oculpar uma linha só, ter uma tag/badge sinalizando o nome do projeto. - Commit hash: 931ca32

### Feature 2: Onboarding Wizard Revamp

Description: Redesign the onboarding wizard to be more intuitive and accessible for users unfamiliar with OpenCode

- [x] 2.01 Revamp do wizard de onboard para ficar mais fácil ainda, principalmente pra quem não sabe o que é OpenCode - Commit hash: d6fcc19
  - Note: O onboarding agora explica o que é OpenCode de forma mais clara e inclui uma superfície de debug separada para configuração do OpenCode
- [ ] 2.02 Apontar balões estilo tour para usar a primeira vez após servidor configurado e funcionando. Após concluir o onboard com sucesso, mostrar botão para ir pra tela principal
- [ ] 2.03 Inicialmente selecionar o modelo opencode/big-pickle automaticamente após onboard

### Feature 3: UI/UX & Platform Improvements

Description: Various UI/UX enhancements, snackbar improvements, task bubble updates, and platform-specific fixes

**Note:** This feature delivered comprehensive improvements including debounced server health notifications, tap-to-dismiss snackbars, task bubble command previews, mobile back navigation handling, ESC key composer focus fixes, simplified server status indicators with inline positioning, filtered bubble group visibility, session-scoped composer draft persistence, and per-agent model/variant memorization — all focused on refining chat UX, platform reliability, and local persistence.

- [x] 3.01 Evitar snackbar sobre servidor unhealthy, usar debounce de 5 segundos e só depois mostrar - Commit hash: 44bbab6
- [x] 3.02 Qualquer snackbar que não tiver botões de opções, clicar em qualquer parte do snackbar deve fazer ele se fechar - Commit hash: 44bbab6
- [x] 3.03 Quando uma bubble task estiver em execução, mostrar o último comando executado numa linha da bubble, similar a OpenCode Web/ADR 023 - Commit hash: 44bbab6
- [x] 3.04 Verificar se o botão 'Permission auto-approve' poderia ser server-side, pois atualmente é local e está conflitando com a economia de recursos do codewalk pois só aprova os pedidos quando a janela é colocada em foreground. Verificar como o OpenCode Web faz. Em último caso, ajustar a dinâmica de background pra ser mais confiável nesse sentido (junto com as notificações) - Commit hash: 44bbab6
- [x] 3.05 No mobile, tecla voltar: se estiver em uma subsessão, voltar para a principal; se estiver numa sessão primária, mostrar o drawer de conversations; se apertar voltar de novo, enviar o app para background - Commit hash: 44bbab6
- [x] 3.06 Algum bug não está fazendo single ESC focar no input do composer - Commit hash: 44bbab6
- [x] 3.07 Simplificar sistema de status do servidor: verde quando conectado e recebendo/enviando dados (independente de oscilações), laranja quando dados estão demorando mais que esperado (e ainda não chegou nada), vermelho quando realmente sem responder - Commit hash: 44bbab6
- [x] 3.08 Sistema de status do servidor: texto de status menor e posicionado logo após o nome do servidor em vez de alinhado à direita, para evitar ellipsis desnecessário quando há espaço para mostrar mais - Commit hash: 44bbab6
- [x] 3.09 Quando 'Display Options' filtrar um grupo de bubbles a ponto de ficar vazio, o grupo deve sumir ao invés de mostrar vazio - Commit hash: 44bbab6
- [x] 3.10 Salvar automaticamente o texto do input do composer como rascunho local relacionado à sessão. Ao trocar de sessão, mostrar o rascunho da sessão atual ou vazio se não existir - Commit hash: 44bbab6
- [x] 3.11 Memorizar localmente a relação agent + model + variant por agente. Ao trocar de agente, se houver memória salva, selecionar automaticamente o último modelo (e sua variante) salvo - Commit hash: 44bbab6
- [x] 3.12 Corrigir bounce do viewport durante turns busy: updates passivos (refresh, deltas realtime e pulsos de status) não podem disputar com o viewport owner ativo nem recolapsar grupos de trabalho durante o turno - Commit hash: d781708

### Feature 4: OpenCode Release Monitoring Skill

Description: Create a skill to monitor OpenCode releases and identify potential impacts on CodeWalk

- [ ] 4.01 Criar uma skill que visita https://github.com/anomalyco/opencode/releases e verifica como as mudanças podem afetar ou necessitar atualizar o CodeWalk, em especial as sessões Core/Desktop/Web
