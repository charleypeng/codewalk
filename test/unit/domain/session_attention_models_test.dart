import 'package:codewalk/domain/entities/session_attention_overlay/session_attention_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const identity = SessionAttentionIdentity(
    serverId: 'server-a',
    directory: '/work/app',
    rootSessionId: 'root-1',
  );

  test('priority keeps actionable states above status states', () {
    expect(
      rootSessionAttentionPriority(RootSessionAttentionKind.error),
      greaterThan(
        rootSessionAttentionPriority(
          RootSessionAttentionKind.pendingInteraction,
        ),
      ),
    );
    expect(
      rootSessionAttentionPriority(RootSessionAttentionKind.pendingInteraction),
      greaterThan(
        rootSessionAttentionPriority(RootSessionAttentionKind.completed),
      ),
    );
    expect(
      rootSessionAttentionPriority(RootSessionAttentionKind.delayed),
      greaterThan(
        rootSessionAttentionPriority(RootSessionAttentionKind.receiving),
      ),
    );
  });

  test('aggregate rejects stale revisions and foreign generations', () {
    const current = SessionAttentionAggregate(
      generation: 'generation-a',
      revision: 4,
      candidates: <RootSessionAttentionCandidate>[],
    );

    expect(
      const SessionAttentionAggregate(
        generation: 'generation-a',
        revision: 4,
        candidates: <RootSessionAttentionCandidate>[],
      ).supersedes(current),
      isFalse,
    );
    expect(
      const SessionAttentionAggregate(
        generation: 'generation-a',
        revision: 5,
        candidates: <RootSessionAttentionCandidate>[],
      ).supersedes(current),
      isTrue,
    );
    expect(
      const SessionAttentionAggregate(
        generation: 'generation-b',
        revision: 1,
        candidates: <RootSessionAttentionCandidate>[],
      ).supersedes(current),
      isFalse,
    );
    expect(
      const SessionAttentionAggregate(
        generation: 'generation-b',
        revision: 1,
        candidates: <RootSessionAttentionCandidate>[],
        isFullResynchronization: true,
      ).supersedes(current),
      isTrue,
    );
  });

  test('highest priority ordering is deterministic', () {
    final observedAt = DateTime.utc(2026, 7, 12);
    final aggregate = SessionAttentionAggregate(
      generation: 'generation-a',
      revision: 1,
      candidates: <RootSessionAttentionCandidate>[
        RootSessionAttentionCandidate(
          identity: identity,
          kind: RootSessionAttentionKind.receiving,
          title: 'Receiving',
          projectLabel: 'App',
          observedAt: observedAt,
        ),
        RootSessionAttentionCandidate(
          identity: const SessionAttentionIdentity(
            serverId: 'server-a',
            directory: '/work/app',
            rootSessionId: 'root-2',
          ),
          kind: RootSessionAttentionKind.error,
          title: 'Error',
          projectLabel: 'App',
          observedAt: observedAt,
        ),
      ],
    );

    expect(aggregate.highestPriority?.kind, RootSessionAttentionKind.error);
  });
}
