part of '../chat_page.dart';

extension _ChatPageTerminalRuntime on _ChatPageState {
  Future<void> _toggleTerminalPanel() async {
    final settingsProvider = _settingsProvider;
    if (settingsProvider == null) {
      return;
    }
    if (!_terminalController.supportsRemoteTerminal) {
      await _showMobileTerminalInfoSheet();
      return;
    }
    final nextVisible = !settingsProvider.terminalPanelVisible;
    await settingsProvider.setTerminalPanelVisible(nextVisible);
    if (nextVisible) {
      await _startTerminalForCurrentProject();
    }
  }

  Future<void> _startTerminalForCurrentProject({bool force = false}) async {
    final projectProvider = _projectProvider;
    final activeServer = _appProvider?.activeServer;
    if (projectProvider == null || activeServer == null) {
      return;
    }
    final signature = _terminalSignatureFor(
      serverId: activeServer.id,
      directory: projectProvider.currentDirectory,
    );
    final isDeadState = _terminalController.isDeadState;
    if (!force && signature == _terminalSessionSignature && !isDeadState) {
      return;
    }
    _terminalSessionSignature = signature;
    await _terminalController.startShell(
      serverProfile: activeServer,
      workingDirectory: projectProvider.currentDirectory,
      force: force,
    );
  }

  String _terminalSignatureFor({
    required String? serverId,
    required String? directory,
  }) {
    return '${serverId ?? '-'}|${directory?.trim() ?? '-'}';
  }

  Future<void> _showMobileTerminalInfoSheet() async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final activeServer = _appProvider?.activeServer;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.terminalTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.terminalEmbeddedUnavailable(
                    activeServer?.displayName ??
                        context.l10n.chatPageStatusServer,
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _restoreMaximizedTerminalIfNeeded({SettingsProvider? settingsProvider}) {
    final effectiveSettingsProvider =
        settingsProvider ??
        _settingsProvider ??
        context.read<SettingsProvider>();
    if (!effectiveSettingsProvider.terminalPanelVisible ||
        !effectiveSettingsProvider.terminalPanelMaximized) {
      return false;
    }
    unawaited(effectiveSettingsProvider.setTerminalPanelMaximized(false));
    return true;
  }

  Widget _buildTerminalPanel(SettingsProvider settingsProvider) {
    final mediaHeight = MediaQuery.sizeOf(context).height;
    final isCompact = context.windowSizeClass.isCompact;
    final normalMaxPanelHeight = isCompact
        ? max(320.0, mediaHeight * 0.72)
        : min(480.0, mediaHeight * 0.55);
    final panelHeight = settingsProvider.terminalPanelHeight.clamp(
      180.0,
      normalMaxPanelHeight,
    );
    return SizedBox(
      height: panelHeight,
      child: _buildTerminalPanelSurface(
        settingsProvider: settingsProvider,
        onHeightDelta: (delta) {
          settingsProvider.updateTerminalPanelHeightInMemory(
            (panelHeight + delta).clamp(180.0, normalMaxPanelHeight),
          );
          unawaited(settingsProvider.persistTerminalPanelHeight());
        },
      ),
    );
  }

  Widget _buildFullscreenTerminalOverlay(SettingsProvider settingsProvider) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent ||
                event.logicalKey != LogicalKeyboardKey.escape) {
              return KeyEventResult.ignored;
            }
            return _restoreMaximizedTerminalIfNeeded(
                  settingsProvider: settingsProvider,
                )
                ? KeyEventResult.handled
                : KeyEventResult.ignored;
          },
          child: _buildTerminalPanelSurface(
            settingsProvider: settingsProvider,
            onHeightDelta: (_) {},
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalPanelSurface({
    required SettingsProvider settingsProvider,
    required ValueChanged<double> onHeightDelta,
  }) {
    return CodewalkTerminalPanel(
      controller: _terminalController,
      isMaximized: settingsProvider.terminalPanelMaximized,
      onHide: () {
        unawaited(settingsProvider.setTerminalPanelVisible(false));
      },
      onReconnect: () {
        unawaited(_startTerminalForCurrentProject(force: true));
      },
      onStop: () {
        _terminalSessionSignature = null;
        unawaited(_terminalController.stop());
        unawaited(settingsProvider.setTerminalPanelVisible(false));
      },
      onToggleMaximize: () {
        unawaited(
          settingsProvider.setTerminalPanelMaximized(
            !settingsProvider.terminalPanelMaximized,
          ),
        );
      },
      onHeightDelta: (delta) {
        if (settingsProvider.terminalPanelMaximized) {
          return;
        }
        onHeightDelta(delta);
      },
    );
  }
}
