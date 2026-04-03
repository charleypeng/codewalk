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

    test('returns unavailable error when working directory does not exist', () {
      final target = resolveCodewalkTerminalShellTarget(
        workingDirectory:
            '${Directory.systemTemp.path}/codewalk-terminal-shell-missing',
      );

      expect(target.isError, isTrue);
      expect(target.errorMessage, contains('unavailable'));
    });

    test('returns shell target for an existing directory', () {
      final directory = Directory.systemTemp.createTempSync(
        'codewalk-terminal-shell-',
      );

      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final target = resolveCodewalkTerminalShellTarget(
        workingDirectory: directory.path,
      );

      expect(target.isError, isFalse);
      expect(target.executable, isNotEmpty);
      expect(target.workingDirectory, directory.path);
      expect(target.statusLabel, isNotEmpty);
    });
  });
}
