part of '../chat_provider.dart';

extension _ChatProviderAbortPolicyOps on ChatProvider {
  void _queueUiNotice({
    required ChatUiNoticeType type,
    required String message,
    String? actionLabel,
  }) {
    _nextUiNoticeId += 1;
    _pendingUiNotice = ChatUiNotice(
      id: _nextUiNoticeId,
      type: type,
      message: message,
      actionLabel: actionLabel,
    );
  }

  bool _isAbortLikeMessage(String message) {
    final normalized = message.trim().toLowerCase();
    return normalized.contains('aborted') ||
        normalized.contains('abort') ||
        normalized.contains('retry') ||
        normalized.contains('cancelled') ||
        normalized.contains('canceled') ||
        normalized.contains('cancelled by user') ||
        normalized.contains('canceled by user');
  }

  void _startAbortSuppression(String sessionId) {
    _abortSuppressionSessionId = sessionId;
    _abortSuppressionStartedAt = DateTime.now();
  }

  void _clearAbortSuppression() {
    _abortSuppressionSessionId = null;
    _abortSuppressionStartedAt = null;
  }
}
