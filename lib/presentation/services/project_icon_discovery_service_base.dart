import '../../domain/entities/project.dart';
import 'project_icon_models.dart';

abstract class ProjectIconDiscoveryService {
  bool get isSupported;

  Future<ProjectIconDiscoveryResult> discover(Project project);
}
