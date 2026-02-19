part of 'chat_provider.dart';

extension _ChatProviderDraftState on ChatProvider {
  void _setActiveSendDraft(
    String draftText, {
    required List<FileInputPart> attachments,
    required bool shellMode,
  }) {
    _clearRejectedDraft();
    final normalizedDraft = draftText.trim();
    final effectiveAttachments = shellMode
        ? const <FileInputPart>[]
        : List<FileInputPart>.unmodifiable(attachments);
    if (normalizedDraft.isEmpty && effectiveAttachments.isEmpty) {
      _activeSendDraft = null;
      return;
    }
    final composerText = shellMode
        ? normalizedDraft.isEmpty
              ? ''
              : '!$normalizedDraft'
        : normalizedDraft;
    _activeSendDraft = ChatComposerDraft(
      text: composerText,
      attachments: effectiveAttachments,
      shellMode: shellMode,
    );
  }

  void _clearActiveSendDraft() {
    _activeSendDraft = null;
  }

  void _clearRejectedDraft() {
    _rejectedDraft = null;
  }

  void _stashRejectedDraftForRetry({String? sessionId}) {
    final draft = _activeSendDraft;
    _activeSendDraft = null;
    if (draft == null || !draft.hasContent) {
      return;
    }
    final effectiveSessionId = sessionId?.trim();
    if (!_isAppInForeground ||
        !_isForegroundActive ||
        !_isChatRouteActive ||
        effectiveSessionId == null ||
        effectiveSessionId.isEmpty) {
      _clearRejectedDraft();
      return;
    }
    _rejectedDraft = _RejectedDraftEnvelope(
      sessionId: effectiveSessionId,
      draft: draft,
    );
  }
}
