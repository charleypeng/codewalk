part of '../chat_provider.dart';

class SessionTabReconciler {
  const SessionTabReconciler._();

  static const Duration recentWindow = Duration(hours: 3);

  static SessionTabReconciliationResult reconcile({
    required String serverId,
    required PersistedSessionTabsState persistedState,
    required Iterable<SessionTabCandidate> candidates,
    required int nowMs,
    SessionTabIdentity? explicitlyOpened,
    String? bootstrapDirectory,
  }) {
    final normalizedServerId = serverId.trim();
    final normalizedBootstrapDirectory = normalizeOptionalFilePath(
      bootstrapDirectory,
    );
    final cutoffMs = nowMs - recentWindow.inMilliseconds;
    final candidateByIdentity = <SessionTabIdentity, SessionTabCandidate>{};
    final candidateOrder = <SessionTabIdentity>[];
    for (final candidate in candidates) {
      final identity = candidate.identity;
      if (!identity.isValid || identity.serverId != normalizedServerId) {
        continue;
      }
      final previous = candidateByIdentity[identity];
      if (previous == null) {
        candidateOrder.add(identity);
        candidateByIdentity[identity] = candidate;
      } else {
        candidateByIdentity[identity] = _mergeCandidates(previous, candidate);
      }
    }

    final closedByIdentity = <SessionTabIdentity, PersistedClosedSessionTab>{};
    final closedOrder = <SessionTabIdentity>[];
    for (final closed in persistedState.closed) {
      final identity = SessionTabIdentity(
        serverId: normalizedServerId,
        directory: closed.directory,
        sessionId: closed.sessionId,
      );
      if (!identity.isValid) continue;
      final candidate = candidateByIdentity[identity];
      if (candidate != null && (!candidate.isRoot || candidate.isArchived)) {
        continue;
      }
      final previous = closedByIdentity[identity];
      if (previous == null) {
        closedOrder.add(identity);
        closedByIdentity[identity] = _normalizedClosed(closed, identity);
      } else if (closed.closedAtMs >= previous.closedAtMs) {
        closedByIdentity[identity] = _normalizedClosed(
          closed,
          identity,
          observedServerUpdatedAtMs: math.max(
            previous.observedServerUpdatedAtMs,
            closed.observedServerUpdatedAtMs,
          ),
        );
      }
    }

    final openByIdentity = <SessionTabIdentity, PersistedSessionTab>{};
    final openOrder = <SessionTabIdentity>[];
    for (final persisted in persistedState.open) {
      final identity = SessionTabIdentity(
        serverId: normalizedServerId,
        directory: persisted.directory,
        sessionId: persisted.sessionId,
      );
      if (!identity.isValid) continue;
      final previous = openByIdentity[identity];
      if (previous == null) {
        openOrder.add(identity);
        openByIdentity[identity] = persisted;
      } else {
        openByIdentity[identity] = _mergePersistedTabs(
          previous,
          persisted,
          identity,
        );
      }
    }

    final tabs = <SessionTabRecord>[];
    final handled = <SessionTabIdentity>{};
    for (final identity in openOrder) {
      final persisted = openByIdentity[identity]!;
      handled.add(identity);
      final candidate = candidateByIdentity[identity];
      if (candidate != null && (!candidate.isRoot || candidate.isArchived)) {
        continue;
      }
      if (_isSuppressedByClosedTab(
        identity: identity,
        candidate: candidate,
        closedByIdentity: closedByIdentity,
        explicitlyOpened: explicitlyOpened,
      )) {
        continue;
      }
      final serverUpdatedAtMs = math.max(
        persisted.serverUpdatedAtMs,
        candidate?.serverUpdatedAtMs ?? 0,
      );
      final lastOpenedAtMs = explicitlyOpened == identity
          ? nowMs
          : persisted.lastOpenedAtMs;
      final isSelected = candidate?.isSelected ?? false;
      final isBusy = candidate?.isBusy ?? false;
      if (!isSelected &&
          !isBusy &&
          math.max(lastOpenedAtMs, serverUpdatedAtMs) < cutoffMs) {
        continue;
      }
      tabs.add(
        SessionTabRecord(
          identity: identity,
          projectId: candidate?.projectId ?? persisted.projectId,
          title: _tabTitle(
            candidate?.title,
            persisted.title,
            identity.sessionId,
          ),
          lastOpenedAtMs: lastOpenedAtMs,
          serverUpdatedAtMs: serverUpdatedAtMs,
          status: candidate?.status ?? SessionStatusType.idle,
          pendingQuestionIds: candidate?.pendingQuestionIds ?? const <String>[],
          seenQuestionIds: persisted.seenQuestionIds,
          completionToken: candidate?.completionToken,
          seenCompletionToken: persisted.seenCompletionToken,
          errorToken: candidate?.errorToken,
          seenErrorToken: persisted.seenErrorToken,
          isSelected: isSelected,
        ),
      );
    }

    final candidateIndex = <SessionTabIdentity, int>{
      for (var index = 0; index < candidateOrder.length; index += 1)
        candidateOrder[index]: index,
    };
    final newCandidates =
        candidateOrder
            .where((identity) => !handled.contains(identity))
            .map((identity) => candidateByIdentity[identity]!)
            .where((candidate) {
              if (!candidate.isRoot || candidate.isArchived) return false;
              if (_isSuppressedByClosedTab(
                identity: candidate.identity,
                candidate: candidate,
                closedByIdentity: closedByIdentity,
                explicitlyOpened: explicitlyOpened,
              )) {
                return false;
              }
              return explicitlyOpened == candidate.identity ||
                  candidate.isSelected ||
                  candidate.isBusy ||
                  candidate.serverUpdatedAtMs >= cutoffMs;
            })
            .toList(growable: false)
          ..sort((left, right) {
            final leftRecentAt = explicitlyOpened == left.identity
                ? nowMs
                : left.serverUpdatedAtMs;
            final rightRecentAt = explicitlyOpened == right.identity
                ? nowMs
                : right.serverUpdatedAtMs;
            final recentComparison = leftRecentAt.compareTo(rightRecentAt);
            if (recentComparison != 0) return recentComparison;
            return candidateIndex[left.identity]!.compareTo(
              candidateIndex[right.identity]!,
            );
          });
    for (final candidate in newCandidates) {
      tabs.add(
        SessionTabRecord(
          identity: candidate.identity,
          projectId: candidate.projectId,
          title: _tabTitle(candidate.title, '', candidate.identity.sessionId),
          lastOpenedAtMs: explicitlyOpened == candidate.identity ? nowMs : 0,
          serverUpdatedAtMs: candidate.serverUpdatedAtMs,
          status: candidate.status,
          pendingQuestionIds: candidate.pendingQuestionIds,
          completionToken: candidate.completionToken,
          errorToken: candidate.errorToken,
          isSelected: candidate.isSelected,
        ),
      );
    }

    if (normalizedBootstrapDirectory != null &&
        !tabs.any(
          (tab) => tab.identity.directory == normalizedBootstrapDirectory,
        )) {
      final fallback = _mostRecentBootstrapTab(
        directory: normalizedBootstrapDirectory,
        openOrder: openOrder,
        openByIdentity: openByIdentity,
        candidateOrder: candidateOrder,
        candidateByIdentity: candidateByIdentity,
        closedByIdentity: closedByIdentity,
        explicitlyOpened: explicitlyOpened,
        nowMs: nowMs,
      );
      if (fallback != null) {
        tabs.add(fallback);
      }
    }

    final retainedClosed = <PersistedClosedSessionTab>[];
    for (final identity in closedOrder) {
      final closed = closedByIdentity[identity];
      if (closed == null) continue;
      retainedClosed.add(closed);
    }

    return SessionTabReconciliationResult(
      tabs: List<SessionTabRecord>.unmodifiable(tabs),
      persistedState: PersistedSessionTabsState(
        open: tabs.map((tab) => tab.toPersisted()).toList(growable: false),
        closed: List<PersistedClosedSessionTab>.unmodifiable(retainedClosed),
      ),
    );
  }

  static PersistedSessionTabsState close({
    required PersistedSessionTabsState state,
    required SessionTabIdentity identity,
    required int nowMs,
  }) {
    if (!identity.isValid) return state;
    var observedServerUpdatedAtMs = 0;
    String? projectId;
    final open = <PersistedSessionTab>[];
    for (final tab in state.open) {
      if (_matchesPersisted(tab, identity)) {
        observedServerUpdatedAtMs = math.max(
          observedServerUpdatedAtMs,
          tab.serverUpdatedAtMs,
        );
        projectId ??= tab.projectId;
      } else {
        open.add(tab);
      }
    }
    final closed =
        state.closed
            .where((tab) => !_matchesClosed(tab, identity))
            .toList(growable: true)
          ..add(
            PersistedClosedSessionTab(
              directory: identity.directory,
              projectId: projectId,
              sessionId: identity.sessionId,
              closedAtMs: nowMs,
              observedServerUpdatedAtMs: observedServerUpdatedAtMs,
            ),
          );
    return PersistedSessionTabsState(open: open, closed: closed);
  }

  static PersistedSessionTabsState removeAuthoritatively({
    required PersistedSessionTabsState state,
    required SessionTabIdentity identity,
  }) {
    return PersistedSessionTabsState(
      open: state.open
          .where((tab) => !_matchesPersisted(tab, identity))
          .toList(growable: false),
      closed: state.closed
          .where((tab) => !_matchesClosed(tab, identity))
          .toList(growable: false),
    );
  }

  static bool _isSuppressedByClosedTab({
    required SessionTabIdentity identity,
    required SessionTabCandidate? candidate,
    required Map<SessionTabIdentity, PersistedClosedSessionTab>
    closedByIdentity,
    required SessionTabIdentity? explicitlyOpened,
  }) {
    final closed = closedByIdentity[identity];
    if (closed == null) return false;
    final shouldReopen =
        explicitlyOpened == identity ||
        (candidate != null &&
            candidate.serverUpdatedAtMs > closed.observedServerUpdatedAtMs);
    if (shouldReopen) {
      closedByIdentity.remove(identity);
      return false;
    }
    return true;
  }

  static SessionTabRecord? _mostRecentBootstrapTab({
    required String directory,
    required List<SessionTabIdentity> openOrder,
    required Map<SessionTabIdentity, PersistedSessionTab> openByIdentity,
    required List<SessionTabIdentity> candidateOrder,
    required Map<SessionTabIdentity, SessionTabCandidate> candidateByIdentity,
    required Map<SessionTabIdentity, PersistedClosedSessionTab>
    closedByIdentity,
    required SessionTabIdentity? explicitlyOpened,
    required int nowMs,
  }) {
    final identities = <SessionTabIdentity>[
      ...openOrder,
      ...candidateOrder.where(
        (identity) => !openByIdentity.containsKey(identity),
      ),
    ];
    SessionTabRecord? latest;
    var latestAtMs = -1;
    for (final identity in identities) {
      if (identity.directory != directory) continue;
      final persisted = openByIdentity[identity];
      final candidate = candidateByIdentity[identity];
      if (candidate != null && (!candidate.isRoot || candidate.isArchived)) {
        continue;
      }
      if (_isSuppressedByClosedTab(
        identity: identity,
        candidate: candidate,
        closedByIdentity: closedByIdentity,
        explicitlyOpened: explicitlyOpened,
      )) {
        continue;
      }
      final serverUpdatedAtMs = math.max(
        persisted?.serverUpdatedAtMs ?? 0,
        candidate?.serverUpdatedAtMs ?? 0,
      );
      final lastOpenedAtMs = explicitlyOpened == identity
          ? nowMs
          : persisted?.lastOpenedAtMs ?? 0;
      final recentAtMs = math.max(lastOpenedAtMs, serverUpdatedAtMs);
      if (latest != null && recentAtMs <= latestAtMs) continue;
      latestAtMs = recentAtMs;
      latest = SessionTabRecord(
        identity: identity,
        projectId: candidate?.projectId ?? persisted?.projectId,
        title: _tabTitle(
          candidate?.title,
          persisted?.title ?? '',
          identity.sessionId,
        ),
        lastOpenedAtMs: lastOpenedAtMs,
        serverUpdatedAtMs: serverUpdatedAtMs,
        status: candidate?.status ?? SessionStatusType.idle,
        pendingQuestionIds: candidate?.pendingQuestionIds ?? const <String>[],
        seenQuestionIds: persisted?.seenQuestionIds ?? const <String>[],
        completionToken: candidate?.completionToken,
        seenCompletionToken: persisted?.seenCompletionToken,
        errorToken: candidate?.errorToken,
        seenErrorToken: persisted?.seenErrorToken,
        isSelected: candidate?.isSelected ?? false,
      );
    }
    return latest;
  }

  static SessionTabCandidate _mergeCandidates(
    SessionTabCandidate previous,
    SessionTabCandidate next,
  ) {
    final latest = next.serverUpdatedAtMs >= previous.serverUpdatedAtMs
        ? next
        : previous;
    final status = next.isBusy
        ? next.status
        : previous.isBusy
        ? previous.status
        : latest.status;
    return SessionTabCandidate(
      identity: previous.identity,
      projectId: latest.projectId ?? previous.projectId ?? next.projectId,
      title: latest.title.trim().isNotEmpty
          ? latest.title
          : previous.title.trim().isNotEmpty
          ? previous.title
          : next.title,
      serverUpdatedAtMs: math.max(
        previous.serverUpdatedAtMs,
        next.serverUpdatedAtMs,
      ),
      status: status,
      isSelected: previous.isSelected || next.isSelected,
      isArchived: latest.isArchived,
      isRoot: latest.isRoot,
      pendingQuestionIds: <String>{
        ...previous.pendingQuestionIds,
        ...next.pendingQuestionIds,
      },
      completionToken:
          latest.completionToken ??
          previous.completionToken ??
          next.completionToken,
      errorToken: latest.errorToken ?? previous.errorToken ?? next.errorToken,
    );
  }

  static PersistedSessionTab _mergePersistedTabs(
    PersistedSessionTab previous,
    PersistedSessionTab next,
    SessionTabIdentity identity,
  ) {
    final previousRecentAt = math.max(
      previous.lastOpenedAtMs,
      previous.serverUpdatedAtMs,
    );
    final nextRecentAt = math.max(next.lastOpenedAtMs, next.serverUpdatedAtMs);
    final latest = nextRecentAt >= previousRecentAt ? next : previous;
    return PersistedSessionTab(
      directory: identity.directory,
      projectId: latest.projectId ?? previous.projectId ?? next.projectId,
      sessionId: identity.sessionId,
      title: _tabTitle(latest.title, previous.title, identity.sessionId),
      lastOpenedAtMs: math.max(previous.lastOpenedAtMs, next.lastOpenedAtMs),
      serverUpdatedAtMs: math.max(
        previous.serverUpdatedAtMs,
        next.serverUpdatedAtMs,
      ),
      seenQuestionIds: <String>{
        ...previous.seenQuestionIds,
        ...next.seenQuestionIds,
      }.toList(growable: false),
      seenCompletionToken:
          latest.seenCompletionToken ?? previous.seenCompletionToken,
      seenErrorToken: latest.seenErrorToken ?? previous.seenErrorToken,
    );
  }

  static PersistedClosedSessionTab _normalizedClosed(
    PersistedClosedSessionTab closed,
    SessionTabIdentity identity, {
    int? observedServerUpdatedAtMs,
  }) {
    return PersistedClosedSessionTab(
      directory: identity.directory,
      projectId: closed.projectId,
      sessionId: identity.sessionId,
      closedAtMs: closed.closedAtMs,
      observedServerUpdatedAtMs:
          observedServerUpdatedAtMs ?? closed.observedServerUpdatedAtMs,
    );
  }

  static bool _matchesPersisted(
    PersistedSessionTab tab,
    SessionTabIdentity identity,
  ) {
    return normalizeFilePath(tab.directory) == identity.directory &&
        tab.sessionId.trim() == identity.sessionId;
  }

  static bool _matchesClosed(
    PersistedClosedSessionTab tab,
    SessionTabIdentity identity,
  ) {
    return normalizeFilePath(tab.directory) == identity.directory &&
        tab.sessionId.trim() == identity.sessionId;
  }

  static String _tabTitle(
    String? candidateTitle,
    String persistedTitle,
    String sessionId,
  ) {
    final normalizedCandidate = candidateTitle?.trim();
    if (normalizedCandidate != null && normalizedCandidate.isNotEmpty) {
      return normalizedCandidate;
    }
    final normalizedPersisted = persistedTitle.trim();
    if (normalizedPersisted.isNotEmpty) return normalizedPersisted;
    return sessionId;
  }
}

extension _ChatProviderSessionTabOps on ChatProvider {
  bool get _isSessionTabRouteVisible =>
      _isForegroundActive && _isChatRouteActive;

  Future<void> _ensureSessionTabsLoaded({String? serverId}) async {
    final targetServerId = (serverId ?? _activeServerId).trim();
    if (targetServerId.isEmpty) return;
    if (_sessionTabsLoadedServerId == targetServerId) {
      _reconcileSessionTabs();
      return;
    }
    final generation = ++_sessionTabsGeneration;
    String? raw;
    try {
      raw = await _enqueueSessionTabsPersistenceOperation<String?>(
        serverId: targetServerId,
        operation: () =>
            localDataSource.getSessionTabsStateJson(serverId: targetServerId),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load session tabs for server=$targetServerId',
        error: error,
        stackTrace: stackTrace,
      );
      if (!_sessionTabsDisposed &&
          generation == _sessionTabsGeneration &&
          targetServerId == _activeServerId) {
        final hadVisibleTabs = _sessionTabs.isNotEmpty;
        _sessionTabs = const <SessionTabRecord>[];
        _sessionTabsPersistedState = const PersistedSessionTabsState();
        _sessionTabsLoadedServerId = null;
        if (hadVisibleTabs) _notifyListeners();
      }
      return;
    }
    if (_sessionTabsDisposed ||
        generation != _sessionTabsGeneration ||
        targetServerId != _activeServerId) {
      return;
    }
    _sessionTabsLoadedServerId = targetServerId;
    _sessionTabsPersistedState = PersistedSessionTabsState.decode(raw);
    _reconcileSessionTabs();
  }

  void _reconcileSessionTabs({
    SessionTabIdentity? explicitlyOpened,
    bool markCurrentViewed = false,
    bool forcePersistence = false,
  }) {
    final serverId = _activeServerId.trim();
    if (serverId.isEmpty || _sessionTabsLoadedServerId != serverId) return;
    final previousStateJson = _sessionTabsPersistedState.encode();
    final result = SessionTabReconciler.reconcile(
      serverId: serverId,
      persistedState: _sessionTabsPersistedState,
      candidates: _collectSessionTabCandidates(serverId),
      nowMs: _sessionTabsNow().millisecondsSinceEpoch,
      explicitlyOpened: explicitlyOpened,
      bootstrapDirectory: _sessionTabBootstrapDirectory,
    );
    var nextTabs = result.tabs;
    var nextPersistedState = result.persistedState;
    if (markCurrentViewed) {
      final viewed = _markCurrentSessionTabViewedIn(nextTabs);
      nextTabs = viewed.tabs;
      nextPersistedState = PersistedSessionTabsState(
        open: nextTabs.map((tab) => tab.toPersisted()).toList(growable: false),
        closed: result.persistedState.closed,
      );
    }
    final runtimeChanged = !listEquals(_sessionTabs, nextTabs);
    final persistedChanged = previousStateJson != nextPersistedState.encode();
    _sessionTabs = List<SessionTabRecord>.unmodifiable(nextTabs);
    _sessionTabsPersistedState = nextPersistedState;
    _pruneSessionTabEventState(serverId);
    if (persistedChanged || forcePersistence) {
      _scheduleSessionTabsPersistence();
    }
    if (runtimeChanged) _notifyListeners();
  }

  void _markAuthoritativeSessionTabBootstrapOpened(String? directory) {
    final normalizedDirectory = normalizeOptionalFilePath(directory);
    if (normalizedDirectory == null ||
        _sessionTabBootstrapDirectory != normalizedDirectory) {
      return;
    }
    final targetTabs = _sessionTabs
        .where((tab) => tab.identity.directory == normalizedDirectory)
        .toList(growable: false);
    if (targetTabs.length != 1) return;
    final tab = targetTabs.single;
    final cutoffMs =
        _sessionTabsNow().millisecondsSinceEpoch -
        SessionTabReconciler.recentWindow.inMilliseconds;
    if (math.max(tab.lastOpenedAtMs, tab.serverUpdatedAtMs) >= cutoffMs) {
      return;
    }
    _reconcileSessionTabs(
      explicitlyOpened: tab.identity,
      markCurrentViewed: _isSessionTabRouteVisible,
    );
  }

  ({List<SessionTabRecord> tabs, bool changed}) _markCurrentSessionTabViewedIn(
    List<SessionTabRecord> tabs,
  ) {
    final currentSession = _currentSession;
    if (currentSession == null) return (tabs: tabs, changed: false);
    final identity = _sessionTabIdentityForSession(
      currentSession,
      contextKey: _activeContextKey,
    );
    if (identity == null) return (tabs: tabs, changed: false);
    var changed = false;
    final next = tabs
        .map((tab) {
          if (tab.identity != identity) return tab;
          final viewedQuestions = _normalizedSessionTabIds(<String>{
            ...tab.seenQuestionIds,
            ...tab.pendingQuestionIds,
          });
          final updated = tab.copyWith(
            seenQuestionIds: viewedQuestions,
            seenCompletionToken: tab.completionToken,
            seenErrorToken: tab.errorToken,
          );
          changed = changed || updated != tab;
          return updated;
        })
        .toList(growable: false);
    return (tabs: changed ? next : tabs, changed: changed);
  }

  void _recordVisibleSessionTab(ChatSession session) {
    if (session.parentId?.trim().isNotEmpty ?? false) return;
    if (session.archived) return;
    final identity = _sessionTabIdentityForSession(
      session,
      contextKey: _activeContextKey,
    );
    if (identity == null) return;
    _reconcileSessionTabs(
      explicitlyOpened: identity,
      markCurrentViewed: _isSessionTabRouteVisible,
    );
  }

  void _markCurrentSessionTabViewed() {
    if (!_isSessionTabRouteVisible) return;
    _reconcileSessionTabs(markCurrentViewed: true);
  }

  Iterable<SessionTabCandidate> _collectSessionTabCandidates(String serverId) {
    final candidates = <SessionTabCandidate>[];
    candidates.addAll(
      _sessionTabCandidatesForContext(
        serverId: serverId,
        contextKey: _activeContextKey,
        sessions: _sessions,
        currentSession: _currentSession,
        statusById: _sessionStatusById,
        pendingQuestionsBySession: _pendingQuestionsBySession,
        unreadCompletionIds: _sessionUnreadCompletionIds,
        unreadCompletionTimestamps: _sessionUnreadCompletionTimestamps,
        errorAttentionIds: _sessionErrorAttentionIds,
      ),
    );
    for (final entry in _contextSnapshots.entries) {
      if (entry.key == _activeContextKey ||
          _serverIdFromContextKey(entry.key) != serverId) {
        continue;
      }
      final snapshot = entry.value;
      candidates.addAll(
        _sessionTabCandidatesForContext(
          serverId: serverId,
          contextKey: entry.key,
          sessions: snapshot.sessions,
          currentSession: snapshot.currentSession,
          statusById: snapshot.sessionStatusById,
          pendingQuestionsBySession: snapshot.pendingQuestionsBySession,
          unreadCompletionIds: snapshot.sessionUnreadCompletionIds,
          unreadCompletionTimestamps:
              snapshot.sessionUnreadCompletionTimestamps,
          errorAttentionIds: snapshot.sessionErrorAttentionIds,
        ),
      );
    }
    final contextIdentities = candidates
        .map((candidate) => candidate.identity)
        .toSet();
    candidates.addAll(
      _sessionTabEventCandidates.values.where(
        (candidate) =>
            candidate.identity.serverId == serverId &&
            !contextIdentities.contains(candidate.identity),
      ),
    );
    return candidates;
  }

  Iterable<SessionTabCandidate> _sessionTabCandidatesForContext({
    required String serverId,
    required String contextKey,
    required List<ChatSession> sessions,
    required ChatSession? currentSession,
    required Map<String, SessionStatusInfo> statusById,
    required Map<String, List<ChatQuestionRequest>> pendingQuestionsBySession,
    required Set<String> unreadCompletionIds,
    required Map<String, DateTime> unreadCompletionTimestamps,
    required Set<String> errorAttentionIds,
  }) sync* {
    final scopeId = _scopeIdFromContextKey(contextKey);
    if (scopeId == null) return;
    for (final session in sessions) {
      final identity = _sessionTabIdentityForSession(
        session,
        contextKey: contextKey,
      );
      if (identity == null || identity.serverId != serverId) continue;
      final completionAt = unreadCompletionTimestamps[session.id];
      final completionToken = unreadCompletionIds.contains(session.id)
          ? _sessionTabCompletionTokens[identity] ??
                'completion:${completionAt?.millisecondsSinceEpoch ?? session.time.millisecondsSinceEpoch}'
          : null;
      final errorToken = errorAttentionIds.contains(session.id)
          ? _sessionTabErrorTokens[identity] ??
                'error:${session.time.millisecondsSinceEpoch}'
          : null;
      yield SessionTabCandidate(
        identity: identity,
        projectId: _sessionTabProjectId(session, contextKey: contextKey),
        title: session.title ?? '',
        serverUpdatedAtMs: session.time.millisecondsSinceEpoch,
        status: statusById[session.id]?.type ?? SessionStatusType.idle,
        isSelected:
            contextKey == _activeContextKey && currentSession?.id == session.id,
        isArchived: session.archived,
        isRoot: session.parentId?.trim().isEmpty ?? true,
        pendingQuestionIds:
            pendingQuestionsBySession[session.id]?.map(
              (request) => request.id,
            ) ??
            const <String>[],
        completionToken: completionToken,
        errorToken: errorToken,
      );
    }
  }

  SessionTabIdentity? _sessionTabIdentityForSession(
    ChatSession session, {
    required String contextKey,
  }) {
    final serverId = _serverIdFromContextKey(contextKey)?.trim();
    final directory =
        normalizeOptionalFilePath(_sessionDirectory(session)) ??
        normalizeOptionalFilePath(_scopeIdFromContextKey(contextKey));
    if (serverId == null || serverId.isEmpty || directory == null) return null;
    final identity = SessionTabIdentity(
      serverId: serverId,
      directory: directory,
      sessionId: session.id,
    );
    return identity.isValid ? identity : null;
  }

  String? _sessionTabProjectId(
    ChatSession session, {
    required String contextKey,
  }) {
    final workspaceId = session.workspaceId.trim();
    if (workspaceId.isNotEmpty && workspaceId != 'default') return workspaceId;
    if (contextKey == _activeContextKey) {
      final projectId = projectProvider.currentProjectId.trim();
      return projectId.isEmpty || projectId == 'default' ? null : projectId;
    }
    return null;
  }

  void _scheduleSessionTabsPersistence() {
    final serverId = _sessionTabsLoadedServerId;
    if (serverId == null || serverId.isEmpty) return;
    final payload = _sessionTabsPersistedState.encode();
    unawaited(
      _enqueueSessionTabsPersistence(serverId: serverId, payload: payload),
    );
  }

  Future<void> _enqueueSessionTabsPersistence({
    required String serverId,
    required String payload,
  }) async {
    try {
      await _enqueueSessionTabsPersistenceOperation<void>(
        serverId: serverId,
        operation: () => localDataSource.saveSessionTabsStateJson(
          payload,
          serverId: serverId,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to persist session tabs for server=$serverId',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<T> _enqueueSessionTabsPersistenceOperation<T>({
    required String serverId,
    required Future<T> Function() operation,
  }) {
    final previous =
        _sessionTabsWriteQueueByServer[serverId] ?? Future<void>.value();
    final result = Completer<T>();
    final next = previous.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    _sessionTabsWriteQueueByServer[serverId] = next;
    return result.future;
  }

  void _pruneSessionTabEventState(String serverId) {
    final retained = <SessionTabIdentity>{
      ..._sessionTabs.map((tab) => tab.identity),
      ..._sessionTabsPersistedState.closed.map(
        (tab) => SessionTabIdentity(
          serverId: serverId,
          directory: tab.directory,
          sessionId: tab.sessionId,
        ),
      ),
    };
    _sessionTabEventCandidates.removeWhere(
      (identity, _) =>
          identity.serverId == serverId && !retained.contains(identity),
    );
    _sessionTabErrorTokens.removeWhere(
      (identity, _) =>
          identity.serverId == serverId && !retained.contains(identity),
    );
    _sessionTabCompletionTokens.removeWhere(
      (identity, _) =>
          identity.serverId == serverId && !retained.contains(identity),
    );
  }

  void _updateSessionTabSignalsForEvent(
    ChatEvent event, {
    required String contextKey,
  }) {
    final sessionId = _effectiveEventSessionIdForEvent(event)?.trim();
    if (sessionId == null || sessionId.isEmpty) return;
    if (event.type == 'session.deleted') {
      final identity = _sessionTabIdentityForEventSession(
        sessionId,
        contextKey: contextKey,
      );
      if (identity != null) {
        _removeSessionTabAuthoritatively(identity);
      }
      return;
    }

    SessionTabIdentity? identity;
    if (event.type == 'session.created' || event.type == 'session.updated') {
      final rawInfo = event.properties['info'];
      if (rawInfo is Map) {
        try {
          final session = ChatSessionModel.fromJson(
            Map<String, dynamic>.from(rawInfo),
          ).toDomain();
          identity = _sessionTabIdentityForSession(
            session,
            contextKey: contextKey,
          );
          if (identity != null && !_isEphemeralTitleSession(session)) {
            final existing =
                _sessionTabEventCandidates[identity] ??
                _sessionTabOpenCandidate(identity);
            final title = session.title?.trim() ?? '';
            _sessionTabEventCandidates[identity] = existing == null
                ? SessionTabCandidate(
                    identity: identity,
                    projectId: _sessionTabProjectId(
                      session,
                      contextKey: contextKey,
                    ),
                    title: title,
                    serverUpdatedAtMs: session.time.millisecondsSinceEpoch,
                    isArchived: session.archived,
                    isRoot: session.parentId?.trim().isEmpty ?? true,
                  )
                : existing.copyWith(
                    projectId: _sessionTabProjectId(
                      session,
                      contextKey: contextKey,
                    ),
                    title: title.isEmpty ? existing.title : title,
                    serverUpdatedAtMs: session.time.millisecondsSinceEpoch,
                    isArchived: session.archived,
                    isRoot: session.parentId?.trim().isEmpty ?? true,
                  );
          }
        } catch (error, stackTrace) {
          AppLogger.warn(
            'Failed to parse session tab event type=${event.type}',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    }
    identity ??= _sessionTabIdentityForEventSession(
      sessionId,
      contextKey: contextKey,
    );
    if (identity == null) return;

    final sessionUpdatedAtMs = _sessionTabServerUpdatedAtMs(
      identity,
      contextKey: contextKey,
    );
    final eventToken = _stableEventValueHash(event.properties);
    String? completionToken;
    String? errorToken;
    SessionStatusType? eventStatus;
    if (event.type == 'session.error') {
      errorToken = 'error:$sessionUpdatedAtMs:$eventToken';
      _sessionTabErrorTokens[identity] = errorToken;
    } else if (event.type == 'session.idle') {
      completionToken = 'completion:$sessionUpdatedAtMs:$eventToken';
      _sessionTabCompletionTokens[identity] = completionToken;
      eventStatus = SessionStatusType.idle;
    } else if (event.type == 'session.status') {
      final rawStatus = event.properties['status'];
      if (rawStatus is Map) {
        try {
          eventStatus = SessionStatusModel.fromJson(
            Map<String, dynamic>.from(rawStatus),
          ).toDomain().type;
          if (eventStatus == SessionStatusType.idle) {
            completionToken = 'completion:$sessionUpdatedAtMs:$eventToken';
            _sessionTabCompletionTokens[identity] = completionToken;
          }
        } catch (_) {
          // The event reducer owns malformed status recovery.
        }
      }
    }

    final existingCandidate =
        _sessionTabEventCandidates[identity] ??
        _sessionTabOpenCandidate(identity);
    if (existingCandidate == null) return;
    var nextCandidate = existingCandidate;
    if (event.type == 'session.error') {
      nextCandidate = nextCandidate.copyWith(errorToken: errorToken);
    } else if (event.type == 'session.idle') {
      nextCandidate = nextCandidate.copyWith(
        status: SessionStatusType.idle,
        completionToken: completionToken,
        errorToken: null,
      );
    } else if (event.type == 'session.status' && eventStatus != null) {
      nextCandidate = nextCandidate.copyWith(
        status: eventStatus,
        completionToken: eventStatus == SessionStatusType.idle
            ? completionToken
            : null,
        errorToken:
            eventStatus == SessionStatusType.idle ||
                eventStatus == SessionStatusType.busy ||
                eventStatus == SessionStatusType.retry
            ? null
            : nextCandidate.errorToken,
      );
    } else if (_isSessionTabQuestionOpenEvent(event.type)) {
      final questionId = _sessionTabQuestionIdForEvent(event);
      if (questionId != null) {
        nextCandidate = nextCandidate.copyWith(
          pendingQuestionIds: <String>{
            ...nextCandidate.pendingQuestionIds,
            questionId,
          },
        );
      }
    } else if (_isSessionTabQuestionResolvedEvent(event.type)) {
      final questionId = _sessionTabQuestionIdForEvent(event);
      if (questionId != null) {
        nextCandidate = nextCandidate.copyWith(
          pendingQuestionIds: nextCandidate.pendingQuestionIds.where(
            (candidate) => candidate != questionId,
          ),
        );
      }
    }
    _sessionTabEventCandidates[identity] = nextCandidate;
  }

  SessionTabCandidate? _sessionTabOpenCandidate(SessionTabIdentity identity) {
    final runtime = _sessionTabs
        .where((tab) => tab.identity == identity)
        .firstOrNull;
    if (runtime != null) {
      return SessionTabCandidate(
        identity: identity,
        projectId: runtime.projectId,
        title: runtime.title,
        serverUpdatedAtMs: runtime.serverUpdatedAtMs,
        status: runtime.status,
        isSelected: runtime.isSelected,
        pendingQuestionIds: runtime.pendingQuestionIds,
        completionToken: runtime.completionToken,
        errorToken: runtime.errorToken,
      );
    }
    final persisted = _sessionTabsPersistedState.open
        .where(
          (tab) =>
              normalizeFilePath(tab.directory) == identity.directory &&
              tab.sessionId.trim() == identity.sessionId,
        )
        .firstOrNull;
    if (persisted == null) return null;
    return SessionTabCandidate(
      identity: identity,
      projectId: persisted.projectId,
      title: persisted.title,
      serverUpdatedAtMs: persisted.serverUpdatedAtMs,
    );
  }

  bool _isSessionTabQuestionOpenEvent(String type) {
    return type == 'question.asked' ||
        type == 'question.updated' ||
        type == 'question.v2.asked' ||
        type == 'question.v2.updated';
  }

  bool _isSessionTabQuestionResolvedEvent(String type) {
    return type == 'question.replied' ||
        type == 'question.rejected' ||
        type == 'question.v2.replied' ||
        type == 'question.v2.rejected';
  }

  String? _sessionTabQuestionIdForEvent(ChatEvent event) {
    final payload = _eventPayloadOrNested(event.properties, const <String>[
      'question',
      'request',
      'info',
    ]);
    final rawId = payload['requestID'] ?? payload['id'];
    if (rawId is! String) return null;
    final normalized = rawId.trim();
    return normalized.isEmpty ? null : normalized;
  }

  SessionTabIdentity? _sessionTabIdentityForEventSession(
    String sessionId, {
    required String contextKey,
  }) {
    final sessions = contextKey == _activeContextKey
        ? _sessions
        : _contextSnapshots[contextKey]?.sessions ?? const <ChatSession>[];
    final session = sessions
        .where((candidate) => candidate.id == sessionId)
        .firstOrNull;
    if (session != null) {
      return _sessionTabIdentityForSession(session, contextKey: contextKey);
    }
    final serverId = _serverIdFromContextKey(contextKey);
    final directory = normalizeOptionalFilePath(
      _scopeIdFromContextKey(contextKey),
    );
    if (serverId == null || directory == null) return null;
    final identity = SessionTabIdentity(
      serverId: serverId,
      directory: directory,
      sessionId: sessionId,
    );
    return identity.isValid ? identity : null;
  }

  int _sessionTabServerUpdatedAtMs(
    SessionTabIdentity identity, {
    required String contextKey,
  }) {
    final sessions = contextKey == _activeContextKey
        ? _sessions
        : _contextSnapshots[contextKey]?.sessions ?? const <ChatSession>[];
    final session = sessions
        .where((candidate) => candidate.id == identity.sessionId)
        .firstOrNull;
    if (session != null) return session.time.millisecondsSinceEpoch;
    final eventCandidate = _sessionTabEventCandidates[identity];
    if (eventCandidate != null) return eventCandidate.serverUpdatedAtMs;
    final tab = _sessionTabs
        .where((candidate) => candidate.identity == identity)
        .firstOrNull;
    return tab?.serverUpdatedAtMs ?? 0;
  }

  void _removeSessionTabAuthoritatively(SessionTabIdentity identity) {
    if (!identity.isValid || _sessionTabsLoadedServerId != identity.serverId) {
      return;
    }
    final previous = _sessionTabsPersistedState.encode();
    _sessionTabsPersistedState = PersistedSessionTabsState(
      open: _sessionTabsPersistedState.open
          .where(
            (tab) => !SessionTabReconciler._matchesPersisted(tab, identity),
          )
          .toList(growable: false),
      closed: _sessionTabsPersistedState.closed
          .where((tab) => !SessionTabReconciler._matchesClosed(tab, identity))
          .toList(growable: false),
    );
    final nextTabs = _sessionTabs
        .where((tab) => tab.identity != identity)
        .toList(growable: false);
    final runtimeChanged = nextTabs.length != _sessionTabs.length;
    _sessionTabs = List<SessionTabRecord>.unmodifiable(nextTabs);
    _sessionTabEventCandidates.removeWhere(
      (candidateIdentity, _) => candidateIdentity == identity,
    );
    _sessionTabErrorTokens.removeWhere(
      (candidateIdentity, _) => candidateIdentity == identity,
    );
    _sessionTabCompletionTokens.removeWhere(
      (candidateIdentity, _) => candidateIdentity == identity,
    );
    if (previous != _sessionTabsPersistedState.encode()) {
      _scheduleSessionTabsPersistence();
    }
    if (runtimeChanged) _notifyListeners();
  }

  void _closeSessionTab(SessionTabIdentity identity) {
    final serverId = _activeServerId.trim();
    if (!identity.isValid ||
        identity.serverId != serverId ||
        _sessionTabsLoadedServerId != serverId ||
        !_sessionTabs.any((tab) => tab.identity == identity)) {
      return;
    }
    final nextState = SessionTabReconciler.close(
      state: _sessionTabsPersistedState,
      identity: identity,
      nowMs: _sessionTabsNow().millisecondsSinceEpoch,
    );
    if (nextState.encode() == _sessionTabsPersistedState.encode()) return;
    _sessionTabsPersistedState = nextState;
    if (_sessionTabBootstrapDirectory == identity.directory) {
      _sessionTabBootstrapDirectory = null;
      _sessionTabBootstrapGeneration += 1;
    }
    _reconcileSessionTabs(forcePersistence: true);
  }

  bool _restoreClosedSessionTab(SessionTabRecord tab, {required int index}) {
    final identity = tab.identity;
    final serverId = _activeServerId.trim();
    if (!identity.isValid ||
        identity.serverId != serverId ||
        _sessionTabsLoadedServerId != serverId) {
      return false;
    }
    if (_sessionTabs.any((candidate) => candidate.identity == identity)) {
      return true;
    }
    if (!_sessionTabsPersistedState.closed.any(
      (closed) => SessionTabReconciler._matchesClosed(closed, identity),
    )) {
      return false;
    }
    final candidate = _collectSessionTabCandidates(
      serverId,
    ).where((candidate) => candidate.identity == identity).firstOrNull;
    if (candidate != null && (!candidate.isRoot || candidate.isArchived)) {
      return false;
    }

    final open = _sessionTabsPersistedState.open
        .where(
          (persisted) =>
              !SessionTabReconciler._matchesPersisted(persisted, identity),
        )
        .toList(growable: true);
    final insertionIndex = math.min(math.max(index, 0), open.length);
    open.insert(insertionIndex, tab.toPersisted());
    _sessionTabsPersistedState = PersistedSessionTabsState(
      open: open,
      closed: _sessionTabsPersistedState.closed
          .where(
            (closed) => !SessionTabReconciler._matchesClosed(closed, identity),
          )
          .toList(growable: false),
    );
    _reconcileSessionTabs(explicitlyOpened: identity, forcePersistence: true);
    return _sessionTabs.any((candidate) => candidate.identity == identity);
  }

  Future<void> _removeSessionTabsForProjectHistory({
    required String serverId,
    required String directory,
  }) async {
    final normalizedServerId = serverId.trim();
    final normalizedDirectory = normalizeOptionalFilePath(directory);
    if (normalizedServerId.isEmpty || normalizedDirectory == null) return;

    _removeSessionTabsForDirectory(
      serverId: normalizedServerId,
      directory: normalizedDirectory,
    );
    if (_sessionTabsLoadedServerId == normalizedServerId) {
      final pendingWrite = _sessionTabsWriteQueueByServer[normalizedServerId];
      if (pendingWrite != null) await pendingWrite;
      return;
    }

    try {
      await _enqueueSessionTabsPersistenceOperation<void>(
        serverId: normalizedServerId,
        operation: () async {
          final raw = await localDataSource.getSessionTabsStateJson(
            serverId: normalizedServerId,
          );
          final state = PersistedSessionTabsState.decode(raw);
          final nextState = PersistedSessionTabsState(
            open: state.open
                .where(
                  (tab) =>
                      normalizeFilePath(tab.directory) != normalizedDirectory,
                )
                .toList(growable: false),
            closed: state.closed
                .where(
                  (tab) =>
                      normalizeFilePath(tab.directory) != normalizedDirectory,
                )
                .toList(growable: false),
          );
          final payload = nextState.encode();
          if (payload == state.encode()) return;
          await localDataSource.saveSessionTabsStateJson(
            payload,
            serverId: normalizedServerId,
          );
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to update session tabs for project-history cleanup '
        'server=$normalizedServerId',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    _removeSessionTabsForDirectory(
      serverId: normalizedServerId,
      directory: normalizedDirectory,
    );
    if (_sessionTabsLoadedServerId == normalizedServerId) {
      final activeWrite = _sessionTabsWriteQueueByServer[normalizedServerId];
      if (activeWrite != null) await activeWrite;
    }
  }

  void _removeSessionTabsForDirectory({
    required String serverId,
    required String directory,
  }) {
    final normalizedServerId = serverId.trim();
    final normalizedDirectory = normalizeOptionalFilePath(directory);
    if (normalizedServerId.isEmpty || normalizedDirectory == null) {
      return;
    }
    final previous = _sessionTabsPersistedState.encode();
    if (_sessionTabsLoadedServerId == normalizedServerId) {
      _sessionTabsPersistedState = PersistedSessionTabsState(
        open: _sessionTabsPersistedState.open
            .where(
              (tab) => normalizeFilePath(tab.directory) != normalizedDirectory,
            )
            .toList(growable: false),
        closed: _sessionTabsPersistedState.closed
            .where(
              (tab) => normalizeFilePath(tab.directory) != normalizedDirectory,
            )
            .toList(growable: false),
      );
    }
    final nextTabs = _sessionTabs
        .where(
          (tab) =>
              tab.identity.serverId != normalizedServerId ||
              tab.identity.directory != normalizedDirectory,
        )
        .toList(growable: false);
    final runtimeChanged = nextTabs.length != _sessionTabs.length;
    _sessionTabs = List<SessionTabRecord>.unmodifiable(nextTabs);
    _contextSnapshots.removeWhere(
      (contextKey, _) =>
          _serverIdFromContextKey(contextKey) == normalizedServerId &&
          normalizeOptionalFilePath(_scopeIdFromContextKey(contextKey)) ==
              normalizedDirectory,
    );
    _dirtyContextKeys.removeWhere(
      (contextKey) =>
          _serverIdFromContextKey(contextKey) == normalizedServerId &&
          normalizeOptionalFilePath(_scopeIdFromContextKey(contextKey)) ==
              normalizedDirectory,
    );
    _sessionTabEventCandidates.removeWhere(
      (identity, _) =>
          identity.serverId == normalizedServerId &&
          identity.directory == normalizedDirectory,
    );
    _sessionTabErrorTokens.removeWhere(
      (identity, _) =>
          identity.serverId == normalizedServerId &&
          identity.directory == normalizedDirectory,
    );
    _sessionTabCompletionTokens.removeWhere(
      (identity, _) =>
          identity.serverId == normalizedServerId &&
          identity.directory == normalizedDirectory,
    );
    if (_sessionTabsLoadedServerId == normalizedServerId &&
        previous != _sessionTabsPersistedState.encode()) {
      _scheduleSessionTabsPersistence();
    }
    if (runtimeChanged) _notifyListeners();
  }
}
