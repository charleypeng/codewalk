import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/i18n/l10n_context.dart';

/// Width reserved for the macOS traffic lights, which stay native and are drawn
/// by the system over the leading edge of the Flutter view.
const double _macOsTrafficLightsInset = 78;

/// Top band of the window in the integrated chrome mode.
///
/// Hosts [child] (the session tab strip) plus a drag region and, on Linux and
/// Windows, the window control buttons. The strip keeps its own hit targets;
/// only the leftover space drags the window, so clicking a tab never starts an
/// accidental move.
class DesktopWindowTitleBar extends StatefulWidget {
  const DesktopWindowTitleBar({
    super.key,
    required this.child,
    required this.height,
  });

  final Widget child;
  final double height;

  @override
  State<DesktopWindowTitleBar> createState() => _DesktopWindowTitleBarState();
}

class _DesktopWindowTitleBarState extends State<DesktopWindowTitleBar>
    with WindowListener {
  bool _isMaximized = false;

  bool get _usesNativeWindowButtons =>
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_syncMaximizedState());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => _setMaximized(true);

  @override
  void onWindowUnmaximize() => _setMaximized(false);

  Future<void> _syncMaximizedState() async {
    try {
      final maximized = await windowManager.isMaximized();
      _setMaximized(maximized);
    } catch (_) {
      // Compositors may reject the query; the button simply keeps its state.
    }
  }

  void _setMaximized(bool value) {
    if (!mounted || _isMaximized == value) {
      return;
    }
    setState(() => _isMaximized = value);
  }

  Future<void> _toggleMaximize() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {
      // Maximize is unavailable on some compositors; ignore rather than crash.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Material ancestor is required by the ink effects on the window buttons.
    return Material(
      color: colorScheme.surfaceContainerLow,
      child: SizedBox(
        height: widget.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_usesNativeWindowButtons)
              const SizedBox(width: _macOsTrafficLightsInset),
            Flexible(child: widget.child),
            Expanded(child: _buildDragRegion()),
            if (!_usesNativeWindowButtons) _buildWindowButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDragRegion() {
    return GestureDetector(
      key: const ValueKey<String>('desktop_window_drag_region'),
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () => unawaited(_toggleMaximize()),
      onPanStart: (_) => unawaited(windowManager.startDragging()),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildWindowButtons(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      // Non-flex child of the title bar row, so it must size to its buttons
      // instead of trying to fill unbounded width.
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WindowButton(
          semanticKey: 'desktop_window_minimize',
          icon: Symbols.remove,
          tooltip: l10n.desktopWindowMinimize,
          onPressed: () => unawaited(windowManager.minimize()),
        ),
        _WindowButton(
          semanticKey: 'desktop_window_maximize',
          icon: _isMaximized ? Symbols.close_fullscreen : Symbols.crop_square,
          tooltip: _isMaximized
              ? l10n.desktopWindowRestore
              : l10n.desktopWindowMaximize,
          onPressed: () => unawaited(_toggleMaximize()),
        ),
        _WindowButton(
          semanticKey: 'desktop_window_close',
          icon: Symbols.close,
          tooltip: l10n.desktopWindowClose,
          isDestructive: true,
          onPressed: () => unawaited(windowManager.close()),
        ),
      ],
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.semanticKey,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String semanticKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: ValueKey<String>(semanticKey),
        onTap: onPressed,
        hoverColor: isDestructive
            ? colorScheme.error.withValues(alpha: 0.16)
            : colorScheme.primary.withValues(alpha: 0.10),
        child: Semantics(
          button: true,
          label: tooltip,
          child: SizedBox(
            width: 46,
            child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
