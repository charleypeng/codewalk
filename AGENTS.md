# CodeWalk - Regras Específicas do Projeto

> ⚠️ **Base**: Todas as regras de `/home/helio/MEGA/CONFIG/AGENTS.md` se aplicam. Este arquivo contém apenas especificidades do CodeWalk.

## Contexto do Projeto

CodeWalk é um projeto que visa permitir acessar agents de código de qualquer lugar, seja por desktop, seja pelo celular.

- **Toda implementação deve ser pensada para mobile e desktop**. Preferencialmente de maneira unificada e responsiva. **Prioridade para UX no mobile**.
- Ao concluir uma mudança, verificar se ela exige novo teste ou atualização de teste existente.
- Em ajustes visuais, confirmar com o usuário o bloco/tela exato citado antes de alterar; evitar suposições.

## 🚀 Fluxo Específico: Build Android

- **Após concluir modificações de código**: Execute `make precommit` **imediatamente** (pode ser em background).
- **Ordem crucial**: `make precommit` deve ser executado logo após conclusão do código, ANTES de alterar arquivos .md ou fazer commit.
- **Se apenas arquivos estáticos (.md, texto) mudaram**: Não é necessário `make precommit`.

### Caption Dinâmica no Upload

- No upload via `tdl` (feito em `make android` vindo de `make precommit`), o `--caption` deve ser **dinâmico e direto**.
- **Evite**: "Ajustes mais recentes feitos"
- **Prefira**: "Corrigida altura da caixa Thinking Process"

## 📦 Liberação de Nova Tag / Release

- Fluxo de versionamento/changelog/push/tag já está definido no AGENTS global.
- Complemento local: após push/tag, fazer watch da pipeline `@.github/workflows/release.yml` a cada 60s e atualizar o usuário a cada status.
- Se qualquer etapa falhar, cancelar a pipeline por completo, analisar os erros e decidir entre:
  - corrigir e repetir o fluxo;
  - avisar o usuário e aguardar instruções.
