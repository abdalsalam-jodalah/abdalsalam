import 'package:flutter/material.dart';

import '../../../data/models/planning/planning_task.dart';
import '../services/day_planning_range.dart';
import 'day_columns_view.dart';
import 'day_list_view.dart';
import 'planning_drag_controller.dart';
import 'planning_task_actions.dart';

class DayPlanningPage extends StatelessWidget {
  final DayPlanningRange range;
  final List<PlanningTask> tasks;
  final bool useColumns;
  final Set<DateTime> collapsedDays;
  final PlanningDragController dragController;
  final PlanningTaskActions actions;
  final void Function(DateTime date) onToggleCollapsed;
  final void Function(DateTime date) onAdd;

  const DayPlanningPage({
    super.key,
    required this.range,
    required this.tasks,
    required this.useColumns,
    required this.collapsedDays,
    required this.dragController,
    required this.actions,
    required this.onToggleCollapsed,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (useColumns) {
      return DayColumnsView(
        range: range,
        tasks: tasks,
        dragController: dragController,
        actions: actions,
        onAdd: onAdd,
      );
    }
    return DayListView(
      range: range,
      tasks: tasks,
      collapsedDays: collapsedDays,
      dragController: dragController,
      actions: actions,
      onToggleCollapsed: onToggleCollapsed,
      onAdd: onAdd,
    );
  }
}
