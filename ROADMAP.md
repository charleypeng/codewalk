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
- [x] 2.02 Apontar balões estilo tour para usar a primeira vez após servidor configurado e funcionando. Após concluir o onboard com sucesso, mostrar botão para ir pra tela principal - Commit hashes: cedda336, e06db5b6, 6140cc31, d57d210, 93137d4, 5d43d3f
- [x] 2.03 Inicialmente selecionar o modelo opencode/big-pickle automaticamente após onboard - Commit hash: 88af23a

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
- [x] 3.12 Corrigir bounce do viewport durante turns busy: updates passivos (refresh, deltas realtime e pulsos de status) não podem disputar com o viewport owner ativo nem recolapsar grupos de trabalho durante o turno - Related commits: d781708 d1cb997 1395955 042705a 9284223 161b9ce 81edb30 4aa9a00 24232eb 5680af9 80ad3a5 49c0f7d 0b1e5a6
- [x] 3.13 Add ModalPrimaryActionShortcuts helper: Enter/NumpadEnter triggers primary action in safe dialogs (workspace, rename, onboarding) — Commit hashes: 97ebf1f, 0e275eb
- [x] 3.14 Redesign compact task bubble: remove View/Show controls, full-bubble tap navigation, icon-only status indicators, latest child-tool progress label fallback, and completed "N tool calls" footer — Commit hash: 4554e47

### Feature 4: Repo-Local OpenCode Agent for Release Impact Review

Description: Create a repo-local OpenCode agent at `.opencode/agents/opencodeNews.md` that inspects OpenCode releases and evaluates CodeWalk impact

- [x] 4.01 Create repo-local agent `.opencode/agents/opencodeNews.md` for OpenCode release impact review, replacing the old `release-monitor` command — Commit hashes: 5d4629d, 6f22c21

### Feature 5: Offline-to-Online Data Reload

Description: Ensure the app automatically reloads initial data when connectivity is restored after an offline start. Currently, if the app launches while offline and the server is unavailable, the project list and related data remain empty even after the connection returns, requiring manual intervention to refresh.

DoD: When the app starts offline and later regains connectivity, recent projects and initial session data should automatically reload without requiring user action (pull-to-refresh or restart).

- [x] 5.01 Detect when the app transitions from offline to online state after initial failed load - Commit hashes: fac3b79, bb16867
- [x] 5.02 Trigger automatic reload of recent projects when connectivity is restored - Commit hashes: fac3b79, bb16867
- [x] 5.03 Ensure session data and sidebar content refreshes without requiring manual action - Commit hashes: fac3b79, bb16867
- [x] 5.04 Handle edge cases: multiple rapid connection changes, server still unavailable after network recovery - Commit hashes: fac3b79, bb16867

### Feature 6: Host-Discovered Quota and Rate-Limit Monitoring (ADR-029)

Description: Implement a host-discovered quota tracking feature for the "Context usage" popup. Uses a strategy-chain transport (OpenChamber REST → hidden ephemeral shell fallback) to surface provider rate-limits without client-side credentials. UI shows grouped providers with severity progress bars and Pace predictions inside the existing Context usage popup.

DoD: Context usage popup shows live provider quotas when data is available; falls back silently when neither REST nor shell path returns data; zero-credential client maintains ADR-001 security boundaries; grouped UI with Pace follows ADR-029 semantics.

- [x] 6.01 Domain entities and Pace calculation utilities — `QuotaSnapshot`, `UsageWindow`, `PaceInfo`, `QuotaProviderGroup`, `QuotaEntry`; pure Dart pace predictor - Commit hashes: edf6b10
- [x] 6.02 Strategy-chain `QuotaRemoteDataSource` — OpenChamber REST fast path + ephemeral shell fallback; DI wiring for `QuotaRemoteDataSource` and `QuotaProvider` - Commit hashes: edf6b10
- [x] 6.03 `QuotaProvider` — TTL-cached polling (60s), server-scoped state, severity-ordered groups - Commit hashes: edf6b10
- [x] 6.04 Quota popup widgets — `QuotaPopupSection`, `QuotaProviderGroupRow`, `QuotaEntryRow`, `PaceLabel` — integrate into Context usage popup after Compact now - Commit hashes: 013e285
- [x] 6.05 Unit tests for pace utils and datasource strategy chain; all 841 tests passing - Commit hashes: 013e285
- [x] 6.06 Update ADR-029, CODEBASE.md, BEHAVIOR.md, and ROADMAP.md to reflect completed implementation - Commit hashes: aaab12d, 5f45938, 533c306

### Feature 7: Upstream Alignment (OpenCode v1.14.x - v1.15.0)

Description: Align CodeWalk with recent upstream changes in OpenCode and OpenChamber, following ADR-023 (Contract-First Compatibility). Includes migration to session-scoped permission routes, HTTP 409 busy handling, heartbeats suppression, and workspace-aware capability discovery.

DoD: All 6 steps from `implement.md` implemented and verified; contract tests updated; no regressions on `prompt_async` or event delivery; compatible with both v1.14+ and legacy servers.

- [x] 7.01 Update Contract Test Harness (Safety First) - Commit hashes: fc93233, b81032e, 1949522, 379c0b6, 5ecd97c, d1e85e0, 67c60b6
- [x] 7.02 Migrate Permission Responses to Session-Scoped Route - Commit hashes: fc93233, b81032e, 1949522, 379c0b6, 5ecd97c, d1e85e0, 67c60b6
- [x] 7.03 Handle HTTP 409 Busy Errors & 400/422 Validation - Commit hashes: fc93233, b81032e, 1949522, 379c0b6, 5ecd97c, d1e85e0, 67c60b6
- [x] 7.04 Ignore `server.heartbeat` Events - Commit hashes: fc93233, b81032e, 1949522, 379c0b6, 5ecd97c, d1e85e0, 67c60b6
- [x] 7.05 Support Workspace Query Parameter - Commit hashes: fc93233, b81032e, 1949522, 379c0b6, 5ecd97c, d1e85e0, 67c60b6
- [x] 7.06 Preserve Typed OpenCode Error Details - Commit hashes: fc93233, b81032e, 1949522, 379c0b6, 5ecd97c, d1e85e0, 67c60b6
