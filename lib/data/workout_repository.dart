import '../models/exercise.dart';

class WorkoutRepository {
  const WorkoutRepository._();

  static const List<Map<String, Object?>> _exerciseJson = [
    {
      'name': 'Squat',
      'category': 'LOWER BODY',
      'status': 'ANALYZED',
      'imageAsset': 'assets/images/squat_thumb.png',
      'analyzed': true,
      'depthScore': 84,
      'repCount': 8,
      'repGoal': 12,
    },
    {
      'name': 'Pull-Up',
      'category': 'BACK',
      'status': 'NOT STARTED',
      'imageAsset': 'assets/images/pullup_thumb.png',
      'analyzed': false,
      'depthScore': 76,
      'repCount': 0,
      'repGoal': 10,
    },
    {
      'name': 'Deadlift',
      'category': 'FULL BODY',
      'status': 'NOT STARTED',
      'imageAsset': 'assets/images/deadlift_thumb.png',
      'analyzed': false,
      'depthScore': 81,
      'repCount': 0,
      'repGoal': 8,
    },
  ];

  static List<Exercise> get exercises {
    return _exerciseJson.map(Exercise.fromJson).toList(growable: false);
  }

  static List<Exercise> filterExercises(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return exercises;
    }

    return exercises
        .where(
          (exercise) =>
              exercise.name.toLowerCase().contains(normalized) ||
              exercise.category.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }
}
