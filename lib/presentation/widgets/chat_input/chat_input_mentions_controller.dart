part of '../chat_input_widget.dart';

extension _ChatInputMentionsController on _ChatInputWidgetState {
  Future<void> _applyActiveSuggestion() async {
    if (!mounted || _activeSuggestionsCount == 0) {
      return;
    }

    switch (_popoverType) {
      case ChatComposerPopoverType.mention:
        final suggestion = _mentionSuggestions[_activeSuggestionIndex];
        _applyMentionSuggestion(suggestion);
        return;
      case ChatComposerPopoverType.slash:
        final suggestion = _slashSuggestions[_activeSuggestionIndex];
        await _applySlashSuggestion(suggestion);
        return;
      case ChatComposerPopoverType.none:
        return;
    }
  }

  void _applyMentionSuggestion(ChatComposerMentionSuggestion suggestion) {
    final value = _controller.value;
    final text = value.text;
    final selectionOffset = value.selection.isValid
        ? value.selection.baseOffset
        : text.length;
    final safeOffset = selectionOffset.clamp(0, text.length).toInt();
    final prefix = text.substring(0, safeOffset);
    final match = _mentionTriggerPattern.firstMatch(prefix);
    if (match == null) {
      return;
    }
    final fullMatch = match.group(0) ?? '';
    final mentionStart = safeOffset - fullMatch.length;
    final replacementPrefix = '${match.group(1) ?? ''}@${suggestion.value} ';
    final suffix = text.substring(safeOffset).replaceFirst(RegExp(r'^\s+'), '');
    final nextText =
        '${text.substring(0, mentionStart)}$replacementPrefix$suffix';
    final nextOffset = mentionStart + replacementPrefix.length;

    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );

    _setState(() {
      _isComposing = nextText.trim().isNotEmpty;
      _popoverType = ChatComposerPopoverType.none;
      _mentionSuggestions = <ChatComposerMentionSuggestion>[];
      _activeSuggestionIndex = 0;
    });
    _effectiveFocusNode.requestFocus();
  }

  List<RegExpMatch> _extractMentionTokens(String text) {
    return _mentionTokenPattern.allMatches(text).toList(growable: false);
  }
}
