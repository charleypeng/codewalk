String? parseReasoningStatusLabel(String text) {
  final normalized = text.trimLeft();
  if (normalized.isEmpty) {
    return null;
  }

  final firstLine = normalized.split('\n').first.trim();
  final match = RegExp(r'^\*\*(.+?)\*\*$').firstMatch(firstLine);
  if (match == null) {
    return null;
  }

  final label = match.group(1)?.trim();
  if (label == null || label.isEmpty) {
    return null;
  }
  return label;
}
