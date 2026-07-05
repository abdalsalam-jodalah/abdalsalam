import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/planning/achievement.dart';
import '../../../data/models/planning/goal.dart';
import '../providers/planning_providers.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  static const routeName = '/planning/achievements';

  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
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
        error: (error, stack) => const Center(child: Text('Failed to load achievements')),
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
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime achievedAt = DateTime.now();
    String? selectedGoalId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
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
                      for (final goal in allGoals)
                        DropdownMenuItem<String?>(value: goal.id, child: Text(goal.title)),
                    ],
                    onChanged: (value) => setDialogState(() => selectedGoalId = value),
                    decoration: const InputDecoration(labelText: 'Related goal (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Achieved on'),
                    subtitle: Text(_formatDate(achievedAt)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: achievedAt,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => achievedAt = picked);
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
              child: const Text('Save'),
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

    GoalScope? scope;
    if (selectedGoalId != null) {
      for (final goal in allGoals) {
        if (goal.id == selectedGoalId) {
          scope = goal.scope;
          break;
        }
      }
    }

    final repo = ref.read(achievementRepositoryProvider);
    final now = DateTime.now();
    final result = await repo.create(
      Achievement(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: planningUserId,
        goalId: selectedGoalId,
        title: title,
        description: description.isEmpty ? null : description,
        achievedAt: achievedAt,
        scope: scope,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? 'Achievement logged' : 'Something went wrong'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
    ref.invalidate(achievementsProvider);
  }
}
