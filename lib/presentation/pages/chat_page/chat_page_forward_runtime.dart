part of '../chat_page.dart';

/// Forward-message runtime: keyboard shortcut, message-tap tracking, dialog
/// invocation, and the success/undo snackbar.
///
/// The forward flow is intentionally side-effect free outside of the
/// `_lastForwardedMessageId` tracker and the `ForwardMessageService` it
/// drives — every side effect (send, undo) is funnelled through
/// [ForwardMessageService] so that the chat-page layer never reaches
/// into the data layer directly.
extension _ChatPageForwardRuntime on _ChatPageState {
  /// Returns true if the message can be forwarded. v1 only allows
  /// assistant and user messages; tool/system parts are filtered at the
  /// text-extraction step. A message with no forwardable text is
  /// rejected so the user does not see a "Forward" button that would
  /// send an empty body.
  bool _canForwardMessage(ChatMessage message) {
    if (message is UserMessage) {
      return _extractForwardableText(message).isNotEmpty;
    }
    if (message is AssistantMessage) {
      return _extractForwardableText(message).isNotEmpty;
    }
    return false;
  }

  /// Track the last message the user interacted with (tapped, focused,
  /// or triggered the forward button on) so the Ctrl/Cmd+Shift+F
  /// keyboard shortcut can target it. The fields live on the page state
  /// because Dart extensions cannot declare instance fields.

  void _recordForwardTarget(ChatMessage message) {
    _lastForwardedMessageId = message.id;
    _lastForwardedMessage = message;
  }

  /// Resolves the message the keyboard shortcut should forward. Falls
  /// back to the most recent assistant or user message visible in the
  /// current session when no explicit tap has been recorded.
  ChatMessage? _resolveShortcutForwardTarget(ChatProvider chatProvider) {
    final stored = _lastForwardedMessage;
    final storedId = _lastForwardedMessageId;
    if (stored != null && storedId != null) {
      for (final msg in chatProvider.messages) {
        if (msg.id == storedId) return msg;
      }
    }
    for (final msg in chatProvider.messages.reversed) {
      if (_canForwardMessage(msg)) return msg;
    }
    return null;
  }

  /// Opens the forward dialog for the given message. The dialog is
  /// scoped to the active server's open projects; see the class-level
  /// note in [ForwardMessageService] for cross-server constraints.
  Future<void> _openForwardDialog(ChatMessage message) async {
    if (!_isChatScreenActive()) return;
    _recordForwardTarget(message);

    final chatProvider = _chatProvider ?? context.read<ChatProvider>();
    final projectProvider = context.read<ProjectProvider>();
    final appProvider = context.read<AppProvider>();

    final selection = _resolveForwardSelection(chatProvider, message);
    if (selection == null) {
      _showChatPageMessageSnackBar(
        context.l10n.forwardNoProviderModel,
      );
      return;
    }

    final forwardService = ForwardMessageService(
      getChatSessions: di.sl(),
      getChatMessages: di.sl(),
      sendChatMessage: di.sl(),
      revertChatMessage: di.sl(),
      projectProvider: projectProvider,
      appProvider: appProvider,
    );

    final originLabel = _composeOriginLabel(
      chatProvider: chatProvider,
      projectProvider: projectProvider,
    );

    final messenger = ScaffoldMessenger.of(context);
    final result = await ForwardMessageDialog.show(
      context: context,
      message: message,
      forwardService: forwardService,
      selection: selection,
      originLabel: originLabel,
    );

    if (!mounted) return;
    if (result == null) return;
    await _handleForwardResult(
      result: result,
      forwardService: forwardService,
      messenger: messenger,
    );
  }

  Future<void> _handleForwardResult({
    required ForwardResult result,
    required ForwardMessageService forwardService,
    required ScaffoldMessengerState messenger,
  }) async {
    if (result.isFullSuccess) {
      messenger.showSnackBar(
        _buildSuccessSnackBar(
          count: result.successes.length,
          undoEntries: result.successes,
          forwardService: forwardService,
        ),
      );
      return;
    }
    if (result.successes.isEmpty) {
      _showChatPageSnackBar(
        content: Text(context.l10n.forwardAllFailed),
      );
      return;
    }
    messenger.showSnackBar(
      _buildPartialSnackBar(
        successes: result.successes,
        failures: result.failures,
        provenanceLine: result.provenanceLine,
        forwardService: forwardService,
      ),
    );
  }

  SnackBar _buildSuccessSnackBar({
    required int count,
    required List<UndoForwardEntry> undoEntries,
    required ForwardMessageService forwardService,
  }) {
    return SnackBar(
      content: Text(context.l10n.forwardSuccess(count)),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: context.l10n.forwardUndo,
        onPressed: () => _runUndo(undoEntries, forwardService),
      ),
    );
  }

  SnackBar _buildPartialSnackBar({
    required List<UndoForwardEntry> successes,
    required List<ForwardFailure> failures,
    required String provenanceLine,
    required ForwardMessageService forwardService,
  }) {
    final total = successes.length + failures.length;
    final retryable = failures
        .where((f) => f.reason == ForwardFailureReason.send)
        .toList(growable: false);
    return SnackBar(
      content: Text(context.l10n.forwardPartial(successes.length, total)),
      duration: const Duration(seconds: 8),
      action: retryable.isEmpty
          ? null
          : SnackBarAction(
              label: context.l10n.forwardRetry,
              onPressed: () => _runRetry(retryable, provenanceLine, forwardService),
            ),
    );
  }

  Future<void> _runUndo(
    List<UndoForwardEntry> entries,
    ForwardMessageService forwardService,
  ) async {
    final failed = await forwardService.undoForward(entries);
    if (!mounted) return;
    if (failed.isEmpty) return;
    _showChatPageSnackBar(
      content: Text(context.l10n.forwardUndoFailed),
    );
  }

  Future<void> _runRetry(
    List<ForwardFailure> failures,
    String provenanceLine,
    ForwardMessageService forwardService,
  ) async {
    final targets = failures
        .where((f) => f.reason == ForwardFailureReason.send)
        .map((f) => f.target)
        .toList(growable: false);
    if (targets.isEmpty) return;
    final chatProvider = _chatProvider ?? context.read<ChatProvider>();
    final selection = _resolveForwardSelection(
      chatProvider,
      _lastForwardedMessage,
    );
    if (selection == null) return;
    final text = _extractForwardableText(_lastForwardedMessage);
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await forwardService.forwardToSessions(
      text: text,
      provenanceLine: provenanceLine,
      targets: targets,
      selection: selection,
    );
    if (!mounted) return;
    await _handleForwardResult(
      result: result,
      forwardService: forwardService,
      messenger: messenger,
    );
  }

  ForwardSelection? _resolveForwardSelection(
    ChatProvider chatProvider,
    ChatMessage? message,
  ) {
    final providerId = message is AssistantMessage
        ? message.providerId
        : null;
    final modelId = message is AssistantMessage ? message.modelId : null;
    final variant = message is AssistantMessage ? message.variant : null;
    final mode = message is AssistantMessage ? message.mode : null;
    final effectiveProviderId = (providerId != null && providerId.isNotEmpty)
        ? providerId
        : chatProvider.selectedProviderId;
    final effectiveModelId = (modelId != null && modelId.isNotEmpty)
        ? modelId
        : chatProvider.selectedModelId;
    if (effectiveProviderId == null ||
        effectiveProviderId.isEmpty ||
        effectiveModelId == null ||
        effectiveModelId.isEmpty) {
      return null;
    }
    return ForwardSelection(
      providerId: effectiveProviderId,
      modelId: effectiveModelId,
      variant: (variant != null && variant.isNotEmpty) ? variant : null,
      mode: (mode != null && mode.isNotEmpty) ? mode : null,
    );
  }

  String _composeOriginLabel({
    required ChatProvider chatProvider,
    required ProjectProvider projectProvider,
  }) {
    final session = chatProvider.currentSession;
    final project = projectProvider.currentProject;
    final sessionTitle = session?.title?.trim();
    if (sessionTitle != null && sessionTitle.isNotEmpty && project != null) {
      return '${project.name} / $sessionTitle';
    }
    if (sessionTitle != null && sessionTitle.isNotEmpty) return sessionTitle;
    if (project != null) return project.name;
    return 'CodeWalk';
  }

  String _extractForwardableText(ChatMessage? message) {
    if (message == null) return '';
    return message.parts
        .whereType<TextPart>()
        .map((part) => part.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n\n');
  }
}
