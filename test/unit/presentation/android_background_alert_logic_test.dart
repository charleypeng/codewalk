import 'package:codewalk/domain/entities/experience_settings.dart';
import 'package:codewalk/presentation/services/android_background_alert_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const planner = BackgroundAlertPlanner();

  test('detects active sessions for busy and retry statuses', () {
    expect(
      hasActiveBackgroundSessions(const <String, String>{
        'ses_idle': 'idle',
        'ses_busy': 'busy',
      }),
      isTrue,
    );
    expect(
      hasActiveBackgroundSessions(const <String, String>{'ses_retry': 'retry'}),
      isTrue,
    );
  });

  test('ignores idle and unknown statuses when detecting active sessions', () {
    expect(
      hasActiveBackgroundSessions(const <String, String>{
        'ses_idle': 'idle',
        'ses_done': 'finished',
      }),
      isFalse,
    );
  });

  test('uses two-minute fast probe cadence', () {
    expect(kBackgroundFastProbeInterval, const Duration(minutes: 2));
  });

  test('uses five-minute tail probe cadence', () {
    expect(kBackgroundTailProbeInterval, const Duration(minutes: 5));
  });

  test('schedules tail probe only when active sessions just ended', () {
    expect(
      shouldScheduleBackgroundTailProbe(
        previousSessionStatusById: const <String, String>{'ses_1': 'busy'},
        currentSessionStatusById: const <String, String>{'ses_1': 'idle'},
      ),
      isTrue,
    );

    expect(
      shouldScheduleBackgroundTailProbe(
        previousSessionStatusById: const <String, String>{'ses_1': 'idle'},
        currentSessionStatusById: const <String, String>{'ses_1': 'idle'},
      ),
      isFalse,
    );

    expect(
      shouldScheduleBackgroundTailProbe(
        previousSessionStatusById: const <String, String>{'ses_1': 'busy'},
        currentSessionStatusById: const <String, String>{'ses_1': 'retry'},
      ),
      isFalse,
    );
  });

  test('first run emits actionable permission and question requests', () {
    const current = BackgroundPollingState(
      sessionStatusById: <String, String>{'ses_1': 'busy'},
      sessionUpdatedAtById: <String, int>{'ses_1': 100},
      sessionTitleById: <String, String>{'ses_1': 'Build feature'},
      permissionRequests: <BackgroundInteractionRequest>[
        BackgroundInteractionRequest(id: 'perm_1', sessionId: 'ses_1'),
      ],
      questionRequests: <BackgroundInteractionRequest>[
        BackgroundInteractionRequest(id: 'q_1', sessionId: 'ses_1'),
      ],
    );

    final plan = planner.plan(
      previous: BackgroundAlertSnapshot.empty(),
      current: current,
      settings: ExperienceSettings.defaults(),
      nowEpochMs: 200,
    );

    expect(plan.baselineOnly, isFalse);
    expect(plan.signals.length, 2);
    expect(
      plan.signals.map((signal) => signal.kind),
      containsAll(<BackgroundAlertKind>[
        BackgroundAlertKind.permission,
        BackgroundAlertKind.question,
      ]),
    );
    expect(plan.nextSnapshot.sessionStatusById['ses_1'], 'busy');
    expect(plan.nextSnapshot.notifiedPermissionRequestIds, contains('perm_1'));
    expect(plan.nextSnapshot.notifiedQuestionRequestIds, contains('q_1'));
  });

  test('creates silent baseline when nothing actionable exists', () {
    const current = BackgroundPollingState(
      sessionStatusById: <String, String>{'ses_1': 'busy'},
      sessionUpdatedAtById: <String, int>{'ses_1': 100},
      sessionTitleById: <String, String>{'ses_1': 'Build feature'},
      permissionRequests: <BackgroundInteractionRequest>[],
      questionRequests: <BackgroundInteractionRequest>[],
    );

    final plan = planner.plan(
      previous: BackgroundAlertSnapshot.empty(),
      current: current,
      settings: ExperienceSettings.defaults(),
      nowEpochMs: 200,
    );

    expect(plan.baselineOnly, isTrue);
    expect(plan.signals, isEmpty);
  });

  test('first run emits error for retry status', () {
    const current = BackgroundPollingState(
      sessionStatusById: <String, String>{'ses_1': 'retry'},
      sessionUpdatedAtById: <String, int>{'ses_1': 100},
      sessionTitleById: <String, String>{'ses_1': 'Build feature'},
      permissionRequests: <BackgroundInteractionRequest>[],
      questionRequests: <BackgroundInteractionRequest>[],
    );

    final plan = planner.plan(
      previous: BackgroundAlertSnapshot.empty(),
      current: current,
      settings: ExperienceSettings.defaults(),
      nowEpochMs: 200,
    );

    expect(plan.baselineOnly, isFalse);
    expect(plan.signals.length, 1);
    expect(plan.signals.first.kind, BackgroundAlertKind.error);
    expect(plan.signals.first.title, 'Build feature');
  });

  test('emits completion when session transitions busy to idle', () {
    const previous = BackgroundAlertSnapshot(
      sessionStatusById: <String, String>{'ses_1': 'busy'},
      sessionUpdatedAtById: <String, int>{'ses_1': 100},
      notifiedPermissionRequestIds: <String>[],
      notifiedQuestionRequestIds: <String>[],
      lastPolledAtEpochMs: 100,
    );
    const current = BackgroundPollingState(
      sessionStatusById: <String, String>{'ses_1': 'idle'},
      sessionUpdatedAtById: <String, int>{'ses_1': 200},
      sessionTitleById: <String, String>{'ses_1': 'Build feature'},
      permissionRequests: <BackgroundInteractionRequest>[],
      questionRequests: <BackgroundInteractionRequest>[],
    );

    final plan = planner.plan(
      previous: previous,
      current: current,
      settings: ExperienceSettings.defaults(),
      nowEpochMs: 200,
    );

    expect(plan.baselineOnly, isFalse);
    expect(plan.signals.length, 1);
    expect(plan.signals.first.kind, BackgroundAlertKind.completion);
    expect(plan.signals.first.categoryKey, 'agent');
    expect(plan.signals.first.title, 'Build feature');
  });

  test('emits error when session transitions to retry', () {
    const previous = BackgroundAlertSnapshot(
      sessionStatusById: <String, String>{'ses_1': 'busy'},
      sessionUpdatedAtById: <String, int>{'ses_1': 100},
      notifiedPermissionRequestIds: <String>[],
      notifiedQuestionRequestIds: <String>[],
      lastPolledAtEpochMs: 100,
    );
    const current = BackgroundPollingState(
      sessionStatusById: <String, String>{'ses_1': 'retry'},
      sessionUpdatedAtById: <String, int>{'ses_1': 200},
      sessionTitleById: <String, String>{'ses_1': 'Build feature'},
      permissionRequests: <BackgroundInteractionRequest>[],
      questionRequests: <BackgroundInteractionRequest>[],
    );

    final plan = planner.plan(
      previous: previous,
      current: current,
      settings: ExperienceSettings.defaults(),
      nowEpochMs: 200,
    );

    expect(plan.signals.length, 1);
    expect(plan.signals.first.kind, BackgroundAlertKind.error);
    expect(plan.signals.first.categoryKey, 'errors');
    expect(plan.signals.first.title, 'Build feature');
  });

  test('emits action-required for unseen permission and question ids', () {
    const previous = BackgroundAlertSnapshot(
      sessionStatusById: <String, String>{'ses_1': 'idle'},
      sessionUpdatedAtById: <String, int>{'ses_1': 100},
      notifiedPermissionRequestIds: <String>['perm_seen'],
      notifiedQuestionRequestIds: <String>['q_seen'],
      lastPolledAtEpochMs: 100,
    );
    const current = BackgroundPollingState(
      sessionStatusById: <String, String>{'ses_1': 'idle'},
      sessionUpdatedAtById: <String, int>{'ses_1': 200},
      sessionTitleById: <String, String>{'ses_1': 'Build feature'},
      permissionRequests: <BackgroundInteractionRequest>[
        BackgroundInteractionRequest(id: 'perm_seen', sessionId: 'ses_1'),
        BackgroundInteractionRequest(id: 'perm_new', sessionId: 'ses_1'),
      ],
      questionRequests: <BackgroundInteractionRequest>[
        BackgroundInteractionRequest(id: 'q_seen', sessionId: 'ses_1'),
        BackgroundInteractionRequest(id: 'q_new', sessionId: 'ses_1'),
      ],
    );

    final plan = planner.plan(
      previous: previous,
      current: current,
      settings: ExperienceSettings.defaults(),
      nowEpochMs: 200,
    );

    expect(plan.signals.length, 2);
    expect(
      plan.signals.map((signal) => signal.kind),
      containsAll(<BackgroundAlertKind>[
        BackgroundAlertKind.permission,
        BackgroundAlertKind.question,
      ]),
    );
  });

  test('respects disabled notification categories', () {
    const previous = BackgroundAlertSnapshot(
      sessionStatusById: <String, String>{'ses_1': 'busy'},
      sessionUpdatedAtById: <String, int>{'ses_1': 100},
      notifiedPermissionRequestIds: <String>[],
      notifiedQuestionRequestIds: <String>[],
      lastPolledAtEpochMs: 100,
    );
    const current = BackgroundPollingState(
      sessionStatusById: <String, String>{'ses_1': 'retry'},
      sessionUpdatedAtById: <String, int>{'ses_1': 200},
      sessionTitleById: <String, String>{'ses_1': 'Build feature'},
      permissionRequests: <BackgroundInteractionRequest>[
        BackgroundInteractionRequest(id: 'perm_new', sessionId: 'ses_1'),
      ],
      questionRequests: <BackgroundInteractionRequest>[],
    );
    final settings = ExperienceSettings.defaults().copyWith(
      notifications: const <NotificationCategory, bool>{
        NotificationCategory.agent: false,
        NotificationCategory.permissions: false,
        NotificationCategory.errors: false,
      },
    );

    final plan = planner.plan(
      previous: previous,
      current: current,
      settings: settings,
      nowEpochMs: 200,
    );

    expect(plan.signals, isEmpty);
  });
}
