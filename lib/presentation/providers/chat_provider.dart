import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/feature_flags.dart';
import '../../core/errors/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/app_local_datasource.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_realtime_model.dart';
import '../../data/models/chat_session_model.dart';
import '../../domain/entities/agent.dart';
import '../../domain/entities/chat_composer_draft.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_realtime.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/provider.dart';
import '../../domain/usecases/abort_chat_session.dart';
import '../../domain/usecases/create_chat_session.dart';
import '../../domain/usecases/delete_chat_session.dart';
import '../../domain/usecases/fork_chat_session.dart';
import '../../domain/usecases/get_agents.dart';
import '../../domain/usecases/get_chat_message.dart';
import '../../domain/usecases/get_chat_messages.dart';
import '../../domain/usecases/get_chat_sessions.dart';
import '../../domain/usecases/get_providers.dart';
import '../../domain/usecases/get_session_children.dart';
import '../../domain/usecases/get_session_diff.dart';
import '../../domain/usecases/get_session_status.dart';
import '../../domain/usecases/get_session_todo.dart';
import '../../domain/usecases/list_pending_permissions.dart';
import '../../domain/usecases/list_pending_questions.dart';
import '../../domain/usecases/reject_question.dart';
import '../../domain/usecases/reply_permission.dart';
import '../../domain/usecases/reply_question.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../../domain/usecases/share_chat_session.dart';
import '../../domain/usecases/summarize_chat_session.dart';
import '../../domain/usecases/unshare_chat_session.dart';
import '../../domain/usecases/update_chat_session.dart';
import '../../domain/usecases/watch_chat_events.dart';
import '../../domain/usecases/watch_global_chat_events.dart';
import '../services/chat_title_generator.dart';
import '../services/event_feedback_dispatcher.dart';
import '../utils/session_title_formatter.dart';
import 'project_provider.dart';
import 'settings_provider.dart';

part 'chat_provider_draft_part.dart';
part 'chat_provider_types_part.dart';
part 'chat_provider/chat_provider_error_policy.dart';
part 'chat_provider/chat_provider_selection_sync_ops.dart';
part 'chat_provider/chat_provider_context_state_ops.dart';
part 'chat_provider/chat_provider_preference_ops.dart';
part 'chat_provider/chat_provider_realtime_ops.dart';
part 'chat_provider/chat_provider_event_reducer_ops.dart';
part 'chat_provider/chat_provider_auto_title_ops.dart';
part 'chat_provider/chat_provider_message_merge_ops.dart';
part 'chat_provider/chat_provider_session_ops.dart';
part 'chat_provider/chat_provider_core.dart';
part 'chat_provider/chat_provider_abort_policy_ops.dart';
part 'chat_provider/chat_provider_selection_helpers.dart';
part 'chat_provider/chat_provider_realtime_aux_ops.dart';
part 'chat_provider/chat_provider_cache_persistence_ops.dart';
part 'chat_provider/chat_provider_message_state_ops.dart';

/// Chat state
enum ChatState { initial, loading, loaded, error, sending }

enum ChatSyncState { connected, reconnecting, delayed }

enum ChatProvidersRefreshState { idle, loading, ready, failed }

enum _SelectionSyncTransactionPhase {
  idle,
  pendingRemote,
  appliedRemote,
  failed,
}

enum SessionListFilter { active, archived, all }

enum SessionListSort { recent, oldest, title }

enum ChatUiNoticeType { remoteAbort }

/// Chat provider
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required this.sendChatMessage,
    this.abortChatSession,
    this.summarizeChatSession,
    required this.getChatSessions,
    required this.createChatSession,
    required this.getChatMessages,
    required this.getChatMessage,
    required this.getAgents,
    required this.getProviders,
    required this.deleteChatSession,
    required this.updateChatSession,
    required this.shareChatSession,
    required this.unshareChatSession,
    required this.forkChatSession,
    required this.getSessionStatus,
    required this.getSessionChildren,
    required this.getSessionTodo,
    required this.getSessionDiff,
    required this.watchChatEvents,
    required this.watchGlobalChatEvents,
    required this.listPendingPermissions,
    required this.replyPermission,
    required this.listPendingQuestions,
    required this.replyQuestion,
    required this.rejectQuestion,
    required this.projectProvider,
    required this.localDataSource,
    this.settingsProvider,
    this.dioClient,
    this.eventFeedbackDispatcher,
    this.titleGenerator,
    Duration syncSignalStaleThreshold = const Duration(seconds: 20),
    Duration syncHealthCheckInterval = const Duration(seconds: 5),
    Duration degradedPollingInterval = const Duration(seconds: 30),
    Duration foregroundResumeSyncIndicatorDuration = const Duration(
      seconds: 12,
    ),
    int foregroundResumeSyncIndicatorMaxCycles = 5,
    int degradedFailureThreshold = 3,
    bool refreshlessRealtimeEnabled = FeatureFlags.refreshlessRealtime,
    Duration abortSuppressionWindow = const Duration(seconds: 8),
  }) {
    _syncSignalStaleThreshold = syncSignalStaleThreshold;
    _syncHealthCheckInterval = syncHealthCheckInterval;
    _degradedPollingInterval = degradedPollingInterval;
    _foregroundResumeSyncIndicatorDuration =
        foregroundResumeSyncIndicatorDuration;
    _foregroundResumeSyncIndicatorMaxCycles =
        foregroundResumeSyncIndicatorMaxCycles;
    _degradedFailureThreshold = degradedFailureThreshold;
    _refreshlessRealtimeEnabled = refreshlessRealtimeEnabled;
    _abortSuppressionWindow = abortSuppressionWindow;
    _activeContextKey = _composeContextKey(
      _activeServerId,
      _resolveContextScopeId(),
    );
  }

  // Scroll callback
  VoidCallback? _scrollToBottomCallback;

  final SendChatMessage sendChatMessage;
  final AbortChatSession? abortChatSession;
  final SummarizeChatSession? summarizeChatSession;
  final GetChatSessions getChatSessions;
  final CreateChatSession createChatSession;
  final GetChatMessages getChatMessages;
  final GetChatMessage getChatMessage;
  final GetAgents getAgents;
  final GetProviders getProviders;
  final DeleteChatSession deleteChatSession;
  final UpdateChatSession updateChatSession;
  final ShareChatSession shareChatSession;
  final UnshareChatSession unshareChatSession;
  final ForkChatSession forkChatSession;
  final GetSessionStatus getSessionStatus;
  final GetSessionChildren getSessionChildren;
  final GetSessionTodo getSessionTodo;
  final GetSessionDiff getSessionDiff;
  final WatchChatEvents watchChatEvents;
  final WatchGlobalChatEvents watchGlobalChatEvents;
  final ListPendingPermissions listPendingPermissions;
  final ReplyPermission replyPermission;
  final ListPendingQuestions listPendingQuestions;
  final ReplyQuestion replyQuestion;
  final RejectQuestion rejectQuestion;
  final ProjectProvider projectProvider;
  final AppLocalDataSource localDataSource;
  final SettingsProvider? settingsProvider;
  final DioClient? dioClient;
  final EventFeedbackDispatcher? eventFeedbackDispatcher;
  final ChatTitleGenerator? titleGenerator;

  ChatState _state = ChatState.initial;
  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  List<ChatMessage> _messages = [];
  // Monotonic counter bumped on every _messages mutation so the timeline
  // builder can short-circuit its cache check in O(1) instead of computing
  // Object.hashAll over all messages+parts (O(N*M)) on every build.
  int _messagesVersion = 0;
  // Monotonic counter bumped on every mutation to the four inputs of
  // currentThreadPermissionRequests (_pendingPermissionsBySession,
  // _sessionChildrenById, _sessions, _currentSession) so the getter can
  // short-circuit its BFS traversal + collection allocation in O(1).
  int _threadPermissionsVersion = 0;
  int _cachedThreadPermissionsAtVersion = -1;
  List<ChatPermissionRequest> _cachedThreadPermissionRequests = const [];
  int _cachedChildMapAtVersion = -1;
  Map<String, List<String>> _cachedChildSessionIdsByParent = const {};
  String? _errorMessage;
  StreamSubscription<dynamic>? _messageSubscription;
  StreamSubscription<dynamic>? _eventSubscription;
  StreamSubscription<dynamic>? _globalEventSubscription;
  // Maps preserved stream subscriptions to their originating session ID so
  // the event reducer can check whether a session still has an active stream.
  final Map<StreamSubscription<dynamic>, String>
  _preservedMessageSubscriptions = <StreamSubscription<dynamic>, String>{};
  int _eventStreamGeneration = 0;
  Timer? _globalRefreshDebounce;
  bool _isRespondingInteraction = false;
  Map<String, SessionStatusInfo> _sessionStatusById =
      <String, SessionStatusInfo>{};
  Map<String, List<ChatPermissionRequest>> _pendingPermissionsBySession =
      <String, List<ChatPermissionRequest>>{};
  Map<String, List<ChatQuestionRequest>> _pendingQuestionsBySession =
      <String, List<ChatQuestionRequest>>{};
  Map<String, List<ChatSession>> _sessionChildrenById =
      <String, List<ChatSession>>{};
  Map<String, List<SessionTodo>> _sessionTodoById =
      <String, List<SessionTodo>>{};
  Map<String, List<SessionDiff>> _sessionDiffById =
      <String, List<SessionDiff>>{};
  String _sessionSearchQuery = '';
  SessionListFilter _sessionListFilter = SessionListFilter.active;
  SessionListSort _sessionListSort = SessionListSort.recent;
  int _sessionVisibleLimit = 40;
  bool _isLoadingSessionInsights = false;
  String? _sessionInsightsError;
  final Set<String> _pendingLocalUserMessageIds = <String>{};
  final Set<String> _queuedLocalUserMessageIds = <String>{};
  final Map<String, ListQueue<_QueuedSendEnvelope>> _queuedSendBySessionId =
      <String, ListQueue<_QueuedSendEnvelope>>{};
  final Set<String> _queuedDrainInFlightSessionIds = <String>{};
  final Set<String> _queuedDrainDeferredSessionIds = <String>{};
  final Set<String> _queuedRetryScheduledSessionIds = <String>{};
  int _localMessageIdSequence = 0;
  bool _activeSessionRefreshInFlight = false;
  bool _isAbortingResponse = false;
  bool _isCompactingContext = false;
  bool _isAppInForeground = true;
  bool _isChatRouteActive = true;
  String? _abortSuppressionSessionId;
  DateTime? _abortSuppressionStartedAt;
  ChatUiNotice? _pendingUiNotice;
  int _messageStreamGeneration = 0;
  String? _activeMessageStreamSessionId;
  ChatComposerDraft? _activeSendDraft;
  _RejectedDraftEnvelope? _rejectedDraft;
  bool _interruptSendInFlight = false;

  // Project and provider-related state
  String? _currentProjectId;
  List<Provider> _providers = [];
  Map<String, String> _defaultModels = {};
  List<Agent> _agents = <Agent>[];
  ChatProvidersRefreshState _providersRefreshState =
      ChatProvidersRefreshState.idle;
  String? _providersRefreshErrorMessage;
  Future<void>? _providersRefreshTask;
  String? _selectedProviderId;
  String? _selectedModelId;
  String? _selectedAgentName;
  String? _selectedVariantId;
  List<String> _recentModelKeys = <String>[];
  List<String> _favoriteModelKeys = <String>[];
  Map<String, int> _modelUsageCounts = <String, int>{};
  Map<String, String> _selectedVariantByModel = <String, String>{};
  String _activeServerId = 'legacy';
  int _providersFetchId = 0;
  int _sessionsFetchId = 0;
  int _messagesFetchId = 0;
  String? _lastSyncedRemoteModelKey;
  String? _lastSyncedRemoteAgentName;
  String? _lastSyncedRemoteVariantKey;
  String? _lastSyncedRemoteSessionOverridesSignature;
  bool _pendingRemoteSelectionSync = false;
  DateTime? _pendingRemoteSelectionSyncSince;
  DateTime? _lastRemoteSelectionSyncAt;
  bool _remoteSelectionSyncInFlight = false;
  _SelectionSyncTransactionPhase _selectionSyncTransactionPhase =
      _SelectionSyncTransactionPhase.idle;
  String _activeContextKey = 'legacy::default';
  final Map<String, _ChatContextSnapshot> _contextSnapshots =
      <String, _ChatContextSnapshot>{};
  final Map<String, _SessionSelectionOverride> _sessionSelectionOverridesByKey =
      <String, _SessionSelectionOverride>{};
  final Set<String> _dirtyContextKeys = <String>{};
  Timer? _syncHealthTimer;
  Timer? _degradedPollingTimer;
  Timer? _foregroundResumeSyncTimer;
  int _foregroundResumeSyncCycleCount = 0;
  DateTime? _lastRealtimeSignalAt;
  ChatSyncState _syncState = ChatSyncState.reconnecting;
  bool _isForegroundActive = true;
  bool _degradedMode = false;
  bool _isForegroundResumeSyncing = false;
  bool _recoverableSyncAlertEscalated = false;
  DateTime? _degradedModeStartedAt;
  int _consecutiveRealtimeFailures = 0;
  bool _pendingRefreshSessions = false;
  bool _pendingRefreshStatus = false;
  bool _pendingRefreshActiveSession = false;
  bool _featureFlagLogged = false;
  final Map<String, String> _pendingRenameTitleBySessionId = <String, String>{};
  final Set<String> _autoTitleConsolidatedSessionIds = <String>{};
  final Map<String, String> _autoTitleLastSignatureBySessionId =
      <String, String>{};
  final Set<String> _autoTitleInFlightSessionIds = <String>{};
  final Set<String> _autoTitleQueuedSessionIds = <String>{};
  late final Duration _syncSignalStaleThreshold;
  late final Duration _syncHealthCheckInterval;
  late final Duration _degradedPollingInterval;
  late final Duration _foregroundResumeSyncIndicatorDuration;
  late final int _foregroundResumeSyncIndicatorMaxCycles;
  late final int _degradedFailureThreshold;
  late final bool _refreshlessRealtimeEnabled;

  // Circular buffer of recent event dedup keys to prevent the global stream
  // from re-processing events already handled by the session stream.
  final Queue<String> _recentEventIds = Queue<String>();
  static const int _maxRecentEventIds = 64;

  static const Duration _sessionsCacheTtl = Duration(days: 3);
  static const Duration _lastSessionSnapshotTtl = Duration(days: 7);
  static const int _maxRecentModels = 8;
  late final Duration _abortSuppressionWindow;
  static const Duration _remoteSelectionSyncThrottle = Duration(seconds: 2);
  static const String _configCodewalkNamespace = 'codewalk';
  static const String _configSelectionKey = 'selection';
  static const String _configVariantByAgentAndModelKey =
      'variantByAgentAndModel';
  static const String _configVariantByModelKey = 'variantByModel';
  static const String _configSessionSelectionsKey = 'sessionSelections';
  static const String _configSyncAgentName = '__codewalk';
  static const String _remoteAutoVariantValue = '__auto__';
  static const String _remoteAbortNoticeMessage =
      'What you want to do different?';
  static const String _remoteAbortInlineErrorName = 'MessageAborted';
  static const Duration _interruptSendStatusPollInterval = Duration(
    milliseconds: 120,
  );
  static const int _interruptSendStatusMaxAttempts = 6;
  static const Duration _interruptSendPostAbortDelay = Duration(
    milliseconds: 120,
  );

  // Microtask coalescing: multiple calls within the same microtask frame
  // result in a single notifyListeners() invocation, reducing rebuild storms
  // during streaming (where 5+ event types fire per tick).
  bool _notifyScheduled = false;

  // Render gate: suppress UI rebuilds while app is in background.
  // SSE data keeps accumulating in internal fields, but widgets won't rebuild
  // until the app returns to foreground and flushes the pending notification.
  bool _hasPendingRenderFlush = false;

  void _notifyListeners() {
    if (!_isForegroundActive) {
      _hasPendingRenderFlush = true;
      return;
    }
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  // Microtask coalescing for scroll-to-bottom: prevents multiple scroll jumps
  // per frame when several events trigger scroll simultaneously.
  bool _scrollScheduled = false;

  void _scheduleScrollToBottom() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    scheduleMicrotask(() {
      _scrollScheduled = false;
      _scrollToBottomCallback?.call();
    });
  }

  // Getters
  ChatState get state => _state;
  List<ChatSession> get sessions => _sessions;
  String get sessionSearchQuery => _sessionSearchQuery;
  SessionListFilter get sessionListFilter => _sessionListFilter;
  SessionListSort get sessionListSort => _sessionListSort;
  bool get isLoadingSessionInsights => _isLoadingSessionInsights;
  String? get sessionInsightsError => _sessionInsightsError;
  ChatSession? get currentSession => _currentSession;
  List<ChatMessage> get messages => _messages;
  int get messagesVersion => _messagesVersion;
  String? get errorMessage => _errorMessage;
  ChatUiNotice? get pendingUiNotice => _pendingUiNotice;
  String? get currentProjectId => _currentProjectId;
  List<Provider> get providers => _providers;
  Map<String, String> get defaultModels => _defaultModels;
  List<Agent> get agents => List<Agent>.unmodifiable(_agents);
  List<Agent> get selectableAgents =>
      List<Agent>.unmodifiable(_sortedSelectableAgents(_agents));
  String? get selectedAgentName => _selectedAgentName;
  String get selectedAgentLabel =>
      _selectedAgentName == null ? 'Select agent' : _selectedAgentName!;
  String? get selectedProviderId => _selectedProviderId;
  String? get selectedModelId => _selectedModelId;
  String? get selectedVariantId => _selectedVariantId;
  List<String> get recentModelKeys =>
      List<String>.unmodifiable(_recentModelKeys);
  List<String> get favoriteModelKeys =>
      List<String>.unmodifiable(_favoriteModelKeys);
  Map<String, int> get modelUsageCounts =>
      Map<String, int>.unmodifiable(_modelUsageCounts);
  String get activeServerId => _activeServerId;
  bool get isRespondingInteraction => _isRespondingInteraction;
  ChatProvidersRefreshState get providersRefreshState => _providersRefreshState;
  String? get providersRefreshErrorMessage => _providersRefreshErrorMessage;
  bool get isProvidersRefreshInProgress =>
      _providersRefreshState == ChatProvidersRefreshState.loading;

  bool isSessionActivelyResponding(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return false;
    }
    final isCurrentSession = _currentSession?.id == normalizedSessionId;
    final hasInProgressAssistant = _messages.whereType<AssistantMessage>().any(
      (message) =>
          message.sessionId == normalizedSessionId && !message.isCompleted,
    );
    final status = _sessionStatusById[normalizedSessionId]?.type;
    final hasBusyStatus =
        status == SessionStatusType.busy || status == SessionStatusType.retry;
    final hasActiveStream =
        _activeMessageStreamSessionId == normalizedSessionId &&
        _messageSubscription != null;

    if (!isCurrentSession) {
      return hasBusyStatus;
    }

    return hasActiveStream || (hasBusyStatus && hasInProgressAssistant);
  }

  bool get isCurrentSessionActivelyResponding {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return false;
    }
    return isSessionActivelyResponding(sessionId);
  }

  ChatSyncState get syncState => _syncState;
  bool get isInDegradedMode => _degradedMode;
  bool get isForegroundResumeSyncing => _isForegroundResumeSyncing;
  bool get isRecoverableSyncAlertEscalated => _recoverableSyncAlertEscalated;
  bool get refreshlessRealtimeEnabled => _refreshlessRealtimeEnabled;
  bool get isAbortingResponse => _isAbortingResponse;
  bool get isCompactingContext => _isCompactingContext;
  Map<String, SessionStatusInfo> get sessionStatusById =>
      Map<String, SessionStatusInfo>.unmodifiable(_sessionStatusById);

  bool get canAbortActiveResponse {
    if (_isAbortingResponse || _currentSession == null) {
      return false;
    }
    return isCurrentSessionActivelyResponding;
  }

  bool isQueuedUserMessage(String messageId) {
    final normalizedMessageId = messageId.trim();
    if (normalizedMessageId.isEmpty) {
      return false;
    }
    return _queuedLocalUserMessageIds.contains(normalizedMessageId);
  }

  int queuedMessageCountForSession(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return 0;
    }
    return _queuedSendBySessionId[normalizedSessionId]?.length ?? 0;
  }

  int get currentSessionQueuedMessageCount {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return 0;
    }
    return queuedMessageCountForSession(sessionId);
  }

  ListQueue<_QueuedSendEnvelope> _queueForSession(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return ListQueue<_QueuedSendEnvelope>();
    }
    return _queuedSendBySessionId.putIfAbsent(
      normalizedSessionId,
      ListQueue<_QueuedSendEnvelope>.new,
    );
  }

  void _syncQueuedLocalUserMessageIds() {
    _queuedLocalUserMessageIds.clear();
    _queuedLocalUserMessageIds.addAll(
      _queuedSendBySessionId.values.expand(
        (queue) => queue.map((item) => item.localMessageId),
      ),
    );
  }

  void _clearQueuedSendState() {
    _queuedSendBySessionId.clear();
    _queuedLocalUserMessageIds.clear();
    _queuedDrainInFlightSessionIds.clear();
    _queuedDrainDeferredSessionIds.clear();
    _queuedRetryScheduledSessionIds.clear();
  }

  String _nextLocalUserMessageId() {
    _localMessageIdSequence += 1;
    return 'local_user_${DateTime.now().microsecondsSinceEpoch}_${_localMessageIdSequence}';
  }

  bool get _isExperimentalMultiDeviceSyncEnabled {
    return settingsProvider?.enableExperimentalMultiDeviceSync ?? false;
  }

  bool get _hasLocalActiveSelectionSyncWork {
    final hasInProgressAssistant = _messages.whereType<AssistantMessage>().any(
      (message) => !message.isCompleted,
    );
    return _state == ChatState.sending ||
        _isAbortingResponse ||
        _messageSubscription != null ||
        hasInProgressAssistant;
  }

  bool get _hasAnyBusySessionStatus {
    for (final status in _sessionStatusById.values) {
      if (status.type == SessionStatusType.busy ||
          status.type == SessionStatusType.retry) {
        return true;
      }
    }
    return false;
  }

  bool get _hasAnyActiveAbortSuppression {
    final sessionId = _abortSuppressionSessionId;
    if (sessionId == null || sessionId.trim().isEmpty) {
      return false;
    }
    return _isAbortSuppressionActiveForSession(sessionId);
  }

  bool get _shouldDeferRemoteSelectionSync {
    if (!_isExperimentalMultiDeviceSyncEnabled) {
      return false;
    }
    if (_hasLocalActiveSelectionSyncWork) {
      return true;
    }
    if (_preservedMessageSubscriptions.isNotEmpty) {
      return true;
    }
    if (_hasAnyActiveAbortSuppression) {
      return true;
    }
    return _hasAnyBusySessionStatus;
  }

  bool get _canFlushPendingRemoteSelectionSync {
    return !_shouldDeferRemoteSelectionSync;
  }

  List<ChatSession> get visibleSessions {
    final query = _sessionSearchQuery.trim().toLowerCase();
    final filtered = _sessions
        .where((session) {
          final archived = session.archived;
          switch (_sessionListFilter) {
            case SessionListFilter.active:
              if (archived) {
                return false;
              }
            case SessionListFilter.archived:
              if (!archived) {
                return false;
              }
            case SessionListFilter.all:
              break;
          }

          if (query.isEmpty) {
            return true;
          }

          final title = (session.title ?? '').toLowerCase();
          final summary = (session.summary ?? '').toLowerCase();
          return title.contains(query) || summary.contains(query);
        })
        .toList(growable: false);

    final sorted = List<ChatSession>.from(filtered)
      ..sort((a, b) {
        switch (_sessionListSort) {
          case SessionListSort.oldest:
            return a.time.compareTo(b.time);
          case SessionListSort.title:
            return (a.title ?? '').toLowerCase().compareTo(
              (b.title ?? '').toLowerCase(),
            );
          case SessionListSort.recent:
            return b.time.compareTo(a.time);
        }
      });

    final limited = sorted.length <= _sessionVisibleLimit
        ? sorted
        : sorted.take(_sessionVisibleLimit).toList(growable: false);

    return _includeVisibleSessionAncestors(
      visibleSessions: limited,
      sortedFilteredSessions: sorted,
    );
  }

  List<ChatSession> _includeVisibleSessionAncestors({
    required List<ChatSession> visibleSessions,
    required List<ChatSession> sortedFilteredSessions,
  }) {
    if (visibleSessions.isEmpty ||
        visibleSessions.length == sortedFilteredSessions.length) {
      return visibleSessions;
    }

    final sessionById = <String, ChatSession>{
      for (final session in sortedFilteredSessions) session.id: session,
    };
    final visibleIds = visibleSessions.map((session) => session.id).toSet();

    for (final session in visibleSessions) {
      var parentId = session.parentId;
      final visited = <String>{session.id};
      while (parentId != null && parentId.isNotEmpty) {
        if (!visited.add(parentId)) {
          break;
        }
        final parent = sessionById[parentId];
        if (parent == null) {
          break;
        }
        visibleIds.add(parent.id);
        parentId = parent.parentId;
      }
    }

    if (visibleIds.length == visibleSessions.length) {
      return visibleSessions;
    }

    return sortedFilteredSessions
        .where((session) => visibleIds.contains(session.id))
        .toList(growable: false);
  }

  bool get canLoadMoreSessions {
    final query = _sessionSearchQuery.trim().toLowerCase();
    final total = _sessions.where((session) {
      final archived = session.archived;
      switch (_sessionListFilter) {
        case SessionListFilter.active:
          if (archived) {
            return false;
          }
        case SessionListFilter.archived:
          if (!archived) {
            return false;
          }
        case SessionListFilter.all:
          break;
      }
      if (query.isEmpty) {
        return true;
      }
      final title = (session.title ?? '').toLowerCase();
      final summary = (session.summary ?? '').toLowerCase();
      return title.contains(query) || summary.contains(query);
    }).length;
    return total > visibleSessions.length;
  }

  SessionStatusInfo? get currentSessionStatus {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return null;
    }
    return _sessionStatusById[sessionId];
  }

  List<ChatPermissionRequest> get currentSessionPermissions {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return const <ChatPermissionRequest>[];
    }
    return List<ChatPermissionRequest>.unmodifiable(
      _pendingPermissionsBySession[sessionId] ??
          const <ChatPermissionRequest>[],
    );
  }

  List<ChatQuestionRequest> get currentSessionQuestions {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return const <ChatQuestionRequest>[];
    }
    return List<ChatQuestionRequest>.unmodifiable(
      _pendingQuestionsBySession[sessionId] ?? const <ChatQuestionRequest>[],
    );
  }

  ChatPermissionRequest? get currentPermissionRequest =>
      currentSessionPermissions.firstOrNull;
  ChatQuestionRequest? get currentQuestionRequest =>
      currentSessionQuestions.firstOrNull;

  List<ChatPermissionRequest> get currentThreadPermissionRequests {
    if (_cachedThreadPermissionsAtVersion == _threadPermissionsVersion) {
      return _cachedThreadPermissionRequests;
    }

    final currentSessionId = _currentSession?.id;
    if (currentSessionId == null || currentSessionId.isEmpty) {
      _cachedThreadPermissionsAtVersion = _threadPermissionsVersion;
      _cachedThreadPermissionRequests = const <ChatPermissionRequest>[];
      return _cachedThreadPermissionRequests;
    }

    final orderedSessionIds = <String>[
      currentSessionId,
      ..._orderedCurrentSessionDescendantIds(),
    ];
    final seenRequestIds = <String>{};
    final collected = <ChatPermissionRequest>[];

    for (final sessionId in orderedSessionIds) {
      final sessionRequests = _pendingPermissionsBySession[sessionId];
      if (sessionRequests == null || sessionRequests.isEmpty) {
        continue;
      }
      for (final request in sessionRequests) {
        if (seenRequestIds.add(request.id)) {
          collected.add(request);
        }
      }
    }

    _cachedThreadPermissionsAtVersion = _threadPermissionsVersion;
    _cachedThreadPermissionRequests = List<ChatPermissionRequest>.unmodifiable(
      collected,
    );
    return _cachedThreadPermissionRequests;
  }

  List<String> _orderedCurrentSessionDescendantIds() {
    final currentSessionId = _currentSession?.id;
    if (currentSessionId == null || currentSessionId.isEmpty) {
      return const <String>[];
    }

    final childIdsByParent = _childSessionIdsByParent();
    if (childIdsByParent.isEmpty) {
      return const <String>[];
    }

    final visited = <String>{currentSessionId};
    final orderedDescendants = <String>[];
    final queue = ListQueue<String>()..add(currentSessionId);

    while (queue.isNotEmpty) {
      final parentId = queue.removeFirst();
      final childIds = childIdsByParent[parentId] ?? const <String>[];
      for (final childId in childIds) {
        if (!visited.add(childId)) {
          continue;
        }
        orderedDescendants.add(childId);
        queue.add(childId);
      }
    }

    return orderedDescendants;
  }

  Map<String, List<String>> _childSessionIdsByParent() {
    if (_cachedChildMapAtVersion == _threadPermissionsVersion) {
      return _cachedChildSessionIdsByParent;
    }

    final output = <String, List<String>>{};

    void appendChild({required String parentId, required String childId}) {
      if (parentId.isEmpty || childId.isEmpty || parentId == childId) {
        return;
      }
      final children = output.putIfAbsent(parentId, () => <String>[]);
      if (!children.contains(childId)) {
        children.add(childId);
      }
    }

    for (final session in _sessions) {
      final parentId = session.parentId?.trim();
      if (parentId == null || parentId.isEmpty) {
        continue;
      }
      appendChild(parentId: parentId, childId: session.id);
    }

    for (final entry in _sessionChildrenById.entries) {
      final parentId = entry.key.trim();
      if (parentId.isEmpty) {
        continue;
      }
      for (final child in entry.value) {
        appendChild(parentId: parentId, childId: child.id);
      }
    }

    _cachedChildMapAtVersion = _threadPermissionsVersion;
    _cachedChildSessionIdsByParent = output;
    return output;
  }

  List<ChatSession> get currentSessionChildren {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return const <ChatSession>[];
    }
    return List<ChatSession>.unmodifiable(
      _sessionChildrenById[sessionId] ?? const <ChatSession>[],
    );
  }

  List<SessionTodo> get currentSessionTodo {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return const <SessionTodo>[];
    }
    return List<SessionTodo>.unmodifiable(
      _sessionTodoById[sessionId] ?? const <SessionTodo>[],
    );
  }

  List<SessionDiff> get currentSessionDiff {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return const <SessionDiff>[];
    }
    return List<SessionDiff>.unmodifiable(
      _sessionDiffById[sessionId] ?? const <SessionDiff>[],
    );
  }

  Provider? get selectedProvider {
    final selectedId = _selectedProviderId;
    if (selectedId == null) {
      return null;
    }
    return _providers
        .where((provider) => provider.id == selectedId)
        .firstOrNull;
  }

  Model? get selectedModel {
    final provider = selectedProvider;
    final modelId = _selectedModelId;
    if (provider == null || modelId == null) {
      return null;
    }
    return provider.models[modelId];
  }

  List<ModelVariant> get availableVariants =>
      selectedModel?.variants.values.toList(growable: false) ??
      const <ModelVariant>[];

  String get selectedVariantLabel {
    final selected = _selectedVariantId;
    if (selected == null) {
      return 'Auto';
    }
    final variant = selectedModel?.variants[selected];
    return variant?.name ?? selected;
  }

  /// Set scroll-to-bottom callback
  void setScrollToBottomCallback(VoidCallback? callback) {
    _scrollToBottomCallback = callback;
  }

  /// Set state

  /// Set error

  ChatUiNotice? consumePendingUiNotice() {
    final notice = _pendingUiNotice;
    _pendingUiNotice = null;
    return notice;
  }

  ChatComposerDraft? consumeRejectedDraft({String? sessionId}) {
    final rejectedDraft = _rejectedDraft;
    if (rejectedDraft == null || !rejectedDraft.draft.hasContent) {
      _clearRejectedDraft();
      return null;
    }

    final expectedSessionId = sessionId?.trim();
    final draftSessionId = rejectedDraft.sessionId.trim();
    if (expectedSessionId != null &&
        expectedSessionId.isNotEmpty &&
        expectedSessionId != draftSessionId) {
      return null;
    }

    _clearRejectedDraft();
    return rejectedDraft.draft;
  }

  void setSessionSearchQuery(String query) {
    final normalized = query.trim();
    if (_sessionSearchQuery == normalized) {
      return;
    }
    _sessionSearchQuery = normalized;
    _sessionVisibleLimit = 40;
    notifyListeners();
  }

  void setSessionListFilter(SessionListFilter filter) {
    if (_sessionListFilter == filter) {
      return;
    }
    _sessionListFilter = filter;
    _sessionVisibleLimit = 40;
    notifyListeners();
  }

  void setSessionListSort(SessionListSort sort) {
    if (_sessionListSort == sort) {
      return;
    }
    _sessionListSort = sort;
    _sortSessionsInPlace();
    _sessionVisibleLimit = 40;
    notifyListeners();
  }

  void loadMoreSessions() {
    _sessionVisibleLimit += 40;
    notifyListeners();
  }

  Future<void> setForegroundActive(bool isActive) async {
    final wasActive = _isForegroundActive;
    _isForegroundActive = isActive;
    if (!isActive) {
      _clearRejectedDraft();
      _stopForegroundResumeSyncIndicator(reason: 'background');
    }

    if (isActive && _hasPendingRenderFlush) {
      // Flush accumulated state changes suppressed while in background.
      _hasPendingRenderFlush = false;
      _notifyListeners();
    }

    if (!_refreshlessRealtimeEnabled) {
      return;
    }

    if (!isActive) {
      // Pause health/degraded timers (UI-only concerns) but keep SSE alive
      // so data accumulates in internal fields for flush on foreground return.
      _syncHealthTimer?.cancel();
      _syncHealthTimer = null;
      _degradedPollingTimer?.cancel();
      _degradedPollingTimer = null;
      _degradedMode = false;
      _degradedModeStartedAt = null;
      return;
    }

    if (!wasActive) {
      _startForegroundResumeSyncIndicator(reason: 'foreground');
    }

    _startSyncHealthMonitor();
    await _resumeRealtimeAfterForeground();
  }

  void setAppInForeground(bool isForeground) {
    _isAppInForeground = isForeground;
    if (!isForeground) {
      _clearRejectedDraft();
    }
  }

  void setChatRouteActive(bool isActive) {
    _isChatRouteActive = isActive;
    if (!isActive) {
      _clearRejectedDraft();
    }
  }

  /// Returns true if [event] belongs to an ephemeral title-generation session.
  /// Checks both the session ID set and the session title as fallback
  /// (the title is known before the POST /session response arrives,
  /// but SSE events may arrive before the ID is added to the set).

  Future<void> refreshActiveSessionView({
    String reason = 'manual',
    bool includeStatus = true,
  }) async {
    final session = _currentSession;
    if (session == null) {
      return;
    }
    // During abort suppression, polling already delivered fresh data.
    // Loading from server risks showing stale abort content that the
    // suppression window is designed to hide.
    if (_isAbortSuppressionActiveForSession(session.id)) {
      AppLogger.info(
        'Skipping active session refresh during abort suppression session=${session.id} reason=$reason',
      );
      return;
    }
    if (_activeSessionRefreshInFlight) {
      return;
    }

    _activeSessionRefreshInFlight = true;
    AppLogger.debug(
      'Refreshing active session view reason=$reason session=${session.id}',
    );

    try {
      final messagesResult = await getChatMessages(
        GetChatMessagesParams(
          projectId: projectProvider.currentProjectId,
          sessionId: session.id,
          directory: projectProvider.currentDirectory,
        ),
      );

      messagesResult.fold(
        (failure) {
          AppLogger.warn(
            'Failed to refresh active session messages for ${session.id}: $failure',
          );
        },
        (messages) {
          if (_currentSession?.id != session.id) {
            return;
          }
          _messages = _mergeServerMessagesWithActiveLocalTail(
            messages,
            sessionId: session.id,
          );
          _messagesVersion++;
          _prunePendingLocalUserMessageIdsToVisibleUsers();
          _pruneQueuedLocalUserMessageIdsToVisibleUsers();
          notifyListeners();
          _scheduleAutoTitleRefresh(session.id);
          if (!_isCompactingContext) {
            _scheduleScrollToBottom();
          }
        },
      );

      if (includeStatus) {
        await refreshSessionStatusSnapshot();
      }
    } finally {
      _activeSessionRefreshInFlight = false;
    }
  }

  Future<void> refreshSessionStatusSnapshot({bool silent = true}) async {
    final result = await getSessionStatus(
      GetSessionStatusParams(directory: projectProvider.currentDirectory),
    );
    result.fold(
      (failure) {
        if (!silent) {
          _sessionInsightsError = 'Failed to load session status';
          notifyListeners();
        }
        AppLogger.warn('Failed to load session status snapshot: $failure');
      },
      (statusMap) {
        // Remove ephemeral title-generation sessions from the status map.
        statusMap.removeWhere(
          (id, _) => ChatTitleGenerator.ephemeralSessionIds.contains(id),
        );
        _sessionStatusById = statusMap;
        if (!silent) {
          _sessionInsightsError = null;
        }
        notifyListeners();
      },
    );
  }

  Future<Either<Failure, T>> _runSessionInsightRequest<T>({
    required String requestName,
    required Future<Either<Failure, T>> Function() request,
  }) async {
    try {
      return await request();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected exception while loading session $requestName',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        UnknownFailure('Unexpected error while loading session $requestName'),
      );
    }
  }

  Future<void> loadSessionInsights(
    String sessionId, {
    String? messageId,
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoadingSessionInsights = true;
      _sessionInsightsError = null;
      notifyListeners();
    }

    try {
      final directory = projectProvider.currentDirectory;
      final projectId = projectProvider.currentProjectId;

      // Launch all 4 independent calls concurrently.
      final childrenFuture = _runSessionInsightRequest(
        requestName: 'children',
        request: () => getSessionChildren(
          GetSessionChildrenParams(
            projectId: projectId,
            sessionId: sessionId,
            directory: directory,
          ),
        ),
      );
      final todoFuture = _runSessionInsightRequest(
        requestName: 'todo',
        request: () => getSessionTodo(
          GetSessionTodoParams(
            projectId: projectId,
            sessionId: sessionId,
            directory: directory,
          ),
        ),
      );
      final diffFuture = _runSessionInsightRequest(
        requestName: 'diff',
        request: () => getSessionDiff(
          GetSessionDiffParams(
            projectId: projectId,
            sessionId: sessionId,
            messageId: messageId,
            directory: directory,
          ),
        ),
      );
      final statusFuture = _runSessionInsightRequest(
        requestName: 'status',
        request: () =>
            getSessionStatus(GetSessionStatusParams(directory: directory)),
      );

      // Await all results (futures already running in parallel).
      final childrenResult = await childrenFuture;
      final todoResult = await todoFuture;
      final diffResult = await diffFuture;
      final statusResult = await statusFuture;

      childrenResult.fold(
        (failure) {
          AppLogger.warn(
            'Failed to load session children for $sessionId: $failure',
          );
        },
        (children) {
          _sessionChildrenById[sessionId] = children;
          _threadPermissionsVersion++;
        },
      );

      todoResult.fold(
        (failure) {
          AppLogger.warn(
            'Failed to load session todo for $sessionId: $failure',
          );
        },
        (todos) {
          _sessionTodoById[sessionId] = todos;
        },
      );

      diffResult.fold(
        (failure) {
          AppLogger.warn(
            'Failed to load session diff for $sessionId: $failure',
          );
        },
        (diff) {
          _sessionDiffById[sessionId] = diff;
        },
      );

      statusResult.fold(
        (failure) {
          AppLogger.warn('Failed to refresh status for $sessionId: $failure');
          if (!silent) {
            _sessionInsightsError = 'Some session details could not be loaded';
          }
        },
        (statusMap) {
          statusMap.removeWhere(
            (id, _) => ChatTitleGenerator.ephemeralSessionIds.contains(id),
          );
          _sessionStatusById = statusMap;
        },
      );
    } finally {
      if (!silent) {
        _isLoadingSessionInsights = false;
      }
      notifyListeners();
    }
  }

  Future<void> respondPermissionRequest({
    required String requestId,
    required String reply,
    String? message,
  }) async {
    if (_isRespondingInteraction) {
      return;
    }
    _isRespondingInteraction = true;
    notifyListeners();
    final result = await replyPermission(
      ReplyPermissionParams(
        requestId: requestId,
        reply: reply,
        message: message,
        directory: projectProvider.currentDirectory,
      ),
    );
    _isRespondingInteraction = false;
    result.fold(_handleFailure, (_) {
      for (final sessionId in _pendingPermissionsBySession.keys.toList()) {
        final filtered = _pendingPermissionsBySession[sessionId]!
            .where((item) => item.id != requestId)
            .toList(growable: false);
        if (filtered.isEmpty) {
          _pendingPermissionsBySession.remove(sessionId);
        } else {
          _pendingPermissionsBySession[sessionId] = filtered;
        }
      }
      _threadPermissionsVersion++;
    });
    notifyListeners();
  }

  Future<void> submitQuestionAnswers({
    required String requestId,
    required List<List<String>> answers,
  }) async {
    if (_isRespondingInteraction) {
      return;
    }
    _isRespondingInteraction = true;
    notifyListeners();
    final result = await replyQuestion(
      ReplyQuestionParams(
        requestId: requestId,
        answers: answers,
        directory: projectProvider.currentDirectory,
      ),
    );
    _isRespondingInteraction = false;
    result.fold(_handleFailure, (_) {
      for (final sessionId in _pendingQuestionsBySession.keys.toList()) {
        final filtered = _pendingQuestionsBySession[sessionId]!
            .where((item) => item.id != requestId)
            .toList(growable: false);
        if (filtered.isEmpty) {
          _pendingQuestionsBySession.remove(sessionId);
        } else {
          _pendingQuestionsBySession[sessionId] = filtered;
        }
      }
    });
    notifyListeners();
  }

  Future<void> rejectQuestionRequest({required String requestId}) async {
    if (_isRespondingInteraction) {
      return;
    }
    _isRespondingInteraction = true;
    notifyListeners();
    final result = await rejectQuestion(
      RejectQuestionParams(
        requestId: requestId,
        directory: projectProvider.currentDirectory,
      ),
    );
    _isRespondingInteraction = false;
    result.fold(_handleFailure, (_) {
      for (final sessionId in _pendingQuestionsBySession.keys.toList()) {
        final filtered = _pendingQuestionsBySession[sessionId]!
            .where((item) => item.id != requestId)
            .toList(growable: false);
        if (filtered.isEmpty) {
          _pendingQuestionsBySession.remove(sessionId);
        } else {
          _pendingQuestionsBySession[sessionId] = filtered;
        }
      }
    });
    notifyListeners();
  }

  void warmupProvidersRefresh({String reason = 'startup'}) {
    AppLogger.info('providers_refresh_warmup reason=$reason');
    unawaited(initializeProviders());
  }

  Future<void> retryProvidersRefresh() async {
    AppLogger.info('providers_refresh_retry');
    await initializeProviders();
  }

  /// Initialize providers
  Future<void> initializeProviders() async {
    final inFlight = _providersRefreshTask;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final task = _initializeProvidersInternal();
    _providersRefreshTask = task;
    try {
      await task;
    } finally {
      if (identical(_providersRefreshTask, task)) {
        _providersRefreshTask = null;
      }
    }
  }

  String _resolveContextScopeId() {
    return projectProvider.currentDirectory ?? projectProvider.currentProjectId;
  }

  Future<String> _resolveServerScopeId() async {
    final stored = await localDataSource.getActiveServerId();
    if (stored != null && stored.isNotEmpty) {
      _activeServerId = stored;
      _activeContextKey = _composeContextKey(
        _activeServerId,
        _resolveContextScopeId(),
      );
      return stored;
    }
    _activeServerId = 'legacy';
    _activeContextKey = _composeContextKey(
      _activeServerId,
      _resolveContextScopeId(),
    );
    return 'legacy';
  }

  Future<void> onProjectScopeChanged() async {
    await _switchContext(reason: 'project');
  }

  /// Reset provider state and reload server-scoped data.
  Future<void> onServerScopeChanged() async {
    await _switchContext(reason: 'server');
  }

  Future<void> _persistSelection({bool syncRemote = true}) async {
    final serverId = await _resolveServerScopeId();
    final scopeId = _resolveContextScopeId();
    if (_selectedProviderId != null) {
      await localDataSource.saveSelectedProvider(
        _selectedProviderId!,
        serverId: serverId,
        scopeId: scopeId,
      );
    }
    if (_selectedModelId != null) {
      await localDataSource.saveSelectedModel(
        _selectedModelId!,
        serverId: serverId,
        scopeId: scopeId,
      );
    }
    await localDataSource.saveSelectedAgent(
      _selectedAgentName,
      serverId: serverId,
      scopeId: scopeId,
    );
    await _persistModelPreferenceState(serverId: serverId, scopeId: scopeId);
    await _persistSessionSelectionOverridesState(
      serverId: serverId,
      scopeId: scopeId,
    );
    if (syncRemote) {
      if (!_isExperimentalMultiDeviceSyncEnabled) {
        _pendingRemoteSelectionSync = false;
        _pendingRemoteSelectionSyncSince = null;
        _setSelectionSyncTransactionPhase(
          _SelectionSyncTransactionPhase.idle,
          reason: 'sync-disabled',
        );
        return;
      }
      if (_shouldDeferRemoteSelectionSync) {
        _markPendingRemoteSelectionSync(reason: 'active-response');
      } else {
        _pendingRemoteSelectionSync = false;
        _pendingRemoteSelectionSyncSince = null;
        _setSelectionSyncTransactionPhase(
          _SelectionSyncTransactionPhase.pendingRemote,
          reason: 'immediate-sync',
        );
        await _runSelectionSyncTransaction(reason: 'immediate-sync');
      }
    }
  }

  Future<void> setSelectedProvider(String providerId) async {
    final provider = _providers.where((p) => p.id == providerId).firstOrNull;
    if (provider == null) {
      return;
    }
    _selectedProviderId = provider.id;

    String? nextModelId;
    if (_selectedModelId != null &&
        provider.models.containsKey(_selectedModelId)) {
      nextModelId = _selectedModelId;
    }

    if (nextModelId == null) {
      for (final recentModelKey in _recentModelKeys) {
        final recentProviderId = _providerFromModelKey(recentModelKey);
        final recentModelId = _modelFromModelKey(recentModelKey);
        if (recentProviderId == provider.id &&
            recentModelId != null &&
            provider.models.containsKey(recentModelId)) {
          nextModelId = recentModelId;
          break;
        }
      }
    }

    if (nextModelId == null) {
      final defaultModelId = _defaultModels[provider.id];
      if (defaultModelId != null &&
          provider.models.containsKey(defaultModelId)) {
        nextModelId = defaultModelId;
      }
    }

    nextModelId ??= provider.models.keys.firstOrNull;
    _selectedModelId = nextModelId;
    _selectedVariantId = _resolveStoredVariantForSelection();
    _storeCurrentSessionSelectionOverride();
    await _persistSelection();
    notifyListeners();
  }

  Future<void> setSelectedModelByProvider({
    required String providerId,
    required String modelId,
  }) async {
    final provider = _providers.where((p) => p.id == providerId).firstOrNull;
    if (provider == null || !provider.models.containsKey(modelId)) {
      return;
    }
    _selectedProviderId = providerId;
    _selectedModelId = modelId;
    _selectedVariantId = _resolveStoredVariantForSelection();
    _storeCurrentSessionSelectionOverride();
    notifyListeners();
    await _persistSelection();
  }

  Future<void> setSelectedModel(String modelId) async {
    final provider = selectedProvider;
    if (provider == null || !provider.models.containsKey(modelId)) {
      return;
    }
    await setSelectedModelByProvider(providerId: provider.id, modelId: modelId);
  }

  Future<void> setSelectedAgent(String agentName) async {
    final candidate = agentName.trim();
    if (candidate.isEmpty) {
      return;
    }
    final next = _resolvePreferredAgentName(_agents, candidate);
    if (next == null) {
      return;
    }
    if (_selectedAgentName == next) {
      return;
    }
    _selectedAgentName = next;
    _storeCurrentSessionSelectionOverride();
    notifyListeners();
    await _persistSelection();
  }

  Future<void> setSelectedVariant(String? variantId) async {
    final providerId = _selectedProviderId;
    final modelId = _selectedModelId;
    final model = selectedModel;
    if (providerId == null || modelId == null || model == null) {
      return;
    }

    final modelKey = _modelKey(providerId, modelId);
    if (variantId == null || variantId.trim().isEmpty) {
      _selectedVariantId = null;
      _selectedVariantByModel.remove(modelKey);
    } else if (model.variants.containsKey(variantId)) {
      _selectedVariantId = variantId;
      _selectedVariantByModel[modelKey] = variantId;
    } else {
      _selectedVariantId = null;
      _selectedVariantByModel.remove(modelKey);
    }

    _storeCurrentSessionSelectionOverride();
    await _persistSelection();
    notifyListeners();
  }

  Future<void> cycleVariant() async {
    final model = selectedModel;
    if (model == null || model.variants.isEmpty) {
      return;
    }
    final variantIds = model.variants.keys.toList(growable: false);
    final selectedVariant = _selectedVariantId;
    if (selectedVariant == null) {
      await setSelectedVariant(variantIds.first);
      return;
    }
    final currentIndex = variantIds.indexOf(selectedVariant);
    if (currentIndex == -1 || currentIndex >= variantIds.length - 1) {
      await setSelectedVariant(null);
      return;
    }
    await setSelectedVariant(variantIds[currentIndex + 1]);
  }

  /// Cycle to the next (or previous) selectable agent.
  /// Returns the name of the newly selected agent, or null when the list
  /// is empty and no cycling was performed.
  Future<String?> cycleAgent({bool reverse = false}) async {
    final available = selectableAgents;
    if (available.isEmpty) {
      return null;
    }

    final selected = _selectedAgentName;
    if (selected == null) {
      await setSelectedAgent(available.first.name);
      return available.first.name;
    }

    final currentIndex = available.indexWhere(
      (agent) => agent.name == selected,
    );
    if (currentIndex == -1) {
      await setSelectedAgent(available.first.name);
      return available.first.name;
    }

    final delta = reverse ? -1 : 1;
    final nextIndex =
        (currentIndex + delta + available.length) % available.length;
    final nextName = available[nextIndex].name;
    await setSelectedAgent(nextName);
    return nextName;
  }

  bool isModelFavorite({required String providerId, required String modelId}) {
    return _favoriteModelKeys.contains(_modelKey(providerId, modelId));
  }

  /// Toggle a model as favorite (local-only, no remote sync).
  Future<void> toggleModelFavorite({
    required String providerId,
    required String modelId,
  }) async {
    final key = _modelKey(providerId, modelId);
    _favoriteModelKeys = List<String>.from(_favoriteModelKeys);
    if (_favoriteModelKeys.contains(key)) {
      _favoriteModelKeys.remove(key);
    } else {
      _favoriteModelKeys.add(key);
    }
    final serverId = await _resolveServerScopeId();
    final scopeId = _resolveContextScopeId();
    await _persistModelPreferenceState(serverId: serverId, scopeId: scopeId);
    notifyListeners();
  }

  /// Load session list
  Future<void> loadSessions() async {
    if (_state == ChatState.loading) return;
    final fetchId = ++_sessionsFetchId;

    _setState(ChatState.loading);
    clearError();

    final serverId = await _resolveServerScopeId();
    final scopeId = _resolveContextScopeId();
    final storedSessionId = await localDataSource.getCurrentSessionId(
      serverId: serverId,
      scopeId: scopeId,
    );

    try {
      // First try loading from cache
      await _loadCachedSessions(serverId: serverId, scopeId: scopeId);
      await _restoreLastSessionSnapshotFromCache(
        serverId: serverId,
        scopeId: scopeId,
        preferredSessionId: storedSessionId,
      );

      // Then fetch latest data from server
      final result = await getChatSessions(
        GetChatSessionsParams(directory: projectProvider.currentDirectory),
      );

      if (fetchId != _sessionsFetchId) {
        return;
      }

      if (result.isLeft()) {
        if (fetchId != _sessionsFetchId) {
          return;
        }
        final failure = result.fold((f) => f, (_) => null);
        if (failure != null) {
          _handleFailure(failure);
        }
        return;
      }

      final sessions = result.fold((_) => <ChatSession>[], (value) => value);
      final filteredSessions = _filterSessionsForCurrentContext(sessions);
      if (fetchId != _sessionsFetchId) {
        return;
      }
      _sessions = filteredSessions;
      _threadPermissionsVersion++;
      _sessionVisibleLimit = 40;
      _sortSessionsInPlace();
      _setState(ChatState.loaded);

      await _saveCachedSessions(
        filteredSessions,
        serverId: serverId,
        scopeId: scopeId,
      );

      if (fetchId != _sessionsFetchId) {
        return;
      }

      await loadLastSession(
        serverId: serverId,
        scopeId: scopeId,
        storedSessionId: storedSessionId,
      );
      await refreshSessionStatusSnapshot();
    } catch (e, stackTrace) {
      if (fetchId != _sessionsFetchId) {
        return;
      }
      AppLogger.error(
        'Failed to load session list',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Failed to load session list: ${e.toString()}');
    }
  }

  /// Load sessions from cache

  /// Save sessions to cache

  /// Save current session ID

  /// Load last selected session
  Future<void> loadLastSession({
    required String serverId,
    required String scopeId,
    String? storedSessionId,
  }) async {
    try {
      if (_sessions.isEmpty) {
        _currentSession = null;
        _threadPermissionsVersion++;
        _messages = <ChatMessage>[];
        _messagesVersion++;
        await _clearLastSessionSnapshotBestEffort(
          serverId: serverId,
          scopeId: scopeId,
        );
        return;
      }

      final resolvedStoredSessionId =
          storedSessionId ??
          await localDataSource.getCurrentSessionId(
            serverId: serverId,
            scopeId: scopeId,
          );

      // Prefer the in-memory session over the persisted ID to avoid reverting
      // a session switch that already updated _currentSession but whose
      // persistence write is still in flight.
      ChatSession? targetSession;
      final inMemorySessionId = _currentSession?.id;
      if (inMemorySessionId != null) {
        targetSession = _sessions
            .where((session) => session.id == inMemorySessionId)
            .firstOrNull;
      }
      if (targetSession == null &&
          resolvedStoredSessionId != null &&
          resolvedStoredSessionId.trim().isNotEmpty) {
        targetSession = _sessions
            .where((session) => session.id == resolvedStoredSessionId)
            .firstOrNull;
      }
      targetSession ??= _sessions.reduce((left, right) {
        return left.time.isAfter(right.time) ? left : right;
      });

      if (_currentSession?.id != targetSession.id) {
        await selectSession(targetSession);
        return;
      }

      final appliedSessionOverride = _applySelectionPriorityForCurrentSession();
      if (appliedSessionOverride) {
        notifyListeners();
      }

      if (_messages.isEmpty) {
        await loadMessages(targetSession.id);
      } else {
        unawaited(loadMessages(targetSession.id, preserveVisibleState: true));
      }

      if (resolvedStoredSessionId != targetSession.id) {
        await _saveCurrentSessionId(
          targetSession.id,
          serverId: serverId,
          scopeId: scopeId,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.warn(
        'Failed to load last session',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Create new session
  Future<void> createNewSession({String? parentId, String? title}) async {
    final projectId = projectProvider.currentProjectId;
    final directory = projectProvider.currentDirectory;
    _setState(ChatState.loading);

    // Generate time-based title
    final now = DateTime.now();
    final defaultTitle = title ?? _generateSessionTitle(now);

    final result = await createChatSession(
      CreateChatSessionParams(
        projectId: projectId,
        input: SessionCreateInput(parentId: parentId, title: defaultTitle),
        directory: directory,
      ),
    );

    if (result.isLeft()) {
      final failure = result.fold((value) => value, (_) => null);
      if (failure != null) {
        _handleFailure(failure);
      }
      return;
    }

    final session = result.fold((_) => null, (value) => value);
    if (session == null) {
      _setError('Failed to create session');
      return;
    }

    _sessions = List<ChatSession>.from(_sessions);
    _removeSessionById(session.id);
    _sessions.add(session);
    _sortSessionsInPlace();
    _currentSession = session;
    _threadPermissionsVersion++;
    _messages = <ChatMessage>[];
    _messagesVersion++;
    _pendingLocalUserMessageIds.clear();
    _clearQueuedSendState();
    _clearRejectedDraft();
    _sessionInsightsError = null;

    final serverId = await _resolveServerScopeId();
    final scopeId = _resolveContextScopeId();
    await _saveCurrentSessionId(
      session.id,
      serverId: serverId,
      scopeId: scopeId,
    );
    _storeCurrentSessionSelectionOverride();
    unawaited(
      _persistLastSessionSnapshotBestEffort(
        serverId: serverId,
        scopeId: scopeId,
      ),
    );
    unawaited(_persistSessionCacheBestEffort());
    unawaited(loadSessionInsights(session.id, silent: true));
    _setState(ChatState.loaded);
  }

  /// Generate time-based session title

  /// Select session
  Future<void> selectSession(ChatSession session) async {
    if (_currentSession?.id == session.id) {
      await loadSessionInsights(session.id, silent: true);
      return;
    }

    // Invalidate any concurrent loadSessions() that captured a stale
    // persisted session ID before this switch updated memory/disk.
    _sessionsFetchId += 1;

    await _cancelActiveMessageSubscription(
      reason: 'session-switch',
      // Invalidate generation so preserved stream callbacks become stale and
      // return early — prevents cross-session message corruption. Messages
      // are reloaded from server when the user switches back.
      invalidateGeneration: true,
      preserveActiveStream: true,
    );
    AppLogger.info(
      'selectSession generation=$_messageStreamGeneration preserved=${_preservedMessageSubscriptions.length} target=${session.id}',
    );

    // Clear current message list
    _messages.clear();
    _messagesVersion++;
    _pendingLocalUserMessageIds.clear();
    _clearQueuedSendState();
    _clearRejectedDraft();
    _currentSession = session;
    _threadPermissionsVersion++;
    _applySelectionPriorityForCurrentSession();
    notifyListeners();

    // Save current session ID
    final serverId = await _resolveServerScopeId();
    final scopeId = _resolveContextScopeId();
    await _saveCurrentSessionId(
      session.id,
      serverId: serverId,
      scopeId: scopeId,
    );

    // Load messages for selected session
    await loadMessages(session.id);
    await loadSessionInsights(session.id, silent: true);
    _scheduleQueuedSendDrain(session.id, reason: 'session-selected');
  }

  /// Load message list
  Future<void> loadMessages(
    String sessionId, {
    bool preserveVisibleState = false,
  }) async {
    final fetchId = ++_messagesFetchId;
    // Sync project ID from ProjectProvider; projectId is optional for the new API
    _currentProjectId = projectProvider.currentProjectId;

    final canKeepVisibleState =
        preserveVisibleState &&
        _currentSession?.id == sessionId &&
        _messages.isNotEmpty;
    if (!canKeepVisibleState) {
      _setState(ChatState.loading);
    }

    final result = await getChatMessages(
      GetChatMessagesParams(
        projectId: projectProvider.currentProjectId,
        sessionId: sessionId,
        directory: projectProvider.currentDirectory,
      ),
    );

    if (fetchId != _messagesFetchId) {
      return;
    }

    result.fold(
      (failure) {
        if (fetchId != _messagesFetchId) {
          return;
        }
        if (canKeepVisibleState) {
          AppLogger.warn(
            'Background session revalidation failed session=$sessionId',
            error: failure,
          );
          _setState(ChatState.loaded);
          return;
        }
        _handleFailure(failure);
      },
      (messages) {
        if (fetchId != _messagesFetchId || _currentSession?.id != sessionId) {
          return;
        }
        _messages = _mergeServerMessagesWithActiveLocalTail(
          messages,
          sessionId: sessionId,
        );
        _messagesVersion++;
        _prunePendingLocalUserMessageIdsToVisibleUsers();
        _pruneQueuedLocalUserMessageIdsToVisibleUsers();
        _scheduleAutoTitleRefresh(sessionId);
        _setState(ChatState.loaded);
        unawaited(_persistLastSessionSnapshotBestEffort());
        _scheduleQueuedSendDrain(sessionId, reason: 'load-messages');
      },
    );
  }

  Future<void> submitMessageWithQueue(
    String text, {
    List<FileInputPart> attachments = const <FileInputPart>[],
    bool shellMode = false,
  }) async {
    final trimmedText = text.trim();
    final effectiveAttachments = shellMode
        ? const <FileInputPart>[]
        : attachments;
    final session = _currentSession;
    if (session == null ||
        (trimmedText.isEmpty && effectiveAttachments.isEmpty)) {
      return;
    }

    final sessionId = session.id;
    final hasQueuedMessages = queuedMessageCountForSession(sessionId) > 0;
    if (_isSessionBusyForQueuedSend(sessionId) || hasQueuedMessages) {
      final localMessageId = _appendLocalUserMessage(
        sessionId: sessionId,
        text: trimmedText,
        attachments: effectiveAttachments,
        shellMode: shellMode,
      );
      final queue = _queueForSession(sessionId)
        ..add(
          _QueuedSendEnvelope(
            sessionId: sessionId,
            localMessageId: localMessageId,
            text: trimmedText,
            attachments: List<FileInputPart>.unmodifiable(effectiveAttachments),
            shellMode: shellMode,
          ),
        );
      _syncQueuedLocalUserMessageIds();
      _notifyListeners();
      _scheduleAutoTitleRefresh(sessionId);
      unawaited(_persistLastSessionSnapshotBestEffort());
      AppLogger.info(
        'Provider queued message session=$sessionId size=${queue.length}',
      );
      if (!_isSessionBusyForQueuedSend(sessionId)) {
        _scheduleQueuedSendDrain(sessionId, reason: 'queue-while-idle');
      }
      return;
    }

    await sendMessage(
      trimmedText,
      attachments: effectiveAttachments,
      shellMode: shellMode,
    );
  }

  bool _isSessionBusyForQueuedSend(String sessionId) {
    if (_currentSession?.id != sessionId) {
      return false;
    }
    if (_interruptSendInFlight || _isAbortingResponse) {
      return true;
    }
    if (_state == ChatState.sending) {
      return true;
    }
    return isSessionActivelyResponding(sessionId);
  }

  void _scheduleQueuedSendDrain(
    String sessionId, {
    required String reason,
    bool allowRetrySchedule = true,
  }) {
    if (_queuedDrainInFlightSessionIds.contains(sessionId)) {
      _queuedDrainDeferredSessionIds.add(sessionId);
      return;
    }
    unawaited(
      _drainQueuedSends(
        sessionId,
        reason: reason,
        allowRetrySchedule: allowRetrySchedule,
      ),
    );
  }

  void _scheduleQueuedSendRetryOnce(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    if (!_queuedRetryScheduledSessionIds.add(normalizedSessionId)) {
      return;
    }

    unawaited(
      Future<void>.delayed(const Duration(seconds: 1), () {
        _queuedRetryScheduledSessionIds.remove(normalizedSessionId);
        if (_currentSession?.id != normalizedSessionId) {
          return;
        }
        if (_isSessionBusyForQueuedSend(normalizedSessionId)) {
          return;
        }
        if (queuedMessageCountForSession(normalizedSessionId) == 0) {
          return;
        }
        _scheduleQueuedSendDrain(
          normalizedSessionId,
          reason: 'retry-after-failure',
          allowRetrySchedule: false,
        );
      }),
    );
  }

  ({String text, List<FileInputPart> attachments, bool shellMode})
  _buildMergedQueuedPayload(List<_QueuedSendEnvelope> queuedBatch) {
    final allShellMode =
        queuedBatch.isNotEmpty &&
        queuedBatch.every((queued) => queued.shellMode);
    final mergedLines = <String>[];
    for (final queued in queuedBatch) {
      final line = queued.text.trim();
      if (line.isEmpty) {
        continue;
      }
      if (allShellMode) {
        mergedLines.add(line);
      } else {
        // Mixed-mode batches are sent in normal mode and keep shell intent by
        // prefixing shell lines with '!'.
        final normalizedShellLine = line.startsWith('!') ? line : '!$line';
        mergedLines.add(queued.shellMode ? normalizedShellLine : line);
      }
    }

    final mergedAttachments = <FileInputPart>[
      for (final queued in queuedBatch) ...queued.attachments,
    ];
    return (
      text: mergedLines.join('\n'),
      attachments: List<FileInputPart>.unmodifiable(mergedAttachments),
      shellMode: allShellMode,
    );
  }

  Future<bool> sendQueuedNow() async {
    final sessionId = _currentSession?.id;
    if (sessionId == null || currentSessionQueuedMessageCount == 0) {
      return false;
    }

    final wasBusy = _isSessionBusyForQueuedSend(sessionId);
    if (wasBusy && canAbortActiveResponse) {
      final stopped = await abortActiveResponse(suppressFailureUi: true);
      if (!stopped) {
        AppLogger.info(
          'Provider send-now continuing after stop failure session=$sessionId',
        );
      }
    }

    if (wasBusy && _currentSession?.id == sessionId) {
      await _awaitInterruptSendSessionReady(sessionId);
    }

    if (_queuedDrainInFlightSessionIds.contains(sessionId)) {
      return true;
    }

    final drained = await _drainQueuedSends(sessionId, reason: 'send-now');
    return drained || queuedMessageCountForSession(sessionId) == 0;
  }

  Future<bool> _drainQueuedSends(
    String sessionId, {
    required String reason,
    bool allowRetrySchedule = true,
  }) async {
    if (_queuedDrainInFlightSessionIds.contains(sessionId)) {
      return false;
    }
    _queuedDrainInFlightSessionIds.add(sessionId);

    try {
      if (_currentSession?.id != sessionId) {
        return false;
      }
      if (_isSessionBusyForQueuedSend(sessionId)) {
        return false;
      }

      final queue = _queuedSendBySessionId[sessionId];
      if (queue == null || queue.isEmpty) {
        _queuedSendBySessionId.remove(sessionId);
        _syncQueuedLocalUserMessageIds();
        _notifyListeners();
        return false;
      }

      final queuedBatch = queue.toList(growable: false);
      final payload = _buildMergedQueuedPayload(queuedBatch);
      if (payload.text.isEmpty && payload.attachments.isEmpty) {
        _queuedSendBySessionId.remove(sessionId);
        _syncQueuedLocalUserMessageIds();
        _notifyListeners();
        return false;
      }

      final mergedLocalMessageId = _consolidateQueuedLocalUserMessages(
        sessionId: sessionId,
        queuedBatch: queuedBatch,
        mergedText: payload.text,
        mergedAttachments: payload.attachments,
        shellMode: payload.shellMode,
      );
      _queuedSendBySessionId[sessionId] =
          ListQueue<_QueuedSendEnvelope>.from(<_QueuedSendEnvelope>[
            _QueuedSendEnvelope(
              sessionId: sessionId,
              localMessageId: mergedLocalMessageId,
              text: payload.text,
              attachments: payload.attachments,
              shellMode: payload.shellMode,
            ),
          ]);
      _syncQueuedLocalUserMessageIds();

      AppLogger.info(
        'Provider draining queued batch session=$sessionId reason=$reason count=${queuedBatch.length}',
      );
      var sendStarted = false;
      try {
        sendStarted = await sendMessage(
          payload.text,
          attachments: payload.attachments,
          shellMode: payload.shellMode,
          localMessageId: mergedLocalMessageId,
          appendOptimisticMessage: false,
          sessionIdOverride: sessionId,
        );
      } catch (error, stackTrace) {
        AppLogger.error(
          'Provider queued batch dispatch crashed session=$sessionId reason=$reason',
          error: error,
          stackTrace: stackTrace,
        );
      }
      if (!sendStarted) {
        AppLogger.warn(
          'Provider queued batch dispatch failed session=$sessionId reason=$reason',
        );
        if (allowRetrySchedule) {
          _scheduleQueuedSendRetryOnce(sessionId);
        }
        _notifyListeners();
        return false;
      }

      _queuedSendBySessionId.remove(sessionId);
      _syncQueuedLocalUserMessageIds();
      _notifyListeners();
      return true;
    } finally {
      _queuedDrainInFlightSessionIds.remove(sessionId);
      final shouldDrainDeferred = _queuedDrainDeferredSessionIds.remove(
        sessionId,
      );
      if (shouldDrainDeferred &&
          _currentSession?.id == sessionId &&
          !_isSessionBusyForQueuedSend(sessionId) &&
          queuedMessageCountForSession(sessionId) > 0) {
        _scheduleQueuedSendDrain(sessionId, reason: 'deferred');
      }
    }
  }

  Future<void> sendMessageWithInterrupt(
    String text, {
    List<FileInputPart> attachments = const <FileInputPart>[],
    bool shellMode = false,
  }) async {
    final trimmedText = text.trim();
    final effectiveAttachments = shellMode
        ? const <FileInputPart>[]
        : attachments;
    if (_currentSession == null ||
        (trimmedText.isEmpty && effectiveAttachments.isEmpty)) {
      return;
    }
    if (_interruptSendInFlight) {
      AppLogger.info(
        'Provider interrupt-and-send ignored because a previous request is still in flight',
      );
      return;
    }
    _interruptSendInFlight = true;

    try {
      final targetSessionId = _currentSession!.id;
      if (isCurrentSessionActivelyResponding) {
        AppLogger.info(
          'Provider interrupt-and-send requested session=$targetSessionId',
        );
        final stopped = await abortActiveResponse(suppressFailureUi: true);
        if (!stopped) {
          AppLogger.info(
            'Provider interrupt-and-send continuing after stop failure session=$targetSessionId',
          );
        }

        if (_currentSession?.id != targetSessionId) {
          AppLogger.info(
            'Provider interrupt-and-send cancelled due session switch from=$targetSessionId to=${_currentSession?.id ?? "-"}',
          );
          return;
        }
        await _awaitInterruptSendSessionReady(targetSessionId);
      }

      if (_currentSession?.id != targetSessionId) {
        AppLogger.info(
          'Provider interrupt-and-send cancelled due session switch from=$targetSessionId to=${_currentSession?.id ?? "-"}',
        );
        return;
      }

      await sendMessage(
        trimmedText,
        attachments: effectiveAttachments,
        shellMode: shellMode,
      );
    } finally {
      _interruptSendInFlight = false;
    }
  }

  Future<void> _awaitInterruptSendSessionReady(String sessionId) async {
    var settled = false;
    for (
      var attempt = 0;
      attempt < _interruptSendStatusMaxAttempts;
      attempt += 1
    ) {
      if (_currentSession?.id != sessionId) {
        return;
      }

      await refreshSessionStatusSnapshot();
      final statusType = _sessionStatusById[sessionId]?.type;
      final hasBusyStatus =
          statusType == SessionStatusType.busy ||
          statusType == SessionStatusType.retry;
      final hasActiveLocalStream =
          _activeMessageStreamSessionId == sessionId &&
          _messageSubscription != null;

      if (!hasBusyStatus && !hasActiveLocalStream && !_isAbortingResponse) {
        settled = true;
        break;
      }

      await Future<void>.delayed(_interruptSendStatusPollInterval);
    }

    if (!settled) {
      AppLogger.warn(
        'Provider interrupt-and-send proceeding without settled status session=$sessionId',
      );
    }

    await Future<void>.delayed(_interruptSendPostAbortDelay);
  }

  /// Send message
  Future<bool> sendMessage(
    String text, {
    List<FileInputPart> attachments = const <FileInputPart>[],
    bool shellMode = false,
    String? localMessageId,
    bool appendOptimisticMessage = true,
    String? sessionIdOverride,
  }) async {
    final trimmedText = text.trim();
    final effectiveAttachments = shellMode
        ? const <FileInputPart>[]
        : attachments;
    final normalizedSessionOverride = sessionIdOverride;
    final hasSessionOverride =
        normalizedSessionOverride != null &&
        normalizedSessionOverride.isNotEmpty;
    if ((!hasSessionOverride && _currentSession == null) ||
        (trimmedText.isEmpty && effectiveAttachments.isEmpty)) {
      return false;
    }

    final sendSessionId = hasSessionOverride
        ? normalizedSessionOverride!
        : _currentSession!.id;
    AppLogger.info(
      'Provider send start session=$sendSessionId agent=${_selectedAgentName ?? "-"} provider=${_selectedProviderId ?? "-"} model=${_selectedModelId ?? "-"} variant=${_selectedVariantId ?? "auto"}',
    );
    _setActiveSendDraft(
      trimmedText,
      attachments: effectiveAttachments,
      shellMode: shellMode,
    );
    _setState(ChatState.sending);

    try {
      // Sync project ID from ProjectProvider
      _currentProjectId = projectProvider.currentProjectId;

      final resolvedLocalMessageId = localMessageId?.trim().isNotEmpty == true
          ? localMessageId!.trim()
          : null;
      final hasExistingLocalMessage =
          resolvedLocalMessageId != null &&
          _messages.whereType<UserMessage>().any(
            (message) => message.id == resolvedLocalMessageId,
          );
      final activeLocalMessageId =
          appendOptimisticMessage ||
              resolvedLocalMessageId == null ||
              !hasExistingLocalMessage
          ? _appendLocalUserMessage(
              sessionId: sendSessionId,
              text: trimmedText,
              attachments: effectiveAttachments,
              shellMode: shellMode,
            )
          : resolvedLocalMessageId;

      _pendingLocalUserMessageIds.add(activeLocalMessageId);
      notifyListeners();
      _scheduleAutoTitleRefresh(sendSessionId);
      unawaited(_persistLastSessionSnapshotBestEffort());

      // Ensure providers are initialized
      if (_selectedProviderId == null || _selectedModelId == null) {
        AppLogger.info('Provider send initializing provider/model selection');
        await initializeProviders();
        AppLogger.info(
          'Provider send initialized provider=${_selectedProviderId ?? "-"} model=${_selectedModelId ?? "-"}',
        );
      }

      _recordModelUsage();
      final selectedAgentForSend = _resolvePreferredAgentName(
        _agents,
        _selectedAgentName,
      );
      if (selectedAgentForSend != null &&
          selectedAgentForSend != _selectedAgentName) {
        _selectedAgentName = selectedAgentForSend;
      }
      // Persisting selection is best-effort; it must not block message sending.
      unawaited(
        _persistSelection().catchError(
          (error, stackTrace) => AppLogger.warn(
            'Provider send selection persistence failed',
            error: error,
            stackTrace: stackTrace is StackTrace ? stackTrace : null,
          ),
        ),
      );

      // Create chat input
      final inputParts = <ChatInputPart>[
        if (trimmedText.isNotEmpty) TextInputPart(text: trimmedText),
        ...effectiveAttachments,
      ];
      final input = ChatInput(
        providerId: _selectedProviderId ?? 'anthropic',
        modelId: _selectedModelId ?? 'claude-3-5-sonnet-20241022',
        variant: _selectedVariantId,
        mode: shellMode ? 'shell' : selectedAgentForSend,
        parts: inputParts,
      );

      // Cancel previous subscription and invalidate stale callbacks.
      final hasOtherSessionActiveStream =
          _messageSubscription != null &&
          _activeMessageStreamSessionId != null &&
          _activeMessageStreamSessionId != sendSessionId;
      await _cancelActiveMessageSubscription(
        reason: 'start-send',
        invalidateGeneration: true,
        preserveActiveStream: hasOtherSessionActiveStream,
      );
      final streamGeneration = _messageStreamGeneration;
      final streamSessionId = sendSessionId;
      _activeMessageStreamSessionId = streamSessionId;

      AppLogger.info(
        'Provider send subscribing stream session=$streamSessionId directory=${projectProvider.currentDirectory ?? "-"}',
      );

      // Send message and listen for streaming response
      late final StreamSubscription<dynamic> sendSubscription;
      sendSubscription =
          sendChatMessage(
            SendChatMessageParams(
              projectId: projectProvider.currentProjectId,
              sessionId: streamSessionId,
              input: input,
              directory: projectProvider.currentDirectory,
            ),
          ).listen(
            (result) {
              if (streamGeneration != _messageStreamGeneration) {
                AppLogger.debug(
                  'Ignoring stale send stream event generation=$streamGeneration active=$_messageStreamGeneration',
                );
                return;
              }
              result.fold((failure) {
                if (_shouldSuppressAbortError(
                  sessionId: streamSessionId,
                  message: failure.message,
                )) {
                  AppLogger.info(
                    'Suppressing expected abort failure session=$streamSessionId',
                  );
                  _clearActiveSendDraft();
                  _errorMessage = null;
                  if (_currentSession?.id == streamSessionId) {
                    _setState(ChatState.loaded);
                  } else {
                    _notifyListeners();
                  }
                  return;
                }
                _stashRejectedDraftForRetry(sessionId: streamSessionId);
                if (_currentSession?.id != streamSessionId) {
                  AppLogger.warn(
                    'Background send stream failure session=$streamSessionId message=${failure.message}',
                  );
                  _sessionStatusById[streamSessionId] = const SessionStatusInfo(
                    type: SessionStatusType.idle,
                  );
                  _notifyListeners();
                  return;
                }
                _handleFailure(failure);
              }, _updateOrAddMessage);
            },
            onError: (error) {
              _preservedMessageSubscriptions.remove(sendSubscription);
              if (streamGeneration != _messageStreamGeneration) {
                if (identical(_messageSubscription, sendSubscription)) {
                  _messageSubscription = null;
                  if (_activeMessageStreamSessionId == streamSessionId) {
                    _activeMessageStreamSessionId = null;
                  }
                }
                // Stream errored while stale — finalize any incomplete messages
                // that were deferred by the event reducer preserved-stream guard.
                _markIncompleteAssistantMessagesAsCompleted(
                  sessionId: streamSessionId,
                );
                AppLogger.info(
                  'Stale send stream error — finalized session=$streamSessionId generation=$streamGeneration active=$_messageStreamGeneration',
                );
                return;
              }
              if (identical(_messageSubscription, sendSubscription)) {
                _messageSubscription = null;
                if (_activeMessageStreamSessionId == streamSessionId) {
                  _activeMessageStreamSessionId = null;
                }
              }
              _stashRejectedDraftForRetry(sessionId: streamSessionId);
              AppLogger.error('Provider send stream error', error: error);
              if (_currentSession?.id != streamSessionId) {
                _sessionStatusById[streamSessionId] = const SessionStatusInfo(
                  type: SessionStatusType.idle,
                );
                _notifyListeners();
                return;
              }
              _setError(
                'Failed to send message: $error',
                sessionId: streamSessionId,
              );
            },
            onDone: () {
              _preservedMessageSubscriptions.remove(sendSubscription);
              if (streamGeneration != _messageStreamGeneration) {
                if (identical(_messageSubscription, sendSubscription)) {
                  _messageSubscription = null;
                  if (_activeMessageStreamSessionId == streamSessionId) {
                    _activeMessageStreamSessionId = null;
                  }
                }
                // Stream finished draining — finalize any incomplete messages
                // that were deferred by the event reducer preserved-stream guard.
                _markIncompleteAssistantMessagesAsCompleted(
                  sessionId: streamSessionId,
                );
                AppLogger.info(
                  'Stale send stream done — finalized session=$streamSessionId generation=$streamGeneration active=$_messageStreamGeneration',
                );
                return;
              }
              if (identical(_messageSubscription, sendSubscription)) {
                _messageSubscription = null;
                if (_activeMessageStreamSessionId == streamSessionId) {
                  _activeMessageStreamSessionId = null;
                }
              }
              _clearActiveSendDraft();
              // Activate abort suppression so that any session.error arriving
              // on the provider-level SSE shortly after this stream closes
              // (e.g. due to half-open TCP after background resume) is
              // suppressed while the datasource polling fallback completes.
              _startAbortSuppression(streamSessionId);
              AppLogger.info(
                'Provider send stream finished session=$streamSessionId',
              );
              _sessionStatusById[streamSessionId] = const SessionStatusInfo(
                type: SessionStatusType.idle,
              );
              if (_currentSession?.id == streamSessionId) {
                _markIncompleteAssistantMessagesAsCompleted(
                  sessionId: streamSessionId,
                );
                _setState(ChatState.loaded);
                unawaited(_persistLastSessionSnapshotBestEffort());
                unawaited(loadSessionInsights(streamSessionId, silent: true));
              } else {
                _notifyListeners();
              }
              _scheduleQueuedSendDrain(
                streamSessionId,
                reason: 'stream-finished',
              );
            },
          );
      _messageSubscription = sendSubscription;
      AppLogger.info('Provider send stream subscription attached');
      return true;
    } catch (error, stackTrace) {
      final streamSessionId = _activeMessageStreamSessionId ?? sendSessionId;
      _activeMessageStreamSessionId = null;
      _stashRejectedDraftForRetry(sessionId: streamSessionId);
      AppLogger.error(
        'Provider send setup failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (_shouldSuppressAbortError(
        sessionId: streamSessionId,
        message: error.toString(),
      )) {
        _clearActiveSendDraft();
        _errorMessage = null;
        _setState(ChatState.loaded);
        return false;
      }
      _setError('Failed to start message send', sessionId: streamSessionId);
      return false;
    }
  }

  Future<bool> abortActiveResponse({bool suppressFailureUi = false}) async {
    if (!canAbortActiveResponse) {
      return false;
    }
    final session = _currentSession;
    final usecase = abortChatSession;
    if (session == null || usecase == null) {
      if (!suppressFailureUi) {
        _setError('Stop is unavailable for the current session');
      }
      return false;
    }

    _startAbortSuppression(session.id);
    _isAbortingResponse = true;
    notifyListeners();
    final previousError = _errorMessage;
    _errorMessage = null;

    final result = await usecase(
      AbortChatSessionParams(
        projectId: projectProvider.currentProjectId,
        sessionId: session.id,
        directory: projectProvider.currentDirectory,
      ),
    );

    late final bool success;
    if (result.isLeft()) {
      final failure = result.fold((value) => value, (_) => null);
      if (!suppressFailureUi) {
        _clearAbortSuppression();
      }
      if (failure != null) {
        if (suppressFailureUi) {
          AppLogger.info(
            'Suppressing abort failure during interrupt-and-send session=${session.id} message=${failure.message}',
          );
          _errorMessage = null;
        } else {
          _handleFailure(failure);
        }
      }
      success = false;
    } else {
      await _cancelActiveMessageSubscription(
        reason: 'abort-success',
        invalidateGeneration: true,
      );
      _setState(ChatState.loaded);
      _markIncompleteAssistantMessagesAsCompleted();
      if (!suppressFailureUi) {
        _sessionStatusById[session.id] = const SessionStatusInfo(
          type: SessionStatusType.idle,
        );
      }
      _clearActiveSendDraft();
      _errorMessage = null;
      success = true;
    }

    _isAbortingResponse = false;
    if (!success && !suppressFailureUi && _errorMessage == null) {
      _errorMessage = previousError ?? 'Failed to stop current response';
    }
    notifyListeners();
    if (success) {
      unawaited(_persistLastSessionSnapshotBestEffort());
      _scheduleQueuedSendDrain(session.id, reason: 'abort-success');
    }
    return success;
  }

  Future<bool> compactCurrentSession() async {
    if (_isCompactingContext) {
      return false;
    }
    if (canAbortActiveResponse) {
      _errorMessage =
          'Wait for the current response to finish before compacting';
      notifyListeners();
      return false;
    }

    final session = _currentSession;
    final usecase = summarizeChatSession;
    if (session == null || usecase == null) {
      _errorMessage = 'Compact context is unavailable for the current session';
      notifyListeners();
      return false;
    }

    if (_selectedProviderId == null || _selectedModelId == null) {
      await initializeProviders();
    }

    final providerId = _selectedProviderId;
    final modelId = _selectedModelId;
    if (providerId == null || modelId == null) {
      _errorMessage = 'Select a model before compacting context';
      notifyListeners();
      return false;
    }

    _isCompactingContext = true;
    final previousError = _errorMessage;
    _errorMessage = null;
    notifyListeners();

    final result = await usecase(
      SummarizeChatSessionParams(
        projectId: projectProvider.currentProjectId,
        sessionId: session.id,
        providerId: providerId,
        modelId: modelId,
        directory: projectProvider.currentDirectory,
      ),
    );

    var success = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message.isEmpty
            ? 'Failed to compact session context'
            : failure.message;
      },
      (_) {
        success = true;
      },
    );

    _isCompactingContext = false;
    if (success) {
      _errorMessage = null;
      // Reset state to loaded in case SSE events set it to error during the
      // async compaction window.
      if (_state == ChatState.error) {
        _state = ChatState.loaded;
      }
      _markIncompleteAssistantMessagesAsCompleted();
      unawaited(loadSessionInsights(session.id, silent: true));
      unawaited(_persistLastSessionSnapshotBestEffort());
    } else {
      _errorMessage ??= previousError ?? 'Failed to compact session context';
    }
    notifyListeners();
    return success;
  }

  /// Update or add message

  /// Handle failure

  Future<bool> renameSession(ChatSession session, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final previous = _sessionById(session.id);
    if (previous == null) {
      return false;
    }
    final previousTitle = previous.title?.trim();
    if (trimmed == previousTitle) {
      return true;
    }

    final optimistic = previous.copyWith(title: trimmed);
    _pendingRenameTitleBySessionId[session.id] = trimmed;
    _applySessionLocally(optimistic);
    notifyListeners();

    final result = await updateChatSession(
      UpdateChatSessionParams(
        projectId: projectProvider.currentProjectId,
        sessionId: session.id,
        input: SessionUpdateInput(title: trimmed),
        directory: projectProvider.currentDirectory,
      ),
    );

    return result.fold(
      (failure) {
        _pendingRenameTitleBySessionId.remove(session.id);
        _applySessionLocally(previous);
        _handleFailure(failure);
        notifyListeners();
        return false;
      },
      (updated) {
        _pendingRenameTitleBySessionId.remove(session.id);
        _applySessionLocally(updated);
        unawaited(_persistSessionCacheBestEffort());
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> setSessionArchived(ChatSession session, bool archived) async {
    final previous = _sessionById(session.id);
    if (previous == null) {
      return false;
    }

    final archivedAt = archived ? DateTime.now() : null;
    final optimistic = previous.copyWith(
      archivedAt: archivedAt,
      title: previous.title,
    );
    _applySessionLocally(optimistic);

    if (archived && _sessionListFilter == SessionListFilter.active) {
      if (_currentSession?.id == session.id) {
        _currentSession = _sessions.firstWhere(
          (item) => item.id != session.id && !item.archived,
          orElse: () => previous,
        );
        _threadPermissionsVersion++;
      }
    }
    notifyListeners();

    final result = await updateChatSession(
      UpdateChatSessionParams(
        projectId: projectProvider.currentProjectId,
        sessionId: session.id,
        input: SessionUpdateInput(
          archivedAtEpochMs: archived ? archivedAt!.millisecondsSinceEpoch : 0,
        ),
        directory: projectProvider.currentDirectory,
      ),
    );

    return result.fold(
      (failure) {
        _applySessionLocally(previous);
        if (_currentSession?.id != previous.id && session.id == previous.id) {
          _currentSession = previous;
          _threadPermissionsVersion++;
        }
        _handleFailure(failure);
        notifyListeners();
        return false;
      },
      (updated) {
        _applySessionLocally(updated);
        unawaited(_persistSessionCacheBestEffort());
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> toggleSessionShare(ChatSession session) async {
    final previous = _sessionById(session.id);
    if (previous == null) {
      return false;
    }

    final optimistic = previous.copyWith(
      shareUrl: previous.shared ? null : previous.shareUrl,
      shared: !previous.shared,
    );
    _applySessionLocally(optimistic);
    notifyListeners();

    final result = previous.shared
        ? await unshareChatSession(
            UnshareChatSessionParams(
              projectId: projectProvider.currentProjectId,
              sessionId: session.id,
              directory: projectProvider.currentDirectory,
            ),
          )
        : await shareChatSession(
            ShareChatSessionParams(
              projectId: projectProvider.currentProjectId,
              sessionId: session.id,
              directory: projectProvider.currentDirectory,
            ),
          );

    return result.fold(
      (failure) {
        _applySessionLocally(previous);
        _handleFailure(failure);
        notifyListeners();
        return false;
      },
      (updated) {
        _applySessionLocally(updated);
        unawaited(_persistSessionCacheBestEffort());
        notifyListeners();
        return true;
      },
    );
  }

  Future<ChatSession?> forkSession(
    ChatSession session, {
    String? messageId,
    bool selectForked = true,
  }) async {
    final result = await forkChatSession(
      ForkChatSessionParams(
        projectId: projectProvider.currentProjectId,
        sessionId: session.id,
        messageId: messageId,
        directory: projectProvider.currentDirectory,
      ),
    );

    return result.fold(
      (failure) {
        _handleFailure(failure);
        return null;
      },
      (forked) async {
        _applySessionLocally(forked);
        unawaited(_persistSessionCacheBestEffort());
        notifyListeners();
        if (selectForked) {
          await selectSession(forked);
        }
        return forked;
      },
    );
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == ChatState.error) {
      _setState(ChatState.loaded);
    }
  }

  /// Delete session
  Future<void> deleteSession(String sessionId) async {
    _currentProjectId = projectProvider.currentProjectId;
    final previousSessions = List<ChatSession>.from(_sessions);
    final previousCurrent = _currentSession;
    final previousMessages = List<ChatMessage>.from(_messages);
    final wasCurrent = previousCurrent?.id == sessionId;

    _removeSessionById(sessionId);
    _sortSessionsInPlace();

    if (wasCurrent) {
      _currentSession = _sessions.firstOrNull;
      _threadPermissionsVersion++;
      _messages = <ChatMessage>[];
      _messagesVersion++;
    }
    notifyListeners();

    final result = await deleteChatSession(
      DeleteChatSessionParams(
        projectId: projectProvider.currentProjectId,
        sessionId: sessionId,
        directory: projectProvider.currentDirectory,
      ),
    );

    result.fold(
      (failure) {
        _sessions = previousSessions;
        _currentSession = previousCurrent;
        _threadPermissionsVersion++;
        _messages = previousMessages;
        _messagesVersion++;
        _sortSessionsInPlace();
        unawaited(_persistLastSessionSnapshotBestEffort());
        _handleFailure(failure);
      },
      (_) async {
        if (wasCurrent && _currentSession != null) {
          await loadMessages(_currentSession!.id);
          await loadSessionInsights(_currentSession!.id, silent: true);
        }
        if (_currentSession == null) {
          unawaited(_clearLastSessionSnapshotBestEffort());
        } else {
          unawaited(_persistLastSessionSnapshotBestEffort());
        }
        notifyListeners();
      },
    );
  }

  /// Refresh current session
  Future<void> refresh() async {
    if (_currentSession != null) {
      await refreshActiveSessionView(reason: 'manual-refresh');
    } else {
      // If there is no current session, reload sessions
      if (_sessions.isNotEmpty) {
        // Assume workspaceId exists; in practice it should come from app state
        // Adjust based on actual app behavior
        _setState(ChatState.loaded);
      }
    }
  }

  @override
  void dispose() {
    unawaited(
      _cancelActiveMessageSubscription(
        reason: 'dispose',
        invalidateGeneration: true,
      ),
    );
    unawaited(_cancelPreservedMessageSubscriptions(reason: 'dispose'));
    _eventStreamGeneration += 1;
    _eventSubscription?.cancel();
    _globalEventSubscription?.cancel();
    _globalRefreshDebounce?.cancel();
    _syncHealthTimer?.cancel();
    _degradedPollingTimer?.cancel();
    _foregroundResumeSyncTimer?.cancel();
    super.dispose();
  }
}
