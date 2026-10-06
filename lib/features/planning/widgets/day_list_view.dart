import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/planning_task.dart';
import '../services/day_planning_range.dart';
import '../services/planning_task_arranger.dart';
import 'day_tasks_card.dart';
import 'drag_auto_scroll_view.dart';
import 'planning_drag_controller.dart';
import 'planning_task_actions.dart';

class DayListView extends StatefulWidget {
  final DayPlanningRange range;
  final List<PlanningTask> tasks;
  final Set<DateTime> collapsedDays;
  final PlanningDragController dragController;
  final PlanningTaskActions actions;
  final void Function(DateTime date) onToggleCollapsed;
  final void Function(DateTime date) onAdd;

  const DayListView({
    super.key,
    required this.range,
    required this.tasks,
    required this.collapsedDays,
    required this.dragController,
    required this.actions,
    required this.onToggleCollapsed,
    required this.onAdd,
  });

  @override
  State<DayListView> createState() => _DayListViewState();
}

class _DayListViewState extends State<DayListView> {
  static const double _todayAlignment = 0.05;

  final GlobalKey _todayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealToday());
  }

  void _revealToday() {
    final todayContext = _todayKey.currentContext;
    if (!mounted || todayContext == null) return;
    unawaited(Scrollable.ensureVisible(todayContext, alignment: _todayAlignment));
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final today = DayPlanningRange.dateOnly(DateTime.now());
    final tasksByDate = PlanningTaskArranger.groupByDate(widget.tasks);
    return DragAutoScrollView(
      dragController: widget.dragController,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(spacing.md, spacing.xs, spacing.md, spacing.xl),
        child: Column(
          children: [
            for (final date in widget.range.days)
              Padding(
                padding: EdgeInsets.only(bottom: spacing.md),
                child: DayTasksCard(
                  key: date == today ? _todayKey : ValueKey('day-card-${date.year}-${date.month}-${date.day}'),
                  date: date,
                  today: today,
                  tasks: tasksByDate[date] ?? const <PlanningTask>[],
                  isCollapsed: widget.collapsedDays.contains(date),
                  dragController: widget.dragController,
                  actions: widget.actions,
                  onAdd: () => widget.onAdd(date),
                  onToggleCollapsed: () => widget.onToggleCollapsed(date),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
