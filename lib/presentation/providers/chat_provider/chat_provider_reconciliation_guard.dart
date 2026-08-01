part of '../chat_provider.dart';

/// Funnels every write to the visible message collection through the
/// non-regressive rule in [reconcileMessages], and records the decision.
extension _ChatProviderReconciliationGuard on ChatProvider {
  /// Applies [next] to [_messages] unless doing so would regress the timeline.
  ///
  /// Returns true when the visible collection actually changed.
  bool _applyMessages(
    List<ChatMessage> next, {
    required MessageUpdateOrigin origin,
    required MessageUpdateKind kind,
    String? sessionId,
    String? reason,
  }) {
    final previous = _messages;
    final outcome = reconcileMessages(
      previous: previous,
      next: next,
      kind: kind,
      sessionId: sessionId,
    );

    if (outcome.decision == MessageUpdateDecision.mergedNonRegressive) {
      // A regression was actually blocked, which means some path is still
      // emitting stale or partial payloads as if they were complete. Worth a
      // warning even in normal operation.
      AppLogger.warn(
        'reconciliation blocked regression '
        'origin=${origin.name} kind=${kind.name} '
        'reason=${reason ?? outcome.reason} session=${sessionId ?? '-'} '
        'before=${previous.length} after=${outcome.messages.length} '
        'preserved=${outcome.preservedIds.join(',')}',
      );
    }

    // Suppress no-op writes: rebuilding with identical content still moves the
    // reading anchor on some layouts, which #111 lists as unacceptable.
    if (_areMessageListsSemanticallyEqual(previous, outcome.messages)) {
      _logReconciliation(
        origin: origin,
        kind: kind,
        outcome: 'no-change',
        sessionId: sessionId,
        previousCount: previous.length,
        nextCount: outcome.messages.length,
        reason: reason ?? outcome.reason,
      );
      return false;
    }

    _messages = outcome.messages;
    _logReconciliation(
      origin: origin,
      kind: kind,
      outcome: outcome.decision.name,
      sessionId: sessionId,
      previousCount: previous.length,
      nextCount: outcome.messages.length,
      reason: reason ?? outcome.reason,
    );
    return true;
  }

  /// Diagnostic trail for reconciliation decisions.
  ///
  /// Kept permanently but silent by default: this bug regressed twice, and
  /// without provenance the next recurrence starts from zero again. Message
  /// content is never recorded, only identifiers and counts.
  void _logReconciliation({
    required MessageUpdateOrigin origin,
    required MessageUpdateKind kind,
    required String outcome,
    required int previousCount,
    required int nextCount,
    required String reason,
    String? sessionId,
  }) {
    AppLogger.debug(
      'reconciliation $outcome '
      'origin=${origin.name} kind=${kind.name} reason=$reason '
      'session=${sessionId ?? '-'} before=$previousCount after=$nextCount',
    );
  }
}
