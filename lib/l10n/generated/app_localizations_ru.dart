// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appShellDownloadingUpdate => 'Загрузка обновления';

  @override
  String get appShellInstall => 'Установить';

  @override
  String get appShellInstallFailed => 'Ошибка установки';

  @override
  String get appShellInstallingUpdate => 'Установка обновления...';

  @override
  String get appShellRestart => 'Перезапустить';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return 'Доступно обновление: v$latestVersion';
  }

  @override
  String get behaviorAdvancedPermissionRule => 'Расширенное правило разрешений';

  @override
  String get behaviorAutomatic => 'Автоматически';

  @override
  String get behaviorAutomaticFallback => 'Автоматический откат';

  @override
  String get behaviorCellularDataSaver => 'Экономия мобильных данных';

  @override
  String get behaviorChatLevelShare => 'Обмен на уровне чата';

  @override
  String get behaviorCodeWalkReleaseChecks => 'Проверки версий CodeWalk';

  @override
  String get behaviorControlsOfficialGlobal =>
      'Управляет официальными глобальными настройками OpenCode';

  @override
  String get behaviorControlsUpstreamOpenCode =>
      'Управляет настройками OpenCode upstream';

  @override
  String get behaviorCustomDisplayName => 'Пользовательское отображаемое имя';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return 'Сокращает автоматическое использование мобильных данных, останавливая фоновые загрузки и ограничивая автоматические обновления на переднем плане одним пакетом каждые $inSeconds секунд.';
  }

  @override
  String get behaviorDisabled => 'Отключено';

  @override
  String get behaviorLightweightTasksLike => 'Лёгкие задачи, такие как';

  @override
  String get behaviorManual => 'Вручную';

  @override
  String get behaviorNotify => 'Уведомлять';

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
  String get cannedNoSuggestions => 'No suggestions';

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
  String get chatAddServerToStart => 'Add a server to start chatting.';

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
    return 'Дочерние: $length';
  }

  @override
  String get chatChooseDirectory => 'Choose Directory';

  @override
  String get chatChooseFolderOpen =>
      'Choose a folder to open as project context.';

  @override
  String get chatClose => 'Close';

  @override
  String get chatCompactContext => 'Compact Context';

  @override
  String get chatConversations => 'Conversations';

  @override
  String get chatConversationsPane => 'Conversations';

  @override
  String get chatCurrent => 'Use current';

  @override
  String get chatDiffFiles => 'Diff files: 0';

  @override
  String get chatDisplay => 'Display';

  @override
  String get chatDisplayToggles => 'Display toggles';

  @override
  String get chatDoubleESCStop => 'Двойной ESC для остановки';

  @override
  String get chatFilterActive => 'Active';

  @override
  String get chatFilterAll => 'All';

  @override
  String get chatFilterArchived => 'Archived';

  @override
  String get chatFilterDirectories => 'Filter directories';

  @override
  String get chatFilterSessions => 'Filter sessions';

  @override
  String get chatGoToFirst => 'Go to first message';

  @override
  String get chatGoToLatest => 'Go to latest message';

  @override
  String chatGroupMessageCountMessages(
    String messageCount,
    String compactionLabel,
  ) {
    return '$messageCount сообщений скрыто перед сжатием $compactionLabel';
  }

  @override
  String get chatHelloAssistant => 'Hello! I am your AI assistant';

  @override
  String get chatHelp => 'How can I help you?';

  @override
  String get chatHideConversationsSidebar => 'Hide Conversations sidebar';

  @override
  String get chatHideUtilitySidebar => 'Hide Utility sidebar';

  @override
  String get chatHistoryCollapsed => 'Previous history is collapsed';

  @override
  String get chatKeepWorking => 'Keep working';

  @override
  String get chatLatestToolActivity =>
      'Latest tool activity stays inside this bounded panel to keep the chat viewport stable.';

  @override
  String get chatLoadMore => 'Load more';

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
    return 'Модель: $modelId';
  }

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return 'Провайдер: $providerId';
  }

  @override
  String get chatMessageRewindEdit => 'Rewind and edit from here';

  @override
  String get chatMessageYou => 'You';

  @override
  String get chatNewChat => 'New Chat';

  @override
  String get chatNewChatTourDescription => 'Start a new conversation here.';

  @override
  String get chatNewChatTourTitle => 'New chat';

  @override
  String get chatNoServerYet => 'No server configured yet';

  @override
  String get chatOpenFiles => 'Open Files';

  @override
  String get chatOpenProject => 'Открыть проект';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenSidebar => 'Открыть боковую панель';

  @override
  String get chatPageStatusContextUsage => 'Использование контекста';

  @override
  String get chatPageStatusCost => 'Стоимость';

  @override
  String get chatPageStatusLimit => 'Лимит';

  @override
  String get chatPageStatusManageServers => 'Управление серверами';

  @override
  String get chatPageStatusSaver => 'Экономия';

  @override
  String get chatPageStatusSwitchServer => 'Сменить сервер';

  @override
  String get chatPageStatusTokens => 'Токены';

  @override
  String get chatPageStatusUsage => 'Использование';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatProjectContext => 'Project Context';

  @override
  String get chatProjectContext2 => 'Контекст проекта';

  @override
  String get chatRealtimeGlobalEvent => 'глобальное событие';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return 'глобальное событие ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale =>
      'глобальное событие (устаревшее поколение)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return 'поток сообщений ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => 'событие реального времени';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return 'событие реального времени ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale =>
      'событие реального времени (устаревшее поколение)';

  @override
  String get chatRealtimeReconnectingServerTry =>
      'Повторное подключение к серверу. Попробуйте снова через мгновение.';

  @override
  String get chatReasoning => 'Рассуждение...';

  @override
  String get chatRecentSessions => 'Recent sessions';

  @override
  String get chatRecentSessionsToggle => 'Recent sessions';

  @override
  String get chatRedoLastTurn => 'Redo last undone turn';

  @override
  String get chatRefresh => 'Refresh';

  @override
  String get chatRefreshConversation => 'Could not refresh this conversation';

  @override
  String get chatRefreshProjects => 'Refresh projects';

  @override
  String get chatRefreshSessionDetails => 'Refresh session details';

  @override
  String chatRemoveDisplayNameHistory(String displayName) {
    return 'Удалить $displayName из истории';
  }

  @override
  String get chatRetry => 'Retry';

  @override
  String get chatRetry2 => 'Retry';

  @override
  String get chatRetryRefresh => 'Retry refresh';

  @override
  String get chatRetryingModelRequest => 'Повторная попытка запроса модели...';

  @override
  String get chatReturnToMainConversation => 'Return to main conversation';

  @override
  String get chatReviewChanges => 'Review changes';

  @override
  String get chatSearchConversations => 'Search conversations';

  @override
  String get chatSearchNextResult => 'Next result';

  @override
  String get chatSearchNoResults => 'No results';

  @override
  String get chatSearchPreviousResult => 'Previous result';

  @override
  String chatSearchResultCount(int current, int total) {
    return 'Message $current of $total';
  }

  @override
  String get chatSearchTimeline => 'Search timeline';

  @override
  String get chatSelectDirectory => 'Select directory';

  @override
  String get chatSelectOrCreate =>
      'Select or create a conversation to start chatting';

  @override
  String get chatSelectProjectBelow => 'Select a project below.';

  @override
  String get chatSessionActions => 'Session actions';

  @override
  String chatSessionChatSessionSession(String title) {
    return 'Сессия чата: $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return 'Разговор $nextAction';
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
  String get chatSetUpServer => 'Set up server';

  @override
  String get chatSettings => 'Settings';

  @override
  String get chatSidebarAccess => 'Доступ к боковой панели';

  @override
  String get chatSortMostRecent => 'Most Recent';

  @override
  String get chatSortOldest => 'Oldest';

  @override
  String get chatSortRecent => 'Recent';

  @override
  String get chatSortSessions => 'Sort sessions';

  @override
  String get chatSortTitle => 'Title';

  @override
  String chatSyncLabel(String label) {
    return 'Синхронизация: $label';
  }

  @override
  String get chatTasks => 'Tasks';

  @override
  String get chatTasksAvailableSession =>
      'No tasks are available for this session.';

  @override
  String get chatToggleSidebars => 'Toggle sidebars';

  @override
  String get chatUndoLastTurn => 'Undo last turn';

  @override
  String get chatUseCurrent => 'Use current';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonSave => 'Save';

  @override
  String get composerAddAttachment => 'Add attachment';

  @override
  String get composerAttachFiles => 'Attach files';

  @override
  String get composerCannedAppendAtCursor => 'Append at cursor';

  @override
  String get composerCannedLabel => 'Label (optional)';

  @override
  String get composerCannedNoReplies => 'No quick replies yet.';

  @override
  String get composerCannedReplace => 'Replace';

  @override
  String get composerCannedSave => 'Save';

  @override
  String get composerCannedScopeGlobal => 'Global';

  @override
  String get composerCannedScopeProject => 'Project-only';

  @override
  String get composerCannedSendAutomatically => 'Send automatically';

  @override
  String get composerCannedText => 'Text';

  @override
  String get composerChatInput => 'Chat input';

  @override
  String get composerDeleteAction => 'Delete';

  @override
  String get composerEdit => 'Edit';

  @override
  String get composerExtras => 'Extras';

  @override
  String get composerNewQuickReply => 'New quick reply';

  @override
  String get composerSelectImages => 'Select Images';

  @override
  String get composerSelectPdf => 'Select PDF';

  @override
  String get composerSend => 'Send';

  @override
  String get composerShellMode => 'Shell mode';

  @override
  String get dialogDownload => 'Download';

  @override
  String get dialogLanguage => 'Language';

  @override
  String get dialogMoonshineModelSize => 'Model size';

  @override
  String get dialogMoonshineVoiceSetup => 'Moonshine Voice Setup';

  @override
  String get dialogParakeetModel => 'Parakeet model';

  @override
  String get dialogParakeetVoiceSetup => 'Parakeet Voice Setup';

  @override
  String get dialogSenseVoiceModel => 'SenseVoice model';

  @override
  String get dialogSenseVoiceSetup => 'SenseVoice Setup';

  @override
  String get dialogVoiceInputSetup => 'Voice Input Setup';

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
    return 'Вложение сохранено в $path и открыто.';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return 'Вложение сохранено в $path.';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return 'Вложение сохранено в $savedPath.';
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
  String get filesHideSidebar => 'Hide Files sidebar';

  @override
  String get filesNames => 'Names';

  @override
  String filesOpenFilesFileState(String length) {
    return 'Открытые файлы ($length)';
  }

  @override
  String get filesQuickOpen => 'Quick Open';

  @override
  String get filesQuickOpenFile => 'Quick Open File';

  @override
  String get filesRefresh => 'Refresh files';

  @override
  String get filesSearchHint => 'Search files by name or path';

  @override
  String get filesTitle => 'Files';

  @override
  String get logsAppLogs => 'App Logs';

  @override
  String get logsClear => 'Clear logs';

  @override
  String get logsCloseSearch => 'Close search';

  @override
  String get logsCopyFiltered => 'Copy filtered logs';

  @override
  String get logsLevel => 'Level';

  @override
  String get logsSearch => 'Search logs';

  @override
  String logsShowingOrderedLength(int length, int length2) {
    return 'Показано $length из $length2 записей';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => 'Математика';

  @override
  String get mermaidCopySourceTooltip => 'Copy source';

  @override
  String get mermaidDiagramLabel => 'Mermaid Diagram';

  @override
  String get modelAuto => 'Auto';

  @override
  String get modelChooseAgent => 'Choose agent';

  @override
  String get modelFavorites => 'Favorites';

  @override
  String get modelLoadingModels => 'Loading models';

  @override
  String get modelModelsFound => 'No models found';

  @override
  String get modelRetryModels => 'Retry models';

  @override
  String get modelSearchHint => 'Search model or provider';

  @override
  String get msgBatterySettingsFailed =>
      'Could not open Android battery optimization settings.';

  @override
  String get msgBatterySettingsOpened =>
      'Android battery settings opened. Allow unrestricted battery for CodeWalk.';

  @override
  String get msgClearUsernameNeedsConfigEdit =>
      'Clearing the OpenCode conversation username still requires editing config outside the app.';

  @override
  String get msgCommandCopied => 'Command copied';

  @override
  String get msgCopiedToClipboard => 'Copied to clipboard';

  @override
  String get msgEnterUsernameToSave =>
      'Enter a username to save a custom OpenCode conversation name.';

  @override
  String get msgFailedToSendMessage =>
      'Failed to send message. Draft kept for retry.';

  @override
  String get msgFailedToStartVoiceInput => 'Failed to start voice input';

  @override
  String msgFilePathNotFound(String path) {
    return 'File not found: $path';
  }

  @override
  String get msgFilteredLogsCopied => 'Filtered logs copied to clipboard';

  @override
  String get msgInfoAgent => 'Agent';

  @override
  String get msgInfoCompaction => 'Compaction';

  @override
  String msgInfoCost(String cost) {
    return 'Cost: \$$cost';
  }

  @override
  String get msgInfoMessageInfo => 'Message Info';

  @override
  String msgInfoModel(String modelId) {
    return 'Model: $modelId';
  }

  @override
  String get msgInfoNoMetadata => 'No metadata available';

  @override
  String msgInfoPartDescriptionModel(String description, String model) {
    return '$description$model';
  }

  @override
  String get msgInfoPatch => 'Patch';

  @override
  String msgInfoProvider(String providerId) {
    return 'Provider: $providerId';
  }

  @override
  String get msgInfoRetry => 'Retry';

  @override
  String get msgInfoSnapshot => 'Snapshot';

  @override
  String msgInfoSubtaskPartAgent(String agent) {
    return 'Подзадача ($agent)';
  }

  @override
  String msgInfoTokens(String total) {
    return 'Tokens: $total';
  }

  @override
  String get msgInfoUndoThisTurn => 'Undo this turn';

  @override
  String get msgInfoView => 'View';

  @override
  String get msgNoSystemSoundsFound =>
      'No system sound was found on this device.';

  @override
  String get msgNoValidFilesSelected => 'No valid files were selected';

  @override
  String get msgReadAloud => 'Read aloud';

  @override
  String get msgReadAloudNotAvailable =>
      'Text-to-speech is not available on this device.';

  @override
  String get msgSetupDebugCopied => 'OpenCode setup debug copied to clipboard';

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
      'System sound picker is not available on this platform.';

  @override
  String get msgUpdatedButRefreshFailed =>
      'Updated the server setting, but could not refresh chat providers.';

  @override
  String get msgVoiceInputUnavailable =>
      'Voice input is unavailable on this device';

  @override
  String get notifAndroidBatteryOptimization => 'Android battery optimization';

  @override
  String get notifConversationUpdates => 'Conversation updates';

  @override
  String get notifNotificationsArriveReopening =>
      'If notifications only arrive when reopening the app, allow CodeWalk to run without optimization on this device.';

  @override
  String get notifResponseRunningKeep =>
      'When a response is running, keep realtime active briefly after you leave the app.';

  @override
  String notifSelectedSoundLabel(String soundLabel) {
    return 'Выбрано: $soundLabel';
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
    return '$length строк журнала настройки и $length2 событий настройки доступны на отдельном экране отладки настройки.';
  }

  @override
  String get onboardingAuthenticate => 'Authenticate';

  @override
  String get onboardingChooseAnotherPath => 'Choose another path';

  @override
  String get onboardingClear => 'Clear';

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
  String get onboardingLabel => 'Label (optional)';

  @override
  String get onboardingLabelHint => 'My server';

  @override
  String onboardingLatestOutputAppProvider(String localServerLastOutput) {
    return 'Последний вывод: $localServerLastOutput';
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
  String get onboardingPassword => 'Password';

  @override
  String get onboardingPasswordRequired => 'Enter password';

  @override
  String get onboardingRecommendedOrderTry =>
      'Recommended order: try Install Bun + OpenCode if you want CodeWalk to bootstrap everything for you. Use Existing if OpenCode is already installed.';

  @override
  String get onboardingRefreshChecks => 'Refresh Checks';

  @override
  String get onboardingRunDiagnosticsToVerify =>
      'Запустите диагностику, чтобы проверить локальные требования OpenCode.';

  @override
  String get onboardingServerUrl => 'Server URL';

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
  String get onboardingUsername => 'Username';

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
  String get permissionAllowOnce => 'Allow Once';

  @override
  String get permissionAlways => 'Always';

  @override
  String get permissionBack => 'Back';

  @override
  String get permissionConfirmReject => 'Confirm Reject';

  @override
  String get permissionReject => 'Reject';

  @override
  String get permissionReopen => 'Reopen';

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
  String get quotaAuthCookie => 'Auth cookie';

  @override
  String get quotaForget => 'Forget';

  @override
  String get quotaOpenCodeGoUsage => 'OpenCode Go usage';

  @override
  String get quotaOpenDashboard => 'Open OpenCode dashboard';

  @override
  String get quotaSaving => 'Saving...';

  @override
  String get quotaWorkspaceId => 'Workspace ID';

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
    return 'Команда: $localServerCommandPath';
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
    return 'Удалить \"$displayName\"?';
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
  String get sessionActionArchived => 'archived';

  @override
  String get sessionActionDeleted => 'deleted';

  @override
  String get sessionActionForked => 'forked';

  @override
  String get sessionActionUnarchived => 'unarchived';

  @override
  String get sessionCancelRename => 'Cancel rename';

  @override
  String get sessionCopyLink => 'Copy Link';

  @override
  String get sessionDelete => 'Delete';

  @override
  String get sessionDeleteTitle => 'Delete Conversation';

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
  String get sessionFailedRename => 'Failed to rename conversation';

  @override
  String get sessionFailedUpdateArchive => 'Failed to update archive state';

  @override
  String get sessionFailedUpdateSharing => 'Failed to update sharing state';

  @override
  String get sessionFork => 'Fork';

  @override
  String get sessionKeyboardShortcuts => 'Keyboard shortcuts';

  @override
  String get sessionNotAvailable =>
      'Conversation is not available for this project yet';

  @override
  String get sessionRename => 'Rename';

  @override
  String get sessionRenameHint => 'Enter new conversation name';

  @override
  String get sessionRenameTitle => 'Rename Conversation';

  @override
  String get sessionSaveTitle => 'Save title';

  @override
  String get sessionShareLinkCopied => 'Share link copied';

  @override
  String get sessionTitleHint => 'Conversation title';

  @override
  String get settingsAboutCheckForUpdates => 'Check for updates';

  @override
  String get settingsAboutCheckOnOpen => 'Check for updates on open';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Automatically check when the app starts';

  @override
  String get settingsAboutChecking => 'Checking...';

  @override
  String get settingsAboutDescription => 'Version, updates and links';

  @override
  String get settingsAboutDismiss => 'Dismiss';

  @override
  String settingsAboutDownloading(String percent) {
    return 'Downloading... $percent%';
  }

  @override
  String get settingsAboutEraseAllData => 'Erase all data and restart';

  @override
  String get settingsAboutInstallUpdate => 'Install update';

  @override
  String get settingsAboutInstalling => 'Installing...';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version is the latest version';
  }

  @override
  String get settingsAboutLoading => 'Loading...';

  @override
  String get settingsAboutReplayChatTour => 'Replay chat tour';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Close settings and show the guided chat walkthrough';

  @override
  String get settingsAboutResetApp => 'Reset app';

  @override
  String get settingsAboutResetAppQuestion => 'Reset app?';

  @override
  String get settingsAboutResetAppWarning =>
      'This will erase all servers, settings, and cached data. This action cannot be undone.';

  @override
  String get settingsAboutRetryInstall => 'Retry install';

  @override
  String get settingsAboutTapToCheck => 'Tap to check for new versions';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutUpToDate => 'You\'re up to date';

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Update available: v$version';
  }

  @override
  String get settingsAboutUpdateInstalled =>
      'Update installed. Restart the app to apply.';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String settingsAboutVersionBuild(String buildNumber, String version) {
    return '$version (build $buildNumber)';
  }

  @override
  String get settingsAppearanceAmoledDark => 'AMOLED dark mode';

  @override
  String get settingsAppearanceAmoledDarkActive =>
      'Use pure black surfaces while dark mode is active.';

  @override
  String get settingsAppearanceAmoledDarkInactive =>
      'Switch to dark mode to enable AMOLED surfaces.';

  @override
  String get settingsAppearanceBrandColor => 'Brand color';

  @override
  String get settingsAppearanceBrandColorDynamicBlocked =>
      'Disable wallpaper colors to pick a brand color.';

  @override
  String get settingsAppearanceBrandColorNormal =>
      'Pick a seed color for the app palette.';

  @override
  String get settingsAppearanceBrandColorPresetBlocked =>
      'Switch to CodeWalk Classic to pick a brand color.';

  @override
  String get settingsAppearanceCodeWalkClassic => 'CodeWalk Classic';

  @override
  String get settingsAppearanceComposerTips => 'Composer tips';

  @override
  String get settingsAppearanceComposerTipsDescription =>
      'Show or hide rotating tips while the assistant is reasoning.';

  @override
  String get settingsAppearanceContrast => 'Contrast';

  @override
  String get settingsAppearanceContrastDynamicBlocked =>
      'Disable wallpaper colors to adjust contrast.';

  @override
  String get settingsAppearanceContrastHigh => 'High';

  @override
  String get settingsAppearanceContrastNormal =>
      'Adjust the contrast level of the color scheme.';

  @override
  String get settingsAppearanceContrastPresetBlocked =>
      'Switch to CodeWalk Classic to adjust contrast.';

  @override
  String get settingsAppearanceContrastReduced => 'Reduced';

  @override
  String get settingsAppearanceDark => 'Dark';

  @override
  String get settingsAppearanceDensity => 'Density';

  @override
  String get settingsAppearanceDensityDense => 'Dense';

  @override
  String get settingsAppearanceDensityDescription =>
      'Apply spacing and component density across the app.';

  @override
  String get settingsAppearanceDensityExtraDense => 'Extra Dense';

  @override
  String get settingsAppearanceDensityExtraSpacious => 'Extra Spacious';

  @override
  String get settingsAppearanceDensityNormal => 'Normal';

  @override
  String get settingsAppearanceDensitySpacious => 'Spacious';

  @override
  String get settingsAppearanceDescription =>
      'Density and timeline bubble visibility';

  @override
  String get settingsAppearanceLight => 'Light';

  @override
  String get settingsAppearanceMathRendering => 'Отображение математики';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      'Отображать математические выражения LaTeX как наборные уравнения в сообщениях чата.';

  @override
  String get settingsAppearanceNoPresets => 'No preset palettes found';

  @override
  String get settingsAppearanceOpenCodePresets => 'OpenCode Presets';

  @override
  String get settingsAppearancePresetHelper =>
      'Mirrors the official OpenCode Web built-in theme list.';

  @override
  String get settingsAppearancePresetNote =>
      'Theme colors now follow the official OpenCode Web registry and drive markdown/code surfaces too.';

  @override
  String get settingsAppearancePresetPalette => 'Preset palette';

  @override
  String get settingsAppearanceSearchPreset => 'Search preset palette';

  @override
  String get settingsAppearanceSectionDescription =>
      'Tune visual density and message surfaces for your workflow.';

  @override
  String get settingsAppearanceSectionTitle => 'Appearance';

  @override
  String get settingsAppearanceSystem => 'System';

  @override
  String get settingsAppearanceTaskList => 'Task list';

  @override
  String get settingsAppearanceTaskListDescription =>
      'Show or hide the session task list widget.';

  @override
  String get settingsAppearanceTheme => 'Theme';

  @override
  String get settingsAppearanceThemeDescription =>
      'Choose light, dark, or system mode, then keep the CodeWalk classic palette or switch to an OpenCode preset.';

  @override
  String get settingsAppearanceThinkingBubbles => 'Thinking bubbles';

  @override
  String get settingsAppearanceThinkingBubblesDescription =>
      'Show or hide reasoning blocks in assistant messages.';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsAppearanceToolCallBubbles => 'Tool call bubbles';

  @override
  String get settingsAppearanceToolCallBubblesDescription =>
      'Show or hide tool execution cards in assistant messages.';

  @override
  String get settingsAppearanceWallpaperColors => 'Use wallpaper colors';

  @override
  String get settingsAppearanceWallpaperNormal =>
      'Extract color scheme from your device wallpaper.';

  @override
  String get settingsAppearanceWallpaperPresetBlocked =>
      'Switch to CodeWalk Classic to use wallpaper colors.';

  @override
  String get settingsBack => 'Back';

  @override
  String get settingsBehaviorAutoupdateCaveat =>
      'Use About for CodeWalk release checks. This setting only mirrors the official OpenCode `autoupdate` config.';

  @override
  String get settingsBehaviorAutoupdateHelp =>
      'Controls upstream OpenCode runtime updates, not CodeWalk app update checks.';

  @override
  String get settingsBehaviorCellularDataSaver => 'Cellular data saver';

  @override
  String get settingsBehaviorConfigDeferred =>
      'CodeWalk will apply this OpenCode setting after the current response finishes.';

  @override
  String settingsBehaviorConfigUpdateFailed(String field) {
    return 'Could not update the OpenCode $field.';
  }

  @override
  String get settingsBehaviorConversationUsername => 'Conversation username';

  @override
  String get settingsBehaviorConversationUsernameHelp =>
      'Custom display name shown in conversations instead of the system username.';

  @override
  String get settingsBehaviorDataSaverActive => 'Active now on mobile data.';

  @override
  String get settingsBehaviorDataSaverCellularOnly =>
      'Only applies when the connection is cellular/mobile.';

  @override
  String get settingsBehaviorDataSaverDescription =>
      'Cuts automatic mobile-data usage by stopping background downloads and throttling automatic foreground refreshes.';

  @override
  String get settingsBehaviorDataSaverWaiting =>
      'Waiting for the next mobile-data sync window.';

  @override
  String get settingsBehaviorDefaultAgent => 'Default agent';

  @override
  String get settingsBehaviorDefaultAgentHelp =>
      'Primary agent used when no agent is explicitly chosen.';

  @override
  String get settingsBehaviorDefaultModel => 'Default model';

  @override
  String get settingsBehaviorDefaultModelHelp =>
      'Shared across OpenCode clients through config.';

  @override
  String get settingsBehaviorDescription =>
      'OpenCode defaults, provenance, and composer sync safety';

  @override
  String get settingsBehaviorEnableDataSaver => 'Enable cellular data saver';

  @override
  String get settingsBehaviorMultiDeviceSync =>
      'Enable experimental multi-device sync';

  @override
  String get settingsBehaviorMultiDeviceSyncDescription =>
      'Sync composer selection (agent/model/variant) with the active server config.';

  @override
  String get settingsBehaviorMultiDeviceSyncWarning =>
      'Can abort ongoing sessions when working in more than one session at the same time.';

  @override
  String get settingsBehaviorNoAgents => 'No agents found';

  @override
  String get settingsBehaviorNoModels => 'No models found';

  @override
  String get settingsBehaviorOpenCodeAutoupdate => 'OpenCode auto-update';

  @override
  String get settingsBehaviorOpenCodeDefaults => 'OpenCode-backed defaults';

  @override
  String get settingsBehaviorOpenCodeDefaultsDescription =>
      'These values write to `/config` on the active server and match official OpenCode shared config.';

  @override
  String get settingsBehaviorOpenCodeSnapshots => 'OpenCode snapshots';

  @override
  String get settingsBehaviorOpenCodeSnapshotsDescription =>
      'Keep upstream git-backed snapshots enabled for undo/redo and recovery history.';

  @override
  String get settingsBehaviorPermissionDeferred =>
      'Advanced permission rule editing stays out of Settings for now and is deferred to later parity work.';

  @override
  String get settingsBehaviorPermissionProvenance =>
      'Permission handling provenance';

  @override
  String get settingsBehaviorPermissionProvenanceDescription =>
      'Official OpenCode permission policy is configured in `opencode.json` with allow/ask/deny rules per tool. CodeWalk keeps the official permission-request cards and adds one approved ADR-023 exception: the composer auto-approve toggle replies with `Always` and `remember: true` unconditionally to create durable session-scoped grants, and keeps the same thread-scoped continuity path active in the Android background worker.';

  @override
  String get settingsBehaviorRefreshDefaults => 'Refresh defaults';

  @override
  String get settingsBehaviorSaveUsername => 'Save username';

  @override
  String get settingsBehaviorSearchAutoupdate => 'Search auto-update mode';

  @override
  String get settingsBehaviorSearchDefaultAgent => 'Search default agent';

  @override
  String get settingsBehaviorSearchDefaultModel => 'Search default model';

  @override
  String get settingsBehaviorSearchShareMode => 'Search sharing mode';

  @override
  String get settingsBehaviorSearchSmallModel => 'Search small model';

  @override
  String get settingsBehaviorShareMode => 'OpenCode sharing default';

  @override
  String get settingsBehaviorShareModeCaveat =>
      'Use the chat-level share action to publish one session now. This setting only changes OpenCode\'s default sharing policy.';

  @override
  String get settingsBehaviorShareModeHelp =>
      'Controls the official global `share` config, not the share button for an individual chat.';

  @override
  String get settingsBehaviorSmallModel => 'Small model';

  @override
  String get settingsBehaviorSmallModelAutoFallback => 'Automatic fallback';

  @override
  String get settingsBehaviorSmallModelFallbackActive =>
      'OpenCode automatic fallback is active because `small_model` is unset.';

  @override
  String get settingsBehaviorSmallModelHelp =>
      'Used for lightweight tasks like title generation.';

  @override
  String get settingsBehaviorSmallModelResetCaveat =>
      'Resetting `small_model` back to automatic fallback still requires editing config outside the app because `/config` patch updates cannot remove keys.';

  @override
  String get settingsBehaviorSnapshotCaveat =>
      'This controls OpenCode snapshot storage and undo/redo support, not CodeWalk local cache snapshots.';

  @override
  String get settingsBehaviorTitle => 'Behavior';

  @override
  String get settingsBehaviorUsernameFallback =>
      'OpenCode uses the system username because `username` is unset.';

  @override
  String get settingsBehaviorUsernamePatchCaveat =>
      'Resetting `username` back to the system default still requires editing config outside the app because `/config` patch updates cannot remove keys.';

  @override
  String get settingsLanguageDescription =>
      'Choose the language used by CodeWalk. System default follows your device language.';

  @override
  String get settingsLanguageEmptyText => 'No languages found';

  @override
  String get settingsLanguageFieldHelper =>
      'Applies immediately and persists across restarts.';

  @override
  String get settingsLanguageFieldLabel => 'App language';

  @override
  String get settingsLanguageSearchHint => 'Search languages';

  @override
  String get settingsLanguageSystemDefault => 'System default';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLogsDescription =>
      'Runtime diagnostics and troubleshooting data';

  @override
  String get settingsLogsTitle => 'Registros';

  @override
  String get settingsNotificationsAgentSubtitle => 'When a response finishes';

  @override
  String get settingsNotificationsAgentUpdates => 'Agent updates';

  @override
  String get settingsNotificationsAnotherConversation => 'Another conversation';

  @override
  String get settingsNotificationsAppInBackground => 'App in background';

  @override
  String get settingsNotificationsBackgroundAlerts =>
      'Android background alerts';

  @override
  String get settingsNotificationsBackgroundBehavior => 'Background behavior';

  @override
  String get settingsNotificationsBackgroundBehaviorDescription =>
      'Choose how CodeWalk behaves after the app leaves the foreground.';

  @override
  String get settingsNotificationsBackgroundDescription =>
      'Use low-data background monitoring for response completions, permission requests, questions, and errors while the app is not on screen.';

  @override
  String get settingsNotificationsBackgroundToggle =>
      'Background alerts on Android';

  @override
  String get settingsNotificationsBackgroundToggleDescription =>
      'Turn off all Android background checks and hide the persistent monitor notification.';

  @override
  String get settingsNotificationsBatteryDescription =>
      'If notifications only arrive when reopening the app, allow CodeWalk to run without optimization on this device.';

  @override
  String get settingsNotificationsBatteryDisabled =>
      'Battery optimization is disabled for CodeWalk.';

  @override
  String get settingsNotificationsBatteryEnabled =>
      'Battery optimization is enabled. Some devices may delay background alerts.';

  @override
  String get settingsNotificationsBatteryOptimization =>
      'Android battery optimization';

  @override
  String get settingsNotificationsBatteryUnknown =>
      'Could not read battery optimization status yet.';

  @override
  String get settingsNotificationsChooseAudioFile => 'Choose audio file';

  @override
  String get settingsNotificationsChooseSystemSound => 'Choose system sound';

  @override
  String get settingsNotificationsCloseToTray => 'Close to tray';

  @override
  String get settingsNotificationsCloseToTrayDescription =>
      'Hide window and keep running in system tray.';

  @override
  String get settingsNotificationsDescription =>
      'Per-category notify and sound controls';

  @override
  String get settingsNotificationsDisableOptimization => 'Disable optimization';

  @override
  String get settingsNotificationsErrors => 'Errors';

  @override
  String get settingsNotificationsErrorsSubtitle =>
      'When a session reports a failure';

  @override
  String get settingsNotificationsJustClose => 'Just close';

  @override
  String get settingsNotificationsJustCloseDescription =>
      'Exit the application completely.';

  @override
  String get settingsNotificationsKeepLive => 'Keep alerts live for 3 min';

  @override
  String get settingsNotificationsKeepLiveDescription =>
      'When a response is already running, keep realtime active briefly after leaving the app.';

  @override
  String get settingsNotificationsLocal => 'Local';

  @override
  String get settingsNotificationsMinimizeWhenClose => 'Minimize when close';

  @override
  String get settingsNotificationsMinimizeWhenCloseDescription =>
      'Minimize to taskbar/dock and keep running.';

  @override
  String get settingsNotificationsNoCondition =>
      'If no condition is selected, alerts are allowed in any context.';

  @override
  String get settingsNotificationsNotify => 'Notify';

  @override
  String get settingsNotificationsNotifyOnlyWhen => 'Notify only when';

  @override
  String get settingsNotificationsOpenBatterySettings =>
      'Open battery settings';

  @override
  String get settingsNotificationsPermissions => 'Permissions and questions';

  @override
  String get settingsNotificationsPermissionsSubtitle =>
      'When tools request your input';

  @override
  String get settingsNotificationsPreview => 'Preview';

  @override
  String get settingsNotificationsRefreshStatus => 'Refresh status';

  @override
  String get settingsNotificationsSearchSoundType => 'Search sound type';

  @override
  String get settingsNotificationsSectionDescription =>
      'Control when alerts appear and when they can play sound.';

  @override
  String get settingsNotificationsSectionTitle => 'Notifications';

  @override
  String settingsNotificationsSelectedSound(String label) {
    return 'Selected: $label';
  }

  @override
  String get settingsNotificationsServer => 'Server';

  @override
  String get settingsNotificationsSound => 'Sound';

  @override
  String get settingsNotificationsSoundOnlyWhen => 'Sound only when';

  @override
  String get settingsNotificationsSoundType => 'Sound type';

  @override
  String get settingsNotificationsSyncInfo =>
      'Some category on/off toggles are synced from /config on the active server.';

  @override
  String get settingsNotificationsSyncInfoLocal =>
      'Current server does not expose notification toggles in /config; local values are active.';

  @override
  String get settingsNotificationsSystemSoundPickerTitle =>
      'Choose system sound';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsWhenClosing => 'When closing the window';

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
  String get settingsServersActive => 'Active';

  @override
  String get settingsServersChooseActive => 'Choose active server';

  @override
  String get settingsServersDefault => 'Default';

  @override
  String get settingsServersDescription =>
      'OpenCode servers and health routing';

  @override
  String get settingsServersTitle => 'Servers';

  @override
  String get settingsSetupWizard => 'Setup Wizard';

  @override
  String get settingsShortcutsDescription => 'Portable app key bindings';

  @override
  String get settingsShortcutsEdit => 'Edit shortcut';

  @override
  String get settingsShortcutsKeyboard => 'Keyboard shortcuts';

  @override
  String get settingsShortcutsReset => 'Reset shortcut';

  @override
  String get settingsShortcutsSearch => 'Search shortcuts';

  @override
  String get settingsShortcutsTitle => 'Shortcuts';

  @override
  String get settingsSpeechDescription =>
      'Engine, silence timeout, and model options';

  @override
  String get settingsSpeechRefreshStatus => 'Refresh status';

  @override
  String settingsSpeechSilenceTimeout(String value) {
    return 'Silence timeout: ${value}s';
  }

  @override
  String get settingsSpeechTitle => 'Speech to text';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get setupDebugBun => 'Bun';

  @override
  String get setupDebugBun2 => 'Bun';

  @override
  String get setupDebugCapturedSetupDetails => 'No captured setup details yet';

  @override
  String get setupDebugCapturedSetupLogs => 'Captured setup logs';

  @override
  String get setupDebugClear => 'Clear setup debug';

  @override
  String get setupDebugClearSetupDebug => 'Clear setup debug';

  @override
  String get setupDebugCodeWalkCaptureEnough =>
      'If CodeWalk did not capture enough context, check the official OpenCode logs and health endpoints directly:';

  @override
  String get setupDebugCommandPath => 'Command path';

  @override
  String get setupDebugCommandPath2 => 'Command path';

  @override
  String get setupDebugCopy => 'Copy setup debug';

  @override
  String get setupDebugCopySetupDebug => 'Copy setup debug';

  @override
  String get setupDebugCurrentStatus => 'Current status';

  @override
  String get setupDebugDiagnosticsLoading => 'Diagnostics are still loading.';

  @override
  String get setupDebugEnvironment => 'Environment diagnostics';

  @override
  String get setupDebugEnvironmentDiagnostics => 'Environment diagnostics';

  @override
  String get setupDebugFocusedOpenCodeSetup => 'Focused on OpenCode setup';

  @override
  String get setupDebugInstallDir => 'Install directory';

  @override
  String get setupDebugInstallDirectory => 'Install directory';

  @override
  String get setupDebugLatestLocalServer => 'Latest local server output';

  @override
  String get setupDebugLogs => 'Captured setup logs';

  @override
  String get setupDebugManual => 'Manual troubleshooting';

  @override
  String get setupDebugManualTroubleshooting => 'Manual troubleshooting';

  @override
  String get setupDebugNetwork => 'Network';

  @override
  String get setupDebugNetwork2 => 'Network';

  @override
  String get setupDebugNoDetails => 'No captured setup details yet';

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
  String get setupDebugPlatform => 'Platform';

  @override
  String get setupDebugPlatform2 => 'Platform';

  @override
  String get setupDebugRunDiagnosticsTry =>
      'Run diagnostics, try an installation method, or attempt a setup flow to capture OpenCode-specific troubleshooting details here.';

  @override
  String get setupDebugScreenCoversOpenCode =>
      'This screen only covers OpenCode installation, diagnostics, and local setup troubleshooting. Use App Logs for general CodeWalk runtime issues.';

  @override
  String get setupDebugServerOutput => 'Latest local server output';

  @override
  String get setupDebugStatus => 'Current status';

  @override
  String setupDebugTimeEntrySource(String time, String source) {
    return '$time - $source';
  }

  @override
  String get setupDebugTimeline => 'Timeline';

  @override
  String get setupDebugTimeline2 => 'Timeline';

  @override
  String get setupDebugTitle => 'Focused on OpenCode setup';

  @override
  String get setupDebugWSL => 'WSL';

  @override
  String get setupDebugWsl => 'WSL';

  @override
  String get shortcutsApply => 'Apply';

  @override
  String shortcutsConflictConflict(String conflict) {
    return 'Конфликт с $conflict';
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
    return 'Установить сочетание клавиш: $label';
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
  String get terminalClose => 'Close terminal';

  @override
  String get terminalMinimize => 'Minimize terminal';

  @override
  String get terminalReconnect => 'Reconnect terminal';

  @override
  String get terminalTerminal => 'Terminal';

  @override
  String get terminalTryAgain => 'Try again';

  @override
  String get toolAwaitingInput => 'Awaiting input';

  @override
  String get toolEditing => 'Editing';

  @override
  String get toolEditingFiles => 'Editing files';

  @override
  String get toolFinding => 'Finding';

  @override
  String get toolFindingFiles => 'Finding files';

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
  String get toolReading => 'Reading';

  @override
  String get toolReadingFile => 'Reading file';

  @override
  String get toolRunning => 'Running';

  @override
  String get toolRunningCommand => 'Running command';

  @override
  String get toolRunningTask => 'Running task';

  @override
  String get toolSearching => 'Searching';

  @override
  String get toolSearchingCode => 'Searching code';

  @override
  String get toolSearchingWeb => 'Searching the web';

  @override
  String get toolUpdatingTaskList => 'Updating task list';

  @override
  String get toolUpdatingTasks => 'Updating tasks';

  @override
  String get toolWaitingForInput => 'Waiting for your input';

  @override
  String get toolWriting => 'Writing';

  @override
  String get toolWritingFile => 'Writing file';

  @override
  String get tourBack => 'Back';

  @override
  String get tourSkip => 'Skip';

  @override
  String get trayQuit => 'Quit';

  @override
  String get trayShow => 'Show';

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
  String get workspaceBrowseDirs => 'Browse directories';

  @override
  String get workspaceChooseFolderOpen =>
      'Choose any folder to open as project context.';

  @override
  String workspaceCloseProject(String project) {
    return 'Close $project';
  }

  @override
  String get workspaceFilterDirs => 'Filter directories';

  @override
  String get workspaceOpenFolder => 'Open folder';

  @override
  String get workspaceOpenProjectFolder => 'Open project folder';

  @override
  String get workspaceProjectDirectory => 'Project directory';

  @override
  String get workspaceProjectHint => '/repo/my-project';

  @override
  String workspaceRemoveFromHistory(String name) {
    return 'Remove $name from history';
  }

  @override
  String get workspaceSuggestions => 'Suggestions';

  @override
  String get onboardingSetup => 'Настройка';

  @override
  String get onboardingSetupWizard => 'Мастер настройки';

  @override
  String get onboardingServerSetup => 'Настройка сервера';

  @override
  String get onboardingEditServer => 'Редактировать сервер';

  @override
  String get onboardingLocalServerSetup => 'Настройка локального сервера';

  @override
  String get onboardingReady => 'Готов';

  @override
  String onboardingWelcomeTo(String appName) {
    return 'Добро пожаловать в $appName';
  }

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName необходим сервер OpenCode, прежде чем он сможет помочь с вашим кодом.';
  }

  @override
  String get onboardingChooseHowToSetup => 'Выберите способ настройки сервера';

  @override
  String get onboardingPickSetupPath =>
      'Выберите путь настройки, соответствующий вашей текущей конфигурации OpenCode.';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'Только для компьютеров: $appName может диагностировать, установить и запустить OpenCode для вас.';
  }

  @override
  String get onboardingAvailableOnlyDesktop =>
      'Доступно только на компьютере (Linux/macOS/Windows).';

  @override
  String get onboardingServerConnection => 'Соединение с сервером';

  @override
  String get onboardingEditServerConnection =>
      'Редактировать соединение с сервером';

  @override
  String onboardingSuggestedUrl(String url) {
    return 'Рекомендуемый URL локального сервера OpenCode: $url';
  }

  @override
  String get onboardingEmulatorRemap =>
      'В эмуляторе Android localhost и 127.0.0.1 автоматически перенаправляются на 10.0.2.2.';

  @override
  String get onboardingBasicAuthTip =>
      'Включайте базовую аутентификацию только если ваш сервер OpenCode защищен паролем.';

  @override
  String get onboardingEnterServerUrl => 'Введите URL сервера';

  @override
  String get onboardingInvalidUrl => 'Неверный URL';

  @override
  String get onboardingTesting => 'Тестирование...';

  @override
  String get onboardingSaveAndTest => 'Сохранить и протестировать';

  @override
  String get onboardingTestConnection => 'Проверить соединение';

  @override
  String get onboardingTailscaleLoginRequired => 'Требуется вход в Tailscale';

  @override
  String get onboardingTailscaleAdminApproval =>
      'Требуется одобрение администратора Tailscale';

  @override
  String get onboardingTailscaleConnected => 'Tailscale подключен';

  @override
  String get onboardingTailscaleConnecting => 'Подключение Tailscale';

  @override
  String get onboardingTailscaleConnectionFailed =>
      'Ошибка подключения Tailscale';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale не поддерживается';

  @override
  String get onboardingTailscaleAuthAfterSave =>
      'Аутентификация Tailscale произойдет после сохранения';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'Откройте URL для входа, чтобы добавить это устройство в вашу сеть tailnet. Если браузер не открылся, скопируйте URL ниже.';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'После того как вы сохраните и протестируете этот сервер, $appName откроет страницу входа Tailscale, если это устройство еще не аутентифицировано.';
  }

  @override
  String get onboardingStarting => 'Запуск';

  @override
  String get onboardingStopping => 'Остановка';

  @override
  String get onboardingFailed => 'Ошибка';

  @override
  String get onboardingStopped => 'Остановлен';

  @override
  String get onboardingUsingDetectedCommand =>
      'Использование обнаруженной команды OpenCode.';

  @override
  String get onboardingContinue => 'Продолжить';

  @override
  String get onboardingDone => 'Готово';

  @override
  String get onboardingYoureAllSet => 'Все готово!';

  @override
  String get onboardingServerUpdated => 'Сервер обновлен';

  @override
  String get onboardingServerConnectedReady =>
      'Ваш сервер подключен и готов к использованию.';

  @override
  String get onboardingServerSettingsSaved =>
      'Настройки сервера сохранены, проверки работоспособности обновлены.';

  @override
  String onboardingStartUsing(String appName) {
    return 'Начать использование $appName';
  }

  @override
  String get onboardingCouldNotVerify =>
      'Не удалось проверить соединение с сервером.';

  @override
  String get onboardingCloudflareAuthFailed =>
      'Ошибка аутентификации Cloudflare Access.';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'Проверка работоспособности сервера не удалась. Возможно, он все еще запускается.';

  @override
  String get onboardingConnectionUpdated =>
      'Соединение с сервером успешно обновлено.';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'Сервер добавлен, но проверка работоспособности не удалась. Возможно, он все еще запускается.';

  @override
  String get onboardingConnectionSaved =>
      'Соединение с сервером успешно сохранено.';

  @override
  String get onboardingAvailable => 'доступно';

  @override
  String get onboardingNotAvailable => 'недоступно';

  @override
  String get onboardingReachable => 'доступен';

  @override
  String get onboardingUnreachable => 'недоступен';

  @override
  String get onboardingWritable => 'доступен для записи';

  @override
  String get onboardingNotWritable => 'нет прав на запись';

  @override
  String toolPresentationRunningTool(String toolName) {
    return 'Выполнение $toolName';
  }

  @override
  String get toolPresentationTool => 'Инструмент';

  @override
  String get shortcutGroupSession => 'Сессия';

  @override
  String get shortcutGroupGeneral => 'Общие';

  @override
  String get shortcutGroupPrompt => 'Промпт';

  @override
  String get shortcutGroupNavigation => 'Навигация';

  @override
  String get shortcutGroupModelAndAgent => 'Модель и агент';

  @override
  String get shortcutGroupApplication => 'Приложение';

  @override
  String get shortcutNewConversation => 'Новая беседа';

  @override
  String get shortcutNewConversationDesc => 'Создать новую сессию чата';

  @override
  String get shortcutRefreshData => 'Обновить данные';

  @override
  String get shortcutRefreshDataDesc => 'Обновить данные текущего чата';

  @override
  String get shortcutFocusInput => 'Фокус на вводе';

  @override
  String get shortcutFocusInputDesc => 'Переместить фокус на поле ввода текста';

  @override
  String get shortcutToggleVoiceInput => 'Переключить голосовой ввод';

  @override
  String get shortcutToggleVoiceInputDesc =>
      'Начать или остановить голосовой ввод в редакторе';

  @override
  String get shortcutQuickOpenFiles => 'Быстрое открытие файлов';

  @override
  String get shortcutQuickOpenFilesDesc => 'Открыть быстрый поиск файлов';

  @override
  String get shortcutOpenSettings => 'Открыть настройки';

  @override
  String get shortcutOpenSettingsDesc => 'Открыть страницу настроек';

  @override
  String get shortcutNextRecentModel => 'Следующая недавняя модель';

  @override
  String get shortcutNextRecentModelDesc =>
      'Переключиться на следующую из недавно использованных моделей';

  @override
  String get shortcutNextVariant => 'Следующий вариант';

  @override
  String get shortcutNextVariantDesc =>
      'Переключиться на следующий доступный вариант модели';

  @override
  String get shortcutFocusCloseDrawer => 'Фокус/закрыть панель';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'Фокус на вводе по умолчанию или закрыть панель, если она открыта';

  @override
  String get shortcutNextAgent => 'Следующий агент';

  @override
  String get shortcutNextAgentDesc =>
      'Переключиться на следующего доступного агента';

  @override
  String get shortcutPreviousAgent => 'Предыдущий агент';

  @override
  String get shortcutPreviousAgentDesc =>
      'Переключиться на предыдущего доступного агента';

  @override
  String get shortcutCloseApp => 'Закрыть приложение';

  @override
  String get shortcutCloseAppDesc =>
      'Закрыть приложение, используя стандартное поведение платформы';

  @override
  String get shortcutQuitApp => 'Выйти из приложения';

  @override
  String get shortcutQuitAppDesc => 'Принудительно завершить работу приложения';

  @override
  String get shortcutStopResponse => 'Остановить ответ';

  @override
  String get shortcutStopResponseDesc =>
      'Остановить активный ответ (во время генерации)';

  @override
  String get errorConnectionFailed => 'Ошибка подключения';

  @override
  String get errorConnectionFailedDesc =>
      'Не удалось связаться с сервером. Проверьте соединение и статус сервера.';

  @override
  String get errorQuotaExceeded => 'Квота превышена';

  @override
  String get errorQuotaExceededDesc =>
      'Квота превышена. Проверьте ваш тарифный план или баланс.';

  @override
  String get errorRateLimitExceeded => 'Превышен лимит запросов';

  @override
  String get errorRateLimitExceededDesc =>
      'Превышен лимит запросов. Подождите немного и попробуйте снова.';

  @override
  String get errorAuthRequired => 'Требуется аутентификация';

  @override
  String get errorAuthRequiredDesc =>
      'Ошибка аутентификации. Переподключите провайдера и попробуйте снова.';

  @override
  String get errorServiceUnavailable => 'Сервис недоступен';

  @override
  String get errorServiceUnavailableDesc =>
      'Сервис временно недоступен. Сервер может находиться в процессе запуска — пожалуйста, попробуйте позже.';

  @override
  String get errorProviderUnavailable => 'Провайдер недоступен';

  @override
  String get errorProviderUnavailableDesc =>
      'Провайдер временно недоступен. Попробуйте позже.';

  @override
  String get errorServerError => 'Ошибка сервера';

  @override
  String get errorServerErrorDesc =>
      'Ошибка сервера. Пожалуйста, попробуйте еще раз.';

  @override
  String get attachmentNotAvailableOnPlatform =>
      'Действия с вложениями недоступны на этой платформе.';

  @override
  String get attachmentUnableToOpenLink =>
      'Не удалось открыть ссылку на вложение.';

  @override
  String get attachmentNoValidLocation =>
      'Вложение не предоставляет допустимое местоположение.';

  @override
  String get attachmentDownloadStarted => 'Загрузка вложения началась.';

  @override
  String get attachmentCouldNotDownload => 'Не удалось скачать вложение.';

  @override
  String get attachmentCouldNotDecode =>
      'Не удалось декодировать данные вложения.';

  @override
  String get attachmentPayloadEmpty => 'Данные вложения пусты.';

  @override
  String attachmentSavedAndOpened(String path) {
    return 'Вложение сохранено в $path и открыто.';
  }

  @override
  String attachmentSavedTo(String path) {
    return 'Вложение сохранено в $path.';
  }

  @override
  String get attachmentCouldNotSave =>
      'Не удалось сохранить вложение на этом устройстве.';

  @override
  String get attachmentSaveCanceled => 'Сохранение отменено.';

  @override
  String attachmentSavedPath(String path) {
    return 'Вложение сохранено в $path.';
  }

  @override
  String get attachmentPathEmpty => 'Путь к вложению пуст.';

  @override
  String get attachmentLocalNotFound =>
      'Локальное вложение не найдено на этом устройстве.';

  @override
  String get attachmentUnableToOpenLocal =>
      'Не удалось открыть локальное вложение.';

  @override
  String speechDesktopOnly(String service) {
    return '$service доступен только на компьютере.';
  }

  @override
  String speechRuntimeFailed(String service) {
    return 'Не удалось инициализировать среду выполнения $service.';
  }

  @override
  String speechModelFilesIncomplete(String service) {
    return 'Файлы модели $service неполные.';
  }

  @override
  String get speechMicPermissionDisabled =>
      'Разрешение на использование микрофона отключено.';

  @override
  String speechUnavailableOnPlatform(String service) {
    return 'Голосовой ввод $service недоступен на этой платформе.';
  }

  @override
  String get terminalOpenToConnect =>
      'Откройте Терминал, чтобы подключиться к терминалу проекта сервера.';

  @override
  String get terminalNotAvailableYet =>
      'Встроенный терминал пока не доступен в этой среде выполнения.';

  @override
  String get terminalSelectServer =>
      'Выберите активный сервер перед открытием Терминала.';

  @override
  String get terminalOpenProjectFirst =>
      'Откройте папку проекта перед запуском терминала сервера.';

  @override
  String terminalConnectingTo(String serverName) {
    return 'Подключение к терминалу $serverName...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'Ошибка подключения к терминалу: $error';
  }

  @override
  String get terminalDisconnected => 'Терминал отключен.';

  @override
  String get terminalSessionClosed => 'Сессия терминала закрыта.';

  @override
  String get notificationConversationUpdates => 'Обновления беседы';

  @override
  String get notificationOpenToClear =>
      'Откройте эту беседу, чтобы очистить связанные уведомления.';

  @override
  String get notificationAgentFinished => 'Агент завершил текущий ответ.';

  @override
  String get notificationSession => 'Сессия';

  @override
  String get chatBadgeServerNeedsAttention =>
      'Соединение с сервером требует внимания.';

  @override
  String chatBadgeConversationError(String title) {
    return 'В «$title» ошибка.';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '«$title» ожидает вашего ввода.';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return 'В «$title» новый ответ.';
  }

  @override
  String get chatBadgeSyncing => 'Синхронизация бесед...';

  @override
  String get chatBadgeDataSaverActive =>
      'Экономия мобильного трафика включена.';

  @override
  String get chatCollapseGroup => 'Свернуть группу';

  @override
  String get chatExpandGroup => 'Развернуть группу';

  @override
  String get chatForkFailed => 'Не удалось разветвить беседу';

  @override
  String get chatForked => 'Беседа разветвлена';

  @override
  String get chatNoConversationsInProject => 'В этом проекте нет бесед.';

  @override
  String get chatOpenProjectToLoad =>
      'Откройте проект, чтобы загрузить беседы.';

  @override
  String get chatExportCanceled => 'Экспорт сессии отменен';

  @override
  String get chatLargeContentSkipped =>
      'Слишком большой или некорректный контент был пропущен для стабильности.';

  @override
  String chatTokensLabel(int total) {
    return 'Токены: $total';
  }

  @override
  String chatCostLabel(String cost) {
    return 'Стоимость: \$$cost';
  }

  @override
  String get chatFileExplorerNames => 'Имена';

  @override
  String get chatFileExplorerContents => 'Содержимое';

  @override
  String chatCloseProject(String project) {
    return 'Закрыть $project';
  }

  @override
  String get sessionExportUser => 'Пользователь';

  @override
  String get sessionExportAssistant => 'Ассистент';

  @override
  String get sessionExportInput => 'Ввод:';

  @override
  String get sessionExportOutput => 'Вывод:';

  @override
  String get sessionExportError => 'Ошибка:';

  @override
  String get sessionExportUntitled => 'Сессия без названия';

  @override
  String get modelLabelTinyEnglish => 'Tiny (английский)';

  @override
  String get modelLabelBaseEnglish => 'Базовая (английский)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 европейских языков)';

  @override
  String get cannedNewQuickReply => 'Новый быстрый ответ';

  @override
  String get settingsSoundPickerNotAvailable =>
      'Выбор системных звуков недоступен на этой платформе.';

  @override
  String get appProviderPrimaryServer => 'Основной сервер';

  @override
  String get appProviderLocalManaged => 'Локальный OpenCode (управляемый)';

  @override
  String get appProviderLocalServerStopped => 'Локальный сервер остановлен.';

  @override
  String get appProviderRunDiagnostics =>
      'Запустите диагностику, чтобы проверить локальные требования OpenCode.';

  @override
  String get appProviderInvalidServerUrl => 'Неверный URL сервера';

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth не поддерживается на этой платформе';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale не поддерживается на этой платформе';

  @override
  String get appProviderProfileNotFound => 'Профиль сервера не найден';

  @override
  String get appProviderCannotActivateUnhealthy =>
      'Невозможно активировать неисправный сервер';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode обнаружен';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode не обнаружен';

  @override
  String get appProviderDetectingCommand => 'Обнаружение команды OpenCode...';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'Команда OpenCode не обнаружена. Если вы только что установили ее, обновите проверки или перезапустите $appName, чтобы обновить PATH.';
  }

  @override
  String get appProviderNotDetectedInstall =>
      'Команда OpenCode не обнаружена. Запустите установку из мастера настройки.';

  @override
  String appProviderUsingCommandAt(String path) {
    return 'Использование команды OpenCode по пути $path';
  }

  @override
  String get appProviderDesktopOnly =>
      'Управляемый локальный сервер доступен только на компьютере.';

  @override
  String get appProviderInstallingRequirements =>
      'Установка требований OpenCode...';

  @override
  String get appProviderInstallationFailed => 'Установка OpenCode не удалась.';

  @override
  String get appProviderInstalledSuccessfully =>
      'Требования OpenCode успешно установлены.';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'Установка прошла успешно. Команда OpenCode доступна по пути $path.';
  }

  @override
  String get appProviderInstallSucceeded => 'Установка прошла успешно.';

  @override
  String get appProviderStartingLocalServer => 'Запуск локального сервера...';

  @override
  String get appProviderFailedToStart =>
      'Не удалось запустить локальный сервер OpenCode.';

  @override
  String appProviderRunningAt(String url) {
    return 'Запущен на $url';
  }

  @override
  String get appProviderStoppingLocalServer =>
      'Остановка локального сервера...';

  @override
  String appProviderExitedWithCode(int code) {
    return 'Локальный сервер завершил работу с кодом $code.';
  }

  @override
  String get appProviderInstallBinary => 'Установить бинарный файл';

  @override
  String get appProviderInstallViaNpm => 'Установить через npm';

  @override
  String get appProviderInstallViaBun => 'Установить через Bun';

  @override
  String get appProviderInstallBunOpenCode => 'Установить Bun + OpenCode';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'Tailscale не поддерживается на этой платформе.';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'Tailscale не поддерживается на Windows.';

  @override
  String get tailscaleWaitingAdminApproval =>
      'Этот узел Tailscale ожидает одобрения администратора.';

  @override
  String get notificationSoundLoadFailed =>
      'Не удалось загрузить системные звуки Android';

  @override
  String get chatDescriptionNewConversation => 'Новая беседа';

  @override
  String get chatDescriptionRefreshData => 'Обновить данные чата';

  @override
  String get chatDescriptionFocusInput => 'Фокус на поле ввода сообщения';

  @override
  String get chatDescriptionVoiceInput =>
      'Начать или остановить голосовой ввод';

  @override
  String get chatDescriptionQuickOpen => 'Быстрое открытие файлов';

  @override
  String get chatDescriptionOpenSettings => 'Открыть настройки';

  @override
  String get chatDescriptionCycleModels => 'Переключить недавние модели';

  @override
  String get chatDescriptionCycleVariant => 'Переключить вариант модели';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      'Фокус на вводе (или закрыть панель, если открыта)';

  @override
  String get chatDescriptionNextAgent => 'Следующий агент';

  @override
  String get chatDescriptionPreviousAgent => 'Предыдущий агент';

  @override
  String get chatDescriptionCloseApp =>
      'Закрыть приложение, используя стандартное поведение платформы';

  @override
  String get chatDescriptionForceExit => 'Принудительный выход из приложения';

  @override
  String get chatDescriptionStopResponse =>
      'Остановить активный ответ (во время генерации)';

  @override
  String get chatDescriptionProjectCommand => 'Команда проекта';

  @override
  String get chatDescriptionOpenProjects =>
      'Используйте эту кнопку, чтобы открыть ваши проекты и беседы.';

  @override
  String get chatDescriptionSwitchProject =>
      'Используйте эту кнопку, чтобы переключить папки проекта и контекст.';

  @override
  String chatDescriptionChildren(int count) {
    return 'Дочерние элементы: $count';
  }

  @override
  String get chatDescriptionDiffFilesZero => 'Файлов diff: 0';

  @override
  String get appProviderErrorInvalidServerUrl => 'Неверный URL сервера';

  @override
  String get appProviderErrorServerUrlRequired => 'URL сервера обязателен';

  @override
  String get appProviderErrorServerAlreadyExists =>
      'Сервер с таким URL уже существует';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth не поддерживается на этой платформе';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale не поддерживается на этой платформе';

  @override
  String get appProviderErrorServerProfileNotFound =>
      'Профиль сервера не найден';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      'Невозможно активировать неисправный сервер';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      'Управляемый локальный сервер доступен только на компьютере.';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'Локальный сервер запущен, но проверка работоспособности не пройдена.';

  @override
  String get appProviderErrorInstallationFailed =>
      'Установка OpenCode не удалась.';

  @override
  String get appProviderStatusLocalServerStopped =>
      'Локальный сервер остановлен.';

  @override
  String get appProviderStatusStartingLocalServer =>
      'Запуск локального сервера...';

  @override
  String appProviderStatusRunningAt(String url) {
    return 'Запущен на $url';
  }

  @override
  String get appProviderStatusStoppingLocalServer =>
      'Остановка локального сервера...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'Локальный сервер завершил работу с кодом $code.';
  }

  @override
  String get appProviderSetupDetectingOpenCode =>
      'Обнаружение команды OpenCode...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode обнаружен';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode не обнаружен';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return 'Использование команды OpenCode по пути $path';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'Установка требований OpenCode...';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'Требования OpenCode успешно установлены.';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'Установка прошла успешно. Команда OpenCode доступна по пути $path.';
  }

  @override
  String get appProviderSetupInstallationSucceeded =>
      'Установка прошла успешно.';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'Команда OpenCode не обнаружена. Если вы только что установили ее, обновите проверки или перезапустите CodeWalk, чтобы обновить PATH.';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'Команда OpenCode не обнаружена. Запустите установку из мастера настройки.';

  @override
  String get appProviderLabelPrimaryServer => 'Основной сервер';

  @override
  String get appProviderLabelLocalOpenCodeManaged =>
      'Локальный OpenCode (управляемый)';
}
