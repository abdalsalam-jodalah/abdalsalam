import '../../../data/models/planning/planning_task.dart';
import 'day_planning_range.dart';

class PlanningTaskArranger {
  const PlanningTaskArranger._();

  static List<PlanningTask> sortForDisplay(Iterable<PlanningTask> tasks) {
    return tasks.toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.order.compareTo(b.order);
      });
  }

  static List<PlanningTask> unassignedTasks(Iterable<PlanningTask> tasks) {
    return sortForDisplay(tasks.where((task) => task.date == null && task.goalId == null));
  }

  static Map<DateTime, List<PlanningTask>> groupByDate(Iterable<PlanningTask> tasks) {
    final grouped = <DateTime, List<PlanningTask>>{};
    for (final task in tasks) {
      final date = task.date;
      if (date != null) {
        grouped.putIfAbsent(DayPlanningRange.dateOnly(date), () => <PlanningTask>[]).add(task);
      }
    }
    return grouped.map((date, dayTasks) => MapEntry(date, sortForDisplay(dayTasks)));
  }

  static List<PlanningTask> tasksOn(Iterable<PlanningTask> tasks, DateTime? date) {
    if (date == null) {
      return unassignedTasks(tasks);
    }
    final target = DayPlanningRange.dateOnly(date);
    return sortForDisplay(tasks.where((task) => task.date != null && DayPlanningRange.dateOnly(task.date!) == target));
  }

  static List<PlanningTask> move({
    required List<PlanningTask> tasks,
    required String taskId,
    required DateTime? targetDate,
    required int targetIndex,
    required DateTime now,
  }) {
    final moving = tasks.where((task) => task.id == taskId).firstOrNull;
    if (moving == null) {
      return const <PlanningTask>[];
    }
    final targetDay = targetDate == null ? null : DayPlanningRange.dateOnly(targetDate);
    final sourceDay = moving.date == null ? null : DayPlanningRange.dateOnly(moving.date!);
    final isSameContainer = sourceDay == targetDay;

    final sourceBefore = tasksOn(tasks, sourceDay);
    final originalIndex = sourceBefore.indexWhere((task) => task.id == taskId);
    final targetBefore = isSameContainer ? sourceBefore : tasksOn(tasks, targetDay);

    var insertionIndex = targetIndex.clamp(0, targetBefore.length);
    if (isSameContainer && originalIndex < insertionIndex) {
      insertionIndex -= 1;
    }
    if (isSameContainer && originalIndex == insertionIndex) {
      return const <PlanningTask>[];
    }

    final targetAfter = targetBefore.where((task) => task.id != taskId).toList();
    targetAfter.insert(
      insertionIndex,
      moving.copyWith(date: targetDay, clearDate: targetDay == null, clearGoalId: targetDay == null),
    );

    final changed = <PlanningTask>[
      for (var index = 0; index < targetAfter.length; index++)
        if (targetAfter[index].id == taskId || targetAfter[index].order != index)
          targetAfter[index].copyWith(order: index, updatedAt: now),
    ];

    if (!isSameContainer) {
      final sourceAfter = sourceBefore.where((task) => task.id != taskId).toList();
      for (var index = 0; index < sourceAfter.length; index++) {
        if (sourceAfter[index].order != index) {
          changed.add(sourceAfter[index].copyWith(order: index, updatedAt: now));
        }
      }
    }
    return changed;
  }
}
