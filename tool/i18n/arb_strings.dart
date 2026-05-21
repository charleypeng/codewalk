/// ARB key definitions and per-locale translations for CodeWalk i18n.
///
/// Usage: `dart tool/i18n/generate_arb.dart`
///
/// Edit translations in the `_translations` map, then regenerate ARB files.
library;

const englishTemplate = <String, String>{
  // ── Language Selector (existing) ────────────────────────────────
  'settingsLanguageTitle': 'Language',
  'settingsLanguageDescription':
      'Choose the language used by CodeWalk. System default follows your device language.',
  'settingsLanguageFieldLabel': 'App language',
  'settingsLanguageFieldHelper':
      'Applies immediately and persists across restarts.',
  'settingsLanguageSearchHint': 'Search languages',
  'settingsLanguageEmptyText': 'No languages found',
  'settingsLanguageSystemDefault': 'System default',

  // ── Settings ─ Section titles & descriptions ────────────────────
  'settingsTitle': 'Settings',
  'settingsServersTitle': 'Servers',
  'settingsServersDescription': 'OpenCode servers and health routing',
  'settingsAppearanceTitle': 'Appearance',
  'settingsAppearanceDescription': 'Density and timeline bubble visibility',
  'settingsBehaviorTitle': 'Behavior',
  'settingsBehaviorDescription':
      'OpenCode defaults, provenance, and composer sync safety',
  'settingsNotificationsTitle': 'Notifications',
  'settingsNotificationsDescription':
      'Per-category notify and sound controls',
  'settingsSpeechTitle': 'Speech to text',
  'settingsSpeechDescription': 'Engine, silence timeout, and model options',
  'settingsLogsTitle': 'Logs',
  'settingsLogsDescription': 'Runtime diagnostics and troubleshooting data',
  'settingsShortcutsTitle': 'Shortcuts',
  'settingsShortcutsDescription': 'Portable app key bindings',
  'settingsAboutTitle': 'About',
  'settingsAboutDescription': 'Version, updates and links',
  'settingsSetupWizard': 'Setup Wizard',

  // ── Settings ─ Behavior section ─────────────────────────────────
  'settingsBehaviorMultiDeviceSync':
      'Enable experimental multi-device sync',
  'settingsBehaviorMultiDeviceSyncDescription':
      'Sync composer selection (agent/model/variant) with the active server config.',
  'settingsBehaviorMultiDeviceSyncWarning':
      'Can abort ongoing sessions when working in more than one session at the same time.',
  'settingsBehaviorOpenCodeDefaults': 'OpenCode-backed defaults',
  'settingsBehaviorOpenCodeDefaultsDescription':
      'These values write to `/config` on the active server and match official OpenCode shared config.',
  'settingsBehaviorRefreshDefaults': 'Refresh defaults',
  'settingsBehaviorDefaultModel': 'Default model',
  'settingsBehaviorDefaultModelHelp':
      'Shared across OpenCode clients through config.',
  'settingsBehaviorSearchDefaultModel': 'Search default model',
  'settingsBehaviorNoModels': 'No models found',
  'settingsBehaviorDefaultAgent': 'Default agent',
  'settingsBehaviorDefaultAgentHelp':
      'Primary agent used when no agent is explicitly chosen.',
  'settingsBehaviorSearchDefaultAgent': 'Search default agent',
  'settingsBehaviorNoAgents': 'No agents found',
  'settingsBehaviorConversationUsername': 'Conversation username',
  'settingsBehaviorConversationUsernameHelp':
      'Custom display name shown in conversations instead of the system username.',
  'settingsBehaviorSaveUsername': 'Save username',
  'settingsBehaviorUsernameFallback':
      'OpenCode uses the system username because `username` is unset.',
  'settingsBehaviorUsernamePatchCaveat':
      'Resetting `username` back to the system default still requires editing config outside the app because `/config` patch updates cannot remove keys.',
  'settingsBehaviorOpenCodeSnapshots': 'OpenCode snapshots',
  'settingsBehaviorOpenCodeSnapshotsDescription':
      'Keep upstream git-backed snapshots enabled for undo/redo and recovery history.',
  'settingsBehaviorSnapshotCaveat':
      'This controls OpenCode snapshot storage and undo/redo support, not CodeWalk local cache snapshots.',
  'settingsBehaviorSmallModel': 'Small model',
  'settingsBehaviorSmallModelHelp':
      'Used for lightweight tasks like title generation.',
  'settingsBehaviorSearchSmallModel': 'Search small model',
  'settingsBehaviorSmallModelAutoFallback': 'Automatic fallback',
  'settingsBehaviorSmallModelFallbackActive':
      'OpenCode automatic fallback is active because `small_model` is unset.',
  'settingsBehaviorSmallModelResetCaveat':
      'Resetting `small_model` back to automatic fallback still requires editing config outside the app because `/config` patch updates cannot remove keys.',
  'settingsBehaviorOpenCodeAutoupdate': 'OpenCode auto-update',
  'settingsBehaviorAutoupdateHelp':
      'Controls upstream OpenCode runtime updates, not CodeWalk app update checks.',
  'settingsBehaviorSearchAutoupdate': 'Search auto-update mode',
  'settingsBehaviorAutoupdateCaveat':
      'Use About for CodeWalk release checks. This setting only mirrors the official OpenCode `autoupdate` config.',
  'settingsBehaviorShareMode': 'OpenCode sharing default',
  'settingsBehaviorShareModeHelp':
      'Controls the official global `share` config, not the share button for an individual chat.',
  'settingsBehaviorSearchShareMode': 'Search sharing mode',
  'settingsBehaviorShareModeCaveat':
      'Use the chat-level share action to publish one session now. This setting only changes OpenCode\'s default sharing policy.',
  'settingsBehaviorPermissionProvenance': 'Permission handling provenance',
  'settingsBehaviorPermissionProvenanceDescription':
      'Official OpenCode permission policy is configured in `opencode.json` with allow/ask/deny rules per tool. CodeWalk keeps the official permission-request cards and adds one approved ADR-023 exception: the composer auto-approve toggle replies with `Always` when the request supports remembered approval, otherwise `Allow Once`, and keeps the same thread-scoped continuity path active in the Android background worker.',
  'settingsBehaviorPermissionDeferred':
      'Advanced permission rule editing stays out of Settings for now and is deferred to later parity work.',
  'settingsBehaviorCellularDataSaver': 'Cellular data saver',
  'settingsBehaviorDataSaverDescription':
      'Cuts automatic mobile-data usage by stopping background downloads and throttling automatic foreground refreshes.',
  'settingsBehaviorEnableDataSaver': 'Enable cellular data saver',
  'settingsBehaviorDataSaverActive':
      'Active now on mobile data.',
  'settingsBehaviorDataSaverWaiting':
      'Waiting for the next mobile-data sync window.',
  'settingsBehaviorDataSaverCellularOnly':
      'Only applies when the connection is cellular/mobile.',
  'settingsBehaviorConfigDeferred':
      'CodeWalk will apply this OpenCode setting after the current response finishes.',
  'settingsBehaviorConfigUpdateFailed':
      'Could not update the OpenCode {field}.',

  // ── Settings ─ Appearance section ───────────────────────────────
  'settingsAppearanceSectionTitle': 'Appearance',
  'settingsAppearanceSectionDescription':
      'Tune visual density and message surfaces for your workflow.',
  'settingsAppearanceTheme': 'Theme',
  'settingsAppearanceThemeDescription':
      'Choose light, dark, or system mode, then keep the CodeWalk classic palette or switch to an OpenCode preset.',
  'settingsAppearanceSystem': 'System',
  'settingsAppearanceLight': 'Light',
  'settingsAppearanceDark': 'Dark',
  'settingsAppearanceCodeWalkClassic': 'CodeWalk Classic',
  'settingsAppearanceOpenCodePresets': 'OpenCode Presets',
  'settingsAppearancePresetPalette': 'Preset palette',
  'settingsAppearancePresetHelper':
      'Mirrors the official OpenCode Web built-in theme list.',
  'settingsAppearanceSearchPreset': 'Search preset palette',
  'settingsAppearanceNoPresets': 'No preset palettes found',
  'settingsAppearancePresetNote':
      'Theme colors now follow the official OpenCode Web registry and drive markdown/code surfaces too.',
  'settingsAppearanceAmoledDark': 'AMOLED dark mode',
  'settingsAppearanceAmoledDarkActive':
      'Use pure black surfaces while dark mode is active.',
  'settingsAppearanceAmoledDarkInactive':
      'Switch to dark mode to enable AMOLED surfaces.',
  'settingsAppearanceWallpaperColors': 'Use wallpaper colors',
  'settingsAppearanceWallpaperPresetBlocked':
      'Switch to CodeWalk Classic to use wallpaper colors.',
  'settingsAppearanceWallpaperNormal':
      'Extract color scheme from your device wallpaper.',
  'settingsAppearanceBrandColor': 'Brand color',
  'settingsAppearanceBrandColorPresetBlocked':
      'Switch to CodeWalk Classic to pick a brand color.',
  'settingsAppearanceBrandColorDynamicBlocked':
      'Disable wallpaper colors to pick a brand color.',
  'settingsAppearanceBrandColorNormal':
      'Pick a seed color for the app palette.',
  'settingsAppearanceContrast': 'Contrast',
  'settingsAppearanceContrastPresetBlocked':
      'Switch to CodeWalk Classic to adjust contrast.',
  'settingsAppearanceContrastDynamicBlocked':
      'Disable wallpaper colors to adjust contrast.',
  'settingsAppearanceContrastNormal':
      'Adjust the contrast level of the color scheme.',
  'settingsAppearanceContrastReduced': 'Reduced',
  'settingsAppearanceContrastHigh': 'High',
  'settingsAppearanceDensity': 'Density',
  'settingsAppearanceDensityDescription':
      'Apply spacing and component density across the app.',
  'settingsAppearanceDensityExtraDense': 'Extra Dense',
  'settingsAppearanceDensityDense': 'Dense',
  'settingsAppearanceDensityNormal': 'Normal',
  'settingsAppearanceDensitySpacious': 'Spacious',
  'settingsAppearanceDensityExtraSpacious': 'Extra Spacious',
  'settingsAppearanceThinkingBubbles': 'Thinking bubbles',
  'settingsAppearanceThinkingBubblesDescription':
      'Show or hide reasoning blocks in assistant messages.',
  'settingsAppearanceToolCallBubbles': 'Tool call bubbles',
  'settingsAppearanceToolCallBubblesDescription':
      'Show or hide tool execution cards in assistant messages.',
  'settingsAppearanceTaskList': 'Task list',
  'settingsAppearanceTaskListDescription':
      'Show or hide the session task list widget.',
  'settingsAppearanceComposerTips': 'Composer tips',
  'settingsAppearanceComposerTipsDescription':
      'Show or hide rotating tips while the assistant is reasoning.',

  // ── Settings ─ Notifications section ────────────────────────────
  'settingsNotificationsSectionTitle': 'Notifications',
  'settingsNotificationsSectionDescription':
      'Control when alerts appear and when they can play sound.',
  'settingsNotificationsSyncInfo':
      'Some category on/off toggles are synced from /config on the active server.',
  'settingsNotificationsSyncInfoLocal':
      'Current server does not expose notification toggles in /config; local values are active.',
  'settingsNotificationsAgentUpdates': 'Agent updates',
  'settingsNotificationsAgentSubtitle': 'When a response finishes',
  'settingsNotificationsPermissions': 'Permissions and questions',
  'settingsNotificationsPermissionsSubtitle':
      'When tools request your input',
  'settingsNotificationsErrors': 'Errors',
  'settingsNotificationsErrorsSubtitle':
      'When a session reports a failure',
  'settingsNotificationsBackgroundAlerts':
      'Android background alerts',
  'settingsNotificationsBackgroundDescription':
      'Use low-data background monitoring for response completions, permission requests, questions, and errors while the app is not on screen.',
  'settingsNotificationsBackgroundToggle':
      'Background alerts on Android',
  'settingsNotificationsBackgroundToggleDescription':
      'Turn off all Android background checks and hide the persistent monitor notification.',
  'settingsNotificationsKeepLive':
      'Keep alerts live for 3 min',
  'settingsNotificationsKeepLiveDescription':
      'When a response is already running, keep realtime active briefly after leaving the app.',
  'settingsNotificationsBatteryOptimization':
      'Android battery optimization',
  'settingsNotificationsBatteryDescription':
      'If notifications only arrive when reopening the app, allow CodeWalk to run without optimization on this device.',
  'settingsNotificationsBatteryDisabled':
      'Battery optimization is disabled for CodeWalk.',
  'settingsNotificationsBatteryEnabled':
      'Battery optimization is enabled. Some devices may delay background alerts.',
  'settingsNotificationsBatteryUnknown':
      'Could not read battery optimization status yet.',
  'settingsNotificationsOpenBatterySettings':
      'Open battery settings',
  'settingsNotificationsDisableOptimization':
      'Disable optimization',
  'settingsNotificationsRefreshStatus': 'Refresh status',
  'settingsNotificationsBackgroundBehavior':
      'Background behavior',
  'settingsNotificationsBackgroundBehaviorDescription':
      'Choose how CodeWalk behaves after the app leaves the foreground.',
  'settingsNotificationsCloseToTray': 'Close to tray',
  'settingsNotificationsCloseToTrayDescription':
      'Hide window and keep running in system tray.',
  'settingsNotificationsMinimizeWhenClose':
      'Minimize when close',
  'settingsNotificationsMinimizeWhenCloseDescription':
      'Minimize to taskbar/dock and keep running.',
  'settingsNotificationsJustClose': 'Just close',
  'settingsNotificationsJustCloseDescription':
      'Exit the application completely.',
  'settingsNotificationsWhenClosing':
      'When closing the window',
  'settingsNotificationsNotify': 'Notify',
  'settingsNotificationsSound': 'Sound',
  'settingsNotificationsNotifyOnlyWhen': 'Notify only when',
  'settingsNotificationsSoundOnlyWhen': 'Sound only when',
  'settingsNotificationsAppInBackground':
      'App in background',
  'settingsNotificationsAnotherConversation':
      'Another conversation',
  'settingsNotificationsNoCondition':
      'If no condition is selected, alerts are allowed in any context.',
  'settingsNotificationsSoundType': 'Sound type',
  'settingsNotificationsSearchSoundType':
      'Search sound type',
  'settingsNotificationsSelectedSound':
      'Selected: {label}',
  'settingsNotificationsChooseSystemSound':
      'Choose system sound',
  'settingsNotificationsChooseAudioFile': 'Choose audio file',
  'settingsNotificationsPreview': 'Preview',
  'settingsNotificationsServer': 'Server',
  'settingsNotificationsLocal': 'Local',
  'settingsNotificationsSystemSoundPickerTitle':
      'Choose system sound',

  // ── Settings ─ Servers section ──────────────────────────────────
  'settingsServersActive': 'Active',
  'settingsServersDefault': 'Default',
  'settingsServersChooseActive': 'Choose active server',

  // ── Settings ─ Shortcuts section ─────────────────────────────────
  'settingsShortcutsKeyboard': 'Keyboard shortcuts',
  'settingsShortcutsSearch': 'Search shortcuts',

  // ── Settings ─ Speech section ──────────────────────────────────
  'settingsSpeechRefreshStatus': 'Refresh status',
  'settingsSpeechSilenceTimeout': 'Silence timeout: {value}s',

  // ── Settings ─ About section (already partially migrated, adding missing) ──
  'settingsAboutVersion': 'Version',
  'settingsAboutLoading': 'Loading...',
  'settingsAboutVersionBuild': '{version} (build {buildNumber})',
  'settingsAboutUpdateAvailable': 'Update available: v{version}',
  'settingsAboutDownloading': 'Downloading... {percent}%',
  'settingsAboutInstalling': 'Installing...',
  'settingsAboutUpdateInstalled':
      'Update installed. Restart the app to apply.',
  'settingsAboutRetryInstall': 'Retry install',
  'settingsAboutInstallUpdate': 'Install update',
  'settingsAboutDismiss': 'Dismiss',
  'settingsAboutUpToDate': 'You\'re up to date',
  'settingsAboutLatestVersion': 'v{version} is the latest version',
  'settingsAboutCheckOnOpen': 'Check for updates on open',
  'settingsAboutCheckOnOpenDescription':
      'Automatically check when the app starts',
  'settingsAboutCheckForUpdates': 'Check for updates',
  'settingsAboutChecking': 'Checking...',
  'settingsAboutTapToCheck': 'Tap to check for new versions',
  'settingsAboutReplayChatTour': 'Replay chat tour',
  'settingsAboutReplayChatTourDescription':
      'Close settings and show the guided chat walkthrough',
  'settingsAboutResetApp': 'Reset app',
  'settingsAboutEraseAllData': 'Erase all data and restart',
  'settingsAboutResetAppQuestion': 'Reset app?',
  'settingsAboutResetAppWarning':
      'This will erase all servers, settings, and cached data. This action cannot be undone.',

  // ── Settings ─ Chat page top-level ──────────────────────────────
  'settingsBack': 'Back',

  // ── Chat ─ Scaffold / sidebar ───────────────────────────────────
  'chatConversations': 'Conversations',
  'chatProjectContext': 'Project Context',
  'chatNewChat': 'New Chat',
  'chatRefresh': 'Refresh',
  'chatHideConversationsSidebar': 'Hide Conversations sidebar',
  'chatHideUtilitySidebar': 'Hide Utility sidebar',
  'chatFilterSessions': 'Filter sessions',
  'chatSortSessions': 'Sort sessions',
  'chatFilterActive': 'Active',
  'chatFilterArchived': 'Archived',
  'chatFilterAll': 'All',
  'chatSortRecent': 'Recent',
  'chatSortMostRecent': 'Most Recent',
  'chatSortOldest': 'Oldest',
  'chatSortTitle': 'Title',
  'chatSearchConversations': 'Search conversations',
  'chatRecentSessions': 'Recent sessions',
  'chatLoadMore': 'Load more',
  'chatRefreshSessionDetails': 'Refresh session details',

  // ── Chat ─ Chrome / toolbar ─────────────────────────────────────
  'chatClose': 'Close',
  'chatToggleSidebars': 'Toggle sidebars',
  'chatUndoLastTurn': 'Undo last turn',
  'chatRedoLastTurn': 'Redo last undone turn',
  'chatDisplayToggles': 'Display toggles',
  'chatOpenFiles': 'Open Files',
  'chatConversationsPane': 'Conversations',
  'chatRecentSessionsToggle': 'Recent sessions',
  'chatNewChatTourTitle': 'New chat',
  'chatNewChatTourDescription': 'Start a new conversation here.',

  // ── Chat ─ Timeline / empty states ──────────────────────────────
  'chatNoServerYet': 'No server configured yet',
  'chatAddServerToStart': 'Add a server to start chatting.',
  'chatSetUpServer': 'Set up server',
  'chatSelectOrCreate': 'Select or create a conversation to start chatting',
  'chatHelloAssistant': 'Hello! I am your AI assistant',
  'chatKeepWorking': 'Keep working',
  'chatRetryRefresh': 'Retry refresh',
  'chatReturnToMainConversation': 'Return to main conversation',
  'chatSessionActions': 'Session actions',
  'chatCompactContext': 'Compact Context',
  'chatGoToFirst': 'Go to first message',
  'chatGoToLatest': 'Go to latest message',
  'chatUseCurrent': 'Use current',
  'chatRetry': 'Retry',

  // ── Chat ─ Session list actions ─────────────────────────────────
  'sessionRename': 'Rename',
  'sessionCopyLink': 'Copy Link',
  'sessionFork': 'Fork',
  'sessionDelete': 'Delete',
  'sessionRenameTitle': 'Rename Conversation',
  'sessionRenameHint': 'Enter new conversation name',
  'sessionDeleteTitle': 'Delete Conversation',
  'sessionNotAvailable':
      'Conversation is not available for this project yet',
  'sessionFailedRename': 'Failed to rename conversation',
  'sessionFailedUpdateSharing': 'Failed to update sharing state',
  'sessionFailedUpdateArchive': 'Failed to update archive state',
  'sessionActionArchived': 'archived',
  'sessionActionUnarchived': 'unarchived',
  'sessionActionDeleted': 'deleted',
  'sessionActionForked': 'forked',
  'sessionShareLinkCopied': 'Share link copied',
  'sessionTitleHint': 'Conversation title',
  'sessionSaveTitle': 'Save title',
  'sessionCancelRename': 'Cancel rename',
  'sessionKeyboardShortcuts': 'Keyboard shortcuts',

  // ── Permissions & Questions ─────────────────────────────────────
  'permissionReject': 'Reject',
  'permissionAlways': 'Always',
  'permissionAllowOnce': 'Allow Once',
  'permissionReopen': 'Reopen',
  'permissionConfirmReject': 'Confirm Reject',
  'permissionBack': 'Back',

  // ── Model Download Dialogs ──────────────────────────────────────
  'dialogVoiceInputSetup': 'Voice Input Setup',
  'dialogParakeetVoiceSetup': 'Parakeet Voice Setup',
  'dialogSenseVoiceSetup': 'SenseVoice Setup',
  'dialogMoonshineVoiceSetup': 'Moonshine Voice Setup',
  'dialogDownload': 'Download',
  'dialogLanguage': 'Language',
  'dialogSenseVoiceModel': 'SenseVoice model',
  'dialogParakeetModel': 'Parakeet model',
  'dialogMoonshineModelSize': 'Model size',

  // ── Terminal Panel ──────────────────────────────────────────────
  'terminalReconnect': 'Reconnect terminal',
  'terminalClose': 'Close terminal',
  'terminalMinimize': 'Minimize terminal',
  'terminalTryAgain': 'Try again',

  // ── Chat Input / Composer ───────────────────────────────────────
  'composerSend': 'Send',
  'composerShellMode': 'Shell mode',
  'composerChatInput': 'Chat input',
  'composerExtras': 'Extras',
  'composerAddAttachment': 'Add attachment',
  'composerNewQuickReply': 'New quick reply',
  'composerAttachFiles': 'Attach files',
  'composerSelectImages': 'Select Images',
  'composerSelectPdf': 'Select PDF',
  'composerEdit': 'Edit',
  'composerDeleteAction': 'Delete',
  'composerCannedAppendAtCursor': 'Append at cursor',
  'composerCannedReplace': 'Replace',
  'composerCannedSendAutomatically': 'Send automatically',
  'composerCannedScopeGlobal': 'Global',
  'composerCannedScopeProject': 'Project-only',
  'composerCannedLabel': 'Label (optional)',
  'composerCannedText': 'Text',
  'composerCannedNoReplies': 'No quick replies yet.',
  'composerCannedSave': 'Save',

  // ── Tour Showcase ───────────────────────────────────────────────
  'tourSkip': 'Skip',
  'tourBack': 'Back',

  // ── SnackBar / User Messages ────────────────────────────────────
  'msgCopiedToClipboard': 'Copied to clipboard',
  'msgCommandCopied': 'Command copied',
  'msgFailedToSendMessage':
      'Failed to send message. Draft kept for retry.',
  'msgVoiceInputUnavailable':
      'Voice input is unavailable on this device',
  'msgFailedToStartVoiceInput':
      'Failed to start voice input',
  'msgNoValidFilesSelected':
      'No valid files were selected',
  'msgSetupDebugCopied':
      'OpenCode setup debug copied to clipboard',
  'msgFilteredLogsCopied':
      'Filtered logs copied to clipboard',
  'msgSystemSoundPickerUnavailable':
      'System sound picker is not available on this platform.',
  'msgNoSystemSoundsFound':
      'No system sound was found on this device.',
  'msgBatterySettingsOpened':
      'Android battery settings opened. Allow unrestricted battery for CodeWalk.',
  'msgBatterySettingsFailed':
      'Could not open Android battery optimization settings.',
  'msgUpdatedButRefreshFailed':
      'Updated the server setting, but could not refresh chat providers.',
  'msgEnterUsernameToSave':
      'Enter a username to save a custom OpenCode conversation name.',
  'msgClearUsernameNeedsConfigEdit':
      'Clearing the OpenCode conversation username still requires editing config outside the app.',
  'sessionDiffReview': 'Review changes',

  // ── Desktop Tray ────────────────────────────────────────────────
  'trayShow': 'Show',
  'trayQuit': 'Quit',

  // ── Notifications / Background ──────────────────────────────────
  'notifConversationUpdates': 'Conversation updates',

  // ── Chat Model Selector ─────────────────────────────────────────
  'modelLoadingModels': 'Loading models',
  'modelRetryModels': 'Retry models',
  'modelAuto': 'Auto',
  'modelSearchHint': 'Search model or provider',

  // ── File Explorer ───────────────────────────────────────────────
  'filesSearchHint': 'Search files by name or path',
  'filesQuickOpen': 'Quick Open',
  'filesRefresh': 'Refresh files',
  'filesHideSidebar': 'Hide Files sidebar',
  'filesTitle': 'Files',

  // ── Tool Presentation ───────────────────────────────────────────
  'toolRunning': 'Running',
  'toolReading': 'Reading',
  'toolWriting': 'Writing',
  'toolEditing': 'Editing',
  'toolFinding': 'Finding',
  'toolSearching': 'Searching',
  'toolAwaitingInput': 'Awaiting input',
  'toolUpdatingTasks': 'Updating tasks',
  'toolRunningCommand': 'Running command',
  'toolReadingFile': 'Reading file',
  'toolWritingFile': 'Writing file',
  'toolEditingFiles': 'Editing files',
  'toolFindingFiles': 'Finding files',
  'toolSearchingCode': 'Searching code',
  'toolSearchingWeb': 'Searching the web',
  'toolWaitingForInput': 'Waiting for your input',
  'toolUpdatingTaskList': 'Updating task list',
  'toolRunningTask': 'Running task',

  // ── Message Info ────────────────────────────────────────────────
  'msgInfoAgent': 'Agent',
  'msgInfoSnapshot': 'Snapshot',
  'msgInfoPatch': 'Patch',
  'msgInfoCompaction': 'Compaction',
  'msgInfoRetry': 'Retry',
  'msgInfoView': 'View',
  'msgInfoUndoThisTurn': 'Undo this turn',
  'msgInfoMessageInfo': 'Message Info',
  'msgInfoModel': 'Model: {modelId}',
  'msgInfoProvider': 'Provider: {providerId}',
  'msgInfoTokens': 'Tokens: {total}',
  'msgInfoCost': 'Cost: \${cost}',
  'msgInfoNoMetadata': 'No metadata available',

  // ── Common actions ──────────────────────────────────────────────
  'commonCancel': 'Cancel',
  'commonReset': 'Reset',
  'commonSave': 'Save',
  'commonDelete': 'Delete',

  // ── Workspace / Project ─────────────────────────────────────────
  'workspaceProjectDirectory': 'Project directory',
  'workspaceProjectHint': '/repo/my-project',
  'workspaceBrowseDirs': 'Browse directories',
  'workspaceCloseProject': 'Close {project}',
  'workspaceRemoveFromHistory': 'Remove {name} from history',
  'workspaceFilterDirs': 'Filter directories',

  // ── OpenCode Setup Debug ────────────────────────────────────────
  'setupDebugTitle': 'Focused on OpenCode setup',
  'setupDebugStatus': 'Current status',
  'setupDebugEnvironment': 'Environment diagnostics',
  'setupDebugTimeline': 'Timeline',
  'setupDebugServerOutput': 'Latest local server output',
  'setupDebugLogs': 'Captured setup logs',
  'setupDebugNoDetails': 'No captured setup details yet',
  'setupDebugManual': 'Manual troubleshooting',
  'setupDebugPlatform': 'Platform',
  'setupDebugCommandPath': 'Command path',
  'setupDebugOpenCode': 'OpenCode',
  'setupDebugNodeJs': 'Node.js',
  'setupDebugNpm': 'npm',
  'setupDebugBun': 'Bun',
  'setupDebugWsl': 'WSL',
  'setupDebugNetwork': 'Network',
  'setupDebugInstallDir': 'Install directory',
  'setupDebugCopy': 'Copy setup debug',
  'setupDebugClear': 'Clear setup debug',

  // ── Quota ───────────────────────────────────────────────────────
  'quotaForget': 'Forget',
  'quotaOpenCodeGoUsage': 'OpenCode Go usage',
  'quotaOpenDashboard': 'Open OpenCode dashboard',
  'quotaWorkspaceId': 'Workspace ID',
  'quotaAuthCookie': 'Auth cookie',
  'quotaSaving': 'Saving...',

  // ── Canned Answers ──────────────────────────────────────────────
  'cannedNoSuggestions': 'No suggestions',

  // ── Onboarding ──────────────────────────────────────────────────
  'onboardingServerUrl': 'Server URL',
  'onboardingLabel': 'Label (optional)',
  'onboardingLabelHint': 'My server',
  'onboardingUsername': 'Username',
  'onboardingPassword': 'Password',
  'onboardingClear': 'Clear',

  // ── Logs ────────────────────────────────────────────────────────
  'logsSearch': 'Search logs',
  'logsCloseSearch': 'Close search',
  'logsCopyFiltered': 'Copy filtered logs',
  'logsClear': 'Clear logs',
};

/// Per-locale translations.
///
/// Keys not present for a locale fall back to the English value.
const translations = <String, Map<String, String>>{
  'pt': {
    // ── Language Selector ────────────────────────────────────
    'settingsLanguageTitle': 'Idioma',
    'settingsLanguageDescription':
        'Escolha o idioma usado pelo CodeWalk. O padrão do sistema segue o idioma do dispositivo.',
    'settingsLanguageFieldLabel': 'Idioma do app',
    'settingsLanguageFieldHelper':
        'Aplica imediatamente e persiste após reiniciar.',
    'settingsLanguageSearchHint': 'Pesquisar idiomas',
    'settingsLanguageEmptyText': 'Nenhum idioma encontrado',
    'settingsLanguageSystemDefault': 'Padrão do sistema',

    // ── Settings ─ Section titles & descriptions ──────────────
    'settingsTitle': 'Configurações',
    'settingsServersTitle': 'Servidores',
    'settingsServersDescription': 'Servidores OpenCode e roteamento de saúde',
    'settingsAppearanceTitle': 'Aparência',
    'settingsAppearanceDescription': 'Densidade e visibilidade dos balões da timeline',
    'settingsBehaviorTitle': 'Comportamento',
    'settingsBehaviorDescription': 'Padrões OpenCode, procedência e segurança de sincronização do composer',
    'settingsNotificationsTitle': 'Notificações',
    'settingsNotificationsDescription': 'Controles de notificação e som por categoria',
    'settingsSpeechTitle': 'Fala para texto',
    'settingsSpeechDescription': 'Motor, tempo de silêncio e opções de modelo',
    'settingsLogsTitle': 'Logs',
    'settingsLogsDescription': 'Diagnóstico em tempo de execução e dados de solução de problemas',
    'settingsShortcutsTitle': 'Atalhos',
    'settingsShortcutsDescription': 'Atalhos de teclado portáteis do app',
    'settingsAboutTitle': 'Sobre',
    'settingsAboutDescription': 'Versão, atualizações e links',
    'settingsSetupWizard': 'Assistente de configuração',

    // ── Settings ─ Behavior section ───────────────────────────
    'settingsBehaviorMultiDeviceSync':
        'Habilitar sincronização experimental entre dispositivos',
    'settingsBehaviorMultiDeviceSyncDescription':
        'Sincroniza a seleção do composer (agente/modelo/variante) com a config do servidor ativo.',
    'settingsBehaviorMultiDeviceSyncWarning':
        'Pode abortar sessões em andamento ao trabalhar em mais de uma sessão ao mesmo tempo.',
    'settingsBehaviorOpenCodeDefaults': 'Padrões do OpenCode',
    'settingsBehaviorOpenCodeDefaultsDescription':
        'Esses valores gravam em `/config` no servidor ativo e correspondem à config oficial do OpenCode.',
    'settingsBehaviorRefreshDefaults': 'Atualizar padrões',
    'settingsBehaviorDefaultModel': 'Modelo padrão',
    'settingsBehaviorDefaultModelHelp':
        'Compartilhado entre clientes OpenCode via config.',
    'settingsBehaviorSearchDefaultModel': 'Buscar modelo padrão',
    'settingsBehaviorNoModels': 'Nenhum modelo encontrado',
    'settingsBehaviorDefaultAgent': 'Agente padrão',
    'settingsBehaviorDefaultAgentHelp':
        'Agente principal usado quando nenhum agente é escolhido explicitamente.',
    'settingsBehaviorSearchDefaultAgent': 'Buscar agente padrão',
    'settingsBehaviorNoAgents': 'Nenhum agente encontrado',
    'settingsBehaviorConversationUsername': 'Nome de usuário da conversa',
    'settingsBehaviorConversationUsernameHelp':
        'Nome de exibição personalizado mostrado nas conversas em vez do nome do sistema.',
    'settingsBehaviorSaveUsername': 'Salvar nome de usuário',
    'settingsBehaviorUsernameFallback':
        'O OpenCode usa o nome de usuário do sistema porque `username` não está definido.',
    'settingsBehaviorUsernamePatchCaveat':
        'Redefinir `username` de volta ao padrão do sistema ainda requer editar a config fora do app porque atualizações de patch `/config` não podem remover chaves.',
    'settingsBehaviorOpenCodeSnapshots': 'Snapshots do OpenCode',
    'settingsBehaviorOpenCodeSnapshotsDescription':
        'Manter snapshots git habilitados para histórico de desfazer/refazer e recuperação.',
    'settingsBehaviorSnapshotCaveat':
        'Isso controla o armazenamento de snapshots e suporte a undo/redo do OpenCode, não os snapshots de cache local do CodeWalk.',
    'settingsBehaviorSmallModel': 'Modelo pequeno',
    'settingsBehaviorSmallModelHelp':
        'Usado para tarefas leves como geração de títulos.',
    'settingsBehaviorSearchSmallModel': 'Buscar modelo pequeno',
    'settingsBehaviorSmallModelAutoFallback': 'Fallback automático',
    'settingsBehaviorSmallModelFallbackActive':
        'O fallback automático do OpenCode está ativo porque `small_model` não está definido.',
    'settingsBehaviorSmallModelResetCaveat':
        'Redefinir `small_model` de volta ao fallback automático ainda requer editar a config fora do app.',
    'settingsBehaviorOpenCodeAutoupdate': 'Atualização automática do OpenCode',
    'settingsBehaviorAutoupdateHelp':
        'Controla as atualizações de runtime do OpenCode upstream, não as verificações de atualização do app CodeWalk.',
    'settingsBehaviorSearchAutoupdate': 'Buscar modo de atualização',
    'settingsBehaviorAutoupdateCaveat':
        'Use a seção Sobre para verificações de versão do CodeWalk. Esta configuração apenas espelha a config `autoupdate` oficial do OpenCode.',
    'settingsBehaviorShareMode': 'Padrão de compartilhamento do OpenCode',
    'settingsBehaviorShareModeHelp':
        'Controla a config global oficial `share`, não o botão de compartilhar de um chat individual.',
    'settingsBehaviorSearchShareMode': 'Buscar modo de compartilhamento',
    'settingsBehaviorShareModeCaveat':
        'Use a ação de compartilhar no chat para publicar uma sessão agora. Esta configuração apenas altera a política de compartilhamento padrão do OpenCode.',
    'settingsBehaviorPermissionProvenance': 'Procedência do tratamento de permissões',
    'settingsBehaviorPermissionProvenanceDescription':
        'A política oficial de permissão do OpenCode é configurada no `opencode.json` com regras allow/ask/deny por ferramenta. O CodeWalk mantém os cards oficiais de solicitação de permissão e adiciona uma exceção ADR-023 aprovada: o toggle de auto-aprovação do composer responde com `Always` quando a solicitação suporta aprovação lembrada, caso contrário `Allow Once`. O mesmo caminho de continuidade com escopo de thread permanece ativo no worker Android em segundo plano.',
    'settingsBehaviorPermissionDeferred':
        'A edição avançada de regras de permissão fica fora das Configurações por enquanto e é adiada para trabalho futuro de paridade.',
    'settingsBehaviorCellularDataSaver': 'Economia de dados móveis',
    'settingsBehaviorDataSaverDescription':
        'Reduz o uso automático de dados móveis interrompendo downloads em segundo plano e limitando as atualizações automáticas em primeiro plano.',
    'settingsBehaviorEnableDataSaver': 'Habilitar economia de dados móveis',
    'settingsBehaviorDataSaverActive':
        'Ativo agora em dados móveis.',
    'settingsBehaviorDataSaverWaiting':
        'Aguardando a próxima janela de sincronização de dados móveis.',
    'settingsBehaviorDataSaverCellularOnly':
        'Aplica-se apenas quando a conexão for celular/móvel.',
    'settingsBehaviorConfigDeferred':
        'O CodeWalk aplicará esta configuração do OpenCode após a resposta atual terminar.',
    'settingsBehaviorConfigUpdateFailed':
        'Não foi possível atualizar o {field} do OpenCode.',

    // ── Settings ─ Appearance section ─────────────────────────
    'settingsAppearanceSectionTitle': 'Aparência',
    'settingsAppearanceSectionDescription':
        'Ajuste a densidade visual e as superfícies de mensagem para o seu fluxo de trabalho.',
    'settingsAppearanceTheme': 'Tema',
    'settingsAppearanceThemeDescription':
        'Escolha entre modo claro, escuro ou sistema, depois mantenha a paleta clássica do CodeWalk ou mude para um preset OpenCode.',
    'settingsAppearanceSystem': 'Sistema',
    'settingsAppearanceLight': 'Claro',
    'settingsAppearanceDark': 'Escuro',
    'settingsAppearanceCodeWalkClassic': 'CodeWalk Clássico',
    'settingsAppearanceOpenCodePresets': 'Presets OpenCode',
    'settingsAppearancePresetPalette': 'Paleta predefinida',
    'settingsAppearancePresetHelper':
        'Espelha a lista oficial de temas integrados do OpenCode Web.',
    'settingsAppearanceSearchPreset': 'Buscar paleta predefinida',
    'settingsAppearanceNoPresets': 'Nenhuma paleta encontrada',
    'settingsAppearancePresetNote':
        'As cores do tema agora seguem o registro oficial do OpenCode Web e também orientam as superfícies de markdown/código.',
    'settingsAppearanceAmoledDark': 'Modo escuro AMOLED',
    'settingsAppearanceAmoledDarkActive':
        'Usar superfícies pretas puras enquanto o modo escuro estiver ativo.',
    'settingsAppearanceAmoledDarkInactive':
        'Mude para o modo escuro para habilitar superfícies AMOLED.',
    'settingsAppearanceWallpaperColors': 'Usar cores do papel de parede',
    'settingsAppearanceWallpaperPresetBlocked':
        'Mude para CodeWalk Clássico para usar cores do papel de parede.',
    'settingsAppearanceWallpaperNormal':
        'Extrair esquema de cores do papel de parede do dispositivo.',
    'settingsAppearanceBrandColor': 'Cor da marca',
    'settingsAppearanceBrandColorPresetBlocked':
        'Mude para CodeWalk Clássico para escolher uma cor da marca.',
    'settingsAppearanceBrandColorDynamicBlocked':
        'Desative as cores do papel de parede para escolher uma cor da marca.',
    'settingsAppearanceBrandColorNormal':
        'Escolha uma cor semente para a paleta do app.',
    'settingsAppearanceContrast': 'Contraste',
    'settingsAppearanceContrastPresetBlocked':
        'Mude para CodeWalk Clássico para ajustar o contraste.',
    'settingsAppearanceContrastDynamicBlocked':
        'Desative as cores do papel de parede para ajustar o contraste.',
    'settingsAppearanceContrastNormal':
        'Ajuste o nível de contraste do esquema de cores.',
    'settingsAppearanceContrastReduced': 'Reduzido',
    'settingsAppearanceContrastHigh': 'Alto',
    'settingsAppearanceDensity': 'Densidade',
    'settingsAppearanceDensityDescription':
        'Aplica espaçamento e densidade de componentes em todo o app.',
    'settingsAppearanceDensityExtraDense': 'Extra Densa',
    'settingsAppearanceDensityDense': 'Densa',
    'settingsAppearanceDensityNormal': 'Normal',
    'settingsAppearanceDensitySpacious': 'Espaçosa',
    'settingsAppearanceDensityExtraSpacious': 'Extra Espaçosa',
    'settingsAppearanceThinkingBubbles': 'Balões de pensamento',
    'settingsAppearanceThinkingBubblesDescription':
        'Mostrar ou ocultar blocos de raciocínio nas mensagens do assistente.',
    'settingsAppearanceToolCallBubbles': 'Balões de chamada de ferramenta',
    'settingsAppearanceToolCallBubblesDescription':
        'Mostrar ou ocultar cartões de execução de ferramentas nas mensagens do assistente.',
    'settingsAppearanceTaskList': 'Lista de tarefas',
    'settingsAppearanceTaskListDescription':
        'Mostrar ou ocultar o widget de lista de tarefas da sessão.',
    'settingsAppearanceComposerTips': 'Dicas do composer',
    'settingsAppearanceComposerTipsDescription':
        'Mostrar ou ocultar dicas rotativas enquanto o assistente está raciocinando.',

    // ── Settings ─ Notifications section ──────────────────────
    'settingsNotificationsSectionTitle': 'Notificações',
    'settingsNotificationsSectionDescription':
        'Controle quando os alertas aparecem e quando podem reproduzir som.',
    'settingsNotificationsSyncInfo':
        'Alguns toggles de categoria são sincronizados do /config no servidor ativo.',
    'settingsNotificationsSyncInfoLocal':
        'O servidor atual não expõe toggles de notificação no /config; os valores locais estão ativos.',
    'settingsNotificationsAgentUpdates': 'Atualizações do agente',
    'settingsNotificationsAgentSubtitle': 'Quando uma resposta termina',
    'settingsNotificationsPermissions': 'Permissões e perguntas',
    'settingsNotificationsPermissionsSubtitle':
        'Quando ferramentas solicitam sua entrada',
    'settingsNotificationsErrors': 'Erros',
    'settingsNotificationsErrorsSubtitle':
        'Quando uma sessão relata uma falha',
    'settingsNotificationsBackgroundAlerts':
        'Alertas em segundo plano Android',
    'settingsNotificationsBackgroundDescription':
        'Usa monitoramento de baixo consumo de dados em segundo plano para conclusões de resposta, solicitações de permissão, perguntas e erros enquanto o app não está na tela.',
    'settingsNotificationsBackgroundToggle':
        'Alertas em segundo plano no Android',
    'settingsNotificationsBackgroundToggleDescription':
        'Desativa todas as verificações em segundo plano do Android e oculta a notificação persistente do monitor.',
    'settingsNotificationsKeepLive':
        'Manter alertas ativos por 3 min',
    'settingsNotificationsKeepLiveDescription':
        'Quando uma resposta já está em execução, mantém o tempo real ativo brevemente após sair do app.',
    'settingsNotificationsBatteryOptimization':
        'Otimização de bateria do Android',
    'settingsNotificationsBatteryDescription':
        'Se as notificações só chegam ao reabrir o app, permita que o CodeWalk execute sem otimização neste dispositivo.',
    'settingsNotificationsBatteryDisabled':
        'A otimização de bateria está desativada para o CodeWalk.',
    'settingsNotificationsBatteryEnabled':
        'A otimização de bateria está ativada. Alguns dispositivos podem atrasar os alertas em segundo plano.',
    'settingsNotificationsBatteryUnknown':
        'Ainda não foi possível ler o status de otimização de bateria.',
    'settingsNotificationsOpenBatterySettings':
        'Abrir configurações de bateria',
    'settingsNotificationsDisableOptimization':
        'Desativar otimização',
    'settingsNotificationsRefreshStatus': 'Atualizar status',
    'settingsNotificationsBackgroundBehavior':
        'Comportamento em segundo plano',
    'settingsNotificationsBackgroundBehaviorDescription':
        'Escolha como o CodeWalk se comporta depois que o app sai do primeiro plano.',
    'settingsNotificationsCloseToTray': 'Fechar para bandeja',
    'settingsNotificationsCloseToTrayDescription':
        'Ocultar janela e continuar executando na bandeja do sistema.',
    'settingsNotificationsMinimizeWhenClose':
        'Minimizar ao fechar',
    'settingsNotificationsMinimizeWhenCloseDescription':
        'Minimizar para a barra de tarefas/dock e continuar executando.',
    'settingsNotificationsJustClose': 'Apenas fechar',
    'settingsNotificationsJustCloseDescription':
        'Sair completamente do aplicativo.',
    'settingsNotificationsWhenClosing':
        'Ao fechar a janela',
    'settingsNotificationsNotify': 'Notificar',
    'settingsNotificationsSound': 'Som',
    'settingsNotificationsNotifyOnlyWhen': 'Notificar apenas quando',
    'settingsNotificationsSoundOnlyWhen': 'Som apenas quando',
    'settingsNotificationsAppInBackground':
        'App em segundo plano',
    'settingsNotificationsAnotherConversation':
        'Outra conversa',
    'settingsNotificationsNoCondition':
        'Se nenhuma condição for selecionada, os alertas são permitidos em qualquer contexto.',
    'settingsNotificationsSoundType': 'Tipo de som',
    'settingsNotificationsSearchSoundType':
        'Buscar tipo de som',
    'settingsNotificationsSelectedSound':
        'Selecionado: {label}',
    'settingsNotificationsChooseSystemSound':
        'Escolher som do sistema',
    'settingsNotificationsChooseAudioFile': 'Escolher arquivo de áudio',
    'settingsNotificationsPreview': 'Pré-visualizar',
    'settingsNotificationsServer': 'Servidor',
    'settingsNotificationsLocal': 'Local',
    'settingsNotificationsSystemSoundPickerTitle':
        'Escolher som do sistema',

    // ── Settings ─ Servers ────────────────────────────────────
    'settingsServersActive': 'Ativo',
    'settingsServersDefault': 'Padrão',
    'settingsServersChooseActive': 'Escolher servidor ativo',

    // ── Settings ─ Shortcuts ──────────────────────────────────
    'settingsShortcutsKeyboard': 'Atalhos de teclado',
    'settingsShortcutsSearch': 'Buscar atalhos',

    // ── Settings ─ Speech ─────────────────────────────────────
    'settingsSpeechRefreshStatus': 'Atualizar status',
    'settingsSpeechSilenceTimeout': 'Tempo de silêncio: {value}s',

    // ── Settings ─ About ──────────────────────────────────────
    'settingsAboutVersion': 'Versão',
    'settingsAboutLoading': 'Carregando...',
    'settingsAboutVersionBuild': '{version} (build {buildNumber})',
    'settingsAboutUpdateAvailable': 'Atualização disponível: v{version}',
    'settingsAboutDownloading': 'Baixando... {percent}%',
    'settingsAboutInstalling': 'Instalando...',
    'settingsAboutUpdateInstalled':
        'Atualização instalada. Reinicie o app para aplicar.',
    'settingsAboutRetryInstall': 'Tentar instalar novamente',
    'settingsAboutInstallUpdate': 'Instalar atualização',
    'settingsAboutDismiss': 'Dispensar',
    'settingsAboutUpToDate': 'Você está em dia',
    'settingsAboutLatestVersion': 'v{version} é a versão mais recente',
    'settingsAboutCheckOnOpen': 'Verificar atualizações ao abrir',
    'settingsAboutCheckOnOpenDescription':
        'Verificar automaticamente quando o app iniciar',
    'settingsAboutCheckForUpdates': 'Verificar atualizações',
    'settingsAboutChecking': 'Verificando...',
    'settingsAboutTapToCheck': 'Toque para buscar novas versões',
    'settingsAboutReplayChatTour': 'Repetir tour do chat',
    'settingsAboutReplayChatTourDescription':
        'Fechar configurações e mostrar o guia do chat',
    'settingsAboutResetApp': 'Redefinir app',
    'settingsAboutEraseAllData': 'Apagar todos os dados e reiniciar',
    'settingsAboutResetAppQuestion': 'Redefinir app?',
    'settingsAboutResetAppWarning':
        'Isso apagará todos os servidores, configurações e dados em cache. Esta ação não pode ser desfeita.',

    // ── Settings ─ Chat top-level ─────────────────────────────
    'settingsBack': 'Voltar',

    // ── Chat ─ Scaffold / sidebar ─────────────────────────────
    'chatConversations': 'Conversas',
    'chatProjectContext': 'Contexto do Projeto',
    'chatNewChat': 'Nova Conversa',
    'chatRefresh': 'Atualizar',
    'chatHideConversationsSidebar': 'Ocultar barra de Conversas',
    'chatHideUtilitySidebar': 'Ocultar barra de Utilidades',
    'chatFilterSessions': 'Filtrar sessões',
    'chatSortSessions': 'Ordenar sessões',
    'chatFilterActive': 'Ativas',
    'chatFilterArchived': 'Arquivadas',
    'chatFilterAll': 'Todas',
    'chatSortRecent': 'Recentes',
    'chatSortMostRecent': 'Mais Recentes',
    'chatSortOldest': 'Mais Antigas',
    'chatSortTitle': 'Título',
    'chatSearchConversations': 'Buscar conversas',
    'chatRecentSessions': 'Sessões recentes',
    'chatLoadMore': 'Carregar mais',
    'chatRefreshSessionDetails': 'Atualizar detalhes da sessão',

    // ── Chat ─ Chrome / toolbar ───────────────────────────────
    'chatClose': 'Fechar',
    'chatToggleSidebars': 'Alternar barras laterais',
    'chatUndoLastTurn': 'Desfazer último turno',
    'chatRedoLastTurn': 'Refazer último turno desfeito',
    'chatDisplayToggles': 'Opções de exibição',
    'chatOpenFiles': 'Abrir Arquivos',
    'chatConversationsPane': 'Conversas',
    'chatRecentSessionsToggle': 'Sessões recentes',
    'chatNewChatTourTitle': 'Nova conversa',
    'chatNewChatTourDescription': 'Inicie uma nova conversa aqui.',

    // ── Chat ─ Timeline / empty states ────────────────────────
    'chatNoServerYet': 'Nenhum servidor configurado ainda',
    'chatAddServerToStart': 'Adicione um servidor para começar a conversar.',
    'chatSetUpServer': 'Configurar servidor',
    'chatSelectOrCreate': 'Selecione ou crie uma conversa para começar',
    'chatHelloAssistant': 'Olá! Eu sou seu assistente de IA',
    'chatKeepWorking': 'Continuar trabalhando',
    'chatRetryRefresh': 'Tentar atualizar novamente',
    'chatReturnToMainConversation': 'Voltar à conversa principal',
    'chatSessionActions': 'Ações da sessão',
    'chatCompactContext': 'Compactar Contexto',
    'chatGoToFirst': 'Ir para primeira mensagem',
    'chatGoToLatest': 'Ir para última mensagem',
    'chatUseCurrent': 'Usar atual',
    'chatRetry': 'Tentar novamente',

    // ── Chat ─ Session list actions ───────────────────────────
    'sessionRename': 'Renomear',
    'sessionCopyLink': 'Copiar Link',
    'sessionFork': 'Bifurcar',
    'sessionDelete': 'Excluir',
    'sessionRenameTitle': 'Renomear Conversa',
    'sessionRenameHint': 'Digite o novo nome da conversa',
    'sessionDeleteTitle': 'Excluir Conversa',
    'sessionNotAvailable':
        'A conversa ainda não está disponível para este projeto',
    'sessionFailedRename': 'Falha ao renomear conversa',
    'sessionFailedUpdateSharing': 'Falha ao atualizar estado de compartilhamento',
    'sessionFailedUpdateArchive': 'Falha ao atualizar estado de arquivamento',
    'sessionActionArchived': 'arquivada',
    'sessionActionUnarchived': 'desarquivada',
    'sessionActionDeleted': 'excluída',
    'sessionActionForked': 'bifurcada',
    'sessionShareLinkCopied': 'Link de compartilhamento copiado',
    'sessionTitleHint': 'Título da conversa',
    'sessionSaveTitle': 'Salvar título',
    'sessionCancelRename': 'Cancelar renomeação',
    'sessionKeyboardShortcuts': 'Atalhos de teclado',

    // ── Permissions & Questions ───────────────────────────────
    'permissionReject': 'Rejeitar',
    'permissionAlways': 'Sempre',
    'permissionAllowOnce': 'Permitir Uma Vez',
    'permissionReopen': 'Reabrir',
    'permissionConfirmReject': 'Confirmar Rejeição',
    'permissionBack': 'Voltar',

    // ── Model Download Dialogs ────────────────────────────────
    'dialogVoiceInputSetup': 'Configuração de Entrada de Voz',
    'dialogParakeetVoiceSetup': 'Configuração de Voz Parakeet',
    'dialogSenseVoiceSetup': 'Configuração SenseVoice',
    'dialogMoonshineVoiceSetup': 'Configuração de Voz Moonshine',
    'dialogDownload': 'Baixar',
    'dialogLanguage': 'Idioma',
    'dialogSenseVoiceModel': 'Modelo SenseVoice',
    'dialogParakeetModel': 'Modelo Parakeet',
    'dialogMoonshineModelSize': 'Tamanho do modelo',

    // ── Terminal Panel ────────────────────────────────────────
    'terminalReconnect': 'Reconectar terminal',
    'terminalClose': 'Fechar terminal',
    'terminalMinimize': 'Minimizar terminal',
    'terminalTryAgain': 'Tentar novamente',

    // ── Chat Input / Composer ─────────────────────────────────
    'composerSend': 'Enviar',
    'composerShellMode': 'Modo shell',
    'composerChatInput': 'Entrada de chat',
    'composerExtras': 'Extras',
    'composerAddAttachment': 'Adicionar anexo',
    'composerNewQuickReply': 'Nova resposta rápida',
    'composerAttachFiles': 'Anexar arquivos',
    'composerSelectImages': 'Selecionar Imagens',
    'composerSelectPdf': 'Selecionar PDF',
    'composerEdit': 'Editar',
    'composerDeleteAction': 'Excluir',
    'composerCannedAppendAtCursor': 'Anexar no cursor',
    'composerCannedReplace': 'Substituir',
    'composerCannedSendAutomatically': 'Enviar automaticamente',
    'composerCannedScopeGlobal': 'Global',
    'composerCannedScopeProject': 'Apenas do projeto',
    'composerCannedLabel': 'Rótulo (opcional)',
    'composerCannedText': 'Texto',
    'composerCannedNoReplies': 'Nenhuma resposta rápida ainda.',
    'composerCannedSave': 'Salvar',

    // ── Tour Showcase ─────────────────────────────────────────
    'tourSkip': 'Pular',
    'tourBack': 'Voltar',

    // ── SnackBar / User Messages ──────────────────────────────
    'msgCopiedToClipboard': 'Copiado para a área de transferência',
    'msgCommandCopied': 'Comando copiado',
    'msgFailedToSendMessage':
        'Falha ao enviar mensagem. Rascunho mantido para nova tentativa.',
    'msgVoiceInputUnavailable':
        'Entrada de voz indisponível neste dispositivo',
    'msgFailedToStartVoiceInput':
        'Falha ao iniciar entrada de voz',
    'msgNoValidFilesSelected':
        'Nenhum arquivo válido foi selecionado',
    'msgSetupDebugCopied':
        'Debug de configuração do OpenCode copiado',
    'msgFilteredLogsCopied':
        'Logs filtrados copiados para a área de transferência',
    'msgSystemSoundPickerUnavailable':
        'Seletor de som do sistema não está disponível nesta plataforma.',
    'msgNoSystemSoundsFound':
        'Nenhum som do sistema foi encontrado neste dispositivo.',
    'msgBatterySettingsOpened':
        'Configurações de bateria do Android abertas. Permita bateria irrestrita para o CodeWalk.',
    'msgBatterySettingsFailed':
        'Não foi possível abrir as configurações de otimização de bateria do Android.',
    'msgUpdatedButRefreshFailed':
        'Configuração do servidor atualizada, mas não foi possível atualizar os provedores de chat.',
    'msgEnterUsernameToSave':
        'Digite um nome de usuário para salvar um nome de conversa personalizado do OpenCode.',
    'msgClearUsernameNeedsConfigEdit':
        'Limpar o nome de usuário da conversa do OpenCode ainda requer editar a config fora do app.',
    'sessionDiffReview': 'Revisar alterações',

    // ── Desktop Tray ──────────────────────────────────────────
    'trayShow': 'Mostrar',
    'trayQuit': 'Sair',

    // ── Notifications / Background ────────────────────────────
    'notifConversationUpdates': 'Atualizações de conversa',

    // ── Chat Model Selector ───────────────────────────────────
    'modelLoadingModels': 'Carregando modelos',
    'modelRetryModels': 'Tentar modelos novamente',
    'modelAuto': 'Automático',
    'modelSearchHint': 'Buscar modelo ou provedor',

    // ── File Explorer ─────────────────────────────────────────
    'filesSearchHint': 'Buscar arquivos por nome ou caminho',
    'filesQuickOpen': 'Abertura Rápida',
    'filesRefresh': 'Atualizar arquivos',
    'filesHideSidebar': 'Ocultar barra de Arquivos',
    'filesTitle': 'Arquivos',

    // ── Tool Presentation ─────────────────────────────────────
    'toolRunning': 'Executando',
    'toolReading': 'Lendo',
    'toolWriting': 'Escrevendo',
    'toolEditing': 'Editando',
    'toolFinding': 'Buscando',
    'toolSearching': 'Pesquisando',
    'toolAwaitingInput': 'Aguardando entrada',
    'toolUpdatingTasks': 'Atualizando tarefas',
    'toolRunningCommand': 'Executando comando',
    'toolReadingFile': 'Lendo arquivo',
    'toolWritingFile': 'Escrevendo arquivo',
    'toolEditingFiles': 'Editando arquivos',
    'toolFindingFiles': 'Buscando arquivos',
    'toolSearchingCode': 'Pesquisando código',
    'toolSearchingWeb': 'Pesquisando na web',
    'toolWaitingForInput': 'Aguardando sua entrada',
    'toolUpdatingTaskList': 'Atualizando lista de tarefas',
    'toolRunningTask': 'Executando tarefa',

    // ── Message Info ──────────────────────────────────────────
    'msgInfoAgent': 'Agente',
    'msgInfoSnapshot': 'Snapshot',
    'msgInfoPatch': 'Patch',
    'msgInfoCompaction': 'Compactação',
    'msgInfoRetry': 'Tentativa',
    'msgInfoView': 'Ver',
    'msgInfoUndoThisTurn': 'Desfazer este turno',
    'msgInfoMessageInfo': 'Informações da Mensagem',
    'msgInfoModel': 'Modelo: {modelId}',
    'msgInfoProvider': 'Provedor: {providerId}',
    'msgInfoTokens': 'Tokens: {total}',
    'msgInfoCost': 'Custo: R\${cost}',
    'msgInfoNoMetadata': 'Nenhum metadado disponível',

    // ── Common actions ────────────────────────────────────────
    'commonCancel': 'Cancelar',
    'commonReset': 'Redefinir',
    'commonSave': 'Salvar',
    'commonDelete': 'Excluir',

    // ── Workspace / Project ───────────────────────────────────
    'workspaceProjectDirectory': 'Diretório do projeto',
    'workspaceProjectHint': '/repo/meu-projeto',
    'workspaceBrowseDirs': 'Navegar diretórios',
    'workspaceCloseProject': 'Fechar {project}',
    'workspaceRemoveFromHistory': 'Remover {name} do histórico',
    'workspaceFilterDirs': 'Filtrar diretórios',

    // ── OpenCode Setup Debug ──────────────────────────────────
    'setupDebugTitle': 'Focado na configuração do OpenCode',
    'setupDebugStatus': 'Status atual',
    'setupDebugEnvironment': 'Diagnóstico do ambiente',
    'setupDebugTimeline': 'Linha do tempo',
    'setupDebugServerOutput': 'Última saída do servidor local',
    'setupDebugLogs': 'Logs de configuração capturados',
    'setupDebugNoDetails': 'Nenhum detalhe de configuração capturado ainda',
    'setupDebugManual': 'Solução de problemas manual',
    'setupDebugPlatform': 'Plataforma',
    'setupDebugCommandPath': 'Caminho do comando',
    'setupDebugOpenCode': 'OpenCode',
    'setupDebugNodeJs': 'Node.js',
    'setupDebugNpm': 'npm',
    'setupDebugBun': 'Bun',
    'setupDebugWsl': 'WSL',
    'setupDebugNetwork': 'Rede',
    'setupDebugInstallDir': 'Diretório de instalação',
    'setupDebugCopy': 'Copiar debug de configuração',
    'setupDebugClear': 'Limpar debug de configuração',

    // ── Quota ─────────────────────────────────────────────────
    'quotaForget': 'Esquecer',
    'quotaOpenCodeGoUsage': 'Uso do OpenCode Go',
    'quotaOpenDashboard': 'Abrir dashboard OpenCode',
    'quotaWorkspaceId': 'ID do Workspace',
    'quotaAuthCookie': 'Cookie de autenticação',
    'quotaSaving': 'Salvando...',

    // ── Canned Answers ────────────────────────────────────────
    'cannedNoSuggestions': 'Nenhuma sugestão',

    // ── Onboarding ────────────────────────────────────────────
    'onboardingServerUrl': 'URL do servidor',
    'onboardingLabel': 'Rótulo (opcional)',
    'onboardingLabelHint': 'Meu servidor',
    'onboardingUsername': 'Usuário',
    'onboardingPassword': 'Senha',
    'onboardingClear': 'Limpar',

    // ── Logs ──────────────────────────────────────────────────
    'logsSearch': 'Buscar logs',
    'logsCloseSearch': 'Fechar busca',
    'logsCopyFiltered': 'Copiar logs filtrados',
    'logsClear': 'Limpar logs',
  },

  'es': {
    'settingsLanguageTitle': 'Idioma',
    'settingsLanguageDescription':
        'Elige el idioma que usa CodeWalk. El valor predeterminado del sistema sigue el idioma del dispositivo.',
    'settingsLanguageFieldLabel': 'Idioma de la app',
    'settingsLanguageFieldHelper':
        'Se aplica de inmediato y se mantiene tras reiniciar.',
    'settingsLanguageSearchHint': 'Buscar idiomas',
    'settingsLanguageEmptyText': 'No se encontraron idiomas',
    'settingsLanguageSystemDefault': 'Predeterminado del sistema',
    'settingsTitle': 'Configuración',
    'settingsServersTitle': 'Servidores',
    'settingsServersDescription': 'Servidores OpenCode y enrutamiento de salud',
    'settingsAppearanceTitle': 'Apariencia',
    'settingsAppearanceDescription': 'Densidad y visibilidad de burbujas de la línea de tiempo',
    'settingsBehaviorTitle': 'Comportamiento',
    'settingsBehaviorDescription': 'Valores predeterminados de OpenCode, procedencia y seguridad de sincronización del compositor',
    'settingsNotificationsTitle': 'Notificaciones',
    'settingsNotificationsDescription': 'Controles de notificación y sonido por categoría',
    'settingsSpeechTitle': 'Voz a texto',
    'settingsSpeechDescription': 'Motor, tiempo de silencio y opciones de modelo',
    'settingsLogsTitle': 'Registros',
    'settingsLogsDescription': 'Diagnóstico en tiempo de ejecución y solución de problemas',
    'settingsShortcutsTitle': 'Atajos',
    'settingsShortcutsDescription': 'Combinaciones de teclas portátiles de la app',
    'settingsAboutTitle': 'Acerca de',
    'settingsAboutDescription': 'Versión, actualizaciones y enlaces',
    'settingsSetupWizard': 'Asistente de configuración',
    'settingsBehaviorMultiDeviceSync': 'Habilitar sincronización multidispositivo experimental',
    'settingsBehaviorMultiDeviceSyncDescription': 'Sincroniza la selección del compositor (agente/modelo/variante) con la configuración del servidor activo.',
    'settingsBehaviorMultiDeviceSyncWarning': 'Puede abortar sesiones en curso al trabajar en más de una sesión al mismo tiempo.',
    'settingsBehaviorOpenCodeDefaults': 'Valores predeterminados de OpenCode',
    'settingsBehaviorOpenCodeDefaultsDescription': 'Estos valores escriben en `/config` en el servidor activo y coinciden con la configuración oficial de OpenCode.',
    'settingsBehaviorRefreshDefaults': 'Actualizar valores',
    'settingsBehaviorDefaultModel': 'Modelo predeterminado',
    'settingsBehaviorDefaultModelHelp': 'Compartido entre clientes OpenCode a través de config.',
    'settingsBehaviorSearchDefaultModel': 'Buscar modelo predeterminado',
    'settingsBehaviorNoModels': 'No se encontraron modelos',
    'settingsBehaviorDefaultAgent': 'Agente predeterminado',
    'settingsBehaviorDefaultAgentHelp': 'Agente principal usado cuando no se elige ningún agente explícitamente.',
    'settingsBehaviorSearchDefaultAgent': 'Buscar agente predeterminado',
    'settingsBehaviorNoAgents': 'No se encontraron agentes',
    'settingsBehaviorConversationUsername': 'Nombre de usuario de conversación',
    'settingsBehaviorConversationUsernameHelp': 'Nombre de visualización personalizado mostrado en las conversaciones en lugar del nombre del sistema.',
    'settingsBehaviorSaveUsername': 'Guardar nombre de usuario',
    'settingsBehaviorUsernameFallback': 'OpenCode usa el nombre de usuario del sistema porque `username` no está configurado.',
    'settingsBehaviorUsernamePatchCaveat': 'Restablecer `username` al valor predeterminado del sistema aún requiere editar la configuración fuera de la app.',
    'settingsBehaviorOpenCodeSnapshots': 'Instantáneas de OpenCode',
    'settingsBehaviorOpenCodeSnapshotsDescription': 'Mantener instantáneas git habilitadas para historial de deshacer/rehacer y recuperación.',
    'settingsBehaviorSnapshotCaveat': 'Esto controla el almacenamiento de instantáneas de OpenCode, no las instantáneas de caché local de CodeWalk.',
    'settingsBehaviorSmallModel': 'Modelo pequeño',
    'settingsBehaviorSmallModelHelp': 'Usado para tareas ligeras como generación de títulos.',
    'settingsBehaviorSearchSmallModel': 'Buscar modelo pequeño',
    'settingsBehaviorSmallModelAutoFallback': 'Respaldo automático',
    'settingsBehaviorSmallModelFallbackActive': 'El respaldo automático de OpenCode está activo porque `small_model` no está configurado.',
    'settingsBehaviorSmallModelResetCaveat': 'Restablecer `small_model` al respaldo automático aún requiere editar la configuración fuera de la app.',
    'settingsBehaviorOpenCodeAutoupdate': 'Actualización automática de OpenCode',
    'settingsBehaviorAutoupdateHelp': 'Controla las actualizaciones de runtime de OpenCode, no las verificaciones de actualización de CodeWalk.',
    'settingsBehaviorSearchAutoupdate': 'Buscar modo de actualización',
    'settingsBehaviorAutoupdateCaveat': 'Use Acerca de para las verificaciones de versión de CodeWalk. Esta configuración solo refleja la config `autoupdate` oficial de OpenCode.',
    'settingsBehaviorShareMode': 'Modo de compartir predeterminado de OpenCode',
    'settingsBehaviorShareModeHelp': 'Controla la config global oficial `share`, no el botón de compartir de un chat individual.',
    'settingsBehaviorSearchShareMode': 'Buscar modo de compartir',
    'settingsBehaviorShareModeCaveat': 'Use la acción de compartir en el chat para publicar una sesión ahora. Esta configuración solo cambia la política de compartir predeterminada de OpenCode.',
    'settingsBehaviorPermissionProvenance': 'Procedencia del manejo de permisos',
    'settingsBehaviorPermissionProvenanceDescription': 'La política oficial de permisos de OpenCode se configura en `opencode.json`. CodeWalk mantiene las tarjetas oficiales y agrega una excepción ADR-023 aprobada.',
    'settingsBehaviorPermissionDeferred': 'La edición avanzada de reglas de permisos queda fuera de Configuración por ahora.',
    'settingsBehaviorCellularDataSaver': 'Ahorro de datos móviles',
    'settingsBehaviorDataSaverDescription': 'Reduce el uso automático de datos móviles deteniendo descargas en segundo plano.',
    'settingsBehaviorEnableDataSaver': 'Habilitar ahorro de datos móviles',
    'settingsBehaviorDataSaverActive': 'Activo ahora en datos móviles.',
    'settingsBehaviorDataSaverWaiting': 'Esperando la próxima ventana de sincronización de datos móviles.',
    'settingsBehaviorDataSaverCellularOnly': 'Solo se aplica cuando la conexión es celular/móvil.',
    'settingsBehaviorConfigDeferred': 'CodeWalk aplicará esta configuración de OpenCode después de que termine la respuesta actual.',
    'settingsBehaviorConfigUpdateFailed': 'No se pudo actualizar {field} de OpenCode.',
    'settingsAppearanceSectionTitle': 'Apariencia',
    'settingsAppearanceSectionDescription': 'Ajuste la densidad visual y las superficies de mensaje para su flujo de trabajo.',
    'settingsAppearanceTheme': 'Tema',
    'settingsAppearanceThemeDescription': 'Elija entre modo claro, oscuro o sistema.',
    'settingsAppearanceSystem': 'Sistema',
    'settingsAppearanceLight': 'Claro',
    'settingsAppearanceDark': 'Oscuro',
    'settingsAppearanceCodeWalkClassic': 'CodeWalk Clásico',
    'settingsAppearanceOpenCodePresets': 'Presets OpenCode',
    'settingsAppearancePresetPalette': 'Paleta predefinida',
    'settingsAppearancePresetHelper': 'Refleja la lista oficial de temas integrados de OpenCode Web.',
    'settingsAppearanceSearchPreset': 'Buscar paleta predefinida',
    'settingsAppearanceNoPresets': 'No se encontraron paletas',
    'settingsAppearancePresetNote': 'Los colores del tema ahora siguen el registro oficial de OpenCode Web.',
    'settingsAppearanceAmoledDark': 'Modo oscuro AMOLED',
    'settingsAppearanceAmoledDarkActive': 'Usar superficies negras puras mientras el modo oscuro esté activo.',
    'settingsAppearanceAmoledDarkInactive': 'Cambie al modo oscuro para habilitar superficies AMOLED.',
    'settingsAppearanceWallpaperColors': 'Usar colores del fondo de pantalla',
    'settingsAppearanceWallpaperPresetBlocked': 'Cambie a CodeWalk Clásico para usar colores del fondo de pantalla.',
    'settingsAppearanceWallpaperNormal': 'Extraer esquema de color del fondo de pantalla del dispositivo.',
    'settingsAppearanceBrandColor': 'Color de marca',
    'settingsAppearanceBrandColorPresetBlocked': 'Cambie a CodeWalk Clásico para elegir un color de marca.',
    'settingsAppearanceBrandColorDynamicBlocked': 'Desactive los colores del fondo de pantalla para elegir un color de marca.',
    'settingsAppearanceBrandColorNormal': 'Elija un color semilla para la paleta de la app.',
    'settingsAppearanceContrast': 'Contraste',
    'settingsAppearanceContrastPresetBlocked': 'Cambie a CodeWalk Clásico para ajustar el contraste.',
    'settingsAppearanceContrastDynamicBlocked': 'Desactive los colores del fondo de pantalla para ajustar el contraste.',
    'settingsAppearanceContrastNormal': 'Ajuste el nivel de contraste del esquema de color.',
    'settingsAppearanceContrastReduced': 'Reducido',
    'settingsAppearanceContrastHigh': 'Alto',
    'settingsAppearanceDensity': 'Densidad',
    'settingsAppearanceDensityDescription': 'Aplica espaciado y densidad de componentes en toda la app.',
    'settingsAppearanceDensityExtraDense': 'Extra Densa',
    'settingsAppearanceDensityDense': 'Densa',
    'settingsAppearanceDensityNormal': 'Normal',
    'settingsAppearanceDensitySpacious': 'Espaciosa',
    'settingsAppearanceDensityExtraSpacious': 'Extra Espaciosa',
    'settingsAppearanceThinkingBubbles': 'Burbujas de pensamiento',
    'settingsAppearanceThinkingBubblesDescription': 'Mostrar u ocultar bloques de razonamiento en los mensajes del asistente.',
    'settingsAppearanceToolCallBubbles': 'Burbujas de llamada de herramienta',
    'settingsAppearanceToolCallBubblesDescription': 'Mostrar u ocultar tarjetas de ejecución de herramientas.',
    'settingsAppearanceTaskList': 'Lista de tareas',
    'settingsAppearanceTaskListDescription': 'Mostrar u ocultar el widget de lista de tareas de la sesión.',
    'settingsAppearanceComposerTips': 'Consejos del compositor',
    'settingsAppearanceComposerTipsDescription': 'Mostrar u ocultar consejos rotativos mientras el asistente razona.',
    'settingsNotificationsSectionTitle': 'Notificaciones',
    'settingsNotificationsSectionDescription': 'Controle cuándo aparecen las alertas y cuándo pueden reproducir sonido.',
    'settingsNotificationsSyncInfo': 'Algunos interruptores se sincronizan desde /config en el servidor activo.',
    'settingsNotificationsSyncInfoLocal': 'El servidor actual no expone interruptores de notificación en /config.',
    'settingsNotificationsAgentUpdates': 'Actualizaciones del agente',
    'settingsNotificationsAgentSubtitle': 'Cuando una respuesta termina',
    'settingsNotificationsPermissions': 'Permisos y preguntas',
    'settingsNotificationsPermissionsSubtitle': 'Cuando las herramientas solicitan su entrada',
    'settingsNotificationsErrors': 'Errores',
    'settingsNotificationsErrorsSubtitle': 'Cuando una sesión informa un fallo',
    'settingsNotificationsBackgroundAlerts': 'Alertas en segundo plano de Android',
    'settingsNotificationsBackgroundDescription': 'Usa monitoreo de bajo consumo de datos en segundo plano.',
    'settingsNotificationsBackgroundToggle': 'Alertas en segundo plano en Android',
    'settingsNotificationsBackgroundToggleDescription': 'Desactiva todas las verificaciones en segundo plano de Android.',
    'settingsNotificationsKeepLive': 'Mantener alertas activas por 3 min',
    'settingsNotificationsKeepLiveDescription': 'Cuando una respuesta ya está en ejecución, mantiene el tiempo real activo brevemente después de salir de la app.',
    'settingsNotificationsBatteryOptimization': 'Optimización de batería de Android',
    'settingsNotificationsBatteryDescription': 'Si las notificaciones solo llegan al reabrir la app, permita que CodeWalk se ejecute sin optimización.',
    'settingsNotificationsBatteryDisabled': 'La optimización de batería está desactivada para CodeWalk.',
    'settingsNotificationsBatteryEnabled': 'La optimización de batería está activada. Algunos dispositivos pueden retrasar las alertas.',
    'settingsNotificationsBatteryUnknown': 'Aún no se pudo leer el estado de optimización de batería.',
    'settingsNotificationsOpenBatterySettings': 'Abrir configuración de batería',
    'settingsNotificationsDisableOptimization': 'Desactivar optimización',
    'settingsNotificationsRefreshStatus': 'Actualizar estado',
    'settingsNotificationsBackgroundBehavior': 'Comportamiento en segundo plano',
    'settingsNotificationsBackgroundBehaviorDescription': 'Elija cómo se comporta CodeWalk después de que la app sale del primer plano.',
    'settingsNotificationsCloseToTray': 'Cerrar a la bandeja',
    'settingsNotificationsCloseToTrayDescription': 'Ocultar ventana y seguir ejecutándose en la bandeja del sistema.',
    'settingsNotificationsMinimizeWhenClose': 'Minimizar al cerrar',
    'settingsNotificationsMinimizeWhenCloseDescription': 'Minimizar a la barra de tareas/dock y seguir ejecutándose.',
    'settingsNotificationsJustClose': 'Solo cerrar',
    'settingsNotificationsJustCloseDescription': 'Salir completamente de la aplicación.',
    'settingsNotificationsWhenClosing': 'Al cerrar la ventana',
    'settingsNotificationsNotify': 'Notificar',
    'settingsNotificationsSound': 'Sonido',
    'settingsNotificationsNotifyOnlyWhen': 'Notificar solo cuando',
    'settingsNotificationsSoundOnlyWhen': 'Sonido solo cuando',
    'settingsNotificationsAppInBackground': 'App en segundo plano',
    'settingsNotificationsAnotherConversation': 'Otra conversación',
    'settingsNotificationsNoCondition': 'Si no se selecciona ninguna condición, las alertas se permiten en cualquier contexto.',
    'settingsNotificationsSoundType': 'Tipo de sonido',
    'settingsNotificationsSearchSoundType': 'Buscar tipo de sonido',
    'settingsNotificationsSelectedSound': 'Seleccionado: {label}',
    'settingsNotificationsChooseSystemSound': 'Elegir sonido del sistema',
    'settingsNotificationsChooseAudioFile': 'Elegir archivo de audio',
    'settingsNotificationsPreview': 'Previsualizar',
    'settingsNotificationsServer': 'Servidor',
    'settingsNotificationsLocal': 'Local',
    'settingsNotificationsSystemSoundPickerTitle': 'Elegir sonido del sistema',
    'settingsServersActive': 'Activo',
    'settingsServersDefault': 'Predeterminado',
    'settingsServersChooseActive': 'Elegir servidor activo',
    'settingsShortcutsKeyboard': 'Atajos de teclado',
    'settingsShortcutsSearch': 'Buscar atajos',
    'settingsSpeechRefreshStatus': 'Actualizar estado',
    'settingsSpeechSilenceTimeout': 'Tiempo de silencio: {value}s',
    'settingsAboutVersion': 'Versión',
    'settingsAboutLoading': 'Cargando...',
    'settingsAboutVersionBuild': '{version} (compilación {buildNumber})',
    'settingsAboutUpdateAvailable': 'Actualización disponible: v{version}',
    'settingsAboutDownloading': 'Descargando... {percent}%',
    'settingsAboutInstalling': 'Instalando...',
    'settingsAboutUpdateInstalled': 'Actualización instalada. Reinicie la app para aplicarla.',
    'settingsAboutRetryInstall': 'Reintentar instalación',
    'settingsAboutInstallUpdate': 'Instalar actualización',
    'settingsAboutDismiss': 'Descartar',
    'settingsAboutUpToDate': 'Estás al día',
    'settingsAboutLatestVersion': 'v{version} es la versión más reciente',
    'settingsAboutCheckOnOpen': 'Buscar actualizaciones al abrir',
    'settingsAboutCheckOnOpenDescription': 'Comprobar automáticamente cuando inicia la app',
    'settingsAboutCheckForUpdates': 'Buscar actualizaciones',
    'settingsAboutChecking': 'Comprobando...',
    'settingsAboutTapToCheck': 'Toca para buscar nuevas versiones',
    'settingsAboutReplayChatTour': 'Repetir recorrido del chat',
    'settingsAboutReplayChatTourDescription': 'Cerrar ajustes y mostrar la guía del chat',
    'settingsAboutResetApp': 'Restablecer app',
    'settingsAboutEraseAllData': 'Borrar todos los datos y reiniciar',
    'settingsAboutResetAppQuestion': '¿Restablecer app?',
    'settingsAboutResetAppWarning': 'Esto borrará todos los servidores, ajustes y datos en caché. Esta acción no se puede deshacer.',
    'settingsBack': 'Volver',
    'chatConversations': 'Conversaciones',
    'chatProjectContext': 'Contexto del Proyecto',
    'chatNewChat': 'Nueva Conversación',
    'chatRefresh': 'Actualizar',
    'chatHideConversationsSidebar': 'Ocultar barra de Conversaciones',
    'chatHideUtilitySidebar': 'Ocultar barra de Utilidades',
    'chatFilterSessions': 'Filtrar sesiones',
    'chatSortSessions': 'Ordenar sesiones',
    'chatFilterActive': 'Activas',
    'chatFilterArchived': 'Archivadas',
    'chatFilterAll': 'Todas',
    'chatSortRecent': 'Recientes',
    'chatSortMostRecent': 'Más Recientes',
    'chatSortOldest': 'Más Antiguas',
    'chatSortTitle': 'Título',
    'chatSearchConversations': 'Buscar conversaciones',
    'chatRecentSessions': 'Sesiones recientes',
    'chatLoadMore': 'Cargar más',
    'chatRefreshSessionDetails': 'Actualizar detalles de sesión',
    'chatClose': 'Cerrar',
    'chatToggleSidebars': 'Alternar barras laterales',
    'chatUndoLastTurn': 'Deshacer último turno',
    'chatRedoLastTurn': 'Rehacer último turno deshecho',
    'chatDisplayToggles': 'Opciones de visualización',
    'chatOpenFiles': 'Abrir Archivos',
    'chatConversationsPane': 'Conversaciones',
    'chatRecentSessionsToggle': 'Sesiones recientes',
    'chatNewChatTourTitle': 'Nueva conversación',
    'chatNewChatTourDescription': 'Inicie una nueva conversación aquí.',
    'chatNoServerYet': 'Aún no hay servidor configurado',
    'chatAddServerToStart': 'Agregue un servidor para comenzar a chatear.',
    'chatSetUpServer': 'Configurar servidor',
    'chatSelectOrCreate': 'Seleccione o cree una conversación para comenzar a chatear',
    'chatHelloAssistant': '¡Hola! Soy tu asistente de IA',
    'chatKeepWorking': 'Seguir trabajando',
    'chatRetryRefresh': 'Reintentar actualización',
    'chatReturnToMainConversation': 'Volver a la conversación principal',
    'chatSessionActions': 'Acciones de sesión',
    'chatCompactContext': 'Compactar Contexto',
    'chatGoToFirst': 'Ir al primer mensaje',
    'chatGoToLatest': 'Ir al último mensaje',
    'chatUseCurrent': 'Usar actual',
    'chatRetry': 'Reintentar',
    'sessionRename': 'Renombrar',
    'sessionCopyLink': 'Copiar Enlace',
    'sessionFork': 'Bifurcar',
    'sessionDelete': 'Eliminar',
    'sessionRenameTitle': 'Renombrar Conversación',
    'sessionRenameHint': 'Ingrese el nuevo nombre de la conversación',
    'sessionDeleteTitle': 'Eliminar Conversación',
    'sessionNotAvailable': 'La conversación aún no está disponible para este proyecto',
    'sessionFailedRename': 'Error al renombrar conversación',
    'sessionFailedUpdateSharing': 'Error al actualizar estado de compartir',
    'sessionFailedUpdateArchive': 'Error al actualizar estado de archivado',
    'sessionActionArchived': 'archivada',
    'sessionActionUnarchived': 'desarchivada',
    'sessionActionDeleted': 'eliminada',
    'sessionActionForked': 'bifurcada',
    'sessionShareLinkCopied': 'Enlace de compartir copiado',
    'sessionTitleHint': 'Título de la conversación',
    'sessionSaveTitle': 'Guardar título',
    'sessionCancelRename': 'Cancelar renombrado',
    'sessionKeyboardShortcuts': 'Atajos de teclado',
    'permissionReject': 'Rechazar',
    'permissionAlways': 'Siempre',
    'permissionAllowOnce': 'Permitir Una Vez',
    'permissionReopen': 'Reabrir',
    'permissionConfirmReject': 'Confirmar Rechazo',
    'permissionBack': 'Volver',
    'dialogVoiceInputSetup': 'Configuración de Entrada de Voz',
    'dialogParakeetVoiceSetup': 'Configuración de Voz Parakeet',
    'dialogSenseVoiceSetup': 'Configuración SenseVoice',
    'dialogMoonshineVoiceSetup': 'Configuración de Voz Moonshine',
    'dialogDownload': 'Descargar',
    'dialogLanguage': 'Idioma',
    'dialogSenseVoiceModel': 'Modelo SenseVoice',
    'dialogParakeetModel': 'Modelo Parakeet',
    'dialogMoonshineModelSize': 'Tamaño del modelo',
    'terminalReconnect': 'Reconectar terminal',
    'terminalClose': 'Cerrar terminal',
    'terminalMinimize': 'Minimizar terminal',
    'terminalTryAgain': 'Intentar de nuevo',
    'composerSend': 'Enviar',
    'composerShellMode': 'Modo shell',
    'composerChatInput': 'Entrada de chat',
    'composerExtras': 'Extras',
    'composerAddAttachment': 'Agregar adjunto',
    'composerNewQuickReply': 'Nueva respuesta rápida',
    'composerAttachFiles': 'Adjuntar archivos',
    'composerSelectImages': 'Seleccionar Imágenes',
    'composerSelectPdf': 'Seleccionar PDF',
    'composerEdit': 'Editar',
    'composerDeleteAction': 'Eliminar',
    'composerCannedAppendAtCursor': 'Agregar en el cursor',
    'composerCannedReplace': 'Reemplazar',
    'composerCannedSendAutomatically': 'Enviar automáticamente',
    'composerCannedScopeGlobal': 'Global',
    'composerCannedScopeProject': 'Solo del proyecto',
    'composerCannedLabel': 'Etiqueta (opcional)',
    'composerCannedText': 'Texto',
    'composerCannedNoReplies': 'Aún no hay respuestas rápidas.',
    'composerCannedSave': 'Guardar',
    'tourSkip': 'Saltar',
    'tourBack': 'Volver',
    'msgCopiedToClipboard': 'Copiado al portapapeles',
    'msgCommandCopied': 'Comando copiado',
    'msgFailedToSendMessage': 'Error al enviar mensaje. Borrador conservado para reintentar.',
    'msgVoiceInputUnavailable': 'Entrada de voz no disponible en este dispositivo',
    'msgFailedToStartVoiceInput': 'Error al iniciar entrada de voz',
    'msgNoValidFilesSelected': 'No se seleccionaron archivos válidos',
    'msgSetupDebugCopied': 'Debug de configuración de OpenCode copiado',
    'msgFilteredLogsCopied': 'Registros filtrados copiados al portapapeles',
    'msgSystemSoundPickerUnavailable': 'El selector de sonido del sistema no está disponible en esta plataforma.',
    'msgNoSystemSoundsFound': 'No se encontró ningún sonido del sistema en este dispositivo.',
    'msgBatterySettingsOpened': 'Configuración de batería de Android abierta. Permita batería sin restricciones para CodeWalk.',
    'msgBatterySettingsFailed': 'No se pudo abrir la configuración de optimización de batería de Android.',
    'msgUpdatedButRefreshFailed': 'Configuración del servidor actualizada, pero no se pudieron actualizar los proveedores de chat.',
    'msgEnterUsernameToSave': 'Ingrese un nombre de usuario para guardar un nombre de conversación personalizado de OpenCode.',
    'msgClearUsernameNeedsConfigEdit': 'Limpiar el nombre de usuario de la conversación de OpenCode aún requiere editar la configuración fuera de la app.',
    'trayShow': 'Mostrar',
    'trayQuit': 'Salir',
    'notifConversationUpdates': 'Actualizaciones de conversación',
    'modelLoadingModels': 'Cargando modelos',
    'modelRetryModels': 'Reintentar modelos',
    'modelAuto': 'Automático',
    'modelSearchHint': 'Buscar modelo o proveedor',
    'filesSearchHint': 'Buscar archivos por nombre o ruta',
    'filesQuickOpen': 'Apertura Rápida',
    'filesRefresh': 'Actualizar archivos',
    'filesHideSidebar': 'Ocultar barra de Archivos',
    'filesTitle': 'Archivos',
    'toolRunning': 'Ejecutando',
    'toolReading': 'Leyendo',
    'toolWriting': 'Escribiendo',
    'toolEditing': 'Editando',
    'toolFinding': 'Buscando',
    'toolSearching': 'Buscando',
    'toolAwaitingInput': 'Esperando entrada',
    'toolUpdatingTasks': 'Actualizando tareas',
    'toolRunningCommand': 'Ejecutando comando',
    'toolReadingFile': 'Leyendo archivo',
    'toolWritingFile': 'Escribiendo archivo',
    'toolEditingFiles': 'Editando archivos',
    'toolFindingFiles': 'Buscando archivos',
    'toolSearchingCode': 'Buscando código',
    'toolSearchingWeb': 'Buscando en la web',
    'toolWaitingForInput': 'Esperando su entrada',
    'toolUpdatingTaskList': 'Actualizando lista de tareas',
    'toolRunningTask': 'Ejecutando tarea',
    'msgInfoAgent': 'Agente',
    'msgInfoSnapshot': 'Instantánea',
    'msgInfoPatch': 'Parche',
    'msgInfoCompaction': 'Compactación',
    'msgInfoRetry': 'Intento',
    'msgInfoView': 'Ver',
    'msgInfoUndoThisTurn': 'Deshacer este turno',
    'msgInfoMessageInfo': 'Información del Mensaje',
    'msgInfoModel': 'Modelo: {modelId}',
    'msgInfoProvider': 'Proveedor: {providerId}',
    'msgInfoTokens': 'Tokens: {total}',
    'msgInfoCost': 'Costo: \${cost}',
    'msgInfoNoMetadata': 'No hay metadatos disponibles',
    'commonCancel': 'Cancelar',
    'commonReset': 'Restablecer',
    'commonSave': 'Guardar',
    'commonDelete': 'Eliminar',
    'workspaceProjectDirectory': 'Directorio del proyecto',
    'workspaceProjectHint': '/repo/mi-proyecto',
    'workspaceBrowseDirs': 'Explorar directorios',
    'workspaceCloseProject': 'Cerrar {project}',
    'workspaceRemoveFromHistory': 'Eliminar {name} del historial',
    'workspaceFilterDirs': 'Filtrar directorios',
    'setupDebugTitle': 'Enfocado en la configuración de OpenCode',
    'setupDebugStatus': 'Estado actual',
    'setupDebugEnvironment': 'Diagnóstico del entorno',
    'setupDebugTimeline': 'Línea de tiempo',
    'setupDebugServerOutput': 'Última salida del servidor local',
    'setupDebugLogs': 'Registros de configuración capturados',
    'setupDebugNoDetails': 'Aún no hay detalles de configuración capturados',
    'setupDebugManual': 'Solución de problemas manual',
    'setupDebugPlatform': 'Plataforma',
    'setupDebugCommandPath': 'Ruta del comando',
    'setupDebugOpenCode': 'OpenCode',
    'setupDebugNodeJs': 'Node.js',
    'setupDebugNpm': 'npm',
    'setupDebugBun': 'Bun',
    'setupDebugWsl': 'WSL',
    'setupDebugNetwork': 'Red',
    'setupDebugInstallDir': 'Directorio de instalación',
    'setupDebugCopy': 'Copiar debug de configuración',
    'setupDebugClear': 'Limpiar debug de configuración',
    'quotaForget': 'Olvidar',
    'quotaOpenCodeGoUsage': 'Uso de OpenCode Go',
    'quotaOpenDashboard': 'Abrir panel de OpenCode',
    'quotaWorkspaceId': 'ID del Espacio de Trabajo',
    'quotaAuthCookie': 'Cookie de autenticación',
    'quotaSaving': 'Guardando...',
    'cannedNoSuggestions': 'Sin sugerencias',
    'onboardingServerUrl': 'URL del servidor',
    'onboardingLabel': 'Etiqueta (opcional)',
    'onboardingLabelHint': 'Mi servidor',
    'onboardingUsername': 'Usuario',
    'onboardingPassword': 'Contraseña',
    'onboardingClear': 'Limpiar',
    'logsSearch': 'Buscar registros',
    'logsCloseSearch': 'Cerrar búsqueda',
    'logsCopyFiltered': 'Copiar registros filtrados',
    'logsClear': 'Limpiar registros',
  },
};
