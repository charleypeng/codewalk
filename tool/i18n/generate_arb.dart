import 'dart:convert';
import 'dart:io';

import 'arb_strings.dart' as defs;

const _arbDir = 'lib/l10n';
const _template = 'app_en.arb';

final _locales = const {
  'ar', 'bn', 'de', 'en',
  'es', 'fr', 'hi', 'it',
  'ja', 'ko', 'pt', 'ru',
  'zh', 'ur',
};

String _escapeArb(String value) {
  // Normalize existing doubled quotes back to single ones first to prevent compounding
  final normalized = value.replaceAll("''", "'");
  return normalized
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll("'", "''")
      .replaceAll('\n', r'\n')
      .replaceAll('\t', r'\t');
}

List<String> _sortedKeys(Map<String, String> map) =>
    map.keys.toList(growable: false)..sort();

List<String> _sortedPlaceholders(Set<String> s) =>
    s.toList(growable: false)..sort();

String _buildEnArb() {
  final buf = StringBuffer();
  buf.writeln('{');
  buf.writeln('  "@@locale": "en",');

  final keys = _sortedKeys(defs.englishTemplate);
  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    final value = defs.englishTemplate[key]!;
    final isLast = i == keys.length - 1;

    buf.writeln('  "$key": "${_escapeArb(value)}",');
    buf.writeln('  "@$key": {');
    buf.writeln('    "description": "CodeWalk UI string — $key"');

    final placeholders = _sortedPlaceholders(_extractPlaceholders(value));
    if (placeholders.isNotEmpty) {
      buf.writeln(',');
      buf.writeln('    "placeholders": {');
      for (var p = 0; p < placeholders.length; p++) {
        final ph = placeholders[p];
        var type = 'String';
        if (RegExp(r'^(count|total|length|length2|inSeconds|usagePercent|added|removed|index|current|limit|code)$', caseSensitive: false).hasMatch(ph) ||
            value.contains('{${ph}, plural,')) {
          type = 'int';
        } else if (ph.toLowerCase() == 'cost') {
          type = 'double';
        }
        buf.write('      "$ph": { "type": "$type" }');
        if (p < placeholders.length - 1) buf.write(',');
        buf.writeln();
      }
      buf.write('    }');
    }

    if (!isLast) {
      buf.write('  },');
    } else {
      buf.write('  }');
    }
    buf.writeln();
  }
  buf.writeln('}');
  return buf.toString();
}

Set<String> _extractPlaceholders(String value) {
  final regex = RegExp(r'\{(\w+)\}');
  final matches = regex.allMatches(value);
  return matches.map((m) => m.group(1)!).toSet();
}

String _buildTranslatedArb(String locale, Map<String, String> translations) {
  final buf = StringBuffer();
  buf.writeln('{');
  buf.writeln('  "@@locale": "$locale",');

  final keys = _sortedKeys(defs.englishTemplate);
  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    final value = translations[key] ?? defs.englishTemplate[key]!;
    final isLast = i == keys.length - 1;

    buf.writeln('  "$key": "${_escapeArb(value)}"${isLast ? '' : ','}');
  }
  buf.writeln('}');
  return buf.toString();
}

void main() {
  final enArb = _buildEnArb();
  File('$_arbDir/$_template').writeAsStringSync(enArb);

  for (final locale in _locales) {
    if (locale == 'en') continue;

    final fileName = '$_arbDir/app_$locale.arb';
    final translations =
        defs.translations[locale] ?? <String, String>{};
    final arbContent = _buildTranslatedArb(locale, translations);
    File(fileName).writeAsStringSync(arbContent);
  }
}
