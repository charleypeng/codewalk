# CodeWalk - Regras Específicas do Projeto

> ⚠️ **Base**: Todas as regras de `/home/helio/MEGA/CONFIG/AGENTS.md` se aplicam. Este arquivo contém apenas especificidades do CodeWalk.

## Contexto do Projeto

CodeWalk é um projeto que visa permitir acessar agents de código de qualquer lugar, seja por desktop, seja pelo celular.

- **Toda implementação deve ser pensada para mobile e desktop**. Preferencialmente de maneira unificada e responsiva. **Prioridade para UX no mobile**.
- Ao concluir uma mudança, verificar se ela exige novo teste ou atualização de teste existente.
- Em ajustes visuais, confirmar com o usuário o bloco/tela exato citado antes de alterar; evitar suposições.

- Neste projeto, em específico, não usamos `make precommit` diretamente, preferindo separar em `make check` e `make android`
- Documentações base importantes estão em ./ai-docs, faça pelo menos um ls na pasta pra ter conhecimento do que existe.

## 🚀 Fluxo Específico: Build Android para test

- **Após concluir modificações de código**: Execute `make check` **imediatamente** (preferencialmente em background).
- **Ordem crucial**: `make check` deve ser executado logo após conclusão do código, ANTES de alterar arquivos .md ou fazer commit.
- **Se apenas arquivos estáticos (.md, texto) mudaram**: Não é necessário `make check` e nem `make android`.
- **Assim que o usuário puder testar**: execute `make android` o mais breve possível pois é um processo relativamente que compila e envia o apk para o telegram. Execute sempre que encerrar uma tarefa envolvendo código.
- **Antes do commit**: Se não mudou nada código desde o último check, não é necessário outro `make check`

### Caption Dinâmica no Upload

- Sempre use`TDL_CAPTION="Minha legenda customizada" make android`
- **Evite**: "Ajustes mais recentes feitos"
- **Prefira**: "Corrigida altura da caixa Thinking Process"

## 📦 Liberação de Nova Tag / Release

- Fluxo de versionamento/changelog/push/tag já está definido no AGENTS global.
- Complemento local: após push/tag, fazer watch da pipeline `@.github/workflows/release.yml` a cada 60s e atualizar o usuário a cada status.
- Se qualquer etapa falhar, cancelar a pipeline por completo, analisar os erros e decidir entre:
  - corrigir e repetir o fluxo;
  - avisar o usuário e aguardar instruções.
- Se tudo passou corretamente revise CODEBASE.md e ADR.md em busca de atualizações necessárias devido últimos commits.
