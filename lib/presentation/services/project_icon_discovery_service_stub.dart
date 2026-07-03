import 'package:dio/dio.dart';

import '../../domain/entities/project.dart';
import 'project_icon_discovery_service_base.dart';
import 'project_icon_models.dart';

ProjectIconDiscoveryService createProjectIconDiscoveryService({Dio? dio}) =>
    const _UnsupportedProjectIconDiscoveryService();

class _UnsupportedProjectIconDiscoveryService
    implements ProjectIconDiscoveryService {
  const _UnsupportedProjectIconDiscoveryService();

  @override
  bool get isSupported => false;

  @override
  Future<ProjectIconDiscoveryResult> discover(Project project) async {
    return const ProjectIconDiscoveryResult(
      status: ProjectIconDiscoveryStatus.unsupportedPlatform,
      message: 'Project icon discovery is not available on this platform.',
    );
  }
}
