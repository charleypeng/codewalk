class ChatServerErrorDisplay {
  const ChatServerErrorDisplay({required this.name, required this.message});

  final String name;
  final String message;
}

bool isServerConnectionFailure({
  String? rawMessage,
  String? code,
  int? statusCode,
}) {
  final normalizedMessage = _sanitizeMessage(rawMessage);
  final normalizedCode = code?.trim().toLowerCase() ?? '';
  final combined = '$normalizedCode $normalizedMessage'.toLowerCase();

  return statusCode == 408 ||
      combined.contains('network connection failed') ||
      combined.contains('network connection error') ||
      combined.contains('connection timeout') ||
      combined.contains('connection refused') ||
      combined.contains('connection reset') ||
      combined.contains('failed host lookup') ||
      combined.contains('socketexception') ||
      combined.contains('network is unreachable') ||
      combined.contains('unable to connect') ||
      combined.contains('timed out');
}

bool isServerUnavailableFailure({
  String? rawMessage,
  String? code,
  int? statusCode,
}) {
  final normalizedMessage = _sanitizeMessage(rawMessage);
  final normalizedCode = code?.trim().toLowerCase() ?? '';
  final combined = '$normalizedCode $normalizedMessage'.toLowerCase();

  return (statusCode != null && statusCode >= 500) ||
      combined.contains('service unavailable') ||
      combined.contains('provider unavailable') ||
      combined.contains('temporarily unavailable') ||
      combined.contains('gateway timeout');
}

ChatServerErrorDisplay formatServerErrorForDisplay({
  String? rawMessage,
  String? code,
  int? statusCode,
}) {
  final normalizedMessage = _sanitizeMessage(rawMessage);
  final normalizedCode = code?.trim().toLowerCase() ?? '';
  final combined = '$normalizedCode $normalizedMessage'.toLowerCase();

  if (isServerConnectionFailure(
    rawMessage: rawMessage,
    code: code,
    statusCode: statusCode,
  )) {
    return const ChatServerErrorDisplay(
      name: 'Connection failed',
      message:
          'Unable to reach the server. Check connection and server status.',
    );
  }

  final hasQuotaSignal =
      combined.contains('insufficient_quota') ||
      combined.contains('usage_not_included') ||
      combined.contains('quota') ||
      combined.contains('billing') ||
      combined.contains('credit');
  if (hasQuotaSignal) {
    return const ChatServerErrorDisplay(
      name: 'Quota exceeded',
      message: 'Quota exceeded. Check your provider plan or billing.',
    );
  }

  final hasRateLimitSignal =
      statusCode == 429 ||
      combined.contains('rate limit') ||
      combined.contains('too many requests') ||
      combined.contains('status: 429') ||
      combined.contains('status code 429') ||
      combined.contains('429');
  if (hasRateLimitSignal) {
    return const ChatServerErrorDisplay(
      name: 'Rate limit exceeded',
      message: 'Rate limit exceeded. Wait a moment and try again.',
    );
  }

  final hasAuthSignal =
      statusCode == 401 ||
      statusCode == 403 ||
      combined.contains('unauthorized') ||
      combined.contains('forbidden') ||
      combined.contains('authentication') ||
      combined.contains('invalid api key') ||
      combined.contains('token refresh failed');
  if (hasAuthSignal) {
    return const ChatServerErrorDisplay(
      name: 'Authentication required',
      message: 'Authentication failed. Reconnect the provider and try again.',
    );
  }

  if (isServerUnavailableFailure(
    rawMessage: rawMessage,
    code: code,
    statusCode: statusCode,
  )) {
    return const ChatServerErrorDisplay(
      name: 'Provider unavailable',
      message: 'Provider temporarily unavailable. Try again shortly.',
    );
  }

  if (normalizedMessage.isNotEmpty) {
    return ChatServerErrorDisplay(
      name: 'Server error',
      message: normalizedMessage,
    );
  }

  return const ChatServerErrorDisplay(
    name: 'Server error',
    message: 'Server error. Please try again.',
  );
}

String _sanitizeMessage(String? input) {
  if (input == null) {
    return '';
  }
  var sanitized = input.trim();
  if (sanitized.isEmpty) {
    return '';
  }
  if (sanitized.startsWith('Exception:')) {
    sanitized = sanitized.substring('Exception:'.length).trim();
  }
  if (sanitized.startsWith('Error:')) {
    sanitized = sanitized.substring('Error:'.length).trim();
  }
  sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
  if (sanitized.length > 160) {
    sanitized = '${sanitized.substring(0, 157)}...';
  }
  return sanitized;
}
