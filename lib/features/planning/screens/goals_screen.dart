import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/goal.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/filter_bar.dart';
import '../../../shared/widgets/ui/filter_option.dart';
import '../../../shared/widgets/ui/progress_bar.dart';
import '../../../shared/widgets/ui/show_confirm_dialog.dart';
import '../providers/planning_providers.dart';
import '../widgets/goal_editor_dialog.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  static const routeName = '/planning/goals';

  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  static const String _goalDeletedMessage = 'Goal deleted';
  static const String _emptyTitle = 'No goals yet';
  static const String _emptySubtitle = 'Tap + to add one.';

  GoalScope? _selectedScope;
  LifeArea? _selectedArea;

  String _scopeLabel(GoalScope scope) => goalScopeLabel(scope);

  String _areaLabel(LifeArea area) => goalAreaLabel(area);

  String _statusLabel(GoalStatus status) => goalStatusLabel(status);

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
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
          Padding(
            padding: EdgeInsets.fromLTRB(tokens.spacing.lg, tokens.spacing.md, tokens.spacing.lg, 0),
            child: FilterBar<GoalScope?>(
              options: [
                const FilterOption<GoalScope?>(null, 'All'),
                for (final scope in GoalScope.values) FilterOption<GoalScope?>(scope, _scopeLabel(scope)),
              ],
              selected: _selectedScope,
              onSelected: (value) => setState(() => _selectedScope = value),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(tokens.spacing.lg, tokens.spacing.sm, tokens.spacing.lg, tokens.spacing.sm),
            child: FilterBar<LifeArea?>(
              options: [
                const FilterOption<LifeArea?>(null, 'All areas'),
                for (final area in LifeArea.values) FilterOption<LifeArea?>(area, _areaLabel(area)),
              ],
              selected: _selectedArea,
              onSelected: (value) => setState(() => _selectedArea = value),
            ),
          ),
          Expanded(
            child: goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AsyncErrorView(
                error: error,
                onRetry: () => ref.invalidate(activeGoalsProvider),
              ),
              data: (goals) {
                final filtered = goals
                    .where((goal) => _selectedScope == null || goal.scope == _selectedScope)
                    .where((goal) => _selectedArea == null || goal.area == _selectedArea)
                    .toList(growable: false);

                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: _emptyTitle,
                    subtitle: _emptySubtitle,
                    icon: Icons.flag_rounded,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(activeGoalsProvider),
                  child: ListView.builder(
                    padding: EdgeInsets.all(tokens.spacing.lg),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(bottom: tokens.spacing.md),
                      child: _buildGoalCard(context, filtered[index], goals),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal, List<Goal> allGoals) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final accent = AppModuleAccents.forModule('planning');
    Goal? parent;
    if (goal.parentGoalId != null) {
      for (final candidate in allGoals) {
        if (candidate.id == goal.parentGoalId) {
          parent = candidate;
          break;
        }
      }
    }

    return AppCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(goal.title, style: theme.textTheme.titleMedium)),
              if (goal.area != null) ...[
                Chip(label: Text(_areaLabel(goal.area!)), visualDensity: VisualDensity.compact),
                SizedBox(width: tokens.spacing.xs),
              ],
              Chip(label: Text(_scopeLabel(goal.scope)), visualDensity: VisualDensity.compact),
            ],
          ),
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            SizedBox(height: tokens.spacing.xs),
            Text(goal.description!, style: theme.textTheme.bodyMedium),
          ],
          if (parent != null) ...[
            SizedBox(height: tokens.spacing.xs),
            Text(
              'Linked to: ${parent.title}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: tokens.spacing.sm),
          ProgressBar(value: goal.progress, color: accent),
          SizedBox(height: tokens.spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_statusLabel(goal.status), style: theme.textTheme.bodySmall),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showGoalDialog(goal: goal),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteGoal(goal),
                  ),
                ],
              ),
            ],
          ),
        ],
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
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Goal',
      message: 'Delete "${goal.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) {
      return;
    }

    final result = await ref.read(goalServiceProvider).softDelete(goal.id);
    if (!mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }
    AppFeedback.showSuccess(context, _goalDeletedMessage);
    ref.invalidate(activeGoalsProvider);
    ref.invalidate(todaysGoalsProvider);
  }
}
