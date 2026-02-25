import 'package:url_launcher/url_launcher.dart';

/// Attempts to launch [uri], swallowing any exception and returning false on
/// failure. Avoids crashing the caller when the URL cannot be handled.
Future<bool> safeLaunch(Uri uri, {LaunchMode? mode}) async {
  try {
    if (mode == null) {
      return launchUrl(uri);
    }
    return launchUrl(uri, mode: mode);
  } catch (_) {
    return false;
  }
}

/// Maps a MIME type string to a common file extension, falling back to ".bin".
String mimeToExtension(String mimeType) {
  if (mimeType.contains('png')) return '.png';
  if (mimeType.contains('jpeg') || mimeType.contains('jpg')) return '.jpg';
  if (mimeType.contains('gif')) return '.gif';
  if (mimeType.contains('webp')) return '.webp';
  if (mimeType.contains('bmp')) return '.bmp';
  if (mimeType.contains('heic')) return '.heic';
  if (mimeType.contains('heif')) return '.heif';
  if (mimeType.contains('pdf')) return '.pdf';
  if (mimeType.contains('json')) return '.json';
  if (mimeType.contains('markdown')) return '.md';
  if (mimeType.contains('plain') || mimeType.startsWith('text/')) return '.txt';
  return '.bin';
}
