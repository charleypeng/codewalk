part of '../chat_input_widget.dart';

extension _ChatInputCommandsController on _ChatInputWidgetState {
  Future<void> _applySlashSuggestion(
    ChatComposerSlashCommandSuggestion suggestion,
  ) async {
    if (suggestion.isBuiltin && widget.onBuiltinSlashCommand != null) {
      final handled = await widget.onBuiltinSlashCommand!(suggestion.name);
      if (handled) {
        _setState(() {
          _popoverType = ChatComposerPopoverType.none;
          _slashSuggestions = <ChatComposerSlashCommandSuggestion>[];
          _activeSuggestionIndex = 0;
          _controller.clear();
          _isComposing = false;
        });
        return;
      }
    }

    final replacement = '/${suggestion.name} ';
    _controller.value = TextEditingValue(
      text: replacement,
      selection: TextSelection.collapsed(offset: replacement.length),
    );
    _setState(() {
      _isComposing = replacement.trim().isNotEmpty;
      _popoverType = ChatComposerPopoverType.none;
      _slashSuggestions = <ChatComposerSlashCommandSuggestion>[];
      _activeSuggestionIndex = 0;
    });
    _effectiveFocusNode.requestFocus();
  }
}
