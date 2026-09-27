import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sports/exercise_set_log.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/sports_providers.dart';
import 'sports_add_set_dialog.dart';
import 'sports_widgets.dart';

const _uuid = Uuid();

/// A [ConsumerStatefulWidget] rather than a stateless [ConsumerWidget] so
/// [ref] stays bound to a stable [State] across the `await showDialog(...)`
/// call in [_showAddSetDialog].
class SportsStrengthSetsSection extends ConsumerStatefulWidget {
  final String exerciseLogId;
  final String exerciseId;

  const SportsStrengthSetsSection({super.key, required this.exerciseLogId, required this.exerciseId});

  @override
  ConsumerState<SportsStrengthSetsSection> createState() => _SportsStrengthSetsSectionState();
}

class _SportsStrengthSetsSectionState extends ConsumerState<SportsStrengthSetsSection> {
  static const String _noSetsMessage = 'No sets logged yet.';
  static const String _addSetLabel = 'Add set';
  static const String _prLabel = 'PR';

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final setsAsync = ref.watch(setsForLogProvider(widget.exerciseLogId));
    final prAsync = ref.watch(personalRecordProvider(widget.exerciseId));

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          setsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => AsyncErrorView(
              error: error,
              isCompact: true,
              onRetry: () => ref.invalidate(setsForLogProvider(widget.exerciseLogId)),
            ),
            data: (sets) {
              if (sets.isEmpty) {
                return Text(_noSetsMessage, style: Theme.of(context).textTheme.bodyMedium);
              }
              return Column(
                children: [
                  for (final set in sets)
                    Row(
                      key: ValueKey(set.id),
                      children: [
                        Expanded(child: Text('Set ${set.setNumber}')),
                        Expanded(child: Text('${set.reps} reps')),
                        Expanded(child: Text(set.weightKg != null ? '${set.weightKg} kg' : '-')),
                        prAsync.maybeWhen(
                          data: (pr) => (pr != null && set.weightKg != null && set.weightKg! >= pr)
                              ? const PRBadge(label: _prLabel)
                              : const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          SizedBox(height: spacing.sm),
          OutlinedButton.icon(
            onPressed: _showAddSetDialog,
            icon: const Icon(Icons.add),
            label: const Text(_addSetLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSetDialog() async {
    final result = await showSportsAddSetDialog(context);

    if (result == null || !mounted) {
      return;
    }
    final currentSets = ref.read(setsForLogProvider(widget.exerciseLogId)).maybeWhen(
          data: (list) => list,
          orElse: () => const <ExerciseSetLog>[],
        );

    final service = ref.read(exerciseSetLogServiceProvider);
    final now = DateTime.now();
    final createResult = await service.create(
      ExerciseSetLog(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: sportUserId,
        exerciseLogId: widget.exerciseLogId,
        setNumber: currentSets.length + 1,
        reps: result.reps,
        weightKg: result.weight,
      ),
    );
    if (!mounted) {
      return;
    }
    if (createResult.isFailure) {
      AppFeedback.showError(context, createResult.error!);
    }
    ref.invalidate(setsForLogProvider(widget.exerciseLogId));
    ref.invalidate(personalRecordProvider(widget.exerciseId));
  }
}
