import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/data/models/planning/goal.dart';
import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:abdalsalam/features/planning/screens/day_planning_screen.dart';
import 'package:abdalsalam/features/planning/screens/goals_screen.dart';
import 'package:abdalsalam/features/sports/providers/sports_providers.dart';
import 'package:abdalsalam/features/sports/screens/sports_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../planning/planning_fakes.dart';
import '../sports/sports_fakes.dart';
import 'support/golden_harness.dart';

void main() {
  setUpAll(loadGoldenFonts);

  final today = DateTime.now();

  for (final brightness in Brightness.values) {
    testWidgets('sports dashboard ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 950));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          exerciseCategoryRepositoryProvider.overrideWithValue(
            FakeExerciseCategoryRepository([buildExerciseCategory()]),
          ),
          exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository([buildExercise()])),
          exerciseLogRepositoryProvider.overrideWithValue(
            FakeExerciseLogRepository([buildExerciseLog(date: today)]),
          ),
          bodyMeasurementRepositoryProvider.overrideWithValue(
            FakeBodyMeasurementRepository([
              buildBodyMeasurement(id: 'measurement-1', date: today.subtract(const Duration(days: 3)), weightKg: 82),
              buildBodyMeasurement(id: 'measurement-2', date: today, weightKg: 80),
            ]),
          ),
        ],
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const SportsDashboardScreen(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/sports_dashboard_${brightness.name}.png'));
    });

    testWidgets('goals screen ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 950));
      final goals = <Goal>[
        buildGoal(id: 'g1', title: 'Read 20 pages', scope: GoalScope.daily, status: GoalStatus.inProgress),
        buildGoal(id: 'g2', title: 'Learn Spanish', scope: GoalScope.monthly, status: GoalStatus.notStarted),
        buildGoal(id: 'g3', title: 'Run a marathon', scope: GoalScope.yearly, status: GoalStatus.achieved),
      ];
      await tester.pumpWidget(ProviderScope(
        overrides: [goalRepositoryProvider.overrideWithValue(FakeGoalRepository(goals))],
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const GoalsScreen(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/goals_screen_${brightness.name}.png'));
    });

    testWidgets('day planning ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 950));
      final goals = <Goal>[
        buildGoal(
          id: 'g1',
          title: 'Morning workout',
          scope: GoalScope.daily,
          status: GoalStatus.inProgress,
          targetDate: today,
        ),
      ];
      final tasks = [buildPlanningTask(id: 't1', title: 'Draft outline', date: today)];
      await tester.pumpWidget(ProviderScope(
        overrides: [
          goalRepositoryProvider.overrideWithValue(FakeGoalRepository(goals)),
          planningTaskRepositoryProvider.overrideWithValue(FakePlanningTaskRepository(tasks)),
        ],
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const DayPlanningScreen(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/day_planning_${brightness.name}.png'));
    });
  }
}
