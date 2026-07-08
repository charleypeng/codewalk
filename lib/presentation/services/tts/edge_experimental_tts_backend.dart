import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/experience_settings.dart';
import 'edge_tts_protocol.dart';
import 'edge_tts_websocket.dart';
import 'tts_backend.dart';

const String kDefaultEdgeTtsVoice = 'en-US-AriaNeural';
const Duration kEdgeTtsConnectTimeout = Duration(seconds: 10);
const Duration kEdgeTtsSynthesisTimeout = Duration(seconds: 45);

typedef EdgeTtsNowProvider = DateTime Function();
typedef EdgeTtsIdProvider = String Function();

class EdgeExperimentalTtsBackend implements TtsBackend {
  EdgeExperimentalTtsBackend({
    Dio? dio,
    EdgeTtsWebSocketConnector? connector,
    EdgeTtsNowProvider? nowProvider,
    EdgeTtsIdProvider? idProvider,
  }) : _dio = dio ?? Dio(),
       _connector = connector ?? openEdgeTtsWebSocket,
       _nowProvider = nowProvider ?? DateTime.now,
       _idProvider = idProvider ?? edgeTtsConnectionId;

  final Dio _dio;
  final EdgeTtsWebSocketConnector _connector;
  final EdgeTtsNowProvider _nowProvider;
  final EdgeTtsIdProvider _idProvider;
  EdgeTtsWebSocketConnection? _activeConnection;
  bool _cancelled = false;

  @override
  ReadAloudProvider get provider => ReadAloudProvider.edgeExperimental;

  @override
  TtsPlaybackMode get playbackMode => TtsPlaybackMode.generatedAudio;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<List<TtsVoiceOption>> getVoices() async {
    try {
      final response = await _dio.get<dynamic>(
        edgeTtsVoicesUri(nowUtc: _nowProvider().toUtc()).toString(),
        options: Options(
          responseType: ResponseType.json,
          connectTimeout: kEdgeTtsConnectTimeout,
          receiveTimeout: kEdgeTtsSynthesisTimeout,
          headers: edgeTtsBrowserHeaders(),
        ),
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
    final text = stripEdgeTtsControlChars(request.text).trim();
    if (text.isEmpty) {
      throw const TtsBackendException(
        TtsBackendErrorKind.invalidRequest,
        'There is no text to read aloud.',
      );
    }
    if (isEdgeTtsInputTooLong(text)) {
      throw const TtsBackendException(
        TtsBackendErrorKind.invalidRequest,
        'Microsoft Edge Speech can read up to 4096 bytes at a time.',
      );
    }

    final connectionId = _idProvider().replaceAll('-', '');
    final requestId = _idProvider().replaceAll('-', '');
    final uri = edgeTtsWebSocketUri(
      connectionId: connectionId,
      nowUtc: _nowProvider().toUtc(),
    );
    final connection = _connector(uri);
    _cancelled = false;
    _activeConnection = connection;
    final audio = BytesBuilder(copy: false);

    try {
      await connection.ready.timeout(kEdgeTtsConnectTimeout);
      final voice = _effectiveVoice(request.voiceId);
      final locale = _effectiveLocale(request.voiceLocale, voice);
      connection.sendText(
        edgeTtsSpeechConfigFrame(nowUtc: _nowProvider().toUtc()),
      );
      connection.sendText(
        edgeTtsSsmlFrame(
          requestId: requestId,
          ssml: buildEdgeTtsSsml(
            text: text,
            voice: voice,
            locale: locale,
            rate: edgeTtsRateAttribute(request.rate),
            pitch: edgeTtsPitchAttribute(request.pitch),
          ),
          nowUtc: _nowProvider().toUtc(),
        ),
      );
      callbacks.onStart?.call();

      await for (final event in connection.stream.timeout(
        kEdgeTtsSynthesisTimeout,
      )) {
        if (_cancelled) {
          throw const TtsBackendException(
            TtsBackendErrorKind.providerUnavailable,
            'Microsoft Edge Speech was cancelled.',
          );
        }
        if (event is String) {
          final frame = parseEdgeTtsTextFrame(event);
          if (frame.path == 'turn.end') {
            break;
          }
          continue;
        }
        if (event is List<int>) {
          final frame = parseEdgeTtsBinaryFrame(event);
          if (frame.path != 'audio') {
            continue;
          }
          if (frame.contentType != null &&
              frame.contentType != kEdgeTtsAudioMimeType) {
            throw const TtsBackendException(
              TtsBackendErrorKind.providerUnavailable,
              'Microsoft Edge Speech returned unsupported audio data.',
            );
          }
          if (frame.audioBytes.isNotEmpty) {
            audio.add(frame.audioBytes);
          }
          continue;
        }
        throw const TtsBackendException(
          TtsBackendErrorKind.providerUnavailable,
          'Microsoft Edge Speech returned an unsupported websocket frame.',
        );
      }

      final bytes = audio.takeBytes();
      if (bytes.isEmpty) {
        throw const TtsBackendException(
          TtsBackendErrorKind.providerUnavailable,
          'Microsoft Edge Speech returned an empty audio response.',
        );
      }
      return GeneratedTtsAudio(
        bytes: Uint8List.fromList(bytes),
        mimeType: kEdgeTtsAudioMimeType,
      );
    } on TimeoutException catch (_) {
      throw const TtsBackendException(
        TtsBackendErrorKind.network,
        'Microsoft Edge Speech timed out.',
      );
    } on FormatException catch (_) {
      throw const TtsBackendException(
        TtsBackendErrorKind.providerUnavailable,
        'Microsoft Edge Speech returned malformed audio data.',
      );
    } on TtsBackendException {
      rethrow;
    } catch (_) {
      throw const TtsBackendException(
        TtsBackendErrorKind.network,
        'Microsoft Edge Speech could not be reached.',
      );
    } finally {
      if (identical(_activeConnection, connection)) {
        _activeConnection = null;
      }
      try {
        await connection.close().timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> stop() async {
    _cancelled = true;
    final connection = _activeConnection;
    _activeConnection = null;
    await connection?.close().timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
  }

  @override
  Future<void> pause() async {}

  @override
  void dispose() {}

  String _effectiveVoice(String? voiceId) {
    final trimmed = voiceId?.trim();
    return trimmed != null && trimmed.isNotEmpty
        ? trimmed
        : kDefaultEdgeTtsVoice;
  }

  String _effectiveLocale(String? locale, String voice) {
    final trimmed = locale?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    final parts = voice.split('-');
    if (parts.length >= 2) {
      return '${parts[0]}-${parts[1]}';
    }
    return 'en-US';
  }
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
