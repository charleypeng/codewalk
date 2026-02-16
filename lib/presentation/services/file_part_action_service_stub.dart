import 'file_part_action_types.dart';

Future<FilePartActionResult> handleFilePartAction({
  required String url,
  required String? sourcePath,
  required String mimeType,
  required String? filename,
}) async {
  return const FilePartActionResult(
    success: false,
    message: 'Attachment actions are not available on this platform.',
  );
}
