import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

const String kEdgeTtsTrustedClientToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';
const String kEdgeTtsChromiumMajorVersion = '143';
const String kEdgeTtsChromiumFullVersion = '143.0.3650.75';
const String kEdgeTtsSecMsGecVersion = '1-143.0.3650.75';
const String kEdgeTtsWebSocketBaseUrl =
    'wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1';
const String kEdgeTtsVoicesUrl =
    'https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list';
const String kEdgeTtsAudioMimeType = 'audio/mpeg';
const String kEdgeTtsAudioOutputFormat = 'audio-24khz-48kbitrate-mono-mp3';
const int kEdgeTtsMaxInputBytes = 4096;

String edgeTtsSecMsGec(DateTime nowUtc) {
  final utc = nowUtc.toUtc();
  final secondsSinceUnixEpoch = utc.millisecondsSinceEpoch ~/ 1000;
  final windowsFileTime = (secondsSinceUnixEpoch + 11644473600) * 10000000;
  final rounded = windowsFileTime - (windowsFileTime % 3000000000);
  return sha256
      .convert(utf8.encode('$rounded$kEdgeTtsTrustedClientToken'))
      .toString()
      .toUpperCase();
}

String edgeTtsConnectionId([String? value]) {
  if (value != null && value.trim().isNotEmpty) {
    return value.replaceAll('-', '');
  }
  return edgeTtsRandomHex32();
}

String edgeTtsRandomHex32() {
  final random = Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i += 1) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

String edgeTtsWebSocketKey() {
  final random = Random.secure();
  return base64Encode(List<int>.generate(16, (_) => random.nextInt(256)));
}

Uri edgeTtsWebSocketUri({
  required String connectionId,
  required DateTime nowUtc,
}) {
  return Uri.parse(kEdgeTtsWebSocketBaseUrl).replace(
    queryParameters: <String, String>{
      'TrustedClientToken': kEdgeTtsTrustedClientToken,
      'ConnectionId': connectionId.replaceAll('-', ''),
      'Sec-MS-GEC': edgeTtsSecMsGec(nowUtc),
      'Sec-MS-GEC-Version': kEdgeTtsSecMsGecVersion,
    },
  );
}

Uri edgeTtsVoicesUri({required DateTime nowUtc}) {
  return Uri.parse(kEdgeTtsVoicesUrl).replace(
    queryParameters: <String, String>{
      'trustedclienttoken': kEdgeTtsTrustedClientToken,
      'Sec-MS-GEC': edgeTtsSecMsGec(nowUtc),
      'Sec-MS-GEC-Version': kEdgeTtsSecMsGecVersion,
    },
  );
}

Map<String, String> edgeTtsBrowserHeaders({String? muid}) {
  return <String, String>{
    'Pragma': 'no-cache',
    'Cache-Control': 'no-cache',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Accept-Language': 'en-US,en;q=0.9',
    'Origin': 'chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold',
    'Sec-WebSocket-Version': '13',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/$kEdgeTtsChromiumMajorVersion.0.0.0 '
        'Safari/537.36 Edg/$kEdgeTtsChromiumMajorVersion.0.0.0',
    if (muid != null && muid.isNotEmpty) 'Cookie': 'muid=$muid;',
  };
}

Map<String, String> edgeTtsVoiceHeaders() {
  return <String, String>{
    'Authority': 'speech.platform.bing.com',
    'Sec-CH-UA':
        '" Not;A Brand";v="99", "Microsoft Edge";v="$kEdgeTtsChromiumMajorVersion", '
        '"Chromium";v="$kEdgeTtsChromiumMajorVersion"',
    'Sec-CH-UA-Mobile': '?0',
    'Accept': '*/*',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Dest': 'empty',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Accept-Language': 'en-US,en;q=0.9',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/$kEdgeTtsChromiumMajorVersion.0.0.0 '
        'Safari/537.36 Edg/$kEdgeTtsChromiumMajorVersion.0.0.0',
  };
}

String edgeTtsFrame({
  required Map<String, String> headers,
  required String payload,
}) {
  final buffer = StringBuffer();
  headers.forEach((key, value) {
    buffer.write(key);
    buffer.write(':');
    buffer.write(value);
    buffer.write('\r\n');
  });
  buffer.write('\r\n');
  buffer.write(payload);
  return buffer.toString();
}

String edgeTtsSpeechConfigFrame({DateTime? nowUtc}) {
  final config = jsonEncode(<String, Object>{
    'context': <String, Object>{
      'synthesis': <String, Object>{
        'audio': <String, Object>{
          'metadataoptions': <String, Object>{
            'sentenceBoundaryEnabled': 'false',
            'wordBoundaryEnabled': 'true',
          },
          'outputFormat': kEdgeTtsAudioOutputFormat,
        },
      },
    },
  });
  return edgeTtsFrame(
    headers: <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Path': 'speech.config',
      'X-Timestamp': edgeTtsTimestamp(nowUtc ?? DateTime.now().toUtc()),
    },
    payload: '$config\r\n',
  );
}

String edgeTtsSsmlFrame({
  required String requestId,
  required String ssml,
  DateTime? nowUtc,
}) {
  return edgeTtsFrame(
    headers: <String, String>{
      'Content-Type': 'application/ssml+xml',
      'Path': 'ssml',
      'X-RequestId': requestId.replaceAll('-', ''),
      'X-Timestamp': '${edgeTtsTimestamp(nowUtc ?? DateTime.now().toUtc())}Z',
    },
    payload: ssml,
  );
}

String edgeTtsTimestamp(DateTime utc) {
  final value = utc.toUtc();
  const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String two(int number) => number.toString().padLeft(2, '0');
  return '${weekdays[value.weekday - 1]} ${months[value.month - 1]} '
      '${two(value.day)} ${value.year} ${two(value.hour)}:${two(value.minute)}:'
      '${two(value.second)} GMT+0000 (Coordinated Universal Time)';
}

String buildEdgeTtsSsml({
  required String text,
  required String voice,
  String locale = 'en-US',
  String rate = '+0%',
  String pitch = '+0Hz',
}) {
  return "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' "
      "xml:lang='${escapeEdgeTtsXml(locale)}'><voice name='${escapeEdgeTtsXml(voice)}'>"
      "<prosody pitch='${escapeEdgeTtsXml(pitch)}' rate='${escapeEdgeTtsXml(rate)}' "
      "volume='+0%'>${escapeEdgeTtsXml(stripEdgeTtsControlChars(text))}"
      '</prosody></voice></speak>';
}

String stripEdgeTtsControlChars(String value) {
  return value.replaceAll(
    RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F]'),
    '',
  );
}

String escapeEdgeTtsXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

int edgeTtsInputByteLength(String value) {
  return utf8.encode(stripEdgeTtsControlChars(value)).length;
}

bool isEdgeTtsInputTooLong(String value) {
  return edgeTtsInputByteLength(value) > kEdgeTtsMaxInputBytes;
}

double edgeTtsRatePercentFromReadAloudRate(double rate) {
  return ((rate.clamp(0.0, 1.0) - 0.5) * 100).roundToDouble();
}

String edgeTtsRateAttribute(double rate) {
  final percent = edgeTtsRatePercentFromReadAloudRate(rate).round();
  return percent >= 0 ? '+$percent%' : '$percent%';
}

String edgeTtsPitchAttribute(double pitch) {
  final percent = ((pitch.clamp(0.5, 2.0) - 1.0) * 50).round();
  return percent >= 0 ? '+${percent}Hz' : '${percent}Hz';
}

class EdgeTtsTextFrame {
  const EdgeTtsTextFrame({required this.headers, required this.body});

  final Map<String, String> headers;
  final String body;

  String? get path => headers['Path'];
}

EdgeTtsTextFrame parseEdgeTtsTextFrame(String frame) {
  final separatorIndex = frame.indexOf('\r\n\r\n');
  final headerText = separatorIndex >= 0
      ? frame.substring(0, separatorIndex)
      : frame;
  final body = separatorIndex >= 0 ? frame.substring(separatorIndex + 4) : '';
  final headers = <String, String>{};
  for (final line in headerText.split('\r\n')) {
    if (line.isEmpty) continue;
    final index = line.indexOf(':');
    if (index <= 0) continue;
    headers[line.substring(0, index)] = line.substring(index + 1);
  }
  return EdgeTtsTextFrame(headers: headers, body: body);
}

class EdgeTtsBinaryFrame {
  const EdgeTtsBinaryFrame({required this.headers, required this.audioBytes});

  final Map<String, String> headers;
  final Uint8List audioBytes;

  String? get path => headers['Path'];
  String? get contentType => headers['Content-Type'];
}

EdgeTtsBinaryFrame parseEdgeTtsBinaryFrame(List<int> data) {
  if (data.length < 2) {
    throw const FormatException('Edge TTS binary frame is too short.');
  }
  final headerLength = (data[0] << 8) + data[1];
  final payloadOffset = headerLength + 2;
  if (data.length < payloadOffset) {
    throw const FormatException('Edge TTS binary frame header is truncated.');
  }
  final headerText = utf8.decode(data.sublist(2, payloadOffset));
  final headers = parseEdgeTtsTextFrame('$headerText\r\n\r\n').headers;
  return EdgeTtsBinaryFrame(
    headers: headers,
    audioBytes: Uint8List.fromList(data.sublist(payloadOffset)),
  );
}

@visibleForTesting
Uint8List buildEdgeTtsBinaryFrameForTest({
  required Map<String, String> headers,
  required List<int> audioBytes,
}) {
  final headerBytes = utf8.encode(
    headers.entries.map((entry) => '${entry.key}:${entry.value}').join('\r\n'),
  );
  final result = Uint8List(2 + headerBytes.length + audioBytes.length);
  result[0] = (headerBytes.length >> 8) & 0xff;
  result[1] = headerBytes.length & 0xff;
  result.setRange(2, 2 + headerBytes.length, headerBytes);
  result.setRange(2 + headerBytes.length, result.length, audioBytes);
  return result;
}
