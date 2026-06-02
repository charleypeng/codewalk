// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appShellDownloadingUpdate => 'اپ ڈیٹ ڈاؤن لوڈ ہو رہا ہے';

  @override
  String get appShellInstall => 'انسٹال کریں';

  @override
  String get appShellInstallFailed => 'انسٹالیشن ناکام';

  @override
  String get appShellInstallingUpdate => 'اپ ڈیٹ انسٹال ہو رہا ہے...';

  @override
  String get appShellRestart => 'دوبارہ شروع کریں';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return 'اپ ڈیٹ دستیاب: v$latestVersion';
  }

  @override
  String get behaviorAdvancedPermissionRule => 'اعلی درجے کی اجازت کا قاعدہ';

  @override
  String get behaviorAutomatic => 'خودکار';

  @override
  String get behaviorAutomaticFallback => 'خودکار فال بیک';

  @override
  String get behaviorCellularDataSaver => 'موبائل ڈیٹا سیور';

  @override
  String get behaviorChatLevelShare => 'چیٹ لیول شیئرنگ';

  @override
  String get behaviorCodeWalkReleaseChecks => 'CodeWalk ریلیز چیکس';

  @override
  String get behaviorControlsOfficialGlobal =>
      'OpenCode کی آفیشل گلوبل سیٹنگز کنٹرول کرتا ہے';

  @override
  String get behaviorControlsUpstreamOpenCode =>
      'اپ اسٹریم OpenCode سیٹنگز کنٹرول کرتا ہے';

  @override
  String get behaviorCustomDisplayName => 'حسب ضرورت ڈسپلے نام';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return 'بیک گراؤنڈ ڈاؤن لوڈز روک کر اور پیش منظر کے خودکار تازہ کاریوں کو ہر $inSeconds سیکنڈ پر ایک رسے تک محدود کر کے خودکار موبائل ڈیٹا استعمال کو کم کرتا ہے۔';
  }

  @override
  String get behaviorDisabled => 'غیر فعال';

  @override
  String get behaviorLightweightTasksLike => 'ہلکے کام جیسے';

  @override
  String get behaviorManual => 'دستی';

  @override
  String get behaviorNotify => 'اطلاع دیں';

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
    return 'بچے: $length';
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
  String get chatDoubleESCStop => 'رکنے کے لیے دو بار ESC';

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
    return '$compactionLabel کمپیکشن سے پہلے $messageCount پیغامات چھپائے گئے';
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
  String get chatMessageHide => 'چھپائیں';

  @override
  String get chatMessageMessagePartUnavailable => 'Message part unavailable';

  @override
  String get chatMessageMetadataAvailable => 'No metadata available';

  @override
  String chatMessageModelMessageModelId(String modelId) {
    return 'ماڈل: $modelId';
  }

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return 'فراہم کنندہ: $providerId';
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
  String get chatOpenProject => 'پروجیکٹ کھولیں';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenSidebar => 'سائیڈ بار کھولیں';

  @override
  String get chatPageStatusContextUsage => 'سیاق استعمال';

  @override
  String get chatPageStatusCost => 'لاگت';

  @override
  String get chatPageStatusLimit => 'حد';

  @override
  String get chatPageStatusManageServers => 'سرورز کا نظم کریں';

  @override
  String get chatPageStatusSaver => 'سیور';

  @override
  String get chatPageStatusSwitchServer => 'سرور تبدیل کریں';

  @override
  String get chatPageStatusTokens => 'ٹوکنز';

  @override
  String get chatPageStatusUsage => 'استعمال';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatProjectContext => 'Project Context';

  @override
  String get chatProjectContext2 => 'پروجیکٹ سیاق';

  @override
  String get chatRealtimeGlobalEvent => 'عالمی واقعہ';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return 'عالمی واقعہ ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale => 'عالمی واقعہ (پرانی نسل)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return 'پیغام کا بہاؤ ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => 'ریئل ٹائم واقعہ';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return 'ریئل ٹائم واقعہ ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale => 'ریئل ٹائم واقعہ (پرانی نسل)';

  @override
  String get chatRealtimeReconnectingServerTry =>
      'سرور سے دوبارہ کنیکٹ ہو رہا ہے۔ ایک لمحے بعد دوبارہ کوشش کریں۔';

  @override
  String get chatReasoning => 'استدلال...';

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
    return 'تاریخ سے $displayName ہٹائیں';
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
    return 'چیٹ سیشن: $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return 'گفتگو $nextAction';
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
  String get chatSidebarAccess => 'سائیڈ بار رسائی';

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
    return 'مطابقت: $label';
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
    return 'منسلک $path میں محفوظ اور کھولا گیا۔';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return 'منسلک $path میں محفوظ ہوا۔';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return 'منسلک $savedPath میں محفوظ ہوا۔';
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
    return 'کھلی فائلیں ($length)';
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
    return '$length2 اندراجات میں سے $length دکھائے گئے';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => 'ریاضی';

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
    return 'ذیلی کام ($agent)';
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
    return 'منتخب: $soundLabel';
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
    return '$length سیٹ اپ لاگ سطریں اور $length2 سیٹ اپ واقعات الگ سیٹ اپ ڈی بگ اسکرین میں دستیاب ہیں۔';
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
    return 'تازہ ترین آؤٹ پٹ: $localServerLastOutput';
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
      'مقامی OpenCode ضروریات کی تصدیق کے لیے تشخیص چلائیں۔';

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
    return 'کمانڈ: $localServerCommandPath';
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
    return '\"$displayName\" ہٹائیں؟';
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
  String get sessionCopyLink => 'لنک کاپی کریں';

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
  String get settingsAppearanceMathRendering => 'ریاضی رینڈرنگ';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      'چیٹ پیغامات میں LaTeX ریاضی اظہار کو ٹائپ سیٹ مساوات کے طور پر رینڈر کریں۔';

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
    return '$conflict کے ساتھ تصادم';
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
    return 'شارٹ کٹ سیٹ کریں: $label';
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
  String get onboardingSetup => 'سیٹ اپ';

  @override
  String get onboardingSetupWizard => 'سیٹ اپ وزرڈ';

  @override
  String get onboardingServerSetup => 'سرور سیٹ اپ';

  @override
  String get onboardingEditServer => 'سرور میں ترمیم کریں';

  @override
  String get onboardingLocalServerSetup => 'مقامی سرور سیٹ اپ';

  @override
  String get onboardingReady => 'تیار';

  @override
  String onboardingWelcomeTo(String appName) {
    return '$appName میں خوش آمدید';
  }

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName کو آپ کے کوڈ میں مدد کرنے سے پہلے ایک OpenCode سرور کی ضرورت ہے۔';
  }

  @override
  String get onboardingChooseHowToSetup =>
      'اپنا سرور سیٹ اپ کرنے کا طریقہ منتخب کریں';

  @override
  String get onboardingPickSetupPath =>
      'وہ سیٹ اپ راستہ منتخب کریں جو آپ کے موجودہ OpenCode سیٹ اپ سے میل کھاتا ہو۔';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'صرف ڈیسک ٹاپ: $appName آپ کے لیے OpenCode کی تشخیص، انسٹال اور چلا سکتا ہے۔';
  }

  @override
  String get onboardingAvailableOnlyDesktop =>
      'صرف ڈیسک ٹاپ (Linux/macOS/Windows) پر دستیاب ہے۔';

  @override
  String get onboardingServerConnection => 'سرور کنکشن';

  @override
  String get onboardingEditServerConnection => 'سرور کنکشن میں ترمیم کریں';

  @override
  String onboardingSuggestedUrl(String url) {
    return 'تجویز کردہ مقامی OpenCode سرور URL: $url';
  }

  @override
  String get onboardingEmulatorRemap =>
      'اینڈرائیڈ ایمولیٹر پر، localhost اور 127.0.0.1 خود بخود 10.0.2.2 پر ری میپ ہو جاتے ہیں۔';

  @override
  String get onboardingBasicAuthTip =>
      'بنیادی تصدیق صرف اس صورت میں فعال کریں جب آپ کا OpenCode سرور پاس ورڈ سے محفوظ ہو۔';

  @override
  String get onboardingEnterServerUrl => 'سرور کا URL درج کریں';

  @override
  String get onboardingInvalidUrl => 'غلط URL';

  @override
  String get onboardingTesting => 'ٹیسٹنگ...';

  @override
  String get onboardingSaveAndTest => 'محفوظ کریں اور ٹیسٹ کریں';

  @override
  String get onboardingTestConnection => 'کنکشن ٹیسٹ کریں';

  @override
  String get onboardingTailscaleLoginRequired => 'Tailscale لاگ ان درکار ہے';

  @override
  String get onboardingTailscaleAdminApproval =>
      'Tailscale ایڈمن کی منظوری درکار ہے';

  @override
  String get onboardingTailscaleConnected => 'Tailscale منسلک ہے';

  @override
  String get onboardingTailscaleConnecting => 'Tailscale منسلک ہو رہا ہے';

  @override
  String get onboardingTailscaleConnectionFailed => 'Tailscale کنکشن ناکام رہا';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale غیر تعاون یافتہ ہے';

  @override
  String get onboardingTailscaleAuthAfterSave =>
      'محفوظ کرنے کے بعد Tailscale کی تصدیق ہوگی';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'اس ڈیوائس کو اپنے tailnet میں شامل کرنے کے لیے لاگ ان URL کھولیں۔ اگر براؤزر نہیں کھلا تو نیچے دیے گئے URL کو کاپی کریں۔';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'اس سرور کو محفوظ کرنے اور ٹیسٹ کرنے کے بعد، $appName Tailscale لاگ ان کھولے گا اگر یہ ڈیوائس ابھی تک تصدیق شدہ نہیں ہے۔';
  }

  @override
  String get onboardingStarting => 'شروع ہو رہا ہے';

  @override
  String get onboardingStopping => 'روک رہا ہے';

  @override
  String get onboardingFailed => 'ناکام';

  @override
  String get onboardingStopped => 'روکا ہوا';

  @override
  String get onboardingUsingDetectedCommand =>
      'پتہ لگائی گئی OpenCode کمانڈ کا استعمال کر رہا ہے۔';

  @override
  String get onboardingContinue => 'جاری رکھیں';

  @override
  String get onboardingDone => 'مکمل';

  @override
  String get onboardingYoureAllSet => 'آپ بالکل تیار ہیں!';

  @override
  String get onboardingServerUpdated => 'سرور اپ ڈیٹ ہو گیا';

  @override
  String get onboardingServerConnectedReady =>
      'آپ کا سرور منسلک اور استعمال کے لیے تیار ہے۔';

  @override
  String get onboardingServerSettingsSaved =>
      'آپ کی سرور کی ترتیبات محفوظ کر لی گئیں اور ہیلتھ چیک اپ ڈیٹ کر دیے گئے۔';

  @override
  String onboardingStartUsing(String appName) {
    return '$appName کا استعمال شروع کریں';
  }

  @override
  String get onboardingCouldNotVerify => 'سرور کنکشن کی تصدیق نہیں ہو سکی۔';

  @override
  String get onboardingCloudflareAuthFailed =>
      'Cloudflare Access کی تصدیق ناکام ہوگئی۔';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'سرور ہیلتھ چیک ناکام رہا۔ یہ ابھی شروع ہو رہا ہو سکتا ہے۔';

  @override
  String get onboardingConnectionUpdated =>
      'سرور کنکشن کامیابی سے اپ ڈیٹ ہو گیا۔';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'سرور شامل کر دیا گیا لیکن ہیلتھ چیک ناکام رہا۔ یہ ابھی شروع ہو رہا ہو سکتا ہے۔';

  @override
  String get onboardingConnectionSaved => 'سرور کنکشن کامیابی سے محفوظ ہو گیا۔';

  @override
  String get onboardingAvailable => 'دستیاب';

  @override
  String get onboardingNotAvailable => 'دستیاب نہیں';

  @override
  String get onboardingReachable => 'قابل رسائی';

  @override
  String get onboardingUnreachable => 'ناقابل رسائی';

  @override
  String get onboardingWritable => 'قابل تحریر';

  @override
  String get onboardingNotWritable => 'قابل تحریر نہیں';

  @override
  String toolPresentationRunningTool(String toolName) {
    return '$toolName چلا رہا ہے';
  }

  @override
  String get toolPresentationTool => 'ٹول';

  @override
  String get shortcutGroupSession => 'سیشن';

  @override
  String get shortcutGroupGeneral => 'عمومی';

  @override
  String get shortcutGroupPrompt => 'پرامپٹ';

  @override
  String get shortcutGroupNavigation => 'نیویگیشن';

  @override
  String get shortcutGroupModelAndAgent => 'ماڈل اور ایجنٹ';

  @override
  String get shortcutGroupApplication => 'ایپلیکیشن';

  @override
  String get shortcutNewConversation => 'نئی گفتگو';

  @override
  String get shortcutNewConversationDesc => 'ایک نیا چیٹ سیشن شروع کریں';

  @override
  String get shortcutRefreshData => 'ڈیٹا ریفریش کریں';

  @override
  String get shortcutRefreshDataDesc => 'موجودہ چیٹ کے ڈیٹا کو ریفریش کریں';

  @override
  String get shortcutFocusInput => 'ان پٹ پر توجہ مرکوز کریں';

  @override
  String get shortcutFocusInputDesc => 'توجہ کو ٹیکسٹ ان پٹ پر منتقل کریں';

  @override
  String get shortcutToggleVoiceInput => 'صوتی ان پٹ کو تبدیل کریں';

  @override
  String get shortcutToggleVoiceInputDesc =>
      'ایڈیٹر میں صوتی ڈکٹیشن شروع کریں یا روکیں';

  @override
  String get shortcutQuickOpenFiles => 'فائلیں جلدی کھولیں';

  @override
  String get shortcutQuickOpenFilesDesc => 'فائلوں کی فوری تلاش کھولیں';

  @override
  String get shortcutOpenSettings => 'ترتیبات کھولیں';

  @override
  String get shortcutOpenSettingsDesc => 'ترتیبات کا صفحہ کھولیں';

  @override
  String get shortcutNextRecentModel => 'اگلا حالیہ ماڈل';

  @override
  String get shortcutNextRecentModelDesc =>
      'حالیہ استعمال شدہ ماڈلز کے درمیان سوئچ کریں';

  @override
  String get shortcutNextVariant => 'اگلی قسم';

  @override
  String get shortcutNextVariantDesc =>
      'دستیاب ماڈل کی اقسام کے درمیان سوئچ کریں';

  @override
  String get shortcutFocusCloseDrawer => 'دراز پر توجہ مرکوز کریں/بند کریں';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'ڈیفالٹ کے طور پر ان پٹ پر توجہ مرکوز کریں، یا دراز کھلا ہونے پر بند کریں';

  @override
  String get shortcutNextAgent => 'اگلا ایجنٹ';

  @override
  String get shortcutNextAgentDesc => 'اگلے دستیاب ایجنٹ پر جائیں';

  @override
  String get shortcutPreviousAgent => 'پچھلا ایجنٹ';

  @override
  String get shortcutPreviousAgentDesc => 'پچھلے دستیاب ایجنٹ پر جائیں';

  @override
  String get shortcutCloseApp => 'ایپلیکیشن بند کریں';

  @override
  String get shortcutCloseAppDesc =>
      'پلیٹ فارم کے بند کرنے کے رویے کا استعمال کرتے ہوئے ایپ بند کریں';

  @override
  String get shortcutQuitApp => 'ایپلیکیشن سے باہر نکلیں';

  @override
  String get shortcutQuitAppDesc => 'ایپ سے زبردستی باہر نکلیں';

  @override
  String get shortcutStopResponse => 'جواب روکیں';

  @override
  String get shortcutStopResponseDesc => 'فعال جواب کو روکیں (جواب دیتے وقت)';

  @override
  String get errorConnectionFailed => 'کنکشن ناکام ہوگیا';

  @override
  String get errorConnectionFailedDesc =>
      'سرور تک پہنچنے میں ناکام۔ کنکشن اور سرور کی حیثیت چیک کریں۔';

  @override
  String get errorQuotaExceeded => 'کوٹہ ختم ہو گیا';

  @override
  String get errorQuotaExceededDesc =>
      'کوٹہ ختم ہو گیا۔ اپنے فراہم کنندہ کا پلان یا بلنگ چیک کریں۔';

  @override
  String get errorRateLimitExceeded => 'ریٹ کی حد سے تجاوز کر گیا';

  @override
  String get errorRateLimitExceededDesc =>
      'ریٹ کی حد سے تجاوز کر گیا۔ تھوڑی دیر انتظار کریں اور دوبارہ کوشش کریں۔';

  @override
  String get errorAuthRequired => 'تصدیق درکار ہے';

  @override
  String get errorAuthRequiredDesc =>
      'تصدیق ناکام ہوگئی۔ فراہم کنندہ کو دوبارہ منسلک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get errorServiceUnavailable => 'سروس دستیاب نہیں ہے';

  @override
  String get errorServiceUnavailableDesc =>
      'سروس عارضی طور پر دستیاب نہیں ہے۔ سرور شروع ہو رہا ہو سکتا ہے — براہ کرم تھوڑی دیر میں دوبارہ کوشش کریں۔';

  @override
  String get errorProviderUnavailable => 'فراہم کنندہ دستیاب نہیں ہے';

  @override
  String get errorProviderUnavailableDesc =>
      'فراہم کنندہ عارضی طور پر دستیاب نہیں ہے۔ تھوڑی دیر میں دوبارہ کوشش کریں۔';

  @override
  String get errorServerError => 'سرور کی خرابی';

  @override
  String get errorServerErrorDesc =>
      'سرور کی خرابی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get attachmentNotAvailableOnPlatform =>
      'اس پلیٹ فارم پر منسلک فائل کے اقدامات دستیاب نہیں ہیں۔';

  @override
  String get attachmentUnableToOpenLink => 'منسلکہ لنک کھولنے میں ناکام۔';

  @override
  String get attachmentNoValidLocation =>
      'منسلکہ کوئی درست مقام فراہم نہیں کرتا۔';

  @override
  String get attachmentDownloadStarted => 'منسلکہ ڈاؤن لوڈ شروع ہو گیا۔';

  @override
  String get attachmentCouldNotDownload => 'منسلکہ ڈاؤن لوڈ نہیں کیا جا سکا۔';

  @override
  String get attachmentCouldNotDecode =>
      'منسلک ڈیٹا کو ڈی کوڈ نہیں کیا جا سکا۔';

  @override
  String get attachmentPayloadEmpty => 'منسلکہ کا پے لوڈ خالی ہے۔';

  @override
  String attachmentSavedAndOpened(String path) {
    return 'منسلکہ $path میں محفوظ اور کھول دیا گیا۔';
  }

  @override
  String attachmentSavedTo(String path) {
    return 'منسلکہ $path میں محفوظ کر دیا گیا۔';
  }

  @override
  String get attachmentCouldNotSave =>
      'اس ڈیوائس پر منسلک فائل محفوظ نہیں کی جا سکی۔';

  @override
  String get attachmentSaveCanceled => 'محفوظ کرنا منسوخ کر دیا گیا۔';

  @override
  String attachmentSavedPath(String path) {
    return 'منسلکہ $path میں محفوظ کر دیا گیا۔';
  }

  @override
  String get attachmentPathEmpty => 'منسلکہ کا راستہ خالی ہے۔';

  @override
  String get attachmentLocalNotFound =>
      'اس ڈیوائس پر مقامی منسلک فائل نہیں ملی۔';

  @override
  String get attachmentUnableToOpenLocal =>
      'مقامی منسلک فائل کھولنے میں ناکام۔';

  @override
  String speechDesktopOnly(String service) {
    return '$service صرف ڈیسک ٹاپ پر دستیاب ہے۔';
  }

  @override
  String speechRuntimeFailed(String service) {
    return '$service رن ٹائم شروع ہونے میں ناکام رہا۔';
  }

  @override
  String speechModelFilesIncomplete(String service) {
    return '$service ماڈل فائلیں نامکمل ہیں۔';
  }

  @override
  String get speechMicPermissionDisabled => 'مائیکروفون کی اجازت غیر فعال ہے۔';

  @override
  String speechUnavailableOnPlatform(String service) {
    return 'اس پلیٹ فارم پر $service اسپیچ دستیاب نہیں ہے۔';
  }

  @override
  String get terminalOpenToConnect =>
      'سرور پروجیکٹ ٹرمینل سے منسلک ہونے کے لیے ٹرمینل کھولیں۔';

  @override
  String get terminalNotAvailableYet =>
      'اس رن ٹائم پر ابھی ایمبیڈڈ ٹرمینل دستیاب نہیں ہے۔';

  @override
  String get terminalSelectServer =>
      'ٹرمینل کھولنے سے پہلے ایک فعال سرور منتخب کریں۔';

  @override
  String get terminalOpenProjectFirst =>
      'سرور ٹرمینل شروع کرنے سے پہلے پروجیکٹ فولڈر کھولیں۔';

  @override
  String terminalConnectingTo(String serverName) {
    return '$serverName ٹرمینل سے منسلک ہو رہا ہے...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'ٹرمینل کنکشن ناکام رہا: $error';
  }

  @override
  String get terminalDisconnected => 'ٹرمینل منقطع ہو گیا۔';

  @override
  String get terminalSessionClosed => 'ٹرمینل سیشن بند کر دیا گیا۔';

  @override
  String get notificationConversationUpdates => 'گفتگو کی اپ ڈیٹس';

  @override
  String get notificationOpenToClear =>
      'متعلقہ اطلاعات کو صاف کرنے کے لیے یہ گفتگو کھولیں۔';

  @override
  String get notificationAgentFinished =>
      'ایجنٹ نے موجودہ جواب مکمل کر لیا ہے۔';

  @override
  String get notificationSession => 'سیشن';

  @override
  String get chatBadgeServerNeedsAttention => 'سرور کنکشن پر توجہ کی ضرورت ہے۔';

  @override
  String chatBadgeConversationError(String title) {
    return '\"$title\" میں ایک خرابی ہے۔';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '\"$title\" کو آپ کے ان پٹ کی ضرورت ہے۔';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '\"$title\" کا ایک نیا جواب آیا ہے۔';
  }

  @override
  String get chatBadgeSyncing => 'گفتگو کی مطابقت پذیری ہو رہی ہے...';

  @override
  String get chatBadgeDataSaverActive => 'سیلولر ڈیٹا سیور فعال ہے۔';

  @override
  String get chatCollapseGroup => 'گروپ کو سکیڑیں';

  @override
  String get chatExpandGroup => 'گروپ کو پھیلائیں';

  @override
  String get chatForkFailed => 'گفتگو کو فورک کرنے میں ناکام';

  @override
  String get chatForked => 'گفتگو فورک کر دی گئی';

  @override
  String get chatNoConversationsInProject =>
      'اس پروجیکٹ میں کوئی گفتگو نہیں ہے۔';

  @override
  String get chatOpenProjectToLoad => 'گفتگو لوڈ کرنے کے لیے پروجیکٹ کھولیں۔';

  @override
  String get chatExportCanceled => 'سیشن ایکسپورٹ منسوخ کر دیا گیا';

  @override
  String get chatLargeContentSkipped =>
      'استحکام کے لیے بڑے یا ناقص مواد کو چھوڑ دیا گیا۔';

  @override
  String chatTokensLabel(int total) {
    return 'ٹوکنز: $total';
  }

  @override
  String chatCostLabel(String cost) {
    return 'لاگت: \$$cost';
  }

  @override
  String get chatFileExplorerNames => 'نام';

  @override
  String get chatFileExplorerContents => 'مشمولات';

  @override
  String chatCloseProject(String project) {
    return '$project بند کریں';
  }

  @override
  String get sessionExportUser => 'صارف';

  @override
  String get sessionExportAssistant => 'اسسٹنٹ';

  @override
  String get sessionExportInput => 'ان پٹ:';

  @override
  String get sessionExportOutput => 'آؤٹ پٹ:';

  @override
  String get sessionExportError => 'خرابی:';

  @override
  String get sessionExportUntitled => 'بغیر عنوان والا سیشن';

  @override
  String get modelLabelTinyEnglish => 'Tiny (انگریزی)';

  @override
  String get modelLabelBaseEnglish => 'بنیادی (انگریزی)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 یورپی زبانیں)';

  @override
  String get cannedNewQuickReply => 'نیا فوری جواب';

  @override
  String get settingsSoundPickerNotAvailable =>
      'سسٹم ساؤنڈ پیکر اس پلیٹ فارم پر دستیاب نہیں ہے۔';

  @override
  String get appProviderPrimaryServer => 'بنیادی سرور';

  @override
  String get appProviderLocalManaged => 'مقامی OpenCode (منظم)';

  @override
  String get appProviderLocalServerStopped => 'مقامی سرور روکا ہوا ہے۔';

  @override
  String get appProviderRunDiagnostics =>
      'مقامی OpenCode ضروریات کی تصدیق کے لیے تشخیص چلائیں۔';

  @override
  String get appProviderInvalidServerUrl => 'غلط سرور URL';

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth اس پلیٹ فارم پر تعاون یافتہ نہیں ہے';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale اس پلیٹ فارم پر تعاون یافتہ نہیں ہے';

  @override
  String get appProviderProfileNotFound => 'سرور پروفائل نہیں ملا';

  @override
  String get appProviderCannotActivateUnhealthy =>
      'غیر صحت مند سرور کو فعال نہیں کیا جا سکتا';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode کا پتہ چل گیا';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode کا پتہ نہیں چلا';

  @override
  String get appProviderDetectingCommand =>
      'OpenCode کمانڈ کا پتہ لگایا جا رہا ہے...';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'OpenCode کمانڈ کا پتہ نہیں چلا۔ اگر آپ نے اسے تھوڑی دیر پہلے انسٹال کیا ہے تو، چیکس کو ریفریش کریں یا PATH کو دوبارہ لوڈ کرنے کے لیے $appName کو دوبارہ کھولیں۔';
  }

  @override
  String get appProviderNotDetectedInstall =>
      'OpenCode کمانڈ کا پتہ نہیں چلا۔ وزرڈ سے انسٹالیشن چلائیں۔';

  @override
  String appProviderUsingCommandAt(String path) {
    return '$path پر OpenCode کمانڈ استعمال ہو رہی ہے';
  }

  @override
  String get appProviderDesktopOnly =>
      'منظم مقامی سرور صرف ڈیسک ٹاپ پر دستیاب ہے۔';

  @override
  String get appProviderInstallingRequirements =>
      'OpenCode کی ضروریات انسٹال ہو رہی ہیں...';

  @override
  String get appProviderInstallationFailed =>
      'OpenCode کی انسٹالیشن ناکام ہوگئی۔';

  @override
  String get appProviderInstalledSuccessfully =>
      'OpenCode کی ضروریات کامیابی سے انسٹال ہو گئیں۔';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'انسٹالیشن کامیاب رہی۔ OpenCode کمانڈ $path پر دستیاب ہے۔';
  }

  @override
  String get appProviderInstallSucceeded => 'انسٹالیشن کامیاب رہی۔';

  @override
  String get appProviderStartingLocalServer => 'مقامی سرور شروع ہو رہا ہے...';

  @override
  String get appProviderFailedToStart =>
      'مقامی OpenCode سرور شروع کرنے میں ناکام۔';

  @override
  String appProviderRunningAt(String url) {
    return '$url پر چل رہا ہے';
  }

  @override
  String get appProviderStoppingLocalServer => 'مقامی سرور روکا جا رہا ہے...';

  @override
  String appProviderExitedWithCode(int code) {
    return 'مقامی سرور کوڈ $code کے ساتھ بند ہوا۔';
  }

  @override
  String get appProviderInstallBinary => 'بائنری انسٹال کریں';

  @override
  String get appProviderInstallViaNpm => 'npm کے ذریعے انسٹال کریں';

  @override
  String get appProviderInstallViaBun => 'Bun کے ذریعے انسٹال کریں';

  @override
  String get appProviderInstallBunOpenCode => 'Bun + OpenCode انسٹال کریں';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'اس پلیٹ فارم پر Tailscale سپورٹ نہیں ہے۔';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'ونڈوز پر Tailscale سپورٹ نہیں ہے۔';

  @override
  String get tailscaleWaitingAdminApproval =>
      'یہ Tailscale نوڈ ایڈمن کی منظوری کا منتظر ہے۔';

  @override
  String get notificationSoundLoadFailed =>
      'اینڈرائیڈ سسٹم کی آوازیں لوڈ کرنے میں ناکام';

  @override
  String get chatDescriptionNewConversation => 'نئی گفتگو';

  @override
  String get chatDescriptionRefreshData => 'چیٹ ڈیٹا کو ریفریش کریں';

  @override
  String get chatDescriptionFocusInput => 'پیغام کے ان پٹ پر توجہ مرکوز کریں';

  @override
  String get chatDescriptionVoiceInput => 'صوتی ان پٹ شروع کریں یا روکیں';

  @override
  String get chatDescriptionQuickOpen => 'فائلیں جلدی کھولیں';

  @override
  String get chatDescriptionOpenSettings => 'ترتیبات کھولیں';

  @override
  String get chatDescriptionCycleModels => 'حالیہ ماڈلز کو تبدیل کریں';

  @override
  String get chatDescriptionCycleVariant => 'ماڈل کی قسم کو تبدیل کریں';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      'ان پٹ پر توجہ مرکوز کریں (یا دراز کھلا ہونے پر بند کریں)';

  @override
  String get chatDescriptionNextAgent => 'اگلا ایجنٹ';

  @override
  String get chatDescriptionPreviousAgent => 'پچھلا ایجنٹ';

  @override
  String get chatDescriptionCloseApp =>
      'پلیٹ فارم کے بند کرنے کے رویے کا استعمال کرتے ہوئے ایپ بند کریں';

  @override
  String get chatDescriptionForceExit => 'ایپ سے زبردستی باہر نکلیں';

  @override
  String get chatDescriptionStopResponse =>
      'فعال جواب کو روکیں (جواب دیتے وقت)';

  @override
  String get chatDescriptionProjectCommand => 'پروجیکٹ کمانڈ';

  @override
  String get chatDescriptionOpenProjects =>
      'اپنے پروجیکٹس اور گفتگو کو کھولنے کے لیے یہ بٹن استعمال کریں۔';

  @override
  String get chatDescriptionSwitchProject =>
      'پروجیکٹ فولڈرز اور سیاق و سباق کو تبدیل کرنے کے لیے یہ بٹن استعمال کریں۔';

  @override
  String chatDescriptionChildren(int count) {
    return 'ذیلی عناصر: $count';
  }

  @override
  String get chatDescriptionDiffFilesZero => 'ڈیف فائلیں: 0';

  @override
  String get appProviderErrorInvalidServerUrl => 'غلط سرور URL';

  @override
  String get appProviderErrorServerUrlRequired => 'سرور کا URL درکار ہے';

  @override
  String get appProviderErrorServerAlreadyExists =>
      'اس URL والا سرور پہلے سے موجود ہے';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth اس پلیٹ فارم پر تعاون یافتہ نہیں ہے';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale اس پلیٹ فارم پر تعاون یافتہ نہیں ہے';

  @override
  String get appProviderErrorServerProfileNotFound => 'سرور پروفائل نہیں ملا';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      'غیر صحت مند سرور کو فعال نہیں کیا جا سکتا';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      'منظم مقامی سرور صرف ڈیسک ٹاپ پر دستیاب ہے۔';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'مقامی سرور شروع ہوا لیکن ہیلتھ چیک پاس نہیں ہوا۔';

  @override
  String get appProviderErrorInstallationFailed =>
      'OpenCode کی انسٹالیشن ناکام ہوگئی۔';

  @override
  String get appProviderStatusLocalServerStopped => 'مقامی سرور روکا ہوا ہے۔';

  @override
  String get appProviderStatusStartingLocalServer =>
      'مقامی سرور شروع ہو رہا ہے...';

  @override
  String appProviderStatusRunningAt(String url) {
    return '$url پر چل رہا ہے';
  }

  @override
  String get appProviderStatusStoppingLocalServer =>
      'مقامی سرور روکا جا رہا ہے...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'مقامی سرور کوڈ $code کے ساتھ بند ہوا۔';
  }

  @override
  String get appProviderSetupDetectingOpenCode =>
      'OpenCode کمانڈ کا پتہ لگایا جا رہا ہے...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode کا پتہ چل گیا';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode کا پتہ نہیں چلا';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return '$path پر OpenCode کمانڈ استعمال ہو رہی ہے';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'OpenCode کی ضروریات انسٹال ہو رہی ہیں...';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'OpenCode کی ضروریات کامیابی سے انسٹال ہو گئیں۔';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'انسٹالیشن کامیاب رہی۔ OpenCode کمانڈ $path پر دستیاب ہے۔';
  }

  @override
  String get appProviderSetupInstallationSucceeded => 'انسٹالیشن کامیاب رہی۔';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'OpenCode کمانڈ کا پتہ نہیں چلا۔ اگر آپ نے اسے تھوڑی دیر پہلے انسٹال کیا ہے تو، چیکس کو ریفریش کریں یا PATH کو دوبارہ لوڈ کرنے کے لیے CodeWalk کو دوبارہ کھولیں۔';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'OpenCode کمانڈ کا پتہ نہیں چلا۔ وزرڈ سے انسٹالیشن چلائیں۔';

  @override
  String get appProviderLabelPrimaryServer => 'بنیادی سرور';

  @override
  String get appProviderLabelLocalOpenCodeManaged => 'مقامی OpenCode (منظم)';

  @override
  String get chatChooseModel => 'ماڈل منتخب کریں';

  @override
  String get chatStartVoiceInput => 'صوتی ان پٹ شروع کریں';

  @override
  String get chatStopVoiceInput => 'صوتی ان پٹ روکیں';

  @override
  String get chatStartingVoiceInput => 'صوتی ان پٹ شروع ہو رہا ہے';

  @override
  String get chatComposerPlaceholder => 'اپنی ضروریات ٹائپ کریں...';

  @override
  String get chatPermissionAutoApproveOn => 'اجازت خودکار منظوری آن ہے';

  @override
  String get chatPermissionAutoApproveOff => 'اجازت خودکار منظوری آف ہے';

  @override
  String get chatModelLockedSubConversation => 'ذیلی گفتگو میں ماڈل مقفل ہے';

  @override
  String get chatComposerHintShell => 'شیل کمانڈ (باہر نکلنے کے لیے Esc)';

  @override
  String get utilityTitle => 'افادیت';

  @override
  String get statusOffline => 'آف لائن';

  @override
  String get statusOnline => 'آن لائن';

  @override
  String get statusConnected => 'منسلک';

  @override
  String get statusReconnecting => 'دوبارہ منسلک ہو رہا ہے';

  @override
  String get statusSyncDelayed => 'ہم آہنگی میں تاخیر';

  @override
  String get statusDelayed => 'تاخیر شدہ';

  @override
  String get chatActiveServerUnhealthyLabel => 'فعال سرور غیر صحت مند ہے';

  @override
  String get chatWaitingForNetworkConnection => 'نیٹ ورک کنکشن کا انتظار...';

  @override
  String get serverHealthHealthy => 'صحت مند';

  @override
  String get serverHealthUnhealthy => 'غیر صحت مند';

  @override
  String get serverHealthUnknown => 'نامعلوم';

  @override
  String get sessionUnshare => 'شیئرنگ ختم کریں';

  @override
  String get sessionShare => 'سیشن شیئر کریں';

  @override
  String get sessionExportMarkdown => 'Markdown برآمد کریں';

  @override
  String get sessionExportDebugJson => 'ڈیبگ JSON برآمد کریں';

  @override
  String get sessionViewTasks => 'کام دیکھیں';

  @override
  String get sessionCompactContext => 'سیاق و سباق کمپیکٹ کریں';

  @override
  String get sessionUnshared => 'گفتگو غیر مشترکہ ہو گئی';

  @override
  String get sessionShared => 'گفتگو مشترکہ ہو گئی';

  @override
  String get sessionShareLinkUnavailable => 'اس سیشن کے لیے لنک دستیاب نہیں';

  @override
  String get sessionExportMarkdownTitle =>
      'سیشن کو Markdown کے طور پر برآمد کریں';

  @override
  String get sessionExportDebugJsonTitle =>
      'سیشن کو ڈیبگ JSON کے طور پر برآمد کریں';

  @override
  String get sessionExportCanceled => 'برآمد منسوخ کر دی گئی';

  @override
  String get sessionExportMarkdownSaved => 'Markdown برآمد محفوظ ہو گئی';

  @override
  String get sessionExportDebugJsonSaved => 'ڈیبگ JSON برآمد محفوظ ہو گئی';

  @override
  String get sessionExportMarkdownErrorClipboard =>
      'فائل محفوظ نہیں ہو سکی؛ Markdown کلپ بورڈ پر کاپی کر دیا گیا';

  @override
  String get sessionExportDebugJsonErrorClipboard =>
      'فائل محفوظ نہیں ہو سکی؛ ڈیبگ JSON کلپ بورڈ پر کاپی کر دیا گیا';

  @override
  String get terminalHide => 'ٹرمینل چھپائیں';

  @override
  String get terminalOpen => 'ٹرمینل کھولیں';

  @override
  String get terminalOpenInfo => 'ٹرمینل کی معلومات کھولیں';

  @override
  String get chatNoSessionSelected =>
      'چیٹ شروع کرنے کے لیے گفتگو منتخب یا بنائیں';

  @override
  String get chatWelcomeMessage => 'ہیلو! میں آپ کا AI معاون ہوں۔';

  @override
  String get chatWelcomeSubmessage => 'آج میں آپ کی کس طرح مدد کر سکتا ہوں؟';

  @override
  String get cannedAppendAtCursor => 'کرسر پر شامل کریں';

  @override
  String get cannedReplace => 'تبدیل کریں';

  @override
  String get chatMessageAttachedFile => 'منسلک فائل';

  @override
  String get chatMessageThinking => 'سوچ رہا ہے';

  @override
  String get chatMessageShow => 'دکھائیں';

  @override
  String get chatMessageMore => 'مزید';

  @override
  String get chatMessageLess => 'کم';

  @override
  String get chatMessageDetails => 'تفصیلات';

  @override
  String get chatMessageToolInput => 'ان پٹ';

  @override
  String get chatMessageToolCommand => 'کمانڈ';

  @override
  String chatMessageToolRunningCount(int count) {
    return '$count چل رہے ہیں';
  }

  @override
  String chatMessageToolQueuedCount(int count) {
    return '$count قطار میں ہیں';
  }

  @override
  String get chatMessageToolOutputTruncated =>
      'بڑے آؤٹ پٹ کا پیش نظارہ استحکام کے لیے مختصر کیا گیا۔';

  @override
  String get chatMessageToolCommandTruncated =>
      'کمانڈ کا پیش نظارہ استحکام کے لیے مختصر کیا گیا۔';

  @override
  String get chatMessageToolInputTruncated =>
      'ان پٹ کا پیش نظارہ استحکام کے لیے مختصر کیا گیا۔';

  @override
  String get chatMessageToolDiffOmitted =>
      'Diff پیش نظارہ خارج کر دیا گیا: ترمیم کا پے لوڈ موبائل پر محفوظ طریقے سے دکھانے کے لیے بہت بڑا ہے۔';

  @override
  String get terminalTitle => 'ٹرمینل';

  @override
  String get chatCouldNotRefreshSession => 'یہ گفتگو تازہ نہیں کی جا سکی';

  @override
  String get chatMainConversationUnavailable =>
      'مرکزی گفتگو ابھی دستیاب نہیں ہے۔';

  @override
  String get chatFailedToRefreshSubConversations =>
      'ذیلی گفتگو تازہ کرنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get chatNoSubConversationFound =>
      'اس کام کے لیے کوئی ذیلی گفتگو نہیں ملی۔';

  @override
  String get errorAnErrorOccurred => 'ایک خرابی پیش آگئی';

  @override
  String get serverConnectionAttention => 'سرور کنکشن پر توجہ درکار ہے۔';

  @override
  String sessionHasError(String title) {
    return '\"$title\" میں خرابی ہے۔';
  }

  @override
  String sessionNeedsInput(String title) {
    return '\"$title\" کو آپ کے ان پٹ کی ضرورت ہے۔';
  }

  @override
  String sessionHasNewReply(String title) {
    return '\"$title\" میں نیا جواب ہے۔';
  }

  @override
  String get sessionSyncing => 'گفتگو ہم آہنگ ہو رہی ہے...';

  @override
  String get behaviorCellularDataSaverActive => 'سیلولر ڈیٹا سیور فعال ہے۔';

  @override
  String get sessionNoCachedConversations =>
      'ابھی تک کوئی محفوظ کردہ گفتگو نہیں';

  @override
  String get sessionForkFailed => 'گفتگو کا فورک ناکام ہوا';

  @override
  String get sessionForked => 'گفتگو فورک ہو گئی';

  @override
  String get sessionNoConversationsInProject =>
      'اس پروجیکٹ میں کوئی گفتگو نہیں۔';

  @override
  String get sessionOpenProjectToLoad =>
      'گفتگو لوڈ کرنے کے لیے پروجیکٹ کھولیں۔';

  @override
  String sessionChildrenCount(int count) {
    return 'ذیلی گفتگو: $count';
  }

  @override
  String sessionDiffFilesCount(int count) {
    return 'Diff فائلیں: $count';
  }

  @override
  String get compactionAutomatic => 'خودکار';

  @override
  String get compactionManual => 'دستی';

  @override
  String get chatMessageShowLessCompact => 'کم';

  @override
  String get chatMessageShowLess => 'کم دکھائیں';

  @override
  String get chatMessageShowMoreCompact => 'مزید';

  @override
  String get chatMessageShowMore => 'مزید دکھائیں';

  @override
  String get chatChooseAgent => 'ایجنٹ منتخب کریں';

  @override
  String get chatEffortLockedSubConversation => 'ذیلی گفتگو میں کوشش مقفل ہے';

  @override
  String get chatChooseEffort => 'کوشش منتخب کریں';

  @override
  String get chatServerSelectedModel => 'سرور کے ذریعے منتخب کردہ ماڈل';

  @override
  String get chatFailedToRefreshProviders =>
      'فراہم کنندگان اور ماڈلز تازہ کرنے میں ناکامی';

  @override
  String get cannedAddTitle => 'فوری جواب شامل کریں';

  @override
  String get cannedEditTitle => 'فوری جواب میں ترمیم کریں';

  @override
  String get cannedTextLabel => 'متن';

  @override
  String get cannedAppendAtCursorSubtitle =>
      'بند = موجودہ کمپوزر متن تبدیل کریں';

  @override
  String get cannedSendAutomaticallySubtitle =>
      'فوری جواب ڈالنے کے فوراً بعد بھیجیں';

  @override
  String get cannedScopeGlobalSubtitle =>
      'صرف پروجیکٹ آئٹم کے لیے غیر فعال کریں';

  @override
  String get cannedScopeGlobalUnavailableSubtitle =>
      'موجودہ سیاق میں صرف پروجیکٹ دستیاب نہیں';

  @override
  String get commonFile => 'فائل';

  @override
  String get serversSearchActiveHint => 'فعال سرور تلاش کریں';

  @override
  String get serversNoServersFound => 'کوئی سرور نہیں ملا';

  @override
  String get serversUnhealthyActivateError =>
      'یہ سرور غیر صحت مند ہے۔ فعال کرنے سے پہلے صحت چیک کریں یا ترتیبات میں ترمیم کریں۔';

  @override
  String get serversTailscaleConnected => 'Tailscale منسلک';

  @override
  String get serversTailscaleConnecting => 'Tailscale منسلک ہو رہا ہے';

  @override
  String get serversTailscaleAuthRequired => 'Tailscale تصدیق درکار';

  @override
  String get serversTailscaleAdminApprovalRequired =>
      'Tailscale ایڈمن کی منظوری درکار';

  @override
  String get serversTailscaleConnectionFailed => 'Tailscale کنکشن ناکام';

  @override
  String get serversTailscaleUnsupported => 'Tailscale تعاون یافتہ نہیں';

  @override
  String get serversTailscaleDisconnected => 'Tailscale منقطع';

  @override
  String get serversTailscaleLoginExplanation =>
      'اس ڈیوائس کو اپنے tailnet میں شامل کرنے کے لیے Tailscale لاگ ان URL کھولیں۔';

  @override
  String get serversTailscaleTrafficExplanation =>
      'اس فعال پروفائل کے لیے OpenCode ٹریفک Tailscale کے ذریعے روٹ کی جاتی ہے۔';

  @override
  String get serversTailscaleConnectExplanation =>
      'जब یہ فعال پروفائل استعمال کیا جائے گا تو Tailscale منسلک ہو جائے گا۔';

  @override
  String get statusStarting => 'شروع ہو رہا ہے';

  @override
  String get statusStopping => 'روکا جا رہا ہے';

  @override
  String get statusFailed => 'ناکام';

  @override
  String get statusStopped => 'روک دیا گیا';

  @override
  String get serversDesktopModeExplanation =>
      'ڈیسک ٹاپ موڈ CodeWalk سے براہ راست `opencode serve` لانچ اور منظم کر سکتا ہے۔';

  @override
  String get serversCannotActivateUnhealthy =>
      'غیر صحت مند سرور کو فعال نہیں کیا جا سکتا';

  @override
  String get commonCopiedToClipboard => 'کلپ بورڈ پر کاپی ہو گیا';

  @override
  String get chatUndoNothing => 'اس سیشن میں کالعدم کرنے کے لیے کچھ نہیں ہے';

  @override
  String get chatRedoNothing => 'اس سیشن میں دوبارہ کرنے کے لیے کچھ نہیں ہے';

  @override
  String get chatStatusPatching => 'پیچنگ ہو رہی ہے';

  @override
  String get chatStatusPatchingOneFile => '1 فائل پیچ ہو رہی ہے';

  @override
  String chatStatusPatchingMultipleFiles(int count) {
    return '$count فائلیں پیچ ہو رہی ہیں';
  }

  @override
  String get chatStatusThinking => 'سوچ رہا ہے...';

  @override
  String get chatStatusSubsession => 'سب سیشن';

  @override
  String get chatStatusBusy => 'حالت: مصروف';

  @override
  String get chatStatusRetry => 'حالت: دوبارہ کوشش';

  @override
  String chatStatusRetryCount(int count) {
    return 'حالت: دوبارہ کوشش #$count';
  }

  @override
  String get appShellUpdateInstalledRestartRequired =>
      'اپ ڈیٹ انسٹال ہو گئی۔ نیا ورژن لاگو کرنے کے لیے دوبارہ شروع کرنا ضروری ہے۔';

  @override
  String get appShellUpdateInstalledRestartApp =>
      'اپ ڈیٹ انسٹال ہو گئی۔ لاگو کرنے کے لیے ایپ دوبارہ شروع کریں۔';

  @override
  String get chatTourProjectsConversations =>
      'اپنے پروجیکٹس اور گفتگو کو کھولنے کے لیے اس بٹن کا استعمال کریں۔';

  @override
  String get chatTourSwitchFolders =>
      'پروجیکٹ فولڈرز اور سیاق و سباق کو تبدیل کرنے کے لیے اس بٹن کا استعمال کریں۔';

  @override
  String get chatTourSidebarProjectTools =>
      'گفتگو کا سائڈبار اور پروجیکٹ ٹولز دکھانے کے لیے اس مینو کا استعمال کریں۔';

  @override
  String get chatActionNext => 'اگلا';

  @override
  String get chatShortcutsNewConversation => 'نئی گفتگو';

  @override
  String get chatShortcutsRefreshChat => 'چیٹ ڈیٹا ریفریش کریں';

  @override
  String get chatShortcutsFocusInput => 'پیغام ان پٹ پر فوکس کریں';

  @override
  String get chatShortcutsStartStopVoice => 'وائس ان پٹ شروع یا بند کریں';

  @override
  String get chatShortcutsQuickOpen => 'فائلیں جلدی کھولیں';

  @override
  String get chatShortcutsOpenSettings => 'ترتیبات کھولیں';

  @override
  String get chatShortcutsCycleModels => 'حالیہ ماڈلز تبدیل کریں';

  @override
  String get chatShortcutsCycleVariant => 'ماڈل کی قسم تبدیل کریں';

  @override
  String get chatShortcutsFocusInputCloseDrawer =>
      'ان پٹ پر فوکس کریں (یا کھلا ہونے پر دراز بند کریں)';

  @override
  String get chatShortcutsNextAgent => 'اگلا ایجنٹ';

  @override
  String get chatShortcutsPreviousAgent => 'پچھلا ایجنٹ';

  @override
  String get chatShortcutsCloseApp =>
      'پلیٹ فارم کا رویہ استعمال کرتے ہوئے ایپ بند کریں';

  @override
  String get chatShortcutsForceExit => 'ایپ سے زبردستی باہر نکلیں';

  @override
  String get chatShortcutsStopResponse => 'فعال جواب روکیں (جواب دیتے وقت)';

  @override
  String get chatTipMentionFiles =>
      'مشورہ: اپنے پرامپٹ میں فائلوں کا ذکر کرنے کے لیے @ استعمال کریں';

  @override
  String get chatTipRenameConversation =>
      'مشورہ: گفتگو کا نام بدلنے کے لیے عنوان پر ٹیپ کریں';

  @override
  String get chatTipShellCommands =>
      'مشورہ: شیل کمانڈز چلانے کے لیے شروع میں ! استعمال کریں';

  @override
  String get chatTipSlashCommands =>
      'مشورہ: سلیش کمانڈز تک رسائی کے لیے / استعمال کریں';

  @override
  String get chatTipLongPressSend =>
      'مشورہ: نئی لائن ڈالنے کے لیے سینڈ کو دیر تک دبائیں';

  @override
  String get chatTipContextKnob =>
      'مشورہ: استعمال کی تفصیلات دیکھنے کے لیے سیاق و سباق کے نوب پر ٹیپ کریں';

  @override
  String get chatTipBeSpecific =>
      'مشورہ: مخصوص بنیں — چھوٹے پرامپٹ کا جواب تیزی سے ملتا ہے';

  @override
  String get chatTipStepByStep =>
      'مشورہ: پیچیدہ مسائل کو ڈیبگ کرتے وقت مرحلہ وار پوچھیں';

  @override
  String get chatTipProvideContext =>
      'مشورہ: سیاق و سباق فراہم کریں — غلطی کے پیغامات اور لاگز پیسٹ کریں';

  @override
  String get chatTipBreakTasks =>
      'مشورہ: بڑے کاموں کو چھوٹے پرامپٹ میں تقسیم کریں';

  @override
  String get chatFailedToLoadDirectories => 'ڈائریکٹریز لوڈ کرنے میں ناکام';

  @override
  String get logsFilterAll => 'تمام';

  @override
  String get logsNoLogsYet => 'ابھی تک کوئی لاگز جمع نہیں ہوئے۔';

  @override
  String get logsNoMatchingLogs =>
      'موجودہ فلٹرز سے کوئی لاگز مطابقت نہیں رکھتے۔';

  @override
  String get settingsDefaultModel => 'ڈیفالٹ ماڈل';

  @override
  String get settingsSearchDefaultModel => 'ڈیفالٹ ماڈل تلاش کریں';

  @override
  String get settingsDefaultAgent => 'ڈیفالٹ ایجنٹ';

  @override
  String get settingsSearchDefaultAgent => 'ڈیفالٹ ایجنٹ تلاش کریں';

  @override
  String get settingsNoAgentsFound => 'کوئی ایجنٹ نہیں ملا';

  @override
  String get settingsConversationUsername => 'گفتگو کا صارف نام';

  @override
  String get settingsUsernameUnsetExplanation =>
      'OpenCode سسٹم کا صارف نام استعمال کرتا ہے کیونکہ `username` سیٹ نہیں ہے۔';

  @override
  String get settingsUsernameResetExplanation =>
      '`/config` پیچ اپ ڈیٹس کیز کو حذف نہیں کر سکتے، اس لیے `username` کو سسٹم ڈیفالٹ پر ری سیٹ کرنے کے لیے اب بھی ایپ سے باہر ترتیب میں ترمیم کی ضرورت ہے۔';

  @override
  String get chatHelpMessage =>
      'ذکر کے لیے @، شیل کے لیے !، کمانڈز کے لیے / استعمال کریں';

  @override
  String terminalEmbeddedUnavailable(String serverName) {
    return 'ایمبیڈڈ ٹرمینل ابھی اس رن ٹائم پر دستیاب نہیں ہے۔ ایک بار کی کمانڈز کے لیے کمپوزر شیل موڈ کا استعمال جاری رکھیں یا $serverName کے لیے سپورٹڈ CodeWalk ایپ رن ٹائم سے ٹرمینل کھولیں۔';
  }

  @override
  String get chatFailedToLoadFile => 'فائل لوڈ کرنے میں ناکام';

  @override
  String get chatMentionFileSubtitle => 'فائل';

  @override
  String get chatMentionSymbolSubtitle => 'علامت';

  @override
  String get chatMentionAgentSubtitle => 'ایجنٹ';

  @override
  String get chatCommandSourceGeneric => 'کمانڈ';

  @override
  String get chatCommandSourceProject => 'پروجیکٹ';

  @override
  String get chatCommandDescriptionProject => 'پروجیکٹ کمانڈ';

  @override
  String get settingsSmallModel => 'چھوٹا ماڈل';

  @override
  String get settingsSearchSmallModel => 'چھوٹا ماڈل تلاش کریں';

  @override
  String get settingsSmallModelUnsetExplanation =>
      'OpenCode خودکار فال بیک فعال ہے کیونکہ `small_model` سیٹ نہیں ہے۔';

  @override
  String get settingsSmallModelResetExplanation =>
      '`/config` پیچ اپ ڈیٹس کیز کو حذف نہیں کر سکتے، اس لیے `small_model` کو خودکار فال بیک پر ری سیٹ کرنے کے لیے اب بھی ایپ سے باہر ترتیب میں ترمیم کی ضرورت ہے۔';

  @override
  String get settingsOpenCodeAutoUpdate => 'OpenCode خودکار اپ ڈیٹ';

  @override
  String get settingsSearchAutoUpdateMode => 'خودکار اپ ڈیٹ موڈ تلاش کریں';

  @override
  String get settingsOpenCodeSharingDefault => 'OpenCode شیئرنگ ڈیفالٹ';

  @override
  String get settingsSearchSharingMode => 'شیئرنگ موڈ تلاش کریں';

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
