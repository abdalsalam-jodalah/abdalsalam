import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/planning_task.dart';
import 'draggable_planning_task_tile.dart';
import 'planning_drag_controller.dart';
import 'planning_task_actions.dart';

class PlanningTaskColumn extends StatelessWidget {
  static const String _emptyHint = 'Drop tasks here';
  static const double _emptyHeight = 64;
  static const double _tailHeight = 32;
  static const Duration _highlightDuration = Duration(milliseconds: 120);

  final List<PlanningTask> tasks;
  final DateTime? date;
  final PlanningDragController dragController;
  final PlanningTaskActions actions;

  const PlanningTaskColumn({
    super.key,
    required this.tasks,
    required this.date,
    required this.dragController,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = AppThemeTokens.of(context);
    return Column(
      children: [
        for (var index = 0; index < tasks.length; index++)
          DraggablePlanningTaskTile(
            key: ValueKey(tasks[index].id),
            task: tasks[index],
            index: index,
            date: date,
            dragController: dragController,
            actions: actions,
          ),
        DragTarget<PlanningTask>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) => actions.onDrop(details.data, date, tasks.length),
          builder: (context, candidates, _) => AnimatedContainer(
            duration: _highlightDuration,
            height: tasks.isEmpty ? _emptyHeight : _tailHeight,
            margin: EdgeInsets.symmetric(horizontal: tokens.spacing.sm, vertical: tokens.spacing.xs),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: candidates.isNotEmpty ? colorScheme.primaryContainer : Colors.transparent,
              borderRadius: tokens.radius.mediumBorder,
              border: tasks.isEmpty
                  ? Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid)
                  : null,
            ),
            child: tasks.isEmpty
                ? Text(
                    _emptyHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
