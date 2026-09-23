import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/planning/goal.dart';
import '../providers/planning_providers.dart';
import '../widgets/goal_editor_dialog.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  static const routeName = '/planning/goals';

  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  GoalScope? _selectedScope;
  LifeArea? _selectedArea;

  String _scopeLabel(GoalScope scope) => goalScopeLabel(scope);

  String _areaLabel(LifeArea area) => goalAreaLabel(area);

  String _statusLabel(GoalStatus status) => goalStatusLabel(status);

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
    await showGoalEditorDialog(
      context,
      ref,
      existing: goal,
      initialScope: _selectedScope,
      initialArea: _selectedArea,
    );
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

    final result = await ref.read(goalServiceProvider).softDelete(goal.id);
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
