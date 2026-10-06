import 'package:abdalsalam/features/dashboard/widgets/dashboard_today_stats.dart';
import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/quran_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../planning/planning_fakes.dart';

Future<void> _pump(WidgetTester tester, {required int daily, required int voluntary}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prayerCountProvider.overrideWithValue(daily),
        voluntaryPrayerCountProvider.overrideWithValue(voluntary),
        quranPagesTodayProvider.overrideWithValue(0),
        todaysGoalsProvider.overrideWith((ref) async => []),
        planningTaskRepositoryProvider.overrideWithValue(FakePlanningTaskRepository()),
      ],
      child: const MaterialApp(home: Scaffold(body: DashboardTodayStats())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the daily prayers out of five without counting prayers for God', (tester) async {
    await _pump(tester, daily: 3, voluntary: 2);

    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.text('+2 for God'), findsOneWidget);
  });

  testWidgets('says all prayers are done when the five are complete and nothing extra was prayed', (tester) async {
    await _pump(tester, daily: 5, voluntary: 0);

    expect(find.text('5 / 5'), findsOneWidget);
    expect(find.text('All prayers done'), findsOneWidget);
  });

  testWidgets('shows no caption when no prayer for God was logged and the day is not complete', (tester) async {
    await _pump(tester, daily: 1, voluntary: 0);

    expect(find.text('All prayers done'), findsNothing);
    expect(find.textContaining('for God'), findsNothing);
  });
}
