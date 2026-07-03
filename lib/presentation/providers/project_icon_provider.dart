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
  final Map<String, Future<ProjectIconData?>> _loadFuturesByKey =
      <String, Future<ProjectIconData?>>{};
  final Set<String> _loadedKeys = <String>{};
  final Set<String> _loadingKeys = <String>{};
  final Set<String> _discoveringKeys = <String>{};
  final Set<String> _autoDiscoveryAttemptedKeys = <String>{};

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

  Future<ProjectIconData?> loadStoredIcon(Project project) async {
    final key = projectIconKeyFor(project);
    final icon = _iconsByKey[key];
    if (icon != null || _loadedKeys.contains(key)) {
      return icon;
    }
    final existing = _loadFuturesByKey[key];
    if (existing != null) {
      return existing;
    }
    final future = _loadStoredIcon(key);
    _loadFuturesByKey[key] = future;
    return future.whenComplete(() => _loadFuturesByKey.remove(key));
  }

  Future<ProjectIconData?> _loadStoredIcon(String key) async {
    if (!_loadingKeys.add(key)) {
      return _iconsByKey[key];
    }
    try {
      final icon = await _store.readIcon(key);
      if (icon != null) {
        _iconsByKey[key] = icon;
      }
      return icon;
    } catch (error) {
      AppLogger.warn('Project icon load failed', error: error);
      return null;
    } finally {
      _loadedKeys.add(key);
      _loadingKeys.remove(key);
      notifyListeners();
    }
  }

  Future<void> autoDiscoverIcon(Project project) async {
    if (!_discoveryService.isSupported) {
      return;
    }
    final key = projectIconKeyFor(project);
    if (!_autoDiscoveryAttemptedKeys.add(key)) {
      return;
    }
    await loadStoredIcon(project);
    await discoverIcon(project);
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
