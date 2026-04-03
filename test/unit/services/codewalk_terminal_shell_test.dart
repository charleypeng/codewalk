import 'dart:io';

import 'package:codewalk/presentation/services/codewalk_terminal_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveCodewalkTerminalShellTarget', () {
    test('returns unavailable error when working directory is missing', () {
      final target = resolveCodewalkTerminalShellTarget(workingDirectory: null);

      expect(target.isError, isTrue);
      expect(target.errorMessage, isNotNull);
    });

    test('returns shell target for an existing directory', () {
      final directory = Directory.systemTemp.path;

      final target = resolveCodewalkTerminalShellTarget(
        workingDirectory: directory,
      );

      expect(target.isError, isFalse);
      expect(target.executable, isNotEmpty);
      expect(target.workingDirectory, directory);
      expect(target.statusLabel, isNotEmpty);
    });
  });
}
