import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/weekly_schedule_entry.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Text(
                  'Weekly Schedule',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          tabBar,
          Expanded(child: tabView),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Schedule'), bottom: tabBar),
      body: tabView,
    );
  }
}

/// A [ConsumerStatefulWidget] rather than a stateless [ConsumerWidget] so
/// [ref] stays bound to a stable [State] across the `await` calls below —
/// see the comment on `_CategorySection` in exercise_library_screen.dart.
class _DayScheduleList extends ConsumerStatefulWidget {
  final int dayOfWeek;

  const _DayScheduleList({super.key, required this.dayOfWeek});

  @override
  ConsumerState<_DayScheduleList> createState() => _DayScheduleListState();
}

class _DayScheduleListState extends ConsumerState<_DayScheduleList> {
  int get dayOfWeek => widget.dayOfWeek;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(scheduleForDayProvider(dayOfWeek));
    final exercisesAsync = ref.watch(allActiveExercisesProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Center(child: Text('Failed to load schedule')),
      data: (entries) {
        return exercisesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Center(child: Text('Failed to load exercises')),
          data: (allExercises) {
            final exerciseById = {for (final exercise in allExercises) exercise.id: exercise};

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ReorderableSportList<WeeklyScheduleEntry>(
                  items: entries,
                  keyOf: (entry) => entry.id,
                  emptyState: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No exercises assigned to this day yet.'),
                  ),
                  itemBuilder: (context, entry, index) {
                    final exercise = exerciseById[entry.exerciseId];
                    return ListTile(
                      key: ValueKey('tile-${entry.id}'),
                      leading: const Icon(Icons.drag_indicator),
                      title: Text(exercise?.name ?? 'Unknown exercise'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeEntry(entry),
                      ),
                    );
                  },
                  onReorder: (reordered) => _reorderEntries(reordered),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAddExerciseSheet(allExercises, entries),
                  icon: const Icon(Icons.add),
                  label: const Text('Assign exercise'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _reorderEntries(List<WeeklyScheduleEntry> reordered) async {
    final repo = ref.read(weeklyScheduleRepositoryProvider);
    final updated = [
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(order: i, updatedAt: DateTime.now()),
    ];
    await repo.updateBulk(updated);
    if (!mounted) {
      return;
    }
    ref.invalidate(scheduleForDayProvider(dayOfWeek));
  }

  Future<void> _removeEntry(WeeklyScheduleEntry entry) async {
    final repo = ref.read(weeklyScheduleRepositoryProvider);
    await repo.softDelete(entry.id);
    if (!mounted) {
      return;
    }
    ref.invalidate(scheduleForDayProvider(dayOfWeek));
  }

  Future<void> _showAddExerciseSheet(
    List<Exercise> allExercises,
    List<WeeklyScheduleEntry> currentEntries,
  ) async {
    final assignedIds = currentEntries.map((entry) => entry.exerciseId).toSet();
    final available = allExercises.where((exercise) => !assignedIds.contains(exercise.id)).toList();

    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      builder: (sheetContext) {
        if (available.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('All exercises are already assigned to this day, or none exist yet.'),
          );
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

    final repo = ref.read(weeklyScheduleRepositoryProvider);
    final now = DateTime.now();
    await repo.create(
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
    ref.invalidate(scheduleForDayProvider(dayOfWeek));
  }
}
