import 'file_part_action_service_stub.dart'
    if (dart.library.io) 'file_part_action_service_io.dart'
    if (dart.library.html) 'file_part_action_service_web.dart'
    as impl;
import 'file_part_action_types.dart';

Future<FilePartActionResult> handleFilePartAction({
  required String url,
  required String? sourcePath,
  required String mimeType,
  required String? filename,
}) {
  return impl.handleFilePartAction(
    url: url,
    sourcePath: sourcePath,
    mimeType: mimeType,
    filename: filename,
  );
}
