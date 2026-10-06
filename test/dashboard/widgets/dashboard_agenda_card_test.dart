import 'package:abdalsalam/features/dashboard/widgets/dashboard_agenda_card.dart';
import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:abdalsalam/features/planning/services/day_planning_range.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../planning/planning_fakes.dart';

final DateTime _today = DayPlanningRange.dateOnly(DateTime.now());

Future<void> _pump(
  WidgetTester tester,
  FakePlanningTaskRepository tasks, {
  FakeTaskCategoryRepository? categories,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        planningTaskRepositoryProvider.overrideWithValue(tasks),
        taskCategoryRepositoryProvider.overrideWithValue(categories ?? FakeTaskCategoryRepository()),
      ],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: DashboardAgendaCard()))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LoggerService.initialize();
  });

  testWidgets('shows an empty state when nothing is planned for today', (tester) async {
    await _pump(tester, FakePlanningTaskRepository());

    expect(find.text('Nothing planned for today'), findsOneWidget);
  });

  testWidgets('shows only today\'s tasks with their progress', (tester) async {
    final done = buildPlanningTask(id: 'a', title: 'Done task', date: _today).copyWith(isCompleted: true);
    await _pump(
      tester,
      FakePlanningTaskRepository([
        done,
        buildPlanningTask(id: 'b', title: 'Open task', date: _today),
        buildPlanningTask(id: 'c', title: 'Tomorrow task', date: _today.add(const Duration(days: 1))),
        buildPlanningTask(id: 'd', title: 'Unassigned task'),
      ]),
    );

    expect(find.text('Done task'), findsOneWidget);
    expect(find.text('Open task'), findsOneWidget);
    expect(find.text('Tomorrow task'), findsNothing);
    expect(find.text('Unassigned task'), findsNothing);
    expect(find.text('1 of 2 done'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('lists open tasks before completed ones', (tester) async {
    await _pump(
      tester,
      FakePlanningTaskRepository([
        buildPlanningTask(id: 'a', title: 'Finished', date: _today).copyWith(isCompleted: true, order: 0),
        buildPlanningTask(id: 'b', title: 'Still open', date: _today).copyWith(order: 1),
      ]),
    );

    expect(tester.getTopLeft(find.text('Still open')).dy, lessThan(tester.getTopLeft(find.text('Finished')).dy));
  });

  testWidgets('completing a task saves it', (tester) async {
    final tasks = FakePlanningTaskRepository([buildPlanningTask(id: 'a', title: 'Open task', date: _today)]);
    await _pump(tester, tasks);

    await tester.tap(find.byKey(const ValueKey('agenda-task-a')));
    await tester.pumpAndSettle();

    expect(tasks.items.single.isCompleted, isTrue);
    expect(find.text('1 of 1 done'), findsOneWidget);
  });

  testWidgets('shows category badges and caps the list with a more hint', (tester) async {
    final tasks = [
      for (var index = 0; index < 8; index++)
        buildPlanningTask(
          id: 't$index',
          title: 'Task $index',
          date: _today,
          categoryIds: index == 0 ? ['cat-1'] : const <String>[],
        ).copyWith(order: index),
    ];
    await _pump(
      tester,
      FakePlanningTaskRepository(tasks),
      categories: FakeTaskCategoryRepository([buildTaskCategory(id: 'cat-1', name: 'Work')]),
    );

    expect(find.text('Work'), findsOneWidget);
    expect(find.text('+2 more in Day Planning'), findsOneWidget);
    expect(find.text('Task 7'), findsNothing);
  });
}
