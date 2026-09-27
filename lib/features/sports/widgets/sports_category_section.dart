import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/exercise_category.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../providers/sports_providers.dart';
import 'sports_exercise_dialog.dart';

const _uuid = Uuid();

/// A [ConsumerStatefulWidget] rather than a stateless [ConsumerWidget] so
/// [ref] stays bound to a stable [State] across the `await showDialog(...)`
/// calls below — using a stateless widget's per-build `ref` across an await
/// risks the widget's element being disposed/reused mid-flight, which
/// crashes once the stale ref is used again.
class SportsCategorySection extends ConsumerStatefulWidget {
  final ExerciseCategory category;

  const SportsCategorySection({super.key, required this.category});

  @override
  ConsumerState<SportsCategorySection> createState() => _SportsCategorySectionState();
}

class _SportsCategorySectionState extends ConsumerState<SportsCategorySection> {
  static const String _emptyMessage = 'No exercises in this category yet.';
  static const String _addExerciseTooltip = 'Add exercise';
  static const String _editAction = 'edit';
  static const String _deleteAction = 'delete';

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(exercisesByCategoryProvider(widget.category.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: widget.category.name,
          action: IconButton(
            icon: const Icon(Icons.add),
            tooltip: _addExerciseTooltip,
            onPressed: () => _showExerciseDialog(),
          ),
        ),
        exercisesAsync.when(
          loading: () => Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
            child: const LinearProgressIndicator(),
          ),
          error: (error, stack) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(exercisesByCategoryProvider(widget.category.id)),
          ),
          data: (exercises) {
            if (exercises.isEmpty) {
              return Text(
                _emptyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              );
            }
            return Column(
              children: [
                for (final exercise in exercises)
                  Padding(
                    padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                    child: EntityTile(
                      key: ValueKey(exercise.id),
                      icon: exercise.trackingType == ExerciseTrackingType.cardio
                          ? Icons.directions_run_rounded
                          : Icons.fitness_center_rounded,
                      title: exercise.name,
                      subtitle: _subtitleFor(exercise),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == _editAction) {
                            await _showExerciseDialog(exercise: exercise);
                          } else if (value == _deleteAction) {
                            await _deleteExercise(exercise);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: _editAction, child: Text('Edit')),
                          PopupMenuItem(value: _deleteAction, child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _subtitleFor(Exercise exercise) {
    final parts = <String>[];
    if (exercise.trackingType == ExerciseTrackingType.reps) {
      if (exercise.defaultSets != null || exercise.defaultReps != null) {
        parts.add('${exercise.defaultSets ?? '-'} x ${exercise.defaultReps ?? '-'}');
      }
      if (exercise.defaultWeightKg != null) {
        parts.add('${exercise.defaultWeightKg} kg');
      }
    }
    if (exercise.equipment != null && exercise.equipment!.isNotEmpty) {
      parts.add(exercise.equipment!);
    }
    parts.add(exercise.difficulty.name);
    if (exercise.instructions != null && exercise.instructions!.isNotEmpty) {
      parts.add(exercise.instructions!);
    }
    return parts.join(' • ');
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final service = ref.read(exerciseServiceProvider);
    final deleteResult = await service.softDelete(exercise.id);
    if (!mounted) {
      return;
    }
    if (deleteResult.isFailure) {
      AppFeedback.showError(context, deleteResult.error!);
    }
    ref.invalidate(exercisesByCategoryProvider(widget.category.id));
    ref.invalidate(allActiveExercisesProvider);
  }

  Future<void> _showExerciseDialog({Exercise? exercise}) async {
    final result = await showSportsExerciseDialog(context, exercise: exercise);

    if (result == null) return;

    if (!mounted) {
      return;
    }
    final service = ref.read(exerciseServiceProvider);
    final now = DateTime.now();

    AppError? failure;
    if (exercise == null) {
      final existing = ref.read(exercisesByCategoryProvider(widget.category.id)).maybeWhen(
            data: (list) => list,
            orElse: () => const <Exercise>[],
          );
      final createResult = await service.create(
        Exercise(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
          userId: sportUserId,
          name: result.name,
          categoryId: widget.category.id,
          trackingType: result.trackingType,
          difficulty: result.difficulty,
          equipment: result.equipment.isEmpty ? null : result.equipment,
          defaultSets: result.defaultSets,
          defaultReps: result.defaultReps,
          defaultWeightKg: result.defaultWeight,
          instructions: result.instructions.isEmpty ? null : result.instructions,
          order: existing.length,
        ),
      );
      failure = createResult.isFailure ? createResult.error : null;
    } else {
      final updateResult = await service.update(
        exercise.copyWith(
          name: result.name,
          trackingType: result.trackingType,
          difficulty: result.difficulty,
          equipment: result.equipment.isEmpty ? null : result.equipment,
          defaultSets: result.defaultSets,
          defaultReps: result.defaultReps,
          defaultWeightKg: result.defaultWeight,
          instructions: result.instructions.isEmpty ? null : result.instructions,
          updatedAt: now,
        ),
      );
      failure = updateResult.isFailure ? updateResult.error : null;
    }

    if (!mounted) {
      return;
    }
    if (failure != null) {
      AppFeedback.showError(context, failure);
    }
    ref.invalidate(exercisesByCategoryProvider(widget.category.id));
    ref.invalidate(allActiveExercisesProvider);
  }
}
