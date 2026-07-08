import '../../../domain/entities/chat_message.dart';

class ReadAloudTextExtractor {
  const ReadAloudTextExtractor._();

  static String extract(AssistantMessage message) {
    final buffer = StringBuffer();
    for (final part in message.parts) {
      if (part is TextPart && part.text.trim().isNotEmpty) {
        final cleaned = cleanMarkdown(part.text);
        if (cleaned.isNotEmpty) {
          buffer.write(cleaned);
          buffer.write(' ');
        }
      }
    }
    return _normalizeWhitespace(buffer.toString());
  }

  static String cleanMarkdown(String input) {
    var text = input;
    text = text.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), ' ');
    text = text.replaceAllMapped(RegExp('`([^`]*)`'), (match) {
      final value = match.group(1)?.trim() ?? '';
      return value.length <= 80 ? value : ' ';
    });
    text = text.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
      (match) => match.group(1)?.trim() ?? ' ',
    );
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]*\)'),
      (match) => match.group(1)?.trim() ?? ' ',
    );
    text = text.replaceAllMapped(
      RegExp(r'(\*\*|__)(.*?)\1'),
      (match) => match.group(2) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'(\*|_)(.*?)\1'),
      (match) => match.group(2) ?? '',
    );
    text = text.replaceAll(RegExp('<[^>]+>'), ' ');

    final lines = <String>[];
    for (final rawLine in text.split('\n')) {
      var line = rawLine;
      if (_looksLikeMarkdownTableLine(line)) {
        continue;
      }
      line = line.replaceFirst(RegExp(r'^\s{0,3}#{1,6}\s*'), '');
      line = line.replaceFirst(RegExp(r'^\s{0,3}>\s?'), '');
      line = line.replaceFirst(RegExp(r'^\s*[-*+]\s+'), '');
      line = line.replaceFirst(RegExp(r'^\s*\d+[.)]\s+'), '');
      lines.add(line);
    }

    return _normalizeWhitespace(lines.join(' '));
  }

  static bool _looksLikeMarkdownTableLine(String line) {
    final pipeCount = '|'.allMatches(line).length;
    if (pipeCount < 2) {
      return false;
    }
    final trimmed = line.trim();
    return trimmed.startsWith('|') || trimmed.contains(RegExp(r'\s\|\s'));
  }

  static String _normalizeWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
