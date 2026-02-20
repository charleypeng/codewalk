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
- `ROADMAP.featM.md` - Icons to Material Symbols migration (technical debt)
- `ROADMAP.featN.md` - Material You design system revamp (responsive, adaptive, modern UX)
- `ROADMAP.featO.md` - Code health & technical debt (bugs, security, performance, cleanup, architecture, tests)
- `ROADMAP.featQ.md` - Cross-platform UX and settings polish

### Next Recommended Feature

- `featM` - `ROADMAP.featM.md` (NEXT: Icons to Material Symbols migration)

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
13. `ROADMAP.featM.md` (Icons to Material Symbols migration - isolated track, can run anytime)
14. `ROADMAP.featN.md` (Material You design system revamp - isolated track, can run anytime)
15. `ROADMAP.featO.md` (Code health & technical debt - isolated track, Groups 1-3 recommended before featF)
16. `ROADMAP.featQ.md` (Cross-platform UX and settings polish - isolated track, can run anytime)

Notes:
- Prefer this order by default to reduce regression risk in timeline/sync behavior.
- If needed, `featJ`, `featK`, `featM`, `featN`, `featO`, and `featQ` can run earlier as mostly isolated tracks.
- `featO` Groups 1-3 (bugs, security, performance) are recommended before `featF` to stabilize the codebase.

### Backlog Pack Execution Checklist

- [x] `featA` - `ROADMAP.featA.md` (sync hardening baseline)
- [x] `featB` - `ROADMAP.featB.md` (realtime read/render foundation)
- [x] `featL` - `ROADMAP.featL.md` (compaction boundary + pre-boundary collapse)
- [x] `featD` - `ROADMAP.featD.md` (thinking/tool UX controls)
- [x] `featH` - `ROADMAP.featH.md` (startup/settings/tool-surface polish)
- [x] `featE` - `ROADMAP.featE.md` (composer popover/local server/shortcuts reliability)
- [x] `featI` - `ROADMAP.featI.md` (agent/shortcut/productivity parity)
- [x] `featF` - `ROADMAP.featF.md` (files drafting UX + duplicate/copy interaction fixes)
- [x] `featG` - `ROADMAP.featG.md` (favorites and variant selector ergonomics)
- [x] `featC` - `ROADMAP.featC.md` (focus/visibility render gate + files planning)
- [x] `featJ` - `ROADMAP.featJ.md` (speech-to-text platform matrix)
- [x] `featK` - `ROADMAP.featK.md` (first-run onboarding wizard)
- [x] `featM` - `ROADMAP.featM.md` (Icons to Material Symbols migration)
- [ ] `featN` - `ROADMAP.featN.md` (Material You design system revamp)
- [x] `featO` - `ROADMAP.featO.md` (Code health & technical debt)
- [ ] `featQ` - `ROADMAP.featQ.md` (Cross-platform UX and settings polish)

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

#### `featC` Focus/visibility gate and Files planning ✅

**Status**: Completed (2026-02-19)

Render gate implemented: `_notifyListeners` suppresses rebuilds while app in background, flush on foreground return, SSE stays alive, desktop window focus/blur handlers added. Files bar icons replaced: `visibility_off` → `left_panel_close_rounded` / `right_panel_close_rounded` (Symbols). File comments planning doc created: `ROADMAP.featC.comments-plan.md`.

- [x] Quando a janela perder foco, continuar recebendo pooling mas não renderizar novas mensagens até a tela ganhar foco novamente para evitar desgaste de eficiencia. Porém somente quando estiver fora e foco e nao visivel pois o usuario pode estar olhando mesmo sem foco (desktop, tablets etc)
- [x] Na barra 'Files' tem um ícone de olho cortado pra ocultar a barra, trocar para algo mais intuitivo como um ícone estilo <| (encontre um ícone nativo)
- [x] Criar planejamento para os arquivos abertos em Files permitir comentar linhas igual no OpenCode web
- [x] File Line References: gutter line numbers, tap/shift-tap selection, selection action bar, FileInputPart context chips in chat input, send pipeline integration. - Commit: 96949cb
  - Fix (51edd51): full-line click area, full-width selection highlight covers gutter+code, dialog closes and focuses composer after "Add to chat", context items sent as inline fenced code blocks instead of FileInputPart attachments to avoid raw XML in response bubbles.
  - Fix (b97f915): on mobile, close both file viewer and Files dialogs when adding line references to context.
  - Fix (f6d4e43): gutter line numbers misaligned with code text — switched gutter from Text.rich to RichText to match HighlightView rendering (no textScaler).

**Commits**: pending-commit, 96949cb, 51edd51, b97f915, f6d4e43

#### `featD` Thinking and tool UX polish

- [x] Inserir botão de fácil acesso para exibir/ocultar Thinking/Tool bubbles (toggle global no topo com popover)
- [x] Adicionar opção em Settings para escolher densidade de todos os elementos do app (denso, normal, espaçoso)
- [x] Limitar altura ao expandir conteúdo de uma tool call (max-height responsivo com teto de 300px)
- [x] Personalizar título das tool calls mais comuns, e tratar respostas para aparência mais suave visando UX
- [x] Substituir destaque visual do status ao lado do título por efeito transitório na linha de status do composer (mantendo knob de contexto atual)

#### `featE` Session header/context controls ✅

**Status**: Completed (2026-02-15)

Implemented desktop local-server wizard with runtime checks for `opencode serve` availability, installer path detection (binary/npm/bun), and CI multi-OS OpenCode smoke test coverage via GitHub Actions.

**Commits**: 5dc1f31, 01f91bf, 7e2732c, 074dcd2

#### `featF` Files navigation and drafting UX ✅

**Status**: Completed (2026-02-19)

Delivered phase F focused on files/chat UX stability: replaced the original full remote editor target with a Files viewer that now supports syntax highlighting (full write editor intentionally deferred due to current server Files API limitations), fixed optimistic-message deduplication for attachment messages including local-vs-remote URL mismatch reconciliation, and revised copy gestures so desktop double-click reliably copies the full assistant message while single-tap on markdown code copies only the snippet and links remain openable.

**Commits**: 840bd75, 20e9d17, 0cb2854
**Post-conclusion**: Performance overhaul eliminating freeze/lag in streaming and large conversations (microtask coalescing, event dedup buffer, timeline/highlight/style caches, build-skip widget conversion, lazy copy text) in `00b326f`. Upgraded flutter_secure_storage 9.2.4 → 10.0.0 (Java 17, linux 3.0.0) in `547da29`.

#### `featG` Model favorites and variant selector ergonomics ✅

**Status**: Completed (2026-02-19)

Model favorites: star toggle in model selector, persisted locally via SharedPreferences (scoped per server+project), "Favorites" section above "Recent" in selector, mod+m cycles favorites+recents. Variant popover auto-fit: replaced fixed 220px width with TextPainter-measured width + padding for compact, content-aware sizing.

**Commits**: af0b5ed

#### `featH` Settings/onboarding/operation polish

- [x] Refresh providers/model em background de forma assíncrona ao abrir o app - Commits: 4a037f9, 3b931c5
- [x] Adicionar instruções básicas de como instalar e executar um servidor OpenCode na tela de adicionar servidor
- [x] Condensar as chamas de tool calls em um collapsable quando a resposta final do assistente chegar
- [x] Tornar bolha de thinking em uma caixa de no máximo 4 linhas, o texto vai subindo suavemente assim que chega, somente se clicar em show more expande um pouco mais mas com altura limitada ativando barra de rolagem interna se necessário

#### `featI` Agent/shortcut/productivity parity

**Group 1 — Header/toolbar layout** `[x]`
- [x] Mudar botão de contexto para o lado do título da sessão
- [x] Remover botão lápis do lado do título da sessão, single-tap para editar
- [x] Mudar o ícone do botão 'Files' para `account_tree_outlined`
- [x] Aumentar largura do select de projeto no desktop (300px normal, 400px large desktop)

**Group 2 — UX/content features** `[x]`
- [x] Exibir seção `Shortcuts` no mobile quando houver teclado físico conectado
- [x] Adicionar suporte a todowrite, todoread e tudo relacionado a to-do
- [x] Criar lista de dicas de uma frase para mostrar enquanto aguarda respostas do servidor mas nada chegou ainda

**Group 3 — Chat attachments and media** `[x]`
- [x] Adicionar ações de download/abertura de anexos em mensagens de chat - Commit: d2fd909
- [x] Implementar pré-visualização de imagens inline nas bolhas de mensagem - Commit: d2fd909

**Group 4 — External integrations** `[x]`
- [x] Substituir serviço ch.at de títulos por agent nativo OpenCode 'title', mantendo cadência de 6 mensagens - Commit: 51d6195
- [x] Verificar atualizações baseadas nos releases do GitHub usando a API pública do GitHub - Commit: 51d6195

**Group 5 — Platform** `[x]`
- [x] Opções em Settings para decidir se app fica em background. Mobile: persistente notification, desktop: tray. Padrão: tray habilitado no desktop, mobile mostra janela de alerta curta na área de notificação. **Nota**: Adicionado fallback Android com WorkManager periódico (15 min) para alertas de conclusão/erro/pergunta com app fechado + agendamento one-off de sonda curta ao ir para background + baseline que já alerta itens acionáveis (retry/permission/question) na primeira execução.

**Refinamento pós-Task 10 — Notifications/Sound** `[x]` - Commit: 20c5dc6
- [x] Implementar regras "only when" para notificações (only when app minimized, only when not responding, only for errors, etc.)
- [x] Adicionar picker de som do sistema + possibilidade de selecionar arquivo de som customizado
- [x] Agrupar notificações por sessão (evitar spam de múltiplas notificações da mesma conversa)
- [x] Melhoria visual da tela de configurações de notificações (UI mais intuitiva e organizada)

**Done**
- [x] Na lista de Conversations, trocar o ícone padrão da sessão por um estado visual de loading suave enquanto aquela sessão/conversa estiver recebendo dados/resposta (mobile + desktop) - Commit: fb6e118
- [x] Implement global desktop keyboard shortcuts (mod+m recent models, mod+t variants, mod+, open settings, OS-specific Ctrl/Cmd labels, mod+j global behavior) - Commit: 7e2732c
#### `featJ` Speech-to-text platform matrix

**Status**: Completed (2026-02-18)

**Planned work (J.01–J.04):**
- J.01 (`e73f15e`): Abstract `SpeechInputService` interface + `SttSpeechInputService` (moves speech_to_text logic out of widget; autoPunctuation on iOS/macOS; pauseFor 5s; dictation mode) + full widget refactor with lazy DI lookup
- J.02 (`52a35e7`): `AndroidSpeechInputService` with custom `EventChannel('codewalk/speech')` + `MethodChannel('codewalk/speech_control')`; Kotlin `RecognitionListener` with `EXTRA_PARTIAL_RESULTS`; `SherpaSpeechInputService` registered for Linux in DI
- J.03 (`0347e88`): `sherpa_onnx ^1.12.25` + `record ^6.0.0` for Linux on-device STT; `SherpaModelManager` (HuggingFace download via Dio, 4-file Kroko INT8 models, detectSystemLanguage); `SherpaModelDownloadDialog` with progress bar; `assets/sherpa_models.json` (7 languages); conditional exports (dart.library.io) to guard web
- J.04 (`86b8162`): macOS `Info.plist` (NSSpeechRecognitionUsageDescription + NSMicrophoneUsageDescription) + sandbox entitlements (com.apple.security.device.audio-input) for Debug and Release
- J.05 (`1f4677c`): Unit tests for autoPunctuation platform logic; ADR-036; CODEBASE.md update; ROADMAP condensation

**Post-release fixes and refinements (from device testing):**
- Fix (`148b650`): `"android.speech.extra.ENABLE_PUNCTUATION"` is not an official Android SDK constant and was silently ignored. Replaced with `"android.speech.extra.ENABLE_FORMATTING"` + `"android.speech.extra.FORMATTING_OPTIMIZE_QUALITY"` (RecognizerIntent.EXTRA_ENABLE_FORMATTING, API 33+, works on Pixel 6+ with Google Voice Typing). Also added `HIDE_PARTIAL_TRAILING_PUNCTUATION=false` so punctuation appears in partial results. Android's `EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS` is silently ignored by Google Speech Engine — replaced with manual silence timer via `Handler` + `onRmsChanged`: resets when voice detected (rmsdB > 1.5f), fires `stopListening()` after `pauseForMs` of silence. `pauseForMs` passed from Flutter via MethodChannel `start` args.
- Feat (`a8a5d96`): `AndroidSpeechInputService` now queries `SpeechRecognizer.isRecognitionAvailable(context)` via new `isAvailable` channel method before using the native channel. On AOSP devices or custom ROMs without Google Play Services, falls back transparently to `SttSpeechInputService` (speech_to_text package), which correctly honours the `pauseFor` silence timeout.
- Aftermath (`92c8d2b`): Removed Android custom STT channel in favor of `speech_to_text` (Native) which achieved parity with recent fixes. Added "Speech to text" settings section with engine selector (Native/Sherpa) and silence timeout. Added Sherpa model management in settings for Linux (Kroko models) with "Sherpa (Experimental)" labeling.
- [x] Polish: Set Sherpa as default engine for Linux and disabled Native engine in settings with explanatory hint. Mic button now shows loading state (static hourglass for visibility during startup freeze) immediately and yields (~10ms) before starting engine to let loading paint. - Commit hash: 317f02e
- [x] Fix (device test): Android policy changed to keep APK slim. Sherpa engine disabled on Android, Native forced, and build excludes Sherpa/ONNX native libs. `make android` now builds arm64-only split APK, returning size to ~21.9 MB. - Commit hash: addc1ac

Commits: e73f15e, 52a35e7, 86b8162, 0347e88, 148b650, 1f4677c, a8a5d96, 889ea9a, 317f02e, addc1ac, f4108fe

#### `featK` First-run onboarding wizard ✅

**Status**: Completed (2026-02-19)

Implemented OnboardingWizardPage with 3-step flow (Welcome, Server Setup, Ready). Added `skipOnboardingWizard` flag in ExperienceSettings with gate in AppShellPage via Consumer2. Extracted ServerSetupQuickGuide as reusable widget. Moved Servers to first position in Settings. Added reset app button in About and Setup Wizard button in Servers section.

- [x] Wizard/onboarding quando abrir o app pela primeira vez: dialog central perguntando qual servidor cadastrar/usar e toggle do serviço do ch.at

**Commits**: 92fa47e

#### `featL` Compaction boundary and low-cost nested history ✅

**Status**: Completed (2026-02-14)

Implemented compaction boundary timeline entry that collapses all pre-compaction messages by default, keeping only compaction response and post-compaction messages visible. Added lazy pre-boundary rendering with session-scoped expansion reset to minimize memory/render cost. Extended boundary detection to handle summary assistant messages as fallback when `CompactionPart` markers are absent. Added selection neutrality guard to prevent compaction-related messages from overriding user-selected agents/models during sync adoption.

**Commits**: fd3ce04, 4af9f01
**Post-completion fixes**: Frozen boundary during active compaction (prevents premature collapse), post-compaction `ChatState.error` reset and incomplete-message cleanup, auto-scroll suppression during compaction streaming.
**ADR**: ADR-027

#### `featM` Icons to Material Symbols migration ✅

**Status**: Completed (2026-02-20)

Completed full migration of icon usage from `Icons.*` to `Symbols.*` using `material_symbols_icons`, aligning the UI with Material Symbols across mobile and desktop.

- [x] Migrar todos os usos de `Icons.*` para `Symbols.*` do pacote `material_symbols_icons` - Commit hash: e05d2fb

#### `featN` Material You design system revamp

- [ ] Implementar dynamic color system com suporte a wallpaper extrapolation em Android 12+
- [ ] Expandir palette de cores com temas brand/custom no Settings
- [ ] Refine spacing/layout para melhor uso de espaço em múltiplos tamanhos de tela
- [ ] Implementar adaptive layout patterns (responsive breakpoints, orientation-aware)
- [ ] Polish componentes para estar 100% alinhado com Material Design 3 specs

#### `featO` Code health & technical debt

**featO progress summary**: Delivered regression fixes in `00583f0`, follow-up scope guard in `4aa38ca`, full rejected-draft UX restoration in `beb5265`, and finalized the remaining 5 items (`1.6`, `1.8`, `1.9`, `2.1`, `3.4`) in `70bcbc6`.

- [x] Group 1: Concluded (`1.6`, `1.8`, `1.9` finalized in `70bcbc6`)
- [x] Group 2: Concluded (`2.1` finalized in `70bcbc6`)
- [x] Group 3: Concluded (`3.4` finalized in `70bcbc6`)
- [x] Group 4: Concluded after necessity triage
- [x] Group 5: Concluded after necessity triage
- [x] Group 6: Concluded after necessity triage
