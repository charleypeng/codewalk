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

class ChatQuickReplyModelOption {
  const ChatQuickReplyModelOption({
    required this.providerId,
    required this.providerLabel,
    required this.modelId,
    required this.modelLabel,
    this.variantOptions = const <ChatQuickReplyThinkingOption>[],
  });

  final String providerId;
  final String providerLabel;
  final String modelId;
  final String modelLabel;
  final List<ChatQuickReplyThinkingOption> variantOptions;
}

class ChatQuickReplyThinkingOption {
  const ChatQuickReplyThinkingOption({required this.id, required this.label});

  final String id;
  final String label;
}

class ChatQuickReplySelectionOverride {
  const ChatQuickReplySelectionOverride({
    required this.agentName,
    required this.providerId,
    required this.modelId,
    required this.thinkingMode,
    required this.thinkingVariantId,
  });

  final String? agentName;
  final String? providerId;
  final String? modelId;
  final CannedAnswerThinkingMode thinkingMode;
  final String? thinkingVariantId;

  bool get hasExplicitOverride =>
      (agentName?.trim().isNotEmpty ?? false) ||
      ((providerId?.trim().isNotEmpty ?? false) &&
          (modelId?.trim().isNotEmpty ?? false)) ||
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
