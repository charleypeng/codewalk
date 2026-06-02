// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appShellDownloadingUpdate => 'Download aggiornamento in corso';

  @override
  String get appShellInstall => 'Installa';

  @override
  String get appShellInstallFailed => 'Installazione non riuscita';

  @override
  String get appShellInstallingUpdate => 'Installazione aggiornamento...';

  @override
  String get appShellRestart => 'Riavvia';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return 'Aggiornamento disponibile: v$latestVersion';
  }

  @override
  String get behaviorAdvancedPermissionRule =>
      'Regola di autorizzazione avanzata';

  @override
  String get behaviorAutomatic => 'Automatico';

  @override
  String get behaviorAutomaticFallback => 'Fallback automatico';

  @override
  String get behaviorCellularDataSaver => 'Risparmio dati mobili';

  @override
  String get behaviorChatLevelShare => 'Condivisione a livello chat';

  @override
  String get behaviorCodeWalkReleaseChecks => 'Controlli versione CodeWalk';

  @override
  String get behaviorControlsOfficialGlobal =>
      'Controlla le impostazioni globali ufficiali di OpenCode';

  @override
  String get behaviorControlsUpstreamOpenCode =>
      'Controlla le impostazioni OpenCode upstream';

  @override
  String get behaviorCustomDisplayName => 'Nome visualizzato personalizzato';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return 'Riduce l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'utilizzo automatico dei dati mobili fermando i download in background e limitando gli aggiornamenti automatici in primo piano a un burst ogni $inSeconds secondi.';
  }

  @override
  String get behaviorDisabled => 'Disabilitato';

  @override
  String get behaviorLightweightTasksLike => 'Attività leggere come';

  @override
  String get behaviorManual => 'Manuale';

  @override
  String get behaviorNotify => 'Notifica';

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
    return 'Figli: $length';
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
  String get chatDoubleESCStop => 'Doppio ESC per interrompere';

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
    return '$messageCount messaggi nascosti prima della compressione $compactionLabel';
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
  String get chatMessageHide => 'Nascondi';

  @override
  String get chatMessageMessagePartUnavailable => 'Message part unavailable';

  @override
  String get chatMessageMetadataAvailable => 'No metadata available';

  @override
  String chatMessageModelMessageModelId(String modelId) {
    return 'Modello: $modelId';
  }

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return 'Provider: $providerId';
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
  String get chatOpenProject => 'Apri progetto';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenSidebar => 'Apri barra laterale';

  @override
  String get chatPageStatusContextUsage => 'Utilizzo del contesto';

  @override
  String get chatPageStatusCost => 'Costo';

  @override
  String get chatPageStatusLimit => 'Limite';

  @override
  String get chatPageStatusManageServers => 'Gestisci server';

  @override
  String get chatPageStatusSaver => 'Risparmio';

  @override
  String get chatPageStatusSwitchServer => 'Cambia server';

  @override
  String get chatPageStatusTokens => 'Token';

  @override
  String get chatPageStatusUsage => 'Utilizzo';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatProjectContext => 'Project Context';

  @override
  String get chatProjectContext2 => 'Contesto del progetto';

  @override
  String get chatRealtimeGlobalEvent => 'evento globale';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return 'evento globale ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale =>
      'evento globale (generazione non aggiornata)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return 'flusso di messaggi ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => 'evento in tempo reale';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return 'evento in tempo reale ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale =>
      'evento in tempo reale (generazione non aggiornata)';

  @override
  String get chatRealtimeReconnectingServerTry =>
      'Riconnessione al server. Riprovare tra un momento.';

  @override
  String get chatReasoning => 'Ragionamento...';

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
    return 'Rimuovi $displayName dalla cronologia';
  }

  @override
  String get chatRetry => 'Retry';

  @override
  String get chatRetry2 => 'Retry';

  @override
  String get chatRetryRefresh => 'Retry refresh';

  @override
  String get chatRetryingModelRequest => 'Retrying model request...';

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
    return 'Sessione di chat: $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return 'Conversazione $nextAction';
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
  String get chatSidebarAccess => 'Accesso barra laterale';

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
    return 'Sincronizzazione: $label';
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
    return 'Allegato salvato in $path e aperto.';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return 'Allegato salvato in $path.';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return 'Allegato salvato in $savedPath.';
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
    return 'File aperti ($length)';
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
    return 'Visualizzazione di $length di $length2 voci';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => 'Matematica';

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
    return 'Sottoattività ($agent)';
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
    return 'Selezionato: $soundLabel';
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
    return '$length righe di log di configurazione e $length2 eventi di configurazione sono disponibili nella schermata di debug di configurazione separata.';
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
  String get onboardingDonShowAgain =>
      'Don\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'t show again';

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
    return 'Ultimo output: $localServerLastOutput';
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
      'Esegui la diagnostica per verificare i requisiti locali di OpenCode.';

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
      'Uses your server\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'s title agent to name conversations';

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
    return 'Rimuovere \"$displayName\"?';
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
  String get sessionCopyLink => 'Copia link';

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
  String get settingsAboutUpToDate =>
      'You\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'re up to date';

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
  String get settingsAppearanceMathRendering => 'Rendering matematico';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      'Mostra espressioni matematiche LaTeX come equazioni composte nei messaggi di chat.';

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
      'Use the chat-level share action to publish one session now. This setting only changes OpenCode\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'s default sharing policy.';

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
    return 'Conflitto con $conflict';
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
    return 'Imposta scorciatoia: $label';
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
  String get onboardingSetup => 'Configurazione';

  @override
  String get onboardingSetupWizard => 'Configurazione guidata';

  @override
  String get onboardingServerSetup => 'Configurazione server';

  @override
  String get onboardingEditServer => 'Modifica server';

  @override
  String get onboardingLocalServerSetup => 'Configurazione server locale';

  @override
  String get onboardingReady => 'Pronto';

  @override
  String onboardingWelcomeTo(String appName) {
    return 'Benvenuto in $appName';
  }

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName ha bisogno di un server OpenCode prima di poter aiutare con il tuo codice.';
  }

  @override
  String get onboardingChooseHowToSetup =>
      'Scegli come configurare il tuo server';

  @override
  String get onboardingPickSetupPath =>
      'Scegli il percorso di configurazione che corrisponde alla tua attuale installazione di OpenCode.';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'Solo desktop: $appName può diagnosticare, installare ed eseguire OpenCode per te.';
  }

  @override
  String get onboardingAvailableOnlyDesktop =>
      'Disponibile solo su desktop (Linux/macOS/Windows).';

  @override
  String get onboardingServerConnection => 'Connessione server';

  @override
  String get onboardingEditServerConnection => 'Modifica connessione server';

  @override
  String onboardingSuggestedUrl(String url) {
    return 'URL del server OpenCode locale suggerito: $url';
  }

  @override
  String get onboardingEmulatorRemap =>
      'Sull\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'emulatore Android, localhost e 127.0.0.1 vengono rimappati automaticamente su 10.0.2.2.';

  @override
  String get onboardingBasicAuthTip =>
      'Abilita lautenticazione di base solo se il tuo server OpenCode è protetto da password.';

  @override
  String get onboardingEnterServerUrl =>
      'Inserisci l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'URL del server';

  @override
  String get onboardingInvalidUrl => 'URL non valido';

  @override
  String get onboardingTesting => 'Test in corso...';

  @override
  String get onboardingSaveAndTest => 'Salva e testa';

  @override
  String get onboardingTestConnection => 'Testa connessione';

  @override
  String get onboardingTailscaleLoginRequired => 'Accesso Tailscale richiesto';

  @override
  String get onboardingTailscaleAdminApproval =>
      'Approvazione amministratore Tailscale richiesta';

  @override
  String get onboardingTailscaleConnected => 'Tailscale connesso';

  @override
  String get onboardingTailscaleConnecting => 'Connessione Tailscale in corso';

  @override
  String get onboardingTailscaleConnectionFailed =>
      'Connessione Tailscale fallita';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale non supportato';

  @override
  String get onboardingTailscaleAuthAfterSave =>
      'Tailscale si autenticherà dopo il salvataggio';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'Apri l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'URL di login per aggiungere questo dispositivo alla tua tailnet. Se il browser non si è aperto, copia l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'URL qui sotto.';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'Dopo aver salvato e testato questo server, $appName aprirà il login di Tailscale se questo dispositivo non è ancora autenticato.';
  }

  @override
  String get onboardingStarting => 'Avvio';

  @override
  String get onboardingStopping => 'Arresto';

  @override
  String get onboardingFailed => 'Fallito';

  @override
  String get onboardingStopped => 'Fermato';

  @override
  String get onboardingUsingDetectedCommand =>
      'Utilizzo del comando OpenCode rilevato.';

  @override
  String get onboardingContinue => 'Continua';

  @override
  String get onboardingDone => 'Fatto';

  @override
  String get onboardingYoureAllSet => 'Sei a posto!';

  @override
  String get onboardingServerUpdated => 'Server aggiornato';

  @override
  String get onboardingServerConnectedReady =>
      'Il tuo server è connesso e pronto all\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'uso.';

  @override
  String get onboardingServerSettingsSaved =>
      'Le impostazioni del server sono state salvate e i controlli di integrità sono stati aggiornati.';

  @override
  String onboardingStartUsing(String appName) {
    return 'Inizia a usare $appName';
  }

  @override
  String get onboardingCouldNotVerify =>
      'Impossibile verificare la connessione al server.';

  @override
  String get onboardingCloudflareAuthFailed =>
      'Autenticazione Cloudflare Access fallita.';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'Controllo di integrità del server fallito. Potrebbe essere ancora in fase di avvio.';

  @override
  String get onboardingConnectionUpdated =>
      'Connessione al server aggiornata con successo.';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'Server aggiunto ma il controllo di integrità è fallito. Potrebbe essere ancora in fase di avvio.';

  @override
  String get onboardingConnectionSaved =>
      'Connessione al server salvata con successo.';

  @override
  String get onboardingAvailable => 'disponibile';

  @override
  String get onboardingNotAvailable => 'non disponibile';

  @override
  String get onboardingReachable => 'raggiungibile';

  @override
  String get onboardingUnreachable => 'non raggiungibile';

  @override
  String get onboardingWritable => 'scrivibile';

  @override
  String get onboardingNotWritable => 'non scrivibile';

  @override
  String toolPresentationRunningTool(String toolName) {
    return 'Esecuzione di $toolName';
  }

  @override
  String get toolPresentationTool => 'Strumento';

  @override
  String get shortcutGroupSession => 'Sessione';

  @override
  String get shortcutGroupGeneral => 'Generale';

  @override
  String get shortcutGroupPrompt => 'Prompt';

  @override
  String get shortcutGroupNavigation => 'Navigazione';

  @override
  String get shortcutGroupModelAndAgent => 'Modello e agente';

  @override
  String get shortcutGroupApplication => 'Applicazione';

  @override
  String get shortcutNewConversation => 'Nuova conversazione';

  @override
  String get shortcutNewConversationDesc => 'Crea una nuova sessione di chat';

  @override
  String get shortcutRefreshData => 'Aggiorna dati';

  @override
  String get shortcutRefreshDataDesc => 'Aggiorna i dati della chat corrente';

  @override
  String get shortcutFocusInput => 'Focus sullinput';

  @override
  String get shortcutFocusInputDesc =>
      'Sposta il focus sull\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'input di testo';

  @override
  String get shortcutToggleVoiceInput => 'Attiva/disattiva input vocale';

  @override
  String get shortcutToggleVoiceInputDesc =>
      'Avvia o ferma il dettato vocale nelleditor';

  @override
  String get shortcutQuickOpenFiles => 'Apertura rapida file';

  @override
  String get shortcutQuickOpenFilesDesc => 'Apri la ricerca rapida dei file';

  @override
  String get shortcutOpenSettings => 'Apri impostazioni';

  @override
  String get shortcutOpenSettingsDesc => 'Apri la pagina delle impostazioni';

  @override
  String get shortcutNextRecentModel => 'Prossimo modello recente';

  @override
  String get shortcutNextRecentModelDesc =>
      'Cicla tra i modelli usati recentemente';

  @override
  String get shortcutNextVariant => 'Prossima variante';

  @override
  String get shortcutNextVariantDesc =>
      'Cicla tra le varianti di modello disponibili';

  @override
  String get shortcutFocusCloseDrawer => 'Focus/chiudi pannello';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'Focus sull\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'input per impostazione predefinita, o chiudi il pannello se aperto';

  @override
  String get shortcutNextAgent => 'Prossimo agente';

  @override
  String get shortcutNextAgentDesc => 'Cicla al prossimo agente disponibile';

  @override
  String get shortcutPreviousAgent => 'Agente precedente';

  @override
  String get shortcutPreviousAgentDesc =>
      'Cicla all\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'agente precedente disponibile';

  @override
  String get shortcutCloseApp => 'Chiudi applicazione';

  @override
  String get shortcutCloseAppDesc =>
      'Chiudi l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'app usando il comportamento di chiusura della piattaforma';

  @override
  String get shortcutQuitApp => 'Esci dallapplicazione';

  @override
  String get shortcutQuitAppDesc =>
      'Forza l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'uscita dall\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'app';

  @override
  String get shortcutStopResponse => 'Ferma risposta';

  @override
  String get shortcutStopResponseDesc =>
      'Ferma risposta attiva (durante la risposta)';

  @override
  String get errorConnectionFailed => 'Connessione fallita';

  @override
  String get errorConnectionFailedDesc =>
      'Impossibile raggiungere il server. Controlla la connessione e lo stato del server.';

  @override
  String get errorQuotaExceeded => 'Quota superata';

  @override
  String get errorQuotaExceededDesc =>
      'Quota superata. Controlla il piano del tuo provider o la fatturazione.';

  @override
  String get errorRateLimitExceeded => 'Limite di velocità superato';

  @override
  String get errorRateLimitExceededDesc =>
      'Limite di velocità superato. Attendi un momento e riprova.';

  @override
  String get errorAuthRequired => 'Autenticazione richiesta';

  @override
  String get errorAuthRequiredDesc =>
      'Autenticazione fallita. Riconnetti il provider e riprova.';

  @override
  String get errorServiceUnavailable => 'Servizio non disponibile';

  @override
  String get errorServiceUnavailableDesc =>
      'Servizio temporaneamente non disponibile. Il server potrebbe essere in fase di avvio — riprova tra poco.';

  @override
  String get errorProviderUnavailable => 'Provider non disponibile';

  @override
  String get errorProviderUnavailableDesc =>
      'Provider temporaneamente non disponibile. Riprova tra poco.';

  @override
  String get errorServerError => 'Errore del server';

  @override
  String get errorServerErrorDesc => 'Errore del server. Per favore riprova.';

  @override
  String get attachmentNotAvailableOnPlatform =>
      'Le azioni sugli allegati non sono disponibili su questa piattaforma.';

  @override
  String get attachmentUnableToOpenLink =>
      'Impossibile aprire il link dell\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'allegato.';

  @override
  String get attachmentNoValidLocation =>
      'L\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'allegato non fornisce una posizione valida.';

  @override
  String get attachmentDownloadStarted => 'Download dellallegato iniziato.';

  @override
  String get attachmentCouldNotDownload =>
      'Impossibile scaricare l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'allegato.';

  @override
  String get attachmentCouldNotDecode =>
      'Impossibile decodificare i dati dell\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'allegato.';

  @override
  String get attachmentPayloadEmpty =>
      'Il payload dell\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'allegato è vuoto.';

  @override
  String attachmentSavedAndOpened(String path) {
    return 'Allegato salvato in $path e aperto.';
  }

  @override
  String attachmentSavedTo(String path) {
    return 'Allegato salvato in $path.';
  }

  @override
  String get attachmentCouldNotSave =>
      'Impossibile salvare l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'allegato su questo dispositivo.';

  @override
  String get attachmentSaveCanceled => 'Salvataggio annullato.';

  @override
  String attachmentSavedPath(String path) {
    return 'Allegato salvato in $path.';
  }

  @override
  String get attachmentPathEmpty =>
      'Il percorso dell\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'allegato è vuoto.';

  @override
  String get attachmentLocalNotFound =>
      'Allegato locale non trovato su questo dispositivo.';

  @override
  String get attachmentUnableToOpenLocal =>
      'Impossibile aprire l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'allegato locale.';

  @override
  String speechDesktopOnly(String service) {
    return '$service è disponibile solo su desktop.';
  }

  @override
  String speechRuntimeFailed(String service) {
    return 'Inizializzazione del runtime di $service fallita.';
  }

  @override
  String speechModelFilesIncomplete(String service) {
    return 'I file del modello di $service sono incompleti.';
  }

  @override
  String get speechMicPermissionDisabled =>
      'L\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'autorizzazione del microfono è disabilitata.';

  @override
  String speechUnavailableOnPlatform(String service) {
    return 'Il parlato di $service non è disponibile su questa piattaforma.';
  }

  @override
  String get terminalOpenToConnect =>
      'Apri il Terminale per connetterti al terminale del progetto del server.';

  @override
  String get terminalNotAvailableYet =>
      'Il terminale integrato non è ancora disponibile su questo runtime.';

  @override
  String get terminalSelectServer =>
      'Seleziona un server attivo prima di aprire il Terminale.';

  @override
  String get terminalOpenProjectFirst =>
      'Apri una cartella di progetto prima di avviare il terminale del server.';

  @override
  String terminalConnectingTo(String serverName) {
    return 'Connessione al terminale di $serverName...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'Connessione al terminale fallita: $error';
  }

  @override
  String get terminalDisconnected => 'Terminale scollegato.';

  @override
  String get terminalSessionClosed => 'Sessione terminale chiusa.';

  @override
  String get notificationConversationUpdates =>
      'Aggiornamenti della conversazione';

  @override
  String get notificationOpenToClear =>
      'Apri questa conversazione per cancellare le relative notifiche.';

  @override
  String get notificationAgentFinished =>
      'L\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'agente ha terminato la risposta corrente.';

  @override
  String get notificationSession => 'Sessione';

  @override
  String get chatBadgeServerNeedsAttention =>
      'La connessione al server richiede attenzione.';

  @override
  String chatBadgeConversationError(String title) {
    return '\"$title\" ha un errore.';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '\"$title\" richiede il tuo intervento.';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '\"$title\" ha una nuova risposta.';
  }

  @override
  String get chatBadgeSyncing => 'Sincronizzazione conversazioni...';

  @override
  String get chatBadgeDataSaverActive =>
      'Il risparmio dati cellulare è attivo.';

  @override
  String get chatCollapseGroup => 'Comprimi gruppo';

  @override
  String get chatExpandGroup => 'Espandi gruppo';

  @override
  String get chatForkFailed => 'Biforcazione conversazione fallita';

  @override
  String get chatForked => 'Conversazione biforcata';

  @override
  String get chatNoConversationsInProject =>
      'Nessuna conversazione in questo progetto.';

  @override
  String get chatOpenProjectToLoad =>
      'Apri un progetto per caricare le conversazioni.';

  @override
  String get chatExportCanceled => 'Esportazione sessione annullata';

  @override
  String get chatLargeContentSkipped =>
      'Contenuto grande o malformato saltato per stabilità.';

  @override
  String chatTokensLabel(int total) {
    return 'Token: $total';
  }

  @override
  String chatCostLabel(String cost) {
    return 'Costo: \$$cost';
  }

  @override
  String get chatFileExplorerNames => 'Nomi';

  @override
  String get chatFileExplorerContents => 'Contenuti';

  @override
  String chatCloseProject(String project) {
    return 'Chiudi $project';
  }

  @override
  String get sessionExportUser => 'Utente';

  @override
  String get sessionExportAssistant => 'Assistente';

  @override
  String get sessionExportInput => 'Input:';

  @override
  String get sessionExportOutput => 'Output:';

  @override
  String get sessionExportError => 'Errore:';

  @override
  String get sessionExportUntitled => 'Sessione senza titolo';

  @override
  String get modelLabelTinyEnglish => 'Tiny (Inglese)';

  @override
  String get modelLabelBaseEnglish => 'Base (Inglese)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 lingue europee)';

  @override
  String get cannedNewQuickReply => 'Nuova risposta rapida';

  @override
  String get settingsSoundPickerNotAvailable =>
      'Il selettore dei suoni di sistema non è disponibile su questa piattaforma.';

  @override
  String get appProviderPrimaryServer => 'Server primario';

  @override
  String get appProviderLocalManaged => 'OpenCode locale (gestito)';

  @override
  String get appProviderLocalServerStopped => 'Il server locale è fermo.';

  @override
  String get appProviderRunDiagnostics =>
      'Esegui la diagnostica per verificare i requisiti locali di OpenCode.';

  @override
  String get appProviderInvalidServerUrl => 'URL del server non valido';

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth non è supportato su questa piattaforma';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale non è supportato su questa piattaforma';

  @override
  String get appProviderProfileNotFound => 'Profilo server non trovato';

  @override
  String get appProviderCannotActivateUnhealthy =>
      'Impossibile attivare un server non integro';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode rilevato';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode non rilevato';

  @override
  String get appProviderDetectingCommand => 'Rilevamento comando OpenCode...';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'Comando OpenCode non rilevato. Se lo hai installato poco fa, aggiorna i controlli o riapri $appName per ricaricare il PATH.';
  }

  @override
  String get appProviderNotDetectedInstall =>
      'Comando OpenCode non rilevato. Esegui l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'installazione dal wizard.';

  @override
  String appProviderUsingCommandAt(String path) {
    return 'Utilizzo del comando OpenCode in $path';
  }

  @override
  String get appProviderDesktopOnly =>
      'Il server locale gestito è disponibile solo su desktop.';

  @override
  String get appProviderInstallingRequirements =>
      'Installazione dei requisiti OpenCode...';

  @override
  String get appProviderInstallationFailed =>
      'Installazione di OpenCode fallita.';

  @override
  String get appProviderInstalledSuccessfully =>
      'Requisiti OpenCode installati con successo.';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'Installazione riuscita. Comando OpenCode disponibile in $path.';
  }

  @override
  String get appProviderInstallSucceeded => 'Installazione riuscita.';

  @override
  String get appProviderStartingLocalServer => 'Avvio del server locale...';

  @override
  String get appProviderFailedToStart =>
      'Avvio del server OpenCode locale fallito.';

  @override
  String appProviderRunningAt(String url) {
    return 'In esecuzione su $url';
  }

  @override
  String get appProviderStoppingLocalServer => 'Arresto del server locale...';

  @override
  String appProviderExitedWithCode(int code) {
    return 'Il server locale è uscito con il codice $code.';
  }

  @override
  String get appProviderInstallBinary => 'Installa binario';

  @override
  String get appProviderInstallViaNpm => 'Installa tramite npm';

  @override
  String get appProviderInstallViaBun => 'Installa tramite Bun';

  @override
  String get appProviderInstallBunOpenCode => 'Installa Bun + OpenCode';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'Tailscale non è supportato su questa piattaforma.';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'Tailscale non è supportato su Windows.';

  @override
  String get tailscaleWaitingAdminApproval =>
      'Questo nodo Tailscale è in attesa dell\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'approvazione dell\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'amministratore.';

  @override
  String get notificationSoundLoadFailed =>
      'Caricamento dei suoni di sistema Android fallito';

  @override
  String get chatDescriptionNewConversation => 'Nuova conversazione';

  @override
  String get chatDescriptionRefreshData => 'Aggiorna dati chat';

  @override
  String get chatDescriptionFocusInput =>
      'Focus sull\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'input del messaggio';

  @override
  String get chatDescriptionVoiceInput => 'Avvia o ferma input vocale';

  @override
  String get chatDescriptionQuickOpen => 'Apertura rapida file';

  @override
  String get chatDescriptionOpenSettings => 'Apri impostazioni';

  @override
  String get chatDescriptionCycleModels => 'Cicla modelli recenti';

  @override
  String get chatDescriptionCycleVariant => 'Cicla variante modello';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      'Focus sull\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'input (o chiudi il pannello se aperto)';

  @override
  String get chatDescriptionNextAgent => 'Prossimo agente';

  @override
  String get chatDescriptionPreviousAgent => 'Agente precedente';

  @override
  String get chatDescriptionCloseApp =>
      'Chiudi l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'app usando il comportamento di chiusura della piattaforma';

  @override
  String get chatDescriptionForceExit =>
      'Forza l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'uscita dall\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'app';

  @override
  String get chatDescriptionStopResponse =>
      'Ferma risposta attiva (durante la risposta)';

  @override
  String get chatDescriptionProjectCommand => 'Comando progetto';

  @override
  String get chatDescriptionOpenProjects =>
      'Usa questo pulsante per aprire i tuoi progetti e conversazioni.';

  @override
  String get chatDescriptionSwitchProject =>
      'Usa questo pulsante per cambiare cartelle di progetto e contesto.';

  @override
  String chatDescriptionChildren(int count) {
    return 'Figli: $count';
  }

  @override
  String get chatDescriptionDiffFilesZero => 'File diff: 0';

  @override
  String get appProviderErrorInvalidServerUrl => 'URL del server non valido';

  @override
  String get appProviderErrorServerUrlRequired =>
      'L\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'URL del server è richiesto';

  @override
  String get appProviderErrorServerAlreadyExists =>
      'Un server con questo URL esiste già';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth non è supportato su questa piattaforma';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale non è supportato su questa piattaforma';

  @override
  String get appProviderErrorServerProfileNotFound =>
      'Profilo server non trovato';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      'Impossibile attivare un server non integro';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      'Il server locale gestito è disponibile solo su desktop.';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'Il server locale è stato avviato ma il controllo di integrità non è passato.';

  @override
  String get appProviderErrorInstallationFailed =>
      'Installazione di OpenCode fallita.';

  @override
  String get appProviderStatusLocalServerStopped => 'Il server locale è fermo.';

  @override
  String get appProviderStatusStartingLocalServer =>
      'Avvio del server locale...';

  @override
  String appProviderStatusRunningAt(String url) {
    return 'In esecuzione su $url';
  }

  @override
  String get appProviderStatusStoppingLocalServer =>
      'Arresto del server locale...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'Il server locale è uscito con il codice $code.';
  }

  @override
  String get appProviderSetupDetectingOpenCode =>
      'Rilevamento comando OpenCode...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode rilevato';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode non rilevato';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return 'Utilizzo del comando OpenCode in $path';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'Installazione dei requisiti OpenCode...';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'Requisiti OpenCode installati con successo.';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'Installazione riuscita. Comando OpenCode disponibile in $path.';
  }

  @override
  String get appProviderSetupInstallationSucceeded => 'Installazione riuscita.';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'Comando OpenCode non rilevato. Se lo hai installato poco fa, aggiorna i controlli o riapri CodeWalk per ricaricare il PATH.';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'Comando OpenCode non rilevato. Esegui l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'installazione dal wizard.';

  @override
  String get appProviderLabelPrimaryServer => 'Server primario';

  @override
  String get appProviderLabelLocalOpenCodeManaged =>
      'OpenCode locale (gestito)';

  @override
  String get chatChooseModel => 'Scegli modello';

  @override
  String get chatStartVoiceInput => 'Avvia input vocale';

  @override
  String get chatStopVoiceInput => 'Ferma input vocale';

  @override
  String get chatStartingVoiceInput => 'Avvio input vocale';

  @override
  String get chatComposerPlaceholder => 'Scrivi le tue esigenze...';

  @override
  String get chatPermissionAutoApproveOn =>
      'Approvazione automatica dei permessi attiva';

  @override
  String get chatPermissionAutoApproveOff =>
      'Approvazione automatica dei permessi disattiva';

  @override
  String get chatModelLockedSubConversation =>
      'Modello bloccato nella sottoconversazione';

  @override
  String get chatComposerHintShell => 'Comando shell (Esc per uscire)';

  @override
  String get utilityTitle => 'Utilità';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusConnected => 'Connesso';

  @override
  String get statusReconnecting => 'Riconnessione';

  @override
  String get statusSyncDelayed => 'Sincronizzazione ritardata';

  @override
  String get statusDelayed => 'Ritardato';

  @override
  String get chatActiveServerUnhealthyLabel => 'Il server attivo non è integro';

  @override
  String get chatWaitingForNetworkConnection =>
      'In attesa di connessione di rete...';

  @override
  String get serverHealthHealthy => 'Integro';

  @override
  String get serverHealthUnhealthy => 'Non integro';

  @override
  String get serverHealthUnknown => 'Sconosciuto';

  @override
  String get sessionUnshare => 'Non condividere più';

  @override
  String get sessionShare => 'Condividi sessione';

  @override
  String get sessionExportMarkdown => 'Esporta Markdown';

  @override
  String get sessionExportDebugJson => 'Esporta JSON di debug';

  @override
  String get sessionViewTasks => 'Vedi attività';

  @override
  String get sessionCompactContext => 'Comprimi contesto';

  @override
  String get sessionUnshared => 'Conversazione non più condivisa';

  @override
  String get sessionShared => 'Conversazione condivisa';

  @override
  String get sessionShareLinkUnavailable =>
      'Link non disponibile per questa sessione';

  @override
  String get sessionExportMarkdownTitle => 'Esporta sessione come Markdown';

  @override
  String get sessionExportDebugJsonTitle =>
      'Esporta sessione come JSON di debug';

  @override
  String get sessionExportCanceled => 'Esportazione annullata';

  @override
  String get sessionExportMarkdownSaved => 'Esportazione Markdown salvata';

  @override
  String get sessionExportDebugJsonSaved =>
      'Esportazione JSON di debug salvata';

  @override
  String get sessionExportMarkdownErrorClipboard =>
      'Impossibile salvare; Markdown copiato negli appunti';

  @override
  String get sessionExportDebugJsonErrorClipboard =>
      'Impossibile salvare; JSON di debug copiato negli appunti';

  @override
  String get terminalHide => 'Nascondi terminale';

  @override
  String get terminalOpen => 'Apri terminale';

  @override
  String get terminalOpenInfo => 'Apri info terminale';

  @override
  String get chatNoSessionSelected => 'Seleziona o crea una conversazione';

  @override
  String get chatWelcomeMessage => 'Ciao! Sono il tuo assistente AI.';

  @override
  String get chatWelcomeSubmessage => 'Come posso aiutarti oggi?';

  @override
  String get cannedAppendAtCursor => 'Aggiungi al cursore';

  @override
  String get cannedReplace => 'Sostituisci';

  @override
  String get chatMessageAttachedFile => 'File allegato';

  @override
  String get chatMessageThinking => 'Sta pensando';

  @override
  String get chatMessageShow => 'Mostra';

  @override
  String get chatMessageMore => 'Altro';

  @override
  String get chatMessageLess => 'Meno';

  @override
  String get chatMessageDetails => 'Dettagli';

  @override
  String get chatMessageToolInput => 'Input';

  @override
  String get chatMessageToolCommand => 'Comando';

  @override
  String chatMessageToolRunningCount(int count) {
    return '$count in esecuzione';
  }

  @override
  String chatMessageToolQueuedCount(int count) {
    return '$count in coda';
  }

  @override
  String get chatMessageToolOutputTruncated =>
      'Anteprima troncata per stabilità.';

  @override
  String get chatMessageToolCommandTruncated => 'Anteprima comando troncata.';

  @override
  String get chatMessageToolInputTruncated => 'Anteprima input troncata.';

  @override
  String get chatMessageToolDiffOmitted =>
      'Anteprima diff omessa: payload troppo grande.';

  @override
  String get terminalTitle => 'Terminale';

  @override
  String get chatCouldNotRefreshSession =>
      'Impossibile aggiornare la conversazione';

  @override
  String get chatMainConversationUnavailable =>
      'Conversazione principale non ancora disponibile.';

  @override
  String get chatFailedToRefreshSubConversations =>
      'Aggiornamento sottoconversazioni fallito. Riprova.';

  @override
  String get chatNoSubConversationFound =>
      'Nessuna sottoconversazione trovata.';

  @override
  String get errorAnErrorOccurred => 'Si è verificato un errore';

  @override
  String get serverConnectionAttention =>
      'La connessione al server richiede attenzione.';

  @override
  String sessionHasError(String title) {
    return '\"$title\" ha un errore.';
  }

  @override
  String sessionNeedsInput(String title) {
    return '\"$title\" richiede il tuo input.';
  }

  @override
  String sessionHasNewReply(String title) {
    return '\"$title\" ha una nuova risposta.';
  }

  @override
  String get sessionSyncing => 'Sincronizzazione conversazioni...';

  @override
  String get behaviorCellularDataSaverActive => 'Il risparmio dati è attivo.';

  @override
  String get sessionNoCachedConversations => 'Nessuna conversazione in cache';

  @override
  String get sessionForkFailed => 'Fork della conversazione fallito';

  @override
  String get sessionForked => 'Conversazione biforcata';

  @override
  String get sessionNoConversationsInProject =>
      'Nessuna conversazione in questo progetto.';

  @override
  String get sessionOpenProjectToLoad =>
      'Apri il progetto per caricare le conversazioni.';

  @override
  String sessionChildrenCount(int count) {
    return 'Sottoconversazioni: $count';
  }

  @override
  String sessionDiffFilesCount(int count) {
    return 'File diff: $count';
  }

  @override
  String get compactionAutomatic => 'automatico';

  @override
  String get compactionManual => 'manuale';

  @override
  String get chatMessageShowLessCompact => 'Meno';

  @override
  String get chatMessageShowLess => 'Mostra meno';

  @override
  String get chatMessageShowMoreCompact => 'Altro';

  @override
  String get chatMessageShowMore => 'Mostra più';

  @override
  String get chatChooseAgent => 'Seleziona agente';

  @override
  String get chatEffortLockedSubConversation =>
      'Impegno bloccato nella sottoconversazione';

  @override
  String get chatChooseEffort => 'Scegli impegno';

  @override
  String get chatServerSelectedModel => 'Modello selezionato dal server';

  @override
  String get chatFailedToRefreshProviders =>
      'Aggiornamento provider e modelli fallito';

  @override
  String get cannedAddTitle => 'Aggiungi risposta rapida';

  @override
  String get cannedEditTitle => 'Modifica risposta rapida';

  @override
  String get cannedTextLabel => 'Testo';

  @override
  String get cannedAppendAtCursorSubtitle =>
      'Off = sostituisce il testo corrente';

  @override
  String get cannedSendAutomaticallySubtitle =>
      'Invia subito dopo l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'inserimento';

  @override
  String get cannedScopeGlobalSubtitle =>
      'Disabilita per elemento solo progetto';

  @override
  String get cannedScopeGlobalUnavailableSubtitle =>
      'Solo progetto non disponibile in questo contesto';

  @override
  String get commonFile => 'File';

  @override
  String get serversSearchActiveHint => 'Cerca server attivo';

  @override
  String get serversNoServersFound => 'Nessun server trovato';

  @override
  String get serversUnhealthyActivateError =>
      'Questo server non è integro. Controlla lo stato o modifica le impostazioni prima di attivarlo.';

  @override
  String get serversTailscaleConnected => 'Tailscale connesso';

  @override
  String get serversTailscaleConnecting => 'Tailscale in connessione';

  @override
  String get serversTailscaleAuthRequired =>
      'Autenticazione Tailscale richiesta';

  @override
  String get serversTailscaleAdminApprovalRequired =>
      'Approvazione amministratore Tailscale richiesta';

  @override
  String get serversTailscaleConnectionFailed =>
      'Connessione Tailscale fallita';

  @override
  String get serversTailscaleUnsupported => 'Tailscale non supportato';

  @override
  String get serversTailscaleDisconnected => 'Tailscale disconnesso';

  @override
  String get serversTailscaleLoginExplanation =>
      'Apri l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'URL di accesso Tailscale per aggiungere questo dispositivo al tuo tailnet.';

  @override
  String get serversTailscaleTrafficExplanation =>
      'Il traffico OpenCode per questo profilo attivo viene instradato attraverso Tailscale.';

  @override
  String get serversTailscaleConnectExplanation =>
      'Tailscale si connetterà quando questo profilo attivo viene utilizzato.';

  @override
  String get statusStarting => 'Avvio';

  @override
  String get statusStopping => 'Arresto';

  @override
  String get statusFailed => 'Fallito';

  @override
  String get statusStopped => 'Fermato';

  @override
  String get serversDesktopModeExplanation =>
      'La modalità desktop può avviare e gestire `opencode serve` direttamente da CodeWalk.';

  @override
  String get serversCannotActivateUnhealthy =>
      'Impossibile attivare un server non integro';

  @override
  String get commonCopiedToClipboard => 'Copiato negli appunti';

  @override
  String get chatUndoNothing => 'Nulla da annullare in questa sessione';

  @override
  String get chatRedoNothing => 'Nulla da ripristinare in questa sessione';

  @override
  String get chatStatusPatching => 'Applicazione patch';

  @override
  String get chatStatusPatchingOneFile => 'Patch di 1 file';

  @override
  String chatStatusPatchingMultipleFiles(int count) {
    return 'Patch di $count file';
  }

  @override
  String get chatStatusThinking => 'Pensando...';

  @override
  String get chatStatusSubsession => 'Sottosessione';

  @override
  String get chatStatusBusy => 'Stato: Occupato';

  @override
  String get chatStatusRetry => 'Stato: Riprova';

  @override
  String chatStatusRetryCount(int count) {
    return 'Stato: Riprova #$count';
  }

  @override
  String get appShellUpdateInstalledRestartRequired =>
      'Aggiornamento installato. È richiesto il riavvio per applicare la nuova versione.';

  @override
  String get appShellUpdateInstalledRestartApp =>
      'Aggiornamento installato. Riavvia l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'app per applicare.';

  @override
  String get chatTourProjectsConversations =>
      'Usa questo pulsante per aprire i tuoi progetti e le tue conversazioni.';

  @override
  String get chatTourSwitchFolders =>
      'Usa questo pulsante per cambiare cartelle di progetto e contesto.';

  @override
  String get chatTourSidebarProjectTools =>
      'Usa questo menu per mostrare la barra laterale delle conversazioni e gli strumenti del progetto.';

  @override
  String get chatActionNext => 'Avanti';

  @override
  String get chatShortcutsNewConversation => 'Nuova conversazione';

  @override
  String get chatShortcutsRefreshChat => 'Aggiorna dati chat';

  @override
  String get chatShortcutsFocusInput => 'Focus inserimento messaggio';

  @override
  String get chatShortcutsStartStopVoice => 'Avvia o ferma input vocale';

  @override
  String get chatShortcutsQuickOpen => 'Apertura rapida file';

  @override
  String get chatShortcutsOpenSettings => 'Apri impostazioni';

  @override
  String get chatShortcutsCycleModels => 'Cicla modelli recenti';

  @override
  String get chatShortcutsCycleVariant => 'Cicla variante modello';

  @override
  String get chatShortcutsFocusInputCloseDrawer =>
      'Focus inserimento (o chiudi cassetto se aperto)';

  @override
  String get chatShortcutsNextAgent => 'Agente successivo';

  @override
  String get chatShortcutsPreviousAgent => 'Agente precedente';

  @override
  String get chatShortcutsCloseApp =>
      'Chiudi app usando il comportamento della piattaforma';

  @override
  String get chatShortcutsForceExit =>
      'Forza l\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'uscita dall\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'app';

  @override
  String get chatShortcutsStopResponse =>
      'Ferma risposta attiva (durante la risposta)';

  @override
  String get chatTipMentionFiles =>
      'Suggerimento: Usa @ per menzionare file nel tuo prompt';

  @override
  String get chatTipRenameConversation =>
      'Suggerimento: Tocca il titolo per rinominare una conversazione';

  @override
  String get chatTipShellCommands =>
      'Suggerimento: Usa ! all\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'inizio per eseguire comandi shell';

  @override
  String get chatTipSlashCommands =>
      'Suggerimento: Usa / per accedere ai comandi slash';

  @override
  String get chatTipLongPressSend =>
      'Suggerimento: Premi a lungo Invia per inserire una nuova riga';

  @override
  String get chatTipContextKnob =>
      'Suggerimento: Tocca la manopola del contesto per vedere i dettagli di utilizzo';

  @override
  String get chatTipBeSpecific =>
      'Suggerimento: Sii specifico — prompt brevi ottengono risposte più veloci';

  @override
  String get chatTipStepByStep =>
      'Suggerimento: Chiedi passo-passo durante il debug di problemi complessi';

  @override
  String get chatTipProvideContext =>
      'Suggerimento: Fornisci contesto — incolla messaggi di errore e log';

  @override
  String get chatTipBreakTasks =>
      'Suggerimento: Dividi compiti grandi in prompt più piccoli';

  @override
  String get chatFailedToLoadDirectories => 'Impossibile caricare le directory';

  @override
  String get logsFilterAll => 'Tutti';

  @override
  String get logsNoLogsYet => 'Nessun log acquisito finora.';

  @override
  String get logsNoMatchingLogs => 'Nessun log corrisponde ai filtri attuali.';

  @override
  String get settingsDefaultModel => 'Modello predefinito';

  @override
  String get settingsSearchDefaultModel => 'Cerca modello predefinito';

  @override
  String get settingsDefaultAgent => 'Agente predefinito';

  @override
  String get settingsSearchDefaultAgent => 'Cerca agente predefinito';

  @override
  String get settingsNoAgentsFound => 'Nessun agente trovato';

  @override
  String get settingsConversationUsername => 'Nome utente conversazione';

  @override
  String get settingsUsernameUnsetExplanation =>
      'OpenCode usa il nome utente di sistema perché `username` non è impostato.';

  @override
  String get settingsUsernameResetExplanation =>
      'Il ripristino di `username` al valore predefinito di sistema richiede comunque la modifica della configurazione all\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'esterno dell\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'app perché gli aggiornamenti patch `/config` non possono rimuovere chiavi.';

  @override
  String get chatHelpMessage =>
      'Usa @ per le menzioni, ! per la shell, / per i comandi';

  @override
  String terminalEmbeddedUnavailable(String serverName) {
    return 'Il terminale integrato non è ancora disponibile su questo runtime. Continua a usare la modalità shell del compositore per comandi singoli o apri il terminale da un runtime dell\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'app CodeWalk supportato per $serverName.';
  }

  @override
  String get chatFailedToLoadFile => 'Impossibile caricare il file';

  @override
  String get chatMentionFileSubtitle => 'file';

  @override
  String get chatMentionSymbolSubtitle => 'simbolo';

  @override
  String get chatMentionAgentSubtitle => 'agente';

  @override
  String get chatCommandSourceGeneric => 'comando';

  @override
  String get chatCommandSourceProject => 'progetto';

  @override
  String get chatCommandDescriptionProject => 'Comando del progetto';

  @override
  String get settingsSmallModel => 'Modello piccolo';

  @override
  String get settingsSearchSmallModel => 'Cerca modello piccolo';

  @override
  String get settingsSmallModelUnsetExplanation =>
      'Il fallback automatico di OpenCode è attivo perché `small_model` non è impostato.';

  @override
  String get settingsSmallModelResetExplanation =>
      'Il ripristino di `small_model` al fallback automatico richiede comunque la modifica della configurazione all\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'esterno dell\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'\'app perché gli aggiornamenti patch `/config` non possono rimuovere chiavi.';

  @override
  String get settingsOpenCodeAutoUpdate => 'Auto-aggiornamento OpenCode';

  @override
  String get settingsSearchAutoUpdateMode =>
      'Cerca modalità auto-aggiornamento';

  @override
  String get settingsOpenCodeSharingDefault =>
      'Predefinito condivisione OpenCode';

  @override
  String get settingsSearchSharingMode => 'Cerca modalità condivisione';

  @override
  String get chatHistoryHideEarlier => 'Hide earlier messages';

  @override
  String get chatHistoryShowEarlier => 'Show earlier messages';

  @override
  String chatHistoryMessagesHidden(int count, String label) {
    return '$count messages hidden before $label compaction';
  }

  @override
  String get chatWorkHide => 'Hide';

  @override
  String get chatWorkExpand => 'Expand';

  @override
  String get chatWorkShow => 'Show';

  @override
  String get chatWorkMessageOne => '1 work message';

  @override
  String chatWorkMessagesMultiple(int count) {
    return '$count work messages';
  }

  @override
  String get chatWorkBoundedPanelExplanation =>
      'Latest tool activity stays inside this bounded panel to keep the chat viewport stable.';

  @override
  String get chatConversation => 'Conversation';

  @override
  String get chatPageStatusContextCompacted => 'Context compacted';

  @override
  String get chatPageStatusFailedToCompactContext =>
      'Failed to compact context';

  @override
  String get chatPageStatusCompactingContextNow => 'Compacting context now...';

  @override
  String get chatPageStatusAutomaticCompactionExplanation =>
      'Automatic compaction happens as context usage grows.';

  @override
  String get chatPageStatusCompacting => 'Compacting...';

  @override
  String get chatPageStatusCompactNow => 'Compact now';

  @override
  String get chatPageStatusServer => 'Server';

  @override
  String get chatMessageSaveFile => 'Save file';

  @override
  String get chatMessageOpenFile => 'Open file';

  @override
  String get chatMessageThinkingProcess => 'Thinking Process';

  @override
  String get chatMessageToolCall => '1 tool call';

  @override
  String chatMessageToolCalls(int count) {
    return '$count tool calls';
  }

  @override
  String get chatMessageRunningTask => 'Running task';

  @override
  String get chatMessageToolStatusQueued => 'Queued';

  @override
  String get chatMessageToolStatusInProgress => 'In progress';

  @override
  String get chatMessageToolStatusNeedsAttention => 'Needs attention';

  @override
  String get terminalRestoreSize => 'Restore size';

  @override
  String get terminalMaximize => 'Maximize';

  @override
  String get behaviorDataSaverActive => 'Active now on mobile data.';

  @override
  String get behaviorDataSaverWaiting =>
      'Waiting for the next mobile-data sync window.';

  @override
  String get behaviorDataSaverCellularOnly =>
      'Only applies when the connection is cellular/mobile.';

  @override
  String get settingsUsernameEnterHint =>
      'Enter a username to save a custom OpenCode conversation name.';

  @override
  String get settingsUsernameClearHint =>
      'Clearing the OpenCode conversation username still requires editing config outside the app.';

  @override
  String get settingsConfigUpdateDeferred =>
      'CodeWalk will apply this OpenCode setting after the current response finishes.';

  @override
  String get settingsConfigRefreshFailed =>
      'Updated the server setting, but could not refresh chat providers.';
}
