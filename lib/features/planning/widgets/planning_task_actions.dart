import '../../../data/models/planning/planning_task.dart';

class PlanningTaskActions {
  final void Function(PlanningTask dropped, DateTime? date, int index) onDrop;
  final void Function(PlanningTask task, bool completed) onToggle;
  final void Function(PlanningTask task) onEdit;
  final void Function(PlanningTask task) onDelete;

  const PlanningTaskActions({
    required this.onDrop,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
}
