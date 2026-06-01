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
      'ローカルの OpenCode 要件を確認するために診断を実行してください。';

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
  String get onboardingSetup => 'セットアップ';

  @override
  String get onboardingSetupWizard => 'セットアップウィザード';

  @override
  String get onboardingServerSetup => 'サーバーセットアップ';

  @override
  String get onboardingEditServer => 'サーバーを編集';

  @override
  String get onboardingLocalServerSetup => 'ローカルサーバーのセットアップ';

  @override
  String get onboardingReady => '準備完了';

  @override
  String onboardingWelcomeTo(String appName) {
    return '$appName へようこそ';
  }

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName がコードの支援を行うには、OpenCode サーバーが必要です。';
  }

  @override
  String get onboardingChooseHowToSetup => 'サーバーのセットアップ方法を選択してください';

  @override
  String get onboardingPickSetupPath =>
      '現在の OpenCode セットアップに一致するセットアップパスを選択してください。';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'デスクトップのみ: $appName は OpenCode の診断、インストール、実行を代行できます。';
  }

  @override
  String get onboardingAvailableOnlyDesktop =>
      'デスクトップ（Linux/macOS/Windows）でのみ利用可能です。';

  @override
  String get onboardingServerConnection => 'サーバー接続';

  @override
  String get onboardingEditServerConnection => 'サーバー接続を編集';

  @override
  String onboardingSuggestedUrl(String url) {
    return '推奨されるローカル OpenCode サーバー URL: $url';
  }

  @override
  String get onboardingEmulatorRemap =>
      'Android エミュレーターでは、localhost と 127.0.0.1 は自動的に 10.0.2.2 にリマップされます。';

  @override
  String get onboardingBasicAuthTip =>
      'OpenCode サーバーがパスワードで保護されている場合のみ、基本認証を有効にしてください。';

  @override
  String get onboardingEnterServerUrl => 'サーバーの URL を入力';

  @override
  String get onboardingInvalidUrl => '無効な URL';

  @override
  String get onboardingTesting => 'テスト中...';

  @override
  String get onboardingSaveAndTest => '保存してテスト';

  @override
  String get onboardingTestConnection => '接続をテスト';

  @override
  String get onboardingTailscaleLoginRequired => 'Tailscale へのログインが必要です';

  @override
  String get onboardingTailscaleAdminApproval => 'Tailscale 管理者の承認が必要です';

  @override
  String get onboardingTailscaleConnected => 'Tailscale 接続済み';

  @override
  String get onboardingTailscaleConnecting => 'Tailscale 接続中';

  @override
  String get onboardingTailscaleConnectionFailed => 'Tailscale 接続失敗';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale 非サポート';

  @override
  String get onboardingTailscaleAuthAfterSave => '保存後に Tailscale の認証が行われます';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'ログイン URL を開いて、このデバイスを tailnet に追加してください。ブラウザが開かなかった場合は、以下の URL をコピーしてください。';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'このサーバーを保存してテストした後、このデバイスがまだ認証されていない場合は、$appName が Tailscale のログイン画面を開きます。';
  }

  @override
  String get onboardingStarting => '起動中';

  @override
  String get onboardingStopping => '停止中';

  @override
  String get onboardingFailed => '失敗';

  @override
  String get onboardingStopped => '停止';

  @override
  String get onboardingUsingDetectedCommand => '検出された OpenCode コマンドを使用しています。';

  @override
  String get onboardingContinue => '続行';

  @override
  String get onboardingDone => '完了';

  @override
  String get onboardingYoureAllSet => '準備が整いました！';

  @override
  String get onboardingServerUpdated => 'サーバーが更新されました';

  @override
  String get onboardingServerConnectedReady => 'サーバーが接続され、使用準備が整いました。';

  @override
  String get onboardingServerSettingsSaved => 'サーバー設定が保存され、ヘルスチェックが更新されました。';

  @override
  String onboardingStartUsing(String appName) {
    return '$appName を使い始める';
  }

  @override
  String get onboardingCouldNotVerify => 'サーバー接続を確認できませんでした。';

  @override
  String get onboardingCloudflareAuthFailed => 'Cloudflare Access の認証に失敗しました。';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'サーバーのヘルスチェックに失敗しました。まだ起動中の可能性があります。';

  @override
  String get onboardingConnectionUpdated => 'サーバー接続が正常に更新されました。';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'サーバーが追加されましたが、ヘルスチェックに失敗しました。まだ起動中の可能性があります。';

  @override
  String get onboardingConnectionSaved => 'サーバー接続が正常に保存されました。';

  @override
  String get onboardingAvailable => '利用可能';

  @override
  String get onboardingNotAvailable => '利用不可';

  @override
  String get onboardingReachable => '到達可能';

  @override
  String get onboardingUnreachable => '到達不能';

  @override
  String get onboardingWritable => '書き込み可能';

  @override
  String get onboardingNotWritable => '書き込み不可';

  @override
  String toolPresentationRunningTool(String toolName) {
    return '$toolName を実行中';
  }

  @override
  String get toolPresentationTool => 'ツール';

  @override
  String get shortcutGroupSession => 'セッション';

  @override
  String get shortcutGroupGeneral => '全般';

  @override
  String get shortcutGroupPrompt => 'プロンプト';

  @override
  String get shortcutGroupNavigation => 'ナビゲーション';

  @override
  String get shortcutGroupModelAndAgent => 'モデルとエージェント';

  @override
  String get shortcutGroupApplication => 'アプリケーション';

  @override
  String get shortcutNewConversation => '新しい会話';

  @override
  String get shortcutNewConversationDesc => '新しいチャットセッションを作成';

  @override
  String get shortcutRefreshData => 'データを更新';

  @override
  String get shortcutRefreshDataDesc => '現在のチャットデータを更新';

  @override
  String get shortcutFocusInput => '入力にフォーカス';

  @override
  String get shortcutFocusInputDesc => 'テキスト入力にフォーカスを移動';

  @override
  String get shortcutToggleVoiceInput => '音声入力を切り替え';

  @override
  String get shortcutToggleVoiceInputDesc => 'エディタで音声入力を開始または停止';

  @override
  String get shortcutQuickOpenFiles => 'ファイルをクイックオープン';

  @override
  String get shortcutQuickOpenFilesDesc => 'ファイルクイック検索を開く';

  @override
  String get shortcutOpenSettings => '設定を開く';

  @override
  String get shortcutOpenSettingsDesc => '設定ページを開く';

  @override
  String get shortcutNextRecentModel => '次の最近のモデル';

  @override
  String get shortcutNextRecentModelDesc => '最近使用したモデルを切り替え';

  @override
  String get shortcutNextVariant => '次のバリアント';

  @override
  String get shortcutNextVariantDesc => '利用可能なモデルバリアントを切り替え';

  @override
  String get shortcutFocusCloseDrawer => 'フォーカス/ドロワーを閉じる';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'デフォルトで入力にフォーカス、または開いている場合はドロワーを閉じる';

  @override
  String get shortcutNextAgent => '次のエージェント';

  @override
  String get shortcutNextAgentDesc => '次の利用可能なエージェントに切り替え';

  @override
  String get shortcutPreviousAgent => '前のエージェント';

  @override
  String get shortcutPreviousAgentDesc => '前の利用可能なエージェントに切り替え';

  @override
  String get shortcutCloseApp => 'アプリを閉じる';

  @override
  String get shortcutCloseAppDesc => 'プラットフォームの終了動作を使用してアプリを閉じる';

  @override
  String get shortcutQuitApp => 'アプリを終了';

  @override
  String get shortcutQuitAppDesc => 'アプリを強制終了';

  @override
  String get shortcutStopResponse => '応答を停止';

  @override
  String get shortcutStopResponseDesc => 'アクティブな応答を停止（応答中）';

  @override
  String get errorConnectionFailed => '接続に失敗しました';

  @override
  String get errorConnectionFailedDesc => 'サーバーに接続できません。接続とサーバーの状態を確認してください。';

  @override
  String get errorQuotaExceeded => 'クォータを超過しました';

  @override
  String get errorQuotaExceededDesc => 'クォータを超過しました。プロバイダーのプランまたは請求を確認してください。';

  @override
  String get errorRateLimitExceeded => 'レート制限を超過しました';

  @override
  String get errorRateLimitExceededDesc => 'レート制限を超過しました。しばらく待ってからもう一度お試しください。';

  @override
  String get errorAuthRequired => '認証が必要です';

  @override
  String get errorAuthRequiredDesc => '認証に失敗しました。プロバイダーを再接続して、もう一度お試しください。';

  @override
  String get errorServiceUnavailable => 'サービスを利用できません';

  @override
  String get errorServiceUnavailableDesc =>
      'サービスは一時的に利用できません。サーバーが起動中の可能性があります。しばらくしてからもう一度お試しください。';

  @override
  String get errorProviderUnavailable => 'プロバイダーを利用できません';

  @override
  String get errorProviderUnavailableDesc =>
      'プロバイダーが一時的に利用できません。しばらくしてからもう一度お試しください。';

  @override
  String get errorServerError => 'サーバーエラー';

  @override
  String get errorServerErrorDesc => 'サーバーエラーが発生しました。もう一度お試しください。';

  @override
  String get attachmentNotAvailableOnPlatform =>
      '添付ファイルのアクションはこのプラットフォームでは利用できません。';

  @override
  String get attachmentUnableToOpenLink => '添付ファイルのリンクを開けません。';

  @override
  String get attachmentNoValidLocation => '添付ファイルに有効な場所が指定されていません。';

  @override
  String get attachmentDownloadStarted => '添付ファイルのダウンロードを開始しました。';

  @override
  String get attachmentCouldNotDownload => '添付ファイルをダウンロードできませんでした。';

  @override
  String get attachmentCouldNotDecode => '添付ファイルデータをデコードできませんでした。';

  @override
  String get attachmentPayloadEmpty => '添付ファイルのペイロードが空です。';

  @override
  String attachmentSavedAndOpened(String path) {
    return '添付ファイルを $path に保存して開きました。';
  }

  @override
  String attachmentSavedTo(String path) {
    return '添付ファイルを $path に保存しました。';
  }

  @override
  String get attachmentCouldNotSave => '添付ファイルをこのデバイスに保存できませんでした。';

  @override
  String get attachmentSaveCanceled => '保存がキャンセルされました。';

  @override
  String attachmentSavedPath(String path) {
    return '添付ファイルを $path に保存しました。';
  }

  @override
  String get attachmentPathEmpty => '添付ファイルのパスが空です。';

  @override
  String get attachmentLocalNotFound => 'ローカルの添付ファイルがこのデバイスで見つかりませんでした。';

  @override
  String get attachmentUnableToOpenLocal => 'ローカルの添付ファイルを開けません。';

  @override
  String speechDesktopOnly(String service) {
    return '$service はデスクトップでのみ利用可能です。';
  }

  @override
  String speechRuntimeFailed(String service) {
    return '$service ランタイムの初期化に失敗しました。';
  }

  @override
  String speechModelFilesIncomplete(String service) {
    return '$service のモデルファイルが不完全です。';
  }

  @override
  String get speechMicPermissionDisabled => 'マイクの権限が無効です。';

  @override
  String speechUnavailableOnPlatform(String service) {
    return '$service 音声はこのプラットフォームでは利用できません。';
  }

  @override
  String get terminalOpenToConnect => 'ターミナルを開いて、サーバープロジェクトターミナルに接続してください。';

  @override
  String get terminalNotAvailableYet => '埋め込みターミナルはこのランタイムではまだ利用できません。';

  @override
  String get terminalSelectServer => 'ターミナルを開く前に、アクティブなサーバーを選択してください。';

  @override
  String get terminalOpenProjectFirst => 'サーバーターミナルを開始する前に、プロジェクトフォルダを開いてください。';

  @override
  String terminalConnectingTo(String serverName) {
    return '$serverName ターミナルに接続中...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'ターミナル接続に失敗しました: $error';
  }

  @override
  String get terminalDisconnected => 'ターミナルが切断されました。';

  @override
  String get terminalSessionClosed => 'ターミナルセッションが終了しました。';

  @override
  String get notificationConversationUpdates => '会話の更新';

  @override
  String get notificationOpenToClear => '関連する通知を消去するには、この会話を開いてください。';

  @override
  String get notificationAgentFinished => 'エージェントが現在の応答を完了しました。';

  @override
  String get notificationSession => 'セッション';

  @override
  String get chatBadgeServerNeedsAttention => 'サーバー接続に注意が必要です。';

  @override
  String chatBadgeConversationError(String title) {
    return '「$title」にエラーがあります。';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '「$title」はあなたの入力を待っています。';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '「$title」に新しい返信があります。';
  }

  @override
  String get chatBadgeSyncing => '会話を同期中...';

  @override
  String get chatBadgeDataSaverActive => 'データ節約モードが有効です。';

  @override
  String get chatCollapseGroup => 'グループを折りたたむ';

  @override
  String get chatExpandGroup => 'グループを展開';

  @override
  String get chatForkFailed => '会話のフォークに失敗しました';

  @override
  String get chatForked => '会話をフォークしました';

  @override
  String get chatNoConversationsInProject => 'このプロジェクトには会話がありません。';

  @override
  String get chatOpenProjectToLoad => 'プロジェクトを開いて会話を読み込んでください。';

  @override
  String get chatExportCanceled => 'セッションのエクスポートがキャンセルされました';

  @override
  String get chatLargeContentSkipped =>
      '安定性のため、サイズの大きいコンテンツまたは不正な形式のコンテンツはスキップされました。';

  @override
  String chatTokensLabel(int total) {
    return 'トークン: $total';
  }

  @override
  String chatCostLabel(String cost) {
    return 'コスト: \$$cost';
  }

  @override
  String get chatFileExplorerNames => '名前';

  @override
  String get chatFileExplorerContents => '内容';

  @override
  String chatCloseProject(String project) {
    return '$project を閉じる';
  }

  @override
  String get sessionExportUser => 'ユーザー';

  @override
  String get sessionExportAssistant => 'アシスタント';

  @override
  String get sessionExportInput => '入力:';

  @override
  String get sessionExportOutput => '出力:';

  @override
  String get sessionExportError => 'エラー:';

  @override
  String get sessionExportUntitled => '無題のセッション';

  @override
  String get modelLabelTinyEnglish => 'Tiny (英語)';

  @override
  String get modelLabelBaseEnglish => 'ベース (英語)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (欧州25言語)';

  @override
  String get cannedNewQuickReply => '新しいクイック返信';

  @override
  String get settingsSoundPickerNotAvailable =>
      'システムサウンドピッカーはこのプラットフォームでは利用できません。';

  @override
  String get appProviderPrimaryServer => 'プライマリサーバー';

  @override
  String get appProviderLocalManaged => 'ローカル OpenCode (管理対象)';

  @override
  String get appProviderLocalServerStopped => 'ローカルサーバーは停止しています。';

  @override
  String get appProviderRunDiagnostics =>
      'ローカルの OpenCode 要件を確認するために診断を実行してください。';

  @override
  String get appProviderInvalidServerUrl => '無効なサーバー URL';

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth はこのプラットフォームではサポートされていません';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale はこのプラットフォームではサポートされていません';

  @override
  String get appProviderProfileNotFound => 'サーバープロファイルが見つかりません';

  @override
  String get appProviderCannotActivateUnhealthy => '異常なサーバーを有効化できません';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode を検出しました';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode が検出されませんでした';

  @override
  String get appProviderDetectingCommand => 'OpenCode コマンドを検出中...';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'OpenCode コマンドが検出されませんでした。インストールしたばかりの場合は、チェックを更新するか $appName を再起動して PATH を再読み込みしてください。';
  }

  @override
  String get appProviderNotDetectedInstall =>
      'OpenCode コマンドが検出されませんでした。ウィザードからインストールを実行してください。';

  @override
  String appProviderUsingCommandAt(String path) {
    return '$path の OpenCode コマンドを使用中';
  }

  @override
  String get appProviderDesktopOnly => '管理対象ローカルサーバーはデスクトップでのみ利用可能です。';

  @override
  String get appProviderInstallingRequirements => 'OpenCode の要件をインストール中...';

  @override
  String get appProviderInstallationFailed => 'OpenCode のインストールに失敗しました。';

  @override
  String get appProviderInstalledSuccessfully => 'OpenCode の要件が正常にインストールされました。';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'インストールが成功しました。OpenCode コマンドは $path で利用可能です。';
  }

  @override
  String get appProviderInstallSucceeded => 'インストールが成功しました。';

  @override
  String get appProviderStartingLocalServer => 'ローカルサーバーを起動中...';

  @override
  String get appProviderFailedToStart => 'ローカル OpenCode サーバーの起動に失敗しました。';

  @override
  String appProviderRunningAt(String url) {
    return '$url で実行中';
  }

  @override
  String get appProviderStoppingLocalServer => 'ローカルサーバーを停止中...';

  @override
  String appProviderExitedWithCode(int code) {
    return 'ローカルサーバーがコード $code で終了しました。';
  }

  @override
  String get appProviderInstallBinary => 'バイナリをインストール';

  @override
  String get appProviderInstallViaNpm => 'npm 経由でインストール';

  @override
  String get appProviderInstallViaBun => 'Bun 経由でインストール';

  @override
  String get appProviderInstallBunOpenCode => 'Bun + OpenCode をインストール';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'Tailscale はこのプラットフォームではサポートされていません。';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'Tailscale は Windows ではサポートされていません。';

  @override
  String get tailscaleWaitingAdminApproval => 'この Tailscale ノードは管理者の承認待ちです。';

  @override
  String get notificationSoundLoadFailed => 'Androidシステムサウンドの読み込みに失敗しました';

  @override
  String get chatDescriptionNewConversation => '新しい会話';

  @override
  String get chatDescriptionRefreshData => 'チャットデータを更新';

  @override
  String get chatDescriptionFocusInput => 'メッセージ入力にフォーカス';

  @override
  String get chatDescriptionVoiceInput => '音声入力を開始または停止';

  @override
  String get chatDescriptionQuickOpen => 'ファイルをクイックオープン';

  @override
  String get chatDescriptionOpenSettings => '設定を開く';

  @override
  String get chatDescriptionCycleModels => '最近のモデルを切り替える';

  @override
  String get chatDescriptionCycleVariant => 'モデルバリアントを切り替える';

  @override
  String get chatDescriptionFocusOrCloseDrawer => '入力にフォーカス（開いている場合はドロワーを閉じる）';

  @override
  String get chatDescriptionNextAgent => '次のエージェント';

  @override
  String get chatDescriptionPreviousAgent => '前のエージェント';

  @override
  String get chatDescriptionCloseApp => 'プラットフォームの終了動作を使用してアプリを閉じる';

  @override
  String get chatDescriptionForceExit => 'アプリを強制終了する';

  @override
  String get chatDescriptionStopResponse => 'アクティブな応答を停止（応答中）';

  @override
  String get chatDescriptionProjectCommand => 'プロジェクトコマンド';

  @override
  String get chatDescriptionOpenProjects => 'このボタンを使用してプロジェクトや会話を開きます。';

  @override
  String get chatDescriptionSwitchProject =>
      'このボタンを使用してプロジェクトフォルダとコンテキストを切り替えます。';

  @override
  String chatDescriptionChildren(int count) {
    return '子要素: $count';
  }

  @override
  String get chatDescriptionDiffFilesZero => '差分ファイル: 0';

  @override
  String get appProviderErrorInvalidServerUrl => '無効なサーバー URL';

  @override
  String get appProviderErrorServerUrlRequired => 'サーバー URL は必須です';

  @override
  String get appProviderErrorServerAlreadyExists => 'この URL のサーバーは既に存在します';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth はこのプラットフォームではサポートされていません';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale はこのプラットフォームではサポートされていません';

  @override
  String get appProviderErrorServerProfileNotFound => 'サーバープロファイルが見つかりません';

  @override
  String get appProviderErrorCannotActivateUnhealthy => '異常なサーバーを有効化できません';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      '管理対象ローカルサーバーはデスクトップでのみ利用可能です。';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'ローカルサーバーは起動しましたが、ヘルスチェックに合格しませんでした。';

  @override
  String get appProviderErrorInstallationFailed => 'OpenCode のインストールに失敗しました。';

  @override
  String get appProviderStatusLocalServerStopped => 'ローカルサーバーは停止しています。';

  @override
  String get appProviderStatusStartingLocalServer => 'ローカルサーバーを起動中...';

  @override
  String appProviderStatusRunningAt(String url) {
    return '$url で実行中';
  }

  @override
  String get appProviderStatusStoppingLocalServer => 'ローカルサーバーを停止中...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'ローカルサーバーがコード $code で終了しました。';
  }

  @override
  String get appProviderSetupDetectingOpenCode => 'OpenCode コマンドを検出中...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode を検出しました';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode が検出されませんでした';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return '$path の OpenCode コマンドを使用中';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'OpenCode の要件をインストール中...';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'OpenCode の要件が正常にインストールされました。';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'インストールが成功しました。OpenCode コマンドは $path で利用可能です。';
  }

  @override
  String get appProviderSetupInstallationSucceeded => 'インストールが成功しました。';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'OpenCode コマンドが検出されませんでした。インストールしたばかりの場合は、チェックを更新するか CodeWalk を再起動して PATH を再読み込みしてください。';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'OpenCode コマンドが検出されませんでした。ウィザードからインストールを実行してください。';

  @override
  String get appProviderLabelPrimaryServer => 'プライマリサーバー';

  @override
  String get appProviderLabelLocalOpenCodeManaged => 'ローカル OpenCode (管理対象)';
}
