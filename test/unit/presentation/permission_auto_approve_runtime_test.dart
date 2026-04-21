import 'package:codewalk/domain/entities/chat_realtime.dart';
import 'package:codewalk/presentation/services/permission_auto_approve_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses always reply when remembered approval patterns exist', () {
    expect(
      permissionAutoApproveReplyForAlwaysPatterns(const <String>[
        'git status*',
      ]),
      'always',
    );
    expect(
      permissionAutoApproveReplyForAlwaysPatterns(const <String>['', '  ']),
      'once',
    );
  });

  test('derives permission reply from chat permission request', () {
    const request = ChatPermissionRequest(
      id: 'perm_1',
      sessionId: 'ses_root',
      permission: 'bash',
      patterns: <String>['*'],
      always: <String>['git status*'],
      metadata: <String, dynamic>{},
    );

    expect(permissionAutoApproveReplyForRequest(request), 'always');
  });

  test('collects descendant session ids transitively', () {
    expect(
      collectThreadSessionIds(
        currentSessionId: 'ses_root',
        parentSessionIdByChild: const <String, String>{
          'ses_child': 'ses_root',
          'ses_grandchild': 'ses_child',
          'ses_other': 'ses_elsewhere',
        },
      ),
      equals(<String>{'ses_root', 'ses_child', 'ses_grandchild'}),
    );
  });

  test(
    'resolves background thread session ids from stored and derived data',
    () {
      const context = PermissionAutoApproveBackgroundContext(
        serverId: 'srv_1',
        scopeId: '/repo',
        currentSessionId: 'ses_root',
        threadSessionIds: <String>['ses_root', 'ses_existing_child'],
        updatedAtEpochMs: 123,
      );

      expect(
        resolveThreadSessionIdsForBackgroundContext(
          context: context,
          parentSessionIdByChild: const <String, String>{
            'ses_existing_child': 'ses_root',
            'ses_new_child': 'ses_root',
          },
        ),
        equals(<String>{'ses_root', 'ses_existing_child', 'ses_new_child'}),
      );
    },
  );

  test('clears background auto-approve context on server change', () {
    expect(
      shouldClearBackgroundPermissionAutoApproveContextForTransition(
        currentServerId: 'srv_a',
        currentScopeId: '/repo-a',
        currentDirectory: '/repo-a',
        nextServerId: 'srv_b',
        nextScopeId: '/repo-a',
        nextDirectory: '/repo-a',
      ),
      isTrue,
    );
  });

  test('clears background auto-approve context on scope change', () {
    expect(
      shouldClearBackgroundPermissionAutoApproveContextForTransition(
        currentServerId: 'srv_a',
        currentScopeId: '/repo-a',
        currentDirectory: '/repo-a',
        nextServerId: 'srv_a',
        nextScopeId: '/repo-b',
        nextDirectory: '/repo-b',
      ),
      isTrue,
    );
  });

  test('keeps background auto-approve context when scope is unchanged', () {
    expect(
      shouldClearBackgroundPermissionAutoApproveContextForTransition(
        currentServerId: 'srv_a',
        currentScopeId: '/repo-a',
        currentDirectory: '/repo-a',
        nextServerId: 'srv_a',
        nextScopeId: '/repo-a',
        nextDirectory: '/repo-a',
      ),
      isFalse,
    );
  });
}
