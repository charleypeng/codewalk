import 'dart:typed_data';

import '../../domain/entities/project.dart';
import 'project_icon_models.dart';

abstract class ProjectIconStore {
  Future<ProjectIconData?> readIcon(String key);

  Future<ProjectIconData> saveIcon({
    required Project project,
    required String key,
    required ProjectIconCandidate candidate,
  });

  Future<void> deleteIcon(String key);
}

ProjectIconCandidate projectIconCandidateForTest({
  required String sourcePath,
  required Uint8List bytes,
  required ProjectIconFormat format,
}) {
  return ProjectIconCandidate(
    sourcePath: sourcePath,
    bytes: bytes,
    sourceFormat: format,
    storedFormat: format == ProjectIconFormat.ico
        ? ProjectIconFormat.png
        : format,
    sourceByteLength: bytes.length,
  );
}
