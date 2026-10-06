import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/planning_task.dart';
import 'day_card_header.dart';
import 'day_highlight.dart';
import 'drag_auto_scroll_view.dart';
import 'planning_drag_controller.dart';
import 'planning_task_actions.dart';
import 'planning_task_column.dart';

class DayTasksCard extends StatelessWidget {
  static const Duration _collapseDuration = Duration(milliseconds: 200);
  static const Duration _highlightDuration = Duration(milliseconds: 120);
  static const double _emphasisBorderWidth = 2;

  final DateTime date;
  final DateTime today;
  final List<PlanningTask> tasks;
  final bool isColumn;
  final bool isCollapsed;
  final PlanningDragController dragController;
  final PlanningTaskActions actions;
  final VoidCallback onAdd;
  final VoidCallback? onToggleCollapsed;

  const DayTasksCard({
    super.key,
    required this.date,
    required this.today,
    required this.tasks,
    required this.dragController,
    required this.actions,
    required this.onAdd,
    this.isColumn = false,
    this.isCollapsed = false,
    this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colors = Theme.of(context).colorScheme;
    final highlight = DayHighlight.of(date, today);
    final completedCount = tasks.where((task) => task.isCompleted).length;
    final taskColumn = PlanningTaskColumn(tasks: tasks, date: date, dragController: dragController, actions: actions);

    return DragTarget<PlanningTask>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => actions.onDrop(details.data, date, tasks.length),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: _highlightDuration,
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? colors.primaryContainer : highlight.cardColor(colors),
          borderRadius: tokens.radius.largeBorder,
          border: Border.all(color: colors.outlineVariant),
        ),
        foregroundDecoration: candidates.isNotEmpty || highlight.isToday
            ? BoxDecoration(
                borderRadius: tokens.radius.largeBorder,
                border: Border.all(color: colors.primary, width: _emphasisBorderWidth),
              )
            : null,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: isColumn ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DayCardHeader(
                key: ValueKey('day-header-${date.year}-${date.month}-${date.day}'),
                date: date,
                highlight: highlight,
                completedCount: completedCount,
                totalCount: tasks.length,
                onAdd: onAdd,
                onTap: isColumn ? null : onToggleCollapsed,
                trailing: isColumn
                    ? null
                    : Padding(
                        padding: EdgeInsets.only(right: tokens.spacing.sm),
                        child: Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
                      ),
              ),
              if (isColumn)
                Expanded(
                  child: DragAutoScrollView(
                    dragController: dragController,
                    builder: (context, controller) => SingleChildScrollView(controller: controller, child: taskColumn),
                  ),
                )
              else
                AnimatedSize(
                  duration: _collapseDuration,
                  alignment: Alignment.topCenter,
                  child: isCollapsed ? const SizedBox(width: double.infinity) : taskColumn,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
