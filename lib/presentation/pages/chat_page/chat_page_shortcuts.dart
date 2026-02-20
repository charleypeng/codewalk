part of '../chat_page.dart';

extension _ChatPageShortcuts on _ChatPageState {
  void _focusInput() {
    if (!_inputFocusNode.hasFocus) {
      _inputFocusNode.requestFocus();
    }
  }

  List<ShortcutAction> _activeShortcutActions() {
    final actions = <ShortcutAction>[
      ShortcutAction.newChat,
      ShortcutAction.focusInput,
      ShortcutAction.quickOpen,
      ShortcutAction.openSettings,
      ShortcutAction.cycleRecentModels,
      ShortcutAction.cycleVariant,
      ShortcutAction.escape,
      ShortcutAction.cycleAgentForward,
      ShortcutAction.cycleAgentBackward,
    ];
    if (!FeatureFlags.refreshlessRealtime) {
      actions.insert(1, ShortcutAction.refresh);
    }
    if (_isDesktopRuntime) {
      actions.add(ShortcutAction.quitApp);
    }
    return actions;
  }

  bool _handleGlobalShortcutKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted || !_isChatScreenActive()) {
      return false;
    }

    final settingsProvider = context.read<SettingsProvider>();
    for (final action in _activeShortcutActions()) {
      final activator = ShortcutBindingCodec.parse(
        settingsProvider.bindingFor(action),
      );
      if (activator == null) {
        continue;
      }
      if (!activator.accepts(event, HardwareKeyboard.instance)) {
        continue;
      }
      if (action == ShortcutAction.escape && _inputFocusNode.hasFocus) {
        // Keep composer-level escape behavior (popover close, shell exit,
        // focused double-Esc stop) when the input already owns focus.
        return false;
      }
      _invokeShortcutAction(action);
      return true;
    }

    return false;
  }

  void _invokeShortcutAction(ShortcutAction action) {
    final chatProvider = _chatProvider ?? context.read<ChatProvider>();
    switch (action) {
      case ShortcutAction.newChat:
        _createNewSession();
        return;
      case ShortcutAction.refresh:
        if (!FeatureFlags.refreshlessRealtime) {
          _refreshData();
        }
        return;
      case ShortcutAction.focusInput:
        _focusInput();
        return;
      case ShortcutAction.quickOpen:
        _openQuickFileDialogFromCurrentContext();
        return;
      case ShortcutAction.openSettings:
        unawaited(_openSettingsPage(closeOnSelect: false));
        return;
      case ShortcutAction.cycleRecentModels:
        unawaited(_cycleRecentModel(chatProvider));
        return;
      case ShortcutAction.cycleVariant:
        unawaited(chatProvider.cycleVariant());
        return;
      case ShortcutAction.escape:
        _handleEscape();
        return;
      case ShortcutAction.cycleAgentForward:
        unawaited(_cycleAgentWithFeedback(chatProvider));
        return;
      case ShortcutAction.cycleAgentBackward:
        unawaited(_cycleAgentWithFeedback(chatProvider, reverse: true));
        return;
      case ShortcutAction.quitApp:
        unawaited(_quitDesktopApp());
        return;
    }
  }

  void _handleEscape() {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState?.isDrawerOpen ?? false) {
      _lastGlobalEscapeAt = null;
      Navigator.of(context).pop();
      return;
    }

    final chatProvider = _chatProvider ?? context.read<ChatProvider>();
    if (chatProvider.canAbortActiveResponse) {
      final now = DateTime.now();
      final shouldStop =
          _lastGlobalEscapeAt != null &&
          now.difference(_lastGlobalEscapeAt!) <=
              _ChatPageState._doubleEscapeStopThreshold;
      _lastGlobalEscapeAt = now;
      _showComposerStopHint();
      if (shouldStop) {
        _lastGlobalEscapeAt = null;
        unawaited(_requestStopActiveResponse(chatProvider));
      }
      return;
    }

    _lastGlobalEscapeAt = null;
    _focusInput();
  }

  Future<void> _requestStopActiveResponse(ChatProvider chatProvider) async {
    final messenger = ScaffoldMessenger.of(context);
    final stopped = await chatProvider.abortActiveResponse();
    if (stopped || !mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          chatProvider.errorMessage ?? 'Failed to stop current response',
        ),
      ),
    );
  }

  /// Force-quit the desktop app, bypassing close-to-tray.
  Future<void> _quitDesktopApp() async {
    if (!_isDesktopRuntime) {
      return;
    }
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  Future<void> _cycleAgentWithFeedback(
    ChatProvider chatProvider, {
    bool reverse = false,
  }) async {
    final name = await chatProvider.cycleAgent(reverse: reverse);
    if (name == null || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Agent: $name'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          width: 260,
        ),
      );
  }

  Future<void> _cycleRecentModel(ChatProvider chatProvider) async {
    final available = <({String providerId, String modelId})>[];
    final seen = <String>{};

    // Favorites first, then recents (excluding duplicates).
    for (final favoriteKey in chatProvider.favoriteModelKeys) {
      final providerId = _providerIdFromSelectorKey(favoriteKey);
      final modelId = _modelIdFromSelectorKey(favoriteKey);
      if (providerId == null || modelId == null) {
        continue;
      }
      final provider = chatProvider.providers
          .where((entry) => entry.id == providerId)
          .firstOrNull;
      if (provider == null || !provider.models.containsKey(modelId)) {
        continue;
      }
      final selectorKey = _selectorEntryKey(providerId, modelId);
      if (!seen.add(selectorKey)) {
        continue;
      }
      available.add((providerId: providerId, modelId: modelId));
    }

    for (final recentModelKey in chatProvider.recentModelKeys) {
      final providerId = _providerIdFromSelectorKey(recentModelKey);
      final modelId = _modelIdFromSelectorKey(recentModelKey);
      if (providerId == null || modelId == null) {
        continue;
      }
      final provider = chatProvider.providers
          .where((entry) => entry.id == providerId)
          .firstOrNull;
      if (provider == null || !provider.models.containsKey(modelId)) {
        continue;
      }
      final selectorKey = _selectorEntryKey(providerId, modelId);
      if (!seen.add(selectorKey)) {
        continue;
      }
      available.add((providerId: providerId, modelId: modelId));
    }

    if (available.length < 2) {
      final selectedProvider = chatProvider.selectedProvider;
      if (selectedProvider != null) {
        final modelIds = selectedProvider.models.keys.toList(growable: false)
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        for (final modelId in modelIds) {
          final selectorKey = _selectorEntryKey(selectedProvider.id, modelId);
          if (!seen.add(selectorKey)) {
            continue;
          }
          available.add((providerId: selectedProvider.id, modelId: modelId));
        }
      }
    }

    if (available.isEmpty) {
      return;
    }

    final selectedProviderId = chatProvider.selectedProviderId;
    final selectedModelId = chatProvider.selectedModelId;
    final currentKey = selectedProviderId == null || selectedModelId == null
        ? null
        : _selectorEntryKey(selectedProviderId, selectedModelId);
    final currentIndex = currentKey == null
        ? -1
        : available.indexWhere(
            (entry) =>
                _selectorEntryKey(entry.providerId, entry.modelId) ==
                currentKey,
          );
    final next = currentIndex == -1
        ? available.first
        : available[(currentIndex + 1) % available.length];
    await chatProvider.setSelectedModelByProvider(
      providerId: next.providerId,
      modelId: next.modelId,
    );
  }
}
