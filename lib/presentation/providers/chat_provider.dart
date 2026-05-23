import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/feature_flags.dart';
import '../../core/errors/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/path_utils.dart';
import '../../data/datasources/app_local_datasource.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_realtime_model.dart';
import '../../data/models/chat_session_model.dart';
import '../../data/models/provider_model.dart';
import '../../data/models/session_lifecycle_model.dart';
import '../../domain/entities/agent.dart';
import '../../domain/entities/chat_composer_draft.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_realtime.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/provider.dart';
import '../../domain/entities/session.dart';
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
import '../../domain/usecases/revert_chat_message.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../../domain/usecases/share_chat_session.dart';
import '../../domain/usecases/summarize_chat_session.dart';
import '../../domain/usecases/unrevert_chat_messages.dart';
import '../../domain/usecases/unshare_chat_session.dart';
import '../../domain/usecases/update_chat_session.dart';
import '../../domain/usecases/watch_chat_events.dart';
import '../../domain/usecases/watch_global_chat_events.dart';
import '../services/chat_title_generator.dart';
import '../services/cellular_data_saver_service.dart';
import '../services/event_feedback_dispatcher.dart';
import '../utils/chat_abort_message.dart';
import '../utils/chat_assistant_settlement.dart';
import '../utils/chat_event_property_extractors.dart';
import '../utils/chat_server_error_formatter.dart';
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

class _SelectionPersistenceSnapshot {
  const _SelectionPersistenceSnapshot({
    required this.serverId,
    required this.scopeId,
    required this.selectedProviderId,
    required this.selectedModelId,
    required this.selectedAgentName,
    required this.recentModelsJson,
    required this.favoriteModelsJson,
    required this.pinnedSessionsJson,
    required this.modelUsageCountsJson,
    required this.selectedVariantMapJson,
    required this.agentSelectionMemoryJson,
    required this.sessionSelectionOverridesJson,
    required this.syncRemote,
  });

  final String serverId;
  final String scopeId;
  final String? selectedProviderId;
  final String? selectedModelId;
  final String? selectedAgentName;
  final String recentModelsJson;
  final String favoriteModelsJson;
  final String pinnedSessionsJson;
  final String modelUsageCountsJson;
  final String selectedVariantMapJson;
  final String agentSelectionMemoryJson;
  final String sessionSelectionOverridesJson;
  final bool syncRemote;

  _SelectionPersistenceSnapshot copyWith({bool? syncRemote}) {
    return _SelectionPersistenceSnapshot(
      serverId: serverId,
      scopeId: scopeId,
      selectedProviderId: selectedProviderId,
      selectedModelId: selectedModelId,
      selectedAgentName: selectedAgentName,
      recentModelsJson: recentModelsJson,
      favoriteModelsJson: favoriteModelsJson,
      pinnedSessionsJson: pinnedSessionsJson,
      modelUsageCountsJson: modelUsageCountsJson,
      selectedVariantMapJson: selectedVariantMapJson,
      agentSelectionMemoryJson: agentSelectionMemoryJson,
      sessionSelectionOverridesJson: sessionSelectionOverridesJson,
      syncRemote: syncRemote ?? this.syncRemote,
    );
  }
}

enum SessionListFilter { active, archived, all }

enum SessionListSort { recent, oldest, title }

enum ChatUiNoticeType { remoteAbort, serverError }

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
    this.revertChatMessage,
    this.unrevertChatMessages,
    required this.projectProvider,
    required this.localDataSource,
    this.settingsProvider,
    this.dioClient,
    CellularDataSaverService? cellularDataSaverService,
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
    _cellularDataSaverService =
        cellularDataSaverService ?? CellularDataSaverService.disabled();
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
    _cellularDataSaverService.addListener(_handleCellularDataSaverChanged);
  }

  @visibleForTesting
  bool debugIsOptimisticLocalUserMessageId(String messageId) =>
      _isOptimisticLocalUserMessageId(messageId);

  @visibleForTesting
  bool debugShouldSkipLocalUserAppendAsDuplicateEcho({
    required UserMessage localMessage,
    required List<ChatMessage> mergedMessages,
  }) {
    return _shouldSkipLocalUserAppendAsDuplicateEcho(
      localMessage: localMessage,
      mergedMessages: mergedMessages,
    );
  }

  // Scroll callback
  void Function({required String reason})? _scrollToBottomCallback;

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
  final RevertChatMessage? revertChatMessage;
  final UnrevertChatMessages? unrevertChatMessages;
  final ProjectProvider projectProvider;
  final AppLocalDataSource localDataSource;
  final SettingsProvider? settingsProvider;
  final DioClient? dioClient;
  late final CellularDataSaverService _cellularDataSaverService;
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
  int _cachedVisibleMessagesVersion = -1;
  String? _cachedVisibleMessagesSessionId;
  String? _cachedVisibleMessagesRevertId;
  String? _cachedVisibleMessagesBranchKey;
  List<ChatMessage> _cachedVisibleMessages = const <ChatMessage>[];
  // Monotonic counter bumped on every mutation that affects the visible
  // current-session permission list so the getter can reuse the same immutable
  // snapshot between rebuilds.
  int _threadPermissionsVersion = 0;
  int _cachedThreadPermissionsAtVersion = -1;
  List<ChatPermissionRequest> _cachedThreadPermissionRequests = const [];
  int _cachedThreadQuestionsAtVersion = -1;
  List<ChatQuestionRequest> _cachedThreadQuestionRequests = const [];
  String? _errorMessage;
  StreamSubscription<dynamic>? _messageSubscription;
  StreamSubscription<dynamic>? _eventSubscription;
  StreamSubscription<dynamic>? _globalEventSubscription;
  int _eventStreamGeneration = 0;
  Timer? _globalRefreshDebounce;
  final Map<String, Timer> _messageFallbackDebounceById = <String, Timer>{};
  bool _isRespondingInteraction = false;
  final Set<String> _dismissedInteractionTombstones = <String>{};
  Map<String, SessionStatusInfo> _sessionStatusById =
      <String, SessionStatusInfo>{};
  Map<String, List<ChatPermissionRequest>> _pendingPermissionsBySession =
      <String, List<ChatPermissionRequest>>{};
  Map<String, List<ChatQuestionRequest>> _pendingQuestionsBySession =
      <String, List<ChatQuestionRequest>>{};
  final Set<String> _sessionUnreadCompletionIds = <String>{};
  final Map<String, DateTime> _sessionUnreadCompletionTimestamps =
      <String, DateTime>{};
  final Set<String> _sessionErrorAttentionIds = <String>{};
  final Set<String> _sseSettledToIdleSessionIds = <String>{};
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
  int _localMessageIdSequence = 0;
  bool _activeSessionRefreshInFlight = false;
  bool _isLoadingOlderMessages = false;
  bool _hasMoreOldMessages = false;
  // Tracks an existing selected session whose timeline is still hydrating.
  String? _pendingCurrentSessionHydrationId;
  bool _isAbortingResponse = false;
  bool _isCompactingContext = false;
  bool _isAppInForeground = true;
  bool _isChatRouteActive = true;
  String? _abortSuppressionSessionId;
  DateTime? _abortSuppressionStartedAt;
  ChatUiNotice? _pendingUiNotice;
  int _messageStreamGeneration = 0;
  String? _activeMessageStreamSessionId;
  String? _preserveBusyStatusOnNextStreamDoneSessionId;
  ChatComposerDraft? _activeSendDraft;
  bool _isNewChatDraftActive = false;
  Future<void>? _lazySessionBootstrapTask;
  _RejectedDraftEnvelope? _rejectedDraft;
  _HistoryComposerSync? _pendingHistoryComposerSync;
  _PendingReplacementBranch? _pendingReplacementBranch;
  int _historyComposerSyncToken = 0;
  bool _historyRevertInFlight = false;
  final LinkedHashMap<String, List<ChatMessage>> _sessionMessagesLruCache =
      LinkedHashMap<String, List<ChatMessage>>();

  // Project and provider-related state
  String? _currentProjectId;
  List<Provider> _providers = [];
  Map<String, String> _defaultModels = {};
  List<String> _connectedProviderIds = <String>[];
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
  Set<String> _pinnedSessionIds = <String>{};
  bool _hasLoadedSessionsAuthoritatively = false;
  Map<String, int> _modelUsageCounts = <String, int>{};
  Map<String, String> _selectedVariantByModel = <String, String>{};
  Map<String, _AgentSelectionMemory> _agentSelectionMemoryByAgent =
      <String, _AgentSelectionMemory>{};
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
  Future<void>? _selectionPersistenceTask;
  bool _selectionPersistenceDirty = false;
  bool _selectionPersistenceSyncRemote = false;
  String _activeContextKey = 'legacy::default';
  final Map<String, _ChatContextSnapshot> _contextSnapshots =
      <String, _ChatContextSnapshot>{};
  final Map<String, _SessionSelectionOverride> _sessionSelectionOverridesByKey =
      <String, _SessionSelectionOverride>{};
  final Set<String> _dirtyContextKeys = <String>{};
  Timer? _syncHealthTimer;
  Timer? _degradedPollingTimer;
  Timer? _foregroundResumeSyncTimer;
  Timer? _sessionUnreadHighlightTimer;
  bool _idleRealtimePausedForDataSaver = false;
  int _foregroundResumeSyncCycleCount = 0;
  DateTime? _lastRealtimeSignalAt;
  ChatSyncState _syncState = ChatSyncState.reconnecting;
  bool _isForegroundActive = true;
  bool _degradedMode = false;
  bool _isForegroundResumeSyncing = false;
  bool _foregroundResumeReconcileInFlight = false;
  final Map<String, DateTime> _lastAutomaticSessionInsightsAtBySessionId =
      <String, DateTime>{};
  bool _realtimeSubscriptionRestartInFlight = false;
  bool _realtimeSubscriptionRestartQueued = false;
  bool _recoverableSyncAlertEscalated = false;
  DateTime? _degradedModeStartedAt;
  int _consecutiveRealtimeFailures = 0;
  bool _postReconnectRecoveryInFlight = false;
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
  final Set<String> _dedupeNextDeltaFieldKeys = <String>{};

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
  static const String _remoteAbortNoticeMessage = kChatAbortNoticeMessage;
  static const String _remoteAbortInlineErrorName = 'MessageAborted';
  static const String _optimisticLocalUserMessageIdPrefix = 'local_user_';
  static const String _traceFinalPrefix = 'CW_TRACE_FINAL';
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

  bool get _hasPendingThreadInteractions {
    for (final items in _pendingPermissionsBySession.values) {
      if (items.isNotEmpty) {
        return true;
      }
    }
    for (final items in _pendingQuestionsBySession.values) {
      if (items.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool get _shouldKeepRealtimeActiveForDataSaver {
    if (!_refreshlessRealtimeEnabled ||
        !_cellularDataSaverService.isDataSaverActive) {
      return true;
    }
    if (!_isForegroundActive) {
      return false;
    }
    if (_cellularDataSaverService.hasInteractiveBurst) {
      return true;
    }
    if (_state == ChatState.sending || isCurrentSessionActivelyResponding) {
      return true;
    }
    return _hasPendingThreadInteractions;
  }

  void _handleCellularDataSaverChanged() {
    if (!_refreshlessRealtimeEnabled) {
      return;
    }
    if (_cellularDataSaverService.shouldSuppressBackgroundWork) {
      _syncHealthTimer?.cancel();
      _syncHealthTimer = null;
      _degradedPollingTimer?.cancel();
      _degradedPollingTimer = null;
      _degradedMode = false;
      _degradedModeStartedAt = null;
    } else if (_isForegroundActive) {
      _startSyncHealthMonitor();
    }
    unawaited(_syncCellularDataSaverRealtimePolicy(reason: 'runtime-change'));
    _notifyListeners();
  }

  // Microtask coalescing for scroll-to-bottom: prevents multiple scroll jumps
  // per frame when several events trigger scroll simultaneously.
  bool _scrollScheduled = false;

  void _scheduleScrollToBottom({String reason = 'provider'}) {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    scheduleMicrotask(() {
      _scrollScheduled = false;
      _scrollToBottomCallback?.call(reason: reason);
    });
  }

  bool _shouldSchedulePassiveAutoScrollForSession(
    String sessionId, {
    ChatMessage? latestMessage,
  }) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty || _isCompactingContext) {
      return false;
    }
    final status = _sessionStatusById[normalizedSessionId]?.type;
    if (status != SessionStatusType.busy && status != SessionStatusType.retry) {
      return true;
    }

    ChatMessage? candidate = latestMessage;
    if (candidate == null) {
      for (var index = _messages.length - 1; index >= 0; index -= 1) {
        final message = _messages[index];
        if (message.sessionId == normalizedSessionId) {
          candidate = message;
          break;
        }
      }
    }
    if (candidate is! AssistantMessage) {
      return false;
    }

    final hasTextPart = candidate.parts.any(
      (part) => part is TextPart && part.text.trim().isNotEmpty,
    );
    return hasTextPart;
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
    final lastMessage = _messages.isEmpty ? '-' : _messages.last.id;
    final suffix = details == null || details.trim().isEmpty
        ? ''
        : ' details=${details.trim()}';

    AppLogger.info(
      '$_traceFinalPrefix provider event=$event session=$effectiveSessionId current=${currentSessionId ?? "-"} state=${_state.name} status=$statusLabel activeStream=${_activeMessageStreamSessionId ?? "-"} hasSub=${_messageSubscription != null} abortSuppressed=$abortSuppressed messages=${_messages.length} last=$lastMessage$suffix',
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
  List<ChatMessage> get messages => _visibleMessagesForCurrentSession();
  List<ChatMessage> get rawMessages =>
      List<ChatMessage>.unmodifiable(_messages);
  List<ChatMessage>? cachedMessagesForSession(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return null;
    }
    if (_currentSession?.id == normalizedSessionId) {
      return List<ChatMessage>.unmodifiable(rawMessages);
    }
    return _cachedSessionMessages(normalizedSessionId);
  }

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
  Set<String> get pinnedSessionIds => UnmodifiableSetView(_pinnedSessionIds);
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
  bool get isCurrentSessionHydrating =>
      _pendingCurrentSessionHydrationId != null &&
      _pendingCurrentSessionHydrationId == _currentSession?.id;
  SessionRevert? get currentSessionRevert => _currentSession?.revert;
  int get pendingHistoryComposerSyncToken =>
      _pendingHistoryComposerSync?.token ?? 0;

  List<ChatMessage> _visibleMessagesForCurrentSession() {
    final session = _currentSession;
    final revertMessageId = session?.revert?.messageId.trim();
    final sessionId = session?.id;
    final pendingBranch = _visiblePendingReplacementBranch;
    final pendingBranchKey = pendingBranch?.cacheKey;
    if (_cachedVisibleMessagesVersion == _messagesVersion &&
        _cachedVisibleMessagesSessionId == sessionId &&
        _cachedVisibleMessagesRevertId == revertMessageId &&
        _cachedVisibleMessagesBranchKey == pendingBranchKey) {
      return _cachedVisibleMessages;
    }
    if (pendingBranch != null) {
      return _cacheVisibleMessages(
        sessionId: sessionId,
        revertMessageId: revertMessageId,
        pendingBranchKey: pendingBranchKey,
        messages: List<ChatMessage>.unmodifiable(
          _applyPendingReplacementBranchToMessages(
            _messages,
            branch: pendingBranch,
          ),
        ),
      );
    }
    if (session == null || revertMessageId == null || revertMessageId.isEmpty) {
      return _cacheVisibleMessages(
        sessionId: sessionId,
        revertMessageId: revertMessageId,
        pendingBranchKey: pendingBranchKey,
        messages: List<ChatMessage>.unmodifiable(_messages),
      );
    }
    final boundaryIndex = _messages.indexWhere(
      (message) =>
          message.sessionId == session.id && message.id == revertMessageId,
    );
    if (boundaryIndex <= 0) {
      return _cacheVisibleMessages(
        sessionId: sessionId,
        revertMessageId: revertMessageId,
        pendingBranchKey: pendingBranchKey,
        messages: const <ChatMessage>[],
      );
    }
    return _cacheVisibleMessages(
      sessionId: sessionId,
      revertMessageId: revertMessageId,
      pendingBranchKey: pendingBranchKey,
      messages: List<ChatMessage>.unmodifiable(
        _messages.sublist(0, boundaryIndex),
      ),
    );
  }

  List<ChatMessage> _cacheVisibleMessages({
    required String? sessionId,
    required String? revertMessageId,
    required String? pendingBranchKey,
    required List<ChatMessage> messages,
  }) {
    _cachedVisibleMessagesVersion = _messagesVersion;
    _cachedVisibleMessagesSessionId = sessionId;
    _cachedVisibleMessagesRevertId = revertMessageId;
    _cachedVisibleMessagesBranchKey = pendingBranchKey;
    _cachedVisibleMessages = messages;
    return _cachedVisibleMessages;
  }

  _PendingReplacementBranch? get _visiblePendingReplacementBranch {
    final branch = _pendingReplacementBranch;
    final sessionId = _currentSession?.id;
    if (branch == null || sessionId == null || branch.sessionId != sessionId) {
      return null;
    }
    return branch;
  }

  List<ChatMessage> _applyPendingReplacementBranchToMessages(
    List<ChatMessage> messages, {
    required _PendingReplacementBranch branch,
  }) {
    final next = <ChatMessage>[];
    final rootMessageId = branch.replacementRootMessageId?.trim();
    var droppingRevertedTail = false;
    for (final message in messages) {
      if (message.sessionId != branch.sessionId) {
        next.add(message);
        continue;
      }
      if (!droppingRevertedTail) {
        if (message.id == branch.revertMessageId) {
          droppingRevertedTail = true;
          continue;
        }
        next.add(message);
        continue;
      }
      if (rootMessageId != null &&
          rootMessageId.isNotEmpty &&
          message.id == rootMessageId) {
        droppingRevertedTail = false;
        next.add(message);
      }
    }
    return next;
  }

  void _startPendingReplacementBranch({
    required String sessionId,
    required String revertMessageId,
  }) {
    final normalizedRevertMessageId = revertMessageId.trim();
    if (normalizedRevertMessageId.isEmpty) {
      return;
    }
    final branch = _PendingReplacementBranch(
      sessionId: sessionId,
      revertMessageId: normalizedRevertMessageId,
    );
    _pendingReplacementBranch = branch;
    final nextMessages = _applyPendingReplacementBranchToMessages(
      _messages,
      branch: branch,
    );
    final messagesChanged = nextMessages.length != _messages.length;
    if (messagesChanged) {
      _messages = nextMessages;
      _cacheSessionMessages(sessionId, _messages);
      _prunePendingLocalUserMessageIdsToVisibleUsers();
    }

    final currentSession = _currentSession;
    final revertChanged =
        currentSession?.id == sessionId && currentSession?.revert != null;
    if (revertChanged) {
      final updatedSession = currentSession!.copyWith(revert: null);
      _currentSession = updatedSession;
      final sessionIndex = _sessions.indexWhere((item) => item.id == sessionId);
      if (sessionIndex != -1) {
        _sessions[sessionIndex] = updatedSession;
      }
      unawaited(_persistSessionCacheBestEffort());
    }

    if (messagesChanged || revertChanged) {
      _messagesVersion++;
    }
  }

  void _setPendingReplacementBranchRootMessage({
    required String sessionId,
    required String messageId,
  }) {
    final branch = _pendingReplacementBranch;
    final normalizedMessageId = messageId.trim();
    if (branch == null ||
        branch.sessionId != sessionId ||
        normalizedMessageId.isEmpty ||
        branch.replacementRootMessageId == normalizedMessageId) {
      return;
    }
    _pendingReplacementBranch = branch.copyWith(
      replacementRootMessageId: normalizedMessageId,
    );
    _messagesVersion++;
  }

  void _clearPendingReplacementBranch({String? sessionId}) {
    final branch = _pendingReplacementBranch;
    if (branch == null) {
      return;
    }
    final normalizedSessionId = sessionId?.trim();
    if (normalizedSessionId != null &&
        normalizedSessionId.isNotEmpty &&
        branch.sessionId != normalizedSessionId) {
      return;
    }
    _pendingReplacementBranch = null;
    _messagesVersion++;
  }

  List<ChatMessage> _filterMessagesForPendingReplacementBranch(
    List<ChatMessage> messages, {
    required String sessionId,
  }) {
    final branch = _pendingReplacementBranch;
    if (branch == null || branch.sessionId != sessionId) {
      return messages;
    }
    return _applyPendingReplacementBranchToMessages(messages, branch: branch);
  }

  void _queueHistoryComposerSync({
    required String sessionId,
    ChatComposerDraft? draft,
    bool clear = false,
  }) {
    _pendingHistoryComposerSync = _HistoryComposerSync(
      token: ++_historyComposerSyncToken,
      sessionId: sessionId,
      draft: draft,
      clear: clear,
    );
  }

  _HistoryComposerSync? consumePendingHistoryComposerSync({String? sessionId}) {
    final pending = _pendingHistoryComposerSync;
    if (pending == null) {
      return null;
    }
    final expectedSessionId = sessionId?.trim();
    if (expectedSessionId != null &&
        expectedSessionId.isNotEmpty &&
        pending.sessionId != expectedSessionId) {
      return null;
    }
    _pendingHistoryComposerSync = null;
    return pending;
  }

  void _applyCurrentSessionRevert(SessionRevert? revert) {
    final session = _currentSession;
    if (session == null) {
      return;
    }
    final updatedSession = session.copyWith(revert: revert);
    _currentSession = updatedSession;
    final sessionIndex = _sessions.indexWhere((item) => item.id == session.id);
    if (sessionIndex != -1) {
      _sessions[sessionIndex] = updatedSession;
    }
    _messagesVersion++;
    unawaited(_persistSessionCacheBestEffort());
  }

  ChatComposerDraft? _buildComposerDraftFromUserMessage(UserMessage message) {
    final textParts = message.parts.whereType<TextPart>().toList(
      growable: false,
    );
    final fileParts = message.parts.whereType<FilePart>().toList(
      growable: false,
    );
    final joinedText = textParts.map((part) => part.text).join('\n').trim();
    final shellMode = joinedText.startsWith('!');
    final normalizedText = shellMode
        ? joinedText.substring(1).trimLeft()
        : joinedText;
    final attachments = shellMode
        ? const <FileInputPart>[]
        : List<FileInputPart>.unmodifiable(
            fileParts.map(
              (part) => FileInputPart(
                mime: part.mime,
                url: part.url,
                filename: part.filename,
                source: part.fileSource == null
                    ? null
                    : FileInputSource(
                        path: part.fileSource!.path,
                        text: FileInputSourceText(
                          value: part.fileSource!.text.value,
                          start: part.fileSource!.text.start,
                          end: part.fileSource!.text.end,
                        ),
                        type: part.fileSource!.type,
                      ),
              ),
            ),
          );
    final draft = ChatComposerDraft(
      text: normalizedText,
      attachments: attachments,
      shellMode: shellMode,
    );
    return draft.hasContent ? draft : null;
  }

  UserMessage? _findUserMessageById(String messageId) {
    for (var index = _messages.length - 1; index >= 0; index -= 1) {
      final message = _messages[index];
      if (message.id == messageId && message is UserMessage) {
        return message;
      }
    }
    return null;
  }

  String? _nextRedoBoundaryMessageId() {
    final session = _currentSession;
    final revertMessageId = session?.revert?.messageId.trim();
    if (session == null || revertMessageId == null || revertMessageId.isEmpty) {
      return null;
    }
    final boundaryIndex = _messages.indexWhere(
      (message) =>
          message.sessionId == session.id && message.id == revertMessageId,
    );
    if (boundaryIndex == -1) {
      return null;
    }
    for (var index = boundaryIndex + 1; index < _messages.length; index += 1) {
      final candidate = _messages[index];
      if (candidate.sessionId != session.id || candidate is! UserMessage) {
        continue;
      }
      if (_isOptimisticLocalUserMessageId(candidate.id)) {
        continue;
      }
      return candidate.id;
    }
    return null;
  }

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

    if (_state == ChatState.sending) {
      return true;
    }

    if (hasInProgressAssistant) {
      return true;
    }

    if (!hasBusyStatus) {
      return false;
    }

    ChatMessage? latestSessionMessage;
    for (var index = _messages.length - 1; index >= 0; index -= 1) {
      final candidate = _messages[index];
      if (candidate.sessionId == normalizedSessionId) {
        latestSessionMessage = candidate;
        break;
      }
    }

    if (latestSessionMessage == null) {
      return false;
    }

    if (latestSessionMessage is UserMessage) {
      return true;
    }

    if (latestSessionMessage is! AssistantMessage) {
      return true;
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

  SessionAttentionState sessionAttentionForScope(
    String sessionId, {
    required String scopeId,
  }) {
    final normalizedScopeId = scopeId.trim();
    if (normalizedScopeId.isEmpty) {
      return sessionAttentionFor(sessionId);
    }
    final contextKey = _composeContextKey(_activeServerId, normalizedScopeId);
    if (contextKey == _activeContextKey) {
      return sessionAttentionFor(sessionId);
    }

    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return const SessionAttentionState();
    }

    final snapshot = _contextSnapshots[contextKey];
    if (snapshot == null) {
      return const SessionAttentionState();
    }

    final statusType = snapshot.sessionStatusById[normalizedSessionId]?.type;
    final hasPendingPermission =
        (snapshot
            .pendingPermissionsBySession[normalizedSessionId]
            ?.isNotEmpty ??
        false);
    final hasPendingQuestion =
        (snapshot.pendingQuestionsBySession[normalizedSessionId]?.isNotEmpty ??
        false);

    return SessionAttentionState(
      isActive:
          statusType == SessionStatusType.busy ||
          statusType == SessionStatusType.retry,
      hasPendingInteraction: hasPendingPermission || hasPendingQuestion,
      hasError: snapshot.sessionErrorAttentionIds.contains(normalizedSessionId),
      hasUnreadCompletion: snapshot.sessionUnreadCompletionIds.contains(
        normalizedSessionId,
      ),
      unreadCompletionAt:
          snapshot.sessionUnreadCompletionTimestamps[normalizedSessionId],
    );
  }

  SessionAttentionState sessionAttentionFor(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return const SessionAttentionState();
    }

    final hasPendingPermission =
        (_pendingPermissionsBySession[normalizedSessionId]?.isNotEmpty ??
        false);
    final hasPendingQuestion =
        (_pendingQuestionsBySession[normalizedSessionId]?.isNotEmpty ?? false);

    return SessionAttentionState(
      isActive: isSessionActivelyResponding(normalizedSessionId),
      hasPendingInteraction: hasPendingPermission || hasPendingQuestion,
      hasError: _sessionErrorAttentionIds.contains(normalizedSessionId),
      hasUnreadCompletion: _sessionUnreadCompletionIds.contains(
        normalizedSessionId,
      ),
      unreadCompletionAt:
          _sessionUnreadCompletionTimestamps[normalizedSessionId],
    );
  }

  bool get hasOutOfFocusAttention => outOfFocusAttentionCount > 0;

  int get outOfFocusAttentionCount {
    final currentSessionId = _currentSession?.id;
    var total = 0;
    for (final session in visibleSessions) {
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

    for (final session in visibleSessions) {
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
    _clearSessionUnreadCompletion(normalizedSessionId);
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
    _sessionUnreadCompletionTimestamps.removeWhere(
      (sessionId, _) => !knownSessionIds.contains(sessionId),
    );

    final currentSessionId = _currentSession?.id;
    if (currentSessionId != null) {
      _clearSessionAttentionForSession(currentSessionId);
    }
    _scheduleSessionUnreadHighlightTimer();
  }

  void _syncAttentionFromStatusMap(Map<String, SessionStatusInfo> statusMap) {
    for (final entry in statusMap.entries) {
      final sessionId = entry.key;
      final statusType = entry.value.type;
      switch (statusType) {
        case SessionStatusType.retry:
          _clearSessionUnreadCompletion(sessionId);
          break;
        case SessionStatusType.busy:
          _clearSessionUnreadCompletion(sessionId);
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
    final sessionId = _currentSession!.id;
    // Active stream or sending state always allows abort. The
    // server connection is live and the user may need to stop it.
    if (_activeMessageStreamSessionId == sessionId &&
        _messageSubscription != null) {
      return true;
    }
    if (_state == ChatState.sending) {
      return true;
    }
    if (!isCurrentSessionActivelyResponding) {
      return false;
    }
    final latestMessage = _latestMessageForSession(sessionId);
    if (latestMessage is! AssistantMessage) {
      return true;
    }
    // A completed assistant with revealable content (text, reasoning,
    // etc.) means the turn has settled. There is nothing locally
    // abortable even if the server still reports busy/retry. This
    // prevents the composer from showing a stuck Stop button after
    // the final response is already visible.
    if (latestMessage.isCompleted &&
        hasRevealableAssistantContent(latestMessage)) {
      return false;
    }
    return true;
  }

  /// Returns the latest message for the given session by searching
  /// backwards through [_messages], or null if none exists.
  ChatMessage? _latestMessageForSession(String sessionId) {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final candidate = _messages[i];
      if (candidate.sessionId == sessionId) {
        return candidate;
      }
    }
    return null;
  }

  // Generates a unique ID for optimistic (locally-appended) user messages.
  //
  // INVARIANT — do NOT change the prefix or format (see ADR-023 Pitfall P-001):
  // The `local_user_*` prefix is load-bearing. The SSE merge logic uses it to
  // identify optimistic bubbles eligible for duplicate-echo suppression
  // (`_shouldSkipLocalUserAppendAsDuplicateEcho`). If the prefix is changed to
  // any server-format value (e.g. `msg_*`), the prefix check short-circuits and
  // the bubble is treated as a confirmed server message. This silently breaks
  // reconciliation for all conversation turns after the first — the UI stays
  // stuck even though the assistant response arrives. (Regression: b0660a2)
  bool _isOptimisticLocalUserMessageId(String messageId) {
    return messageId.trim().startsWith(_optimisticLocalUserMessageIdPrefix);
  }

  String _nextLocalUserMessageId() {
    _localMessageIdSequence += 1;
    return '${_optimisticLocalUserMessageIdPrefix}${DateTime.now().microsecondsSinceEpoch}_${_localMessageIdSequence}';
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

  List<ChatSession> recentRootSessionsForScopeId(String scopeId) {
    final sessions = _sessionsForScopeId(scopeId);
    if (sessions.isEmpty) {
      return const <ChatSession>[];
    }
    final recent =
        sessions
            .where(
              (session) =>
                  !session.archived &&
                  (session.parentId == null ||
                      session.parentId!.trim().isEmpty),
            )
            .toList(growable: false)
          ..sort((a, b) => b.time.compareTo(a.time));
    return recent;
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
    return _buildVisibleSessionsFrom(
      snapshot.sessions,
      pinnedSessionIds: snapshot.pinnedSessionIds,
    );
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
    List<ChatSession> sourceSessions, {
    Set<String>? pinnedSessionIds,
  }) {
    final effectivePinnedSessionIds = pinnedSessionIds ?? _pinnedSessionIds;
    final query = _sessionSearchQuery.trim().toLowerCase();
    final sessionById = <String, ChatSession>{
      for (final session in sourceSessions) session.id: session,
    };
    final hiddenByArchivedAncestor = _hiddenByArchivedAncestor(sessionById);
    final filtered = sourceSessions
        .where((session) {
          final archived = session.archived;
          final hiddenByAncestor =
              hiddenByArchivedAncestor[session.id] ?? false;
          switch (_sessionListFilter) {
            case SessionListFilter.active:
              if (archived || hiddenByAncestor) {
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
      ..sort(
        (a, b) => _compareSessionsForSidebarOrder(
          a,
          b,
          pinnedSessionIds: effectivePinnedSessionIds,
        ),
      );

    final limited = sorted.length <= _sessionVisibleLimit
        ? sorted
        : sorted.take(_sessionVisibleLimit).toList(growable: false);

    return _includeVisibleSessionAncestors(
      visibleSessions: limited,
      sortedFilteredSessions: sorted,
    );
  }

  int _compareSessionsForSidebarOrder(
    ChatSession a,
    ChatSession b, {
    Set<String>? pinnedSessionIds,
  }) {
    final effectivePinnedSessionIds = pinnedSessionIds ?? _pinnedSessionIds;
    final aPinned = effectivePinnedSessionIds.contains(a.id);
    final bPinned = effectivePinnedSessionIds.contains(b.id);
    if (aPinned != bPinned) {
      return aPinned ? -1 : 1;
    }

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
  }

  void _prunePinnedSessionIdsToKnownSessions() {
    if (!_hasLoadedSessionsAuthoritatively || _pinnedSessionIds.isEmpty) {
      return;
    }
    final knownSessionIds = _sessions.map((session) => session.id).toSet();
    _pinnedSessionIds = _pinnedSessionIds
        .where((id) => knownSessionIds.contains(id))
        .toSet();
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
    final sessionById = <String, ChatSession>{
      for (final session in _sessions) session.id: session,
    };
    final hiddenByArchivedAncestor = _hiddenByArchivedAncestor(sessionById);
    final total = _sessions.where((session) {
      final archived = session.archived;
      final hiddenByAncestor = hiddenByArchivedAncestor[session.id] ?? false;
      switch (_sessionListFilter) {
        case SessionListFilter.active:
          if (archived || hiddenByAncestor) {
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

  List<ChatQuestionRequest> get currentThreadQuestionRequests {
    if (_cachedThreadQuestionsAtVersion == _threadPermissionsVersion) {
      return _cachedThreadQuestionRequests;
    }

    final currentSessionId = _currentSession?.id;
    if (currentSessionId == null || currentSessionId.isEmpty) {
      _cachedThreadQuestionsAtVersion = _threadPermissionsVersion;
      _cachedThreadQuestionRequests = const <ChatQuestionRequest>[];
      return _cachedThreadQuestionRequests;
    }

    final orderedSessionIds = <String>[
      currentSessionId,
      ..._orderedCurrentSessionDescendantIds(),
    ];
    final seenRequestIds = <String>{};
    final collected = <ChatQuestionRequest>[];

    for (final sessionId in orderedSessionIds) {
      final sessionRequests = _pendingQuestionsBySession[sessionId];
      if (sessionRequests == null || sessionRequests.isEmpty) {
        continue;
      }
      for (final request in sessionRequests) {
        if (seenRequestIds.add(request.id)) {
          collected.add(request);
        }
      }
    }

    _cachedThreadQuestionsAtVersion = _threadPermissionsVersion;
    _cachedThreadQuestionRequests = List<ChatQuestionRequest>.unmodifiable(
      collected,
    );
    return _cachedThreadQuestionRequests;
  }

  List<String> get currentThreadSessionIds {
    final currentSessionId = _currentSession?.id;
    if (currentSessionId == null || currentSessionId.isEmpty) {
      return const <String>[];
    }

    return List<String>.unmodifiable(<String>[
      currentSessionId,
      ..._orderedCurrentSessionDescendantIds(),
    ]);
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
  void setScrollToBottomCallback(
    void Function({required String reason})? callback,
  ) {
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
    _cellularDataSaverService.setAppForeground(isActive);
    if (!isActive) {
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
      // Pause automatic network work in background. When cellular data saver is
      // active we also close idle realtime streams so no background downloads continue.
      _syncHealthTimer?.cancel();
      _syncHealthTimer = null;
      _degradedPollingTimer?.cancel();
      _degradedPollingTimer = null;
      _degradedMode = false;
      _degradedModeStartedAt = null;
      if (_cellularDataSaverService.shouldDisableBackgroundNetworkTasks) {
        _idleRealtimePausedForDataSaver = true;
        await _stopRealtimeEventSubscriptions(reason: 'background-data-saver');
      }
      return;
    }

    if (!wasActive) {
      _startForegroundResumeSyncIndicator(reason: 'foreground');
    }

    _startSyncHealthMonitor();
    await _syncCellularDataSaverRealtimePolicy(reason: 'foreground-return');
    await _resumeRealtimeAfterForeground();
  }

  void setAppInForeground(bool isForeground) {
    _isAppInForeground = isForeground;
  }

  void setChatRouteActive(bool isActive) {
    _isChatRouteActive = isActive;
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

    final refreshStartVersion = _messagesVersion;
    var fallbackToFullFetch = false;

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
          if (_messagesVersion != refreshStartVersion) {
            return;
          }
          var serverMessagesForMerge = messages;
          var requiresFullFetch = false;
          var usedGapRecovery = false;
          if (canUseDelta) {
            final deltaResult = _mergeServerTailWithCachedMessages(
              serverMessages: messages,
              cachedMessages: cachedMessages,
              sessionId: session.id,
            );
            serverMessagesForMerge = deltaResult.messages;
            requiresFullFetch = deltaResult.requiresFullFetch;
            usedGapRecovery = deltaResult.usedGapRecovery;
          }
          serverMessagesForMerge = _filterMessagesForPendingReplacementBranch(
            serverMessagesForMerge,
            sessionId: session.id,
          );
          final mergedMessages = _mergeServerMessagesWithActiveLocalTail(
            serverMessagesForMerge,
            sessionId: session.id,
          );
          final nextHasMoreOldMessages =
              usedGapRecovery ||
              serverMessagesForMerge.length >= _defaultOlderMessagesChunkSize;
          final messagesChanged = !_areMessageListsSemanticallyEqual(
            cachedMessages,
            mergedMessages,
          );
          final hasMoreOldMessagesChanged =
              _hasMoreOldMessages != nextHasMoreOldMessages;
          if (!messagesChanged) {
            if (!hasMoreOldMessagesChanged) {
              _traceFinal(
                'refresh-active-noop',
                sessionId: session.id,
                details: 'reason=$reason',
              );
              return;
            }
            _hasMoreOldMessages = nextHasMoreOldMessages;
            notifyListeners();
            return;
          }

          _messages = List<ChatMessage>.from(mergedMessages);
          _cacheSessionMessages(session.id, _messages);
          if (messagesChanged) {
            _messagesVersion++;
          }
          _hasMoreOldMessages = nextHasMoreOldMessages;
          _prunePendingLocalUserMessageIdsToVisibleUsers();
          notifyListeners();
          _traceFinal(
            'refresh-active-merged',
            sessionId: session.id,
            details: 'reason=$reason mergedMessages=${_messages.length}',
          );
          _scheduleAutoTitleRefresh(session.id);
          if (!usedGapRecovery) {
            unawaited(
              _persistSessionMessagesSnapshotBestEffort(session.id, _messages),
            );
          }
          final sessionStatusType = _sessionStatusById[session.id]?.type;
          final hasBusyRefreshStatus =
              sessionStatusType == SessionStatusType.busy ||
              sessionStatusType == SessionStatusType.retry;
          final latestSessionMessage = _messages.lastOrNull;
          final latestSessionMessageChanged =
              latestSessionMessage != previousLatestSessionMessage;
          if (!_isCompactingContext &&
              latestSessionMessageChanged &&
              !hasBusyRefreshStatus &&
              !isSessionActivelyResponding(session.id)) {
            _scheduleScrollToBottom(reason: 'refresh-active-session-view');
          }
          if (requiresFullFetch && _currentSession?.id == session.id) {
            fallbackToFullFetch = true;
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

    if (fallbackToFullFetch && _currentSession?.id == session.id) {
      unawaited(
        refreshActiveSessionView(
          reason: '$reason:delta-fallback',
          includeStatus: false,
          allowDuringAbortSuppression: allowDuringAbortSuppression,
          preferDelta: false,
        ),
      );
    }
  }

  Future<void> refreshSessionStatusSnapshot({bool silent = true}) async {
    final currentIdAtCall = _currentSession?.id;
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
        // Guard: prevent stale REST busy (from the onDone-triggered
        // loadSessionInsights) from re-enabling Stop after the SSE
        // send-stream has settled with a final revealable response.
        // The SSE-settled flag is consumed here immediately so it is
        // strictly a one-shot: only the very first status refresh after
        // onDone is protected. Subsequent refreshes accept REST status
        // normally, avoiding turn-unscoped suppression of legitimate
        // later busy (e.g. resumed/reconnected work or another client).
        // currentIdAtCall is captured before the await above so the guard
        // applies to the session that was current when the request was
        // made, not the session current when the response arrives
        // (the user may have switched sessions during the in-flight await).
        if (currentIdAtCall != null) {
          final currentStatus = _sessionStatusById[currentIdAtCall]?.type;
          final sseSettledToIdle = _sseSettledToIdleSessionIds.remove(
            currentIdAtCall,
          );
          const idle = SessionStatusType.idle;
          if (sseSettledToIdle &&
              (currentStatus == null || currentStatus == idle) &&
              statusMap[currentIdAtCall]?.type == SessionStatusType.busy &&
              hasCompletedRevealableAssistantMessage(
                _messages,
                currentIdAtCall,
              )) {
            statusMap[currentIdAtCall] = const SessionStatusInfo(type: idle);
          }
        }
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
    bool userInitiated = false,
  }) async {
    if (userInitiated) {
      _cellularDataSaverService.noteExplicitUserAction(
        reason: 'session-insights',
      );
      await _syncCellularDataSaverRealtimePolicy(
        reason: 'session-insights-user',
        forceBurst: true,
      );
    }

    final automaticDataSaverMode =
        _cellularDataSaverService.isDataSaverActive && !userInitiated;
    if (automaticDataSaverMode) {
      final lastAutomaticLoadAt =
          _lastAutomaticSessionInsightsAtBySessionId[sessionId];
      final now = DateTime.now();
      if (lastAutomaticLoadAt != null &&
          now.difference(lastAutomaticLoadAt) <
              _cellularDataSaverService.automaticSyncInterval) {
        return;
      }
      _lastAutomaticSessionInsightsAtBySessionId[sessionId] = now;
    }

    if (!silent) {
      _isLoadingSessionInsights = true;
      _sessionInsightsError = null;
      notifyListeners();
    }

    try {
      // Consume the SSE-settled-to-idle flag immediately (before any await)
      // so it is not stolen by lingering unawaited loadSessionInsights calls
      // from selectSession that interleave in the microtask queue. The flag
      // is a strict one-shot: only the method that first checks it gets it.
      // Capture current session ID at the same time so the guard applies to
      // the session that was current when the request was made, not the one
      // current when the response arrives (user may switch during await).
      final currentIdAtCall = _currentSession?.id;
      final guardSseSettled = _sseSettledToIdleSessionIds.remove(sessionId);

      final directory = projectProvider.currentDirectory;
      final projectId = projectProvider.currentProjectId;

      Future<Either<Failure, List<ChatSession>>>? childrenFuture;
      Future<Either<Failure, List<SessionTodo>>>? todoFuture;
      Future<Either<Failure, List<SessionDiff>>>? diffFuture;
      if (!automaticDataSaverMode) {
        // Full insights are useful after explicit actions, but expensive to pull
        // automatically on cellular data.
        childrenFuture = _runSessionInsightRequest(
          requestName: 'children',
          request: () => getSessionChildren(
            GetSessionChildrenParams(
              projectId: projectId,
              sessionId: sessionId,
              directory: directory,
            ),
          ),
        );
        todoFuture = _runSessionInsightRequest(
          requestName: 'todo',
          request: () => getSessionTodo(
            GetSessionTodoParams(
              projectId: projectId,
              sessionId: sessionId,
              directory: directory,
            ),
          ),
        );
        diffFuture = _runSessionInsightRequest(
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
      }
      final statusFuture = _runSessionInsightRequest(
        requestName: 'status',
        request: () =>
            getSessionStatus(GetSessionStatusParams(directory: directory)),
      );

      final statusResult = await statusFuture;
      if (childrenFuture != null) {
        final childrenResult = await childrenFuture;
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
      }

      if (todoFuture != null) {
        final todoResult = await todoFuture;
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
      }

      if (diffFuture != null) {
        final diffResult = await diffFuture;
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
      }

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
          // Guard: prevent stale REST busy (from the onDone-triggered
          // loadSessionInsights) from re-enabling Stop after the SSE
          // send-stream has settled with a final revealable response.
          // The SSE-settled flag is consumed at method entry above so it is
          // strictly a one-shot: only the very first status refresh after
          // onDone is protected. Subsequent refreshes accept REST status
          // normally, avoiding turn-unscoped suppression of legitimate
          // later busy (e.g. resumed/reconnected work or another client).
          // currentIdAtCall was captured before any await so the guard uses
          // the session that was current when the request was made, not the
          // one current now (user may have switched during the in-flight
          // await above).
          if (currentIdAtCall != null) {
            final currentStatus = _sessionStatusById[currentIdAtCall]?.type;
            const idle = SessionStatusType.idle;
            if (guardSseSettled &&
                (currentStatus == null || currentStatus == idle) &&
                statusMap[currentIdAtCall]?.type == SessionStatusType.busy &&
                hasCompletedRevealableAssistantMessage(
                  _messages,
                  currentIdAtCall,
                )) {
              statusMap[currentIdAtCall] = const SessionStatusInfo(type: idle);
            }
          }
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
    required String sessionId,
    required String requestId,
    required String reply,
    String? message,
  }) async {
    if (_isRespondingInteraction ||
        !_guardTransportForAction(actionLabel: 'reply to permission')) {
      return;
    }
    final tombstoneKey = _permissionInteractionKey(requestId);
    _rememberDismissedInteractionTombstone(tombstoneKey);
    _isRespondingInteraction = true;
    notifyListeners();
    final result = await replyPermission(
      ReplyPermissionParams(
        sessionId: sessionId,
        requestId: requestId,
        reply: reply,
        message: message,
        directory: projectProvider.currentDirectory,
      ),
    );
    _isRespondingInteraction = false;
    result.fold(
      (failure) {
        _dismissedInteractionTombstones.remove(tombstoneKey);
        _handleFailure(failure);
      },
      (_) {
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
      },
    );
    notifyListeners();
  }

  String? _sessionIdForPendingQuestion(String requestId) {
    final normalizedRequestId = requestId.trim();
    if (normalizedRequestId.isEmpty) {
      return null;
    }
    for (final entry in _pendingQuestionsBySession.entries) {
      final ownsQuestion = entry.value.any(
        (question) => question.id == normalizedRequestId,
      );
      if (ownsQuestion) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> submitQuestionAnswers({
    required String requestId,
    required List<List<String>> answers,
  }) async {
    if (_isRespondingInteraction ||
        !_guardTransportForAction(actionLabel: 'reply to question')) {
      return;
    }
    final tombstoneKey = _questionInteractionKey(requestId);
    final owningSessionId = _sessionIdForPendingQuestion(requestId);
    _rememberDismissedInteractionTombstone(tombstoneKey);
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
    result.fold(
      (failure) {
        _dismissedInteractionTombstones.remove(tombstoneKey);
        _handleFailure(failure);
      },
      (_) {
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
        _threadPermissionsVersion++;
      },
    );
    notifyListeners();
  }

  Future<void> rejectQuestionRequest({required String requestId}) async {
    if (_isRespondingInteraction ||
        !_guardTransportForAction(actionLabel: 'reject question')) {
      return;
    }
    final tombstoneKey = _questionInteractionKey(requestId);
    final owningSessionId = _sessionIdForPendingQuestion(requestId);
    _rememberDismissedInteractionTombstone(tombstoneKey);
    _isRespondingInteraction = true;
    notifyListeners();
    final result = await rejectQuestion(
      RejectQuestionParams(
        requestId: requestId,
        directory: projectProvider.currentDirectory,
      ),
    );
    _isRespondingInteraction = false;
    result.fold(
      (failure) {
        _dismissedInteractionTombstones.remove(tombstoneKey);
        _handleFailure(failure);
      },
      (_) {
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
        _threadPermissionsVersion++;
      },
    );
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

  _SelectionPersistenceSnapshot _captureSelectionPersistenceSnapshot({
    bool syncRemote = true,
  }) {
    final serverId = _activeServerId.trim().isEmpty
        ? 'legacy'
        : _activeServerId;
    final scopeId = _resolveContextScopeId();
    final overrides = _sessionOverridesForContext(_activeContextKey);
    final serializedOverrides = <String, dynamic>{};
    for (final entry in overrides.entries) {
      serializedOverrides[entry.key] = _sessionOverrideToJson(entry.value);
    }
    return _SelectionPersistenceSnapshot(
      serverId: serverId,
      scopeId: scopeId,
      selectedProviderId: _selectedProviderId,
      selectedModelId: _selectedModelId,
      selectedAgentName: _selectedAgentName,
      recentModelsJson: json.encode(_recentModelKeys),
      favoriteModelsJson: json.encode(_favoriteModelKeys),
      pinnedSessionsJson: json.encode(
        _pinnedSessionIds.toList(growable: false),
      ),
      modelUsageCountsJson: json.encode(_modelUsageCounts),
      selectedVariantMapJson: json.encode(_selectedVariantByModel),
      agentSelectionMemoryJson: json.encode(_encodeAgentSelectionMemory()),
      sessionSelectionOverridesJson: json.encode(serializedOverrides),
      syncRemote: syncRemote,
    );
  }

  Future<void> _persistSelectionSnapshot(
    _SelectionPersistenceSnapshot snapshot, {
    required bool syncRemote,
  }) async {
    if (snapshot.selectedProviderId != null) {
      await localDataSource.saveSelectedProvider(
        snapshot.selectedProviderId!,
        serverId: snapshot.serverId,
        scopeId: snapshot.scopeId,
      );
    }
    if (snapshot.selectedModelId != null) {
      await localDataSource.saveSelectedModel(
        snapshot.selectedModelId!,
        serverId: snapshot.serverId,
        scopeId: snapshot.scopeId,
      );
    }
    await localDataSource.saveSelectedAgent(
      snapshot.selectedAgentName,
      serverId: snapshot.serverId,
      scopeId: snapshot.scopeId,
    );
    await localDataSource.saveRecentModelsJson(
      snapshot.recentModelsJson,
      serverId: snapshot.serverId,
      scopeId: snapshot.scopeId,
    );
    await localDataSource.saveFavoriteModelsJson(
      snapshot.favoriteModelsJson,
      serverId: snapshot.serverId,
    );
    await localDataSource.savePinnedSessionsJson(
      snapshot.pinnedSessionsJson,
      serverId: snapshot.serverId,
      scopeId: snapshot.scopeId,
    );
    await localDataSource.saveModelUsageCountsJson(
      snapshot.modelUsageCountsJson,
      serverId: snapshot.serverId,
      scopeId: snapshot.scopeId,
    );
    await localDataSource.saveSelectedVariantMap(
      snapshot.selectedVariantMapJson,
      serverId: snapshot.serverId,
      scopeId: snapshot.scopeId,
    );
    await localDataSource.saveAgentSelectionMemoryJson(
      snapshot.agentSelectionMemoryJson,
      serverId: snapshot.serverId,
      scopeId: snapshot.scopeId,
    );
    await localDataSource.saveSessionSelectionOverridesJson(
      snapshot.sessionSelectionOverridesJson,
      serverId: snapshot.serverId,
      scopeId: snapshot.scopeId,
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

  void _scheduleSelectionPersistence({bool syncRemote = true}) {
    _selectionPersistenceDirty = true;
    _selectionPersistenceSyncRemote =
        syncRemote || _selectionPersistenceSyncRemote;
    final inFlight = _selectionPersistenceTask;
    if (inFlight != null) {
      return;
    }
    final task = _flushScheduledSelectionPersistence();
    _selectionPersistenceTask = task;
    unawaited(task);
  }

  Future<void> _flushScheduledSelectionPersistence() async {
    try {
      while (true) {
        if (!_selectionPersistenceDirty) {
          break;
        }
        _selectionPersistenceDirty = false;
        final syncRemote = _selectionPersistenceSyncRemote;
        _selectionPersistenceSyncRemote = false;
        final snapshot = _captureSelectionPersistenceSnapshot(
          syncRemote: syncRemote,
        );
        await _persistSelectionSnapshot(snapshot, syncRemote: syncRemote);
      }
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Selection persistence flush failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _selectionPersistenceTask = null;
    }
    if (_selectionPersistenceDirty) {
      final retryTask = _flushScheduledSelectionPersistence();
      _selectionPersistenceTask = retryTask;
      unawaited(retryTask);
      return;
    }
    _selectionPersistenceTask = null;
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
    final snapshot = _captureSelectionPersistenceSnapshot(
      syncRemote: syncRemote,
    );
    await _persistSelectionSnapshot(snapshot, syncRemote: syncRemote);
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
    _rememberCurrentSelectionForAgent(agentName: _selectedAgentName);
    _recordModelSelectionRecency(previousModelKey: previousModelKey);
    _recordVariantSelectionRecencyForCurrentModel();
    _storeCurrentSessionSelectionOverride();
    _notifyListeners();
    _scheduleSelectionPersistence();
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
    _rememberCurrentSelectionForAgent(agentName: _selectedAgentName);
    _recordModelSelectionRecency(previousModelKey: previousModelKey);
    _recordVariantSelectionRecencyForCurrentModel();
    _storeCurrentSessionSelectionOverride();
    _notifyListeners();
    _scheduleSelectionPersistence();
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
    _rememberCurrentSelectionForAgent(agentName: previousAgentName);
    _selectedAgentName = next;
    _restoreSelectionForAgent(next);
    _recordAgentSelectionRecency(previousAgentName: previousAgentName);
    _storeCurrentSessionSelectionOverride();
    _notifyListeners();
    _scheduleSelectionPersistence();
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
    _rememberCurrentSelectionForAgent(agentName: _selectedAgentName);

    _storeCurrentSessionSelectionOverride();
    _notifyListeners();
    _scheduleSelectionPersistence();
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

  bool isSessionPinned(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return false;
    }
    return _pinnedSessionIds.contains(normalizedSessionId);
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

  Future<void> toggleSessionPinned(ChatSession session) async {
    final sessionId = session.id.trim();
    if (sessionId.isEmpty) {
      return;
    }

    if (_pinnedSessionIds.contains(sessionId)) {
      _pinnedSessionIds.remove(sessionId);
    } else {
      _pinnedSessionIds.add(sessionId);
    }

    _sortSessionsInPlace();
    notifyListeners();

    final serverId = await _resolveServerScopeId();
    final scopeId = _resolveContextScopeId();
    await _persistModelPreferenceState(serverId: serverId, scopeId: scopeId);
  }

  /// Load session list
  Future<void> loadSessions({
    bool preserveVisibleState = false,
    bool userInitiated = false,
  }) async {
    if (_state == ChatState.loading) return;
    if (userInitiated) {
      _cellularDataSaverService.noteExplicitUserAction(reason: 'load-sessions');
      await _syncCellularDataSaverRealtimePolicy(
        reason: 'load-sessions-user',
        forceBurst: true,
      );
    }
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
        _hasLoadedSessionsAuthoritatively = true;
        _threadPermissionsVersion++;
        _sessionVisibleLimit = 40;
        _prunePinnedSessionIdsToKnownSessions();
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
        _pendingCurrentSessionHydrationId = null;
        _threadPermissionsVersion++;
        _messages = <ChatMessage>[];
        _isLoadingOlderMessages = false;
        _hasMoreOldMessages = messages.length >= _defaultOlderMessagesChunkSize;
        _messagesVersion++;
        _clearPendingReplacementBranch();
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
        _pendingCurrentSessionHydrationId = null;
        _threadPermissionsVersion++;
        _messages = <ChatMessage>[];
        _isLoadingOlderMessages = false;
        _hasMoreOldMessages = false;
        _messagesVersion++;
        _clearPendingReplacementBranch();
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
          _pendingCurrentSessionHydrationId = null;
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
    _clearPendingReplacementBranch();
    _pendingLocalUserMessageIds.clear();
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
    _clearPendingReplacementBranch();
    _pendingLocalUserMessageIds.clear();
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
    _cellularDataSaverService.noteExplicitUserAction(reason: 'select-session');
    await _syncCellularDataSaverRealtimePolicy(
      reason: 'select-session-user',
      forceBurst: true,
    );
    _isNewChatDraftActive = false;
    if (_currentSession?.id == session.id) {
      unawaited(
        loadSessionInsights(session.id, silent: true, userInitiated: true),
      );
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

    _pendingLocalUserMessageIds.clear();
    _clearPendingReplacementBranch();
    _clearRejectedDraft();

    // Move selection ownership to the tapped session before awaiting stream
    // teardown so the UI can render session-scoped hydration feedback
    // immediately during cacheless switches.
    _messageStreamGeneration += 1;
    _currentSession = session;
    _isLoadingOlderMessages = false;
    _hasMoreOldMessages = false;
    _clearSessionAttentionForSession(session.id);
    _threadPermissionsVersion++;
    _applySelectionPriorityForCurrentSession();

    final warmCachedMessages = _cachedSessionMessages(session.id);
    final hasWarmCachedMessages =
        warmCachedMessages != null && warmCachedMessages.isNotEmpty;

    // Show the session-scoped hydration state immediately while cache lookup
    // and network hydration run, so cacheless switches never fall back to the
    // generic empty placeholder for a frame.
    if (hasWarmCachedMessages) {
      _pendingCurrentSessionHydrationId = null;
      _messages = List<ChatMessage>.from(warmCachedMessages);
      _cacheSessionMessages(session.id, _messages);
      _hasMoreOldMessages = _messages.length >= _defaultOlderMessagesChunkSize;
      _messagesVersion++;
      _setState(ChatState.loaded);
    } else {
      _pendingCurrentSessionHydrationId = session.id;
      _messages = <ChatMessage>[];
      _messagesVersion++;
      _setState(ChatState.loading);
    }

    await _cancelActiveMessageSubscription(
      reason: 'session-switch',
      invalidateGeneration: false,
    );
    AppLogger.info(
      'selectSession generation=$_messageStreamGeneration target=${session.id}',
    );

    // Save current session ID and try cache-first restore (SWR).
    final serverId = await _resolveServerScopeId();
    final scopeId = _resolveContextScopeId();
    final restoredComposerDraft = await _loadPersistedComposerDraft(
      session.id,
      serverId: serverId,
      scopeId: scopeId,
    );
    _queueHistoryComposerSync(
      sessionId: session.id,
      draft: restoredComposerDraft,
      clear: true,
    );

    final restoredCachedMessages = hasWarmCachedMessages
        ? warmCachedMessages
        : await _restoreSessionMessagesFromCache(
            session.id,
            serverId: serverId,
            scopeId: scopeId,
          );

    if (restoredCachedMessages != null && restoredCachedMessages.isNotEmpty) {
      _pendingCurrentSessionHydrationId = null;
      final restoredMessages = List<ChatMessage>.from(restoredCachedMessages);
      _hasMoreOldMessages =
          restoredCachedMessages.length >= _defaultOlderMessagesChunkSize;
      if (!_areMessageListsSemanticallyEqual(_messages, restoredMessages)) {
        _messages = restoredMessages;
        _cacheSessionMessages(session.id, _messages);
        _messagesVersion++;
        _setState(ChatState.loaded);
      }
    } else {
      _pendingCurrentSessionHydrationId = session.id;
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
    unawaited(
      loadSessionInsights(session.id, silent: true, userInitiated: true),
    );
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
        if (_currentSession?.id == sessionId) {
          _pendingCurrentSessionHydrationId = null;
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
        _pendingCurrentSessionHydrationId = null;
        final previousVisibleMessages = List<ChatMessage>.from(
          _messages.where((message) => message.sessionId == sessionId),
          growable: false,
        );
        var serverMessagesForMerge = messages;
        var requiresFullFetch = false;
        var usedGapRecovery = false;
        if (canKeepVisibleState && preferDelta && cachedMessages.isNotEmpty) {
          final deltaResult = _mergeServerTailWithCachedMessages(
            serverMessages: messages,
            cachedMessages: cachedMessages,
            sessionId: sessionId,
          );
          serverMessagesForMerge = deltaResult.messages;
          requiresFullFetch = deltaResult.requiresFullFetch;
          usedGapRecovery = deltaResult.usedGapRecovery;
        }
        serverMessagesForMerge = _filterMessagesForPendingReplacementBranch(
          serverMessagesForMerge,
          sessionId: sessionId,
        );
        final mergedMessages = _mergeServerMessagesWithActiveLocalTail(
          serverMessagesForMerge,
          sessionId: sessionId,
        );
        final nextHasMoreOldMessages =
            usedGapRecovery ||
            serverMessagesForMerge.length >= _defaultOlderMessagesChunkSize;
        final messagesChanged = !_areMessageListsSemanticallyEqual(
          previousVisibleMessages,
          mergedMessages,
        );
        final hasMoreOldMessagesChanged =
            _hasMoreOldMessages != nextHasMoreOldMessages;
        if (!messagesChanged) {
          if (!hasMoreOldMessagesChanged) {
            if (_state != ChatState.loaded) {
              _setState(ChatState.loaded);
            }
            return;
          }
          _hasMoreOldMessages = nextHasMoreOldMessages;
          if (_state != ChatState.loaded) {
            _setState(ChatState.loaded);
          } else {
            _notifyListeners();
          }
          return;
        }

        _messages = List<ChatMessage>.from(mergedMessages);
        _cacheSessionMessages(sessionId, _messages);
        if (messagesChanged) {
          _messagesVersion++;
        }
        _hasMoreOldMessages = nextHasMoreOldMessages;
        _prunePendingLocalUserMessageIdsToVisibleUsers();
        _scheduleAutoTitleRefresh(sessionId);
        if (_state != ChatState.loaded ||
            messagesChanged ||
            hasMoreOldMessagesChanged) {
          _setState(ChatState.loaded);
        }
        if (!usedGapRecovery) {
          unawaited(_persistLastSessionSnapshotBestEffort());
          unawaited(
            _persistSessionMessagesSnapshotBestEffort(sessionId, _messages),
          );
        }
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
          final filteredMessages = _filterMessagesForPendingReplacementBranch(
            messages,
            sessionId: sessionId,
          );
          _messages = _mergeServerMessagesWithActiveLocalTail(
            filteredMessages,
            sessionId: sessionId,
          );
          _cacheSessionMessages(sessionId, _messages);
          _messagesVersion++;
          _hasMoreOldMessages = filteredMessages.length >= requestedLimit;
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

  Future<void> submitMessage(
    String text, {
    List<FileInputPart> attachments = const <FileInputPart>[],
    bool shellMode = false,
    bool commandMode = false,
  }) async {
    final trimmedText = text.trim();
    final effectiveAttachments = shellMode || commandMode
        ? const <FileInputPart>[]
        : attachments;
    if (trimmedText.isEmpty && effectiveAttachments.isEmpty) {
      return;
    }
    _traceFinal(
      'submit-message',
      sessionId: _currentSession?.id,
      details:
          'textLen=${trimmedText.length} attachments=${effectiveAttachments.length} shellMode=$shellMode commandMode=$commandMode',
    );
    await sendMessage(
      trimmedText,
      attachments: effectiveAttachments,
      shellMode: shellMode,
      commandMode: commandMode,
    );
  }

  /// Send message
  Future<bool> sendMessage(
    String text, {
    List<FileInputPart> attachments = const <FileInputPart>[],
    bool shellMode = false,
    bool commandMode = false,
    String? localMessageId,
    bool appendOptimisticMessage = true,
    String? sessionIdOverride,
  }) async {
    final trimmedText = text.trim();
    final effectiveAttachments = shellMode || commandMode
        ? const <FileInputPart>[]
        : attachments;
    final normalizedSessionOverride = sessionIdOverride;
    final hasSessionOverride =
        normalizedSessionOverride != null &&
        normalizedSessionOverride.isNotEmpty;
    if (trimmedText.isEmpty && effectiveAttachments.isEmpty) {
      return false;
    }
    if (!_guardTransportForAction(actionLabel: 'send message')) {
      // Preserve the user's draft so it is restored to the composer
      // instead of being silently discarded. This upholds the
      // BEHAVIOR.md invariant that user text is never lost on send
      // failure. The same _setActiveSendDraft + _stashRejectedDraftForRetry
      // pair is used by existing stream-failure recovery paths.
      _setActiveSendDraft(
        trimmedText,
        attachments: effectiveAttachments,
        shellMode: shellMode,
      );
      _stashRejectedDraftForRetry(sessionId: _currentSession?.id);
      return false;
    }

    _cellularDataSaverService.noteExplicitUserAction(reason: 'send-message');
    await _syncCellularDataSaverRealtimePolicy(
      reason: 'send-message-user',
      forceBurst: true,
    );

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
    final currentReplacementBranch = _pendingReplacementBranch;
    if (currentReplacementBranch != null &&
        currentReplacementBranch.sessionId != sendSessionId) {
      _clearPendingReplacementBranch(
        sessionId: currentReplacementBranch.sessionId,
      );
    }
    final activeRevert = _currentSession?.id == sendSessionId
        ? _currentSession?.revert
        : null;
    if (activeRevert != null) {
      _startPendingReplacementBranch(
        sessionId: sendSessionId,
        revertMessageId: activeRevert.messageId,
      );
    }
    AppLogger.info(
      'Provider send start session=$sendSessionId agent=${_selectedAgentName ?? "-"} provider=${_selectedProviderId ?? "-"} model=${_selectedModelId ?? "-"} variant=${_selectedVariantId ?? "auto"}',
    );
    _traceFinal(
      'send-start',
      sessionId: sendSessionId,
      details:
          'textLen=${trimmedText.length} attachments=${effectiveAttachments.length} shell=$shellMode command=$commandMode sessionOverride=$hasSessionOverride',
    );
    _setActiveSendDraft(
      trimmedText,
      attachments: effectiveAttachments,
      shellMode: shellMode,
    );
    _preserveBusyStatusOnNextStreamDoneSessionId = null;
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

      _setPendingReplacementBranchRootMessage(
        sessionId: sendSessionId,
        messageId: activeLocalMessageId,
      );

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

      // Create chat input.
      //
      // INVARIANT — do NOT add a `messageId` field here (see ADR-023 Pitfall P-001):
      // The server must assign its own canonical ID for the user message. Forwarding
      // the local optimistic ID as `messageId` in the payload causes the SSE event
      // stream to fail reconciliation for all turns after the first — assistant
      // responses are received but silently discarded. (Regression: b0660a2)
      final inputParts = <ChatInputPart>[
        if (trimmedText.isNotEmpty) TextInputPart(text: trimmedText),
        ...effectiveAttachments,
      ];
      final input = ChatInput(
        providerId: _selectedProviderId ?? 'anthropic',
        modelId: _selectedModelId ?? 'claude-3-5-sonnet-20241022',
        variant: _selectedVariantId,
        mode: commandMode
            ? 'command'
            : (shellMode ? 'shell' : selectedAgentForSend),
        parts: inputParts,
      );

      // Cancel previous subscription and invalidate stale callbacks.
      _traceFinal(
        'send-cancel-previous-subscription',
        sessionId: sendSessionId,
        details: 'previousActive=${_activeMessageStreamSessionId ?? "-"}',
      );
      await _cancelActiveMessageSubscription(
        reason: 'start-send',
        invalidateGeneration: true,
      );
      final streamGeneration = _messageStreamGeneration;
      final streamSessionId = sendSessionId;
      _activeMessageStreamSessionId = streamSessionId;
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
                    _clearSessionUnreadCompletion(streamSessionId);
                    _sessionErrorAttentionIds.add(streamSessionId);
                    _notifyListeners();
                    return;
                  }
                  _handleSendFailure(failure, sessionId: streamSessionId);
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
                _clearSessionUnreadCompletion(streamSessionId);
                _sessionErrorAttentionIds.add(streamSessionId);
                _notifyListeners();
                return;
              }
              _presentServerErrorForCurrentSession(
                sessionId: streamSessionId,
                rawMessage: error.toString(),
              );
            },
            onDone: () {
              _traceFinal(
                'send-stream-ondone',
                sessionId: streamSessionId,
                details:
                    'eventGeneration=$streamGeneration active=$_messageStreamGeneration',
              );
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
              unawaited(
                _persistComposerDraftForSessionInternal(
                  sessionId: streamSessionId,
                  draft: null,
                ),
              );
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
              final preserveBusyStatusOnDone =
                  _preserveBusyStatusOnNextStreamDoneSessionId ==
                  streamSessionId;
              if (preserveBusyStatusOnDone) {
                _preserveBusyStatusOnNextStreamDoneSessionId = null;
                if (_currentSession?.id == streamSessionId) {
                  _setState(ChatState.loaded);
                } else {
                  _notifyListeners();
                }
                return;
              }
              _sessionStatusById[streamSessionId] = const SessionStatusInfo(
                type: SessionStatusType.idle,
              );
              _sseSettledToIdleSessionIds.add(streamSessionId);
              if (_currentSession?.id == streamSessionId) {
                _markIncompleteAssistantMessagesAsCompleted(
                  sessionId: streamSessionId,
                );
                _setState(ChatState.loaded);
                unawaited(_persistLastSessionSnapshotBestEffort());
                unawaited(loadSessionInsights(streamSessionId, silent: true));
              } else {
                final clearedError = _sessionErrorAttentionIds.remove(
                  streamSessionId,
                );
                final addedUnread = !_sessionUnreadCompletionIds.contains(
                  streamSessionId,
                );
                _markSessionUnreadCompletion(streamSessionId);
                final statusChanged =
                    previousStatusType != SessionStatusType.idle;
                if (statusChanged || clearedError || addedUnread) {
                  _notifyListeners();
                }
              }
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
      unawaited(
        _persistComposerDraftForSessionInternal(
          sessionId: session.id,
          draft: null,
        ),
      );
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
    }
    return success;
  }

  Future<bool> compactCurrentSession() async {
    if (_isCompactingContext) {
      return false;
    }
    if (!_guardTransportForAction(actionLabel: 'compact session')) {
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
    final previousCurrentSession = _currentSession;

    final archivedAt = archived ? DateTime.now() : null;
    final optimistic = previous.copyWith(
      archivedAt: archivedAt,
      title: previous.title,
    );
    _applySessionLocally(optimistic);

    if (archived && _sessionListFilter == SessionListFilter.active) {
      final visibleSessionIds = _buildVisibleSessionsFrom(
        _sessions,
      ).map((item) => item.id).toSet();
      final currentSessionId = _currentSession?.id;
      if (currentSessionId != null &&
          !visibleSessionIds.contains(currentSessionId)) {
        _currentSession = _buildVisibleSessionsFrom(
          _sessions,
        ).where((item) => item.id != currentSessionId).firstOrNull;
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
        if (previousCurrentSession != null) {
          _currentSession =
              _sessionById(previousCurrentSession.id) ?? previousCurrentSession;
          _threadPermissionsVersion++;
        }
        _handleFailure(failure);
        notifyListeners();
        return false;
      },
      (updated) {
        _applySessionLocally(updated);
        if (_currentSession?.id == updated.id) {
          _currentSession = updated;
        }
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

  String? get latestRevertibleMessageId {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      return null;
    }
    final visibleMessages = messages;
    for (var index = visibleMessages.length - 1; index >= 0; index -= 1) {
      final message = visibleMessages[index];
      if (message.sessionId != sessionId || message is! UserMessage) {
        continue;
      }
      if (_isOptimisticLocalUserMessageId(message.id)) {
        continue;
      }
      return message.id;
    }
    return null;
  }

  bool get canUndoCurrentSession => latestRevertibleMessageId != null;

  bool get canRedoCurrentSession => currentSessionRevert != null;

  bool get shouldDeferConfigMutations =>
      _hasLocalActiveSelectionSyncWork ||
      _hasAnyActiveAbortSuppression ||
      _hasAnyBusySessionStatus;

  Future<bool> undoLastTurn() async {
    final messageId = latestRevertibleMessageId;
    if (messageId == null) {
      return false;
    }

    return revertToTurn(messageId);
  }

  Future<bool> revertToTurn(String messageId) async {
    if (_isOptimisticLocalUserMessageId(messageId) || _historyRevertInFlight) {
      return false;
    }

    final session = _currentSession;
    final useCase = revertChatMessage;
    if (session == null || useCase == null) {
      return false;
    }

    _historyRevertInFlight = true;
    try {
      return await _performRevertToTurn(session: session, messageId: messageId);
    } finally {
      _historyRevertInFlight = false;
    }
  }

  Future<bool> _performRevertToTurn({
    required ChatSession session,
    required String messageId,
  }) async {
    final useCase = revertChatMessage!;
    _clearPendingReplacementBranch(sessionId: session.id);

    final revertedMessage = _findUserMessageById(messageId);
    final restoredDraft = revertedMessage == null
        ? null
        : _buildComposerDraftFromUserMessage(revertedMessage);

    final result = await useCase(
      RevertChatMessageParams(
        projectId: projectProvider.currentProjectId,
        sessionId: session.id,
        messageId: messageId,
        directory: projectProvider.currentDirectory,
      ),
    );

    return result.fold<Future<bool>>(
      (failure) async {
        _handleFailure(failure);
        notifyListeners();
        return false;
      },
      (_) async {
        _applyCurrentSessionRevert(SessionRevert(messageId: messageId));
        _queueHistoryComposerSync(sessionId: session.id, draft: restoredDraft);
        await refreshActiveSessionView(reason: 'undo-success');
        await loadSessionInsights(session.id, silent: true);
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> redoLastTurn() async {
    final session = _currentSession;
    if (session == null || currentSessionRevert == null) {
      return false;
    }

    _clearPendingReplacementBranch(sessionId: session.id);

    final nextRevertMessageId = _nextRedoBoundaryMessageId();
    if (nextRevertMessageId != null) {
      final useCase = revertChatMessage;
      if (useCase == null) {
        return false;
      }
      final result = await useCase(
        RevertChatMessageParams(
          projectId: projectProvider.currentProjectId,
          sessionId: session.id,
          messageId: nextRevertMessageId,
          directory: projectProvider.currentDirectory,
        ),
      );

      return result.fold(
        (failure) {
          _handleFailure(failure);
          notifyListeners();
          return false;
        },
        (_) async {
          _applyCurrentSessionRevert(
            SessionRevert(messageId: nextRevertMessageId),
          );
          await refreshActiveSessionView(reason: 'redo-success');
          await loadSessionInsights(session.id, silent: true);
          notifyListeners();
          return true;
        },
      );
    }

    final useCase = unrevertChatMessages;
    if (useCase == null) {
      return false;
    }

    final result = await useCase(
      UnrevertChatMessagesParams(
        projectId: projectProvider.currentProjectId,
        sessionId: session.id,
        directory: projectProvider.currentDirectory,
      ),
    );

    return result.fold(
      (failure) {
        _handleFailure(failure);
        notifyListeners();
        return false;
      },
      (_) async {
        _applyCurrentSessionRevert(null);
        _queueHistoryComposerSync(sessionId: session.id, clear: true);
        await refreshActiveSessionView(reason: 'redo-success');
        await loadSessionInsights(session.id, silent: true);
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
        _messages = List<ChatMessage>.from(previousMessages);
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
    _cellularDataSaverService.noteExplicitUserAction(reason: 'manual-refresh');
    await _syncCellularDataSaverRealtimePolicy(
      reason: 'manual-refresh-user',
      forceBurst: true,
    );
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
    _cellularDataSaverService.removeListener(_handleCellularDataSaverChanged);
    unawaited(
      _cancelActiveMessageSubscription(
        reason: 'dispose',
        invalidateGeneration: true,
      ),
    );
    _eventStreamGeneration += 1;
    _eventSubscription?.cancel();
    _globalEventSubscription?.cancel();
    _globalRefreshDebounce?.cancel();
    for (final timer in _messageFallbackDebounceById.values) {
      timer.cancel();
    }
    _messageFallbackDebounceById.clear();
    _syncHealthTimer?.cancel();
    _degradedPollingTimer?.cancel();
    _foregroundResumeSyncTimer?.cancel();
    _sessionUnreadHighlightTimer?.cancel();
    super.dispose();
  }

  List<ChatSession> _sessionsForScopeId(String scopeId) {
    final normalizedScopeId = scopeId.trim();
    if (normalizedScopeId.isEmpty) {
      return const <ChatSession>[];
    }
    final contextKey = _composeContextKey(_activeServerId, normalizedScopeId);
    if (contextKey == _activeContextKey) {
      return _sessions;
    }
    return _contextSnapshots[contextKey]?.sessions ?? const <ChatSession>[];
  }

  Map<String, bool> _hiddenByArchivedAncestor(
    Map<String, ChatSession> sessionById,
  ) {
    final memo = <String, bool>{};

    bool resolve(String sessionId, Set<String> stack) {
      final cached = memo[sessionId];
      if (cached != null) {
        return cached;
      }
      if (!stack.add(sessionId)) {
        return false;
      }
      final session = sessionById[sessionId];
      final parentId = session?.parentId?.trim();
      if (session == null || parentId == null || parentId.isEmpty) {
        memo[sessionId] = false;
        stack.remove(sessionId);
        return false;
      }
      final parent = sessionById[parentId];
      final hidden =
          parent != null && (parent.archived || resolve(parentId, stack));
      memo[sessionId] = hidden;
      stack.remove(sessionId);
      return hidden;
    }

    for (final sessionId in sessionById.keys) {
      resolve(sessionId, <String>{});
    }
    return memo;
  }

  void _markSessionUnreadCompletion(String sessionId, {DateTime? timestamp}) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    // Child/task sessions should finish silently; only root sessions own
    // completion attention surfaces such as unread highlights and menu badges.
    final session = _sessionById(normalizedSessionId);
    final parentId = session?.parentId?.trim();
    if (session == null || (parentId != null && parentId.isNotEmpty)) {
      _clearSessionUnreadCompletion(normalizedSessionId);
      return;
    }
    _sessionUnreadCompletionIds.add(normalizedSessionId);
    _sessionUnreadCompletionTimestamps[normalizedSessionId] =
        timestamp ??
        _sessionUnreadCompletionTimestamps[normalizedSessionId] ??
        DateTime.now();
    _scheduleSessionUnreadHighlightTimer();
  }

  void _clearSessionUnreadCompletion(String sessionId) {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      return;
    }
    _sessionUnreadCompletionIds.remove(normalizedSessionId);
    _sessionUnreadCompletionTimestamps.remove(normalizedSessionId);
    _scheduleSessionUnreadHighlightTimer();
  }

  void _scheduleSessionUnreadHighlightTimer() {
    _sessionUnreadHighlightTimer?.cancel();
    _sessionUnreadHighlightTimer = null;

    final now = DateTime.now();
    DateTime? nextExpiry;
    for (final entry in _sessionUnreadCompletionTimestamps.entries) {
      final expiresAt = entry.value.add(const Duration(hours: 1));
      if (!expiresAt.isAfter(now)) {
        continue;
      }
      if (nextExpiry == null || expiresAt.isBefore(nextExpiry)) {
        nextExpiry = expiresAt;
      }
    }
    for (final snapshot in _contextSnapshots.values) {
      for (final entry in snapshot.sessionUnreadCompletionTimestamps.entries) {
        final expiresAt = entry.value.add(const Duration(hours: 1));
        if (!expiresAt.isAfter(now)) {
          continue;
        }
        if (nextExpiry == null || expiresAt.isBefore(nextExpiry)) {
          nextExpiry = expiresAt;
        }
      }
    }
    if (nextExpiry == null) {
      return;
    }

    _sessionUnreadHighlightTimer = Timer(nextExpiry.difference(now), () {
      _pruneExpiredUnreadHighlights();
      _notifyListeners();
    });
  }

  void _pruneExpiredUnreadHighlights() {
    final now = DateTime.now();
    _sessionUnreadCompletionTimestamps.removeWhere((sessionId, timestamp) {
      final expired = now.difference(timestamp) >= const Duration(hours: 1);
      if (expired) {
        _sessionUnreadCompletionIds.remove(sessionId);
      }
      return expired;
    });

    final updatedSnapshots = <String, _ChatContextSnapshot>{};
    for (final entry in _contextSnapshots.entries) {
      final snapshot = entry.value;
      final nextTimestamps = Map<String, DateTime>.from(
        snapshot.sessionUnreadCompletionTimestamps,
      );
      final nextIds = Set<String>.from(snapshot.sessionUnreadCompletionIds);
      var changed = false;
      nextTimestamps.removeWhere((sessionId, timestamp) {
        final expired = now.difference(timestamp) >= const Duration(hours: 1);
        if (expired) {
          nextIds.remove(sessionId);
          changed = true;
        }
        return expired;
      });
      if (!changed) {
        continue;
      }
      updatedSnapshots[entry.key] = _ChatContextSnapshot(
        sessions: snapshot.sessions,
        currentSession: snapshot.currentSession,
        messages: snapshot.messages,
        sessionStatusById: snapshot.sessionStatusById,
        pendingPermissionsBySession: snapshot.pendingPermissionsBySession,
        pendingQuestionsBySession: snapshot.pendingQuestionsBySession,
        sessionUnreadCompletionIds: nextIds,
        sessionUnreadCompletionTimestamps: nextTimestamps,
        sessionErrorAttentionIds: snapshot.sessionErrorAttentionIds,
        sessionChildrenById: snapshot.sessionChildrenById,
        sessionTodoById: snapshot.sessionTodoById,
        sessionDiffById: snapshot.sessionDiffById,
        sessionSearchQuery: snapshot.sessionSearchQuery,
        sessionListFilter: snapshot.sessionListFilter,
        sessionListSort: snapshot.sessionListSort,
        pinnedSessionIds: snapshot.pinnedSessionIds,
        sessionVisibleLimit: snapshot.sessionVisibleLimit,
        isNewChatDraftActive: snapshot.isNewChatDraftActive,
        activeSendDraft: snapshot.activeSendDraft,
        rejectedDraft: snapshot.rejectedDraft,
      );
    }
    if (updatedSnapshots.isNotEmpty) {
      _contextSnapshots.addAll(updatedSnapshots);
    }
    _scheduleSessionUnreadHighlightTimer();
  }
}
