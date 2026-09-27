import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/goal.dart';
import '../../../data/models/planning/plan_topic.dart';
import '../../../data/models/planning/planning_task.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/progress_ring.dart';
import '../providers/planning_providers.dart';
import '../widgets/goal_editor_dialog.dart';
import '../widgets/planning_task_dialog.dart';
import '../widgets/reorderable_task_list.dart';

const _uuid = Uuid();

enum _TopicMenuAction { addChild, edit, delete }

class LifePlanningTopicsScreen extends ConsumerWidget {
  static const routeName = '/planning/life/topics';

  const LifePlanningTopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final rootTopicsAsync = ref.watch(rootTopicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTopicDialog(context, ref, parentTopicId: null),
          ),
        ],
      ),
      body: rootTopicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(rootTopicsProvider),
        ),
        data: (topics) {
          if (topics.isEmpty) {
            return const EmptyState(
              title: 'No topics yet',
              subtitle: 'Tap + to add one.',
              icon: Icons.account_tree_rounded,
            );
          }
          return ListView(
            padding: EdgeInsets.all(tokens.spacing.lg),
            children: [
              for (final topic in topics)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spacing.md),
                  child: _TopicTile(topic: topic),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showTopicDialog(
  BuildContext context,
  WidgetRef ref, {
  required String? parentTopicId,
  PlanTopic? existing,
}) async {
  final result = await showDialog<_TopicDialogResult>(
    context: context,
    builder: (_) => _TopicDialogContent(existing: existing, parentTopicId: parentTopicId),
  );

  if (result == null) return;

  final service = ref.read(planTopicServiceProvider);
  final now = DateTime.now();

  final saveResult = existing == null
      ? await service.create(
          PlanTopic(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            userId: planningUserId,
            title: result.title,
            description: result.description.isEmpty ? null : result.description,
            parentTopicId: parentTopicId,
          ),
        )
      : await service.update(
          existing.copyWith(
            title: result.title,
            description: result.description.isEmpty ? null : result.description,
            updatedAt: now,
          ),
        );

  if (!context.mounted) return;
  if (saveResult.isFailure) {
    AppFeedback.showError(context, saveResult.error!);
    return;
  }
  if (parentTopicId == null) {
    ref.invalidate(rootTopicsProvider);
  } else {
    ref.invalidate(subTopicsProvider(parentTopicId));
  }
}

class _TopicDialogResult {
  _TopicDialogResult(this.title, this.description);

  final String title;
  final String description;
}

class _TopicDialogContent extends StatefulWidget {
  const _TopicDialogContent({required this.existing, required this.parentTopicId});

  final PlanTopic? existing;
  final String? parentTopicId;

  @override
  State<_TopicDialogContent> createState() => _TopicDialogContentState();
}

class _TopicDialogContentState extends State<_TopicDialogContent> {
  static const String _titleRequiredMessage = 'Title is required';

  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existing?.title ?? '');
    descriptionController = TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _TopicDialogResult(titleController.text.trim(), descriptionController.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return AppFormDialog(
      title: widget.existing == null ? (widget.parentTopicId == null ? 'New Topic' : 'New Sub-topic') : 'Edit',
      submitLabel: widget.existing == null ? 'Create' : 'Save',
      onSubmit: _submit,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => (value == null || value.trim().isEmpty) ? _titleRequiredMessage : null,
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _deleteTopic(BuildContext context, WidgetRef ref, PlanTopic topic) async {
  final service = ref.read(planTopicServiceProvider);
  final deleteResult = await service.softDelete(topic.id);
  if (!context.mounted) return;
  if (deleteResult.isFailure) {
    AppFeedback.showError(context, deleteResult.error!);
    return;
  }
  if (topic.parentTopicId == null) {
    ref.invalidate(rootTopicsProvider);
  } else {
    ref.invalidate(subTopicsProvider(topic.parentTopicId!));
  }
}

class _TopicTile extends ConsumerStatefulWidget {
  final PlanTopic topic;

  const _TopicTile({required this.topic});

  @override
  ConsumerState<_TopicTile> createState() => _TopicTileState();
}

class _TopicTileState extends ConsumerState<_TopicTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final topic = widget.topic;
    final accent = AppModuleAccents.forModule('planning');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntityTile(
          icon: Icons.account_tree_outlined,
          accentColor: accent,
          title: topic.title,
          subtitle: topic.description,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          trailing: PopupMenuButton<_TopicMenuAction>(
            icon: Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            onSelected: (action) async {
              switch (action) {
                case _TopicMenuAction.addChild:
                  await _showTopicDialog(context, ref, parentTopicId: topic.id);
                case _TopicMenuAction.edit:
                  await _showTopicDialog(context, ref, parentTopicId: topic.parentTopicId, existing: topic);
                case _TopicMenuAction.delete:
                  await _deleteTopic(context, ref, topic);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _TopicMenuAction.addChild, child: Text('Add sub-topic')),
              PopupMenuItem(value: _TopicMenuAction.edit, child: Text('Edit')),
              PopupMenuItem(value: _TopicMenuAction.delete, child: Text('Delete')),
            ],
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sm, left: tokens.spacing.lg),
            child: Consumer(
              builder: (context, ref, _) {
                final subTopicsAsync = ref.watch(subTopicsProvider(topic.id));
                return subTopicsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => AsyncErrorView(
                    error: error,
                    isCompact: true,
                    onRetry: () => ref.invalidate(subTopicsProvider(topic.id)),
                  ),
                  data: (subTopics) => Column(
                    children: [
                      for (final subTopic in subTopics)
                        Padding(
                          padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                          child: _SubTopicTile(subTopic: subTopic),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SubTopicTile extends ConsumerStatefulWidget {
  final PlanTopic subTopic;

  const _SubTopicTile({required this.subTopic});

  @override
  ConsumerState<_SubTopicTile> createState() => _SubTopicTileState();
}

class _SubTopicTileState extends ConsumerState<_SubTopicTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final subTopic = widget.subTopic;
    final accent = AppModuleAccents.forModule('planning');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntityTile(
          icon: Icons.label_outline_rounded,
          accentColor: accent,
          title: subTopic.title,
          subtitle: subTopic.description,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          trailing: PopupMenuButton<_TopicMenuAction>(
            icon: Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            onSelected: (action) async {
              switch (action) {
                case _TopicMenuAction.addChild:
                  await showGoalEditorDialog(context, ref, topicId: subTopic.id);
                case _TopicMenuAction.edit:
                  await _showTopicDialog(context, ref, parentTopicId: subTopic.parentTopicId, existing: subTopic);
                case _TopicMenuAction.delete:
                  await _deleteTopic(context, ref, subTopic);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _TopicMenuAction.addChild, child: Text('Add goal')),
              PopupMenuItem(value: _TopicMenuAction.edit, child: Text('Edit')),
              PopupMenuItem(value: _TopicMenuAction.delete, child: Text('Delete')),
            ],
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sm, left: tokens.spacing.lg),
            child: Consumer(
              builder: (context, ref, _) {
                final goalsAsync = ref.watch(goalsForTopicProvider(subTopic.id));
                return goalsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => AsyncErrorView(
                    error: error,
                    isCompact: true,
                    onRetry: () => ref.invalidate(goalsForTopicProvider(subTopic.id)),
                  ),
                  data: (goals) => Column(
                    children: [
                      for (final goal in goals)
                        Padding(
                          padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                          child: _GoalTile(goal: goal),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _GoalTile extends ConsumerStatefulWidget {
  final Goal goal;

  const _GoalTile({required this.goal});

  @override
  ConsumerState<_GoalTile> createState() => _GoalTileState();
}

class _GoalTileState extends ConsumerState<_GoalTile> {
  static const double _progressRingSize = 36;
  static const int _percentScale = 100;

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final goal = widget.goal;
    final accent = AppModuleAccents.forModule('planning');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntityTile(
          accentColor: accent,
          leading: ProgressRing(
            value: goal.progress,
            size: _progressRingSize,
            color: accent,
            center: Text(
              '${(goal.progress * _percentScale).round()}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          title: goal.title,
          subtitle: goalStatusLabel(goal.status),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          trailing: PopupMenuButton<_TopicMenuAction>(
            icon: Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            onSelected: (action) async {
              switch (action) {
                case _TopicMenuAction.addChild:
                  await _addTask(context, ref);
                case _TopicMenuAction.edit:
                  await showGoalEditorDialog(context, ref, existing: goal, topicId: goal.topicId);
                case _TopicMenuAction.delete:
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _TopicMenuAction.addChild, child: Text('Add task')),
              PopupMenuItem(value: _TopicMenuAction.edit, child: Text('Edit goal')),
            ],
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sm, left: tokens.spacing.lg),
            child: Consumer(
              builder: (context, ref, _) {
                final tasksAsync = ref.watch(tasksForGoalProvider(goal.id));
                return tasksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => AsyncErrorView(
                    error: error,
                    isCompact: true,
                    onRetry: () => ref.invalidate(tasksForGoalProvider(goal.id)),
                  ),
                  data: (tasks) => ReorderableTaskList(
                    tasks: tasks,
                    onToggle: (task, completed) => _toggleTask(context, ref, task, completed),
                    onEdit: (task) => _editTask(context, ref, task),
                    onDelete: (task) => _deleteTask(context, ref, task),
                    onReorder: (reordered) => _reorderTasks(context, ref, reordered),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final currentTasks = ref.read(tasksForGoalProvider(widget.goal.id)).maybeWhen(
          data: (list) => list,
          orElse: () => const <PlanningTask>[],
        );
    await showPlanningTaskDialog(context, ref, fixedGoalId: widget.goal.id, order: currentTasks.length);
  }

  Future<void> _editTask(BuildContext context, WidgetRef ref, PlanningTask task) async {
    await showPlanningTaskDialog(context, ref, existing: task, fixedGoalId: widget.goal.id);
  }

  Future<void> _toggleTask(BuildContext context, WidgetRef ref, PlanningTask task, bool completed) async {
    final service = ref.read(planningTaskServiceProvider);
    final updateResult = await service.update(task.copyWith(isCompleted: completed, updatedAt: DateTime.now()));
    if (!context.mounted) return;
    if (updateResult.isFailure) {
      AppFeedback.showError(context, updateResult.error!);
      return;
    }
    ref.invalidate(tasksForGoalProvider(widget.goal.id));
  }

  Future<void> _deleteTask(BuildContext context, WidgetRef ref, PlanningTask task) async {
    final service = ref.read(planningTaskServiceProvider);
    final deleteResult = await service.softDelete(task.id);
    if (!context.mounted) return;
    if (deleteResult.isFailure) {
      AppFeedback.showError(context, deleteResult.error!);
      return;
    }
    ref.invalidate(tasksForGoalProvider(widget.goal.id));
  }

  Future<void> _reorderTasks(BuildContext context, WidgetRef ref, List<PlanningTask> reordered) async {
    final service = ref.read(planningTaskServiceProvider);
    final updated = [
      for (var i = 0; i < reordered.length; i++) reordered[i].copyWith(order: i, updatedAt: DateTime.now()),
    ];
    final updateResult = await service.updateBulk(updated);
    if (!context.mounted) return;
    if (updateResult.isFailure) {
      AppFeedback.showError(context, updateResult.error!);
      return;
    }
    ref.invalidate(tasksForGoalProvider(widget.goal.id));
  }
}
