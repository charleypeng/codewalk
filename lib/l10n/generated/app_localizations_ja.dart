// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appShellDownloadingUpdate => 'アップデートをダウンロード中';

  @override
  String get appShellInstall => 'インストール';

  @override
  String get appShellInstallFailed => 'インストールに失敗しました';

  @override
  String get appShellInstallingUpdate => 'アップデートをインストール中...';

  @override
  String get appShellRestart => '再起動';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return 'アップデートあり: v$latestVersion';
  }

  @override
  String get behaviorAdvancedPermissionRule => '高度な権限ルール';

  @override
  String get behaviorAutomatic => '自動';

  @override
  String get behaviorAutomaticFallback => '自動フォールバック';

  @override
  String get behaviorCellularDataSaver => 'モバイルデータセーバー';

  @override
  String get behaviorChatLevelShare => 'チャットレベル共有';

  @override
  String get behaviorCodeWalkReleaseChecks => 'CodeWalkリリースチェック';

  @override
  String get behaviorControlsOfficialGlobal => 'OpenCodeの公式グローバル設定を制御';

  @override
  String get behaviorControlsUpstreamOpenCode => 'アップストリームOpenCode設定を制御';

  @override
  String get behaviorCustomDisplayName => 'カスタム表示名';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return 'バックグラウンドダウンロードを停止し、フォアグラウンドの自動更新を$inSeconds秒ごとに1回のバーストに制限することで、自動モバイルデータ使用量を削減します。';
  }

  @override
  String get behaviorDisabled => '無効';

  @override
  String get behaviorLightweightTasksLike => '次のような軽量タスク';

  @override
  String get behaviorManual => '手動';

  @override
  String get behaviorNotify => '通知';

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
    return '子: $length';
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
  String get chatDoubleESCStop => 'ESCを2回押して停止';

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
    return '$compactionLabel圧縮前に$messageCount件のメッセージが非表示';
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
    return 'モデル: $modelId';
  }

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return 'プロバイダー: $providerId';
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
  String get chatOpenProject => 'プロジェクトを開く';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenSidebar => 'サイドバーを開く';

  @override
  String get chatPageStatusContextUsage => 'コンテキスト使用量';

  @override
  String get chatPageStatusCost => 'コスト';

  @override
  String get chatPageStatusLimit => '制限';

  @override
  String get chatPageStatusManageServers => 'サーバーを管理';

  @override
  String get chatPageStatusSaver => 'セーバー';

  @override
  String get chatPageStatusSwitchServer => 'サーバーを切り替え';

  @override
  String get chatPageStatusTokens => 'トークン';

  @override
  String get chatPageStatusUsage => '使用量';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatProjectContext => 'Project Context';

  @override
  String get chatProjectContext2 => 'プロジェクトコンテキスト';

  @override
  String get chatRealtimeGlobalEvent => 'グローバルイベント';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return 'グローバルイベント ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale => 'グローバルイベント (古い世代)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return 'メッセージストリーム ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => 'リアルタイムイベント';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return 'リアルタイムイベント ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale => 'リアルタイムイベント (古い世代)';

  @override
  String get chatRealtimeReconnectingServerTry =>
      'サーバーに再接続中。しばらくしてからもう一度お試しください。';

  @override
  String get chatReasoning => '推論中...';

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
    return '履歴から$displayNameを削除';
  }

  @override
  String get chatRetry => 'Retry';

  @override
  String get chatRetry2 => 'Retry';

  @override
  String get chatRetryRefresh => 'Retry refresh';

  @override
  String get chatRetryingModelRequest => 'モデルリクエストを再試行中...';

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
    return 'チャットセッション: $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return '会話 $nextAction';
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
  String get chatSidebarAccess => 'サイドバーアクセス';

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
    return '同期: $label';
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
    return '添付ファイルを$pathに保存して開きました。';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return '添付ファイルを$pathに保存しました。';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return '添付ファイルを$savedPathに保存しました。';
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
    return '開いているファイル ($length)';
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
    return '$length2件中$length件のエントリを表示';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => '数式';

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
    return 'サブタスク ($agent)';
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
    return '選択済み: $soundLabel';
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
    return '$length件のセットアップログ行と$length2件のセットアップイベントが別のセットアップデバッグ画面で利用できます。';
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
    return '最新の出力: $localServerLastOutput';
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
      'Run diagnostics to verify local OpenCode requirements.';

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
    return 'コマンド: $localServerCommandPath';
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
    return '\"$displayName\"を削除しますか？';
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
  String get settingsAppearanceMathRendering => '数式レンダリング';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      'チャットメッセージでLaTeX数式を組版済み方程式としてレンダリングします。';

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
    return '$conflictと競合';
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
    return 'ショートカットを設定: $label';
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
  String get onboardingSetup => 'Setup';

  @override
  String get onboardingSetupWizard => 'Setup wizard';

  @override
  String get onboardingServerSetup => 'Server setup';

  @override
  String get onboardingEditServer => 'Edit server';

  @override
  String get onboardingLocalServerSetup => 'Local server setup';

  @override
  String get onboardingReady => 'Ready';

  @override
  String onboardingWelcomeTo(String appName) {
    return 'Welcome to $appName';
  }

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName needs an OpenCode server before it can help with your code.';
  }

  @override
  String get onboardingChooseHowToSetup => 'Choose how to set up your server';

  @override
  String get onboardingPickSetupPath =>
      'Pick the setup path that matches your current OpenCode setup.';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'Desktop only: $appName can diagnose, install, and run OpenCode for you.';
  }

  @override
  String get onboardingAvailableOnlyDesktop =>
      'Available only on desktop (Linux/macOS/Windows).';

  @override
  String get onboardingServerConnection => 'Server connection';

  @override
  String get onboardingEditServerConnection => 'Edit server connection';

  @override
  String onboardingSuggestedUrl(String url) {
    return 'Suggested local OpenCode server URL: $url';
  }

  @override
  String get onboardingEmulatorRemap =>
      'On Android emulator, localhost and 127.0.0.1 are remapped to 10.0.2.2 automatically.';

  @override
  String get onboardingBasicAuthTip =>
      'Enable Basic Auth only if your OpenCode server is password-protected.';

  @override
  String get onboardingEnterServerUrl => 'Enter a server URL';

  @override
  String get onboardingInvalidUrl => 'Invalid URL';

  @override
  String get onboardingTesting => 'Testing...';

  @override
  String get onboardingSaveAndTest => 'Save and test';

  @override
  String get onboardingTestConnection => 'Test connection';

  @override
  String get onboardingTailscaleLoginRequired => 'Tailscale login required';

  @override
  String get onboardingTailscaleAdminApproval =>
      'Tailscale admin approval required';

  @override
  String get onboardingTailscaleConnected => 'Tailscale connected';

  @override
  String get onboardingTailscaleConnecting => 'Tailscale connecting';

  @override
  String get onboardingTailscaleConnectionFailed =>
      'Tailscale connection failed';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale unsupported';

  @override
  String get onboardingTailscaleAuthAfterSave =>
      'Tailscale will authenticate after saving';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'Open the login URL to add this device to your tailnet. If the browser did not open, copy the URL below.';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'After you save and test this server, $appName will open Tailscale login if this device is not authenticated yet.';
  }

  @override
  String get onboardingStarting => 'Starting';

  @override
  String get onboardingStopping => 'Stopping';

  @override
  String get onboardingFailed => 'Failed';

  @override
  String get onboardingStopped => 'Stopped';

  @override
  String get onboardingUsingDetectedCommand =>
      'Using detected OpenCode command.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingDone => 'Done';

  @override
  String get onboardingYoureAllSet => 'You\'re all set!';

  @override
  String get onboardingServerUpdated => 'Server updated';

  @override
  String get onboardingServerConnectedReady =>
      'Your server is connected and ready to use.';

  @override
  String get onboardingServerSettingsSaved =>
      'Your server settings were saved and health checks were refreshed.';

  @override
  String onboardingStartUsing(String appName) {
    return 'Start using $appName';
  }

  @override
  String get onboardingCouldNotVerify =>
      'Could not verify the server connection.';

  @override
  String get onboardingCloudflareAuthFailed =>
      'Cloudflare Access authentication failed.';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'Server health check failed. It may still be starting up.';

  @override
  String get onboardingConnectionUpdated =>
      'Server connection updated successfully.';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'Server added but health check failed. It may still be starting up.';

  @override
  String get onboardingConnectionSaved =>
      'Server connection saved successfully.';

  @override
  String get onboardingAvailable => 'available';

  @override
  String get onboardingNotAvailable => 'not available';

  @override
  String get onboardingReachable => 'reachable';

  @override
  String get onboardingUnreachable => 'unreachable';

  @override
  String get onboardingWritable => 'writable';

  @override
  String get onboardingNotWritable => 'not writable';

  @override
  String toolPresentationRunningTool(String toolName) {
    return 'Running $toolName';
  }

  @override
  String get toolPresentationTool => 'Tool';

  @override
  String get shortcutGroupSession => 'Session';

  @override
  String get shortcutGroupGeneral => 'General';

  @override
  String get shortcutGroupPrompt => 'Prompt';

  @override
  String get shortcutGroupNavigation => 'Navigation';

  @override
  String get shortcutGroupModelAndAgent => 'Model and agent';

  @override
  String get shortcutGroupApplication => 'Application';

  @override
  String get shortcutNewConversation => 'New conversation';

  @override
  String get shortcutNewConversationDesc => 'Create a new chat session';

  @override
  String get shortcutRefreshData => 'Refresh data';

  @override
  String get shortcutRefreshDataDesc => 'Refresh current chat data';

  @override
  String get shortcutFocusInput => 'Focus input';

  @override
  String get shortcutFocusInputDesc => 'Move focus to the prompt input';

  @override
  String get shortcutToggleVoiceInput => 'Toggle voice input';

  @override
  String get shortcutToggleVoiceInputDesc =>
      'Start or stop speech-to-text in the composer';

  @override
  String get shortcutQuickOpenFiles => 'Quick open files';

  @override
  String get shortcutQuickOpenFilesDesc => 'Open file quick search';

  @override
  String get shortcutOpenSettings => 'Open settings';

  @override
  String get shortcutOpenSettingsDesc => 'Open settings page';

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
  String get shortcutFocusCloseDrawer => 'Focus/close drawer';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'Focus composer by default, or close drawer when open';

  @override
  String get shortcutNextAgent => 'Next agent';

  @override
  String get shortcutNextAgentDesc => 'Cycle to next available agent';

  @override
  String get shortcutPreviousAgent => 'Previous agent';

  @override
  String get shortcutPreviousAgentDesc => 'Cycle to previous available agent';

  @override
  String get shortcutCloseApp => 'Close application';

  @override
  String get shortcutCloseAppDesc => 'Close app using platform close behavior';

  @override
  String get shortcutQuitApp => 'Quit application';

  @override
  String get shortcutQuitAppDesc => 'Force-exit the app';

  @override
  String get shortcutStopResponse => 'Stop active response';

  @override
  String get shortcutStopResponseDesc =>
      'Stop active response (while responding)';

  @override
  String get errorConnectionFailed => 'Connection failed';

  @override
  String get errorConnectionFailedDesc =>
      'Unable to reach the server. Check connection and server status.';

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
  String get errorAuthRequired => 'Authentication required';

  @override
  String get errorAuthRequiredDesc =>
      'Authentication failed. Reconnect the provider and try again.';

  @override
  String get errorServiceUnavailable => 'Service unavailable';

  @override
  String get errorServiceUnavailableDesc =>
      'Service temporarily unavailable. The server may be starting up — please try again shortly.';

  @override
  String get errorProviderUnavailable => 'Provider unavailable';

  @override
  String get errorProviderUnavailableDesc =>
      'Provider temporarily unavailable. Try again shortly.';

  @override
  String get errorServerError => 'Server error';

  @override
  String get errorServerErrorDesc => 'Server error. Please try again.';

  @override
  String get attachmentNotAvailableOnPlatform =>
      'Attachment actions are not available on this platform.';

  @override
  String get attachmentUnableToOpenLink =>
      'Unable to open the attachment link.';

  @override
  String get attachmentNoValidLocation =>
      'Attachment does not provide a valid location.';

  @override
  String get attachmentDownloadStarted => 'Attachment download started.';

  @override
  String get attachmentCouldNotDownload =>
      'Attachment could not be downloaded.';

  @override
  String get attachmentCouldNotDecode =>
      'Attachment data could not be decoded.';

  @override
  String get attachmentPayloadEmpty => 'Attachment payload is empty.';

  @override
  String attachmentSavedAndOpened(String path) {
    return 'Attachment saved to $path and opened.';
  }

  @override
  String attachmentSavedTo(String path) {
    return 'Attachment saved to $path.';
  }

  @override
  String get attachmentCouldNotSave =>
      'Attachment could not be saved on this device.';

  @override
  String get attachmentSaveCanceled => 'Save canceled.';

  @override
  String attachmentSavedPath(String path) {
    return 'Attachment saved to $path.';
  }

  @override
  String get attachmentPathEmpty => 'Attachment path is empty.';

  @override
  String get attachmentLocalNotFound =>
      'Local attachment was not found on this device.';

  @override
  String get attachmentUnableToOpenLocal =>
      'Unable to open the local attachment.';

  @override
  String speechDesktopOnly(String service) {
    return '$service is available on desktop only.';
  }

  @override
  String speechRuntimeFailed(String service) {
    return '$service runtime failed to initialize.';
  }

  @override
  String speechModelFilesIncomplete(String service) {
    return '$service model files are incomplete.';
  }

  @override
  String get speechMicPermissionDisabled =>
      'Microphone permission is disabled.';

  @override
  String speechUnavailableOnPlatform(String service) {
    return '$service speech is unavailable on this platform.';
  }

  @override
  String get terminalOpenToConnect =>
      'Open Terminal to connect to the server project terminal.';

  @override
  String get terminalNotAvailableYet =>
      'Embedded terminal is not available on this runtime yet.';

  @override
  String get terminalSelectServer =>
      'Select an active server before opening Terminal.';

  @override
  String get terminalOpenProjectFirst =>
      'Open a project folder before starting the server terminal.';

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
  String get terminalSessionClosed => 'Terminal session closed.';

  @override
  String get notificationConversationUpdates => 'Conversation updates';

  @override
  String get notificationOpenToClear =>
      'Open this conversation to clear related notifications.';

  @override
  String get notificationAgentFinished =>
      'Agent finished the current response.';

  @override
  String get notificationSession => 'Session';

  @override
  String get chatBadgeServerNeedsAttention =>
      'Server connection needs attention.';

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
  String get chatBadgeSyncing => 'Syncing conversations...';

  @override
  String get chatBadgeDataSaverActive => 'Cellular data saver is active.';

  @override
  String get chatCollapseGroup => 'Collapse group';

  @override
  String get chatExpandGroup => 'Expand group';

  @override
  String get chatForkFailed => 'Failed to fork conversation';

  @override
  String get chatForked => 'Conversation forked';

  @override
  String get chatNoConversationsInProject =>
      'No conversations in this project.';

  @override
  String get chatOpenProjectToLoad => 'Open project to load conversations.';

  @override
  String get chatExportCanceled => 'Session export canceled';

  @override
  String get chatLargeContentSkipped =>
      'Large or malformed content was skipped for stability.';

  @override
  String chatTokensLabel(int total) {
    return 'Tokens: $total';
  }

  @override
  String chatCostLabel(String cost) {
    return 'Cost: \$$cost';
  }

  @override
  String get chatFileExplorerNames => 'Names';

  @override
  String get chatFileExplorerContents => 'Contents';

  @override
  String chatCloseProject(String project) {
    return 'Close $project';
  }

  @override
  String get sessionExportUser => 'User';

  @override
  String get sessionExportAssistant => 'Assistant';

  @override
  String get sessionExportInput => 'Input:';

  @override
  String get sessionExportOutput => 'Output:';

  @override
  String get sessionExportError => 'Error:';

  @override
  String get sessionExportUntitled => 'Untitled session';

  @override
  String get modelLabelTinyEnglish => 'Tiny (English)';

  @override
  String get modelLabelBaseEnglish => 'Base (English)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 European languages)';

  @override
  String get cannedNewQuickReply => 'New quick reply';

  @override
  String get settingsSoundPickerNotAvailable =>
      'System sound picker is not available on this platform.';

  @override
  String get appProviderPrimaryServer => 'Primary server';

  @override
  String get appProviderLocalManaged => 'Local OpenCode (Managed)';

  @override
  String get appProviderLocalServerStopped => 'Local server is stopped.';

  @override
  String get appProviderRunDiagnostics =>
      'Run diagnostics to verify local OpenCode requirements.';

  @override
  String get appProviderInvalidServerUrl => 'Invalid server URL';

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth is not supported on this platform';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale is not supported on this platform';

  @override
  String get appProviderProfileNotFound => 'Server profile not found';

  @override
  String get appProviderCannotActivateUnhealthy =>
      'Cannot activate an unhealthy server';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode detected';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode not detected';

  @override
  String get appProviderDetectingCommand => 'Detecting OpenCode command...';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'OpenCode command was not detected. If you installed it moments ago, refresh checks or reopen $appName to reload PATH.';
  }

  @override
  String get appProviderNotDetectedInstall =>
      'OpenCode command was not detected. Run installation from the wizard.';

  @override
  String appProviderUsingCommandAt(String path) {
    return 'Using OpenCode command at $path';
  }

  @override
  String get appProviderDesktopOnly =>
      'Managed local server is available only on desktop.';

  @override
  String get appProviderInstallingRequirements =>
      'Installing OpenCode requirements...';

  @override
  String get appProviderInstallationFailed => 'OpenCode installation failed.';

  @override
  String get appProviderInstalledSuccessfully =>
      'OpenCode requirements installed successfully.';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'Installation succeeded. OpenCode command available at $path.';
  }

  @override
  String get appProviderInstallSucceeded => 'Installation succeeded.';

  @override
  String get appProviderStartingLocalServer => 'Starting local server...';

  @override
  String get appProviderFailedToStart =>
      'Failed to start local OpenCode server.';

  @override
  String appProviderRunningAt(String url) {
    return 'Running at $url';
  }

  @override
  String get appProviderStoppingLocalServer => 'Stopping local server...';

  @override
  String appProviderExitedWithCode(int code) {
    return 'Local server exited with code $code.';
  }

  @override
  String get appProviderInstallBinary => 'Install Binary';

  @override
  String get appProviderInstallViaNpm => 'Install via npm';

  @override
  String get appProviderInstallViaBun => 'Install via Bun';

  @override
  String get appProviderInstallBunOpenCode => 'Install Bun + OpenCode';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'Tailscale is not supported on this platform.';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'Tailscale is not supported on Windows.';

  @override
  String get tailscaleWaitingAdminApproval =>
      'This Tailscale node is waiting for admin approval.';

  @override
  String get notificationSoundLoadFailed =>
      'Failed to load Android system sounds';

  @override
  String get chatDescriptionNewConversation => 'New conversation';

  @override
  String get chatDescriptionRefreshData => 'Refresh chat data';

  @override
  String get chatDescriptionFocusInput => 'Focus message input';

  @override
  String get chatDescriptionVoiceInput => 'Start or stop voice input';

  @override
  String get chatDescriptionQuickOpen => 'Quick open files';

  @override
  String get chatDescriptionOpenSettings => 'Open settings';

  @override
  String get chatDescriptionCycleModels => 'Cycle recent models';

  @override
  String get chatDescriptionCycleVariant => 'Cycle model variant';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      'Focus input (or close drawer when open)';

  @override
  String get chatDescriptionNextAgent => 'Next agent';

  @override
  String get chatDescriptionPreviousAgent => 'Previous agent';

  @override
  String get chatDescriptionCloseApp =>
      'Close app using platform close behavior';

  @override
  String get chatDescriptionForceExit => 'Force-exit the app';

  @override
  String get chatDescriptionStopResponse =>
      'Stop active response (while responding)';

  @override
  String get chatDescriptionProjectCommand => 'Project command';

  @override
  String get chatDescriptionOpenProjects =>
      'Use this button to open your projects and conversations.';

  @override
  String get chatDescriptionSwitchProject =>
      'Use this button to switch project folders and context.';

  @override
  String chatDescriptionChildren(int count) {
    return 'Children: $count';
  }

  @override
  String get chatDescriptionDiffFilesZero => 'Diff files: 0';

  @override
  String get appProviderErrorInvalidServerUrl => 'Invalid server URL';

  @override
  String get appProviderErrorServerUrlRequired => 'Server URL is required';

  @override
  String get appProviderErrorServerAlreadyExists =>
      'A server with this URL already exists';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth is not supported on this platform';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale is not supported on this platform';

  @override
  String get appProviderErrorServerProfileNotFound =>
      'Server profile not found';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      'Cannot activate an unhealthy server';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      'Managed local server is available only on desktop.';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'Local server started but health check did not pass.';

  @override
  String get appProviderErrorInstallationFailed =>
      'OpenCode installation failed.';

  @override
  String get appProviderStatusLocalServerStopped => 'Local server is stopped.';

  @override
  String get appProviderStatusStartingLocalServer => 'Starting local server...';

  @override
  String appProviderStatusRunningAt(String url) {
    return 'Running at $url';
  }

  @override
  String get appProviderStatusStoppingLocalServer => 'Stopping local server...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'Local server exited with code $code.';
  }

  @override
  String get appProviderSetupDetectingOpenCode =>
      'Detecting OpenCode command...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode detected';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode not detected';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return 'Using OpenCode command at $path';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'Installing OpenCode requirements...';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'OpenCode requirements installed successfully.';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'Installation succeeded. OpenCode command available at $path.';
  }

  @override
  String get appProviderSetupInstallationSucceeded => 'Installation succeeded.';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'OpenCode command was not detected. If you installed it moments ago, refresh checks or reopen CodeWalk to reload PATH.';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'OpenCode command was not detected. Run installation from the wizard.';

  @override
  String get appProviderLabelPrimaryServer => 'Primary server';

  @override
  String get appProviderLabelLocalOpenCodeManaged => 'Local OpenCode (Managed)';
}
