// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appShellDownloadingUpdate => '업데이트 다운로드 중';

  @override
  String get appShellInstall => '설치';

  @override
  String get appShellInstallFailed => '설치 실패';

  @override
  String get appShellInstallingUpdate => '업데이트 설치 중...';

  @override
  String get appShellRestart => '재시작';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return '업데이트 가능: v$latestVersion';
  }

  @override
  String get behaviorAdvancedPermissionRule => '고급 권한 규칙';

  @override
  String get behaviorAutomatic => '자동';

  @override
  String get behaviorAutomaticFallback => '자동 대체';

  @override
  String get behaviorCellularDataSaver => '모바일 데이터 절약';

  @override
  String get behaviorChatLevelShare => '채팅 수준 공유';

  @override
  String get behaviorCodeWalkReleaseChecks => 'CodeWalk 릴리스 확인';

  @override
  String get behaviorControlsOfficialGlobal => 'OpenCode 공식 전역 설정 제어';

  @override
  String get behaviorControlsUpstreamOpenCode => '업스트림 OpenCode 설정 제어';

  @override
  String get behaviorCustomDisplayName => '사용자 지정 표시 이름';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return '백그라운드 다운로드를 중지하고 포그라운드 자동 새로고침을 $inSeconds초마다 한 번으로 제한하여 자동 모바일 데이터 사용량을 줄입니다.';
  }

  @override
  String get behaviorDisabled => '비활성화됨';

  @override
  String get behaviorLightweightTasksLike => '다음과 같은 가벼운 작업';

  @override
  String get behaviorManual => '수동';

  @override
  String get behaviorNotify => '알림';

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
    return '하위: $length';
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
  String get chatDoubleESCStop => 'ESC 두 번 눌러서 중지';

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
    return '$compactionLabel 압축 전 $messageCount개 메시지 숨김';
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
  String get chatMessageHide => '숨기기';

  @override
  String get chatMessageMessagePartUnavailable => 'Message part unavailable';

  @override
  String get chatMessageMetadataAvailable => 'No metadata available';

  @override
  String chatMessageModelMessageModelId(String modelId) {
    return '모델: $modelId';
  }

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return '제공자: $providerId';
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
  String get chatOpenProject => '프로젝트 열기';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenSidebar => '사이드바 열기';

  @override
  String get chatPageStatusContextUsage => '컨텍스트 사용량';

  @override
  String get chatPageStatusCost => '비용';

  @override
  String get chatPageStatusLimit => '제한';

  @override
  String get chatPageStatusManageServers => '서버 관리';

  @override
  String get chatPageStatusSaver => '절약';

  @override
  String get chatPageStatusSwitchServer => '서버 전환';

  @override
  String get chatPageStatusTokens => '토큰';

  @override
  String get chatPageStatusUsage => '사용량';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatProjectContext => 'Project Context';

  @override
  String get chatProjectContext2 => '프로젝트 컨텍스트';

  @override
  String get chatRealtimeGlobalEvent => '글로벌 이벤트';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return '글로벌 이벤트 ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale => '글로벌 이벤트 (오래된 세대)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return '메시지 스트림 ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => '실시간 이벤트';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return '실시간 이벤트 ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale => '실시간 이벤트 (오래된 세대)';

  @override
  String get chatRealtimeReconnectingServerTry => '서버에 재연결 중. 잠시 후 다시 시도하세요.';

  @override
  String get chatReasoning => '추론 중...';

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
    return '기록에서 $displayName 제거';
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
    return '채팅 세션: $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return '대화 $nextAction';
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
  String get chatSidebarAccess => '사이드바 액세스';

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
    return '동기화: $label';
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
    return '첨부파일이 $path에 저장되고 열렸습니다.';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return '첨부파일이 $path에 저장되었습니다.';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return '첨부파일이 $savedPath에 저장되었습니다.';
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
    return '열린 파일 ($length)';
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
    return '항목 $length2개 중 $length개 표시';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => '수식';

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
    return '하위 작업 ($agent)';
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
    return '선택됨: $soundLabel';
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
    return '$length개의 설정 로그 줄과 $length2개의 설정 이벤트가 별도의 설정 디버그 화면에서 사용 가능합니다.';
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
    return '최신 출력: $localServerLastOutput';
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
      '로컬 OpenCode 요구 사항을 확인하려면 진단을 실행하십시오.';

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
    return '명령: $localServerCommandPath';
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
    return '\"$displayName\"을(를) 제거하시겠습니까?';
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
  String get sessionCopyLink => '공유 링크 복사';

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
  String get settingsAppearanceMathRendering => '수식 렌더링';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      '채팅 메시지에서 LaTeX 수학 표현식을 조판된 방정식으로 렌더링합니다.';

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
    return '$conflict과(와) 충돌';
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
    return '단축키 설정: $label';
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
  String get onboardingSetup => '설정';

  @override
  String get onboardingSetupWizard => '설정 마법사';

  @override
  String get onboardingServerSetup => '서버 설정';

  @override
  String get onboardingEditServer => '서버 편집';

  @override
  String get onboardingLocalServerSetup => '로컬 서버 설정';

  @override
  String get onboardingReady => '준비됨';

  @override
  String onboardingWelcomeTo(String appName) {
    return '$appName에 오신 것을 환영합니다';
  }

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName을(를) 사용하여 코드를 작성하려면 OpenCode 서버가 필요합니다.';
  }

  @override
  String get onboardingChooseHowToSetup => '서버 설정 방법 선택';

  @override
  String get onboardingPickSetupPath => '현재 OpenCode 설정과 일치하는 설정 경로를 선택하십시오.';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return '데스크톱 전용: $appName은(는) 사용자를 대신하여 OpenCode를 진단, 설치 및 실행할 수 있습니다.';
  }

  @override
  String get onboardingAvailableOnlyDesktop =>
      '데스크톱(Linux/macOS/Windows)에서만 사용할 수 있습니다.';

  @override
  String get onboardingServerConnection => '서버 연결';

  @override
  String get onboardingEditServerConnection => '서버 연결 편집';

  @override
  String onboardingSuggestedUrl(String url) {
    return '제안된 로컬 OpenCode 서버 URL: $url';
  }

  @override
  String get onboardingEmulatorRemap =>
      'Android 에뮬레이터에서 localhost 및 127.0.0.1은 자동으로 10.0.2.2로 리맵됩니다.';

  @override
  String get onboardingBasicAuthTip =>
      'OpenCode 서버가 비밀번호로 보호되는 경우에만 기본 인증을 활성화하십시오.';

  @override
  String get onboardingEnterServerUrl => '서버 URL 입력';

  @override
  String get onboardingInvalidUrl => '유효하지 않은 URL';

  @override
  String get onboardingTesting => '테스트 중...';

  @override
  String get onboardingSaveAndTest => '저장 및 테스트';

  @override
  String get onboardingTestConnection => '연결 테스트';

  @override
  String get onboardingTailscaleLoginRequired => 'Tailscale 로그인 필요';

  @override
  String get onboardingTailscaleAdminApproval => 'Tailscale 관리자 승인 필요';

  @override
  String get onboardingTailscaleConnected => 'Tailscale 연결됨';

  @override
  String get onboardingTailscaleConnecting => 'Tailscale 연결 중';

  @override
  String get onboardingTailscaleConnectionFailed => 'Tailscale 연결 실패';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale 지원되지 않음';

  @override
  String get onboardingTailscaleAuthAfterSave => '저장 후 Tailscale 인증이 진행됩니다.';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      '로그인 URL을 열어 이 기기를 tailnet에 추가하십시오. 브라우저가 열리지 않으면 아래 URL을 복사하십시오.';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return '이 서버를 저장하고 테스트한 후, 이 기기가 아직 인증되지 않은 경우 $appName에서 Tailscale 로그인 페이지를 엽니다.';
  }

  @override
  String get onboardingStarting => '시작 중';

  @override
  String get onboardingStopping => '중지 중';

  @override
  String get onboardingFailed => '실패';

  @override
  String get onboardingStopped => '중지됨';

  @override
  String get onboardingUsingDetectedCommand => '감지된 OpenCode 명령을 사용합니다.';

  @override
  String get onboardingContinue => '계속';

  @override
  String get onboardingDone => '완료';

  @override
  String get onboardingYoureAllSet => '모든 준비가 완료되었습니다!';

  @override
  String get onboardingServerUpdated => '서버가 업데이트되었습니다.';

  @override
  String get onboardingServerConnectedReady => '서버가 연결되어 사용할 준비가 되었습니다.';

  @override
  String get onboardingServerSettingsSaved =>
      '서버 설정이 저장되었으며 상태 확인이 새로 고침되었습니다.';

  @override
  String onboardingStartUsing(String appName) {
    return '$appName 시작하기';
  }

  @override
  String get onboardingCouldNotVerify => '서버 연결을 확인할 수 없습니다.';

  @override
  String get onboardingCloudflareAuthFailed => 'Cloudflare Access 인증에 실패했습니다.';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      '서버 상태 확인에 실패했습니다. 아직 시작 중일 수 있습니다.';

  @override
  String get onboardingConnectionUpdated => '서버 연결이 성공적으로 업데이트되었습니다.';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      '서버가 추가되었지만 상태 확인에 실패했습니다. 아직 시작 중일 수 있습니다.';

  @override
  String get onboardingConnectionSaved => '서버 연결이 성공적으로 저장되었습니다.';

  @override
  String get onboardingAvailable => '사용 가능';

  @override
  String get onboardingNotAvailable => '사용 불가';

  @override
  String get onboardingReachable => '연결 가능';

  @override
  String get onboardingUnreachable => '연결 불가능';

  @override
  String get onboardingWritable => '쓰기 가능';

  @override
  String get onboardingNotWritable => '쓰기 불가';

  @override
  String toolPresentationRunningTool(String toolName) {
    return '$toolName 실행 중';
  }

  @override
  String get toolPresentationTool => '도구';

  @override
  String get shortcutGroupSession => '세션';

  @override
  String get shortcutGroupGeneral => '일반';

  @override
  String get shortcutGroupPrompt => '프롬프트';

  @override
  String get shortcutGroupNavigation => '내비게이션';

  @override
  String get shortcutGroupModelAndAgent => '모델 및 에이전트';

  @override
  String get shortcutGroupApplication => '애플리케이션';

  @override
  String get shortcutNewConversation => '새 대화';

  @override
  String get shortcutNewConversationDesc => '새 채팅 세션 생성';

  @override
  String get shortcutRefreshData => '데이터 새로 고침';

  @override
  String get shortcutRefreshDataDesc => '현재 채팅 데이터 새로 고침';

  @override
  String get shortcutFocusInput => '입력 창 포커스';

  @override
  String get shortcutFocusInputDesc => '텍스트 입력 창으로 포커스 이동';

  @override
  String get shortcutToggleVoiceInput => '음성 입력 전환';

  @override
  String get shortcutToggleVoiceInputDesc => '에디터에서 음성 받아쓰기 시작 또는 중지';

  @override
  String get shortcutQuickOpenFiles => '파일 빠른 열기';

  @override
  String get shortcutQuickOpenFilesDesc => '파일 빠른 검색 열기';

  @override
  String get shortcutOpenSettings => '설정 열기';

  @override
  String get shortcutOpenSettingsDesc => '설정 페이지 열기';

  @override
  String get shortcutNextRecentModel => '다음 최근 모델';

  @override
  String get shortcutNextRecentModelDesc => '최근에 사용한 모델 간 전환';

  @override
  String get shortcutNextVariant => '다음 변형';

  @override
  String get shortcutNextVariantDesc => '사용 가능한 모델 변형 간 전환';

  @override
  String get shortcutFocusCloseDrawer => '포커스/드로어 닫기';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      '기본적으로 입력 창에 포커스, 또는 열려 있을 때 드로어 닫기';

  @override
  String get shortcutNextAgent => '다음 에이전트';

  @override
  String get shortcutNextAgentDesc => '다음 사용 가능한 에이전트로 전환';

  @override
  String get shortcutPreviousAgent => '이전 에이전트';

  @override
  String get shortcutPreviousAgentDesc => '이전 사용 가능한 에이전트로 전환';

  @override
  String get shortcutCloseApp => '애플리케이션 닫기';

  @override
  String get shortcutCloseAppDesc => '플랫폼 종료 동작을 사용하여 앱 닫기';

  @override
  String get shortcutQuitApp => '애플리케이션 종료';

  @override
  String get shortcutQuitAppDesc => '앱 강제 종료';

  @override
  String get shortcutStopResponse => '응답 중지';

  @override
  String get shortcutStopResponseDesc => '활성 응답 중지 (응답 중)';

  @override
  String get errorConnectionFailed => '연결 실패';

  @override
  String get errorConnectionFailedDesc => '서버에 연결할 수 없습니다. 연결 및 서버 상태를 확인하십시오.';

  @override
  String get errorQuotaExceeded => '할당량 초과';

  @override
  String get errorQuotaExceededDesc =>
      '할당량이 초과되었습니다. 공급자 요금제 또는 결제 정보를 확인하십시오.';

  @override
  String get errorRateLimitExceeded => '요청 제한 초과';

  @override
  String get errorRateLimitExceededDesc =>
      '요청 제한이 초과되었습니다. 잠시 기다린 후 다시 시도하십시오.';

  @override
  String get errorAuthRequired => '인증 필요';

  @override
  String get errorAuthRequiredDesc => '인증에 실패했습니다. 공급자를 다시 연결하고 다시 시도하십시오.';

  @override
  String get errorServiceUnavailable => '서비스 사용 불가';

  @override
  String get errorServiceUnavailableDesc =>
      '서비스를 일시적으로 사용할 수 없습니다. 서버가 시작 중일 수 있습니다. 잠시 후 다시 시도하십시오.';

  @override
  String get errorProviderUnavailable => '공급자 사용 불가';

  @override
  String get errorProviderUnavailableDesc =>
      '공급자를 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도하십시오.';

  @override
  String get errorServerError => '서버 오류';

  @override
  String get errorServerErrorDesc => '서버 오류가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get attachmentNotAvailableOnPlatform =>
      '이 플랫폼에서는 첨부 파일 작업을 사용할 수 없습니다.';

  @override
  String get attachmentUnableToOpenLink => '첨부 파일 링크를 열 수 없습니다.';

  @override
  String get attachmentNoValidLocation => '첨부 파일에 유효한 위치가 제공되지 않았습니다.';

  @override
  String get attachmentDownloadStarted => '첨부 파일 다운로드가 시작되었습니다.';

  @override
  String get attachmentCouldNotDownload => '첨부 파일을 다운로드할 수 없습니다.';

  @override
  String get attachmentCouldNotDecode => '첨부 파일 데이터를 디코딩할 수 없습니다.';

  @override
  String get attachmentPayloadEmpty => '첨부 파일 페이로드가 비어 있습니다.';

  @override
  String attachmentSavedAndOpened(String path) {
    return '첨부 파일을 $path에 저장하고 열었습니다.';
  }

  @override
  String attachmentSavedTo(String path) {
    return '첨부 파일을 $path에 저장했습니다.';
  }

  @override
  String get attachmentCouldNotSave => '이 기기에 첨부 파일을 저장할 수 없습니다.';

  @override
  String get attachmentSaveCanceled => '저장이 취소되었습니다.';

  @override
  String attachmentSavedPath(String path) {
    return '첨부 파일을 $path에 저장했습니다.';
  }

  @override
  String get attachmentPathEmpty => '첨부 파일 경로가 비어 있습니다.';

  @override
  String get attachmentLocalNotFound => '이 기기에서 로컬 첨부 파일을 찾을 수 없습니다.';

  @override
  String get attachmentUnableToOpenLocal => '로컬 첨부 파일을 열 수 없습니다.';

  @override
  String speechDesktopOnly(String service) {
    return '$service은(는) 데스크톱에서만 사용할 수 있습니다.';
  }

  @override
  String speechRuntimeFailed(String service) {
    return '$service 런타임을 초기화하지 못했습니다.';
  }

  @override
  String speechModelFilesIncomplete(String service) {
    return '$service 모델 파일이 불완전합니다.';
  }

  @override
  String get speechMicPermissionDisabled => '마이크 권한이 비활성화되어 있습니다.';

  @override
  String speechUnavailableOnPlatform(String service) {
    return '$service 음성을 이 플랫폼에서 사용할 수 없습니다.';
  }

  @override
  String get terminalOpenToConnect => '터미널을 열어 서버 프로젝트 터미널에 연결하십시오.';

  @override
  String get terminalNotAvailableYet => '이 런타임에서는 임베디드 터미널을 아직 사용할 수 없습니다.';

  @override
  String get terminalSelectServer => '터미널을 열기 전에 활성 서버를 선택하십시오.';

  @override
  String get terminalOpenProjectFirst => '서버 터미널을 시작하기 전에 프로젝트 폴더를 여십시오.';

  @override
  String terminalConnectingTo(String serverName) {
    return '$serverName 터미널에 연결 중...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return '터미널 연결 실패: $error';
  }

  @override
  String get terminalDisconnected => '터미널 연결이 끊어졌습니다.';

  @override
  String get terminalSessionClosed => '터미널 세션이 종료되었습니다.';

  @override
  String get notificationConversationUpdates => '대화 업데이트';

  @override
  String get notificationOpenToClear => '관련 알림을 지우려면 이 대화를 여십시오.';

  @override
  String get notificationAgentFinished => '에이전트가 현재 응답을 마쳤습니다.';

  @override
  String get notificationSession => '세션';

  @override
  String get chatBadgeServerNeedsAttention => '서버 연결에 주의가 필요합니다.';

  @override
  String chatBadgeConversationError(String title) {
    return '\"$title\"에 오류가 있습니다.';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '\"$title\"에 입력이 필요합니다.';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '\"$title\"에 새 답장이 있습니다.';
  }

  @override
  String get chatBadgeSyncing => '대화 동기화 중...';

  @override
  String get chatBadgeDataSaverActive => '데이터 절약 모드가 활성화되었습니다.';

  @override
  String get chatCollapseGroup => '그룹 접기';

  @override
  String get chatExpandGroup => '그룹 펼치기';

  @override
  String get chatForkFailed => '대화 포크 실패';

  @override
  String get chatForked => '대화 포크됨';

  @override
  String get chatNoConversationsInProject => '이 프로젝트에 대화가 없습니다.';

  @override
  String get chatOpenProjectToLoad => '대화를 로드하려면 프로젝트를 여십시오.';

  @override
  String get chatExportCanceled => '세션 내보내기 취소됨';

  @override
  String get chatLargeContentSkipped => '안정성을 위해 크거나 잘못된 형식의 콘텐츠를 건너뛰었습니다.';

  @override
  String chatTokensLabel(int total) {
    return '토큰: $total';
  }

  @override
  String chatCostLabel(String cost) {
    return '비용: \$$cost';
  }

  @override
  String get chatFileExplorerNames => '이름';

  @override
  String get chatFileExplorerContents => '내용';

  @override
  String chatCloseProject(String project) {
    return '$project 닫기';
  }

  @override
  String get sessionExportUser => '사용자';

  @override
  String get sessionExportAssistant => '어시스턴트';

  @override
  String get sessionExportInput => '입력:';

  @override
  String get sessionExportOutput => '출력:';

  @override
  String get sessionExportError => '오류:';

  @override
  String get sessionExportUntitled => '제목 없는 세션';

  @override
  String get modelLabelTinyEnglish => 'Tiny (영어)';

  @override
  String get modelLabelBaseEnglish => '기본 (영어)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25개 유럽 언어)';

  @override
  String get cannedNewQuickReply => '새 빠른 답장';

  @override
  String get settingsSoundPickerNotAvailable =>
      '시스템 사운드 선택기는 이 플랫폼에서 사용할 수 없습니다.';

  @override
  String get appProviderPrimaryServer => '기본 서버';

  @override
  String get appProviderLocalManaged => '로컬 OpenCode (관리형)';

  @override
  String get appProviderLocalServerStopped => '로컬 서버가 중지되었습니다.';

  @override
  String get appProviderRunDiagnostics =>
      '로컬 OpenCode 요구 사항을 확인하려면 진단을 실행하십시오.';

  @override
  String get appProviderInvalidServerUrl => '유효하지 않은 서버 URL';

  @override
  String get appProviderOAuthNotSupported =>
      '이 플랫폼에서는 Cloudflare Access OAuth를 지원하지 않습니다.';

  @override
  String get appProviderTailscaleNotSupported =>
      '이 플랫폼에서는 Tailscale을 지원하지 않습니다.';

  @override
  String get appProviderProfileNotFound => '서버 프로필을 찾을 수 없습니다.';

  @override
  String get appProviderCannotActivateUnhealthy => '상태가 좋지 않은 서버를 활성화할 수 없습니다.';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode 감지됨';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode 감지되지 않음';

  @override
  String get appProviderDetectingCommand => 'OpenCode 명령 감지 중...';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'OpenCode 명령이 감지되지 않았습니다. 방금 설치한 경우 체크를 새로 고치거나 $appName을(를) 다시 열어 PATH를 다시 로드하십시오.';
  }

  @override
  String get appProviderNotDetectedInstall =>
      'OpenCode 명령이 감지되지 않았습니다. 마법사에서 설치를 실행하십시오.';

  @override
  String appProviderUsingCommandAt(String path) {
    return '$path에 있는 OpenCode 명령 사용 중';
  }

  @override
  String get appProviderDesktopOnly => '관리형 로컬 서버는 데스크톱에서만 사용할 수 있습니다.';

  @override
  String get appProviderInstallingRequirements => 'OpenCode 요구 사항 설치 중...';

  @override
  String get appProviderInstallationFailed => 'OpenCode 설치에 실패했습니다.';

  @override
  String get appProviderInstalledSuccessfully =>
      'OpenCode 요구 사항이 성공적으로 설치되었습니다.';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return '설치에 성공했습니다. OpenCode 명령은 $path에서 사용할 수 있습니다.';
  }

  @override
  String get appProviderInstallSucceeded => '설치에 성공했습니다.';

  @override
  String get appProviderStartingLocalServer => '로컬 서버 시작 중...';

  @override
  String get appProviderFailedToStart => '로컬 OpenCode 서버를 시작하지 못했습니다.';

  @override
  String appProviderRunningAt(String url) {
    return '$url에서 실행 중';
  }

  @override
  String get appProviderStoppingLocalServer => '로컬 서버 중지 중...';

  @override
  String appProviderExitedWithCode(int code) {
    return '로컬 서버가 코드 $code번으로 종료되었습니다.';
  }

  @override
  String get appProviderInstallBinary => '바이너리 설치';

  @override
  String get appProviderInstallViaNpm => 'npm을 통해 설치';

  @override
  String get appProviderInstallViaBun => 'Bun을 통해 설치';

  @override
  String get appProviderInstallBunOpenCode => 'Bun + OpenCode 설치';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      '이 플랫폼에서는 Tailscale을 지원하지 않습니다.';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'Windows에서는 Tailscale을 지원하지 않습니다.';

  @override
  String get tailscaleWaitingAdminApproval =>
      '이 Tailscale 노드는 관리자 승인을 기다리고 있습니다.';

  @override
  String get notificationSoundLoadFailed => 'Android 시스템 사운드를 로드하지 못했습니다.';

  @override
  String get chatDescriptionNewConversation => '새 대화';

  @override
  String get chatDescriptionRefreshData => '채팅 데이터 새로 고침';

  @override
  String get chatDescriptionFocusInput => '메시지 입력 창 포커스';

  @override
  String get chatDescriptionVoiceInput => '음성 입력 시작 또는 중지';

  @override
  String get chatDescriptionQuickOpen => '파일 빠른 열기';

  @override
  String get chatDescriptionOpenSettings => '설정 열기';

  @override
  String get chatDescriptionCycleModels => '최근 모델 순환';

  @override
  String get chatDescriptionCycleVariant => '모델 변형 순환';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      '입력 창 포커스 (또는 열려 있을 때 드로어 닫기)';

  @override
  String get chatDescriptionNextAgent => '다음 에이전트';

  @override
  String get chatDescriptionPreviousAgent => '이전 에이전트';

  @override
  String get chatDescriptionCloseApp => '플랫폼 종료 동작을 사용하여 앱 닫기';

  @override
  String get chatDescriptionForceExit => '앱 강제 종료';

  @override
  String get chatDescriptionStopResponse => '활성 응답 중지 (응답 중)';

  @override
  String get chatDescriptionProjectCommand => '프로젝트 명령';

  @override
  String get chatDescriptionOpenProjects => '이 버튼을 사용하여 프로젝트와 대화를 엽니다.';

  @override
  String get chatDescriptionSwitchProject => '이 버튼을 사용하여 프로젝트 폴더와 컨텍스트를 전환합니다.';

  @override
  String chatDescriptionChildren(int count) {
    return '하위 항목: $count';
  }

  @override
  String get chatDescriptionDiffFilesZero => 'Diff 파일: 0';

  @override
  String get appProviderErrorInvalidServerUrl => '유효하지 않은 서버 URL';

  @override
  String get appProviderErrorServerUrlRequired => '서버 URL이 필요합니다.';

  @override
  String get appProviderErrorServerAlreadyExists => '이 URL을 사용하는 서버가 이미 존재합니다.';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      '이 플랫폼에서는 Cloudflare Access OAuth를 지원하지 않습니다.';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      '이 플랫폼에서는 Tailscale을 지원하지 않습니다.';

  @override
  String get appProviderErrorServerProfileNotFound => '서버 프로필을 찾을 수 없습니다.';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      '상태가 좋지 않은 서버를 활성화할 수 없습니다.';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      '관리형 로컬 서버는 데스크톱에서만 사용할 수 있습니다.';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      '로컬 서버가 시작되었지만 상태 확인을 통과하지 못했습니다.';

  @override
  String get appProviderErrorInstallationFailed => 'OpenCode 설치에 실패했습니다.';

  @override
  String get appProviderStatusLocalServerStopped => '로컬 서버가 중지되었습니다.';

  @override
  String get appProviderStatusStartingLocalServer => '로컬 서버 시작 중...';

  @override
  String appProviderStatusRunningAt(String url) {
    return '$url에서 실행 중';
  }

  @override
  String get appProviderStatusStoppingLocalServer => '로컬 서버 중지 중...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return '로컬 서버가 코드 $code번으로 종료되었습니다.';
  }

  @override
  String get appProviderSetupDetectingOpenCode => 'OpenCode 명령 감지 중...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode 감지됨';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode 감지되지 않음';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return '$path에 있는 OpenCode 명령 사용 중';
  }

  @override
  String get appProviderSetupInstallingRequirements => 'OpenCode 요구 사항 설치 중...';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'OpenCode 요구 사항이 성공적으로 설치되었습니다.';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return '설치에 성공했습니다. OpenCode 명령은 $path에서 사용할 수 있습니다.';
  }

  @override
  String get appProviderSetupInstallationSucceeded => '설치에 성공했습니다.';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'OpenCode 명령이 감지되지 않았습니다. 방금 설치한 경우 체크를 새로 고치거나 CodeWalk를 다시 열어 PATH를 다시 로드하십시오.';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'OpenCode 명령이 감지되지 않았습니다. 마법사에서 설치를 실행하십시오.';

  @override
  String get appProviderLabelPrimaryServer => '기본 서버';

  @override
  String get appProviderLabelLocalOpenCodeManaged => '로컬 OpenCode (관리형)';

  @override
  String get chatChooseModel => '모델 선택';

  @override
  String get chatStartVoiceInput => '음성 입력 시작';

  @override
  String get chatStopVoiceInput => '음성 입력 중지';

  @override
  String get chatStartingVoiceInput => '음성 입력 시작 중';

  @override
  String get chatComposerPlaceholder => '필요한 사항을 입력하세요...';

  @override
  String get chatPermissionAutoApproveOn => '권한 자동 승인 켜짐';

  @override
  String get chatPermissionAutoApproveOff => '권한 자동 승인 꺼짐';

  @override
  String get chatModelLockedSubConversation => '하위 대화에서 모델 잠김';

  @override
  String get chatComposerHintShell => '셸 명령어 (Esc 종료)';

  @override
  String get utilityTitle => '유틸리티';

  @override
  String get statusOffline => '오프라인';

  @override
  String get statusOnline => '온라인';

  @override
  String get statusConnected => '연결됨';

  @override
  String get statusReconnecting => '재연결 중';

  @override
  String get statusSyncDelayed => '동기화 지연됨';

  @override
  String get statusDelayed => '지연됨';

  @override
  String get chatActiveServerUnhealthyLabel => '활성 서버가 비정상입니다';

  @override
  String get chatWaitingForNetworkConnection => '네트워크 연결 대기 중...';

  @override
  String get serverHealthHealthy => '정상';

  @override
  String get serverHealthUnhealthy => '비정상';

  @override
  String get serverHealthUnknown => '알 수 없음';

  @override
  String get sessionUnshare => '세션 공유 해제';

  @override
  String get sessionShare => '세션 공유';

  @override
  String get sessionExportMarkdown => 'Markdown 내보내기';

  @override
  String get sessionExportDebugJson => '디버그 JSON 내보내기';

  @override
  String get sessionViewTasks => '작업 보기';

  @override
  String get sessionCompactContext => '컨텍스트 압축';

  @override
  String get sessionUnshared => '대화 공유가 해제되었습니다';

  @override
  String get sessionShared => '대화가 공유되었습니다';

  @override
  String get sessionShareLinkUnavailable => '이 세션에 공유 링크를 사용할 수 없습니다';

  @override
  String get sessionExportMarkdownTitle => '세션을 Markdown으로 내보내기';

  @override
  String get sessionExportDebugJsonTitle => '세션을 디버그 JSON으로 내보내기';

  @override
  String get sessionExportCanceled => '내보내기가 취소되었습니다';

  @override
  String get sessionExportMarkdownSaved => 'Markdown 내보내기가 저장되었습니다';

  @override
  String get sessionExportDebugJsonSaved => '디버그 JSON 내보내기가 저장되었습니다';

  @override
  String get sessionExportMarkdownErrorClipboard =>
      '파일을 저장할 수 없습니다. Markdown이 클립보드에 복사되었습니다';

  @override
  String get sessionExportDebugJsonErrorClipboard =>
      '파일을 저장할 수 없습니다. 디버그 JSON이 클립보드에 복사되었습니다';

  @override
  String get terminalHide => '터미널 숨기기';

  @override
  String get terminalOpen => '터미널 열기';

  @override
  String get terminalOpenInfo => '터미널 정보 열기';

  @override
  String get chatNoSessionSelected => '대화를 선택하거나 생성하세요';

  @override
  String get chatWelcomeMessage => '안녕하세요! 저는 당신의 AI 어시스턴트입니다.';

  @override
  String get chatWelcomeSubmessage => '오늘 무엇을 도와드릴까요?';

  @override
  String get cannedAppendAtCursor => '커서에 추가';

  @override
  String get cannedReplace => '바꾸기';

  @override
  String get chatMessageAttachedFile => '첨부 파일';

  @override
  String get chatMessageThinking => '생각 중';

  @override
  String get chatMessageShow => '보기';

  @override
  String get chatMessageMore => '더보기';

  @override
  String get chatMessageLess => '접기';

  @override
  String get chatMessageDetails => '세부 정보';

  @override
  String get chatMessageToolInput => '입력';

  @override
  String get chatMessageToolCommand => '명령어';

  @override
  String chatMessageToolRunningCount(int count) {
    return '$count개 실행 중';
  }

  @override
  String chatMessageToolQueuedCount(int count) {
    return '$count개 대기 중';
  }

  @override
  String get chatMessageToolOutputTruncated => '앱 안정성을 위해 큰 도구 출력이 잘렸습니다.';

  @override
  String get chatMessageToolCommandTruncated => '안정성을 위해 명령어 미리보기가 잘렸습니다.';

  @override
  String get chatMessageToolInputTruncated => '안정성을 위해 입력 미리보기가 잘렸습니다.';

  @override
  String get chatMessageToolDiffOmitted =>
      'Diff 미리보기가 생략되었습니다: 편집 페이로드가 너무 큽니다.';

  @override
  String get terminalTitle => '터미널';

  @override
  String get chatCouldNotRefreshSession => '이 대화를 새로고침할 수 없습니다';

  @override
  String get chatMainConversationUnavailable => '메인 대화를 아직 사용할 수 없습니다.';

  @override
  String get chatFailedToRefreshSubConversations =>
      '하위 대화를 새로고침하지 못했습니다. 다시 시도하세요.';

  @override
  String get chatNoSubConversationFound => '이 작업에 대한 하위 대화를 찾을 수 없습니다.';

  @override
  String get errorAnErrorOccurred => '오류가 발생했습니다';

  @override
  String get serverConnectionAttention => '서버 연결에 주의가 필요합니다.';

  @override
  String sessionHasError(String title) {
    return '\"$title\"에 오류가 있습니다.';
  }

  @override
  String sessionNeedsInput(String title) {
    return '\"$title\"이(가) 당신의 입력을 필요로 합니다.';
  }

  @override
  String sessionHasNewReply(String title) {
    return '\"$title\"에 새 답변이 있습니다.';
  }

  @override
  String get sessionSyncing => '대화 동기화 중...';

  @override
  String get behaviorCellularDataSaverActive => '셀룰러 데이터 세이버가 활성화되었습니다.';

  @override
  String get sessionNoCachedConversations => '아직 캐시된 대화가 없습니다';

  @override
  String get sessionForkFailed => '대화 포크에 실패했습니다';

  @override
  String get sessionForked => '대화가 포크되었습니다';

  @override
  String get sessionNoConversationsInProject => '이 프로젝트에 대화가 없습니다.';

  @override
  String get sessionOpenProjectToLoad => '프로젝트를 열어 대화를 로드하세요.';

  @override
  String sessionChildrenCount(int count) {
    return '하위 대화: $count';
  }

  @override
  String sessionDiffFilesCount(int count) {
    return 'Diff 파일: $count';
  }

  @override
  String get compactionAutomatic => '자동';

  @override
  String get compactionManual => '수동';

  @override
  String get chatMessageShowLessCompact => '접기';

  @override
  String get chatMessageShowLess => '덜 보기';

  @override
  String get chatMessageShowMoreCompact => '더보기';

  @override
  String get chatMessageShowMore => '더 보기';

  @override
  String get chatChooseAgent => '에이전트 선택';

  @override
  String get chatEffortLockedSubConversation => '하위 대화에서 노력 수준이 잠김';

  @override
  String get chatChooseEffort => '노력 수준 선택';

  @override
  String get chatServerSelectedModel => '서버 선택 모델';

  @override
  String get chatFailedToRefreshProviders => '공급자 및 모델을 새로고침하지 못했습니다';

  @override
  String get cannedAddTitle => '빠른 답변 추가';

  @override
  String get cannedEditTitle => '빠른 답변 편집';

  @override
  String get cannedTextLabel => '텍스트';

  @override
  String get cannedAppendAtCursorSubtitle => '끄기 = 현재 작성기 텍스트 바꾸기';

  @override
  String get cannedSendAutomaticallySubtitle => '삽입 후 즉시 보내기';

  @override
  String get cannedScopeGlobalSubtitle => '프로젝트 전용 항목의 경우 비활성화';

  @override
  String get cannedScopeGlobalUnavailableSubtitle => '현재 컨텍스트에서 프로젝트 전용 사용 불가';

  @override
  String get commonFile => '파일';

  @override
  String get serversSearchActiveHint => '활성 서버 검색';

  @override
  String get serversNoServersFound => '서버를 찾을 수 없음';

  @override
  String get serversUnhealthyActivateError =>
      '이 서버의 상태가 좋지 않습니다. 활성화하기 전에 상태 확인을 하거나 설정을 편집하세요.';

  @override
  String get serversTailscaleConnected => 'Tailscale 연결됨';

  @override
  String get serversTailscaleConnecting => 'Tailscale 연결 중';

  @override
  String get serversTailscaleAuthRequired => 'Tailscale 인증 필요';

  @override
  String get serversTailscaleAdminApprovalRequired => 'Tailscale 관리자 승인 필요';

  @override
  String get serversTailscaleConnectionFailed => 'Tailscale 연결 실패';

  @override
  String get serversTailscaleUnsupported => 'Tailscale 지원되지 않음';

  @override
  String get serversTailscaleDisconnected => 'Tailscale 연결 해제됨';

  @override
  String get serversTailscaleLoginExplanation =>
      '이 기기를 tailnet에 추가하려면 Tailscale 로그인 URL을 여세요.';

  @override
  String get serversTailscaleTrafficExplanation =>
      '이 활성 프로필의 OpenCode 트래픽은 Tailscale을 통해 라우팅됩니다.';

  @override
  String get serversTailscaleConnectExplanation =>
      '이 활성 프로필을 사용하면 Tailscale이 연결됩니다.';

  @override
  String get statusStarting => '시작 중';

  @override
  String get statusStopping => '중지 중';

  @override
  String get statusFailed => '실패';

  @override
  String get statusStopped => '중지됨';

  @override
  String get serversDesktopModeExplanation =>
      '데스크톱 모드는 CodeWalk에서 직접 `opencode serve`를 실행하고 관리할 수 있습니다.';

  @override
  String get serversCannotActivateUnhealthy => '상태가 좋지 않은 서버를 활성화할 수 없음';

  @override
  String get commonCopiedToClipboard => '클립보드에 복사됨';

  @override
  String get chatUndoNothing => '이 세션에서 취소할 작업이 없습니다';

  @override
  String get chatRedoNothing => '이 세션에서 다시 실행할 작업이 없습니다';

  @override
  String get chatStatusPatching => '패치 중';

  @override
  String get chatStatusPatchingOneFile => '1개 파일 패치 중';

  @override
  String chatStatusPatchingMultipleFiles(int count) {
    return '$count개 파일 패치 중';
  }

  @override
  String get chatStatusThinking => '생각 중...';

  @override
  String get chatStatusSubsession => '하위 세션';

  @override
  String get chatStatusBusy => '상태: 바쁨';

  @override
  String get chatStatusRetry => '상태: 재시도';

  @override
  String chatStatusRetryCount(int count) {
    return '상태: 재시도 #$count';
  }

  @override
  String get appShellUpdateInstalledRestartRequired =>
      '업데이트가 설치되었습니다. 새 버전을 적용하려면 재시작이 필요합니다.';

  @override
  String get appShellUpdateInstalledRestartApp =>
      '업데이트가 설치되었습니다. 적용하려면 앱을 재시작하세요.';

  @override
  String get chatTourProjectsConversations => '이 버튼을 사용하여 프로젝트와 대화를 엽니다.';

  @override
  String get chatTourSwitchFolders => '이 버튼을 사용하여 프로젝트 폴더와 컨텍스트를 전환합니다.';

  @override
  String get chatTourSidebarProjectTools =>
      '이 메뉴를 사용하여 대화 사이드바와 프로젝트 도구를 표시합니다.';

  @override
  String get chatActionNext => '다음';

  @override
  String get chatShortcutsNewConversation => '새 대화';

  @override
  String get chatShortcutsRefreshChat => '채팅 데이터 새로고침';

  @override
  String get chatShortcutsFocusInput => '메시지 입력창에 포커스';

  @override
  String get chatShortcutsStartStopVoice => '음성 입력 시작 또는 중지';

  @override
  String get chatShortcutsQuickOpen => '파일 빠르게 열기';

  @override
  String get chatShortcutsOpenSettings => '설정 열기';

  @override
  String get chatShortcutsCycleModels => '최근 모델 순환';

  @override
  String get chatShortcutsCycleVariant => '모델 변형 순환';

  @override
  String get chatShortcutsFocusInputCloseDrawer =>
      '입력창에 포커스(또는 열려 있는 경우 서랍 닫기)';

  @override
  String get chatShortcutsNextAgent => '다음 에이전트';

  @override
  String get chatShortcutsPreviousAgent => '이전 에이전트';

  @override
  String get chatShortcutsCloseApp => '플랫폼 종료 동작을 사용하여 앱 닫기';

  @override
  String get chatShortcutsForceExit => '앱 강제 종료';

  @override
  String get chatShortcutsStopResponse => '활성 응답 중지(응답 중일 때)';

  @override
  String get chatTipMentionFiles => '팁: 프롬프트에서 @를 사용하여 파일을 언급하세요';

  @override
  String get chatTipRenameConversation => '팁: 제목을 탭하여 대화 이름을 변경하세요';

  @override
  String get chatTipShellCommands => '팁: 시작 부분에 !를 사용하여 쉘 명령을 실행하세요';

  @override
  String get chatTipSlashCommands => '팁: /를 사용하여 슬래시 명령에 액세스하세요';

  @override
  String get chatTipLongPressSend => '팁: 전송 버튼을 길게 눌러 줄바꿈을 삽입하세요';

  @override
  String get chatTipContextKnob => '팁: 컨텍스트 노브를 탭하여 사용 세부 정보를 확인하세요';

  @override
  String get chatTipBeSpecific => '팁: 구체적으로 작성하세요 — 프롬프트가 짧을수록 답변이 빠릅니다';

  @override
  String get chatTipStepByStep => '팁: 복잡한 문제 디버깅 시 단계별 설명을 요청하세요';

  @override
  String get chatTipProvideContext => '팁: 컨텍스트를 제공하세요 — 오류 메시지와 로그를 붙여넣으세요';

  @override
  String get chatTipBreakTasks => '팁: 큰 작업은 작은 프롬프트로 나누세요';

  @override
  String get chatFailedToLoadDirectories => '디렉토리를 로드하지 못했습니다';

  @override
  String get logsFilterAll => '전체';

  @override
  String get logsNoLogsYet => '아직 캡처된 로그가 없습니다.';

  @override
  String get logsNoMatchingLogs => '현재 필터와 일치하는 로그가 없습니다.';

  @override
  String get settingsDefaultModel => '기본 모델';

  @override
  String get settingsSearchDefaultModel => '기본 모델 검색';

  @override
  String get settingsDefaultAgent => '기본 에이전트';

  @override
  String get settingsSearchDefaultAgent => '기본 에이전트 검색';

  @override
  String get settingsNoAgentsFound => '에이전트를 찾을 수 없음';

  @override
  String get settingsConversationUsername => '대화 사용자 이름';

  @override
  String get settingsUsernameUnsetExplanation =>
      'OpenCode는 `username`이 설정되지 않았으므로 시스템 사용자 이름을 사용합니다.';

  @override
  String get settingsUsernameResetExplanation =>
      '`/config` 패치 업데이트는 키를 제거할 수 없으므로 `username`을 시스템 기본값으로 재설정하려면 앱 외부에서 구성을 편집해야 합니다.';

  @override
  String get chatHelpMessage => '멘션은 @, 쉘은 !, 명령은 /를 사용하세요';

  @override
  String terminalEmbeddedUnavailable(String serverName) {
    return '내장 터미널은 아직 이 런타임에서 사용할 수 없습니다. 일회성 명령에는 컴포저 쉘 모드를 계속 사용하거나 지원되는 CodeWalk 앱 런타임에서 $serverName의 터미널을 여세요.';
  }

  @override
  String get chatFailedToLoadFile => '파일을 로드하지 못했습니다';

  @override
  String get chatMentionFileSubtitle => '파일';

  @override
  String get chatMentionSymbolSubtitle => '기호';

  @override
  String get chatMentionAgentSubtitle => '에이전트';

  @override
  String get chatCommandSourceGeneric => '명령';

  @override
  String get chatCommandSourceProject => '프로젝트';

  @override
  String get chatCommandDescriptionProject => '프로젝트 명령';

  @override
  String get settingsSmallModel => '소형 모델';

  @override
  String get settingsSearchSmallModel => '소형 모델 검색';

  @override
  String get settingsSmallModelUnsetExplanation =>
      '`small_model`이 설정되지 않았으므로 OpenCode 자동 폴백이 활성화됩니다.';

  @override
  String get settingsSmallModelResetExplanation =>
      '`/config` 패치 업데이트는 키를 제거할 수 없으므로 `small_model`을 자동 폴백으로 재설정하려면 앱 외부에서 구성을 편집해야 합니다.';

  @override
  String get settingsOpenCodeAutoUpdate => 'OpenCode 자동 업데이트';

  @override
  String get settingsSearchAutoUpdateMode => '자동 업데이트 모드 검색';

  @override
  String get settingsOpenCodeSharingDefault => 'OpenCode 공유 기본값';

  @override
  String get settingsSearchSharingMode => '공유 모드 검색';

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
