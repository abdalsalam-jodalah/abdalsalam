import '../../../data/models/sports/exercise.dart';

class ExerciseLibraryService {
  List<Exercise> predefinedExercises({required String userId, required DateTime now}) {
    return <Exercise>[
      Exercise(
        id: 'pushup',
        createdAt: now,
        updatedAt: now,
        userId: userId,
        workoutId: 'library',
        exerciseName: 'Push Up',
        sets: 3,
        reps: 12,
        weight: null,
        distance: null,
        durationSeconds: null,
        muscleGroup: 'Chest',
        instructions: 'Keep your core tight and chest controlled.',
        notes: null,
      ),
      Exercise(
        id: 'squat',
        createdAt: now,
        updatedAt: now,
        userId: userId,
        workoutId: 'library',
        exerciseName: 'Squat',
        sets: 4,
        reps: 8,
        weight: 40,
        distance: null,
        durationSeconds: null,
        muscleGroup: 'Legs',
        instructions: 'Drive knees out and keep neutral spine.',
        notes: null,
      ),
    ];
  }

  Exercise customExercise({
    required String userId,
    required DateTime now,
    required String id,
    required String name,
    required String muscleGroup,
    String? instructions,
  }) {
    return Exercise(
      id: id,
      createdAt: now,
      updatedAt: now,
      userId: userId,
      workoutId: 'custom',
      exerciseName: name,
      sets: 0,
      reps: 0,
      weight: null,
      distance: null,
      durationSeconds: null,
      muscleGroup: muscleGroup,
      instructions: instructions,
      notes: null,
    );
  }
}
