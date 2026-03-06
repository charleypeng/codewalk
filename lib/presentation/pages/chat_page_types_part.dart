part of 'chat_page.dart';

class _NewSessionIntent extends Intent {
  const _NewSessionIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _FocusInputIntent extends Intent {
  const _FocusInputIntent();
}

class _ToggleVoiceInputIntent extends Intent {
  const _ToggleVoiceInputIntent();
}

class _QuickOpenIntent extends Intent {
  const _QuickOpenIntent();
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

class _CycleRecentModelsIntent extends Intent {
  const _CycleRecentModelsIntent();
}

class _CycleVariantIntent extends Intent {
  const _CycleVariantIntent();
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

class _CloseAppIntent extends Intent {
  const _CloseAppIntent();
}

class _QuitAppIntent extends Intent {
  const _QuitAppIntent();
}

class _ModelSelectorEntry {
  const _ModelSelectorEntry({
    required this.providerId,
    required this.providerName,
    required this.modelId,
    required this.modelName,
  });

  final String providerId;
  final String providerName;
  final String modelId;
  final String modelName;
}

class _SessionContextUsageSnapshot {
  const _SessionContextUsageSnapshot({
    required this.usagePercent,
    required this.totalTokens,
    required this.totalCost,
    required this.modelLimit,
  });

  final int usagePercent;
  final int totalTokens;
  final double totalCost;
  final int? modelLimit;
}
