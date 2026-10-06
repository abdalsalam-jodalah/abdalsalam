import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/planning_task.dart';
import '../services/day_planning_range.dart';
import '../services/planning_task_arranger.dart';
import 'day_planning_layout.dart';
import 'day_tasks_card.dart';
import 'drag_auto_scroll_view.dart';
import 'planning_drag_controller.dart';
import 'planning_task_actions.dart';

class DayColumnsView extends StatelessWidget {
  final DayPlanningRange range;
  final List<PlanningTask> tasks;
  final PlanningDragController dragController;
  final PlanningTaskActions actions;
  final void Function(DateTime date) onAdd;

  const DayColumnsView({
    super.key,
    required this.range,
    required this.tasks,
    required this.dragController,
    required this.actions,
    required this.onAdd,
  });

  Widget _columnFor(DateTime date, DateTime today, Map<DateTime, List<PlanningTask>> tasksByDate) {
    return DayTasksCard(
      key: ValueKey('day-column-${date.year}-${date.month}-${date.day}'),
      date: date,
      today: today,
      tasks: tasksByDate[date] ?? const <PlanningTask>[],
      isColumn: true,
      dragController: dragController,
      actions: actions,
      onAdd: () => onAdd(date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final today = DayPlanningRange.dateOnly(DateTime.now());
    final tasksByDate = PlanningTaskArranger.groupByDate(tasks);
    final days = range.days;
    const gap = DayPlanningLayout.columnGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - spacing.md * 2;
        final fittingColumnWidth = (availableWidth - gap * (days.length - 1)) / days.length;
        final padding = EdgeInsets.fromLTRB(spacing.md, spacing.xs, spacing.md, spacing.md);

        if (days.length == 1) {
          return Padding(
            padding: padding,
            child: Center(
              child: SizedBox(
                width: math.min(availableWidth, DayPlanningLayout.singleColumnMaxWidth),
                child: _columnFor(days.first, today, tasksByDate),
              ),
            ),
          );
        }

        if (fittingColumnWidth >= DayPlanningLayout.minColumnWidth) {
          return Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < days.length; index++) ...[
                  if (index > 0) const SizedBox(width: gap),
                  Expanded(child: _columnFor(days[index], today, tasksByDate)),
                ],
              ],
            ),
          );
        }

        const columnWidth = DayPlanningLayout.scrollingColumnWidth;
        final todayIndex = days.indexOf(today);
        final initialOffset = todayIndex < 0 ? 0.0 : todayIndex * (columnWidth + gap);
        return DragAutoScrollView(
          axis: Axis.horizontal,
          dragController: dragController,
          initialScrollOffset: initialOffset,
          builder: (context, controller) => ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: padding,
            itemCount: days.length,
            separatorBuilder: (context, index) => const SizedBox(width: gap),
            itemBuilder: (context, index) =>
                SizedBox(width: columnWidth, child: _columnFor(days[index], today, tasksByDate)),
          ),
        );
      },
    );
  }
}
