import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';

class ChatTitleGeneratorMessage {
  const ChatTitleGeneratorMessage({required this.role, required this.text});

  final String role;
  final String text;
}

abstract class ChatTitleGenerator {
  /// Session IDs of ephemeral title-generation sessions.
  /// Event handlers should ignore events from these sessions.
  static final Set<String> ephemeralSessionIds = <String>{};

  /// Title used for ephemeral title-generation sessions.
  /// Used as fallback filter when session ID is not yet known.
  static const String ephemeralSessionTitle = '_title_gen';

  Future<String?> generateTitle(
    List<ChatTitleGeneratorMessage> messages, {
    int maxWords,
  });
}

class OpenCodeTitleGenerator implements ChatTitleGenerator {
  OpenCodeTitleGenerator({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const int _maxTitleLength = 80;
  static const int _defaultMaxWords = 6;
  static const Duration _pollInterval = Duration(milliseconds: 500);
  static const int _maxPollAttempts = 30; // 15s max wait

  @override
  Future<String?> generateTitle(
    List<ChatTitleGeneratorMessage> messages, {
    int maxWords = _defaultMaxWords,
  }) async {
    if (messages.isEmpty) return null;

    String? sessionId;
    try {
      // 1. Create ephemeral session
      final createResp = await _dio.post<dynamic>(
        '/session',
        data: <String, dynamic>{'title': '_title_gen'},
      );
      sessionId =
          (createResp.data as Map<String, dynamic>)['id'] as String?;
      if (sessionId == null) return null;
      ChatTitleGenerator.ephemeralSessionIds.add(sessionId);

      // 2. Send prompt with agent: "title" (no model → server uses agent default)
      final effectiveMaxWords = maxWords.clamp(1, 12).toInt();
      final prompt = _buildPrompt(messages, maxWords: effectiveMaxWords);
      await _dio.post<dynamic>(
        '/session/$sessionId/message',
        data: <String, dynamic>{
          'agent': 'title',
          'parts': <Map<String, String>>[
            <String, String>{'type': 'text', 'text': prompt},
          ],
          'noReply': false,
        },
      );

      // 3. Poll for completed assistant message
      for (var i = 0; i < _maxPollAttempts; i++) {
        await Future<void>.delayed(_pollInterval);
        final msgResp = await _dio.get<dynamic>(
          '/session/$sessionId/message',
        );
        final list = msgResp.data as List<dynamic>? ?? <dynamic>[];
        final title = _extractAssistantTitle(list);
        if (title != null) return _normalizeTitle(title);
      }
      return null;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Native title generation failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      if (sessionId != null) {
        try {
          await _dio.delete<dynamic>('/session/$sessionId');
        } catch (_) {}
        // Keep ID in filter set briefly so trailing SSE events
        // (session.idle, session.deleted) are still filtered out.
        final id = sessionId;
        Future<void>.delayed(const Duration(seconds: 5), () {
          ChatTitleGenerator.ephemeralSessionIds.remove(id);
        });
      }
    }
  }

  String _buildPrompt(
    List<ChatTitleGeneratorMessage> messages, {
    required int maxWords,
  }) {
    final lines = StringBuffer();
    for (var index = 0; index < messages.length; index += 1) {
      final message = messages[index];
      lines.writeln(
        '${index + 1}. ${message.role.toUpperCase()}: ${message.text}',
      );
    }

    return [
      'Based on the texts below, generate a title for this conversation with at most $_maxTitleLength characters.',
      'Use at most $maxWords words.',
      'Use plain text only, no quotes, no markdown.',
      lines.toString().trimRight(),
    ].join('\n\n');
  }

  /// Extracts assistant title from message list.
  ///
  /// The API returns messages in envelope format:
  /// `[{ "info": { "role": "assistant", "time": { "completed": ms } }, "parts": [...] }]`
  String? _extractAssistantTitle(List<dynamic> messages) {
    for (final raw in messages.reversed) {
      if (raw is! Map<String, dynamic>) continue;

      // Envelope format: { info: {...}, parts: [...] }
      final info = raw['info'] as Map<String, dynamic>?;
      final role = info?['role'] as String? ?? raw['role'] as String?;
      if (role != 'assistant') continue;

      // Check completion: info.time.completed or legacy completedTime
      final time = info?['time'];
      final bool isCompleted;
      if (time is Map<String, dynamic>) {
        isCompleted = time['completed'] != null;
      } else {
        isCompleted = raw['completedTime'] != null;
      }
      if (!isCompleted) continue;

      // Parts can be at top level or inside envelope
      final parts = raw['parts'];
      if (parts is! List) continue;
      final textParts = <String>[];
      for (final part in parts) {
        if (part is! Map<String, dynamic>) continue;
        if (part['type'] != 'text') continue;
        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) {
          textParts.add(text.trim());
        }
      }
      if (textParts.isNotEmpty) {
        return textParts.join(' ');
      }
    }
    return null;
  }

  String? _normalizeTitle(String raw) {
    var normalized = raw.trim();
    if (normalized.length >= 2 &&
        normalized.startsWith('"') &&
        normalized.endsWith('"')) {
      normalized = normalized.substring(1, normalized.length - 1).trim();
    }
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return null;
    if (normalized.length > _maxTitleLength) {
      normalized = normalized.substring(0, _maxTitleLength).trimRight();
    }
    return normalized;
  }
}
