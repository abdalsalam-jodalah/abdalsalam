import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/prayer_log.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/religious_tracking_providers.dart';
import 'package:abdalsalam/features/religious/screens/prayer_logs_screen.dart';
import 'package:abdalsalam/features/religious/widgets/prayer_log_tile.dart';
import 'package:abdalsalam/features/religious/widgets/prayer_stats_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../religious_fakes.dart';
import 'screen_test_utils.dart';

PrayerLog _log(PrayerName prayer, {bool onTime = true, DateTime? scheduledAt}) {
  final at = DateTime.now().subtract(const Duration(minutes: 10));
  return PrayerLog(
    id: '${prayer.name}-${scheduledAt?.hour}-$onTime',
    createdAt: at,
    updatedAt: at,
    userId: demoUserId,
    prayerName: prayer,
    prayedAt: at,
    onTime: onTime,
    scheduledAt: scheduledAt,
  );
}

class _RecordingPrayerService extends FakePrayerService {
  final List<PrayerName> logged = [];

  _RecordingPrayerService({required List<PrayerLog> today})
      : super(todayLogsResult: Success(today), logPrayerResult: Success(_log(PrayerName.voluntary)));

  @override
  Future<Result<PrayerLog, AppError>> logPrayer({
    required String userId,
    required PrayerName prayerName,
    required bool onTime,
    String? notes,
    DateTime? prayedAt,
    DateTime? scheduledAt,
  }) async {
    logged.add(prayerName);
    return super.logPrayer(
      userId: userId,
      prayerName: prayerName,
      onTime: onTime,
      notes: notes,
      prayedAt: prayedAt,
      scheduledAt: scheduledAt,
    );
  }
}

Future<_RecordingPrayerService> _pumpScreen(WidgetTester tester, {List<PrayerLog> logs = const <PrayerLog>[]}) async {
  final service = _RecordingPrayerService(today: logs);
  final container = ProviderContainer(
    overrides: [
      prayerServiceProvider.overrideWithValue(service),
      prayerRepositoryProvider.overrideWithValue(FakePrayerRepository(byUserIdResult: Success(logs))),
      religiousServiceProvider.overrideWithValue(
        FakeReligiousService(statisticsResult: const Success(<String, dynamic>{'currentStreak': 0})),
      ),
      todayPrayerTimesProvider.overrideWith((ref) async => throw StateError('no prayer times in this test')),
    ],
  );
  addTearDown(container.dispose);
  enlargeTestSurface(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MaterialApp(home: PrayerLogsScreen())),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  group('Log a prayer for God', () {
    testWidgets('opens the dialog with the voluntary prayer selected and explains it', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('log-prayer-for-god')));
      await tester.pumpAndSettle();

      expect(find.text('For God'), findsWidgets);
      expect(find.byKey(const ValueKey('voluntary-hint')), findsOneWidget);
      expect(find.text('Manually override on-time status'), findsNothing);
    });

    testWidgets('saves a voluntary prayer', (tester) async {
      final service = await _pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('log-prayer-for-god')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(service.logged, [PrayerName.voluntary]);
    });

    testWidgets('keeps the on time override for the five daily prayers', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('voluntary-hint')), findsNothing);
      expect(find.text('Manually override on-time status'), findsOneWidget);
    });

    testWidgets('offers the voluntary prayer as a sixth choice in the dialog', (tester) async {
      final service = await _pumpScreen(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<PrayerName>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('For God').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('voluntary-hint')), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(service.logged, [PrayerName.voluntary]);
    });
  });

  group('PrayerLogTile', () {
    Future<void> pumpTile(WidgetTester tester, PrayerLog log) {
      return tester.pumpWidget(MaterialApp(home: Scaffold(body: PrayerLogTile(log: log))));
    }

    testWidgets('shows the voluntary prayer as FOR GOD without an on time check', (tester) async {
      await pumpTile(tester, _log(PrayerName.voluntary));

      expect(find.textContaining('FOR GOD'), findsOneWidget);
      expect(find.textContaining('Voluntary'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('keeps showing the on time check for a daily prayer', (tester) async {
      await pumpTile(tester, _log(PrayerName.fajr));

      expect(find.textContaining('FAJR'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('names the daily prayer in the early or late label', (tester) async {
      final scheduled = DateTime.now().subtract(const Duration(minutes: 40));
      await pumpTile(tester, _log(PrayerName.dhuhr, scheduledAt: scheduled));

      expect(find.textContaining('min after Dhuhr'), findsOneWidget);
    });
  });

  group('PrayerStatsSummary', () {
    testWidgets('counts daily prayers and for God prayers separately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerStatsSummary(
              allLogs: [
                _log(PrayerName.fajr),
                _log(PrayerName.dhuhr, onTime: false),
                _log(PrayerName.voluntary),
                _log(PrayerName.voluntary, scheduledAt: DateTime(2026)),
                _log(PrayerName.voluntary, onTime: false),
              ],
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('For God'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}
