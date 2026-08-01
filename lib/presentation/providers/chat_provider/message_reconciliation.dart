import '../../../domain/entities/chat_message.dart';

/// Where a message-collection update came from.
///
/// The flicker in #111 came from any of these paths being able to overwrite the
/// visible collection wholesale, so provenance has to travel with the update in
/// order to be judged.
enum MessageUpdateOrigin {
  realtimeEvent,
  httpFallback,
  sessionRefresh,
  cacheHydration,
  localMutation,
  sessionSwitch,
}

/// What the payload claims to be.
///
/// A payload that only carries part of the conversation must never be applied
/// as if it described the whole of it.
enum MessageUpdateKind {
  /// Claims to describe the session's full collection.
  fullSnapshot,

  /// Carries a subset; absent messages say nothing about their existence.
  partialDelta,

  /// The server explicitly said these messages are gone.
  authoritativeRemoval,

  /// Session switch, sign-out, cache eviction: emptying is intended.
  reset,
}

/// Outcome of judging one update.
enum MessageUpdateDecision {
  /// The payload was taken as-is.
  applied,

  /// The payload would have dropped newer messages, so they were kept.
  mergedNonRegressive,
}

/// Result of judging a candidate message collection.
class MessageReconciliation {
  const MessageReconciliation({
    required this.messages,
    required this.decision,
    required this.reason,
    this.preservedIds = const <String>[],
  });

  final List<ChatMessage> messages;
  final MessageUpdateDecision decision;
  final String reason;

  /// Messages the payload omitted but that were newer than anything it carried.
  final List<String> preservedIds;
}

/// Decides what the visible message collection should become.
///
/// Issue #111 had been patched twice (#76, #48) at individual call sites and
/// came back both times, because roughly twenty places replace the collection
/// outright. This is the single rule they all go through: an update may never
/// remove a message newer than everything the update itself carries, unless it
/// is an explicit removal or a reset.
///
/// Pure on purpose, so the invariant can be tested against fabricated event
/// orderings without standing up a provider.
MessageReconciliation reconcileMessages({
  required List<ChatMessage> previous,
  required List<ChatMessage> next,
  required MessageUpdateKind kind,
  String? sessionId,
}) {
  // Resets and explicit removals are authoritative by definition.
  if (kind == MessageUpdateKind.reset ||
      kind == MessageUpdateKind.authoritativeRemoval) {
    return MessageReconciliation(
      messages: List<ChatMessage>.from(next),
      decision: MessageUpdateDecision.applied,
      reason: 'authoritative',
    );
  }

  final scopedPrevious = sessionId == null
      ? previous
      : previous
            .where((message) => message.sessionId == sessionId)
            .toList(growable: false);

  final nextIds = next.map((message) => message.id).toSet();
  final dropped = scopedPrevious
      .where((message) => !nextIds.contains(message.id))
      .toList(growable: false);

  if (dropped.isEmpty) {
    return MessageReconciliation(
      messages: List<ChatMessage>.from(next),
      decision: MessageUpdateDecision.applied,
      reason: 'no-drop',
    );
  }

  // The payload drops messages. That is only legitimate when none of them is
  // newer than what the payload itself knows about; otherwise it is stale or
  // partial and is describing an older world than the one already on screen.
  final newestInNext = _newestTime(next);
  final regressive = dropped
      .where(
        (message) =>
            newestInNext == null || !message.time.isBefore(newestInNext),
      )
      .toList(growable: false);

  if (regressive.isEmpty) {
    return MessageReconciliation(
      messages: List<ChatMessage>.from(next),
      decision: MessageUpdateDecision.applied,
      reason: 'drop-older-only',
    );
  }

  // Keep the newer tail the payload failed to mention, in timeline order.
  final preserved = <ChatMessage>[...next, ...regressive]
    ..sort((a, b) => a.time.compareTo(b.time));

  return MessageReconciliation(
    messages: preserved,
    decision: MessageUpdateDecision.mergedNonRegressive,
    reason: 'stale-or-partial-payload',
    preservedIds: regressive
        .map((message) => message.id)
        .toList(growable: false),
  );
}

DateTime? _newestTime(List<ChatMessage> messages) {
  DateTime? newest;
  for (final message in messages) {
    if (newest == null || message.time.isAfter(newest)) {
      newest = message.time;
    }
  }
  return newest;
}
