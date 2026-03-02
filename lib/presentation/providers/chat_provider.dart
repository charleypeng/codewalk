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
import '../utils/chat_event_property_extractors.dart';
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
part 'chat_provider/chat_provider_shortcut_cycle_ops.dart';

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
    Duration shortcutCycleWindow = const Duration(seconds: 3),
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
    _shortcutCycleWindow = shortcutCycleWindow;
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
  final Set<String> _sessionUnreadCompletionIds = <String>{};
  final Set<String> _sessionErrorAttentionIds = <String>{};
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
  final Map<String, Timer> _queuedRetryTimersBySessionId = <String, Timer>{};
  final Map<String, int> _queuedRetryAttemptsBySessionId = <String, int>{};
  int _localMessageIdSequence = 0;
  bool _activeSessionRefreshInFlight = false;
  bool _isLoadingOlderMessages = false;
  bool _hasMoreOldMessages = false;
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
  bool _isNewChatDraftActive = false;
  Future<void>? _lazySessionBootstrapTask;
  _RejectedDraftEnvelope? _rejectedDraft;
  bool _interruptSendInFlight = false;
  // One-shot guard: tracks the session+turn that last fired a final-message
  // reconcile, preventing duplicate reconciles from repeated session.idle
  // events within the same completion cycle.
  String? _lastIdleReconcileSessionTurnKey;
  final Map<String, String> _deferredIdleReconcileTurnKeyBySessionId =
      <String, String>{};
  int _idleReconcileEvaluations = 0;
  int _idleReconcileTriggers = 0;
  int _idleReconcileSkips = 0;
  final LinkedHashMap<String, List<ChatMessage>> _sessionMessagesLruCache =
      LinkedHashMap<String, List<ChatMessage>>();

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
  List<String> _recentAgentNames = <String>[];
  Map<String, List<String>> _recentVariantValuesByModel =
      <String, List<String>>{};
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
  bool _foregroundResumeReconcileInFlight = false;
  bool _realtimeSubscriptionRestartInFlight = false;
  bool _realtimeSubscriptionRestartQueued = false;
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
  late final Duration _shortcutCycleWindow;
  final Map<_ShortcutCycleDomain, _ShortcutCycleState>
  _shortcutCycleStateByDomain = <_ShortcutCycleDomain, _ShortcutCycleState>{};

  // Circular buffer of recent event dedup keys to prevent the global stream
  // from re-processing events already handled by the session stream.
  final Queue<String> _recentEventIds = Queue<String>();
  static const int _maxRecentEventIds = 64;

  static const Duration _sessionsCacheTtl = Duration(days: 3);
  static const Duration _lastSessionSnapshotTtl = Duration(days: 7);
  static const Duration _sessionMessagesSnapshotTtl = Duration(days: 7);
  static const int _maxSessionMessageCacheEntries = 20;
  static const int _maxPersistedSessionMessageSnapshots = 8;
  static const int _defaultOlderMessagesChunkSize = 200;
  static const int _maxRecentModels = 8;
  static const int _maxRecentAgents = 8;
  static const int _maxRecentVariantsPerModel = 8;
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
  static const String _traceFinalPrefix = 'CW_TRACE_FINAL';
  static const Duration _interruptSendStatusPollInterval = Duration(
    milliseconds: 120,
  );
  static const int _interruptSendStatusMaxAttempts = 6;
  static const Duration _interruptSendPostAbortDelay = Duration(
    milliseconds: 120,
  );
  static const int _queuedRetryMaxAttempts = 12;

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

  void _traceFinal(String event, {String? sessionId, String? details}) {
    final currentSessionId = _currentSession?.id;
    final normalizedSessionId = (sessionId ?? currentSessionId ?? '-').trim();
    final effectiveSessionId = normalizedSessionId.isEmpty
        ? '-'
        : normalizedSessionId;
    final statusLabel =
        _sessionStatusById[effectiveSessionId]?.type.name ?? '-';
    final abortSuppressed =
        effectiveSessionId == '-' ||
            _abortSuppressionSessionId != effectiveSessionId ||
            _abortSuppressionStartedAt == null
        ? false
        : DateTime.now().difference(_abortSuppressionStartedAt!) <=
              _abortSuppressionWindow;
    final preserved = effectiveSessionId == '-'
        ? false
        : _hasPreservedStreamForSession(effectiveSessionId);
    final queueSize = effectiveSessionId == '-'
        ? 0
        : queuedMessageCountForSession(effectiveSessionId);
    final lastMessage = _messages.isEmpty ? '-' : _messages.last.id;
    final suffix = details == null || details.trim().isEmpty
        ? ''
        : ' details=${details.trim()}';

    AppLogger.info(
      '$_traceFinalPrefix provider event=$event session=$effectiveSessionId current=${currentSessionId ?? "-"} state=${_state.name} status=$statusLabel activeStream=${_activeMessageStreamSessionId ?? "-"} hasSub=${_messageSubscription != null} preserved=$preserved abortSuppressed=$abortSuppressed messages=${_messages.length} last=$lastMessage queue=$queueSize$suffix',
    );
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
  bool get isLoadingOlderMessages => _isLoadingOlderMessages;
  bool get hasMoreOldMessages => _hasMoreOldMessages;
  bool get isDraftingNewChat => _isNewChatDraftActive;

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

    if (hasActiveStream) {
      return true;
    }

    if (!hasBusyStatus) {
      return false;
    }

    if (_state == ChatState.sending) {
      return true;
    }

    if (hasInProgressAssistant) {
      return true;
    }

    ChatMessage? latestSessionMessage;
    for (var index = _messages.length - 1; index >= 0; index -= 1) {
      final candidate = _messages[index];
      if (candidate.sessionId == normalizedSessionId) {
        latestSessionMessage = candidate;
        break;
      }
    }

    if (latestSessionMessage is! AssistantMessage) {
      return false;
    }

    final hasToolSurfacePart = latestSessionMessage.parts.any(
      (part) => part is ToolPart || part is PatchPart,
    );

    // Keep the active session in responding mode for busy tool-only turns
    // where step chunks can be emitted as completed assistant messages.
    return hasToolSurfacePart;
  }

  bool get isCurrentSessionActivelyResponding {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return false;
    }
    return isSessionActivelyResponding(sessionId);
  }

  SessionAttentionState sessionAttentionFor(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return const SessionAttentionState();
    }

    final statusType = _sessionStatusById[normalizedSessionId]?.type;
    final hasPendingPermission =
        (_pendingPermissionsBySession[normalizedSessionId]?.isNotEmpty ??
        false);
    final hasPendingQuestion =
        (_pendingQuestionsBySession[normalizedSessionId]?.isNotEmpty ?? false);

    return SessionAttentionState(
      isActive: isSessionActivelyResponding(normalizedSessionId),
      hasPendingInteraction: hasPendingPermission || hasPendingQuestion,
      hasError:
          statusType == SessionStatusType.retry ||
          _sessionErrorAttentionIds.contains(normalizedSessionId),
      hasUnreadCompletion: _sessionUnreadCompletionIds.contains(
        normalizedSessionId,
      ),
    );
  }

  bool get hasOutOfFocusAttention => outOfFocusAttentionCount > 0;

  int get outOfFocusAttentionCount {
    final currentSessionId = _currentSession?.id;
    var total = 0;
    for (final session in _sessions) {
      if (session.id == currentSessionId) {
        continue;
      }
      final attention = sessionAttentionFor(session.id);
      if (attention.requiresAttention) {
        total += 1;
      }
    }
    return total;
  }

  SessionAttentionKind get outOfFocusAttentionKind {
    final currentSessionId = _currentSession?.id;
    var hasPendingInteraction = false;
    var hasUnreadCompletion = false;

    for (final session in _sessions) {
      if (session.id == currentSessionId) {
        continue;
      }
      final attention = sessionAttentionFor(session.id);
      if (!attention.requiresAttention) {
        continue;
      }
      if (attention.hasError) {
        return SessionAttentionKind.error;
      }
      hasPendingInteraction =
          hasPendingInteraction || attention.hasPendingInteraction;
      hasUnreadCompletion =
          hasUnreadCompletion || attention.hasUnreadCompletion;
    }

    if (hasPendingInteraction) {
      return SessionAttentionKind.pendingInteraction;
    }
    if (hasUnreadCompletion) {
      return SessionAttentionKind.unreadCompletion;
    }
    return SessionAttentionKind.none;
  }

  void _clearSessionAttentionForSession(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    _sessionUnreadCompletionIds.remove(normalizedSessionId);
    _sessionErrorAttentionIds.remove(normalizedSessionId);
  }

  void _pruneSessionAttentionStateToKnownSessions() {
    final knownSessionIds = _sessions.map((session) => session.id).toSet();
    _sessionUnreadCompletionIds.removeWhere(
      (sessionId) => !knownSessionIds.contains(sessionId),
    );
    _sessionErrorAttentionIds.removeWhere(
      (sessionId) => !knownSessionIds.contains(sessionId),
    );

    final currentSessionId = _currentSession?.id;
    if (currentSessionId != null) {
      _clearSessionAttentionForSession(currentSessionId);
    }
  }

  void _syncAttentionFromStatusMap(Map<String, SessionStatusInfo> statusMap) {
    final currentSessionId = _currentSession?.id;
    for (final entry in statusMap.entries) {
      final sessionId = entry.key;
      final statusType = entry.value.type;
      switch (statusType) {
        case SessionStatusType.retry:
          _sessionUnreadCompletionIds.remove(sessionId);
          if (sessionId != currentSessionId) {
            _sessionErrorAttentionIds.add(sessionId);
          }
          break;
        case SessionStatusType.busy:
          _sessionUnreadCompletionIds.remove(sessionId);
          break;
        case SessionStatusType.idle:
          // Keep sticky error attention on idle until the user focuses the
          // session or an explicit event clears it, avoiding silent dismissal
          // on snapshot refresh races.
          break;
      }
    }
    _pruneSessionAttentionStateToKnownSessions();
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
    for (final timer in _queuedRetryTimersBySessionId.values) {
      timer.cancel();
    }
    _queuedSendBySessionId.clear();
    _queuedLocalUserMessageIds.clear();
    _queuedDrainInFlightSessionIds.clear();
    _queuedDrainDeferredSessionIds.clear();
    _queuedRetryTimersBySessionId.clear();
    _queuedRetryAttemptsBySessionId.clear();
  }

  String _nextLocalUserMessageId() {
    _localMessageIdSequence += 1;
    return 'msg_${DateTime.now().microsecondsSinceEpoch}_${_localMessageIdSequence}';
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
    return _buildVisibleSessionsFrom(_sessions);
  }

  List<ChatSession> visibleSessionsForScopeId(String scopeId) {
    final normalizedScopeId = scopeId.trim();
    if (normalizedScopeId.isEmpty) {
      return const <ChatSession>[];
    }
    final contextKey = _composeContextKey(_activeServerId, normalizedScopeId);
    if (contextKey == _activeContextKey) {
      return visibleSessions;
    }
    final snapshot = _contextSnapshots[contextKey];
    if (snapshot == null) {
      return const <ChatSession>[];
    }
    return _buildVisibleSessionsFrom(snapshot.sessions);
  }

  bool hasSnapshotForScopeId(String scopeId) {
    final normalizedScopeId = scopeId.trim();
    if (normalizedScopeId.isEmpty) {
      return false;
    }
    final contextKey = _composeContextKey(_activeServerId, normalizedScopeId);
    if (contextKey == _activeContextKey) {
      return true;
    }
    return _contextSnapshots.containsKey(contextKey);
  }

  List<ChatSession> _buildVisibleSessionsFrom(
    List<ChatSession> sourceSessions,
  ) {
    final query = _sessionSearchQuery.trim().toLowerCase();
    final filtered = sourceSessions
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
    bool allowDuringAbortSuppression = false,
    bool preferDelta = true,
  }) async {
    final session = _currentSession;
    if (session == null) {
      return;
    }
    // During abort suppression, polling already delivered fresh data.
    // Loading from server risks showing stale abort content that the
    // suppression window is designed to hide.
    if (!allowDuringAbortSuppression &&
        _isAbortSuppressionActiveForSession(session.id)) {
      _traceFinal(
        'refresh-active-skip-abort-suppression',
        sessionId: session.id,
        details:
            'reason=$reason includeStatus=$includeStatus allowDuringAbortSuppression=$allowDuringAbortSuppression',
      );
      AppLogger.info(
        'Skipping active session refresh during abort suppression session=${session.id} reason=$reason',
      );
      return;
    }
    if (_activeSessionRefreshInFlight) {
      return;
    }

    _activeSessionRefreshInFlight = true;
    _traceFinal(
      'refresh-active-start',
      sessionId: session.id,
      details:
          'reason=$reason includeStatus=$includeStatus allowDuringAbortSuppression=$allowDuringAbortSuppression',
    );
    AppLogger.debug(
      'Refreshing active session view reason=$reason session=${session.id}',
    );

    try {
      final cachedMessages = List<ChatMessage>.from(
        _messages.where((message) => message.sessionId == session.id),
      );
      final previousLatestSessionMessage = cachedMessages.lastOrNull;
      final canUseDelta = preferDelta && cachedMessages.isNotEmpty;
      final messagesResult = await getChatMessages(
        GetChatMessagesParams(
          projectId: projectProvider.currentProjectId,
          sessionId: session.id,
          directory: projectProvider.currentDirectory,
          limit: canUseDelta ? _defaultOlderMessagesChunkSize : null,
        ),
      );

      messagesResult.fold(
        (failure) {
          _traceFinal(
            'refresh-active-failure',
            sessionId: session.id,
            details: 'reason=$reason failure=${failure.runtimeType}',
          );
          AppLogger.warn(
            'Failed to refresh active session messages for ${session.id}: $failure',
          );
        },
        (messages) {
          if (_currentSession?.id != session.id) {
            return;
          }
          var serverMessagesForMerge = messages;
          var requiresFullFetch = false;
          if (canUseDelta) {
            final deltaResult = _mergeServerTailWithCachedMessages(
              serverMessages: messages,
              cachedMessages: cachedMessages,
              sessionId: session.id,
            );
            serverMessagesForMerge = deltaResult.messages;
            requiresFullFetch = deltaResult.requiresFullFetch;
          }
          _messages = _mergeServerMessagesWithActiveLocalTail(
            serverMessagesForMerge,
            sessionId: session.id,
          );
          _cacheSessionMessages(session.id, _messages);
          _messagesVersion++;
          _hasMoreOldMessages =
              serverMessagesForMerge.length >= _defaultOlderMessagesChunkSize;
          _prunePendingLocalUserMessageIdsToVisibleUsers();
          _pruneQueuedLocalUserMessageIdsToVisibleUsers();
          notifyListeners();
          _traceFinal(
            'refresh-active-merged',
            sessionId: session.id,
            details: 'reason=$reason mergedMessages=${_messages.length}',
          );
          _scheduleAutoTitleRefresh(session.id);
          unawaited(
            _persistSessionMessagesSnapshotBestEffort(session.id, _messages),
          );
          final hasActiveLocalStream =
              _activeMessageStreamSessionId == session.id &&
              _messageSubscription != null;
          final latestSessionMessage = _messages.lastOrNull;
          final latestSessionMessageChanged =
              latestSessionMessage != previousLatestSessionMessage;
          if (!_isCompactingContext &&
              (hasActiveLocalStream ||
                  _state == ChatState.sending ||
                  latestSessionMessageChanged)) {
            _scheduleScrollToBottom();
          }
          if (requiresFullFetch && _currentSession?.id == session.id) {
            unawaited(
              refreshActiveSessionView(
                reason: '$reason:delta-fallback',
                includeStatus: false,
                allowDuringAbortSuppression: allowDuringAbortSuppression,
                preferDelta: false,
              ),
            );
          }
        },
      );

      if (includeStatus) {
        await refreshSessionStatusSnapshot();
      }
    } finally {
      _activeSessionRefreshInFlight = false;
      _traceFinal(
        'refresh-active-finished',
        sessionId: session.id,
        details: 'reason=$reason includeStatus=$includeStatus',
      );
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
        _syncAttentionFromStatusMap(statusMap);
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
          _syncAttentionFromStatusMap(statusMap);
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

  Future<void> onProjectScopeChanged({bool waitForRevalidation = true}) async {
    await _switchContext(
      reason: 'project',
      waitForRevalidation: waitForRevalidation,
    );
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
    final previousModelKey = _currentModelKey();
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
    _recordModelSelectionRecency(previousModelKey: previousModelKey);
    _recordVariantSelectionRecencyForCurrentModel();
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
    final previousModelKey = _currentModelKey();
    _selectedProviderId = providerId;
    _selectedModelId = modelId;
    _selectedVariantId = _resolveStoredVariantForSelection();
    _recordModelSelectionRecency(previousModelKey: previousModelKey);
    _recordVariantSelectionRecencyForCurrentModel();
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

  Future<void> cycleRecentModelShortcut() async {
    final candidates = _availableModelCycleKeys();
    if (candidates.isEmpty) {
      return;
    }

    final currentModelKey = _currentModelKey();
    final nextModelKey = _nextShortcutCycleTarget(
      domain: _ShortcutCycleDomain.model,
      currentKey: currentModelKey,
      candidateKeys: candidates,
      historyKeys: _recentModelKeys,
    );
    if (nextModelKey == null || nextModelKey == currentModelKey) {
      return;
    }

    final providerId = _providerFromModelKey(nextModelKey);
    final modelId = _modelFromModelKey(nextModelKey);
    if (providerId == null || modelId == null) {
      return;
    }

    await setSelectedModelByProvider(providerId: providerId, modelId: modelId);
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
    final previousAgentName = _selectedAgentName;
    _selectedAgentName = next;
    _recordAgentSelectionRecency(previousAgentName: previousAgentName);
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
    final previousVariantId = _selectedVariantId;
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

    _recordVariantSelectionRecencyForCurrentModel(
      previousVariantId: previousVariantId,
    );

    _storeCurrentSessionSelectionOverride();
    await _persistSelection();
    notifyListeners();
  }

  Future<void> cycleVariant() async {
    final model = selectedModel;
    if (model == null || model.variants.isEmpty) {
      return;
    }
    final currentModelKey = _currentModelKey();
    if (currentModelKey == null) {
      return;
    }
    final nextVariantValue = _nextShortcutCycleTarget(
      domain: _ShortcutCycleDomain.variant,
      currentKey: _variantHistoryValue(_selectedVariantId),
      candidateKeys: _availableVariantCycleValues(model),
      historyKeys:
          _recentVariantValuesByModel[currentModelKey] ?? const <String>[],
    );
    if (nextVariantValue == null) {
      return;
    }
    final nextVariantId = _variantIdFromHistoryValue(nextVariantValue);
    if (nextVariantId == _selectedVariantId) {
      return;
    }
    await setSelectedVariant(nextVariantId);
  }

  /// Cycle to the next (or previous) selectable agent.
  /// Returns the name of the newly selected agent, or null when the list
  /// is empty and no cycling was performed.
  Future<String?> cycleAgent({bool reverse = false}) async {
    final candidates = selectableAgents
        .map((agent) => agent.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return null;
    }

    final nextAgentName = _nextShortcutCycleTarget(
      domain: _ShortcutCycleDomain.agent,
      currentKey: _selectedAgentName,
      candidateKeys: candidates,
      historyKeys: _recentAgentNames,
      reverse: reverse,
    );
    if (nextAgentName == null) {
      return null;
    }
    if (nextAgentName == _selectedAgentName) {
      return nextAgentName;
    }

    await setSelectedAgent(nextAgentName);
    return nextAgentName;
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
  Future<void> loadSessions({bool preserveVisibleState = false}) async {
    if (_state == ChatState.loading) return;
    final fetchId = ++_sessionsFetchId;

    final canKeepVisibleState = preserveVisibleState && _sessions.isNotEmpty;
    if (!canKeepVisibleState) {
      _setState(ChatState.loading);
    }
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

      Future<void> revalidateFromServer({
        required bool preserveVisibleDataOnFailure,
      }) async {
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
            if (preserveVisibleDataOnFailure) {
              AppLogger.warn(
                'Background session revalidation failed for scope=$scopeId',
                error: failure,
              );
              _setState(ChatState.loaded);
            } else {
              _handleFailure(failure);
            }
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
        _pruneSessionAttentionStateToKnownSessions();
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
      }

      final canRevalidateInBackground =
          preserveVisibleState && _sessions.isNotEmpty;
      if (canRevalidateInBackground) {
        unawaited(
          revalidateFromServer(preserveVisibleDataOnFailure: true).catchError((
            Object error,
            StackTrace stackTrace,
          ) {
            if (fetchId != _sessionsFetchId) {
              return;
            }
            AppLogger.warn(
              'Background session revalidation threw unexpectedly',
              error: error,
              stackTrace: stackTrace,
            );
          }),
        );
        return;
      }

      await revalidateFromServer(preserveVisibleDataOnFailure: false);
    } catch (e, stackTrace) {
      if (fetchId != _sessionsFetchId) {
        return;
      }
      if (preserveVisibleState && _sessions.isNotEmpty) {
        AppLogger.warn(
          'Failed to load session list during background refresh',
          error: e,
          stackTrace: stackTrace,
        );
        _setState(ChatState.loaded);
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
        _isLoadingOlderMessages = false;
        _hasMoreOldMessages = messages.length >= _defaultOlderMessagesChunkSize;
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

      if (_isNewChatDraftActive) {
        _currentSession = null;
        _threadPermissionsVersion++;
        _messages = <ChatMessage>[];
        _isLoadingOlderMessages = false;
        _hasMoreOldMessages = false;
        _messagesVersion++;
        _setState(ChatState.loaded);
        return;
      }

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
        final restoredCachedMessages = await _restoreSessionMessagesFromCache(
          targetSession.id,
          serverId: serverId,
          scopeId: scopeId,
        );
        if (restoredCachedMessages != null &&
            restoredCachedMessages.isNotEmpty) {
          _messages = List<ChatMessage>.from(restoredCachedMessages);
          _cacheSessionMessages(targetSession.id, _messages);
          _hasMoreOldMessages =
              restoredCachedMessages.length >= _defaultOlderMessagesChunkSize;
          _messagesVersion++;
          _setState(ChatState.loaded);
          unawaited(loadMessages(targetSession.id, preserveVisibleState: true));
        } else {
          await loadMessages(targetSession.id);
        }
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
  Future<void> beginNewChatDraft() async {
    final outgoingSessionId = _currentSession?.id;
    if (outgoingSessionId != null && _messages.isNotEmpty) {
      _cacheSessionMessages(outgoingSessionId, _messages);
      unawaited(
        _persistSessionMessagesSnapshotBestEffort(outgoingSessionId, _messages),
      );
    }

    _lazySessionBootstrapTask = null;
    _currentSession = null;
    _isNewChatDraftActive = true;
    _threadPermissionsVersion++;
    _messages = <ChatMessage>[];
    _isLoadingOlderMessages = false;
    _hasMoreOldMessages = false;
    _messagesVersion++;
    _pendingLocalUserMessageIds.clear();
    _clearQueuedSendState();
    _clearRejectedDraft();
    _sessionInsightsError = null;

    final serverId = await _resolveServerScopeId();
    final scopeId = _resolveContextScopeId();
    await _saveCurrentSessionId('', serverId: serverId, scopeId: scopeId);

    _setState(ChatState.loaded);
  }

  /// Create new session
  Future<void> createNewSession({String? parentId, String? title}) async {
    final contextKeyAtStart = _activeContextKey;
    _isNewChatDraftActive = false;
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

    if (contextKeyAtStart != _activeContextKey) {
      AppLogger.info(
        'Ignoring createNewSession result after context switch from=$contextKeyAtStart to=$_activeContextKey',
      );
      return;
    }

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
    _isLoadingOlderMessages = false;
    _hasMoreOldMessages = false;
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
    _isNewChatDraftActive = false;
    if (_currentSession?.id == session.id) {
      unawaited(loadSessionInsights(session.id, silent: true));
      return;
    }

    final outgoingSessionId = _currentSession?.id;
    if (outgoingSessionId != null && _messages.isNotEmpty) {
      _cacheSessionMessages(outgoingSessionId, _messages);
      unawaited(
        _persistSessionMessagesSnapshotBestEffort(outgoingSessionId, _messages),
      );
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

    // Save current session ID and try cache-first restore (SWR).
    final serverId = await _resolveServerScopeId();
    final scopeId = _resolveContextScopeId();

    final restoredCachedMessages = await _restoreSessionMessagesFromCache(
      session.id,
      serverId: serverId,
      scopeId: scopeId,
    );

    _pendingLocalUserMessageIds.clear();
    _clearQueuedSendState();
    _clearRejectedDraft();
    _currentSession = session;
    _isLoadingOlderMessages = false;
    _hasMoreOldMessages = false;
    _clearSessionAttentionForSession(session.id);
    _threadPermissionsVersion++;
    _applySelectionPriorityForCurrentSession();
    if (restoredCachedMessages != null && restoredCachedMessages.isNotEmpty) {
      _messages = List<ChatMessage>.from(restoredCachedMessages);
      _cacheSessionMessages(session.id, _messages);
      _hasMoreOldMessages =
          restoredCachedMessages.length >= _defaultOlderMessagesChunkSize;
      _messagesVersion++;
      _setState(ChatState.loaded);
    } else {
      _messages.clear();
      _messagesVersion++;
      notifyListeners();
    }

    await _saveCurrentSessionId(
      session.id,
      serverId: serverId,
      scopeId: scopeId,
    );

    // SWR behavior: if cache exists, keep visible data and revalidate silently.
    if (restoredCachedMessages != null && restoredCachedMessages.isNotEmpty) {
      unawaited(loadMessages(session.id, preserveVisibleState: true));
    } else {
      await loadMessages(session.id);
    }

    // Insights are non-critical and run fire-and-forget.
    unawaited(loadSessionInsights(session.id, silent: true));
    _scheduleQueuedSendDrain(session.id, reason: 'session-selected');
  }

  /// Load message list
  Future<void> loadMessages(
    String sessionId, {
    bool preserveVisibleState = false,
    bool preferDelta = true,
  }) async {
    final fetchId = ++_messagesFetchId;
    // Sync project ID from ProjectProvider; projectId is optional for the new API
    _currentProjectId = projectProvider.currentProjectId;

    final canKeepVisibleState =
        preserveVisibleState &&
        _currentSession?.id == sessionId &&
        _messages.isNotEmpty;
    final cachedMessages = canKeepVisibleState
        ? List<ChatMessage>.from(
            _messages.where((message) => message.sessionId == sessionId),
          )
        : const <ChatMessage>[];
    if (!canKeepVisibleState) {
      _setState(ChatState.loading);
    }

    final result = await getChatMessages(
      GetChatMessagesParams(
        projectId: projectProvider.currentProjectId,
        sessionId: sessionId,
        directory: projectProvider.currentDirectory,
        limit: canKeepVisibleState && preferDelta
            ? _defaultOlderMessagesChunkSize
            : null,
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
        var serverMessagesForMerge = messages;
        var requiresFullFetch = false;
        if (canKeepVisibleState && preferDelta && cachedMessages.isNotEmpty) {
          final deltaResult = _mergeServerTailWithCachedMessages(
            serverMessages: messages,
            cachedMessages: cachedMessages,
            sessionId: sessionId,
          );
          serverMessagesForMerge = deltaResult.messages;
          requiresFullFetch = deltaResult.requiresFullFetch;
        }
        _messages = _mergeServerMessagesWithActiveLocalTail(
          serverMessagesForMerge,
          sessionId: sessionId,
        );
        _cacheSessionMessages(sessionId, _messages);
        _messagesVersion++;
        _hasMoreOldMessages =
            serverMessagesForMerge.length >= _defaultOlderMessagesChunkSize;
        _prunePendingLocalUserMessageIdsToVisibleUsers();
        _pruneQueuedLocalUserMessageIdsToVisibleUsers();
        _scheduleAutoTitleRefresh(sessionId);
        _setState(ChatState.loaded);
        unawaited(_persistLastSessionSnapshotBestEffort());
        unawaited(
          _persistSessionMessagesSnapshotBestEffort(sessionId, _messages),
        );
        _scheduleQueuedSendDrain(sessionId, reason: 'load-messages');
        if (requiresFullFetch && _currentSession?.id == sessionId) {
          unawaited(
            loadMessages(
              sessionId,
              preserveVisibleState: true,
              preferDelta: false,
            ),
          );
        }
      },
    );
  }

  Future<void> loadOlderMessages({
    int chunkSize = _defaultOlderMessagesChunkSize,
  }) async {
    final sessionId = _currentSession?.id;
    if (sessionId == null || sessionId.trim().isEmpty) {
      return;
    }
    if (_isLoadingOlderMessages || chunkSize <= 0) {
      return;
    }

    _isLoadingOlderMessages = true;
    _notifyListeners();
    final requestedLimit = _messages.length + chunkSize;

    try {
      final result = await getChatMessages(
        GetChatMessagesParams(
          projectId: projectProvider.currentProjectId,
          sessionId: sessionId,
          directory: projectProvider.currentDirectory,
          limit: requestedLimit,
        ),
      );

      result.fold(
        (failure) {
          AppLogger.warn(
            'Failed to load older messages for session=$sessionId: $failure',
          );
        },
        (messages) {
          if (_currentSession?.id != sessionId) {
            return;
          }
          _messages = _mergeServerMessagesWithActiveLocalTail(
            messages,
            sessionId: sessionId,
          );
          _cacheSessionMessages(sessionId, _messages);
          _messagesVersion++;
          _hasMoreOldMessages = messages.length >= requestedLimit;
          _notifyListeners();
          unawaited(_persistLastSessionSnapshotBestEffort());
          unawaited(
            _persistSessionMessagesSnapshotBestEffort(sessionId, _messages),
          );
        },
      );
    } finally {
      _isLoadingOlderMessages = false;
      _notifyListeners();
    }
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
    if (trimmedText.isEmpty && effectiveAttachments.isEmpty) {
      return;
    }

    if (session == null) {
      await sendMessage(
        trimmedText,
        attachments: effectiveAttachments,
        shellMode: shellMode,
      );
      return;
    }

    final sessionId = session.id;
    final hasQueuedMessages = queuedMessageCountForSession(sessionId) > 0;
    _traceFinal(
      'submit-message-with-queue',
      sessionId: sessionId,
      details:
          'textLen=${trimmedText.length} attachments=${effectiveAttachments.length} shellMode=$shellMode hasQueued=$hasQueuedMessages busy=${_isSessionBusyForQueuedSend(sessionId)}',
    );
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
      _traceFinal(
        'queue-message-enqueued',
        sessionId: sessionId,
        details: 'size=${queue.length} localMessageId=$localMessageId',
      );
      if (!_isSessionBusyForQueuedSend(sessionId)) {
        _scheduleQueuedSendDrain(sessionId, reason: 'queue-while-idle');
      } else {
        final hasLiveStreamForSession =
            _activeMessageStreamSessionId == sessionId &&
            _messageSubscription != null;
        if (!hasLiveStreamForSession) {
          _traceFinal(
            'queue-message-retry-scheduled',
            sessionId: sessionId,
            details: 'reason=no-live-stream-while-busy',
          );
          _scheduleQueuedSendRetryOnce(sessionId);
        }
      }
      return;
    }

    _traceFinal(
      'submit-message-direct-send',
      sessionId: sessionId,
      details: 'textLen=${trimmedText.length}',
    );
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
    _traceFinal(
      'queue-drain-schedule',
      sessionId: sessionId,
      details:
          'reason=$reason allowRetrySchedule=$allowRetrySchedule inFlight=${_queuedDrainInFlightSessionIds.contains(sessionId)}',
    );
    if (_queuedDrainInFlightSessionIds.contains(sessionId)) {
      _queuedDrainDeferredSessionIds.add(sessionId);
      _traceFinal(
        'queue-drain-deferred',
        sessionId: sessionId,
        details: 'reason=$reason',
      );
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
    if (_queuedRetryTimersBySessionId.containsKey(normalizedSessionId)) {
      _traceFinal(
        'queue-retry-already-scheduled',
        sessionId: normalizedSessionId,
      );
      return;
    }

    final nextAttempt =
        (_queuedRetryAttemptsBySessionId[normalizedSessionId] ?? 0) + 1;
    if (nextAttempt > _queuedRetryMaxAttempts) {
      AppLogger.warn(
        'Provider queued retry reached max attempts session=$normalizedSessionId queue=${queuedMessageCountForSession(normalizedSessionId)}',
      );
      _traceFinal(
        'queue-retry-max-attempts',
        sessionId: normalizedSessionId,
        details: 'attempt=$nextAttempt max=$_queuedRetryMaxAttempts',
      );
      _queuedRetryAttemptsBySessionId.remove(normalizedSessionId);
      return;
    }
    _queuedRetryAttemptsBySessionId[normalizedSessionId] = nextAttempt;
    _traceFinal(
      'queue-retry-scheduled',
      sessionId: normalizedSessionId,
      details: 'attempt=$nextAttempt',
    );

    _queuedRetryTimersBySessionId[normalizedSessionId] = Timer(
      const Duration(seconds: 1),
      () {
        _queuedRetryTimersBySessionId.remove(normalizedSessionId);
        _traceFinal(
          'queue-retry-fired',
          sessionId: normalizedSessionId,
          details: 'attempt=$nextAttempt',
        );
        if (_currentSession?.id != normalizedSessionId) {
          _queuedRetryAttemptsBySessionId.remove(normalizedSessionId);
          _traceFinal(
            'queue-retry-cancelled-session-changed',
            sessionId: normalizedSessionId,
          );
          return;
        }
        if (queuedMessageCountForSession(normalizedSessionId) == 0) {
          _queuedRetryAttemptsBySessionId.remove(normalizedSessionId);
          _traceFinal(
            'queue-retry-cancelled-empty-queue',
            sessionId: normalizedSessionId,
          );
          return;
        }
        if (_isSessionBusyForQueuedSend(normalizedSessionId)) {
          _traceFinal(
            'queue-retry-rescheduled-busy',
            sessionId: normalizedSessionId,
          );
          _scheduleQueuedSendRetryOnce(normalizedSessionId);
          return;
        }
        _queuedRetryAttemptsBySessionId.remove(normalizedSessionId);
        _traceFinal(
          'queue-retry-drain-trigger',
          sessionId: normalizedSessionId,
        );
        _scheduleQueuedSendDrain(
          normalizedSessionId,
          reason: 'retry-after-failure',
          allowRetrySchedule: false,
        );
      },
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
    _traceFinal(
      'queue-drain-start',
      sessionId: sessionId,
      details:
          'reason=$reason allowRetrySchedule=$allowRetrySchedule inFlight=${_queuedDrainInFlightSessionIds.contains(sessionId)}',
    );
    if (_queuedDrainInFlightSessionIds.contains(sessionId)) {
      _traceFinal(
        'queue-drain-skip-inflight',
        sessionId: sessionId,
        details: 'reason=$reason',
      );
      return false;
    }
    _queuedDrainInFlightSessionIds.add(sessionId);

    try {
      if (_currentSession?.id != sessionId) {
        _traceFinal(
          'queue-drain-skip-session-changed',
          sessionId: sessionId,
          details: 'reason=$reason current=${_currentSession?.id ?? "-"}',
        );
        return false;
      }
      if (_isSessionBusyForQueuedSend(sessionId)) {
        _traceFinal(
          'queue-drain-skip-busy',
          sessionId: sessionId,
          details: 'reason=$reason',
        );
        return false;
      }

      final queue = _queuedSendBySessionId[sessionId];
      if (queue == null || queue.isEmpty) {
        _queuedRetryAttemptsBySessionId.remove(sessionId);
        _queuedSendBySessionId.remove(sessionId);
        _syncQueuedLocalUserMessageIds();
        _notifyListeners();
        _traceFinal(
          'queue-drain-noop-empty',
          sessionId: sessionId,
          details: 'reason=$reason',
        );
        return false;
      }

      final queuedBatch = queue.toList(growable: false);
      final payload = _buildMergedQueuedPayload(queuedBatch);
      if (payload.text.isEmpty && payload.attachments.isEmpty) {
        _queuedRetryAttemptsBySessionId.remove(sessionId);
        _queuedSendBySessionId.remove(sessionId);
        _syncQueuedLocalUserMessageIds();
        _notifyListeners();
        _traceFinal(
          'queue-drain-noop-empty-payload',
          sessionId: sessionId,
          details: 'reason=$reason batch=${queuedBatch.length}',
        );
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
      _traceFinal(
        'queue-drain-dispatch',
        sessionId: sessionId,
        details:
            'reason=$reason batch=${queuedBatch.length} payloadTextLen=${payload.text.length} attachments=${payload.attachments.length}',
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
        _traceFinal(
          'queue-drain-dispatch-failed',
          sessionId: sessionId,
          details:
              'reason=$reason allowRetrySchedule=$allowRetrySchedule batch=${queuedBatch.length}',
        );
        if (allowRetrySchedule) {
          _scheduleQueuedSendRetryOnce(sessionId);
        }
        _notifyListeners();
        return false;
      }

      _queuedRetryAttemptsBySessionId.remove(sessionId);
      _queuedSendBySessionId.remove(sessionId);
      _syncQueuedLocalUserMessageIds();
      _notifyListeners();
      _traceFinal(
        'queue-drain-dispatch-ok',
        sessionId: sessionId,
        details: 'reason=$reason batch=${queuedBatch.length}',
      );
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
        _traceFinal('queue-drain-run-deferred', sessionId: sessionId);
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
    if (trimmedText.isEmpty && effectiveAttachments.isEmpty) {
      return;
    }
    if (_currentSession == null) {
      await sendMessage(
        trimmedText,
        attachments: effectiveAttachments,
        shellMode: shellMode,
      );
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
    _traceFinal('interrupt-await-start', sessionId: sessionId);
    for (
      var attempt = 0;
      attempt < _interruptSendStatusMaxAttempts;
      attempt += 1
    ) {
      if (_currentSession?.id != sessionId) {
        _traceFinal(
          'interrupt-await-cancelled-session-changed',
          sessionId: sessionId,
          details: 'attempt=$attempt current=${_currentSession?.id ?? "-"}',
        );
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
      _traceFinal(
        'interrupt-await-check',
        sessionId: sessionId,
        details:
            'attempt=$attempt status=${statusType?.name ?? "-"} hasBusyStatus=$hasBusyStatus hasActiveLocalStream=$hasActiveLocalStream isAborting=$_isAbortingResponse',
      );

      if (!hasBusyStatus && !hasActiveLocalStream && !_isAbortingResponse) {
        settled = true;
        _traceFinal(
          'interrupt-await-settled',
          sessionId: sessionId,
          details: 'attempt=$attempt',
        );
        break;
      }

      await Future<void>.delayed(_interruptSendStatusPollInterval);
    }

    if (!settled) {
      AppLogger.warn(
        'Provider interrupt-and-send proceeding without settled status session=$sessionId',
      );
      _traceFinal('interrupt-await-timeout', sessionId: sessionId);
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
    if (trimmedText.isEmpty && effectiveAttachments.isEmpty) {
      return false;
    }

    if (!hasSessionOverride && _currentSession == null) {
      final inFlight = _lazySessionBootstrapTask;
      if (inFlight != null) {
        await inFlight;
      } else {
        _lazySessionBootstrapTask = createNewSession();
        try {
          await _lazySessionBootstrapTask;
        } finally {
          _lazySessionBootstrapTask = null;
        }
      }
      if (_currentSession == null) {
        return false;
      }
    }

    final sendSessionId = hasSessionOverride
        ? normalizedSessionOverride
        : _currentSession!.id;
    AppLogger.info(
      'Provider send start session=$sendSessionId agent=${_selectedAgentName ?? "-"} provider=${_selectedProviderId ?? "-"} model=${_selectedModelId ?? "-"} variant=${_selectedVariantId ?? "auto"}',
    );
    _traceFinal(
      'send-start',
      sessionId: sendSessionId,
      details:
          'textLen=${trimmedText.length} attachments=${effectiveAttachments.length} shell=$shellMode sessionOverride=$hasSessionOverride',
    );
    _setActiveSendDraft(
      trimmedText,
      attachments: effectiveAttachments,
      shellMode: shellMode,
    );
    _setState(ChatState.sending);
    _traceFinal('send-state-sending', sessionId: sendSessionId);

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
      _traceFinal(
        'send-local-user-appended',
        sessionId: sendSessionId,
        details:
            'localMessageId=$activeLocalMessageId appendOptimistic=$appendOptimisticMessage',
      );
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
        messageId: activeLocalMessageId,
        mode: shellMode ? 'shell' : selectedAgentForSend,
        parts: inputParts,
      );

      // Cancel previous subscription and invalidate stale callbacks.
      final hasOtherSessionActiveStream =
          _messageSubscription != null &&
          _activeMessageStreamSessionId != null &&
          _activeMessageStreamSessionId != sendSessionId;
      _traceFinal(
        'send-cancel-previous-subscription',
        sessionId: sendSessionId,
        details:
            'preserveOtherSession=$hasOtherSessionActiveStream previousActive=${_activeMessageStreamSessionId ?? "-"}',
      );
      await _cancelActiveMessageSubscription(
        reason: 'start-send',
        invalidateGeneration: true,
        preserveActiveStream: hasOtherSessionActiveStream,
      );
      final streamGeneration = _messageStreamGeneration;
      final streamSessionId = sendSessionId;
      _activeMessageStreamSessionId = streamSessionId;
      // Reset one-shot reconcile guard so the new turn can trigger a reconcile
      // if the final message ends up missing.
      _lastIdleReconcileSessionTurnKey = null;
      _deferredIdleReconcileTurnKeyBySessionId.remove(streamSessionId);
      _traceFinal(
        'send-stream-ready',
        sessionId: streamSessionId,
        details: 'generation=$streamGeneration',
      );

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
                _traceFinal(
                  'send-stream-event-ignored-stale-generation',
                  sessionId: streamSessionId,
                  details:
                      'eventGeneration=$streamGeneration active=$_messageStreamGeneration',
                );
                return;
              }
              result.fold(
                (failure) {
                  _traceFinal(
                    'send-stream-failure-event',
                    sessionId: streamSessionId,
                    details:
                        'failure=${failure.runtimeType} message=${failure.message}',
                  );
                  if (_shouldSuppressAbortError(
                    sessionId: streamSessionId,
                    message: failure.message,
                  )) {
                    AppLogger.info(
                      'Suppressing expected abort failure session=$streamSessionId',
                    );
                    _traceFinal(
                      'send-stream-failure-suppressed',
                      sessionId: streamSessionId,
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
                    _traceFinal(
                      'send-stream-failure-background-session',
                      sessionId: streamSessionId,
                    );
                    _sessionStatusById[streamSessionId] =
                        const SessionStatusInfo(type: SessionStatusType.idle);
                    _sessionUnreadCompletionIds.remove(streamSessionId);
                    _sessionErrorAttentionIds.add(streamSessionId);
                    _notifyListeners();
                    return;
                  }
                  _handleFailure(failure);
                },
                (message) {
                  final completed = message is AssistantMessage
                      ? message.isCompleted
                      : false;
                  _traceFinal(
                    'send-stream-message-event',
                    sessionId: streamSessionId,
                    details:
                        'messageId=${message.id} role=${message.role} completed=$completed parts=${message.parts.length}',
                  );
                  _updateOrAddMessage(message);
                },
              );
            },
            onError: (error) {
              _traceFinal(
                'send-stream-onerror',
                sessionId: streamSessionId,
                details: 'error=$error',
              );
              final deferredIdleTurnKey =
                  _deferredIdleReconcileTurnKeyBySessionId.remove(
                    streamSessionId,
                  );
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
                _traceFinal(
                  'send-stream-onerror-stale-generation-finalized',
                  sessionId: streamSessionId,
                  details:
                      'eventGeneration=$streamGeneration active=$_messageStreamGeneration',
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
                _sessionUnreadCompletionIds.remove(streamSessionId);
                _sessionErrorAttentionIds.add(streamSessionId);
                _notifyListeners();
                return;
              }
              if (deferredIdleTurnKey != null &&
                  deferredIdleTurnKey.isNotEmpty &&
                  _lastIdleReconcileSessionTurnKey != deferredIdleTurnKey) {
                _lastIdleReconcileSessionTurnKey = deferredIdleTurnKey;
                _traceFinal(
                  'send-stream-onerror-run-deferred-idle-reconcile',
                  sessionId: streamSessionId,
                  details:
                      'turnKey=$deferredIdleTurnKey reason=session-idle-deferred-reconcile-onerror',
                );
                unawaited(
                  refreshActiveSessionView(
                    reason: 'session-idle-deferred-reconcile-onerror',
                    includeStatus: false,
                    allowDuringAbortSuppression: true,
                  ).catchError((Object reconcileError, StackTrace stackTrace) {
                    AppLogger.warn(
                      'Deferred idle reconcile after send stream error failed session=$streamSessionId',
                      error: reconcileError,
                      stackTrace: stackTrace,
                    );
                  }),
                );
              }
              _setError(
                'Failed to send message: $error',
                sessionId: streamSessionId,
              );
            },
            onDone: () {
              _traceFinal(
                'send-stream-ondone',
                sessionId: streamSessionId,
                details:
                    'eventGeneration=$streamGeneration active=$_messageStreamGeneration',
              );
              final deferredIdleTurnKey =
                  _deferredIdleReconcileTurnKeyBySessionId.remove(
                    streamSessionId,
                  );
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
                _traceFinal(
                  'send-stream-ondone-stale-generation-finalized',
                  sessionId: streamSessionId,
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
              _traceFinal(
                'send-stream-ondone-start-abort-suppression',
                sessionId: streamSessionId,
              );
              AppLogger.info(
                'Provider send stream finished session=$streamSessionId',
              );
              final previousStatusType =
                  _sessionStatusById[streamSessionId]?.type;
              _sessionStatusById[streamSessionId] = const SessionStatusInfo(
                type: SessionStatusType.idle,
              );
              if (_currentSession?.id == streamSessionId) {
                _markIncompleteAssistantMessagesAsCompleted(
                  sessionId: streamSessionId,
                );
                _setState(ChatState.loaded);
                if (deferredIdleTurnKey != null &&
                    deferredIdleTurnKey.isNotEmpty &&
                    _lastIdleReconcileSessionTurnKey != deferredIdleTurnKey) {
                  _lastIdleReconcileSessionTurnKey = deferredIdleTurnKey;
                  _traceFinal(
                    'send-stream-ondone-run-deferred-idle-reconcile',
                    sessionId: streamSessionId,
                    details:
                        'turnKey=$deferredIdleTurnKey reason=session-idle-deferred-reconcile',
                  );
                  unawaited(
                    refreshActiveSessionView(
                      reason: 'session-idle-deferred-reconcile',
                      includeStatus: false,
                      allowDuringAbortSuppression: true,
                    ).catchError((
                      Object reconcileError,
                      StackTrace stackTrace,
                    ) {
                      AppLogger.warn(
                        'Deferred idle reconcile after send stream completion failed session=$streamSessionId',
                        error: reconcileError,
                        stackTrace: stackTrace,
                      );
                    }),
                  );
                }
                unawaited(_persistLastSessionSnapshotBestEffort());
                unawaited(loadSessionInsights(streamSessionId, silent: true));
              } else {
                final clearedError = _sessionErrorAttentionIds.remove(
                  streamSessionId,
                );
                final addedUnread = _sessionUnreadCompletionIds.add(
                  streamSessionId,
                );
                // `Set.add` returns true only when the value is newly inserted.
                final statusChanged =
                    previousStatusType != SessionStatusType.idle;
                if (statusChanged || clearedError || addedUnread) {
                  _notifyListeners();
                }
              }
              _scheduleQueuedSendDrain(
                streamSessionId,
                reason: 'stream-finished',
              );
            },
          );
      _messageSubscription = sendSubscription;
      AppLogger.info('Provider send stream subscription attached');
      _traceFinal(
        'send-stream-subscription-attached',
        sessionId: streamSessionId,
      );
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
      _traceFinal(
        'send-setup-failed',
        sessionId: streamSessionId,
        details: 'error=$error',
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
      _clearSessionAttentionForSession(session.id);
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

    _removeSessionMessagesCache(sessionId);
    unawaited(_clearSessionMessagesSnapshotBestEffort(sessionId));

    _removeSessionById(sessionId);
    _sortSessionsInPlace();

    if (wasCurrent) {
      _currentSession = _sessions.firstOrNull;
      _threadPermissionsVersion++;
      _messages = <ChatMessage>[];
      _isLoadingOlderMessages = false;
      _hasMoreOldMessages = false;
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
        if (previousCurrent != null) {
          _cacheSessionMessages(previousCurrent.id, previousMessages);
          unawaited(
            _persistSessionMessagesSnapshotBestEffort(
              previousCurrent.id,
              previousMessages,
            ),
          );
        }
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
