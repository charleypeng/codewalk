part of '../chat_page.dart';

extension _ChatPageTerminalRuntime on _ChatPageState {
  Future<void> _toggleTerminalPanel({required bool isMobile}) async {
    final settingsProvider = _settingsProvider;
    if (settingsProvider == null) {
      return;
    }
    if (isMobile) {
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
                  'The embedded project terminal is desktop-first for now. On mobile, keep using composer shell mode for one-shot commands or open a desktop shell for ${activeServer?.displayName ?? 'the active server'}.',
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
    final maxPanelHeight = min(480.0, mediaHeight * 0.55);
    final panelHeight = settingsProvider.terminalPanelHeight.clamp(
      180.0,
      maxPanelHeight,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SizedBox(
        height: panelHeight,
        child: CodewalkTerminalPanel(
          controller: _terminalController,
          onHide: () {
            unawaited(settingsProvider.setTerminalPanelVisible(false));
          },
          onReconnect: () {
            unawaited(_startTerminalForCurrentProject(force: true));
          },
          onStop: () {
            _terminalSessionSignature = null;
            unawaited(_terminalController.stop());
          },
          onHeightDelta: (delta) {
            settingsProvider.updateTerminalPanelHeightInMemory(
              (panelHeight + delta).clamp(180.0, maxPanelHeight),
            );
            unawaited(settingsProvider.persistTerminalPanelHeight());
          },
        ),
      ),
    );
  }
}
