import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/exercise_category.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/sports_providers.dart';

const _uuid = Uuid();

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  static const routeName = '/sports/library';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SportsScreen] shell.
  final bool embedded;

  const ExerciseLibraryScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);

    final body = categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(exerciseCategoriesProvider),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                const Text('No categories yet'),
                const SizedBox(height: 8),
                const Text('Tap + to add your first category (e.g. Chest, Back, Cardio)'),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final category in categories)
              _CategorySection(key: ValueKey(category.id), category: category),
          ],
        );
      },
    );

    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Text(
                  'Exercise Library',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.add), onPressed: _showCategoryDialog),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showCategoryDialog)],
      ),
      body: body,
    );
  }

  Future<void> _showCategoryDialog({ExerciseCategory? category}) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryNameDialogContent(category: category),
    );

    if (name == null) return;

    if (!mounted) {
      return;
    }
    final service = ref.read(exerciseCategoryServiceProvider);
    final now = DateTime.now();

    AppError? failure;
    if (category == null) {
      final existing = ref.read(exerciseCategoriesProvider).maybeWhen(
            data: (list) => list,
            orElse: () => const <ExerciseCategory>[],
          );
      final createResult = await service.create(
        ExerciseCategory(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
          userId: sportUserId,
          name: name,
          order: existing.length,
        ),
      );
      failure = createResult.isFailure ? createResult.error : null;
    } else {
      final updateResult = await service.update(category.copyWith(name: name, updatedAt: now));
      failure = updateResult.isFailure ? updateResult.error : null;
    }
    if (!mounted) {
      return;
    }
    if (failure != null) {
      AppFeedback.showError(context, failure);
    }
    ref.invalidate(exerciseCategoriesProvider);
  }
}

class _CategoryNameDialogContent extends StatefulWidget {
  const _CategoryNameDialogContent({required this.category});

  final ExerciseCategory? category;

  @override
  State<_CategoryNameDialogContent> createState() => _CategoryNameDialogContentState();
}

class _CategoryNameDialogContentState extends State<_CategoryNameDialogContent> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'New Category' : 'Edit Category'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, nameController.text.trim());
            }
          },
          child: Text(widget.category == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}

/// A [ConsumerStatefulWidget] rather than a stateless [ConsumerWidget] so
/// [ref] stays bound to a stable [State] across the `await showDialog(...)`
/// calls below — using a stateless widget's per-build `ref` across an await
/// risks the widget's element being disposed/reused mid-flight (Flutter
/// dynamic lists reconcile children positionally), which crashes with
/// 'InheritedElement._dependents.isEmpty' once the stale ref is used again.
class _CategorySection extends ConsumerStatefulWidget {
  final ExerciseCategory category;

  const _CategorySection({super.key, required this.category});

  @override
  ConsumerState<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<_CategorySection> {
  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesByCategoryProvider(widget.category.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.category.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add exercise',
                  onPressed: () => _showExerciseDialog(),
                ),
              ],
            ),
            exercisesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (error, stack) => AsyncErrorView(
                error: error,
                isCompact: true,
                onRetry: () => ref.invalidate(exercisesByCategoryProvider(widget.category.id)),
              ),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No exercises in this category yet.'),
                  );
                }
                return Column(
                  children: [
                    for (final exercise in exercises)
                      ListTile(
                        key: ValueKey(exercise.id),
                        dense: true,
                        leading: Icon(
                          exercise.trackingType == ExerciseTrackingType.cardio
                              ? Icons.directions_run
                              : Icons.fitness_center,
                        ),
                        title: Text(exercise.name),
                        subtitle: Text(_subtitleFor(exercise), maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showExerciseDialog(exercise: exercise);
                            } else if (value == 'delete') {
                              _deleteExercise(exercise);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
    final result = await showDialog<_ExerciseDialogResult>(
      context: context,
      builder: (_) => _ExerciseDialogContent(exercise: exercise),
    );

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

class _ExerciseDialogResult {
  _ExerciseDialogResult({
    required this.name,
    required this.instructions,
    required this.equipment,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultWeight,
    required this.trackingType,
    required this.difficulty,
  });

  final String name;
  final String instructions;
  final String equipment;
  final int? defaultSets;
  final int? defaultReps;
  final double? defaultWeight;
  final ExerciseTrackingType trackingType;
  final ExerciseDifficulty difficulty;
}

class _ExerciseDialogContent extends StatefulWidget {
  const _ExerciseDialogContent({required this.exercise});

  final Exercise? exercise;

  @override
  State<_ExerciseDialogContent> createState() => _ExerciseDialogContentState();
}

class _ExerciseDialogContentState extends State<_ExerciseDialogContent> {
  static const String _mustBeWholeNumberMessage = 'Must be a whole number';
  static const String _mustBeNumberMessage = 'Must be a number';

  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController instructionsController;
  late final TextEditingController equipmentController;
  late final TextEditingController setsController;
  late final TextEditingController repsController;
  late final TextEditingController weightController;
  late ExerciseTrackingType selectedType;
  late ExerciseDifficulty selectedDifficulty;

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    nameController = TextEditingController(text: exercise?.name ?? '');
    instructionsController = TextEditingController(text: exercise?.instructions ?? '');
    equipmentController = TextEditingController(text: exercise?.equipment ?? '');
    setsController = TextEditingController(text: exercise?.defaultSets?.toString() ?? '');
    repsController = TextEditingController(text: exercise?.defaultReps?.toString() ?? '');
    weightController = TextEditingController(text: exercise?.defaultWeightKg?.toString() ?? '');
    selectedType = exercise?.trackingType ?? ExerciseTrackingType.reps;
    selectedDifficulty = exercise?.difficulty ?? ExerciseDifficulty.intermediate;
  }

  @override
  void dispose() {
    nameController.dispose();
    instructionsController.dispose();
    equipmentController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    super.dispose();
  }

  String? _validateOptionalPositiveInt(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return _mustBeWholeNumberMessage;
    }
    return ValidationUtils.positiveNumber(value: parsed, fieldName: fieldName);
  }

  String? _validateOptionalNonNegativeWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return _mustBeNumberMessage;
    }
    return ValidationUtils.numericRange(value: parsed, fieldName: 'Default weight', min: 0);
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    return AlertDialog(
      title: Text(exercise == null ? 'New Exercise' : 'Edit Exercise'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExerciseTrackingType>(
                decoration: const InputDecoration(labelText: 'Tracking', border: OutlineInputBorder()),
                initialValue: selectedType,
                items: const [
                  DropdownMenuItem(value: ExerciseTrackingType.reps, child: Text('Sets / Reps / Weight')),
                  DropdownMenuItem(
                    value: ExerciseTrackingType.cardio,
                    child: Text('Cardio (steps/duration/distance)'),
                  ),
                ],
                onChanged: (value) => setState(() => selectedType = value ?? selectedType),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExerciseDifficulty>(
                decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                initialValue: selectedDifficulty,
                items: const [
                  DropdownMenuItem(value: ExerciseDifficulty.beginner, child: Text('Beginner')),
                  DropdownMenuItem(value: ExerciseDifficulty.intermediate, child: Text('Intermediate')),
                  DropdownMenuItem(value: ExerciseDifficulty.advanced, child: Text('Advanced')),
                ],
                onChanged: (value) => setState(() => selectedDifficulty = value ?? selectedDifficulty),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: equipmentController,
                decoration: const InputDecoration(labelText: 'Equipment (optional)', border: OutlineInputBorder()),
              ),
              if (selectedType == ExerciseTrackingType.reps) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: setsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Default sets', border: OutlineInputBorder()),
                        validator: (value) => _validateOptionalPositiveInt(value, 'Default sets'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Default reps', border: OutlineInputBorder()),
                        validator: (value) => _validateOptionalPositiveInt(value, 'Default reps'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Default weight (kg, optional)', border: OutlineInputBorder()),
                  validator: _validateOptionalNonNegativeWeight,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: instructionsController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Instructions (optional)', border: OutlineInputBorder()),
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
                _ExerciseDialogResult(
                  name: nameController.text.trim(),
                  instructions: instructionsController.text.trim(),
                  equipment: equipmentController.text.trim(),
                  defaultSets: int.tryParse(setsController.text),
                  defaultReps: int.tryParse(repsController.text),
                  defaultWeight: double.tryParse(weightController.text),
                  trackingType: selectedType,
                  difficulty: selectedDifficulty,
                ),
              );
            }
          },
          child: Text(exercise == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
