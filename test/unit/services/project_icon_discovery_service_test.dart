import 'dart:io';

import 'package:codewalk/domain/entities/project.dart';
import 'package:codewalk/presentation/services/project_icon_discovery_service_io.dart';
import 'package:codewalk/presentation/services/project_icon_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('codewalk_project_icon_');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  Project project() {
    return Project(
      id: 'project_1',
      name: 'Project',
      path: root.path,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  test('chooses the favicon with the shortest relative path', () async {
    await Directory('${root.path}/assets/icons').create(recursive: true);
    await Directory('${root.path}/public').create(recursive: true);
    await File(
      '${root.path}/assets/icons/favicon.svg',
    ).writeAsString('<svg />');
    await File('${root.path}/public/favicon.png').writeAsBytes(<int>[1, 2, 3]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourcePath, endsWith('/public/favicon.png'));
    expect(result.candidate?.sourceFormat, ProjectIconFormat.png);
  });

  test('ignores non-canonical favicon suffixes', () async {
    await File('${root.path}/favicon.backup.png').writeAsBytes(<int>[1, 2, 3]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.notFound);
  });

  test('ignores favicon files in skipped directories', () async {
    await Directory('${root.path}/node_modules/pkg').create(recursive: true);
    await File(
      '${root.path}/node_modules/pkg/favicon.png',
    ).writeAsBytes(<int>[1, 2, 3]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.notFound);
  });

  test('reports oversized favicon files', () async {
    await File(
      '${root.path}/favicon.png',
    ).writeAsBytes(List<int>.filled(projectIconMaxBytes + 1, 0));

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.oversized);
  });

  test('reports unsupported favicon formats', () async {
    await File('${root.path}/favicon.gif').writeAsBytes(<int>[1, 2, 3]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.unsupported);
  });
}
