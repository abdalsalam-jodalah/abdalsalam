import 'package:flutter/material.dart';

import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/exercise_log.dart';
import '../../../shared/widgets/ui/app_card.dart';
import 'sports_cardio_log_form.dart';
import 'sports_strength_sets_section.dart';

class SportsLogTile extends StatelessWidget {
  static const String _unknownExerciseLabel = 'Unknown exercise';
  static const String _summarySeparator = ' • ';

  final ExerciseLog log;
  final Exercise? exercise;
  final VoidCallback onDelete;

  const SportsLogTile({super.key, required this.log, required this.exercise, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isCardio = exercise?.trackingType == ExerciseTrackingType.cardio;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const Icon(Icons.drag_indicator),
        title: Text(exercise?.name ?? _unknownExerciseLabel),
        subtitle: isCardio ? _cardioSummary(context) : null,
        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        children: [
          if (isCardio)
            SportsCardioLogForm(key: ValueKey('cardio-${log.id}'), log: log)
          else
            SportsStrengthSetsSection(
              key: ValueKey('strength-${log.id}'),
              exerciseLogId: log.id,
              exerciseId: log.exerciseId,
            ),
        ],
      ),
    );
  }

  Widget? _cardioSummary(BuildContext context) {
    final parts = <String>[];
    if (log.steps != null) parts.add('${log.steps} steps');
    if (log.durationSeconds != null) parts.add('${(log.durationSeconds! / 60).toStringAsFixed(0)} min');
    if (log.distanceKm != null) parts.add('${log.distanceKm!.toStringAsFixed(1)} km');
    if (parts.isEmpty) return null;
    return Text(parts.join(_summarySeparator));
  }
}
