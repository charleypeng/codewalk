// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appShellDownloadingUpdate => 'Téléchargement de la mise à jour';

  @override
  String get appShellInstall => 'Installer';

  @override
  String get appShellInstallFailed => 'Échec de l\'installation';

  @override
  String get appShellInstallingUpdate => 'Installation de la mise à jour...';

  @override
  String get appShellRestart => 'Redémarrer';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return 'Mise à jour disponible : v$latestVersion';
  }

  @override
  String get behaviorAdvancedPermissionRule => 'Règle d\'autorisation avancée';

  @override
  String get behaviorAutomatic => 'Automatique';

  @override
  String get behaviorAutomaticFallback => 'Repli automatique';

  @override
  String get behaviorCellularDataSaver => 'Économiseur de données mobiles';

  @override
  String get behaviorChatLevelShare => 'Partage au niveau du chat';

  @override
  String get behaviorCodeWalkReleaseChecks =>
      'Vérifications de version CodeWalk';

  @override
  String get behaviorControlsOfficialGlobal =>
      'Contrôle les paramètres globaux officiels d\'OpenCode';

  @override
  String get behaviorControlsUpstreamOpenCode =>
      'Contrôle les paramètres OpenCode en amont';

  @override
  String get behaviorCustomDisplayName => 'Nom d\'affichage personnalisé';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return 'Réduit l\'utilisation automatique des données mobiles en arrêtant les téléchargements en arrière-plan et en limitant les actualisations automatiques au premier plan à une rafale toutes les $inSeconds secondes.';
  }

  @override
  String get behaviorDisabled => 'Désactivé';

  @override
  String get behaviorLightweightTasksLike => 'Tâches légères comme';

  @override
  String get behaviorManual => 'Manuel';

  @override
  String get behaviorNotify => 'Notifier';

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
    return 'Enfants : $length';
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
  String get chatDoubleESCStop => 'Double Échap pour arrêter';

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
    return '$messageCount messages masqués avant la compression $compactionLabel';
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
    return 'Modèle : $modelId';
  }

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return 'Fournisseur : $providerId';
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
  String get chatOpenProject => 'Ouvrir le projet';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenSidebar => 'Ouvrir la barre latérale';

  @override
  String get chatPageStatusContextUsage => 'Utilisation du contexte';

  @override
  String get chatPageStatusCost => 'Coût';

  @override
  String get chatPageStatusLimit => 'Limite';

  @override
  String get chatPageStatusManageServers => 'Gérer les serveurs';

  @override
  String get chatPageStatusSaver => 'Économiseur';

  @override
  String get chatPageStatusSwitchServer => 'Changer de serveur';

  @override
  String get chatPageStatusTokens => 'Jetons';

  @override
  String get chatPageStatusUsage => 'Utilisation';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatProjectContext => 'Project Context';

  @override
  String get chatProjectContext2 => 'Contexte du projet';

  @override
  String get chatRealtimeGlobalEvent => 'événement global';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return 'événement global ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale =>
      'événement global (génération périmée)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return 'flux de messages ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => 'événement en temps réel';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return 'événement en temps réel ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale =>
      'événement en temps réel (génération périmée)';

  @override
  String get chatRealtimeReconnectingServerTry =>
      'Reconnexion au serveur. Veuillez réessayer dans un instant.';

  @override
  String get chatReasoning => 'Raisonnement...';

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
    return 'Supprimer $displayName de l\'historique';
  }

  @override
  String get chatRetry => 'Retry';

  @override
  String get chatRetry2 => 'Retry';

  @override
  String get chatRetryRefresh => 'Retry refresh';

  @override
  String get chatRetryingModelRequest =>
      'Nouvelle tentative de requête de modèle...';

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
    return 'Session de chat : $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return 'Conversation $nextAction';
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
  String get chatSidebarAccess => 'Accès à la barre latérale';

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
    return 'Synchronisation : $label';
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
    return 'Pièce jointe enregistrée dans $path et ouverte.';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return 'Pièce jointe enregistrée dans $path.';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return 'Pièce jointe enregistrée dans $savedPath.';
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
    return 'Fichiers ouverts ($length)';
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
    return 'Affichage de $length sur $length2 entrées';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => 'Mathématiques';

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
    return 'Sous-tâche ($agent)';
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
    return 'Sélectionné : $soundLabel';
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
    return '$length lignes de journal de configuration et $length2 événements de configuration sont disponibles dans l\'écran de débogage de configuration séparé.';
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
    return 'Dernière sortie : $localServerLastOutput';
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
      'Exécutez les diagnostics pour vérifier les prérequis locaux d\'OpenCode.';

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
    return 'Commande : $localServerCommandPath';
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
    return 'Supprimer \"$displayName\" ?';
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
  String get settingsAppearanceMathRendering => 'Rendu mathématique';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      'Afficher les expressions mathématiques LaTeX sous forme d\'équations composées dans les messages.';

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
    return 'Conflit avec $conflict';
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
    return 'Définir le raccourci : $label';
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
  String get onboardingSetup => 'Configuration';

  @override
  String get onboardingSetupWizard => 'Assistant de configuration';

  @override
  String get onboardingServerSetup => 'Configuration du serveur';

  @override
  String get onboardingEditServer => 'Modifier le serveur';

  @override
  String get onboardingLocalServerSetup => 'Configuration du serveur local';

  @override
  String get onboardingReady => 'Prêt';

  @override
  String onboardingWelcomeTo(String appName) {
    return 'Bienvenue sur $appName';
  }

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName a besoin d\'un serveur OpenCode avant de pouvoir vous aider avec votre code.';
  }

  @override
  String get onboardingChooseHowToSetup =>
      'Choisissez comment configurer votre serveur';

  @override
  String get onboardingPickSetupPath =>
      'Choisissez le chemin de configuration qui correspond à votre installation actuelle d\'OpenCode.';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'Ordinateur uniquement : $appName peut diagnostiquer, installer et exécuter OpenCode pour vous.';
  }

  @override
  String get onboardingAvailableOnlyDesktop =>
      'Disponible uniquement sur ordinateur (Linux/macOS/Windows).';

  @override
  String get onboardingServerConnection => 'Connexion au serveur';

  @override
  String get onboardingEditServerConnection =>
      'Modifier la connexion au serveur';

  @override
  String onboardingSuggestedUrl(String url) {
    return 'URL suggérée pour le serveur OpenCode local : $url';
  }

  @override
  String get onboardingEmulatorRemap =>
      'Sur l\'émulateur Android, localhost et 127.0.0.1 sont automatiquement redirigés vers 10.0.2.2.';

  @override
  String get onboardingBasicAuthTip =>
      'Activez lauthentification de base uniquement si votre serveur OpenCode est protégé par un mot de passe.';

  @override
  String get onboardingEnterServerUrl => 'Entrez l\'URL du serveur';

  @override
  String get onboardingInvalidUrl => 'URL invalide';

  @override
  String get onboardingTesting => 'Test en cours...';

  @override
  String get onboardingSaveAndTest => 'Enregistrer et tester';

  @override
  String get onboardingTestConnection => 'Tester la connexion';

  @override
  String get onboardingTailscaleLoginRequired => 'Connexion Tailscale requise';

  @override
  String get onboardingTailscaleAdminApproval =>
      'Approbation de l\'administrateur Tailscale requise';

  @override
  String get onboardingTailscaleConnected => 'Tailscale connecté';

  @override
  String get onboardingTailscaleConnecting => 'Connexion Tailscale en cours';

  @override
  String get onboardingTailscaleConnectionFailed =>
      'Échec de la connexion Tailscale';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale non supporté';

  @override
  String get onboardingTailscaleAuthAfterSave =>
      'Tailscale s\'authentifiera après l\'enregistrement';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'Ouvrez l\'URL de connexion pour ajouter cet appareil à votre tailnet. Si le navigateur ne s\'est pas ouvert, copiez l\'URL ci-dessous.';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'Après avoir enregistré et testé ce serveur, $appName ouvrira la page de connexion Tailscale si cet appareil nest pas encore authentifié.';
  }

  @override
  String get onboardingStarting => 'Démarrage';

  @override
  String get onboardingStopping => 'Arrêt';

  @override
  String get onboardingFailed => 'Échec';

  @override
  String get onboardingStopped => 'Arrêté';

  @override
  String get onboardingUsingDetectedCommand =>
      'Utilisation de la commande OpenCode détectée.';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get onboardingDone => 'Terminé';

  @override
  String get onboardingYoureAllSet => 'Tout est prêt !';

  @override
  String get onboardingServerUpdated => 'Serveur mis à jour';

  @override
  String get onboardingServerConnectedReady =>
      'Votre serveur est connecté et prêt à l\'emploi.';

  @override
  String get onboardingServerSettingsSaved =>
      'Vos paramètres de serveur ont été enregistrés et les tests de santé ont été actualisés.';

  @override
  String onboardingStartUsing(String appName) {
    return 'Commencer à utiliser $appName';
  }

  @override
  String get onboardingCouldNotVerify =>
      'Impossible de vérifier la connexion au serveur.';

  @override
  String get onboardingCloudflareAuthFailed =>
      'L\'authentification Cloudflare Access a échoué.';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'Le test de santé du serveur a échoué. Il est peut-être encore en train de démarrer.';

  @override
  String get onboardingConnectionUpdated =>
      'Connexion au serveur mise à jour avec succès.';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'Serveur ajouté mais le test de santé a échoué. Il est peut-être encore en train de démarrer.';

  @override
  String get onboardingConnectionSaved =>
      'Connexion au serveur enregistrée avec succès.';

  @override
  String get onboardingAvailable => 'disponible';

  @override
  String get onboardingNotAvailable => 'non disponible';

  @override
  String get onboardingReachable => 'accessible';

  @override
  String get onboardingUnreachable => 'inaccessible';

  @override
  String get onboardingWritable => 'accessible en écriture';

  @override
  String get onboardingNotWritable => 'non accessible en écriture';

  @override
  String toolPresentationRunningTool(String toolName) {
    return 'Exécution de $toolName';
  }

  @override
  String get toolPresentationTool => 'Outil';

  @override
  String get shortcutGroupSession => 'Session';

  @override
  String get shortcutGroupGeneral => 'Général';

  @override
  String get shortcutGroupPrompt => 'Invite';

  @override
  String get shortcutGroupNavigation => 'Navigation';

  @override
  String get shortcutGroupModelAndAgent => 'Modèle et agent';

  @override
  String get shortcutGroupApplication => 'Application';

  @override
  String get shortcutNewConversation => 'Nouvelle conversation';

  @override
  String get shortcutNewConversationDesc =>
      'Créer une nouvelle session de chat';

  @override
  String get shortcutRefreshData => 'Actualiser les données';

  @override
  String get shortcutRefreshDataDesc => 'Actualiser les données du chat actuel';

  @override
  String get shortcutFocusInput => 'Focus sur lentrée';

  @override
  String get shortcutFocusInputDesc =>
      'Déplacer le focus vers l\'entrée de texte';

  @override
  String get shortcutToggleVoiceInput => 'Basculer la saisie vocale';

  @override
  String get shortcutToggleVoiceInputDesc =>
      'Démarrer ou arrêter la saisie vocale dans léditeur';

  @override
  String get shortcutQuickOpenFiles => 'Ouverture rapide de fichiers';

  @override
  String get shortcutQuickOpenFilesDesc =>
      'Ouvrir la recherche rapide de fichiers';

  @override
  String get shortcutOpenSettings => 'Ouvrir les paramètres';

  @override
  String get shortcutOpenSettingsDesc => 'Ouvrir la page des paramètres';

  @override
  String get shortcutNextRecentModel => 'Modèle récent suivant';

  @override
  String get shortcutNextRecentModelDesc =>
      'Passer d\'un modèle récemment utilisé à l\'autre';

  @override
  String get shortcutNextVariant => 'Variante suivante';

  @override
  String get shortcutNextVariantDesc =>
      'Passer d\'une variante de modèle disponible à l\'autre';

  @override
  String get shortcutFocusCloseDrawer => 'Focus/fermer le tiroir';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'Focus sur l\'entrée par défaut, ou fermer le tiroir s\'il est ouvert';

  @override
  String get shortcutNextAgent => 'Agent suivant';

  @override
  String get shortcutNextAgentDesc => 'Passer à l\'agent disponible suivant';

  @override
  String get shortcutPreviousAgent => 'Agent précédent';

  @override
  String get shortcutPreviousAgentDesc =>
      'Passer à l\'agent disponible précédent';

  @override
  String get shortcutCloseApp => 'Fermer lapplication';

  @override
  String get shortcutCloseAppDesc =>
      'Fermer l\'application en utilisant le comportement de fermeture de la plateforme';

  @override
  String get shortcutQuitApp => 'Quitter lapplication';

  @override
  String get shortcutQuitAppDesc => 'Forcer la sortie de l\'application';

  @override
  String get shortcutStopResponse => 'Arrêter la réponse';

  @override
  String get shortcutStopResponseDesc =>
      'Arrêter la réponse active (pendant la réponse)';

  @override
  String get errorConnectionFailed => 'Échec de la connexion';

  @override
  String get errorConnectionFailedDesc =>
      'Impossible de joindre le serveur. Vérifiez la connexion et l\'état du serveur.';

  @override
  String get errorQuotaExceeded => 'Quota dépassé';

  @override
  String get errorQuotaExceededDesc =>
      'Quota dépassé. Vérifiez votre plan de fournisseur ou votre facturation.';

  @override
  String get errorRateLimitExceeded => 'Limite de débit dépassée';

  @override
  String get errorRateLimitExceededDesc =>
      'Limite de débit dépassée. Attendez un moment et réessayez.';

  @override
  String get errorAuthRequired => 'Authentification requise';

  @override
  String get errorAuthRequiredDesc =>
      'L\'authentification a échoué. Reconnectez le fournisseur et réessayez.';

  @override
  String get errorServiceUnavailable => 'Service indisponible';

  @override
  String get errorServiceUnavailableDesc =>
      'Service temporairement indisponible. Le serveur est peut-être en train de démarrer — veuillez réessayer bientôt.';

  @override
  String get errorProviderUnavailable => 'Fournisseur indisponible';

  @override
  String get errorProviderUnavailableDesc =>
      'Fournisseur temporairement indisponible. Réessayez bientôt.';

  @override
  String get errorServerError => 'Erreur du serveur';

  @override
  String get errorServerErrorDesc => 'Erreur du serveur. Veuillez réessayer.';

  @override
  String get attachmentNotAvailableOnPlatform =>
      'Les actions sur les pièces jointes ne sont pas disponibles sur cette plateforme.';

  @override
  String get attachmentUnableToOpenLink =>
      'Impossible d\'ouvrir le lien de la pièce jointe.';

  @override
  String get attachmentNoValidLocation =>
      'La pièce jointe ne fournit pas d\'emplacement valide.';

  @override
  String get attachmentDownloadStarted =>
      'Téléchargement de la pièce jointe commencé.';

  @override
  String get attachmentCouldNotDownload =>
      'La pièce jointe n\'a pas pu être téléchargée.';

  @override
  String get attachmentCouldNotDecode =>
      'Les données de la pièce jointe n\'ont pas pu être décodées.';

  @override
  String get attachmentPayloadEmpty =>
      'La charge utile de la pièce jointe est vide.';

  @override
  String attachmentSavedAndOpened(String path) {
    return 'Pièce jointe enregistrée dans $path et ouverte.';
  }

  @override
  String attachmentSavedTo(String path) {
    return 'Pièce jointe enregistrée dans $path.';
  }

  @override
  String get attachmentCouldNotSave =>
      'La pièce jointe n\'a pas pu être enregistrée sur cet appareil.';

  @override
  String get attachmentSaveCanceled => 'Enregistrement annulé.';

  @override
  String attachmentSavedPath(String path) {
    return 'Pièce jointe enregistrée dans $path.';
  }

  @override
  String get attachmentPathEmpty => 'Le chemin de la pièce jointe est vide.';

  @override
  String get attachmentLocalNotFound =>
      'La pièce jointe locale n\'a pas été trouvée sur cet appareil.';

  @override
  String get attachmentUnableToOpenLocal =>
      'Impossible d\'ouvrir la pièce jointe locale.';

  @override
  String speechDesktopOnly(String service) {
    return '$service est disponible sur ordinateur uniquement.';
  }

  @override
  String speechRuntimeFailed(String service) {
    return 'Le runtime $service n\'a pas pu s\'initialiser.';
  }

  @override
  String speechModelFilesIncomplete(String service) {
    return 'Les fichiers du modèle $service sont incomplets.';
  }

  @override
  String get speechMicPermissionDisabled =>
      'L\'autorisation du microphone est désactivée.';

  @override
  String speechUnavailableOnPlatform(String service) {
    return 'La parole $service n\'est pas disponible sur cette plateforme.';
  }

  @override
  String get terminalOpenToConnect =>
      'Ouvrez le Terminal pour vous connecter au terminal du projet du serveur.';

  @override
  String get terminalNotAvailableYet =>
      'Le terminal intégré n\'est pas encore disponible sur ce runtime.';

  @override
  String get terminalSelectServer =>
      'Sélectionnez un serveur actif avant d\'ouvrir le Terminal.';

  @override
  String get terminalOpenProjectFirst =>
      'Ouvrez un dossier de projet avant de démarrer le terminal du serveur.';

  @override
  String terminalConnectingTo(String serverName) {
    return 'Connexion au terminal de $serverName...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'Échec de la connexion au terminal : $error';
  }

  @override
  String get terminalDisconnected => 'Terminal déconnecté.';

  @override
  String get terminalSessionClosed => 'Session de terminal fermée.';

  @override
  String get notificationConversationUpdates =>
      'Mises à jour de la conversation';

  @override
  String get notificationOpenToClear =>
      'Ouvrez cette conversation pour effacer les notifications associées.';

  @override
  String get notificationAgentFinished =>
      'L\'agent a terminé la réponse actuelle.';

  @override
  String get notificationSession => 'Session';

  @override
  String get chatBadgeServerNeedsAttention =>
      'La connexion au serveur nécessite une attention particulière.';

  @override
  String chatBadgeConversationError(String title) {
    return '\"$title\" a une erreur.';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '\"$title\" nécessite votre intervention.';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '\"$title\" a une nouvelle réponse.';
  }

  @override
  String get chatBadgeSyncing => 'Synchronisation des conversations...';

  @override
  String get chatBadgeDataSaverActive =>
      'Léconomiseur de données mobiles est activé.';

  @override
  String get chatCollapseGroup => 'Réduire le groupe';

  @override
  String get chatExpandGroup => 'Développer le groupe';

  @override
  String get chatForkFailed => 'Échec de la bifurcation de la conversation';

  @override
  String get chatForked => 'Conversation bifurquée';

  @override
  String get chatNoConversationsInProject =>
      'Aucune conversation dans ce projet.';

  @override
  String get chatOpenProjectToLoad =>
      'Ouvrez un projet pour charger les conversations.';

  @override
  String get chatExportCanceled => 'Exportation de la session annulée';

  @override
  String get chatLargeContentSkipped =>
      'Le contenu volumineux ou malformé a été ignoré pour des raisons de stabilité.';

  @override
  String chatTokensLabel(int total) {
    return 'Tokens : $total';
  }

  @override
  String chatCostLabel(String cost) {
    return 'Coût : \$$cost';
  }

  @override
  String get chatFileExplorerNames => 'Noms';

  @override
  String get chatFileExplorerContents => 'Contenu';

  @override
  String chatCloseProject(String project) {
    return 'Fermer $project';
  }

  @override
  String get sessionExportUser => 'Utilisateur';

  @override
  String get sessionExportAssistant => 'Assistant';

  @override
  String get sessionExportInput => 'Entrée :';

  @override
  String get sessionExportOutput => 'Sortie :';

  @override
  String get sessionExportError => 'Erreur :';

  @override
  String get sessionExportUntitled => 'Session sans titre';

  @override
  String get modelLabelTinyEnglish => 'Tiny (Anglais)';

  @override
  String get modelLabelBaseEnglish => 'Base (Anglais)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 langues européennes)';

  @override
  String get cannedNewQuickReply => 'Nouvelle réponse rapide';

  @override
  String get settingsSoundPickerNotAvailable =>
      'Le sélecteur de sons système n\'est pas disponible sur cette plateforme.';

  @override
  String get appProviderPrimaryServer => 'Serveur principal';

  @override
  String get appProviderLocalManaged => 'OpenCode local (géré)';

  @override
  String get appProviderLocalServerStopped => 'Le serveur local est arrêté.';

  @override
  String get appProviderRunDiagnostics =>
      'Exécutez les diagnostics pour vérifier les prérequis locaux dOpenCode.';

  @override
  String get appProviderInvalidServerUrl => 'URL du serveur invalide';

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth n\'est pas supporté sur cette plateforme';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale n\'est pas supporté sur cette plateforme';

  @override
  String get appProviderProfileNotFound => 'Profil de serveur introuvable';

  @override
  String get appProviderCannotActivateUnhealthy =>
      'Impossible d\'activer un serveur en mauvaise santé';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode détecté';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode non détecté';

  @override
  String get appProviderDetectingCommand =>
      'Détection de la commande OpenCode...';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'La commande OpenCode n\'a pas été détectée. Si vous l\'avez installée il y a un instant, actualisez les tests ou redémarrez $appName pour recharger le PATH.';
  }

  @override
  String get appProviderNotDetectedInstall =>
      'La commande OpenCode n\'a pas été détectée. Lancez l\'installation depuis l\'assistant.';

  @override
  String appProviderUsingCommandAt(String path) {
    return 'Utilisation de la commande OpenCode à $path';
  }

  @override
  String get appProviderDesktopOnly =>
      'Le serveur local géré n\'est disponible que sur ordinateur.';

  @override
  String get appProviderInstallingRequirements =>
      'Installation des prérequis OpenCode...';

  @override
  String get appProviderInstallationFailed =>
      'L\'installation d\'OpenCode a échoué.';

  @override
  String get appProviderInstalledSuccessfully =>
      'Prérequis OpenCode installés avec succès.';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'Installation réussie. Commande OpenCode disponible à $path.';
  }

  @override
  String get appProviderInstallSucceeded => 'Installation réussie.';

  @override
  String get appProviderStartingLocalServer => 'Démarrage du serveur local...';

  @override
  String get appProviderFailedToStart =>
      'Échec du démarrage du serveur OpenCode local.';

  @override
  String appProviderRunningAt(String url) {
    return 'Lancé sur $url';
  }

  @override
  String get appProviderStoppingLocalServer => 'Arrêt du serveur local...';

  @override
  String appProviderExitedWithCode(int code) {
    return 'Le serveur local s\'est arrêté avec le code $code.';
  }

  @override
  String get appProviderInstallBinary => 'Installer le binaire';

  @override
  String get appProviderInstallViaNpm => 'Installer via npm';

  @override
  String get appProviderInstallViaBun => 'Installer via Bun';

  @override
  String get appProviderInstallBunOpenCode => 'Installer Bun + OpenCode';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'Tailscale n\'est pas supporté sur cette plateforme.';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'Tailscale n\'est pas supporté sur Windows.';

  @override
  String get tailscaleWaitingAdminApproval =>
      'Ce nœud Tailscale est en attente de l\'approbation de l\'administrateur.';

  @override
  String get notificationSoundLoadFailed =>
      'Échec du chargement des sons système Android';

  @override
  String get chatDescriptionNewConversation => 'Nouvelle conversation';

  @override
  String get chatDescriptionRefreshData => 'Actualiser les données du chat';

  @override
  String get chatDescriptionFocusInput => 'Focus sur l\'entrée du message';

  @override
  String get chatDescriptionVoiceInput =>
      'Démarrer ou arrêter la saisie vocale';

  @override
  String get chatDescriptionQuickOpen => 'Ouverture rapide de fichiers';

  @override
  String get chatDescriptionOpenSettings => 'Ouvrir les paramètres';

  @override
  String get chatDescriptionCycleModels => 'Faire défiler les modèles récents';

  @override
  String get chatDescriptionCycleVariant =>
      'Faire défiler les variantes de modèle';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      'Focus sur l\'entrée (ou fermer le tiroir s\'il est ouvert)';

  @override
  String get chatDescriptionNextAgent => 'Agent suivant';

  @override
  String get chatDescriptionPreviousAgent => 'Agent précédent';

  @override
  String get chatDescriptionCloseApp =>
      'Fermer l\'application en utilisant le comportement de fermeture de la plateforme';

  @override
  String get chatDescriptionForceExit => 'Forcer la sortie de l\'application';

  @override
  String get chatDescriptionStopResponse =>
      'Arrêter la réponse active (pendant la réponse)';

  @override
  String get chatDescriptionProjectCommand => 'Commande de projet';

  @override
  String get chatDescriptionOpenProjects =>
      'Utilisez ce bouton pour ouvrir vos projets et conversations.';

  @override
  String get chatDescriptionSwitchProject =>
      'Utilisez ce bouton pour changer de dossier de projet et de contexte.';

  @override
  String chatDescriptionChildren(int count) {
    return 'Enfants : $count';
  }

  @override
  String get chatDescriptionDiffFilesZero => 'Fichiers diff : 0';

  @override
  String get appProviderErrorInvalidServerUrl => 'URL du serveur invalide';

  @override
  String get appProviderErrorServerUrlRequired =>
      'L\'URL du serveur est requise';

  @override
  String get appProviderErrorServerAlreadyExists =>
      'Un serveur avec cette URL existe déjà';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth n\'est pas supporté sur cette plateforme';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale n\'est pas supporté sur cette plateforme';

  @override
  String get appProviderErrorServerProfileNotFound =>
      'Profil de serveur introuvable';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      'Impossible d\'activer un serveur en mauvaise santé';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      'Le serveur local géré n\'est disponible que sur ordinateur.';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'Le serveur local a démarré mais le test de santé n\'a pas été concluant.';

  @override
  String get appProviderErrorInstallationFailed =>
      'L\'installation d\'OpenCode a échoué.';

  @override
  String get appProviderStatusLocalServerStopped =>
      'Le serveur local est arrêté.';

  @override
  String get appProviderStatusStartingLocalServer =>
      'Démarrage du serveur local...';

  @override
  String appProviderStatusRunningAt(String url) {
    return 'Lancé sur $url';
  }

  @override
  String get appProviderStatusStoppingLocalServer =>
      'Arrêt du serveur local...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'Le serveur local sest arrêté avec le code $code.';
  }

  @override
  String get appProviderSetupDetectingOpenCode =>
      'Détection de la commande OpenCode...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode détecté';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode non détecté';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return 'Utilisation de la commande OpenCode à $path';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'Installation des prérequis OpenCode...';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'Prérequis OpenCode installés avec succès.';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'Installation réussie. Commande OpenCode disponible à $path.';
  }

  @override
  String get appProviderSetupInstallationSucceeded => 'Installation réussie.';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'La commande OpenCode n\'a pas été détectée. Si vous l\'avez installée il y a un instant, actualisez les tests ou redémarrez CodeWalk pour recharger le PATH.';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'La commande OpenCode n\'a pas été détectée. Lancez l\'installation depuis l\'assistant.';

  @override
  String get appProviderLabelPrimaryServer => 'Serveur principal';

  @override
  String get appProviderLabelLocalOpenCodeManaged => 'OpenCode local (géré)';
}
