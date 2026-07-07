import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/planning/goal.dart';
import '../providers/planning_providers.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  static const routeName = '/planning/goals';

  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _uuid = const Uuid();
  GoalScope? _selectedScope;
  LifeArea? _selectedArea;

  String _scopeLabel(GoalScope scope) {
    switch (scope) {
      case GoalScope.life:
        return 'Life';
      case GoalScope.yearly:
        return 'Yearly';
      case GoalScope.quarterly:
        return 'Quarterly';
      case GoalScope.monthly:
        return 'Monthly';
      case GoalScope.weekly:
        return 'Weekly';
      case GoalScope.daily:
        return 'Daily';
    }
  }

  String _areaLabel(LifeArea area) {
    switch (area) {
      case LifeArea.mind:
        return 'Mind';
      case LifeArea.body:
        return 'Body';
      case LifeArea.money:
        return 'Money';
      case LifeArea.soul:
        return 'Soul';
    }
  }

  String _statusLabel(GoalStatus status) {
    switch (status) {
      case GoalStatus.notStarted:
        return 'Not started';
      case GoalStatus.inProgress:
        return 'In progress';
      case GoalStatus.achieved:
        return 'Achieved';
      case GoalStatus.abandoned:
        return 'Abandoned';
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(activeGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showGoalDialog()),
        ],
      ),
      body: Column(
        children: [
          _buildScopeFilter(),
          _buildAreaFilter(),
          Expanded(
            child: goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Center(child: Text('Failed to load goals')),
              data: (goals) {
                final filtered = goals
                    .where((goal) => _selectedScope == null || goal.scope == _selectedScope)
                    .where((goal) => _selectedArea == null || goal.area == _selectedArea)
                    .toList(growable: false);

                if (filtered.isEmpty) {
                  return const Center(child: Text('No goals yet. Tap + to add one.'));
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(activeGoalsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildGoalCard(filtered[index], goals),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _selectedScope == null,
              onSelected: (_) => setState(() => _selectedScope = null),
            ),
            const SizedBox(width: 8),
            for (final scope in GoalScope.values) ...[
              ChoiceChip(
                label: Text(_scopeLabel(scope)),
                selected: _selectedScope == scope,
                onSelected: (_) => setState(() => _selectedScope = scope),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAreaFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('All areas'),
              selected: _selectedArea == null,
              onSelected: (_) => setState(() => _selectedArea = null),
            ),
            const SizedBox(width: 8),
            for (final area in LifeArea.values) ...[
              ChoiceChip(
                label: Text(_areaLabel(area)),
                selected: _selectedArea == area,
                onSelected: (_) => setState(() => _selectedArea = area),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, List<Goal> allGoals) {
    Goal? parent;
    if (goal.parentGoalId != null) {
      for (final candidate in allGoals) {
        if (candidate.id == goal.parentGoalId) {
          parent = candidate;
          break;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (goal.area != null) ...[
                  Chip(label: Text(_areaLabel(goal.area!)), visualDensity: VisualDensity.compact),
                  const SizedBox(width: 4),
                ],
                Chip(label: Text(_scopeLabel(goal.scope)), visualDensity: VisualDensity.compact),
              ],
            ),
            if (goal.description != null && goal.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(goal.description!),
            ],
            if (parent != null) ...[
              const SizedBox(height: 4),
              Text('Linked to: ${parent.title}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            LinearProgressIndicator(value: goal.progress.clamp(0.0, 1.0)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_statusLabel(goal.status), style: Theme.of(context).textTheme.bodySmall),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showGoalDialog(goal: goal),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _deleteGoal(goal),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGoalDialog({Goal? goal}) async {
    final allGoals = ref.read(activeGoalsProvider).maybeWhen(data: (list) => list, orElse: () => const <Goal>[]);
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: goal?.title ?? '');
    final descriptionController = TextEditingController(text: goal?.description ?? '');
    GoalScope selectedScope = goal?.scope ?? _selectedScope ?? GoalScope.daily;
    GoalStatus selectedStatus = goal?.status ?? GoalStatus.notStarted;
    DateTime? selectedDate = goal?.targetDate ?? DateTime.now();
    String? selectedParentId = goal?.parentGoalId;
    LifeArea? selectedArea = goal?.area ?? _selectedArea;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(goal == null ? 'New Goal' : 'Edit Goal'),
          content: SingleChildScrollView(
            child: Form(
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GoalScope>(
                    initialValue: selectedScope,
                    items: GoalScope.values
                        .map((scope) => DropdownMenuItem(value: scope, child: Text(_scopeLabel(scope))))
                        .toList(),
                    onChanged: (value) => setDialogState(() => selectedScope = value ?? selectedScope),
                    decoration: const InputDecoration(labelText: 'Scope', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GoalStatus>(
                    initialValue: selectedStatus,
                    items: GoalStatus.values
                        .map((status) => DropdownMenuItem(value: status, child: Text(_statusLabel(status))))
                        .toList(),
                    onChanged: (value) => setDialogState(() => selectedStatus = value ?? selectedStatus),
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedParentId,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None')),
                      for (final candidate in allGoals.where((g) => g.id != goal?.id))
                        DropdownMenuItem<String?>(value: candidate.id, child: Text(candidate.title)),
                    ],
                    onChanged: (value) => setDialogState(() => selectedParentId = value),
                    decoration: const InputDecoration(labelText: 'Linked goal (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<LifeArea>(
                    initialValue: selectedArea,
                    items: LifeArea.values
                        .map((area) => DropdownMenuItem(value: area, child: Text(_areaLabel(area))))
                        .toList(),
                    onChanged: (value) => setDialogState(() => selectedArea = value),
                    validator: (value) => value == null ? 'Pick a life area' : null,
                    decoration: const InputDecoration(labelText: 'Life area', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Target date'),
                    subtitle: Text(selectedDate == null
                        ? 'Not set'
                        : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(goal == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      titleController.dispose();
      descriptionController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    titleController.dispose();
    descriptionController.dispose();

    final repo = ref.read(goalRepositoryProvider);
    final now = DateTime.now();

    final result = goal == null
        ? await repo.create(
            Goal(
              id: _uuid.v4(),
              createdAt: now,
              updatedAt: now,
              userId: planningUserId,
              title: title,
              description: description.isEmpty ? null : description,
              scope: selectedScope,
              status: selectedStatus,
              targetDate: selectedDate,
              parentGoalId: selectedParentId,
              area: selectedArea,
            ),
          )
        : await repo.update(
            goal.copyWith(
              title: title,
              description: description.isEmpty ? null : description,
              scope: selectedScope,
              status: selectedStatus,
              targetDate: selectedDate,
              parentGoalId: selectedParentId,
              area: selectedArea,
              updatedAt: now,
            ),
          );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? (goal == null ? 'Goal created' : 'Goal updated') : 'Something went wrong'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
    ref.invalidate(activeGoalsProvider);
    ref.invalidate(todaysGoalsProvider);
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final result = await ref.read(goalRepositoryProvider).softDelete(goal.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? 'Goal deleted' : 'Something went wrong'),
        backgroundColor: result.isSuccess ? Colors.red : Colors.grey,
      ),
    );
    ref.invalidate(activeGoalsProvider);
    ref.invalidate(todaysGoalsProvider);
  }
}
