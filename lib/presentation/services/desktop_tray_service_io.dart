import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/logging/app_logger.dart';
import 'desktop_tray_service_types.dart';

DesktopTrayService createDesktopTrayService() {
  return _DesktopTrayServiceIo();
}

class _DesktopTrayServiceIo
    with TrayListener, WindowListener
    implements DesktopTrayService {
  bool _initialized = false;
  bool _closeToTrayEnabled = true;
  bool _exiting = false;
  bool _trayAvailable = true;

  bool get _isDesktopPlatform {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
  }

  @override
  bool get supported {
    return _isDesktopPlatform && _trayAvailable;
  }

  @override
  Future<void> initialize({required bool closeToTrayEnabled}) async {
    if (!_isDesktopPlatform) {
      return;
    }

    _closeToTrayEnabled = closeToTrayEnabled;

    await windowManager.ensureInitialized();

    if (!_trayAvailable) {
      await windowManager.setPreventClose(false);
      return;
    }

    if (_initialized) {
      await windowManager.setPreventClose(_closeToTrayEnabled);
      return;
    }

    try {
      await trayManager.setIcon(
        'assets/images/icon.png',
        isTemplate: defaultTargetPlatform == TargetPlatform.macOS,
      );
      await trayManager.setToolTip('CodeWalk');
      await trayManager.setContextMenu(
        Menu(
          items: <MenuItem>[
            MenuItem(key: 'open', label: 'Open CodeWalk'),
            MenuItem.separator(),
            MenuItem(key: 'quit', label: 'Quit CodeWalk'),
          ],
        ),
      );
      trayManager.addListener(this);

      await windowManager.setPreventClose(_closeToTrayEnabled);
      windowManager.addListener(this);
    } on MissingPluginException catch (error, stackTrace) {
      await _markTrayUnavailable(error, stackTrace);
      return;
    } catch (error, stackTrace) {
      await _markTrayUnavailable(error, stackTrace);
      return;
    }

    _initialized = true;
    AppLogger.info('Desktop tray initialized');
  }

  @override
  Future<void> setCloseToTrayEnabled(bool enabled) async {
    _closeToTrayEnabled = enabled;
    if (!supported || !_initialized) {
      return;
    }
    await windowManager.setPreventClose(_closeToTrayEnabled);
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _initialized = false;
  }

  @override
  void onTrayIconMouseDown() {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      unawaited(trayManager.popUpContextMenu());
      return;
    }
    unawaited(_showWindow());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'open':
        unawaited(_showWindow());
        break;
      case 'quit':
        unawaited(_quitApplication());
        break;
      default:
        break;
    }
  }

  @override
  Future<void> onWindowClose() async {
    if (!_closeToTrayEnabled || _exiting || !_trayAvailable) {
      await windowManager.setPreventClose(false);
      return;
    }
    await windowManager.hide();
  }

  Future<void> _markTrayUnavailable(Object error, StackTrace stackTrace) async {
    _trayAvailable = false;
    _initialized = false;
    try {
      trayManager.removeListener(this);
    } catch (_) {
      // Ignore best-effort cleanup.
    }
    try {
      windowManager.removeListener(this);
    } catch (_) {
      // Ignore best-effort cleanup.
    }
    try {
      await windowManager.setPreventClose(false);
    } catch (_) {
      // Ignore best-effort cleanup.
    }
    AppLogger.warn(
      'Desktop tray plugin unavailable; close-to-tray was disabled',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quitApplication() async {
    _exiting = true;
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }
}
