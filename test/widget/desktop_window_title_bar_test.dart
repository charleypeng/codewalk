import 'dart:convert';

import 'package:codewalk/core/network/dio_client.dart';
import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:codewalk/presentation/services/sound_service.dart';
import 'package:codewalk/presentation/widgets/desktop_window_title_bar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';
import '../support/pump_localized_app.dart';

void main() {
  const barHeight = 54.0;
  const barWidth = 700.0;

  Widget app({double childWidth = 200}) {
    return localizedMaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: barWidth,
            child: DesktopWindowTitleBar(
              height: barHeight,
              child: SizedBox(
                width: childWidth,
                height: barHeight,
                child: const ColoredBox(color: Color(0xFF00FF00)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('window buttons stay flush against the trailing edge', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();

    final barRight = tester.getRect(find.byType(DesktopWindowTitleBar)).right;
    final closeRect = tester.getRect(
      find.byKey(const ValueKey<String>('desktop_window_close')),
    );

    // Regression: the buttons used to float in the middle of the space the
    // tab strip did not consume, because the strip and the drag region each
    // took half of the free width.
    expect(closeRect.right, moreOrLessEquals(barRight, epsilon: 0.5));
  });

  testWidgets('buttons stay flush regardless of how wide the strip is', (
    tester,
  ) async {
    for (final childWidth in <double>[0, 120, 600]) {
      await tester.pumpWidget(app(childWidth: childWidth));
      await tester.pump();

      final barRight = tester.getRect(find.byType(DesktopWindowTitleBar)).right;
      final closeRect = tester.getRect(
        find.byKey(const ValueKey<String>('desktop_window_close')),
      );

      expect(
        closeRect.right,
        moreOrLessEquals(barRight, epsilon: 0.5),
        reason: 'strip width $childWidth should not move the window buttons',
      );
    }
  });

  testWidgets('drag region fills the space left by the strip', (tester) async {
    await tester.pumpWidget(app(childWidth: 200));
    await tester.pump();

    final dragRect = tester.getRect(
      find.byKey(const ValueKey<String>('desktop_window_drag_region')),
    );
    final minimizeRect = tester.getRect(
      find.byKey(const ValueKey<String>('desktop_window_minimize')),
    );

    // The drag region spans from the leading edge to the window buttons, so
    // every empty pixel of the bar can move the window.
    final barLeft = tester.getRect(find.byType(DesktopWindowTitleBar)).left;
    expect(dragRect.left, moreOrLessEquals(barLeft, epsilon: 0.5));
    expect(dragRect.right, moreOrLessEquals(minimizeRect.left, epsilon: 0.5));
  });

  testWidgets('frame keeps chrome around route content in integrated mode', (
    tester,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    final localDataSource = InMemoryAppLocalDataSource()
      ..experienceSettingsJson = jsonEncode(<String, dynamic>{
        'checkUpdatesOnOpen': false,
      });
    final settingsProvider = SettingsProvider(
      localDataSource: localDataSource,
      dioClient: _NoopDioClient(),
      soundService: SoundService(),
    );

    try {
      await tester.pumpWidget(
        localizedMaterialApp(
          home: ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
            child: const DesktopWindowChromeFrame(
              child: ColoredBox(color: Colors.green),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DesktopWindowTitleBar), findsNothing);

      await settingsProvider.initialize();
      await tester.pump();

      expect(find.byType(DesktopWindowTitleBar), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('desktop_window_close')),
        findsOneWidget,
      );

      await settingsProvider.setDesktopWindowChrome(
        DesktopWindowChrome.systemDecoration,
      );
      await tester.pump();

      expect(find.byType(DesktopWindowTitleBar), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      settingsProvider.dispose();
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });

  testWidgets('frame above the navigator provides an overlay for controls', (
    tester,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    final settingsProvider = SettingsProvider(
      localDataSource: InMemoryAppLocalDataSource(),
      dioClient: _NoopDioClient(),
      soundService: SoundService(),
    );

    try {
      await settingsProvider.initialize();
      await tester.pumpWidget(
        localizedMaterialApp(
          home: const Scaffold(body: ColoredBox(color: Colors.green)),
          builder: (context, child) {
            return ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
              child: DesktopWindowChromeFrame(child: child!),
            );
          },
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final closeButton = find.byKey(
        const ValueKey<String>('desktop_window_close'),
      );
      final closeContext = tester.element(closeButton);
      expect(Overlay.maybeOf(closeContext), isNotNull);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(closeButton));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Close'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      settingsProvider.dispose();
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
}

class _NoopDioClient extends DioClient {
  _NoopDioClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: <String, dynamic>{} as T,
    );
  }
}
