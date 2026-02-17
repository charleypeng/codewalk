import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/experience_settings.dart';

class SoundService {
  Future<bool> play({required SoundOption option, String? source}) async {
    if (option == SoundOption.off) {
      return true;
    }

    try {
      if (option == SoundOption.systemDefault) {
        await SystemSound.play(SystemSoundType.alert);
        return true;
      }

      if (option == SoundOption.systemChoice ||
          option == SoundOption.customFile) {
        final normalizedSource = _normalizeSource(source);
        if (normalizedSource == null) {
          return false;
        }
        final player = AudioPlayer();
        await player.play(UrlSource(normalizedSource), volume: 1.0);
        player.onPlayerComplete.listen((_) {
          unawaited(player.dispose());
        });
        return true;
      }

      final bytes = _buildToneWav(
        frequencyHz: option == SoundOption.click ? 950 : 550,
        durationMs: option == SoundOption.click ? 85 : 220,
        withTail: option == SoundOption.alert,
      );
      final player = AudioPlayer();
      await player.play(BytesSource(bytes), volume: 1.0);
      player.onPlayerComplete.listen((_) {
        unawaited(player.dispose());
      });
      return true;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Sound unavailable on this platform',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  String? _normalizeSource(String? source) {
    final value = source?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('file://') ||
        value.startsWith('content://') ||
        value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return Uri.file(value).toString();
    }
    return value;
  }

  Uint8List _buildToneWav({
    required int frequencyHz,
    required int durationMs,
    required bool withTail,
  }) {
    const sampleRate = 22050;
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final samples = Int16List(sampleCount);
    final angular = 2 * pi * frequencyHz / sampleRate;

    for (var i = 0; i < sampleCount; i += 1) {
      final progress = i / sampleCount;
      final envelope = withTail ? (1.0 - progress).clamp(0.0, 1.0) : 1.0;
      final sample = sin(i * angular) * envelope * 0.45;
      samples[i] = (sample * 32767).round();
    }

    final dataLength = sampleCount * 2;
    final fileLength = 44 + dataLength;
    final bytes = ByteData(fileLength);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i += 1) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    bytes.setUint32(4, fileLength - 8, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);

    var cursor = 44;
    for (final sample in samples) {
      bytes.setInt16(cursor, sample, Endian.little);
      cursor += 2;
    }

    return bytes.buffer.asUint8List();
  }
}
