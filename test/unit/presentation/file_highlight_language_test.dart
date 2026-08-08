import 'package:codewalk/presentation/utils/file_highlight_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves canonical language names and package aliases', () {
    expect(resolveBuiltinFileHighlightLanguage('lua'), 'lua');
    expect(resolveBuiltinFileHighlightLanguage('cs'), 'csharp');
    expect(resolveBuiltinFileHighlightLanguage('ps1'), 'powershell');
    expect(resolveBuiltinFileHighlightLanguage('tex'), 'latex');
    expect(resolveBuiltinFileHighlightLanguage('exs'), 'elixir');
    expect(resolveBuiltinFileHighlightLanguage('fs'), 'fsharp');
  });

  test('normalizes extension case and rejects unknown languages', () {
    expect(resolveBuiltinFileHighlightLanguage('RS'), 'rust');
    expect(resolveBuiltinFileHighlightLanguage('not-a-language'), isNull);
  });
}
