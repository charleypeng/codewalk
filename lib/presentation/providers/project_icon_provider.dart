import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/project.dart';
import '../services/project_icon_discovery_service_base.dart';
import '../services/project_icon_models.dart';
import '../services/project_icon_store_base.dart';

class ProjectIconProvider extends ChangeNotifier {
  ProjectIconProvider({
    required ProjectIconStore store,
    required ProjectIconDiscoveryService discoveryService,
  }) : _store = store,
       _discoveryService = discoveryService;

  final ProjectIconStore _store;
  final ProjectIconDiscoveryService _discoveryService;
  final Map<String, ProjectIconData> _iconsByKey = <String, ProjectIconData>{};
  final Set<String> _loadedKeys = <String>{};
  final Set<String> _loadingKeys = <String>{};
  final Set<String> _discoveringKeys = <String>{};

  bool get discoverySupported => _discoveryService.isSupported;

  ProjectIconData? iconFor(Project project) {
    return _iconsByKey[projectIconKeyFor(project)];
  }

  bool isLoading(Project project) {
    return _loadingKeys.contains(projectIconKeyFor(project));
  }

  bool isDiscovering(Project project) {
    return _discoveringKeys.contains(projectIconKeyFor(project));
  }

  Future<void> loadStoredIcon(Project project) async {
    final key = projectIconKeyFor(project);
    if (_iconsByKey.containsKey(key) ||
        _loadedKeys.contains(key) ||
        !_loadingKeys.add(key)) {
      return;
    }
    try {
      final icon = await _store.readIcon(key);
      if (icon != null) {
        _iconsByKey[key] = icon;
      }
    } catch (error) {
      AppLogger.warn('Project icon load failed', error: error);
    } finally {
      _loadedKeys.add(key);
      _loadingKeys.remove(key);
      notifyListeners();
    }
  }

  Future<ProjectIconDiscoveryResult> discoverIcon(Project project) async {
    final key = projectIconKeyFor(project);
    if (!_discoveringKeys.add(key)) {
      return const ProjectIconDiscoveryResult(
        status: ProjectIconDiscoveryStatus.error,
        message: 'Project icon discovery is already running.',
      );
    }
    notifyListeners();
    try {
      final result = await _discoveryService.discover(project);
      final candidate = result.candidate;
      if (result.found && candidate != null) {
        final icon = await _store.saveIcon(
          project: project,
          key: key,
          candidate: candidate,
        );
        _iconsByKey[key] = icon;
        _loadedKeys.add(key);
      } else if (result.status == ProjectIconDiscoveryStatus.notFound ||
          result.status == ProjectIconDiscoveryStatus.oversized ||
          result.status == ProjectIconDiscoveryStatus.unsupported) {
        await _store.deleteIcon(key);
        _iconsByKey.remove(key);
        _loadedKeys.add(key);
      }
      return result;
    } catch (error) {
      AppLogger.warn('Project icon discovery failed', error: error);
      return ProjectIconDiscoveryResult(
        status: ProjectIconDiscoveryStatus.error,
        message: error.toString(),
      );
    } finally {
      _discoveringKeys.remove(key);
      notifyListeners();
    }
  }
}
