// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appShellDownloadingUpdate => 'Baixando atualização';

  @override
  String get appShellInstall => 'Instalar';

  @override
  String get appShellInstallFailed => 'Falha na instalação';

  @override
  String get appShellInstallingUpdate => 'Instalando atualização...';

  @override
  String get appShellRestart => 'Reiniciar';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return 'Atualização disponível: v$latestVersion';
  }

  @override
  String get behaviorAdvancedPermissionRule => 'Regra de permissão avançada';

  @override
  String get behaviorAutomatic => 'Automático';

  @override
  String get behaviorAutomaticFallback => 'Fallback automático';

  @override
  String get behaviorCellularDataSaver => 'Economia de dados móveis';

  @override
  String get behaviorChatLevelShare => 'Compartilhamento em nível de chat';

  @override
  String get behaviorCodeWalkReleaseChecks =>
      'Verificações de versão do CodeWalk';

  @override
  String get behaviorControlsOfficialGlobal =>
      'Controla as configurações globais oficiais do OpenCode';

  @override
  String get behaviorControlsUpstreamOpenCode =>
      'Controla as configurações do OpenCode upstream';

  @override
  String get behaviorCustomDisplayName => 'Nome de exibição personalizado';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return 'Reduz o uso automático de dados móveis parando downloads em segundo plano e limitando as atualizações automáticas em primeiro plano a uma rajada a cada $inSeconds segundos.';
  }

  @override
  String get behaviorDisabled => 'Desativado';

  @override
  String get behaviorLightweightTasksLike => 'Tarefas leves como';

  @override
  String get behaviorManual => 'Manual';

  @override
  String get behaviorNotify => 'Notificar';

  @override
  String get behaviorOfficialOpenCodePermission =>
      'Official OpenCode permission policy is configured in `opencode.json` with allow/ask/deny rules per tool. CodeWalk keeps the official permission-request cards and adds one approved ADR-023 exception: the composer auto-approve toggle replies with `Always` and `remember: true` unconditionally to create durable session-scoped grants, and keeps the same thread-scoped continuity path active in the Android background worker.';

  @override
  String get behaviorOpenCodeBackedDefaults => 'OpenCode-backed defaults';

  @override
  String get behaviorPermissionHandlingProvenance =>
      'Permission handling provenance';

  @override
  String get behaviorPermissionsVariantReasoning =>
      'Permissions and variant/reasoning parity stay separate until their UI can preserve advanced config safely.';

  @override
  String get behaviorPrimaryAgentAgent =>
      'Primary agent used when no agent is explicitly chosen.';

  @override
  String get behaviorRefreshDefaults => 'Refresh defaults';

  @override
  String get behaviorSharedAcrossOpenCode =>
      'Shared across OpenCode clients through config.';

  @override
  String get behaviorTheseValuesWrite =>
      'These values write to `/config` on the active server and match official OpenCode shared config.';

  @override
  String get cannedAttachFiles => 'Attach files';

  @override
  String get cannedNoSuggestions => 'Nenhuma sugestão';

  @override
  String get cannedOffMeansReplace => 'Off means replace current composer text';

  @override
  String get cannedQuickReply => 'New quick reply';

  @override
  String get cannedSendImmediatelyInserting =>
      'Send immediately after inserting this quick reply';

  @override
  String get chatActiveServerUnhealthy =>
      'Active server is unhealthy. Sends will try once and fail fast until recovery.';

  @override
  String get chatAddServerToStart =>
      'Adicione um servidor para começar a conversar.';

  @override
  String get chatAppBarMoreActions => 'More actions';

  @override
  String get chatAppBarPinAction => 'Pin to app bar';

  @override
  String get chatAppBarPinDescription =>
      'This action will stay visible outside the menu.';

  @override
  String get chatAppBarUnpinAction => 'Unpin from app bar';

  @override
  String get chatAppBarUnpinDescription =>
      'This action will move back into the menu.';

  @override
  String get chatCachedConversationsYet => 'No cached conversations yet';

  @override
  String get chatChangedFilesAvailable =>
      'No changed files are available for this session.';

  @override
  String chatChildrenChatProviderCurrentSessionChildren(String length) {
    return 'Filhos: $length';
  }

  @override
  String get chatChooseDirectory => 'Choose Directory';

  @override
  String get chatChooseFolderOpen =>
      'Choose a folder to open as project context.';

  @override
  String get chatClose => 'Fechar';

  @override
  String get chatCompactContext => 'Compactar Contexto';

  @override
  String get chatConversations => 'Conversas';

  @override
  String get chatConversationsPane => 'Conversas';

  @override
  String get chatCurrent => 'Use current';

  @override
  String get chatDiffFiles => 'Diff files: 0';

  @override
  String get chatDisplay => 'Display';

  @override
  String get chatDisplayToggles => 'Opções de exibição';

  @override
  String get chatDoubleESCStop => 'Duplo ESC para parar';

  @override
  String get chatFilterActive => 'Ativas';

  @override
  String get chatFilterAll => 'Todas';

  @override
  String get chatFilterArchived => 'Arquivadas';

  @override
  String get chatFilterDirectories => 'Filter directories';

  @override
  String get chatFilterSessions => 'Filtrar sessões';

  @override
  String get chatGoToFirst => 'Ir para primeira mensagem';

  @override
  String get chatGoToLatest => 'Ir para última mensagem';

  @override
  String chatGroupMessageCountMessages(
    String messageCount,
    String compactionLabel,
  ) {
    return '$messageCount mensagens ocultas antes da compactação $compactionLabel';
  }

  @override
  String get chatHelloAssistant => 'Olá! Eu sou seu assistente de IA';

  @override
  String get chatHelp => 'How can I help you?';

  @override
  String get chatHideConversationsSidebar => 'Ocultar barra de Conversas';

  @override
  String get chatHideUtilitySidebar => 'Ocultar barra de Utilidades';

  @override
  String get chatHistoryCollapsed => 'Previous history is collapsed';

  @override
  String get chatKeepWorking => 'Continuar trabalhando';

  @override
  String get chatLatestToolActivity =>
      'Latest tool activity stays inside this bounded panel to keep the chat viewport stable.';

  @override
  String get chatLoadMore => 'Carregar mais';

  @override
  String get chatLoadingProjectContext => 'Loading project context...';

  @override
  String get chatMessageHide => 'Hide';

  @override
  String get chatMessageMessagePartUnavailable => 'Message part unavailable';

  @override
  String get chatMessageMetadataAvailable => 'No metadata available';

  @override
  String chatMessageModelMessageModelId(String modelId) {
    return 'Modelo: $modelId';
  }

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return 'Provedor: $providerId';
  }

  @override
  String get chatMessageRewindEdit => 'Rewind and edit from here';

  @override
  String get chatMessageYou => 'You';

  @override
  String get chatNewChat => 'Nova Conversa';

  @override
  String get chatNewChatTourDescription => 'Inicie uma nova conversa aqui.';

  @override
  String get chatNewChatTourTitle => 'Nova conversa';

  @override
  String get chatNoServerYet => 'Nenhum servidor configurado ainda';

  @override
  String get chatOpenFiles => 'Abrir Arquivos';

  @override
  String get chatOpenProject => 'Abrir projeto';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenSidebar => 'Abrir barra lateral';

  @override
  String get chatPageStatusContextUsage => 'Uso do contexto';

  @override
  String get chatPageStatusCost => 'Custo';

  @override
  String get chatPageStatusLimit => 'Limite';

  @override
  String get chatPageStatusManageServers => 'Gerenciar servidores';

  @override
  String get chatPageStatusSaver => 'Economia';

  @override
  String get chatPageStatusSwitchServer => 'Trocar servidor';

  @override
  String get chatPageStatusTokens => 'Tokens';

  @override
  String get chatPageStatusUsage => 'Uso';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatProjectContext => 'Contexto do Projeto';

  @override
  String get chatProjectContext2 => 'Contexto do projeto';

  @override
  String get chatRealtimeGlobalEvent => 'evento global';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return 'evento global ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale => 'evento global (geração obsoleta)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return 'fluxo de mensagens ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => 'evento em tempo real';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return 'evento em tempo real ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale =>
      'evento em tempo real (geração obsoleta)';

  @override
  String get chatRealtimeReconnectingServerTry =>
      'Reconectando ao servidor. Tente novamente em um momento.';

  @override
  String get chatReasoning => 'Raciocinando...';

  @override
  String get chatRecentSessions => 'Sessões recentes';

  @override
  String get chatRecentSessionsToggle => 'Sessões recentes';

  @override
  String get chatRedoLastTurn => 'Refazer último turno desfeito';

  @override
  String get chatRefresh => 'Atualizar';

  @override
  String get chatRefreshConversation => 'Could not refresh this conversation';

  @override
  String get chatRefreshProjects => 'Refresh projects';

  @override
  String get chatRefreshSessionDetails => 'Atualizar detalhes da sessão';

  @override
  String chatRemoveDisplayNameHistory(String displayName) {
    return 'Remover $displayName do histórico';
  }

  @override
  String get chatRetry => 'Tentar novamente';

  @override
  String get chatRetry2 => 'Retry';

  @override
  String get chatRetryRefresh => 'Tentar atualizar novamente';

  @override
  String get chatRetryingModelRequest =>
      'Tentando novamente solicitação do modelo...';

  @override
  String get chatReturnToMainConversation => 'Voltar à conversa principal';

  @override
  String get chatReviewChanges => 'Review changes';

  @override
  String get chatSearchConversations => 'Buscar conversas';

  @override
  String get chatSearchNextResult => 'Próximo resultado';

  @override
  String get chatSearchNoResults => 'Nenhum resultado';

  @override
  String get chatSearchPreviousResult => 'Resultado anterior';

  @override
  String chatSearchResultCount(int current, int total) {
    return 'Mensagem $current de $total';
  }

  @override
  String get chatSearchTimeline => 'Buscar na timeline';

  @override
  String get chatSelectDirectory => 'Select directory';

  @override
  String get chatSelectOrCreate =>
      'Selecione ou crie uma conversa para começar';

  @override
  String get chatSelectProjectBelow => 'Select a project below.';

  @override
  String get chatSessionActions => 'Ações da sessão';

  @override
  String chatSessionChatSessionSession(String title) {
    return 'Sessão de chat: $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return 'Conversa $nextAction';
  }

  @override
  String get chatSessionConversations => 'No conversations';

  @override
  String get chatSessionCreateConversationStart =>
      'Create a new conversation to start chatting';

  @override
  String chatSessionsLength(String length) {
    return '$length';
  }

  @override
  String get chatSetUpServer => 'Configurar servidor';

  @override
  String get chatSettings => 'Settings';

  @override
  String get chatSidebarAccess => 'Acesso à barra lateral';

  @override
  String get chatSortMostRecent => 'Mais Recentes';

  @override
  String get chatSortOldest => 'Mais Antigas';

  @override
  String get chatSortRecent => 'Recentes';

  @override
  String get chatSortSessions => 'Ordenar sessões';

  @override
  String get chatSortTitle => 'Título';

  @override
  String chatSyncLabel(String label) {
    return 'Sincronização: $label';
  }

  @override
  String get chatTasks => 'Tasks';

  @override
  String get chatTasksAvailableSession =>
      'No tasks are available for this session.';

  @override
  String get chatToggleSidebars => 'Alternar barras laterais';

  @override
  String get chatUndoLastTurn => 'Desfazer último turno';

  @override
  String get chatUseCurrent => 'Usar atual';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonReset => 'Redefinir';

  @override
  String get commonSave => 'Salvar';

  @override
  String get composerAddAttachment => 'Adicionar anexo';

  @override
  String get composerAttachFiles => 'Anexar arquivos';

  @override
  String get composerCannedAppendAtCursor => 'Anexar no cursor';

  @override
  String get composerCannedLabel => 'Rótulo (opcional)';

  @override
  String get composerCannedNoReplies => 'Nenhuma resposta rápida ainda.';

  @override
  String get composerCannedReplace => 'Substituir';

  @override
  String get composerCannedSave => 'Salvar';

  @override
  String get composerCannedScopeGlobal => 'Global';

  @override
  String get composerCannedScopeProject => 'Apenas do projeto';

  @override
  String get composerCannedSendAutomatically => 'Enviar automaticamente';

  @override
  String get composerCannedText => 'Texto';

  @override
  String get composerChatInput => 'Entrada de chat';

  @override
  String get composerDeleteAction => 'Excluir';

  @override
  String get composerEdit => 'Editar';

  @override
  String get composerExtras => 'Extras';

  @override
  String get composerNewQuickReply => 'Nova resposta rápida';

  @override
  String get composerSelectImages => 'Selecionar Imagens';

  @override
  String get composerSelectPdf => 'Selecionar PDF';

  @override
  String get composerSend => 'Enviar';

  @override
  String get composerShellMode => 'Modo shell';

  @override
  String get dialogDownload => 'Baixar';

  @override
  String get dialogLanguage => 'Idioma';

  @override
  String get dialogMoonshineModelSize => 'Tamanho do modelo';

  @override
  String get dialogMoonshineVoiceSetup => 'Configuração de Voz Moonshine';

  @override
  String get dialogParakeetModel => 'Modelo Parakeet';

  @override
  String get dialogParakeetVoiceSetup => 'Configuração de Voz Parakeet';

  @override
  String get dialogSenseVoiceModel => 'Modelo SenseVoice';

  @override
  String get dialogSenseVoiceSetup => 'Configuração SenseVoice';

  @override
  String get dialogVoiceInputSetup => 'Configuração de Entrada de Voz';

  @override
  String get errorFormatAuthenticationFailedReconnect =>
      'Authentication failed. Reconnect the provider and try again.';

  @override
  String get errorFormatProviderTemporarilyUnavailable =>
      'Provider temporarily unavailable. Try again shortly.';

  @override
  String get errorFormatQuotaExceededCheck =>
      'Quota exceeded. Check your provider plan or billing.';

  @override
  String get errorFormatRateLimitExceeded =>
      'Rate limit exceeded. Wait a moment and try again.';

  @override
  String get errorFormatServerErrorPlease => 'Server error. Please try again.';

  @override
  String get errorFormatServiceTemporarilyUnavailable =>
      'Service temporarily unavailable. The server may be starting up — please try again shortly.';

  @override
  String get errorFormatUnableReachServer =>
      'Unable to reach the server. Check connection and server status.';

  @override
  String get fileActionAttachmentDataDecoded =>
      'Attachment data could not be decoded.';

  @override
  String get fileActionAttachmentPathEmpty => 'Attachment path is empty.';

  @override
  String get fileActionAttachmentPayloadEmpty => 'Attachment payload is empty.';

  @override
  String get fileActionAttachmentProvideValid =>
      'Attachment does not provide a valid location.';

  @override
  String get fileActionAttachmentSavedDevice =>
      'Attachment could not be saved on this device.';

  @override
  String fileActionAttachmentSavedOutputFile(String path) {
    return 'Anexo salvo em $path e aberto.';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return 'Anexo salvo em $path.';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return 'Anexo salvo em $savedPath.';
  }

  @override
  String get fileActionLocalAttachmentFound =>
      'Local attachment was not found on this device.';

  @override
  String get fileActionSaveCanceled => 'Save canceled.';

  @override
  String get fileActionUnableOpenLocal =>
      'Unable to open the local attachment.';

  @override
  String get filesAddChat => 'Add to chat';

  @override
  String get filesBinaryFilePreview => 'Binary file preview is not available.';

  @override
  String get filesClear => 'Clear';

  @override
  String get filesContents => 'Contents';

  @override
  String get filesFileEmpty => 'File is empty.';

  @override
  String get filesFilesFound => 'No files found';

  @override
  String get filesHideSidebar => 'Ocultar barra de Arquivos';

  @override
  String get filesNames => 'Names';

  @override
  String filesOpenFilesFileState(String length) {
    return 'Arquivos abertos ($length)';
  }

  @override
  String get filesQuickOpen => 'Abertura Rápida';

  @override
  String get filesQuickOpenFile => 'Quick Open File';

  @override
  String get filesRefresh => 'Atualizar arquivos';

  @override
  String get filesSearchHint => 'Buscar arquivos por nome ou caminho';

  @override
  String get filesTitle => 'Arquivos';

  @override
  String get logsAppLogs => 'App Logs';

  @override
  String get logsClear => 'Limpar logs';

  @override
  String get logsCloseSearch => 'Fechar busca';

  @override
  String get logsCopyFiltered => 'Copiar logs filtrados';

  @override
  String get logsLevel => 'Level';

  @override
  String get logsSearch => 'Buscar logs';

  @override
  String logsShowingOrderedLength(int length, int length2) {
    return 'Mostrando $length de $length2 entradas';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => 'Matemática';

  @override
  String get mermaidCopySourceTooltip => 'Copy source';

  @override
  String get mermaidDiagramLabel => 'Mermaid Diagram';

  @override
  String get modelAuto => 'Automático';

  @override
  String get modelChooseAgent => 'Choose agent';

  @override
  String get modelFavorites => 'Favorites';

  @override
  String get modelLoadingModels => 'Carregando modelos';

  @override
  String get modelModelsFound => 'No models found';

  @override
  String get modelRetryModels => 'Tentar modelos novamente';

  @override
  String get modelSearchHint => 'Buscar modelo ou provedor';

  @override
  String get msgBatterySettingsFailed =>
      'Não foi possível abrir as configurações de otimização de bateria do Android.';

  @override
  String get msgBatterySettingsOpened =>
      'Configurações de bateria do Android abertas. Permita bateria irrestrita para o CodeWalk.';

  @override
  String get msgClearUsernameNeedsConfigEdit =>
      'Limpar o nome de usuário da conversa do OpenCode ainda requer editar a config fora do app.';

  @override
  String get msgCommandCopied => 'Comando copiado';

  @override
  String get msgCopiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get msgEnterUsernameToSave =>
      'Digite um nome de usuário para salvar um nome de conversa personalizado do OpenCode.';

  @override
  String get msgFailedToSendMessage =>
      'Falha ao enviar mensagem. Rascunho mantido para nova tentativa.';

  @override
  String get msgFailedToStartVoiceInput => 'Falha ao iniciar entrada de voz';

  @override
  String msgFilePathNotFound(String path) {
    return 'Arquivo não encontrado: $path';
  }

  @override
  String get msgFilteredLogsCopied =>
      'Logs filtrados copiados para a área de transferência';

  @override
  String get msgInfoAgent => 'Agente';

  @override
  String get msgInfoCompaction => 'Compactação';

  @override
  String msgInfoCost(String cost) {
    return 'Custo: R\$$cost';
  }

  @override
  String get msgInfoMessageInfo => 'Informações da Mensagem';

  @override
  String msgInfoModel(String modelId) {
    return 'Modelo: $modelId';
  }

  @override
  String get msgInfoNoMetadata => 'Nenhum metadado disponível';

  @override
  String msgInfoPartDescriptionModel(String description, String model) {
    return '$description$model';
  }

  @override
  String get msgInfoPatch => 'Patch';

  @override
  String msgInfoProvider(String providerId) {
    return 'Provedor: $providerId';
  }

  @override
  String get msgInfoRetry => 'Tentativa';

  @override
  String get msgInfoSnapshot => 'Snapshot';

  @override
  String msgInfoSubtaskPartAgent(String agent) {
    return 'Subtarefa ($agent)';
  }

  @override
  String msgInfoTokens(String total) {
    return 'Tokens: $total';
  }

  @override
  String get msgInfoUndoThisTurn => 'Desfazer este turno';

  @override
  String get msgInfoView => 'Ver';

  @override
  String get msgNoSystemSoundsFound =>
      'Nenhum som do sistema foi encontrado neste dispositivo.';

  @override
  String get msgNoValidFilesSelected => 'Nenhum arquivo válido foi selecionado';

  @override
  String get msgReadAloud => 'Read aloud';

  @override
  String get msgReadAloudNotAvailable =>
      'Text-to-speech is not available on this device.';

  @override
  String get msgSetupDebugCopied => 'Debug de configuração do OpenCode copiado';

  @override
  String get msgShareAsImage => 'Share as image';

  @override
  String get msgShareAsImageFailed => 'Could not share message as image.';

  @override
  String get msgShareAsImageSubject => 'CodeWalk message';

  @override
  String get msgShareAsImageTooTall =>
      'Message is too long to share as an image.';

  @override
  String get msgStopReadAloud => 'Stop reading';

  @override
  String get msgSystemSoundPickerUnavailable =>
      'Seletor de som do sistema não está disponível nesta plataforma.';

  @override
  String get msgUpdatedButRefreshFailed =>
      'Configuração do servidor atualizada, mas não foi possível atualizar os provedores de chat.';

  @override
  String get msgVoiceInputUnavailable =>
      'Entrada de voz indisponível neste dispositivo';

  @override
  String get notifAndroidBatteryOptimization => 'Android battery optimization';

  @override
  String get notifConversationUpdates => 'Atualizações de conversa';

  @override
  String get notifNotificationsArriveReopening =>
      'If notifications only arrive when reopening the app, allow CodeWalk to run without optimization on this device.';

  @override
  String get notifResponseRunningKeep =>
      'When a response is running, keep realtime active briefly after you leave the app.';

  @override
  String notifSelectedSoundLabel(String soundLabel) {
    return 'Selecionado: $soundLabel';
  }

  @override
  String get onboardingAIGeneratedTitles => 'AI generated titles';

  @override
  String get onboardingAddServerLater =>
      'You can add a server later in Settings > Servers.';

  @override
  String get onboardingAlmostInstallOpenCode =>
      'You are almost there. Install OpenCode first, then connect CodeWalk to the server URL.';

  @override
  String onboardingAppProviderLocalSetupLogsLength(int length, int length2) {
    return '$length linhas de log de configuração e $length2 eventos de configuração estão disponíveis na tela de depuração de configuração separada.';
  }

  @override
  String get onboardingAuthenticate => 'Authenticate';

  @override
  String get onboardingChooseAnotherPath => 'Choose another path';

  @override
  String get onboardingClear => 'Limpar';

  @override
  String get onboardingCodeWalkAppOpenCode =>
      'CodeWalk is the app. OpenCode is the engine it connects to.';

  @override
  String get onboardingConnectRunningServer => 'Connect to a running server';

  @override
  String get onboardingConnectionIssue => 'Connection issue';

  @override
  String get onboardingConnectionTips => 'Connection tips';

  @override
  String get onboardingContinueServerURL => 'Continue to server URL';

  @override
  String get onboardingCopyLoginURL => 'Copy login URL';

  @override
  String get onboardingDefaultURLEmulator =>
      'Default URL, emulator loopback, auth, and debug help.';

  @override
  String get onboardingDetailedSetupEvents =>
      'Detailed setup events were captured for troubleshooting.';

  @override
  String get onboardingDonShowAgain => 'Don\'t show again';

  @override
  String get onboardingExisting => 'Use Existing';

  @override
  String get onboardingExplainInstallOpenCode =>
      'Explain how to install OpenCode, start the server, and then connect from CodeWalk.';

  @override
  String get onboardingGoodOptionDesktop => 'Good first option on desktop';

  @override
  String get onboardingInstallBinary => 'Install Binary';

  @override
  String get onboardingInstallBun => 'Install via Bun';

  @override
  String get onboardingInstallBunOpenCode => 'Install Bun + OpenCode';

  @override
  String get onboardingInstallNpm => 'Install via npm';

  @override
  String get onboardingInstallRunOpenCode =>
      'Install and run OpenCode directly from CodeWalk on desktop.';

  @override
  String get onboardingLabel => 'Rótulo (opcional)';

  @override
  String get onboardingLabelHint => 'Meu servidor';

  @override
  String onboardingLatestOutputAppProvider(String localServerLastOutput) {
    return 'Última saída: $localServerLastOutput';
  }

  @override
  String get onboardingLetCodeWalkSet => 'Let CodeWalk set it up locally';

  @override
  String get onboardingManagedLocalServer => 'Managed local server';

  @override
  String get onboardingManagedLocalServer2 =>
      'Managed local server mode is available only on desktop builds (Linux/macOS/Windows).';

  @override
  String get onboardingOpenCode => 'What is OpenCode?';

  @override
  String get onboardingOpenCodeRunningDevice =>
      'I already have OpenCode running on this device or somewhere on my network.';

  @override
  String get onboardingOpenCodeRunsLocally =>
      'OpenCode runs locally or on a server and powers the AI coding features inside CodeWalk. If OpenCode is already running, connect to it. If not, pick one of the guided setup paths below.';

  @override
  String get onboardingOpenTailscaleLogin =>
      'Could not open Tailscale login URL.';

  @override
  String get onboardingPassword => 'Senha';

  @override
  String get onboardingPasswordRequired => 'Enter password';

  @override
  String get onboardingRecommendedOrderTry =>
      'Recommended order: try Install Bun + OpenCode if you want CodeWalk to bootstrap everything for you. Use Existing if OpenCode is already installed.';

  @override
  String get onboardingRefreshChecks => 'Refresh Checks';

  @override
  String get onboardingRunDiagnosticsToVerify =>
      'Execute diagnósticos para verificar os requisitos locais do OpenCode.';

  @override
  String get onboardingServerUrl => 'URL do servidor';

  @override
  String get onboardingShowSetupSteps => 'Show me the setup steps';

  @override
  String get onboardingShowSetupSteps2 => 'Show setup steps';

  @override
  String get onboardingSkip => 'Skip for now';

  @override
  String get onboardingSkipSetup => 'Skip setup?';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingStop => 'Stop';

  @override
  String get onboardingUseBasicAuth => 'Use Basic Auth';

  @override
  String get onboardingUsername => 'Usuário';

  @override
  String get onboardingUsernameRequired => 'Enter username';

  @override
  String get onboardingUsesServerTitle =>
      'Uses your server\'s title agent to name conversations';

  @override
  String get onboardingViewSetupDebug => 'View setup debug';

  @override
  String get onboardingWindowsTipInstalling =>
      'Windows tip: after installing, click Refresh Checks. If detection still fails, reopen CodeWalk to reload PATH changes.';

  @override
  String get permissionAllowOnce => 'Permitir Uma Vez';

  @override
  String get permissionAlways => 'Sempre';

  @override
  String get permissionBack => 'Voltar';

  @override
  String get permissionConfirmReject => 'Confirmar Rejeição';

  @override
  String get permissionReject => 'Rejeitar';

  @override
  String get permissionReopen => 'Reabrir';

  @override
  String get questionAnswerSelected => 'No answer selected.';

  @override
  String get questionCommaSeparatedValues => 'Comma-separated values';

  @override
  String get questionQuestionGroupMarked =>
      'Question group marked as rejected. You can keep chatting and reopen this group anytime before confirming.';

  @override
  String get questionQuestionRequest => 'Question request';

  @override
  String get questionQuestionsProvidedSubmit =>
      'No questions provided. You can submit an empty response.';

  @override
  String get questionReviewAnswersSubmitting =>
      'Review your answers before submitting.';

  @override
  String get quotaAuthCookie => 'Cookie de autenticação';

  @override
  String get quotaForget => 'Esquecer';

  @override
  String get quotaOpenCodeGoUsage => 'Uso do OpenCode Go';

  @override
  String get quotaOpenDashboard => 'Abrir dashboard OpenCode';

  @override
  String get quotaSaving => 'Salvando...';

  @override
  String get quotaWorkspaceId => 'ID do Workspace';

  @override
  String get serverClearOAuth => 'Clear OAuth';

  @override
  String get serverOAuthAuthFailed => 'OAuth authentication failed';

  @override
  String get serverOAuthChip => 'OAuth';

  @override
  String get serverOAuthNotSupported =>
      'Cloudflare Access OAuth is not supported on this platform';

  @override
  String get serverReauthenticate => 'Re-authenticate';

  @override
  String get serverTailscaleChip => 'Tailscale';

  @override
  String get serversActive => 'Active';

  @override
  String get serversActiveServer => 'Active Server';

  @override
  String get serversAddLeastOpenCode =>
      'Add at least one OpenCode server to start using the app.';

  @override
  String get serversAddServer => 'Add Server';

  @override
  String get serversCancel => 'Cancel';

  @override
  String get serversCheckHealth => 'Check Health';

  @override
  String get serversClearDefault => 'Clear Default';

  @override
  String serversCommandAppProviderLocalServerCommandPath(
    String localServerCommandPath,
  ) {
    return 'Comando: $localServerCommandPath';
  }

  @override
  String get serversCopy => 'Copy';

  @override
  String get serversDefault => 'Default';

  @override
  String get serversDelete => 'Delete';

  @override
  String get serversDeleteServer => 'Delete server';

  @override
  String get serversEdit => 'Edit';

  @override
  String get serversLocalOpenCodeServer => 'Local OpenCode Server';

  @override
  String get serversManagedModeAvailable =>
      'This managed mode is available only on desktop builds (Linux/macOS/Windows).';

  @override
  String get serversRefreshHealth => 'Refresh Health';

  @override
  String serversRemoveProfileDisplayName(String displayName) {
    return 'Remover \"$displayName\"?';
  }

  @override
  String get serversServersConfigured => 'No servers configured';

  @override
  String get serversSetActive => 'Set Active';

  @override
  String get serversSetDefault => 'Set Default';

  @override
  String get serversSetupDebug => 'Setup Debug';

  @override
  String get serversSetupWizard => 'Setup Wizard';

  @override
  String get sessionActionArchived => 'arquivada';

  @override
  String get sessionActionDeleted => 'excluída';

  @override
  String get sessionActionForked => 'bifurcada';

  @override
  String get sessionActionUnarchived => 'desarquivada';

  @override
  String get sessionCancelRename => 'Cancelar renomeação';

  @override
  String get sessionCopyLink => 'Copiar Link';

  @override
  String get sessionDelete => 'Excluir';

  @override
  String get sessionDeleteTitle => 'Excluir Conversa';

  @override
  String get sessionDiffChangedFile => 'Arquivo alterado';

  @override
  String get sessionDiffContentNotCaptured =>
      'File content not captured by the server';

  @override
  String sessionDiffFilesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files changed',
      one: '1 file changed',
    );
    return '$_temp0';
  }

  @override
  String sessionDiffLinesAddedRemoved(int added, int removed) {
    return '+$added lines added -$removed lines removed';
  }

  @override
  String sessionDiffLinesCollapsed(int count) {
    return '$count lines collapsed — tap to expand';
  }

  @override
  String get sessionDiffReview => 'Review changes';

  @override
  String get sessionDiffSplit => 'Split';

  @override
  String get sessionDiffSummary => 'Summary';

  @override
  String get sessionDiffUnified => 'Unified';

  @override
  String get sessionFailedRename => 'Falha ao renomear conversa';

  @override
  String get sessionFailedUpdateArchive =>
      'Falha ao atualizar estado de arquivamento';

  @override
  String get sessionFailedUpdateSharing =>
      'Falha ao atualizar estado de compartilhamento';

  @override
  String get sessionFork => 'Bifurcar';

  @override
  String get sessionKeyboardShortcuts => 'Atalhos de teclado';

  @override
  String get sessionNotAvailable =>
      'A conversa ainda não está disponível para este projeto';

  @override
  String get sessionRename => 'Renomear';

  @override
  String get sessionRenameHint => 'Digite o novo nome da conversa';

  @override
  String get sessionRenameTitle => 'Renomear Conversa';

  @override
  String get sessionSaveTitle => 'Salvar título';

  @override
  String get sessionShareLinkCopied => 'Link de compartilhamento copiado';

  @override
  String get sessionTitleHint => 'Título da conversa';

  @override
  String get settingsAboutCheckForUpdates => 'Verificar atualizações';

  @override
  String get settingsAboutCheckOnOpen => 'Verificar atualizações ao abrir';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Verificar automaticamente quando o app iniciar';

  @override
  String get settingsAboutChecking => 'Verificando...';

  @override
  String get settingsAboutDescription => 'Versão, atualizações e links';

  @override
  String get settingsAboutDismiss => 'Dispensar';

  @override
  String settingsAboutDownloading(String percent) {
    return 'Baixando... $percent%';
  }

  @override
  String get settingsAboutEraseAllData => 'Apagar todos os dados e reiniciar';

  @override
  String get settingsAboutInstallUpdate => 'Instalar atualização';

  @override
  String get settingsAboutInstalling => 'Instalando...';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version é a versão mais recente';
  }

  @override
  String get settingsAboutLoading => 'Carregando...';

  @override
  String get settingsAboutReplayChatTour => 'Repetir tour do chat';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Fechar configurações e mostrar o guia do chat';

  @override
  String get settingsAboutResetApp => 'Redefinir app';

  @override
  String get settingsAboutResetAppQuestion => 'Redefinir app?';

  @override
  String get settingsAboutResetAppWarning =>
      'Isso apagará todos os servidores, configurações e dados em cache. Esta ação não pode ser desfeita.';

  @override
  String get settingsAboutRetryInstall => 'Tentar instalar novamente';

  @override
  String get settingsAboutTapToCheck => 'Toque para buscar novas versões';

  @override
  String get settingsAboutTitle => 'Sobre';

  @override
  String get settingsAboutUpToDate => 'Você está em dia';

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Atualização disponível: v$version';
  }

  @override
  String get settingsAboutUpdateInstalled =>
      'Atualização instalada. Reinicie o app para aplicar.';

  @override
  String get settingsAboutVersion => 'Versão';

  @override
  String settingsAboutVersionBuild(String buildNumber, String version) {
    return '$version (compilação $buildNumber)';
  }

  @override
  String get settingsAppearanceAmoledDark => 'Modo escuro AMOLED';

  @override
  String get settingsAppearanceAmoledDarkActive =>
      'Usar superfícies pretas puras enquanto o modo escuro estiver ativo.';

  @override
  String get settingsAppearanceAmoledDarkInactive =>
      'Mude para o modo escuro para habilitar superfícies AMOLED.';

  @override
  String get settingsAppearanceBrandColor => 'Cor da marca';

  @override
  String get settingsAppearanceBrandColorDynamicBlocked =>
      'Desative as cores do papel de parede para escolher uma cor da marca.';

  @override
  String get settingsAppearanceBrandColorNormal =>
      'Escolha uma cor semente para a paleta do app.';

  @override
  String get settingsAppearanceBrandColorPresetBlocked =>
      'Mude para CodeWalk Clássico para escolher uma cor da marca.';

  @override
  String get settingsAppearanceCodeWalkClassic => 'CodeWalk Clássico';

  @override
  String get settingsAppearanceComposerTips => 'Dicas do composer';

  @override
  String get settingsAppearanceComposerTipsDescription =>
      'Mostrar ou ocultar dicas rotativas enquanto o assistente está raciocinando.';

  @override
  String get settingsAppearanceContrast => 'Contraste';

  @override
  String get settingsAppearanceContrastDynamicBlocked =>
      'Desative as cores do papel de parede para ajustar o contraste.';

  @override
  String get settingsAppearanceContrastHigh => 'Alto';

  @override
  String get settingsAppearanceContrastNormal =>
      'Ajuste o nível de contraste do esquema de cores.';

  @override
  String get settingsAppearanceContrastPresetBlocked =>
      'Mude para CodeWalk Clássico para ajustar o contraste.';

  @override
  String get settingsAppearanceContrastReduced => 'Reduzido';

  @override
  String get settingsAppearanceDark => 'Escuro';

  @override
  String get settingsAppearanceDensity => 'Densidade';

  @override
  String get settingsAppearanceDensityDense => 'Densa';

  @override
  String get settingsAppearanceDensityDescription =>
      'Aplica espaçamento e densidade de componentes em todo o app.';

  @override
  String get settingsAppearanceDensityExtraDense => 'Extra Densa';

  @override
  String get settingsAppearanceDensityExtraSpacious => 'Extra Espaçosa';

  @override
  String get settingsAppearanceDensityNormal => 'Normal';

  @override
  String get settingsAppearanceDensitySpacious => 'Espaçosa';

  @override
  String get settingsAppearanceDescription =>
      'Densidade e visibilidade dos balões da timeline';

  @override
  String get settingsAppearanceLight => 'Claro';

  @override
  String get settingsAppearanceMathRendering => 'Renderização de matemática';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      'Renderizar expressões matemáticas LaTeX como equações tipografadas nas mensagens de chat.';

  @override
  String get settingsAppearanceNoPresets => 'Nenhuma paleta encontrada';

  @override
  String get settingsAppearanceOpenCodePresets => 'Presets OpenCode';

  @override
  String get settingsAppearancePresetHelper =>
      'Espelha a lista oficial de temas integrados do OpenCode Web.';

  @override
  String get settingsAppearancePresetNote =>
      'As cores do tema agora seguem o registro oficial do OpenCode Web e também orientam as superfícies de markdown/código.';

  @override
  String get settingsAppearancePresetPalette => 'Paleta predefinida';

  @override
  String get settingsAppearanceSearchPreset => 'Buscar paleta predefinida';

  @override
  String get settingsAppearanceSectionDescription =>
      'Ajuste a densidade visual e as superfícies de mensagem para o seu fluxo de trabalho.';

  @override
  String get settingsAppearanceSectionTitle => 'Aparência';

  @override
  String get settingsAppearanceSystem => 'Sistema';

  @override
  String get settingsAppearanceTaskList => 'Lista de tarefas';

  @override
  String get settingsAppearanceTaskListDescription =>
      'Mostrar ou ocultar o widget de lista de tarefas da sessão.';

  @override
  String get settingsAppearanceTheme => 'Tema';

  @override
  String get settingsAppearanceThemeDescription =>
      'Escolha entre modo claro, escuro ou sistema, depois mantenha a paleta clássica do CodeWalk ou mude para um preset OpenCode.';

  @override
  String get settingsAppearanceThinkingBubbles => 'Balões de pensamento';

  @override
  String get settingsAppearanceThinkingBubblesDescription =>
      'Mostrar ou ocultar blocos de raciocínio nas mensagens do assistente.';

  @override
  String get settingsAppearanceTitle => 'Aparência';

  @override
  String get settingsAppearanceToolCallBubbles =>
      'Balões de chamada de ferramenta';

  @override
  String get settingsAppearanceToolCallBubblesDescription =>
      'Mostrar ou ocultar cartões de execução de ferramentas nas mensagens do assistente.';

  @override
  String get settingsAppearanceWallpaperColors =>
      'Usar cores do papel de parede';

  @override
  String get settingsAppearanceWallpaperNormal =>
      'Extrair esquema de cores do papel de parede do dispositivo.';

  @override
  String get settingsAppearanceWallpaperPresetBlocked =>
      'Mude para CodeWalk Clássico para usar cores do papel de parede.';

  @override
  String get settingsBack => 'Voltar';

  @override
  String get settingsBehaviorAutoupdateCaveat =>
      'Use a seção Sobre para verificações de versão do CodeWalk. Esta configuração apenas espelha a config `autoupdate` oficial do OpenCode.';

  @override
  String get settingsBehaviorAutoupdateHelp =>
      'Controla as atualizações de runtime do OpenCode upstream, não as verificações de atualização do app CodeWalk.';

  @override
  String get settingsBehaviorCellularDataSaver => 'Economia de dados móveis';

  @override
  String get settingsBehaviorConfigDeferred =>
      'O CodeWalk aplicará esta configuração do OpenCode após a resposta atual terminar.';

  @override
  String settingsBehaviorConfigUpdateFailed(String field) {
    return 'Não foi possível atualizar o $field do OpenCode.';
  }

  @override
  String get settingsBehaviorConversationUsername =>
      'Nome de usuário da conversa';

  @override
  String get settingsBehaviorConversationUsernameHelp =>
      'Nome de exibição personalizado mostrado nas conversas em vez do nome do sistema.';

  @override
  String get settingsBehaviorDataSaverActive => 'Ativo agora em dados móveis.';

  @override
  String get settingsBehaviorDataSaverCellularOnly =>
      'Aplica-se apenas quando a conexão for celular/móvel.';

  @override
  String get settingsBehaviorDataSaverDescription =>
      'Reduz o uso automático de dados móveis interrompendo downloads em segundo plano e limitando as atualizações automáticas em primeiro plano.';

  @override
  String get settingsBehaviorDataSaverWaiting =>
      'Aguardando a próxima janela de sincronização de dados móveis.';

  @override
  String get settingsBehaviorDefaultAgent => 'Agente padrão';

  @override
  String get settingsBehaviorDefaultAgentHelp =>
      'Agente principal usado quando nenhum agente é escolhido explicitamente.';

  @override
  String get settingsBehaviorDefaultModel => 'Modelo padrão';

  @override
  String get settingsBehaviorDefaultModelHelp =>
      'Compartilhado entre clientes OpenCode via config.';

  @override
  String get settingsBehaviorDescription =>
      'Padrões OpenCode, procedência e segurança de sincronização do composer';

  @override
  String get settingsBehaviorEnableDataSaver =>
      'Habilitar economia de dados móveis';

  @override
  String get settingsBehaviorMultiDeviceSync =>
      'Habilitar sincronização experimental entre dispositivos';

  @override
  String get settingsBehaviorMultiDeviceSyncDescription =>
      'Sincroniza a seleção do composer (agente/modelo/variante) com a config do servidor ativo.';

  @override
  String get settingsBehaviorMultiDeviceSyncWarning =>
      'Pode abortar sessões em andamento ao trabalhar em mais de uma sessão ao mesmo tempo.';

  @override
  String get settingsBehaviorNoAgents => 'Nenhum agente encontrado';

  @override
  String get settingsBehaviorNoModels => 'Nenhum modelo encontrado';

  @override
  String get settingsBehaviorOpenCodeAutoupdate =>
      'Atualização automática do OpenCode';

  @override
  String get settingsBehaviorOpenCodeDefaults => 'Padrões do OpenCode';

  @override
  String get settingsBehaviorOpenCodeDefaultsDescription =>
      'Esses valores gravam em `/config` no servidor ativo e correspondem à config oficial do OpenCode.';

  @override
  String get settingsBehaviorOpenCodeSnapshots => 'Snapshots do OpenCode';

  @override
  String get settingsBehaviorOpenCodeSnapshotsDescription =>
      'Manter snapshots git habilitados para histórico de desfazer/refazer e recuperação.';

  @override
  String get settingsBehaviorPermissionDeferred =>
      'A edição avançada de regras de permissão fica fora das Configurações por enquanto e é adiada para trabalho futuro de paridade.';

  @override
  String get settingsBehaviorPermissionProvenance =>
      'Procedência do tratamento de permissões';

  @override
  String get settingsBehaviorPermissionProvenanceDescription =>
      'A política oficial de permissão do OpenCode é configurada no `opencode.json` com regras allow/ask/deny por ferramenta. O CodeWalk mantém os cards oficiais de solicitação de permissão e adiciona uma exceção ADR-023 aprovada: o toggle de auto-aprovação do composer responde com `Always` e `remember: true` incondicionalmente para criar concessões duráveis com escopo de sessão. O mesmo caminho de continuidade com escopo de thread permanece ativo no worker Android em segundo plano.';

  @override
  String get settingsBehaviorRefreshDefaults => 'Atualizar padrões';

  @override
  String get settingsBehaviorSaveUsername => 'Salvar nome de usuário';

  @override
  String get settingsBehaviorSearchAutoupdate => 'Buscar modo de atualização';

  @override
  String get settingsBehaviorSearchDefaultAgent => 'Buscar agente padrão';

  @override
  String get settingsBehaviorSearchDefaultModel => 'Buscar modelo padrão';

  @override
  String get settingsBehaviorSearchShareMode =>
      'Buscar modo de compartilhamento';

  @override
  String get settingsBehaviorSearchSmallModel => 'Buscar modelo pequeno';

  @override
  String get settingsBehaviorShareMode =>
      'Padrão de compartilhamento do OpenCode';

  @override
  String get settingsBehaviorShareModeCaveat =>
      'Use a ação de compartilhar no chat para publicar uma sessão agora. Esta configuração apenas altera a política de compartilhamento padrão do OpenCode.';

  @override
  String get settingsBehaviorShareModeHelp =>
      'Controla a config global oficial `share`, não o botão de compartilhar de um chat individual.';

  @override
  String get settingsBehaviorSmallModel => 'Modelo pequeno';

  @override
  String get settingsBehaviorSmallModelAutoFallback => 'Fallback automático';

  @override
  String get settingsBehaviorSmallModelFallbackActive =>
      'O fallback automático do OpenCode está ativo porque `small_model` não está definido.';

  @override
  String get settingsBehaviorSmallModelHelp =>
      'Usado para tarefas leves como geração de títulos.';

  @override
  String get settingsBehaviorSmallModelResetCaveat =>
      'Redefinir `small_model` de volta ao fallback automático ainda requer editar a config fora do app.';

  @override
  String get settingsBehaviorSnapshotCaveat =>
      'Isso controla o armazenamento de snapshots e suporte a undo/redo do OpenCode, não os snapshots de cache local do CodeWalk.';

  @override
  String get settingsBehaviorTitle => 'Comportamento';

  @override
  String get settingsBehaviorUsernameFallback =>
      'O OpenCode usa o nome de usuário do sistema porque `username` não está definido.';

  @override
  String get settingsBehaviorUsernamePatchCaveat =>
      'Redefinir `username` de volta ao padrão do sistema ainda requer editar a config fora do app porque atualizações de patch `/config` não podem remover chaves.';

  @override
  String get settingsLanguageDescription =>
      'Escolha o idioma usado pelo CodeWalk. O padrão do sistema segue o idioma do dispositivo.';

  @override
  String get settingsLanguageEmptyText => 'Nenhum idioma encontrado';

  @override
  String get settingsLanguageFieldHelper =>
      'Aplica imediatamente e persiste após reiniciar.';

  @override
  String get settingsLanguageFieldLabel => 'Idioma do app';

  @override
  String get settingsLanguageSearchHint => 'Pesquisar idiomas';

  @override
  String get settingsLanguageSystemDefault => 'Padrão do sistema';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLogsDescription =>
      'Diagnóstico em tempo de execução e dados de solução de problemas';

  @override
  String get settingsLogsTitle => 'Registros';

  @override
  String get settingsNotificationsAgentSubtitle =>
      'Quando uma resposta termina';

  @override
  String get settingsNotificationsAgentUpdates => 'Atualizações do agente';

  @override
  String get settingsNotificationsAnotherConversation => 'Outra conversa';

  @override
  String get settingsNotificationsAppInBackground => 'App em segundo plano';

  @override
  String get settingsNotificationsBackgroundAlerts =>
      'Alertas em segundo plano Android';

  @override
  String get settingsNotificationsBackgroundBehavior =>
      'Comportamento em segundo plano';

  @override
  String get settingsNotificationsBackgroundBehaviorDescription =>
      'Escolha como o CodeWalk se comporta depois que o app sai do primeiro plano.';

  @override
  String get settingsNotificationsBackgroundDescription =>
      'Usa monitoramento de baixo consumo de dados em segundo plano para conclusões de resposta, solicitações de permissão, perguntas e erros enquanto o app não está na tela.';

  @override
  String get settingsNotificationsBackgroundToggle =>
      'Alertas em segundo plano no Android';

  @override
  String get settingsNotificationsBackgroundToggleDescription =>
      'Desativa todas as verificações em segundo plano do Android e oculta a notificação persistente do monitor.';

  @override
  String get settingsNotificationsBatteryDescription =>
      'Se as notificações só chegam ao reabrir o app, permita que o CodeWalk execute sem otimização neste dispositivo.';

  @override
  String get settingsNotificationsBatteryDisabled =>
      'A otimização de bateria está desativada para o CodeWalk.';

  @override
  String get settingsNotificationsBatteryEnabled =>
      'A otimização de bateria está ativada. Alguns dispositivos podem atrasar os alertas em segundo plano.';

  @override
  String get settingsNotificationsBatteryOptimization =>
      'Otimização de bateria do Android';

  @override
  String get settingsNotificationsBatteryUnknown =>
      'Ainda não foi possível ler o status de otimização de bateria.';

  @override
  String get settingsNotificationsChooseAudioFile =>
      'Escolher arquivo de áudio';

  @override
  String get settingsNotificationsChooseSystemSound =>
      'Escolher som do sistema';

  @override
  String get settingsNotificationsCloseToTray => 'Fechar para bandeja';

  @override
  String get settingsNotificationsCloseToTrayDescription =>
      'Ocultar janela e continuar executando na bandeja do sistema.';

  @override
  String get settingsNotificationsDescription =>
      'Controles de notificação e som por categoria';

  @override
  String get settingsNotificationsDisableOptimization => 'Desativar otimização';

  @override
  String get settingsNotificationsErrors => 'Erros';

  @override
  String get settingsNotificationsErrorsSubtitle =>
      'Quando uma sessão relata uma falha';

  @override
  String get settingsNotificationsJustClose => 'Apenas fechar';

  @override
  String get settingsNotificationsJustCloseDescription =>
      'Sair completamente do aplicativo.';

  @override
  String get settingsNotificationsKeepLive => 'Manter alertas ativos por 3 min';

  @override
  String get settingsNotificationsKeepLiveDescription =>
      'Quando uma resposta já está em execução, mantém o tempo real ativo brevemente após sair do app.';

  @override
  String get settingsNotificationsLocal => 'Local';

  @override
  String get settingsNotificationsMinimizeWhenClose => 'Minimizar ao fechar';

  @override
  String get settingsNotificationsMinimizeWhenCloseDescription =>
      'Minimizar para a barra de tarefas/dock e continuar executando.';

  @override
  String get settingsNotificationsNoCondition =>
      'Se nenhuma condição for selecionada, os alertas são permitidos em qualquer contexto.';

  @override
  String get settingsNotificationsNotify => 'Notificar';

  @override
  String get settingsNotificationsNotifyOnlyWhen => 'Notificar apenas quando';

  @override
  String get settingsNotificationsOpenBatterySettings =>
      'Abrir configurações de bateria';

  @override
  String get settingsNotificationsPermissions => 'Permissões e perguntas';

  @override
  String get settingsNotificationsPermissionsSubtitle =>
      'Quando ferramentas solicitam sua entrada';

  @override
  String get settingsNotificationsPreview => 'Pré-visualizar';

  @override
  String get settingsNotificationsRefreshStatus => 'Atualizar status';

  @override
  String get settingsNotificationsSearchSoundType => 'Buscar tipo de som';

  @override
  String get settingsNotificationsSectionDescription =>
      'Controle quando os alertas aparecem e quando podem reproduzir som.';

  @override
  String get settingsNotificationsSectionTitle => 'Notificações';

  @override
  String settingsNotificationsSelectedSound(String label) {
    return 'Selecionado: $label';
  }

  @override
  String get settingsNotificationsServer => 'Servidor';

  @override
  String get settingsNotificationsSound => 'Som';

  @override
  String get settingsNotificationsSoundOnlyWhen => 'Som apenas quando';

  @override
  String get settingsNotificationsSoundType => 'Tipo de som';

  @override
  String get settingsNotificationsSyncInfo =>
      'Alguns toggles de categoria são sincronizados do /config no servidor ativo.';

  @override
  String get settingsNotificationsSyncInfoLocal =>
      'O servidor atual não expõe toggles de notificação no /config; os valores locais estão ativos.';

  @override
  String get settingsNotificationsSystemSoundPickerTitle =>
      'Escolher som do sistema';

  @override
  String get settingsNotificationsTitle => 'Notificações';

  @override
  String get settingsNotificationsWhenClosing => 'Ao fechar a janela';

  @override
  String get settingsReadAloudEnabled => 'Read aloud';

  @override
  String get settingsReadAloudEnabledDescription =>
      'Show a read-aloud button on assistant messages.';

  @override
  String get settingsReadAloudPitch => 'Pitch';

  @override
  String get settingsReadAloudPitchDescription => 'Adjust the voice pitch.';

  @override
  String get settingsReadAloudSectionDescription =>
      'Read assistant responses aloud. Configure speed, pitch, and voice.';

  @override
  String get settingsReadAloudSectionTitle => 'Text to speech';

  @override
  String get settingsReadAloudSpeed => 'Speed';

  @override
  String get settingsReadAloudSpeedDescription => 'Adjust the speaking rate.';

  @override
  String get settingsReadAloudVoice => 'Voice';

  @override
  String get settingsReadAloudVoiceHint => 'Select a voice for read-aloud.';

  @override
  String get settingsServersActive => 'Ativo';

  @override
  String get settingsServersChooseActive => 'Escolher servidor ativo';

  @override
  String get settingsServersDefault => 'Padrão';

  @override
  String get settingsServersDescription =>
      'Servidores OpenCode e roteamento de saúde';

  @override
  String get settingsServersTitle => 'Servidores';

  @override
  String get settingsSetupWizard => 'Assistente de configuração';

  @override
  String get settingsShortcutsDescription =>
      'Atalhos de teclado portáteis do app';

  @override
  String get settingsShortcutsEdit => 'Editar atalho';

  @override
  String get settingsShortcutsKeyboard => 'Atalhos de teclado';

  @override
  String get settingsShortcutsReset => 'Redefinir atalho';

  @override
  String get settingsShortcutsSearch => 'Buscar atalhos';

  @override
  String get settingsShortcutsTitle => 'Atalhos';

  @override
  String get settingsSpeechDescription =>
      'Motor, tempo de silêncio e opções de modelo';

  @override
  String get settingsSpeechRefreshStatus => 'Atualizar status';

  @override
  String settingsSpeechSilenceTimeout(String value) {
    return 'Tempo de silêncio: ${value}s';
  }

  @override
  String get settingsSpeechTitle => 'Fala para texto';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get setupDebugBun => 'Bun';

  @override
  String get setupDebugBun2 => 'Bun';

  @override
  String get setupDebugCapturedSetupDetails => 'No captured setup details yet';

  @override
  String get setupDebugCapturedSetupLogs => 'Captured setup logs';

  @override
  String get setupDebugClear => 'Limpar debug de configuração';

  @override
  String get setupDebugClearSetupDebug => 'Clear setup debug';

  @override
  String get setupDebugCodeWalkCaptureEnough =>
      'If CodeWalk did not capture enough context, check the official OpenCode logs and health endpoints directly:';

  @override
  String get setupDebugCommandPath => 'Caminho do comando';

  @override
  String get setupDebugCommandPath2 => 'Command path';

  @override
  String get setupDebugCopy => 'Copiar debug de configuração';

  @override
  String get setupDebugCopySetupDebug => 'Copy setup debug';

  @override
  String get setupDebugCurrentStatus => 'Current status';

  @override
  String get setupDebugDiagnosticsLoading => 'Diagnostics are still loading.';

  @override
  String get setupDebugEnvironment => 'Diagnóstico do ambiente';

  @override
  String get setupDebugEnvironmentDiagnostics => 'Environment diagnostics';

  @override
  String get setupDebugFocusedOpenCodeSetup => 'Focused on OpenCode setup';

  @override
  String get setupDebugInstallDir => 'Diretório de instalação';

  @override
  String get setupDebugInstallDirectory => 'Install directory';

  @override
  String get setupDebugLatestLocalServer => 'Latest local server output';

  @override
  String get setupDebugLogs => 'Logs de configuração capturados';

  @override
  String get setupDebugManual => 'Solução de problemas manual';

  @override
  String get setupDebugManualTroubleshooting => 'Manual troubleshooting';

  @override
  String get setupDebugNetwork => 'Rede';

  @override
  String get setupDebugNetwork2 => 'Network';

  @override
  String get setupDebugNoDetails =>
      'Nenhum detalhe de configuração capturado ainda';

  @override
  String get setupDebugNode => 'Node.js';

  @override
  String get setupDebugNodeJs => 'Node.js';

  @override
  String get setupDebugNpm => 'npm';

  @override
  String get setupDebugNpm2 => 'npm';

  @override
  String get setupDebugOpenCode => 'OpenCode';

  @override
  String get setupDebugOpenCode2 => 'OpenCode';

  @override
  String get setupDebugOpenCodeSetupDebug => 'OpenCode Setup Debug';

  @override
  String get setupDebugPlatform => 'Plataforma';

  @override
  String get setupDebugPlatform2 => 'Platform';

  @override
  String get setupDebugRunDiagnosticsTry =>
      'Run diagnostics, try an installation method, or attempt a setup flow to capture OpenCode-specific troubleshooting details here.';

  @override
  String get setupDebugScreenCoversOpenCode =>
      'This screen only covers OpenCode installation, diagnostics, and local setup troubleshooting. Use App Logs for general CodeWalk runtime issues.';

  @override
  String get setupDebugServerOutput => 'Última saída do servidor local';

  @override
  String get setupDebugStatus => 'Status atual';

  @override
  String setupDebugTimeEntrySource(String time, String source) {
    return '$time - $source';
  }

  @override
  String get setupDebugTimeline => 'Linha do tempo';

  @override
  String get setupDebugTimeline2 => 'Timeline';

  @override
  String get setupDebugTitle => 'Focado na configuração do OpenCode';

  @override
  String get setupDebugWSL => 'WSL';

  @override
  String get setupDebugWsl => 'WSL';

  @override
  String get shortcutsApply => 'Apply';

  @override
  String shortcutsConflictConflict(String conflict) {
    return 'Conflito com $conflict';
  }

  @override
  String get shortcutsKeyboardShortcuts => 'Keyboard shortcuts';

  @override
  String get shortcutsReset => 'Reset all';

  @override
  String get shortcutsSearchEditBindings =>
      'Search, edit bindings, and resolve conflicts before saving.';

  @override
  String shortcutsSetShortcutWidget(String label) {
    return 'Definir atalho: $label';
  }

  @override
  String get shortcutsTheseBindingsStored =>
      'These bindings are stored in CodeWalk for the current app runtime and do not edit OpenCode `tui.json` keybinds.';

  @override
  String get speechAutoStopSilence => 'Auto-stop silence timeout';

  @override
  String get speechChooseRecognitionEngine =>
      'Choose the recognition engine, silence timeout, and model options.';

  @override
  String get speechDownload => 'Download';

  @override
  String get speechEngine => 'Engine';

  @override
  String get speechInstalledLanguages => 'Installed languages';

  @override
  String get speechListeningStopsAutomatically =>
      'Listening stops automatically after this many seconds of silence.';

  @override
  String get speechMoonshine => 'Moonshine';

  @override
  String get speechMoonshineModelsDesktop => 'Moonshine models (desktop)';

  @override
  String get speechMoonshineStaysDownloadable =>
      'Moonshine stays downloadable and out of the app bundle. Pick one model for this desktop device and remove it later if you want the space back.';

  @override
  String get speechNative => 'Native';

  @override
  String get speechNativeSTTDisabled =>
      'Native STT is disabled on Linux in this app. Parakeet is the default engine for new installs.';

  @override
  String get speechNativeSTTWorks =>
      'Native STT works on Windows when OS speech services are enabled. If native initialization fails, CodeWalk automatically falls back to Sherpa. Check Windows microphone privacy, Online speech recognition, and installed speech language packs.';

  @override
  String get speechNativeStartsFaster =>
      'Native starts faster. Sherpa runs fully on-device with heavier setup and deeper model control.';

  @override
  String get speechParakeet => 'Parakeet';

  @override
  String get speechParakeetModelsDesktop => 'Parakeet models (desktop)';

  @override
  String get speechParakeetStaysDownloadable =>
      'Parakeet stays downloadable and out of the app bundle. It currently exposes one multilingual model optimized for 25 European languages.';

  @override
  String get speechPickLanguagePacks =>
      'Pick language packs and download/remove models for on-device recognition.';

  @override
  String get speechRemove => 'Remove';

  @override
  String get speechSelectSherpaAbove =>
      'Select Sherpa above to manage language packs and download models.';

  @override
  String get speechSenseVoice => 'SenseVoice';

  @override
  String get speechSenseVoiceModelsDesktop => 'SenseVoice models (desktop)';

  @override
  String get speechSenseVoiceStaysDownloadable =>
      'SenseVoice stays downloadable and out of the app bundle. It is the strongest desktop option here for Chinese, Cantonese, Japanese, Korean, and English.';

  @override
  String get speechSherpa => 'Sherpa';

  @override
  String get speechSherpaExperimentalFail =>
      'Sherpa is experimental and can fail on some devices. Prefer Native if you want the most stable behavior.';

  @override
  String get speechSherpaModelsLinux => 'Sherpa models (Linux)';

  @override
  String get speechSpeechText => 'Speech to text';

  @override
  String get tailscaleNoPeers => 'No peers found';

  @override
  String get tailscalePeerOffline => 'offline';

  @override
  String get tailscaleSelectPeer => 'Select a Tailscale peer';

  @override
  String get terminalClose => 'Fechar terminal';

  @override
  String get terminalMinimize => 'Minimizar terminal';

  @override
  String get terminalReconnect => 'Reconectar terminal';

  @override
  String get terminalTerminal => 'Terminal';

  @override
  String get terminalTryAgain => 'Tentar novamente';

  @override
  String get toolAwaitingInput => 'Aguardando entrada';

  @override
  String get toolEditing => 'Editando';

  @override
  String get toolEditingFiles => 'Editando arquivos';

  @override
  String get toolFinding => 'Buscando';

  @override
  String get toolFindingFiles => 'Buscando arquivos';

  @override
  String get toolPresentationAwaitingInput => 'Awaiting input';

  @override
  String get toolPresentationEditing => 'Editing';

  @override
  String get toolPresentationEditingFiles => 'Editing files';

  @override
  String get toolPresentationFinding => 'Finding';

  @override
  String get toolPresentationFindingFiles => 'Finding files';

  @override
  String get toolPresentationReading => 'Reading';

  @override
  String get toolPresentationReadingFile => 'Reading file';

  @override
  String get toolPresentationRunning => 'Running';

  @override
  String get toolPresentationRunningCommand => 'Running command';

  @override
  String get toolPresentationSearching => 'Searching';

  @override
  String get toolPresentationSearchingCode => 'Searching code';

  @override
  String get toolPresentationSearchingWeb => 'Searching the web';

  @override
  String get toolPresentationUpdatingTaskList => 'Updating task list';

  @override
  String get toolPresentationUpdatingTasks => 'Updating tasks';

  @override
  String get toolPresentationWaitingInput => 'Waiting for your input';

  @override
  String get toolPresentationWriting => 'Writing';

  @override
  String get toolPresentationWritingFile => 'Writing file';

  @override
  String get toolReading => 'Lendo';

  @override
  String get toolReadingFile => 'Lendo arquivo';

  @override
  String get toolRunning => 'Executando';

  @override
  String get toolRunningCommand => 'Executando comando';

  @override
  String get toolRunningTask => 'Executando tarefa';

  @override
  String get toolSearching => 'Pesquisando';

  @override
  String get toolSearchingCode => 'Pesquisando código';

  @override
  String get toolSearchingWeb => 'Pesquisando na web';

  @override
  String get toolUpdatingTaskList => 'Atualizando lista de tarefas';

  @override
  String get toolUpdatingTasks => 'Atualizando tarefas';

  @override
  String get toolWaitingForInput => 'Aguardando sua entrada';

  @override
  String get toolWriting => 'Escrevendo';

  @override
  String get toolWritingFile => 'Escrevendo arquivo';

  @override
  String get tourBack => 'Voltar';

  @override
  String get tourSkip => 'Pular';

  @override
  String get trayQuit => 'Sair';

  @override
  String get trayShow => 'Mostrar';

  @override
  String get useOAuthCloudflareAccess => 'Use OAuth (Cloudflare Access)';

  @override
  String get useOAuthCloudflareAccessSubtitle =>
      'Opens a browser for Cloudflare Access Managed OAuth.';

  @override
  String get useOAuthCloudflareAccessUnsupported =>
      'Cloudflare Access OAuth is not available on this platform. Use Basic Auth instead.';

  @override
  String get useTailscale => 'Use Tailscale';

  @override
  String get useTailscaleSubtitle =>
      'Routes traffic through the Tailscale network without a system VPN.';

  @override
  String get useTailscaleUnsupported =>
      'Tailscale is not supported on this platform.';

  @override
  String get workspaceBrowseDirs => 'Navegar diretórios';

  @override
  String get workspaceChooseFolderOpen =>
      'Choose any folder to open as project context.';

  @override
  String workspaceCloseProject(String project) {
    return 'Fechar $project';
  }

  @override
  String get workspaceFilterDirs => 'Filtrar diretórios';

  @override
  String get workspaceOpenFolder => 'Open folder';

  @override
  String get workspaceOpenProjectFolder => 'Open project folder';

  @override
  String get workspaceProjectDirectory => 'Diretório do projeto';

  @override
  String get workspaceProjectHint => '/repo/meu-projeto';

  @override
  String workspaceRemoveFromHistory(String name) {
    return 'Remover $name do histórico';
  }

  @override
  String get workspaceSuggestions => 'Suggestions';

  @override
  String get onboardingSetup => 'Configuração';

  @override
  String get onboardingSetupWizard => 'Assistente de configuração';

  @override
  String get onboardingServerSetup => 'Configuração do servidor';

  @override
  String get onboardingEditServer => 'Editar servidor';

  @override
  String get onboardingLocalServerSetup => 'Configuração do servidor local';

  @override
  String get onboardingReady => 'Pronto';

  @override
  String onboardingWelcomeTo(String appName) {
    return 'Bem-vindo ao $appName';
  }

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return 'O $appName precisa de um servidor OpenCode antes de poder ajudar com o seu código.';
  }

  @override
  String get onboardingChooseHowToSetup =>
      'Escolha como configurar seu servidor';

  @override
  String get onboardingPickSetupPath =>
      'Escolha o caminho de configuração que corresponde à sua configuração atual do OpenCode.';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'Apenas desktop: o $appName pode diagnosticar, instalar e executar o OpenCode para você.';
  }

  @override
  String get onboardingAvailableOnlyDesktop =>
      'Disponível apenas para desktop (Linux/macOS/Windows).';

  @override
  String get onboardingServerConnection => 'Conexão do servidor';

  @override
  String get onboardingEditServerConnection => 'Editar conexão do servidor';

  @override
  String onboardingSuggestedUrl(String url) {
    return 'URL sugerida para o servidor OpenCode local: $url';
  }

  @override
  String get onboardingEmulatorRemap =>
      'No emulador Android, localhost e 127.0.0.1 são remapeados para 10.0.2.2 automaticamente.';

  @override
  String get onboardingBasicAuthTip =>
      'Ative o Basic Auth apenas se o seu servidor OpenCode estiver protegido por senha.';

  @override
  String get onboardingEnterServerUrl => 'Digite a URL do servidor';

  @override
  String get onboardingInvalidUrl => 'URL inválida';

  @override
  String get onboardingTesting => 'Testando...';

  @override
  String get onboardingSaveAndTest => 'Salvar e testar';

  @override
  String get onboardingTestConnection => 'Testar conexão';

  @override
  String get onboardingTailscaleLoginRequired =>
      'Login do Tailscale necessário';

  @override
  String get onboardingTailscaleAdminApproval =>
      'Aprovação do administrador do Tailscale necessária';

  @override
  String get onboardingTailscaleConnected => 'Tailscale conectado';

  @override
  String get onboardingTailscaleConnecting => 'Tailscale conectando';

  @override
  String get onboardingTailscaleConnectionFailed =>
      'Falha na conexão do Tailscale';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale não suportado';

  @override
  String get onboardingTailscaleAuthAfterSave =>
      'O Tailscale irá autenticar após salvar';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'Abra a URL de login para adicionar este dispositivo à sua tailnet. Se o navegador não abrir, copie a URL abaixo.';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'Depois de salvar e testar este servidor, o $appName abrirá o login do Tailscale se este dispositivo ainda não estiver autenticado.';
  }

  @override
  String get onboardingStarting => 'Iniciando';

  @override
  String get onboardingStopping => 'Parando';

  @override
  String get onboardingFailed => 'Falhou';

  @override
  String get onboardingStopped => 'Parado';

  @override
  String get onboardingUsingDetectedCommand =>
      'Usando o comando OpenCode detectado.';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingDone => 'Concluído';

  @override
  String get onboardingYoureAllSet => 'Está tudo pronto!';

  @override
  String get onboardingServerUpdated => 'Servidor atualizado';

  @override
  String get onboardingServerConnectedReady =>
      'Seu servidor está conectado e pronto para uso.';

  @override
  String get onboardingServerSettingsSaved =>
      'As configurações do servidor foram salvas e as verificações de integridade foram atualizadas.';

  @override
  String onboardingStartUsing(String appName) {
    return 'Começar a usar o $appName';
  }

  @override
  String get onboardingCouldNotVerify =>
      'Não foi posible verificar a conexão com o servidor.';

  @override
  String get onboardingCloudflareAuthFailed =>
      'A autenticação do Cloudflare Access falhou.';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'A verificação de integridade do servidor falhou. Ele ainda pode estar iniciando.';

  @override
  String get onboardingConnectionUpdated =>
      'Conexão com o servidor atualizada com sucesso.';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'Servidor adicionado, mas a verificação de integridade falhou. Ele ainda pode estar iniciando.';

  @override
  String get onboardingConnectionSaved =>
      'Conexão com o servidor salva com sucesso.';

  @override
  String get onboardingAvailable => 'disponível';

  @override
  String get onboardingNotAvailable => 'não disponível';

  @override
  String get onboardingReachable => 'alcançável';

  @override
  String get onboardingUnreachable => 'inalcançável';

  @override
  String get onboardingWritable => 'gravável';

  @override
  String get onboardingNotWritable => 'não gravável';

  @override
  String toolPresentationRunningTool(String toolName) {
    return 'Executando $toolName';
  }

  @override
  String get toolPresentationTool => 'Ferramenta';

  @override
  String get shortcutGroupSession => 'Sessão';

  @override
  String get shortcutGroupGeneral => 'Geral';

  @override
  String get shortcutGroupPrompt => 'Prompt';

  @override
  String get shortcutGroupNavigation => 'Navegação';

  @override
  String get shortcutGroupModelAndAgent => 'Modelo e agente';

  @override
  String get shortcutGroupApplication => 'Aplicativo';

  @override
  String get shortcutNewConversation => 'Nova conversa';

  @override
  String get shortcutNewConversationDesc => 'Criar uma nova sessão de chat';

  @override
  String get shortcutRefreshData => 'Atualizar dados';

  @override
  String get shortcutRefreshDataDesc => 'Atualizar os dados do chat atual';

  @override
  String get shortcutFocusInput => 'Focar entrada';

  @override
  String get shortcutFocusInputDesc => 'Mover o foco para a entrada de texto';

  @override
  String get shortcutToggleVoiceInput => 'Alternar entrada de voz';

  @override
  String get shortcutToggleVoiceInputDesc =>
      'Iniciar ou parar o ditado de voz no editor';

  @override
  String get shortcutQuickOpenFiles => 'Abertura rápida de arquivos';

  @override
  String get shortcutQuickOpenFilesDesc => 'Abrir busca rápida de arquivos';

  @override
  String get shortcutOpenSettings => 'Abrir configurações';

  @override
  String get shortcutOpenSettingsDesc => 'Abrir a página de configurações';

  @override
  String get shortcutNextRecentModel => 'Próximo modelo recente';

  @override
  String get shortcutNextRecentModelDesc =>
      'Alternar entre os modelos usados recentemente';

  @override
  String get shortcutNextVariant => 'Próxima variante';

  @override
  String get shortcutNextVariantDesc =>
      'Alternar entre as variantes de modelo disponíveis';

  @override
  String get shortcutFocusCloseDrawer => 'Focar/fechar painel';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'Focar entrada por padrão, ou fechar painel quando aberto';

  @override
  String get shortcutNextAgent => 'Próximo agente';

  @override
  String get shortcutNextAgentDesc =>
      'Alternar para o próximo agente disponível';

  @override
  String get shortcutPreviousAgent => 'Agente anterior';

  @override
  String get shortcutPreviousAgentDesc =>
      'Alternar para o agente anterior disponível';

  @override
  String get shortcutCloseApp => 'Fechar aplicativo';

  @override
  String get shortcutCloseAppDesc =>
      'Fechar o aplicativo usando o comportamento de fechamento da plataforma';

  @override
  String get shortcutQuitApp => 'Sair do aplicativo';

  @override
  String get shortcutQuitAppDesc => 'Forçar a saída do aplicativo';

  @override
  String get shortcutStopResponse => 'Parar resposta';

  @override
  String get shortcutStopResponseDesc =>
      'Parar resposta ativa (enquanto responde)';

  @override
  String get errorConnectionFailed => 'Falha na conexão';

  @override
  String get errorConnectionFailedDesc =>
      'Não foi possível contactar o servidor. Verifique a conexão e o status do servidor.';

  @override
  String get errorQuotaExceeded => 'Cota excedida';

  @override
  String get errorQuotaExceededDesc =>
      'Cota excedida. Verifique o plano do seu provedor ou faturamento.';

  @override
  String get errorRateLimitExceeded => 'Limite de taxa excedido';

  @override
  String get errorRateLimitExceededDesc =>
      'Limite de taxa excedido. Aguarde um momento e tente novamente.';

  @override
  String get errorAuthRequired => 'Autenticação necessária';

  @override
  String get errorAuthRequiredDesc =>
      'A autenticação falhou. Reconecte o provedor e tente novamente.';

  @override
  String get errorServiceUnavailable => 'Serviço indisponível';

  @override
  String get errorServiceUnavailableDesc =>
      'Serviço temporariamente indisponível. O servidor pode estar iniciando — por favor, tente novamente em breve.';

  @override
  String get errorProviderUnavailable => 'Provedor indisponível';

  @override
  String get errorProviderUnavailableDesc =>
      'Provedor temporariamente indisponível. Tente novamente em breve.';

  @override
  String get errorServerError => 'Erro no servidor';

  @override
  String get errorServerErrorDesc =>
      'Erro no servidor. Por favor, tente novamente.';

  @override
  String get attachmentNotAvailableOnPlatform =>
      'As ações de anexo não estão disponíveis nesta plataforma.';

  @override
  String get attachmentUnableToOpenLink =>
      'Não foi possível abrir o link do anexo.';

  @override
  String get attachmentNoValidLocation =>
      'O anexo não fornece um local válido.';

  @override
  String get attachmentDownloadStarted => 'O download do anexo começou.';

  @override
  String get attachmentCouldNotDownload => 'Não foi possível baixar o anexo.';

  @override
  String get attachmentCouldNotDecode =>
      'Não foi possível decodificar os dados do anexo.';

  @override
  String get attachmentPayloadEmpty => 'A carga útil do anexo está vazia.';

  @override
  String attachmentSavedAndOpened(String path) {
    return 'Anexo salvo em $path e aberto.';
  }

  @override
  String attachmentSavedTo(String path) {
    return 'Anexo salvo em $path.';
  }

  @override
  String get attachmentCouldNotSave =>
      'Não foi possível salvar o anexo neste dispositivo.';

  @override
  String get attachmentSaveCanceled => 'Salvamento cancelado.';

  @override
  String attachmentSavedPath(String path) {
    return 'Anexo salvo em $path.';
  }

  @override
  String get attachmentPathEmpty => 'O caminho do anexo está vazio.';

  @override
  String get attachmentLocalNotFound =>
      'O anexo local não foi encontrado neste dispositivo.';

  @override
  String get attachmentUnableToOpenLocal =>
      'Não foi possível abrir o anexo local.';

  @override
  String speechDesktopOnly(String service) {
    return '$service está disponível apenas na versão desktop.';
  }

  @override
  String speechRuntimeFailed(String service) {
    return 'O tempo de execução do $service falhou ao inicializar.';
  }

  @override
  String speechModelFilesIncomplete(String service) {
    return 'Os arquivos de modelo do $service estão incompletos.';
  }

  @override
  String get speechMicPermissionDisabled =>
      'A permissão do microfone está desativada.';

  @override
  String speechUnavailableOnPlatform(String service) {
    return 'A fala do $service não está disponível nesta plataforma.';
  }

  @override
  String get terminalOpenToConnect =>
      'Abra o Terminal para se conectar ao terminal do projeto do servidor.';

  @override
  String get terminalNotAvailableYet =>
      'O terminal incorporado ainda não está disponível neste tempo de execução.';

  @override
  String get terminalSelectServer =>
      'Selecione um servidor ativo antes de abrir o Terminal.';

  @override
  String get terminalOpenProjectFirst =>
      'Abra uma pasta de projeto antes de iniciar o terminal do servidor.';

  @override
  String terminalConnectingTo(String serverName) {
    return 'Conectando ao terminal do $serverName...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'Falha na conexão do terminal: $error';
  }

  @override
  String get terminalDisconnected => 'Terminal desconectado.';

  @override
  String get terminalSessionClosed => 'Sessão de terminal encerrada.';

  @override
  String get notificationConversationUpdates => 'Atualizações da conversa';

  @override
  String get notificationOpenToClear =>
      'Abra esta conversa para limpar as notificações relacionadas.';

  @override
  String get notificationAgentFinished => 'O agente terminou a resposta atual.';

  @override
  String get notificationSession => 'Sessão';

  @override
  String get chatBadgeServerNeedsAttention =>
      'A conexão do servidor precisa de atenção.';

  @override
  String chatBadgeConversationError(String title) {
    return '\"$title\" tem um erro.';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '\"$title\" precisa da sua intervenção.';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '\"$title\" tem uma nova resposta.';
  }

  @override
  String get chatBadgeSyncing => 'Sincronizando conversas...';

  @override
  String get chatBadgeDataSaverActive =>
      'A economia de dados móveis está ativa.';

  @override
  String get chatCollapseGroup => 'Recolher grupo';

  @override
  String get chatExpandGroup => 'Expandir grupo';

  @override
  String get chatForkFailed => 'Falha ao bifurcar conversa';

  @override
  String get chatForked => 'Conversa bifurcada';

  @override
  String get chatNoConversationsInProject => 'Nenhuma conversa neste projeto.';

  @override
  String get chatOpenProjectToLoad =>
      'Abra um projeto para carregar conversas.';

  @override
  String get chatExportCanceled => 'Exportação de sessão cancelada';

  @override
  String get chatLargeContentSkipped =>
      'Conteúdo grande ou malformado foi ignorado para estabilidade.';

  @override
  String chatTokensLabel(int total) {
    return 'Tokens: $total';
  }

  @override
  String chatCostLabel(String cost) {
    return 'Custo: \$$cost';
  }

  @override
  String get chatFileExplorerNames => 'Nomes';

  @override
  String get chatFileExplorerContents => 'Conteúdos';

  @override
  String chatCloseProject(String project) {
    return 'Fechar $project';
  }

  @override
  String get sessionExportUser => 'Usuário';

  @override
  String get sessionExportAssistant => 'Assistente';

  @override
  String get sessionExportInput => 'Entrada:';

  @override
  String get sessionExportOutput => 'Saída:';

  @override
  String get sessionExportError => 'Erro:';

  @override
  String get sessionExportUntitled => 'Sessão sem título';

  @override
  String get modelLabelTinyEnglish => 'Tiny (Inglês)';

  @override
  String get modelLabelBaseEnglish => 'Base (Inglês)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 idiomas europeus)';

  @override
  String get cannedNewQuickReply => 'Nova resposta rápida';

  @override
  String get settingsSoundPickerNotAvailable =>
      'O seletor de sons do sistema não está disponível nesta plataforma.';

  @override
  String get appProviderPrimaryServer => 'Servidor primário';

  @override
  String get appProviderLocalManaged => 'OpenCode Local (Gerenciado)';

  @override
  String get appProviderLocalServerStopped => 'O servidor local está parado.';

  @override
  String get appProviderRunDiagnostics =>
      'Execute diagnósticos para verificar os requisitos locais do OpenCode.';

  @override
  String get appProviderInvalidServerUrl => 'URL do servidor inválida';

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth não é suportado nesta plataforma';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale não é suportado nesta plataforma';

  @override
  String get appProviderProfileNotFound => 'Perfil de servidor não encontrado';

  @override
  String get appProviderCannotActivateUnhealthy =>
      'Não é possível ativar um servidor não saudável';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode detectado';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode não detectado';

  @override
  String get appProviderDetectingCommand => 'Detectando comando OpenCode...';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'O comando OpenCode não foi detectado. Se você o instalou há pouco tempo, atualize as verificações ou reabra o $appName para recarregar o PATH.';
  }

  @override
  String get appProviderNotDetectedInstall =>
      'O comando OpenCode não foi detectado. Execute a instalação a partir do assistente.';

  @override
  String appProviderUsingCommandAt(String path) {
    return 'Usando comando OpenCode em $path';
  }

  @override
  String get appProviderDesktopOnly =>
      'O servidor local gerenciado está disponível apenas no desktop.';

  @override
  String get appProviderInstallingRequirements =>
      'Instalando requisitos do OpenCode...';

  @override
  String get appProviderInstallationFailed =>
      'A instalação do OpenCode falhou.';

  @override
  String get appProviderInstalledSuccessfully =>
      'Requisitos do OpenCode instalados com sucesso.';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'Instalação bem-sucedida. Comando OpenCode disponível em $path.';
  }

  @override
  String get appProviderInstallSucceeded => 'Instalação bem-sucedida.';

  @override
  String get appProviderStartingLocalServer => 'Iniciando servidor local...';

  @override
  String get appProviderFailedToStart =>
      'Falha ao iniciar o servidor OpenCode local.';

  @override
  String appProviderRunningAt(String url) {
    return 'Rodando em $url';
  }

  @override
  String get appProviderStoppingLocalServer => 'Parando servidor local...';

  @override
  String appProviderExitedWithCode(int code) {
    return 'O servidor local saiu com o código $code.';
  }

  @override
  String get appProviderInstallBinary => 'Instalar binário';

  @override
  String get appProviderInstallViaNpm => 'Instalar via npm';

  @override
  String get appProviderInstallViaBun => 'Instalar via Bun';

  @override
  String get appProviderInstallBunOpenCode => 'Instalar Bun + OpenCode';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'O Tailscale não é suportado nesta plataforma.';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'O Tailscale não é suportado no Windows.';

  @override
  String get tailscaleWaitingAdminApproval =>
      'Este nó do Tailscale está aguardando aprovação do administrador.';

  @override
  String get notificationSoundLoadFailed =>
      'Falha ao carregar os sons do sistema Android';

  @override
  String get chatDescriptionNewConversation => 'Nova conversa';

  @override
  String get chatDescriptionRefreshData => 'Atualizar dados do chat';

  @override
  String get chatDescriptionFocusInput => 'Focar entrada de mensagem';

  @override
  String get chatDescriptionVoiceInput => 'Iniciar ou parar entrada de voz';

  @override
  String get chatDescriptionQuickOpen => 'Abertura rápida de arquivos';

  @override
  String get chatDescriptionOpenSettings => 'Abrir configurações';

  @override
  String get chatDescriptionCycleModels => 'Alternar modelos recentes';

  @override
  String get chatDescriptionCycleVariant => 'Alternar variante do modelo';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      'Focar entrada (ou fechar painel quando aberto)';

  @override
  String get chatDescriptionNextAgent => 'Próximo agente';

  @override
  String get chatDescriptionPreviousAgent => 'Agente anterior';

  @override
  String get chatDescriptionCloseApp =>
      'Fechar o aplicativo usando o comportamento de fechamento da plataforma';

  @override
  String get chatDescriptionForceExit => 'Forçar saída do aplicativo';

  @override
  String get chatDescriptionStopResponse =>
      'Parar resposta ativa (enquanto responde)';

  @override
  String get chatDescriptionProjectCommand => 'Comando do projeto';

  @override
  String get chatDescriptionOpenProjects =>
      'Use este botão para abrir seus projetos e conversas.';

  @override
  String get chatDescriptionSwitchProject =>
      'Use este botão para alternar pastas de projeto e contexto.';

  @override
  String chatDescriptionChildren(int count) {
    return 'Filhos: $count';
  }

  @override
  String get chatDescriptionDiffFilesZero => 'Arquivos diff: 0';

  @override
  String get appProviderErrorInvalidServerUrl => 'URL do servidor inválida';

  @override
  String get appProviderErrorServerUrlRequired =>
      'A URL do servidor é obrigatória';

  @override
  String get appProviderErrorServerAlreadyExists =>
      'Um servidor com esta URL já existe';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth não é suportado nesta plataforma';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale não é suportado nesta plataforma';

  @override
  String get appProviderErrorServerProfileNotFound =>
      'Perfil de servidor não encontrado';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      'Não é possível ativar um servidor não saudável';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      'O servidor local gerenciado está disponível apenas no desktop.';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'O servidor local iniciou, mas a verificação de integridade não passou.';

  @override
  String get appProviderErrorInstallationFailed =>
      'A instalação do OpenCode falhou.';

  @override
  String get appProviderStatusLocalServerStopped =>
      'O servidor local está parado.';

  @override
  String get appProviderStatusStartingLocalServer =>
      'Iniciando servidor local...';

  @override
  String appProviderStatusRunningAt(String url) {
    return 'Rodando em $url';
  }

  @override
  String get appProviderStatusStoppingLocalServer =>
      'Parando servidor local...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'O servidor local saiu com o código $code.';
  }

  @override
  String get appProviderSetupDetectingOpenCode =>
      'Detectando comando OpenCode...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode detectado';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode não detectado';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return 'Usando comando OpenCode em $path';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'Instalando requisitos do OpenCode...';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'Requisitos do OpenCode instalados com sucesso.';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'Instalação bem-sucedida. Comando OpenCode disponível em $path.';
  }

  @override
  String get appProviderSetupInstallationSucceeded =>
      'Instalação bem-sucedida.';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'O comando OpenCode não foi detectado. Se você o instalou há pouco tempo, atualize as verificações ou reabra o CodeWalk para recarregar o PATH.';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'O comando OpenCode não foi detectado. Execute a instalação a partir do assistente.';

  @override
  String get appProviderLabelPrimaryServer => 'Servidor primário';

  @override
  String get appProviderLabelLocalOpenCodeManaged =>
      'OpenCode Local (Gerenciado)';
}
