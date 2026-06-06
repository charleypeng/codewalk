import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:codewalk/data/datasources/terminal_remote_datasource.dart';
import 'package:codewalk/data/models/pty_session_model.dart';
import 'package:codewalk/domain/entities/server_profile.dart';
import 'package:codewalk/presentation/services/codewalk_terminal_controller.dart';
import 'package:codewalk/presentation/services/codewalk_terminal_socket.dart';

class FakeTerminalRemoteDataSource implements TerminalRemoteDataSource {
  int createPtyCount = 0;
  int deletePtyCount = 0;
  int resizePtyCount = 0;
  String? lastCreatedPtyId;
  String? lastDeletedPtyId;
  String? lastResizedPtyId;
  int? lastResizedRows;
  int? lastResizedCols;
  bool shouldThrowOnResize = false;

  @override
  Future<PtySessionModel> createPty({required String directory}) async {
    createPtyCount++;
    final ptyId = 'pty_$createPtyCount';
    lastCreatedPtyId = ptyId;
    return PtySessionModel(
      id: ptyId,
      title: 'Fake Title',
      command: 'sh',
      args: const [],
      cwd: directory,
      status: 'active',
      pid: 1234,
    );
  }

  @override
  Future<void> deletePty({required String ptyId, required String directory}) async {
    deletePtyCount++;
    lastDeletedPtyId = ptyId;
  }

  @override
  Future<void> resizePty({
    required String ptyId,
    required String directory,
    required int rows,
    required int cols,
  }) async {
    resizePtyCount++;
    lastResizedPtyId = ptyId;
    lastResizedRows = rows;
    lastResizedCols = cols;
    if (shouldThrowOnResize) {
      throw Exception('Resize failed simulated');
    }
  }
}

class FakeCodewalkTerminalSocketConnection implements CodewalkTerminalSocketConnection {
  final _messageController = StreamController<List<int>>.broadcast();
  final _doneCompleter = Completer<void>();
  final List<List<int>> sentData = [];
  bool isClosed = false;

  @override
  Stream<List<int>> get messages => _messageController.stream;

  @override
  Future<void> get done => _doneCompleter.future;

  @override
  void send(List<int> data) {
    sentData.add(data);
  }

  @override
  Future<void> close() async {
    if (isClosed) return;
    isClosed = true;
    await _messageController.close();
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }

  void emitBytes(List<int> bytes) {
    _messageController.add(bytes);
  }

  void emitError(Object error) {
    _messageController.addError(error);
  }
}

void main() {
  group('CodewalkTerminalController Unit Tests', () {
    late FakeTerminalRemoteDataSource remoteDataSource;
    late ServerProfile serverProfile;
    late FakeCodewalkTerminalSocketConnection latestSocketConnection;

    setUp(() {
      remoteDataSource = FakeTerminalRemoteDataSource();
      serverProfile = const ServerProfile(
        id: 'srv_1',
        url: 'http://localhost:4096',
        createdAt: 0,
        updatedAt: 0,
      );
    });

    Future<CodewalkTerminalSocketConnection> socketOpener({
      required Uri url,
      Map<String, String>? headers,
    }) async {
      latestSocketConnection = FakeCodewalkTerminalSocketConnection();
      return latestSocketConnection;
    }

    test('starts shell and creates a new PTY session on first run', () async {
      final controller = CodewalkTerminalController(
        remoteDataSource: remoteDataSource,
        socketOpener: socketOpener,
      );

      expect(controller.state, CodewalkTerminalState.idle);

      await controller.startShell(
        serverProfile: serverProfile,
        workingDirectory: '/home/project',
      );

      expect(remoteDataSource.createPtyCount, 1);
      expect(controller.state, CodewalkTerminalState.starting);
    });

    test('reconnect with force: true deletes current PTY and creates a new one', () async {
      final controller = CodewalkTerminalController(
        remoteDataSource: remoteDataSource,
        socketOpener: socketOpener,
      );

      await controller.startShell(
        serverProfile: serverProfile,
        workingDirectory: '/home/project',
      );

      expect(remoteDataSource.createPtyCount, 1);
      expect(remoteDataSource.deletePtyCount, 0);

      // Trigger a force reconnect
      await controller.startShell(
        serverProfile: serverProfile,
        workingDirectory: '/home/project',
        force: true,
      );

      expect(remoteDataSource.deletePtyCount, 1);
      expect(remoteDataSource.lastDeletedPtyId, 'pty_1');
      expect(remoteDataSource.createPtyCount, 2);
    });

    test('dead exited PTY session is not reused and triggers fresh PTY creation', () async {
      final controller = CodewalkTerminalController(
        remoteDataSource: remoteDataSource,
        socketOpener: socketOpener,
      );

      await controller.startShell(
        serverProfile: serverProfile,
        workingDirectory: '/home/project',
      );

      expect(remoteDataSource.createPtyCount, 1);

      // Simulate connection close -> transition to exited
      await latestSocketConnection.close();
      await Future<void>.delayed(Duration.zero); // yield for microtasks

      expect(controller.state, CodewalkTerminalState.exited);

      // Attempt to restart shell for same directory, non-forced
      await controller.startShell(
        serverProfile: serverProfile,
        workingDirectory: '/home/project',
      );

      // Should delete the old one and create a new one (not reuse)
      expect(remoteDataSource.deletePtyCount, 1);
      expect(remoteDataSource.createPtyCount, 2);
    });

    test('dead failed PTY session is not reused and triggers fresh PTY creation', () async {
      final controller = CodewalkTerminalController(
        remoteDataSource: remoteDataSource,
        socketOpener: socketOpener,
      );

      await controller.startShell(
        serverProfile: serverProfile,
        workingDirectory: '/home/project',
      );

      expect(remoteDataSource.createPtyCount, 1);

      // Simulate connection error -> transition to failed
      latestSocketConnection.emitError(Exception('Socket disconnected unexpectedly'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, CodewalkTerminalState.failed);

      // Attempt to restart shell for same directory, non-forced
      await controller.startShell(
        serverProfile: serverProfile,
        workingDirectory: '/home/project',
      );

      // Should delete the old one and create a new one (not reuse)
      expect(remoteDataSource.deletePtyCount, 1);
      expect(remoteDataSource.createPtyCount, 2);
    });

    test('stateful UTF-8 decoder handles multi-byte characters split across frames', () async {
      final controller = CodewalkTerminalController(
        remoteDataSource: remoteDataSource,
        socketOpener: socketOpener,
      );

      await controller.startShell(
        serverProfile: serverProfile,
        workingDirectory: '/home/project',
      );

      // Euro character (€) is encoded in UTF-8 as 3 bytes: 0xE2, 0x82, 0xAC
      // Emit the first byte
      latestSocketConnection.emitBytes([0xE2]);
      await Future<void>.delayed(Duration.zero);

      // Emit the remaining two bytes
      latestSocketConnection.emitBytes([0x82, 0xAC]);
      await Future<void>.delayed(Duration.zero);

      // Verify the terminal received the reconstructed Euro sign
      expect(controller.terminal.buffer.lines[0].toString(), contains('€'));
    });

    test('swallows resize exceptions during debounced resize on unreachable PTY', () async {
      remoteDataSource.shouldThrowOnResize = true;

      final controller = CodewalkTerminalController(
        remoteDataSource: remoteDataSource,
        socketOpener: socketOpener,
      );

      await controller.startShell(
        serverProfile: serverProfile,
        workingDirectory: '/home/project',
      );

      // Trigger resize through terminal
      controller.terminal.resize(100, 40);

      // Wait past the 80ms debounce window
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(remoteDataSource.resizePtyCount, 1);
      // If we got here without throwing an unhandled async error, the exception was swallowed correctly.
    });
  });
}
