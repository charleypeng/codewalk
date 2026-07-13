import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../../domain/entities/session_attention_overlay/session_attention_models.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/session_attention/session_attention_snapshot_store.dart';
import '../../../domain/entities/experience_settings.dart';
import '../../widgets/session_attention_overlay/session_attention_overlay.dart';
import 'session_attention_host_protocol.dart';

const sessionAttentionDesktopChildRole = 'session_attention_child_v1';
const sessionAttentionDesktopChannelName =
    'codewalk/session_attention_desktop_v1';
const _androidServiceChannel = MethodChannel(
  'codewalk/session_overlay_service',
);

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
  runApp(SessionAttentionHostApp.desktop(controller: controller));
  return true;
}

@pragma('vm:entry-point')
void sessionOverlayAndroidMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SessionAttentionHostApp.android());
}

class SessionAttentionHostApp extends StatefulWidget {
  const SessionAttentionHostApp.android({super.key}) : desktopController = null;

  const SessionAttentionHostApp.desktop({
    super.key,
    required WindowController controller,
  }) : desktopController = controller;

  final WindowController? desktopController;

  @override
  State<SessionAttentionHostApp> createState() =>
      _SessionAttentionHostAppState();
}

class _SessionAttentionHostAppState extends State<SessionAttentionHostApp>
    with WindowListener {
  SessionAttentionHostSnapshot? _snapshot;
  SessionAttentionPresentation? _desktopPresentation;
  final WindowMethodChannel _desktopChannel = const WindowMethodChannel(
    sessionAttentionDesktopChannelName,
    mode: ChannelMode.bidirectional,
  );

  @override
  void initState() {
    super.initState();
    if (widget.desktopController == null) {
      _androidServiceChannel.setMethodCallHandler(_handleMethodCall);
      _androidServiceChannel.invokeMethod<void>('requestFullSnapshot');
      unawaited(_restoreAndroidSnapshot());
    } else {
      _desktopChannel.setMethodCallHandler(_handleMethodCall);
      windowManager.addListener(this);
      unawaited(windowManager.setPreventClose(true));
      unawaited(_restoreDesktopSnapshot());
    }
  }

  @override
  void onWindowClose() {
    unawaited(windowManager.hide());
  }

  Future<void> _restoreDesktopSnapshot() async {
    final raw = await _desktopChannel.invokeMethod<Map<dynamic, dynamic>>(
      'requestFullSnapshot',
    );
    if (raw != null) {
      await _handleMethodCall(MethodCall('applySnapshot', raw));
    }
  }

  Future<void> _restoreAndroidSnapshot() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final rawSettings = preferences.getString(
        AppConstants.experienceSettingsKey,
      );
      var settings = ExperienceSettings.defaults();
      if (rawSettings != null && rawSettings.isNotEmpty) {
        final decoded = jsonDecode(rawSettings);
        if (decoded is Map) {
          settings = ExperienceSettings.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }
      final read = await SessionAttentionSnapshotStore().read();
      final activeServerId =
          preferences.getString(AppConstants.activeServerIdKey) ?? '';
      final snapshot = SessionAttentionHostSnapshot(
        generation: 'service-${DateTime.now().microsecondsSinceEpoch}',
        revision: read.payload.revision,
        presentation: settings.sessionAttentionPresentation,
        activeServerId: activeServerId,
        items: read.payload.items
            .where((item) => item.identity.serverId == activeServerId)
            .toList(growable: false),
        fullResynchronization: true,
        producer: 'restore',
      );
      await _androidServiceChannel.invokeMethod<void>(
        'restoreSnapshot',
        snapshot.toJson(),
      );
    } catch (_) {
      // Keep the FGS alive with no sensitive view until the main producer syncs.
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method != 'applySnapshot' &&
        call.method != 'sessionAttention.applySnapshot') {
      return null;
    }
    final raw = call.arguments;
    if (raw is! Map) return false;
    late final SessionAttentionHostSnapshot next;
    try {
      next = SessionAttentionHostSnapshot.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on FormatException {
      return false;
    }
    if (!next.supersedes(_snapshot)) return false;
    if (mounted) {
      setState(() => _snapshot = next);
    }
    if (widget.desktopController != null) {
      if (_desktopPresentation != next.presentation) {
        _desktopPresentation = next.presentation;
        await windowManager.setSize(
          next.presentation == SessionAttentionPresentation.panel
              ? const Size(420, 560)
              : const Size(112, 112),
        );
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setSkipTaskbar(true);
      }
    }
    return true;
  }

  Future<void> _command(String action, [SessionAttentionItem? item]) async {
    final payload = <String, dynamic>{
      'action': action,
      if (item != null) ...<String, dynamic>{
        ...item.identity.toJson(),
        'snapshotId': item.snapshotId,
      },
    };
    if (widget.desktopController == null) {
      await _androidServiceChannel.invokeMethod<void>('command', payload);
    } else {
      await _desktopChannel.invokeMethod<void>('command', payload);
    }
  }

  @override
  void dispose() {
    if (widget.desktopController == null) {
      _androidServiceChannel.setMethodCallHandler(null);
    } else {
      _desktopChannel.setMethodCallHandler(null);
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final expanded = snapshot?.presentation.name == 'panel';
    final items = snapshot?.items ?? const <SessionAttentionItem>[];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xff6750a4)),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SessionAttentionOverlay(
            items: items,
            expanded: expanded,
            semanticLabel: '${items.length} sessions need attention',
            stateLabelBuilder: (kind) => kind.name,
            openLabel: 'Open',
            expandLabel: 'Expand',
            collapseLabel: 'Collapse',
            readLabel: 'Read',
            stopReadingLabel: 'Stop reading',
            dismissLabel: 'Dismiss',
            stopOverlayLabel: 'Stop overlay',
            activeSpeechSnapshotId: snapshot?.activeSpeechSnapshotId,
            onOpen: (item) => _command('open', item),
            onRead: (item) => _command('read', item),
            onDismiss: (item) => _command('dismiss', item),
            onToggleExpanded: () => _command(expanded ? 'collapse' : 'expand'),
            onStopOverlay: () => _command('stop'),
          ),
        ),
      ),
    );
  }
}
