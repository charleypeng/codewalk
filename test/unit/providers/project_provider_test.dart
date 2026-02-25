import 'dart:async';
import 'dart:convert';

import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/core/logging/app_logger.dart';
import 'package:codewalk/domain/entities/project.dart';
import 'package:codewalk/domain/entities/worktree.dart';
import 'package:codewalk/presentation/providers/project_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class _DelayedWorktreeProjectRepository extends FakeProjectRepository {
  _DelayedWorktreeProjectRepository({
    required super.currentProject,
    required super.projects,
    required super.worktrees,
  });

  Completer<void>? pendingWorktreeGate;

  @override
  Future<Either<Failure, List<Worktree>>> getWorktrees({
    String? directory,
  }) async {
    final gate = pendingWorktreeGate;
    if (gate != null) {
      await gate.future;
    }
    return super.getWorktrees(directory: directory);
  }
}

class _CollidingDirectoryProjectRepository extends FakeProjectRepository {
  _CollidingDirectoryProjectRepository({
    required super.currentProject,
    required super.projects,
  });

  @override
  Future<Either<Failure, Project>> getCurrentProject({
    String? directory,
  }) async {
    if (directory != null && directory.trim().isNotEmpty) {
      final normalized = directory.trim();
      return Right(
        Project(
          id: 'project',
          name: 'Directory',
          path: normalized,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    }
    return super.getCurrentProject(directory: directory);
  }
}

void main() {
  group('ProjectProvider', () {
    late InMemoryAppLocalDataSource localDataSource;
    late FakeProjectRepository projectRepository;
    late ProjectProvider provider;

    setUp(() {
      AppLogger.clearEntries();
      localDataSource = InMemoryAppLocalDataSource()
        ..activeServerId = 'srv_test';
      projectRepository = FakeProjectRepository(
        currentProject: Project(
          id: 'proj_a',
          name: 'Project A',
          path: '/repo/a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        projects: <Project>[
          Project(
            id: 'proj_a',
            name: 'Project A',
            path: '/repo/a',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
          Project(
            id: 'proj_b',
            name: 'Project B',
            path: '/repo/b',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1),
          ),
        ],
        worktrees: const <Worktree>[
          Worktree(
            id: 'wt_1',
            name: 'Workspace A',
            directory: '/repo/a/workspace-a',
            projectId: 'proj_a',
          ),
        ],
      );
      provider = ProjectProvider(
        projectRepository: projectRepository,
        localDataSource: localDataSource,
      );
    });

    tearDown(AppLogger.clearEntries);

    test('initializeProject restores scoped current project id', () async {
      await localDataSource.saveCurrentProjectId(
        'proj_b',
        serverId: 'srv_test',
      );
      await localDataSource.saveOpenProjectIdsJson(
        jsonEncode(<String>['proj_b']),
        serverId: 'srv_test',
      );

      await provider.initializeProject();

      expect(provider.status, ProjectStatus.loaded);
      expect(provider.currentProject?.id, 'proj_b');
      expect(provider.openProjectIds, contains('proj_b'));
      expect(provider.contextKey, 'srv_test::/repo/b');
    });

    test(
      'switchProject persists scoped selection and keeps context open',
      () async {
        await provider.initializeProject();

        final changed = await provider.switchProject('proj_b');

        expect(changed, isTrue);
        expect(provider.currentProject?.id, 'proj_b');
        expect(
          provider.openProjectIds,
          containsAll(<String>['proj_a', 'proj_b']),
        );
        expect(
          localDataSource.scopedStrings['current_project_id::srv_test'],
          'proj_b',
        );
      },
    );

    test('switchProject does not block while worktrees refresh', () async {
      final delayedRepository = _DelayedWorktreeProjectRepository(
        currentProject: Project(
          id: 'proj_a',
          name: 'Project A',
          path: '/repo/a',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        projects: <Project>[
          Project(
            id: 'proj_a',
            name: 'Project A',
            path: '/repo/a',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
          Project(
            id: 'proj_b',
            name: 'Project B',
            path: '/repo/b',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1),
          ),
        ],
        worktrees: const <Worktree>[
          Worktree(
            id: 'wt_1',
            name: 'Workspace A',
            directory: '/repo/a/workspace-a',
            projectId: 'proj_a',
          ),
        ],
      );
      provider = ProjectProvider(
        projectRepository: delayedRepository,
        localDataSource: localDataSource,
      );

      await provider.initializeProject();

      final gate = Completer<void>();
      delayedRepository.pendingWorktreeGate = gate;

      final switched = await provider
          .switchProject('proj_b')
          .timeout(const Duration(milliseconds: 80), onTimeout: () => false);

      expect(switched, isTrue);
      expect(provider.currentProject?.id, 'proj_b');

      gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 1));
    });

    test(
      'close and reopen context updates open lists deterministically',
      () async {
        await provider.initializeProject();
        await provider.switchProject('proj_b');

        final closed = await provider.closeProject('proj_a');
        expect(closed, isTrue);
        expect(provider.openProjectIds, isNot(contains('proj_a')));

        final reopened = await provider.reopenProject(
          'proj_a',
          makeActive: false,
        );
        expect(reopened, isTrue);
        expect(provider.openProjectIds, contains('proj_a'));
        expect(provider.currentProject?.id, 'proj_b');
      },
    );

    test(
      'archiveClosedProject hides project from closed list and persists',
      () async {
        await provider.initializeProject();
        await provider.switchProject('proj_b');
        await provider.closeProject('proj_a');

        expect(
          provider.closedProjects.any((project) => project.id == 'proj_a'),
          isTrue,
        );

        final archived = await provider.archiveClosedProject('proj_a');
        expect(archived, isTrue);
        expect(
          provider.closedProjects.any((project) => project.id == 'proj_a'),
          isFalse,
        );
        expect(provider.archivedProjectIds, contains('proj_a'));
        expect(
          localDataSource.scopedStrings['archived_project_ids::srv_test'],
          isNotNull,
        );
      },
    );

    test('worktree operations load/create/reset/delete', () async {
      await provider.initializeProject();

      await provider.loadWorktrees();
      expect(provider.worktreeSupported, isTrue);
      expect(provider.worktrees, hasLength(1));

      final created = await provider.createWorktree('Feature Branch');
      expect(created, isNotNull);

      final resetOk = await provider.resetWorktree(created!.id);
      expect(resetOk, isTrue);

      final deleteOk = await provider.deleteWorktree(created.id);
      expect(deleteOk, isTrue);
      expect(
        provider.projects.any((item) => item.path == created.directory),
        isFalse,
      );
      expect(provider.currentProject?.path, isNot(created.directory));
    });

    test('listDirectories returns sorted unique directories', () async {
      projectRepository.directoriesByPath['/repo/a'] = <String>[
        '/repo/a/zeta',
        '/repo/a/Alpha',
        '/repo/a/alpha',
      ];

      final listed = await provider.listDirectories('/repo/a');

      expect(listed, isNotNull);
      expect(listed, hasLength(3));
      expect(listed!.first, '/repo/a/Alpha');
    });

    test('isGitDirectory returns true for configured git path', () async {
      projectRepository.gitDirectories.add('/repo/a');

      final isGit = await provider.isGitDirectory('/repo/a');

      expect(isGit, isTrue);
    });

    test('switchToDirectoryContext switches to matching directory', () async {
      await provider.initializeProject();

      final switched = await provider.switchToDirectoryContext('/repo/b');

      expect(switched, isTrue);
      expect(provider.currentProject?.path, '/repo/b');
    });

    test(
      'switchToDirectoryContext creates directory fallback when server keeps current project',
      () async {
        await provider.initializeProject();

        final switched = await provider.switchToDirectoryContext('/repo/plain');

        expect(switched, isTrue);
        expect(provider.currentProject?.path, '/repo/plain');
        expect(provider.currentProject?.id, 'dir::/repo/plain');
        expect(
          provider.projects.any((project) => project.path == '/repo/plain'),
          isTrue,
        );
      },
    );

    test(
      'switchToDirectoryContext keeps previously opened non-git directories',
      () async {
        await provider.initializeProject();

        final switchedFirst = await provider.switchToDirectoryContext(
          '/repo/plain-a',
        );
        final switchedSecond = await provider.switchToDirectoryContext(
          '/repo/plain-b',
        );

        expect(switchedFirst, isTrue);
        expect(switchedSecond, isTrue);
        expect(
          provider.openProjectIds,
          containsAll(<String>['dir::/repo/plain-a', 'dir::/repo/plain-b']),
        );
        expect(provider.openProjectIds, isNot(contains('project')));
        expect(
          provider.openProjects.map((item) => item.path),
          containsAll(<String>['/repo/plain-a', '/repo/plain-b']),
        );
      },
    );

    test(
      'initializeProject migrates legacy generic open id to synthetic directory id',
      () async {
        projectRepository = _CollidingDirectoryProjectRepository(
          currentProject: Project(
            id: 'project',
            name: 'Directory',
            path: '/repo/plain-a',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
          projects: <Project>[
            Project(
              id: 'proj_a',
              name: 'Project A',
              path: '/repo/a',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          ],
        );
        provider = ProjectProvider(
          projectRepository: projectRepository,
          localDataSource: localDataSource,
        );
        await localDataSource.saveCurrentProjectId(
          'project',
          serverId: 'srv_test',
        );
        await localDataSource.saveOpenProjectIdsJson(
          jsonEncode(<String>['project']),
          serverId: 'srv_test',
        );

        await provider.initializeProject();

        expect(provider.openProjectIds, contains('dir::/repo/plain-a'));
        expect(
          provider.openProjects.any((item) => item.path == '/repo/plain-a'),
          isTrue,
        );
      },
    );

    test(
      'switchToDirectoryContext handles server id collisions per directory',
      () async {
        projectRepository = _CollidingDirectoryProjectRepository(
          currentProject: Project(
            id: 'project',
            name: 'Project',
            path: '/repo/a',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
          projects: <Project>[
            Project(
              id: 'project',
              name: 'Project',
              path: '/repo/a',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          ],
        );
        provider = ProjectProvider(
          projectRepository: projectRepository,
          localDataSource: localDataSource,
        );

        await provider.initializeProject();
        await provider.switchToDirectoryContext('/repo/plain-a');
        await provider.switchToDirectoryContext('/repo/plain-b');

        expect(
          provider.openProjectIds,
          containsAll(<String>['dir::/repo/plain-a', 'dir::/repo/plain-b']),
        );
        expect(
          provider.openProjects.map((item) => item.path),
          containsAll(<String>['/repo/plain-a', '/repo/plain-b']),
        );
      },
    );

    test(
      'switchToDirectoryContext returns false when directory is unchanged',
      () async {
        await provider.initializeProject();

        final switched = await provider.switchToDirectoryContext('/repo/a');

        expect(switched, isFalse);
        expect(provider.currentProject?.path, '/repo/a');
      },
    );

    test(
      'switchToDirectoryContext treats trailing slash as unchanged directory',
      () async {
        await provider.initializeProject();

        final switched = await provider.switchToDirectoryContext('/repo/a/');

        expect(switched, isFalse);
        expect(provider.currentProject?.path, '/repo/a');
      },
    );

    test(
      'switchToDirectoryContext normalizes synthetic directory id to avoid duplicates',
      () async {
        await provider.initializeProject();

        final switchedFirst = await provider.switchToDirectoryContext(
          '/repo/plain-a/',
        );
        final switchedSecond = await provider.switchToDirectoryContext(
          '/repo/plain-a',
        );

        expect(switchedFirst, isTrue);
        expect(switchedSecond, isFalse);
        expect(provider.openProjectIds, contains('dir::/repo/plain-a'));
        expect(provider.openProjectIds, isNot(contains('dir::/repo/plain-a/')));
      },
    );

    test(
      'initializeProject preserves in-memory server scope when storage is temporarily empty',
      () async {
        await provider.initializeProject();
        expect(provider.activeServerId, 'srv_test');

        localDataSource.activeServerId = null;
        await provider.initializeProject(forceReload: true);

        expect(provider.activeServerId, 'srv_test');
      },
    );

    test('listDirectories surfaces errors and logs them', () async {
      projectRepository.directoryFailure = const NetworkFailure(
        'Client error',
        400,
      );

      final listed = await provider.listDirectories('/repo/a');

      expect(listed, isNull);
      expect(provider.error, 'Failed to list directories: Client error');
      expect(
        AppLogger.entries.value.any(
          (entry) => entry.message.contains('Directory list failed'),
        ),
        isTrue,
      );
    });

    test('logs workspace create failure in app logger', () async {
      await provider.initializeProject();
      projectRepository.worktreeFailure = const NetworkFailure(
        'Client error',
        400,
      );

      final created = await provider.createWorktree(
        'Feature Broken',
        directory: '/repo/a',
      );

      expect(created, isNull);
      expect(provider.error, 'Failed to create workspace: Client error');
      expect(
        AppLogger.entries.value.any(
          (entry) => entry.message.contains('Workspace create failed'),
        ),
        isTrue,
      );
      expect(
        AppLogger.entries.value.any(
          (entry) => entry.message.contains('Failed to create workspace'),
        ),
        isTrue,
      );
    });

    test('filters synthetic root project when real contexts exist', () async {
      final rootProject = Project(
        id: '/',
        name: '/',
        path: '/',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      projectRepository = FakeProjectRepository(
        currentProject: rootProject,
        projects: <Project>[
          rootProject,
          Project(
            id: 'proj_real',
            name: 'Project Real',
            path: '/repo/real',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1),
          ),
        ],
      );
      provider = ProjectProvider(
        projectRepository: projectRepository,
        localDataSource: localDataSource,
      );

      await provider.initializeProject();

      expect(provider.projects.map((item) => item.id), isNot(contains('/')));
      expect(provider.currentProject?.id, 'proj_real');
      expect(provider.currentDirectory, '/repo/real');
    });

    test(
      'treats global root project as placeholder when real contexts exist',
      () async {
        final globalProject = Project(
          id: 'global',
          name: 'Global',
          path: '/',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        );
        projectRepository = FakeProjectRepository(
          currentProject: globalProject,
          projects: <Project>[
            globalProject,
            Project(
              id: 'proj_real',
              name: 'Project Real',
              path: '/repo/real',
              createdAt: DateTime.fromMillisecondsSinceEpoch(1),
            ),
          ],
        );
        provider = ProjectProvider(
          projectRepository: projectRepository,
          localDataSource: localDataSource,
        );

        await provider.initializeProject();

        expect(
          provider.projects.map((item) => item.id),
          isNot(contains('global')),
        );
        expect(provider.currentProject?.id, 'proj_real');
        expect(provider.currentDirectory, '/repo/real');
      },
    );

    test(
      'root path uses project id as scope and no directory filter',
      () async {
        projectRepository = FakeProjectRepository(
          currentProject: Project(
            id: 'proj_root',
            name: 'Root',
            path: '/',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
          projects: <Project>[
            Project(
              id: 'proj_root',
              name: 'Root',
              path: '/',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          ],
        );
        provider = ProjectProvider(
          projectRepository: projectRepository,
          localDataSource: localDataSource,
        );

        await provider.initializeProject();

        expect(provider.currentDirectory, isNull);
        expect(provider.currentScopeId, 'proj_root');
        expect(provider.contextKey, 'srv_test::proj_root');
      },
    );
  });
}
