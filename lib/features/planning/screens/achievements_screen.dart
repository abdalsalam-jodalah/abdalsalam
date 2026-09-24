import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/planning/achievement.dart';
import '../../../data/models/planning/goal.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/planning_providers.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  static const routeName = '/planning/achievements';

  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  static const String _achievementLoggedMessage = 'Achievement logged';

  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAchievementDialog),
        ],
      ),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(achievementsProvider),
        ),
        data: (achievements) {
          if (achievements.isEmpty) {
            return const Center(child: Text('No achievements yet. Tap + to log one.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(achievementsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(achievement.title),
                    subtitle: Text(
                      achievement.description == null || achievement.description!.isEmpty
                          ? _formatDate(achievement.achievedAt)
                          : '${achievement.description}\n${_formatDate(achievement.achievedAt)}',
                    ),
                    isThreeLine: achievement.description != null && achievement.description!.isNotEmpty,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _showAchievementDialog() async {
    final allGoals = ref.read(activeGoalsProvider).maybeWhen(data: (list) => list, orElse: () => const <Goal>[]);

    final result = await showDialog<_AchievementDialogResult>(
      context: context,
      builder: (_) => _AchievementDialogContent(allGoals: allGoals, formatDate: _formatDate),
    );

    if (result == null) return;

    GoalScope? scope;
    if (result.selectedGoalId != null) {
      for (final goal in allGoals) {
        if (goal.id == result.selectedGoalId) {
          scope = goal.scope;
          break;
        }
      }
    }

    final service = ref.read(achievementServiceProvider);
    final now = DateTime.now();
    final saveResult = await service.create(
      Achievement(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: planningUserId,
        goalId: result.selectedGoalId,
        title: result.title,
        description: result.description.isEmpty ? null : result.description,
        achievedAt: result.achievedAt,
        scope: scope,
      ),
    );

    if (!mounted) return;
    if (saveResult.isFailure) {
      AppFeedback.showError(context, saveResult.error!);
      return;
    }
    AppFeedback.showSuccess(context, _achievementLoggedMessage);
    ref.invalidate(achievementsProvider);
  }
}

class _AchievementDialogResult {
  _AchievementDialogResult({
    required this.title,
    required this.description,
    required this.achievedAt,
    required this.selectedGoalId,
  });

  final String title;
  final String description;
  final DateTime achievedAt;
  final String? selectedGoalId;
}

class _AchievementDialogContent extends StatefulWidget {
  const _AchievementDialogContent({required this.allGoals, required this.formatDate});

  final List<Goal> allGoals;
  final String Function(DateTime date) formatDate;

  @override
  State<_AchievementDialogContent> createState() => _AchievementDialogContentState();
}

class _AchievementDialogContentState extends State<_AchievementDialogContent> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime achievedAt = DateTime.now();
  String? selectedGoalId;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Achievement'),
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
              DropdownButtonFormField<String?>(
                initialValue: selectedGoalId,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Not linked to a goal')),
                  for (final goal in widget.allGoals)
                    DropdownMenuItem<String?>(value: goal.id, child: Text(goal.title)),
                ],
                onChanged: (value) => setState(() => selectedGoalId = value),
                decoration: const InputDecoration(labelText: 'Related goal (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Achieved on'),
                subtitle: Text(widget.formatDate(achievedAt)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: achievedAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (!mounted) return;
                  if (picked != null) {
                    setState(() => achievedAt = picked);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                _AchievementDialogResult(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  achievedAt: achievedAt,
                  selectedGoalId: selectedGoalId,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
