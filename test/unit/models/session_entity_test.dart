import 'package:codewalk/domain/entities/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Session equality includes nested share and revert data', () {
    final first = Session(
      id: 'ses-1',
      parentId: 'parent-1',
      title: 'Session 1',
      version: 'v1',
      time: const SessionTime(created: 1, updated: 2),
      share: const SessionShare(url: 'https://example.com'),
      revert: const SessionRevert(
        messageId: 'm-1',
        partId: 'p-1',
        snapshot: 'snapshot',
        diff: 'diff',
      ),
    );

    final second = Session(
      id: 'ses-1',
      parentId: 'parent-1',
      title: 'Session 1',
      version: 'v1',
      time: const SessionTime(created: 1, updated: 2),
      share: const SessionShare(url: 'https://example.com'),
      revert: const SessionRevert(
        messageId: 'm-1',
        partId: 'p-1',
        snapshot: 'snapshot',
        diff: 'diff',
      ),
    );

    final changed = Session(
      id: 'ses-1',
      parentId: 'parent-1',
      title: 'Session changed',
      version: 'v1',
      time: const SessionTime(created: 1, updated: 2),
      share: const SessionShare(url: 'https://example.com'),
      revert: const SessionRevert(
        messageId: 'm-1',
        partId: 'p-1',
        snapshot: 'snapshot',
        diff: 'diff',
      ),
    );

    expect(first, second);
    expect(first, isNot(changed));
  });
}
