import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderBox, ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart' hide Provider;
import 'package:showcaseview/showcaseview.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/config/feature_flags.dart';
import '../../core/di/injection_container.dart' as di;
import '../../core/logging/app_logger.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/path_utils.dart';
import '../../data/datasources/terminal_remote_datasource.dart';
import '../../domain/entities/agent.dart';
import '../../domain/entities/chat_composer_draft.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_realtime.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/experience_settings.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/provider.dart';
import '../../domain/entities/server_profile.dart';
import '../providers/app_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/project_provider.dart';
import '../providers/settings_provider.dart';
import '../services/android_background_alert_logic.dart';
import '../services/android_background_alert_worker.dart';
import '../services/android_foreground_monitor_service.dart';
import '../services/codewalk_terminal_controller.dart';
import '../services/notification_service.dart';
import '../services/permission_auto_approve_runtime.dart';
import '../theme/app_animations.dart';
import '../theme/app_shapes.dart';
import '../theme/opencode_highlight_theme.dart';
import '../theme/opencode_theme_presets.dart';
import '../utils/app_page_route.dart';
import '../utils/chat_abort_message.dart';
import '../utils/chat_server_error_formatter.dart';
import '../utils/file_explorer_logic.dart';
import '../utils/reasoning_status_parser.dart';
import '../utils/session_title_formatter.dart';
import '../utils/shortcut_binding_codec.dart';
import '../utils/tool_presentation.dart';
import '../utils/window_size_class.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/chat_session_list.dart';
import '../widgets/chat_skeleton_shimmer.dart';
import '../widgets/chat_tour_showcase.dart';
import '../widgets/codewalk_terminal_panel.dart';
import '../widgets/message_entrance_animation.dart';
import '../widgets/modal_primary_action_shortcuts.dart';
import '../widgets/permission_request_card.dart';
import '../widgets/question_request_card.dart';
import '../widgets/session_title_inline_editor.dart';
import '../widgets/session_todo_list_widget.dart';
import 'onboarding_wizard_page.dart';
import 'settings_page.dart';

part 'chat_page_types_part.dart';
part 'chat_page/chat_page_lifecycle.dart';
part 'chat_page/chat_page_scroll_coordinator.dart';
part 'chat_page/chat_page_workspace_controller.dart';
part 'chat_page/chat_page_shortcuts.dart';
part 'chat_page/chat_page_status_presenter.dart';
part 'chat_page/chat_page_selector_flow.dart';
part 'chat_page/chat_page_scaffold.dart';
part 'chat_page/chat_page_file_explorer_controller.dart';
part 'chat_page/chat_page_file_viewer.dart';
part 'chat_page/chat_page_timeline_builder.dart';
part 'chat_page/chat_page_composer_status.dart';
part 'chat_page/chat_page_command_query.dart';
part 'chat_page/chat_page_runtime_support.dart';
part 'chat_page/chat_page_chrome.dart';
part 'chat_page/chat_page_file_runtime.dart';
part 'chat_page/chat_page_composer_widgets.dart';
part 'chat_page/chat_page_model_selector_runtime.dart';
part 'chat_page/chat_page_timeline_runtime.dart';
part 'chat_page/chat_page_terminal_runtime.dart';

enum _ContextUsageAction { compactNow }

enum _DisplayToggleAction {
  thinkingBubbles,
  toolCallBubbles,
  taskList,
  recentSessions,
  composerTips,
  replayTour,
}

enum _HistoryToolbarAction { undo, redo }

enum _PostOnboardingTourPhase { idle, intro, composer }

enum _ScrollOwner {
  none,
  userDrag,
  paginationRestore,
  newMessage,
  streaming,
  returnReveal,
  contentShrinkSnap,
}

enum _CachedViewportRestoreTarget { none, bottom, latestResponse }

@visibleForTesting
({String title, String description}) postOnboardingSidebarTourCopy({
  required bool isMobile,
  required bool showConversationPane,
}) {
  if (isMobile) {
    return (
      title: 'Open sidebar',
      description: 'Use this button to open your projects and conversations.',
    );
  }
  if (showConversationPane) {
    return (
      title: 'Open project',
      description: 'Use this button to switch project folders and context.',
    );
  }
  return (
    title: 'Sidebar access',
    description:
        'Use this menu to show the conversations sidebar and project tools.',
  );
}

/// Chat page
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.projectId});
  final String? projectId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with WidgetsBindingObserver, WindowListener {
  static const int _maxHydratedTimelineCacheEntries = 20;
  // File pane shown when expanded and width exceeds this threshold
  static const double _filePaneBreakpoint = 1100;
  static const double _mediumSessionPaneWidth = 260;
  static const double _nearBottomThreshold = 200;
  static const double _olderMessagesTopLoadThreshold = 72;
  static const double _olderMessagesTopLoadArmThreshold = 220;
  static const double _jumpToFirstFabThreshold = 360;
  static const double _scrollToBottomEpsilon = 1;
  static const int _maxScrollToBottomPasses = 6;
  static const Duration _scrollToBottomFirstPassDuration = Duration(
    milliseconds: 260,
  );
  static const Duration _scrollToBottomNextPassDuration = Duration(
    milliseconds: 140,
  );
  static const String _rootTreeCacheKey = '__root__';
  static const Duration _serverAlertGracePeriod = Duration(seconds: 10);
  static const Duration _unhealthySnackbarDebounce = Duration(seconds: 5);
  static const Duration _foregroundWarningConfirmationDelay = Duration(
    seconds: 2,
  );
  static const Duration _initialDataRecoveryDebounce = Duration(
    milliseconds: 600,
  );
  static const Duration _composerStatusShowDelay = Duration(seconds: 2);
  static const Duration _composerStatusHideDelay = Duration(seconds: 1);
  static const Duration _composerStopHintDuration = Duration(seconds: 1);
  static const Duration _mobileBackgroundRealtimeHoldDuration = Duration(
    minutes: 3,
  );
  static const Duration _doubleEscapeStopThreshold = Duration(
    milliseconds: 500,
  );
  static const int _notificationTapMaxAttempts = 12;
  static const int _notificationTapReloadAttempts = 3;
  static const Duration _notificationTapRetryInterval = Duration(
    milliseconds: 180,
  );
  static const Duration _postOnboardingTourRetryDelay = Duration(
    milliseconds: 150,
  );
  static const Duration _postOnboardingTourStartDelay = Duration(
    milliseconds: 350,
  );
  static const int _postOnboardingTourMaxAttempts = 20;
  static const double _composerStatusReservedHeight = 26;
  static const Duration _finalAssistantRevealDuration = Duration(
    milliseconds: 260,
  );
  static const double _finalAssistantRevealAlignment = 0.0;
  static const int _maxFinalAssistantRevealAttempts = 8;
  static const double _returnLatestRevealAlignment = 0.0;
  static const int _maxReturnLatestRevealAttempts = 8;
  static const String _traceFinalPrefix = 'CW_TRACE_FINAL';

  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode(debugLabel: 'chat_input');
  final ChatInputController _chatInputController = ChatInputController();
  final CodewalkTerminalController _terminalController =
      CodewalkTerminalController(
        remoteDataSource: di.sl.isRegistered<TerminalRemoteDataSource>()
            ? di.sl<TerminalRemoteDataSource>()
            : null,
      );
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _agentSelectorChipKey = GlobalKey(
    debugLabel: 'agent_selector_chip',
  );
  final GlobalKey _drawerAccessTourKey = GlobalKey(
    debugLabel: 'tour_drawer_access',
  );
  final GlobalKey _drawerAccessTourTargetKey = GlobalKey(
    debugLabel: 'tour_drawer_access_target',
  );
  final GlobalKey _projectContextTourKey = GlobalKey(
    debugLabel: 'tour_project_context',
  );
  final GlobalKey _projectContextTourTargetKey = GlobalKey(
    debugLabel: 'tour_project_context_target',
  );
  final GlobalKey _desktopSidebarMenuTourKey = GlobalKey(
    debugLabel: 'tour_desktop_sidebar_menu',
  );
  final GlobalKey _desktopSidebarMenuTourTargetKey = GlobalKey(
    debugLabel: 'tour_desktop_sidebar_menu_target',
  );
  final GlobalKey _newChatTourKey = GlobalKey(debugLabel: 'tour_new_chat');
  final GlobalKey _newChatTourTargetKey = GlobalKey(
    debugLabel: 'tour_new_chat_target',
  );
  final GlobalKey _composerTourKey = GlobalKey(debugLabel: 'tour_composer');
  final GlobalKey _composerTourTargetKey = GlobalKey(
    debugLabel: 'tour_composer_target',
  );
  final GlobalKey _sendButtonTourKey = GlobalKey(debugLabel: 'tour_send');
  final GlobalKey _sendButtonTourTargetKey = GlobalKey(
    debugLabel: 'tour_send_target',
  );
  final GlobalKey<ShowCaseWidgetState> _showcaseWidgetKey =
      GlobalKey<ShowCaseWidgetState>();
  final TextEditingController _sessionSearchController =
      TextEditingController();
  NotificationService? _notificationService;
  StreamSubscription<NotificationTapPayload>? _notificationTapSubscription;
  NotificationTapPayload? _pendingNotificationTap;
  Future<void>? _notificationTapTask;
  ChatProvider? _chatProvider;
  AppProvider? _appProvider;
  ProjectProvider? _projectProvider;
  SettingsProvider? _settingsProvider;
  bool _autoApprovePermissionDrainScheduled = false;
  bool _autoApprovePermissionDrainRunning = false;
  bool _autoApprovePermissionDrainQueued = false;
  final Set<String> _autoApprovePermissionCooldownIds = <String>{};
  String? _backgroundPermissionAutoApproveContextSignature;
  String? _lastServerId;
  bool? _lastServerConnectionState;
  ServerHealthStatus _lastActiveServerHealthStatus = ServerHealthStatus.unknown;
  String? _trackedSessionId;
  String? _pendingInitialScrollSessionId;
  bool _autoFollowToLatest = true;
  bool _showScrollToLatestFab = false;
  bool _hasUnreadMessagesBelow = false;
  bool _showScrollToFirstFab = false;
  bool _isProjectScopeTransitioning = false;
  Future<void>? _projectScopeTransitionTask;
  bool _isProjectSelectorActionInFlight = false;
  // Per-session collapse state cache (up to 20 sessions, LRU-evicted).
  // Stores the last expanded history group ID for each session ID.
  final Map<String, String?> _sessionCollapseHistoryCache = {};
  final Map<String, bool> _projectGroupExpandedById = <String, bool>{};
  bool _isAppInForeground = true;
  bool _wasChatRouteCurrent = false;
  bool _isProgrammaticScrollInFlight = false;
  bool _isReturnRevealInFlight = false;
  bool _olderMessagesLoadTriggerArmed = true;
  bool _olderMessagesAnchorRestoreInFlight = false;
  _ScrollOwner _currentScrollOwner = _ScrollOwner.none;
  _CachedViewportRestoreTarget _pendingCachedViewportRestoreTarget =
      _CachedViewportRestoreTarget.none;
  int _scrollToBottomRequestToken = 0;
  bool _manualScrollFollowPaused = false;
  int _responseSettleFramesRemaining = 0;
  bool _wasCurrentSessionActivelyResponding = false;
  bool _deferAssistantWorkCollapse = false;
  bool _suppressPostCompletionAutoSnap = false;
  bool _shouldRevealFinalAssistantOnCompletion = false;
  String? _pendingFinalAssistantRevealMessageId;
  String? _settledLatestAssistantWorkGroupId;

  void _setScrollOwner(_ScrollOwner owner) {
    final previousOwner = _currentScrollOwner;
    _currentScrollOwner = owner;
    _isProgrammaticScrollInFlight =
        owner != _ScrollOwner.none && owner != _ScrollOwner.userDrag;
    _isReturnRevealInFlight = owner == _ScrollOwner.returnReveal;
    _olderMessagesAnchorRestoreInFlight =
        owner == _ScrollOwner.paginationRestore;
    if (previousOwner != owner) {
      AppLogger.debug(
        'Chat viewport owner: ${previousOwner.name} -> ${owner.name} '
        'session=${_chatProvider?.currentSession?.id ?? "-"} '
        'autoFollow=$_autoFollowToLatest '
        'requestToken=$_scrollToBottomRequestToken',
      );
    }
  }

  void _requestPassiveScrollToBottom({required String reason}) {
    if (!mounted) {
      return;
    }
    if (_currentScrollOwner == _ScrollOwner.userDrag) {
      _traceFinalUi(
        'passive-scroll-suppressed-user-drag',
        details: 'reason=$reason',
      );
      _markUnreadMessagesBelow();
      return;
    }
    if (_manualScrollFollowPaused) {
      _traceFinalUi(
        'passive-scroll-suppressed-manual-pause',
        details: 'reason=$reason',
      );
      _markUnreadMessagesBelow();
      return;
    }
    if (_currentScrollOwner != _ScrollOwner.none ||
        _isReturnRevealInFlight ||
        _olderMessagesAnchorRestoreInFlight) {
      _traceFinalUi(
        'passive-scroll-suppressed-owner-active',
        details: 'reason=$reason owner=${_currentScrollOwner.name}',
      );
      return;
    }
    if (!_autoFollowToLatest) {
      _traceFinalUi(
        'passive-scroll-suppressed-auto-follow-disabled',
        details: 'reason=$reason',
      );
      _markUnreadMessagesBelow();
      return;
    }
    if (_chatProvider != null &&
        _pendingInitialScrollSessionId == _chatProvider!.currentSession?.id &&
        _pendingCachedViewportRestoreTarget ==
            _CachedViewportRestoreTarget.latestResponse) {
      _traceFinalUi(
        'passive-scroll-promote-cached-latest-restore',
        details: 'reason=$reason',
      );
      _consumeQueuedCachedViewportRestore(
        _chatProvider!,
        reason: 'passive:$reason',
      );
      return;
    }
    _traceFinalUi('passive-scroll-request', details: 'reason=$reason');
    _scrollToBottom(force: false);
  }

  void _traceFinalUi(String event, {String? details}) {
    final provider = _chatProvider;
    final sessionId = provider?.currentSession?.id ?? '-';
    final messages = provider?.messages ?? const <ChatMessage>[];
    final lastMessageId = messages.isEmpty ? '-' : messages.last.id;
    final suffix = details == null || details.trim().isEmpty
        ? ''
        : ' details=${details.trim()}';
    AppLogger.info(
      '$_traceFinalPrefix ui event=$event session=$sessionId responding=${provider?.isCurrentSessionActivelyResponding ?? false} state=${provider?.state.name ?? "-"} messages=${messages.length} last=$lastMessageId pendingFinal=${_pendingFinalAssistantRevealMessageId ?? "-"} settledFinal=${_finalAssistantRevealSettledMessageId ?? "-"} settledWorkGroup=${_settledLatestAssistantWorkGroupId ?? "-"} deferCollapse=$_deferAssistantWorkCollapse autoFollow=$_autoFollowToLatest$suffix',
    );
  }

  String? _finalAssistantRevealSettledMessageId;
  bool _finalAssistantRevealScheduled = false;
  int _pendingFinalAssistantRevealAttempts = 0;
  final Map<String, GlobalKey> _messageRevealAnchorKeysByMessageId =
      <String, GlobalKey>{};
  String? _lastForegroundPolicySettingsSignature;
  String? _terminalSessionSignature;
  ChatComposerDraft? _composerPrefilledDraft;
  int _composerPrefilledDraftVersion = 0;
  final Map<String, _FileExplorerContextState> _fileContextStates =
      <String, _FileExplorerContextState>{};
  final Map<String, String> _fileDiffSignaturesByContext = <String, String>{};
  final List<FileInputPart> _fileContextItems = <FileInputPart>[];
  DateTime? _serverAlertIssueStartedAt;
  Timer? _serverAlertRevealTimer;
  DateTime? _foregroundWarningGraceEndsAt;
  Timer? _foregroundWarningUiRefreshTimer;
  Timer? _foregroundWarningSnackbarTimer;
  Timer? _unhealthySnackbarDebounceTimer;
  Timer? _initialDataRecoveryTimer;
  Timer? _composerDraftPersistTimer;
  Timer? _composerStatusShowTimer;
  Timer? _composerStatusHideTimer;
  Timer? _composerStopHintTimer;
  Timer? _backgroundRealtimeHoldTimer;
  Timer? _tipRotationTimer;
  DateTime? _lastResumeRefreshAt;
  DateTime? _lastReturnToChatAt;
  String? _lastReturnToChatSignature;
  String? _lastConsumedCachedViewportRestoreSignature;
  DateTime? _lastConsumedCachedViewportRestoreAt;
  bool _resumeRefreshViewportRestorePending = false;
  bool _needsInitialDataRecovery = false;
  bool _initialDataRecoveryInFlight = false;
  int _initialDataRecoveryAttemptCount = 0;
  int _currentTipIndex = 0;
  DateTime? _lastGlobalEscapeAt;
  _ComposerStatusPresentation? _visibleComposerStatus;
  _ComposerStatusPresentation? _priorityComposerStatus;
  _ComposerStatusPresentation? _pendingComposerStatus;
  _ComposerStatusPresentation? _queuedComposerStatusTarget;
  _ComposerStatusPresentation? _lastComposerStatusTarget;
  bool _composerStatusTargetInitialized = false;
  String? _expandedCollapsedHistoryGroupId;
  String? _expandedAssistantWorkGroupId;
  String? _frozenCompactionBoundaryId;
  bool _wasCompactingContext = false;
  String? _nextFrozenCompactionBoundaryId;
  bool _nextWasCompactingContext = false;
  bool _compactionStateSyncScheduled = false;
  bool _tourStartScheduled = false;
  bool _tourAdvancingToComposerPhase = false;
  bool _tourExplicitSkipRequested = false;
  _PostOnboardingTourPhase _tourPhase = _PostOnboardingTourPhase.idle;
  int _postOnboardingTourRunToken = 0;
  bool _queuedPendingPostOnboardingTourAutoStart = false;
  bool _lastPendingPostOnboardingChatTour = false;

  // Per-session hydrated timeline cache so reopening a cached session can
  // reuse its grouped presentation instead of rebuilding the whole timeline.
  final Map<String, _SessionTimelineEntriesCacheEntry>
  _sessionTimelineEntriesCache = <String, _SessionTimelineEntriesCacheEntry>{};

  // Track timeline growth for message entrance animations (Phase 2.2).
  // _animationBaselineSessionId records which session the baseline was set for,
  // so switching sessions resets the baseline and avoids animating history.
  int _previousTimelineLength = 0;
  String? _animationBaselineSessionId;

  // Cache for _resolveSessionContextUsage (O(N) double-scan of messages).
  int _cachedContextUsageMsgCount = -1;
  String? _cachedContextUsageLastMsgId;
  String? _cachedContextUsageProviderId;
  String? _cachedContextUsageModelId;
  _SessionContextUsageSnapshot? _cachedContextUsage;

  // Cache for _resolveLatestReasoningPartKey (O(N*M) backward scan).
  int _cachedReasoningKeyMsgCount = -1;
  String? _cachedReasoningKeyLastMsgId;
  String? _cachedReasoningKeyResult;
  bool _cachedReasoningKeyComputed = false;

  // Cache for _resolveAssistantProgressStage (O(N) scan for streaming parts).
  int _cachedProgressStageMsgCount = -1;
  String? _cachedProgressStageLastMsgId;
  bool _cachedProgressStageResponding = false;
  _AssistantProgressStage? _cachedProgressStageResult;
  bool _cachedProgressStageComputed = false;

  // Cache for _collectSentMessageHistory (O(N) filter of user messages).
  int _cachedSentHistoryMsgCount = -1;
  String? _cachedSentHistoryLastMsgId;
  List<String>? _cachedSentHistory;

  // Cache for locked sub-conversation model/variant labels.
  String? _cachedLockedSubConversationSessionId;
  int _cachedLockedSubConversationMessagesVersion = -1;
  int _cachedLockedSubConversationProviderCatalogSignature = -1;
  _LockedSubConversationSelection? _cachedLockedSubConversationSelection;

  // Cached highlight theme to avoid re-creating the Map<String, TextStyle>
  // spread on every _resolveHighlightTheme() call, which forces the
  // HighlightView to re-parse when it detects a "changed" theme reference.
  Map<String, TextStyle>? _cachedHighlightTheme;
  Brightness? _cachedHighlightBrightness;
  String? _cachedHighlightThemeKey;

  @override
  void initState() {
    super.initState();
    _currentTipIndex = Random().nextInt(
      _ComposerStatusPresentation._receivingTips.length,
    );
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_handleGlobalShortcutKeyEvent);
    _scrollController.addListener(_handleScrollChanged);
    if (_isDesktopRuntime) {
      windowManager.addListener(this);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Invalidate highlight theme cache on dependency change (theme switch).
    _cachedHighlightTheme = null;
    // Safely get ChatProvider reference here
    final nextChatProvider = context.read<ChatProvider>();
    if (!identical(_chatProvider, nextChatProvider)) {
      _chatProvider?.removeListener(_handleChatProviderChanged);
      _chatProvider = nextChatProvider;
      _chatProvider?.addListener(_handleChatProviderChanged);
      _autoApprovePermissionCooldownIds.clear();
    }
    _chatProvider?.setAppInForeground(_isAppInForeground);
    final nextAppProvider = context.read<AppProvider>();
    if (!identical(_appProvider, nextAppProvider)) {
      _appProvider?.removeListener(_handleAppProviderChange);
      _appProvider = nextAppProvider;
      _lastServerId = nextAppProvider.activeServerId;
      _lastServerConnectionState = nextAppProvider.isConnected;
      final initialActiveServer = nextAppProvider.activeServer;
      _lastActiveServerHealthStatus = initialActiveServer == null
          ? ServerHealthStatus.unknown
          : nextAppProvider.healthFor(initialActiveServer.id);
      _appProvider?.addListener(_handleAppProviderChange);
    }
    final nextProjectProvider = context.read<ProjectProvider>();
    if (!identical(_projectProvider, nextProjectProvider)) {
      _projectProvider?.removeListener(_handleProjectProviderChange);
      _projectProvider = nextProjectProvider;
      _projectProvider?.addListener(_handleProjectProviderChange);
    }
    if (di.sl.isRegistered<NotificationService>()) {
      final nextNotificationService = di.sl<NotificationService>();
      if (!identical(_notificationService, nextNotificationService)) {
        _notificationTapSubscription?.cancel();
        _notificationService = nextNotificationService;
        _notificationTapSubscription = nextNotificationService
            .onNotificationTapped
            .listen(_scheduleNotificationTap);
        final pendingPayload = nextNotificationService.consumePendingTap();
        if (pendingPayload != null) {
          _scheduleNotificationTap(pendingPayload);
        }
        unawaited(nextNotificationService.initialize());
      }
    }
    final nextSettingsProvider = context.read<SettingsProvider>();
    if (!identical(_settingsProvider, nextSettingsProvider)) {
      _settingsProvider?.removeListener(_handleSettingsChanged);
      _settingsProvider = nextSettingsProvider;
      _settingsProvider?.addListener(_handleSettingsChanged);
      _lastPendingPostOnboardingChatTour =
          nextSettingsProvider.pendingPostOnboardingChatTour;
      _queuedPendingPostOnboardingTourAutoStart =
          nextSettingsProvider.pendingPostOnboardingChatTour;
      _applyForegroundPolicy(reason: 'settings-provider-attached');
      _lastForegroundPolicySettingsSignature =
          _foregroundPolicySettingsSignature(nextSettingsProvider.settings);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _flushPendingPostOnboardingTourAutoStart();
      });
    }
  }

  @override
  void dispose() {
    // Clean up scroll callback using saved reference
    _chatProvider?.setScrollToBottomCallback(null);
    _chatProvider?.setChatRouteActive(false);
    unawaited(_chatProvider?.setForegroundActive(false));
    _chatProvider?.removeListener(_handleChatProviderChanged);
    _scrollToBottomRequestToken += 1;
    _appProvider?.removeListener(_handleAppProviderChange);
    _projectProvider?.removeListener(_handleProjectProviderChange);
    _notificationTapSubscription?.cancel();
    _settingsProvider?.removeListener(_handleSettingsChanged);
    _serverAlertRevealTimer?.cancel();
    _foregroundWarningUiRefreshTimer?.cancel();
    _foregroundWarningSnackbarTimer?.cancel();
    _unhealthySnackbarDebounceTimer?.cancel();
    _initialDataRecoveryTimer?.cancel();
    _composerDraftPersistTimer?.cancel();
    _composerStatusShowTimer?.cancel();
    _composerStatusHideTimer?.cancel();
    _composerStopHintTimer?.cancel();
    _backgroundRealtimeHoldTimer?.cancel();
    _tipRotationTimer?.cancel();
    _scrollController.removeListener(_handleScrollChanged);
    HardwareKeyboard.instance.removeHandler(_handleGlobalShortcutKeyEvent);
    if (_isDesktopRuntime) {
      windowManager.removeListener(this);
    }
    WidgetsBinding.instance.removeObserver(this);

    _scrollController.dispose();
    _inputFocusNode.dispose();
    _sessionSearchController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    final provider = _chatProvider;
    if (provider != null) {
      provider.setAppInForeground(_isAppInForeground);
      _applyForegroundPolicy(reason: 'app-lifecycle-${state.name}');
      if (_isAppInForeground) {
        _startForegroundWarningGrace();
        if (_isChatScreenActive()) {
          _lastResumeRefreshAt = DateTime.now();
          _resumeRefreshViewportRestorePending = true;
          unawaited(
            provider
                .refreshActiveSessionView(reason: 'app-lifecycle-resumed')
                .whenComplete(() {
                  _resumeRefreshViewportRestorePending = false;
                  if (!mounted ||
                      !_isAppInForeground ||
                      !_isChatScreenActive()) {
                    return;
                  }
                  _handleReturnToChat(
                    provider,
                    reason: 'app-resumed-refresh-complete',
                  );
                }),
          );
        }
        _handleReturnToChat(provider, reason: 'app-resumed');
      }
    }
  }

  // Desktop window visibility: suppress rebuilds when minimized,
  // resume when restored/focused. Blur (losing focus while visible) is a no-op
  // because the window content is still on-screen.
  @override
  void onWindowMinimize() {
    _isAppInForeground = false;
    _applyForegroundPolicy(reason: 'window-minimize');
  }

  @override
  void onWindowRestore() {
    _isAppInForeground = true;
    _applyForegroundPolicy(reason: 'window-restore');
    _startForegroundWarningGrace();
    final provider = _chatProvider;
    if (provider != null) {
      _handleReturnToChat(provider, reason: 'window-restore');
    }
  }

  @override
  void onWindowFocus() {
    if (!_isAppInForeground) {
      _isAppInForeground = true;
      _applyForegroundPolicy(reason: 'window-focus');
      _startForegroundWarningGrace();
      final provider = _chatProvider;
      if (provider != null) {
        _handleReturnToChat(provider, reason: 'window-focus');
      }
    }
  }

  bool get _isDesktopRuntime {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
  }

  bool get _isMobileRuntime {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  void _setState(VoidCallback fn) {
    setState(fn);
  }

  void _loadInitialData() {
    final chatProvider = context.read<ChatProvider>();

    // Set scroll to bottom callback
    chatProvider.setScrollToBottomCallback(_requestPassiveScrollToBottom);
    _applyForegroundPolicy(reason: 'chat-load-initial-data');

    // Technical comment translated to English.
    _initializeChatProvider(chatProvider);
  }

  Future<void> _initializeChatProvider(ChatProvider chatProvider) async {
    final appProvider = context.read<AppProvider>();
    final projectProvider = context.read<ProjectProvider>();
    try {
      await appProvider.initialize();
      await projectProvider.initializeProject();
      if (appProvider.activeServer == null) {
        _clearInitialDataRecoveryState();
        chatProvider.clearError();
        return;
      }
      await appProvider.checkConnection(
        directory: projectProvider.currentDirectory,
      );
      chatProvider.warmupProvidersRefresh(reason: 'chat-startup');

      // Technical comment translated to English.
      await chatProvider.loadSessions();
      if (!appProvider.isConnected) {
        // Offline startup can still restore cached data, but it needs a full
        // recovery pass once the backend is reachable again.
        _markInitialDataRecoveryNeeded();
        return;
      }
      _clearInitialDataRecoveryState();
    } catch (e) {
      if (appProvider.activeServer != null && !appProvider.isConnected) {
        _markInitialDataRecoveryNeeded();
      } else {
        _clearInitialDataRecoveryState();
      }
      // Technical comment translated to English.
      chatProvider.clearError();
      AppLogger.error('Chat initialization failed', error: e);
    }
  }

  void _handleAppProviderChange() {
    final appProvider = _appProvider;
    if (appProvider == null) {
      return;
    }
    final currentServerId = appProvider.activeServerId;
    final currentConnected = appProvider.isConnected;
    final activeServer = appProvider.activeServer;
    final currentHealth = activeServer == null
        ? ServerHealthStatus.unknown
        : appProvider.healthFor(activeServer.id);
    final serverChanged = currentServerId != _lastServerId;

    if (serverChanged) {
      _lastServerId = currentServerId;
      _lastServerConnectionState = currentConnected;
      _lastActiveServerHealthStatus = currentHealth;
      _terminalSessionSignature = null;
      if (_settingsProvider?.terminalPanelVisible == true) {
        unawaited(_startTerminalForCurrentProject(force: true));
      } else {
        unawaited(_terminalController.stop());
      }
      if (currentServerId != null) {
        unawaited(_handleServerScopeChange());
      }
      return;
    }

    final previousHealth = _lastActiveServerHealthStatus;
    _lastActiveServerHealthStatus = currentHealth;
    if (previousHealth == ServerHealthStatus.healthy &&
        currentHealth == ServerHealthStatus.unhealthy) {
      _showServerUnhealthyNoticeWithConfirmation();
    } else if (previousHealth == ServerHealthStatus.unhealthy &&
        currentHealth != ServerHealthStatus.unhealthy) {
      _cancelPendingServerUnhealthyNotice();
    }

    final wasConnected = _lastServerConnectionState;
    _lastServerConnectionState = currentConnected;
    if (_needsInitialDataRecovery &&
        !currentConnected &&
        currentHealth != ServerHealthStatus.healthy) {
      _cancelPendingInitialDataRecovery();
    }
    final shouldScheduleInitialDataRecovery =
        _needsInitialDataRecovery &&
        ((wasConnected == false && currentConnected) ||
            (previousHealth != ServerHealthStatus.healthy &&
                currentHealth == ServerHealthStatus.healthy));
    if (shouldScheduleInitialDataRecovery) {
      _scheduleInitialDataRecovery(
        delay: _initialDataRecoveryDebounce,
        reason: currentConnected
            ? 'app-provider-connected'
            : 'server-health-healthy',
      );
      return;
    }
    if (wasConnected == false && currentConnected) {
      unawaited(_handleServerReconnected());
    }
  }

  void _handleProjectProviderChange() {
    if (_settingsProvider?.terminalPanelVisible != true) {
      return;
    }
    unawaited(_startTerminalForCurrentProject());
  }

  void _markInitialDataRecoveryNeeded() {
    _needsInitialDataRecovery = true;
    _initialDataRecoveryAttemptCount = 0;
  }

  void _clearInitialDataRecoveryState() {
    _needsInitialDataRecovery = false;
    _initialDataRecoveryAttemptCount = 0;
    _cancelPendingInitialDataRecovery();
  }

  void _cancelPendingInitialDataRecovery() {
    _initialDataRecoveryTimer?.cancel();
    _initialDataRecoveryTimer = null;
  }

  Duration _initialDataRecoveryRetryDelay(int attemptCount) {
    if (attemptCount <= 1) {
      return const Duration(seconds: 1);
    }
    if (attemptCount == 2) {
      return const Duration(seconds: 2);
    }
    return const Duration(seconds: 4);
  }

  void _scheduleInitialDataRecovery({
    required Duration delay,
    required String reason,
  }) {
    if (!_needsInitialDataRecovery || !mounted) {
      return;
    }
    _initialDataRecoveryTimer?.cancel();
    AppLogger.info(
      'initial_data_recovery_scheduled reason=$reason delayMs=${delay.inMilliseconds} attempts=$_initialDataRecoveryAttemptCount',
    );
    _initialDataRecoveryTimer = Timer(delay, () {
      _initialDataRecoveryTimer = null;
      unawaited(_runInitialDataRecovery(reason: reason));
    });
  }

  void _retryInitialDataRecovery({required String reason}) {
    if (!_needsInitialDataRecovery || !mounted) {
      return;
    }
    _initialDataRecoveryAttemptCount += 1;
    _scheduleInitialDataRecovery(
      delay: _initialDataRecoveryRetryDelay(_initialDataRecoveryAttemptCount),
      reason: reason,
    );
  }

  Future<void> _runInitialDataRecovery({required String reason}) async {
    if (!mounted ||
        !_needsInitialDataRecovery ||
        _initialDataRecoveryInFlight) {
      return;
    }
    if (!_isChatScreenActive()) {
      return;
    }

    final appProvider = _appProvider ?? context.read<AppProvider>();
    final projectProvider = context.read<ProjectProvider>();
    final chatProvider = _chatProvider ?? context.read<ChatProvider>();
    final expectedServerId = appProvider.activeServerId;
    if (expectedServerId == null) {
      return;
    }

    _initialDataRecoveryInFlight = true;
    AppLogger.info(
      'initial_data_recovery_start reason=$reason attempts=$_initialDataRecoveryAttemptCount server=$expectedServerId',
    );

    try {
      await appProvider.checkConnection(
        directory: projectProvider.currentDirectory,
      );
      if (!mounted || appProvider.activeServerId != expectedServerId) {
        return;
      }
      if (!appProvider.isConnected) {
        AppLogger.info(
          'initial_data_recovery_waiting_for_backend reason=$reason server=$expectedServerId',
        );
        _retryInitialDataRecovery(reason: 'connection-not-ready');
        return;
      }

      final previousContextKey = projectProvider.contextKey;
      await projectProvider.initializeProject(forceReload: true);
      if (!mounted || appProvider.activeServerId != expectedServerId) {
        return;
      }
      if (projectProvider.status == ProjectStatus.error ||
          projectProvider.currentProject == null) {
        AppLogger.warn(
          'Initial data recovery could not restore project context yet',
        );
        _retryInitialDataRecovery(reason: 'project-context-not-ready');
        return;
      }

      final contextChanged = projectProvider.contextKey != previousContextKey;
      if (contextChanged) {
        await chatProvider.onProjectScopeChanged();
      } else {
        await chatProvider.loadSessions(
          preserveVisibleState: chatProvider.sessions.isNotEmpty,
        );
      }
      if (!mounted || appProvider.activeServerId != expectedServerId) {
        return;
      }
      if (chatProvider.state == ChatState.error) {
        AppLogger.warn('Initial data recovery session reload failed; retrying');
        _retryInitialDataRecovery(reason: 'session-reload-failed');
        return;
      }

      chatProvider.warmupProvidersRefresh(reason: 'offline-start-recovery');
      if (chatProvider.currentSession != null) {
        await chatProvider.refreshActiveSessionView(
          reason: 'offline-start-recovery',
        );
      }

      _clearInitialDataRecoveryState();
      _scheduleAutoApprovePermissionDrain(reason: 'offline-start-recovery');
      AppLogger.info(
        'initial_data_recovery_complete server=$expectedServerId context=${projectProvider.contextKey}',
      );
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Initial data recovery failed unexpectedly',
        error: e,
        stackTrace: stackTrace,
      );
      _retryInitialDataRecovery(reason: 'unexpected-recovery-error');
    } finally {
      _initialDataRecoveryInFlight = false;
    }
  }

  SnackBar _buildChatPageSnackBar({
    required Widget content,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    final dismissOnTap = action == null;
    return SnackBar(
      behavior: behavior,
      duration: duration,
      action: action,
      content: dismissOnTap
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar(),
              child: content,
            )
          : content,
    );
  }

  void _showChatPageSnackBar({
    required Widget content,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    bool hideCurrent = true,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    if (hideCurrent) {
      messenger.hideCurrentSnackBar();
    }
    messenger.showSnackBar(
      _buildChatPageSnackBar(
        content: content,
        action: action,
        duration: duration,
        behavior: behavior,
      ),
    );
  }

  void _showChatPageMessageSnackBar(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    bool hideCurrent = true,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    _showChatPageSnackBar(
      content: Text(message),
      action: action,
      duration: duration,
      hideCurrent: hideCurrent,
      behavior: behavior,
    );
  }

  void _scheduleComposerDraftPersistence({
    required String? sessionId,
    required ChatComposerDraft? draft,
  }) {
    final normalizedSessionId = sessionId?.trim();
    if (normalizedSessionId == null || normalizedSessionId.isEmpty) {
      return;
    }
    _composerDraftPersistTimer?.cancel();
    if (draft == null || !draft.hasContent) {
      unawaited(
        (_chatProvider ?? context.read<ChatProvider>())
            .persistComposerDraftForSession(
              sessionId: normalizedSessionId,
              draft: null,
            ),
      );
      return;
    }
    _composerDraftPersistTimer = Timer(const Duration(milliseconds: 250), () {
      _composerDraftPersistTimer = null;
      unawaited(
        (_chatProvider ?? context.read<ChatProvider>())
            .persistComposerDraftForSession(
              sessionId: normalizedSessionId,
              draft: draft,
            ),
      );
    });
  }

  void _cancelPendingServerUnhealthyNotice() {
    _foregroundWarningSnackbarTimer?.cancel();
    _foregroundWarningSnackbarTimer = null;
    _unhealthySnackbarDebounceTimer?.cancel();
    _unhealthySnackbarDebounceTimer = null;
  }

  void _showServerUnhealthyNotice() {
    _showChatPageSnackBar(
      content: const Text(
        'Active server is unhealthy. Sends will try once and fail fast until recovery.',
      ),
    );
  }

  // Resume-time health and connectivity probes can briefly report stale failure
  // states while sockets and reachability settle, so warning-only UI waits for
  // a short confirmation window before escalating.
  void _startForegroundWarningGrace() {
    _foregroundWarningGraceEndsAt = DateTime.now().add(
      _foregroundWarningConfirmationDelay,
    );
    _foregroundWarningUiRefreshTimer?.cancel();
    _foregroundWarningSnackbarTimer?.cancel();
    _foregroundWarningUiRefreshTimer = Timer(
      _foregroundWarningConfirmationDelay,
      () {
        _foregroundWarningUiRefreshTimer = null;
        if (!mounted) {
          return;
        }
        _setState(() {});
      },
    );
  }

  bool _isForegroundWarningGraceActive() {
    final endsAt = _foregroundWarningGraceEndsAt;
    return _isAppInForeground &&
        endsAt != null &&
        DateTime.now().isBefore(endsAt);
  }

  bool _shouldDeferForegroundWarningUi({
    required ChatProvider chatProvider,
    required AppProvider appProvider,
  }) {
    if (!_isForegroundWarningGraceActive()) {
      return false;
    }
    final health = _activeServerHealth(appProvider);
    return !appProvider.isConnected ||
        health == ServerHealthStatus.unhealthy ||
        _isRecoverableSyncState(chatProvider: chatProvider);
  }

  void _showServerUnhealthyNoticeWithConfirmation() {
    _cancelPendingServerUnhealthyNotice();
    _unhealthySnackbarDebounceTimer = Timer(_unhealthySnackbarDebounce, () {
      _unhealthySnackbarDebounceTimer = null;
      if (!mounted) {
        return;
      }
      _showServerUnhealthyNoticeAfterForegroundGrace();
    });
  }

  void _showServerUnhealthyNoticeAfterForegroundGrace() {
    final chatProvider = _chatProvider;
    final appProvider = _appProvider;
    if (chatProvider == null || appProvider == null) {
      _showServerUnhealthyNotice();
      return;
    }
    if (!_shouldDeferForegroundWarningUi(
      chatProvider: chatProvider,
      appProvider: appProvider,
    )) {
      _showServerUnhealthyNotice();
      return;
    }
    final endsAt = _foregroundWarningGraceEndsAt;
    if (endsAt == null) {
      return;
    }
    final remaining = endsAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _showServerUnhealthyNotice();
      return;
    }
    _foregroundWarningSnackbarTimer?.cancel();
    _foregroundWarningSnackbarTimer = Timer(remaining, () {
      _foregroundWarningSnackbarTimer = null;
      if (!mounted) {
        return;
      }
      final currentChatProvider = _chatProvider;
      final currentAppProvider = _appProvider;
      if (currentChatProvider == null || currentAppProvider == null) {
        return;
      }
      if (_shouldDeferForegroundWarningUi(
        chatProvider: currentChatProvider,
        appProvider: currentAppProvider,
      )) {
        return;
      }
      if (_activeServerHealth(currentAppProvider) ==
          ServerHealthStatus.unhealthy) {
        _showServerUnhealthyNotice();
      }
    });
  }

  Future<void> _handleServerReconnected() async {
    if (!mounted || !_isChatScreenActive()) {
      return;
    }
    final lastResumeRefreshAt = _lastResumeRefreshAt;
    if (lastResumeRefreshAt != null &&
        DateTime.now().difference(lastResumeRefreshAt) <
            const Duration(seconds: 2)) {
      return;
    }
    final chatProvider = _chatProvider ?? context.read<ChatProvider>();
    await chatProvider.refreshActiveSessionView(
      reason: 'app-provider-reconnected',
    );
    _scheduleAutoApprovePermissionDrain(reason: 'server-reconnected');
  }

  Future<void> _handleMobileBackPress() async {
    if (!_isMobileRuntime || !mounted) {
      return;
    }
    final chatProvider = _chatProvider ?? context.read<ChatProvider>();
    if (_isSubConversationSession(chatProvider.currentSession)) {
      await _returnToMainConversation(chatProvider);
      return;
    }
    final scaffoldState = _scaffoldKey.currentState;
    if (!(scaffoldState?.isDrawerOpen ?? false)) {
      scaffoldState?.openDrawer();
      return;
    }
    if (!kIsWeb) {
      await SystemNavigator.pop();
    }
  }

  void _scheduleNotificationTap(NotificationTapPayload payload) {
    _pendingNotificationTap = payload;
    _notificationTapTask ??= _drainNotificationTapQueue();
  }

  Future<void> _drainNotificationTapQueue() async {
    try {
      while (mounted) {
        final payload = _pendingNotificationTap;
        if (payload == null) {
          break;
        }
        _pendingNotificationTap = null;
        await _handleNotificationTap(payload);
      }
    } finally {
      _notificationTapTask = null;
      if (mounted && _pendingNotificationTap != null) {
        _notificationTapTask = _drainNotificationTapQueue();
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationTapPayload payload) async {
    if (!mounted) {
      return;
    }
    final sessionId = payload.sessionId?.trim();
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    final targetDirectory = payload.directory?.trim();
    if (targetDirectory != null && targetDirectory.isNotEmpty) {
      final currentDirectory = context.read<ProjectProvider>().currentDirectory;
      if (currentDirectory != targetDirectory) {
        await _switchDirectoryContext(targetDirectory);
        if (!mounted) {
          return;
        }
      }
    }

    final chatProvider = _chatProvider ?? context.read<ChatProvider>();
    var reloadAttempts = 0;

    for (var attempt = 0; attempt < _notificationTapMaxAttempts; attempt += 1) {
      final targetSession = chatProvider.sessions
          .where((item) => item.id == sessionId)
          .firstOrNull;
      if (targetSession != null) {
        await chatProvider.selectSession(targetSession);
        return;
      }

      if (chatProvider.state != ChatState.loading &&
          reloadAttempts < _notificationTapReloadAttempts) {
        reloadAttempts += 1;
        await chatProvider.loadSessions(userInitiated: true);
        if (!mounted) {
          return;
        }
        continue;
      }

      if (attempt + 1 >= _notificationTapMaxAttempts) {
        return;
      }

      await Future<void>.delayed(_notificationTapRetryInterval);
      if (!mounted) {
        return;
      }
    }
  }

  double _lastKnownMaxScrollExtent = 0;

  ({bool isMobile, bool showConversationPane}) _currentTourLayout(
    SettingsProvider settingsProvider,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = WindowSizeClass.fromWidth(width);
    final compactLayout = sizeClass == WindowSizeClass.compact;
    final mediumLayout = sizeClass == WindowSizeClass.medium;
    final conversationsPaneEnabled = settingsProvider.isDesktopPaneVisible(
      DesktopPane.conversations,
    );
    final showConversationPane =
        !compactLayout &&
        (mediumLayout ? conversationsPaneEnabled : true) &&
        conversationsPaneEnabled;
    return (
      isMobile: compactLayout || (mediumLayout && !showConversationPane),
      showConversationPane: showConversationPane,
    );
  }

  GlobalKey _sidebarAccessTourKey({
    required bool isMobile,
    required bool showConversationPane,
  }) {
    if (isMobile) {
      return _drawerAccessTourKey;
    }
    return showConversationPane
        ? _projectContextTourKey
        : _desktopSidebarMenuTourKey;
  }

  GlobalKey _sidebarAccessTourTargetKey({
    required bool isMobile,
    required bool showConversationPane,
  }) {
    if (isMobile) {
      return _drawerAccessTourTargetKey;
    }
    return showConversationPane
        ? _projectContextTourTargetKey
        : _desktopSidebarMenuTourTargetKey;
  }

  Widget _buildTourTarget({
    required GlobalKey showcaseKey,
    required GlobalKey targetKey,
    required Widget child,
    required String title,
    required String description,
    required TooltipPosition tooltipPosition,
    bool includePrevious = false,
    String primaryActionLabel = 'Next',
    VoidCallback? onNext,
  }) {
    return ChatTourShowcase(
      showcaseKey: showcaseKey,
      targetKey: targetKey,
      title: title,
      description: description,
      tooltipPosition: tooltipPosition,
      includePrevious: includePrevious,
      primaryActionLabel: primaryActionLabel,
      onPrimaryAction: onNext,
      onSkipAction: _handlePostOnboardingTourSkip,
      targetBorderRadius: AppShapes.borderLarge,
      child: child,
    );
  }

  bool _isTourTargetReady(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return false;
    }
    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox) {
      return false;
    }
    return renderObject.attached && renderObject.hasSize;
  }

  void _resetPostOnboardingTourTransientState() {
    _postOnboardingTourRunToken += 1;
    _tourPhase = _PostOnboardingTourPhase.idle;
    _tourStartScheduled = false;
    _tourAdvancingToComposerPhase = false;
    _tourExplicitSkipRequested = false;
  }

  void _handlePostOnboardingTourSkip() {
    _tourExplicitSkipRequested = true;
    ShowcaseView.get().dismiss();
  }

  int _startPostOnboardingTourRun() {
    _postOnboardingTourRunToken += 1;
    _tourStartScheduled = true;
    return _postOnboardingTourRunToken;
  }

  bool _isPostOnboardingTourRunActive(int token) {
    return mounted && token == _postOnboardingTourRunToken;
  }

  void _flushPendingPostOnboardingTourAutoStart() {
    final settingsProvider = _settingsProvider;
    if (settingsProvider == null ||
        !_queuedPendingPostOnboardingTourAutoStart ||
        !settingsProvider.pendingPostOnboardingChatTour ||
        _tourStartScheduled ||
        !_isChatScreenActive()) {
      return;
    }
    final runToken = _startPostOnboardingTourRun();
    Future<void>.delayed(_postOnboardingTourStartDelay, () {
      if (!_isPostOnboardingTourRunActive(runToken)) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isPostOnboardingTourRunActive(runToken)) {
          return;
        }
        _startIntroPostOnboardingTour(attempt: 0, runToken: runToken);
      });
    });
  }

  bool _startShowcaseIfReady(
    List<({GlobalKey showcase, GlobalKey target})> targets, {
    Duration delay = _postOnboardingTourStartDelay,
  }) {
    final allMounted = targets.every(
      (target) => _isTourTargetReady(target.target),
    );
    final showcaseState = _showcaseWidgetKey.currentState;
    if (showcaseState == null || !allMounted) {
      return false;
    }
    showcaseState.startShowCase(
      targets.map((target) => target.showcase).toList(growable: false),
      delay: delay,
    );
    return true;
  }

  void _startIntroPostOnboardingTour({
    required int attempt,
    required int runToken,
  }) {
    if (!_isPostOnboardingTourRunActive(runToken)) {
      return;
    }
    final settingsProvider =
        _settingsProvider ?? context.read<SettingsProvider>();
    final layout = _currentTourLayout(settingsProvider);
    if (layout.isMobile) {
      _closeDrawerIfNeeded(closeOnSelect: true);
    }
    final targets = <({GlobalKey showcase, GlobalKey target})>[
      (
        showcase: _sidebarAccessTourKey(
          isMobile: layout.isMobile,
          showConversationPane: layout.showConversationPane,
        ),
        target: _sidebarAccessTourTargetKey(
          isMobile: layout.isMobile,
          showConversationPane: layout.showConversationPane,
        ),
      ),
      (showcase: _newChatTourKey, target: _newChatTourTargetKey),
    ];
    if (!_startShowcaseIfReady(targets)) {
      if (attempt >= _postOnboardingTourMaxAttempts) {
        _resetPostOnboardingTourTransientState();
        return;
      }
      Future<void>.delayed(_postOnboardingTourRetryDelay, () {
        if (!mounted) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isPostOnboardingTourRunActive(runToken)) {
            return;
          }
          _startIntroPostOnboardingTour(
            attempt: attempt + 1,
            runToken: runToken,
          );
        });
      });
      return;
    }
    _queuedPendingPostOnboardingTourAutoStart = false;
    _tourPhase = _PostOnboardingTourPhase.intro;
  }

  Future<void> _advancePostOnboardingTourToComposer() async {
    if (_tourAdvancingToComposerPhase) {
      return;
    }
    final runToken = _postOnboardingTourRunToken;
    _tourAdvancingToComposerPhase = true;
    _tourPhase = _PostOnboardingTourPhase.composer;
    ShowcaseView.get().dismiss();

    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState?.isDrawerOpen ?? false) {
      scaffoldState?.closeDrawer();
      await Future<void>.delayed(_postOnboardingTourRetryDelay);
      if (!mounted) {
        return;
      }
    }

    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.currentSession != null ||
        !chatProvider.isDraftingNewChat) {
      await chatProvider.beginNewChatDraft();
    }
    if (!_isPostOnboardingTourRunActive(runToken)) {
      return;
    }
    Future<void>.delayed(_postOnboardingTourStartDelay, () {
      if (!_isPostOnboardingTourRunActive(runToken)) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isPostOnboardingTourRunActive(runToken)) {
          return;
        }
        _startComposerPostOnboardingTour(attempt: 0, runToken: runToken);
      });
    });
  }

  void _startComposerPostOnboardingTour({
    required int attempt,
    required int runToken,
  }) {
    if (!_isPostOnboardingTourRunActive(runToken)) {
      return;
    }
    final targets = <({GlobalKey showcase, GlobalKey target})>[
      (showcase: _composerTourKey, target: _composerTourTargetKey),
      (showcase: _sendButtonTourKey, target: _sendButtonTourTargetKey),
    ];
    if (!_startShowcaseIfReady(targets)) {
      if (attempt >= _postOnboardingTourMaxAttempts) {
        _tourAdvancingToComposerPhase = false;
        _tourStartScheduled = false;
        return;
      }
      Future<void>.delayed(_postOnboardingTourRetryDelay, () {
        if (!mounted) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isPostOnboardingTourRunActive(runToken)) {
            return;
          }
          _startComposerPostOnboardingTour(
            attempt: attempt + 1,
            runToken: runToken,
          );
        });
      });
      return;
    }
    // Keep the persisted handoff armed until the user finishes or dismisses the
    // replayed composer steps, even if the composer takes longer than one frame.
    _tourAdvancingToComposerPhase = false;
  }

  Future<void> _restartPostOnboardingTour() async {
    _resetPostOnboardingTourTransientState();
    ShowcaseView.get().dismiss();
    final settingsProvider =
        _settingsProvider ?? context.read<SettingsProvider>();
    if (settingsProvider.pendingPostOnboardingChatTour) {
      await settingsProvider.setPendingPostOnboardingChatTour(false);
    }
    await settingsProvider.setPendingPostOnboardingChatTour(true);
  }

  Future<void> _clearPendingPostOnboardingTour() async {
    _resetPostOnboardingTourTransientState();
    _queuedPendingPostOnboardingTourAutoStart = false;
    _lastPendingPostOnboardingChatTour = false;
    final settingsProvider =
        _settingsProvider ?? context.read<SettingsProvider>();
    await settingsProvider.setPendingPostOnboardingChatTour(false);
  }

  void _handlePostOnboardingTourDismiss(GlobalKey? _) {
    if (_tourAdvancingToComposerPhase ||
        _tourPhase == _PostOnboardingTourPhase.idle) {
      return;
    }
    if (_tourExplicitSkipRequested) {
      unawaited(_clearPendingPostOnboardingTour());
      return;
    }
    // Passive dismiss should stop the current run without consuming the
    // first-use handoff. The next eligible return to chat can re-open it.
    _resetPostOnboardingTourTransientState();
    final settingsProvider =
        _settingsProvider ?? context.read<SettingsProvider>();
    if (settingsProvider.pendingPostOnboardingChatTour) {
      _queuedPendingPostOnboardingTourAutoStart = true;
    }
  }

  void _handlePostOnboardingTourFinish() {
    if (_tourAdvancingToComposerPhase ||
        _tourPhase != _PostOnboardingTourPhase.composer) {
      return;
    }
    unawaited(_clearPendingPostOnboardingTour());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final sizeClass = WindowSizeClass.fromWidth(width);
        final isMobile = sizeClass.isCompact;
        final isMedium = sizeClass == WindowSizeClass.medium;
        final isLargeDesktop = sizeClass.isAtLeastLarge;
        final keyboardOpen =
            MediaQuery.viewInsetsOf(context).bottom > 0 ||
            View.of(context).viewInsets.bottom > 0;
        final settingsProvider = context.watch<SettingsProvider>();
        final conversationsPaneEnabled = settingsProvider.isDesktopPaneVisible(
          DesktopPane.conversations,
        );
        // Medium: narrow conversation pane; expanded+: full pane
        final showConversationPane =
            !isMobile &&
            (isMedium ? conversationsPaneEnabled : true) &&
            conversationsPaneEnabled;
        final showDesktopFilePane =
            !isMobile &&
            !isMedium &&
            width >= _filePaneBreakpoint &&
            settingsProvider.isDesktopPaneVisible(DesktopPane.files);
        final showDesktopUtilityPane =
            isLargeDesktop &&
            settingsProvider.isDesktopPaneVisible(DesktopPane.utility);
        // Medium breakpoint stays fixed (compact layout); expanded+ uses
        // the persisted/resizable width from settings.
        final sessionPaneWidth = isMedium
            ? _mediumSessionPaneWidth
            : settingsProvider.desktopPaneWidth(DesktopPane.conversations);
        final mainContentWidth = isLargeDesktop ? 960.0 : double.infinity;
        const refreshlessEnabled = FeatureFlags.refreshlessRealtime;
        final availableShortcutActions = shortcutActionsForRuntime(
          isWeb: kIsWeb,
          targetPlatform: defaultTargetPlatform,
          refreshlessRealtimeEnabled: refreshlessEnabled,
        );
        final shortcutMap = <ShortcutActivator, Intent>{};
        void addShortcut(ShortcutAction action, Intent intent) {
          final binding = settingsProvider.bindingFor(action);
          final activator = ShortcutBindingCodec.parse(binding);
          if (activator != null) {
            shortcutMap[activator] = intent;
          }
        }

        final actionMap = <Type, Action<Intent>>{
          _NewSessionIntent: CallbackAction<_NewSessionIntent>(
            onInvoke: (_) {
              _createNewSession();
              return null;
            },
          ),
          _FocusInputIntent: CallbackAction<_FocusInputIntent>(
            onInvoke: (_) {
              _focusInput();
              return null;
            },
          ),
          _ToggleVoiceInputIntent: CallbackAction<_ToggleVoiceInputIntent>(
            onInvoke: (_) {
              unawaited(_toggleVoiceInputShortcut());
              return null;
            },
          ),
          _QuickOpenIntent: CallbackAction<_QuickOpenIntent>(
            onInvoke: (_) {
              _invokeShortcutAction(ShortcutAction.quickOpen);
              return null;
            },
          ),
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) {
              _invokeShortcutAction(ShortcutAction.openSettings);
              return null;
            },
          ),
          _CycleRecentModelsIntent: CallbackAction<_CycleRecentModelsIntent>(
            onInvoke: (_) {
              _invokeShortcutAction(ShortcutAction.cycleRecentModels);
              return null;
            },
          ),
          _CycleVariantIntent: CallbackAction<_CycleVariantIntent>(
            onInvoke: (_) {
              _invokeShortcutAction(ShortcutAction.cycleVariant);
              return null;
            },
          ),
          _EscapeIntent: CallbackAction<_EscapeIntent>(
            onInvoke: (_) {
              _handleEscape();
              return null;
            },
          ),
          _CloseAppIntent: CallbackAction<_CloseAppIntent>(
            onInvoke: (_) {
              unawaited(_closeAppShortcut());
              return null;
            },
          ),
          _QuitAppIntent: CallbackAction<_QuitAppIntent>(
            onInvoke: (_) {
              unawaited(_quitAppShortcut());
              return null;
            },
          ),
        };
        for (final action in availableShortcutActions) {
          switch (action) {
            case ShortcutAction.newChat:
              addShortcut(action, const _NewSessionIntent());
              break;
            case ShortcutAction.refresh:
              actionMap[_RefreshIntent] = CallbackAction<_RefreshIntent>(
                onInvoke: (_) {
                  _refreshData();
                  return null;
                },
              );
              addShortcut(action, const _RefreshIntent());
              break;
            case ShortcutAction.focusInput:
              addShortcut(action, const _FocusInputIntent());
              break;
            case ShortcutAction.toggleVoiceInput:
              addShortcut(action, const _ToggleVoiceInputIntent());
              break;
            case ShortcutAction.quickOpen:
              addShortcut(action, const _QuickOpenIntent());
              break;
            case ShortcutAction.openSettings:
              addShortcut(action, const _OpenSettingsIntent());
              break;
            case ShortcutAction.cycleRecentModels:
              addShortcut(action, const _CycleRecentModelsIntent());
              break;
            case ShortcutAction.cycleVariant:
              addShortcut(action, const _CycleVariantIntent());
              break;
            case ShortcutAction.escape:
              addShortcut(action, const _EscapeIntent());
              break;
            case ShortcutAction.cycleAgentForward:
            case ShortcutAction.cycleAgentBackward:
              // Handled by the global key-event loop to keep direction-specific
              // behavior centralized with the other chat actions.
              break;
            case ShortcutAction.closeApp:
              addShortcut(action, const _CloseAppIntent());
              break;
            case ShortcutAction.quitApp:
              addShortcut(action, const _QuitAppIntent());
              break;
          }
        }

        return ShowCaseWidget(
          key: _showcaseWidgetKey,
          onDismiss: _handlePostOnboardingTourDismiss,
          onFinish: _handlePostOnboardingTourFinish,
          enableAutoScroll: false,
          builder: (context) => Shortcuts(
            shortcuts: shortcutMap,
            child: Actions(
              actions: actionMap,
              child: Focus(
                autofocus: true,
                onKeyEvent: (_, event) {
                  return _handleGlobalShortcutKeyEvent(event)
                      ? KeyEventResult.handled
                      : KeyEventResult.ignored;
                },
                child: PopScope<void>(
                  canPop: !_isMobileRuntime,
                  onPopInvokedWithResult: (didPop, _) {
                    if (didPop || !_isMobileRuntime) {
                      return;
                    }
                    unawaited(_handleMobileBackPress());
                  },
                  child: Scaffold(
                    key: _scaffoldKey,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    resizeToAvoidBottomInset: true,
                    appBar: _buildAppBar(
                      isMobile: isMobile || (isMedium && !showConversationPane),
                      isLargeDesktop: isLargeDesktop,
                      settingsProvider: settingsProvider,
                    ),
                    drawer: (isMobile || (isMedium && !showConversationPane))
                        ? _buildSessionDrawer()
                        : null,
                    body: Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        _syncSessionScrollState(chatProvider);
                        _syncResponseViewportPolicy(chatProvider);
                        _syncChatRouteActivity(chatProvider);
                        _consumePendingUiNotice(chatProvider);
                        _consumePendingHistoryComposerSync(chatProvider);
                        _consumeRejectedDraft(chatProvider);
                        late final Widget content;
                        if (isMobile) {
                          content = _buildChatContent(
                            chatProvider: chatProvider,
                            isKeyboardOpen: keyboardOpen,
                            maxContentWidth: double.infinity,
                            horizontalPadding: 0,
                            verticalPadding: 0,
                          );
                        } else {
                          final filePaneWidth = settingsProvider
                              .desktopPaneWidth(DesktopPane.files);
                          final utilityPaneWidth = settingsProvider
                              .desktopPaneWidth(DesktopPane.utility);
                          final rowChildren = <Widget>[
                            if (showConversationPane) ...[
                              SizedBox(
                                width: sessionPaneWidth,
                                child: _buildSessionPanel(
                                  closeOnSelect: false,
                                  isMobileLayout: false,
                                  onCollapseRequested: () {
                                    unawaited(
                                      settingsProvider.setDesktopPaneVisible(
                                        DesktopPane.conversations,
                                        false,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (isMedium)
                                _buildPaneDivider()
                              else
                                _buildResizableHandle(
                                  pane: DesktopPane.conversations,
                                  settingsProvider: settingsProvider,
                                  paneOnLeft: true,
                                ),
                            ],
                            if (showDesktopFilePane) ...[
                              SizedBox(
                                width: filePaneWidth,
                                child: _buildDesktopFilePane(
                                  chatProvider,
                                  onCollapseRequested: () {
                                    unawaited(
                                      settingsProvider.setDesktopPaneVisible(
                                        DesktopPane.files,
                                        false,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              _buildResizableHandle(
                                pane: DesktopPane.files,
                                settingsProvider: settingsProvider,
                                paneOnLeft: true,
                              ),
                            ],
                            Expanded(
                              child: _buildChatContent(
                                chatProvider: chatProvider,
                                isKeyboardOpen: keyboardOpen,
                                maxContentWidth: mainContentWidth,
                                horizontalPadding: 12,
                                verticalPadding: 2,
                              ),
                            ),
                            if (showDesktopUtilityPane) ...[
                              _buildResizableHandle(
                                pane: DesktopPane.utility,
                                settingsProvider: settingsProvider,
                                paneOnLeft: false,
                              ),
                              SizedBox(
                                width: utilityPaneWidth,
                                child: _buildDesktopUtilityPane(
                                  chatProvider,
                                  settingsProvider: settingsProvider,
                                  onCollapseRequested: () {
                                    unawaited(
                                      settingsProvider.setDesktopPaneVisible(
                                        DesktopPane.utility,
                                        false,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ];
                          content = Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: rowChildren,
                          );
                        }

                        if (!_isProjectScopeTransitioning) {
                          return content;
                        }

                        return Stack(
                          children: [
                            Positioned.fill(child: content),
                            Positioned.fill(
                              child: _buildProjectScopeLoadingOverlay(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<({String shortcut, String description})> _keyboardShortcutHints(
    SettingsProvider settingsProvider,
  ) {
    final entries = <({ShortcutAction action, String description})>[
      for (final action in shortcutActionsForRuntime(
        isWeb: kIsWeb,
        targetPlatform: defaultTargetPlatform,
        refreshlessRealtimeEnabled: FeatureFlags.refreshlessRealtime,
      ))
        switch (action) {
          ShortcutAction.newChat => (
            action: action,
            description: 'New conversation',
          ),
          ShortcutAction.refresh => (
            action: action,
            description: 'Refresh chat data',
          ),
          ShortcutAction.focusInput => (
            action: action,
            description: 'Focus message input',
          ),
          ShortcutAction.toggleVoiceInput => (
            action: action,
            description: 'Start or stop voice input',
          ),
          ShortcutAction.quickOpen => (
            action: action,
            description: 'Quick open files',
          ),
          ShortcutAction.openSettings => (
            action: action,
            description: 'Open settings',
          ),
          ShortcutAction.cycleRecentModels => (
            action: action,
            description: 'Cycle recent models',
          ),
          ShortcutAction.cycleVariant => (
            action: action,
            description: 'Cycle model variant',
          ),
          ShortcutAction.escape => (
            action: action,
            description: 'Focus input (or close drawer when open)',
          ),
          ShortcutAction.cycleAgentForward => (
            action: action,
            description: 'Next agent',
          ),
          ShortcutAction.cycleAgentBackward => (
            action: action,
            description: 'Previous agent',
          ),
          ShortcutAction.closeApp => (
            action: action,
            description: 'Close app using platform close behavior',
          ),
          ShortcutAction.quitApp => (
            action: action,
            description: 'Force-exit the app',
          ),
        },
    ];

    final hints = entries
        .map(
          (entry) => (
            shortcut: ShortcutBindingCodec.formatForDisplay(
              settingsProvider.bindingFor(entry.action),
            ),
            description: entry.description,
          ),
        )
        .toList();

    final escapeShortcut = ShortcutBindingCodec.formatForDisplay(
      settingsProvider.bindingFor(ShortcutAction.escape),
    );
    hints.add((
      shortcut: '$escapeShortcut, $escapeShortcut',
      description: 'Stop active response (while responding)',
    ));
    return hints;
  }

  bool get _isMobileViewport {
    if (!mounted) {
      return false;
    }
    // Medium (tablet) still uses single-column layout where long-press
    // to reuse prompt and similar mobile gestures must work.
    return !context.windowSizeClass.isAtLeastExpanded;
  }

  ({String compactionId, String compactionLabel})? _resolveCompactionBoundary(
    ChatMessage message,
  ) {
    final compactionPart = _findCompactionPart(message);
    if (compactionPart != null) {
      return (
        compactionId: compactionPart.id,
        compactionLabel: compactionPart.auto ? 'automatic' : 'manual',
      );
    }
    if (_isCompactionSummaryMessage(message)) {
      return (
        compactionId: 'summary_${message.id}',
        compactionLabel: 'context',
      );
    }
    return null;
  }
}

class _FileExplorerContextState {
  _FileExplorerContextState({required this.rootDirectory});

  String rootDirectory;
  DateTime? lastLoadedAt;
  final Map<String, List<FileNode>> directoryChildren =
      <String, List<FileNode>>{};
  final Set<String> expandedDirectories = <String>{};
  final Set<String> loadingDirectories = <String>{};
  final Map<String, _FileTabViewState> tabsByPath =
      <String, _FileTabViewState>{};
  FileTabSelectionState tabSelection = const FileTabSelectionState();
  // Line selection state for "add to chat" feature (1-based line numbers).
  final Map<String, Set<int>> selectedLinesByPath = <String, Set<int>>{};
  final Map<String, int> lastSelectedLineByPath = <String, int>{};
  bool rootLoadScheduled = false;
  String? treeError;

  void resetForRoot(String nextRootDirectory) {
    rootDirectory = nextRootDirectory;
    lastLoadedAt = null;
    directoryChildren.clear();
    expandedDirectories.clear();
    loadingDirectories.clear();
    selectedLinesByPath.clear();
    lastSelectedLineByPath.clear();
    rootLoadScheduled = false;
    treeError = null;
  }
}

enum _FileTabLoadStatus { loading, ready, binary, empty, error }

class _FileTabViewState {
  const _FileTabViewState({
    required this.status,
    required this.content,
    this.errorMessage,
    this.mimeType,
  });

  final _FileTabLoadStatus status;
  final String content;
  final String? errorMessage;
  final String? mimeType;
}

abstract class _TimelineEntry {
  const _TimelineEntry();

  String get key;
}

class _TimelineMessageEntry extends _TimelineEntry {
  const _TimelineMessageEntry(this.message);

  final ChatMessage message;

  @override
  String get key => 'timeline_msg_${message.id}';
}

class _TimelinePermissionPromptEntry extends _TimelineEntry {
  const _TimelinePermissionPromptEntry({required this.request});

  final ChatPermissionRequest request;

  @override
  String get key => 'timeline_permission_prompt_${request.id}';
}

class _TimelineCollapsedHistoryEntry extends _TimelineEntry {
  const _TimelineCollapsedHistoryEntry({
    required this.group,
    required this.expanded,
  });

  final _CollapsedHistoryGroup group;
  final bool expanded;

  @override
  String get key => 'timeline_collapsed_history_${group.id}';
}

class _CollapsedHistoryGroup {
  const _CollapsedHistoryGroup({
    required this.startMessageId,
    required this.endMessageId,
    required this.messageCount,
    required this.createdAt,
    required this.compactionId,
    required this.compactionLabel,
  });

  final String startMessageId;
  final String endMessageId;
  final int messageCount;
  final DateTime createdAt;
  final String compactionId;
  final String compactionLabel;

  String get id => '${compactionId}_${startMessageId}_$endMessageId';
}

class _TimelineCollapsedAssistantWorkEntry extends _TimelineEntry {
  const _TimelineCollapsedAssistantWorkEntry({
    required this.group,
    required this.expanded,
    this.previewMessages = const <ChatMessage>[],
    this.showBoundedPreview = false,
  });

  final _CollapsedAssistantWorkGroup group;
  final bool expanded;
  final List<ChatMessage> previewMessages;
  final bool showBoundedPreview;

  @override
  String get key => 'timeline_collapsed_assistant_work_${group.id}';
}

class _CollapsedAssistantWorkGroup {
  const _CollapsedAssistantWorkGroup({
    required this.startMessageId,
    required this.endMessageId,
    required this.finalMessageId,
    required this.messageCount,
    required this.createdAt,
  });

  final String startMessageId;
  final String endMessageId;
  final String finalMessageId;
  final int messageCount;
  final DateTime createdAt;

  String get id => 'assistant_work_$finalMessageId';
}

class _TimelineRetryIndicatorEntry extends _TimelineEntry {
  const _TimelineRetryIndicatorEntry();

  @override
  String get key => 'timeline_retry_indicator';
}

enum _AssistantProgressStage { thinking, receiving, retrying }

enum _ComposerStatusType {
  activeProgress,
  dynamicReasoning,
  receiving,
  retrying,
  stopHint,
  tip,
}

class _ComposerStatusPresentation {
  const _ComposerStatusPresentation._({
    required this.type,
    required this.label,
    this.icon,
  });

  const _ComposerStatusPresentation.activeProgress({
    required String label,
    required IconData icon,
  }) : this._(
         type: _ComposerStatusType.activeProgress,
         label: label,
         icon: icon,
       );

  const _ComposerStatusPresentation.dynamicReasoning(String label)
    : this._(type: _ComposerStatusType.dynamicReasoning, label: label);

  const _ComposerStatusPresentation.receiving()
    : this._(type: _ComposerStatusType.receiving, label: 'Reasoning...');

  const _ComposerStatusPresentation.retrying()
    : this._(
        type: _ComposerStatusType.retrying,
        label: 'Retrying model request...',
      );

  const _ComposerStatusPresentation.stopHint()
    : this._(type: _ComposerStatusType.stopHint, label: 'Double ESC to stop');

  const _ComposerStatusPresentation.tip(String label)
    : this._(type: _ComposerStatusType.tip, label: label);

  static const List<String> _receivingTips = [
    'Tip: Use @ to mention files in your prompt',
    'Tip: Tap the title to rename a conversation',
    'Tip: Use ! at the start to run shell commands',
    'Tip: Use / to access slash commands',
    'Tip: Long-press Send to insert a newline',
    'Tip: Tap the context knob to see usage details',
    'Tip: Be specific — shorter prompts get faster answers',
    'Tip: Ask for step-by-step when debugging complex issues',
    'Tip: Provide context — paste error messages and logs',
    'Tip: Break large tasks into smaller prompts',
  ];

  final _ComposerStatusType type;
  final String label;
  final IconData? icon;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _ComposerStatusPresentation &&
        other.type == type &&
        other.label == label &&
        other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(type, label, icon);
}

class _ComposerStatusLanternText extends StatefulWidget {
  const _ComposerStatusLanternText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.repeat = true,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool repeat;

  @override
  State<_ComposerStatusLanternText> createState() =>
      _ComposerStatusLanternTextState();
}

class _ComposerStatusLanternTextState extends State<_ComposerStatusLanternText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant _ComposerStatusLanternText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repeat != widget.repeat || oldWidget.text != widget.text) {
      _syncAnimationState(restart: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _animationsEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery?.disableAnimations ?? false) {
      return false;
    }
    return !WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
  }

  void _syncAnimationState({bool restart = false}) {
    if (!_animationsEnabled(context)) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      if (_controller.value != 0) {
        _controller.value = 0;
      }
      return;
    }
    if (widget.repeat) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
      return;
    }
    if (restart || _controller.status == AnimationStatus.completed) {
      _controller.stop();
      _controller.forward(from: 0);
      return;
    }
    if (!_controller.isAnimating &&
        _controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style;
    final textWidget = Text(
      widget.text,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      style: textStyle,
    );

    if (!_animationsEnabled(context)) {
      return textWidget;
    }

    if (!widget.repeat &&
        !_controller.isAnimating &&
        _controller.status == AnimationStatus.completed) {
      return textWidget;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = textStyle?.color ?? colorScheme.onSurfaceVariant;
    final dimColor = baseColor.withValues(alpha: 0.72);
    final highlightColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.35),
      baseColor,
    );

    return AnimatedBuilder(
      animation: _controller,
      child: textWidget,
      builder: (context, child) {
        final rawCenter = (_controller.value * 1.8) - 0.4;
        final left = (rawCenter - 0.16).clamp(0.0, 1.0);
        final innerLeft = (rawCenter - 0.06).clamp(0.0, 1.0);
        final center = rawCenter.clamp(0.0, 1.0);
        final innerRight = (rawCenter + 0.06).clamp(0.0, 1.0);
        final right = (rawCenter + 0.16).clamp(0.0, 1.0);

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                dimColor,
                dimColor,
                baseColor,
                highlightColor,
                baseColor,
                dimColor,
                dimColor,
              ],
              stops: [0.0, left, innerLeft, center, innerRight, right, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _DirectoryPickerSheet extends StatefulWidget {
  const _DirectoryPickerSheet({required this.initialDirectory});

  final String initialDirectory;

  @override
  State<_DirectoryPickerSheet> createState() => _DirectoryPickerSheetState();
}

class _DirectoryPickerSheetState extends State<_DirectoryPickerSheet> {
  late String _currentDirectory;
  final TextEditingController _filterController = TextEditingController();
  List<String> _directories = const <String>[];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentDirectory = _normalizeDirectory(widget.initialDirectory);
    _loadDirectory(_currentDirectory);
    _filterController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory(String directory) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final provider = context.read<ProjectProvider>();
    final listed = await provider.listDirectories(directory);

    if (!mounted) {
      return;
    }

    if (listed == null) {
      setState(() {
        _loading = false;
        _error = provider.error ?? 'Failed to load directories';
      });
      return;
    }

    setState(() {
      _currentDirectory = _normalizeDirectory(directory);
      _directories = listed;
      _loading = false;
      _error = null;
    });
  }

  String _normalizeDirectory(String input) {
    var value = input.trim();
    if (value.isEmpty) {
      return '/';
    }
    if (value.length > 1 && value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  String _basename(String path) {
    final normalized = _normalizeDirectory(path).replaceAll('\\', '/');
    if (normalized == '/') {
      return '/';
    }
    final parts = normalized
        .split('/')
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? normalized : parts.last;
  }

  String? _parentDirectory(String path) {
    final normalized = _normalizeDirectory(path).replaceAll('\\', '/');
    if (normalized == '/') {
      return null;
    }
    final index = normalized.lastIndexOf('/');
    if (index <= 0) {
      return '/';
    }
    return normalized.substring(0, index);
  }

  @override
  Widget build(BuildContext context) {
    final query = _filterController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _directories
        : _directories
              .where((item) {
                final base = _basename(item).toLowerCase();
                return base.contains(query) ||
                    item.toLowerCase().contains(query);
              })
              .toList(growable: false);
    final parent = _parentDirectory(_currentDirectory);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: Column(
        key: const ValueKey<String>('directory_picker_sheet'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select directory',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  key: const ValueKey<String>('directory_picker_use_current'),
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(_currentDirectory),
                  child: const Text('Use current'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _currentDirectory,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Symbols.info,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Choose a folder to open as project context.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              key: const ValueKey<String>('directory_picker_filter'),
              controller: _filterController,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Symbols.search),
                hintText: 'Filter directories',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: () => _loadDirectory(_currentDirectory),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      if (parent != null)
                        ListTile(
                          key: const ValueKey<String>(
                            'directory_picker_parent',
                          ),
                          leading: const Icon(Symbols.arrow_upward_rounded),
                          title: const Text('..'),
                          subtitle: Text(parent),
                          onTap: () => _loadDirectory(parent),
                        ),
                      for (final directory in filtered)
                        ListTile(
                          key: ValueKey<String>(
                            'directory_picker_item_$directory',
                          ),
                          leading: const Icon(Symbols.folder),
                          title: Text(_basename(directory)),
                          subtitle: Text(
                            directory,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _loadDirectory(directory),
                          onLongPress: () => Navigator.of(
                            context,
                          ).pop(_normalizeDirectory(directory)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
