import 'package:codewalk/presentation/utils/shortcut_binding_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShortcutBindingCodec.formatForDisplay', () {
    test('shows Option on macOS for alt bindings', () {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = previousPlatform;
      });

      expect(ShortcutBindingCodec.formatForDisplay('alt+s'), 'Option+S');
    });

    test('shows Alt on non-mac platforms for alt bindings', () {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = previousPlatform;
      });

      expect(ShortcutBindingCodec.formatForDisplay('alt+s'), 'Alt+S');
    });
  });
}
