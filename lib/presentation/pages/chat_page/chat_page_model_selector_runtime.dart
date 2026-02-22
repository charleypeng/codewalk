part of '../chat_page.dart';

extension _ChatPageModelSelectorRuntime on _ChatPageState {
  Widget _buildModelControls(
    ChatProvider chatProvider, {
    required bool attachmentsEnabled,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedModel = chatProvider.selectedModel;
    final selectedAgent = chatProvider.selectedAgentName;
    final selectableAgents = chatProvider.selectableAgents;
    final selectedAgentEntry = _selectedAgentEntry(chatProvider);
    final selectedAgentColor = _parseAgentColor(selectedAgentEntry?.color);
    final variants = chatProvider.availableVariants;
    final showProvidersLoadingHint =
        chatProvider.isProvidersRefreshInProgress &&
        chatProvider.providers.isEmpty;
    final showProvidersRetryHint =
        chatProvider.providersRefreshState == ChatProvidersRefreshState.failed;
    final attachButtonStyle = composerAttachButtonStyle(
      colorScheme: colorScheme,
      visualDensity: Theme.of(context).visualDensity,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Tooltip(
            message: 'Choose agent',
            child: Builder(
              key: _agentSelectorChipKey,
              builder: (chipContext) => ActionChip(
                key: const ValueKey<String>('agent_selector_button'),
                side: BorderSide.none,
                shape: const StadiumBorder(),
                backgroundColor: selectedAgentColor?.withValues(alpha: 0.16),
                label: Text(
                  selectedAgent == null
                      ? 'Select agent'
                      : _formatAgentLabel(selectedAgent),
                  style: selectedAgentColor == null
                      ? null
                      : TextStyle(color: selectedAgentColor),
                ),
                onPressed: selectableAgents.isEmpty
                    ? null
                    : () => unawaited(
                        _openAgentQuickSelector(
                          chatProvider,
                          anchorContext: chipContext,
                        ),
                      ),
              ),
            ),
          ),
          Tooltip(
            message: 'Choose model',
            child: ActionChip(
              key: const ValueKey<String>('model_selector_button'),
              side: BorderSide.none,
              shape: const StadiumBorder(),
              label: Text(selectedModel?.name ?? 'Select model'),
              onPressed: chatProvider.providers.isEmpty
                  ? null
                  : () => unawaited(_openModelSelector(chatProvider)),
            ),
          ),
          if (showProvidersLoadingHint)
            Chip(
              avatar: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              label: const Text('Loading models'),
              side: BorderSide.none,
              backgroundColor: colorScheme.surfaceContainerHighest,
            )
          else if (showProvidersRetryHint)
            Tooltip(
              message:
                  chatProvider.providersRefreshErrorMessage ??
                  'Failed to refresh providers and models',
              child: ActionChip(
                key: const ValueKey<String>('model_selector_retry_button'),
                avatar: const Icon(Symbols.refresh_rounded, size: 16),
                side: BorderSide.none,
                shape: const StadiumBorder(),
                label: const Text('Retry models'),
                onPressed: () =>
                    unawaited(chatProvider.retryProvidersRefresh()),
              ),
            ),
          if (variants.isNotEmpty)
            Tooltip(
              message: 'Choose effort',
              child: Builder(
                builder: (chipContext) => ActionChip(
                  key: const ValueKey<String>('variant_selector_button'),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  label: Text(chatProvider.selectedVariantLabel),
                  onPressed: () => unawaited(
                    _openVariantQuickSelector(
                      chatProvider,
                      anchorContext: chipContext,
                    ),
                  ),
                ),
              ),
            ),
          if (attachmentsEnabled)
            Tooltip(
              message: 'Add attachment',
              child: IconButton(
                onPressed: chatProvider.currentSession == null
                    ? null
                    : _chatInputController.openAttachmentOptions,
                style: attachButtonStyle,
                icon: const Icon(Symbols.attach_file_rounded),
              ),
            ),
        ],
      ),
    );
  }

  Agent? _selectedAgentEntry(ChatProvider chatProvider) {
    final selectedName = chatProvider.selectedAgentName;
    if (selectedName == null || selectedName.trim().isEmpty) {
      return null;
    }
    for (final agent in chatProvider.selectableAgents) {
      if (agent.name == selectedName) {
        return agent;
      }
    }
    final normalized = selectedName.toLowerCase();
    for (final agent in chatProvider.selectableAgents) {
      if (agent.name.toLowerCase() == normalized) {
        return agent;
      }
    }
    return null;
  }

  Color? _parseAgentColor(String? rawColor) {
    if (rawColor == null) {
      return null;
    }
    var normalized = rawColor.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('#')) {
      normalized = normalized.substring(1);
    } else if (normalized.startsWith('0x')) {
      normalized = normalized.substring(2);
    }
    if (normalized.length == 3) {
      normalized = normalized
          .split('')
          .map((segment) => '$segment$segment')
          .join();
    }
    if (normalized.length == 6) {
      normalized = 'FF$normalized';
    }
    if (normalized.length != 8) {
      return null;
    }
    final parsedValue = int.tryParse(normalized, radix: 16);
    if (parsedValue == null) {
      return null;
    }
    return Color(parsedValue);
  }

  String _formatAgentLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return value;
    }
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }

  IconData _providerBrandIcon({
    required String? providerId,
    required String? providerName,
  }) {
    final normalizedProvider = '${providerId ?? ''} ${providerName ?? ''}'
        .trim()
        .toLowerCase();

    if (_containsAnyBrandToken(normalizedProvider, const ['anthropic'])) {
      return SimpleIcons.anthropic;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['google'])) {
      return SimpleIcons.google;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['openrouter'])) {
      return SimpleIcons.openrouter;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['minimax'])) {
      return SimpleIcons.minimax;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['mistral'])) {
      return SimpleIcons.mistralai;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['xai'])) {
      return SimpleIcons.spacex;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['github'])) {
      return SimpleIcons.github;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['gitlab'])) {
      return SimpleIcons.gitlab;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['cloudflare'])) {
      return SimpleIcons.cloudflare;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['ollama'])) {
      return SimpleIcons.ollama;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['huggingface'])) {
      return SimpleIcons.huggingface;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['vercel'])) {
      return SimpleIcons.vercel;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['perplexity'])) {
      return SimpleIcons.perplexity;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['nvidia'])) {
      return SimpleIcons.nvidia;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['alibaba'])) {
      return SimpleIcons.alibabacloud;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['poe'])) {
      return SimpleIcons.poe;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['scaleway'])) {
      return SimpleIcons.scaleway;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['sap'])) {
      return SimpleIcons.sap;
    }
    if (_containsAnyBrandToken(normalizedProvider, const ['v0'])) {
      return SimpleIcons.v0;
    }

    return Symbols.smart_toy;
  }

  IconData _modelSelectorListIcon({
    required String? providerId,
    required String? providerName,
    required String? modelId,
    required String? modelName,
  }) {
    final normalizedModel = '${modelId ?? ''} ${modelName ?? ''}'
        .trim()
        .toLowerCase();

    // Model-aware matching first to avoid ambiguous provider IDs.
    if (_containsAnyBrandToken(normalizedModel, const [
      'claude',
      'anthropic',
    ])) {
      return SimpleIcons.claude;
    }
    if (_containsAnyBrandToken(normalizedModel, const ['gemini', 'google'])) {
      return SimpleIcons.googlegemini;
    }

    final providerIcon = _providerBrandIcon(
      providerId: providerId,
      providerName: providerName,
    );
    return providerIcon;
  }

  bool _containsAnyBrandToken(String source, List<String> tokens) {
    for (final token in tokens) {
      if (source.contains(token)) {
        return true;
      }
    }
    return false;
  }

  void _handleMessageBackgroundLongPress(ChatMessage message) {
    if (!_isMobileViewport || message.role != MessageRole.user) {
      return;
    }
    final text = _extractUserMessageText(message);
    if (text.isEmpty) {
      return;
    }
    _setState(() {
      _composerPrefilledDraft = ChatComposerDraft(text: text);
      _composerPrefilledDraftVersion += 1;
    });
    unawaited(HapticFeedback.selectionClick());
  }

  void _handleMessageBackgroundLongPressEnd(ChatMessage message) {
    if (!_isMobileViewport || message.role != MessageRole.user) {
      return;
    }
    final text = _extractUserMessageText(message);
    if (text.isEmpty) {
      return;
    }
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 16), () {
        if (!mounted) {
          return;
        }
        _inputFocusNode.requestFocus();
      }),
    );
  }

  String _agentKey(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
  }

  Future<void> _openAgentQuickSelector(
    ChatProvider chatProvider, {
    required BuildContext anchorContext,
  }) async {
    final entries = chatProvider.selectableAgents;
    if (entries.isEmpty) {
      return;
    }
    final buttonBox = anchorContext.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(anchorContext).context.findRenderObject() as RenderBox?;
    if (buttonBox == null || overlayBox == null) {
      return;
    }
    final buttonTopLeft = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final buttonRect = buttonTopLeft & buttonBox.size;
    const margin = 8.0;
    const menuWidth = 260.0;
    final left = (buttonRect.center.dx - (menuWidth / 2))
        .clamp(margin, overlayBox.size.width - menuWidth - margin)
        .toDouble();
    final top = (buttonRect.top - 4).clamp(margin, overlayBox.size.height - 48);

    final selected = await showMenu<String>(
      context: context,
      constraints: const BoxConstraints(
        minWidth: menuWidth,
        maxWidth: menuWidth,
      ),
      position: RelativeRect.fromLTRB(
        left,
        top.toDouble(),
        overlayBox.size.width - left - menuWidth,
        overlayBox.size.height - top.toDouble(),
      ),
      items: [
        for (final entry in entries)
          PopupMenuItem<String>(
            key: ValueKey<String>(
              'agent_selector_item_${_agentKey(entry.name)}',
            ),
            value: entry.name,
            child: Row(
              children: [
                if (_parseAgentColor(entry.color) case final color?)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _formatAgentLabel(entry.name),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (chatProvider.selectedAgentName == entry.name)
                  const Icon(Symbols.check_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
    if (selected == null) {
      return;
    }
    await chatProvider.setSelectedAgent(selected);
  }

  List<_ModelSelectorEntry> _buildModelSelectorEntries(
    ChatProvider chatProvider,
  ) {
    final entries = <_ModelSelectorEntry>[];
    final providers = _sortedProviders(chatProvider);
    for (final provider in providers) {
      final models = provider.models.values.toList(growable: false)
        ..sort((a, b) {
          final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          if (byName != 0) {
            return byName;
          }
          return a.id.compareTo(b.id);
        });
      for (final model in models) {
        entries.add(
          _ModelSelectorEntry(
            providerId: provider.id,
            providerName: provider.name,
            modelId: model.id,
            modelName: model.name,
          ),
        );
      }
    }
    return entries;
  }

  List<Provider> _sortedProviders(ChatProvider chatProvider) {
    final providers = List.of(chatProvider.providers);
    providers.sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) {
        return byName;
      }
      return a.id.compareTo(b.id);
    });
    return providers;
  }

  String _selectorEntryKey(String providerId, String modelId) {
    return '$providerId/$modelId';
  }

  String? _providerIdFromSelectorKey(String modelKey) {
    final separatorIndex = modelKey.indexOf('/');
    if (separatorIndex <= 0) {
      return null;
    }
    return modelKey.substring(0, separatorIndex);
  }

  String? _modelIdFromSelectorKey(String modelKey) {
    final separatorIndex = modelKey.indexOf('/');
    if (separatorIndex <= 0 || separatorIndex == modelKey.length - 1) {
      return null;
    }
    return modelKey.substring(separatorIndex + 1);
  }

  List<_ModelSelectorEntry> _buildRecentModelEntries(
    ChatProvider chatProvider,
    List<_ModelSelectorEntry> allEntries,
  ) {
    final byKey = <String, _ModelSelectorEntry>{
      for (final entry in allEntries)
        _selectorEntryKey(entry.providerId, entry.modelId): entry,
    };
    final recent = <_ModelSelectorEntry>[];
    final seen = <String>{};

    for (final recentModelKey in chatProvider.recentModelKeys) {
      final providerId = _providerIdFromSelectorKey(recentModelKey);
      final modelId = _modelIdFromSelectorKey(recentModelKey);
      if (providerId == null || modelId == null) {
        continue;
      }
      final key = _selectorEntryKey(providerId, modelId);
      if (!seen.add(key)) {
        continue;
      }
      final entry = byKey[key];
      if (entry == null) {
        continue;
      }
      recent.add(entry);
      if (recent.length >= 3) {
        break;
      }
    }
    return recent;
  }

  /// Build favorite model entries from the provider's favorite keys.
  List<_ModelSelectorEntry> _buildFavoriteModelEntries(
    ChatProvider chatProvider,
    List<_ModelSelectorEntry> allEntries,
  ) {
    final byKey = <String, _ModelSelectorEntry>{
      for (final entry in allEntries)
        _selectorEntryKey(entry.providerId, entry.modelId): entry,
    };
    final favorites = <_ModelSelectorEntry>[];
    final seen = <String>{};

    for (final favoriteKey in chatProvider.favoriteModelKeys) {
      final providerId = _providerIdFromSelectorKey(favoriteKey);
      final modelId = _modelIdFromSelectorKey(favoriteKey);
      if (providerId == null || modelId == null) {
        continue;
      }
      final key = _selectorEntryKey(providerId, modelId);
      if (!seen.add(key)) {
        continue;
      }
      final entry = byKey[key];
      if (entry == null) {
        continue;
      }
      favorites.add(entry);
    }
    return favorites;
  }

  /// Trailing widget for model selector: star toggle + checkmark.
  Widget _modelSelectorTrailing({
    required ChatProvider chatProvider,
    required String providerId,
    required String modelId,
    required bool isSelected,
    required void Function() onFavoriteToggled,
  }) {
    final isFavorite = chatProvider.isModelFavorite(
      providerId: providerId,
      modelId: modelId,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isFavorite ? Symbols.star_rounded : Symbols.star_outline_rounded,
            size: 20,
            color: isFavorite ? Colors.amber : null,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () async {
            await chatProvider.toggleModelFavorite(
              providerId: providerId,
              modelId: modelId,
            );
            onFavoriteToggled();
          },
        ),
        if (isSelected) const Icon(Symbols.check_rounded, size: 18),
      ],
    );
  }

  Future<void> _openModelSelector(ChatProvider chatProvider) async {
    final entries = _buildModelSelectorEntries(chatProvider);
    final sortedProviders = _sortedProviders(chatProvider);
    var query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (bottomSheetContext, setModalState) {
            final normalizedQuery = query.trim().toLowerCase();
            final matchingEntries = entries
                .where((entry) {
                  if (normalizedQuery.isEmpty) {
                    return true;
                  }
                  return entry.modelName.toLowerCase().contains(
                        normalizedQuery,
                      ) ||
                      entry.modelId.toLowerCase().contains(normalizedQuery) ||
                      entry.providerName.toLowerCase().contains(
                        normalizedQuery,
                      ) ||
                      entry.providerId.toLowerCase().contains(normalizedQuery);
                })
                .toList(growable: false);

            // Favorites section (shown when no search query).
            final favoriteEntries = normalizedQuery.isEmpty
                ? _buildFavoriteModelEntries(chatProvider, entries)
                : const <_ModelSelectorEntry>[];
            final favoriteKeys = favoriteEntries
                .map(
                  (entry) => _selectorEntryKey(entry.providerId, entry.modelId),
                )
                .toSet();

            // Recent section excludes favorites.
            final recentEntries = normalizedQuery.isEmpty
                ? _buildRecentModelEntries(chatProvider, entries)
                      .where(
                        (entry) => !favoriteKeys.contains(
                          _selectorEntryKey(entry.providerId, entry.modelId),
                        ),
                      )
                      .toList(growable: false)
                : const <_ModelSelectorEntry>[];
            final recentKeys = recentEntries
                .map(
                  (entry) => _selectorEntryKey(entry.providerId, entry.modelId),
                )
                .toSet();

            // Provider sections exclude favorites and recents.
            final excludeFromGrouped = {...favoriteKeys, ...recentKeys};
            final groupedSourceEntries =
                normalizedQuery.isEmpty && excludeFromGrouped.isNotEmpty
                ? matchingEntries
                      .where(
                        (entry) => !excludeFromGrouped.contains(
                          _selectorEntryKey(entry.providerId, entry.modelId),
                        ),
                      )
                      .toList(growable: false)
                : matchingEntries;

            final groupedEntries = <String, List<_ModelSelectorEntry>>{};
            for (final entry in groupedSourceEntries) {
              groupedEntries
                  .putIfAbsent(entry.providerId, () => <_ModelSelectorEntry>[])
                  .add(entry);
            }
            final hasVisibleEntries =
                favoriteEntries.isNotEmpty ||
                recentEntries.isNotEmpty ||
                groupedEntries.isNotEmpty;

            final selectedProviderId = chatProvider.selectedProviderId;
            final selectedModelId = chatProvider.selectedModelId;
            final selectedKey =
                selectedProviderId == null || selectedModelId == null
                ? null
                : '$selectedProviderId/$selectedModelId';

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(bottomSheetContext).bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(bottomSheetContext).height * 0.72,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: TextField(
                          autofocus: true,
                          onChanged: (value) {
                            setModalState(() {
                              query = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search model or provider',
                            prefixIcon: const Icon(Symbols.search),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: !hasVisibleEntries
                            ? Center(
                                child: Text(
                                  'No models found',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                            : ListView(
                                children: [
                                  // Favorites section
                                  if (favoriteEntries.isNotEmpty) ...[
                                    Padding(
                                      key: const ValueKey<String>(
                                        'model_selector_favorites_header',
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        16,
                                        4,
                                      ),
                                      child: Text(
                                        'Favorites',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    for (final entry in favoriteEntries)
                                      ListTile(
                                        key: ValueKey<String>(
                                          'model_selector_fav_${entry.providerId}_${entry.modelId}',
                                        ),
                                        leading: Icon(
                                          _modelSelectorListIcon(
                                            providerId: entry.providerId,
                                            providerName: entry.providerName,
                                            modelId: entry.modelId,
                                            modelName: entry.modelName,
                                          ),
                                          size: 18,
                                        ),
                                        title: Text(entry.modelName),
                                        subtitle: Text(entry.providerName),
                                        trailing: _modelSelectorTrailing(
                                          chatProvider: chatProvider,
                                          providerId: entry.providerId,
                                          modelId: entry.modelId,
                                          isSelected:
                                              selectedKey ==
                                              _selectorEntryKey(
                                                entry.providerId,
                                                entry.modelId,
                                              ),
                                          onFavoriteToggled: () =>
                                              setModalState(() {}),
                                        ),
                                        onTap: () async {
                                          await chatProvider
                                              .setSelectedModelByProvider(
                                                providerId: entry.providerId,
                                                modelId: entry.modelId,
                                              );
                                          if (!bottomSheetContext.mounted) {
                                            return;
                                          }
                                          Navigator.of(
                                            bottomSheetContext,
                                          ).pop();
                                        },
                                      ),
                                  ],
                                  // Recent section
                                  if (recentEntries.isNotEmpty) ...[
                                    Padding(
                                      key: const ValueKey<String>(
                                        'model_selector_recent_header',
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        16,
                                        4,
                                      ),
                                      child: Text(
                                        'Recent',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    for (final entry in recentEntries)
                                      ListTile(
                                        key: ValueKey<String>(
                                          'model_selector_recent_${entry.providerId}_${entry.modelId}',
                                        ),
                                        leading: Icon(
                                          _modelSelectorListIcon(
                                            providerId: entry.providerId,
                                            providerName: entry.providerName,
                                            modelId: entry.modelId,
                                            modelName: entry.modelName,
                                          ),
                                          size: 18,
                                        ),
                                        title: Text(entry.modelName),
                                        subtitle: Text(entry.providerName),
                                        trailing: _modelSelectorTrailing(
                                          chatProvider: chatProvider,
                                          providerId: entry.providerId,
                                          modelId: entry.modelId,
                                          isSelected:
                                              selectedKey ==
                                              _selectorEntryKey(
                                                entry.providerId,
                                                entry.modelId,
                                              ),
                                          onFavoriteToggled: () =>
                                              setModalState(() {}),
                                        ),
                                        onTap: () async {
                                          await chatProvider
                                              .setSelectedModelByProvider(
                                                providerId: entry.providerId,
                                                modelId: entry.modelId,
                                              );
                                          if (!bottomSheetContext.mounted) {
                                            return;
                                          }
                                          Navigator.of(
                                            bottomSheetContext,
                                          ).pop();
                                        },
                                      ),
                                  ],
                                  // Provider sections
                                  for (final provider in sortedProviders)
                                    if (groupedEntries.containsKey(
                                      provider.id,
                                    )) ...[
                                      Padding(
                                        key: ValueKey<String>(
                                          'model_selector_provider_header_${provider.id}',
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          12,
                                          16,
                                          4,
                                        ),
                                        child: Text(
                                          provider.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      for (final entry
                                          in groupedEntries[provider.id]!)
                                        ListTile(
                                          key: ValueKey<String>(
                                            'model_selector_item_${entry.providerId}_${entry.modelId}',
                                          ),
                                          leading: Icon(
                                            _modelSelectorListIcon(
                                              providerId: entry.providerId,
                                              providerName: entry.providerName,
                                              modelId: entry.modelId,
                                              modelName: entry.modelName,
                                            ),
                                            size: 18,
                                          ),
                                          title: Text(entry.modelName),
                                          subtitle:
                                              entry.modelName == entry.modelId
                                              ? null
                                              : Text(entry.modelId),
                                          trailing: _modelSelectorTrailing(
                                            chatProvider: chatProvider,
                                            providerId: entry.providerId,
                                            modelId: entry.modelId,
                                            isSelected:
                                                selectedKey ==
                                                _selectorEntryKey(
                                                  entry.providerId,
                                                  entry.modelId,
                                                ),
                                            onFavoriteToggled: () =>
                                                setModalState(() {}),
                                          ),
                                          onTap: () async {
                                            await chatProvider
                                                .setSelectedModelByProvider(
                                                  providerId: entry.providerId,
                                                  modelId: entry.modelId,
                                                );
                                            if (!bottomSheetContext.mounted) {
                                              return;
                                            }
                                            Navigator.of(
                                              bottomSheetContext,
                                            ).pop();
                                          },
                                        ),
                                    ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openVariantQuickSelector(
    ChatProvider chatProvider, {
    required BuildContext anchorContext,
  }) async {
    final variants = chatProvider.availableVariants;
    if (variants.isEmpty) {
      return;
    }

    final buttonBox = anchorContext.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(anchorContext).context.findRenderObject() as RenderBox?;
    if (buttonBox == null || overlayBox == null) {
      return;
    }
    final buttonTopLeft = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final buttonRect = buttonTopLeft & buttonBox.size;
    const margin = 8.0;

    // Auto-fit width based on the longest label text.
    final textStyle =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 14);
    final labels = ['Auto', ...variants.map((v) => v.name)];
    final longestLabel = labels.reduce((a, b) => a.length > b.length ? a : b);
    final textPainter = TextPainter(
      text: TextSpan(text: longestLabel, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    // padding: 16 leading + 8 gap + 18 check icon + 16 trailing = 58
    final menuWidth = (textPainter.width + 58).ceilToDouble();

    final left = (buttonRect.center.dx - (menuWidth / 2))
        .clamp(margin, overlayBox.size.width - menuWidth - margin)
        .toDouble();
    final top = (buttonRect.top - 4).clamp(margin, overlayBox.size.height - 48);

    final selected = await showMenu<String?>(
      context: context,
      constraints: BoxConstraints(minWidth: menuWidth, maxWidth: menuWidth),
      position: RelativeRect.fromLTRB(
        left,
        top.toDouble(),
        overlayBox.size.width - left - menuWidth,
        overlayBox.size.height - top.toDouble(),
      ),
      items: [
        PopupMenuItem<String?>(
          key: const ValueKey<String>('variant_selector_option_auto'),
          value: null,
          child: Row(
            children: [
              const Expanded(child: Text('Auto')),
              if (chatProvider.selectedVariantId == null)
                const Icon(Symbols.check_rounded, size: 18),
            ],
          ),
        ),
        for (final variant in variants)
          PopupMenuItem<String?>(
            key: ValueKey<String>('variant_selector_option_${variant.id}'),
            value: variant.id,
            child: Row(
              children: [
                Expanded(
                  child: Text(variant.name, overflow: TextOverflow.ellipsis),
                ),
                if (chatProvider.selectedVariantId == variant.id)
                  const Icon(Symbols.check_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
    if (selected == null && chatProvider.selectedVariantId == null) {
      return;
    }
    await chatProvider.setSelectedVariant(selected);
  }

  Future<void> _createNewSession() async {
    final chatProvider = context.read<ChatProvider>();

    // Technical comment translated to English.
    await chatProvider.createNewSession();
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _inputFocusNode.requestFocus();
    });
  }

  List<ChatComposerSlashCommandSuggestion> _builtinSlashCommands() {
    return const <ChatComposerSlashCommandSuggestion>[
      ChatComposerSlashCommandSuggestion(
        name: 'new',
        source: 'builtin',
        description: 'Create a new chat session',
        isBuiltin: true,
      ),
      ChatComposerSlashCommandSuggestion(
        name: 'model',
        source: 'builtin',
        description: 'Open model selector',
        isBuiltin: true,
      ),
      ChatComposerSlashCommandSuggestion(
        name: 'agent',
        source: 'builtin',
        description: 'Open agent selector',
        isBuiltin: true,
      ),
      ChatComposerSlashCommandSuggestion(
        name: 'open',
        source: 'builtin',
        description: 'File open quick action',
        isBuiltin: true,
      ),
      ChatComposerSlashCommandSuggestion(
        name: 'help',
        source: 'builtin',
        description: 'Show command help',
        isBuiltin: true,
      ),
      ChatComposerSlashCommandSuggestion(
        name: 'compact',
        source: 'builtin',
        description: 'Compact current session context',
        isBuiltin: true,
      ),
    ];
  }
}
