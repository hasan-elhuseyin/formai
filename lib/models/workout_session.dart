class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.targetReps,
    required this.targetSets,
    required this.repsCompleted,
    required this.setsCompleted,
    required this.formScore,
    required this.coachSummary,
    this.endedAt,
  });

  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int targetReps;
  final int targetSets;
  final int repsCompleted;
  final int setsCompleted;
  final int formScore;
  final String coachSummary;

  bool get isComplete => endedAt != null;

  WorkoutSession copyWith({
    String? id,
    String? workoutId,
    String? workoutName,
    DateTime? startedAt,
    Object? endedAt = _sentinel,
    int? targetReps,
    int? targetSets,
    int? repsCompleted,
    int? setsCompleted,
    int? formScore,
    String? coachSummary,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: identical(endedAt, _sentinel)
          ? this.endedAt
          : endedAt as DateTime?,
      targetReps: targetReps ?? this.targetReps,
      targetSets: targetSets ?? this.targetSets,
      repsCompleted: repsCompleted ?? this.repsCompleted,
      setsCompleted: setsCompleted ?? this.setsCompleted,
      formScore: formScore ?? this.formScore,
      coachSummary: coachSummary ?? this.coachSummary,
    );
  }

  factory WorkoutSession.fromJson(Map<String, Object?> json) {
    return WorkoutSession(
      id: json['id'] as String,
      workoutId: json['workoutId'] as String,
      workoutName: json['workoutName'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      targetReps: json['targetReps'] as int,
      targetSets: json['targetSets'] as int,
      repsCompleted: json['repsCompleted'] as int? ?? 0,
      setsCompleted: json['setsCompleted'] as int? ?? 0,
      formScore: json['formScore'] as int? ?? 0,
      coachSummary: json['coachSummary'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'targetReps': targetReps,
      'targetSets': targetSets,
      'repsCompleted': repsCompleted,
      'setsCompleted': setsCompleted,
      'formScore': formScore,
      'coachSummary': coachSummary,
    };
  }
}

const Object _sentinel = Object();
