part of '../chat_page.dart';

extension _ChatPageShortcuts on _ChatPageState {
  void _focusInput() {
    if (!_inputFocusNode.hasFocus) {
      _inputFocusNode.requestFocus();
    }
  }

  List<ShortcutAction> _activeShortcutActions() {
    return shortcutActionsForRuntime(
      isWeb: kIsWeb,
      targetPlatform: defaultTargetPlatform,
      refreshlessRealtimeEnabled: FeatureFlags.refreshlessRealtime,
    );
  }

  bool _handleGlobalShortcutKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted || !_isChatScreenActive()) {
      return false;
    }

    final hardwareKeyboard = HardwareKeyboard.instance;
    final isFindShortcut =
        event.logicalKey == LogicalKeyboardKey.keyF &&
        (hardwareKeyboard.isControlPressed || hardwareKeyboard.isMetaPressed);
    if (isFindShortcut) {
      _openTimelineSearch();
      return true;
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
      case ShortcutAction.closeApp:
        unawaited(_closeAppShortcut());
        return;
      case ShortcutAction.quitApp:
        unawaited(_quitAppShortcut());
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
      } else {
        _chatInputController.armGlobalEscapeStopHint();
        _focusInput();
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
    final stopped = await chatProvider.abortActiveResponse();
    if (stopped || !mounted) {
      return;
    }
    final rawMessage =
        chatProvider.errorMessage ?? 'Failed to stop current response';
    _showChatPageMessageSnackBar(normalizeAbortMessageForDisplay(rawMessage));
  }

  Future<void> _closeAppShortcut() async {
    final settingsProvider =
        _settingsProvider ?? context.read<SettingsProvider>();
    await settingsProvider.persistDesktopPaneWidths();
    if (_isDesktopRuntime) {
      await windowManager.close();
      return;
    }
    if (!kIsWeb) {
      await SystemNavigator.pop();
    }
  }

  /// Force-exit the app, bypassing soft-close behavior when supported.
  Future<void> _quitAppShortcut() async {
    final settingsProvider =
        _settingsProvider ?? context.read<SettingsProvider>();
    await settingsProvider.persistDesktopPaneWidths();
    if (_isDesktopRuntime) {
      await windowManager.destroy();
      return;
    }
    if (!kIsWeb) {
      await SystemNavigator.pop();
    }
  }
}
