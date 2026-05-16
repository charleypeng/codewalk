import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_part.dart';

/// Determines whether a list of messages for a given session has a settled,
/// revealable completed assistant response — meaning the assistant has produced
/// final text/reasoning content, not just tool-only work parts.
///
/// Used by the provider to distinguish between:
/// - A legitimate tool-only busy tail (multi-step tool chain, keep Stop visible)
/// - A completed final response that happens to also contain ToolPart/PatchPart
///   alongside revealable text/reasoning content (session settled, hide Stop)
bool hasCompletedRevealableAssistantMessage(
  List<ChatMessage> messages,
  String sessionId,
) {
  for (var i = messages.length - 1; i >= 0; i--) {
    final message = messages[i];
    if (message.sessionId != sessionId) continue;
    if (message is! AssistantMessage) continue;
    if (!message.isCompleted) return false;
    return _hasRevealableContent(message);
  }
  return false;
}

/// Returns true if the given assistant message has revealable content
/// (text, reasoning, etc.) beyond just tool/patch work parts.
bool _hasRevealableContent(AssistantMessage message) {
  return message.parts.any((part) => part is! ToolPart && part is! PatchPart);
}

/// Returns true if the given assistant message is a tool-only work step
/// (all parts are ToolPart or PatchPart, no revealable content).
bool isToolOnlyAssistantMessage(AssistantMessage message) {
  return message.parts.every((part) => part is ToolPart || part is PatchPart);
}
