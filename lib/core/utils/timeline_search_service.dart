import '../../domain/entities/chat_message.dart';

/// A single search match within a message.
class TimelineSearchMatch {
  const TimelineSearchMatch({
    required this.messageId,
    required this.matchCount,
  });

  /// The ID of the message containing the match.
  final String messageId;

  /// Number of individual text occurrences within this message.
  final int matchCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineSearchMatch &&
          messageId == other.messageId &&
          matchCount == other.matchCount;

  @override
  int get hashCode => Object.hash(messageId, matchCount);
}

/// Result of a timeline search operation.
class TimelineSearchResult {
  const TimelineSearchResult({
    required this.query,
    required this.matches,
    required this.totalMatchCount,
  });

  /// The original search query (lowercased).
  final String query;

  /// Ordered list of messages that contain matches, oldest first.
  final List<TimelineSearchMatch> matches;

  /// Total number of individual text occurrences across all matched messages.
  final int totalMatchCount;

  /// Whether there are any matches.
  bool get isEmpty => matches.isEmpty;

  /// Whether there are matches.
  bool get isNotEmpty => matches.isNotEmpty;

  static final TimelineSearchResult empty = const TimelineSearchResult(
    query: '',
    matches: [],
    totalMatchCount: 0,
  );
}

/// Extracts searchable text from [ChatMessage] parts and performs
/// case-insensitive full-text search across a list of messages.
///
/// Searchable content includes [TextPart.text] and [ReasoningPart.text],
/// matching the message surfaces that support inline search highlighting.
class TimelineSearchService {
  const TimelineSearchService();

  /// Extracts all searchable text from a single [message], concatenated with
  /// newline separators between parts.
  String extractSearchableText(ChatMessage message) {
    final buffer = StringBuffer();
    for (final part in message.parts) {
      if (part is TextPart) {
        buffer.writeln(part.text);
      } else if (part is ReasoningPart) {
        buffer.writeln(part.text);
      }
    }
    return buffer.toString().trimRight();
  }

  /// Counts the number of case-insensitive occurrences of [query] in [text].
  int _countOccurrences(String text, String query) {
    if (query.isEmpty) return 0;
    var count = 0;
    var startIndex = 0;
    while (true) {
      final index = text.indexOf(query, startIndex);
      if (index == -1) break;
      count++;
      startIndex = index + query.length;
    }
    return count;
  }

  /// Searches [messages] for [query] (case-insensitive) and returns a
  /// [TimelineSearchResult] with matched message IDs and occurrence counts.
  ///
  /// Returns [TimelineSearchResult.empty] if [query] is empty or null.
  TimelineSearchResult search({
    required List<ChatMessage> messages,
    required String? query,
  }) {
    if (query == null || query.trim().isEmpty) {
      return TimelineSearchResult.empty;
    }
    final normalizedQuery = query.trim().toLowerCase();
    final matches = <TimelineSearchMatch>[];
    var totalMatchCount = 0;

    for (final message in messages) {
      final text = extractSearchableText(message).toLowerCase();
      final count = _countOccurrences(text, normalizedQuery);
      if (count > 0) {
        matches.add(
          TimelineSearchMatch(messageId: message.id, matchCount: count),
        );
        totalMatchCount += count;
      }
    }

    return TimelineSearchResult(
      query: normalizedQuery,
      matches: List.unmodifiable(matches),
      totalMatchCount: totalMatchCount,
    );
  }
}
