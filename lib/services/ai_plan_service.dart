import '../models/workout_type.dart';

class PlanRequest {
  const PlanRequest({
    required this.goal,
    required this.experience,
    required this.daysPerWeek,
    required this.equipment,
    this.reminderTime,
  });

  final String goal;
  final String experience;
  final int daysPerWeek;
  final String equipment;
  final String? reminderTime;
}

class PlanWorkoutDraft {
  const PlanWorkoutDraft({
    required this.type,
    required this.repGoal,
    required this.setGoal,
    required this.scheduleDays,
    required this.note,
  });

  final WorkoutType type;
  final int repGoal;
  final int setGoal;
  final List<int> scheduleDays;
  final String note;
}

class PlanSuggestion {
  const PlanSuggestion({
    required this.title,
    required this.rationale,
    required this.workouts,
  });

  final String title;
  final String rationale;
  final List<PlanWorkoutDraft> workouts;
}

class PlanCoachReply {
  const PlanCoachReply({required this.message, this.request});

  final String message;
  final PlanRequest? request;
}

class AiPlanService {
  const AiPlanService();

  PlanCoachReply reply({
    required String message,
    required List<WorkoutType> catalog,
  }) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const PlanCoachReply(
        message: 'Tell me your goal, training days, and equipment.',
      );
    }

    final days = _readDays(normalized) ?? 3;
    final experience = normalized.contains('advanced')
        ? 'Advanced'
        : normalized.contains('beginner')
        ? 'Beginner'
        : 'Intermediate';
    final equipment =
        normalized.contains('gym') ||
            normalized.contains('barbell') ||
            normalized.contains('dumbbell')
        ? 'Gym or weights'
        : 'Bodyweight';

    if (_looksReadyForPlan(normalized)) {
      final request = PlanRequest(
        goal: message.trim(),
        experience: experience,
        daysPerWeek: days,
        equipment: equipment,
      );
      return PlanCoachReply(
        request: request,
        message:
            'I can build that into a $days-day $experience plan. I will balance push, legs, pull, and core, then track each movement with the camera.',
      );
    }

    final movementNames = catalog.take(4).map((type) => type.name).join(', ');
    return PlanCoachReply(
      message:
          'Good start. I need one more decision: how many days per week and what equipment do you have? I can track $movementNames right away.',
    );
  }

  PlanSuggestion buildPlan(PlanRequest request, List<WorkoutType> catalog) {
    final goal = request.goal.toLowerCase();
    final bodyweight =
        request.equipment.toLowerCase().contains('body') ||
        request.equipment.trim().isEmpty;
    final targetDays = request.daysPerWeek.clamp(1, 6).toInt();
    final selected = <WorkoutType>[];

    void add(String id) {
      final type = catalog.firstWhere(
        (candidate) => candidate.id == id,
        orElse: () => catalog.first,
      );
      if (!selected.any((existing) => existing.id == type.id)) {
        selected.add(type);
      }
    }

    if (goal.contains('cardio') ||
        goal.contains('conditioning') ||
        goal.contains('fat') ||
        goal.contains('lose')) {
      add('burpee');
      add('mountain_climber');
      add('squat');
      add('plank');
    } else if (goal.contains('strength') || goal.contains('muscle')) {
      add('push_up');
      add(bodyweight ? 'pull_up' : 'deadlift');
      add('squat');
      add('shoulder_press');
    } else if (goal.contains('core') || goal.contains('posture')) {
      add('plank');
      add('deadlift');
      add('push_up');
      add('reverse_lunge');
    } else if (goal.contains('leg') || goal.contains('lower')) {
      add('squat');
      add('reverse_lunge');
      add('deadlift');
      add('glute_bridge');
    } else {
      add('push_up');
      add('squat');
      add('pull_up');
      add('plank');
      add('bench_dip');
    }

    final days = _scheduleDays(targetDays);
    final intensity = switch (request.experience.toLowerCase()) {
      'beginner' => 0.75,
      'advanced' => 1.25,
      _ => 1.0,
    };

    final drafts = <PlanWorkoutDraft>[];
    for (var index = 0; index < selected.length; index += 1) {
      final type = selected[index];
      final reps = (type.defaultRepGoal * intensity)
          .round()
          .clamp(3, 60)
          .toInt();
      final sets = (type.defaultSetGoal + (targetDays >= 4 ? 1 : 0))
          .clamp(1, 5)
          .toInt();
      drafts.add(
        PlanWorkoutDraft(
          type: type,
          repGoal: reps,
          setGoal: sets,
          scheduleDays: [
            for (var i = index; i < days.length; i += selected.length) days[i],
          ],
          note: '${type.primaryCue} ${type.secondaryCue}',
        ),
      );
    }

    return PlanSuggestion(
      title: '${request.experience} ${targetDays}x weekly plan',
      rationale:
          'Built from your goal, available equipment, and recovery window. Each item is saved as a camera-trackable workout.',
      workouts: drafts,
    );
  }

  bool _looksReadyForPlan(String normalized) {
    final hasGoal =
        normalized.contains('build') ||
        normalized.contains('plan') ||
        normalized.contains('strength') ||
        normalized.contains('muscle') ||
        normalized.contains('push') ||
        normalized.contains('lose') ||
        normalized.contains('fit');
    return hasGoal &&
        (_readDays(normalized) != null || normalized.contains('daily'));
  }

  int? _readDays(String normalized) {
    if (normalized.contains('daily') || normalized.contains('every day')) {
      return 6;
    }
    final numeric = RegExp(r'(\d)\s*(day|x|times)').firstMatch(normalized);
    if (numeric != null) {
      return int.tryParse(numeric.group(1)!);
    }
    final words = {
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
    };
    for (final entry in words.entries) {
      if (normalized.contains('${entry.key} day')) {
        return entry.value;
      }
    }
    return null;
  }

  List<int> _scheduleDays(int daysPerWeek) {
    return switch (daysPerWeek) {
      1 => const [1],
      2 => const [1, 4],
      3 => const [1, 3, 5],
      4 => const [1, 2, 4, 6],
      5 => const [1, 2, 3, 5, 6],
      _ => const [1, 2, 3, 4, 5, 6],
    };
  }
}
