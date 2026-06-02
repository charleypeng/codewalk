// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appProviderCannotActivateUnhealthy => '无法激活不健康的服务器';

  @override
  String get appProviderDesktopOnly => '托管本地服务器仅在桌面端可用。';

  @override
  String get appProviderDetectingCommand => '正在检测 OpenCode 命令...';

  @override
  String get appProviderErrorCannotActivateUnhealthy => '无法激活不健康的服务器';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      '此平台不支持 Cloudflare Access OAuth';

  @override
  String get appProviderErrorInstallationFailed => 'OpenCode 安装失败。';

  @override
  String get appProviderErrorInvalidServerUrl => '无效的服务器 URL';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      '本地服务器已启动，但健康检查未通过。';

  @override
  String get appProviderErrorManagedDesktopOnly => '托管本地服务器仅在桌面端可用。';

  @override
  String get appProviderErrorServerAlreadyExists => '使用此 URL 的服务器已存在';

  @override
  String get appProviderErrorServerProfileNotFound => '找不到服务器配置文件';

  @override
  String get appProviderErrorServerUrlRequired => '服务器 URL 是必填项';

  @override
  String get appProviderErrorTailscaleNotSupported => '此平台不支持 Tailscale';

  @override
  String appProviderExitedWithCode(int code) {
    return '本地服务器已退出，退出代码为 $code。';
  }

  @override
  String get appProviderFailedToStart => '启动本地 OpenCode 服务器失败。';

  @override
  String get appProviderInstallBinary => '安装二进制文件';

  @override
  String get appProviderInstallBunOpenCode => '安装 Bun + OpenCode';

  @override
  String get appProviderInstallSucceeded => '安装成功。';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return '安装成功。OpenCode 命令位于 $path。';
  }

  @override
  String get appProviderInstallViaBun => '通过 Bun 安装';

  @override
  String get appProviderInstallViaNpm => '通过 npm 安装';

  @override
  String get appProviderInstallationFailed => 'OpenCode 安装失败。';

  @override
  String get appProviderInstalledSuccessfully => 'OpenCode 要求已成功安装。';

  @override
  String get appProviderInstallingRequirements => '正在安装 OpenCode 要求...';

  @override
  String get appProviderInvalidServerUrl => '无效的服务器 URL';

  @override
  String get appProviderLabelLocalOpenCodeManaged => '本地 OpenCode (托管)';

  @override
  String get appProviderLabelPrimaryServer => '主服务器';

  @override
  String get appProviderLocalManaged => '本地 OpenCode (托管)';

  @override
  String get appProviderLocalServerStopped => '本地服务器已停止。';

  @override
  String get appProviderNotDetectedInstall => '未检测到 OpenCode 命令。请从向导运行安装。';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return '未检测到 OpenCode 命令。如果您刚刚安装，请刷新检查或重新打开 $appName 以重新加载 PATH。';
  }

  @override
  String get appProviderOAuthNotSupported => '此平台不支持 Cloudflare Access OAuth';

  @override
  String get appProviderOpenCodeDetected => '已检测到 OpenCode';

  @override
  String get appProviderOpenCodeNotDetected => '未检测到 OpenCode';

  @override
  String get appProviderPrimaryServer => '主服务器';

  @override
  String get appProviderProfileNotFound => '找不到服务器配置文件';

  @override
  String get appProviderRunDiagnostics => '运行诊断以验证本地 OpenCode 要求。';

  @override
  String appProviderRunningAt(String url) {
    return '运行于 $url';
  }

  @override
  String get appProviderSetupDetectingOpenCode => '正在检测 OpenCode 命令...';

  @override
  String get appProviderSetupInstallationSucceeded => '安装成功。';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return '安装成功。OpenCode 命令位于 $path。';
  }

  @override
  String get appProviderSetupInstallingRequirements => '正在安装 OpenCode 要求...';

  @override
  String get appProviderSetupOpenCodeDetected => '已检测到 OpenCode';

  @override
  String get appProviderSetupOpenCodeNotDetected => '未检测到 OpenCode';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      '未检测到 OpenCode 命令。请从向导运行安装。';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      '未检测到 OpenCode 命令。如果您刚刚安装，请刷新检查或重新打开 CodeWalk 以重新加载 PATH。';

  @override
  String get appProviderSetupRequirementsInstalled => 'OpenCode 要求已成功安装。';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return '正在使用位于 $path 的 OpenCode 命令';
  }

  @override
  String get appProviderStartingLocalServer => '正在启动本地服务器...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return '本地服务器已退出，退出代码为 $code。';
  }

  @override
  String get appProviderStatusLocalServerStopped => '本地服务器已停止。';

  @override
  String appProviderStatusRunningAt(String url) {
    return '运行于 $url';
  }

  @override
  String get appProviderStatusStartingLocalServer => '正在启动本地服务器...';

  @override
  String get appProviderStatusStoppingLocalServer => '正在停止本地服务器...';

  @override
  String get appProviderStoppingLocalServer => '正在停止本地服务器...';

  @override
  String get appProviderTailscaleNotSupported => '此平台不支持 Tailscale';

  @override
  String appProviderUsingCommandAt(String path) {
    return '正在使用位于 $path 的 OpenCode 命令';
  }

  @override
  String get appShellDownloadingUpdate => '正在下载更新';

  @override
  String get appShellInstall => '安装';

  @override
  String get appShellInstallFailed => '安装失败';

  @override
  String get appShellInstallingUpdate => '正在安装更新...';

  @override
  String get appShellRestart => '重启';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return '有可用更新: v$latestVersion';
  }

  @override
  String get appShellUpdateInstalledRestartApp => '更新已安装。请重启应用以生效。';

  @override
  String get appShellUpdateInstalledRestartRequired => '更新已安装。需要重启以应用新版本。';

  @override
  String get attachmentCouldNotDecode => '无法解码附件数据。';

  @override
  String get attachmentCouldNotDownload => '无法下载附件。';

  @override
  String get attachmentCouldNotSave => '无法在此设备上保存附件。';

  @override
  String get attachmentDownloadStarted => '附件下载已开始。';

  @override
  String get attachmentLocalNotFound => '在此设备上找不到本地附件。';

  @override
  String get attachmentNoValidLocation => '附件未提供有效位置。';

  @override
  String get attachmentNotAvailableOnPlatform => '附件操作在此平台上不可用。';

  @override
  String get attachmentPathEmpty => '附件路径为空。';

  @override
  String get attachmentPayloadEmpty => '附件有效负载为空。';

  @override
  String get attachmentSaveCanceled => '保存已取消。';

  @override
  String attachmentSavedAndOpened(String path) {
    return '附件已保存至 $path 并打开。';
  }

  @override
  String attachmentSavedPath(String path) {
    return '附件已保存至 $path。';
  }

  @override
  String attachmentSavedTo(String path) {
    return '附件已保存至 $path。';
  }

  @override
  String get attachmentUnableToOpenLink => '无法打开附件链接。';

  @override
  String get attachmentUnableToOpenLocal => '无法打开本地附件。';

  @override
  String get behaviorAdvancedPermissionRule => '高级权限规则';

  @override
  String get behaviorAutomatic => '自动';

  @override
  String get behaviorAutomaticFallback => '自动回退';

  @override
  String get behaviorCellularDataSaver => '移动数据节省';

  @override
  String get behaviorCellularDataSaverActive => '蜂窝数据节省模式已开启。';

  @override
  String get behaviorChatLevelShare => '聊天级别共享';

  @override
  String get behaviorCodeWalkReleaseChecks => 'CodeWalk版本检查';

  @override
  String get behaviorControlsOfficialGlobal => '控制OpenCode官方全局设置';

  @override
  String get behaviorControlsUpstreamOpenCode => '控制上游OpenCode设置';

  @override
  String get behaviorCustomDisplayName => '自定义显示名称';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return '通过停止后台下载并将前台自动刷新限制为每$inSeconds秒一次突发，减少自动移动数据使用。';
  }

  @override
  String get behaviorDataSaverActive => 'Active now on mobile data.';

  @override
  String get behaviorDataSaverCellularOnly =>
      'Only applies when the connection is cellular/mobile.';

  @override
  String get behaviorDataSaverWaiting =>
      'Waiting for the next mobile-data sync window.';

  @override
  String get behaviorDisabled => '已禁用';

  @override
  String get behaviorLightweightTasksLike => '轻量级任务如';

  @override
  String get behaviorManual => '手动';

  @override
  String get behaviorNotify => '通知';

  @override
  String get behaviorOfficialOpenCodePermission =>
      'Official OpenCode permission policy is configured in `opencode.json` with allow/ask/deny rules per tool. CodeWalk keeps the official permission-request cards and adds one approved ADR-023 exception: the composer auto-approve toggle replies with `Always` and `remember: true` unconditionally to create durable session-scoped grants, and keeps the same thread-scoped continuity path active in the Android background worker.';

  @override
  String get behaviorOpenCodeBackedDefaults => 'OpenCode-backed defaults';

  @override
  String get behaviorPermissionHandlingProvenance =>
      'Permission handling provenance';

  @override
  String get behaviorPermissionsVariantReasoning =>
      'Permissions and variant/reasoning parity stay separate until their UI can preserve advanced config safely.';

  @override
  String get behaviorPrimaryAgentAgent =>
      'Primary agent used when no agent is explicitly chosen.';

  @override
  String get behaviorRefreshDefaults => 'Refresh defaults';

  @override
  String get behaviorSharedAcrossOpenCode =>
      'Shared across OpenCode clients through config.';

  @override
  String get behaviorTheseValuesWrite =>
      'These values write to `/config` on the active server and match official OpenCode shared config.';

  @override
  String get cannedAddTitle => '添加快捷回复';

  @override
  String get cannedAppendAtCursor => '在光标处追加';

  @override
  String get cannedAppendAtCursorSubtitle => '关闭 = 替换当前编辑器文本';

  @override
  String get cannedAttachFiles => 'Attach files';

  @override
  String get cannedEditTitle => '编辑快捷回复';

  @override
  String get cannedNewQuickReply => '新快速回复';

  @override
  String get cannedNoSuggestions => 'No suggestions';

  @override
  String get cannedOffMeansReplace => 'Off means replace current composer text';

  @override
  String get cannedQuickReply => 'New quick reply';

  @override
  String get cannedReplace => '替换';

  @override
  String get cannedScopeGlobalSubtitle => '禁用为仅项目项';

  @override
  String get cannedScopeGlobalUnavailableSubtitle => '当前上下文中仅项目不可用';

  @override
  String get cannedSendAutomaticallySubtitle => '插入此快速回复后立即发送';

  @override
  String get cannedSendImmediatelyInserting =>
      'Send immediately after inserting this quick reply';

  @override
  String get cannedTextLabel => '文本';

  @override
  String get chatActionNext => '下一步';

  @override
  String get chatActiveServerUnhealthy =>
      'Active server is unhealthy. Sends will try once and fail fast until recovery.';

  @override
  String get chatActiveServerUnhealthyLabel => '当前服务器状态异常';

  @override
  String get chatAddServerToStart => 'Add a server to start chatting.';

  @override
  String get chatAppBarMoreActions => 'More actions';

  @override
  String get chatAppBarPinAction => 'Pin to app bar';

  @override
  String get chatAppBarPinDescription =>
      'This action will stay visible outside the menu.';

  @override
  String get chatAppBarUnpinAction => 'Unpin from app bar';

  @override
  String get chatAppBarUnpinDescription =>
      'This action will move back into the menu.';

  @override
  String chatBadgeConversationError(String title) {
    return '“$title”出现错误。';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '“$title”需要您的输入。';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '“$title”有新回复。';
  }

  @override
  String get chatBadgeDataSaverActive => '移动数据节省模式已开启。';

  @override
  String get chatBadgeServerNeedsAttention => '服务器连接需要注意。';

  @override
  String get chatBadgeSyncing => '正在同步会话...';

  @override
  String get chatCachedConversationsYet => 'No cached conversations yet';

  @override
  String get chatChangedFilesAvailable =>
      'No changed files are available for this session.';

  @override
  String chatChildrenChatProviderCurrentSessionChildren(int length) {
    return '子项: $length';
  }

  @override
  String get chatChooseAgent => '选择代理';

  @override
  String get chatChooseDirectory => 'Choose Directory';

  @override
  String get chatChooseEffort => '选择努力程度';

  @override
  String get chatChooseFolderOpen =>
      'Choose a folder to open as project context.';

  @override
  String get chatChooseModel => '选择模型';

  @override
  String get chatClose => 'Close';

  @override
  String chatCloseProject(String project) {
    return '关闭 $project';
  }

  @override
  String get chatCollapseGroup => '折叠分组';

  @override
  String get chatCommandDescriptionProject => '项目命令';

  @override
  String get chatCommandSourceGeneric => '命令';

  @override
  String get chatCommandSourceProject => '项目';

  @override
  String get chatCompactContext => 'Compact Context';

  @override
  String get chatComposerHintShell => 'Shell命令（按Esc退出）';

  @override
  String get chatComposerPlaceholder => '输入您的需求...';

  @override
  String get chatConversation => 'Conversation';

  @override
  String get chatConversations => 'Conversations';

  @override
  String get chatConversationsPane => 'Conversations';

  @override
  String chatCostLabel(double cost) {
    return '费用：\$$cost';
  }

  @override
  String get chatCouldNotRefreshSession => '无法刷新此对话';

  @override
  String get chatCurrent => 'Use current';

  @override
  String chatDescriptionChildren(int count) {
    return '子项：$count';
  }

  @override
  String get chatDescriptionCloseApp => '使用平台关闭行为关闭应用';

  @override
  String get chatDescriptionCycleModels => '循环切换近期模型';

  @override
  String get chatDescriptionCycleVariant => '循环切换模型变体';

  @override
  String get chatDescriptionDiffFilesZero => '差异文件：0';

  @override
  String get chatDescriptionFocusInput => '聚焦消息输入框';

  @override
  String get chatDescriptionFocusOrCloseDrawer => '聚焦输入框（或在打开时关闭侧边栏）';

  @override
  String get chatDescriptionForceExit => '强制退出应用';

  @override
  String get chatDescriptionNewConversation => '新会话';

  @override
  String get chatDescriptionNextAgent => '下一个代理';

  @override
  String get chatDescriptionOpenProjects => '使用此按钮打开您的项目和会话。';

  @override
  String get chatDescriptionOpenSettings => '打开设置';

  @override
  String get chatDescriptionPreviousAgent => '上一个代理';

  @override
  String get chatDescriptionProjectCommand => '项目命令';

  @override
  String get chatDescriptionQuickOpen => '快速打开文件';

  @override
  String get chatDescriptionRefreshData => '刷新聊天数据';

  @override
  String get chatDescriptionStopResponse => '停止当前响应（响应时）';

  @override
  String get chatDescriptionSwitchProject => '使用此按钮切换项目文件夹和上下文。';

  @override
  String get chatDescriptionVoiceInput => '开始或停止语音输入';

  @override
  String get chatDiffFiles => 'Diff files: 0';

  @override
  String get chatDisplay => 'Display';

  @override
  String get chatDisplayToggles => 'Display toggles';

  @override
  String get chatDoubleESCStop => '双击ESC停止';

  @override
  String get chatEffortLockedSubConversation => '子对话中已锁定努力程度';

  @override
  String get chatExpandGroup => '展开分组';

  @override
  String get chatExportCanceled => '会话导出已取消';

  @override
  String get chatFailedToLoadDirectories => '加载目录失败';

  @override
  String get chatFailedToLoadFile => '加载文件失败';

  @override
  String get chatFailedToRefreshProviders => '刷新提供程序和模型失败';

  @override
  String get chatFailedToRefreshSubConversations => '刷新子对话失败，请重试。';

  @override
  String get chatFailedToStopResponse => 'Failed to stop current response';

  @override
  String get chatFileExplorerContents => '内容';

  @override
  String get chatFileExplorerNames => '名称';

  @override
  String get chatFilterActive => 'Active';

  @override
  String get chatFilterAll => 'All';

  @override
  String get chatFilterArchived => 'Archived';

  @override
  String get chatFilterDirectories => 'Filter directories';

  @override
  String get chatFilterSessions => 'Filter sessions';

  @override
  String get chatForkFailed => '派生会话失败';

  @override
  String get chatForked => '已派生会话';

  @override
  String get chatGoToFirst => 'Go to first message';

  @override
  String get chatGoToLatest => 'Go to latest message';

  @override
  String chatGroupMessageCountMessages(
    String compactionLabel,
    String messageCount,
  ) {
    return '$compactionLabel压缩前隐藏了$messageCount条消息';
  }

  @override
  String get chatHelloAssistant => 'Hello! I am your AI assistant';

  @override
  String get chatHelp => 'How can I help you?';

  @override
  String get chatHelpMessage => '使用 @ 提及，! 运行 shell，/ 运行命令';

  @override
  String get chatHideConversationsSidebar => 'Hide Conversations sidebar';

  @override
  String get chatHideUtilitySidebar => 'Hide Utility sidebar';

  @override
  String get chatHistoryCollapsed => 'Previous history is collapsed';

  @override
  String get chatHistoryHideEarlier => 'Hide earlier messages';

  @override
  String chatHistoryMessagesHidden(int count, String label) {
    return '$count messages hidden before $label compaction';
  }

  @override
  String get chatHistoryShowEarlier => 'Show earlier messages';

  @override
  String get chatKeepWorking => 'Keep working';

  @override
  String get chatLargeContentSkipped => '为了稳定性，已跳过超大或格式错误的内容。';

  @override
  String get chatLatestToolActivity =>
      'Latest tool activity stays inside this bounded panel to keep the chat viewport stable.';

  @override
  String get chatLoadMore => 'Load more';

  @override
  String get chatLoadingProjectContext => 'Loading project context...';

  @override
  String get chatMainConversationUnavailable => '主对话尚不可用。';

  @override
  String get chatMentionAgentSubtitle => '智能体';

  @override
  String get chatMentionFileSubtitle => '文件';

  @override
  String get chatMentionSymbolSubtitle => '符号';

  @override
  String get chatMessageAttachedFile => '已附加文件';

  @override
  String get chatMessageDetails => '详情';

  @override
  String get chatMessageHide => '隐藏';

  @override
  String get chatMessageLess => '收起';

  @override
  String get chatMessageMessagePartUnavailable => 'Message part unavailable';

  @override
  String get chatMessageMetadataAvailable => 'No metadata available';

  @override
  String chatMessageModelMessageModelId(String modelId) {
    return '模型: $modelId';
  }

  @override
  String get chatMessageMore => '更多';

  @override
  String get chatMessageOpenFile => 'Open file';

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return '提供者: $providerId';
  }

  @override
  String get chatMessageRewindEdit => 'Rewind and edit from here';

  @override
  String get chatMessageRunningTask => 'Running task';

  @override
  String get chatMessageSaveFile => 'Save file';

  @override
  String get chatMessageShow => '显示';

  @override
  String get chatMessageShowLess => '显示较少';

  @override
  String get chatMessageShowLessCompact => '收起';

  @override
  String get chatMessageShowMore => '显示更多';

  @override
  String get chatMessageShowMoreCompact => '更多';

  @override
  String get chatMessageThinking => '思考中';

  @override
  String get chatMessageThinkingProcess => 'Thinking Process';

  @override
  String get chatMessageToolCall => '1 tool call';

  @override
  String chatMessageToolCalls(int count) {
    return '$count tool calls';
  }

  @override
  String get chatMessageToolCommand => '命令';

  @override
  String get chatMessageToolCommandTruncated => '命令预览已截断以保持稳定性。';

  @override
  String get chatMessageToolDiffOmitted => '差异预览已省略：编辑负载过大，无法在移动端安全渲染。';

  @override
  String get chatMessageToolInput => '输入';

  @override
  String get chatMessageToolInputTruncated => '输入预览已截断以保持稳定性。';

  @override
  String get chatMessageToolOutputTruncated => '大型工具输出预览已截断以保持应用稳定性。';

  @override
  String chatMessageToolQueuedCount(int count) {
    return '$count 排队中';
  }

  @override
  String chatMessageToolRunningCount(int count) {
    return '$count 运行中';
  }

  @override
  String get chatMessageToolStatusInProgress => 'In progress';

  @override
  String get chatMessageToolStatusNeedsAttention => 'Needs attention';

  @override
  String get chatMessageToolStatusQueued => 'Queued';

  @override
  String get chatMessageYou => 'You';

  @override
  String get chatModelLockedSubConversation => '模型在子对话中已锁定';

  @override
  String get chatNewChat => 'New Chat';

  @override
  String get chatNewChatTourDescription => 'Start a new conversation here.';

  @override
  String get chatNewChatTourTitle => 'New chat';

  @override
  String get chatNoConversationsInProject => '此项目中没有会话。';

  @override
  String get chatNoServerYet => 'No server configured yet';

  @override
  String get chatNoSessionSelected => '选择或创建一个对话开始聊天';

  @override
  String get chatNoSubConversationFound => '未找到此任务的子对话。';

  @override
  String get chatOpenFiles => 'Open Files';

  @override
  String get chatOpenProject => '打开项目';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenProjectToLoad => '打开项目以加载会话。';

  @override
  String get chatOpenSidebar => '打开侧边栏';

  @override
  String get chatPageStatusAutomaticCompactionExplanation =>
      'Automatic compaction happens as context usage grows.';

  @override
  String get chatPageStatusCompactNow => 'Compact now';

  @override
  String get chatPageStatusCompacting => 'Compacting...';

  @override
  String get chatPageStatusCompactingContextNow => 'Compacting context now...';

  @override
  String get chatPageStatusContextCompacted => 'Context compacted';

  @override
  String get chatPageStatusContextUsage => '上下文使用';

  @override
  String get chatPageStatusCost => '费用';

  @override
  String get chatPageStatusFailedToCompactContext =>
      'Failed to compact context';

  @override
  String get chatPageStatusLimit => '限额';

  @override
  String get chatPageStatusManageServers => '管理服务器';

  @override
  String get chatPageStatusSaver => '节省';

  @override
  String get chatPageStatusServer => 'Server';

  @override
  String get chatPageStatusSwitchServer => '切换服务器';

  @override
  String get chatPageStatusTokens => '令牌';

  @override
  String get chatPageStatusUsage => '使用';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatPermissionAutoApproveOff => '权限自动批准已关闭';

  @override
  String get chatPermissionAutoApproveOn => '权限自动批准已开启';

  @override
  String get chatProjectContext => 'Project Context';

  @override
  String get chatProjectContext2 => '项目上下文';

  @override
  String get chatRealtimeGlobalEvent => '全局事件';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return '全局事件 ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale => '全局事件 (过时代)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return '消息流 ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => '实时事件';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return '实时事件 ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale => '实时事件 (过时代)';

  @override
  String get chatRealtimeReconnectingServerTry => '正在重新连接服务器。请稍后重试。';

  @override
  String get chatReasoning => '推理中...';

  @override
  String get chatRecentSessions => 'Recent sessions';

  @override
  String get chatRecentSessionsToggle => 'Recent sessions';

  @override
  String get chatRedoLastTurn => 'Redo last undone turn';

  @override
  String get chatRedoNothing => '此会话中没有可重做的操作';

  @override
  String get chatRefresh => 'Refresh';

  @override
  String get chatRefreshConversation => 'Could not refresh this conversation';

  @override
  String get chatRefreshProjects => 'Refresh projects';

  @override
  String get chatRefreshSessionDetails => 'Refresh session details';

  @override
  String chatRemoveDisplayNameHistory(String displayName) {
    return '从历史记录中移除$displayName';
  }

  @override
  String get chatRetry => 'Retry';

  @override
  String get chatRetry2 => 'Retry';

  @override
  String get chatRetryRefresh => 'Retry refresh';

  @override
  String get chatRetryingModelRequest => 'Retrying model request...';

  @override
  String get chatReturnToMainConversation => 'Return to main conversation';

  @override
  String get chatReviewChanges => 'Review changes';

  @override
  String get chatSearchConversations => 'Search conversations';

  @override
  String get chatSearchNextResult => 'Next result';

  @override
  String get chatSearchNoResults => 'No results';

  @override
  String get chatSearchPreviousResult => 'Previous result';

  @override
  String chatSearchResultCount(int current, int total) {
    return 'Message $current of $total';
  }

  @override
  String get chatSearchTimeline => 'Search timeline';

  @override
  String get chatSelectDirectory => 'Select directory';

  @override
  String get chatSelectOrCreate =>
      'Select or create a conversation to start chatting';

  @override
  String get chatSelectProjectBelow => 'Select a project below.';

  @override
  String get chatServerSelectedModel => '服务器选择的模型';

  @override
  String get chatSessionActions => 'Session actions';

  @override
  String chatSessionChatSessionSession(String title) {
    return '聊天会话: $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return '对话 $nextAction';
  }

  @override
  String get chatSessionConversations => 'No conversations';

  @override
  String get chatSessionCreateConversationStart =>
      'Create a new conversation to start chatting';

  @override
  String chatSessionsLength(int length) {
    return '$length';
  }

  @override
  String get chatSetUpServer => 'Set up server';

  @override
  String get chatSettings => 'Settings';

  @override
  String get chatShortcutsCloseApp => '使用平台关闭行为关闭应用';

  @override
  String get chatShortcutsCycleModels => '轮换最近使用的模型';

  @override
  String get chatShortcutsCycleVariant => '轮换模型变体';

  @override
  String get chatShortcutsFocusInput => '聚焦消息输入';

  @override
  String get chatShortcutsFocusInputCloseDrawer => '聚焦输入（或在打开时关闭抽屉）';

  @override
  String get chatShortcutsForceExit => '强制退出应用';

  @override
  String get chatShortcutsNewConversation => '新对话';

  @override
  String get chatShortcutsNextAgent => '下一个智能体';

  @override
  String get chatShortcutsOpenSettings => '打开设置';

  @override
  String get chatShortcutsPreviousAgent => '上一个智能体';

  @override
  String get chatShortcutsQuickOpen => '快速打开文件';

  @override
  String get chatShortcutsRefreshChat => '刷新聊天数据';

  @override
  String get chatShortcutsStartStopVoice => '开始或停止语音输入';

  @override
  String get chatShortcutsStopResponse => '停止当前响应（正在响应时）';

  @override
  String get chatSidebarAccess => '侧边栏访问';

  @override
  String get chatSortMostRecent => 'Most Recent';

  @override
  String get chatSortOldest => 'Oldest';

  @override
  String get chatSortRecent => 'Recent';

  @override
  String get chatSortSessions => 'Sort sessions';

  @override
  String get chatSortTitle => 'Title';

  @override
  String get chatStartVoiceInput => '开始语音输入';

  @override
  String get chatStartingVoiceInput => '正在启动语音输入';

  @override
  String get chatStatusBusy => '状态：忙碌';

  @override
  String get chatStatusPatching => '正在打补丁';

  @override
  String chatStatusPatchingMultipleFiles(int count) {
    return '正在为 $count 个文件打补丁';
  }

  @override
  String get chatStatusPatchingOneFile => '正在为 1 个文件打补丁';

  @override
  String get chatStatusRetry => '状态：重试';

  @override
  String chatStatusRetryCount(int count) {
    return '状态：重试 #$count';
  }

  @override
  String get chatStatusSubsession => '子会话';

  @override
  String get chatStatusThinking => '正在思考...';

  @override
  String get chatStopVoiceInput => '停止语音输入';

  @override
  String chatSyncLabel(String label) {
    return '同步: $label';
  }

  @override
  String get chatTasks => 'Tasks';

  @override
  String get chatTasksAvailableSession =>
      'No tasks are available for this session.';

  @override
  String get chatTipBeSpecific => '提示：请具体一些 — 简短的提示词能获得更快的回答';

  @override
  String get chatTipBreakTasks => '提示：将大任务分解为更小的提示词';

  @override
  String get chatTipContextKnob => '提示：点击上下文旋钮查看使用详情';

  @override
  String get chatTipLongPressSend => '提示：长按发送键插入新行';

  @override
  String get chatTipMentionFiles => '提示：在提示词中使用 @ 来提及文件';

  @override
  String get chatTipProvideContext => '提示：提供上下文 — 粘贴错误消息和日志';

  @override
  String get chatTipRenameConversation => '提示：点击标题重命名对话';

  @override
  String get chatTipShellCommands => '提示：在开头使用 ! 来运行 shell 命令';

  @override
  String get chatTipSlashCommands => '提示：使用 / 访问斜杠命令';

  @override
  String get chatTipStepByStep => '提示：在调试复杂问题时要求逐步进行';

  @override
  String get chatToggleSidebars => 'Toggle sidebars';

  @override
  String chatTokensLabel(int total) {
    return 'Token：$total';
  }

  @override
  String get chatTourProjectsConversations => '使用此按钮打开您的项目和对话。';

  @override
  String get chatTourSidebarProjectTools => '使用此菜单显示对话侧边栏和项目工具。';

  @override
  String get chatTourSwitchFolders => '使用此按钮切换项目文件夹和上下文。';

  @override
  String get chatUndoLastTurn => 'Undo last turn';

  @override
  String get chatUndoNothing => '此会话中没有可撤销的操作';

  @override
  String get chatUseCurrent => 'Use current';

  @override
  String get chatWaitingForNetworkConnection => '等待网络连接...';

  @override
  String get chatWelcomeMessage => '您好！我是您的AI助手。';

  @override
  String get chatWelcomeSubmessage => '今天我能为您做些什么？';

  @override
  String get chatWorkBoundedPanelExplanation =>
      'Latest tool activity stays inside this bounded panel to keep the chat viewport stable.';

  @override
  String get chatWorkExpand => 'Expand';

  @override
  String get chatWorkHide => 'Hide';

  @override
  String get chatWorkMessageOne => '1 work message';

  @override
  String chatWorkMessagesMultiple(int count) {
    return '$count work messages';
  }

  @override
  String get chatWorkShow => 'Show';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonCopiedToClipboard => '已复制到剪贴板';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonFile => '文件';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonSave => 'Save';

  @override
  String get compactionAutomatic => '自动';

  @override
  String get compactionManual => '手动';

  @override
  String get composerAddAttachment => 'Add attachment';

  @override
  String get composerAttachFiles => 'Attach files';

  @override
  String get composerCannedAppendAtCursor => 'Append at cursor';

  @override
  String get composerCannedLabel => 'Label (optional)';

  @override
  String get composerCannedNoReplies => 'No quick replies yet.';

  @override
  String get composerCannedReplace => 'Replace';

  @override
  String get composerCannedSave => 'Save';

  @override
  String get composerCannedScopeGlobal => 'Global';

  @override
  String get composerCannedScopeProject => 'Project-only';

  @override
  String get composerCannedSendAutomatically => 'Send automatically';

  @override
  String get composerCannedText => 'Text';

  @override
  String get composerChatInput => 'Chat input';

  @override
  String get composerDeleteAction => 'Delete';

  @override
  String get composerEdit => 'Edit';

  @override
  String get composerExtras => 'Extras';

  @override
  String get composerNewQuickReply => 'New quick reply';

  @override
  String get composerSelectImages => 'Select Images';

  @override
  String get composerSelectPdf => 'Select PDF';

  @override
  String get composerSend => 'Send';

  @override
  String get composerShellMode => 'Shell mode';

  @override
  String get dialogDownload => 'Download';

  @override
  String get dialogLanguage => 'Language';

  @override
  String get dialogMoonshineModelSize => 'Model size';

  @override
  String get dialogMoonshineVoiceSetup => 'Moonshine Voice Setup';

  @override
  String get dialogParakeetModel => 'Parakeet model';

  @override
  String get dialogParakeetVoiceSetup => 'Parakeet Voice Setup';

  @override
  String get dialogSenseVoiceModel => 'SenseVoice model';

  @override
  String get dialogSenseVoiceSetup => 'SenseVoice Setup';

  @override
  String get dialogVoiceInputSetup => 'Voice Input Setup';

  @override
  String get errorAnErrorOccurred => '发生了一个错误';

  @override
  String get errorAuthRequired => '需要身份验证';

  @override
  String get errorAuthRequiredDesc => '身份验证失败。请重新连接提供商并重试。';

  @override
  String get errorConnectionFailed => '连接失败';

  @override
  String get errorConnectionFailedDesc => '无法连接到服务器。请检查网络连接和服务器状态。';

  @override
  String get errorFormatAuthenticationFailedReconnect =>
      'Authentication failed. Reconnect the provider and try again.';

  @override
  String get errorFormatProviderTemporarilyUnavailable =>
      'Provider temporarily unavailable. Try again shortly.';

  @override
  String get errorFormatQuotaExceededCheck =>
      'Quota exceeded. Check your provider plan or billing.';

  @override
  String get errorFormatRateLimitExceeded =>
      'Rate limit exceeded. Wait a moment and try again.';

  @override
  String get errorFormatServerErrorPlease => 'Server error. Please try again.';

  @override
  String get errorFormatServiceTemporarilyUnavailable =>
      'Service temporarily unavailable. The server may be starting up — please try again shortly.';

  @override
  String get errorFormatUnableReachServer =>
      'Unable to reach the server. Check connection and server status.';

  @override
  String get errorProviderUnavailable => '提供商不可用';

  @override
  String get errorProviderUnavailableDesc => '提供商暂时不可用。请稍后再试。';

  @override
  String get errorQuotaExceeded => '配额已超限';

  @override
  String get errorQuotaExceededDesc => '配额已超限。请检查您的提供商计划或账单。';

  @override
  String get errorRateLimitExceeded => '速率限制已超限';

  @override
  String get errorRateLimitExceededDesc => '速率限制已超限。请稍等片刻后重试。';

  @override
  String get errorServerError => '服务器错误';

  @override
  String get errorServerErrorDesc => '服务器错误。请重试。';

  @override
  String get errorServiceUnavailable => '服务不可用';

  @override
  String get errorServiceUnavailableDesc => '服务暂时不可用。服务器可能正在启动，请稍后再试。';

  @override
  String get fileActionAttachmentDataDecoded =>
      'Attachment data could not be decoded.';

  @override
  String get fileActionAttachmentPathEmpty => 'Attachment path is empty.';

  @override
  String get fileActionAttachmentPayloadEmpty => 'Attachment payload is empty.';

  @override
  String get fileActionAttachmentProvideValid =>
      'Attachment does not provide a valid location.';

  @override
  String get fileActionAttachmentSavedDevice =>
      'Attachment could not be saved on this device.';

  @override
  String fileActionAttachmentSavedOutputFile(String path) {
    return '附件已保存到$path并打开。';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return '附件已保存到$path。';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return '附件已保存到$savedPath。';
  }

  @override
  String get fileActionLocalAttachmentFound =>
      'Local attachment was not found on this device.';

  @override
  String get fileActionSaveCanceled => 'Save canceled.';

  @override
  String get fileActionUnableOpenLocal =>
      'Unable to open the local attachment.';

  @override
  String get filesAddChat => 'Add to chat';

  @override
  String get filesBinaryFilePreview => 'Binary file preview is not available.';

  @override
  String get filesClear => 'Clear';

  @override
  String get filesContents => 'Contents';

  @override
  String get filesFileEmpty => 'File is empty.';

  @override
  String get filesFilesFound => 'No files found';

  @override
  String get filesHideSidebar => 'Hide Files sidebar';

  @override
  String get filesNames => 'Names';

  @override
  String filesOpenFilesFileState(int length) {
    return '打开的文件 ($length)';
  }

  @override
  String get filesQuickOpen => 'Quick Open';

  @override
  String get filesQuickOpenFile => 'Quick Open File';

  @override
  String get filesRefresh => 'Refresh files';

  @override
  String get filesSearchHint => 'Search files by name or path';

  @override
  String get filesTitle => 'Files';

  @override
  String get logsAppLogs => 'App Logs';

  @override
  String get logsClear => 'Clear logs';

  @override
  String get logsCloseSearch => 'Close search';

  @override
  String get logsCopyFiltered => 'Copy filtered logs';

  @override
  String get logsFilterAll => '全部';

  @override
  String get logsLevel => 'Level';

  @override
  String get logsNoLogsYet => '尚未捕获日志。';

  @override
  String get logsNoMatchingLogs => '没有符合当前过滤条件的日志。';

  @override
  String get logsSearch => 'Search logs';

  @override
  String logsShowingOrderedLength(int length, int length2) {
    return '显示$length2条中的$length条';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => '数学';

  @override
  String get mermaidCopySourceTooltip => 'Copy source';

  @override
  String get mermaidDiagramLabel => 'Mermaid Diagram';

  @override
  String get modelAuto => 'Auto';

  @override
  String get modelChooseAgent => 'Choose agent';

  @override
  String get modelFavorites => 'Favorites';

  @override
  String get modelLabelBaseEnglish => '基础 (英语)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 种欧洲语言)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelTinyEnglish => 'Tiny (英语)';

  @override
  String get modelLoadingModels => 'Loading models';

  @override
  String get modelModelsFound => 'No models found';

  @override
  String get modelRetryModels => 'Retry models';

  @override
  String get modelSearchHint => 'Search model or provider';

  @override
  String get msgBatterySettingsFailed =>
      'Could not open Android battery optimization settings.';

  @override
  String get msgBatterySettingsOpened =>
      'Android battery settings opened. Allow unrestricted battery for CodeWalk.';

  @override
  String get msgClearUsernameNeedsConfigEdit =>
      'Clearing the OpenCode conversation username still requires editing config outside the app.';

  @override
  String get msgCommandCopied => 'Command copied';

  @override
  String get msgCopiedToClipboard => 'Copied to clipboard';

  @override
  String get msgEnterUsernameToSave =>
      'Enter a username to save a custom OpenCode conversation name.';

  @override
  String get msgFailedToSendMessage =>
      'Failed to send message. Draft kept for retry.';

  @override
  String get msgFailedToStartVoiceInput => 'Failed to start voice input';

  @override
  String msgFilePathNotFound(String path) {
    return 'File not found: $path';
  }

  @override
  String get msgFilteredLogsCopied => 'Filtered logs copied to clipboard';

  @override
  String get msgInfoAgent => 'Agent';

  @override
  String get msgInfoCompaction => 'Compaction';

  @override
  String msgInfoCost(double cost) {
    return 'Cost: \$$cost';
  }

  @override
  String get msgInfoMessageInfo => 'Message Info';

  @override
  String msgInfoModel(String modelId) {
    return 'Model: $modelId';
  }

  @override
  String get msgInfoNoMetadata => 'No metadata available';

  @override
  String msgInfoPartDescriptionModel(String description, String model) {
    return '$description$model';
  }

  @override
  String get msgInfoPatch => 'Patch';

  @override
  String msgInfoProvider(String providerId) {
    return 'Provider: $providerId';
  }

  @override
  String get msgInfoRetry => 'Retry';

  @override
  String get msgInfoSnapshot => 'Snapshot';

  @override
  String msgInfoSubtaskPartAgent(String agent) {
    return '子任务 ($agent)';
  }

  @override
  String msgInfoTokens(int total) {
    return 'Tokens: $total';
  }

  @override
  String get msgInfoUndoThisTurn => 'Undo this turn';

  @override
  String get msgInfoView => 'View';

  @override
  String get msgNoSystemSoundsFound =>
      'No system sound was found on this device.';

  @override
  String get msgNoValidFilesSelected => 'No valid files were selected';

  @override
  String get msgReadAloud => 'Read aloud';

  @override
  String get msgReadAloudNotAvailable =>
      'Text-to-speech is not available on this device.';

  @override
  String get msgSetupDebugCopied => 'OpenCode setup debug copied to clipboard';

  @override
  String get msgShareAsImage => 'Share as image';

  @override
  String get msgShareAsImageFailed => 'Could not share message as image.';

  @override
  String get msgShareAsImageSubject => 'CodeWalk message';

  @override
  String get msgShareAsImageTooTall =>
      'Message is too long to share as an image.';

  @override
  String get msgStopReadAloud => 'Stop reading';

  @override
  String get msgSystemSoundPickerUnavailable =>
      'System sound picker is not available on this platform.';

  @override
  String get msgUpdatedButRefreshFailed =>
      'Updated the server setting, but could not refresh chat providers.';

  @override
  String get msgVoiceInputUnavailable =>
      'Voice input is unavailable on this device';

  @override
  String get notifAndroidBatteryOptimization => 'Android battery optimization';

  @override
  String get notifConversationUpdates => 'Conversation updates';

  @override
  String get notifNotificationsArriveReopening =>
      'If notifications only arrive when reopening the app, allow CodeWalk to run without optimization on this device.';

  @override
  String get notifResponseRunningKeep =>
      'When a response is running, keep realtime active briefly after you leave the app.';

  @override
  String notifSelectedSoundLabel(String soundLabel) {
    return '已选择: $soundLabel';
  }

  @override
  String get notificationAgentFinished => '代理已完成当前响应。';

  @override
  String get notificationConversationUpdates => '会话更新';

  @override
  String get notificationOpenToClear => '打开此会话以清除相关通知。';

  @override
  String get notificationSession => '会话';

  @override
  String get notificationSoundLoadFailed => '无法加载 Android 系统声音';

  @override
  String get onboardingAIGeneratedTitles => 'AI generated titles';

  @override
  String get onboardingAddServerLater =>
      'You can add a server later in Settings > Servers.';

  @override
  String get onboardingAddedButHealthCheckFailed => '已添加服务器，但健康检查失败。它可能仍在启动中。';

  @override
  String get onboardingAlmostInstallOpenCode =>
      'You are almost there. Install OpenCode first, then connect CodeWalk to the server URL.';

  @override
  String onboardingAppProviderLocalSetupLogsLength(int length, int length2) {
    return '$length行设置日志和$length2个设置事件可在单独的设置调试屏幕中查看。';
  }

  @override
  String get onboardingAuthenticate => 'Authenticate';

  @override
  String get onboardingAvailable => '可用';

  @override
  String get onboardingAvailableOnlyDesktop => '仅在桌面端（Linux/macOS/Windows）可用。';

  @override
  String get onboardingBasicAuthTip => '仅当您的 OpenCode 服务器受密码保护时才启用基本身份验证。';

  @override
  String get onboardingChooseAnotherPath => 'Choose another path';

  @override
  String get onboardingChooseHowToSetup => '选择如何设置您的服务器';

  @override
  String get onboardingClear => 'Clear';

  @override
  String get onboardingCloudflareAuthFailed => 'Cloudflare Access 身份验证失败。';

  @override
  String get onboardingCodeWalkAppOpenCode =>
      'CodeWalk is the app. OpenCode is the engine it connects to.';

  @override
  String get onboardingConnectRunningServer => 'Connect to a running server';

  @override
  String get onboardingConnectionIssue => 'Connection issue';

  @override
  String get onboardingConnectionSaved => '服务器连接保存成功。';

  @override
  String get onboardingConnectionTips => 'Connection tips';

  @override
  String get onboardingConnectionUpdated => '服务器连接更新成功。';

  @override
  String get onboardingContinue => '继续';

  @override
  String get onboardingContinueServerURL => 'Continue to server URL';

  @override
  String get onboardingCopyLoginURL => 'Copy login URL';

  @override
  String get onboardingCouldNotVerify => '无法验证服务器连接。';

  @override
  String get onboardingDefaultURLEmulator =>
      'Default URL, emulator loopback, auth, and debug help.';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return '仅限桌面：$appName 可以为您诊断、安装和运行 OpenCode。';
  }

  @override
  String get onboardingDetailedSetupEvents =>
      'Detailed setup events were captured for troubleshooting.';

  @override
  String get onboardingDonShowAgain => 'Don\'t show again';

  @override
  String get onboardingDone => '完成';

  @override
  String get onboardingEditServer => '编辑服务器';

  @override
  String get onboardingEditServerConnection => '编辑服务器连接';

  @override
  String get onboardingEmulatorRemap =>
      '在 Android 模拟器上，localhost 和 127.0.0.1 会自动映射到 10.0.2.2。';

  @override
  String get onboardingEnterServerUrl => '输入服务器 URL';

  @override
  String get onboardingExisting => 'Use Existing';

  @override
  String get onboardingExplainInstallOpenCode =>
      'Explain how to install OpenCode, start the server, and then connect from CodeWalk.';

  @override
  String get onboardingFailed => '失败';

  @override
  String get onboardingGoodOptionDesktop => 'Good first option on desktop';

  @override
  String get onboardingHealthCheckFailedMayBeStarting => '服务器健康检查失败。它可能仍在启动中。';

  @override
  String get onboardingInstallBinary => 'Install Binary';

  @override
  String get onboardingInstallBun => 'Install via Bun';

  @override
  String get onboardingInstallBunOpenCode => 'Install Bun + OpenCode';

  @override
  String get onboardingInstallNpm => 'Install via npm';

  @override
  String get onboardingInstallRunOpenCode =>
      'Install and run OpenCode directly from CodeWalk on desktop.';

  @override
  String get onboardingInvalidUrl => '无效的 URL';

  @override
  String get onboardingLabel => 'Label (optional)';

  @override
  String get onboardingLabelHint => 'My server';

  @override
  String onboardingLatestOutputAppProvider(String localServerLastOutput) {
    return '最新输出: $localServerLastOutput';
  }

  @override
  String get onboardingLetCodeWalkSet => 'Let CodeWalk set it up locally';

  @override
  String get onboardingLocalServerSetup => '本地服务器设置';

  @override
  String get onboardingManagedLocalServer => 'Managed local server';

  @override
  String get onboardingManagedLocalServer2 =>
      'Managed local server mode is available only on desktop builds (Linux/macOS/Windows).';

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName 需要一个 OpenCode 服务器才能为您提供代码帮助。';
  }

  @override
  String get onboardingNotAvailable => '不可用';

  @override
  String get onboardingNotWritable => '不可写';

  @override
  String get onboardingOpenCode => 'What is OpenCode?';

  @override
  String get onboardingOpenCodeRunningDevice =>
      'I already have OpenCode running on this device or somewhere on my network.';

  @override
  String get onboardingOpenCodeRunsLocally =>
      'OpenCode runs locally or on a server and powers the AI coding features inside CodeWalk. If OpenCode is already running, connect to it. If not, pick one of the guided setup paths below.';

  @override
  String get onboardingOpenTailscaleLogin =>
      'Could not open Tailscale login URL.';

  @override
  String get onboardingPassword => 'Password';

  @override
  String get onboardingPasswordRequired => 'Enter password';

  @override
  String get onboardingPickSetupPath => '选择与您当前的 OpenCode 设置匹配的设置路径。';

  @override
  String get onboardingReachable => '可达';

  @override
  String get onboardingReady => '就绪';

  @override
  String get onboardingRecommendedOrderTry =>
      'Recommended order: try Install Bun + OpenCode if you want CodeWalk to bootstrap everything for you. Use Existing if OpenCode is already installed.';

  @override
  String get onboardingRefreshChecks => 'Refresh Checks';

  @override
  String get onboardingRunDiagnosticsToVerify => '运行诊断以验证本地 OpenCode 要求。';

  @override
  String get onboardingSaveAndTest => '保存并测试';

  @override
  String get onboardingServerConnectedReady => '您的服务器已连接并可以使用。';

  @override
  String get onboardingServerConnection => '服务器连接';

  @override
  String get onboardingServerSettingsSaved => '您的服务器设置已保存，健康检查已刷新。';

  @override
  String get onboardingServerSetup => '服务器设置';

  @override
  String get onboardingServerUpdated => '服务器已更新';

  @override
  String get onboardingServerUrl => 'Server URL';

  @override
  String get onboardingSetup => '设置';

  @override
  String get onboardingSetupWizard => '设置向导';

  @override
  String get onboardingShowSetupSteps => 'Show me the setup steps';

  @override
  String get onboardingShowSetupSteps2 => 'Show setup steps';

  @override
  String get onboardingSkip => 'Skip for now';

  @override
  String get onboardingSkipSetup => 'Skip setup?';

  @override
  String get onboardingStart => 'Start';

  @override
  String onboardingStartUsing(String appName) {
    return '开始使用 $appName';
  }

  @override
  String get onboardingStarting => '正在启动';

  @override
  String get onboardingStop => 'Stop';

  @override
  String get onboardingStopped => '已停止';

  @override
  String get onboardingStopping => '正在停止';

  @override
  String onboardingSuggestedUrl(String url) {
    return '建议的本地 OpenCode 服务器 URL：$url';
  }

  @override
  String get onboardingTailscaleAdminApproval => '需要 Tailscale 管理员批准';

  @override
  String get onboardingTailscaleAuthAfterSave => '保存后将进行 Tailscale 身份验证';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return '在您保存并测试此服务器后，如果此设备尚未通过身份验证，$appName 将打开 Tailscale 登录页面。';
  }

  @override
  String get onboardingTailscaleConnected => 'Tailscale 已连接';

  @override
  String get onboardingTailscaleConnecting => 'Tailscale 正在连接';

  @override
  String get onboardingTailscaleConnectionFailed => 'Tailscale 连接失败';

  @override
  String get onboardingTailscaleLoginRequired => '需要登录 Tailscale';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      '打开登录 URL 将此设备添加到您的 tailnet。如果浏览器未打开，请复制下面的 URL。';

  @override
  String get onboardingTailscaleUnsupported => '不支持 Tailscale';

  @override
  String get onboardingTestConnection => '测试连接';

  @override
  String get onboardingTesting => '正在测试...';

  @override
  String get onboardingUnreachable => '不可达';

  @override
  String get onboardingUseBasicAuth => 'Use Basic Auth';

  @override
  String get onboardingUsername => 'Username';

  @override
  String get onboardingUsernameRequired => 'Enter username';

  @override
  String get onboardingUsesServerTitle =>
      'Uses your server\'s title agent to name conversations';

  @override
  String get onboardingUsingDetectedCommand => '使用检测到的 OpenCode 命令。';

  @override
  String get onboardingViewSetupDebug => 'View setup debug';

  @override
  String onboardingWelcomeTo(String appName) {
    return '欢迎使用 $appName';
  }

  @override
  String get onboardingWindowsTipInstalling =>
      'Windows tip: after installing, click Refresh Checks. If detection still fails, reopen CodeWalk to reload PATH changes.';

  @override
  String get onboardingWritable => '可写';

  @override
  String get onboardingYoureAllSet => '一切就绪！';

  @override
  String get permissionAllowOnce => 'Allow Once';

  @override
  String get permissionAlways => 'Always';

  @override
  String get permissionBack => 'Back';

  @override
  String get permissionConfirmReject => 'Confirm Reject';

  @override
  String get permissionReject => 'Reject';

  @override
  String get permissionReopen => 'Reopen';

  @override
  String get questionAnswerSelected => 'No answer selected.';

  @override
  String get questionCommaSeparatedValues => 'Comma-separated values';

  @override
  String get questionQuestionGroupMarked =>
      'Question group marked as rejected. You can keep chatting and reopen this group anytime before confirming.';

  @override
  String get questionQuestionRequest => 'Question request';

  @override
  String get questionQuestionsProvidedSubmit =>
      'No questions provided. You can submit an empty response.';

  @override
  String get questionReviewAnswersSubmitting =>
      'Review your answers before submitting.';

  @override
  String get quotaAuthCookie => 'Auth cookie';

  @override
  String get quotaForget => 'Forget';

  @override
  String get quotaOpenCodeGoUsage => 'OpenCode Go usage';

  @override
  String get quotaOpenDashboard => 'Open OpenCode dashboard';

  @override
  String get quotaSaving => 'Saving...';

  @override
  String get quotaWorkspaceId => 'Workspace ID';

  @override
  String get serverClearOAuth => 'Clear OAuth';

  @override
  String get serverConnectionAttention => '服务器连接需要注意。';

  @override
  String get serverHealthHealthy => '正常';

  @override
  String get serverHealthUnhealthy => '异常';

  @override
  String get serverHealthUnknown => '未知';

  @override
  String get serverOAuthAuthFailed => 'OAuth authentication failed';

  @override
  String get serverOAuthChip => 'OAuth';

  @override
  String get serverOAuthNotSupported =>
      'Cloudflare Access OAuth is not supported on this platform';

  @override
  String get serverReauthenticate => 'Re-authenticate';

  @override
  String get serverTailscaleChip => 'Tailscale';

  @override
  String get serversActive => 'Active';

  @override
  String get serversActiveServer => 'Active Server';

  @override
  String get serversAddLeastOpenCode =>
      'Add at least one OpenCode server to start using the app.';

  @override
  String get serversAddServer => 'Add Server';

  @override
  String get serversCancel => 'Cancel';

  @override
  String get serversCannotActivateUnhealthy => '无法激活不健康的服务器';

  @override
  String get serversCheckHealth => 'Check Health';

  @override
  String get serversClearDefault => 'Clear Default';

  @override
  String serversCommandAppProviderLocalServerCommandPath(
    String localServerCommandPath,
  ) {
    return '命令: $localServerCommandPath';
  }

  @override
  String get serversCopy => 'Copy';

  @override
  String get serversDefault => 'Default';

  @override
  String get serversDelete => 'Delete';

  @override
  String get serversDeleteServer => 'Delete server';

  @override
  String get serversDesktopModeExplanation =>
      '桌面模式可以直接从 CodeWalk 启动和管理 `opencode serve`。';

  @override
  String get serversEdit => 'Edit';

  @override
  String get serversLocalOpenCodeServer => 'Local OpenCode Server';

  @override
  String get serversManagedModeAvailable =>
      'This managed mode is available only on desktop builds (Linux/macOS/Windows).';

  @override
  String get serversNoServersFound => '未找到服务器';

  @override
  String get serversRefreshHealth => 'Refresh Health';

  @override
  String serversRemoveProfileDisplayName(String displayName) {
    return '删除\"$displayName\"？';
  }

  @override
  String get serversSearchActiveHint => '搜索活动服务器';

  @override
  String get serversServersConfigured => 'No servers configured';

  @override
  String get serversSetActive => 'Set Active';

  @override
  String get serversSetDefault => 'Set Default';

  @override
  String get serversSetupDebug => 'Setup Debug';

  @override
  String get serversSetupWizard => 'Setup Wizard';

  @override
  String get serversTailscaleAdminApprovalRequired => '需要 Tailscale 管理员批准';

  @override
  String get serversTailscaleAuthRequired => '需要 Tailscale 身份验证';

  @override
  String get serversTailscaleConnectExplanation => '使用此活动配置文件时，Tailscale 将连接。';

  @override
  String get serversTailscaleConnected => 'Tailscale 已连接';

  @override
  String get serversTailscaleConnecting => 'Tailscale 正在连接';

  @override
  String get serversTailscaleConnectionFailed => 'Tailscale 连接失败';

  @override
  String get serversTailscaleDisconnected => 'Tailscale 已断开';

  @override
  String get serversTailscaleLoginExplanation =>
      '打开 Tailscale 登录 URL 将此设备添加到您的 tailnet。';

  @override
  String get serversTailscaleTrafficExplanation =>
      '此活动配置文件的 OpenCode 流量通过 Tailscale 路由。';

  @override
  String get serversTailscaleUnsupported => '不支持 Tailscale';

  @override
  String get serversUnhealthyActivateError => '此服务器不健康。请在激活前检查运行状况或编辑设置。';

  @override
  String get sessionActionArchived => 'archived';

  @override
  String get sessionActionDeleted => 'deleted';

  @override
  String get sessionActionForked => 'forked';

  @override
  String get sessionActionUnarchived => 'unarchived';

  @override
  String get sessionCancelRename => 'Cancel rename';

  @override
  String sessionChildrenCount(int count) {
    return '子对话：$count';
  }

  @override
  String get sessionCompactContext => '压缩上下文';

  @override
  String get sessionCopyLink => '复制共享链接';

  @override
  String get sessionDelete => 'Delete';

  @override
  String get sessionDeleteTitle => 'Delete Conversation';

  @override
  String get sessionDiffChangedFile => 'Changed file';

  @override
  String get sessionDiffContentNotCaptured =>
      'File content not captured by the server';

  @override
  String sessionDiffFilesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files changed',
      one: '1 file changed',
    );
    return '$_temp0';
  }

  @override
  String sessionDiffFilesCount(int count) {
    return '差异文件：$count';
  }

  @override
  String sessionDiffLinesAddedRemoved(int added, int removed) {
    return '+$added lines added -$removed lines removed';
  }

  @override
  String sessionDiffLinesCollapsed(int count) {
    return '$count lines collapsed — tap to expand';
  }

  @override
  String get sessionDiffReview => 'Review changes';

  @override
  String get sessionDiffSplit => 'Split';

  @override
  String get sessionDiffSummary => 'Summary';

  @override
  String get sessionDiffUnified => 'Unified';

  @override
  String get sessionExportAssistant => '助手';

  @override
  String get sessionExportCanceled => '会话导出已取消';

  @override
  String get sessionExportDebugJson => '导出调试JSON';

  @override
  String get sessionExportDebugJsonErrorClipboard => '无法保存文件；调试JSON已复制到剪贴板';

  @override
  String get sessionExportDebugJsonSaved => '调试JSON导出已保存';

  @override
  String get sessionExportDebugJsonTitle => '将会话导出为调试JSON';

  @override
  String get sessionExportError => '错误：';

  @override
  String get sessionExportInput => '输入：';

  @override
  String get sessionExportMarkdown => '导出Markdown';

  @override
  String get sessionExportMarkdownErrorClipboard => '无法保存文件；Markdown已复制到剪贴板';

  @override
  String get sessionExportMarkdownSaved => 'Markdown导出已保存';

  @override
  String get sessionExportMarkdownTitle => '将会话导出为Markdown';

  @override
  String get sessionExportOutput => '输出：';

  @override
  String get sessionExportUntitled => '无标题会话';

  @override
  String get sessionExportUser => '用户';

  @override
  String get sessionFailedRename => 'Failed to rename conversation';

  @override
  String get sessionFailedUpdateArchive => 'Failed to update archive state';

  @override
  String get sessionFailedUpdateSharing => 'Failed to update sharing state';

  @override
  String get sessionFork => 'Fork';

  @override
  String get sessionForkFailed => '复制对话失败';

  @override
  String get sessionForked => '对话已复制';

  @override
  String sessionHasError(String title) {
    return '“$title”有错误。';
  }

  @override
  String sessionHasNewReply(String title) {
    return '“$title”有新的回复。';
  }

  @override
  String get sessionKeyboardShortcuts => 'Keyboard shortcuts';

  @override
  String sessionNeedsInput(String title) {
    return '“$title”需要您的输入。';
  }

  @override
  String get sessionNoCachedConversations => '暂无缓存的对话';

  @override
  String get sessionNoConversationsInProject => '此项目中没有对话。';

  @override
  String get sessionNotAvailable =>
      'Conversation is not available for this project yet';

  @override
  String get sessionOpenProjectToLoad => '打开项目以加载对话。';

  @override
  String get sessionRename => 'Rename';

  @override
  String get sessionRenameHint => 'Enter new conversation name';

  @override
  String get sessionRenameTitle => 'Rename Conversation';

  @override
  String get sessionSaveTitle => 'Save title';

  @override
  String get sessionShare => '共享会话';

  @override
  String get sessionShareLinkCopied => 'Share link copied';

  @override
  String get sessionShareLinkUnavailable => '此会话的共享链接不可用';

  @override
  String get sessionShared => '对话已共享';

  @override
  String get sessionSyncing => '正在同步对话...';

  @override
  String get sessionTitleHint => 'Conversation title';

  @override
  String get sessionUnshare => '取消共享会话';

  @override
  String get sessionUnshared => '对话已取消共享';

  @override
  String get sessionViewTasks => '查看任务';

  @override
  String get settingsAboutCheckForUpdates => 'Check for updates';

  @override
  String get settingsAboutCheckOnOpen => 'Check for updates on open';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Automatically check when the app starts';

  @override
  String get settingsAboutChecking => 'Checking...';

  @override
  String get settingsAboutDescription => 'Version, updates and links';

  @override
  String get settingsAboutDismiss => 'Dismiss';

  @override
  String settingsAboutDownloading(String percent) {
    return 'Downloading... $percent%';
  }

  @override
  String get settingsAboutEraseAllData => 'Erase all data and restart';

  @override
  String get settingsAboutInstallUpdate => 'Install update';

  @override
  String get settingsAboutInstalling => 'Installing...';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version is the latest version';
  }

  @override
  String get settingsAboutLoading => 'Loading...';

  @override
  String get settingsAboutReplayChatTour => 'Replay chat tour';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Close settings and show the guided chat walkthrough';

  @override
  String get settingsAboutResetApp => 'Reset app';

  @override
  String get settingsAboutResetAppQuestion => 'Reset app?';

  @override
  String get settingsAboutResetAppWarning =>
      'This will erase all servers, settings, and cached data. This action cannot be undone.';

  @override
  String get settingsAboutRetryInstall => 'Retry install';

  @override
  String get settingsAboutTapToCheck => 'Tap to check for new versions';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutUpToDate => 'You\'re up to date';

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Update available: v$version';
  }

  @override
  String get settingsAboutUpdateInstalled =>
      'Update installed. Restart the app to apply.';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String settingsAboutVersionBuild(String buildNumber, String version) {
    return '$version (build $buildNumber)';
  }

  @override
  String get settingsAppearanceAmoledDark => 'AMOLED dark mode';

  @override
  String get settingsAppearanceAmoledDarkActive =>
      'Use pure black surfaces while dark mode is active.';

  @override
  String get settingsAppearanceAmoledDarkInactive =>
      'Switch to dark mode to enable AMOLED surfaces.';

  @override
  String get settingsAppearanceBrandColor => 'Brand color';

  @override
  String get settingsAppearanceBrandColorDynamicBlocked =>
      'Disable wallpaper colors to pick a brand color.';

  @override
  String get settingsAppearanceBrandColorNormal =>
      'Pick a seed color for the app palette.';

  @override
  String get settingsAppearanceBrandColorPresetBlocked =>
      'Switch to CodeWalk Classic to pick a brand color.';

  @override
  String get settingsAppearanceCodeWalkClassic => 'CodeWalk Classic';

  @override
  String get settingsAppearanceComposerTips => 'Composer tips';

  @override
  String get settingsAppearanceComposerTipsDescription =>
      'Show or hide rotating tips while the assistant is reasoning.';

  @override
  String get settingsAppearanceContrast => 'Contrast';

  @override
  String get settingsAppearanceContrastDynamicBlocked =>
      'Disable wallpaper colors to adjust contrast.';

  @override
  String get settingsAppearanceContrastHigh => 'High';

  @override
  String get settingsAppearanceContrastNormal =>
      'Adjust the contrast level of the color scheme.';

  @override
  String get settingsAppearanceContrastPresetBlocked =>
      'Switch to CodeWalk Classic to adjust contrast.';

  @override
  String get settingsAppearanceContrastReduced => 'Reduced';

  @override
  String get settingsAppearanceDark => 'Dark';

  @override
  String get settingsAppearanceDensity => 'Density';

  @override
  String get settingsAppearanceDensityDense => 'Dense';

  @override
  String get settingsAppearanceDensityDescription =>
      'Apply spacing and component density across the app.';

  @override
  String get settingsAppearanceDensityExtraDense => 'Extra Dense';

  @override
  String get settingsAppearanceDensityExtraSpacious => 'Extra Spacious';

  @override
  String get settingsAppearanceDensityNormal => 'Normal';

  @override
  String get settingsAppearanceDensitySpacious => 'Spacious';

  @override
  String get settingsAppearanceDescription =>
      'Density and timeline bubble visibility';

  @override
  String get settingsAppearanceLight => 'Light';

  @override
  String get settingsAppearanceMathRendering => '数学公式渲染';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      '在聊天消息中将 LaTeX 数学表达式渲染为排版公式。';

  @override
  String get settingsAppearanceNoPresets => 'No preset palettes found';

  @override
  String get settingsAppearanceOpenCodePresets => 'OpenCode Presets';

  @override
  String get settingsAppearancePresetHelper =>
      'Mirrors the official OpenCode Web built-in theme list.';

  @override
  String get settingsAppearancePresetNote =>
      'Theme colors now follow the official OpenCode Web registry and drive markdown/code surfaces too.';

  @override
  String get settingsAppearancePresetPalette => 'Preset palette';

  @override
  String get settingsAppearanceSearchPreset => 'Search preset palette';

  @override
  String get settingsAppearanceSectionDescription =>
      'Tune visual density and message surfaces for your workflow.';

  @override
  String get settingsAppearanceSectionTitle => 'Appearance';

  @override
  String get settingsAppearanceSystem => 'System';

  @override
  String get settingsAppearanceTaskList => 'Task list';

  @override
  String get settingsAppearanceTaskListDescription =>
      'Show or hide the session task list widget.';

  @override
  String get settingsAppearanceTheme => 'Theme';

  @override
  String get settingsAppearanceThemeDescription =>
      'Choose light, dark, or system mode, then keep the CodeWalk classic palette or switch to an OpenCode preset.';

  @override
  String get settingsAppearanceThinkingBubbles => 'Thinking bubbles';

  @override
  String get settingsAppearanceThinkingBubblesDescription =>
      'Show or hide reasoning blocks in assistant messages.';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsAppearanceToolCallBubbles => 'Tool call bubbles';

  @override
  String get settingsAppearanceToolCallBubblesDescription =>
      'Show or hide tool execution cards in assistant messages.';

  @override
  String get settingsAppearanceWallpaperColors => 'Use wallpaper colors';

  @override
  String get settingsAppearanceWallpaperNormal =>
      'Extract color scheme from your device wallpaper.';

  @override
  String get settingsAppearanceWallpaperPresetBlocked =>
      'Switch to CodeWalk Classic to use wallpaper colors.';

  @override
  String get settingsBack => 'Back';

  @override
  String get settingsBehaviorAutoupdateCaveat =>
      'Use About for CodeWalk release checks. This setting only mirrors the official OpenCode `autoupdate` config.';

  @override
  String get settingsBehaviorAutoupdateHelp =>
      'Controls upstream OpenCode runtime updates, not CodeWalk app update checks.';

  @override
  String get settingsBehaviorCellularDataSaver => 'Cellular data saver';

  @override
  String get settingsBehaviorConfigDeferred =>
      'CodeWalk will apply this OpenCode setting after the current response finishes.';

  @override
  String settingsBehaviorConfigUpdateFailed(String field) {
    return 'Could not update the OpenCode $field.';
  }

  @override
  String get settingsBehaviorConversationUsername => 'Conversation username';

  @override
  String get settingsBehaviorConversationUsernameHelp =>
      'Custom display name shown in conversations instead of the system username.';

  @override
  String get settingsBehaviorDataSaverActive => 'Active now on mobile data.';

  @override
  String get settingsBehaviorDataSaverCellularOnly =>
      'Only applies when the connection is cellular/mobile.';

  @override
  String get settingsBehaviorDataSaverDescription =>
      'Cuts automatic mobile-data usage by stopping background downloads and throttling automatic foreground refreshes.';

  @override
  String get settingsBehaviorDataSaverWaiting =>
      'Waiting for the next mobile-data sync window.';

  @override
  String get settingsBehaviorDefaultAgent => 'Default agent';

  @override
  String get settingsBehaviorDefaultAgentHelp =>
      'Primary agent used when no agent is explicitly chosen.';

  @override
  String get settingsBehaviorDefaultModel => 'Default model';

  @override
  String get settingsBehaviorDefaultModelHelp =>
      'Shared across OpenCode clients through config.';

  @override
  String get settingsBehaviorDescription =>
      'OpenCode defaults, provenance, and composer sync safety';

  @override
  String get settingsBehaviorEnableDataSaver => 'Enable cellular data saver';

  @override
  String get settingsBehaviorMultiDeviceSync =>
      'Enable experimental multi-device sync';

  @override
  String get settingsBehaviorMultiDeviceSyncDescription =>
      'Sync composer selection (agent/model/variant) with the active server config.';

  @override
  String get settingsBehaviorMultiDeviceSyncWarning =>
      'Can abort ongoing sessions when working in more than one session at the same time.';

  @override
  String get settingsBehaviorNoAgents => 'No agents found';

  @override
  String get settingsBehaviorNoModels => 'No models found';

  @override
  String get settingsBehaviorOpenCodeAutoupdate => 'OpenCode auto-update';

  @override
  String get settingsBehaviorOpenCodeDefaults => 'OpenCode-backed defaults';

  @override
  String get settingsBehaviorOpenCodeDefaultsDescription =>
      'These values write to `/config` on the active server and match official OpenCode shared config.';

  @override
  String get settingsBehaviorOpenCodeSnapshots => 'OpenCode snapshots';

  @override
  String get settingsBehaviorOpenCodeSnapshotsDescription =>
      'Keep upstream git-backed snapshots enabled for undo/redo and recovery history.';

  @override
  String get settingsBehaviorPermissionDeferred =>
      'Advanced permission rule editing stays out of Settings for now and is deferred to later parity work.';

  @override
  String get settingsBehaviorPermissionProvenance =>
      'Permission handling provenance';

  @override
  String get settingsBehaviorPermissionProvenanceDescription =>
      'Official OpenCode permission policy is configured in `opencode.json` with allow/ask/deny rules per tool. CodeWalk keeps the official permission-request cards and adds one approved ADR-023 exception: the composer auto-approve toggle replies with `Always` and `remember: true` unconditionally to create durable session-scoped grants, and keeps the same thread-scoped continuity path active in the Android background worker.';

  @override
  String get settingsBehaviorRefreshDefaults => 'Refresh defaults';

  @override
  String get settingsBehaviorSaveUsername => 'Save username';

  @override
  String get settingsBehaviorSearchAutoupdate => 'Search auto-update mode';

  @override
  String get settingsBehaviorSearchDefaultAgent => 'Search default agent';

  @override
  String get settingsBehaviorSearchDefaultModel => 'Search default model';

  @override
  String get settingsBehaviorSearchShareMode => 'Search sharing mode';

  @override
  String get settingsBehaviorSearchSmallModel => 'Search small model';

  @override
  String get settingsBehaviorShareMode => 'OpenCode sharing default';

  @override
  String get settingsBehaviorShareModeCaveat =>
      'Use the chat-level share action to publish one session now. This setting only changes OpenCode\'s default sharing policy.';

  @override
  String get settingsBehaviorShareModeHelp =>
      'Controls the official global `share` config, not the share button for an individual chat.';

  @override
  String get settingsBehaviorSmallModel => 'Small model';

  @override
  String get settingsBehaviorSmallModelAutoFallback => 'Automatic fallback';

  @override
  String get settingsBehaviorSmallModelFallbackActive =>
      'OpenCode automatic fallback is active because `small_model` is unset.';

  @override
  String get settingsBehaviorSmallModelHelp =>
      'Used for lightweight tasks like title generation.';

  @override
  String get settingsBehaviorSmallModelResetCaveat =>
      'Resetting `small_model` back to automatic fallback still requires editing config outside the app because `/config` patch updates cannot remove keys.';

  @override
  String get settingsBehaviorSnapshotCaveat =>
      'This controls OpenCode snapshot storage and undo/redo support, not CodeWalk local cache snapshots.';

  @override
  String get settingsBehaviorTitle => 'Behavior';

  @override
  String get settingsBehaviorUsernameFallback =>
      'OpenCode uses the system username because `username` is unset.';

  @override
  String get settingsBehaviorUsernamePatchCaveat =>
      'Resetting `username` back to the system default still requires editing config outside the app because `/config` patch updates cannot remove keys.';

  @override
  String get settingsConfigRefreshFailed =>
      'Updated the server setting, but could not refresh chat providers.';

  @override
  String get settingsConfigUpdateDeferred =>
      'CodeWalk will apply this OpenCode setting after the current response finishes.';

  @override
  String get settingsConversationUsername => '对话用户名';

  @override
  String get settingsDefaultAgent => '默认智能体';

  @override
  String get settingsDefaultModel => '默认模型';

  @override
  String get settingsLanguageDescription =>
      'Choose the language used by CodeWalk. System default follows your device language.';

  @override
  String get settingsLanguageEmptyText => 'No languages found';

  @override
  String get settingsLanguageFieldHelper =>
      'Applies immediately and persists across restarts.';

  @override
  String get settingsLanguageFieldLabel => 'App language';

  @override
  String get settingsLanguageSearchHint => 'Search languages';

  @override
  String get settingsLanguageSystemDefault => 'System default';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLogsDescription =>
      'Runtime diagnostics and troubleshooting data';

  @override
  String get settingsLogsTitle => 'Registros';

  @override
  String get settingsNoAgentsFound => '未找到智能体';

  @override
  String get settingsNotificationsAgentSubtitle => 'When a response finishes';

  @override
  String get settingsNotificationsAgentUpdates => 'Agent updates';

  @override
  String get settingsNotificationsAnotherConversation => 'Another conversation';

  @override
  String get settingsNotificationsAppInBackground => 'App in background';

  @override
  String get settingsNotificationsBackgroundAlerts =>
      'Android background alerts';

  @override
  String get settingsNotificationsBackgroundBehavior => 'Background behavior';

  @override
  String get settingsNotificationsBackgroundBehaviorDescription =>
      'Choose how CodeWalk behaves after the app leaves the foreground.';

  @override
  String get settingsNotificationsBackgroundDescription =>
      'Use low-data background monitoring for response completions, permission requests, questions, and errors while the app is not on screen.';

  @override
  String get settingsNotificationsBackgroundToggle =>
      'Background alerts on Android';

  @override
  String get settingsNotificationsBackgroundToggleDescription =>
      'Turn off all Android background checks and hide the persistent monitor notification.';

  @override
  String get settingsNotificationsBatteryDescription =>
      'If notifications only arrive when reopening the app, allow CodeWalk to run without optimization on this device.';

  @override
  String get settingsNotificationsBatteryDisabled =>
      'Battery optimization is disabled for CodeWalk.';

  @override
  String get settingsNotificationsBatteryEnabled =>
      'Battery optimization is enabled. Some devices may delay background alerts.';

  @override
  String get settingsNotificationsBatteryOptimization =>
      'Android battery optimization';

  @override
  String get settingsNotificationsBatteryUnknown =>
      'Could not read battery optimization status yet.';

  @override
  String get settingsNotificationsChooseAudioFile => 'Choose audio file';

  @override
  String get settingsNotificationsChooseSystemSound => 'Choose system sound';

  @override
  String get settingsNotificationsCloseToTray => 'Close to tray';

  @override
  String get settingsNotificationsCloseToTrayDescription =>
      'Hide window and keep running in system tray.';

  @override
  String get settingsNotificationsDescription =>
      'Per-category notify and sound controls';

  @override
  String get settingsNotificationsDisableOptimization => 'Disable optimization';

  @override
  String get settingsNotificationsErrors => 'Errors';

  @override
  String get settingsNotificationsErrorsSubtitle =>
      'When a session reports a failure';

  @override
  String get settingsNotificationsJustClose => 'Just close';

  @override
  String get settingsNotificationsJustCloseDescription =>
      'Exit the application completely.';

  @override
  String get settingsNotificationsKeepLive => 'Keep alerts live for 3 min';

  @override
  String get settingsNotificationsKeepLiveDescription =>
      'When a response is already running, keep realtime active briefly after leaving the app.';

  @override
  String get settingsNotificationsLocal => 'Local';

  @override
  String get settingsNotificationsMinimizeWhenClose => 'Minimize when close';

  @override
  String get settingsNotificationsMinimizeWhenCloseDescription =>
      'Minimize to taskbar/dock and keep running.';

  @override
  String get settingsNotificationsNoCondition =>
      'If no condition is selected, alerts are allowed in any context.';

  @override
  String get settingsNotificationsNotify => 'Notify';

  @override
  String get settingsNotificationsNotifyOnlyWhen => 'Notify only when';

  @override
  String get settingsNotificationsOpenBatterySettings =>
      'Open battery settings';

  @override
  String get settingsNotificationsPermissions => 'Permissions and questions';

  @override
  String get settingsNotificationsPermissionsSubtitle =>
      'When tools request your input';

  @override
  String get settingsNotificationsPreview => 'Preview';

  @override
  String get settingsNotificationsRefreshStatus => 'Refresh status';

  @override
  String get settingsNotificationsSearchSoundType => 'Search sound type';

  @override
  String get settingsNotificationsSectionDescription =>
      'Control when alerts appear and when they can play sound.';

  @override
  String get settingsNotificationsSectionTitle => 'Notifications';

  @override
  String settingsNotificationsSelectedSound(String label) {
    return 'Selected: $label';
  }

  @override
  String get settingsNotificationsServer => 'Server';

  @override
  String get settingsNotificationsSound => 'Sound';

  @override
  String get settingsNotificationsSoundOnlyWhen => 'Sound only when';

  @override
  String get settingsNotificationsSoundType => 'Sound type';

  @override
  String get settingsNotificationsSyncInfo =>
      'Some category on/off toggles are synced from /config on the active server.';

  @override
  String get settingsNotificationsSyncInfoLocal =>
      'Current server does not expose notification toggles in /config; local values are active.';

  @override
  String get settingsNotificationsSystemSoundPickerTitle =>
      'Choose system sound';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsWhenClosing => 'When closing the window';

  @override
  String get settingsOpenCodeAutoUpdate => 'OpenCode 自动更新';

  @override
  String get settingsOpenCodeSharingDefault => 'OpenCode 默认共享';

  @override
  String get settingsReadAloudEnabled => 'Read aloud';

  @override
  String get settingsReadAloudEnabledDescription =>
      'Show a read-aloud button on assistant messages.';

  @override
  String get settingsReadAloudPitch => 'Pitch';

  @override
  String get settingsReadAloudPitchDescription => 'Adjust the voice pitch.';

  @override
  String get settingsReadAloudSectionDescription =>
      'Read assistant responses aloud. Configure speed, pitch, and voice.';

  @override
  String get settingsReadAloudSectionTitle => 'Text to speech';

  @override
  String get settingsReadAloudSpeed => 'Speed';

  @override
  String get settingsReadAloudSpeedDescription => 'Adjust the speaking rate.';

  @override
  String get settingsReadAloudVoice => 'Voice';

  @override
  String get settingsReadAloudVoiceHint => 'Select a voice for read-aloud.';

  @override
  String get settingsSearchAutoUpdateMode => '搜索自动更新模式';

  @override
  String get settingsSearchDefaultAgent => '搜索默认智能体';

  @override
  String get settingsSearchDefaultModel => '搜索默认模型';

  @override
  String get settingsSearchSharingMode => '搜索共享模式';

  @override
  String get settingsSearchSmallModel => '搜索小模型';

  @override
  String get settingsServersActive => 'Active';

  @override
  String get settingsServersChooseActive => 'Choose active server';

  @override
  String get settingsServersDefault => 'Default';

  @override
  String get settingsServersDescription =>
      'OpenCode servers and health routing';

  @override
  String get settingsServersTitle => 'Servers';

  @override
  String get settingsSetupWizard => 'Setup Wizard';

  @override
  String get settingsShortcutsDescription => 'Portable app key bindings';

  @override
  String get settingsShortcutsEdit => 'Edit shortcut';

  @override
  String get settingsShortcutsKeyboard => 'Keyboard shortcuts';

  @override
  String get settingsShortcutsReset => 'Reset shortcut';

  @override
  String get settingsShortcutsSearch => 'Search shortcuts';

  @override
  String get settingsShortcutsTitle => 'Shortcuts';

  @override
  String get settingsSmallModel => '小模型';

  @override
  String get settingsSmallModelResetExplanation =>
      '将 `small_model` 重置回自动回退仍需在应用外编辑配置，因为 `/config` 补丁更新无法删除键。';

  @override
  String get settingsSmallModelUnsetExplanation =>
      '由于未设置 `small_model`，OpenCode 自动回退已激活。';

  @override
  String get settingsSoundPickerNotAvailable => '系统声音选择器在此平台上不可用。';

  @override
  String get settingsSpeechDescription =>
      'Engine, silence timeout, and model options';

  @override
  String get settingsSpeechRefreshStatus => 'Refresh status';

  @override
  String settingsSpeechSilenceTimeout(String value) {
    return 'Silence timeout: ${value}s';
  }

  @override
  String get settingsSpeechTitle => 'Speech to text';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUsernameClearHint =>
      'Clearing the OpenCode conversation username still requires editing config outside the app.';

  @override
  String get settingsUsernameEnterHint =>
      'Enter a username to save a custom OpenCode conversation name.';

  @override
  String get settingsUsernameResetExplanation =>
      '将 `username` 重置回系统默认值仍需在应用外编辑配置，因为 `/config` 补丁更新无法删除键。';

  @override
  String get settingsUsernameUnsetExplanation =>
      'OpenCode 使用系统用户名，因为 `username` 未设置。';

  @override
  String get setupDebugBun => 'Bun';

  @override
  String get setupDebugBun2 => 'Bun';

  @override
  String get setupDebugCapturedSetupDetails => 'No captured setup details yet';

  @override
  String get setupDebugCapturedSetupLogs => 'Captured setup logs';

  @override
  String get setupDebugClear => 'Clear setup debug';

  @override
  String get setupDebugClearSetupDebug => 'Clear setup debug';

  @override
  String get setupDebugCodeWalkCaptureEnough =>
      'If CodeWalk did not capture enough context, check the official OpenCode logs and health endpoints directly:';

  @override
  String get setupDebugCommandPath => 'Command path';

  @override
  String get setupDebugCommandPath2 => 'Command path';

  @override
  String get setupDebugCopy => 'Copy setup debug';

  @override
  String get setupDebugCopySetupDebug => 'Copy setup debug';

  @override
  String get setupDebugCurrentStatus => 'Current status';

  @override
  String get setupDebugDiagnosticsLoading => 'Diagnostics are still loading.';

  @override
  String get setupDebugEnvironment => 'Environment diagnostics';

  @override
  String get setupDebugEnvironmentDiagnostics => 'Environment diagnostics';

  @override
  String get setupDebugFocusedOpenCodeSetup => 'Focused on OpenCode setup';

  @override
  String get setupDebugInstallDir => 'Install directory';

  @override
  String get setupDebugInstallDirectory => 'Install directory';

  @override
  String get setupDebugLatestLocalServer => 'Latest local server output';

  @override
  String get setupDebugLogs => 'Captured setup logs';

  @override
  String get setupDebugManual => 'Manual troubleshooting';

  @override
  String get setupDebugManualTroubleshooting => 'Manual troubleshooting';

  @override
  String get setupDebugNetwork => 'Network';

  @override
  String get setupDebugNetwork2 => 'Network';

  @override
  String get setupDebugNoDetails => 'No captured setup details yet';

  @override
  String get setupDebugNode => 'Node.js';

  @override
  String get setupDebugNodeJs => 'Node.js';

  @override
  String get setupDebugNpm => 'npm';

  @override
  String get setupDebugNpm2 => 'npm';

  @override
  String get setupDebugOpenCode => 'OpenCode';

  @override
  String get setupDebugOpenCode2 => 'OpenCode';

  @override
  String get setupDebugOpenCodeSetupDebug => 'OpenCode Setup Debug';

  @override
  String get setupDebugPlatform => 'Platform';

  @override
  String get setupDebugPlatform2 => 'Platform';

  @override
  String get setupDebugRunDiagnosticsTry =>
      'Run diagnostics, try an installation method, or attempt a setup flow to capture OpenCode-specific troubleshooting details here.';

  @override
  String get setupDebugScreenCoversOpenCode =>
      'This screen only covers OpenCode installation, diagnostics, and local setup troubleshooting. Use App Logs for general CodeWalk runtime issues.';

  @override
  String get setupDebugServerOutput => 'Latest local server output';

  @override
  String get setupDebugStatus => 'Current status';

  @override
  String setupDebugTimeEntrySource(String source, String time) {
    return '$time - $source';
  }

  @override
  String get setupDebugTimeline => 'Timeline';

  @override
  String get setupDebugTimeline2 => 'Timeline';

  @override
  String get setupDebugTitle => 'Focused on OpenCode setup';

  @override
  String get setupDebugWSL => 'WSL';

  @override
  String get setupDebugWsl => 'WSL';

  @override
  String get shortcutCloseApp => '关闭应用';

  @override
  String get shortcutCloseAppDesc => '使用平台关闭行为关闭应用';

  @override
  String get shortcutFocusCloseDrawer => '聚焦/关闭侧边栏';

  @override
  String get shortcutFocusCloseDrawerDesc => '默认聚焦输入框，或在打开时关闭侧边栏';

  @override
  String get shortcutFocusInput => '聚焦输入框';

  @override
  String get shortcutFocusInputDesc => '将焦点移动到文本输入框';

  @override
  String get shortcutGroupApplication => '应用';

  @override
  String get shortcutGroupGeneral => '通用';

  @override
  String get shortcutGroupModelAndAgent => '模型与代理';

  @override
  String get shortcutGroupNavigation => '导航';

  @override
  String get shortcutGroupPrompt => '提示词';

  @override
  String get shortcutGroupSession => '会话';

  @override
  String get shortcutNewConversation => '新会话';

  @override
  String get shortcutNewConversationDesc => '创建一个新的聊天会话';

  @override
  String get shortcutNextAgent => '下一个代理';

  @override
  String get shortcutNextAgentDesc => '切换到下一个可用代理';

  @override
  String get shortcutNextRecentModel => '下一个近期模型';

  @override
  String get shortcutNextRecentModelDesc => '在最近使用的模型之间切换';

  @override
  String get shortcutNextVariant => '下一个变体';

  @override
  String get shortcutNextVariantDesc => '在可用的模型变体之间切换';

  @override
  String get shortcutOpenSettings => '打开设置';

  @override
  String get shortcutOpenSettingsDesc => '打开设置页面';

  @override
  String get shortcutPreviousAgent => '上一个代理';

  @override
  String get shortcutPreviousAgentDesc => '切换到上一个可用代理';

  @override
  String get shortcutQuickOpenFiles => '快速打开文件';

  @override
  String get shortcutQuickOpenFilesDesc => '打开文件快速搜索';

  @override
  String get shortcutQuitApp => '退出应用';

  @override
  String get shortcutQuitAppDesc => '强制退出应用';

  @override
  String get shortcutRefreshData => '刷新数据';

  @override
  String get shortcutRefreshDataDesc => '刷新当前聊天数据';

  @override
  String get shortcutStopResponse => '停止响应';

  @override
  String get shortcutStopResponseDesc => '停止当前响应（响应时）';

  @override
  String get shortcutToggleVoiceInput => '切换语音输入';

  @override
  String get shortcutToggleVoiceInputDesc => '在编辑器中开始或停止语音听写';

  @override
  String get shortcutsApply => 'Apply';

  @override
  String shortcutsConflictConflict(String conflict) {
    return '与$conflict冲突';
  }

  @override
  String get shortcutsKeyboardShortcuts => 'Keyboard shortcuts';

  @override
  String get shortcutsReset => 'Reset all';

  @override
  String get shortcutsSearchEditBindings =>
      'Search, edit bindings, and resolve conflicts before saving.';

  @override
  String shortcutsSetShortcutWidget(String label) {
    return '设置快捷键: $label';
  }

  @override
  String get shortcutsTheseBindingsStored =>
      'These bindings are stored in CodeWalk for the current app runtime and do not edit OpenCode `tui.json` keybinds.';

  @override
  String get speechAutoStopSilence => 'Auto-stop silence timeout';

  @override
  String get speechChooseRecognitionEngine =>
      'Choose the recognition engine, silence timeout, and model options.';

  @override
  String speechDesktopOnly(String service) {
    return '$service 仅在桌面端可用。';
  }

  @override
  String get speechDownload => 'Download';

  @override
  String get speechEngine => 'Engine';

  @override
  String get speechInstalledLanguages => 'Installed languages';

  @override
  String get speechListeningStopsAutomatically =>
      'Listening stops automatically after this many seconds of silence.';

  @override
  String get speechMicPermissionDisabled => '麦克风权限已禁用。';

  @override
  String speechModelFilesIncomplete(String service) {
    return '$service 模型文件不完整。';
  }

  @override
  String get speechMoonshine => 'Moonshine';

  @override
  String get speechMoonshineModelsDesktop => 'Moonshine models (desktop)';

  @override
  String get speechMoonshineStaysDownloadable =>
      'Moonshine stays downloadable and out of the app bundle. Pick one model for this desktop device and remove it later if you want the space back.';

  @override
  String get speechNative => 'Native';

  @override
  String get speechNativeSTTDisabled =>
      'Native STT is disabled on Linux in this app. Parakeet is the default engine for new installs.';

  @override
  String get speechNativeSTTWorks =>
      'Native STT works on Windows when OS speech services are enabled. If native initialization fails, CodeWalk automatically falls back to Sherpa. Check Windows microphone privacy, Online speech recognition, and installed speech language packs.';

  @override
  String get speechNativeStartsFaster =>
      'Native starts faster. Sherpa runs fully on-device with heavier setup and deeper model control.';

  @override
  String get speechParakeet => 'Parakeet';

  @override
  String get speechParakeetModelsDesktop => 'Parakeet models (desktop)';

  @override
  String get speechParakeetStaysDownloadable =>
      'Parakeet stays downloadable and out of the app bundle. It currently exposes one multilingual model optimized for 25 European languages.';

  @override
  String get speechPickLanguagePacks =>
      'Pick language packs and download/remove models for on-device recognition.';

  @override
  String get speechRemove => 'Remove';

  @override
  String speechRuntimeFailed(String service) {
    return '$service 运行时初始化失败。';
  }

  @override
  String get speechSelectSherpaAbove =>
      'Select Sherpa above to manage language packs and download models.';

  @override
  String get speechSenseVoice => 'SenseVoice';

  @override
  String get speechSenseVoiceModelsDesktop => 'SenseVoice models (desktop)';

  @override
  String get speechSenseVoiceStaysDownloadable =>
      'SenseVoice stays downloadable and out of the app bundle. It is the strongest desktop option here for Chinese, Cantonese, Japanese, Korean, and English.';

  @override
  String get speechSherpa => 'Sherpa';

  @override
  String get speechSherpaExperimentalFail =>
      'Sherpa is experimental and can fail on some devices. Prefer Native if you want the most stable behavior.';

  @override
  String get speechSherpaModelsLinux => 'Sherpa models (Linux)';

  @override
  String get speechSpeechText => 'Speech to text';

  @override
  String speechUnavailableOnPlatform(String service) {
    return '$service 语音在此平台上不可用。';
  }

  @override
  String get statusConnected => '已连接';

  @override
  String get statusDelayed => '延迟';

  @override
  String get statusFailed => '失败';

  @override
  String get statusOffline => '离线';

  @override
  String get statusOnline => '在线';

  @override
  String get statusReconnecting => '重新连接';

  @override
  String get statusStarting => '正在启动';

  @override
  String get statusStopped => '已停止';

  @override
  String get statusStopping => '正在停止';

  @override
  String get statusSyncDelayed => '同步延迟';

  @override
  String get tailscaleNoPeers => 'No peers found';

  @override
  String get tailscaleNotSupportedOnPlatform => '此平台不支持 Tailscale。';

  @override
  String get tailscaleNotSupportedOnWindows => 'Windows 不支持 Tailscale。';

  @override
  String get tailscalePeerOffline => 'offline';

  @override
  String get tailscaleSelectPeer => 'Select a Tailscale peer';

  @override
  String get tailscaleWaitingAdminApproval => '此 Tailscale 节点正在等待管理员批准。';

  @override
  String get terminalClose => 'Close terminal';

  @override
  String terminalConnectingTo(String serverName) {
    return '正在连接到 $serverName 终端...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return '终端连接失败：$error';
  }

  @override
  String get terminalDisconnected => '终端已断开连接。';

  @override
  String terminalEmbeddedUnavailable(String serverName) {
    return '此运行时尚不支持嵌入式终端。请继续使用撰写器的 shell 模式执行一次性命令，或从支持的 CodeWalk 应用运行时打开 $serverName 的终端。';
  }

  @override
  String get terminalHide => '隐藏终端';

  @override
  String get terminalMaximize => 'Maximize';

  @override
  String get terminalMinimize => 'Minimize terminal';

  @override
  String get terminalNotAvailableYet => '嵌入式终端在此运行时中尚不可用。';

  @override
  String get terminalOpen => '打开终端';

  @override
  String get terminalOpenInfo => '打开终端信息';

  @override
  String get terminalOpenProjectFirst => '在启动服务器终端之前，请先打开项目文件夹。';

  @override
  String get terminalOpenToConnect => '打开终端以连接到服务器项目终端。';

  @override
  String get terminalReconnect => 'Reconnect terminal';

  @override
  String get terminalRestoreSize => 'Restore size';

  @override
  String get terminalSelectServer => '在打开终端之前，请选择一个活动服务器。';

  @override
  String get terminalSessionClosed => '终端会话已关闭。';

  @override
  String get terminalTerminal => 'Terminal';

  @override
  String get terminalTitle => '终端';

  @override
  String get terminalTryAgain => 'Try again';

  @override
  String get toolAwaitingInput => 'Awaiting input';

  @override
  String get toolEditing => 'Editing';

  @override
  String get toolEditingFiles => 'Editing files';

  @override
  String get toolFinding => 'Finding';

  @override
  String get toolFindingFiles => 'Finding files';

  @override
  String get toolPresentationAwaitingInput => 'Awaiting input';

  @override
  String get toolPresentationEditing => 'Editing';

  @override
  String get toolPresentationEditingFiles => 'Editing files';

  @override
  String get toolPresentationFinding => 'Finding';

  @override
  String get toolPresentationFindingFiles => 'Finding files';

  @override
  String get toolPresentationReading => 'Reading';

  @override
  String get toolPresentationReadingFile => 'Reading file';

  @override
  String get toolPresentationRunning => 'Running';

  @override
  String get toolPresentationRunningCommand => 'Running command';

  @override
  String toolPresentationRunningTool(String toolName) {
    return '正在运行 $toolName';
  }

  @override
  String get toolPresentationSearching => 'Searching';

  @override
  String get toolPresentationSearchingCode => 'Searching code';

  @override
  String get toolPresentationSearchingWeb => 'Searching the web';

  @override
  String get toolPresentationTool => '工具';

  @override
  String get toolPresentationUpdatingTaskList => 'Updating task list';

  @override
  String get toolPresentationUpdatingTasks => 'Updating tasks';

  @override
  String get toolPresentationWaitingInput => 'Waiting for your input';

  @override
  String get toolPresentationWriting => 'Writing';

  @override
  String get toolPresentationWritingFile => 'Writing file';

  @override
  String get toolReading => 'Reading';

  @override
  String get toolReadingFile => 'Reading file';

  @override
  String get toolRunning => 'Running';

  @override
  String get toolRunningCommand => 'Running command';

  @override
  String get toolRunningTask => 'Running task';

  @override
  String get toolSearching => 'Searching';

  @override
  String get toolSearchingCode => 'Searching code';

  @override
  String get toolSearchingWeb => 'Searching the web';

  @override
  String get toolUpdatingTaskList => 'Updating task list';

  @override
  String get toolUpdatingTasks => 'Updating tasks';

  @override
  String get toolWaitingForInput => 'Waiting for your input';

  @override
  String get toolWriting => 'Writing';

  @override
  String get toolWritingFile => 'Writing file';

  @override
  String get tourBack => 'Back';

  @override
  String get tourSkip => 'Skip';

  @override
  String get trayQuit => 'Quit';

  @override
  String get trayShow => 'Show';

  @override
  String get useOAuthCloudflareAccess => 'Use OAuth (Cloudflare Access)';

  @override
  String get useOAuthCloudflareAccessSubtitle =>
      'Opens a browser for Cloudflare Access Managed OAuth.';

  @override
  String get useOAuthCloudflareAccessUnsupported =>
      'Cloudflare Access OAuth is not available on this platform. Use Basic Auth instead.';

  @override
  String get useTailscale => 'Use Tailscale';

  @override
  String get useTailscaleSubtitle =>
      'Routes traffic through the Tailscale network without a system VPN.';

  @override
  String get useTailscaleUnsupported =>
      'Tailscale is not supported on this platform.';

  @override
  String get utilityTitle => '实用工具';

  @override
  String get workspaceBrowseDirs => 'Browse directories';

  @override
  String get workspaceChooseFolderOpen =>
      'Choose any folder to open as project context.';

  @override
  String workspaceCloseProject(String project) {
    return 'Close $project';
  }

  @override
  String get workspaceFilterDirs => 'Filter directories';

  @override
  String get workspaceOpenFolder => 'Open folder';

  @override
  String get workspaceOpenProjectFolder => 'Open project folder';

  @override
  String get workspaceProjectDirectory => 'Project directory';

  @override
  String get workspaceProjectHint => '/repo/my-project';

  @override
  String workspaceRemoveFromHistory(String name) {
    return 'Remove $name from history';
  }

  @override
  String get workspaceSuggestions => 'Suggestions';
}
