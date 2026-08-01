import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Extensions the composer already accepts through the file picker.
///
/// Kept here so dropped (#118) and pasted (#119) files are judged by exactly
/// the same rule as picked ones, instead of each entry point inventing its own.
const Set<String> kComposerAttachmentExtensions = <String>{
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'heic',
  'heif',
  'pdf',
};

/// Extension of [path], lowercased, without the dot. Empty when absent.
String composerFileExtension(String path) {
  final name = path.split(RegExp(r'[/\\]')).last;
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) {
    return '';
  }
  return name.substring(dot + 1).toLowerCase();
}

/// File name of [path], or a fallback when the platform gives only a URI.
String composerFileName(String path, {required String fallback}) {
  final name = path.split(RegExp(r'[/\\]')).last.trim();
  return name.isEmpty ? fallback : name;
}

/// Builds a [PlatformFile] for a file the user dropped or pasted.
///
/// Returns null when the extension is not one the composer accepts, so callers
/// can count it as skipped without inspecting arbitrary content.
PlatformFile? composerFileFromPath(
  String path, {
  required String fallbackName,
}) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (!kComposerAttachmentExtensions.contains(composerFileExtension(trimmed))) {
    return null;
  }
  return PlatformFile(
    path: trimmed,
    name: composerFileName(trimmed, fallback: fallbackName),
    size: 0,
  );
}

/// Builds a [PlatformFile] for raw image bytes, such as a pasted screenshot.
///
/// Screenshots arrive without a name, so one is supplied by the caller in the
/// user's language, with the extension derived from the detected format.
PlatformFile? composerFileFromImageBytes(
  Uint8List bytes, {
  required String baseName,
}) {
  if (bytes.isEmpty) {
    return null;
  }
  final extension = composerImageExtensionFromBytes(bytes);
  return PlatformFile(
    name: '$baseName.$extension',
    size: bytes.length,
    bytes: bytes,
  );
}

/// Detects an image format from its magic bytes.
///
/// The clipboard hands over bytes with no filename, and guessing PNG for
/// everything would mislabel JPEG screenshots, so the header is read instead.
/// Defaults to png, which is what most platforms put on the clipboard.
String composerImageExtensionFromBytes(Uint8List bytes) {
  bool startsWith(List<int> signature, {int offset = 0}) {
    if (bytes.length < offset + signature.length) {
      return false;
    }
    for (var i = 0; i < signature.length; i += 1) {
      if (bytes[offset + i] != signature[i]) {
        return false;
      }
    }
    return true;
  }

  if (startsWith(<int>[0x89, 0x50, 0x4E, 0x47])) {
    return 'png';
  }
  if (startsWith(<int>[0xFF, 0xD8, 0xFF])) {
    return 'jpg';
  }
  if (startsWith(<int>[0x47, 0x49, 0x46, 0x38])) {
    return 'gif';
  }
  if (startsWith(<int>[0x42, 0x4D])) {
    return 'bmp';
  }
  if (startsWith(<int>[0x52, 0x49, 0x46, 0x46]) &&
      startsWith(<int>[0x57, 0x45, 0x42, 0x50], offset: 8)) {
    return 'webp';
  }
  if (startsWith(<int>[0x66, 0x74, 0x79, 0x70], offset: 4)) {
    return 'heic';
  }
  return 'png';
}

/// Drops duplicates while preserving the order the platform reported.
///
/// The clipboard can expose the same file through more than one
/// representation, and a drop can repeat a path; both would otherwise reach
/// the attachment list twice.
List<PlatformFile> composerDedupeFiles(List<PlatformFile> files) {
  final seen = <String>{};
  final result = <PlatformFile>[];
  for (final file in files) {
    final key = file.path ?? '${file.name}:${file.size}';
    if (seen.add(key)) {
      result.add(file);
    }
  }
  return result;
}
