import '../../domain/entities/project.dart';
import 'project_icon_store_base.dart';
import 'project_icon_models.dart';

ProjectIconStore createProjectIconStore() =>
    const _UnsupportedProjectIconStore();

class _UnsupportedProjectIconStore implements ProjectIconStore {
  const _UnsupportedProjectIconStore();

  @override
  Future<void> deleteIcon(String key) async {}

  @override
  Future<ProjectIconData?> readIcon(String key) async => null;

  @override
  Future<ProjectIconData> saveIcon({
    required Project project,
    required String key,
    required ProjectIconCandidate candidate,
  }) async {
    final metadata = ProjectIconMetadata(
      key: key,
      projectId: project.id,
      projectPath: project.path,
      sourcePath: candidate.sourcePath,
      storedPath: '',
      sourceFormat: candidate.sourceFormat,
      storedFormat: candidate.storedFormat,
      sourceByteLength: candidate.sourceByteLength,
      storedByteLength: candidate.bytes.length,
      updatedAt: DateTime.now(),
    );
    return ProjectIconData(metadata: metadata, bytes: candidate.bytes);
  }
}
