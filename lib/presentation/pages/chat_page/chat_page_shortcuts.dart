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
      ShortcutAction.toggleVoiceInput,
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
    final parentId = chatProvider.currentSession?.parentId?.trim();
    final isSubConversation = parentId != null && parentId.isNotEmpty;
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
      case ShortcutAction.toggleVoiceInput:
        unawaited(_toggleVoiceInputShortcut());
        return;
      case ShortcutAction.quickOpen:
        _openQuickFileDialogFromCurrentContext();
        return;
      case ShortcutAction.openSettings:
        unawaited(_openSettingsPage(closeOnSelect: false));
        return;
      case ShortcutAction.cycleRecentModels:
        if (isSubConversation) {
          return;
        }
        unawaited(chatProvider.cycleRecentModelShortcut());
        return;
      case ShortcutAction.cycleVariant:
        if (isSubConversation) {
          return;
        }
        unawaited(chatProvider.cycleVariant());
        return;
      case ShortcutAction.escape:
        _handleEscape();
        return;
      case ShortcutAction.cycleAgentForward:
        if (isSubConversation) {
          return;
        }
        unawaited(chatProvider.cycleAgent());
        return;
      case ShortcutAction.cycleAgentBackward:
        if (isSubConversation) {
          return;
        }
        unawaited(chatProvider.cycleAgent(reverse: true));
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

  Future<void> _toggleVoiceInputShortcut() async {
    if (!_chatInputController.canToggleVoiceInput) {
      return;
    }
    _chatInputController.focusInput();
    await _chatInputController.toggleVoiceInput();
  }

  Future<void> _requestStopActiveResponse(ChatProvider chatProvider) async {
    final messenger = ScaffoldMessenger.of(context);
    final stopped = await chatProvider.abortActiveResponse();
    if (stopped || !mounted) {
      return;
    }
    final rawMessage =
        chatProvider.errorMessage ?? 'Failed to stop current response';
    messenger.showSnackBar(
      SnackBar(content: Text(normalizeAbortMessageForDisplay(rawMessage))),
    );
  }

  /// Force-quit the desktop app, bypassing close-to-tray.
  /// Uses destroy() instead of close() so setPreventClose stays active
  /// and the X-button close-to-tray behavior is never broken.
  /// Flushes pending settings to disk before destroying the window.
  Future<void> _quitDesktopApp() async {
    if (!_isDesktopRuntime) {
      return;
    }
    final settingsProvider =
        _settingsProvider ?? context.read<SettingsProvider>();
    await settingsProvider.persistDesktopPaneWidths();
    await windowManager.destroy();
  }
}
