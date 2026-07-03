import 'dart:convert';
import 'dart:io';

import 'package:codewalk/domain/entities/project.dart';
import 'package:codewalk/presentation/services/project_icon_discovery_service_io.dart';
import 'package:codewalk/presentation/services/project_icon_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

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

  test('prefers Flutter Apple app icons over web favicons', () async {
    await Directory(
      '${root.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset',
    ).create(recursive: true);
    await Directory('${root.path}/web').create(recursive: true);
    await File('${root.path}/web/favicon.png').writeAsBytes(<int>[1, 2, 3]);
    await File(
      '${root.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png',
    ).writeAsBytes(<int>[4, 5, 6]);
    await File(
      '${root.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
    ).writeAsBytes(<int>[7, 8, 9]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourcePath, contains('AppIcon.appiconset'));
    expect(result.candidate?.sourcePath, contains('1024x1024'));
  });

  test('prefers Android launcher icons by density', () async {
    await Directory(
      '${root.path}/android/app/src/main/res/mipmap-mdpi',
    ).create(recursive: true);
    await Directory(
      '${root.path}/android/app/src/main/res/mipmap-xxxhdpi',
    ).create(recursive: true);
    await File(
      '${root.path}/android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
    ).writeAsBytes(<int>[1, 2, 3]);
    await File(
      '${root.path}/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    ).writeAsBytes(<int>[4, 5, 6]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourcePath, contains('mipmap-xxxhdpi'));
  });

  test('prefers Tauri app icons over root favicons', () async {
    await Directory('${root.path}/src-tauri/icons').create(recursive: true);
    await File('${root.path}/favicon.png').writeAsBytes(<int>[1, 2, 3]);
    await File(
      '${root.path}/src-tauri/icons/StoreLogo.png',
    ).writeAsBytes(<int>[4, 5, 6]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(
      result.candidate?.sourcePath,
      contains('src-tauri/icons/StoreLogo.png'),
    );
  });

  test('keeps deep canonical favicons as fallback candidates', () async {
    await Directory('${root.path}/packages/app/assets').create(recursive: true);
    await File(
      '${root.path}/packages/app/assets/favicon.png',
    ).writeAsBytes(<int>[1, 2, 3]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(
      result.candidate?.sourcePath,
      contains('packages/app/assets/favicon.png'),
    );
  });

  test('does not treat generic assets as Electron priority', () async {
    await Directory('${root.path}/assets').create(recursive: true);
    await Directory(
      '${root.path}/android/app/src/main/res/mipmap-xxxhdpi',
    ).create(recursive: true);
    await File(
      '${root.path}/assets/icon-72x72.png',
    ).writeAsBytes(<int>[1, 2, 3]);
    await File(
      '${root.path}/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    ).writeAsBytes(<int>[4, 5, 6]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourcePath, contains('mipmap-xxxhdpi'));
  });

  test('does not let numeric directory names affect quality ranking', () async {
    await Directory('${root.path}/web/v2024').create(recursive: true);
    await File('${root.path}/web/favicon.png').writeAsBytes(<int>[1, 2, 3]);
    await File(
      '${root.path}/web/v2024/favicon.png',
    ).writeAsBytes(<int>[4, 5, 6]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourcePath, endsWith('/web/favicon.png'));
  });

  test('discovers Flutter Linux app icons', () async {
    await Directory(
      '${root.path}/linux/runner/resources',
    ).create(recursive: true);
    await File(
      '${root.path}/linux/runner/resources/app_icon.png',
    ).writeAsBytes(<int>[1, 2, 3]);
    await File('${root.path}/favicon.png').writeAsBytes(<int>[4, 5, 6]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(
      result.candidate?.sourcePath,
      contains('linux/runner/resources/app_icon.png'),
    );
  });

  test('discovers nested common app icon variants', () async {
    await Directory('${root.path}/assets/resources').create(recursive: true);
    await File(
      '${root.path}/assets/resources/logo.256.png',
    ).writeAsBytes(<int>[1, 2, 3]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(
      result.candidate?.sourcePath,
      contains('assets/resources/logo.256.png'),
    );
  });

  test('discovers sized icon variants in common asset roots', () async {
    await Directory('${root.path}/assets').create(recursive: true);
    await File('${root.path}/assets/icon-512.png').writeAsBytes(<int>[1, 2, 3]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourcePath, contains('assets/icon-512.png'));
  });

  test('normalizes discovered ico icons to png storage', () async {
    await Directory('${root.path}/build').create(recursive: true);
    final icoBytes = img.encodeIco(
      img.Image(width: 1, height: 1)..setPixelRgba(0, 0, 255, 0, 0, 255),
    );
    await File('${root.path}/build/icon.ico').writeAsBytes(icoBytes);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourceFormat, ProjectIconFormat.ico);
    expect(result.candidate?.storedFormat, ProjectIconFormat.png);
  });

  test('ignores intentionally unsupported icns app icons', () async {
    await Directory('${root.path}/src-tauri/icons').create(recursive: true);
    await File(
      '${root.path}/src-tauri/icons/icon.icns',
    ).writeAsBytes(<int>[1, 2, 3]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.notFound);
  });

  test('checks Electron build icon without traversing build output', () async {
    await Directory('${root.path}/build/deep').create(recursive: true);
    await File('${root.path}/build/icon.png').writeAsBytes(<int>[1, 2, 3]);
    await File(
      '${root.path}/build/deep/favicon.png',
    ).writeAsBytes(<int>[4, 5, 6]);

    const service = ProjectIconDiscoveryServiceIo();
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourcePath, endsWith('/build/icon.png'));
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

  test('discovers root favicon from the OpenCode server', () async {
    final adapter = _ProjectIconDioAdapter()
      ..enqueue(<_ProjectIconDioResponse>[
        const _ProjectIconDioResponse(<Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'favicon.png',
            'path': 'favicon.png',
            'type': 'file',
          },
        ]),
        const _ProjectIconDioResponse(<String>['favicon.png']),
        _ProjectIconDioResponse(<String, dynamic>{
          'type': 'binary',
          'content': base64Encode(<int>[1, 2, 3]),
          'encoding': 'base64',
          'mimeType': 'image/png',
        }),
      ]);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:4096'));
    dio.httpClientAdapter = adapter;

    final service = ProjectIconDiscoveryServiceIo(dio: dio);
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourcePath, endsWith('/favicon.png'));
    expect(result.candidate?.sourceFormat, ProjectIconFormat.png);
    expect(result.candidate?.bytes, <int>[1, 2, 3]);
    expect(adapter.capturedRequests, hasLength(3));
    expect(adapter.capturedRequests[0].path, '/file');
    expect(adapter.capturedRequests[0].queryParameters['directory'], root.path);
    expect(adapter.capturedRequests[1].path, '/find/file');
    expect(adapter.capturedRequests[1].queryParameters['directory'], root.path);
    expect(adapter.capturedRequests[2].path, '/file/content');
    expect(adapter.capturedRequests[2].queryParameters['path'], 'favicon.png');
  });

  test('discovers sized web favicons from the OpenCode server', () async {
    final adapter = _ProjectIconDioAdapter()
      ..enqueue(<_ProjectIconDioResponse>[
        const _ProjectIconDioResponse(<Map<String, dynamic>>[]),
        const _ProjectIconDioResponse(<String>['public/favicon-32x32.png']),
        _ProjectIconDioResponse(<String, dynamic>{
          'type': 'binary',
          'content': base64Encode(<int>[10, 11, 12]),
          'encoding': 'base64',
          'mimeType': 'image/png',
        }),
      ]);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:4096'));
    dio.httpClientAdapter = adapter;

    final service = ProjectIconDiscoveryServiceIo(dio: dio);
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourcePath, endsWith('/public/favicon-32x32.png'));
    expect(result.candidate?.bytes, <int>[10, 11, 12]);
    expect(
      adapter.capturedRequests[2].queryParameters['path'],
      'public/favicon-32x32.png',
    );
  });

  test('keeps local discovery when a local icon is available', () async {
    await File('${root.path}/favicon.png').writeAsBytes(<int>[4, 5, 6]);
    final adapter = _ProjectIconDioAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:4096'));
    dio.httpClientAdapter = adapter;

    final service = ProjectIconDiscoveryServiceIo(dio: dio);
    final result = await service.discover(project());

    expect(result.status, ProjectIconDiscoveryStatus.found);
    expect(result.candidate?.sourcePath, endsWith('/favicon.png'));
    expect(result.candidate?.bytes, <int>[4, 5, 6]);
    expect(adapter.capturedRequests, isEmpty);
  });

  test(
    'tries the next remote favicon when one remote candidate is empty',
    () async {
      final adapter = _ProjectIconDioAdapter()
        ..enqueue(<_ProjectIconDioResponse>[
          const _ProjectIconDioResponse(<Map<String, dynamic>>[]),
          const _ProjectIconDioResponse(<String>[
            'favicon.png',
            'public/favicon.png',
          ]),
          const _ProjectIconDioResponse(<String, dynamic>{
            'type': 'text',
            'content': '',
          }),
          _ProjectIconDioResponse(<String, dynamic>{
            'type': 'binary',
            'content': base64Encode(<int>[7, 8, 9]),
            'encoding': 'base64',
            'mimeType': 'image/png',
          }),
        ]);
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:4096'));
      dio.httpClientAdapter = adapter;

      final service = ProjectIconDiscoveryServiceIo(dio: dio);
      final result = await service.discover(project());

      expect(result.status, ProjectIconDiscoveryStatus.found);
      expect(result.candidate?.sourcePath, endsWith('/public/favicon.png'));
      expect(result.candidate?.bytes, <int>[7, 8, 9]);
      expect(adapter.capturedRequests, hasLength(4));
      expect(
        adapter.capturedRequests[2].queryParameters['path'],
        'favicon.png',
      );
      expect(
        adapter.capturedRequests[3].queryParameters['path'],
        'public/favicon.png',
      );
    },
  );
}

class _ProjectIconDioResponse {
  const _ProjectIconDioResponse(this.data);

  final dynamic data;
}

class _ProjectIconDioAdapter implements HttpClientAdapter {
  final List<_ProjectIconDioResponse> _responses = <_ProjectIconDioResponse>[];
  final List<RequestOptions> capturedRequests = <RequestOptions>[];

  void enqueue(List<_ProjectIconDioResponse> responses) {
    _responses.addAll(responses);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedRequests.add(options);
    if (_responses.isEmpty) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'No mock response',
      );
    }
    final response = _responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      200,
      headers: <String, List<String>>{
        'content-type': <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
