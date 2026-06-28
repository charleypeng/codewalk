import 'dart:typed_data';

import 'package:codewalk/domain/entities/project.dart';
import 'package:codewalk/presentation/providers/project_icon_provider.dart';
import 'package:codewalk/presentation/services/project_icon_discovery_service_base.dart';
import 'package:codewalk/presentation/services/project_icon_models.dart';
import 'package:codewalk/presentation/services/project_icon_store_base.dart';
import 'package:codewalk/presentation/widgets/project_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

void main() {
  late Project project;

  setUp(() {
    project = Project(
      id: 'project_1',
      name: 'Project',
      path: '/repo/project',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  });

  testWidgets('falls back to the folder icon without stored metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: ProjectIcon(project: project)),
      ),
    );

    expect(find.byIcon(Symbols.folder_open), findsOneWidget);
  });

  testWidgets('renders a stored svg project icon', (tester) async {
    final store = _MemoryProjectIconStore(
      icon: _projectIconData(
        project: project,
        bytes: Uint8List.fromList(
          '<svg viewBox="0 0 8 8"><rect width="8" height="8" /></svg>'
              .codeUnits,
        ),
        format: ProjectIconFormat.svg,
      ),
    );
    final provider = ProjectIconProvider(
      store: store,
      discoveryService: const _UnsupportedDiscoveryService(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ProjectIconProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Center(child: ProjectIcon(project: project)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(store.readCount, 1);
  });

  testWidgets('falls back when a stored svg cannot render', (tester) async {
    final store = _MemoryProjectIconStore(
      icon: _projectIconData(
        project: project,
        bytes: Uint8List.fromList('not svg'.codeUnits),
        format: ProjectIconFormat.svg,
      ),
    );
    final provider = ProjectIconProvider(
      store: store,
      discoveryService: const _UnsupportedDiscoveryService(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ProjectIconProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Center(child: ProjectIcon(project: project)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Symbols.folder_open), findsOneWidget);
  });

  testWidgets('discovery button stores found icons and reports the result', (
    tester,
  ) async {
    final candidate = projectIconCandidateForTest(
      sourcePath: '/repo/project/favicon.svg',
      bytes: Uint8List.fromList('<svg />'.codeUnits),
      format: ProjectIconFormat.svg,
    );
    final store = _MemoryProjectIconStore();
    final provider = ProjectIconProvider(
      store: store,
      discoveryService: _FakeDiscoveryService(
        ProjectIconDiscoveryResult.found(candidate),
      ),
    );
    ProjectIconDiscoveryResult? observed;

    await tester.pumpWidget(
      ChangeNotifierProvider<ProjectIconProvider>.value(
        value: provider,
        child: MaterialApp(
          home: ProjectIconDiscoveryButton(
            project: project,
            tooltip: 'Find project icon',
            onResult: (result) => observed = result,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Find project icon'));
    await tester.pumpAndSettle();

    expect(observed?.status, ProjectIconDiscoveryStatus.found);
    expect(store.saved?.metadata.sourcePath, '/repo/project/favicon.svg');
  });
}

ProjectIconData _projectIconData({
  required Project project,
  required Uint8List bytes,
  required ProjectIconFormat format,
}) {
  final key = projectIconKeyFor(project);
  return ProjectIconData(
    metadata: ProjectIconMetadata(
      key: key,
      projectId: project.id,
      projectPath: project.path,
      sourcePath: '${project.path}/favicon.${format.extension}',
      storedPath: '$key.${format.storageExtension}',
      sourceFormat: format,
      storedFormat: format,
      sourceByteLength: bytes.length,
      storedByteLength: bytes.length,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    bytes: bytes,
  );
}

class _MemoryProjectIconStore implements ProjectIconStore {
  _MemoryProjectIconStore({this.icon});

  ProjectIconData? icon;
  ProjectIconData? saved;
  int readCount = 0;

  @override
  Future<void> deleteIcon(String key) async {
    icon = null;
  }

  @override
  Future<ProjectIconData?> readIcon(String key) async {
    readCount += 1;
    return icon;
  }

  @override
  Future<ProjectIconData> saveIcon({
    required Project project,
    required String key,
    required ProjectIconCandidate candidate,
  }) async {
    saved = ProjectIconData(
      metadata: ProjectIconMetadata(
        key: key,
        projectId: project.id,
        projectPath: project.path,
        sourcePath: candidate.sourcePath,
        storedPath: '$key.${candidate.storedFormat.storageExtension}',
        sourceFormat: candidate.sourceFormat,
        storedFormat: candidate.storedFormat,
        sourceByteLength: candidate.sourceByteLength,
        storedByteLength: candidate.bytes.length,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      bytes: candidate.bytes,
    );
    icon = saved;
    return saved!;
  }
}

class _UnsupportedDiscoveryService implements ProjectIconDiscoveryService {
  const _UnsupportedDiscoveryService();

  @override
  bool get isSupported => false;

  @override
  Future<ProjectIconDiscoveryResult> discover(Project project) async {
    return const ProjectIconDiscoveryResult(
      status: ProjectIconDiscoveryStatus.unsupportedPlatform,
    );
  }
}

class _FakeDiscoveryService implements ProjectIconDiscoveryService {
  const _FakeDiscoveryService(this.result);

  final ProjectIconDiscoveryResult result;

  @override
  bool get isSupported => true;

  @override
  Future<ProjectIconDiscoveryResult> discover(Project project) async => result;
}
