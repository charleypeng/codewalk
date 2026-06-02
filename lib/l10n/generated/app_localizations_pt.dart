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
  String get appProviderCannotActivateUnhealthy =>
      'Cannot activate an unhealthy server';

  @override
  String get appProviderDesktopOnly =>
      'Managed local server is available only on desktop.';

  @override
  String get appProviderDetectingCommand => 'Detecting OpenCode command...';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      'Cannot activate an unhealthy server';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth is not supported on this platform';

  @override
  String get appProviderErrorInstallationFailed =>
      'OpenCode installation failed.';

  @override
  String get appProviderErrorInvalidServerUrl => 'Invalid server URL';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'Local server started but health check did not pass.';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      'Managed local server is available only on desktop.';

  @override
  String get appProviderErrorServerAlreadyExists =>
      'A server with this URL already exists';

  @override
  String get appProviderErrorServerProfileNotFound =>
      'Server profile not found';

  @override
  String get appProviderErrorServerUrlRequired => 'Server URL is required';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale is not supported on this platform';

  @override
  String appProviderExitedWithCode(int code) {
    return 'Local server exited with code $code.';
  }

  @override
  String get appProviderFailedToStart =>
      'Failed to start local OpenCode server.';

  @override
  String get appProviderInstallBinary => 'Install Binary';

  @override
  String get appProviderInstallBunOpenCode => 'Install Bun + OpenCode';

  @override
  String get appProviderInstallSucceeded => 'Installation succeeded.';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'Installation succeeded. OpenCode command available at $path.';
  }

  @override
  String get appProviderInstallViaBun => 'Install via Bun';

  @override
  String get appProviderInstallViaNpm => 'Install via npm';

  @override
  String get appProviderInstallationFailed => 'OpenCode installation failed.';

  @override
  String get appProviderInstalledSuccessfully =>
      'OpenCode requirements installed successfully.';

  @override
  String get appProviderInstallingRequirements =>
      'Installing OpenCode requirements...';

  @override
  String get appProviderInvalidServerUrl => 'Invalid server URL';

  @override
  String get appProviderLabelLocalOpenCodeManaged => 'Local OpenCode (Managed)';

  @override
  String get appProviderLabelPrimaryServer => 'Primary server';

  @override
  String get appProviderLocalManaged => 'Local OpenCode (Managed)';

  @override
  String get appProviderLocalServerStopped => 'Local server is stopped.';

  @override
  String get appProviderNotDetectedInstall =>
      'OpenCode command was not detected. Run installation from the wizard.';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'OpenCode command was not detected. If you installed it moments ago, refresh checks or reopen $appName to reload PATH.';
  }

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth is not supported on this platform';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode detected';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode not detected';

  @override
  String get appProviderPrimaryServer => 'Primary server';

  @override
  String get appProviderProfileNotFound => 'Server profile not found';

  @override
  String get appProviderRunDiagnostics =>
      'Run diagnostics to verify local OpenCode requirements.';

  @override
  String appProviderRunningAt(String url) {
    return 'Running at $url';
  }

  @override
  String get appProviderSetupDetectingOpenCode =>
      'Detecting OpenCode command...';

  @override
  String get appProviderSetupInstallationSucceeded => 'Installation succeeded.';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'Installation succeeded. OpenCode command available at $path.';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'Installing OpenCode requirements...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode detected';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode not detected';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'OpenCode command was not detected. Run installation from the wizard.';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'OpenCode command was not detected. If you installed it moments ago, refresh checks or reopen CodeWalk to reload PATH.';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'OpenCode requirements installed successfully.';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return 'Using OpenCode command at $path';
  }

  @override
  String get appProviderStartingLocalServer => 'Starting local server...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'Local server exited with code $code.';
  }

  @override
  String get appProviderStatusLocalServerStopped => 'Local server is stopped.';

  @override
  String appProviderStatusRunningAt(String url) {
    return 'Running at $url';
  }

  @override
  String get appProviderStatusStartingLocalServer => 'Starting local server...';

  @override
  String get appProviderStatusStoppingLocalServer => 'Stopping local server...';

  @override
  String get appProviderStoppingLocalServer => 'Stopping local server...';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale is not supported on this platform';

  @override
  String appProviderUsingCommandAt(String path) {
    return 'Using OpenCode command at $path';
  }

  @override
  String get appShellDownloadingUpdate => 'Downloading update…';

  @override
  String get appShellInstall => 'Install';

  @override
  String get appShellInstallFailed => 'Install failed';

  @override
  String get appShellInstallingUpdate => 'Installing update...';

  @override
  String get appShellRestart => 'Restart';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return 'Update available: v$latestVersion';
  }

  @override
  String get appShellUpdateInstalledRestartApp =>
      'Update installed. Restart the app to apply.';

  @override
  String get appShellUpdateInstalledRestartRequired =>
      'Update installed. Restart is required to apply the new version.';

  @override
  String get attachmentCouldNotDecode =>
      'Attachment data could not be decoded.';

  @override
  String get attachmentCouldNotDownload =>
      'Attachment could not be downloaded.';

  @override
  String get attachmentCouldNotSave =>
      'Attachment could not be saved on this device.';

  @override
  String get attachmentDownloadStarted => 'Attachment download started.';

  @override
  String get attachmentLocalNotFound =>
      'Local attachment was not found on this device.';

  @override
  String get attachmentNoValidLocation =>
      'Attachment does not provide a valid location.';

  @override
  String get attachmentNotAvailableOnPlatform =>
      'Attachment actions are not available on this platform.';

  @override
  String get attachmentPathEmpty => 'Attachment path is empty.';

  @override
  String get attachmentPayloadEmpty => 'Attachment payload is empty.';

  @override
  String get attachmentSaveCanceled => 'Save canceled.';

  @override
  String attachmentSavedAndOpened(String path) {
    return 'Attachment saved to $path and opened.';
  }

  @override
  String attachmentSavedPath(String path) {
    return 'Attachment saved to $path.';
  }

  @override
  String attachmentSavedTo(String path) {
    return 'Attachment saved to $path.';
  }

  @override
  String get attachmentUnableToOpenLink =>
      'Unable to open the attachment link.';

  @override
  String get attachmentUnableToOpenLocal =>
      'Unable to open the local attachment.';

  @override
  String get behaviorAdvancedPermissionRule =>
      'Advanced permission rule editing stays out of Settings for now and is deferred to later parity work.';

  @override
  String get behaviorAutomatic => 'Automatic';

  @override
  String get behaviorAutomaticFallback => 'Automatic fallback';

  @override
  String get behaviorCellularDataSaver => 'Cellular data saver';

  @override
  String get behaviorCellularDataSaverActive =>
      'Cellular data saver is active.';

  @override
  String get behaviorChatLevelShare =>
      'Use the chat-level share action to publish one session now. This setting only changes OpenCode’s default sharing policy.';

  @override
  String get behaviorCodeWalkReleaseChecks =>
      'Use About for CodeWalk release checks. This setting only mirrors the official OpenCode `autoupdate` config.';

  @override
  String get behaviorControlsOfficialGlobal =>
      'Controls the official global `share` config, not the share button for an individual chat.';

  @override
  String get behaviorControlsUpstreamOpenCode =>
      'Controls upstream OpenCode runtime updates, not CodeWalk app update checks.';

  @override
  String get behaviorCustomDisplayName =>
      'Custom display name shown in conversations instead of the system username.';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return 'Cuts automatic mobile-data usage by stopping background downloads and throttling automatic foreground refreshes to one burst every $inSeconds seconds.';
  }

  @override
  String get behaviorDataSaverActive => 'Active now on mobile data.';

  @override
  String get behaviorDataSaverCellularOnly =>
      'Only applies when the connection is cellular/mobile.';

  @override
  String get behaviorDataSaverWaiting =>
      'Waiting for the next mobile-data sync window.';

  @override
  String get behaviorDisabled => 'Disabled';

  @override
  String get behaviorLightweightTasksLike =>
      'Used for lightweight tasks like title generation.';

  @override
  String get behaviorManual => 'Manual';

  @override
  String get behaviorNotify => 'Notify only';

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
  String get cannedAddTitle => 'Add canned answer';

  @override
  String get cannedAppendAtCursor => 'Append at cursor';

  @override
  String get cannedAppendAtCursorSubtitle =>
      'Off means replace current composer text';

  @override
  String get cannedAttachFiles => 'Attach files';

  @override
  String get cannedEditTitle => 'Edit canned answer';

  @override
  String get cannedNewQuickReply => 'New quick reply';

  @override
  String get cannedNoSuggestions => 'Nenhuma sugestão';

  @override
  String get cannedOffMeansReplace => 'Off means replace current composer text';

  @override
  String get cannedQuickReply => 'New quick reply';

  @override
  String get cannedReplace => 'Replace';

  @override
  String get cannedScopeGlobalSubtitle => 'Disable for project-only item';

  @override
  String get cannedScopeGlobalUnavailableSubtitle =>
      'Project-only unavailable in current context';

  @override
  String get cannedSendAutomaticallySubtitle =>
      'Send immediately after inserting this quick reply';

  @override
  String get cannedSendImmediatelyInserting =>
      'Send immediately after inserting this quick reply';

  @override
  String get cannedTextLabel => 'Text';

  @override
  String get chatActionNext => 'Next';

  @override
  String get chatActiveServerUnhealthy =>
      'Active server is unhealthy. Sends will try once and fail fast until recovery.';

  @override
  String get chatActiveServerUnhealthyLabel => 'Active server is unhealthy';

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
  String chatBadgeConversationError(String title) {
    return '\"$title\" has an error.';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '\"$title\" needs your input.';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '\"$title\" has a new reply.';
  }

  @override
  String get chatBadgeDataSaverActive => 'Cellular data saver is active.';

  @override
  String get chatBadgeServerNeedsAttention =>
      'Server connection needs attention.';

  @override
  String get chatBadgeSyncing => 'Syncing conversations...';

  @override
  String get chatCachedConversationsYet => 'No cached conversations yet';

  @override
  String get chatChangedFilesAvailable =>
      'No changed files are available for this session.';

  @override
  String chatChildrenChatProviderCurrentSessionChildren(int length) {
    return 'Children: $length';
  }

  @override
  String get chatChooseAgent => 'Select agent';

  @override
  String get chatChooseDirectory => 'Choose Directory';

  @override
  String get chatChooseEffort => 'Choose effort';

  @override
  String get chatChooseFolderOpen =>
      'Choose a folder to open as project context.';

  @override
  String get chatChooseModel => 'Choose model';

  @override
  String get chatClose => 'Fechar';

  @override
  String chatCloseProject(String project) {
    return 'Close $project';
  }

  @override
  String get chatCollapseGroup => 'Collapse group';

  @override
  String get chatCommandDescriptionProject => 'Project command';

  @override
  String get chatCommandSourceGeneric => 'command';

  @override
  String get chatCommandSourceProject => 'project';

  @override
  String get chatCompactContext => 'Compactar Contexto';

  @override
  String get chatComposerHintShell => 'Shell command (Esc to exit)';

  @override
  String get chatComposerPlaceholder => 'Type your needs...';

  @override
  String get chatConversation => 'Conversation';

  @override
  String get chatConversations => 'Conversas';

  @override
  String get chatConversationsPane => 'Conversas';

  @override
  String chatCostLabel(double cost) {
    return 'Cost: \$$cost';
  }

  @override
  String get chatCouldNotRefreshSession =>
      'Could not refresh this conversation';

  @override
  String get chatCurrent => 'Use current';

  @override
  String chatDescriptionChildren(int count) {
    return 'Children: $count';
  }

  @override
  String get chatDescriptionCloseApp =>
      'Close app using platform close behavior';

  @override
  String get chatDescriptionCycleModels => 'Cycle recent models';

  @override
  String get chatDescriptionCycleVariant => 'Cycle model variant';

  @override
  String get chatDescriptionDiffFilesZero => 'Diff files: 0';

  @override
  String get chatDescriptionFocusInput => 'Focus message input';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      'Focus input (or close drawer when open)';

  @override
  String get chatDescriptionForceExit => 'Force-exit the app';

  @override
  String get chatDescriptionNewConversation => 'New conversation';

  @override
  String get chatDescriptionNextAgent => 'Next agent';

  @override
  String get chatDescriptionOpenProjects =>
      'Use this button to open your projects and conversations.';

  @override
  String get chatDescriptionOpenSettings => 'Open settings';

  @override
  String get chatDescriptionPreviousAgent => 'Previous agent';

  @override
  String get chatDescriptionProjectCommand => 'Project command';

  @override
  String get chatDescriptionQuickOpen => 'Quick open files';

  @override
  String get chatDescriptionRefreshData => 'Refresh chat data';

  @override
  String get chatDescriptionStopResponse =>
      'Stop active response (while responding)';

  @override
  String get chatDescriptionSwitchProject =>
      'Use this button to switch project folders and context.';

  @override
  String get chatDescriptionVoiceInput => 'Start or stop voice input';

  @override
  String get chatDiffFiles => 'Diff files: 0';

  @override
  String get chatDisplay => 'Display';

  @override
  String get chatDisplayToggles => 'Opções de exibição';

  @override
  String get chatDoubleESCStop => 'Double ESC to stop';

  @override
  String get chatEffortLockedSubConversation =>
      'Effort locked in sub-conversation';

  @override
  String get chatExpandGroup => 'Expand group';

  @override
  String get chatExportCanceled => 'Session export canceled';

  @override
  String get chatFailedToLoadDirectories => 'Failed to load directories';

  @override
  String get chatFailedToLoadFile => 'Failed to load file';

  @override
  String get chatFailedToRefreshProviders =>
      'Failed to refresh providers and models';

  @override
  String get chatFailedToRefreshSubConversations =>
      'Failed to refresh sub-conversations. Please try again.';

  @override
  String get chatFailedToStopResponse => 'Failed to stop current response';

  @override
  String get chatFileExplorerContents => 'Contents';

  @override
  String get chatFileExplorerNames => 'Names';

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
  String get chatForkFailed => 'Failed to fork conversation';

  @override
  String get chatForked => 'Conversation forked';

  @override
  String get chatGoToFirst => 'Ir para primeira mensagem';

  @override
  String get chatGoToLatest => 'Ir para última mensagem';

  @override
  String chatGroupMessageCountMessages(
    String compactionLabel,
    String messageCount,
  ) {
    return '$messageCount messages hidden before $compactionLabel compaction';
  }

  @override
  String get chatHelloAssistant => 'Olá! Eu sou seu assistente de IA';

  @override
  String get chatHelp => 'How can I help you?';

  @override
  String get chatHelpMessage =>
      'Use @ for mentions, ! for shell, / for commands';

  @override
  String get chatHideConversationsSidebar => 'Ocultar barra de Conversas';

  @override
  String get chatHideUtilitySidebar => 'Ocultar barra de Utilidades';

  @override
  String get chatHistoryCollapsed => 'Previous history is collapsed';

  @override
  String get chatHistoryHideEarlier => 'Hide earlier messages';

  @override
  String chatHistoryMessagesHidden(int count, String label) {
    return '$count messages hidden before $label compaction';
  }

  @override
  String get chatHistoryShowEarlier => 'Show earlier messages';

  @override
  String get chatKeepWorking => 'Continuar trabalhando';

  @override
  String get chatLargeContentSkipped =>
      'Large or malformed content was skipped for stability.';

  @override
  String get chatLatestToolActivity =>
      'Latest tool activity stays inside this bounded panel to keep the chat viewport stable.';

  @override
  String get chatLoadMore => 'Carregar mais';

  @override
  String get chatLoadingProjectContext => 'Loading project context...';

  @override
  String get chatMainConversationUnavailable =>
      'Main conversation is not available yet.';

  @override
  String get chatMentionAgentSubtitle => 'agent';

  @override
  String get chatMentionFileSubtitle => 'file';

  @override
  String get chatMentionSymbolSubtitle => 'symbol';

  @override
  String get chatMessageAttachedFile => 'Attached file';

  @override
  String get chatMessageDetails => 'Details';

  @override
  String get chatMessageHide => 'Hide';

  @override
  String get chatMessageLess => 'Less';

  @override
  String get chatMessageMessagePartUnavailable => 'Message part unavailable';

  @override
  String get chatMessageMetadataAvailable => 'No metadata available';

  @override
  String chatMessageModelMessageModelId(String modelId) {
    return 'Model: $modelId';
  }

  @override
  String get chatMessageMore => 'More';

  @override
  String get chatMessageOpenFile => 'Open file';

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return 'Provider: $providerId';
  }

  @override
  String get chatMessageRewindEdit => 'Rewind and edit from here';

  @override
  String get chatMessageRunningTask => 'Running task';

  @override
  String get chatMessageSaveFile => 'Save file';

  @override
  String get chatMessageShow => 'Show';

  @override
  String get chatMessageShowLess => 'Show less';

  @override
  String get chatMessageShowLessCompact => 'Less';

  @override
  String get chatMessageShowMore => 'Show more';

  @override
  String get chatMessageShowMoreCompact => 'More';

  @override
  String get chatMessageThinking => 'Thinking';

  @override
  String get chatMessageThinkingProcess => 'Thinking Process';

  @override
  String get chatMessageToolCall => '1 tool call';

  @override
  String chatMessageToolCalls(int count) {
    return '$count tool calls';
  }

  @override
  String get chatMessageToolCommand => 'Command';

  @override
  String get chatMessageToolCommandTruncated =>
      'Command preview truncated for stability.';

  @override
  String get chatMessageToolDiffOmitted =>
      'Diff preview omitted: edit payload is too large to render safely on mobile.';

  @override
  String get chatMessageToolInput => 'Input';

  @override
  String get chatMessageToolInputTruncated =>
      'Input preview truncated for stability.';

  @override
  String get chatMessageToolOutputTruncated =>
      'Large tool output preview truncated for app stability.';

  @override
  String chatMessageToolQueuedCount(int count) {
    return '$count queued';
  }

  @override
  String chatMessageToolRunningCount(int count) {
    return '$count running';
  }

  @override
  String get chatMessageToolStatusInProgress => 'In progress';

  @override
  String get chatMessageToolStatusNeedsAttention => 'Needs attention';

  @override
  String get chatMessageToolStatusQueued => 'Queued';

  @override
  String get chatMessageYou => 'You';

  @override
  String get chatModelLockedSubConversation =>
      'Model locked in sub-conversation';

  @override
  String get chatNewChat => 'Nova Conversa';

  @override
  String get chatNewChatTourDescription => 'Inicie uma nova conversa aqui.';

  @override
  String get chatNewChatTourTitle => 'Nova conversa';

  @override
  String get chatNoConversationsInProject =>
      'No conversations in this project.';

  @override
  String get chatNoServerYet => 'Nenhum servidor configurado ainda';

  @override
  String get chatNoSessionSelected =>
      'Select or create a conversation to start chatting';

  @override
  String get chatNoSubConversationFound =>
      'No sub-conversation found for this task.';

  @override
  String get chatOpenFiles => 'Abrir Arquivos';

  @override
  String get chatOpenProject => 'Open project';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenProjectToLoad => 'Open project to load conversations.';

  @override
  String get chatOpenSidebar => 'Open sidebar';

  @override
  String get chatPageStatusAutomaticCompactionExplanation =>
      'Automatic compaction happens as context usage grows.';

  @override
  String get chatPageStatusCompactNow => 'Compact now';

  @override
  String get chatPageStatusCompacting => 'Compacting...';

  @override
  String get chatPageStatusCompactingContextNow => 'Compacting context now...';

  @override
  String get chatPageStatusContextCompacted => 'Context compacted';

  @override
  String get chatPageStatusContextUsage => 'Context usage';

  @override
  String get chatPageStatusCost => 'Cost';

  @override
  String get chatPageStatusFailedToCompactContext =>
      'Failed to compact context';

  @override
  String get chatPageStatusLimit => 'Limit';

  @override
  String get chatPageStatusManageServers => 'Manage Servers';

  @override
  String get chatPageStatusSaver => 'Saver';

  @override
  String get chatPageStatusServer => 'Server';

  @override
  String get chatPageStatusSwitchServer => 'Switch Server';

  @override
  String get chatPageStatusTokens => 'Tokens';

  @override
  String get chatPageStatusUsage => 'Usage';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatPermissionAutoApproveOff => 'Permission auto-approve is off';

  @override
  String get chatPermissionAutoApproveOn => 'Permission auto-approve is on';

  @override
  String get chatProjectContext => 'Contexto do Projeto';

  @override
  String get chatProjectContext2 => 'Project context';

  @override
  String get chatRealtimeGlobalEvent => 'global event';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return 'global event ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale => 'global event (stale generation)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return 'message stream ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => 'realtime event';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return 'realtime event ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale =>
      'realtime event (stale generation)';

  @override
  String get chatRealtimeReconnectingServerTry =>
      'Reconnecting to the server. Try again in a moment.';

  @override
  String get chatReasoning => 'Reasoning...';

  @override
  String get chatRecentSessions => 'Sessões recentes';

  @override
  String get chatRecentSessionsToggle => 'Sessões recentes';

  @override
  String get chatRedoLastTurn => 'Refazer último turno desfeito';

  @override
  String get chatRedoNothing => 'Nothing to redo in this session';

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
    return 'Remove $displayName from history';
  }

  @override
  String get chatRetry => 'Tentar novamente';

  @override
  String get chatRetry2 => 'Retry';

  @override
  String get chatRetryRefresh => 'Tentar atualizar novamente';

  @override
  String get chatRetryingModelRequest => 'Retrying model request...';

  @override
  String get chatReturnToMainConversation => 'Voltar à conversa principal';

  @override
  String get chatReviewChanges => 'Review changes';

  @override
  String get chatSearchConversations => 'Buscar conversas';

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
      'Selecione ou crie uma conversa para começar';

  @override
  String get chatSelectProjectBelow => 'Select a project below.';

  @override
  String get chatServerSelectedModel => 'Server-selected model';

  @override
  String get chatSessionActions => 'Ações da sessão';

  @override
  String chatSessionChatSessionSession(String title) {
    return 'Chat session: $title';
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
  String chatSessionsLength(int length) {
    return '$length';
  }

  @override
  String get chatSetUpServer => 'Configurar servidor';

  @override
  String get chatSettings => 'Settings';

  @override
  String get chatShortcutsCloseApp => 'Close app using platform close behavior';

  @override
  String get chatShortcutsCycleModels => 'Cycle recent models';

  @override
  String get chatShortcutsCycleVariant => 'Cycle model variant';

  @override
  String get chatShortcutsFocusInput => 'Focus message input';

  @override
  String get chatShortcutsFocusInputCloseDrawer =>
      'Focus input (or close drawer when open)';

  @override
  String get chatShortcutsForceExit => 'Force-exit the app';

  @override
  String get chatShortcutsNewConversation => 'New conversation';

  @override
  String get chatShortcutsNextAgent => 'Next agent';

  @override
  String get chatShortcutsOpenSettings => 'Open settings';

  @override
  String get chatShortcutsPreviousAgent => 'Previous agent';

  @override
  String get chatShortcutsQuickOpen => 'Quick open files';

  @override
  String get chatShortcutsRefreshChat => 'Refresh chat data';

  @override
  String get chatShortcutsStartStopVoice => 'Start or stop voice input';

  @override
  String get chatShortcutsStopResponse =>
      'Stop active response (while responding)';

  @override
  String get chatSidebarAccess => 'Sidebar access';

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
  String get chatStartVoiceInput => 'Start voice input';

  @override
  String get chatStartingVoiceInput => 'Starting voice input';

  @override
  String get chatStatusBusy => 'Status: Busy';

  @override
  String get chatStatusPatching => 'Patching';

  @override
  String chatStatusPatchingMultipleFiles(int count) {
    return 'Patching $count files';
  }

  @override
  String get chatStatusPatchingOneFile => 'Patching 1 file';

  @override
  String get chatStatusRetry => 'Status: Retry';

  @override
  String chatStatusRetryCount(int count) {
    return 'Status: Retry #$count';
  }

  @override
  String get chatStatusSubsession => 'Subsession';

  @override
  String get chatStatusThinking => 'Thinking...';

  @override
  String get chatStopVoiceInput => 'Stop voice input';

  @override
  String chatSyncLabel(String label) {
    return 'Sync: $label';
  }

  @override
  String get chatTasks => 'Tasks';

  @override
  String get chatTasksAvailableSession =>
      'No tasks are available for this session.';

  @override
  String get chatTipBeSpecific =>
      'Tip: Be specific — shorter prompts get faster answers';

  @override
  String get chatTipBreakTasks => 'Tip: Break large tasks into smaller prompts';

  @override
  String get chatTipContextKnob =>
      'Tip: Tap the context knob to see usage details';

  @override
  String get chatTipLongPressSend => 'Tip: Long-press Send to insert a newline';

  @override
  String get chatTipMentionFiles =>
      'Tip: Use @ to mention files in your prompt';

  @override
  String get chatTipProvideContext =>
      'Tip: Provide context — paste error messages and logs';

  @override
  String get chatTipRenameConversation =>
      'Tip: Tap the title to rename a conversation';

  @override
  String get chatTipShellCommands =>
      'Tip: Use ! at the start to run shell commands';

  @override
  String get chatTipSlashCommands => 'Tip: Use / to access slash commands';

  @override
  String get chatTipStepByStep =>
      'Tip: Ask for step-by-step when debugging complex issues';

  @override
  String get chatToggleSidebars => 'Alternar barras laterais';

  @override
  String chatTokensLabel(int total) {
    return 'Tokens: $total';
  }

  @override
  String get chatTourProjectsConversations =>
      'Use this button to open your projects and conversations.';

  @override
  String get chatTourSidebarProjectTools =>
      'Use this menu to show the conversations sidebar and project tools.';

  @override
  String get chatTourSwitchFolders =>
      'Use this button to switch project folders and context.';

  @override
  String get chatUndoLastTurn => 'Desfazer último turno';

  @override
  String get chatUndoNothing => 'Nothing to undo in this session';

  @override
  String get chatUseCurrent => 'Usar atual';

  @override
  String get chatWaitingForNetworkConnection =>
      'Waiting for network connection...';

  @override
  String get chatWelcomeMessage => 'Hello! I am your AI assistant.';

  @override
  String get chatWelcomeSubmessage => 'How can I help you today?';

  @override
  String get chatWorkBoundedPanelExplanation =>
      'Latest tool activity stays inside this bounded panel to keep the chat viewport stable.';

  @override
  String get chatWorkExpand => 'Expand';

  @override
  String get chatWorkHide => 'Hide';

  @override
  String get chatWorkMessageOne => '1 work message';

  @override
  String chatWorkMessagesMultiple(int count) {
    return '$count work messages';
  }

  @override
  String get chatWorkShow => 'Show';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonCopiedToClipboard => 'Copied to clipboard';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonFile => 'File';

  @override
  String get commonReset => 'Redefinir';

  @override
  String get commonSave => 'Salvar';

  @override
  String get compactionAutomatic => 'automatic';

  @override
  String get compactionManual => 'manual';

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
  String get errorAnErrorOccurred => 'An error occurred';

  @override
  String get errorAuthRequired => 'Authentication required';

  @override
  String get errorAuthRequiredDesc =>
      'Authentication failed. Reconnect the provider and try again.';

  @override
  String get errorConnectionFailed => 'Connection failed';

  @override
  String get errorConnectionFailedDesc =>
      'Unable to reach the server. Check connection and server status.';

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
  String get errorProviderUnavailable => 'Provider unavailable';

  @override
  String get errorProviderUnavailableDesc =>
      'Provider temporarily unavailable. Try again shortly.';

  @override
  String get errorQuotaExceeded => 'Quota exceeded';

  @override
  String get errorQuotaExceededDesc =>
      'Quota exceeded. Check your provider plan or billing.';

  @override
  String get errorRateLimitExceeded => 'Rate limit exceeded';

  @override
  String get errorRateLimitExceededDesc =>
      'Rate limit exceeded. Wait a moment and try again.';

  @override
  String get errorServerError => 'Server error';

  @override
  String get errorServerErrorDesc => 'Server error. Please try again.';

  @override
  String get errorServiceUnavailable => 'Service unavailable';

  @override
  String get errorServiceUnavailableDesc =>
      'Service temporarily unavailable. The server may be starting up — please try again shortly.';

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
    return 'Attachment saved to $path and opened.';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return 'Attachment saved to $path.';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return 'Attachment saved to $savedPath.';
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
  String filesOpenFilesFileState(int length) {
    return 'Open files ($length)';
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
  String get logsFilterAll => 'All';

  @override
  String get logsLevel => 'Level';

  @override
  String get logsNoLogsYet => 'No logs captured yet.';

  @override
  String get logsNoMatchingLogs => 'No logs match the current filters.';

  @override
  String get logsSearch => 'Buscar logs';

  @override
  String logsShowingOrderedLength(int length, int length2) {
    return 'Showing $length of $length2 entries';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => 'Math';

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
  String get modelLabelBaseEnglish => 'Base (English)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 European languages)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelTinyEnglish => 'Tiny (English)';

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
    return 'File not found: $path';
  }

  @override
  String get msgFilteredLogsCopied =>
      'Logs filtrados copiados para a área de transferência';

  @override
  String get msgInfoAgent => 'Agente';

  @override
  String get msgInfoCompaction => 'Compactação';

  @override
  String msgInfoCost(double cost) {
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
    return 'Subtask ($agent)';
  }

  @override
  String msgInfoTokens(int total) {
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
    return 'Selected: $soundLabel';
  }

  @override
  String get notificationAgentFinished =>
      'Agent finished the current response.';

  @override
  String get notificationConversationUpdates => 'Conversation updates';

  @override
  String get notificationOpenToClear =>
      'Open this conversation to clear related notifications.';

  @override
  String get notificationSession => 'Session';

  @override
  String get notificationSoundLoadFailed =>
      'Failed to load Android system sounds';

  @override
  String get onboardingAIGeneratedTitles => 'AI generated titles';

  @override
  String get onboardingAddServerLater =>
      'You can add a server later in Settings > Servers.';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'Server added but health check failed. It may still be starting up.';

  @override
  String get onboardingAlmostInstallOpenCode =>
      'You are almost there. Install OpenCode first, then connect CodeWalk to the server URL.';

  @override
  String onboardingAppProviderLocalSetupLogsLength(int length, int length2) {
    return '$length setup log lines and $length2 setup events are available in the separate setup debug screen.';
  }

  @override
  String get onboardingAuthenticate => 'Authenticate';

  @override
  String get onboardingAvailable => 'available';

  @override
  String get onboardingAvailableOnlyDesktop =>
      'Available only on desktop (Linux/macOS/Windows).';

  @override
  String get onboardingBasicAuthTip =>
      'Enable Basic Auth only if your OpenCode server is password-protected.';

  @override
  String get onboardingChooseAnotherPath => 'Choose another path';

  @override
  String get onboardingChooseHowToSetup => 'Choose how to set up your server';

  @override
  String get onboardingClear => 'Limpar';

  @override
  String get onboardingCloudflareAuthFailed =>
      'Cloudflare Access authentication failed.';

  @override
  String get onboardingCodeWalkAppOpenCode =>
      'CodeWalk is the app. OpenCode is the engine it connects to.';

  @override
  String get onboardingConnectRunningServer => 'Connect to a running server';

  @override
  String get onboardingConnectionIssue => 'Connection issue';

  @override
  String get onboardingConnectionSaved =>
      'Server connection saved successfully.';

  @override
  String get onboardingConnectionTips => 'Connection tips';

  @override
  String get onboardingConnectionUpdated =>
      'Server connection updated successfully.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingContinueServerURL => 'Continue to server URL';

  @override
  String get onboardingCopyLoginURL => 'Copy login URL';

  @override
  String get onboardingCouldNotVerify =>
      'Could not verify the server connection.';

  @override
  String get onboardingDefaultURLEmulator =>
      'Default URL, emulator loopback, auth, and debug help.';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'Desktop only: $appName can diagnose, install, and run OpenCode for you.';
  }

  @override
  String get onboardingDetailedSetupEvents =>
      'Detailed setup events were captured for troubleshooting.';

  @override
  String get onboardingDonShowAgain => 'Don\'t show again';

  @override
  String get onboardingDone => 'Done';

  @override
  String get onboardingEditServer => 'Edit server';

  @override
  String get onboardingEditServerConnection => 'Edit server connection';

  @override
  String get onboardingEmulatorRemap =>
      'On Android emulator, localhost and 127.0.0.1 are remapped to 10.0.2.2 automatically.';

  @override
  String get onboardingEnterServerUrl => 'Enter a server URL';

  @override
  String get onboardingExisting => 'Use Existing';

  @override
  String get onboardingExplainInstallOpenCode =>
      'Explain how to install OpenCode, start the server, and then connect from CodeWalk.';

  @override
  String get onboardingFailed => 'Failed';

  @override
  String get onboardingGoodOptionDesktop => 'Good first option on desktop';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'Server health check failed. It may still be starting up.';

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
  String get onboardingInvalidUrl => 'Invalid URL';

  @override
  String get onboardingLabel => 'Rótulo (opcional)';

  @override
  String get onboardingLabelHint => 'Meu servidor';

  @override
  String onboardingLatestOutputAppProvider(String localServerLastOutput) {
    return 'Latest output: $localServerLastOutput';
  }

  @override
  String get onboardingLetCodeWalkSet => 'Let CodeWalk set it up locally';

  @override
  String get onboardingLocalServerSetup => 'Local server setup';

  @override
  String get onboardingManagedLocalServer => 'Managed local server';

  @override
  String get onboardingManagedLocalServer2 =>
      'Managed local server mode is available only on desktop builds (Linux/macOS/Windows).';

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName needs an OpenCode server before it can help with your code.';
  }

  @override
  String get onboardingNotAvailable => 'not available';

  @override
  String get onboardingNotWritable => 'not writable';

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
  String get onboardingPickSetupPath =>
      'Pick the setup path that matches your current OpenCode setup.';

  @override
  String get onboardingReachable => 'reachable';

  @override
  String get onboardingReady => 'Ready';

  @override
  String get onboardingRecommendedOrderTry =>
      'Recommended order: try Install Bun + OpenCode if you want CodeWalk to bootstrap everything for you. Use Existing if OpenCode is already installed.';

  @override
  String get onboardingRefreshChecks => 'Refresh Checks';

  @override
  String get onboardingRunDiagnosticsToVerify =>
      'Run diagnostics to verify local OpenCode requirements.';

  @override
  String get onboardingSaveAndTest => 'Save and test';

  @override
  String get onboardingServerConnectedReady =>
      'Your server is connected and ready to use.';

  @override
  String get onboardingServerConnection => 'Server connection';

  @override
  String get onboardingServerSettingsSaved =>
      'Your server settings were saved and health checks were refreshed.';

  @override
  String get onboardingServerSetup => 'Server setup';

  @override
  String get onboardingServerUpdated => 'Server updated';

  @override
  String get onboardingServerUrl => 'URL do servidor';

  @override
  String get onboardingSetup => 'Setup';

  @override
  String get onboardingSetupWizard => 'Setup wizard';

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
  String onboardingStartUsing(String appName) {
    return 'Start using $appName';
  }

  @override
  String get onboardingStarting => 'Starting';

  @override
  String get onboardingStop => 'Stop';

  @override
  String get onboardingStopped => 'Stopped';

  @override
  String get onboardingStopping => 'Stopping';

  @override
  String onboardingSuggestedUrl(String url) {
    return 'Suggested local OpenCode server URL: $url';
  }

  @override
  String get onboardingTailscaleAdminApproval =>
      'Tailscale admin approval required';

  @override
  String get onboardingTailscaleAuthAfterSave =>
      'Tailscale will authenticate after saving';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'After you save and test this server, $appName will open Tailscale login if this device is not authenticated yet.';
  }

  @override
  String get onboardingTailscaleConnected => 'Tailscale connected';

  @override
  String get onboardingTailscaleConnecting => 'Tailscale connecting';

  @override
  String get onboardingTailscaleConnectionFailed =>
      'Tailscale connection failed';

  @override
  String get onboardingTailscaleLoginRequired => 'Tailscale login required';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'Open the login URL to add this device to your tailnet. If the browser did not open, copy the URL below.';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale unsupported';

  @override
  String get onboardingTestConnection => 'Test connection';

  @override
  String get onboardingTesting => 'Testing...';

  @override
  String get onboardingUnreachable => 'unreachable';

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
  String get onboardingUsingDetectedCommand =>
      'Using detected OpenCode command.';

  @override
  String get onboardingViewSetupDebug => 'View setup debug';

  @override
  String onboardingWelcomeTo(String appName) {
    return 'Welcome to $appName';
  }

  @override
  String get onboardingWindowsTipInstalling =>
      'Windows tip: after installing, click Refresh Checks. If detection still fails, reopen CodeWalk to reload PATH changes.';

  @override
  String get onboardingWritable => 'writable';

  @override
  String get onboardingYoureAllSet => 'You\'re all set!';

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
  String get serverConnectionAttention => 'Server connection needs attention.';

  @override
  String get serverHealthHealthy => 'Healthy';

  @override
  String get serverHealthUnhealthy => 'Unhealthy';

  @override
  String get serverHealthUnknown => 'Unknown';

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
  String get serversCannotActivateUnhealthy =>
      'Cannot activate an unhealthy server';

  @override
  String get serversCheckHealth => 'Check Health';

  @override
  String get serversClearDefault => 'Clear Default';

  @override
  String serversCommandAppProviderLocalServerCommandPath(
    String localServerCommandPath,
  ) {
    return 'Command: $localServerCommandPath';
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
  String get serversDesktopModeExplanation =>
      'Desktop mode can launch and manage `opencode serve` directly from CodeWalk.';

  @override
  String get serversEdit => 'Edit';

  @override
  String get serversLocalOpenCodeServer => 'Local OpenCode Server';

  @override
  String get serversManagedModeAvailable =>
      'This managed mode is available only on desktop builds (Linux/macOS/Windows).';

  @override
  String get serversNoServersFound => 'No servers found';

  @override
  String get serversRefreshHealth => 'Refresh Health';

  @override
  String serversRemoveProfileDisplayName(String displayName) {
    return 'Remove \"$displayName\"?';
  }

  @override
  String get serversSearchActiveHint => 'Search active server';

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
  String get serversTailscaleAdminApprovalRequired =>
      'Tailscale admin approval required';

  @override
  String get serversTailscaleAuthRequired =>
      'Tailscale authentication required';

  @override
  String get serversTailscaleConnectExplanation =>
      'Tailscale will connect when this active profile is used.';

  @override
  String get serversTailscaleConnected => 'Tailscale connected';

  @override
  String get serversTailscaleConnecting => 'Tailscale connecting';

  @override
  String get serversTailscaleConnectionFailed => 'Tailscale connection failed';

  @override
  String get serversTailscaleDisconnected => 'Tailscale disconnected';

  @override
  String get serversTailscaleLoginExplanation =>
      'Open the Tailscale login URL to add this device to your tailnet.';

  @override
  String get serversTailscaleTrafficExplanation =>
      'OpenCode traffic for this active profile is routed through Tailscale.';

  @override
  String get serversTailscaleUnsupported => 'Tailscale unsupported';

  @override
  String get serversUnhealthyActivateError =>
      'This server is unhealthy. Use check health or edit settings before activating.';

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
  String sessionChildrenCount(int count) {
    return 'Children: $count';
  }

  @override
  String get sessionCompactContext => 'Compact context';

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
  String sessionDiffFilesCount(int count) {
    return 'Diff files: $count';
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
  String get sessionDiffReview => 'Revisar alterações';

  @override
  String get sessionDiffSplit => 'Split';

  @override
  String get sessionDiffSummary => 'Summary';

  @override
  String get sessionDiffUnified => 'Unified';

  @override
  String get sessionExportAssistant => 'Assistant';

  @override
  String get sessionExportCanceled => 'Session export canceled';

  @override
  String get sessionExportDebugJson => 'Export debug JSON';

  @override
  String get sessionExportDebugJsonErrorClipboard =>
      'Could not save file; debug JSON copied to clipboard';

  @override
  String get sessionExportDebugJsonSaved => 'Debug JSON export saved';

  @override
  String get sessionExportDebugJsonTitle => 'Export session as debug JSON';

  @override
  String get sessionExportError => 'Error:';

  @override
  String get sessionExportInput => 'Input:';

  @override
  String get sessionExportMarkdown => 'Export Markdown';

  @override
  String get sessionExportMarkdownErrorClipboard =>
      'Could not save file; Markdown copied to clipboard';

  @override
  String get sessionExportMarkdownSaved => 'Markdown export saved';

  @override
  String get sessionExportMarkdownTitle => 'Export session as Markdown';

  @override
  String get sessionExportOutput => 'Output:';

  @override
  String get sessionExportUntitled => 'Untitled session';

  @override
  String get sessionExportUser => 'User';

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
  String get sessionForkFailed => 'Failed to fork conversation';

  @override
  String get sessionForked => 'Conversation forked';

  @override
  String sessionHasError(String title) {
    return '\"$title\" has an error.';
  }

  @override
  String sessionHasNewReply(String title) {
    return '\"$title\" has a new reply.';
  }

  @override
  String get sessionKeyboardShortcuts => 'Atalhos de teclado';

  @override
  String sessionNeedsInput(String title) {
    return '\"$title\" needs your input.';
  }

  @override
  String get sessionNoCachedConversations => 'No cached conversations yet';

  @override
  String get sessionNoConversationsInProject =>
      'No conversations in this project.';

  @override
  String get sessionNotAvailable =>
      'A conversa ainda não está disponível para este projeto';

  @override
  String get sessionOpenProjectToLoad => 'Open project to load conversations.';

  @override
  String get sessionRename => 'Renomear';

  @override
  String get sessionRenameHint => 'Digite o novo nome da conversa';

  @override
  String get sessionRenameTitle => 'Renomear Conversa';

  @override
  String get sessionSaveTitle => 'Salvar título';

  @override
  String get sessionShare => 'Share session';

  @override
  String get sessionShareLinkCopied => 'Link de compartilhamento copiado';

  @override
  String get sessionShareLinkUnavailable =>
      'Share link unavailable for this session';

  @override
  String get sessionShared => 'Conversation shared';

  @override
  String get sessionSyncing => 'Syncing conversations...';

  @override
  String get sessionTitleHint => 'Título da conversa';

  @override
  String get sessionUnshare => 'Unshare session';

  @override
  String get sessionUnshared => 'Conversation unshared';

  @override
  String get sessionViewTasks => 'View tasks';

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
  String get settingsAppearanceMathRendering => 'Math rendering';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      'Render LaTeX math expressions (\$…\$ and \$\$…\$\$) as typeset equations in chat messages.';

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
  String get settingsConfigRefreshFailed =>
      'Updated the server setting, but could not refresh chat providers.';

  @override
  String get settingsConfigUpdateDeferred =>
      'CodeWalk will apply this OpenCode setting after the current response finishes.';

  @override
  String get settingsConversationUsername => 'Conversation username';

  @override
  String get settingsDefaultAgent => 'Default agent';

  @override
  String get settingsDefaultModel => 'Default model';

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
  String get settingsLogsTitle => 'Logs';

  @override
  String get settingsNoAgentsFound => 'No agents found';

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
  String get settingsOpenCodeAutoUpdate => 'OpenCode auto-update';

  @override
  String get settingsOpenCodeSharingDefault => 'OpenCode sharing default';

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
  String get settingsSearchAutoUpdateMode => 'Search auto-update mode';

  @override
  String get settingsSearchDefaultAgent => 'Search default agent';

  @override
  String get settingsSearchDefaultModel => 'Search default model';

  @override
  String get settingsSearchSharingMode => 'Search sharing mode';

  @override
  String get settingsSearchSmallModel => 'Search small model';

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
  String get settingsSmallModel => 'Small model';

  @override
  String get settingsSmallModelResetExplanation =>
      'Resetting `small_model` back to automatic fallback still requires editing config outside the app because `/config` patch updates cannot remove keys.';

  @override
  String get settingsSmallModelUnsetExplanation =>
      'OpenCode automatic fallback is active because `small_model` is unset.';

  @override
  String get settingsSoundPickerNotAvailable =>
      'System sound picker is not available on this platform.';

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
  String get settingsUsernameClearHint =>
      'Clearing the OpenCode conversation username still requires editing config outside the app.';

  @override
  String get settingsUsernameEnterHint =>
      'Enter a username to save a custom OpenCode conversation name.';

  @override
  String get settingsUsernameResetExplanation =>
      'Resetting `username` back to the system default still requires editing config outside the app because `/config` patch updates cannot remove keys.';

  @override
  String get settingsUsernameUnsetExplanation =>
      'OpenCode uses the system username because `username` is unset.';

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
  String setupDebugTimeEntrySource(String source, String time) {
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
  String get shortcutCloseApp => 'Close application';

  @override
  String get shortcutCloseAppDesc => 'Close app using platform close behavior';

  @override
  String get shortcutFocusCloseDrawer => 'Focus/close drawer';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'Focus composer by default, or close drawer when open';

  @override
  String get shortcutFocusInput => 'Focus input';

  @override
  String get shortcutFocusInputDesc => 'Move focus to the prompt input';

  @override
  String get shortcutGroupApplication => 'Application';

  @override
  String get shortcutGroupGeneral => 'General';

  @override
  String get shortcutGroupModelAndAgent => 'Model and agent';

  @override
  String get shortcutGroupNavigation => 'Navigation';

  @override
  String get shortcutGroupPrompt => 'Prompt';

  @override
  String get shortcutGroupSession => 'Session';

  @override
  String get shortcutNewConversation => 'New conversation';

  @override
  String get shortcutNewConversationDesc => 'Create a new chat session';

  @override
  String get shortcutNextAgent => 'Next agent';

  @override
  String get shortcutNextAgentDesc => 'Cycle to next available agent';

  @override
  String get shortcutNextRecentModel => 'Next recent model';

  @override
  String get shortcutNextRecentModelDesc =>
      'Cycle through recently used models';

  @override
  String get shortcutNextVariant => 'Next variant';

  @override
  String get shortcutNextVariantDesc =>
      'Cycle through available model variants';

  @override
  String get shortcutOpenSettings => 'Open settings';

  @override
  String get shortcutOpenSettingsDesc => 'Open settings page';

  @override
  String get shortcutPreviousAgent => 'Previous agent';

  @override
  String get shortcutPreviousAgentDesc => 'Cycle to previous available agent';

  @override
  String get shortcutQuickOpenFiles => 'Quick open files';

  @override
  String get shortcutQuickOpenFilesDesc => 'Open file quick search';

  @override
  String get shortcutQuitApp => 'Quit application';

  @override
  String get shortcutQuitAppDesc => 'Force-exit the app';

  @override
  String get shortcutRefreshData => 'Refresh data';

  @override
  String get shortcutRefreshDataDesc => 'Refresh current chat data';

  @override
  String get shortcutStopResponse => 'Stop active response';

  @override
  String get shortcutStopResponseDesc =>
      'Stop active response (while responding)';

  @override
  String get shortcutToggleVoiceInput => 'Toggle voice input';

  @override
  String get shortcutToggleVoiceInputDesc =>
      'Start or stop speech-to-text in the composer';

  @override
  String get shortcutsApply => 'Apply';

  @override
  String shortcutsConflictConflict(String conflict) {
    return 'Conflict with $conflict';
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
    return 'Set shortcut: $label';
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
  String speechDesktopOnly(String service) {
    return '$service is available on desktop only.';
  }

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
  String get speechMicPermissionDisabled =>
      'Microphone permission is disabled.';

  @override
  String speechModelFilesIncomplete(String service) {
    return '$service model files are incomplete.';
  }

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
  String speechRuntimeFailed(String service) {
    return '$service runtime failed to initialize.';
  }

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
  String speechUnavailableOnPlatform(String service) {
    return '$service speech is unavailable on this platform.';
  }

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusDelayed => 'Delayed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusReconnecting => 'Reconnecting';

  @override
  String get statusStarting => 'Starting';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusStopping => 'Stopping';

  @override
  String get statusSyncDelayed => 'Sync delayed';

  @override
  String get tailscaleNoPeers => 'No peers found';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'Tailscale is not supported on this platform.';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'Tailscale is not supported on Windows.';

  @override
  String get tailscalePeerOffline => 'offline';

  @override
  String get tailscaleSelectPeer => 'Select a Tailscale peer';

  @override
  String get tailscaleWaitingAdminApproval =>
      'This Tailscale node is waiting for admin approval.';

  @override
  String get terminalClose => 'Fechar terminal';

  @override
  String terminalConnectingTo(String serverName) {
    return 'Connecting to $serverName terminal...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'Terminal connection failed: $error';
  }

  @override
  String get terminalDisconnected => 'Terminal disconnected.';

  @override
  String terminalEmbeddedUnavailable(String serverName) {
    return 'Embedded terminal is not available on this runtime yet. Keep using composer shell mode for one-shot commands or open the terminal from a supported CodeWalk app runtime for $serverName.';
  }

  @override
  String get terminalHide => 'Hide terminal';

  @override
  String get terminalMaximize => 'Maximize';

  @override
  String get terminalMinimize => 'Minimizar terminal';

  @override
  String get terminalNotAvailableYet =>
      'Embedded terminal is not available on this runtime yet.';

  @override
  String get terminalOpen => 'Open terminal';

  @override
  String get terminalOpenInfo => 'Open terminal info';

  @override
  String get terminalOpenProjectFirst =>
      'Open a project folder before starting the server terminal.';

  @override
  String get terminalOpenToConnect =>
      'Open Terminal to connect to the server project terminal.';

  @override
  String get terminalReconnect => 'Reconectar terminal';

  @override
  String get terminalRestoreSize => 'Restore size';

  @override
  String get terminalSelectServer =>
      'Select an active server before opening Terminal.';

  @override
  String get terminalSessionClosed => 'Terminal session closed.';

  @override
  String get terminalTerminal => 'Terminal';

  @override
  String get terminalTitle => 'Terminal';

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
  String toolPresentationRunningTool(String toolName) {
    return 'Running $toolName';
  }

  @override
  String get toolPresentationSearching => 'Searching';

  @override
  String get toolPresentationSearchingCode => 'Searching code';

  @override
  String get toolPresentationSearchingWeb => 'Searching the web';

  @override
  String get toolPresentationTool => 'Tool';

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
  String get utilityTitle => 'Utility';

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
}
