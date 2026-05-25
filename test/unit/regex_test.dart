import 'package:flutter_test/flutter_test.dart';

void main() {
  test('regex test', () {
    final regExp = RegExp(r'(\*\*|__)(.*?)\1|(\*|_)(.*?)\3|`([^`]*)`|!?\[([^\]]*)\]\([^)]*\)|^#{1,6}\s*|^>\s*', multiLine: true);
    final text = "**hello** [link](url) # header";
    final cleaned = text.replaceAll(regExp, r'$2$4$5$6');
    print("Cleaned: " + cleaned);
    expect(cleaned, isNot(contains(r'$2$4$5$6')));
  });
}
