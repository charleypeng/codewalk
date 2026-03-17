---
feature: "Session Management Improvements"
spec: |
  Bug fixes and improvements related to session archiving and hierarchical session handling.
---

## Task List

### Feature 1: Session Archiving & Subsession Handling

Description: Fix issues where archived sessions leave orphaned subsessions visible in the list

- [ ] 1.01 Ao arquivar uma sessão, as subsessões deveriam ser ocultas também, percebi que em algumas situações elas ficam orfãs na lista como se fossem sessões principais
- [ ] 1.02 Ocultar additions: e deletions: da lista lateral de sessões
- [ ] 1.03 Quando uma sessão principal com menos de uma horas atrás não foi lida ainda após receber uma resposta final mudar a cor dela para destaque, respeitando as cores do tema atual. O objetivo é sinalizar novidade. Se passou de uma hora não destacar mais.
- [ ] 1.04 Em 'Display Toggles' adicionar opção 'Recent sessions' que quando ativada mostrar as 5 sessões mais recentes acima dos grupos de projetos em 'Conversations', a ideia é acesso rápido às 5 sessoes primarias mais recentes independente do projeto. Cada item deve oculpar uma linha só, ter uma tag/badge sinalizando o nome do projeto.
