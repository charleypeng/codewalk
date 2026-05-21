import 'dart:async';

import 'package:codewalk/core/i18n/app_locales.dart';
import 'package:codewalk/data/datasources/quota_remote_datasource.dart';
import 'package:codewalk/domain/entities/quota.dart';
import 'package:codewalk/presentation/providers/quota_provider.dart';
import 'package:codewalk/presentation/widgets/quota/quota_entry_row.dart';
import 'package:codewalk/presentation/widgets/quota/quota_popup_section.dart';
import 'package:codewalk/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart' as support;

class _FakeQuotaRemoteDataSource implements QuotaRemoteDataSource {
  _FakeQuotaRemoteDataSource(this.results);

  final List<QuotaProviderResult> results;
  OpenCodeGoDashboardCredentials? lastOpenCodeGoCredentials;

  @override
  Future<List<QuotaProviderResult>> fetchQuotaResults({
    OpenCodeGoDashboardCredentials? openCodeGoCredentials,
  }) async {
    lastOpenCodeGoCredentials = openCodeGoCredentials;
    return results;
  }
}

class _QueuedQuotaRemoteDataSource implements QuotaRemoteDataSource {
  _QueuedQuotaRemoteDataSource(this.responses);

  final List<Future<List<QuotaProviderResult>>> responses;
  int callCount = 0;

  @override
  Future<List<QuotaProviderResult>> fetchQuotaResults({
    OpenCodeGoDashboardCredentials? openCodeGoCredentials,
  }) {
    if (callCount >= responses.length) {
      return Future<List<QuotaProviderResult>>.value(
        const <QuotaProviderResult>[],
      );
    }
    return responses[callCount++];
  }
}

QuotaProviderResult _buildOpenRouterResult() {
  return const QuotaProviderResult(
    providerId: 'openrouter',
    providerName: 'OpenRouter',
    ok: true,
    configured: true,
    usage: QuotaProviderUsage(
      windows: {
        'credits': UsageWindow(
          usedPercent: null,
          remainingPercent: null,
          windowSeconds: null,
          resetAfterSeconds: null,
          resetAt: null,
          resetAtFormatted: null,
          resetAfterFormatted: null,
          valueLabel: r'$12.00 remaining',
        ),
      },
      models: {},
    ),
    error: null,
    fetchedAt: 1,
  );
}

void main() {
  test(
    'QuotaProvider passes stored OpenCode Go dashboard credentials',
    () async {
      final remoteDataSource = _FakeQuotaRemoteDataSource(const []);
      final localDataSource = support.InMemoryAppLocalDataSource();
      await localDataSource.saveOpenCodeGoWorkspaceId(
        'wrk_test',
        serverId: 'srv_test',
      );
      await localDataSource.saveOpenCodeGoAuthCookie(
        'auth=secret',
        serverId: 'srv_test',
      );
      final provider = QuotaProvider(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      await provider.ensureLoaded(serverId: 'srv_test');

      expect(remoteDataSource.lastOpenCodeGoCredentials, isNotNull);
      expect(
        remoteDataSource.lastOpenCodeGoCredentials!.workspaceId,
        'wrk_test',
      );
      expect(
        remoteDataSource.lastOpenCodeGoCredentials!.authCookie,
        'auth=secret',
      );
    },
  );

  test('QuotaEntry treats zero remaining currency labels as exhausted', () {
    const entry = QuotaEntry(
      providerId: 'openrouter',
      providerName: 'OpenRouter',
      label: 'Credits',
      usedPercent: null,
      remainingPercent: null,
      windowSeconds: null,
      resetAfterSeconds: null,
      resetAt: null,
      valueLabel: r'$0.00 remaining',
      paceInfo: null,
    );

    expect(entry.hasZeroRemainingValueLabel, isTrue);
    expect(entry.effectiveUsedPercent, 100);
    expect(entry.severityScore, 100);
  });

  test(
    'QuotaProvider orders mixed windows by highest used percent first',
    () async {
      final provider = QuotaProvider(
        remoteDataSource: _FakeQuotaRemoteDataSource([
          const QuotaProviderResult(
            providerId: 'codex',
            providerName: 'Codex',
            ok: true,
            configured: true,
            usage: QuotaProviderUsage(
              windows: {
                'weekly': UsageWindow(
                  usedPercent: 35,
                  remainingPercent: 65,
                  windowSeconds: 7 * 86400,
                  resetAfterSeconds: 3600,
                  resetAt: 1,
                  resetAtFormatted: null,
                  resetAfterFormatted: null,
                  valueLabel: null,
                ),
                '5h': UsageWindow(
                  usedPercent: 80,
                  remainingPercent: 20,
                  windowSeconds: 5 * 3600,
                  resetAfterSeconds: 1800,
                  resetAt: 1,
                  resetAtFormatted: null,
                  resetAfterFormatted: null,
                  valueLabel: null,
                ),
              },
              models: {},
            ),
            error: null,
            fetchedAt: 1,
          ),
        ]),
      );

      await provider.ensureLoaded(serverId: 'srv_test');

      expect(provider.groups, hasLength(1));
      expect(provider.groups.first.entries, hasLength(2));
      expect(provider.groups.first.leadingEntry.label, '5-Hour');
      expect(provider.groups.first.entries.first.label, '5-Hour');
      expect(provider.groups.first.entries.last.label, 'Weekly Limit');
    },
  );

  test('QuotaProvider hides zero-credit only groups', () async {
    final provider = QuotaProvider(
      remoteDataSource: _FakeQuotaRemoteDataSource(const [
        QuotaProviderResult(
          providerId: 'openrouter',
          providerName: 'OpenRouter',
          ok: true,
          configured: true,
          usage: QuotaProviderUsage(
            windows: {
              'credits': UsageWindow(
                usedPercent: null,
                remainingPercent: null,
                windowSeconds: null,
                resetAfterSeconds: null,
                resetAt: null,
                resetAtFormatted: null,
                resetAfterFormatted: null,
                valueLabel: r'$0.00 remaining',
              ),
            },
            models: {},
          ),
          error: null,
          fetchedAt: 1,
        ),
      ]),
    );

    await provider.ensureLoaded(serverId: 'srv_test');

    expect(provider.groups, isEmpty);
  });

  test(
    'QuotaProvider keeps mixed groups and drops zero-credit entries',
    () async {
      final provider = QuotaProvider(
        remoteDataSource: _FakeQuotaRemoteDataSource([
          const QuotaProviderResult(
            providerId: 'codex',
            providerName: 'Codex',
            ok: true,
            configured: true,
            usage: QuotaProviderUsage(
              windows: {
                'weekly': UsageWindow(
                  usedPercent: 35,
                  remainingPercent: 65,
                  windowSeconds: 7 * 86400,
                  resetAfterSeconds: 3600,
                  resetAt: 1,
                  resetAtFormatted: null,
                  resetAfterFormatted: null,
                  valueLabel: null,
                ),
                '5h': UsageWindow(
                  usedPercent: 80,
                  remainingPercent: 20,
                  windowSeconds: 5 * 3600,
                  resetAfterSeconds: 1800,
                  resetAt: 1,
                  resetAtFormatted: null,
                  resetAfterFormatted: null,
                  valueLabel: null,
                ),
                'credits': UsageWindow(
                  usedPercent: null,
                  remainingPercent: null,
                  windowSeconds: null,
                  resetAfterSeconds: null,
                  resetAt: null,
                  resetAtFormatted: null,
                  resetAfterFormatted: null,
                  valueLabel: r'$0.00 remaining',
                ),
              },
              models: {},
            ),
            error: null,
            fetchedAt: 1,
          ),
        ]),
      );

      await provider.ensureLoaded(serverId: 'srv_test');

      expect(provider.groups, hasLength(1));
      expect(provider.groups.first.providerId, 'codex');
      expect(provider.groups.first.entries, hasLength(2));
      expect(
        provider.groups.first.entries.any(
          (entry) => entry.hasZeroRemainingValueLabel,
        ),
        isFalse,
      );
      expect(
        provider.groups.first.entries.map((entry) => entry.label).toList(),
        <String>['5-Hour', 'Weekly Limit'],
      );
    },
  );

  testWidgets('QuotaEntryRow shows determinate full bar for zero remaining', (
    tester,
  ) async {
    const entry = QuotaEntry(
      providerId: 'openrouter',
      providerName: 'OpenRouter',
      label: 'Credits',
      usedPercent: null,
      remainingPercent: null,
      windowSeconds: null,
      resetAfterSeconds: null,
      resetAt: null,
      valueLabel: r'$0.00 remaining',
      paceInfo: null,
    );

    await tester.pumpWidget(
      _buildApp(
        home: Scaffold(body: QuotaEntryRow(entry: entry)),
      ),
    );

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 1.0);
  });

  testWidgets(
    'QuotaPopupSection shows subtle first-load state and then hides when empty',
    (tester) async {
      final firstLoad = Completer<List<QuotaProviderResult>>();
      final provider = QuotaProvider(
        remoteDataSource: _QueuedQuotaRemoteDataSource([firstLoad.future]),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<QuotaProvider>.value(
          value: provider,
          child: _buildApp(
            home: Scaffold(body: QuotaPopupSection(serverId: 'srv_test')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Rate limits'), findsOneWidget);
      expect(find.text('Refreshing...'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('quota-initial-loading-state')),
        findsOneWidget,
      );

      firstLoad.complete(const <QuotaProviderResult>[]);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Rate limits'), findsNothing);
      expect(
        find.byKey(const ValueKey('quota-initial-loading-state')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'QuotaPopupSection shows OpenCode Go setup when dashboard credentials are missing',
    (tester) async {
      final provider = QuotaProvider(
        remoteDataSource: _FakeQuotaRemoteDataSource(const [
          QuotaProviderResult(
            providerId: 'opencode-go',
            providerName: 'OpenCode Go',
            ok: false,
            configured: true,
            usage: null,
            error:
                'OpenCode Go is configured, but subscription usage requires setup.',
            fetchedAt: 1,
          ),
        ]),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<QuotaProvider>.value(
          value: provider,
          child: _buildApp(
            home: Scaffold(body: QuotaPopupSection(serverId: 'srv_test')),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Rate limits'), findsOneWidget);
      expect(find.text('OpenCode Go detected'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('opencode-go-connect-usage-dashboard')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'QuotaPopupSection swaps refresh button for refreshing label during reload',
    (tester) async {
      final refreshLoad = Completer<List<QuotaProviderResult>>();
      final provider = QuotaProvider(
        remoteDataSource: _QueuedQuotaRemoteDataSource([
          Future<List<QuotaProviderResult>>.value([_buildOpenRouterResult()]),
          refreshLoad.future,
        ]),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<QuotaProvider>.value(
          value: provider,
          child: _buildApp(
            home: Scaffold(body: QuotaPopupSection(serverId: 'srv_test')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Rate limits'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('quota-refresh-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('quota-refreshing-label')),
        findsNothing,
      );

      await tester.tap(find.text('Refresh'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const ValueKey('quota-refresh-button')), findsNothing);
      expect(
        find.byKey(const ValueKey('quota-refreshing-label')),
        findsOneWidget,
      );

      refreshLoad.complete([_buildOpenRouterResult()]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('quota-refresh-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('quota-refreshing-label')),
        findsNothing,
      );
    },
  );
}

Widget _buildApp({required Widget home}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocales.supported,
    home: home,
  );
}
