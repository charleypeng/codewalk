String? parseReasoningStatusLabel(String text) {
  final label = _extractReasoningStatusLabel(text);
  if (label == null || !_isHumanReadableReasoningStatusLabel(label)) {
    return null;
  }
  return label;
}

bool isReasoningStatusMarker(String text) {
  return _extractReasoningStatusLabel(text) != null;
}

String? _extractReasoningStatusLabel(String text) {
  final normalized = text.trimLeft();
  if (normalized.isEmpty) {
    return null;
  }

  final firstLine = normalized.split('\n').first.trim();
  final match = RegExp(r'^\*\*(.*?)\*\*$').firstMatch(firstLine);
  if (match == null) {
    return null;
  }

  final label = match.group(1)?.trim();
  return label ?? '';
}

bool _isHumanReadableReasoningStatusLabel(String label) {
  if (label.isEmpty || label.runes.length > 64) {
    return false;
  }
  if (RegExp(r'[\[\]{}*+?\\^$|<>]').hasMatch(label)) {
    return false;
  }

  final firstRune = label.runes.first;
  final startsWithAsciiLetterOrDigit =
      (firstRune >= 0x30 && firstRune <= 0x39) ||
      (firstRune >= 0x41 && firstRune <= 0x5A) ||
      (firstRune >= 0x61 && firstRune <= 0x7A);
  if (!startsWithAsciiLetterOrDigit && firstRune <= 0x7F) {
    return false;
  }

  var likelyLetterCount = 0;
  for (final rune in label.runes) {
    final isAsciiLetter =
        (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
    if (isAsciiLetter || rune > 0x7F) {
      likelyLetterCount += 1;
      if (likelyLetterCount >= 2) {
        return true;
      }
    }
  }
  return false;
}
