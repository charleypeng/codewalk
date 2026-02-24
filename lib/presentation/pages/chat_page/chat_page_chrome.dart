part of '../chat_page.dart';

extension _ChatPageChrome on _ChatPageState {
  VerticalDivider _buildPaneDivider() {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
    );
  }

  String _desktopPaneLabel(DesktopPane pane) {
    return switch (pane) {
      DesktopPane.conversations => 'Conversations',
      DesktopPane.files => 'Files',
      DesktopPane.utility => 'Utility',
    };
  }

  String _displayToggleLabel(_DisplayToggleAction action) {
    return switch (action) {
      _DisplayToggleAction.thinkingBubbles => 'Thinking bubbles',
      _DisplayToggleAction.toolCallBubbles => 'Tool call bubbles',
      _DisplayToggleAction.taskList => 'Task list',
      _DisplayToggleAction.composerTips => 'Composer tips',
    };
  }

  Widget _buildProjectScopeLoadingOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    return AbsorbPointer(
      key: const ValueKey<String>('project_scope_loading_overlay'),
      child: ColoredBox(
        color: colorScheme.surface.withValues(alpha: 0.74),
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading project context...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _toolbarHeightForDensity({
    required bool isMobile,
    required AppDensity density,
  }) {
    final base = isMobile ? 46.0 : 44.0;
    return switch (density) {
      AppDensity.extraDense => base - 4,
      AppDensity.dense => base - 2,
      AppDensity.normal => base,
      AppDensity.spacious => base + 4,
      AppDensity.extraSpacious => base + 8,
    };
  }

  bool _useDenseListTiles(BuildContext context) {
    return Theme.of(context).visualDensity.vertical < 0;
  }

  AppBar _buildAppBar({
    required bool isMobile,
    required bool isLargeDesktop,
    required SettingsProvider settingsProvider,
  }) {
    const refreshlessEnabled = FeatureFlags.refreshlessRealtime;
    return AppBar(
      toolbarHeight: _toolbarHeightForDensity(
        isMobile: isMobile,
        density: settingsProvider.appDensity,
      ),
      leadingWidth: isMobile ? 42 : null,
      leading: isMobile
          ? Builder(
              builder: (leadingContext) {
                return Consumer2<ChatProvider, AppProvider>(
                  builder: (context, chatProvider, appProvider, _) {
                    final hasAlert = _hasServerStatusAlert(
                      chatProvider: chatProvider,
                      appProvider: appProvider,
                    );
                    final showSyncLoading = _shouldShowMenuSyncLoading(
                      chatProvider: chatProvider,
                    );
                    final alertColor = _serverStatusColor(
                      context: context,
                      chatProvider: chatProvider,
                      appProvider: appProvider,
                    );
                    const menuIcon = Icon(Symbols.menu);
                    final alertIcon = SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(child: Icon(Symbols.menu)),
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              key: const ValueKey<String>(
                                'appbar_drawer_alert_badge',
                              ),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: alertColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    final loadingIcon = SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(child: Icon(Symbols.menu)),
                          Positioned(
                            top: -1,
                            right: -1,
                            child: SizedBox(
                              key: const ValueKey<String>(
                                'appbar_drawer_sync_loading',
                              ),
                              width: 9,
                              height: 9,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    return IconButton(
                      key: const ValueKey<String>('appbar_drawer_button'),
                      tooltip: MaterialLocalizations.of(
                        leadingContext,
                      ).openAppDrawerTooltip,
                      onPressed: () => Scaffold.of(leadingContext).openDrawer(),
                      icon: hasAlert
                          ? alertIcon
                          : (showSyncLoading ? loadingIcon : menuIcon),
                    );
                  },
                );
              },
            )
          : null,
      titleSpacing: isMobile ? 0 : 4,
      title: _buildProjectSelectorTitle(
        isMobile: isMobile,
        isLargeDesktop: isLargeDesktop,
      ),
      actions: [
        if (!isMobile)
          PopupMenuButton<DesktopPane>(
            key: const ValueKey<String>('desktop_sidebars_menu_button'),
            tooltip: 'Toggle sidebars',
            onSelected: (pane) {
              final next = !settingsProvider.isDesktopPaneVisible(pane);
              unawaited(settingsProvider.setDesktopPaneVisible(pane, next));
            },
            itemBuilder: (context) {
              return DesktopPane.values
                  .map(
                    (pane) => PopupMenuItem<DesktopPane>(
                      key: ValueKey<String>(
                        'desktop_sidebar_menu_item_${pane.name}',
                      ),
                      value: pane,
                      child: Row(
                        children: [
                          Icon(
                            settingsProvider.isDesktopPaneVisible(pane)
                                ? Symbols.check_box_rounded
                                : Symbols.check_box_outline_blank_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(_desktopPaneLabel(pane)),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false);
            },
            icon: const Icon(Symbols.view_sidebar),
          ),
        PopupMenuButton<_DisplayToggleAction>(
          key: const ValueKey<String>('appbar_display_toggles_button'),
          tooltip: 'Display toggles',
          onSelected: (action) {
            switch (action) {
              case _DisplayToggleAction.thinkingBubbles:
                unawaited(
                  settingsProvider.setShowThinkingBubbles(
                    !settingsProvider.showThinkingBubbles,
                  ),
                );
                break;
              case _DisplayToggleAction.toolCallBubbles:
                unawaited(
                  settingsProvider.setShowToolCallBubbles(
                    !settingsProvider.showToolCallBubbles,
                  ),
                );
                break;
              case _DisplayToggleAction.taskList:
                unawaited(
                  settingsProvider.setShowTaskList(
                    !settingsProvider.showTaskList,
                  ),
                );
                break;
              case _DisplayToggleAction.composerTips:
                unawaited(
                  settingsProvider.setShowComposerTips(
                    !settingsProvider.showComposerTips,
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) {
            return [
              PopupMenuItem<_DisplayToggleAction>(
                enabled: false,
                child: Text(
                  'Display',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              CheckedPopupMenuItem<_DisplayToggleAction>(
                key: const ValueKey<String>('display_toggle_item_thinking'),
                value: _DisplayToggleAction.thinkingBubbles,
                checked: settingsProvider.showThinkingBubbles,
                child: Text(
                  _displayToggleLabel(_DisplayToggleAction.thinkingBubbles),
                ),
              ),
              CheckedPopupMenuItem<_DisplayToggleAction>(
                key: const ValueKey<String>('display_toggle_item_tool_calls'),
                value: _DisplayToggleAction.toolCallBubbles,
                checked: settingsProvider.showToolCallBubbles,
                child: Text(
                  _displayToggleLabel(_DisplayToggleAction.toolCallBubbles),
                ),
              ),
              CheckedPopupMenuItem<_DisplayToggleAction>(
                key: const ValueKey<String>('display_toggle_item_task_list'),
                value: _DisplayToggleAction.taskList,
                checked: settingsProvider.showTaskList,
                child: Text(_displayToggleLabel(_DisplayToggleAction.taskList)),
              ),
              CheckedPopupMenuItem<_DisplayToggleAction>(
                key: const ValueKey<String>(
                  'display_toggle_item_composer_tips',
                ),
                value: _DisplayToggleAction.composerTips,
                checked: settingsProvider.showComposerTips,
                child: Text(
                  _displayToggleLabel(_DisplayToggleAction.composerTips),
                ),
              ),
            ];
          },
          icon: const Icon(Symbols.bottom_panel_close),
        ),
        if (refreshlessEnabled && !isMobile)
          Consumer2<ChatProvider, AppProvider>(
            builder: (context, chatProvider, appProvider, child) {
              final label = _syncStatusLabel(
                chatProvider: chatProvider,
                appProvider: appProvider,
              );
              final color = _syncStatusColor(
                context: context,
                chatProvider: chatProvider,
                appProvider: appProvider,
              );
              return Tooltip(
                message: 'Sync: $label',
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    key: const ValueKey<String>('chat_sync_status_chip'),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(Symbols.sync_rounded, size: 14, color: color),
                  ),
                ),
              );
            },
          ),
        if (isMobile)
          IconButton(
            key: const ValueKey<String>('appbar_quick_open_button'),
            icon: const Icon(Symbols.account_tree),
            tooltip: 'Open Files',
            onPressed: () => unawaited(_openMobileFilesDialog()),
          ),
        if (!isMobile)
          IconButton(
            icon: const Icon(Symbols.add_comment),
            tooltip: 'New Chat',
            onPressed: _createNewSession,
          ),
        if (!refreshlessEnabled)
          IconButton(
            icon: const Icon(Symbols.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
        if (isMobile)
          IconButton(
            icon: const Icon(Symbols.add_comment),
            tooltip: 'New Chat',
            onPressed: _createNewSession,
          ),
        const SizedBox(width: 2),
      ],
    );
  }

  Future<void> _openMobileFilesDialog() async {
    if (!mounted) {
      return;
    }
    final projectProvider = context.read<ProjectProvider>();
    final appProvider = context.read<AppProvider>();
    final chatProvider = context.read<ChatProvider>();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<ProjectProvider>.value(
              value: projectProvider,
            ),
            ChangeNotifierProvider<AppProvider>.value(value: appProvider),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
          ],
          child: Dialog.fullscreen(
            key: const ValueKey<String>('mobile_files_dialog_fullscreen'),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Files'),
                leading: IconButton(
                  icon: const Icon(Symbols.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              body: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Consumer3<ProjectProvider, AppProvider, ChatProvider>(
                    builder:
                        (
                          context,
                          projectProvider,
                          appProvider,
                          chatProvider,
                          _,
                        ) {
                          final fileState = _resolveFileContextState(
                            projectProvider: projectProvider,
                            appProvider: appProvider,
                          );
                          _reconcileFileContextWithSessionDiff(
                            contextKey: projectProvider.contextKey,
                            fileState: fileState,
                            chatProvider: chatProvider,
                            projectProvider: projectProvider,
                          );
                          return SafeArea(
                            child: _buildFileExplorerPanel(
                              fileState: fileState,
                              projectProvider: projectProvider,
                              isMobileLayout: true,
                              onStateChanged: () => setDialogState(() {}),
                            ),
                          );
                        },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Color _contextUsageColor(
    BuildContext context, {
    required int usagePercent,
    required bool enabled,
  }) {
    if (!enabled) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
    }
    if (usagePercent >= 85) {
      return Theme.of(context).colorScheme.error;
    }
    if (usagePercent >= 65) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.primary;
  }

  Widget _buildContextUsageRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatUsd(double value) {
    if (value.isNaN || value.isInfinite) {
      return r'$0.0000';
    }
    return r'$' + value.toStringAsFixed(4);
  }

  String _formatIntWithGroup(int value) {
    final sign = value < 0 ? '-' : '';
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i += 1) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return '$sign$buffer';
  }

  Color _syncStatusColor({
    required BuildContext context,
    required ChatProvider chatProvider,
    required AppProvider appProvider,
  }) {
    final hasRecoverableSyncState = _isRecoverableSyncState(
      chatProvider: chatProvider,
    );
    if (hasRecoverableSyncState) {
      // Show error color immediately when the device is confirmed offline,
      // regardless of the loading indicator state.
      if (!appProvider.isConnected) {
        return Theme.of(context).colorScheme.error;
      }
      return Theme.of(context).colorScheme.primary;
    }
    if (!appProvider.isConnected) {
      return Theme.of(context).colorScheme.error;
    }
    return Colors.green;
  }

  bool _isRecoverableSyncState({required ChatProvider chatProvider}) {
    return chatProvider.syncState == ChatSyncState.reconnecting ||
        chatProvider.syncState == ChatSyncState.delayed ||
        chatProvider.isInDegradedMode;
  }

  bool _isRecoverableSyncLoading({required ChatProvider chatProvider}) {
    if (AndroidForegroundMonitorService.isRunning) {
      return false;
    }
    if (!chatProvider.isForegroundResumeSyncing) {
      return false;
    }
    return _isRecoverableSyncState(chatProvider: chatProvider);
  }

  bool _shouldShowMenuSyncLoading({required ChatProvider chatProvider}) {
    return _isRecoverableSyncLoading(chatProvider: chatProvider);
  }

  ServerHealthStatus _activeServerHealth(AppProvider appProvider) {
    final active = appProvider.activeServer;
    if (active == null) {
      return ServerHealthStatus.unknown;
    }
    return appProvider.healthFor(active.id);
  }

  Color _serverStatusColor({
    required BuildContext context,
    required ChatProvider chatProvider,
    required AppProvider appProvider,
  }) {
    final health = _activeServerHealth(appProvider);
    if (health == ServerHealthStatus.unhealthy) {
      return Theme.of(context).colorScheme.error;
    }
    if (health == ServerHealthStatus.unknown) {
      return Theme.of(context).colorScheme.outline;
    }
    return _syncStatusColor(
      context: context,
      chatProvider: chatProvider,
      appProvider: appProvider,
    );
  }

  bool _hasImmediateServerStatusAlert({
    required ChatProvider chatProvider,
    required AppProvider appProvider,
  }) {
    final health = _activeServerHealth(appProvider);
    if (health == ServerHealthStatus.unhealthy) {
      return true;
    }
    if (health == ServerHealthStatus.unknown) {
      return false;
    }
    if (!FeatureFlags.refreshlessRealtime) {
      return !appProvider.isConnected;
    }
    if (_isRecoverableSyncState(chatProvider: chatProvider)) {
      return false;
    }
    return !appProvider.isConnected;
  }

  void _resetServerAlertGraceState() {
    _serverAlertIssueStartedAt = null;
    _serverAlertRevealTimer?.cancel();
    _serverAlertRevealTimer = null;
  }

  bool _hasServerStatusAlert({
    required ChatProvider chatProvider,
    required AppProvider appProvider,
  }) {
    final immediateAlert = _hasImmediateServerStatusAlert(
      chatProvider: chatProvider,
      appProvider: appProvider,
    );
    if (!immediateAlert) {
      _resetServerAlertGraceState();
      return false;
    }

    final now = DateTime.now();
    _serverAlertIssueStartedAt ??= now;

    final startedAt = _serverAlertIssueStartedAt ?? now;
    final elapsed = now.difference(startedAt);
    if (elapsed >= _ChatPageState._serverAlertGracePeriod) {
      _serverAlertRevealTimer?.cancel();
      _serverAlertRevealTimer = null;
      return true;
    }

    final remaining = _ChatPageState._serverAlertGracePeriod - elapsed;
    if (!(_serverAlertRevealTimer?.isActive ?? false)) {
      _serverAlertRevealTimer = Timer(remaining, () {
        _serverAlertRevealTimer = null;
        if (!mounted) {
          return;
        }
        _setState(() {});
      });
    }
    return false;
  }

  /// Draggable resize handle that replaces VerticalDivider between panes.
  /// [paneOnLeft] means the pane being resized is to the left of the handle;
  /// when false (utility pane on the right), the drag delta is inverted.
  Widget _buildResizableHandle({
    required DesktopPane pane,
    required SettingsProvider settingsProvider,
    required bool paneOnLeft,
  }) {
    return _PaneResizeHandle(
      pane: pane,
      settingsProvider: settingsProvider,
      paneOnLeft: paneOnLeft,
    );
  }

  Widget _buildSelectorSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildOpenProjectTile({
    required BuildContext dialogContext,
    required Project project,
    required bool selected,
    required VoidCallback onSwitch,
    required VoidCallback onClose,
    required bool closeEnabled,
  }) {
    final path = _directoryLabel(project.path);
    final displayName = _projectDisplayLabel(project);

    return ListTile(
      dense: _useDenseListTiles(dialogContext),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        selected ? Symbols.radio_button_checked : Symbols.folder_open,
        size: 20,
      ),
      title: Text(displayName, overflow: TextOverflow.ellipsis),
      subtitle: path == displayName
          ? null
          : Text(path, overflow: TextOverflow.ellipsis),
      selected: selected,
      onTap: onSwitch,
      trailing: IconButton(
        icon: const Icon(Symbols.close_rounded),
        tooltip: 'Close ${_projectDisplayLabel(project)}',
        onPressed: closeEnabled ? onClose : null,
      ),
    );
  }

  Future<void> _openCreateWorkspaceFromSelector(
    BuildContext dialogContext,
  ) async {
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    await _createWorkspace();
  }

  Future<void> _switchProjectFromSelector(
    BuildContext dialogContext,
    String projectId,
  ) async {
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    await _switchProjectContext(projectId);
  }

  Future<void> _switchWorkspaceFromSelector(
    BuildContext dialogContext,
    String directory,
  ) async {
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    await _switchDirectoryContext(directory);
  }

  String _directoryLabel(String? directory) {
    final trimmed = directory?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        trimmed == '/' ||
        trimmed == '-') {
      return 'Global';
    }
    return trimmed;
  }

  String _directoryBasename(String directoryLabel) {
    if (directoryLabel == 'Global') {
      return directoryLabel;
    }
    final normalized = directoryLabel.replaceAll('\\', '/');
    final parts = normalized
        .split('/')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return directoryLabel;
    }
    return parts.last;
  }

  String _projectDisplayLabel(Project project) {
    final name = project.name.trim();
    final path = _directoryLabel(project.path);
    if (name.isEmpty || name == '/' || name == path) {
      return path;
    }
    return name;
  }

  // Close the drawer without yielding to the microtask queue. A
  // `Future.delayed(Duration.zero)` yield here would allow pending gesture
  // callbacks (e.g. DrawerController._handleDragCancel after a rapid double
  // tap) to re-open the drawer before the close animation settles.
  void _closeDrawerIfNeeded({required bool closeOnSelect}) {
    if (!closeOnSelect) {
      return;
    }
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null || !scaffoldState.isDrawerOpen) {
      return;
    }
    scaffoldState.closeDrawer();
  }

  Future<void> _openSettingsPage({
    required bool closeOnSelect,
    String initialSectionId = '',
  }) async {
    _closeDrawerIfNeeded(closeOnSelect: closeOnSelect);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(initialSectionId: initialSectionId),
      ),
    );
  }

  Widget _headerChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// Interactive resize handle for desktop sidebar panes.
/// Provides an 8px hit area with a thin visual line that thickens on
/// hover/drag. Double-tap resets to the default width.
class _PaneResizeHandle extends StatefulWidget {
  const _PaneResizeHandle({
    required this.pane,
    required this.settingsProvider,
    required this.paneOnLeft,
  });

  final DesktopPane pane;
  final SettingsProvider settingsProvider;
  final bool paneOnLeft;

  @override
  State<_PaneResizeHandle> createState() => _PaneResizeHandleState();
}

class _PaneResizeHandleState extends State<_PaneResizeHandle> {
  bool _hovering = false;
  bool _dragging = false;
  bool _dirty = false;

  void _persistIfDirty() {
    if (!_dirty) {
      return;
    }
    _dirty = false;
    unawaited(widget.settingsProvider.persistDesktopPaneWidths());
  }

  @override
  Widget build(BuildContext context) {
    final active = _hovering || _dragging;
    final lineWidth = active ? 3.0 : 1.0;
    final color = active
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.12);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (details) {
          final delta = widget.paneOnLeft
              ? details.delta.dx
              : -details.delta.dx;
          final current = widget.settingsProvider.desktopPaneWidth(widget.pane);
          final next = (current + delta).clamp(160.0, 500.0);
          // Update in memory only; persist once on drag end/cancel to avoid
          // excessive SharedPreferences writes during continuous drag.
          widget.settingsProvider.updateDesktopPaneWidthInMemory(
            widget.pane,
            next,
          );
          _dirty = true;
        },
        onHorizontalDragEnd: (_) {
          setState(() => _dragging = false);
          _persistIfDirty();
        },
        onHorizontalDragCancel: () {
          setState(() => _dragging = false);
          _persistIfDirty();
        },
        onDoubleTap: () {
          unawaited(widget.settingsProvider.resetDesktopPaneWidth(widget.pane));
        },
        child: SizedBox(
          width: 8,
          child: Center(
            child: Container(width: lineWidth, color: color),
          ),
        ),
      ),
    );
  }
}
