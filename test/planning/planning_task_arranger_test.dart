import 'package:abdalsalam/data/models/planning/planning_task.dart';
import 'package:abdalsalam/features/planning/services/planning_task_arranger.dart';
import 'package:flutter_test/flutter_test.dart';

import 'planning_fakes.dart';

final DateTime _monday = DateTime(2026, 3, 9);
final DateTime _tuesday = DateTime(2026, 3, 10);
final DateTime _now = DateTime(2026, 3, 9, 12);

PlanningTask _task(String id, {DateTime? date, int order = 0, bool isCompleted = false, String? goalId}) {
  return buildPlanningTask(id: id, date: date, goalId: goalId).copyWith(order: order, isCompleted: isCompleted);
}

Map<String, PlanningTask> _applied(List<PlanningTask> tasks, List<PlanningTask> changed) {
  final byId = {for (final task in tasks) task.id: task};
  for (final task in changed) {
    byId[task.id] = task;
  }
  return byId;
}

List<String> _idsOn(Map<String, PlanningTask> byId, DateTime? date) =>
    PlanningTaskArranger.tasksOn(byId.values, date).map((task) => task.id).toList();

void main() {
  group('PlanningTaskArranger.sortForDisplay', () {
    test('should place completed tasks after incomplete ones keeping their order', () {
      final sorted = PlanningTaskArranger.sortForDisplay([
        _task('done-1', order: 0, isCompleted: true),
        _task('open-2', order: 2),
        _task('open-1', order: 1),
      ]);

      expect(sorted.map((task) => task.id), ['open-1', 'open-2', 'done-1']);
    });
  });

  group('PlanningTaskArranger.unassignedTasks', () {
    test('should exclude dated tasks and goal tasks', () {
      final unassigned = PlanningTaskArranger.unassignedTasks([
        _task('free'),
        _task('dated', date: _monday),
        _task('goal-task', goalId: 'goal-1'),
      ]);

      expect(unassigned.map((task) => task.id), ['free']);
    });
  });

  group('PlanningTaskArranger.move', () {
    test('should reorder within a day when dropped before an earlier task', () {
      final tasks = [
        _task('a', date: _monday, order: 0),
        _task('b', date: _monday, order: 1),
        _task('c', date: _monday, order: 2),
      ];

      final changed = PlanningTaskArranger.move(
        tasks: tasks,
        taskId: 'c',
        targetDate: _monday,
        targetIndex: 0,
        now: _now,
      );

      expect(_idsOn(_applied(tasks, changed), _monday), ['c', 'a', 'b']);
    });

    test('should reorder within a day when dropped after a later task', () {
      final tasks = [
        _task('a', date: _monday, order: 0),
        _task('b', date: _monday, order: 1),
        _task('c', date: _monday, order: 2),
      ];

      final changed = PlanningTaskArranger.move(
        tasks: tasks,
        taskId: 'a',
        targetDate: _monday,
        targetIndex: 3,
        now: _now,
      );

      expect(_idsOn(_applied(tasks, changed), _monday), ['b', 'c', 'a']);
    });

    test('should return nothing when the task is dropped where it already is', () {
      final tasks = [_task('a', date: _monday, order: 0), _task('b', date: _monday, order: 1)];

      expect(
        PlanningTaskArranger.move(tasks: tasks, taskId: 'a', targetDate: _monday, targetIndex: 1, now: _now),
        isEmpty,
      );
      expect(
        PlanningTaskArranger.move(tasks: tasks, taskId: 'a', targetDate: _monday, targetIndex: 0, now: _now),
        isEmpty,
      );
    });

    test('should move a task to another day and reindex both days', () {
      final tasks = [
        _task('a', date: _monday, order: 0),
        _task('b', date: _monday, order: 1),
        _task('x', date: _tuesday, order: 0),
      ];

      final changed = PlanningTaskArranger.move(
        tasks: tasks,
        taskId: 'a',
        targetDate: _tuesday,
        targetIndex: 0,
        now: _now,
      );

      final result = _applied(tasks, changed);
      expect(_idsOn(result, _monday), ['b']);
      expect(result['b']!.order, 0);
      expect(_idsOn(result, _tuesday), ['a', 'x']);
      expect(result['a']!.date, _tuesday);
    });

    test('should move an unassigned task onto a day', () {
      final tasks = [_task('free'), _task('x', date: _monday, order: 0)];

      final changed = PlanningTaskArranger.move(
        tasks: tasks,
        taskId: 'free',
        targetDate: _monday,
        targetIndex: 1,
        now: _now,
      );

      final result = _applied(tasks, changed);
      expect(_idsOn(result, _monday), ['x', 'free']);
      expect(PlanningTaskArranger.unassignedTasks(result.values), isEmpty);
    });

    test('should clear the date and goal link when moving a task to unassigned', () {
      final tasks = [_task('a', date: _monday, goalId: 'goal-1')];

      final changed = PlanningTaskArranger.move(
        tasks: tasks,
        taskId: 'a',
        targetDate: null,
        targetIndex: 0,
        now: _now,
      );

      expect(changed.single.date, isNull);
      expect(changed.single.goalId, isNull);
    });

    test('should keep the completed flag when moving between days', () {
      final tasks = [_task('a', date: _monday, isCompleted: true)];

      final changed = PlanningTaskArranger.move(
        tasks: tasks,
        taskId: 'a',
        targetDate: _tuesday,
        targetIndex: 0,
        now: _now,
      );

      expect(changed.single.isCompleted, isTrue);
    });

    test('should return nothing when the task does not exist', () {
      expect(
        PlanningTaskArranger.move(tasks: const [], taskId: 'ghost', targetDate: _monday, targetIndex: 0, now: _now),
        isEmpty,
      );
    });
  });
}
