part of 'chat_input_widget.dart';

class _SpeechServiceResolution {
  const _SpeechServiceResolution({
    required this.service,
    required this.engine,
    required this.usedFallback,
    this.unavailableReason,
  });

  final SpeechInputService service;
  final SpeechToTextEngine engine;
  final bool usedFallback;
  final String? unavailableReason;
}

class ChatQuickReplyAgentOption {
  const ChatQuickReplyAgentOption({required this.name, required this.label});

  final String name;
  final String label;
}

class ChatQuickReplyThinkingOption {
  const ChatQuickReplyThinkingOption({required this.id, required this.label});

  final String id;
  final String label;
}

class ChatQuickReplySelectionOverride {
  const ChatQuickReplySelectionOverride({
    required this.agentName,
    required this.thinkingMode,
    required this.thinkingVariantId,
  });

  final String? agentName;
  final CannedAnswerThinkingMode thinkingMode;
  final String? thinkingVariantId;

  bool get hasExplicitOverride =>
      (agentName?.trim().isNotEmpty ?? false) ||
      thinkingMode != CannedAnswerThinkingMode.inherit;
}

class ChatQuickReplySelectionApplyResult {
  const ChatQuickReplySelectionApplyResult({
    required this.applied,
    this.message,
  });

  final bool applied;
  final String? message;
}
