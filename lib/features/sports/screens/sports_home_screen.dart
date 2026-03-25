import 'package:flutter/material.dart';

import '../widgets/sports_widgets.dart';
import 'active_workout_screen.dart';
import 'exercise_library_screen.dart';
import 'progress_charts_screen.dart';
import 'workout_list_screen.dart';

class SportsHomeScreen extends StatelessWidget {
  static const routeName = '/sports/home';

  const SportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sports Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(ActiveWorkoutScreen.routeName),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Workout'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(WorkoutListScreen.routeName),
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('Workout List'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('This Week: 145 min / 980 kcal'),
                  PRBadge(label: '2 PRs'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Recent Sessions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const WorkoutCard(title: 'Push Day', subtitle: '45 min • Moderate'),
          const WorkoutCard(title: 'Walking', subtitle: '35 min • Low'),
          const SizedBox(height: 12),
          Text('Quick Rest Timer', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  RestTimer(seconds: 60),
                  SizedBox(width: 8),
                  RestTimer(seconds: 90),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Progress', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const ProgressChart(points: [40, 44, 43, 47, 49, 52]),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Exercise Library'),
                onPressed: () => Navigator.of(context).pushNamed(ExerciseLibraryScreen.routeName),
              ),
              ActionChip(
                label: const Text('Progress Charts'),
                onPressed: () => Navigator.of(context).pushNamed(ProgressChartsScreen.routeName),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
