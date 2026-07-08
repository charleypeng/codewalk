import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/services/tts/read_aloud_default_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadAloudDefaultResolver', () {
    test('defaults Linux first run to Edge even when native probe is true', () {
      final selection = ReadAloudDefaultResolver.resolve(
        const ReadAloudDefaultEnvironment(
          isWeb: false,
          targetPlatform: TargetPlatform.linux,
          nativeTtsAvailable: true,
          appLocaleCode: 'pt',
        ),
      );

      expect(selection.provider, ReadAloudProvider.edgeExperimental);
      expect(selection.voiceId, 'pt-BR-FranciscaNeural');
      expect(selection.voiceLocale, 'pt-BR');
    });

    test('prefers native when native TTS is available outside Linux', () {
      final selection = ReadAloudDefaultResolver.resolve(
        const ReadAloudDefaultEnvironment(
          isWeb: false,
          targetPlatform: TargetPlatform.windows,
          nativeTtsAvailable: true,
          appLocaleCode: 'en-GB',
        ),
      );

      expect(selection.provider, ReadAloudProvider.native);
      expect(selection.voiceId, isNull);
      expect(selection.voiceLocale, isNull);
    });

    test('falls back to Edge when native TTS is unavailable', () {
      final selection = ReadAloudDefaultResolver.resolve(
        const ReadAloudDefaultEnvironment(
          isWeb: false,
          targetPlatform: TargetPlatform.macOS,
          nativeTtsAvailable: false,
          appLocaleCode: 'ja',
        ),
      );

      expect(selection.provider, ReadAloudProvider.edgeExperimental);
      expect(selection.voiceId, 'ja-JP-NanamiNeural');
      expect(selection.voiceLocale, 'ja-JP');
    });

    test('uses app locale before system locale', () {
      final preference = ReadAloudDefaultResolver.edgePreferenceForLocale(
        appLocaleCode: 'fr',
        systemLocaleName: 'pt_BR',
      );

      expect(preference.voiceId, 'fr-FR-DeniseNeural');
      expect(preference.locale, 'fr-FR');
    });

    test('uses exact system locale when app locale is not set', () {
      final preference = ReadAloudDefaultResolver.edgePreferenceForLocale(
        systemLocaleName: 'en_GB',
      );

      expect(preference.voiceId, 'en-GB-SoniaNeural');
      expect(preference.locale, 'en-GB');
    });

    test('strips POSIX locale suffixes before Edge voice matching', () {
      final preference = ReadAloudDefaultResolver.edgePreferenceForLocale(
        systemLocaleName: 'pt_PT.UTF-8@calendar=gregorian',
      );

      expect(preference.voiceId, 'pt-PT-RaquelNeural');
      expect(preference.locale, 'pt-PT');
    });

    test('falls back to same-language Edge voice for unknown region', () {
      final preference = ReadAloudDefaultResolver.edgePreferenceForLocale(
        systemLocaleName: 'es_AR',
      );

      expect(preference.voiceId, 'es-ES-ElviraNeural');
      expect(preference.locale, 'es-ES');
    });

    test('maps Traditional Chinese script locale to Taiwan Edge voice', () {
      final preference = ReadAloudDefaultResolver.edgePreferenceForLocale(
        systemLocaleName: 'zh_Hant_TW',
      );

      expect(preference.voiceId, 'zh-TW-HsiaoChenNeural');
      expect(preference.locale, 'zh-TW');
    });

    test('maps Simplified Chinese script locale to mainland Edge voice', () {
      final preference = ReadAloudDefaultResolver.edgePreferenceForLocale(
        systemLocaleName: 'zh_Hans_SG',
      );

      expect(preference.voiceId, 'zh-CN-XiaoxiaoNeural');
      expect(preference.locale, 'zh-CN');
    });

    test('falls back to English Edge voice for unknown language', () {
      final preference = ReadAloudDefaultResolver.edgePreferenceForLocale(
        systemLocaleName: 'tl_PH',
      );

      expect(preference.voiceId, 'en-US-EmmaMultilingualNeural');
      expect(preference.locale, 'en-US');
    });

    test('maps CodeWalk supported app locales to concrete Edge locales', () {
      final expected = <String, String>{
        'ar': 'ar-SA-ZariyahNeural',
        'bn': 'bn-BD-NabanitaNeural',
        'de': 'de-DE-KatjaNeural',
        'en': 'en-US-EmmaMultilingualNeural',
        'es': 'es-ES-ElviraNeural',
        'fr': 'fr-FR-DeniseNeural',
        'hi': 'hi-IN-SwaraNeural',
        'it': 'it-IT-ElsaNeural',
        'ja': 'ja-JP-NanamiNeural',
        'ko': 'ko-KR-SunHiNeural',
        'pt': 'pt-BR-FranciscaNeural',
        'ru': 'ru-RU-SvetlanaNeural',
        'ur': 'ur-PK-UzmaNeural',
        'zh': 'zh-CN-XiaoxiaoNeural',
      };

      for (final entry in expected.entries) {
        final preference = ReadAloudDefaultResolver.edgePreferenceForLocale(
          appLocaleCode: entry.key,
        );
        expect(preference.voiceId, entry.value, reason: entry.key);
      }
    });
  });
}
