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
      await _attachTerminalForActiveServer();
    }
  }

  Future<void> _attachTerminalForActiveServer({bool force = false}) async {
    final appProvider = _appProvider;
    if (appProvider == null) {
      return;
    }
    final activeServer = appProvider.activeServer;
    final signature = _terminalSignatureFor(
      server: activeServer,
      commandPath: appProvider.localServerCommandPath,
    );
    if (!force && signature == _terminalAttachSignature) {
      return;
    }
    _terminalAttachSignature = signature;
    await _terminalController.attach(
      serverProfile: activeServer,
      commandPath: appProvider.localServerCommandPath,
      force: force,
    );
  }

  String _terminalSignatureFor({
    required ServerProfile? server,
    required String commandPath,
  }) {
    return '${server?.id ?? '-'}|${server?.url ?? '-'}|${commandPath.trim()}';
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
                  'The embedded OpenCode terminal is desktop-first for now. On mobile, keep using composer shell mode for one-shot commands or attach from a desktop terminal to ${activeServer?.displayName ?? 'the active server'}.',
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
            unawaited(_attachTerminalForActiveServer(force: true));
          },
          onStop: () {
            _terminalAttachSignature = null;
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
