import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/exercise_category.dart';
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
      error: (error, stack) => const Center(child: Text('Failed to load categories')),
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
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(category == null ? 'New Category' : 'Edit Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
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
            child: Text(category == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );

    if (saved != true) {
      nameController.dispose();
      return;
    }

    final name = nameController.text.trim();
    nameController.dispose();
    if (!mounted) {
      return;
    }
    final repo = ref.read(exerciseCategoryRepositoryProvider);
    final now = DateTime.now();

    if (category == null) {
      final existing = ref.read(exerciseCategoriesProvider).maybeWhen(
            data: (list) => list,
            orElse: () => const <ExerciseCategory>[],
          );
      await repo.create(
        ExerciseCategory(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
          userId: sportUserId,
          name: name,
          order: existing.length,
        ),
      );
    } else {
      await repo.update(category.copyWith(name: name, updatedAt: now));
    }
    if (!mounted) {
      return;
    }
    ref.invalidate(exerciseCategoriesProvider);
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
              error: (error, stack) => const Text('Failed to load exercises'),
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
    final repo = ref.read(exerciseRepositoryProvider);
    await repo.softDelete(exercise.id);
    if (!mounted) {
      return;
    }
    ref.invalidate(exercisesByCategoryProvider(widget.category.id));
    ref.invalidate(allActiveExercisesProvider);
  }

  Future<void> _showExerciseDialog({Exercise? exercise}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: exercise?.name ?? '');
    final instructionsController = TextEditingController(text: exercise?.instructions ?? '');
    final equipmentController = TextEditingController(text: exercise?.equipment ?? '');
    final setsController = TextEditingController(text: exercise?.defaultSets?.toString() ?? '');
    final repsController = TextEditingController(text: exercise?.defaultReps?.toString() ?? '');
    final weightController = TextEditingController(text: exercise?.defaultWeightKg?.toString() ?? '');
    ExerciseTrackingType selectedType = exercise?.trackingType ?? ExerciseTrackingType.reps;
    ExerciseDifficulty selectedDifficulty = exercise?.difficulty ?? ExerciseDifficulty.intermediate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
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
                    onChanged: (value) => setDialogState(() => selectedType = value ?? selectedType),
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
                    onChanged: (value) => setDialogState(() => selectedDifficulty = value ?? selectedDifficulty),
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
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: repsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Default reps', border: OutlineInputBorder()),
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
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(exercise == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      nameController.dispose();
      instructionsController.dispose();
      equipmentController.dispose();
      setsController.dispose();
      repsController.dispose();
      weightController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final instructions = instructionsController.text.trim();
    final equipment = equipmentController.text.trim();
    final defaultSets = int.tryParse(setsController.text);
    final defaultReps = int.tryParse(repsController.text);
    final defaultWeight = double.tryParse(weightController.text);
    nameController.dispose();
    instructionsController.dispose();
    equipmentController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();

    if (!mounted) {
      return;
    }
    final repo = ref.read(exerciseRepositoryProvider);
    final now = DateTime.now();

    if (exercise == null) {
      final existing = ref.read(exercisesByCategoryProvider(widget.category.id)).maybeWhen(
            data: (list) => list,
            orElse: () => const <Exercise>[],
          );
      await repo.create(
        Exercise(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
          userId: sportUserId,
          name: name,
          categoryId: widget.category.id,
          trackingType: selectedType,
          difficulty: selectedDifficulty,
          equipment: equipment.isEmpty ? null : equipment,
          defaultSets: defaultSets,
          defaultReps: defaultReps,
          defaultWeightKg: defaultWeight,
          instructions: instructions.isEmpty ? null : instructions,
          order: existing.length,
        ),
      );
    } else {
      await repo.update(
        exercise.copyWith(
          name: name,
          trackingType: selectedType,
          difficulty: selectedDifficulty,
          equipment: equipment.isEmpty ? null : equipment,
          defaultSets: defaultSets,
          defaultReps: defaultReps,
          defaultWeightKg: defaultWeight,
          instructions: instructions.isEmpty ? null : instructions,
          updatedAt: now,
        ),
      );
    }

    if (!mounted) {
      return;
    }
    ref.invalidate(exercisesByCategoryProvider(widget.category.id));
    ref.invalidate(allActiveExercisesProvider);
  }
}
