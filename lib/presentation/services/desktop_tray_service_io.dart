import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/i18n/l10n_bridge.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/experience_settings.dart';
import 'desktop_tray_service_types.dart';

DesktopTrayService createDesktopTrayService() {
  return _DesktopTrayServiceIo();
}

class _DesktopTrayServiceIo
    with TrayListener, WindowListener
    implements DesktopTrayService {
  bool _initialized = false;
  bool _windowListenerAttached = false;
  DesktopCloseBehavior _closeBehavior = DesktopCloseBehavior.tray;
  bool _exiting = false;
  bool _trayAvailable = true;

  String get _trayIconAssetPath {
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS => 'assets/images/tray_icon_macos_template.png',
      TargetPlatform.windows => 'assets/images/tray_icon_windows.ico',
      TargetPlatform.linux => 'assets/images/tray_icon_linux.png',
      _ => 'assets/images/tray_icon_linux.png',
    };
  }

  bool get _interceptsClose {
    return _closeBehavior != DesktopCloseBehavior.close;
  }

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
  Future<void> initialize({required DesktopCloseBehavior closeBehavior}) async {
    if (!_isDesktopPlatform) {
      return;
    }

    _closeBehavior = closeBehavior;

    await windowManager.ensureInitialized();
    if (!_windowListenerAttached) {
      windowManager.addListener(this);
      _windowListenerAttached = true;
    }

    if (!_trayAvailable) {
      await windowManager.setPreventClose(_interceptsClose);
      return;
    }

    if (_initialized) {
      await windowManager.setPreventClose(_interceptsClose);
      return;
    }

    try {
      await trayManager.setIcon(
        _trayIconAssetPath,
        isTemplate: defaultTargetPlatform == TargetPlatform.macOS,
      );
      if (defaultTargetPlatform != TargetPlatform.linux) {
        await trayManager.setToolTip('CodeWalk');
      }
      await trayManager.setContextMenu(
        Menu(
          items: <MenuItem>[
            MenuItem(
              key: 'show',
              label: L10nBridge.current?.trayShow ?? 'Show',
            ),
            MenuItem.separator(),
            MenuItem(
              key: 'quit',
              label: L10nBridge.current?.trayQuit ?? 'Quit',
            ),
          ],
        ),
      );
      trayManager.addListener(this);

      await windowManager.setPreventClose(_interceptsClose);
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
  Future<void> setDesktopCloseBehavior(DesktopCloseBehavior behavior) async {
    _closeBehavior = behavior;
    if (!_isDesktopPlatform) {
      return;
    }
    await windowManager.setPreventClose(_interceptsClose);
  }

  @override
  Future<void> dispose() async {
    if (_initialized) {
      trayManager.removeListener(this);
      _initialized = false;
    }
    if (_windowListenerAttached) {
      windowManager.removeListener(this);
      _windowListenerAttached = false;
    }
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_showWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      // Linux AppIndicator handles right-click context menu natively.
      return;
    }
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
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
    if (_exiting) {
      return;
    }
    switch (_closeBehavior) {
      case DesktopCloseBehavior.close:
        _exiting = true;
        try {
          // Disabling preventClose during onWindowClose lets the native
          // close pipeline proceed — no explicit close()/destroy() needed.
          await windowManager.setPreventClose(false);
        } catch (error, stackTrace) {
          _exiting = false;
          AppLogger.warn(
            'Failed to disable close prevention',
            error: error,
            stackTrace: stackTrace,
          );
        }
        return;
      case DesktopCloseBehavior.minimize:
        await windowManager.minimize();
        return;
      case DesktopCloseBehavior.tray:
        if (!_trayAvailable) {
          await windowManager.minimize();
          return;
        }
        await windowManager.hide();
        return;
    }
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
      await windowManager.setPreventClose(_interceptsClose);
    } catch (_) {
      // Ignore best-effort cleanup.
    }
    AppLogger.warn(
      'Desktop tray plugin unavailable; close falls back to taskbar minimize',
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
    try {
      // Use destroy() to bypass close prevention without toggling
      // setPreventClose, so close-to-tray stays intact until the very end.
      await windowManager.destroy();
    } catch (error, stackTrace) {
      _exiting = false;
      AppLogger.warn(
        'Failed to destroy window during quit',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
