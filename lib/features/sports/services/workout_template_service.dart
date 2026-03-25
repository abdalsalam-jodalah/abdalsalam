import '../../../data/models/sports/workout.dart';

class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final int defaultDuration;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultDuration,
  });
}

class WorkoutTemplateService {
  List<WorkoutTemplate> templates() {
    return const <WorkoutTemplate>[
      WorkoutTemplate(
        id: 'push-day',
        name: 'Push Day',
        description: 'Chest, shoulders, triceps focused workout',
        defaultDuration: 45,
      ),
      WorkoutTemplate(
        id: 'legs-day',
        name: 'Legs Day',
        description: 'Lower body strength and stability',
        defaultDuration: 50,
      ),
    ];
  }

  Workout quickLogFromTemplate({
    required WorkoutTemplate template,
    required String userId,
    required String workoutId,
    required DateTime startedAt,
  }) {
    final end = startedAt.add(Duration(minutes: template.defaultDuration));
    return Workout(
      id: workoutId,
      createdAt: startedAt,
      updatedAt: startedAt,
      userId: userId,
      type: template.name,
      name: template.name,
      description: template.description,
      startTime: startedAt,
      endTime: end,
      durationMinutes: template.defaultDuration,
      caloriesBurned: template.defaultDuration * 6,
      intensity: 'moderate',
      location: null,
    );
  }
}
