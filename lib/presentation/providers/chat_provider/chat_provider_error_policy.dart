part of '../chat_provider.dart';

extension _ChatProviderErrorPolicy on ChatProvider {
  void _setState(ChatState newState) {
    _state = newState;
    _notifyListeners();
    _attemptPendingRemoteSelectionSync(reason: 'state-$newState');
  }

  void _setProvidersRefreshState(
    ChatProvidersRefreshState state, {
    String? errorMessage,
    bool notify = true,
  }) {
    final changed =
        _providersRefreshState != state ||
        _providersRefreshErrorMessage != errorMessage;
    _providersRefreshState = state;
    _providersRefreshErrorMessage = errorMessage;
    if (changed && notify) {
      _notifyListeners();
    }
  }

  void _setError(String message, {String? sessionId}) {
    final effectiveSessionId = sessionId ?? _currentSession?.id;
    if (_shouldSuppressAbortError(
      sessionId: effectiveSessionId,
      message: message,
    )) {
      AppLogger.info(
        'Suppressing expected abort error session=${effectiveSessionId ?? "-"} message=$message',
      );
      _errorMessage = null;
      _setState(ChatState.loaded);
      return;
    }
    _errorMessage = message;
    _setState(ChatState.error);
  }

  bool _isAbortSuppressionActiveForSession(String? sessionId) {
    if (sessionId == null ||
        _abortSuppressionSessionId == null ||
        _abortSuppressionStartedAt == null ||
        sessionId != _abortSuppressionSessionId) {
      return false;
    }
    final startedAt = _abortSuppressionStartedAt!;
    if (DateTime.now().difference(startedAt) >
        ChatProvider._abortSuppressionWindow) {
      _clearAbortSuppression();
      return false;
    }
    return true;
  }

  bool _isRemoteAbortError({required String message, String? code}) {
    final normalizedMessage = message.trim().toLowerCase();
    final normalizedCode = code?.trim().toLowerCase() ?? '';
    if (normalizedCode.contains('abort') || normalizedCode.contains('cancel')) {
      return true;
    }
    return normalizedMessage.contains('aborted') ||
        normalizedMessage.contains('abort') ||
        normalizedMessage.contains('cancelled') ||
        normalizedMessage.contains('canceled');
  }

  bool _shouldSuppressAbortError({
    required String? sessionId,
    required String message,
  }) {
    if (!_isAbortSuppressionActiveForSession(sessionId)) {
      return false;
    }
    return _isAbortLikeMessage(message);
  }
}
