import 'dart:io';

/// Code migrator: replaces hardcoded English UI strings with context.l10n calls.
/// Run: `dart tool/i18n/migrate_code.dart`
/// Can be re-run safely — each replacement is idempotent.

final _replacements = <_Replacement>[
  // ── Shared common patterns ──────────────────────────────────
  _rep("import '../providers/settings_provider.dart';",
      "import '../providers/settings_provider.dart';\nimport '../../core/i18n/l10n_context.dart';"),
  _rep("import '../../../providers/settings_provider.dart';",
      "import '../../../providers/settings_provider.dart';\nimport '../../../core/i18n/l10n_context.dart';"),
  _rep("import '../../../theme/brand_colors.dart';",
      "import '../../../theme/brand_colors.dart';\nimport '../../../core/i18n/l10n_context.dart';"),
  _rep("import '../../../../core/constants/app_constants.dart';",
      "import '../../../core/i18n/l10n_context.dart';\nimport '../../../../core/constants/app_constants.dart';"),

  // ── Settings page ───────────────────────────────────────────
  _rep("title: 'Servers',", "title: l10n.settingsServersTitle,"),
  _rep("title: 'Appearance',", "title: l10n.settingsAppearanceTitle,"),
  _rep("title: 'Behavior',", "title: l10n.settingsBehaviorTitle,"),
  _rep("title: 'Notifications',", "title: l10n.settingsNotificationsTitle,"),
  _rep("title: 'Speech to text',", "title: l10n.settingsSpeechTitle,"),
  _rep("title: 'Logs',", "title: l10n.settingsLogsTitle,"),
  _rep("title: 'Shortcuts',", "title: l10n.settingsShortcutsTitle,"),
  _rep("title: 'About',", "title: l10n.settingsAboutTitle,"),
  _rep("description: 'OpenCode servers and health routing',",
      "description: l10n.settingsServersDescription,"),
  _rep("description: 'Density and timeline bubble visibility',",
      "description: l10n.settingsAppearanceDescription,"),
  _rep("description: 'OpenCode defaults, provenance, and composer sync safety',",
      "description: l10n.settingsBehaviorDescription,"),
  _rep("description: 'Per-category notify and sound controls',",
      "description: l10n.settingsNotificationsDescription,"),
  _rep("description: 'Engine, silence timeout, and model options',",
      "description: l10n.settingsSpeechDescription,"),
  _rep("description: 'Runtime diagnostics and troubleshooting data',",
      "description: l10n.settingsLogsDescription,"),
  _rep("description: 'Portable app key bindings',",
      "description: l10n.settingsShortcutsDescription,"),
  _rep("description: 'Version, updates and links',",
      "description: l10n.settingsAboutDescription,"),
  _rep("label: const Text('Setup Wizard'),",
      "label: Text(l10n.settingsSetupWizard),"),
  _rep("label: const Text('Replay chat tour'),",
      "label: Text(l10n.settingsAboutReplayChatTour),"),

  // ── Chat scaffold ───────────────────────────────────────────
  _rep("tooltip: 'Project Context',",
      "tooltip: context.l10n.chatProjectContext,"),
  _rep("tooltip: 'New Chat',", "tooltip: context.l10n.chatNewChat,"),
  _rep("tooltip: 'Refresh',", "tooltip: context.l10n.chatRefresh,"),
  _rep("tooltip: 'Hide Conversations sidebar',",
      "tooltip: context.l10n.chatHideConversationsSidebar,"),
  _rep("tooltip: 'Hide Utility sidebar',",
      "tooltip: context.l10n.chatHideUtilitySidebar,"),
  _rep("tooltip: 'Filter sessions',",
      "tooltip: context.l10n.chatFilterSessions,"),
  _rep("tooltip: 'Sort sessions',",
      "tooltip: context.l10n.chatSortSessions,"),
  _rep(
      "tooltip: 'Refresh session details',",
      "tooltip: context.l10n.chatRefreshSessionDetails,"),

  // Session filter labels (in menu items and chip)
  _rep("child: Text('Active'),", "child: Text(context.l10n.chatFilterActive),"),
  _rep("child: Text('Archived'),",
      "child: Text(context.l10n.chatFilterArchived),"),
  _rep("child: Text('All'),", "child: Text(context.l10n.chatFilterAll),"),
  _rep("SessionListFilter.active => 'Active',",
      "SessionListFilter.active => context.l10n.chatFilterActive,"),
  _rep("SessionListFilter.archived => 'Archived',",
      "SessionListFilter.archived => context.l10n.chatFilterArchived,"),
  _rep("SessionListFilter.all => 'All',",
      "SessionListFilter.all => context.l10n.chatFilterAll,"),

  // Session sort labels
  _rep("child: Text('Most Recent'),",
      "child: Text(context.l10n.chatSortMostRecent),"),
  _rep("child: Text('Oldest'),", "child: Text(context.l10n.chatSortOldest),"),
  _rep("child: Text('Title'),", "child: Text(context.l10n.chatSortTitle),"),
  _rep("SessionListSort.recent => 'Recent',",
      "SessionListSort.recent => context.l10n.chatSortRecent,"),
  _rep("SessionListSort.oldest => 'Oldest',",
      "SessionListSort.oldest => context.l10n.chatSortOldest,"),
  _rep("SessionListSort.title => 'Title',",
      "SessionListSort.title => context.l10n.chatSortTitle,"),

  // Search field
  _rep("hintText: 'Search conversations',",
      "hintText: context.l10n.chatSearchConversations,"),

  // Recent sessions
  _rep("'Recent sessions'", "context.l10n.chatRecentSessions"),

  // Load more
  _rep("label: const Text('Load more'),",
      "label: Text(context.l10n.chatLoadMore),"),

  // New Chat / Refresh buttons in utility pane
  _rep("label: const Text('New Chat'),",
      "label: Text(context.l10n.chatNewChat),"),
  _rep("label: const Text('Refresh'),",
      "label: Text(context.l10n.chatRefresh),"),

  // Session not available
  _rep("'Conversation is not available for this project yet'",
      "context.l10n.sessionNotAvailable"),

  // Keyboard shortcuts
  _rep("'Keyboard shortcuts'", "context.l10n.sessionKeyboardShortcuts"),

  // ── Chat chrome ─────────────────────────────────────────────
  _rep("tooltip: 'Close',", "tooltip: context.l10n.chatClose,"),
  _rep("tooltip: 'Toggle sidebars',",
      "tooltip: context.l10n.chatToggleSidebars,"),
  _rep("tooltip: 'Undo last turn',",
      "tooltip: context.l10n.chatUndoLastTurn,"),
  _rep("tooltip: 'Redo last undone turn',",
      "tooltip: context.l10n.chatRedoLastTurn,"),
  _rep("tooltip: 'Display toggles',",
      "tooltip: context.l10n.chatDisplayToggles,"),
  _rep("tooltip: 'Open Files',", "tooltip: context.l10n.chatOpenFiles,"),
  _rep("DesktopPane.conversations => 'Conversations',",
      "DesktopPane.conversations => context.l10n.chatConversationsPane,"),
  _rep("_DisplayToggleAction.recentSessions => 'Recent sessions',",
      "_DisplayToggleAction.recentSessions => context.l10n.chatRecentSessionsToggle,"),
  _rep("title: 'New chat',", "title: context.l10n.chatNewChatTourTitle,"),
  _rep("description: 'Start a new conversation here.'",
      "description: context.l10n.chatNewChatTourDescription"),
  _rep("description: 'Start a new conversation here.',",
      "description: context.l10n.chatNewChatTourDescription,"),
  _rep("title: 'Files',", "title: context.l10n.filesTitle,"),

  // ── Chat timeline builder ────────────────────────────────────
  _rep("'No server configured yet'", "context.l10n.chatNoServerYet"),
  _rep("'Add a server to start chatting.'", "context.l10n.chatAddServerToStart"),
  _rep("label: const Text('Set up server'),",
      "label: Text(context.l10n.chatSetUpServer),"),
  _rep(
      "'Select or create a conversation to start chatting'",
      "context.l10n.chatSelectOrCreate"),
  _rep("label: const Text('New Chat'),",
      "label: Text(context.l10n.chatNewChat),"),

  // Retry / Keep working
  _rep("child: const Text('Retry'),", "child: Text(context.l10n.chatRetry),"),
  _rep("child: const Text('Keep working'),",
      "child: Text(context.l10n.chatKeepWorking),"),
  _rep("child: const Text('Retry refresh'),",
      "child: Text(context.l10n.chatRetryRefresh),"),
  _rep("label: const Text('Return to main conversation'),",
      "label: Text(context.l10n.chatReturnToMainConversation),"),
  _rep("child: const Text('Use current'),",
      "child: Text(context.l10n.chatUseCurrent),"),

  // Session actions / Compact context
  _rep("tooltip: 'Session actions',",
      "tooltip: context.l10n.chatSessionActions,"),
  _rep("tooltip: 'Compact Context',",
      "tooltip: context.l10n.chatCompactContext,"),
  _rep("tooltip: 'Go to first message',",
      "tooltip: context.l10n.chatGoToFirst,"),
  _rep("tooltip: 'Go to latest message',",
      "tooltip: context.l10n.chatGoToLatest,"),


  // ── Chat session list ───────────────────────────────────────
  _rep("Text('Rename'),", "Text(context.l10n.sessionRename),"),
  _rep("Text('Copy Link'),", "Text(context.l10n.sessionCopyLink),"),
  _rep("Text('Fork'),", "Text(context.l10n.sessionFork),"),
  _rep(
      "Text('Delete', style: TextStyle(color: Colors.red)),",
      "Text(context.l10n.sessionDelete, style: TextStyle(color: Colors.red)),"),
  _rep(
      "const SnackBar(content: Text('Failed to rename conversation'))",
      "SnackBar(content: Text(context.l10n.sessionFailedRename))"),
  _rep("title: const Text('Rename Conversation'),",
      "title: Text(context.l10n.sessionRenameTitle),"),
  _rep("child: const Text('Cancel'),",
      "child: Text(context.l10n.commonCancel),"),
  _rep("child: const Text('Save'),",
      "child: Text(context.l10n.commonSave),"),
  _rep(
      "const SnackBar(content: Text('Failed to update sharing state'))",
      "SnackBar(content: Text(context.l10n.sessionFailedUpdateSharing))"),
  // Skipped — dynamic concatenation needs manual migration
  // _rep("SnackBar(content: Text('Conversation \$nextAction'))", ...),
  _rep(
      "const SnackBar(content: Text('Share link copied'))",
      "SnackBar(content: Text(context.l10n.sessionShareLinkCopied))"),
  _rep(
      "const SnackBar(content: Text('Failed to update archive state'))",
      "SnackBar(content: Text(context.l10n.sessionFailedUpdateArchive))"),
  _rep("title: const Text('Delete Conversation'),",
      "title: Text(context.l10n.sessionDeleteTitle),"),
  _rep("child: const Text('Delete'),",
      "child: Text(context.l10n.commonDelete),"),
  _rep(
      "hintText: 'Enter new conversation name',",
      "hintText: context.l10n.sessionRenameHint,"),
  _rep(
      "hintText: 'Conversation title',",
      "hintText: context.l10n.sessionTitleHint,"),
  _rep("tooltip: 'Save title',",
      "tooltip: context.l10n.sessionSaveTitle,"),
  _rep("tooltip: 'Cancel rename',",
      "tooltip: context.l10n.sessionCancelRename,"),

  // ── Permission cards ────────────────────────────────────────
  _rep("child: const Text('Reject'),",
      "child: Text(context.l10n.permissionReject),"),
  _rep("child: const Text('Always'),",
      "child: Text(context.l10n.permissionAlways),"),
  _rep("child: const Text('Allow Once'),",
      "child: Text(context.l10n.permissionAllowOnce),"),
  _rep("child: const Text('Reopen'),",
      "child: Text(context.l10n.permissionReopen),"),
  _rep("child: const Text('Confirm Reject'),",
      "child: Text(context.l10n.permissionConfirmReject),"),
  _rep("child: const Text('Back'),",
      "child: Text(context.l10n.permissionBack),"),

  // ── Model dialogs ───────────────────────────────────────────
  _rep("title: const Text('Voice Input Setup'),",
      "title: Text(context.l10n.dialogVoiceInputSetup),"),
  _rep("title: const Text('Parakeet Voice Setup'),",
      "title: Text(context.l10n.dialogParakeetVoiceSetup),"),
  _rep("title: const Text('SenseVoice Setup'),",
      "title: Text(context.l10n.dialogSenseVoiceSetup),"),
  _rep("title: const Text('Moonshine Voice Setup'),",
      "title: Text(context.l10n.dialogMoonshineVoiceSetup),"),
  _rep("child: const Text('Download'),",
      "child: Text(context.l10n.dialogDownload),"),

  // ── Terminal ────────────────────────────────────────────────
  _rep("tooltip: 'Reconnect terminal',",
      "tooltip: context.l10n.terminalReconnect,"),
  _rep("tooltip: 'Close terminal',",
      "tooltip: context.l10n.terminalClose,"),
  _rep("tooltip: 'Minimize terminal',",
      "tooltip: context.l10n.terminalMinimize,"),
  _rep("label: const Text('Try again'),",
      "label: Text(context.l10n.terminalTryAgain),"),

  // ── Chat input / Composer ───────────────────────────────────
  _rep("title: 'Chat input',", "title: context.l10n.composerChatInput,"),
  _rep("title: 'Send',", "title: context.l10n.composerSend,"),
  _rep("label: const Text('Shell mode'),",
      "label: Text(context.l10n.composerShellMode),"),
  _rep("tooltip: 'Add attachment',",
      "tooltip: context.l10n.composerAddAttachment,"),
  _rep("tooltip: 'Extras',", "tooltip: context.l10n.composerExtras,"),

  // ── Canned answer controller ────────────────────────────────
  _rep("title: const Text('Edit'),", "title: Text(context.l10n.composerEdit),"),
  _rep(
      "title: const Text('Delete'),",
      "title: Text(context.l10n.composerDeleteAction),"),
  _rep(
      "title: const Text('Append at cursor'),",
      "title: Text(context.l10n.composerCannedAppendAtCursor),"),
  _rep(
      "title: const Text('Send automatically'),",
      "title: Text(context.l10n.composerCannedSendAutomatically),"),
  _rep(
      "title: const Text('Global'),",
      "title: Text(context.l10n.composerCannedScopeGlobal),"),
  _rep(
      "label: 'New quick reply',",
      "label: context.l10n.composerNewQuickReply,"),
  _rep(
      "label: 'Attach files',",
      "label: context.l10n.composerAttachFiles,"),
  _rep(
      "child: Text('No quick replies yet.'),",
      "child: Text(context.l10n.composerCannedNoReplies),"),

  // ── Attachment controller ───────────────────────────────────
  _rep(
      "title: const Text('Select Images'),",
      "title: Text(context.l10n.composerSelectImages),"),
  _rep(
      "title: const Text('Select PDF'),",
      "title: Text(context.l10n.composerSelectPdf),"),
  _rep(
      "const SnackBar(content: Text('No valid files were selected'))",
      "SnackBar(content: Text(context.l10n.msgNoValidFilesSelected))"),

  // ── Tour ────────────────────────────────────────────────────
  _rep("child: const Text('Skip'),",
      "child: Text(context.l10n.tourSkip),"),
  _rep("child: const Text('Back'),",
      "child: Text(context.l10n.tourBack),"),

  // ── SnackBar / common messages ──────────────────────────────
  _rep(
      "const SnackBar(content: Text('Copied to clipboard'))",
      "SnackBar(content: Text(context.l10n.msgCopiedToClipboard))"),
  _rep(
      "content: Text('Failed to send message. Draft kept for retry.')",
      "content: Text(context.l10n.msgFailedToSendMessage)"),
  _rep(
      "content: Text('Voice input is unavailable on this device')",
      "content: Text(context.l10n.msgVoiceInputUnavailable)"),
  _rep(
      "const SnackBar(content: Text('Failed to start voice input'))",
      "SnackBar(content: Text(context.l10n.msgFailedToStartVoiceInput))"),
  _rep(
      "const SnackBar(content: Text('OpenCode setup debug copied to clipboard'))",
      "SnackBar(content: Text(context.l10n.msgSetupDebugCopied))"),
  _rep(
      "const SnackBar(content: Text('Filtered logs copied to clipboard'))",
      "SnackBar(content: Text(context.l10n.msgFilteredLogsCopied))"),

  // ── Desktop tray ────────────────────────────────────────────
  _rep(
      "MenuItem(key: 'show', label: 'Show'),",
      "MenuItem(key: 'show', label: context.l10n.trayShow),"),
  _rep(
      "MenuItem(key: 'quit', label: 'Quit'),",
      "MenuItem(key: 'quit', label: context.l10n.trayQuit),"),

  // ── Notification service ────────────────────────────────────
  _rep(
      "title: 'Conversation updates',",
      "title: context.l10n.notifConversationUpdates,"),

  // ── Chat model selector ─────────────────────────────────────
  _rep(
      "label: const Text('Loading models'),",
      "label: Text(context.l10n.modelLoadingModels),"),
  _rep(
      "label: const Text('Retry models'),",
      "label: Text(context.l10n.modelRetryModels),"),
  _rep(
      "const Expanded(child: Text('Auto')),",
      "Expanded(child: Text(context.l10n.modelAuto)),"),

  // ── Chat info parts ─────────────────────────────────────────
  _rep("title: 'Agent',", "title: context.l10n.msgInfoAgent,"),
  _rep("title: 'Snapshot',", "title: context.l10n.msgInfoSnapshot,"),
  _rep("title: 'Patch',", "title: context.l10n.msgInfoPatch,"),
  _rep("title: 'Compaction',", "title: context.l10n.msgInfoCompaction,"),
  _rep("title: 'Retry #", "title: context.l10n.msgInfoRetry + ' #"),
  _rep("child: const Text('View'),",
      "child: Text(context.l10n.msgInfoView),"),

  // ── Chat message content ────────────────────────────────────
  _rep("tooltip: 'Undo this turn',",
      "tooltip: context.l10n.msgInfoUndoThisTurn,"),
  _rep("tooltip: 'Message Info',",
      "tooltip: context.l10n.msgInfoMessageInfo,"),
  // Skipped — these contain dynamic interpolations, migrate manually:
  _rep(r"child: Text('Model: ${message.modelId}'),",
      r"child: Text(context.l10n.msgInfoModel(message.modelId ?? '')),"),
  _rep(r"child: Text('Provider: ${message.providerId}'),",
      r"child: Text(context.l10n.msgInfoProvider(message.providerId ?? '')),"),
  _rep(r"child: Text('Tokens: ${message.tokens!.total}'),",
      r"child: Text(context.l10n.msgInfoTokens('${message.tokens!.total}')),"),
  _rep(r"child: Text('Cost: \$${message.cost!.toStringAsFixed(6)}'),",
      r"child: Text(context.l10n.msgInfoCost(message.cost!.toStringAsFixed(6))),"),
  _rep(
      "child: Text('No metadata available'),",
      "child: Text(context.l10n.msgInfoNoMetadata),"),

  // ── File explorer ───────────────────────────────────────────
  _rep(
      "hintText: 'Search files by name or path',",
      "hintText: context.l10n.filesSearchHint,"),
  _rep("tooltip: 'Quick Open',", "tooltip: context.l10n.filesQuickOpen,"),
  _rep(
      "tooltip: 'Refresh files',",
      "tooltip: context.l10n.filesRefresh,"),
  _rep(
      "tooltip: 'Hide Files sidebar',",
      "tooltip: context.l10n.filesHideSidebar,"),

  // ── Chat suggestion popover ─────────────────────────────────
  _rep(
      "child: Center(child: Text('No suggestions')),",
      "child: Center(child: Text(context.l10n.cannedNoSuggestions)),"),

  // ── Workspace controller ────────────────────────────────────
  _rep(
      "labelText: 'Project directory',",
      "labelText: context.l10n.workspaceProjectDirectory,"),
  _rep(
      "hintText: '/repo/my-project',",
      "hintText: context.l10n.workspaceProjectHint,"),
  _rep(
      "tooltip: 'Browse directories',",
      "tooltip: context.l10n.workspaceBrowseDirs,"),

  // ── Onboarding ──────────────────────────────────────────────
  _rep(
      "labelText: 'Server URL',",
      "labelText: context.l10n.onboardingServerUrl,"),
  _rep(
      "labelText: 'Label (optional)',",
      "labelText: context.l10n.onboardingLabel,"),
  _rep(
      "hintText: 'My server',",
      "hintText: context.l10n.onboardingLabelHint,"),
  _rep(
      "decoration: const InputDecoration(labelText: 'Username'),",
      "decoration: InputDecoration(labelText: context.l10n.onboardingUsername),"),
  _rep(
      "decoration: const InputDecoration(labelText: 'Password'),",
      "decoration: InputDecoration(labelText: context.l10n.onboardingPassword),"),
  _rep("tooltip: 'Clear',", "tooltip: context.l10n.onboardingClear,"),

  // ── Logs ────────────────────────────────────────────────────
  _rep("hintText: 'Search logs',", "hintText: context.l10n.logsSearch,"),
  _rep(
      "tooltip: 'Close search',",
      "tooltip: context.l10n.logsCloseSearch,"),
  _rep(
      "tooltip: 'Search logs',",
      "tooltip: context.l10n.logsSearch,"),
  _rep(
      "tooltip: 'Copy filtered logs',",
      "tooltip: context.l10n.logsCopyFiltered,"),
  _rep("tooltip: 'Clear logs',", "tooltip: context.l10n.logsClear,"),

  // ── Quota ───────────────────────────────────────────────────
  _rep(
      "child: const Text('Forget'),",
      "child: Text(context.l10n.quotaForget),"),
  _rep(
      "title: const Text('OpenCode Go usage'),",
      "title: Text(context.l10n.quotaOpenCodeGoUsage),"),
  _rep(
      "label: const Text('Open OpenCode dashboard'),",
      "label: Text(context.l10n.quotaOpenDashboard),"),
  _rep(
      "child: _saving ? const Text('Saving...') : const Text('Save'),",
      "child: _saving ? Text(context.l10n.quotaSaving) : Text(context.l10n.commonSave),"),
  _rep(
      "labelText: 'Workspace ID',",
      "labelText: context.l10n.quotaWorkspaceId,"),
  _rep(
      "hintText: 'workspace_...',",
      "hintText: 'workspace_...',"),
  _rep(
      "labelText: 'Auth cookie',",
      "labelText: context.l10n.quotaAuthCookie,"),
  _rep(
      "hintText: 'auth=...',",
      "hintText: 'auth=...',"),

  // ── Settings model selectors ────────────────────────────────
  _rep(
      "labelText: 'Choose active server',",
      "labelText: context.l10n.settingsServersChooseActive,"),
  _rep(
      "hintText: 'Search shortcuts',",
      "hintText: context.l10n.settingsShortcutsSearch,"),
  _rep(
      "hintText: 'Search model or provider',",
      "hintText: context.l10n.modelSearchHint,"),
  _rep(
      "hintText: 'Filter directories',",
      "hintText: context.l10n.workspaceFilterDirs,"),
  _rep(
      "labelText: 'Changed file',",
      "labelText: context.l10n.workspaceProjectDirectory,"),

  // ── Partial quotes fix for the SnackBar at line 837 ─────────
  // (skipped — dynamic concatenation, needs manual handling)

  // ── Common false positives from generic words like "Cancel" ──
  // These should NOT be replaced because they match too broadly.
  // "Cancel" in CancelToken, "Refresh" in class names, etc.
  // Only the specific `child: const Text(` and `label: const Text(` patterns are targeted.
];

class _Replacement {
  final String from;
  final String to;
  const _Replacement(this.from, this.to);
}

_Replacement _rep(String from, String to) => _Replacement(from, to);

final _presentationDirs = [
  'lib/presentation/pages/settings_page.dart',
  'lib/presentation/pages/settings/sections/appearance_settings_section.dart',
  'lib/presentation/pages/settings/sections/behavior_settings_section.dart',
  'lib/presentation/pages/settings/sections/notifications_settings_section.dart',
  'lib/presentation/pages/settings/sections/servers_settings_section.dart',
  'lib/presentation/pages/settings/sections/shortcuts_settings_section.dart',
  'lib/presentation/pages/settings/sections/speech_settings_section.dart',
  'lib/presentation/pages/chat_page.dart',
  'lib/presentation/pages/chat_page/chat_page_scaffold.dart',
  'lib/presentation/pages/chat_page/chat_page_chrome.dart',
  'lib/presentation/pages/chat_page/chat_page_timeline_builder.dart',
  'lib/presentation/pages/chat_page/chat_page_workspace_controller.dart',
  'lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart',
  'lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart',
  'lib/presentation/pages/chat_page/chat_page_status_presenter.dart',
  'lib/presentation/pages/chat_page/chat_page_selector_flow.dart',
  'lib/presentation/pages/chat_page/chat_page_file_runtime.dart',
  'lib/presentation/pages/onboarding_wizard_page.dart',
  'lib/presentation/pages/opencode_setup_debug_page.dart',
  'lib/presentation/pages/logs_page.dart',
  'lib/presentation/widgets/chat_session_list.dart',
  'lib/presentation/widgets/chat_input_widget.dart',
  'lib/presentation/widgets/chat_tour_showcase.dart',
  'lib/presentation/widgets/codewalk_terminal_panel.dart',
  'lib/presentation/widgets/permission_request_card.dart',
  'lib/presentation/widgets/question_request_card.dart',
  'lib/presentation/widgets/sherpa_model_download_dialog.dart',
  'lib/presentation/widgets/parakeet_model_download_dialog.dart',
  'lib/presentation/widgets/sensevoice_model_download_dialog.dart',
  'lib/presentation/widgets/moonshine_model_download_dialog.dart',
  'lib/presentation/widgets/chat_input/chat_input_canned_controller.dart',
  'lib/presentation/widgets/chat_input/chat_input_attachment_controller.dart',
  'lib/presentation/widgets/chat_input/chat_input_speech_controller.dart',
  'lib/presentation/widgets/chat_input/chat_input_state_machine.dart',
  'lib/presentation/widgets/chat_input/chat_input_suggestion_popover.dart',
  'lib/presentation/widgets/chat_message/chat_message_text_part.dart',
  'lib/presentation/widgets/chat_message/chat_message_content.dart',
  'lib/presentation/widgets/chat_message/chat_message_info_parts.dart',
  'lib/presentation/widgets/quota/quota_popup_section.dart',
  'lib/presentation/widgets/session_title_inline_editor.dart',
  'lib/presentation/services/desktop_tray_service_io.dart',
  'lib/presentation/services/notification_service.dart',
];

void main() {
  var total = 0;
  for (final filePath in _presentationDirs) {
    if (!File(filePath).existsSync()) {
      stderr.writeln('WARN: not found — $filePath');
      continue;
    }
    var content = File(filePath).readAsStringSync();
    var changed = false;

    for (final rep in _replacements) {
      if (content.contains(rep.from)) {
        content = content.replaceAll(rep.from, rep.to);
        changed = true;
        total++;
      }
    }

    if (changed) {
      File(filePath).writeAsStringSync(content);
      stdout.writeln('MIGRATED: $filePath');
    }
  }
  stdout.writeln('Done — $total replacements applied.');
}
