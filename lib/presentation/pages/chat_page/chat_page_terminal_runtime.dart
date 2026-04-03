part of '../chat_page.dart';

extension _ChatPageTerminalRuntime on _ChatPageState {
  Future<void> _toggleTerminalPanel() async {
    final settingsProvider = _settingsProvider;
    if (settingsProvider == null) {
      return;
    }
    if (!_terminalController.supportsDesktopAttach) {
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
    if (projectProvider == null) {
      return;
    }
    final signature = _terminalSignatureFor(
      serverId: _appProvider?.activeServerId,
      directory: projectProvider.currentDirectory,
    );
    if (!force && signature == _terminalSessionSignature) {
      return;
    }
    _terminalSessionSignature = signature;
    await _terminalController.startShell(
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
                Text('Terminal', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(
                  'Embedded terminal is not available on this platform yet. Keep using composer shell mode for one-shot commands or open a supported native terminal for ${activeServer?.displayName ?? 'the active server'}.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTerminalPanel(SettingsProvider settingsProvider) {
    final mediaHeight = MediaQuery.sizeOf(context).height;
    final isCompact = context.windowSizeClass.isCompact;
    final normalMaxPanelHeight = isCompact
        ? max(320.0, mediaHeight * 0.72)
        : min(480.0, mediaHeight * 0.55);
    final maximizedHeight = mediaHeight * (isCompact ? 0.88 : 0.8);
    final panelHeight = settingsProvider.terminalPanelMaximized
        ? maximizedHeight
        : settingsProvider.terminalPanelHeight.clamp(
            180.0,
            normalMaxPanelHeight,
          );
    return SizedBox(
      height: panelHeight,
      child: CodewalkTerminalPanel(
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
          settingsProvider.updateTerminalPanelHeightInMemory(
            (panelHeight + delta).clamp(180.0, normalMaxPanelHeight),
          );
          unawaited(settingsProvider.persistTerminalPanelHeight());
        },
      ),
    );
  }
}
