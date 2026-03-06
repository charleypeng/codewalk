part of '../chat_input_widget.dart';

extension _ChatInputHistoryController on _ChatInputWidgetState {
  bool _shouldDeferArrowKeyToTextField({required bool moveUp}) {
    final selection = _controller.selection;
    if (!selection.isValid) {
      return false;
    }

    if (!selection.isCollapsed) {
      return true;
    }

    final editableTextState = _editableTextState();
    final renderEditable = editableTextState?.renderEditable;
    if (renderEditable == null || !renderEditable.hasSize) {
      return false;
    }

    final currentPosition = TextPosition(
      offset: selection.extentOffset.clamp(0, _controller.text.length).toInt(),
      affinity: selection.affinity,
    );
    final nextPosition = moveUp
        ? renderEditable.getTextPositionAbove(currentPosition)
        : renderEditable.getTextPositionBelow(currentPosition);
    final currentLine = renderEditable.getLineAtOffset(currentPosition);
    final nextLine = renderEditable.getLineAtOffset(nextPosition);
    return currentLine.baseOffset != nextLine.baseOffset ||
        currentLine.extentOffset != nextLine.extentOffset;
  }

  bool _navigateHistoryUp() {
    final history = widget.sentMessageHistory;
    if (history.isEmpty) {
      return false;
    }

    if (_historyIndexFromNewest == null) {
      _historyDraftValue = _controller.value;
      _historyIndexFromNewest = 0;
      _applyHistoryMessage(history.last, caretAtStart: false);
      return true;
    }

    final selectionOffset = _safeSelectionOffset(_controller.value);
    if (selectionOffset > 0) {
      _moveCaretToBoundary(atStart: true);
      return true;
    }

    final nextIndex = _historyIndexFromNewest! + 1;
    if (nextIndex >= history.length) {
      return true;
    }
    _historyIndexFromNewest = nextIndex;
    _applyHistoryMessage(history[history.length - 1 - nextIndex]);
    return true;
  }

  bool _navigateHistoryDown() {
    if (_historyIndexFromNewest == null) {
      return false;
    }

    final selectionOffset = _safeSelectionOffset(_controller.value);
    final textLength = _controller.text.length;
    if (selectionOffset < textLength) {
      _moveCaretToBoundary(atStart: false);
      return true;
    }

    final currentIndex = _historyIndexFromNewest!;
    if (currentIndex == 0) {
      final draft = _historyDraftValue;
      _exitHistoryNavigation(updateDraft: false);
      if (draft != null) {
        _applyTextValue(draft);
      }
      return true;
    }

    final nextIndex = currentIndex - 1;
    final history = widget.sentMessageHistory;
    if (nextIndex >= history.length) {
      return true;
    }
    _historyIndexFromNewest = nextIndex;
    _applyHistoryMessage(history[history.length - 1 - nextIndex]);
    return true;
  }

  void _moveCaretToBoundary({required bool atStart}) {
    final length = _controller.text.length;
    _controller.value = _controller.value.copyWith(
      selection: TextSelection.collapsed(offset: atStart ? 0 : length),
      composing: TextRange.empty,
    );
  }

  void _applyHistoryMessage(String text, {bool caretAtStart = false}) {
    _applyTextValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
          offset: caretAtStart ? 0 : text.length,
        ),
      ),
    );
  }

  void _applyTextValue(TextEditingValue value) {
    _isApplyingHistoryValue = true;
    _controller.value = value.copyWith(composing: TextRange.empty);
    _handleTextChanged(value.text);
    _isApplyingHistoryValue = false;
  }

  void _exitHistoryNavigation({required bool updateDraft}) {
    if (_historyIndexFromNewest == null && _historyDraftValue == null) {
      return;
    }
    if (updateDraft) {
      _historyDraftValue = _controller.value;
    }
    _historyIndexFromNewest = null;
  }
}
