import 'dart:async';

import 'package:codewalk/data/datasources/quota_remote_datasource.dart';
import 'package:codewalk/domain/entities/quota.dart';
import 'package:codewalk/presentation/providers/quota_provider.dart';
import 'package:codewalk/presentation/widgets/quota/quota_entry_row.dart';
import 'package:codewalk/presentation/widgets/quota/quota_popup_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeQuotaRemoteDataSource implements QuotaRemoteDataSource {
  _FakeQuotaRemoteDataSource(this.results);

  final List<QuotaProviderResult> results;

  @override
  Future<List<QuotaProviderResult>> fetchQuotaResults() async => results;
}

class _QueuedQuotaRemoteDataSource implements QuotaRemoteDataSource {
  _QueuedQuotaRemoteDataSource(this.responses);

  final List<Future<List<QuotaProviderResult>>> responses;
  int callCount = 0;

  @override
  Future<List<QuotaProviderResult>> fetchQuotaResults() {
    if (callCount >= responses.length) {
      return Future<List<QuotaProviderResult>>.value(
        const <QuotaProviderResult>[],
      );
    }
    return responses[callCount++];
  }
}

QuotaProviderResult _buildOpenRouterResult() {
  return QuotaProviderResult(
    providerId: 'openrouter',
    providerName: 'OpenRouter',
    ok: true,
    configured: true,
    usage: QuotaProviderUsage(
      windows: const {
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
      models: const {},
    ),
    error: null,
    fetchedAt: 1,
  );
}

void main() {
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
          QuotaProviderResult(
            providerId: 'codex',
            providerName: 'Codex',
            ok: true,
            configured: true,
            usage: QuotaProviderUsage(
              windows: const {
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
              models: const {},
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
      const MaterialApp(
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
          child: const MaterialApp(
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
          child: const MaterialApp(
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
