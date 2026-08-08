import 'package:codewalk/presentation/providers/chat_provider.dart';
import 'package:codewalk/presentation/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'chat_provider_test_support.dart';

void main() {
  group('empty project enters the new chat draft', () {
    late FakeChatRepository chatRepository;
    late FakeAppRepository appRepository;
    late InMemoryAppLocalDataSource localDataSource;
    late SettingsProvider defaultSettingsProvider;

    setUp(() async {
      final fixtures = await buildDefaultTestFixtures();
      chatRepository = fixtures.chatRepository;
      appRepository = fixtures.appRepository;
      localDataSource = fixtures.localDataSource;
      defaultSettingsProvider = fixtures.defaultSettingsProvider;
    });

    ChatProvider build() => buildChatProvider(
      chatRepository: chatRepository,
      appRepository: appRepository,
      localDataSource: localDataSource,
      defaultSettingsProvider: defaultSettingsProvider,
    );

    test('a project without sessions drafts automatically', () async {
      chatRepository.sessions.clear();
      final provider = build();
      addTearDown(provider.dispose);

      await provider.loadSessions();
      await Future<void>.delayed(Duration.zero);

      // The composer becomes usable without the redundant "New chat" gate.
      expect(provider.isDraftingNewChat, isTrue);
      // And nothing was created remotely just by opening the project.
      expect(provider.currentSession, isNull);
      expect(chatRepository.sessions, isEmpty);
    });

    test('a project with sessions is left alone', () async {
      final provider = build();
      addTearDown(provider.dispose);

      await provider.loadSessions();
      await Future<void>.delayed(Duration.zero);

      expect(provider.sessions, isNotEmpty);
      expect(provider.isDraftingNewChat, isFalse);
    });

    test(
      'an authoritative empty load does not clobber an existing draft',
      () async {
        chatRepository.sessions.clear();
        final provider = build();
        addTearDown(provider.dispose);

        await provider.beginNewChatDraft();
        expect(provider.isDraftingNewChat, isTrue);

        await provider.loadSessions();
        await Future<void>.delayed(Duration.zero);

        expect(provider.isDraftingNewChat, isTrue);
        expect(provider.currentSession, isNull);
      },
    );
  });
}
