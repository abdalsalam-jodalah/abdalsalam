import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/habits/habit.dart';
import '../../../data/models/habits/habit_log.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/stat_tile.dart';
import '../providers/habits_providers.dart';
import '../widgets/habits_widgets.dart';
import '../widgets/log_habit_sheet.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';

class HabitsHomeScreen extends ConsumerWidget {
  static const routeName = '/habits/home';

  static const String _title = 'Habits Home';
  static const String _newHabitLabel = 'New Habit';
  static const String _buildingTitle = 'Building';
  static const String _breakingTitle = 'Breaking';
  static const String _noGoodHabitsTitle = 'No good habits yet';
  static const String _noGoodHabitsSubtitle = 'Add one above to start building a streak.';
  static const String _noBadHabitsTitle = 'No bad habits tracked';
  static const String _noBadHabitsSubtitle = 'Track a habit you want to break.';

  const HabitsHomeScreen({super.key});

  Future<void> _openNewHabit(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).pushNamed(HabitFormScreen.routeName);
    if (!context.mounted) {
      return;
    }
    ref.invalidate(activeHabitsProvider);
  }

  Future<void> _openDetail(BuildContext context, Habit habit) async {
    await Navigator.of(context).pushNamed(HabitDetailScreen.routeName, arguments: habit.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final habitsAsync = ref.watch(activeHabitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: habitsAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(activeHabitsProvider),
        ),
        data: (habits) {
          final goodHabits = habits.where((habit) => habit.isGoodHabit).toList(growable: false);
          final badHabits = habits.where((habit) => !habit.isGoodHabit).toList(growable: false);

          return ListView(
            padding: EdgeInsets.all(tokens.spacing.lg),
            children: [
              FilledButton.icon(
                onPressed: () => _openNewHabit(context, ref),
                icon: const Icon(Icons.add),
                label: const Text(_newHabitLabel),
              ),
              SizedBox(height: tokens.spacing.md),
              _TodayCompletionCard(goodHabits: goodHabits),
              AppSectionHeader(title: _buildingTitle),
              if (goodHabits.isEmpty)
                EmptyState(title: _noGoodHabitsTitle, subtitle: _noGoodHabitsSubtitle, isCompact: true)
              else
                for (final habit in goodHabits)
                  Padding(
                    padding: EdgeInsets.only(bottom: tokens.spacing.md),
                    child: _HabitCardEntry(habit: habit, onTap: () => _openDetail(context, habit)),
                  ),
              AppSectionHeader(title: _breakingTitle),
              if (badHabits.isEmpty)
                EmptyState(title: _noBadHabitsTitle, subtitle: _noBadHabitsSubtitle, isCompact: true)
              else
                for (final habit in badHabits)
                  Padding(
                    padding: EdgeInsets.only(bottom: tokens.spacing.md),
                    child: _HabitCardEntry(habit: habit, onTap: () => _openDetail(context, habit)),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _TodayCompletionCard extends ConsumerWidget {
  static const String _completionTodayLabel = 'Completion Today';

  final List<Habit> goodHabits;

  const _TodayCompletionCard({required this.goodHabits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (goodHabits.isEmpty) {
      return const SizedBox.shrink();
    }
    final tokens = AppThemeTokens.of(context);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final accent = AppModuleAccents.forModule('habits');

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.md),
      child: Consumer(
        builder: (context, ref, _) {
          final logsAsync = <AsyncValue<List<HabitLog>>>[
            for (final habit in goodHabits) ref.watch(logsForHabitProvider(habit.id)),
          ];
          final loaded = logsAsync.every((value) => value.hasValue);
          if (!loaded) {
            return const LoadingSkeleton(lines: 1, isScrollable: false);
          }
          final completedToday = logsAsync.where((value) {
            final logs = value.value ?? const <HabitLog>[];
            return logs.any((log) {
              final completedAt = log.completedAt;
              return DateTime(completedAt.year, completedAt.month, completedAt.day) == todayOnly;
            });
          }).length;
          final percent = goodHabits.isEmpty ? 0 : (completedToday / goodHabits.length * 100).round();
          return StatTile(
            icon: Icons.task_alt_rounded,
            label: _completionTodayLabel,
            value: '$completedToday / ${goodHabits.length}',
            caption: '$percent%',
            accentColor: accent,
          );
        },
      ),
    );
  }
}

class _HabitCardEntry extends ConsumerWidget {
  final Habit habit;
  final VoidCallback onTap;

  const _HabitCardEntry({required this.habit, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(habitStatisticsProvider(habit.id));
    final streak = statsAsync.value?['currentStreak'] as int? ?? 0;
    return HabitCard(
      habit: habit,
      currentStreak: streak,
      onTap: onTap,
      onCheckIn: () => showLogHabitSheet(context, ref, habit),
    );
  }
}
