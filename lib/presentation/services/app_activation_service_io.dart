import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

Future<void> bringCodeWalkToFront() async {
  if (kIsWeb) {
    return;
  }
  final isDesktop = switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    _ => false,
  };
  if (!isDesktop) {
    return;
  }

  if (await windowManager.isMinimized()) {
    await windowManager.restore();
  }
  await windowManager.show();
  await windowManager.focus();
}
