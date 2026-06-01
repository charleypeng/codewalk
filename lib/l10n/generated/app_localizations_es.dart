// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appShellDownloadingUpdate => 'Descargando actualización';

  @override
  String get appShellInstall => 'Instalar';

  @override
  String get appShellInstallFailed => 'Instalación fallida';

  @override
  String get appShellInstallingUpdate => 'Instalando actualización...';

  @override
  String get appShellRestart => 'Reiniciar';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return 'Actualización disponible: v$latestVersion';
  }

  @override
  String get behaviorAdvancedPermissionRule => 'Regla de permiso avanzada';

  @override
  String get behaviorAutomatic => 'Automático';

  @override
  String get behaviorAutomaticFallback => 'Respaldo automático';

  @override
  String get behaviorCellularDataSaver => 'Ahorro de datos móviles';

  @override
  String get behaviorChatLevelShare => 'Compartir a nivel de chat';

  @override
  String get behaviorCodeWalkReleaseChecks =>
      'Verificaciones de versión de CodeWalk';

  @override
  String get behaviorControlsOfficialGlobal =>
      'Controla la configuración global oficial de OpenCode';

  @override
  String get behaviorControlsUpstreamOpenCode =>
      'Controla la configuración de OpenCode ascendente';

  @override
  String get behaviorCustomDisplayName => 'Nombre para mostrar personalizado';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return 'Reduce el uso automático de datos móviles deteniendo las descargas en segundo plano y limitando las actualizaciones automáticas en primer plano a una ráfaga cada $inSeconds segundos.';
  }

  @override
  String get behaviorDisabled => 'Desactivado';

  @override
  String get behaviorLightweightTasksLike => 'Tareas ligeras como';

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
  String get cannedNoSuggestions => 'Sin sugerencias';

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
      'Agregue un servidor para comenzar a chatear.';

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
    return 'Hijos: $length';
  }

  @override
  String get chatChooseDirectory => 'Choose Directory';

  @override
  String get chatChooseFolderOpen =>
      'Choose a folder to open as project context.';

  @override
  String get chatClose => 'Cerrar';

  @override
  String get chatCompactContext => 'Compactar Contexto';

  @override
  String get chatConversations => 'Conversaciones';

  @override
  String get chatConversationsPane => 'Conversaciones';

  @override
  String get chatCurrent => 'Use current';

  @override
  String get chatDiffFiles => 'Diff files: 0';

  @override
  String get chatDisplay => 'Display';

  @override
  String get chatDisplayToggles => 'Opciones de visualización';

  @override
  String get chatDoubleESCStop => 'Doble ESC para detener';

  @override
  String get chatFilterActive => 'Activas';

  @override
  String get chatFilterAll => 'Todas';

  @override
  String get chatFilterArchived => 'Archivadas';

  @override
  String get chatFilterDirectories => 'Filter directories';

  @override
  String get chatFilterSessions => 'Filtrar sesiones';

  @override
  String get chatGoToFirst => 'Ir al primer mensaje';

  @override
  String get chatGoToLatest => 'Ir al último mensaje';

  @override
  String chatGroupMessageCountMessages(
    String messageCount,
    String compactionLabel,
  ) {
    return '$messageCount mensajes ocultos antes de la compactación $compactionLabel';
  }

  @override
  String get chatHelloAssistant => '¡Hola! Soy tu asistente de IA';

  @override
  String get chatHelp => 'How can I help you?';

  @override
  String get chatHideConversationsSidebar => 'Ocultar barra de Conversaciones';

  @override
  String get chatHideUtilitySidebar => 'Ocultar barra de Utilidades';

  @override
  String get chatHistoryCollapsed => 'Previous history is collapsed';

  @override
  String get chatKeepWorking => 'Seguir trabajando';

  @override
  String get chatLatestToolActivity =>
      'Latest tool activity stays inside this bounded panel to keep the chat viewport stable.';

  @override
  String get chatLoadMore => 'Cargar más';

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
    return 'Proveedor: $providerId';
  }

  @override
  String get chatMessageRewindEdit => 'Rewind and edit from here';

  @override
  String get chatMessageYou => 'You';

  @override
  String get chatNewChat => 'Nueva Conversación';

  @override
  String get chatNewChatTourDescription =>
      'Inicie una nueva conversación aquí.';

  @override
  String get chatNewChatTourTitle => 'Nueva conversación';

  @override
  String get chatNoServerYet => 'Aún no hay servidor configurado';

  @override
  String get chatOpenFiles => 'Abrir Archivos';

  @override
  String get chatOpenProject => 'Abrir proyecto';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenSidebar => 'Abrir barra lateral';

  @override
  String get chatPageStatusContextUsage => 'Uso del contexto';

  @override
  String get chatPageStatusCost => 'Costo';

  @override
  String get chatPageStatusLimit => 'Límite';

  @override
  String get chatPageStatusManageServers => 'Gestionar servidores';

  @override
  String get chatPageStatusSaver => 'Ahorro';

  @override
  String get chatPageStatusSwitchServer => 'Cambiar servidor';

  @override
  String get chatPageStatusTokens => 'Tokens';

  @override
  String get chatPageStatusUsage => 'Uso';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatProjectContext => 'Contexto del Proyecto';

  @override
  String get chatProjectContext2 => 'Contexto del proyecto';

  @override
  String get chatRealtimeGlobalEvent => 'evento global';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return 'evento global ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale =>
      'evento global (generación obsoleta)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return 'flujo de mensajes ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => 'evento en tiempo real';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return 'evento en tiempo real ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale =>
      'evento en tiempo real (generación obsoleta)';

  @override
  String get chatRealtimeReconnectingServerTry =>
      'Reconectando al servidor. Intente de nuevo en un momento.';

  @override
  String get chatReasoning => 'Razonando...';

  @override
  String get chatRecentSessions => 'Sesiones recientes';

  @override
  String get chatRecentSessionsToggle => 'Sesiones recientes';

  @override
  String get chatRedoLastTurn => 'Rehacer último turno deshecho';

  @override
  String get chatRefresh => 'Actualizar';

  @override
  String get chatRefreshConversation => 'Could not refresh this conversation';

  @override
  String get chatRefreshProjects => 'Refresh projects';

  @override
  String get chatRefreshSessionDetails => 'Actualizar detalles de sesión';

  @override
  String chatRemoveDisplayNameHistory(String displayName) {
    return 'Eliminar $displayName del historial';
  }

  @override
  String get chatRetry => 'Reintentar';

  @override
  String get chatRetry2 => 'Retry';

  @override
  String get chatRetryRefresh => 'Reintentar actualización';

  @override
  String get chatRetryingModelRequest => 'Reintentando solicitud del modelo...';

  @override
  String get chatReturnToMainConversation =>
      'Volver a la conversación principal';

  @override
  String get chatReviewChanges => 'Review changes';

  @override
  String get chatSearchConversations => 'Buscar conversaciones';

  @override
  String get chatSearchNextResult => 'Siguiente resultado';

  @override
  String get chatSearchNoResults => 'Sin resultados';

  @override
  String get chatSearchPreviousResult => 'Resultado anterior';

  @override
  String chatSearchResultCount(int current, int total) {
    return 'Mensaje $current de $total';
  }

  @override
  String get chatSearchTimeline => 'Buscar en la cronología';

  @override
  String get chatSelectDirectory => 'Select directory';

  @override
  String get chatSelectOrCreate =>
      'Seleccione o cree una conversación para comenzar a chatear';

  @override
  String get chatSelectProjectBelow => 'Select a project below.';

  @override
  String get chatSessionActions => 'Acciones de sesión';

  @override
  String chatSessionChatSessionSession(String title) {
    return 'Sesión de chat: $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return 'Conversación $nextAction';
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
  String get chatSidebarAccess => 'Acceso a la barra lateral';

  @override
  String get chatSortMostRecent => 'Más Recientes';

  @override
  String get chatSortOldest => 'Más Antiguas';

  @override
  String get chatSortRecent => 'Recientes';

  @override
  String get chatSortSessions => 'Ordenar sesiones';

  @override
  String get chatSortTitle => 'Título';

  @override
  String chatSyncLabel(String label) {
    return 'Sincronización: $label';
  }

  @override
  String get chatTasks => 'Tasks';

  @override
  String get chatTasksAvailableSession =>
      'No tasks are available for this session.';

  @override
  String get chatToggleSidebars => 'Alternar barras laterales';

  @override
  String get chatUndoLastTurn => 'Deshacer último turno';

  @override
  String get chatUseCurrent => 'Usar actual';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonReset => 'Restablecer';

  @override
  String get commonSave => 'Guardar';

  @override
  String get composerAddAttachment => 'Agregar adjunto';

  @override
  String get composerAttachFiles => 'Adjuntar archivos';

  @override
  String get composerCannedAppendAtCursor => 'Agregar en el cursor';

  @override
  String get composerCannedLabel => 'Etiqueta (opcional)';

  @override
  String get composerCannedNoReplies => 'Aún no hay respuestas rápidas.';

  @override
  String get composerCannedReplace => 'Reemplazar';

  @override
  String get composerCannedSave => 'Guardar';

  @override
  String get composerCannedScopeGlobal => 'Global';

  @override
  String get composerCannedScopeProject => 'Solo del proyecto';

  @override
  String get composerCannedSendAutomatically => 'Enviar automáticamente';

  @override
  String get composerCannedText => 'Texto';

  @override
  String get composerChatInput => 'Entrada de chat';

  @override
  String get composerDeleteAction => 'Eliminar';

  @override
  String get composerEdit => 'Editar';

  @override
  String get composerExtras => 'Extras';

  @override
  String get composerNewQuickReply => 'Nueva respuesta rápida';

  @override
  String get composerSelectImages => 'Seleccionar Imágenes';

  @override
  String get composerSelectPdf => 'Seleccionar PDF';

  @override
  String get composerSend => 'Enviar';

  @override
  String get composerShellMode => 'Modo shell';

  @override
  String get dialogDownload => 'Descargar';

  @override
  String get dialogLanguage => 'Idioma';

  @override
  String get dialogMoonshineModelSize => 'Tamaño del modelo';

  @override
  String get dialogMoonshineVoiceSetup => 'Configuración de Voz Moonshine';

  @override
  String get dialogParakeetModel => 'Modelo Parakeet';

  @override
  String get dialogParakeetVoiceSetup => 'Configuración de Voz Parakeet';

  @override
  String get dialogSenseVoiceModel => 'Modelo SenseVoice';

  @override
  String get dialogSenseVoiceSetup => 'Configuración SenseVoice';

  @override
  String get dialogVoiceInputSetup => 'Configuración de Entrada de Voz';

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
    return 'Adjunto guardado en $path y abierto.';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return 'Adjunto guardado en $path.';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return 'Adjunto guardado en $savedPath.';
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
  String get filesHideSidebar => 'Ocultar barra de Archivos';

  @override
  String get filesNames => 'Names';

  @override
  String filesOpenFilesFileState(String length) {
    return 'Archivos abiertos ($length)';
  }

  @override
  String get filesQuickOpen => 'Apertura Rápida';

  @override
  String get filesQuickOpenFile => 'Quick Open File';

  @override
  String get filesRefresh => 'Actualizar archivos';

  @override
  String get filesSearchHint => 'Buscar archivos por nombre o ruta';

  @override
  String get filesTitle => 'Archivos';

  @override
  String get logsAppLogs => 'App Logs';

  @override
  String get logsClear => 'Limpiar registros';

  @override
  String get logsCloseSearch => 'Cerrar búsqueda';

  @override
  String get logsCopyFiltered => 'Copiar registros filtrados';

  @override
  String get logsLevel => 'Level';

  @override
  String get logsSearch => 'Buscar registros';

  @override
  String logsShowingOrderedLength(int length, int length2) {
    return 'Mostrando $length de $length2 entradas';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => 'Matemáticas';

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
  String get modelLoadingModels => 'Cargando modelos';

  @override
  String get modelModelsFound => 'No models found';

  @override
  String get modelRetryModels => 'Reintentar modelos';

  @override
  String get modelSearchHint => 'Buscar modelo o proveedor';

  @override
  String get msgBatterySettingsFailed =>
      'No se pudo abrir la configuración de optimización de batería de Android.';

  @override
  String get msgBatterySettingsOpened =>
      'Configuración de batería de Android abierta. Permita batería sin restricciones para CodeWalk.';

  @override
  String get msgClearUsernameNeedsConfigEdit =>
      'Limpiar el nombre de usuario de la conversación de OpenCode aún requiere editar la configuración fuera de la app.';

  @override
  String get msgCommandCopied => 'Comando copiado';

  @override
  String get msgCopiedToClipboard => 'Copiado al portapapeles';

  @override
  String get msgEnterUsernameToSave =>
      'Ingrese un nombre de usuario para guardar un nombre de conversación personalizado de OpenCode.';

  @override
  String get msgFailedToSendMessage =>
      'Error al enviar mensaje. Borrador conservado para reintentar.';

  @override
  String get msgFailedToStartVoiceInput => 'Error al iniciar entrada de voz';

  @override
  String msgFilePathNotFound(String path) {
    return 'Archivo no encontrado: $path';
  }

  @override
  String get msgFilteredLogsCopied =>
      'Registros filtrados copiados al portapapeles';

  @override
  String get msgInfoAgent => 'Agente';

  @override
  String get msgInfoCompaction => 'Compactación';

  @override
  String msgInfoCost(String cost) {
    return 'Costo: \$$cost';
  }

  @override
  String get msgInfoMessageInfo => 'Información del Mensaje';

  @override
  String msgInfoModel(String modelId) {
    return 'Modelo: $modelId';
  }

  @override
  String get msgInfoNoMetadata => 'No hay metadatos disponibles';

  @override
  String msgInfoPartDescriptionModel(String description, String model) {
    return '$description$model';
  }

  @override
  String get msgInfoPatch => 'Parche';

  @override
  String msgInfoProvider(String providerId) {
    return 'Proveedor: $providerId';
  }

  @override
  String get msgInfoRetry => 'Intento';

  @override
  String get msgInfoSnapshot => 'Instantánea';

  @override
  String msgInfoSubtaskPartAgent(String agent) {
    return 'Subtarea ($agent)';
  }

  @override
  String msgInfoTokens(String total) {
    return 'Tokens: $total';
  }

  @override
  String get msgInfoUndoThisTurn => 'Deshacer este turno';

  @override
  String get msgInfoView => 'Ver';

  @override
  String get msgNoSystemSoundsFound =>
      'No se encontró ningún sonido del sistema en este dispositivo.';

  @override
  String get msgNoValidFilesSelected => 'No se seleccionaron archivos válidos';

  @override
  String get msgReadAloud => 'Read aloud';

  @override
  String get msgReadAloudNotAvailable =>
      'Text-to-speech is not available on this device.';

  @override
  String get msgSetupDebugCopied =>
      'Debug de configuración de OpenCode copiado';

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
      'El selector de sonido del sistema no está disponible en esta plataforma.';

  @override
  String get msgUpdatedButRefreshFailed =>
      'Configuración del servidor actualizada, pero no se pudieron actualizar los proveedores de chat.';

  @override
  String get msgVoiceInputUnavailable =>
      'Entrada de voz no disponible en este dispositivo';

  @override
  String get notifAndroidBatteryOptimization => 'Android battery optimization';

  @override
  String get notifConversationUpdates => 'Actualizaciones de conversación';

  @override
  String get notifNotificationsArriveReopening =>
      'If notifications only arrive when reopening the app, allow CodeWalk to run without optimization on this device.';

  @override
  String get notifResponseRunningKeep =>
      'When a response is running, keep realtime active briefly after you leave the app.';

  @override
  String notifSelectedSoundLabel(String soundLabel) {
    return 'Seleccionado: $soundLabel';
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
    return '$length líneas de registro de configuración y $length2 eventos de configuración están disponibles en la pantalla de depuración de configuración separada.';
  }

  @override
  String get onboardingAuthenticate => 'Authenticate';

  @override
  String get onboardingChooseAnotherPath => 'Choose another path';

  @override
  String get onboardingClear => 'Limpiar';

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
  String get onboardingLabel => 'Etiqueta (opcional)';

  @override
  String get onboardingLabelHint => 'Mi servidor';

  @override
  String onboardingLatestOutputAppProvider(String localServerLastOutput) {
    return 'Última salida: $localServerLastOutput';
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
  String get onboardingPassword => 'Contraseña';

  @override
  String get onboardingPasswordRequired => 'Enter password';

  @override
  String get onboardingRecommendedOrderTry =>
      'Recommended order: try Install Bun + OpenCode if you want CodeWalk to bootstrap everything for you. Use Existing if OpenCode is already installed.';

  @override
  String get onboardingRefreshChecks => 'Refresh Checks';

  @override
  String get onboardingRunDiagnosticsToVerify =>
      'Ejecute diagnósticos para verificar los requisitos locales de OpenCode.';

  @override
  String get onboardingServerUrl => 'URL del servidor';

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
  String get onboardingUsername => 'Usuario';

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
  String get permissionAllowOnce => 'Permitir Una Vez';

  @override
  String get permissionAlways => 'Siempre';

  @override
  String get permissionBack => 'Volver';

  @override
  String get permissionConfirmReject => 'Confirmar Rechazo';

  @override
  String get permissionReject => 'Rechazar';

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
  String get quotaAuthCookie => 'Cookie de autenticación';

  @override
  String get quotaForget => 'Olvidar';

  @override
  String get quotaOpenCodeGoUsage => 'Uso de OpenCode Go';

  @override
  String get quotaOpenDashboard => 'Abrir panel de OpenCode';

  @override
  String get quotaSaving => 'Guardando...';

  @override
  String get quotaWorkspaceId => 'ID del Espacio de Trabajo';

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
    return '¿Eliminar \"$displayName\"?';
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
  String get sessionActionArchived => 'archivada';

  @override
  String get sessionActionDeleted => 'eliminada';

  @override
  String get sessionActionForked => 'bifurcada';

  @override
  String get sessionActionUnarchived => 'desarchivada';

  @override
  String get sessionCancelRename => 'Cancelar renombrado';

  @override
  String get sessionCopyLink => 'Copiar Enlace';

  @override
  String get sessionDelete => 'Eliminar';

  @override
  String get sessionDeleteTitle => 'Eliminar Conversación';

  @override
  String get sessionDiffChangedFile => 'Changed file';

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
  String get sessionFailedRename => 'Error al renombrar conversación';

  @override
  String get sessionFailedUpdateArchive =>
      'Error al actualizar estado de archivado';

  @override
  String get sessionFailedUpdateSharing =>
      'Error al actualizar estado de compartir';

  @override
  String get sessionFork => 'Bifurcar';

  @override
  String get sessionKeyboardShortcuts => 'Atajos de teclado';

  @override
  String get sessionNotAvailable =>
      'La conversación aún no está disponible para este proyecto';

  @override
  String get sessionRename => 'Renombrar';

  @override
  String get sessionRenameHint => 'Ingrese el nuevo nombre de la conversación';

  @override
  String get sessionRenameTitle => 'Renombrar Conversación';

  @override
  String get sessionSaveTitle => 'Guardar título';

  @override
  String get sessionShareLinkCopied => 'Enlace de compartir copiado';

  @override
  String get sessionTitleHint => 'Título de la conversación';

  @override
  String get settingsAboutCheckForUpdates => 'Buscar actualizaciones';

  @override
  String get settingsAboutCheckOnOpen => 'Buscar actualizaciones al abrir';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Comprobar automáticamente cuando inicia la app';

  @override
  String get settingsAboutChecking => 'Comprobando...';

  @override
  String get settingsAboutDescription => 'Versión, actualizaciones y enlaces';

  @override
  String get settingsAboutDismiss => 'Descartar';

  @override
  String settingsAboutDownloading(String percent) {
    return 'Descargando... $percent%';
  }

  @override
  String get settingsAboutEraseAllData => 'Borrar todos los datos y reiniciar';

  @override
  String get settingsAboutInstallUpdate => 'Instalar actualización';

  @override
  String get settingsAboutInstalling => 'Instalando...';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version es la versión más reciente';
  }

  @override
  String get settingsAboutLoading => 'Cargando...';

  @override
  String get settingsAboutReplayChatTour => 'Repetir recorrido del chat';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Cerrar ajustes y mostrar la guía del chat';

  @override
  String get settingsAboutResetApp => 'Restablecer app';

  @override
  String get settingsAboutResetAppQuestion => '¿Restablecer app?';

  @override
  String get settingsAboutResetAppWarning =>
      'Esto borrará todos los servidores, ajustes y datos en caché. Esta acción no se puede deshacer.';

  @override
  String get settingsAboutRetryInstall => 'Reintentar instalación';

  @override
  String get settingsAboutTapToCheck => 'Toca para buscar nuevas versiones';

  @override
  String get settingsAboutTitle => 'Acerca de';

  @override
  String get settingsAboutUpToDate => 'Estás al día';

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Actualización disponible: v$version';
  }

  @override
  String get settingsAboutUpdateInstalled =>
      'Actualización instalada. Reinicie la app para aplicarla.';

  @override
  String get settingsAboutVersion => 'Versión';

  @override
  String settingsAboutVersionBuild(String buildNumber, String version) {
    return '$version (compilación $buildNumber)';
  }

  @override
  String get settingsAppearanceAmoledDark => 'Modo oscuro AMOLED';

  @override
  String get settingsAppearanceAmoledDarkActive =>
      'Usar superficies negras puras mientras el modo oscuro esté activo.';

  @override
  String get settingsAppearanceAmoledDarkInactive =>
      'Cambie al modo oscuro para habilitar superficies AMOLED.';

  @override
  String get settingsAppearanceBrandColor => 'Color de marca';

  @override
  String get settingsAppearanceBrandColorDynamicBlocked =>
      'Desactive los colores del fondo de pantalla para elegir un color de marca.';

  @override
  String get settingsAppearanceBrandColorNormal =>
      'Elija un color semilla para la paleta de la app.';

  @override
  String get settingsAppearanceBrandColorPresetBlocked =>
      'Cambie a CodeWalk Clásico para elegir un color de marca.';

  @override
  String get settingsAppearanceCodeWalkClassic => 'CodeWalk Clásico';

  @override
  String get settingsAppearanceComposerTips => 'Consejos del compositor';

  @override
  String get settingsAppearanceComposerTipsDescription =>
      'Mostrar u ocultar consejos rotativos mientras el asistente razona.';

  @override
  String get settingsAppearanceContrast => 'Contraste';

  @override
  String get settingsAppearanceContrastDynamicBlocked =>
      'Desactive los colores del fondo de pantalla para ajustar el contraste.';

  @override
  String get settingsAppearanceContrastHigh => 'Alto';

  @override
  String get settingsAppearanceContrastNormal =>
      'Ajuste el nivel de contraste del esquema de color.';

  @override
  String get settingsAppearanceContrastPresetBlocked =>
      'Cambie a CodeWalk Clásico para ajustar el contraste.';

  @override
  String get settingsAppearanceContrastReduced => 'Reducido';

  @override
  String get settingsAppearanceDark => 'Oscuro';

  @override
  String get settingsAppearanceDensity => 'Densidad';

  @override
  String get settingsAppearanceDensityDense => 'Densa';

  @override
  String get settingsAppearanceDensityDescription =>
      'Aplica espaciado y densidad de componentes en toda la app.';

  @override
  String get settingsAppearanceDensityExtraDense => 'Extra Densa';

  @override
  String get settingsAppearanceDensityExtraSpacious => 'Extra Espaciosa';

  @override
  String get settingsAppearanceDensityNormal => 'Normal';

  @override
  String get settingsAppearanceDensitySpacious => 'Espaciosa';

  @override
  String get settingsAppearanceDescription =>
      'Densidad y visibilidad de burbujas de la línea de tiempo';

  @override
  String get settingsAppearanceLight => 'Claro';

  @override
  String get settingsAppearanceMathRendering => 'Renderizado de matemáticas';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      'Renderizar expresiones matemáticas LaTeX como ecuaciones tipografiadas en mensajes de chat.';

  @override
  String get settingsAppearanceNoPresets => 'No se encontraron paletas';

  @override
  String get settingsAppearanceOpenCodePresets => 'Presets OpenCode';

  @override
  String get settingsAppearancePresetHelper =>
      'Refleja la lista oficial de temas integrados de OpenCode Web.';

  @override
  String get settingsAppearancePresetNote =>
      'Los colores del tema ahora siguen el registro oficial de OpenCode Web.';

  @override
  String get settingsAppearancePresetPalette => 'Paleta predefinida';

  @override
  String get settingsAppearanceSearchPreset => 'Buscar paleta predefinida';

  @override
  String get settingsAppearanceSectionDescription =>
      'Ajuste la densidad visual y las superficies de mensaje para su flujo de trabajo.';

  @override
  String get settingsAppearanceSectionTitle => 'Apariencia';

  @override
  String get settingsAppearanceSystem => 'Sistema';

  @override
  String get settingsAppearanceTaskList => 'Lista de tareas';

  @override
  String get settingsAppearanceTaskListDescription =>
      'Mostrar u ocultar el widget de lista de tareas de la sesión.';

  @override
  String get settingsAppearanceTheme => 'Tema';

  @override
  String get settingsAppearanceThemeDescription =>
      'Elija entre modo claro, oscuro o sistema.';

  @override
  String get settingsAppearanceThinkingBubbles => 'Burbujas de pensamiento';

  @override
  String get settingsAppearanceThinkingBubblesDescription =>
      'Mostrar u ocultar bloques de razonamiento en los mensajes del asistente.';

  @override
  String get settingsAppearanceTitle => 'Apariencia';

  @override
  String get settingsAppearanceToolCallBubbles =>
      'Burbujas de llamada de herramienta';

  @override
  String get settingsAppearanceToolCallBubblesDescription =>
      'Mostrar u ocultar tarjetas de ejecución de herramientas.';

  @override
  String get settingsAppearanceWallpaperColors =>
      'Usar colores del fondo de pantalla';

  @override
  String get settingsAppearanceWallpaperNormal =>
      'Extraer esquema de color del fondo de pantalla del dispositivo.';

  @override
  String get settingsAppearanceWallpaperPresetBlocked =>
      'Cambie a CodeWalk Clásico para usar colores del fondo de pantalla.';

  @override
  String get settingsBack => 'Volver';

  @override
  String get settingsBehaviorAutoupdateCaveat =>
      'Use Acerca de para las verificaciones de versión de CodeWalk. Esta configuración solo refleja la config `autoupdate` oficial de OpenCode.';

  @override
  String get settingsBehaviorAutoupdateHelp =>
      'Controla las actualizaciones de runtime de OpenCode, no las verificaciones de actualización de CodeWalk.';

  @override
  String get settingsBehaviorCellularDataSaver => 'Ahorro de datos móviles';

  @override
  String get settingsBehaviorConfigDeferred =>
      'CodeWalk aplicará esta configuración de OpenCode después de que termine la respuesta actual.';

  @override
  String settingsBehaviorConfigUpdateFailed(String field) {
    return 'No se pudo actualizar $field de OpenCode.';
  }

  @override
  String get settingsBehaviorConversationUsername =>
      'Nombre de usuario de conversación';

  @override
  String get settingsBehaviorConversationUsernameHelp =>
      'Nombre de visualización personalizado mostrado en las conversaciones en lugar del nombre del sistema.';

  @override
  String get settingsBehaviorDataSaverActive =>
      'Activo ahora en datos móviles.';

  @override
  String get settingsBehaviorDataSaverCellularOnly =>
      'Solo se aplica cuando la conexión es celular/móvil.';

  @override
  String get settingsBehaviorDataSaverDescription =>
      'Reduce el uso automático de datos móviles deteniendo descargas en segundo plano.';

  @override
  String get settingsBehaviorDataSaverWaiting =>
      'Esperando la próxima ventana de sincronización de datos móviles.';

  @override
  String get settingsBehaviorDefaultAgent => 'Agente predeterminado';

  @override
  String get settingsBehaviorDefaultAgentHelp =>
      'Agente principal usado cuando no se elige ningún agente explícitamente.';

  @override
  String get settingsBehaviorDefaultModel => 'Modelo predeterminado';

  @override
  String get settingsBehaviorDefaultModelHelp =>
      'Compartido entre clientes OpenCode a través de config.';

  @override
  String get settingsBehaviorDescription =>
      'Valores predeterminados de OpenCode, procedencia y seguridad de sincronización del compositor';

  @override
  String get settingsBehaviorEnableDataSaver =>
      'Habilitar ahorro de datos móviles';

  @override
  String get settingsBehaviorMultiDeviceSync =>
      'Habilitar sincronización multidispositivo experimental';

  @override
  String get settingsBehaviorMultiDeviceSyncDescription =>
      'Sincroniza la selección del compositor (agente/modelo/variante) con la configuración del servidor activo.';

  @override
  String get settingsBehaviorMultiDeviceSyncWarning =>
      'Puede abortar sesiones en curso al trabajar en más de una sesión al mismo tiempo.';

  @override
  String get settingsBehaviorNoAgents => 'No se encontraron agentes';

  @override
  String get settingsBehaviorNoModels => 'No se encontraron modelos';

  @override
  String get settingsBehaviorOpenCodeAutoupdate =>
      'Actualización automática de OpenCode';

  @override
  String get settingsBehaviorOpenCodeDefaults =>
      'Valores predeterminados de OpenCode';

  @override
  String get settingsBehaviorOpenCodeDefaultsDescription =>
      'Estos valores escriben en `/config` en el servidor activo y coinciden con la configuración oficial de OpenCode.';

  @override
  String get settingsBehaviorOpenCodeSnapshots => 'Instantáneas de OpenCode';

  @override
  String get settingsBehaviorOpenCodeSnapshotsDescription =>
      'Mantener instantáneas git habilitadas para historial de deshacer/rehacer y recuperación.';

  @override
  String get settingsBehaviorPermissionDeferred =>
      'La edición avanzada de reglas de permisos queda fuera de Configuración por ahora.';

  @override
  String get settingsBehaviorPermissionProvenance =>
      'Procedencia del manejo de permisos';

  @override
  String get settingsBehaviorPermissionProvenanceDescription =>
      'La política oficial de permisos de OpenCode se configura en `opencode.json` con reglas allow/ask/deny por herramienta. CodeWalk mantiene las tarjetas oficiales de solicitud de permiso y agrega una excepción ADR-023 aprobada: el toggle de auto-aprobación del composer responde con `Always` y `remember: true` incondicionalmente para crear concesiones duraderas con alcance de sesión.';

  @override
  String get settingsBehaviorRefreshDefaults => 'Actualizar valores';

  @override
  String get settingsBehaviorSaveUsername => 'Guardar nombre de usuario';

  @override
  String get settingsBehaviorSearchAutoupdate => 'Buscar modo de actualización';

  @override
  String get settingsBehaviorSearchDefaultAgent =>
      'Buscar agente predeterminado';

  @override
  String get settingsBehaviorSearchDefaultModel =>
      'Buscar modelo predeterminado';

  @override
  String get settingsBehaviorSearchShareMode => 'Buscar modo de compartir';

  @override
  String get settingsBehaviorSearchSmallModel => 'Buscar modelo pequeño';

  @override
  String get settingsBehaviorShareMode =>
      'Modo de compartir predeterminado de OpenCode';

  @override
  String get settingsBehaviorShareModeCaveat =>
      'Use la acción de compartir en el chat para publicar una sesión ahora. Esta configuración solo cambia la política de compartir predeterminada de OpenCode.';

  @override
  String get settingsBehaviorShareModeHelp =>
      'Controla la config global oficial `share`, no el botón de compartir de un chat individual.';

  @override
  String get settingsBehaviorSmallModel => 'Modelo pequeño';

  @override
  String get settingsBehaviorSmallModelAutoFallback => 'Respaldo automático';

  @override
  String get settingsBehaviorSmallModelFallbackActive =>
      'El respaldo automático de OpenCode está activo porque `small_model` no está configurado.';

  @override
  String get settingsBehaviorSmallModelHelp =>
      'Usado para tareas ligeras como generación de títulos.';

  @override
  String get settingsBehaviorSmallModelResetCaveat =>
      'Restablecer `small_model` al respaldo automático aún requiere editar la configuración fuera de la app.';

  @override
  String get settingsBehaviorSnapshotCaveat =>
      'Esto controla el almacenamiento de instantáneas de OpenCode, no las instantáneas de caché local de CodeWalk.';

  @override
  String get settingsBehaviorTitle => 'Comportamiento';

  @override
  String get settingsBehaviorUsernameFallback =>
      'OpenCode usa el nombre de usuario del sistema porque `username` no está configurado.';

  @override
  String get settingsBehaviorUsernamePatchCaveat =>
      'Restablecer `username` al valor predeterminado del sistema aún requiere editar la configuración fuera de la app.';

  @override
  String get settingsLanguageDescription =>
      'Elige el idioma que usa CodeWalk. El valor predeterminado del sistema sigue el idioma del dispositivo.';

  @override
  String get settingsLanguageEmptyText => 'No se encontraron idiomas';

  @override
  String get settingsLanguageFieldHelper =>
      'Se aplica de inmediato y se mantiene tras reiniciar.';

  @override
  String get settingsLanguageFieldLabel => 'Idioma de la app';

  @override
  String get settingsLanguageSearchHint => 'Buscar idiomas';

  @override
  String get settingsLanguageSystemDefault => 'Predeterminado del sistema';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLogsDescription =>
      'Diagnóstico en tiempo de ejecución y solución de problemas';

  @override
  String get settingsLogsTitle => 'Registros';

  @override
  String get settingsNotificationsAgentSubtitle =>
      'Cuando una respuesta termina';

  @override
  String get settingsNotificationsAgentUpdates => 'Actualizaciones del agente';

  @override
  String get settingsNotificationsAnotherConversation => 'Otra conversación';

  @override
  String get settingsNotificationsAppInBackground => 'App en segundo plano';

  @override
  String get settingsNotificationsBackgroundAlerts =>
      'Alertas en segundo plano de Android';

  @override
  String get settingsNotificationsBackgroundBehavior =>
      'Comportamiento en segundo plano';

  @override
  String get settingsNotificationsBackgroundBehaviorDescription =>
      'Elija cómo se comporta CodeWalk después de que la app sale del primer plano.';

  @override
  String get settingsNotificationsBackgroundDescription =>
      'Usa monitoreo de bajo consumo de datos en segundo plano.';

  @override
  String get settingsNotificationsBackgroundToggle =>
      'Alertas en segundo plano en Android';

  @override
  String get settingsNotificationsBackgroundToggleDescription =>
      'Desactiva todas las verificaciones en segundo plano de Android.';

  @override
  String get settingsNotificationsBatteryDescription =>
      'Si las notificaciones solo llegan al reabrir la app, permita que CodeWalk se ejecute sin optimización.';

  @override
  String get settingsNotificationsBatteryDisabled =>
      'La optimización de batería está desactivada para CodeWalk.';

  @override
  String get settingsNotificationsBatteryEnabled =>
      'La optimización de batería está activada. Algunos dispositivos pueden retrasar las alertas.';

  @override
  String get settingsNotificationsBatteryOptimization =>
      'Optimización de batería de Android';

  @override
  String get settingsNotificationsBatteryUnknown =>
      'Aún no se pudo leer el estado de optimización de batería.';

  @override
  String get settingsNotificationsChooseAudioFile => 'Elegir archivo de audio';

  @override
  String get settingsNotificationsChooseSystemSound =>
      'Elegir sonido del sistema';

  @override
  String get settingsNotificationsCloseToTray => 'Cerrar a la bandeja';

  @override
  String get settingsNotificationsCloseToTrayDescription =>
      'Ocultar ventana y seguir ejecutándose en la bandeja del sistema.';

  @override
  String get settingsNotificationsDescription =>
      'Controles de notificación y sonido por categoría';

  @override
  String get settingsNotificationsDisableOptimization =>
      'Desactivar optimización';

  @override
  String get settingsNotificationsErrors => 'Errores';

  @override
  String get settingsNotificationsErrorsSubtitle =>
      'Cuando una sesión informa un fallo';

  @override
  String get settingsNotificationsJustClose => 'Solo cerrar';

  @override
  String get settingsNotificationsJustCloseDescription =>
      'Salir completamente de la aplicación.';

  @override
  String get settingsNotificationsKeepLive =>
      'Mantener alertas activas por 3 min';

  @override
  String get settingsNotificationsKeepLiveDescription =>
      'Cuando una respuesta ya está en ejecución, mantiene el tiempo real activo brevemente después de salir de la app.';

  @override
  String get settingsNotificationsLocal => 'Local';

  @override
  String get settingsNotificationsMinimizeWhenClose => 'Minimizar al cerrar';

  @override
  String get settingsNotificationsMinimizeWhenCloseDescription =>
      'Minimizar a la barra de tareas/dock y seguir ejecutándose.';

  @override
  String get settingsNotificationsNoCondition =>
      'Si no se selecciona ninguna condición, las alertas se permiten en cualquier contexto.';

  @override
  String get settingsNotificationsNotify => 'Notificar';

  @override
  String get settingsNotificationsNotifyOnlyWhen => 'Notificar solo cuando';

  @override
  String get settingsNotificationsOpenBatterySettings =>
      'Abrir configuración de batería';

  @override
  String get settingsNotificationsPermissions => 'Permisos y preguntas';

  @override
  String get settingsNotificationsPermissionsSubtitle =>
      'Cuando las herramientas solicitan su entrada';

  @override
  String get settingsNotificationsPreview => 'Previsualizar';

  @override
  String get settingsNotificationsRefreshStatus => 'Actualizar estado';

  @override
  String get settingsNotificationsSearchSoundType => 'Buscar tipo de sonido';

  @override
  String get settingsNotificationsSectionDescription =>
      'Controle cuándo aparecen las alertas y cuándo pueden reproducir sonido.';

  @override
  String get settingsNotificationsSectionTitle => 'Notificaciones';

  @override
  String settingsNotificationsSelectedSound(String label) {
    return 'Seleccionado: $label';
  }

  @override
  String get settingsNotificationsServer => 'Servidor';

  @override
  String get settingsNotificationsSound => 'Sonido';

  @override
  String get settingsNotificationsSoundOnlyWhen => 'Sonido solo cuando';

  @override
  String get settingsNotificationsSoundType => 'Tipo de sonido';

  @override
  String get settingsNotificationsSyncInfo =>
      'Algunos interruptores se sincronizan desde /config en el servidor activo.';

  @override
  String get settingsNotificationsSyncInfoLocal =>
      'El servidor actual no expone interruptores de notificación en /config.';

  @override
  String get settingsNotificationsSystemSoundPickerTitle =>
      'Elegir sonido del sistema';

  @override
  String get settingsNotificationsTitle => 'Notificaciones';

  @override
  String get settingsNotificationsWhenClosing => 'Al cerrar la ventana';

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
  String get settingsServersActive => 'Activo';

  @override
  String get settingsServersChooseActive => 'Elegir servidor activo';

  @override
  String get settingsServersDefault => 'Predeterminado';

  @override
  String get settingsServersDescription =>
      'Servidores OpenCode y enrutamiento de salud';

  @override
  String get settingsServersTitle => 'Servidores';

  @override
  String get settingsSetupWizard => 'Asistente de configuración';

  @override
  String get settingsShortcutsDescription =>
      'Combinaciones de teclas portátiles de la app';

  @override
  String get settingsShortcutsEdit => 'Editar atajo';

  @override
  String get settingsShortcutsKeyboard => 'Atajos de teclado';

  @override
  String get settingsShortcutsReset => 'Restablecer atajo';

  @override
  String get settingsShortcutsSearch => 'Buscar atajos';

  @override
  String get settingsShortcutsTitle => 'Atajos';

  @override
  String get settingsSpeechDescription =>
      'Motor, tiempo de silencio y opciones de modelo';

  @override
  String get settingsSpeechRefreshStatus => 'Actualizar estado';

  @override
  String settingsSpeechSilenceTimeout(String value) {
    return 'Tiempo de silencio: ${value}s';
  }

  @override
  String get settingsSpeechTitle => 'Voz a texto';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get setupDebugBun => 'Bun';

  @override
  String get setupDebugBun2 => 'Bun';

  @override
  String get setupDebugCapturedSetupDetails => 'No captured setup details yet';

  @override
  String get setupDebugCapturedSetupLogs => 'Captured setup logs';

  @override
  String get setupDebugClear => 'Limpiar debug de configuración';

  @override
  String get setupDebugClearSetupDebug => 'Clear setup debug';

  @override
  String get setupDebugCodeWalkCaptureEnough =>
      'If CodeWalk did not capture enough context, check the official OpenCode logs and health endpoints directly:';

  @override
  String get setupDebugCommandPath => 'Ruta del comando';

  @override
  String get setupDebugCommandPath2 => 'Command path';

  @override
  String get setupDebugCopy => 'Copiar debug de configuración';

  @override
  String get setupDebugCopySetupDebug => 'Copy setup debug';

  @override
  String get setupDebugCurrentStatus => 'Current status';

  @override
  String get setupDebugDiagnosticsLoading => 'Diagnostics are still loading.';

  @override
  String get setupDebugEnvironment => 'Diagnóstico del entorno';

  @override
  String get setupDebugEnvironmentDiagnostics => 'Environment diagnostics';

  @override
  String get setupDebugFocusedOpenCodeSetup => 'Focused on OpenCode setup';

  @override
  String get setupDebugInstallDir => 'Directorio de instalación';

  @override
  String get setupDebugInstallDirectory => 'Install directory';

  @override
  String get setupDebugLatestLocalServer => 'Latest local server output';

  @override
  String get setupDebugLogs => 'Registros de configuración capturados';

  @override
  String get setupDebugManual => 'Solución de problemas manual';

  @override
  String get setupDebugManualTroubleshooting => 'Manual troubleshooting';

  @override
  String get setupDebugNetwork => 'Red';

  @override
  String get setupDebugNetwork2 => 'Network';

  @override
  String get setupDebugNoDetails =>
      'Aún no hay detalles de configuración capturados';

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
  String get setupDebugServerOutput => 'Última salida del servidor local';

  @override
  String get setupDebugStatus => 'Estado actual';

  @override
  String setupDebugTimeEntrySource(String time, String source) {
    return '$time - $source';
  }

  @override
  String get setupDebugTimeline => 'Línea de tiempo';

  @override
  String get setupDebugTimeline2 => 'Timeline';

  @override
  String get setupDebugTitle => 'Enfocado en la configuración de OpenCode';

  @override
  String get setupDebugWSL => 'WSL';

  @override
  String get setupDebugWsl => 'WSL';

  @override
  String get shortcutsApply => 'Apply';

  @override
  String shortcutsConflictConflict(String conflict) {
    return 'Conflicto con $conflict';
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
    return 'Establecer atajo: $label';
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
  String get terminalClose => 'Cerrar terminal';

  @override
  String get terminalMinimize => 'Minimizar terminal';

  @override
  String get terminalReconnect => 'Reconectar terminal';

  @override
  String get terminalTerminal => 'Terminal';

  @override
  String get terminalTryAgain => 'Intentar de nuevo';

  @override
  String get toolAwaitingInput => 'Esperando entrada';

  @override
  String get toolEditing => 'Editando';

  @override
  String get toolEditingFiles => 'Editando archivos';

  @override
  String get toolFinding => 'Buscando';

  @override
  String get toolFindingFiles => 'Buscando archivos';

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
  String get toolReading => 'Leyendo';

  @override
  String get toolReadingFile => 'Leyendo archivo';

  @override
  String get toolRunning => 'Ejecutando';

  @override
  String get toolRunningCommand => 'Ejecutando comando';

  @override
  String get toolRunningTask => 'Ejecutando tarea';

  @override
  String get toolSearching => 'Buscando';

  @override
  String get toolSearchingCode => 'Buscando código';

  @override
  String get toolSearchingWeb => 'Buscando en la web';

  @override
  String get toolUpdatingTaskList => 'Actualizando lista de tareas';

  @override
  String get toolUpdatingTasks => 'Actualizando tareas';

  @override
  String get toolWaitingForInput => 'Esperando su entrada';

  @override
  String get toolWriting => 'Escribiendo';

  @override
  String get toolWritingFile => 'Escribiendo archivo';

  @override
  String get tourBack => 'Volver';

  @override
  String get tourSkip => 'Saltar';

  @override
  String get trayQuit => 'Salir';

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
  String get workspaceBrowseDirs => 'Explorar directorios';

  @override
  String get workspaceChooseFolderOpen =>
      'Choose any folder to open as project context.';

  @override
  String workspaceCloseProject(String project) {
    return 'Cerrar $project';
  }

  @override
  String get workspaceFilterDirs => 'Filtrar directorios';

  @override
  String get workspaceOpenFolder => 'Open folder';

  @override
  String get workspaceOpenProjectFolder => 'Open project folder';

  @override
  String get workspaceProjectDirectory => 'Directorio del proyecto';

  @override
  String get workspaceProjectHint => '/repo/mi-proyecto';

  @override
  String workspaceRemoveFromHistory(String name) {
    return 'Eliminar $name del historial';
  }

  @override
  String get workspaceSuggestions => 'Suggestions';

  @override
  String get onboardingSetup => 'Configuración';

  @override
  String get onboardingSetupWizard => 'Asistente de configuración';

  @override
  String get onboardingServerSetup => 'Configuración del servidor';

  @override
  String get onboardingEditServer => 'Editar servidor';

  @override
  String get onboardingLocalServerSetup => 'Configuración del servidor local';

  @override
  String get onboardingReady => 'Listo';

  @override
  String onboardingWelcomeTo(String appName) {
    return 'Bienvenido a $appName';
  }

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName necesita un servidor OpenCode antes de poder ayudarle con su código.';
  }

  @override
  String get onboardingChooseHowToSetup => 'Elija cómo configurar su servidor';

  @override
  String get onboardingPickSetupPath =>
      'Elija la ruta de configuración que coincida con su configuración actual de OpenCode.';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'Solo escritorio: $appName puede diagnosticar, instalar y ejecutar OpenCode por usted.';
  }

  @override
  String get onboardingAvailableOnlyDesktop =>
      'Disponible solo en escritorio (Linux/macOS/Windows).';

  @override
  String get onboardingServerConnection => 'Conexión del servidor';

  @override
  String get onboardingEditServerConnection => 'Editar conexión del servidor';

  @override
  String onboardingSuggestedUrl(String url) {
    return 'URL sugerida del servidor OpenCode local: $url';
  }

  @override
  String get onboardingEmulatorRemap =>
      'En el emulador de Android, localhost y 127.0.0.1 se reasignan a 10.0.2.2 automáticamente.';

  @override
  String get onboardingBasicAuthTip =>
      'Habilite la autenticación básica solo si su servidor OpenCode está protegido por contraseña.';

  @override
  String get onboardingEnterServerUrl => 'Ingrese la URL del servidor';

  @override
  String get onboardingInvalidUrl => 'URL inválida';

  @override
  String get onboardingTesting => 'Probando...';

  @override
  String get onboardingSaveAndTest => 'Guardar y probar';

  @override
  String get onboardingTestConnection => 'Probar conexión';

  @override
  String get onboardingTailscaleLoginRequired =>
      'Se requiere inicio de sesión en Tailscale';

  @override
  String get onboardingTailscaleAdminApproval =>
      'Se requiere aprobación del administrador de Tailscale';

  @override
  String get onboardingTailscaleConnected => 'Tailscale conectado';

  @override
  String get onboardingTailscaleConnecting => 'Tailscale conectando';

  @override
  String get onboardingTailscaleConnectionFailed =>
      'Conexión de Tailscale fallida';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale no compatible';

  @override
  String get onboardingTailscaleAuthAfterSave =>
      'Tailscale se autenticará después de guardar';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'Abra la URL de inicio de sesión para añadir este dispositivo a su tailnet. Si el navegador no se abrió, copie la URL a continuación.';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'Después de guardar y probar este servidor, $appName abrirá el inicio de sesión de Tailscale si este dispositivo aún no está autenticado.';
  }

  @override
  String get onboardingStarting => 'Iniciando';

  @override
  String get onboardingStopping => 'Deteniendo';

  @override
  String get onboardingFailed => 'Falló';

  @override
  String get onboardingStopped => 'Detenido';

  @override
  String get onboardingUsingDetectedCommand =>
      'Usando el comando OpenCode detectado.';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingDone => 'Hecho';

  @override
  String get onboardingYoureAllSet => '¡Todo listo!';

  @override
  String get onboardingServerUpdated => 'Servidor actualizado';

  @override
  String get onboardingServerConnectedReady =>
      'Su servidor está conectado y listo para usar.';

  @override
  String get onboardingServerSettingsSaved =>
      'Se guardaron los ajustes del servidor y se actualizaron las comprobaciones de salud.';

  @override
  String onboardingStartUsing(String appName) {
    return 'Empezar a usar $appName';
  }

  @override
  String get onboardingCouldNotVerify =>
      'No se pudo verificar la conexión al servidor.';

  @override
  String get onboardingCloudflareAuthFailed =>
      'La autenticación de Cloudflare Access falló.';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'La comprobación de salud del servidor falló. Puede que aún se esté iniciando.';

  @override
  String get onboardingConnectionUpdated =>
      'Conexión al servidor actualizada con éxito.';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'Servidor añadido pero la comprobación de salud falló. Puede que aún se esté iniciando.';

  @override
  String get onboardingConnectionSaved =>
      'Conexión al servidor guardada con éxito.';

  @override
  String get onboardingAvailable => 'disponible';

  @override
  String get onboardingNotAvailable => 'no disponible';

  @override
  String get onboardingReachable => 'alcanzable';

  @override
  String get onboardingUnreachable => 'inalcanzable';

  @override
  String get onboardingWritable => 'escribible';

  @override
  String get onboardingNotWritable => 'no escribible';

  @override
  String toolPresentationRunningTool(String toolName) {
    return 'Ejecutando $toolName';
  }

  @override
  String get toolPresentationTool => 'Herramienta';

  @override
  String get shortcutGroupSession => 'Sesión';

  @override
  String get shortcutGroupGeneral => 'General';

  @override
  String get shortcutGroupPrompt => 'Prompter';

  @override
  String get shortcutGroupNavigation => 'Navegación';

  @override
  String get shortcutGroupModelAndAgent => 'Modelo y agente';

  @override
  String get shortcutGroupApplication => 'Aplicación';

  @override
  String get shortcutNewConversation => 'Nueva conversación';

  @override
  String get shortcutNewConversationDesc => 'Crear una nueva sesión de chat';

  @override
  String get shortcutRefreshData => 'Refrescar datos';

  @override
  String get shortcutRefreshDataDesc => 'Refrescar los datos del chat actual';

  @override
  String get shortcutFocusInput => 'Enfocar entrada';

  @override
  String get shortcutFocusInputDesc => 'Mover el foco a la entrada de texto';

  @override
  String get shortcutToggleVoiceInput => 'Alternar entrada de voz';

  @override
  String get shortcutToggleVoiceInputDesc =>
      'Iniciar o detener dictado de voz en el editor';

  @override
  String get shortcutQuickOpenFiles => 'Apertura rápida de archivos';

  @override
  String get shortcutQuickOpenFilesDesc => 'Abrir búsqueda rápida de archivos';

  @override
  String get shortcutOpenSettings => 'Abrir ajustes';

  @override
  String get shortcutOpenSettingsDesc => 'Abrir la página de ajustes';

  @override
  String get shortcutNextRecentModel => 'Siguiente modelo reciente';

  @override
  String get shortcutNextRecentModelDesc =>
      'Ciclar a través de los modelos usados recientemente';

  @override
  String get shortcutNextVariant => 'Siguiente variante';

  @override
  String get shortcutNextVariantDesc =>
      'Ciclar a través de las variantes de modelo disponibles';

  @override
  String get shortcutFocusCloseDrawer => 'Enfocar/cerrar panel';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'Enfocar entrada por defecto, o cerrar panel cuando está abierto';

  @override
  String get shortcutNextAgent => 'Siguiente agente';

  @override
  String get shortcutNextAgentDesc => 'Ciclar al siguiente agente disponible';

  @override
  String get shortcutPreviousAgent => 'Agente anterior';

  @override
  String get shortcutPreviousAgentDesc =>
      'Ciclar al agente anterior disponible';

  @override
  String get shortcutCloseApp => 'Cerrar aplicación';

  @override
  String get shortcutCloseAppDesc =>
      'Cerrar la aplicación usando el comportamiento de cierre de la plataforma';

  @override
  String get shortcutQuitApp => 'Salir de la aplicación';

  @override
  String get shortcutQuitAppDesc => 'Forzar la salida de la aplicación';

  @override
  String get shortcutStopResponse => 'Detener respuesta';

  @override
  String get shortcutStopResponseDesc =>
      'Detener respuesta activa (mientras responde)';

  @override
  String get errorConnectionFailed => 'Conexión fallida';

  @override
  String get errorConnectionFailedDesc =>
      'No se puede contactar con el servidor. Compruebe la conexión y el estado del servidor.';

  @override
  String get errorQuotaExceeded => 'Cuota excedida';

  @override
  String get errorQuotaExceededDesc =>
      'Cuota excedida. Compruebe su plan de proveedor o facturación.';

  @override
  String get errorRateLimitExceeded => 'Límite de velocidad excedido';

  @override
  String get errorRateLimitExceededDesc =>
      'Límite de velocidad excedido. Espere un momento e inténtelo de nuevo.';

  @override
  String get errorAuthRequired => 'Autenticación requerida';

  @override
  String get errorAuthRequiredDesc =>
      'La autenticación falló. Vuelva a conectar el proveedor e inténtelo de nuevo.';

  @override
  String get errorServiceUnavailable => 'Servicio no disponible';

  @override
  String get errorServiceUnavailableDesc =>
      'Servicio temporalmente no disponible. El servidor puede estar iniciándose; por favor, inténtelo de nuevo en breve.';

  @override
  String get errorProviderUnavailable => 'Proveedor no disponible';

  @override
  String get errorProviderUnavailableDesc =>
      'El proveedor no está disponible temporalmente. Inténtelo de nuevo en breve.';

  @override
  String get errorServerError => 'Error del servidor';

  @override
  String get errorServerErrorDesc =>
      'Error del servidor. Por favor, inténtelo de nuevo.';

  @override
  String get attachmentNotAvailableOnPlatform =>
      'Las acciones de archivos adjuntos no están disponibles en esta plataforma.';

  @override
  String get attachmentUnableToOpenLink =>
      'No se puede abrir el enlace del archivo adjunto.';

  @override
  String get attachmentNoValidLocation =>
      'El archivo adjunto no proporciona una ubicación válida.';

  @override
  String get attachmentDownloadStarted =>
      'Descarga del archivo adjunto iniciada.';

  @override
  String get attachmentCouldNotDownload =>
      'El archivo adjunto no pudo ser descargado.';

  @override
  String get attachmentCouldNotDecode =>
      'Los datos del archivo adjunto no pudieron ser decodificados.';

  @override
  String get attachmentPayloadEmpty =>
      'La carga útil del archivo adjunto está vacía.';

  @override
  String attachmentSavedAndOpened(String path) {
    return 'Archivo adjunto guardado en $path y abierto.';
  }

  @override
  String attachmentSavedTo(String path) {
    return 'Archivo adjunto guardado en $path.';
  }

  @override
  String get attachmentCouldNotSave =>
      'El archivo adjunto no pudo ser guardado en este dispositivo.';

  @override
  String get attachmentSaveCanceled => 'Guardado cancelado.';

  @override
  String attachmentSavedPath(String path) {
    return 'Archivo adjunto guardado en $path.';
  }

  @override
  String get attachmentPathEmpty => 'La ruta del archivo adjunto está vacía.';

  @override
  String get attachmentLocalNotFound =>
      'El archivo adjunto local no se encontró en este dispositivo.';

  @override
  String get attachmentUnableToOpenLocal =>
      'No se puede abrir el archivo adjunto local.';

  @override
  String speechDesktopOnly(String service) {
    return '$service está disponible solo en escritorio.';
  }

  @override
  String speechRuntimeFailed(String service) {
    return 'El entorno de ejecución de $service no pudo inicializarse.';
  }

  @override
  String speechModelFilesIncomplete(String service) {
    return 'Los archivos del modelo de $service están incompletos.';
  }

  @override
  String get speechMicPermissionDisabled =>
      'El permiso del micrófono está desactivado.';

  @override
  String speechUnavailableOnPlatform(String service) {
    return 'El habla de $service no está disponible en esta plataforma.';
  }

  @override
  String get terminalOpenToConnect =>
      'Abra el Terminal para conectarse al terminal del proyecto del servidor.';

  @override
  String get terminalNotAvailableYet =>
      'El terminal integrado aún no está disponible en este entorno de ejecución.';

  @override
  String get terminalSelectServer =>
      'Seleccione un servidor activo antes de abrir el Terminal.';

  @override
  String get terminalOpenProjectFirst =>
      'Abra una carpeta de proyecto antes de iniciar el terminal del servidor.';

  @override
  String terminalConnectingTo(String serverName) {
    return 'Conectando al terminal de $serverName...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'Conexión de terminal fallida: $error';
  }

  @override
  String get terminalDisconnected => 'Terminal desconectado.';

  @override
  String get terminalSessionClosed => 'Sesión de terminal cerrada.';

  @override
  String get notificationConversationUpdates =>
      'Actualizaciones de la conversación';

  @override
  String get notificationOpenToClear =>
      'Abra esta conversación para borrar las notificaciones relacionadas.';

  @override
  String get notificationAgentFinished =>
      'El agente terminó la respuesta actual.';

  @override
  String get notificationSession => 'Sesión';

  @override
  String get chatBadgeServerNeedsAttention =>
      'La conexión del servidor necesita atención.';

  @override
  String chatBadgeConversationError(String title) {
    return '\"$title\" tiene un error.';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '\"$title\" necesita su intervención.';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '\"$title\" tiene una nueva respuesta.';
  }

  @override
  String get chatBadgeSyncing => 'Sincronizando conversaciones...';

  @override
  String get chatBadgeDataSaverActive =>
      'El ahorro de datos móviles está activo.';

  @override
  String get chatCollapseGroup => 'Contraer grupo';

  @override
  String get chatExpandGroup => 'Expandir grupo';

  @override
  String get chatForkFailed => 'Error al bifurcar conversación';

  @override
  String get chatForked => 'Conversación bifurcada';

  @override
  String get chatNoConversationsInProject =>
      'No hay conversaciones en este proyecto.';

  @override
  String get chatOpenProjectToLoad =>
      'Abra un proyecto para cargar conversaciones.';

  @override
  String get chatExportCanceled => 'Exportación de sesión cancelada';

  @override
  String get chatLargeContentSkipped =>
      'Se omitió contenido grande o mal formado por estabilidad.';

  @override
  String chatTokensLabel(int total) {
    return 'Tokens: $total';
  }

  @override
  String chatCostLabel(String cost) {
    return 'Costo: \$$cost';
  }

  @override
  String get chatFileExplorerNames => 'Nombres';

  @override
  String get chatFileExplorerContents => 'Contenidos';

  @override
  String chatCloseProject(String project) {
    return 'Cerrar $project';
  }

  @override
  String get sessionExportUser => 'Usuario';

  @override
  String get sessionExportAssistant => 'Asistente';

  @override
  String get sessionExportInput => 'Entrada:';

  @override
  String get sessionExportOutput => 'Salida:';

  @override
  String get sessionExportError => 'Error:';

  @override
  String get sessionExportUntitled => 'Sesión sin título';

  @override
  String get modelLabelTinyEnglish => 'Tiny (Inglés)';

  @override
  String get modelLabelBaseEnglish => 'Base (Inglés)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 idiomas europeos)';

  @override
  String get cannedNewQuickReply => 'Nueva respuesta rápida';

  @override
  String get settingsSoundPickerNotAvailable =>
      'El selector de sonidos del sistema no está disponible en esta plataforma.';

  @override
  String get appProviderPrimaryServer => 'Servidor primario';

  @override
  String get appProviderLocalManaged => 'OpenCode Local (Gestionado)';

  @override
  String get appProviderLocalServerStopped =>
      'El servidor local está detenido.';

  @override
  String get appProviderRunDiagnostics =>
      'Ejecute diagnósticos para verificar los requisitos locales de OpenCode.';

  @override
  String get appProviderInvalidServerUrl => 'URL del servidor inválida';

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth no es compatible con esta plataforma';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale no es compatible con esta plataforma';

  @override
  String get appProviderProfileNotFound => 'Perfil de servidor no encontrado';

  @override
  String get appProviderCannotActivateUnhealthy =>
      'No se puede activar un servidor no saludable';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode detectado';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode no detectado';

  @override
  String get appProviderDetectingCommand => 'Detectando comando OpenCode...';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'No se detectó el comando OpenCode. Si lo instaló hace un momento, refresque las comprobaciones o reabra $appName para recargar el PATH.';
  }

  @override
  String get appProviderNotDetectedInstall =>
      'No se detectó el comando OpenCode. Ejecute la instalación desde el asistente.';

  @override
  String appProviderUsingCommandAt(String path) {
    return 'Usando comando OpenCode en $path';
  }

  @override
  String get appProviderDesktopOnly =>
      'El servidor local gestionado solo está disponible en escritorio.';

  @override
  String get appProviderInstallingRequirements =>
      'Instalando requisitos de OpenCode...';

  @override
  String get appProviderInstallationFailed =>
      'La instalación de OpenCode falló.';

  @override
  String get appProviderInstalledSuccessfully =>
      'Requisitos de OpenCode instalados con éxito.';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'Instalación exitosa. Comando OpenCode disponible en $path.';
  }

  @override
  String get appProviderInstallSucceeded => 'Instalación exitosa.';

  @override
  String get appProviderStartingLocalServer => 'Iniciando servidor local...';

  @override
  String get appProviderFailedToStart =>
      'Error al iniciar el servidor OpenCode local.';

  @override
  String appProviderRunningAt(String url) {
    return 'Ejecutándose en $url';
  }

  @override
  String get appProviderStoppingLocalServer => 'Deteniendo servidor local...';

  @override
  String appProviderExitedWithCode(int code) {
    return 'El servidor local salió con el código $code.';
  }

  @override
  String get appProviderInstallBinary => 'Instalar binario';

  @override
  String get appProviderInstallViaNpm => 'Instalar vía npm';

  @override
  String get appProviderInstallViaBun => 'Instalar vía Bun';

  @override
  String get appProviderInstallBunOpenCode => 'Instalar Bun + OpenCode';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'Tailscale no es compatible con esta plataforma.';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'Tailscale no es compatible con Windows.';

  @override
  String get tailscaleWaitingAdminApproval =>
      'Este nodo de Tailscale está esperando la aprobación del administrador.';

  @override
  String get notificationSoundLoadFailed =>
      'Error al cargar los sonidos del sistema Android';

  @override
  String get chatDescriptionNewConversation => 'Nueva conversación';

  @override
  String get chatDescriptionRefreshData => 'Refrescar datos del chat';

  @override
  String get chatDescriptionFocusInput => 'Enfocar entrada de mensaje';

  @override
  String get chatDescriptionVoiceInput => 'Iniciar o detener entrada de voz';

  @override
  String get chatDescriptionQuickOpen => 'Apertura rápida de archivos';

  @override
  String get chatDescriptionOpenSettings => 'Abrir ajustes';

  @override
  String get chatDescriptionCycleModels => 'Ciclar modelos recientes';

  @override
  String get chatDescriptionCycleVariant => 'Ciclar variante de modelo';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      'Enfocar entrada (o cerrar panel cuando está abierto)';

  @override
  String get chatDescriptionNextAgent => 'Siguiente agente';

  @override
  String get chatDescriptionPreviousAgent => 'Agente anterior';

  @override
  String get chatDescriptionCloseApp =>
      'Cerrar la aplicación usando el comportamiento de cierre de la plataforma';

  @override
  String get chatDescriptionForceExit => 'Forzar salida de la aplicación';

  @override
  String get chatDescriptionStopResponse =>
      'Detener respuesta activa (mientras responde)';

  @override
  String get chatDescriptionProjectCommand => 'Comando de proyecto';

  @override
  String get chatDescriptionOpenProjects =>
      'Use este botón para abrir sus proyectos y conversaciones.';

  @override
  String get chatDescriptionSwitchProject =>
      'Use este botón para cambiar carpetas de proyecto y contexto.';

  @override
  String chatDescriptionChildren(int count) {
    return 'Hijos: $count';
  }

  @override
  String get chatDescriptionDiffFilesZero => 'Archivos diff: 0';

  @override
  String get appProviderErrorInvalidServerUrl => 'URL del servidor inválida';

  @override
  String get appProviderErrorServerUrlRequired =>
      'La URL del servidor es obligatoria';

  @override
  String get appProviderErrorServerAlreadyExists =>
      'Ya existe un servidor con esta URL';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth no es compatible con esta plataforma';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale no es compatible con esta plataforma';

  @override
  String get appProviderErrorServerProfileNotFound =>
      'Perfil de servidor no encontrado';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      'No se puede activar un servidor no saludable';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      'El servidor local gestionado solo está disponible en escritorio.';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'El servidor local se inició pero la comprobación de salud no pasó.';

  @override
  String get appProviderErrorInstallationFailed =>
      'La instalación de OpenCode falló.';

  @override
  String get appProviderStatusLocalServerStopped =>
      'El servidor local está detenido.';

  @override
  String get appProviderStatusStartingLocalServer =>
      'Iniciando servidor local...';

  @override
  String appProviderStatusRunningAt(String url) {
    return 'Ejecutándose en $url';
  }

  @override
  String get appProviderStatusStoppingLocalServer =>
      'Deteniendo servidor local...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'El servidor local salió con el código $code.';
  }

  @override
  String get appProviderSetupDetectingOpenCode =>
      'Detectando comando OpenCode...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode detectado';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode no detectado';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return 'Usando comando OpenCode en $path';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'Instalando requisitos de OpenCode...';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'Requisitos de OpenCode instalados con éxito.';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'Instalación exitosa. Comando OpenCode disponible en $path.';
  }

  @override
  String get appProviderSetupInstallationSucceeded => 'Instalación exitosa.';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'No se detectó el comando OpenCode. Si lo instaló hace un momento, refresque las comprobaciones o reabra CodeWalk para recargar el PATH.';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'No se detectó el comando OpenCode. Ejecute la instalación desde el asistente.';

  @override
  String get appProviderLabelPrimaryServer => 'Servidor primario';

  @override
  String get appProviderLabelLocalOpenCodeManaged =>
      'OpenCode Local (Gestionado)';
}
