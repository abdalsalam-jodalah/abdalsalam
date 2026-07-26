import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/planning/goal.dart';
import '../../../data/models/planning/plan_topic.dart';
import '../../../data/models/planning/planning_task.dart';
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
        error: (error, stack) => const Center(child: Text('Failed to load topics')),
        data: (topics) {
          if (topics.isEmpty) {
            return const Center(child: Text('No topics yet. Tap + to add one.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final topic in topics) _TopicTile(topic: topic)],
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

  final repo = ref.read(planTopicRepositoryProvider);
  final now = DateTime.now();

  if (existing == null) {
    await repo.create(
      PlanTopic(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: planningUserId,
        title: result.title,
        description: result.description.isEmpty ? null : result.description,
        parentTopicId: parentTopicId,
      ),
    );
  } else {
    await repo.update(
      existing.copyWith(title: result.title, description: result.description.isEmpty ? null : result.description, updatedAt: now),
    );
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? (widget.parentTopicId == null ? 'New Topic' : 'New Sub-topic') : 'Edit'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                _TopicDialogResult(titleController.text.trim(), descriptionController.text.trim()),
              );
            }
          },
          child: Text(widget.existing == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}

Future<void> _deleteTopic(WidgetRef ref, PlanTopic topic) async {
  final repo = ref.read(planTopicRepositoryProvider);
  await repo.softDelete(topic.id);
  if (topic.parentTopicId == null) {
    ref.invalidate(rootTopicsProvider);
  } else {
    ref.invalidate(subTopicsProvider(topic.parentTopicId!));
  }
}

class _TopicTile extends ConsumerWidget {
  final PlanTopic topic;

  const _TopicTile({required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subTopicsAsync = ref.watch(subTopicsProvider(topic.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(topic.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: topic.description != null && topic.description!.isNotEmpty
            ? Text(topic.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: PopupMenuButton<_TopicMenuAction>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case _TopicMenuAction.addChild:
                _showTopicDialog(context, ref, parentTopicId: topic.id);
              case _TopicMenuAction.edit:
                _showTopicDialog(context, ref, parentTopicId: topic.parentTopicId, existing: topic);
              case _TopicMenuAction.delete:
                _deleteTopic(ref, topic);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: _TopicMenuAction.addChild, child: Text('Add sub-topic')),
            PopupMenuItem(value: _TopicMenuAction.edit, child: Text('Edit')),
            PopupMenuItem(value: _TopicMenuAction.delete, child: Text('Delete')),
          ],
        ),
        children: subTopicsAsync.when(
          loading: () => const [Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator())],
          error: (error, stack) => const [Padding(padding: EdgeInsets.all(12), child: Text('Failed to load sub-topics'))],
          data: (subTopics) => [for (final subTopic in subTopics) _SubTopicTile(subTopic: subTopic)],
        ),
      ),
    );
  }
}

class _SubTopicTile extends ConsumerWidget {
  final PlanTopic subTopic;

  const _SubTopicTile({required this.subTopic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsForTopicProvider(subTopic.id));

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ExpansionTile(
        title: Text(subTopic.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subTopic.description != null && subTopic.description!.isNotEmpty
            ? Text(subTopic.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: PopupMenuButton<_TopicMenuAction>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case _TopicMenuAction.addChild:
                showGoalEditorDialog(context, ref, topicId: subTopic.id);
              case _TopicMenuAction.edit:
                _showTopicDialog(context, ref, parentTopicId: subTopic.parentTopicId, existing: subTopic);
              case _TopicMenuAction.delete:
                _deleteTopic(ref, subTopic);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: _TopicMenuAction.addChild, child: Text('Add goal')),
            PopupMenuItem(value: _TopicMenuAction.edit, child: Text('Edit')),
            PopupMenuItem(value: _TopicMenuAction.delete, child: Text('Delete')),
          ],
        ),
        children: goalsAsync.when(
          loading: () => const [Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator())],
          error: (error, stack) => const [Padding(padding: EdgeInsets.all(12), child: Text('Failed to load goals'))],
          data: (goals) => [for (final goal in goals) _GoalTile(goal: goal)],
        ),
      ),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  final Goal goal;

  const _GoalTile({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksForGoalProvider(goal.id));

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.flag_outlined),
        title: Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(goalStatusLabel(goal.status)),
        trailing: PopupMenuButton<_TopicMenuAction>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case _TopicMenuAction.addChild:
                _addTask(context, ref);
              case _TopicMenuAction.edit:
                showGoalEditorDialog(context, ref, existing: goal, topicId: goal.topicId);
              case _TopicMenuAction.delete:
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: _TopicMenuAction.addChild, child: Text('Add task')),
            PopupMenuItem(value: _TopicMenuAction.edit, child: Text('Edit goal')),
          ],
        ),
        children: [
          tasksAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (error, stack) => const Padding(padding: EdgeInsets.all(12), child: Text('Failed to load tasks')),
            data: (tasks) => ReorderableTaskList(
              tasks: tasks,
              onToggle: (task, completed) => _toggleTask(ref, task, completed),
              onEdit: (task) => _editTask(context, ref, task),
              onDelete: (task) => _deleteTask(ref, task),
              onReorder: (reordered) => _reorderTasks(ref, reordered),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final currentTasks = ref.read(tasksForGoalProvider(goal.id)).maybeWhen(
          data: (list) => list,
          orElse: () => const <PlanningTask>[],
        );
    await showPlanningTaskDialog(context, ref, fixedGoalId: goal.id, order: currentTasks.length);
  }

  Future<void> _editTask(BuildContext context, WidgetRef ref, PlanningTask task) async {
    await showPlanningTaskDialog(context, ref, existing: task, fixedGoalId: goal.id);
  }

  Future<void> _toggleTask(WidgetRef ref, PlanningTask task, bool completed) async {
    final repo = ref.read(planningTaskRepositoryProvider);
    await repo.update(task.copyWith(isCompleted: completed, updatedAt: DateTime.now()));
    ref.invalidate(tasksForGoalProvider(goal.id));
  }

  Future<void> _deleteTask(WidgetRef ref, PlanningTask task) async {
    final repo = ref.read(planningTaskRepositoryProvider);
    await repo.softDelete(task.id);
    ref.invalidate(tasksForGoalProvider(goal.id));
  }

  Future<void> _reorderTasks(WidgetRef ref, List<PlanningTask> reordered) async {
    final repo = ref.read(planningTaskRepositoryProvider);
    final updated = [
      for (var i = 0; i < reordered.length; i++) reordered[i].copyWith(order: i, updatedAt: DateTime.now()),
    ];
    await repo.updateBulk(updated);
    ref.invalidate(tasksForGoalProvider(goal.id));
  }
}
