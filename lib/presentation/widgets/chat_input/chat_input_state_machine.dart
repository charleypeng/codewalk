part of '../chat_input_widget.dart';

extension _ChatInputStateMachine on _ChatInputWidgetState {
  Future<void> _handleSendMessage() async {
    final text = _controller.text.trim();
    final payloadText = _mode == ChatComposerMode.shell
        ? _normalizeShellPayload(text)
        : text;
    if (!widget.enabled || _isSending || widget.isResponding) {
      return;
    }
    if (payloadText.isEmpty &&
        (_mode == ChatComposerMode.shell || _attachments.isEmpty)) {
      return;
    }
    if (_isListening) {
      await _stopListening();
    }

    _setState(() {
      _isSending = true;
    });

    try {
      await widget.onSendMessage(
        ChatInputSubmission(
          text: payloadText,
          attachments: _mode == ChatComposerMode.shell
              ? const <FileInputPart>[]
              : List<FileInputPart>.unmodifiable(_attachments),
          mode: _mode,
        ),
      );
      if (!mounted) {
        return;
      }
      _controller.clear();
      _setState(() {
        _isComposing = false;
        _attachments.clear();
        _mode = ChatComposerMode.normal;
        _popoverType = ChatComposerPopoverType.none;
        _mentionSuggestions = <ChatComposerMentionSuggestion>[];
        _slashSuggestions = <ChatComposerSlashCommandSuggestion>[];
        _activeSuggestionIndex = 0;
      });
      if (_shouldHideKeyboardAfterSend) {
        _effectiveFocusNode.unfocus();
        unawaited(
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Draft kept for retry.'),
        ),
      );
      _ensureInputFocus();
    } finally {
      if (mounted) {
        _setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _handleTextChanged(String text) {
    if (!_isApplyingHistoryValue) {
      _exitHistoryNavigation(updateDraft: true);
    }
    _refreshComposerMode(text);
    _scheduleSuggestionQuery();
    if (_popoverType != ChatComposerPopoverType.none &&
        _activeSuggestionIndex >= _activeSuggestionsCount) {
      _activeSuggestionIndex = _activeSuggestionsCount > 0
          ? _activeSuggestionsCount - 1
          : 0;
    }
    _setState(() {
      _isComposing = text.trim().isNotEmpty;
    });
    if (_suppressEnsureInputFocus) {
      _suppressEnsureInputFocus = false;
      return;
    }
    _ensureInputFocus();
  }

  String _normalizeShellPayload(String text) {
    final normalized = text.startsWith('!') ? text.substring(1) : text;
    return normalized.trim();
  }

  void _refreshComposerMode(String text) {
    final nextMode = text.startsWith('!')
        ? ChatComposerMode.shell
        : ChatComposerMode.normal;
    if (_mode == nextMode) {
      return;
    }
    _setState(() {
      _mode = nextMode;
    });
  }

  void _scheduleSuggestionQuery() {
    _suggestionDebounce?.cancel();
    _suggestionDebounce = Timer(
      const Duration(milliseconds: 120),
      _refreshSuggestions,
    );
  }

  Future<void> _refreshSuggestions() async {
    if (!mounted) {
      return;
    }

    final value = _controller.value;
    final text = value.text;
    final selectionOffset = value.selection.isValid
        ? value.selection.baseOffset
        : text.length;
    final safeOffset = selectionOffset.clamp(0, text.length).toInt();
    final prefix = text.substring(0, safeOffset);

    final mentionMatch = _mentionTriggerPattern.firstMatch(prefix);
    if (mentionMatch != null && widget.onMentionQuery != null) {
      final query = mentionMatch.group(2) ?? '';
      _activeMentionQuery = query;
      await _loadMentionSuggestions(query);
      return;
    }

    final slashMatch = _slashTriggerPattern.firstMatch(text.trim());
    if (slashMatch != null && widget.onSlashQuery != null) {
      final query = slashMatch.group(1) ?? '';
      _activeSlashQuery = query;
      await _loadSlashSuggestions(query);
      return;
    }

    if (!mounted) {
      return;
    }
    _setState(() {
      _popoverType = ChatComposerPopoverType.none;
      _mentionSuggestions = <ChatComposerMentionSuggestion>[];
      _slashSuggestions = <ChatComposerSlashCommandSuggestion>[];
      _activeSuggestionIndex = 0;
      _isLoadingSuggestions = false;
    });
    _ensureInputFocus();
  }
}
