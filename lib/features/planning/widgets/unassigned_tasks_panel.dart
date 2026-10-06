import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/planning_task.dart';
import 'drag_auto_scroll_view.dart';
import 'planning_drag_controller.dart';
import 'planning_task_actions.dart';
import 'planning_task_column.dart';

class UnassignedTasksPanel extends StatefulWidget {
  static const String title = 'Unassigned tasks';
  static const double _maxBodyHeight = 240;
  static const Duration _collapseDuration = Duration(milliseconds: 200);

  final List<PlanningTask> tasks;
  final PlanningDragController dragController;
  final PlanningTaskActions actions;
  final VoidCallback onAdd;
  final bool isSidePanel;

  const UnassignedTasksPanel({
    super.key,
    required this.tasks,
    required this.dragController,
    required this.actions,
    required this.onAdd,
    this.isSidePanel = false,
  });

  @override
  State<UnassignedTasksPanel> createState() => _UnassignedTasksPanelState();
}

class _UnassignedTasksPanelState extends State<UnassignedTasksPanel> {
  bool _isExpanded = true;

  Widget _animatedBody(Widget body) {
    return AnimatedSize(
      duration: UnassignedTasksPanel._collapseDuration,
      alignment: Alignment.topCenter,
      child: _isExpanded ? body : const SizedBox(width: double.infinity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colors = Theme.of(context).colorScheme;
    final body = DragAutoScrollView(
      dragController: widget.dragController,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        child: PlanningTaskColumn(
          tasks: widget.tasks,
          date: null,
          dragController: widget.dragController,
          actions: widget.actions,
        ),
      ),
    );

    return DragTarget<PlanningTask>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => widget.actions.onDrop(details.data, null, widget.tasks.length),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? colors.primaryContainer : colors.surfaceContainerLow,
          borderRadius: tokens.radius.largeBorder,
          border: Border.all(
            color: candidates.isNotEmpty ? colors.primary : colors.outlineVariant,
            width: candidates.isNotEmpty ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.inbox_rounded),
                title: Text('${UnassignedTasksPanel.title} (${widget.tasks.length})'),
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Add task',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: widget.onAdd,
                    ),
                    Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
              if (widget.isSidePanel)
                Flexible(child: _animatedBody(body))
              else
                _animatedBody(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: UnassignedTasksPanel._maxBodyHeight),
                    child: body,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
