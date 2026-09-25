import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/data/models/planning/goal.dart';
import 'package:abdalsalam/features/dashboard/providers/dashboard_providers.dart';
import 'package:abdalsalam/features/dashboard/screens/dashboard_screen.dart';
import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/quran_providers.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_harness.dart';

void main() {
  setUpAll(loadGoldenFonts);

  final goals = <Goal>[
    Goal(
      id: 'g1',
      createdAt: DateTime(2026, 9, 24),
      updatedAt: DateTime(2026, 9, 24),
      userId: 'u',
      title: 'Read 20 pages',
      scope: GoalScope.daily,
      status: GoalStatus.inProgress,
      progress: 0.6,
    ),
  ];

  for (final brightness in Brightness.values) {
    testWidgets('dashboard ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 1200));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appStateManagerProvider.overrideWithValue(logic.AppStateManagerImpl.create(config: const logic.AppStateConfig())),
          prayerCountProvider.overrideWithValue(4),
          quranPagesTodayProvider.overrideWithValue(12),
          weatherProvider.overrideWith((ref) async => null),
          currencyRatesProvider.overrideWith((ref) async => <String, double>{'USD': 0.27, 'JOD': 0.19}),
          usdHistoryProvider.overrideWith((ref) async => []),
          jodHistoryProvider.overrideWith((ref) async => []),
          todaysGoalsProvider.overrideWith((ref) async => goals),
          appSettingsProvider.overrideWith((ref) async => <String, dynamic>{}),
        ],
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const DashboardScreen(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/dashboard_${brightness.name}.png'));
    });
  }
}
