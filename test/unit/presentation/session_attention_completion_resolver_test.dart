import 'dart:async';

import 'package:codewalk/data/session_attention/session_attention_snapshot_file_store.dart';
import 'package:codewalk/data/session_attention/session_attention_snapshot_store.dart';
import 'package:codewalk/domain/entities/chat_message.dart';
import 'package:codewalk/domain/entities/session_attention_overlay/session_attention_models.dart';
import 'package:codewalk/domain/usecases/get_chat_messages.dart';
import 'package:codewalk/presentation/services/session_attention/session_attention_completion_resolver.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class _MemoryKeyStorage implements SessionAttentionSnapshotKeyStorage {
  String? value;
  @override
  Future<void> delete() async => value = null;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
}

class _MemoryFileStore implements SessionAttentionSnapshotFileStore {
  String? value;
  @override
  Future<T> synchronized<T>(Future<T> Function() operation) => operation();
  @override
  Future<void> delete() async => value = null;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> writeAtomically(String value) async => this.value = value;
}

void main() {
  const identity = SessionAttentionIdentity(
    serverId: 'server-a',
    directory: '/repo/a',
    rootSessionId: 'session-a',
  );

  test(
    'fetches only 20 messages and stores latest completed text parts',
    () async {
      final repository = FakeChatRepository();
      repository.messagesBySession['session-a'] = <ChatMessage>[
        AssistantMessage(
          id: 'older',
          sessionId: 'session-a',
          time: DateTime.utc(2026),
          completedTime: DateTime.utc(2026),
          parts: const <MessagePart>[
            TextPart(
              id: 'part-old',
              messageId: 'older',
              sessionId: 'session-a',
              text: 'Old response',
            ),
          ],
        ),
        AssistantMessage(
          id: 'latest',
          sessionId: 'session-a',
          time: DateTime.utc(2026, 1, 2),
          completedTime: DateTime.utc(2026, 1, 2),
          parts: const <MessagePart>[
            TextPart(
              id: 'part-text',
              messageId: 'latest',
              sessionId: 'session-a',
              text: '**Final** response',
            ),
            ReasoningPart(
              id: 'part-secret',
              messageId: 'latest',
              sessionId: 'session-a',
              text: 'private reasoning',
            ),
          ],
        ),
      ];
      final store = SessionAttentionSnapshotStore(
        keyStorage: _MemoryKeyStorage(),
        fileStore: _MemoryFileStore(),
      );
      final resolver = SessionAttentionCompletionResolver(
        getChatMessages: GetChatMessages(repository),
        snapshotStore: store,
        delay: (_) async {},
      );

      final resolved = await resolver.resolve(
        identity: identity,
        title: 'Session',
        projectLabel: 'Project',
        completedAt: DateTime.utc(2026, 1, 2),
      );

      expect(repository.lastGetMessagesLimit, 20);
      expect(resolved?.assistantMessageId, 'latest');
      expect(resolved?.displayText, '**Final** response');
      expect(resolved?.speechText, 'Final response');
      expect(resolved?.displayText, isNot(contains('private reasoning')));
      expect(
        (await store.read()).payload.items.single.assistantMessageId,
        resolved?.assistantMessageId,
      );
    },
  );

  test(
    'keeps an already completed assistant from the current user turn',
    () async {
      final repository = FakeChatRepository();
      repository.messagesBySession['session-a'] = <ChatMessage>[
        AssistantMessage(
          id: 'baseline',
          sessionId: 'session-a',
          time: DateTime.utc(2026, 1, 1),
          completedTime: DateTime.utc(2026, 1, 1),
        ),
        UserMessage(
          id: 'user-current',
          sessionId: 'session-a',
          time: DateTime.utc(2026, 1, 2),
        ),
        AssistantMessage(
          id: 'current-final',
          sessionId: 'session-a',
          time: DateTime.utc(2026, 1, 2, 0, 1),
          completedTime: DateTime.utc(2026, 1, 2, 0, 1),
          parts: const <MessagePart>[
            TextPart(
              id: 'current-text',
              messageId: 'current-final',
              sessionId: 'session-a',
              text: 'Current final response',
            ),
          ],
        ),
      ];
      final resolver = SessionAttentionCompletionResolver(
        getChatMessages: GetChatMessages(repository),
        snapshotStore: SessionAttentionSnapshotStore(
          keyStorage: _MemoryKeyStorage(),
          fileStore: _MemoryFileStore(),
        ),
        delay: (_) async {},
      );

      final resolved = await resolver.resolve(
        identity: identity,
        title: 'Session',
        projectLabel: 'Project',
        completedAt: DateTime.utc(2026, 1, 2, 0, 1),
        baselineAssistantMessageId: 'baseline',
      );

      expect(resolved?.assistantMessageId, 'current-final');
      expect(resolved?.displayText, 'Current final response');
      expect(repository.getMessagesCallCount, 1);
    },
  );

  test('retries bounded delays when completion text is not ready', () async {
    final repository = FakeChatRepository();
    final waits = <Duration>[];
    var calls = 0;
    repository.getMessagesHandler = (_, _, {directory, limit}) async {
      calls += 1;
      if (calls < 4) {
        return const Right(<ChatMessage>[]);
      }
      return Right(<ChatMessage>[
        AssistantMessage(
          id: 'ready',
          sessionId: 'session-a',
          time: DateTime.utc(2026),
          completedTime: DateTime.utc(2026),
        ),
      ]);
    };
    final resolver = SessionAttentionCompletionResolver(
      getChatMessages: GetChatMessages(repository),
      snapshotStore: SessionAttentionSnapshotStore(
        keyStorage: _MemoryKeyStorage(),
        fileStore: _MemoryFileStore(),
      ),
      delay: (duration) async => waits.add(duration),
    );

    await resolver.resolve(
      identity: identity,
      title: 'Session',
      projectLabel: 'Project',
      completedAt: DateTime.utc(2026),
    );

    expect(calls, 4);
    expect(waits, const <Duration>[
      Duration(milliseconds: 500),
      Duration(milliseconds: 1500),
      Duration(seconds: 3),
    ]);
  });

  test('reopen-required transport performs no fetch or overwrite', () async {
    final repository = FakeChatRepository();
    final store = SessionAttentionSnapshotStore(
      keyStorage: _MemoryKeyStorage(),
      fileStore: _MemoryFileStore(),
    );
    final resolver = SessionAttentionCompletionResolver(
      getChatMessages: GetChatMessages(repository),
      snapshotStore: store,
    );

    final result = await resolver.resolve(
      identity: identity,
      title: 'Session',
      projectLabel: 'Project',
      completedAt: DateTime.utc(2026),
      transportCapability: SessionAttentionTransportCapability.reopenRequired,
    );

    expect(result, isNull);
    expect(repository.getMessagesCallCount, 0);
    expect((await store.read()).payload.items, isEmpty);
  });

  test('dismisses a completion without message ID by digest', () async {
    final repository = FakeChatRepository();
    final store = SessionAttentionSnapshotStore(
      keyStorage: _MemoryKeyStorage(),
      fileStore: _MemoryFileStore(),
    );
    final resolver = SessionAttentionCompletionResolver(
      getChatMessages: GetChatMessages(repository),
      snapshotStore: store,
      delay: (_) async {},
    );
    final resolved = await resolver.resolve(
      identity: identity,
      title: 'Session',
      projectLabel: 'Project',
      completedAt: DateTime.utc(2026),
    );

    await resolver.dismissSnapshot(resolved!.snapshotId);
    await resolver.resolve(
      identity: identity,
      title: 'Session',
      projectLabel: 'Project',
      completedAt: DateTime.utc(2026),
    );

    final payload = (await store.read()).payload;
    expect(payload.items, isEmpty);
    expect(
      payload.dismissalTombstones,
      contains('${identity.key}::${resolved.contentDigest}'),
    );
  });

  test('truncates display text by Unicode scalar values', () async {
    final repository = FakeChatRepository();
    final text = List<String>.filled(4001, '😀').join();
    repository.messagesBySession['session-a'] = <ChatMessage>[
      AssistantMessage(
        id: 'long',
        sessionId: 'session-a',
        time: DateTime.utc(2026),
        completedTime: DateTime.utc(2026),
        parts: <MessagePart>[
          TextPart(
            id: 'part-long',
            messageId: 'long',
            sessionId: 'session-a',
            text: text,
          ),
        ],
      ),
    ];
    final resolver = SessionAttentionCompletionResolver(
      getChatMessages: GetChatMessages(repository),
      snapshotStore: SessionAttentionSnapshotStore(
        keyStorage: _MemoryKeyStorage(),
        fileStore: _MemoryFileStore(),
      ),
      delay: (_) async {},
    );

    final resolved = await resolver.resolve(
      identity: identity,
      title: 'Session',
      projectLabel: 'Project',
      completedAt: DateTime.utc(2026),
    );

    expect(resolved?.displayText.runes.length, 4000);
    expect(resolved?.displayTruncated, isTrue);
  });

  test('identity deletion invalidates an in-flight completion write', () async {
    final repository = FakeChatRepository();
    final gate = Completer<void>();
    repository.getMessagesHandler = (_, _, {directory, limit}) async {
      await gate.future;
      return Right(<ChatMessage>[
        AssistantMessage(
          id: 'late',
          sessionId: 'session-a',
          time: DateTime.utc(2026),
          completedTime: DateTime.utc(2026),
        ),
      ]);
    };
    final store = SessionAttentionSnapshotStore(
      keyStorage: _MemoryKeyStorage(),
      fileStore: _MemoryFileStore(),
    );
    final resolver = SessionAttentionCompletionResolver(
      getChatMessages: GetChatMessages(repository),
      snapshotStore: store,
      delay: (_) async {},
    );
    final resolving = resolver.resolve(
      identity: identity,
      title: 'Session',
      projectLabel: 'Project',
      completedAt: DateTime.utc(2026),
    );

    await resolver.removeIdentity(identity);
    gate.complete();

    expect(await resolving, isNull);
    expect((await store.read()).payload.items, isEmpty);
  });

  test(
    'external ownership invalidates an in-flight completion write',
    () async {
      final repository = FakeChatRepository();
      final gate = Completer<void>();
      repository.getMessagesHandler = (_, _, {directory, limit}) async {
        await gate.future;
        return Right(<ChatMessage>[
          AssistantMessage(
            id: 'late',
            sessionId: 'session-a',
            time: DateTime.utc(2026),
            completedTime: DateTime.utc(2026),
          ),
        ]);
      };
      final store = SessionAttentionSnapshotStore(
        keyStorage: _MemoryKeyStorage(),
        fileStore: _MemoryFileStore(),
      );
      final resolver = SessionAttentionCompletionResolver(
        getChatMessages: GetChatMessages(repository),
        snapshotStore: store,
        delay: (_) async {},
      );
      var ownsFallback = true;
      final resolving = resolver.resolve(
        identity: identity,
        title: 'Session',
        projectLabel: 'Project',
        completedAt: DateTime.utc(2026),
        isStillValid: () => ownsFallback,
      );

      ownsFallback = false;
      gate.complete();

      expect(await resolving, isNull);
      expect((await store.read()).payload.items, isEmpty);
    },
  );

  test(
    'existing completion is not replaced by the same stale answer',
    () async {
      final repository = FakeChatRepository();
      final previousMessage = AssistantMessage(
        id: 'previous',
        sessionId: 'session-a',
        time: DateTime.utc(2026),
        completedTime: DateTime.utc(2026),
        parts: const <MessagePart>[
          TextPart(
            id: 'part-previous',
            messageId: 'previous',
            sessionId: 'session-a',
            text: 'Previous answer',
          ),
        ],
      );
      repository.messagesBySession['session-a'] = <ChatMessage>[
        previousMessage,
      ];
      final store = SessionAttentionSnapshotStore(
        keyStorage: _MemoryKeyStorage(),
        fileStore: _MemoryFileStore(),
      );
      final firstResolver = SessionAttentionCompletionResolver(
        getChatMessages: GetChatMessages(repository),
        snapshotStore: store,
        delay: (_) async {},
      );
      await firstResolver.resolve(
        identity: identity,
        title: 'Session',
        projectLabel: 'Project',
        completedAt: DateTime.utc(2026),
      );
      final resolver = SessionAttentionCompletionResolver(
        getChatMessages: GetChatMessages(repository),
        snapshotStore: store,
        delay: (_) async {},
      );
      repository.getMessagesCallCount = 0;

      final resolved = await resolver.resolve(
        identity: identity,
        title: 'Session',
        projectLabel: 'Project',
        completedAt: DateTime.utc(2026, 1, 1, 0, 1),
        baselineAssistantMessageId: 'previous',
      );

      expect(repository.getMessagesCallCount, 4);
      expect(resolved?.assistantMessageId, 'previous');
      expect(
        (await store.read()).payload.items.single.displayText,
        'Previous answer',
      );
    },
  );
}
