import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

import 'file_part_action_types.dart';

Future<FilePartActionResult> handleFilePartAction({
  required String url,
  required String? sourcePath,
  required String mimeType,
  required String? filename,
}) async {
  final trimmedUrl = url.trim();
  final parsedUrl = trimmedUrl.isEmpty ? null : Uri.tryParse(trimmedUrl);

  if (parsedUrl != null) {
    final scheme = parsedUrl.scheme.toLowerCase();
    if (scheme == 'data') {
      return _downloadInlineAttachment(
        dataUrl: trimmedUrl,
        mimeType: mimeType,
        filename: filename,
      );
    }
    if (scheme == 'http' || scheme == 'https') {
      final launched = await _safeLaunch(
        parsedUrl,
        mode: LaunchMode.platformDefault,
      );
      if (launched) {
        return const FilePartActionResult(success: true);
      }
      return const FilePartActionResult(
        success: false,
        message: 'Unable to open the attachment link.',
      );
    }
    if (scheme == 'file') {
      return const FilePartActionResult(
        success: false,
        message:
            'Browser sandbox prevents opening local file:// attachments directly.',
      );
    }

    if (parsedUrl.hasScheme) {
      final launched = await _safeLaunch(parsedUrl);
      if (launched) {
        return const FilePartActionResult(success: true);
      }
    }
  }

  if (sourcePath != null && sourcePath.trim().isNotEmpty) {
    return const FilePartActionResult(
      success: false,
      message:
          'This attachment points to a local path that cannot be opened from the browser.',
    );
  }

  return const FilePartActionResult(
    success: false,
    message: 'Attachment does not provide a valid location.',
  );
}

FilePartActionResult _downloadInlineAttachment({
  required String dataUrl,
  required String mimeType,
  required String? filename,
}) {
  try {
    final safeName = _resolveOutputName(
      filename: filename,
      mimeType: mimeType,
      dataUrl: dataUrl,
    );
    final anchor = web.HTMLAnchorElement()
      ..href = dataUrl
      ..download = safeName
      ..style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    return const FilePartActionResult(
      success: true,
      message: 'Attachment download started.',
    );
  } catch (_) {
    return const FilePartActionResult(
      success: false,
      message: 'Attachment could not be downloaded.',
    );
  }
}

Future<bool> _safeLaunch(Uri uri, {LaunchMode? mode}) async {
  try {
    if (mode == null) {
      return launchUrl(uri);
    }
    return launchUrl(uri, mode: mode);
  } catch (_) {
    return false;
  }
}

String _resolveOutputName({
  required String? filename,
  required String mimeType,
  required String dataUrl,
}) {
  final trimmedName = filename?.trim() ?? '';
  if (trimmedName.isNotEmpty) {
    return _sanitizeFilename(trimmedName);
  }

  String effectiveMime = mimeType.trim().toLowerCase();
  if (effectiveMime.isEmpty) {
    try {
      effectiveMime = UriData.parse(dataUrl).mimeType.trim().toLowerCase();
    } catch (_) {
      effectiveMime = '';
    }
  }
  final extension = _mimeToExtension(effectiveMime);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return 'attachment_$timestamp$extension';
}

String _mimeToExtension(String mimeType) {
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

String _sanitizeFilename(String filename) {
  final sanitized = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  if (sanitized.isEmpty) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'attachment_$timestamp.bin';
  }
  return sanitized;
}
