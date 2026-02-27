part of '../chat_provider.dart';

extension _ChatProviderShortcutCycleOps on ChatProvider {
  void _recordModelSelectionRecency({String? previousModelKey}) {
    final currentModelKey = _currentModelKey();
    if (currentModelKey == null || currentModelKey.trim().isEmpty) {
      return;
    }
    _recentModelKeys = _recordRecentSelection(
      _recentModelKeys,
      currentModelKey,
      previousSelectionKey: previousModelKey,
      maxEntries: ChatProvider._maxRecentModels,
    );
  }

  void _recordAgentSelectionRecency({String? previousAgentName}) {
    final currentAgentName = _selectedAgentName?.trim();
    if (currentAgentName == null || currentAgentName.isEmpty) {
      return;
    }
    _recentAgentNames = _recordRecentSelection(
      _recentAgentNames,
      currentAgentName,
      previousSelectionKey: previousAgentName,
      maxEntries: ChatProvider._maxRecentAgents,
    );
  }

  void _recordVariantSelectionRecencyForCurrentModel({
    String? previousVariantId,
  }) {
    final modelKey = _currentModelKey();
    if (modelKey == null || modelKey.trim().isEmpty) {
      return;
    }
    final currentVariantValue = _variantHistoryValue(_selectedVariantId);
    final previousVariantValue = _variantHistoryValue(previousVariantId);
    final existingHistory =
        _recentVariantValuesByModel[modelKey] ?? const <String>[];
    _recentVariantValuesByModel[modelKey] = _recordRecentSelection(
      existingHistory,
      currentVariantValue,
      previousSelectionKey: previousVariantValue,
      maxEntries: ChatProvider._maxRecentVariantsPerModel,
    );
  }

  List<String> _recordRecentSelection(
    List<String> currentHistory,
    String currentSelectionKey, {
    String? previousSelectionKey,
    required int maxEntries,
  }) {
    final next = <String>[];
    final seen = <String>{};

    void add(String? value) {
      final normalized = value?.trim();
      if (normalized == null || normalized.isEmpty) {
        return;
      }
      if (!seen.add(normalized)) {
        return;
      }
      next.add(normalized);
    }

    add(currentSelectionKey);
    if (previousSelectionKey != null &&
        previousSelectionKey.trim() != currentSelectionKey.trim()) {
      add(previousSelectionKey);
    }
    for (final value in currentHistory) {
      add(value);
    }

    if (next.length <= maxEntries) {
      return next;
    }
    return next.take(maxEntries).toList(growable: false);
  }

  List<String> _availableModelCycleKeys() {
    final candidates = <String>[];
    final seen = <String>{};

    void addModelKey(String modelKey) {
      final normalized = modelKey.trim();
      if (normalized.isEmpty || !seen.add(normalized)) {
        return;
      }
      final providerId = _providerFromModelKey(normalized);
      final modelId = _modelFromModelKey(normalized);
      if (providerId == null || modelId == null) {
        return;
      }
      final provider = _providers
          .where((entry) => entry.id == providerId)
          .firstOrNull;
      if (provider == null || !provider.models.containsKey(modelId)) {
        return;
      }
      candidates.add(normalized);
    }

    for (final favoriteKey in _favoriteModelKeys) {
      addModelKey(favoriteKey);
    }
    for (final recentKey in _recentModelKeys) {
      addModelKey(recentKey);
    }

    if (candidates.length < 2) {
      final provider = selectedProvider;
      if (provider != null) {
        final modelIds = provider.models.keys.toList(growable: false)
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        for (final modelId in modelIds) {
          addModelKey(_modelKey(provider.id, modelId));
        }
      }
    }

    return candidates;
  }

  List<String> _availableVariantCycleValues(Model model) {
    final candidates = <String>[ChatProvider._remoteAutoVariantValue];
    for (final variantId in model.variants.keys) {
      final normalized = variantId.trim();
      if (normalized.isEmpty ||
          normalized == ChatProvider._remoteAutoVariantValue) {
        continue;
      }
      candidates.add(normalized);
    }
    return candidates;
  }

  String _variantHistoryValue(String? variantId) {
    final normalized = variantId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return ChatProvider._remoteAutoVariantValue;
    }
    return normalized;
  }

  String? _variantIdFromHistoryValue(String value) {
    if (value == ChatProvider._remoteAutoVariantValue) {
      return null;
    }
    return value;
  }

  String? _nextShortcutCycleTarget({
    required _ShortcutCycleDomain domain,
    required String? currentKey,
    required List<String> candidateKeys,
    required List<String> historyKeys,
    bool reverse = false,
  }) {
    final candidates = _normalizedCycleKeys(candidateKeys);
    if (candidates.isEmpty) {
      _shortcutCycleStateByDomain.remove(domain);
      return null;
    }
    if (candidates.length == 1) {
      _shortcutCycleStateByDomain.remove(domain);
      final singleCandidate = candidates.first;
      if (singleCandidate == currentKey?.trim()) {
        return null;
      }
      return singleCandidate;
    }

    final candidateSet = candidates.toSet();
    final history = _normalizedHistoryKeys(historyKeys, candidateSet);
    final normalizedCurrent = currentKey?.trim();
    final now = DateTime.now();
    final existingState = _shortcutCycleStateByDomain[domain];

    if (existingState != null &&
        existingState.reverse == reverse &&
        now.difference(existingState.lastActivatedAt) <= _shortcutCycleWindow &&
        normalizedCurrent != null &&
        normalizedCurrent.isNotEmpty) {
      final filteredSnapshot = existingState.snapshot
          .where((key) => candidateSet.contains(key))
          .toList(growable: false);
      if (filteredSnapshot.length >= 2 &&
          existingState.currentIndex >= 0 &&
          existingState.currentIndex < filteredSnapshot.length &&
          filteredSnapshot[existingState.currentIndex] == normalizedCurrent) {
        final nextIndex = _advanceCycleIndex(
          existingState.currentIndex,
          filteredSnapshot.length,
          reverse: reverse,
        );
        _shortcutCycleStateByDomain[domain] = _ShortcutCycleState(
          snapshot: filteredSnapshot,
          currentIndex: nextIndex,
          lastActivatedAt: now,
          reverse: reverse,
        );
        return filteredSnapshot[nextIndex];
      }
    }

    final hasEnoughHistory = history.length >= 2;
    final snapshot = hasEnoughHistory
        ? _historySnapshotWithCurrentFirst(history, normalizedCurrent)
        : candidates;
    if (snapshot.isEmpty) {
      _shortcutCycleStateByDomain.remove(domain);
      return null;
    }
    if (snapshot.length == 1) {
      _shortcutCycleStateByDomain.remove(domain);
      final single = snapshot.first;
      if (single == normalizedCurrent) {
        return null;
      }
      return single;
    }

    final currentIndex = normalizedCurrent == null
        ? -1
        : snapshot.indexOf(normalizedCurrent);
    late final int nextIndex;
    if (currentIndex == -1) {
      nextIndex = 0;
    } else if (hasEnoughHistory) {
      // Alt+Tab behavior: first activation focuses the previously used item.
      nextIndex = (currentIndex + 1) % snapshot.length;
    } else {
      // Fallback when history is insufficient keeps deterministic linear order.
      nextIndex = _advanceCycleIndex(
        currentIndex,
        snapshot.length,
        reverse: reverse,
      );
    }

    _shortcutCycleStateByDomain[domain] = _ShortcutCycleState(
      snapshot: snapshot,
      currentIndex: nextIndex,
      lastActivatedAt: now,
      reverse: reverse,
    );
    return snapshot[nextIndex];
  }

  List<String> _normalizedCycleKeys(List<String> keys) {
    final normalized = <String>[];
    final seen = <String>{};
    for (final key in keys) {
      final value = key.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      normalized.add(value);
    }
    return normalized;
  }

  List<String> _normalizedHistoryKeys(
    List<String> history,
    Set<String> candidates,
  ) {
    final normalized = <String>[];
    final seen = <String>{};
    for (final key in history) {
      final value = key.trim();
      if (value.isEmpty || !candidates.contains(value) || !seen.add(value)) {
        continue;
      }
      normalized.add(value);
    }
    return normalized;
  }

  List<String> _historySnapshotWithCurrentFirst(
    List<String> history,
    String? currentKey,
  ) {
    final snapshot = List<String>.from(history);
    if (currentKey == null || currentKey.isEmpty) {
      return snapshot;
    }
    snapshot.remove(currentKey);
    snapshot.insert(0, currentKey);
    return snapshot;
  }

  int _advanceCycleIndex(
    int currentIndex,
    int length, {
    required bool reverse,
  }) {
    if (length <= 0) {
      return 0;
    }
    if (reverse) {
      return (currentIndex - 1 + length) % length;
    }
    return (currentIndex + 1) % length;
  }
}
