# CodeWalk - Regras Específicas do Projeto

> ⚠️ **Base**: Todas as regras de `/AGENTS.md` principal se aplicam. Este arquivo contém apenas especificidades do CodeWalk.

## Contexto do Projeto

CodeWalk é um projeto que visa permitir acessar agents de código de qualquer lugar, seja por desktop, seja pelo celular.

- **Toda implementação deve ser pensada para mobile e desktop**. Preferencialmente de maneira unificada e responsiva. **Prioridade para UX no mobile, visual moderno, material you**.
- Ao concluir uma mudança, verificar se ela exige novo teste ou atualização de teste existente.
- Em ajustes visuais, confirmar com o usuário o bloco/tela exato citado antes de alterar; evitar suposições.

- Neste projeto, em específico, não usamos `make precommit` diretamente, preferindo separar em `make check` e `make android`
- Documentações base importantes estão em ./ai-docs, faça pelo menos um ls na pasta pra ter conhecimento do que existe.

## 🚀 Fluxo Específico: Build Android para test

- **Após concluir modificações de código**: Execute `make check` **imediatamente** (preferencialmente em background e preferencialmente assincrono).
- **Ordem crucial**: `make check` deve ser executado logo após conclusão do código, ANTES de alterar arquivos .md ou fazer commit.
- **Se apenas arquivos estáticos (.md, texto) mudaram**: Não é necessário `make check` e nem `make android`.
- **Assim que o usuário puder testar**: execute `make android` o mais breve possível pois é um processo relativamente que compila e envia o apk para o telegram. Execute sempre que encerrar uma tarefa envolvendo código. Também preferencialmente em background e assincrono
- **Antes do commit**: Se não mudou nada código desde o último check, não é necessário outro `make check`

### Caption Dinâmica no Upload

- Sempre use`HEY_CAPTION="Minha legenda customizada" make android`
- **Evite**: "Ajustes mais recentes feitos"
- **Prefira**: "Corrigida altura da caixa Thinking Process"

## 📦 Liberação de Nova Tag / Release

- **Usar `make release V=<tipo>`** para liberar novas versões:
  - `make release V=patch` — bump patch (ex: 1.5.4 → 1.5.5)
  - `make release V=minor` — bump minor (ex: 1.5.4 → 1.6.0)
  - `make release V=major` — bump major (ex: 1.5.4 → 2.0.0)
- O comando atualiza `pubspec.yaml` (versão + build number), commita, cria tag e faz push automaticamente.
- **Antes de rodar**: garantir que todas as mudanças de código estejam commitadas. O `make release` só commita o bump de versão.
- Após o push/tag, fazer watch da pipeline `@.github/workflows/release.yml` a cada 60s e atualizar o usuário a cada status. Se não suportar background/assincrono, use comando sleep.
- Se qualquer etapa falhar, cancelar a pipeline por completo, analisar os erros e decidir entre:
  - corrigir e repetir o fluxo;
  - avisar o usuário e aguardar instruções.
- Se tudo passou corretamente revise CODEBASE.md e ADR.md em busca de atualizações necessárias devido últimos commits.
