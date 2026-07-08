import 'package:flutter/foundation.dart';

import '../../../domain/entities/experience_settings.dart';

class EdgeTtsLocalePreference {
  const EdgeTtsLocalePreference({required this.locale, required this.voiceId});

  final String locale;
  final String voiceId;
}

class ReadAloudDefaultEnvironment {
  const ReadAloudDefaultEnvironment({
    required this.isWeb,
    required this.targetPlatform,
    required this.nativeTtsAvailable,
    this.appLocaleCode,
    this.systemLocaleName,
  });

  final bool isWeb;
  final TargetPlatform targetPlatform;
  final bool nativeTtsAvailable;
  final String? appLocaleCode;
  final String? systemLocaleName;
}

class ReadAloudDefaultSelection {
  const ReadAloudDefaultSelection({
    required this.provider,
    this.voiceId,
    this.voiceLocale,
  });

  final ReadAloudProvider provider;
  final String? voiceId;
  final String? voiceLocale;
}

class ReadAloudDefaultResolver {
  const ReadAloudDefaultResolver._();

  static ReadAloudDefaultSelection resolve(ReadAloudDefaultEnvironment env) {
    if (!_shouldPreferEdge(env) && env.nativeTtsAvailable) {
      return const ReadAloudDefaultSelection(
        provider: ReadAloudProvider.native,
      );
    }
    final edge = edgePreferenceForLocale(
      appLocaleCode: env.appLocaleCode,
      systemLocaleName: env.systemLocaleName,
    );
    return ReadAloudDefaultSelection(
      provider: ReadAloudProvider.edgeExperimental,
      voiceId: edge.voiceId,
      voiceLocale: edge.locale,
    );
  }

  static EdgeTtsLocalePreference edgePreferenceForLocale({
    String? appLocaleCode,
    String? systemLocaleName,
  }) {
    final preferred =
        _normalizeLocale(appLocaleCode) ??
        _normalizeLocale(systemLocaleName) ??
        'en-US';
    final exact = _edgeVoiceByLocale[preferred.toLowerCase()];
    if (exact != null) {
      return exact;
    }
    final language = preferred.split('-').first.toLowerCase();
    return _defaultEdgeVoiceByLanguage[language] ??
        _edgeVoiceByLocale['en-us']!;
  }

  static bool _shouldPreferEdge(ReadAloudDefaultEnvironment env) {
    return !env.isWeb && env.targetPlatform == TargetPlatform.linux;
  }

  static String? _normalizeLocale(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final normalized = trimmed.replaceAll('_', '-');
    final parts = normalized
        .split('-')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return null;
    }
    final language = parts.first.toLowerCase();
    if (parts.length == 1) {
      return _localeByLanguage[language] ?? language;
    }
    final region = parts[1].toUpperCase();
    return '$language-$region';
  }
}

const Map<String, String> _localeByLanguage = <String, String>{
  'ar': 'ar-SA',
  'bn': 'bn-BD',
  'de': 'de-DE',
  'en': 'en-US',
  'es': 'es-ES',
  'fr': 'fr-FR',
  'hi': 'hi-IN',
  'it': 'it-IT',
  'ja': 'ja-JP',
  'ko': 'ko-KR',
  'pt': 'pt-BR',
  'ru': 'ru-RU',
  'ur': 'ur-PK',
  'zh': 'zh-CN',
};

const Map<String, EdgeTtsLocalePreference> _edgeVoiceByLocale =
    <String, EdgeTtsLocalePreference>{
      'ar-sa': EdgeTtsLocalePreference(
        locale: 'ar-SA',
        voiceId: 'ar-SA-ZariyahNeural',
      ),
      'bn-bd': EdgeTtsLocalePreference(
        locale: 'bn-BD',
        voiceId: 'bn-BD-NabanitaNeural',
      ),
      'de-de': EdgeTtsLocalePreference(
        locale: 'de-DE',
        voiceId: 'de-DE-KatjaNeural',
      ),
      'en-us': EdgeTtsLocalePreference(
        locale: 'en-US',
        voiceId: 'en-US-EmmaMultilingualNeural',
      ),
      'en-gb': EdgeTtsLocalePreference(
        locale: 'en-GB',
        voiceId: 'en-GB-SoniaNeural',
      ),
      'es-es': EdgeTtsLocalePreference(
        locale: 'es-ES',
        voiceId: 'es-ES-ElviraNeural',
      ),
      'es-mx': EdgeTtsLocalePreference(
        locale: 'es-MX',
        voiceId: 'es-MX-DaliaNeural',
      ),
      'fr-fr': EdgeTtsLocalePreference(
        locale: 'fr-FR',
        voiceId: 'fr-FR-DeniseNeural',
      ),
      'hi-in': EdgeTtsLocalePreference(
        locale: 'hi-IN',
        voiceId: 'hi-IN-SwaraNeural',
      ),
      'it-it': EdgeTtsLocalePreference(
        locale: 'it-IT',
        voiceId: 'it-IT-ElsaNeural',
      ),
      'ja-jp': EdgeTtsLocalePreference(
        locale: 'ja-JP',
        voiceId: 'ja-JP-NanamiNeural',
      ),
      'ko-kr': EdgeTtsLocalePreference(
        locale: 'ko-KR',
        voiceId: 'ko-KR-SunHiNeural',
      ),
      'pt-br': EdgeTtsLocalePreference(
        locale: 'pt-BR',
        voiceId: 'pt-BR-FranciscaNeural',
      ),
      'pt-pt': EdgeTtsLocalePreference(
        locale: 'pt-PT',
        voiceId: 'pt-PT-RaquelNeural',
      ),
      'ru-ru': EdgeTtsLocalePreference(
        locale: 'ru-RU',
        voiceId: 'ru-RU-SvetlanaNeural',
      ),
      'ur-pk': EdgeTtsLocalePreference(
        locale: 'ur-PK',
        voiceId: 'ur-PK-UzmaNeural',
      ),
      'zh-cn': EdgeTtsLocalePreference(
        locale: 'zh-CN',
        voiceId: 'zh-CN-XiaoxiaoNeural',
      ),
      'zh-tw': EdgeTtsLocalePreference(
        locale: 'zh-TW',
        voiceId: 'zh-TW-HsiaoChenNeural',
      ),
    };

final Map<String, EdgeTtsLocalePreference> _defaultEdgeVoiceByLanguage =
    <String, EdgeTtsLocalePreference>{
      'ar': _edgeVoiceByLocale['ar-sa']!,
      'bn': _edgeVoiceByLocale['bn-bd']!,
      'de': _edgeVoiceByLocale['de-de']!,
      'en': _edgeVoiceByLocale['en-us']!,
      'es': _edgeVoiceByLocale['es-es']!,
      'fr': _edgeVoiceByLocale['fr-fr']!,
      'hi': _edgeVoiceByLocale['hi-in']!,
      'it': _edgeVoiceByLocale['it-it']!,
      'ja': _edgeVoiceByLocale['ja-jp']!,
      'ko': _edgeVoiceByLocale['ko-kr']!,
      'pt': _edgeVoiceByLocale['pt-br']!,
      'ru': _edgeVoiceByLocale['ru-ru']!,
      'ur': _edgeVoiceByLocale['ur-pk']!,
      'zh': _edgeVoiceByLocale['zh-cn']!,
    };
