import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/experience_settings.dart';
import 'tts_backend.dart';

const String kEdgeTtsTrustedClientToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';
const String kEdgeTtsVoicesUrl =
    'https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list';

class EdgeExperimentalTtsBackend implements TtsBackend {
  EdgeExperimentalTtsBackend({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  ReadAloudProvider get provider => ReadAloudProvider.edgeExperimental;

  @override
  TtsPlaybackMode get playbackMode => TtsPlaybackMode.generatedAudio;

  @override
  Future<bool> get isAvailable async => false;

  @override
  Future<List<TtsVoiceOption>> getVoices() async {
    try {
      final response = await _dio.get<dynamic>(
        kEdgeTtsVoicesUrl,
        queryParameters: <String, String>{
          'trustedclienttoken': kEdgeTtsTrustedClientToken,
        },
        options: Options(responseType: ResponseType.json),
      );
      return parseEdgeTtsVoices(response.data);
    } catch (_) {
      return const <TtsVoiceOption>[];
    }
  }

  @override
  Future<List<String>> getLanguages() async {
    final voices = await getVoices();
    return voices
        .map((voice) => voice.locale)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
  }

  @override
  Future<TtsSynthesisResult> speakOrSynthesize(
    TtsSynthesisRequest request,
    TtsBackendCallbacks callbacks,
  ) async {
    throw const TtsBackendException(
      TtsBackendErrorKind.providerUnavailable,
      'Microsoft Edge Speech is experimental and direct synthesis is blocked in this build because the unofficial Edge Read Aloud protocol requires unstable Edge-specific transport headers. Use an OpenAI-compatible Edge proxy or switch providers.',
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  void dispose() {}
}

@visibleForTesting
List<TtsVoiceOption> parseEdgeTtsVoices(dynamic data) {
  if (data is! List) {
    return const <TtsVoiceOption>[];
  }
  return data
      .map<TtsVoiceOption?>((dynamic value) {
        if (value is! Map) {
          return null;
        }
        final id = value['ShortName']?.toString() ?? value['Name']?.toString();
        if (id == null || id.trim().isEmpty) {
          return null;
        }
        final locale = value['Locale']?.toString();
        final friendlyName = value['FriendlyName']?.toString();
        final gender = value['Gender']?.toString();
        final label = friendlyName != null && friendlyName.isNotEmpty
            ? friendlyName
            : id;
        return TtsVoiceOption(
          id: id,
          label: locale != null && locale.isNotEmpty
              ? '$label ($locale)'
              : label,
          locale: locale,
          providerMetadata: <String, String>{
            if (gender != null && gender.isNotEmpty) 'gender': gender,
          },
        );
      })
      .whereType<TtsVoiceOption>()
      .toList(growable: false);
}

@visibleForTesting
String buildEdgeTtsSsml({
  required String text,
  required String voice,
  String locale = 'en-US',
  String rate = '+0%',
  String pitch = '+0Hz',
}) {
  return '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
      'xml:lang="${escapeEdgeTtsXml(locale)}"><voice name="${escapeEdgeTtsXml(voice)}">'
      '<prosody rate="${escapeEdgeTtsXml(rate)}" pitch="${escapeEdgeTtsXml(pitch)}">'
      '${escapeEdgeTtsXml(text)}</prosody></voice></speak>';
}

@visibleForTesting
String escapeEdgeTtsXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
