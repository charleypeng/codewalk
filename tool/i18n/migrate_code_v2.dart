import 'dart:io';

/// Safe code migrator v2 — replaces hardcoded English UI strings with
/// context.l10n calls. Does NOT touch import lines. Removes const
/// qualifiers where needed. Run after manually adding l10n imports.

final _files = [
  'lib/presentation/pages/chat_page/chat_page_scaffold.dart',
  'lib/presentation/pages/chat_page/chat_page_chrome.dart',
  'lib/presentation/pages/chat_page/chat_page_timeline_builder.dart',
  'lib/presentation/pages/settings_page.dart',
  'lib/presentation/widgets/chat_session_list.dart',
  'lib/presentation/widgets/permission_request_card.dart',
  'lib/presentation/widgets/question_request_card.dart',
  'lib/presentation/widgets/chat_tour_showcase.dart',
  'lib/presentation/widgets/codewalk_terminal_panel.dart',
  'lib/presentation/widgets/chat_input_widget.dart',
  'lib/presentation/widgets/chat_input/chat_input_canned_controller.dart',
  'lib/presentation/widgets/chat_input/chat_input_attachment_controller.dart',
  'lib/presentation/widgets/chat_input/chat_input_speech_controller.dart',
  'lib/presentation/widgets/chat_input/chat_input_state_machine.dart',
  'lib/presentation/widgets/chat_input/chat_input_suggestion_popover.dart',
  'lib/presentation/widgets/chat_message/chat_message_text_part.dart',
  'lib/presentation/widgets/chat_message/chat_message_content.dart',
  'lib/presentation/widgets/chat_message/chat_message_info_parts.dart',
  'lib/presentation/widgets/sherpa_model_download_dialog.dart',
  'lib/presentation/widgets/parakeet_model_download_dialog.dart',
  'lib/presentation/widgets/sensevoice_model_download_dialog.dart',
  'lib/presentation/widgets/moonshine_model_download_dialog.dart',
  'lib/presentation/widgets/quota/quota_popup_section.dart',
  'lib/presentation/widgets/session_title_inline_editor.dart',
  'lib/presentation/services/desktop_tray_service_io.dart',
  'lib/presentation/pages/onboarding_wizard_page.dart',
  'lib/presentation/pages/opencode_setup_debug_page.dart',
  'lib/presentation/pages/logs_page.dart',
  'lib/presentation/pages/chat_page/chat_page_workspace_controller.dart',
  'lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart',
  'lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart',
  'lib/presentation/pages/chat_page/chat_page_status_presenter.dart',
  'lib/presentation/pages/chat_page/chat_page_selector_flow.dart',
  'lib/presentation/pages/chat_page/chat_page_file_runtime.dart',
];

// Map of English string literal -> context.l10n getter
final _map = <String, String>{
  // ── Chat scaffold ────────────────────────────────────────────
  r"'Conversations'": 'context.l10n.chatConversations',
  "'New Chat'": 'context.l10n.chatNewChat',
  "'Refresh'": 'context.l10n.chatRefresh',
  "'Project Context'": 'context.l10n.chatProjectContext',
  "'Hide Conversations sidebar'": 'context.l10n.chatHideConversationsSidebar',
  "'Hide Utility sidebar'": 'context.l10n.chatHideUtilitySidebar',
  "'Filter sessions'": 'context.l10n.chatFilterSessions',
  "'Sort sessions'": 'context.l10n.chatSortSessions',
  "'Active'": 'context.l10n.chatFilterActive',
  "'Archived'": 'context.l10n.chatFilterArchived',
  "'All'": 'context.l10n.chatFilterAll',
  "'Recent'": 'context.l10n.chatSortRecent',
  "'Most Recent'": 'context.l10n.chatSortMostRecent',
  "'Oldest'": 'context.l10n.chatSortOldest',
  "'Title'": 'context.l10n.chatSortTitle',
  "'Search conversations'": 'context.l10n.chatSearchConversations',
  "'Recent sessions'": 'context.l10n.chatRecentSessions',
  "'Load more'": 'context.l10n.chatLoadMore',
  "'Refresh session details'": 'context.l10n.chatRefreshSessionDetails',
  "'Keyboard shortcuts'": 'context.l10n.sessionKeyboardShortcuts',
  r"'Conversation is not available for this project yet'":
      'context.l10n.sessionNotAvailable',

  // ── Chat chrome ──────────────────────────────────────────────
  "'Close'": 'context.l10n.chatClose',
  "'Toggle sidebars'": 'context.l10n.chatToggleSidebars',
  "'Undo last turn'": 'context.l10n.chatUndoLastTurn',
  "'Redo last undone turn'": 'context.l10n.chatRedoLastTurn',
  "'Display toggles'": 'context.l10n.chatDisplayToggles',
  "'Open Files'": 'context.l10n.chatOpenFiles',
  "'New chat'": 'context.l10n.chatNewChatTourTitle',
  r"'Start a new conversation here.'":
      'context.l10n.chatNewChatTourDescription',

  // ── Chat timeline ────────────────────────────────────────────
  r"'No server configured yet'": 'context.l10n.chatNoServerYet',
  r"'Add a server to start chatting.'": 'context.l10n.chatAddServerToStart',
  "'Set up server'": 'context.l10n.chatSetUpServer',
  r"'Select or create a conversation to start chatting'":
      'context.l10n.chatSelectOrCreate',
  "'Hello! I am your AI assistant'": 'context.l10n.chatHelloAssistant',
  "'Keep working'": 'context.l10n.chatKeepWorking',
  "'Retry refresh'": 'context.l10n.chatRetryRefresh',
  "'Use current'": 'context.l10n.chatUseCurrent',
  "'Retry'": 'context.l10n.chatRetry',
  "'Return to main conversation'":
      'context.l10n.chatReturnToMainConversation',
  "'Session actions'": 'context.l10n.chatSessionActions',
  "'Compact Context'": 'context.l10n.chatCompactContext',
  "'Go to first message'": 'context.l10n.chatGoToFirst',
  "'Go to latest message'": 'context.l10n.chatGoToLatest',

  // ── Session list ─────────────────────────────────────────────
  "'Rename'": 'context.l10n.sessionRename',
  "'Copy Link'": 'context.l10n.sessionCopyLink',
  "'Fork'": 'context.l10n.sessionFork',
  "'Delete'": 'context.l10n.sessionDelete',
  "'Rename Conversation'": 'context.l10n.sessionRenameTitle',
  "'Enter new conversation name'": 'context.l10n.sessionRenameHint',
  "'Delete Conversation'": 'context.l10n.sessionDeleteTitle',
  "'Conversation title'": 'context.l10n.sessionTitleHint',
  "'Save title'": 'context.l10n.sessionSaveTitle',
  "'Cancel rename'": 'context.l10n.sessionCancelRename',

  // ── Permissions ──────────────────────────────────────────────
  "'Reject'": 'context.l10n.permissionReject',
  "'Always'": 'context.l10n.permissionAlways',
  "'Allow Once'": 'context.l10n.permissionAllowOnce',
  "'Reopen'": 'context.l10n.permissionReopen',
  "'Confirm Reject'": 'context.l10n.permissionConfirmReject',
  "'Back'": 'context.l10n.permissionBack',

  // ── Model dialogs ────────────────────────────────────────────
  "'Voice Input Setup'": 'context.l10n.dialogVoiceInputSetup',
  "'Parakeet Voice Setup'": 'context.l10n.dialogParakeetVoiceSetup',
  "'SenseVoice Setup'": 'context.l10n.dialogSenseVoiceSetup',
  "'Moonshine Voice Setup'": 'context.l10n.dialogMoonshineVoiceSetup',
  "'Download'": 'context.l10n.dialogDownload',

  // ── Terminal ─────────────────────────────────────────────────
  "'Reconnect terminal'": 'context.l10n.terminalReconnect',
  "'Close terminal'": 'context.l10n.terminalClose',
  "'Minimize terminal'": 'context.l10n.terminalMinimize',
  "'Try again'": 'context.l10n.terminalTryAgain',

  // ── Chat input ───────────────────────────────────────────────
  "'Send'": 'context.l10n.composerSend',
  "'Shell mode'": 'context.l10n.composerShellMode',
  "'Chat input'": 'context.l10n.composerChatInput',
  "'Extras'": 'context.l10n.composerExtras',
  "'Add attachment'": 'context.l10n.composerAddAttachment',
  "'Select Images'": 'context.l10n.composerSelectImages',
  "'Select PDF'": 'context.l10n.composerSelectPdf',
  "'Edit'": 'context.l10n.composerEdit',
  "'Append at cursor'": 'context.l10n.composerCannedAppendAtCursor',
  "'Send automatically'": 'context.l10n.composerCannedSendAutomatically',
  "'Global'": 'context.l10n.composerCannedScopeGlobal',
  r"'No quick replies yet.'": 'context.l10n.composerCannedNoReplies',
  "'Save'": 'context.l10n.commonSave',

  // ── Tour ─────────────────────────────────────────────────────
  "'Skip'": 'context.l10n.tourSkip',

  // ── SnackBars ────────────────────────────────────────────────
  r"'Copied to clipboard'": 'context.l10n.msgCopiedToClipboard',
  "'Command copied'": 'context.l10n.msgCommandCopied',
  r"'Failed to send message. Draft kept for retry.'":
      'context.l10n.msgFailedToSendMessage',
  r"'Voice input is unavailable on this device'":
      'context.l10n.msgVoiceInputUnavailable',
  r"'Failed to start voice input'": 'context.l10n.msgFailedToStartVoiceInput',
  r"'No valid files were selected'": 'context.l10n.msgNoValidFilesSelected',
  r"'OpenCode setup debug copied to clipboard'":
      'context.l10n.msgSetupDebugCopied',
  r"'Filtered logs copied to clipboard'":
      'context.l10n.msgFilteredLogsCopied',

  // ── SnackBars (session list) ─────────────────────────────────
  r"'Failed to rename conversation'": 'context.l10n.sessionFailedRename',
  r"'Failed to update sharing state'":
      'context.l10n.sessionFailedUpdateSharing',
  r"'Failed to update archive state'":
      'context.l10n.sessionFailedUpdateArchive',
  r"'Share link copied'": 'context.l10n.sessionShareLinkCopied',

  // ── Desktop tray ─────────────────────────────────────────────
  "'Show'": 'context.l10n.trayShow',
  "'Quit'": 'context.l10n.trayQuit',

  // ── Notifications ────────────────────────────────────────────
  "'Conversation updates'": 'context.l10n.notifConversationUpdates',

  // ── Model selector ──────────────────────────────────────────
  "'Loading models'": 'context.l10n.modelLoadingModels',
  "'Retry models'": 'context.l10n.modelRetryModels',
  "'Auto'": 'context.l10n.modelAuto',
  "'Search model or provider'": 'context.l10n.modelSearchHint',

  // ── File explorer ───────────────────────────────────────────
  r"'Search files by name or path'": 'context.l10n.filesSearchHint',
  "'Quick Open'": 'context.l10n.filesQuickOpen',
  "'Refresh files'": 'context.l10n.filesRefresh',
  "'Hide Files sidebar'": 'context.l10n.filesHideSidebar',
  "'Files'": 'context.l10n.filesTitle',

  // ── Message info ────────────────────────────────────────────
  "'Agent'": 'context.l10n.msgInfoAgent',
  "'Snapshot'": 'context.l10n.msgInfoSnapshot',
  "'Patch'": 'context.l10n.msgInfoPatch',
  "'Compaction'": 'context.l10n.msgInfoCompaction',
  "'View'": 'context.l10n.msgInfoView',
  "'Undo this turn'": 'context.l10n.msgInfoUndoThisTurn',
  "'Message Info'": 'context.l10n.msgInfoMessageInfo',

  // ── Info parts ──────────────────────────────────────────────
  "'Retry #":
      'context.l10n.msgInfoRetry + \' #',

  // ── Inline editor ──────────────────────────────────────────
  "'Cancel'": 'context.l10n.commonCancel',

  // ── Workspace ──────────────────────────────────────────────
  "'Project directory'": 'context.l10n.workspaceProjectDirectory',
  r"'/repo/my-project'": 'context.l10n.workspaceProjectHint',
  "'Browse directories'": 'context.l10n.workspaceBrowseDirs',
  "'Filter directories'": 'context.l10n.workspaceFilterDirs',

  // ── Onboarding ─────────────────────────────────────────────
  "'Server URL'": 'context.l10n.onboardingServerUrl',
  "'Label (optional)'": 'context.l10n.onboardingLabel',
  "'My server'": 'context.l10n.onboardingLabelHint',
  "'Username'": 'context.l10n.onboardingUsername',
  "'Password'": 'context.l10n.onboardingPassword',
  "'Clear'": 'context.l10n.onboardingClear',

  // ── Logs ───────────────────────────────────────────────────
  "'Search logs'": 'context.l10n.logsSearch',
  "'Close search'": 'context.l10n.logsCloseSearch',
  "'Copy filtered logs'": 'context.l10n.logsCopyFiltered',
  "'Clear logs'": 'context.l10n.logsClear',

  // ── Quota ──────────────────────────────────────────────────
  "'Forget'": 'context.l10n.quotaForget',
  "'OpenCode Go usage'": 'context.l10n.quotaOpenCodeGoUsage',
  "'Open OpenCode dashboard'": 'context.l10n.quotaOpenDashboard',

  // ── Canned / misc ──────────────────────────────────────────
  "'No suggestions'": 'context.l10n.cannedNoSuggestions',
  "'Workspace ID'": 'context.l10n.quotaWorkspaceId',
  r"'workspace_...'": 'context.l10n.quotaWorkspaceId', // hint kept literal
  "'Auth cookie'": 'context.l10n.quotaAuthCookie',
  r"'auth=...'": 'context.l10n.quotaAuthCookie', // hint kept literal
  "'Saving...'": 'context.l10n.quotaSaving',

  // ── Settings page section titles ──────────────────────────
  "'Servers'": 'context.l10n.settingsServersTitle',
  "'Appearance'": 'context.l10n.settingsAppearanceTitle',
  "'Behavior'": 'context.l10n.settingsBehaviorTitle',
  "'Notifications'": 'context.l10n.settingsNotificationsTitle',
  "'Speech to text'": 'context.l10n.settingsSpeechTitle',
  "'Logs'": 'context.l10n.settingsLogsTitle',
  "'Shortcuts'": 'context.l10n.settingsShortcutsTitle',
  "'About'": 'context.l10n.settingsAboutTitle',
  "'Setup Wizard'": 'context.l10n.settingsSetupWizard',
  "'Replay chat tour'": 'context.l10n.settingsAboutReplayChatTour',

  // ── Settings descriptions ─────────────────────────────────
  "'OpenCode servers and health routing'":
      'context.l10n.settingsServersDescription',
  "'Density and timeline bubble visibility'":
      'context.l10n.settingsAppearanceDescription',
  "'OpenCode defaults, provenance, and composer sync safety'":
      'context.l10n.settingsBehaviorDescription',
  "'Per-category notify and sound controls'":
      'context.l10n.settingsNotificationsDescription',
  "'Engine, silence timeout, and model options'":
      'context.l10n.settingsSpeechDescription',
  "'Runtime diagnostics and troubleshooting data'":
      'context.l10n.settingsLogsDescription',
  "'Portable app key bindings'":
      'context.l10n.settingsShortcutsDescription',
  "'Version, updates and links'": 'context.l10n.settingsAboutDescription',
};

void main() {
  var count = 0;
  for (final filePath in _files) {
    final f = File(filePath);
    if (!f.existsSync()) {
      stderr.writeln('SKIP missing: $filePath');
      continue;
    }
    var content = f.readAsStringSync();
    var changed = false;

    // 1. Replace literal strings with l10n calls
    for (final entry in _map.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        changed = true;
        count++;
      }
    }

    // 2. Remove 'const' from const Text(context.l10n...) patterns
    // Pattern: const Text( → Text(
    if (content.contains('const Text(context.l10n.')) {
      content = content.replaceAll('const Text(context.l10n.', 'Text(context.l10n.');
      changed = true;
    }
    // const SnackBar(content: Text(context.l10n… → SnackBar(content: Text(context.l10n…
    if (content.contains(
        'const SnackBar(content: Text(context.l10n.')) {
      content = content.replaceAll(
          'const SnackBar(content: Text(context.l10n.',
          'SnackBar(content: Text(context.l10n.');
      changed = true;
    }
    // const [PopupMenuItem(... child: Text(context.l10n… → [PopupMenuItem(...
    if (content.contains("=> const [\n") &&
        content.contains('child: Text(context.l10n.')) {
      content = content.replaceAll(r'=> const [', '=> [');
      changed = true;
    }
    // const InputDecoration(... context.l10n … → InputDecoration(...
    if (content.contains('const InputDecoration(') &&
        content.contains('context.l10n.')) {
      content = content.replaceAll(
          'const InputDecoration(', 'InputDecoration(');
      changed = true;
    }

    if (changed) {
      f.writeAsStringSync(content);
      stdout.writeln('OK: $filePath');
    }
  }
  stdout.writeln('$count string replacements.');
}
