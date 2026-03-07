import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/di/injection_container.dart' as di;
import '../../core/logging/app_logger.dart';
import '../../data/datasources/app_local_datasource.dart';
import '../../domain/entities/canned_answer.dart';
import '../../domain/entities/chat_composer_draft.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/experience_settings.dart';
import '../providers/settings_provider.dart';
import '../services/speech_input_service.dart';
import '../theme/app_shapes.dart';
import '../services/speech_input_service_sherpa.dart';
import '../services/speech_input_service_stt.dart';
import 'sherpa_model_download_dialog.dart';

part 'chat_input_widget_types_part.dart';
part 'chat_input/chat_input_state_machine.dart';
part 'chat_input/chat_input_history_controller.dart';
part 'chat_input/chat_input_mentions_controller.dart';
part 'chat_input/chat_input_commands_controller.dart';
part 'chat_input/chat_input_suggestion_popover.dart';
part 'chat_input/chat_input_attachment_controller.dart';
part 'chat_input/chat_input_send_controller.dart';
part 'chat_input/chat_input_speech_controller.dart';
part 'chat_input/chat_input_canned_controller.dart';

enum ChatComposerMode { normal, shell }

enum ChatComposerSuggestionType { file, agent }

enum ChatComposerPopoverType { none, mention, slash, canned }

class ChatInputController {
  _ChatInputWidgetState? _state;

  bool get canOpenAttachmentOptions =>
      _state?._canOpenAttachmentOptions ?? false;

  bool get hasDraftContent => _state?._hasDraftContent ?? false;

  bool get canToggleVoiceInput => _state?._canToggleVoiceInput ?? false;

  void openAttachmentOptions() {
    _state?._openAttachmentOptionsFromExternal();
  }

  void focusInput() {
    _state?._focusInputFromExternal();
  }

  Future<void> toggleVoiceInput() async {
    if (!canToggleVoiceInput) {
      return;
    }
    await _state?._toggleVoiceInputFromExternal();
  }

  void _attach(_ChatInputWidgetState state) {
    _state = state;
  }

  void _detach(_ChatInputWidgetState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }
}

class ChatInputSubmission {
  const ChatInputSubmission({
    required this.text,
    required this.attachments,
    required this.mode,
  });

  final String text;
  final List<FileInputPart> attachments;
  final ChatComposerMode mode;
}

class ChatComposerMentionSuggestion {
  const ChatComposerMentionSuggestion({
    required this.value,
    required this.type,
    this.subtitle,
  });

  final String value;
  final ChatComposerSuggestionType type;
  final String? subtitle;
}

class ChatComposerSlashCommandSuggestion {
  const ChatComposerSlashCommandSuggestion({
    required this.name,
    required this.source,
    this.description,
    this.isBuiltin = false,
  });

  final String name;
  final String source;
  final String? description;
  final bool isBuiltin;
}

@visibleForTesting
Color microphoneButtonBackgroundColor({
  required bool isListening,
  required ColorScheme colorScheme,
}) {
  return isListening ? colorScheme.error : Colors.transparent;
}

@visibleForTesting
Color microphoneButtonForegroundColor({
  required bool isListening,
  required ColorScheme colorScheme,
}) {
  return isListening ? colorScheme.onError : colorScheme.onSecondaryContainer;
}

ButtonStyle composerAttachButtonStyle({
  required ColorScheme colorScheme,
  VisualDensity visualDensity = VisualDensity.standard,
}) {
  return IconButton.styleFrom(
    foregroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
    disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(
      alpha: 0.38,
    ),
    backgroundColor: Colors.transparent,
    disabledBackgroundColor: Colors.transparent,
    overlayColor: Colors.transparent,
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,
    minimumSize: const Size(36, 36),
    maximumSize: const Size(36, 36),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: visualDensity,
  );
}

@visibleForTesting
Color resolveComposerBubbleColor({
  required Color preferredColor,
  required Color surfaceColor,
  required Color fallbackOverlayColor,
  required double minLuminanceDelta,
}) {
  final preferredLuminanceDelta =
      (preferredColor.computeLuminance() - surfaceColor.computeLuminance())
          .abs();
  if (preferredLuminanceDelta >= minLuminanceDelta) {
    return preferredColor;
  }

  final fallbackColor = Color.alphaBlend(fallbackOverlayColor, surfaceColor);
  final fallbackLuminanceDelta =
      (fallbackColor.computeLuminance() - surfaceColor.computeLuminance())
          .abs();
  if (fallbackLuminanceDelta >= minLuminanceDelta) {
    return fallbackColor;
  }

  final fallbackAlpha = fallbackOverlayColor.a;
  final boostedFallbackAlpha = (fallbackAlpha * 1.5).clamp(0.0, 1.0).toDouble();
  return Color.alphaBlend(
    fallbackOverlayColor.withValues(alpha: boostedFallbackAlpha),
    surfaceColor,
  );
}

@visibleForTesting
({String leadingText, String trailingText}) splitComposerTextAtSelection(
  TextEditingValue value,
) {
  final text = value.text;
  final length = text.length;
  if (!value.selection.isValid) {
    return (leadingText: text, trailingText: '');
  }
  final start = value.selection.start.clamp(0, length).toInt();
  final end = value.selection.end.clamp(0, length).toInt();
  final from = math.min(start, end);
  final to = math.max(start, end);
  return (
    leadingText: text.substring(0, from),
    trailingText: text.substring(to),
  );
}

@visibleForTesting
TextEditingValue composeComposerValueWithSuffix({
  required String leadingText,
  required String trailingText,
}) {
  final text = '$leadingText$trailingText';
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: leadingText.length),
  );
}

/// Chat input widget
class ChatInputWidget extends StatefulWidget {
  const ChatInputWidget({
    super.key,
    required this.onSendMessage,
    this.sentMessageHistory = const <String>[],
    this.prefilledDraft,
    this.prefilledDraftVersion = 0,
    this.onMentionQuery,
    this.onSlashQuery,
    this.onBuiltinSlashCommand,
    this.enabled = true,
    this.isResponding = false,
    this.onStopRequested,
    this.onStopHintRequested,
    this.focusNode,
    this.showAttachmentButton = false,
    this.showInlineAttachmentButton = true,
    this.allowImageAttachment = true,
    this.allowPdfAttachment = true,
    this.controller,
    this.cannedAnswersDataSource,
    this.cannedAnswersServerId,
    this.cannedAnswersScopeId,
    this.contextItems = const <FileInputPart>[],
    this.onRemoveContextItem,
  });

  final FutureOr<void> Function(ChatInputSubmission submission) onSendMessage;
  final List<String> sentMessageHistory;
  final ChatComposerDraft? prefilledDraft;
  final int prefilledDraftVersion;
  final Future<List<ChatComposerMentionSuggestion>> Function(String query)?
  onMentionQuery;
  final Future<List<ChatComposerSlashCommandSuggestion>> Function(String query)?
  onSlashQuery;
  final FutureOr<bool> Function(String commandName)? onBuiltinSlashCommand;
  final bool enabled;
  final bool isResponding;
  final FutureOr<void> Function()? onStopRequested;
  final VoidCallback? onStopHintRequested;
  final FocusNode? focusNode;
  final bool showAttachmentButton;
  final bool showInlineAttachmentButton;
  final bool allowImageAttachment;
  final bool allowPdfAttachment;
  final ChatInputController? controller;
  final AppLocalDataSource? cannedAnswersDataSource;
  final String? cannedAnswersServerId;
  final String? cannedAnswersScopeId;
  // File line references added as context for the next message.
  final List<FileInputPart> contextItems;
  final void Function(int index)? onRemoveContextItem;

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  static const double _inputRowHeight = 52;
  static const double _popoverInputHeightMultiplier = 3;
  static const int _composerMaxLines = 6;
  static const double _composerActionButtonSize = 42;
  static const Duration _doubleEscapeStopThreshold = Duration(
    milliseconds: 500,
  );
  final TextEditingController _controller = TextEditingController();
  final FocusNode _internalFocusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey(debugLabel: 'composer_text_field');
  final List<FileInputPart> _attachments = <FileInputPart>[];
  final RegExp _mentionTriggerPattern = RegExp(r'(^|\s)@([^\s@]*)$');
  final RegExp _slashTriggerPattern = RegExp(r'^/(\S*)$');
  final RegExp _mentionTokenPattern = RegExp(r'@([^\s@]+)');
  // STT services are resolved lazily. The active backend is selected from
  // settings (Native/Sherpa) and can fall back automatically when unavailable.
  SpeechInputService? _activeSpeechService;
  SttSpeechInputService? _nativeSpeechServiceInstance;
  SherpaSpeechInputService? _sherpaSpeechServiceInstance;
  bool _isComposing = false;
  bool _isSending = false;
  bool _isListening = false;
  bool _isStartingListening = false;
  bool _isLoadingSuggestions = false;
  ChatComposerMode _mode = ChatComposerMode.normal;
  ChatComposerPopoverType _popoverType = ChatComposerPopoverType.none;
  List<ChatComposerMentionSuggestion> _mentionSuggestions =
      <ChatComposerMentionSuggestion>[];
  List<ChatComposerSlashCommandSuggestion> _slashSuggestions =
      <ChatComposerSlashCommandSuggestion>[];
  List<CannedAnswer> _globalCannedAnswers = <CannedAnswer>[];
  List<CannedAnswer> _projectCannedAnswers = <CannedAnswer>[];
  int _activeSuggestionIndex = 0;
  String _activeMentionQuery = '';
  String _activeSlashQuery = '';
  String _speechPrefix = '';
  String _speechSuffix = '';
  String _speechCommittedText = '';
  Timer? _sendHoldTimer;
  Timer? _suggestionDebounce;
  Timer? _speechStartWatchdog;
  DateTime? _lastSecondarySendActionAt;
  bool _holdSendTriggered = false;
  int? _historyIndexFromNewest;
  TextEditingValue? _historyDraftValue;
  bool _isApplyingHistoryValue = false;
  bool _suppressEnsureInputFocus = false;
  DateTime? _lastNormalModeEscapeAt;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  bool get _hasDraftContent =>
      _controller.text.trim().isNotEmpty ||
      _attachments.isNotEmpty ||
      widget.contextItems.isNotEmpty;

  bool get _canToggleVoiceInput => widget.enabled && !_isStartingListening;

  bool get _isDesktopPlatform {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  bool get _isNativeEngineSupported {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform != TargetPlatform.linux;
  }

  bool get _isSherpaEngineSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform != TargetPlatform.android;
  }

  bool get _isSoftwareKeyboardVisible {
    final mediaQueryInsetBottom = MediaQuery.maybeOf(
      context,
    )?.viewInsets.bottom;
    final viewInsetBottom = View.maybeOf(context)?.viewInsets.bottom;
    return (mediaQueryInsetBottom ?? 0) > 0 || (viewInsetBottom ?? 0) > 0;
  }

  bool get _shouldHideKeyboardAfterSend =>
      !_isDesktopPlatform && _isSoftwareKeyboardVisible;

  SpeechInputService get _nativeSpeechService =>
      _nativeSpeechServiceInstance ??= di.sl<SttSpeechInputService>();

  SpeechInputService? get _sherpaSpeechService {
    if (kIsWeb) {
      return null;
    }
    return _sherpaSpeechServiceInstance ??= di.sl<SherpaSpeechInputService>();
  }

  SpeechInputService get _speechService =>
      _activeSpeechService ?? _nativeSpeechService;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    unawaited(_loadCannedAnswers());
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _sendHoldTimer?.cancel();
    _suggestionDebounce?.cancel();
    _speechStartWatchdog?.cancel();
    unawaited(_activeSpeechService?.stopListening() ?? Future.value());
    _controller.dispose();
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.cannedAnswersServerId != widget.cannedAnswersServerId ||
        oldWidget.cannedAnswersScopeId != widget.cannedAnswersScopeId) {
      unawaited(_loadCannedAnswers());
    }
    if (widget.prefilledDraftVersion != oldWidget.prefilledDraftVersion) {
      final prefilledDraft = widget.prefilledDraft;
      if (prefilledDraft != null && prefilledDraft.hasContent) {
        _exitHistoryNavigation(updateDraft: false);
        _historyDraftValue = null;
        _suppressEnsureInputFocus = true;

        var prefilledText = prefilledDraft.text.trim();
        if (prefilledDraft.shellMode &&
            prefilledText.isNotEmpty &&
            !prefilledText.startsWith('!')) {
          prefilledText = '!$prefilledText';
        }

        final restoredAttachments = prefilledDraft.shellMode
            ? const <FileInputPart>[]
            : prefilledDraft.attachments
                  .where((attachment) => _isMimeAllowed(attachment.mime))
                  .toList(growable: false);

        setState(() {
          _mode = prefilledDraft.shellMode && prefilledText.isNotEmpty
              ? ChatComposerMode.shell
              : ChatComposerMode.normal;
          _attachments
            ..clear()
            ..addAll(restoredAttachments);
        });

        _applyHistoryMessage(prefilledText);
      }
    }
    if (!listEquals(oldWidget.sentMessageHistory, widget.sentMessageHistory)) {
      _exitHistoryNavigation(updateDraft: false);
      _historyDraftValue = null;
    }
    if (!widget.showAttachmentButton && _attachments.isNotEmpty) {
      setState(_attachments.clear);
      return;
    }

    if (_attachments.isEmpty) {
      return;
    }

    final filtered = _attachments
        .where((attachment) => _isMimeAllowed(attachment.mime))
        .toList(growable: false);
    if (filtered.length != _attachments.length) {
      setState(() {
        _attachments
          ..clear()
          ..addAll(filtered);
      });
    }
  }

  void _ensureInputFocus() {
    if (!widget.enabled) {
      return;
    }
    if (!_effectiveFocusNode.hasFocus) {
      _effectiveFocusNode.requestFocus();
    }
  }

  void _setState(VoidCallback fn) {
    setState(fn);
  }

  int get _activeSuggestionsCount {
    switch (_popoverType) {
      case ChatComposerPopoverType.mention:
        return _mentionSuggestions.length;
      case ChatComposerPopoverType.slash:
        return _slashSuggestions.length;
      case ChatComposerPopoverType.canned:
        return _visibleCannedAnswers.length;
      case ChatComposerPopoverType.none:
        return 0;
    }
  }

  Future<void> _loadMentionSuggestions(String query) async {
    final loader = widget.onMentionQuery;
    if (loader == null) {
      return;
    }
    setState(() {
      _isLoadingSuggestions = true;
      _popoverType = ChatComposerPopoverType.mention;
    });
    try {
      final suggestions = await loader(query);
      if (!mounted || query != _activeMentionQuery) {
        return;
      }
      setState(() {
        _mentionSuggestions = suggestions;
        _activeSuggestionIndex = 0;
        _popoverType = suggestions.isEmpty
            ? ChatComposerPopoverType.none
            : ChatComposerPopoverType.mention;
      });
      _ensureInputFocus();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
        _ensureInputFocus();
      }
    }
  }

  Future<void> _loadSlashSuggestions(String query) async {
    final loader = widget.onSlashQuery;
    if (loader == null) {
      return;
    }
    setState(() {
      _isLoadingSuggestions = true;
      _popoverType = ChatComposerPopoverType.slash;
    });
    try {
      final suggestions = await loader(query);
      if (!mounted || query != _activeSlashQuery) {
        return;
      }
      setState(() {
        _slashSuggestions = suggestions;
        _activeSuggestionIndex = 0;
        _popoverType = suggestions.isEmpty
            ? ChatComposerPopoverType.none
            : ChatComposerPopoverType.slash;
      });
      _ensureInputFocus();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
        _ensureInputFocus();
      }
    }
  }

  KeyEventResult _handleInputKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final logicalKey = event.logicalKey;
    final hasPopover = _popoverType != ChatComposerPopoverType.none;

    if (hasPopover && _activeSuggestionsCount > 0) {
      if (logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _activeSuggestionIndex =
              (_activeSuggestionIndex + 1) % _activeSuggestionsCount;
        });
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _activeSuggestionIndex =
              (_activeSuggestionIndex - 1 + _activeSuggestionsCount) %
              _activeSuggestionsCount;
        });
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.enter ||
          logicalKey == LogicalKeyboardKey.tab) {
        unawaited(_applyActiveSuggestion());
        return KeyEventResult.handled;
      }
    }

    if (logicalKey == LogicalKeyboardKey.escape) {
      if (hasPopover) {
        _closePopover();
        return KeyEventResult.handled;
      }
      if (_mode == ChatComposerMode.shell) {
        setState(() {
          _mode = ChatComposerMode.normal;
          _controller.clear();
          _isComposing = false;
        });
        return KeyEventResult.handled;
      }
      if (_mode == ChatComposerMode.normal) {
        if (widget.isResponding && widget.onStopRequested != null) {
          final now = DateTime.now();
          // Require two quick Esc presses to mirror explicit stop-button intent.
          final shouldStop =
              _lastNormalModeEscapeAt != null &&
              now.difference(_lastNormalModeEscapeAt!) <=
                  _doubleEscapeStopThreshold;
          _lastNormalModeEscapeAt = now;
          widget.onStopHintRequested?.call();
          if (shouldStop) {
            unawaited(_requestStopResponse());
          }
          return KeyEventResult.handled;
        }
        _lastNormalModeEscapeAt = null;
        return KeyEventResult.handled;
      }
    }

    if (logicalKey == LogicalKeyboardKey.backspace &&
        _mode == ChatComposerMode.shell) {
      final normalized = _normalizeShellPayload(_controller.text);
      if (normalized.isEmpty) {
        setState(() {
          _mode = ChatComposerMode.normal;
          _controller.clear();
          _isComposing = false;
        });
        return KeyEventResult.handled;
      }
    }

    if (hasPopover) {
      return KeyEventResult.ignored;
    }

    if (_isDesktopPlatform && logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_hasArrowNavigationModifierPressed() ||
          _shouldDeferArrowKeyToTextField(moveUp: true)) {
        return KeyEventResult.ignored;
      }
      if (_navigateHistoryUp()) {
        return KeyEventResult.handled;
      }
    }

    if (_isDesktopPlatform && logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_hasArrowNavigationModifierPressed() ||
          _shouldDeferArrowKeyToTextField(moveUp: false)) {
        return KeyEventResult.ignored;
      }
      if (_navigateHistoryDown()) {
        return KeyEventResult.handled;
      }
    }

    if (_isDesktopPlatform && logicalKey == LogicalKeyboardKey.enter) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _insertComposerNewline();
        return KeyEventResult.handled;
      }
      unawaited(_handleSendMessage());
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _requestStopResponse() async {
    if (!widget.enabled || _isSending || !widget.isResponding) {
      return;
    }
    final stopRequested = widget.onStopRequested;
    if (stopRequested == null) {
      return;
    }
    await Future<void>.sync(stopRequested);
  }

  int _safeSelectionOffset(TextEditingValue value) {
    final length = value.text.length;
    if (!value.selection.isValid) {
      return length;
    }
    return value.selection.baseOffset.clamp(0, length).toInt();
  }

  bool _hasArrowNavigationModifierPressed() {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isAltPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isShiftPressed;
  }

  EditableTextState? _editableTextState() {
    final context = _textFieldKey.currentContext;
    if (context == null) {
      return null;
    }

    EditableTextState? result;

    void visit(Element element) {
      if (result != null) {
        return;
      }
      if (element is StatefulElement && element.state is EditableTextState) {
        result = element.state as EditableTextState;
        return;
      }
      element.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    return result;
  }

  void _closePopover() {
    setState(() {
      _popoverType = ChatComposerPopoverType.none;
      _mentionSuggestions = <ChatComposerMentionSuggestion>[];
      _slashSuggestions = <ChatComposerSlashCommandSuggestion>[];
      _activeSuggestionIndex = 0;
    });
  }

  Widget _buildComposerPopover({
    required ColorScheme colorScheme,
    required double maxHeight,
  }) {
    if (_popoverType == ChatComposerPopoverType.canned) {
      return _buildCannedAnswersPopover(
        colorScheme: colorScheme,
        maxHeight: maxHeight,
      );
    }
    return _buildSuggestionPopover(
      colorScheme: colorScheme,
      maxHeight: maxHeight,
    );
  }

  IconData _mentionIconForToken(String value) {
    if (value.contains('/') || value.contains('.')) {
      return Symbols.insert_drive_file;
    }
    return Symbols.smart_toy;
  }

  String _composerHintText() {
    if (_mode == ChatComposerMode.shell) {
      return 'Shell command (Esc to exit)';
    }
    return 'Type your needs...';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attachButtonStyle = composerAttachButtonStyle(
      colorScheme: colorScheme,
    );
    final mentionTokens = _extractMentionTokens(_controller.text);
    final showAttachments =
        _attachments.isNotEmpty && _mode == ChatComposerMode.normal;
    final hasSendPayload =
        (_isComposing ||
        ((_attachments.isNotEmpty || widget.contextItems.isNotEmpty) &&
            _mode == ChatComposerMode.normal));
    final canSend = hasSendPayload && widget.enabled && !_isSending;
    final showStopAction = widget.isResponding && !hasSendPayload;
    final sendSemanticsLabel = showStopAction
        ? 'Stop response'
        : (widget.isResponding
              ? 'Send message while response is running'
              : 'Send message');
    final showPopover = _popoverType != ChatComposerPopoverType.none;
    const composerBackgroundColor = Colors.transparent;
    final normalBubblePreferredColor = Color.alphaBlend(
      colorScheme.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.94 : 0.96,
      ),
      colorScheme.surface,
    );
    final normalBubbleFallbackOverlayColor = colorScheme.onSurface.withValues(
      alpha: isDark ? 0.12 : 0.035,
    );
    final normalBubbleColor = resolveComposerBubbleColor(
      preferredColor: normalBubblePreferredColor,
      surfaceColor: colorScheme.surface,
      fallbackOverlayColor: normalBubbleFallbackOverlayColor,
      minLuminanceDelta: isDark ? 0.03 : 0.015,
    );
    final shellBubblePreferredColor = Color.alphaBlend(
      colorScheme.tertiaryContainer.withValues(alpha: isDark ? 0.6 : 0.84),
      colorScheme.surface,
    );
    final shellBubbleColor = resolveComposerBubbleColor(
      preferredColor: shellBubblePreferredColor,
      surfaceColor: colorScheme.surface,
      fallbackOverlayColor: colorScheme.tertiary.withValues(
        alpha: isDark ? 0.24 : 0.16,
      ),
      minLuminanceDelta: isDark ? 0.03 : 0.015,
    );
    final inputBubbleColor = _mode == ChatComposerMode.shell
        ? shellBubbleColor
        : normalBubbleColor;
    final inputBubbleBorderRadius = AppShapes.borderExtraLarge;

    return Container(
      key: const ValueKey<String>('composer_root_container'),
      decoration: const BoxDecoration(color: composerBackgroundColor),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_mode == ChatComposerMode.shell)
              Padding(
                key: const ValueKey<String>('composer_shell_mode_row'),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    key: const ValueKey<String>('composer_shell_mode_chip'),
                    avatar: const Icon(Symbols.terminal_rounded, size: 16),
                    label: const Text('Shell mode'),
                    onDeleted: widget.enabled
                        ? () {
                            setState(() {
                              _mode = ChatComposerMode.normal;
                              _controller.clear();
                              _isComposing = false;
                            });
                          }
                        : null,
                  ),
                ),
              ),
            if (mentionTokens.isNotEmpty)
              Padding(
                key: const ValueKey<String>('composer_mention_tokens_row'),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mentionTokens
                        .map((token) {
                          final value = token.group(1) ?? '';
                          return InputChip(
                            key: ValueKey<String>('mention_token_$value'),
                            avatar: Icon(_mentionIconForToken(value), size: 16),
                            label: Text('@$value'),
                            onDeleted: widget.enabled
                                ? () {
                                    final start = token.start;
                                    final end = token.end;
                                    final current = _controller.text;
                                    if (start < 0 || end > current.length) {
                                      return;
                                    }
                                    final nextText = current.replaceRange(
                                      start,
                                      end,
                                      '',
                                    );
                                    _controller.value = TextEditingValue(
                                      text: nextText,
                                      selection: TextSelection.collapsed(
                                        offset: start.clamp(0, nextText.length),
                                      ),
                                    );
                                    _handleTextChanged(nextText);
                                  }
                                : null,
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ),
            if (showAttachments)
              Padding(
                key: const ValueKey<String>('composer_attachments_row'),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List<Widget>.generate(_attachments.length, (index) {
                    final attachment = _attachments[index];
                    return InputChip(
                      avatar: Icon(
                        attachment.mime.startsWith('image/')
                            ? Symbols.image
                            : Symbols.picture_as_pdf,
                        size: 18,
                      ),
                      label: Text(attachment.filename ?? 'attachment'),
                      onDeleted: widget.enabled
                          ? () {
                              setState(() {
                                _attachments.removeAt(index);
                              });
                            }
                          : null,
                    );
                  }),
                ),
              ),
            if (widget.contextItems.isNotEmpty)
              Padding(
                key: const ValueKey<String>('composer_context_items_row'),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List<Widget>.generate(widget.contextItems.length, (
                    index,
                  ) {
                    final item = widget.contextItems[index];
                    final source = item.source;
                    final label = source != null
                        ? '${item.filename}:${source.text.start}-${source.text.end}'
                        : (item.filename ?? 'context');
                    return InputChip(
                      avatar: const Icon(Symbols.code_rounded, size: 16),
                      label: Text(label),
                      onDeleted: widget.enabled
                          ? () => widget.onRemoveContextItem?.call(index)
                          : null,
                    );
                  }),
                ),
              ),
            if (showPopover)
              Padding(
                key: const ValueKey<String>('composer_popover_row'),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: _buildComposerPopover(
                  colorScheme: colorScheme,
                  maxHeight: _popoverMaxHeight(context),
                ),
              ),
            Padding(
              key: const ValueKey<String>('composer_input_row'),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.showAttachmentButton &&
                      widget.showInlineAttachmentButton &&
                      _mode == ChatComposerMode.normal) ...[
                    IconButton(
                      onPressed: widget.enabled ? _showAttachmentOptions : null,
                      tooltip: 'Add attachment',
                      style: attachButtonStyle,
                      icon: const Icon(Symbols.attach_file_rounded),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: _composerActionButtonSize,
                      ),
                      child: DecoratedBox(
                        key: const ValueKey<String>('composer_input_bubble'),
                        decoration: BoxDecoration(
                          color: inputBubbleColor,
                          borderRadius: inputBubbleBorderRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: inputBubbleBorderRadius,
                          child: Focus(
                            onKeyEvent: _handleInputKeyEvent,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: IconButton.filledTonal(
                                    onPressed: widget.enabled
                                        ? _toggleCannedPopover
                                        : null,
                                    tooltip: 'Canned answers',
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(40, 40),
                                      maximumSize: const Size(40, 40),
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: Theme.of(
                                        context,
                                      ).visualDensity,
                                    ),
                                    icon: const Icon(
                                      Symbols.quickreply_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    key: _textFieldKey,
                                    controller: _controller,
                                    focusNode: _effectiveFocusNode,
                                    enabled: widget.enabled,
                                    minLines: 1,
                                    maxLines: _composerMaxLines,
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: _isDesktopPlatform
                                        ? TextInputAction.newline
                                        : TextInputAction.send,
                                    keyboardType: TextInputType.multiline,
                                    onChanged: _handleTextChanged,
                                    onSubmitted: (_) =>
                                        unawaited(_handleSendMessage()),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    decoration: InputDecoration(
                                      hintText: _composerHintText(),
                                      hintStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? colorScheme.onSurface
                                                      .withValues(alpha: 0.72)
                                                : colorScheme.onSurfaceVariant
                                                      .withValues(alpha: 0.88),
                                          ),
                                      isDense: true,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        16,
                                        7,
                                        8,
                                        7,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: IconButton.filledTonal(
                                    onPressed:
                                        widget.enabled && !_isStartingListening
                                        ? () => unawaited(_toggleVoiceInput())
                                        : null,
                                    tooltip: _isStartingListening
                                        ? 'Starting voice input'
                                        : _isListening
                                        ? 'Stop voice input'
                                        : 'Start voice input',
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(40, 40),
                                      maximumSize: const Size(40, 40),
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: Theme.of(
                                        context,
                                      ).visualDensity,
                                      backgroundColor:
                                          microphoneButtonBackgroundColor(
                                            isListening:
                                                _isListening ||
                                                _isStartingListening,
                                            colorScheme: colorScheme,
                                          ),
                                      foregroundColor:
                                          microphoneButtonForegroundColor(
                                            isListening:
                                                _isListening ||
                                                _isStartingListening,
                                            colorScheme: colorScheme,
                                          ),
                                    ),
                                    icon: _isStartingListening
                                        ? const Icon(
                                            Symbols.hourglass_top_rounded,
                                            size: 20,
                                          )
                                        : Icon(
                                            _isListening
                                                ? Symbols.mic_rounded
                                                : Symbols.mic_none_rounded,
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Listener(
                    onPointerDown: (_) =>
                        _handleSendButtonPressStart(canSend: canSend),
                    onPointerUp: (_) => _handleSendButtonPressEnd(),
                    onPointerCancel: (_) => _handleSendButtonPressEnd(),
                    child: Semantics(
                      label: sendSemanticsLabel,
                      button: true,
                      child: SizedBox.square(
                        dimension: _composerActionButtonSize,
                        child: FilledButton(
                          onPressed: showStopAction
                              ? (widget.enabled &&
                                        !_isSending &&
                                        widget.onStopRequested != null
                                    ? () => unawaited(_requestStopResponse())
                                    : null)
                              : (canSend ? _handleSendButtonTap : null),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(
                              _composerActionButtonSize,
                              _composerActionButtonSize,
                            ),
                            maximumSize: const Size(
                              _composerActionButtonSize,
                              _composerActionButtonSize,
                            ),
                            fixedSize: const Size(
                              _composerActionButtonSize,
                              _composerActionButtonSize,
                            ),
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            backgroundColor: showStopAction
                                ? const Color(0xFF424242)
                                : (canSend
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerHighest),
                            foregroundColor: showStopAction
                                ? colorScheme.error
                                : (canSend
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant),
                            elevation: canSend ? 1.5 : 0,
                            shadowColor: colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: Theme.of(context).visualDensity,
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: _composerActionButtonSize,
                                  height: _composerActionButtonSize,
                                  child: Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              : showStopAction
                              ? SizedBox(
                                  width: _composerActionButtonSize,
                                  height: _composerActionButtonSize,
                                  child: Center(
                                    child: Icon(
                                      Symbols.stop_rounded,
                                      size: 24,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: _composerActionButtonSize,
                                  height: _composerActionButtonSize,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      const Align(
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Symbols.send_rounded,
                                          size: 24,
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 3,
                                            bottom: 3,
                                          ),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: canSend
                                                  ? colorScheme.onPrimary
                                                        .withValues(alpha: 0.16)
                                                  : colorScheme
                                                        .primaryContainer,
                                              borderRadius:
                                                  AppShapes.borderFull,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(1),
                                              child: Icon(
                                                Symbols.keyboard_return_rounded,
                                                size: 9,
                                                color: canSend
                                                    ? colorScheme.onPrimary
                                                    : colorScheme
                                                          .onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canOpenAttachmentOptions =>
      widget.showAttachmentButton &&
      widget.enabled &&
      _mode == ChatComposerMode.normal &&
      (widget.allowImageAttachment || widget.allowPdfAttachment);

  void _openAttachmentOptionsFromExternal() {
    if (!_canOpenAttachmentOptions) {
      return;
    }
    _showAttachmentOptions();
  }

  void _startListeningLoading() {
    _speechStartWatchdog?.cancel();
    _speechStartWatchdog = Timer(const Duration(seconds: 12), () {
      if (!mounted) {
        return;
      }
      if (_isStartingListening) {
        setState(() {
          _isStartingListening = false;
        });
      }
    });
    setState(() {
      _isStartingListening = true;
    });
  }

  void _finishListeningLoading() {
    _speechStartWatchdog?.cancel();
    _speechStartWatchdog = null;
    if (!mounted) {
      return;
    }
    if (_isStartingListening) {
      setState(() {
        _isStartingListening = false;
      });
    }
  }

  SpeechInputService? _serviceForEngine(SpeechToTextEngine engine) {
    return switch (engine) {
      SpeechToTextEngine.native =>
        _isNativeEngineSupported ? _nativeSpeechService : null,
      SpeechToTextEngine.sherpa =>
        _isSherpaEngineSupported ? _sherpaSpeechService : null,
    };
  }

  String _speechEngineLabel(SpeechToTextEngine engine) {
    return switch (engine) {
      SpeechToTextEngine.native => 'Native',
      SpeechToTextEngine.sherpa => 'Sherpa',
    };
  }

  String? _localeForService(
    SpeechInputService service,
    SettingsProvider settingsProvider,
  ) {
    if (service is! SherpaSpeechInputService) {
      return null;
    }
    final configured = settingsProvider.sherpaLanguageCode;
    if (configured == kSherpaLanguageSystem) {
      return null;
    }
    return configured;
  }

  // Updates the composer text with new recognized speech, appending to any
  // existing text that was in the field before listening started.

  String _appendSpeechSegment(String base, String addition) {
    if (addition.isEmpty) return base;
    if (base.isEmpty) return addition;
    if (base.endsWith(' ') || base.endsWith('\n')) {
      return '$base$addition';
    }
    return '$base $addition';
  }

  // Shows the Sherpa model download dialog when an on-device model is required,
  // then retries listening after a successful download.
}
