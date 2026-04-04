import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:xterm/xterm.dart';

import '../services/codewalk_terminal_controller.dart';

class CodewalkTerminalPanel extends StatefulWidget {
  const CodewalkTerminalPanel({
    required this.controller,
    required this.isMaximized,
    required this.onHide,
    required this.onReconnect,
    required this.onStop,
    required this.onToggleMaximize,
    required this.onHeightDelta,
    super.key,
  });

  final CodewalkTerminalController controller;
  final bool isMaximized;
  final VoidCallback onHide;
  final VoidCallback onReconnect;
  final VoidCallback onStop;
  final VoidCallback onToggleMaximize;
  final ValueChanged<double> onHeightDelta;

  @override
  State<CodewalkTerminalPanel> createState() => _CodewalkTerminalPanelState();
}

class _CodewalkTerminalPanelState extends State<CodewalkTerminalPanel> {
  TerminalController _viewController = TerminalController();
  int? _terminalGeneration;

  void _syncTerminalController() {
    final generation = widget.controller.terminalGeneration;
    if (_terminalGeneration == generation) {
      return;
    }
    _terminalGeneration = generation;
    _viewController = TerminalController();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        _syncTerminalController();
        return Container(
          key: const ValueKey<String>('terminal_panel'),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              GestureDetector(
                key: const ValueKey<String>('terminal_panel_resize_handle'),
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  widget.onHeightDelta(-details.delta.dy);
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
                child: Row(
                  children: [
                    const Icon(Symbols.terminal_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.controller.statusMessage,
                        key: const ValueKey<String>(
                          'terminal_panel_status_text',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey<String>(
                        'terminal_panel_reconnect_button',
                      ),
                      tooltip: 'Reconnect terminal',
                      onPressed: widget.onReconnect,
                      icon: const Icon(Symbols.refresh_rounded),
                    ),
                    IconButton(
                      key: const ValueKey<String>(
                        'terminal_panel_maximize_button',
                      ),
                      tooltip: widget.isMaximized
                          ? 'Restore terminal size'
                          : 'Maximize terminal',
                      onPressed: widget.onToggleMaximize,
                      icon: Icon(
                        widget.isMaximized
                            ? Symbols.close_fullscreen_rounded
                            : Symbols.open_in_full_rounded,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey<String>('terminal_panel_stop_button'),
                      tooltip: 'Close terminal',
                      onPressed: widget.onStop,
                      icon: const Icon(Symbols.close_rounded),
                    ),
                    IconButton(
                      key: const ValueKey<String>('terminal_panel_hide_button'),
                      tooltip: 'Minimize terminal',
                      onPressed: widget.onHide,
                      icon: const Icon(Symbols.keyboard_arrow_down_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final state = widget.controller.state;
    if (state == CodewalkTerminalState.running ||
        state == CodewalkTerminalState.starting ||
        state == CodewalkTerminalState.exited) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: KeyedSubtree(
          key: ValueKey<int>(widget.controller.terminalGeneration),
          child: TerminalView(
            widget.controller.terminal,
            controller: _viewController,
            autofocus: true,
            // Email keyboard mode breaks Android terminal composition,
            // especially when inserting spaces. Use the plain text IME there.
            keyboardType: defaultTargetPlatform == TargetPlatform.android
                ? TextInputType.text
                : TextInputType.emailAddress,
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.terminal_rounded,
              size: 36,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              widget.controller.statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: widget.onReconnect,
              icon: const Icon(Symbols.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
