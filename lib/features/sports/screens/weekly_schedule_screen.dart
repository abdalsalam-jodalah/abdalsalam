import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/weekly_schedule_entry.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/show_app_bottom_sheet.dart';
import '../providers/sports_providers.dart';
import '../widgets/reorderable_sport_list.dart';

const _uuid = Uuid();

const List<String> _dayLabels = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class WeeklyScheduleScreen extends ConsumerStatefulWidget {
  static const routeName = '/sports/schedule';
  static const String title = 'Weekly Schedule';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SportsScreen] shell.
  final bool embedded;

  const WeeklyScheduleScreen({super.key, this.embedded = false});

  @override
  ConsumerState<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends ConsumerState<WeeklyScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this, initialIndex: DateTime.now().weekday - 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final tabBar = TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: [for (final label in _dayLabels) Tab(text: label)],
    );

    final tabView = TabBarView(
      controller: _tabController,
      children: [
        for (var day = 1; day <= 7; day++) _DayScheduleList(key: ValueKey('day-$day'), dayOfWeek: day),
      ],
    );

    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(tokens.spacing.lg, tokens.spacing.lg, tokens.spacing.sm, 0),
            child: AppSectionHeader(title: WeeklyScheduleScreen.title, padding: EdgeInsets.zero),
          ),
          tabBar,
          Expanded(child: tabView),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(WeeklyScheduleScreen.title), bottom: tabBar),
      body: tabView,
    );
  }
}

/// A [ConsumerStatefulWidget] rather than a stateless [ConsumerWidget] so
/// [ref] stays bound to a stable [State] across the `await` calls below —
/// see the comment on [SportsCategorySection] in
/// widgets/sports_category_section.dart.
class _DayScheduleList extends ConsumerStatefulWidget {
  final int dayOfWeek;

  const _DayScheduleList({super.key, required this.dayOfWeek});

  @override
  ConsumerState<_DayScheduleList> createState() => _DayScheduleListState();
}

class _DayScheduleListState extends ConsumerState<_DayScheduleList> {
  static const String _emptyTitle = 'Nothing assigned yet';
  static const String _emptySubtitle = 'No exercises assigned to this day yet.';
  static const String _assignLabel = 'Assign exercise';
  static const String _unknownExerciseLabel = 'Unknown exercise';

  int get dayOfWeek => widget.dayOfWeek;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final entriesAsync = ref.watch(scheduleForDayProvider(dayOfWeek));
    final exercisesAsync = ref.watch(allActiveExercisesProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(scheduleForDayProvider(dayOfWeek)),
      ),
      data: (entries) {
        return exercisesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(allActiveExercisesProvider),
          ),
          data: (allExercises) {
            final exerciseById = {for (final exercise in allExercises) exercise.id: exercise};

            return ListView(
              padding: EdgeInsets.all(tokens.spacing.lg),
              children: [
                ReorderableSportList<WeeklyScheduleEntry>(
                  items: entries,
                  keyOf: (entry) => entry.id,
                  emptyState: const EmptyState(
                    title: _emptyTitle,
                    subtitle: _emptySubtitle,
                    icon: Icons.event_repeat_outlined,
                    isCompact: true,
                  ),
                  itemBuilder: (context, entry, index) {
                    final exercise = exerciseById[entry.exerciseId];
                    return Padding(
                      padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                      child: AppCard(
                        key: ValueKey('tile-${entry.id}'),
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.drag_indicator),
                          title: Text(exercise?.name ?? _unknownExerciseLabel),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeEntry(entry),
                          ),
                        ),
                      ),
                    );
                  },
                  onReorder: (reordered) => _reorderEntries(reordered),
                ),
                SizedBox(height: tokens.spacing.md),
                OutlinedButton.icon(
                  onPressed: () => _showAddExerciseSheet(allExercises, entries),
                  icon: const Icon(Icons.add),
                  label: const Text(_assignLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _reorderEntries(List<WeeklyScheduleEntry> reordered) async {
    final service = ref.read(weeklyScheduleServiceProvider);
    final updated = [
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(order: i, updatedAt: DateTime.now()),
    ];
    final updateResult = await service.updateBulk(updated);
    if (!mounted) {
      return;
    }
    if (updateResult.isFailure) {
      AppFeedback.showError(context, updateResult.error!);
    }
    ref.invalidate(scheduleForDayProvider(dayOfWeek));
  }

  Future<void> _removeEntry(WeeklyScheduleEntry entry) async {
    final service = ref.read(weeklyScheduleServiceProvider);
    final deleteResult = await service.softDelete(entry.id);
    if (!mounted) {
      return;
    }
    if (deleteResult.isFailure) {
      AppFeedback.showError(context, deleteResult.error!);
    }
    ref.invalidate(scheduleForDayProvider(dayOfWeek));
  }

  Future<void> _showAddExerciseSheet(
    List<Exercise> allExercises,
    List<WeeklyScheduleEntry> currentEntries,
  ) async {
    final assignedIds = currentEntries.map((entry) => entry.exerciseId).toSet();
    final available = allExercises.where((exercise) => !assignedIds.contains(exercise.id)).toList();

    final selected = await showAppBottomSheet<Exercise>(
      context,
      title: _assignLabel,
      builder: (sheetContext) {
        if (available.isEmpty) {
          return const Text('All exercises are already assigned to this day, or none exist yet.');
        }
        return ListView(
          shrinkWrap: true,
          children: [
            for (final exercise in available)
              ListTile(
                title: Text(exercise.name),
                onTap: () => Navigator.pop(sheetContext, exercise),
              ),
          ],
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    final service = ref.read(weeklyScheduleServiceProvider);
    final now = DateTime.now();
    final createResult = await service.create(
      WeeklyScheduleEntry(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: sportUserId,
        dayOfWeek: dayOfWeek,
        exerciseId: selected.id,
        order: currentEntries.length,
      ),
    );
    if (!mounted) {
      return;
    }
    if (createResult.isFailure) {
      AppFeedback.showError(context, createResult.error!);
    }
    ref.invalidate(scheduleForDayProvider(dayOfWeek));
  }
}
