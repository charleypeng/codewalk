import 'package:codewalk/presentation/widgets/desktop_window_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
