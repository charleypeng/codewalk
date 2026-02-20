import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart' hide Provider;
import 'package:simple_icons/simple_icons.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/config/feature_flags.dart';
import '../../core/di/injection_container.dart' as di;
import '../../core/logging/app_logger.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/agent.dart';
import '../../domain/entities/chat_composer_draft.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_realtime.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/experience_settings.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/provider.dart';
import '../providers/app_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/project_provider.dart';
import '../providers/settings_provider.dart';
import '../services/android_background_alert_worker.dart';
import '../services/notification_service.dart';
import '../utils/file_explorer_logic.dart';
import '../utils/reasoning_status_parser.dart';
import '../utils/session_title_formatter.dart';
import '../utils/shortcut_binding_codec.dart';
import '../utils/window_size_class.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/chat_session_list.dart';
import '../widgets/permission_request_card.dart';
import '../widgets/question_request_card.dart';
import '../widgets/session_title_inline_editor.dart';
import '../widgets/session_todo_list_widget.dart';
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

enum _ContextUsageAction { compactNow }

enum _DisplayToggleAction {
  thinkingBubbles,
  toolCallBubbles,
  taskList,
  composerTips,
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
  // File pane shown when expanded and width exceeds this threshold
  static const double _filePaneBreakpoint = 1100;
  static const double _desktopSessionPaneWidth = 300;
  static const double _largeDesktopSessionPaneWidth = 320;
  static const double _desktopFilePaneWidth = 280;
  static const double _largeDesktopUtilityPaneWidth = 280;
  static const double _nearBottomThreshold = 200;
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
  static const Duration _composerStatusShowDelay = Duration(seconds: 2);
  static const Duration _composerStatusHideDelay = Duration(seconds: 1);
  static const Duration _composerStopHintDuration = Duration(seconds: 1);
  static const Duration _mobileBackgroundRealtimeHoldDuration = Duration(
    minutes: 3,
  );
  static const Duration _doubleEscapeStopThreshold = Duration(
    milliseconds: 500,
  );
  static const double _composerStatusReservedHeight = 26;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode(debugLabel: 'chat_input');
  final ChatInputController _chatInputController = ChatInputController();
  final GlobalKey _agentSelectorChipKey = GlobalKey(
    debugLabel: 'agent_selector_chip',
  );
  final TextEditingController _sessionSearchController =
      TextEditingController();
  NotificationService? _notificationService;
  StreamSubscription<NotificationTapPayload>? _notificationTapSubscription;
  ChatProvider? _chatProvider;
  AppProvider? _appProvider;
  SettingsProvider? _settingsProvider;
  String? _lastServerId;
  bool? _lastServerConnectionState;
  String? _trackedSessionId;
  String? _pendingInitialScrollSessionId;
  bool _autoFollowToLatest = true;
  bool _showScrollToLatestFab = false;
  bool _hasUnreadMessagesBelow = false;
  bool _showScrollToFirstFab = false;
  bool _isAppInForeground = true;
  bool _wasChatRouteCurrent = true;
  bool _isProgrammaticScrollInFlight = false;
  int _scrollToBottomRequestToken = 0;
  ChatComposerDraft? _composerPrefilledDraft;
  int _composerPrefilledDraftVersion = 0;
  final Map<String, _FileExplorerContextState> _fileContextStates =
      <String, _FileExplorerContextState>{};
  final Map<String, String> _fileDiffSignaturesByContext = <String, String>{};
  final List<FileInputPart> _fileContextItems = <FileInputPart>[];
  DateTime? _serverAlertIssueStartedAt;
  Timer? _serverAlertRevealTimer;
  Timer? _composerStatusShowTimer;
  Timer? _composerStatusHideTimer;
  Timer? _composerStopHintTimer;
  Timer? _backgroundRealtimeHoldTimer;
  Timer? _tipRotationTimer;
  int _currentTipIndex = 0;
  DateTime? _lastGlobalEscapeAt;
  _ComposerStatusPresentation? _visibleComposerStatus;
  _ComposerStatusPresentation? _priorityComposerStatus;
  _ComposerStatusPresentation? _pendingComposerStatus;
  _ComposerStatusPresentation? _queuedComposerStatusTarget;
  _ComposerStatusPresentation? _lastComposerStatusTarget;
  bool _composerStatusTargetInitialized = false;
  String? _expandedCollapsedHistoryGroupId;
  String? _frozenCompactionBoundaryId;
  bool _wasCompactingContext = false;
  String? _nextFrozenCompactionBoundaryId;
  bool _nextWasCompactingContext = false;
  bool _compactionStateSyncScheduled = false;

  // Cache for _buildMessageTimelineEntries to avoid O(N) recomputation on
  // rebuilds where the message list hasn't changed (e.g. session.status events).
  int _cachedTimelineMessageCount = -1;
  String? _cachedTimelineLastMessageId;
  bool _cachedTimelineIsCompacting = false;
  bool _cachedTimelineIsResponding = false;
  bool _cachedTimelineShowRetry = false;
  String? _cachedTimelineExpandedGroupId;
  List<_TimelineEntry>? _cachedTimelineEntries;

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

  // Cached highlight theme to avoid re-creating the Map<String, TextStyle>
  // spread on every _resolveHighlightTheme() call, which forces the
  // HighlightView to re-parse when it detects a "changed" theme reference.
  Map<String, TextStyle>? _cachedHighlightTheme;
  Brightness? _cachedHighlightBrightness;

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
    _chatProvider ??= context.read<ChatProvider>();
    _chatProvider?.setAppInForeground(_isAppInForeground);
    final nextAppProvider = context.read<AppProvider>();
    if (!identical(_appProvider, nextAppProvider)) {
      _appProvider?.removeListener(_handleAppProviderChange);
      _appProvider = nextAppProvider;
      _lastServerId = nextAppProvider.activeServerId;
      _lastServerConnectionState = nextAppProvider.isConnected;
      _appProvider?.addListener(_handleAppProviderChange);
    }
    if (di.sl.isRegistered<NotificationService>()) {
      final nextNotificationService = di.sl<NotificationService>();
      if (!identical(_notificationService, nextNotificationService)) {
        _notificationTapSubscription?.cancel();
        _notificationService = nextNotificationService;
        _notificationTapSubscription = nextNotificationService
            .onNotificationTapped
            .listen((payload) {
              unawaited(_handleNotificationTap(payload));
            });
        final pendingPayload = nextNotificationService.consumePendingTap();
        if (pendingPayload != null) {
          unawaited(_handleNotificationTap(pendingPayload));
        }
      }
    }
    final nextSettingsProvider = context.read<SettingsProvider>();
    if (!identical(_settingsProvider, nextSettingsProvider)) {
      _settingsProvider?.removeListener(_handleSettingsChanged);
      _settingsProvider = nextSettingsProvider;
      _settingsProvider?.addListener(_handleSettingsChanged);
      _applyForegroundPolicy(reason: 'settings-provider-attached');
    }
  }

  @override
  void dispose() {
    // Clean up scroll callback using saved reference
    _chatProvider?.setScrollToBottomCallback(null);
    _chatProvider?.setChatRouteActive(false);
    unawaited(_chatProvider?.setForegroundActive(false));
    _scrollToBottomRequestToken += 1;
    _appProvider?.removeListener(_handleAppProviderChange);
    _notificationTapSubscription?.cancel();
    _settingsProvider?.removeListener(_handleSettingsChanged);
    _serverAlertRevealTimer?.cancel();
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
    chatProvider.setScrollToBottomCallback(_scrollToBottom);
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
      await appProvider.checkConnection(
        directory: projectProvider.currentDirectory,
      );
      chatProvider.warmupProvidersRefresh(reason: 'chat-startup');

      // Technical comment translated to English.
      await chatProvider.loadSessions();
    } catch (e) {
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
    final serverChanged = currentServerId != _lastServerId;

    if (serverChanged) {
      _lastServerId = currentServerId;
      _lastServerConnectionState = currentConnected;
      if (currentServerId != null) {
        unawaited(_handleServerScopeChange());
      }
      return;
    }

    final wasConnected = _lastServerConnectionState;
    _lastServerConnectionState = currentConnected;
    if (wasConnected == false && currentConnected) {
      unawaited(_handleServerReconnected());
    }
  }

  Future<void> _handleServerReconnected() async {
    if (!mounted || !_isChatScreenActive()) {
      return;
    }
    final chatProvider = _chatProvider ?? context.read<ChatProvider>();
    await chatProvider.refreshActiveSessionView(
      reason: 'app-provider-reconnected',
    );
  }

  Future<void> _handleNotificationTap(NotificationTapPayload payload) async {
    if (!mounted) {
      return;
    }
    final sessionId = payload.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    final chatProvider = _chatProvider ?? context.read<ChatProvider>();
    var targetSession = chatProvider.sessions
        .where((item) => item.id == sessionId)
        .firstOrNull;
    if (targetSession == null) {
      await chatProvider.loadSessions();
      if (!mounted) {
        return;
      }
      targetSession = chatProvider.sessions
          .where((item) => item.id == sessionId)
          .firstOrNull;
    }
    if (targetSession == null) {
      return;
    }
    await chatProvider.selectSession(targetSession);
  }

  double _lastKnownMaxScrollExtent = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final sizeClass = WindowSizeClass.fromWidth(width);
        final isMobile = sizeClass.isCompact || sizeClass == WindowSizeClass.medium;
        final isLargeDesktop = sizeClass.isAtLeastLarge;
        final settingsProvider = context.watch<SettingsProvider>();
        final showConversationPane =
            !isMobile &&
            settingsProvider.isDesktopPaneVisible(DesktopPane.conversations);
        final showDesktopFilePane =
            !isMobile &&
            width >= _filePaneBreakpoint &&
            settingsProvider.isDesktopPaneVisible(DesktopPane.files);
        final showDesktopUtilityPane =
            isLargeDesktop &&
            settingsProvider.isDesktopPaneVisible(DesktopPane.utility);
        final sessionPaneWidth = isLargeDesktop
            ? _largeDesktopSessionPaneWidth
            : _desktopSessionPaneWidth;
        final mainContentWidth = isLargeDesktop ? 960.0 : double.infinity;
        const refreshlessEnabled = FeatureFlags.refreshlessRealtime;
        final shortcutMap = <ShortcutActivator, Intent>{};
        void addShortcut(ShortcutAction action, Intent intent) {
          final binding = settingsProvider.bindingFor(action);
          final activator = ShortcutBindingCodec.parse(binding);
          if (activator != null) {
            shortcutMap[activator] = intent;
          }
        }

        addShortcut(ShortcutAction.newChat, const _NewSessionIntent());
        addShortcut(ShortcutAction.focusInput, const _FocusInputIntent());
        addShortcut(ShortcutAction.quickOpen, const _QuickOpenIntent());
        addShortcut(ShortcutAction.openSettings, const _OpenSettingsIntent());
        addShortcut(
          ShortcutAction.cycleRecentModels,
          const _CycleRecentModelsIntent(),
        );
        addShortcut(ShortcutAction.cycleVariant, const _CycleVariantIntent());
        addShortcut(ShortcutAction.escape, const _EscapeIntent());
        addShortcut(
          ShortcutAction.cycleAgentForward,
          const _CycleAgentIntent(),
        );
        addShortcut(
          ShortcutAction.cycleAgentBackward,
          const _CycleAgentIntent(reverse: true),
        );
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
          _CycleAgentIntent: CallbackAction<_CycleAgentIntent>(
            onInvoke: (intent) {
              final chatProvider = context.read<ChatProvider>();
              unawaited(chatProvider.cycleAgent(reverse: intent.reverse));
              return null;
            },
          ),
        };
        if (!refreshlessEnabled) {
          addShortcut(ShortcutAction.refresh, const _RefreshIntent());
          actionMap[_RefreshIntent] = CallbackAction<_RefreshIntent>(
            onInvoke: (_) {
              _refreshData();
              return null;
            },
          );
        }

        return Shortcuts(
          shortcuts: shortcutMap,
          child: Actions(
            actions: actionMap,
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                resizeToAvoidBottomInset: true,
                appBar: _buildAppBar(
                  isMobile: isMobile,
                  isLargeDesktop: isLargeDesktop,
                  settingsProvider: settingsProvider,
                ),
                drawer: isMobile ? _buildSessionDrawer() : null,
                body: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    _syncSessionScrollState(chatProvider);
                    _syncChatRouteActivity(chatProvider);
                    _consumePendingUiNotice(chatProvider);
                    _consumeRejectedDraft(chatProvider);
                    if (isMobile) {
                      return _buildChatContent(
                        chatProvider: chatProvider,
                        maxContentWidth: double.infinity,
                        horizontalPadding: 0,
                        verticalPadding: 0,
                      );
                    }

                    final rowChildren = <Widget>[
                      if (showConversationPane) ...[
                        SizedBox(
                          width: sessionPaneWidth,
                          child: _buildSessionPanel(
                            closeOnSelect: false,
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
                        _buildPaneDivider(),
                      ],
                      if (showDesktopFilePane) ...[
                        SizedBox(
                          width: _desktopFilePaneWidth,
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
                        _buildPaneDivider(),
                      ],
                      Expanded(
                        child: _buildChatContent(
                          chatProvider: chatProvider,
                          maxContentWidth: mainContentWidth,
                          horizontalPadding: 12,
                          verticalPadding: 2,
                        ),
                      ),
                      if (showDesktopUtilityPane) ...[
                        _buildPaneDivider(),
                        SizedBox(
                          width: _largeDesktopUtilityPaneWidth,
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
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: rowChildren,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<({String shortcut, String description})> _desktopShortcutHints(
    SettingsProvider settingsProvider,
  ) {
    final entries = <({ShortcutAction action, String description})>[
      (action: ShortcutAction.newChat, description: 'New conversation'),
      if (!FeatureFlags.refreshlessRealtime)
        (action: ShortcutAction.refresh, description: 'Refresh chat data'),
      (action: ShortcutAction.focusInput, description: 'Focus message input'),
      (action: ShortcutAction.quickOpen, description: 'Quick open files'),
      (action: ShortcutAction.openSettings, description: 'Open settings'),
      (
        action: ShortcutAction.cycleRecentModels,
        description: 'Cycle recent models',
      ),
      (action: ShortcutAction.cycleVariant, description: 'Cycle model variant'),
      (action: ShortcutAction.cycleAgentForward, description: 'Next agent'),
      (
        action: ShortcutAction.cycleAgentBackward,
        description: 'Previous agent',
      ),
      (
        action: ShortcutAction.escape,
        description: 'Focus input (or close drawer when open)',
      ),
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
    final sizeClass = context.windowSizeClass;
    return sizeClass.isCompact || sizeClass == WindowSizeClass.medium;
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

  String get id =>
      '${compactionId}_${startMessageId}_${endMessageId}_${createdAt.millisecondsSinceEpoch}';
}

class _TimelineRetryIndicatorEntry extends _TimelineEntry {
  const _TimelineRetryIndicatorEntry();

  @override
  String get key => 'timeline_retry_indicator';
}

enum _AssistantProgressStage { thinking, receiving, retrying }

enum _ComposerStatusType {
  dynamicReasoning,
  receiving,
  thinking,
  stopHint,
  tip,
}

class _ComposerStatusPresentation {
  const _ComposerStatusPresentation._({
    required this.type,
    required this.label,
  });

  const _ComposerStatusPresentation.dynamicReasoning(String label)
    : this._(type: _ComposerStatusType.dynamicReasoning, label: label);

  const _ComposerStatusPresentation.receiving()
    : this._(type: _ComposerStatusType.receiving, label: 'Reasoning...');

  const _ComposerStatusPresentation.thinking()
    : this._(type: _ComposerStatusType.thinking, label: 'Thinking...');

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _ComposerStatusPresentation &&
        other.type == type &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(type, label);
}

class _ComposerStatusLanternText extends StatefulWidget {
  const _ComposerStatusLanternText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

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
    )..repeat();
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
      if (_controller.isAnimating) {
        _controller.stop();
      }
      return textWidget;
    }

    if (!_controller.isAnimating) {
      _controller.repeat();
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
        final center = ((_controller.value * 1.8) - 0.4).clamp(0.0, 1.0);
        final left = (center - 0.16).clamp(0.0, 1.0);
        final innerLeft = (center - 0.06).clamp(0.0, 1.0);
        final innerRight = (center + 0.06).clamp(0.0, 1.0);
        final right = (center + 0.16).clamp(0.0, 1.0);

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
                      'Workspace creation requires a Git repository directory.',
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
