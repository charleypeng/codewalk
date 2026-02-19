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

class _RejectedDraftEnvelope {
  const _RejectedDraftEnvelope({required this.sessionId, required this.draft});

  final String sessionId;
  final ChatComposerDraft draft;
}

class _ChatContextSnapshot {
  const _ChatContextSnapshot({
    required this.sessions,
    required this.currentSession,
    required this.messages,
    required this.sessionStatusById,
    required this.pendingPermissionsBySession,
    required this.pendingQuestionsBySession,
    required this.sessionChildrenById,
    required this.sessionTodoById,
    required this.sessionDiffById,
    required this.sessionSearchQuery,
    required this.sessionListFilter,
    required this.sessionListSort,
    required this.sessionVisibleLimit,
  });

  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final List<ChatMessage> messages;
  final Map<String, SessionStatusInfo> sessionStatusById;
  final Map<String, List<ChatPermissionRequest>> pendingPermissionsBySession;
  final Map<String, List<ChatQuestionRequest>> pendingQuestionsBySession;
  final Map<String, List<ChatSession>> sessionChildrenById;
  final Map<String, List<SessionTodo>> sessionTodoById;
  final Map<String, List<SessionDiff>> sessionDiffById;
  final String sessionSearchQuery;
  final SessionListFilter sessionListFilter;
  final SessionListSort sessionListSort;
  final int sessionVisibleLimit;
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
