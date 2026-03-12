part of 'chat_provider.dart';

class ChatUiNotice {
  const ChatUiNotice({
    required this.id,
    required this.type,
    required this.message,
    this.actionLabel,
  });

  final int id;
  final ChatUiNoticeType type;
  final String message;
  final String? actionLabel;

  bool get hasAction => actionLabel != null && actionLabel!.trim().isNotEmpty;
}

enum SessionAttentionKind {
  none,
  active,
  unreadCompletion,
  pendingInteraction,
  error,
}

@immutable
class SessionAttentionState {
  const SessionAttentionState({
    this.isActive = false,
    this.hasPendingInteraction = false,
    this.hasError = false,
    this.hasUnreadCompletion = false,
  });

  final bool isActive;
  final bool hasPendingInteraction;
  final bool hasError;
  final bool hasUnreadCompletion;

  bool get requiresAttention =>
      hasPendingInteraction || hasError || hasUnreadCompletion;

  SessionAttentionKind get primaryKind {
    if (hasError) {
      return SessionAttentionKind.error;
    }
    if (hasPendingInteraction) {
      return SessionAttentionKind.pendingInteraction;
    }
    if (hasUnreadCompletion) {
      return SessionAttentionKind.unreadCompletion;
    }
    if (isActive) {
      return SessionAttentionKind.active;
    }
    return SessionAttentionKind.none;
  }
}

class _RejectedDraftEnvelope {
  const _RejectedDraftEnvelope({required this.sessionId, required this.draft});

  final String sessionId;
  final ChatComposerDraft draft;
}

class _HistoryComposerSync {
  const _HistoryComposerSync({
    required this.token,
    required this.sessionId,
    this.draft,
    this.clear = false,
  });

  final int token;
  final String sessionId;
  final ChatComposerDraft? draft;
  final bool clear;
}

class _PendingReplacementBranch {
  const _PendingReplacementBranch({
    required this.sessionId,
    required this.revertMessageId,
    this.replacementRootMessageId,
  });

  final String sessionId;
  final String revertMessageId;
  final String? replacementRootMessageId;

  String get cacheKey =>
      '$sessionId::$revertMessageId::${replacementRootMessageId ?? ''}';

  _PendingReplacementBranch copyWith({String? replacementRootMessageId}) {
    return _PendingReplacementBranch(
      sessionId: sessionId,
      revertMessageId: revertMessageId,
      replacementRootMessageId:
          replacementRootMessageId ?? this.replacementRootMessageId,
    );
  }
}

class _ChatContextSnapshot {
  const _ChatContextSnapshot({
    required this.sessions,
    required this.currentSession,
    required this.messages,
    required this.sessionStatusById,
    required this.pendingPermissionsBySession,
    required this.pendingQuestionsBySession,
    required this.sessionUnreadCompletionIds,
    required this.sessionErrorAttentionIds,
    required this.sessionChildrenById,
    required this.sessionTodoById,
    required this.sessionDiffById,
    required this.sessionSearchQuery,
    required this.sessionListFilter,
    required this.sessionListSort,
    required this.pinnedSessionIds,
    required this.sessionVisibleLimit,
    required this.isNewChatDraftActive,
    required this.activeSendDraft,
    required this.rejectedDraft,
  });

  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final List<ChatMessage> messages;
  final Map<String, SessionStatusInfo> sessionStatusById;
  final Map<String, List<ChatPermissionRequest>> pendingPermissionsBySession;
  final Map<String, List<ChatQuestionRequest>> pendingQuestionsBySession;
  final Set<String> sessionUnreadCompletionIds;
  final Set<String> sessionErrorAttentionIds;
  final Map<String, List<ChatSession>> sessionChildrenById;
  final Map<String, List<SessionTodo>> sessionTodoById;
  final Map<String, List<SessionDiff>> sessionDiffById;
  final String sessionSearchQuery;
  final SessionListFilter sessionListFilter;
  final SessionListSort sessionListSort;
  final Set<String> pinnedSessionIds;
  final int sessionVisibleLimit;
  final bool isNewChatDraftActive;
  final ChatComposerDraft? activeSendDraft;
  final _RejectedDraftEnvelope? rejectedDraft;
}

class _AutoTitleCandidateMessage {
  const _AutoTitleCandidateMessage({
    required this.id,
    required this.role,
    required this.text,
  });

  final String id;
  final MessageRole role;
  final String text;
}

class _AutoTitleSnapshot {
  const _AutoTitleSnapshot({
    required this.messages,
    required this.signature,
    required this.userCount,
    required this.assistantCount,
  });

  final List<_AutoTitleCandidateMessage> messages;
  final String signature;
  final int userCount;
  final int assistantCount;

  bool get isConsolidated => userCount >= 3 && assistantCount >= 3;
}

class _RemoteChatSelection {
  const _RemoteChatSelection({
    this.providerId,
    this.modelId,
    this.agentName,
    this.variantByAgentAndModel = const <String, Map<String, String>>{},
    this.sessionOverridesBySessionId =
        const <String, _SessionSelectionOverride>{},
  });

  final String? providerId;
  final String? modelId;
  final String? agentName;
  final Map<String, Map<String, String>> variantByAgentAndModel;
  final Map<String, _SessionSelectionOverride> sessionOverridesBySessionId;

  bool get hasModel =>
      providerId != null &&
      providerId!.trim().isNotEmpty &&
      modelId != null &&
      modelId!.trim().isNotEmpty;

  String? variantForModel({
    required String agentName,
    required String modelKey,
  }) {
    final byModel = variantByAgentAndModel[agentName];
    if (byModel == null) {
      return null;
    }
    return byModel[modelKey];
  }
}

class _ProviderCatalogSnapshot {
  const _ProviderCatalogSnapshot({
    required this.providers,
    required this.defaultModels,
    required this.connected,
  });

  final List<Provider> providers;
  final Map<String, String> defaultModels;
  final List<String> connected;

  bool get isEmpty => providers.isEmpty;
}

class _SessionSelectionOverride {
  const _SessionSelectionOverride({
    required this.providerId,
    required this.modelId,
    required this.agentName,
    required this.variantId,
    required this.updatedAtEpochMs,
  });

  final String providerId;
  final String modelId;
  final String agentName;
  final String? variantId;
  final int updatedAtEpochMs;
}

enum _ShortcutCycleDomain { model, agent, variant }

class _ShortcutCycleState {
  const _ShortcutCycleState({
    required this.snapshot,
    required this.currentIndex,
    required this.lastActivatedAt,
    required this.reverse,
  });

  final List<String> snapshot;
  final int currentIndex;
  final DateTime lastActivatedAt;
  final bool reverse;
}
