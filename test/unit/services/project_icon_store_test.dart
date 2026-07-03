import 'dart:io';
import 'dart:typed_data';

import 'package:codewalk/domain/entities/project.dart';
import 'package:codewalk/presentation/services/project_icon_models.dart';
import 'package:codewalk/presentation/services/project_icon_store_base.dart';
import 'package:codewalk/presentation/services/project_icon_store_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory root;
  late ProjectIconStoreIo store;
  late Project project;

  setUp(() {
    root = Directory.systemTemp.createTempSync('codewalk_project_icon_store_');
    store = ProjectIconStoreIo(rootDirectory: root);
    project = Project(
      id: 'project_1',
      name: 'Project',
      path: '/repo/project',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('saves and reads project icon metadata and bytes', () async {
    final candidate = projectIconCandidateForTest(
      sourcePath: '/repo/project/favicon.svg',
      bytes: Uint8List.fromList('<svg />'.codeUnits),
      format: ProjectIconFormat.svg,
    );
    final key = projectIconKeyFor(project);

    final saved = await store.saveIcon(
      project: project,
      key: key,
      candidate: candidate,
    );
    final loaded = await store.readIcon(key);

    expect(saved.metadata.key, key);
    expect(saved.metadata.sourcePath, '/repo/project/favicon.svg');
    expect(loaded?.metadata.storedFormat, ProjectIconFormat.svg);
    expect(loaded?.bytes, candidate.bytes);
  });

  test('replaces old stored file when storage format changes', () async {
    final key = projectIconKeyFor(project);
    final svgCandidate = projectIconCandidateForTest(
      sourcePath: '/repo/project/favicon.svg',
      bytes: Uint8List.fromList('<svg />'.codeUnits),
      format: ProjectIconFormat.svg,
    );
    final pngCandidate = projectIconCandidateForTest(
      sourcePath: '/repo/project/favicon.ico',
      bytes: Uint8List.fromList(<int>[137, 80, 78, 71]),
      format: ProjectIconFormat.ico,
    );

    final first = await store.saveIcon(
      project: project,
      key: key,
      candidate: svgCandidate,
    );
    expect(File(first.metadata.storedPath).existsSync(), isTrue);

    final second = await store.saveIcon(
      project: project,
      key: key,
      candidate: pngCandidate,
    );

    expect(File(first.metadata.storedPath).existsSync(), isFalse);
    expect(File(second.metadata.storedPath).existsSync(), isTrue);
    expect(second.metadata.storedFormat, ProjectIconFormat.png);
  });

  test('repairs legacy animated ico png cache on read', () async {
    final key = projectIconKeyFor(project);
    await Directory('${root.path}/source').create(recursive: true);
    final sourceIcoPath = '${root.path}/source/favicon.ico';
    final small = img.Image(width: 16, height: 16)
      ..setPixelRgba(0, 0, 255, 0, 0, 255)
      ..frameType = img.FrameType.sequence;
    final large = img.Image(width: 32, height: 32)
      ..setPixelRgba(0, 0, 0, 255, 0, 255);
    small.addFrame(large);
    await File(sourceIcoPath).writeAsBytes(img.encodeIco(small));
    final animatedPng = Uint8List.fromList(img.encodePng(small));

    final saved = await store.saveIcon(
      project: project,
      key: key,
      candidate: projectIconCandidateForTest(
        sourcePath: sourceIcoPath,
        bytes: animatedPng,
        format: ProjectIconFormat.ico,
      ),
    );
    final loaded = await store.readIcon(key);
    final decoded = img.decodePng(loaded!.bytes);
    final fileDecoded = img.decodePng(
      await File(saved.metadata.storedPath).readAsBytes(),
    );

    expect(saved.metadata.sourceFormat, ProjectIconFormat.ico);
    expect(saved.metadata.storedFormat, ProjectIconFormat.png);
    expect(decoded?.numFrames, 1);
    expect(decoded?.width, 32);
    expect(decoded?.height, 32);
    expect(fileDecoded?.numFrames, 1);
  });

  test(
    'collapses legacy animated ico png cache when source is missing',
    () async {
      final key = projectIconKeyFor(project);
      final first = img.Image(width: 16, height: 16)
        ..setPixelRgba(0, 0, 255, 0, 0, 255)
        ..frameType = img.FrameType.sequence;
      final second = img.Image(width: 16, height: 16)
        ..setPixelRgba(0, 0, 0, 255, 0, 255);
      first.addFrame(second);
      final animatedPng = Uint8List.fromList(img.encodePng(first));

      final saved = await store.saveIcon(
        project: project,
        key: key,
        candidate: projectIconCandidateForTest(
          sourcePath: '${root.path}/missing/favicon.ico',
          bytes: animatedPng,
          format: ProjectIconFormat.ico,
        ),
      );
      final loaded = await store.readIcon(key);
      final decoded = img.decodePng(loaded!.bytes);
      final fileDecoded = img.decodePng(
        await File(saved.metadata.storedPath).readAsBytes(),
      );

      expect(decoded?.numFrames, 1);
      expect(fileDecoded?.numFrames, 1);
    },
  );

  test('serializes concurrent metadata updates', () async {
    final projects = List<Project>.generate(4, (index) {
      return Project(
        id: 'project_$index',
        name: 'Project $index',
        path: '/repo/project_$index',
        createdAt: DateTime.fromMillisecondsSinceEpoch(index),
      );
    });

    await Future.wait(
      projects.map((item) {
        return store.saveIcon(
          project: item,
          key: projectIconKeyFor(item),
          candidate: projectIconCandidateForTest(
            sourcePath: '${item.path}/favicon.svg',
            bytes: Uint8List.fromList('<svg>${item.id}</svg>'.codeUnits),
            format: ProjectIconFormat.svg,
          ),
        );
      }),
    );

    for (final item in projects) {
      final loaded = await store.readIcon(projectIconKeyFor(item));
      expect(loaded?.metadata.projectId, item.id);
    }
  });
}
