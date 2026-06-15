import 'package:codewalk/data/models/workspace_symbol_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceSymbolModel', () {
    test('keeps POSIX file URIs as POSIX paths on Windows hosts', () {
      final symbol = WorkspaceSymbolModel.fromJson(<String, dynamic>{
        'name': 'CodeWalkController',
        'kind': 'class',
        'location': <String, dynamic>{
          'uri': 'file:///workspace/project/lib/codewalk_controller.dart',
        },
      });

      expect(symbol.name, 'CodeWalkController');
      expect(symbol.path, '/workspace/project/lib/codewalk_controller.dart');
    });

    test('normalizes Windows file URIs to forward-slash paths', () {
      final symbol = WorkspaceSymbolModel.fromJson(<String, dynamic>{
        'name': 'WindowsController',
        'uri': 'file:///C:/workspace/project/lib/windows_controller.dart',
      });

      expect(symbol.path, 'C:/workspace/project/lib/windows_controller.dart');
    });
  });
}
