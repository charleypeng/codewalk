import 'package:codewalk/core/errors/failures.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/chat_session.dart';
import 'package:codewalk/domain/entities/project.dart';
import 'package:codewalk/domain/usecases/get_chat_messages.dart';
import 'package:codewalk/domain/usecases/get_chat_sessions.dart';
import 'package:codewalk/domain/usecases/revert_chat_message.dart';
import 'package:codewalk/domain/usecases/send_chat_message.dart';
import 'package:codewalk/presentation/providers/app_provider.dart';
import 'package:codewalk/presentation/services/forward_message_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class _FakeForwardContext implements ForwardServiceContext {
  _FakeForwardContext({
    this.health = ServerHealthStatus.healthy,
    this.projects = const <Project>[],
  });

  ServerHealthStatus health;
  List<Project> projects;

  @override
  String? get activeServerId => 'srv-1';

  @override
  ServerHealthStatus serverHealth(String serverId) => health;

  @override
  List<Project> get openProjects => projects;

  @override
  String get currentProjectId => 'default';
}

Project _project({required String id, required String name, String? path}) {
  return Project(
    id: id,
    name: name,
    path: path ?? '/tmp/$id',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

ChatSession _session({
  required String id,
  String? title,
  DateTime? time,
}) {
  return ChatSession(
    id: id,
    workspaceId: 'default',
    time: time ?? DateTime.fromMillisecondsSinceEpoch(0),
    title: title,
  );
}

AssistantMessage _assistantPlaceholder(String sessionId) {
  return AssistantMessage(
    id: 'placeholder_$sessionId',
    sessionId: sessionId,
    time: DateTime.fromMillisecondsSinceEpoch(0),
    parts: const <MessagePart>[],
  );
}

UserMessage _userMessage({
  required String id,
  required String sessionId,
  required String text,
}) {
  return UserMessage(
    id: id,
    sessionId: sessionId,
    time: DateTime.fromMillisecondsSinceEpoch(0),
    parts: <MessagePart>[
      TextPart(
        id: 'prt_$id',
        messageId: id,
        sessionId: sessionId,
        text: text,
      ),
    ],
  );
}

void main() {
  group('ForwardMessageService', () {
    late FakeChatRepository repository;

    setUp(() {
      repository = FakeChatRepository();
    });

    ForwardMessageService buildService(_FakeForwardContext context) {
      return ForwardMessageService.forTesting(
        getChatSessions: GetChatSessions(repository),
        getChatMessages: GetChatMessages(repository),
        sendChatMessage: SendChatMessage(repository),
        revertChatMessage: RevertChatMessage(repository),
        context: context,
      );
    }

    test('loadTargetSessions groups by project and orders by recency',
        () async {
      final projectA = _project(id: 'p1', name: 'Alpha', path: '/tmp/p1');
      final context = _FakeForwardContext(
        projects: <Project>[projectA],
      );

      final oldSession = _session(
        id: 'ses_old',
        title: 'Old',
        time: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final newSession = _session(
        id: 'ses_new',
        title: 'New',
        time: DateTime.fromMillisecondsSinceEpoch(2000),
      );
      repository.sessions.addAll(<ChatSession>[oldSession, newSession]);

      final bundle = await buildService(context).loadTargetSessions();

      expect(bundle.serverReachable, isTrue);
      expect(bundle.totalSessions, 2);
      expect(bundle.groups, hasLength(1));
      final firstGroup = bundle.groups.first;
      expect(firstGroup.sessions.first.id, 'ses_new');
      expect(firstGroup.sessions.last.id, 'ses_old');
    });

    test(
        'loadTargetSessions returns empty groups when active server is unhealthy',
        () async {
      final project = _project(id: 'p1', name: 'Alpha');
      final context = _FakeForwardContext(
        health: ServerHealthStatus.unhealthy,
        projects: <Project>[project],
      );

      final bundle = await buildService(context).loadTargetSessions();
      expect(bundle.serverReachable, isFalse);
      expect(bundle.totalSessions, 0);
      expect(bundle.groups, hasLength(1));
      expect(bundle.groups.first.sessions, isEmpty);
    });

    test(
        'forwardToSessions sends to each target without forwarding a messageId '
        '(ADR-023 P-001)', () async {
      final project = _project(id: 'p1', name: 'Alpha');
      final context = _FakeForwardContext(projects: <Project>[project]);

      final sentSessionIds = <String>[];
      final sentTexts = <String>[];
      final sentMessageIds = <String?>[];

      repository.sendMessageHandler = (
        String projectId,
        String sessionId,
        ChatInput input,
        String? directory,
      ) {
        sentSessionIds.add(sessionId);
        sentTexts.add((input.parts.first as TextInputPart).text);
        sentMessageIds.add(input.messageId);
        return Stream<Either<Failure, ChatMessage>>.value(
          Right<Failure, ChatMessage>(_assistantPlaceholder(sessionId)),
        );
      };
      repository.messagesBySession['ses_a'] = <ChatMessage>[
        _userMessage(id: 'usr_a', sessionId: 'ses_a', text: 'forwarded body'),
      ];
      repository.messagesBySession['ses_b'] = <ChatMessage>[
        _userMessage(id: 'usr_b', sessionId: 'ses_b', text: 'forwarded body'),
      ];

      final result = await buildService(context).forwardToSessions(
        text: 'forwarded body',
        provenanceLine: '> Encaminhado de: Alpha / origin',
        targets: const <ForwardTarget>[
          ForwardTarget(sessionId: 'ses_a', directory: '/tmp/p1'),
          ForwardTarget(sessionId: 'ses_b', directory: '/tmp/p1'),
        ],
        selection: const ForwardSelection(
          providerId: 'prov',
          modelId: 'model',
        ),
      );

      expect(result.isFullSuccess, isTrue);
      expect(sentSessionIds, <String>['ses_a', 'ses_b']);
      expect(sentTexts.first, contains('forwarded body'));
      expect(sentTexts.first, contains('Encaminhado de: Alpha / origin'));
      // ADR-023 Pitfall P-001: messageId MUST NOT be forwarded to
      // prompt_async. Forwarding the local optimistic id breaks SSE
      // event stream reconciliation in the target session.
      expect(sentMessageIds, everyElement(isNull));
      expect(result.successes, hasLength(2));
      expect(result.successes[0].sessionId, 'ses_a');
      expect(result.successes[0].userMessageId, 'usr_a');
    });

    test('forwardToSessions records per-target failures with typed reasons',
        () async {
      final project = _project(id: 'p1', name: 'Alpha');
      final context = _FakeForwardContext(projects: <Project>[project]);

      repository.sendMessageHandler = (
        String projectId,
        String sessionId,
        ChatInput input,
        String? directory,
      ) {
        if (sessionId == 'ses_fail') {
          return Stream<Either<Failure, ChatMessage>>.value(
            const Left<Failure, ChatMessage>(ServerFailure('boom', 500)),
          );
        }
        return Stream<Either<Failure, ChatMessage>>.value(
          Right<Failure, ChatMessage>(_assistantPlaceholder(sessionId)),
        );
      };
      repository.messagesBySession['ses_ok'] = <ChatMessage>[
        _userMessage(id: 'usr_ok', sessionId: 'ses_ok', text: 'ok'),
      ];

      final result = await buildService(context).forwardToSessions(
        text: 'body',
        provenanceLine: '> Encaminhado',
        targets: const <ForwardTarget>[
          ForwardTarget(sessionId: 'ses_ok', directory: '/tmp/p1'),
          ForwardTarget(sessionId: 'ses_fail', directory: '/tmp/p1'),
        ],
        selection: const ForwardSelection(providerId: 'p', modelId: 'm'),
      );

      expect(result.successes, hasLength(1));
      expect(result.failures, hasLength(1));
      expect(result.failures.first.target.sessionId, 'ses_fail');
      expect(result.failures.first.reason, ForwardFailureReason.send);
      expect(result.failures.first.error, isA<ServerFailure>());
    });

    test(
        'forwardToSessions reports undoUnresolved when the message is sent '
        'but the user message id cannot be resolved', () async {
      final project = _project(id: 'p1', name: 'Alpha');
      final context = _FakeForwardContext(projects: <Project>[project]);

      repository.sendMessageHandler = (
        String projectId,
        String sessionId,
        ChatInput input,
        String? directory,
      ) {
        return Stream<Either<Failure, ChatMessage>>.value(
          Right<Failure, ChatMessage>(_assistantPlaceholder(sessionId)),
        );
      };
      // Note: no entry in messagesBySession for ses_orphan — the service
      // must NOT surface this as a send failure (it would be retried and
      // duplicate the message). It must surface it as undoUnresolved so
      // the UI hides the retry action.
      repository.messagesBySession.remove('ses_orphan');

      final result = await buildService(context).forwardToSessions(
        text: 'body',
        provenanceLine: '> Encaminhado',
        targets: const <ForwardTarget>[
          ForwardTarget(sessionId: 'ses_orphan', directory: '/tmp/p1'),
        ],
        selection: const ForwardSelection(providerId: 'p', modelId: 'm'),
      );

      expect(result.successes, isEmpty);
      expect(result.failures, hasLength(1));
      expect(result.failures.first.reason,
          ForwardFailureReason.undoUnresolved);
      // undoUnresolved failures must NOT be retryable — a retry would
      // duplicate the already-sent message in the target session.
      expect(result.retryableFailures, isEmpty);
    });

    test('undoForward reverts each successful entry and reports the rest',
        () async {
      final context = _FakeForwardContext();
      final service = buildService(context);

      repository.revertMessageFailure = const ServerFailure('oops', 500);

      final failed = await service.undoForward(const <UndoForwardEntry>[
        UndoForwardEntry(sessionId: 'ses_a', userMessageId: 'usr_a'),
      ]);

      expect(failed, hasLength(1));
      expect(repository.lastRevertSessionId, 'ses_a');
      expect(repository.lastRevertMessageId, 'usr_a');
    });
  });
}
