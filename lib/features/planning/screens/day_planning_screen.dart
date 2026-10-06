import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/planning_task.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/planning_board_provider.dart';
import '../services/day_planning_range.dart';
import '../services/day_planning_view_mode.dart';
import '../services/planning_task_arranger.dart';
import 'task_categories_screen.dart';
import '../widgets/custom_days_dialog.dart';
import '../widgets/day_planning_layout.dart';
import '../widgets/day_planning_page.dart';
import '../widgets/day_planning_view_selector.dart';
import '../widgets/planning_drag_controller.dart';
import '../widgets/planning_task_actions.dart';
import '../widgets/planning_task_dialog.dart';
import '../widgets/unassigned_tasks_panel.dart';

class DayPlanningScreen extends ConsumerStatefulWidget {
  static const routeName = '/planning/day';

  const DayPlanningScreen({super.key});

  @override
  ConsumerState<DayPlanningScreen> createState() => _DayPlanningScreenState();
}

class _DayPlanningScreenState extends ConsumerState<DayPlanningScreen> {
  static const int _basePage = 5000;
  static const double _edgeFlipZone = 40;
  static const Duration _edgeFlipDwell = Duration(milliseconds: 700);
  static const Duration _pageAnimationDuration = Duration(milliseconds: 300);
  static final DateTime _earliestDate = DateTime(2020);
  static final DateTime _latestDate = DateTime(2100);

  final PageController _pageController = PageController(initialPage: _basePage);
  final PlanningDragController _dragController = PlanningDragController();
  final Set<DateTime> _collapsedDays = <DateTime>{};

  DateTime _originAnchor = DayPlanningRange.dateOnly(DateTime.now());
  DayPlanningViewMode _viewMode = DayPlanningViewMode.day;
  int _customDays = DayPlanningRange.defaultCustomDays;
  int _pageOffset = 0;
  Timer? _edgeFlipTimer;
  int _edgeDirection = 0;

  @override
  void initState() {
    super.initState();
    _dragController.addListener(_cancelEdgeFlipWhenDragEnds);
  }

  @override
  void dispose() {
    _edgeFlipTimer?.cancel();
    _dragController
      ..removeListener(_cancelEdgeFlipWhenDragEnds)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  DateTime _anchorForOffset(int offset) =>
      DayPlanningRange.shiftAnchor(_viewMode, _originAnchor, offset, customDays: _customDays);

  int get _weekStartDay {
    final settings = ref.read(appSettingsProvider).value;
    return DayPlanningRange.weekStartDayFromSetting(settings?['firstDayOfWeek']);
  }

  DayPlanningRange _rangeForOffset(int offset) => DayPlanningRange.of(
    _viewMode,
    _anchorForOffset(offset),
    customDays: _customDays,
    weekStartDay: _weekStartDay,
  );

  String get _title {
    final range = _rangeForOffset(_pageOffset);
    return switch (_viewMode) {
      DayPlanningViewMode.day => AppDateFormatter.date(range.start),
      DayPlanningViewMode.month => AppDateFormatter.monthYear(range.start),
      DayPlanningViewMode.week ||
      DayPlanningViewMode.custom => '${AppDateFormatter.shortDate(range.start)} – ${AppDateFormatter.date(range.end)}',
    };
  }

  void _restartAt({required DateTime anchor, DayPlanningViewMode? mode, int? customDays}) {
    setState(() {
      _originAnchor = DayPlanningRange.dateOnly(anchor);
      _viewMode = mode ?? _viewMode;
      _customDays = customDays ?? _customDays;
      _pageOffset = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_basePage);
    }
  }

  void _flipPage(int direction) {
    if (!_pageController.hasClients) return;
    unawaited(
      _pageController.animateToPage(
        _basePage + _pageOffset + direction,
        duration: _pageAnimationDuration,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorForOffset(_pageOffset),
      firstDate: _earliestDate,
      lastDate: _latestDate,
    );
    if (!mounted || picked == null) return;
    _restartAt(anchor: picked);
  }

  Future<void> _selectViewMode(DayPlanningViewMode mode) async {
    if (mode == DayPlanningViewMode.custom) {
      await _editCustomDays(switchToCustom: true);
      return;
    }
    _restartAt(anchor: _anchorForOffset(_pageOffset), mode: mode);
  }

  Future<void> _editCustomDays({bool switchToCustom = false}) async {
    final days = await showCustomDaysDialog(context, initialDays: _customDays);
    if (!mounted || days == null) return;
    _restartAt(
      anchor: _anchorForOffset(_pageOffset),
      mode: switchToCustom ? DayPlanningViewMode.custom : null,
      customDays: days,
    );
  }

  void _handleDragPointer(PointerEvent event, {required double pagesLeft, required double pagesRight}) {
    if (!_dragController.isDragging) {
      _cancelEdgeFlip();
      return;
    }
    final x = event.localPosition.dx;
    final isNearLeftEdge = x >= pagesLeft && x < pagesLeft + _edgeFlipZone;
    final isNearRightEdge = x <= pagesRight && x > pagesRight - _edgeFlipZone;
    final direction = isNearLeftEdge ? -1 : (isNearRightEdge ? 1 : 0);
    if (direction == _edgeDirection) return;
    _cancelEdgeFlip();
    _edgeDirection = direction;
    if (direction != 0) {
      _edgeFlipTimer = Timer.periodic(_edgeFlipDwell, (_) => _flipPage(direction));
    }
  }

  void _cancelEdgeFlipWhenDragEnds() {
    if (!_dragController.isDragging) {
      _cancelEdgeFlip();
    }
  }

  void _cancelEdgeFlip() {
    _edgeFlipTimer?.cancel();
    _edgeFlipTimer = null;
    _edgeDirection = 0;
  }

  void _toggleCollapsed(DateTime date) {
    setState(() {
      if (!_collapsedDays.remove(date)) {
        _collapsedDays.add(date);
      }
    });
  }

  List<PlanningTask> get _boardTasks => ref.read(planningBoardProvider).value ?? const <PlanningTask>[];

  Future<void> _addTask(DateTime? date) {
    return showPlanningTaskDialog(
      context,
      ref,
      date: date,
      order: PlanningTaskArranger.tasksOn(_boardTasks, date).length,
    );
  }

  Future<void> _editTask(PlanningTask task) {
    return showPlanningTaskDialog(context, ref, existing: task, date: task.date, fixedGoalId: task.goalId);
  }

  Future<void> _reportFailure(Future<AppError?> operation) async {
    final error = await operation;
    if (!mounted || error == null) return;
    AppFeedback.showError(context, error);
  }

  void _dropTask(PlanningTask dropped, DateTime? date, int index) {
    unawaited(
      _reportFailure(
        ref.read(planningBoardProvider.notifier).moveTask(taskId: dropped.id, targetDate: date, targetIndex: index),
      ),
    );
  }

  void _toggleTask(PlanningTask task, bool completed) {
    unawaited(_reportFailure(ref.read(planningBoardProvider.notifier).toggleTask(task, isCompleted: completed)));
  }

  void _deleteTask(PlanningTask task) {
    unawaited(_reportFailure(ref.read(planningBoardProvider.notifier).deleteTask(task)));
  }

  PlanningTaskActions get _taskActions => PlanningTaskActions(
    onDrop: _dropTask,
    onToggle: _toggleTask,
    onEdit: _editTask,
    onDelete: _deleteTask,
  );

  Widget _buildPages(List<PlanningTask> tasks, {required bool useColumns}) {
    final actions = _taskActions;
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (page) => setState(() => _pageOffset = page - _basePage),
      itemBuilder: (context, page) => DayPlanningPage(
        range: _rangeForOffset(page - _basePage),
        tasks: tasks,
        useColumns: useColumns,
        collapsedDays: _collapsedDays,
        dragController: _dragController,
        actions: actions,
        onToggleCollapsed: _toggleCollapsed,
        onAdd: _addTask,
      ),
    );
  }

  Widget _buildBody(List<PlanningTask> tasks, BoxConstraints constraints) {
    final spacing = AppThemeTokens.of(context).spacing;
    final isWide = DayPlanningLayout.isWide(constraints.maxWidth);
    final actions = _taskActions;
    final unassigned = PlanningTaskArranger.unassignedTasks(tasks);
    final selector = Padding(
      padding: EdgeInsets.fromLTRB(spacing.lg, spacing.md, spacing.lg, spacing.md),
      child: DayPlanningViewSelector(
        mode: _viewMode,
        customDays: _customDays,
        onModeChanged: _selectViewMode,
        onEditCustomDays: _editCustomDays,
      ),
    );
    final pagesLeft = isWide ? DayPlanningLayout.sidePanelWidth + spacing.md : 0.0;
    final canFlipOnEdges = !isWide || _viewMode == DayPlanningViewMode.day;

    return Listener(
      onPointerMove: (event) {
        if (canFlipOnEdges) {
          _handleDragPointer(event, pagesLeft: pagesLeft, pagesRight: constraints.maxWidth);
        }
      },
      onPointerUp: (_) => _cancelEdgeFlip(),
      onPointerCancel: (_) => _cancelEdgeFlip(),
      child: Column(
        children: [
          selector,
          if (isWide)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: DayPlanningLayout.sidePanelWidth + spacing.md,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(spacing.md, spacing.xs, 0, spacing.md),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: UnassignedTasksPanel(
                          isSidePanel: true,
                          tasks: unassigned,
                          dragController: _dragController,
                          actions: actions,
                          onAdd: () => _addTask(null),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _buildPages(tasks, useColumns: true)),
                ],
              ),
            )
          else ...[
            Padding(
              padding: EdgeInsets.fromLTRB(spacing.md, 0, spacing.md, spacing.sm),
              child: UnassignedTasksPanel(
                tasks: unassigned,
                dragController: _dragController,
                actions: actions,
                onAdd: () => _addTask(null),
              ),
            ),
            Expanded(child: _buildPages(tasks, useColumns: false)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(planningBoardProvider);
    ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Task categories',
            icon: const Icon(Icons.label_outline),
            onPressed: () => Navigator.of(context).pushNamed(TaskCategoriesScreen.routeName),
          ),
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _flipPage(-1)),
          IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: _pickDate),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _flipPage(1)),
        ],
      ),
      body: boardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AsyncErrorView(error: error, onRetry: () => ref.invalidate(planningBoardProvider)),
        data: (tasks) => LayoutBuilder(builder: (context, constraints) => _buildBody(tasks, constraints)),
      ),
    );
  }
}
