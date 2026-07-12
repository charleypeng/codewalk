import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const sessionAttentionDesktopChildRole = 'session_attention_child_v1';

bool get _isDesktopRuntime =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows);

Future<bool> runSessionAttentionDesktopChildIfNeeded() async {
  if (!_isDesktopRuntime) {
    return false;
  }
  final controller = await WindowController.fromCurrentEngine();
  if (controller.arguments != sessionAttentionDesktopChildRole) {
    return false;
  }
  await windowManager.ensureInitialized();
  await windowManager.setAlwaysOnTop(true);
  runApp(const SessionAttentionHostPrototypeApp());
  return true;
}

@pragma('vm:entry-point')
void sessionOverlayAndroidMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SessionAttentionHostPrototypeApp());
}

class SessionAttentionHostPrototypeApp extends StatelessWidget {
  const SessionAttentionHostPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Semantics(
            label: 'CodeWalk session attention host prototype',
            child: const CircleAvatar(
              radius: 32,
              child: Icon(Icons.hourglass_top_rounded),
            ),
          ),
        ),
      ),
    );
  }
}
