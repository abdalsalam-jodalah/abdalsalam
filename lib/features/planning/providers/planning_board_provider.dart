import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../data/models/planning/planning_task.dart';
import '../services/planning_task_arranger.dart';
import 'planning_providers.dart';

class PlanningBoardNotifier extends AsyncNotifier<List<PlanningTask>> {
  @override
  Future<List<PlanningTask>> build() async {
    final result = await ref.watch(planningTaskServiceProvider).getBoardTasks();
    return result.getOrThrow();
  }

  Future<AppError?> moveTask({
    required String taskId,
    required DateTime? targetDate,
    required int targetIndex,
  }) async {
    final current = state.value;
    if (current == null) return null;
    final changed = PlanningTaskArranger.move(
      tasks: current,
      taskId: taskId,
      targetDate: targetDate,
      targetIndex: targetIndex,
      now: DateTime.now(),
    );
    return _applyOptimistically(changed);
  }

  Future<AppError?> toggleTask(PlanningTask task, {required bool isCompleted}) {
    return _applyOptimistically([task.copyWith(isCompleted: isCompleted, updatedAt: DateTime.now())]);
  }

  Future<AppError?> deleteTask(PlanningTask task) async {
    final current = state.value;
    if (current == null) return null;
    state = AsyncData(current.where((item) => item.id != task.id).toList(growable: false));
    final result = await ref.read(planningTaskServiceProvider).softDelete(task.id);
    if (result.isFailure) {
      ref.invalidateSelf();
      return result.error;
    }
    return null;
  }

  Future<AppError?> _applyOptimistically(List<PlanningTask> changed) async {
    final current = state.value;
    if (current == null || changed.isEmpty) return null;
    final changedById = {for (final task in changed) task.id: task};
    state = AsyncData([for (final task in current) changedById[task.id] ?? task]);
    final result = await ref.read(planningTaskServiceProvider).updateBulk(changed);
    if (result.isFailure) {
      ref.invalidateSelf();
      return result.error;
    }
    return null;
  }
}

final planningBoardProvider = AsyncNotifierProvider<PlanningBoardNotifier, List<PlanningTask>>(
  PlanningBoardNotifier.new,
);
