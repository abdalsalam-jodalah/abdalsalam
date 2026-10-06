import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/features/planning/providers/planning_board_provider.dart';
import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'planning_fakes.dart';

final DateTime _monday = DateTime(2026, 3, 9);
final DateTime _tuesday = DateTime(2026, 3, 10);

ProviderContainer _container(FakePlanningTaskRepository repo) {
  final container = ProviderContainer(overrides: [planningTaskRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('planningBoardProvider', () {
    test('should load dated and unassigned tasks but not goal tasks', () async {
      final repo = FakePlanningTaskRepository([
        buildPlanningTask(id: 'dated', date: _monday),
        buildPlanningTask(id: 'free'),
        buildPlanningTask(id: 'goal-task', goalId: 'goal-1'),
      ]);
      final container = _container(repo);

      final tasks = await container.read(planningBoardProvider.future);

      expect(tasks.map((task) => task.id), unorderedEquals(['dated', 'free']));
    });

    test('should surface a typed error when loading fails', () async {
      final repo = FakePlanningTaskRepository()..shouldFailGetByDate = true;
      final container = _container(repo);

      await expectLater(container.read(planningBoardProvider.future), throwsA(isA<DatabaseError>()));
    });

    test('should update state before persistence finishes when moving a task', () async {
      final repo = FakePlanningTaskRepository([buildPlanningTask(id: 'a', date: _monday)]);
      final container = _container(repo);
      await container.read(planningBoardProvider.future);

      final pending = container
          .read(planningBoardProvider.notifier)
          .moveTask(taskId: 'a', targetDate: _tuesday, targetIndex: 0);

      expect(container.read(planningBoardProvider).value!.single.date, _tuesday);
      expect(await pending, isNull);
      expect(repo.items.single.date, _tuesday);
    });

    test('should report the error and reload when persisting a move fails', () async {
      final repo = FakePlanningTaskRepository([buildPlanningTask(id: 'a', date: _monday)])..shouldFailUpdate = true;
      final container = _container(repo);
      await container.read(planningBoardProvider.future);

      final error = await container
          .read(planningBoardProvider.notifier)
          .moveTask(taskId: 'a', targetDate: _tuesday, targetIndex: 0);
      final reloaded = await container.read(planningBoardProvider.future);

      expect(error, isA<DatabaseError>());
      expect(reloaded.single.date, _monday);
    });

    test('should persist the completed flag when toggling a task', () async {
      final task = buildPlanningTask(id: 'a', date: _monday);
      final repo = FakePlanningTaskRepository([task]);
      final container = _container(repo);
      await container.read(planningBoardProvider.future);

      await container.read(planningBoardProvider.notifier).toggleTask(task, isCompleted: true);

      expect(container.read(planningBoardProvider).value!.single.isCompleted, isTrue);
      expect(repo.items.single.isCompleted, isTrue);
    });

    test('should remove a deleted task from state', () async {
      final task = buildPlanningTask(id: 'a', date: _monday);
      final repo = FakePlanningTaskRepository([task]);
      final container = _container(repo);
      await container.read(planningBoardProvider.future);

      await container.read(planningBoardProvider.notifier).deleteTask(task);

      expect(container.read(planningBoardProvider).value, isEmpty);
      expect(repo.items, isEmpty);
    });
  });
}
