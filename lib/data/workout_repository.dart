import '../models/workout_type.dart';

class WorkoutRepository {
  const WorkoutRepository._();

  static const List<Map<String, Object?>> _workoutTypeJson = [
    {
      'id': 'push_up',
      'name': 'Push-Up',
      'category': 'UPPER BODY',
      'imageAsset': 'assets/images/pullup_thumb.png',
      'trackingProfile': 'pushUp',
      'defaultRepGoal': 12,
      'defaultSetGoal': 3,
      'primaryCue': 'Keep shoulders, hips, and ankles in one line.',
      'secondaryCue': 'Lower until elbows pass roughly 90 degrees.',
    },
    {
      'id': 'squat',
      'name': 'Squat',
      'category': 'LOWER BODY',
      'imageAsset': 'assets/images/squat_thumb.png',
      'trackingProfile': 'squat',
      'defaultRepGoal': 12,
      'defaultSetGoal': 3,
      'primaryCue': 'Track knees over toes and keep heels grounded.',
      'secondaryCue': 'Hit depth with hips below knee height when possible.',
    },
    {
      'id': 'pull_up',
      'name': 'Pull-Up',
      'category': 'BACK',
      'imageAsset': 'assets/images/pullup_thumb.png',
      'trackingProfile': 'pullUp',
      'defaultRepGoal': 6,
      'defaultSetGoal': 4,
      'primaryCue': 'Pull elbows toward ribs instead of craning the neck.',
      'secondaryCue': 'Control the full hang before the next rep.',
    },
    {
      'id': 'deadlift',
      'name': 'Deadlift',
      'category': 'FULL BODY',
      'imageAsset': 'assets/images/deadlift_thumb.png',
      'trackingProfile': 'deadlift',
      'defaultRepGoal': 8,
      'defaultSetGoal': 3,
      'primaryCue': 'Hinge from the hips while keeping the spine neutral.',
      'secondaryCue': 'Stand tall by driving through the floor.',
    },
    {
      'id': 'reverse_lunge',
      'name': 'Reverse Lunge',
      'category': 'LOWER BODY',
      'imageAsset': 'assets/images/squat_thumb.png',
      'trackingProfile': 'lunge',
      'defaultRepGoal': 10,
      'defaultSetGoal': 3,
      'primaryCue': 'Keep the front knee stacked over the mid-foot.',
      'secondaryCue': 'Drop the back knee with control, then drive up.',
    },
    {
      'id': 'plank',
      'name': 'Plank',
      'category': 'CORE',
      'imageAsset': 'assets/images/deadlift_thumb.png',
      'trackingProfile': 'plank',
      'defaultRepGoal': 45,
      'defaultSetGoal': 3,
      'primaryCue': 'Brace the core and keep hips level with shoulders.',
      'secondaryCue': 'Avoid sagging or piking as fatigue builds.',
    },
    {
      'id': 'shoulder_press',
      'name': 'Shoulder Press',
      'category': 'UPPER BODY',
      'imageAsset': 'assets/images/pullup_thumb.png',
      'trackingProfile': 'shoulderPress',
      'defaultRepGoal': 10,
      'defaultSetGoal': 3,
      'primaryCue': 'Press overhead without leaning back.',
      'secondaryCue': 'Finish with biceps near the ears and ribs tucked.',
    },
  ];

  static List<WorkoutType> get workoutTypes {
    return _workoutTypeJson.map(WorkoutType.fromJson).toList(growable: false);
  }

  static WorkoutType workoutTypeById(String id) {
    return workoutTypes.firstWhere(
      (type) => type.id == id,
      orElse: () => workoutTypes.first,
    );
  }
}
