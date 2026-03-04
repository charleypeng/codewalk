const String kChatAbortNoticeMessage = 'What you want to do different?';

bool isAbortLikeError({String? name, required String message}) {
  final normalizedName = name?.trim().toLowerCase() ?? '';
  final normalizedMessage = message.trim().toLowerCase();

  if (normalizedName.contains('abort') || normalizedName.contains('cancel')) {
    return true;
  }

  return normalizedMessage.contains('aborted') ||
      normalizedMessage.contains('abort') ||
      normalizedMessage.contains('cancelled') ||
      normalizedMessage.contains('canceled') ||
      normalizedMessage.contains('cancelled by user') ||
      normalizedMessage.contains('canceled by user');
}

String normalizeAbortMessageForDisplay(String message, {String? name}) {
  if (isAbortLikeError(name: name, message: message)) {
    return kChatAbortNoticeMessage;
  }
  return message;
}
