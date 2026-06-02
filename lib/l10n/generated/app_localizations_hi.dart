// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appShellDownloadingUpdate => 'अपडेट डाउनलोड हो रहा है';

  @override
  String get appShellInstall => 'इंस्टॉल करें';

  @override
  String get appShellInstallFailed => 'इंस्टॉलेशन विफल';

  @override
  String get appShellInstallingUpdate => 'अपडेट इंस्टॉल हो रहा है...';

  @override
  String get appShellRestart => 'पुनः आरंभ करें';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return 'अपडेट उपलब्ध: v$latestVersion';
  }

  @override
  String get behaviorAdvancedPermissionRule => 'उन्नत अनुमति नियम';

  @override
  String get behaviorAutomatic => 'स्वचालित';

  @override
  String get behaviorAutomaticFallback => 'स्वचालित फॉलबैक';

  @override
  String get behaviorCellularDataSaver => 'मोबाइल डेटा सेवर';

  @override
  String get behaviorChatLevelShare => 'चैट-स्तर साझाकरण';

  @override
  String get behaviorCodeWalkReleaseChecks => 'CodeWalk रिलीज़ जाँच';

  @override
  String get behaviorControlsOfficialGlobal =>
      'OpenCode आधिकारिक वैश्विक सेटिंग्स नियंत्रित करता है';

  @override
  String get behaviorControlsUpstreamOpenCode =>
      'अपस्ट्रीम OpenCode सेटिंग्स नियंत्रित करता है';

  @override
  String get behaviorCustomDisplayName => 'कस्टम प्रदर्शन नाम';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return 'बैकग्राउंड डाउनलोड रोककर और अग्रभूमि स्वचालित रीफ्रेश को हर $inSeconds सेकंड में एक बर्स्ट तक सीमित करके स्वचालित मोबाइल डेटा उपयोग कम करता है।';
  }

  @override
  String get behaviorDisabled => 'अक्षम';

  @override
  String get behaviorLightweightTasksLike => 'हल्के कार्य जैसे';

  @override
  String get behaviorManual => 'मैनुअल';

  @override
  String get behaviorNotify => 'सूचित करें';

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
    return 'बच्चे: $length';
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
  String get chatDoubleESCStop => 'रुकने के लिए दो बार ESC';

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
    return '$compactionLabel संपीडन से पहले $messageCount संदेश छिपाए गए';
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
  String get chatMessageHide => 'छिपाएं';

  @override
  String get chatMessageMessagePartUnavailable => 'Message part unavailable';

  @override
  String get chatMessageMetadataAvailable => 'No metadata available';

  @override
  String chatMessageModelMessageModelId(String modelId) {
    return 'मॉडल: $modelId';
  }

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return 'प्रदाता: $providerId';
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
  String get chatOpenProject => 'प्रोजेक्ट खोलें';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenSidebar => 'साइडबार खोलें';

  @override
  String get chatPageStatusContextUsage => 'संदर्भ उपयोग';

  @override
  String get chatPageStatusCost => 'लागत';

  @override
  String get chatPageStatusLimit => 'सीमा';

  @override
  String get chatPageStatusManageServers => 'सर्वर प्रबंधित करें';

  @override
  String get chatPageStatusSaver => 'सेवर';

  @override
  String get chatPageStatusSwitchServer => 'सर्वर बदलें';

  @override
  String get chatPageStatusTokens => 'टोकन';

  @override
  String get chatPageStatusUsage => 'उपयोग';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatProjectContext => 'Project Context';

  @override
  String get chatProjectContext2 => 'प्रोजेक्ट संदर्भ';

  @override
  String get chatRealtimeGlobalEvent => 'वैश्विक घटना';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return 'वैश्विक घटना ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale => 'वैश्विक घटना (पुरानी पीढ़ी)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return 'संदेश प्रवाह ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => 'रीयलटाइम घटना';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return 'रीयलटाइम घटना ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale => 'रीयलटाइम घटना (पुरानी पीढ़ी)';

  @override
  String get chatRealtimeReconnectingServerTry =>
      'सर्वर से पुनः कनेक्ट हो रहा है। कुछ क्षण में पुनः प्रयास करें।';

  @override
  String get chatReasoning => 'तर्क कर रहा है...';

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
    return 'इतिहास से $displayName हटाएँ';
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
    return 'चैट सत्र: $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return 'वार्तालाप $nextAction';
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
  String get chatSidebarAccess => 'साइडबार एक्सेस';

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
    return 'सिंक: $label';
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
    return 'अटैचमेंट $path में सहेजा गया और खोला गया।';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return 'अटैचमेंट $path में सहेजा गया।';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return 'अटैचमेंट $savedPath में सहेजा गया।';
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
    return 'खुली फ़ाइलें ($length)';
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
    return '$length2 में से $length प्रविष्टियाँ दिखाई गईं';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => 'गणित';

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
    return 'उपकार्य ($agent)';
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
    return 'चयनित: $soundLabel';
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
    return '$length सेटअप लॉग पंक्तियाँ और $length2 सेटअप घटनाएँ अलग सेटअप डीबग स्क्रीन में उपलब्ध हैं।';
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
    return 'नवीनतम आउटपुट: $localServerLastOutput';
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
      'स्थानीय OpenCode आवश्यकताओं को सत्यापित करने के लिए निदान चलाएँ।';

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
    return 'कमांड: $localServerCommandPath';
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
    return '\"$displayName\" हटाएँ?';
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
  String get sessionCopyLink => 'लिंक कॉपी करें';

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
  String get settingsAppearanceMathRendering => 'गणित रेंडरिंग';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      'चैट संदेशों में LaTeX गणितीय अभिव्यक्तियों को टाइपसेट समीकरणों के रूप में प्रस्तुत करें।';

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
    return '$conflict के साथ विरोध';
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
    return 'शॉर्टकट सेट करें: $label';
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
  String get onboardingSetup => 'सेटअप';

  @override
  String get onboardingSetupWizard => 'सेटअप विज़ार्ड';

  @override
  String get onboardingServerSetup => 'सर्वर सेटअप';

  @override
  String get onboardingEditServer => 'सर्वर संपादित करें';

  @override
  String get onboardingLocalServerSetup => 'स्थानीय सर्वर सेटअप';

  @override
  String get onboardingReady => 'तैयार';

  @override
  String onboardingWelcomeTo(String appName) {
    return '$appName में आपका स्वागत है';
  }

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName को आपके कोड में मदद करने से पहले एक OpenCode सर्वर की आवश्यकता है।';
  }

  @override
  String get onboardingChooseHowToSetup =>
      'चुनें कि अपना सर्वर कैसे सेटअप करें';

  @override
  String get onboardingPickSetupPath =>
      'वह सेटअप पथ चुनें जो आपके वर्तमान OpenCode सेटअप से मेल खाता हो।';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'केवल डेस्कटॉप: $appName आपके लिए OpenCode का निदान, स्थापना और संचालन कर सकता है।';
  }

  @override
  String get onboardingAvailableOnlyDesktop =>
      'केवल डेस्कटॉप (Linux/macOS/Windows) पर उपलब्ध है।';

  @override
  String get onboardingServerConnection => 'सर्वर कनेक्शन';

  @override
  String get onboardingEditServerConnection => 'सर्वर कनेक्शन संपादित करें';

  @override
  String onboardingSuggestedUrl(String url) {
    return 'सुझाया गया स्थानीय OpenCode सर्वर URL: $url';
  }

  @override
  String get onboardingEmulatorRemap =>
      'Android एमुलेटर पर, localhost और 127.0.0.1 स्वचालित रूप से 10.0.2.2 पर रीमैप हो जाते हैं।';

  @override
  String get onboardingBasicAuthTip =>
      'बेसिक ऑथ को केवल तभी सक्षम करें जब आपका OpenCode सर्वर पासवर्ड से सुरक्षित हो।';

  @override
  String get onboardingEnterServerUrl => 'सर्वर URL दर्ज करें';

  @override
  String get onboardingInvalidUrl => 'अमान्य URL';

  @override
  String get onboardingTesting => 'परीक्षण जारी है...';

  @override
  String get onboardingSaveAndTest => 'सहेजें और परीक्षण करें';

  @override
  String get onboardingTestConnection => 'कनेक्शन का परीक्षण करें';

  @override
  String get onboardingTailscaleLoginRequired => 'Tailscale लॉगिन आवश्यक';

  @override
  String get onboardingTailscaleAdminApproval =>
      'Tailscale व्यवस्थापक अनुमोदन आवश्यक';

  @override
  String get onboardingTailscaleConnected => 'Tailscale कनेक्टेड';

  @override
  String get onboardingTailscaleConnecting => 'Tailscale कनेक्ट हो रहा है';

  @override
  String get onboardingTailscaleConnectionFailed =>
      'Tailscale कनेक्शन विफल रहा';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale समर्थित नहीं है';

  @override
  String get onboardingTailscaleAuthAfterSave =>
      'सहेजने के बाद Tailscale प्रमाणित होगा';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'इस डिवाइस को अपने tailnet में जोड़ने के लिए लॉगिन URL खोलें। यदि ब्राउज़र नहीं खुला, तो नीचे दिए गए URL को कॉपी करें।';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'इस सर्वर को सहेजने और परीक्षण करने के बाद, $appName Tailscale लॉगिन खोलेगा यदि यह डिवाइस अभी तक प्रमाणित नहीं है।';
  }

  @override
  String get onboardingStarting => 'शुरू हो रहा है';

  @override
  String get onboardingStopping => 'रुक रहा है';

  @override
  String get onboardingFailed => 'विफल';

  @override
  String get onboardingStopped => 'रुका हुआ';

  @override
  String get onboardingUsingDetectedCommand =>
      'पता लगाए गए OpenCode कमांड का उपयोग कर रहा है।';

  @override
  String get onboardingContinue => 'जारी रखें';

  @override
  String get onboardingDone => 'हो गया';

  @override
  String get onboardingYoureAllSet => 'आप पूरी तरह तैयार हैं!';

  @override
  String get onboardingServerUpdated => 'सर्वर अपडेट किया गया';

  @override
  String get onboardingServerConnectedReady =>
      'आपका सर्वर कनेक्ट है और उपयोग के लिए तैयार है।';

  @override
  String get onboardingServerSettingsSaved =>
      'आपकी सर्वर सेटिंग्स सहेजी गईं और स्वास्थ्य जांच रिफ्रेश की गई।';

  @override
  String onboardingStartUsing(String appName) {
    return '$appName का उपयोग शुरू करें';
  }

  @override
  String get onboardingCouldNotVerify =>
      'सर्वर कनेक्शन को सत्यापित नहीं किया जा सका।';

  @override
  String get onboardingCloudflareAuthFailed =>
      'Cloudflare Access प्रमाणीकरण विफल रहा।';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'सर्वर स्वास्थ्य जांच विफल रही। यह अभी भी शुरू हो रहा हो सकता है।';

  @override
  String get onboardingConnectionUpdated =>
      'सर्वर कनेक्शन सफलतापूर्वक अपडेट किया गया।';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'सर्वर जोड़ा गया लेकिन स्वास्थ्य जांच विफल रही। यह अभी भी शुरू हो रहा हो सकता है।';

  @override
  String get onboardingConnectionSaved =>
      'सर्वर कनेक्शन सफलतापूर्वक सहेजा गया।';

  @override
  String get onboardingAvailable => 'उपलब्ध';

  @override
  String get onboardingNotAvailable => 'उपलब्ध नहीं';

  @override
  String get onboardingReachable => 'पहुंच योग्य';

  @override
  String get onboardingUnreachable => 'पहुंच से बाहर';

  @override
  String get onboardingWritable => 'लिखने योग्य';

  @override
  String get onboardingNotWritable => 'लिखने योग्य नहीं';

  @override
  String toolPresentationRunningTool(String toolName) {
    return '$toolName चल रहा है';
  }

  @override
  String get toolPresentationTool => 'उपकरण';

  @override
  String get shortcutGroupSession => 'सत्र';

  @override
  String get shortcutGroupGeneral => 'सामान्य';

  @override
  String get shortcutGroupPrompt => 'प्रॉम्प्ट';

  @override
  String get shortcutGroupNavigation => 'नेविगेशन';

  @override
  String get shortcutGroupModelAndAgent => 'मॉडल और एजेंट';

  @override
  String get shortcutGroupApplication => 'एप्लिकेशन';

  @override
  String get shortcutNewConversation => 'नई बातचीत';

  @override
  String get shortcutNewConversationDesc => 'एक नया चैट सत्र बनाएं';

  @override
  String get shortcutRefreshData => 'डेटा रिफ्रेश करें';

  @override
  String get shortcutRefreshDataDesc => 'वर्तमान चैट डेटा रिफ्रेश करें';

  @override
  String get shortcutFocusInput => 'इनपुट पर ध्यान केंद्रित करें';

  @override
  String get shortcutFocusInputDesc => 'ध्यान टेक्स्ट इनपुट पर ले जाएं';

  @override
  String get shortcutToggleVoiceInput => 'आवाज इनपुट टॉगल करें';

  @override
  String get shortcutToggleVoiceInputDesc =>
      'संपादक में आवाज श्रुतलेख शुरू या बंद करें';

  @override
  String get shortcutQuickOpenFiles => 'फाइलें जल्दी खोलें';

  @override
  String get shortcutQuickOpenFilesDesc => 'फाइल त्वरित खोज खोलें';

  @override
  String get shortcutOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get shortcutOpenSettingsDesc => 'सेटिंग्स पेज खोलें';

  @override
  String get shortcutNextRecentModel => 'अगला हालिया मॉडल';

  @override
  String get shortcutNextRecentModelDesc =>
      'हाल ही में उपयोग किए गए मॉडल के बीच चक्र करें';

  @override
  String get shortcutNextVariant => 'अगला संस्करण';

  @override
  String get shortcutNextVariantDesc =>
      'उपलब्ध मॉडल संस्करणों के बीच चक्र करें';

  @override
  String get shortcutFocusCloseDrawer => 'दराज पर ध्यान केंद्रित करें/बंद करें';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'डिफ़ॉल्ट रूप से इनपुट पर ध्यान केंद्रित करें, या खुला होने पर दराज बंद करें';

  @override
  String get shortcutNextAgent => 'अगला एजेंट';

  @override
  String get shortcutNextAgentDesc => 'अगले उपलब्ध एजेंट पर जाएं';

  @override
  String get shortcutPreviousAgent => 'पिछला एजेंट';

  @override
  String get shortcutPreviousAgentDesc => 'पिछले उपलब्ध एजेंट पर जाएं';

  @override
  String get shortcutCloseApp => 'एप्लिकेशन बंद करें';

  @override
  String get shortcutCloseAppDesc =>
      'प्लेटफ़ॉर्म बंद करने के व्यवहार का उपयोग करके ऐप बंद करें';

  @override
  String get shortcutQuitApp => 'एप्लिकेशन से बाहर निकलें';

  @override
  String get shortcutQuitAppDesc => 'ऐप को जबरन बंद करें';

  @override
  String get shortcutStopResponse => 'प्रतिक्रिया रोकें';

  @override
  String get shortcutStopResponseDesc =>
      'सक्रिय प्रतिक्रिया रोकें (प्रतिक्रिया देते समय)';

  @override
  String get errorConnectionFailed => 'कनेक्शन विफल रहा';

  @override
  String get errorConnectionFailedDesc =>
      'सर्वर तक पहुँचने में असमर्थ। कनेक्शन और सर्वर स्थिति की जाँच करें।';

  @override
  String get errorQuotaExceeded => 'कोटा समाप्त हो गया';

  @override
  String get errorQuotaExceededDesc =>
      'कोटा समाप्त हो गया। अपने प्रदाता प्लान या बिलिंग की जाँच करें।';

  @override
  String get errorRateLimitExceeded => 'दर सीमा समाप्त हो गई';

  @override
  String get errorRateLimitExceededDesc =>
      'दर सीमा समाप्त हो गई। एक क्षण प्रतीक्षा करें और पुनः प्रयास करें।';

  @override
  String get errorAuthRequired => 'प्रमाणीकरण आवश्यक है';

  @override
  String get errorAuthRequiredDesc =>
      'प्रमाणीकरण विफल रहा। प्रदाता को फिर से कनेक्ट करें और पुनः प्रयास करें।';

  @override
  String get errorServiceUnavailable => 'सेवा अनुपलब्ध है';

  @override
  String get errorServiceUnavailableDesc =>
      'सेवा अस्थायी रूप से अनुपलब्ध है। सर्वर शुरू हो रहा हो सकता है — कृपया थोड़ी देर में पुनः प्रयास करें।';

  @override
  String get errorProviderUnavailable => 'प्रदाता अनुपलब्ध है';

  @override
  String get errorProviderUnavailableDesc =>
      'प्रदाता अस्थायी रूप से अनुपलब्ध है। थोड़ी देर में पुनः प्रयास करें।';

  @override
  String get errorServerError => 'सर्वर त्रुटि';

  @override
  String get errorServerErrorDesc => 'सर्वर त्रुटि। कृपया पुनः प्रयास करें।';

  @override
  String get attachmentNotAvailableOnPlatform =>
      'इस प्लेटफॉर्म पर अनुलग्नक क्रियाएं उपलब्ध नहीं हैं।';

  @override
  String get attachmentUnableToOpenLink => 'अनुलग्नक लिंक खोलने में असमर्थ।';

  @override
  String get attachmentNoValidLocation =>
      'अनुलग्नक एक मान्य स्थान प्रदान नहीं करता है।';

  @override
  String get attachmentDownloadStarted => 'अनुलग्नक डाउनलोड शुरू हुआ।';

  @override
  String get attachmentCouldNotDownload => 'अनुलग्नक डाउनलोड नहीं किया जा सका।';

  @override
  String get attachmentCouldNotDecode =>
      'अनुलग्नक डेटा को डिकोड नहीं किया जा सका।';

  @override
  String get attachmentPayloadEmpty => 'अनुलग्नक पेलोड खाली है।';

  @override
  String attachmentSavedAndOpened(String path) {
    return 'अनुलग्नक $path में सहेजा गया और खोला गया।';
  }

  @override
  String attachmentSavedTo(String path) {
    return 'अनुलग्नक $path में सहेजा गया।';
  }

  @override
  String get attachmentCouldNotSave =>
      'इस डिवाइस पर अनुलग्नक सहेजा नहीं जा सका।';

  @override
  String get attachmentSaveCanceled => 'सहेजना रद्द कर दिया गया।';

  @override
  String attachmentSavedPath(String path) {
    return 'अनुलग्नक $path में सहेजा गया।';
  }

  @override
  String get attachmentPathEmpty => 'अनुलग्नक पथ खाली है।';

  @override
  String get attachmentLocalNotFound =>
      'इस डिवाइस पर स्थानीय अनुलग्नक नहीं मिला।';

  @override
  String get attachmentUnableToOpenLocal =>
      'स्थानीय अनुलग्नक खोलने में असमर्थ।';

  @override
  String speechDesktopOnly(String service) {
    return '$service केवल डेस्कटॉप पर उपलब्ध है।';
  }

  @override
  String speechRuntimeFailed(String service) {
    return '$service रनटाइम शुरू होने में विफल रहा।';
  }

  @override
  String speechModelFilesIncomplete(String service) {
    return '$service मॉडल फ़ाइलें अपूर्ण हैं।';
  }

  @override
  String get speechMicPermissionDisabled => 'माइक्रोफ़ोन अनुमति अक्षम है।';

  @override
  String speechUnavailableOnPlatform(String service) {
    return 'इस प्लेटफॉर्म पर $service स्पीच उपलब्ध नहीं है।';
  }

  @override
  String get terminalOpenToConnect =>
      'सर्वर प्रोजेक्ट टर्मिनल से जुड़ने के लिए टर्मिनल खोलें।';

  @override
  String get terminalNotAvailableYet =>
      'इस रनटाइम पर एम्बेडेड टर्मिनल अभी उपलब्ध नहीं है।';

  @override
  String get terminalSelectServer =>
      'टर्मिनल खोलने से पहले एक सक्रिय सर्वर चुनें।';

  @override
  String get terminalOpenProjectFirst =>
      'सर्वर टर्मिनल शुरू करने से पहले एक प्रोजेक्ट फ़ोल्डर खोलें।';

  @override
  String terminalConnectingTo(String serverName) {
    return '$serverName टर्मिनल से जुड़ रहा है...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'टर्मिनल कनेक्शन विफल रहा: $error';
  }

  @override
  String get terminalDisconnected => 'टर्मिनल डिस्कनेक्ट हो गया।';

  @override
  String get terminalSessionClosed => 'टर्मिनल सत्र बंद हो गया।';

  @override
  String get notificationConversationUpdates => 'बातचीत अपडेट';

  @override
  String get notificationOpenToClear =>
      'संबंधित सूचनाओं को हटाने के लिए इस बातचीत को खोलें।';

  @override
  String get notificationAgentFinished =>
      'एजेंट ने वर्तमान प्रतिक्रिया समाप्त कर दी है।';

  @override
  String get notificationSession => 'सत्र';

  @override
  String get chatBadgeServerNeedsAttention =>
      'सर्वर कनेक्शन पर ध्यान देने की आवश्यकता है।';

  @override
  String chatBadgeConversationError(String title) {
    return '\"$title\" में एक त्रुटि है।';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '\"$title\" को आपके इनपुट की आवश्यकता है।';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '\"$title\" में एक नई प्रतिक्रिया है।';
  }

  @override
  String get chatBadgeSyncing => 'बातचीत सिंक हो रही है...';

  @override
  String get chatBadgeDataSaverActive => 'सेलुलर डेटा सेवर सक्रिय है।';

  @override
  String get chatCollapseGroup => 'समूह छोटा करें';

  @override
  String get chatExpandGroup => 'समूह विस्तार करें';

  @override
  String get chatForkFailed => 'बातचीत को फोर्क करने में विफल';

  @override
  String get chatForked => 'बातचीत फोर्क की गई';

  @override
  String get chatNoConversationsInProject =>
      'इस प्रोजेक्ट में कोई बातचीत नहीं है।';

  @override
  String get chatOpenProjectToLoad => 'बातचीत लोड करने के लिए प्रोजेक्ट खोलें।';

  @override
  String get chatExportCanceled => 'सत्र निर्यात रद्द कर दिया गया';

  @override
  String get chatLargeContentSkipped =>
      'स्थिरता के लिए बड़ी या खराब सामग्री को छोड़ दिया गया।';

  @override
  String chatTokensLabel(int total) {
    return 'टोकन: $total';
  }

  @override
  String chatCostLabel(String cost) {
    return 'लागत: \$$cost';
  }

  @override
  String get chatFileExplorerNames => 'नाम';

  @override
  String get chatFileExplorerContents => 'सामग्री';

  @override
  String chatCloseProject(String project) {
    return '$project बंद करें';
  }

  @override
  String get sessionExportUser => 'उपयोगकर्ता';

  @override
  String get sessionExportAssistant => 'सहायक';

  @override
  String get sessionExportInput => 'इनपुट:';

  @override
  String get sessionExportOutput => 'आउटपुट:';

  @override
  String get sessionExportError => 'त्रुटि:';

  @override
  String get sessionExportUntitled => 'बिना शीर्षक वाला सत्र';

  @override
  String get modelLabelTinyEnglish => 'Tiny (अंग्रेजी)';

  @override
  String get modelLabelBaseEnglish => 'बेस (अंग्रेजी)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 यूरोपीय भाषाएं)';

  @override
  String get cannedNewQuickReply => 'नई त्वरित प्रतिक्रिया';

  @override
  String get settingsSoundPickerNotAvailable =>
      'सिस्टम ध्वनि चयनकर्ता इस प्लेटफॉर्म पर उपलब्ध नहीं है।';

  @override
  String get appProviderPrimaryServer => 'प्राथमिक सर्वर';

  @override
  String get appProviderLocalManaged => 'स्थानीय OpenCode (प्रबंधित)';

  @override
  String get appProviderLocalServerStopped => 'स्थानीय सर्वर रुका हुआ है।';

  @override
  String get appProviderRunDiagnostics =>
      'स्थानीय OpenCode आवश्यकताओं को सत्यापित करने के लिए निदान चलाएँ।';

  @override
  String get appProviderInvalidServerUrl => 'अमान्य सर्वर URL';

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth इस प्लेटफॉर्म पर समर्थित नहीं है';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale इस प्लेटफॉर्म पर समर्थित नहीं है';

  @override
  String get appProviderProfileNotFound => 'सर्वर प्रोफाइल नहीं मिला';

  @override
  String get appProviderCannotActivateUnhealthy =>
      'एक अस्वस्थ सर्वर को सक्रिय नहीं किया जा सकता';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode का पता चला';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode का पता नहीं चला';

  @override
  String get appProviderDetectingCommand =>
      'OpenCode कमांड का पता लगाया जा रहा है...';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'OpenCode कमांड का पता नहीं चला। यदि आपने इसे अभी स्थापित किया है, तो जांच रिफ्रेश करें या PATH को फिर से लोड करने के लिए $appName को फिर से खोलें।';
  }

  @override
  String get appProviderNotDetectedInstall =>
      'OpenCode कमांड का पता नहीं चला। विज़ार्ड से स्थापना चलाएँ।';

  @override
  String appProviderUsingCommandAt(String path) {
    return '$path पर OpenCode कमांड का उपयोग करना';
  }

  @override
  String get appProviderDesktopOnly =>
      'प्रबंधित स्थानीय सर्वर केवल डेस्कटॉप पर उपलब्ध है।';

  @override
  String get appProviderInstallingRequirements =>
      'OpenCode आवश्यकताएँ स्थापित की जा रही हैं...';

  @override
  String get appProviderInstallationFailed => 'OpenCode स्थापना विफल रही।';

  @override
  String get appProviderInstalledSuccessfully =>
      'OpenCode आवश्यकताएँ सफलतापूर्वक स्थापित की गईं।';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'स्थापना सफल रही। OpenCode कमांड $path पर उपलब्ध है।';
  }

  @override
  String get appProviderInstallSucceeded => 'स्थापना सफल रही।';

  @override
  String get appProviderStartingLocalServer =>
      'स्थानीय सर्वर शुरू हो रहा है...';

  @override
  String get appProviderFailedToStart =>
      'स्थानीय OpenCode सर्वर शुरू करने में विफल।';

  @override
  String appProviderRunningAt(String url) {
    return '$url पर चल रहा है';
  }

  @override
  String get appProviderStoppingLocalServer => 'स्थानीय सर्वर रुक रहा है...';

  @override
  String appProviderExitedWithCode(int code) {
    return 'स्थानीय सर्वर कोड $code के साथ बाहर निकल गया।';
  }

  @override
  String get appProviderInstallBinary => 'बाइनरी स्थापित करें';

  @override
  String get appProviderInstallViaNpm => 'npm के माध्यम से स्थापित करें';

  @override
  String get appProviderInstallViaBun => 'Bun के माध्यम से स्थापित करें';

  @override
  String get appProviderInstallBunOpenCode => 'Bun + OpenCode स्थापित करें';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'इस प्लेटफॉर्म पर Tailscale समर्थित नहीं है।';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'Windows पर Tailscale समर्थित नहीं है।';

  @override
  String get tailscaleWaitingAdminApproval =>
      'यह Tailscale नोड एडमिन की मंजूरी का इंतज़ार कर रहा है।';

  @override
  String get notificationSoundLoadFailed =>
      'Android सिस्टम ध्वनियाँ लोड करने में विफल';

  @override
  String get chatDescriptionNewConversation => 'नई बातचीत';

  @override
  String get chatDescriptionRefreshData => 'चैट डेटा रिफ्रेश करें';

  @override
  String get chatDescriptionFocusInput => 'संदेश इनपुट पर ध्यान केंद्रित करें';

  @override
  String get chatDescriptionVoiceInput => 'आवाज इनपुट शुरू या बंद करें';

  @override
  String get chatDescriptionQuickOpen => 'फाइलें जल्दी खोलें';

  @override
  String get chatDescriptionOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get chatDescriptionCycleModels => 'हाल के मॉडल बदलें';

  @override
  String get chatDescriptionCycleVariant => 'मॉडल संस्करण बदलें';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      'इनपुट पर ध्यान केंद्रित करें (या खुला होने पर दराज बंद करें)';

  @override
  String get chatDescriptionNextAgent => 'अगला एजेंट';

  @override
  String get chatDescriptionPreviousAgent => 'पिछला एजेंट';

  @override
  String get chatDescriptionCloseApp =>
      'प्लेटफ़ॉर्म बंद करने के व्यवहार का उपयोग करके ऐप बंद करें';

  @override
  String get chatDescriptionForceExit => 'ऐप को जबरन बंद करें';

  @override
  String get chatDescriptionStopResponse =>
      'सक्रिय प्रतिक्रिया रोकें (प्रतिक्रिया देते समय)';

  @override
  String get chatDescriptionProjectCommand => 'प्रोजेक्ट कमांड';

  @override
  String get chatDescriptionOpenProjects =>
      'अपने प्रोजेक्ट और बातचीत खोलने के लिए इस बटन का उपयोग करें।';

  @override
  String get chatDescriptionSwitchProject =>
      'प्रोजेक्ट फोल्डर और संदर्भ बदलने के लिए इस बटन का उपयोग करें।';

  @override
  String chatDescriptionChildren(int count) {
    return 'बच्चे: $count';
  }

  @override
  String get chatDescriptionDiffFilesZero => 'डिफ फाइलें: 0';

  @override
  String get appProviderErrorInvalidServerUrl => 'अमान्य सर्वर URL';

  @override
  String get appProviderErrorServerUrlRequired => 'सर्वर URL आवश्यक है';

  @override
  String get appProviderErrorServerAlreadyExists =>
      'इस URL वाला सर्वर पहले से मौजूद है';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth इस प्लेटफॉर्म पर समर्थित नहीं है';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale इस प्लेटफॉर्म पर समर्थित नहीं है';

  @override
  String get appProviderErrorServerProfileNotFound =>
      'सर्वर प्रोफाइल नहीं मिला';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      'एक अस्वस्थ सर्वर को सक्रिय नहीं किया जा सकता';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      'प्रबंधित स्थानीय सर्वर केवल डेस्कटॉप पर उपलब्ध है।';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'स्थानीय सर्वर शुरू हुआ लेकिन स्वास्थ्य जांच पास नहीं हुई।';

  @override
  String get appProviderErrorInstallationFailed => 'OpenCode स्थापना विफल रही।';

  @override
  String get appProviderStatusLocalServerStopped =>
      'स्थानीय सर्वर रुका हुआ है।';

  @override
  String get appProviderStatusStartingLocalServer =>
      'स्थानीय सर्वर शुरू हो रहा है...';

  @override
  String appProviderStatusRunningAt(String url) {
    return '$url पर चल रहा है';
  }

  @override
  String get appProviderStatusStoppingLocalServer =>
      'स्थानीय सर्वर रुक रहा है...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'स्थानीय सर्वर कोड $code के साथ बाहर निकल गया।';
  }

  @override
  String get appProviderSetupDetectingOpenCode =>
      'OpenCode कमांड का पता लगाया जा रहा है...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode का पता चला';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode का पता नहीं चला';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return '$path पर OpenCode कमांड का उपयोग करना';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'OpenCode आवश्यकताएँ स्थापित की जा रही हैं...';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'OpenCode आवश्यकताएँ सफलतापूर्वक स्थापित की गईं।';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'स्थापना सफल रही। OpenCode कमांड $path पर उपलब्ध है।';
  }

  @override
  String get appProviderSetupInstallationSucceeded => 'स्थापना सफल रही।';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'OpenCode कमांड का पता नहीं चला। यदि आपने इसे अभी स्थापित किया है, तो जांच रिफ्रेश करें या PATH को फिर से लोड करने के लिए CodeWalk को फिर से खोलें।';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'OpenCode कमांड का पता नहीं चला। विज़ार्ड से स्थापना चलाएँ।';

  @override
  String get appProviderLabelPrimaryServer => 'प्राथमिक सर्वर';

  @override
  String get appProviderLabelLocalOpenCodeManaged =>
      'स्थानीय OpenCode (प्रबंधित)';

  @override
  String get chatChooseModel => 'मॉडल चुनें';

  @override
  String get chatStartVoiceInput => 'आवाज़ इनपुट शुरू करें';

  @override
  String get chatStopVoiceInput => 'आवाज़ इनपुट बंद करें';

  @override
  String get chatStartingVoiceInput => 'आवाज़ इनपुट शुरू हो रहा है';

  @override
  String get chatComposerPlaceholder => 'अपनी ज़रूरतें लिखें...';

  @override
  String get chatPermissionAutoApproveOn => 'अनुमति स्वतः-अनुमोदन चालू है';

  @override
  String get chatPermissionAutoApproveOff => 'अनुमति स्वतः-अनुमोदन बंद है';

  @override
  String get chatModelLockedSubConversation => 'उप-वार्तालाप में मॉडल लॉक है';

  @override
  String get chatComposerHintShell =>
      'शेल कमांड (बाहर निकलने के लिए Esc दबाएं)';

  @override
  String get utilityTitle => 'उपयोगिता';

  @override
  String get statusOffline => 'ऑफ़लाइन';

  @override
  String get statusOnline => 'ऑनलाइन';

  @override
  String get statusConnected => 'कनेक्टेड';

  @override
  String get statusReconnecting => 'पुनः कनेक्ट हो रहा है';

  @override
  String get statusSyncDelayed => 'सिंक विलंबित';

  @override
  String get statusDelayed => 'विलंबित';

  @override
  String get chatActiveServerUnhealthyLabel => 'सक्रिय सर्वर अस्वस्थ है';

  @override
  String get chatWaitingForNetworkConnection =>
      'नेटवर्क कनेक्शन की प्रतीक्षा...';

  @override
  String get serverHealthHealthy => 'स्वस्थ';

  @override
  String get serverHealthUnhealthy => 'अस्वस्थ';

  @override
  String get serverHealthUnknown => 'अज्ञात';

  @override
  String get sessionUnshare => 'सत्र साझा करना बंद करें';

  @override
  String get sessionShare => 'सत्र साझा करें';

  @override
  String get sessionExportMarkdown => 'Markdown निर्यात करें';

  @override
  String get sessionExportDebugJson => 'डीबग JSON निर्यात करें';

  @override
  String get sessionViewTasks => 'कार्य देखें';

  @override
  String get sessionCompactContext => 'संदर्भ संक्षिप्त करें';

  @override
  String get sessionUnshared => 'वार्तालाप साझा करना बंद किया गया';

  @override
  String get sessionShared => 'वार्तालाप साझा किया गया';

  @override
  String get sessionShareLinkUnavailable =>
      'इस सत्र के लिए लिंक उपलब्ध नहीं है';

  @override
  String get sessionExportMarkdownTitle =>
      'Markdown के रूप में सत्र निर्यात करें';

  @override
  String get sessionExportDebugJsonTitle =>
      'डीबग JSON के रूप में सत्र निर्यात करें';

  @override
  String get sessionExportCanceled => 'सत्र निर्यात रद्द किया गया';

  @override
  String get sessionExportMarkdownSaved => 'Markdown निर्यात सहेजा गया';

  @override
  String get sessionExportDebugJsonSaved => 'डीबग JSON निर्यात सहेजा गया';

  @override
  String get sessionExportMarkdownErrorClipboard =>
      'फ़ाइल सहेजी नहीं जा सकी; Markdown क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get sessionExportDebugJsonErrorClipboard =>
      'फ़ाइल सहेजी नहीं जा सकी; डीबग JSON क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get terminalHide => 'टर्मिनल छिपाएं';

  @override
  String get terminalOpen => 'टर्मिनल खोलें';

  @override
  String get terminalOpenInfo => 'टर्मिनल जानकारी खोलें';

  @override
  String get chatNoSessionSelected =>
      'चैट शुरू करने के लिए वार्तालाप चुनें या बनाएं';

  @override
  String get chatWelcomeMessage => 'नमस्ते! मैं आपका AI सहायक हूँ।';

  @override
  String get chatWelcomeSubmessage => 'आज मैं आपकी कैसे मदद कर सकता हूँ?';

  @override
  String get cannedAppendAtCursor => 'कर्सर पर जोड़ें';

  @override
  String get cannedReplace => 'बदलें';

  @override
  String get chatMessageAttachedFile => 'संलग्न फ़ाइल';

  @override
  String get chatMessageThinking => 'सोच रहा है';

  @override
  String get chatMessageShow => 'दिखाएं';

  @override
  String get chatMessageMore => 'और';

  @override
  String get chatMessageLess => 'कम';

  @override
  String get chatMessageDetails => 'विवरण';

  @override
  String get chatMessageToolInput => 'इनपुट';

  @override
  String get chatMessageToolCommand => 'कमांड';

  @override
  String chatMessageToolRunningCount(int count) {
    return '$count चल रहे हैं';
  }

  @override
  String chatMessageToolQueuedCount(int count) {
    return '$count कतार में हैं';
  }

  @override
  String get chatMessageToolOutputTruncated =>
      'बड़े आउटपुट का पूर्वावलोकन स्थिरता के लिए छोटा किया गया।';

  @override
  String get chatMessageToolCommandTruncated =>
      'कमांड पूर्वावलोकन स्थिरता के लिए छोटा किया गया।';

  @override
  String get chatMessageToolInputTruncated =>
      'इनपुट पूर्वावलोकन स्थिरता के लिए छोटा किया गया।';

  @override
  String get chatMessageToolDiffOmitted =>
      'Diff पूर्वावलोकन हटाया गया: पेलोड मोबाइल पर दिखाने के लिए बहुत बड़ा है।';

  @override
  String get terminalTitle => 'टर्मिनल';

  @override
  String get chatCouldNotRefreshSession =>
      'यह वार्तालाप रीफ़्रेश नहीं किया जा सका';

  @override
  String get chatMainConversationUnavailable =>
      'मुख्य वार्तालाप अभी उपलब्ध नहीं है।';

  @override
  String get chatFailedToRefreshSubConversations =>
      'उप-वार्तालाप रीफ़्रेश नहीं हुए। कृपया पुनः प्रयास करें।';

  @override
  String get chatNoSubConversationFound =>
      'इस कार्य के लिए कोई उप-वार्तालाप नहीं मिला।';

  @override
  String get errorAnErrorOccurred => 'एक त्रुटि हुई';

  @override
  String get serverConnectionAttention =>
      'सर्वर कनेक्शन पर ध्यान देने की आवश्यकता है।';

  @override
  String sessionHasError(String title) {
    return '\"$title\" में त्रुटि है।';
  }

  @override
  String sessionNeedsInput(String title) {
    return '\"$title\" को आपके इनपुट की आवश्यकता है।';
  }

  @override
  String sessionHasNewReply(String title) {
    return '\"$title\" में नया उत्तर है।';
  }

  @override
  String get sessionSyncing => 'वार्तालाप सिंक हो रहे हैं...';

  @override
  String get behaviorCellularDataSaverActive => 'मोबाइल डेटा सेवर सक्रिय है।';

  @override
  String get sessionNoCachedConversations => 'अभी तक कोई कैश्ड वार्तालाप नहीं';

  @override
  String get sessionForkFailed => 'वार्तालाप फोर्क करने में विफल';

  @override
  String get sessionForked => 'वार्तालाप फोर्क किया गया';

  @override
  String get sessionNoConversationsInProject =>
      'इस प्रोजेक्ट में कोई वार्तालाप नहीं।';

  @override
  String get sessionOpenProjectToLoad =>
      'वार्तालाप लोड करने के लिए प्रोजेक्ट खोलें।';

  @override
  String sessionChildrenCount(int count) {
    return 'उप-वार्तालाप: $count';
  }

  @override
  String sessionDiffFilesCount(int count) {
    return 'Diff फ़ाइलें: $count';
  }

  @override
  String get compactionAutomatic => 'स्वचालित';

  @override
  String get compactionManual => 'मैन्युअल';

  @override
  String get chatMessageShowLessCompact => 'कम';

  @override
  String get chatMessageShowLess => 'कम दिखाएं';

  @override
  String get chatMessageShowMoreCompact => 'और';

  @override
  String get chatMessageShowMore => 'और दिखाएं';

  @override
  String get chatChooseAgent => 'एजेंट चुनें';

  @override
  String get chatEffortLockedSubConversation =>
      'उप-वार्तालाप में प्रयास लॉक है';

  @override
  String get chatChooseEffort => 'प्रयास चुनें';

  @override
  String get chatServerSelectedModel => 'सर्वर-चयनित मॉडल';

  @override
  String get chatFailedToRefreshProviders =>
      'प्रदाता और मॉडल रीफ़्रेश करने में विफल';

  @override
  String get cannedAddTitle => 'त्वरित उत्तर जोड़ें';

  @override
  String get cannedEditTitle => 'त्वरित उत्तर संपादित करें';

  @override
  String get cannedTextLabel => 'टेक्स्ट';

  @override
  String get cannedAppendAtCursorSubtitle =>
      'बंद = वर्तमान कंपोज़र टेक्स्ट बदलें';

  @override
  String get cannedSendAutomaticallySubtitle =>
      'यह त्वरित उत्तर डालने के तुरंत बाद भेजें';

  @override
  String get cannedScopeGlobalSubtitle =>
      'केवल प्रोजेक्ट आइटम के लिए अक्षम करें';

  @override
  String get cannedScopeGlobalUnavailableSubtitle =>
      'वर्तमान संदर्भ में केवल-प्रोजेक्ट उपलब्ध नहीं';

  @override
  String get commonFile => 'फ़ाइल';

  @override
  String get serversSearchActiveHint => 'सक्रिय सर्वर खोजें';

  @override
  String get serversNoServersFound => 'कोई सर्वर नहीं मिला';

  @override
  String get serversUnhealthyActivateError =>
      'यह सर्वर स्वस्थ नहीं है। सक्रिय करने से पहले स्वास्थ्य जांचें या सेटिंग्स संपादित करें।';

  @override
  String get serversTailscaleConnected => 'Tailscale कनेक्टेड';

  @override
  String get serversTailscaleConnecting => 'Tailscale कनेक्ट हो रहा है';

  @override
  String get serversTailscaleAuthRequired => 'Tailscale प्रमाणीकरण आवश्यक';

  @override
  String get serversTailscaleAdminApprovalRequired =>
      'Tailscale व्यवस्थापक अनुमोदन आवश्यक';

  @override
  String get serversTailscaleConnectionFailed => 'Tailscale कनेक्शन विफल';

  @override
  String get serversTailscaleUnsupported => 'Tailscale समर्थित नहीं है';

  @override
  String get serversTailscaleDisconnected => 'Tailscale डिस्कनेक्टेड';

  @override
  String get serversTailscaleLoginExplanation =>
      'इस डिवाइस को अपने tailnet में जोड़ने के लिए Tailscale लॉगिन URL खोलें।';

  @override
  String get serversTailscaleTrafficExplanation =>
      'इस सक्रिय प्रोफ़ाइल के लिए OpenCode ट्रैफ़िक Tailscale के माध्यम से रूट किया जाता है।';

  @override
  String get serversTailscaleConnectExplanation =>
      'इस सक्रिय प्रोफ़ाइल का उपयोग करने पर Tailscale कनेक्ट होगा।';

  @override
  String get statusStarting => 'शुरू हो रहा है';

  @override
  String get statusStopping => 'रुक रहा है';

  @override
  String get statusFailed => 'विफल';

  @override
  String get statusStopped => 'रुका हुआ';

  @override
  String get serversDesktopModeExplanation =>
      'डेस्कटॉप मोड CodeWalk से सीधे `opencode serve` लॉन्च और प्रबंधित कर सकता है।';

  @override
  String get serversCannotActivateUnhealthy =>
      'अस्वस्थ सर्वर को सक्रिय नहीं किया जा सकता';

  @override
  String get commonCopiedToClipboard => 'क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get chatUndoNothing => 'इस सत्र में पूर्ववत करने के लिए कुछ नहीं है';

  @override
  String get chatRedoNothing => 'इस सत्र में फिर से करने के लिए कुछ नहीं है';

  @override
  String get chatStatusPatching => 'पैच किया जा रहा है';

  @override
  String get chatStatusPatchingOneFile => '1 फ़ाइल पैच की जा रही है';

  @override
  String chatStatusPatchingMultipleFiles(int count) {
    return '$count फ़ाइलें पैच की जा रही हैं';
  }

  @override
  String get chatStatusThinking => 'सोच रहा है...';

  @override
  String get chatStatusSubsession => 'उप-सत्र';

  @override
  String get chatStatusBusy => 'स्थिति: व्यस्त';

  @override
  String get chatStatusRetry => 'स्थिति: पुन: प्रयास';

  @override
  String chatStatusRetryCount(int count) {
    return 'स्थिति: पुन: प्रयास #$count';
  }

  @override
  String get appShellUpdateInstalledRestartRequired =>
      'अपडेट इंस्टॉल हो गया है। नया संस्करण लागू करने के लिए पुनरारंभ आवश्यक है।';

  @override
  String get appShellUpdateInstalledRestartApp =>
      'अपडेट इंस्टॉल हो गया है। लागू करने के लिए ऐप को पुनरारंभ करें।';

  @override
  String get chatTourProjectsConversations =>
      'अपने प्रोजेक्ट और बातचीत खोलने के लिए इस बटन का उपयोग करें।';

  @override
  String get chatTourSwitchFolders =>
      'प्रोजेक्ट फोल्डर और संदर्भ बदलने के लिए इस बटन का उपयोग करें।';

  @override
  String get chatTourSidebarProjectTools =>
      'बातचीत साइडबार और प्रोजेक्ट टूल दिखाने के लिए इस मेनू का उपयोग करें।';

  @override
  String get chatActionNext => 'अगला';

  @override
  String get chatShortcutsNewConversation => 'नई बातचीत';

  @override
  String get chatShortcutsRefreshChat => 'चैट डेटा रीफ्रेश करें';

  @override
  String get chatShortcutsFocusInput => 'संदेश इनपुट पर ध्यान दें';

  @override
  String get chatShortcutsStartStopVoice => 'आवाज इनपुट शुरू या बंद करें';

  @override
  String get chatShortcutsQuickOpen => 'फ़ाइलें जल्दी खोलें';

  @override
  String get chatShortcutsOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get chatShortcutsCycleModels => 'हाल के मॉडल बदलें';

  @override
  String get chatShortcutsCycleVariant => 'मॉडल संस्करण बदलें';

  @override
  String get chatShortcutsFocusInputCloseDrawer =>
      'इनपुट पर ध्यान दें (या खुला होने पर ड्रॉर बंद करें)';

  @override
  String get chatShortcutsNextAgent => 'अगला एजेंट';

  @override
  String get chatShortcutsPreviousAgent => 'पिछला एजेंट';

  @override
  String get chatShortcutsCloseApp =>
      'प्लेटफ़ॉर्म व्यवहार का उपयोग करके ऐप बंद करें';

  @override
  String get chatShortcutsForceExit => 'ऐप से ज़बरदस्ती बाहर निकलें';

  @override
  String get chatShortcutsStopResponse =>
      'सक्रिय प्रतिक्रिया रोकें (प्रतिक्रिया देते समय)';

  @override
  String get chatTipMentionFiles =>
      'सुझाव: अपने प्रॉम्प्ट में फ़ाइलों का उल्लेख करने के लिए @ का उपयोग करें';

  @override
  String get chatTipRenameConversation =>
      'सुझाव: बातचीत का नाम बदलने के लिए शीर्षक पर टैप करें';

  @override
  String get chatTipShellCommands =>
      'सुझाव: शेल कमांड चलाने के लिए शुरुआत में ! का उपयोग करें';

  @override
  String get chatTipSlashCommands =>
      'सुझाव: स्लैश कमांड तक पहुँचने के लिए / का उपयोग करें';

  @override
  String get chatTipLongPressSend =>
      'सुझाव: नई लाइन डालने के लिए सेंड को देर तक दबाएं';

  @override
  String get chatTipContextKnob =>
      'सुझाव: उपयोग विवरण देखने के लिए संदर्भ नॉब पर टैप करें';

  @override
  String get chatTipBeSpecific =>
      'सुझाव: विशिष्ट बनें — छोटे प्रॉम्प्ट का उत्तर तेज़ी से मिलता है';

  @override
  String get chatTipStepByStep =>
      'सुझाव: जटिल समस्याओं को डीबग करते समय चरण-दर-चरण पूछें';

  @override
  String get chatTipProvideContext =>
      'सुझाव: संदर्भ प्रदान करें — त्रुटि संदेश और लॉग पेस्ट करें';

  @override
  String get chatTipBreakTasks =>
      'सुझाव: बड़े कार्यों को छोटे प्रॉम्प्ट में विभाजित करें';

  @override
  String get chatFailedToLoadDirectories => 'निर्देशिकाएँ लोड करने में विफल';

  @override
  String get logsFilterAll => 'सभी';

  @override
  String get logsNoLogsYet => 'अभी तक कोई लॉग कैप्चर नहीं किया गया है।';

  @override
  String get logsNoMatchingLogs =>
      'कोई भी लॉग वर्तमान फ़िल्टर से मेल नहीं खाता है।';

  @override
  String get settingsDefaultModel => 'डिफ़ॉルト मॉडल';

  @override
  String get settingsSearchDefaultModel => 'डिफ़ॉल्ट मॉडल खोजें';

  @override
  String get settingsDefaultAgent => 'डिफ़ॉल्ट एजेंट';

  @override
  String get settingsSearchDefaultAgent => 'डिफ़ॉल्ट एजेंट खोजें';

  @override
  String get settingsNoAgentsFound => 'कोई एजेंट नहीं मिला';

  @override
  String get settingsConversationUsername => 'बातचीत उपयोगकर्ता नाम';

  @override
  String get settingsUsernameUnsetExplanation =>
      'OpenCode सिस्टम उपयोगकर्ता नाम का उपयोग करता है क्योंकि `username` सेट नहीं है।';

  @override
  String get settingsUsernameResetExplanation =>
      '`/config` पैच अपडेट कुंजियों को नहीं हटा सकते हैं, इसलिए `username` को सिस्टम डिफ़ॉल्ट पर रीसेट करने के लिए अभी भी ऐप के बाहर कॉन्फ़िगरेशन संपादित करने की आवश्यकता है।';

  @override
  String get chatHelpMessage =>
      'उल्लेख के लिए @, शेल के लिए !, कमांड के लिए / का उपयोग करें';

  @override
  String terminalEmbeddedUnavailable(String serverName) {
    return 'एम्बेडेड टर्मिनल अभी इस रनटाइम पर उपलब्ध नहीं है। एक-बार के कमांड के लिए कंपोज़र शेल मोड का उपयोग जारी रखें या $serverName के लिए समर्थित CodeWalk ऐप रनटाइम से टर्मिनल खोलें।';
  }

  @override
  String get chatFailedToLoadFile => 'फ़ाइल लोड करने में विफल';

  @override
  String get chatMentionFileSubtitle => 'फ़ाइल';

  @override
  String get chatMentionSymbolSubtitle => 'प्रतीक';

  @override
  String get chatMentionAgentSubtitle => 'एजेंट';

  @override
  String get chatCommandSourceGeneric => 'कमांड';

  @override
  String get chatCommandSourceProject => 'प्रोजेक्ट';

  @override
  String get chatCommandDescriptionProject => 'प्रोजेक्ट कमांड';

  @override
  String get settingsSmallModel => 'छोटा मॉडल';

  @override
  String get settingsSearchSmallModel => 'छोटा मॉडल खोजें';

  @override
  String get settingsSmallModelUnsetExplanation =>
      'OpenCode स्वचालित फ़ालबैक सक्रिय है क्योंकि `small_model` सेट नहीं है।';

  @override
  String get settingsSmallModelResetExplanation =>
      '`/config` पैच अपडेट कुंजियों को नहीं हटा सकते हैं, इसलिए `small_model` को स्वचालित फ़ालबैक पर रीसेट करने के लिए अभी भी ऐप के बाहर कॉन्फ़िगरेशन संपादित करने की आवश्यकता है।';

  @override
  String get settingsOpenCodeAutoUpdate => 'OpenCode ऑटो-अपडेट';

  @override
  String get settingsSearchAutoUpdateMode => 'ऑटो-अपडेट मोड खोजें';

  @override
  String get settingsOpenCodeSharingDefault => 'OpenCode शेयरिंग डिफ़ॉल्ट';

  @override
  String get settingsSearchSharingMode => 'शेयरिंग मोड खोजें';

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
