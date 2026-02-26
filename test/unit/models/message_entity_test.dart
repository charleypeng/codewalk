import 'package:codewalk/domain/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AssistantMessage equality reflects nested fields', () {
    final first = AssistantMessage(
      id: 'msg-1',
      sessionId: 'ses-1',
      time: const MessageTime(created: 1, completed: 2),
      system: const <String>['system-a'],
      modelId: 'model-a',
      providerId: 'provider-a',
      mode: 'chat',
      path: const MessagePath(cwd: '/cwd', root: '/root'),
      summary: true,
      cost: 1.5,
      tokens: const MessageTokens(
        input: 1,
        output: 2,
        reasoning: 3,
        cache: TokenCache(read: 4, write: 5),
      ),
      error: const UnknownError(message: 'none'),
    );

    final second = AssistantMessage(
      id: 'msg-1',
      sessionId: 'ses-1',
      time: const MessageTime(created: 1, completed: 2),
      system: const <String>['system-a'],
      modelId: 'model-a',
      providerId: 'provider-a',
      mode: 'chat',
      path: const MessagePath(cwd: '/cwd', root: '/root'),
      summary: true,
      cost: 1.5,
      tokens: const MessageTokens(
        input: 1,
        output: 2,
        reasoning: 3,
        cache: TokenCache(read: 4, write: 5),
      ),
      error: const UnknownError(message: 'none'),
    );

    final changed = AssistantMessage(
      id: 'msg-1',
      sessionId: 'ses-1',
      time: const MessageTime(created: 1, completed: 2),
      system: const <String>['system-b'],
      modelId: 'model-a',
      providerId: 'provider-a',
      mode: 'chat',
      path: const MessagePath(cwd: '/cwd', root: '/root'),
      summary: true,
      cost: 1.5,
      tokens: const MessageTokens(
        input: 1,
        output: 2,
        reasoning: 3,
        cache: TokenCache(read: 4, write: 5),
      ),
      error: const UnknownError(message: 'none'),
    );

    expect(first, second);
    expect(first, isNot(changed));
  });

  test('UserMessage has user role', () {
    final message = UserMessage(
      id: 'msg-user',
      sessionId: 'ses-user',
      time: const MessageTime(created: 7),
    );

    expect(message.role, MessageRole.user);
  });
}
