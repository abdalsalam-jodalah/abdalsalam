import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sports/exercise.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../providers/sports_providers.dart';

class SportsCategoryBreakdownCard extends ConsumerStatefulWidget {
  static const String _title = 'Category breakdown';

  final DateRangeQuery range;

  const SportsCategoryBreakdownCard({super.key, required this.range});

  @override
  ConsumerState<SportsCategoryBreakdownCard> createState() => _SportsCategoryBreakdownCardState();
}

class _SportsCategoryBreakdownCardState extends ConsumerState<SportsCategoryBreakdownCard> {
  static const String _noCategoriesMessage = 'No categories yet — add some in the Library tab.';
  static const String _noSessionsMessage = 'No logged sessions for this category in the selected period.';
  static const int _progressionWindowDays = 90;
  static const double _progressionChartHeight = 160;

  String? _selectedCategoryId;
  String? _selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: SportsCategoryBreakdownCard._title, padding: EdgeInsets.zero),
          AsyncSection(
            value: categoriesAsync,
            onRetry: () => ref.invalidate(exerciseCategoriesProvider),
            builder: (categories) {
              if (categories.isEmpty) {
                return Text(_noCategoriesMessage, style: Theme.of(context).textTheme.bodyMedium);
              }
              _selectedCategoryId ??= categories.first.id;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(value: category.id, child: Text(category.name)),
                    ],
                    onChanged: (value) => setState(() {
                      _selectedCategoryId = value;
                      _selectedExerciseId = null;
                    }),
                  ),
                  SizedBox(height: spacing.md),
                  if (_selectedCategoryId != null) _buildExerciseBreakdown(context, _selectedCategoryId!),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseBreakdown(BuildContext context, String categoryId) {
    final exercisesAsync = ref.watch(exercisesByCategoryProvider(categoryId));
    final logsAsync = ref.watch(logsInRangeProvider(widget.range));
    return AsyncSection(
      value: exercisesAsync,
      onRetry: () => ref.invalidate(exercisesByCategoryProvider(categoryId)),
      builder: (exercises) => AsyncSection(
        value: logsAsync,
        onRetry: () => ref.invalidate(logsInRangeProvider(widget.range)),
        builder: (logs) {
          final exerciseIds = exercises.map((exercise) => exercise.id).toSet();
          final countByExercise = <String, int>{};
          for (final log in logs) {
            if (exerciseIds.contains(log.exerciseId)) {
              countByExercise[log.exerciseId] = (countByExercise[log.exerciseId] ?? 0) + 1;
            }
          }
          if (countByExercise.isEmpty) {
            return Text(_noSessionsMessage, style: Theme.of(context).textTheme.bodyMedium);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final exercise in exercises.where((exercise) => countByExercise.containsKey(exercise.id)))
                ListTile(
                  dense: true,
                  title: Text(exercise.name),
                  trailing: Text('${countByExercise[exercise.id]}x'),
                  selected: _selectedExerciseId == exercise.id,
                  onTap: () => setState(() => _selectedExerciseId = exercise.id),
                ),
              if (_selectedExerciseId != null) ...[
                SizedBox(height: AppThemeTokens.of(context).spacing.md),
                _buildProgressionChart(context, _selectedExerciseId!, exercises),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressionChart(BuildContext context, String exerciseId, List<Exercise> exercises) {
    Exercise? exercise;
    for (final item in exercises) {
      if (item.id == exerciseId) {
        exercise = item;
        break;
      }
    }
    if (exercise == null) {
      return const SizedBox.shrink();
    }
    final resolvedExercise = exercise;
    final today = dateOnly(DateTime.now());
    final range = (start: today.subtract(const Duration(days: _progressionWindowDays)), end: today);

    if (resolvedExercise.trackingType == ExerciseTrackingType.cardio) {
      final logsAsync = ref.watch(
        logsForExerciseInRangeProvider((exerciseId: exerciseId, start: range.start, end: range.end)),
      );
      return AsyncSection(
        value: logsAsync,
        onRetry: () => ref.invalidate(
          logsForExerciseInRangeProvider((exerciseId: exerciseId, start: range.start, end: range.end)),
        ),
        builder: (logs) => _progressionChart(
          context,
          '${resolvedExercise.name} — steps',
          [for (final log in logs) if (log.steps != null) log.steps!.toDouble()],
        ),
      );
    }

    final setsAsync = ref.watch(
      setsForExerciseInRangeProvider((exerciseId: exerciseId, start: range.start, end: range.end)),
    );
    return AsyncSection(
      value: setsAsync,
      onRetry: () => ref.invalidate(
        setsForExerciseInRangeProvider((exerciseId: exerciseId, start: range.start, end: range.end)),
      ),
      builder: (sets) => _progressionChart(
        context,
        '${resolvedExercise.name} — weight (kg)',
        [for (final set in sets) if (set.weightKg != null) set.weightKg!],
      ),
    );
  }

  Widget _progressionChart(BuildContext context, String title, List<double> points) {
    final spacing = AppThemeTokens.of(context).spacing;
    if (points.isEmpty) {
      return Text('No data yet for $title.', style: Theme.of(context).textTheme.bodyMedium);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacing.sm),
        AppLineChart(
          points: points,
          color: AppModuleAccents.forModule('sports'),
          height: _progressionChartHeight,
        ),
      ],
    );
  }
}
