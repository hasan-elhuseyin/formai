import 'workout_type.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.typeId,
    required this.name,
    required this.category,
    required this.status,
    required this.imageAsset,
    required this.trackingProfile,
    required this.analyzed,
    required this.depthScore,
    required this.repCount,
    required this.repGoal,
    required this.setCount,
    required this.setGoal,
    required this.externalLoadKg,
    required this.totalReps,
    required this.sessionCount,
    required this.reminderTime,
    required this.scheduleDays,
    required this.planNote,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String typeId;
  final String name;
  final String category;
  final String status;
  final String imageAsset;
  final TrackingProfile trackingProfile;
  final bool analyzed;
  final int depthScore;
  final int repCount;
  final int repGoal;
  final int setCount;
  final int setGoal;
  final double externalLoadKg;
  final int totalReps;
  final int sessionCount;
  final String? reminderTime;
  final List<int> scheduleDays;
  final String planNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get targetReps => repGoal * setGoal;
  int get remainingReps => (targetReps - repCount).clamp(0, targetReps).toInt();
  double get progress => targetReps == 0 ? 0 : repCount / targetReps;
  String get scheduleLabel {
    if (scheduleDays.isEmpty) {
      return 'Flexible';
    }
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return scheduleDays.map((day) => labels[(day - 1).clamp(0, 6)]).join(', ');
  }

  Exercise copyWith({
    String? id,
    String? typeId,
    String? name,
    String? category,
    String? status,
    String? imageAsset,
    TrackingProfile? trackingProfile,
    bool? analyzed,
    int? depthScore,
    int? repCount,
    int? repGoal,
    int? setCount,
    int? setGoal,
    double? externalLoadKg,
    int? totalReps,
    int? sessionCount,
    Object? reminderTime = _sentinel,
    List<int>? scheduleDays,
    String? planNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      typeId: typeId ?? this.typeId,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      imageAsset: imageAsset ?? this.imageAsset,
      trackingProfile: trackingProfile ?? this.trackingProfile,
      analyzed: analyzed ?? this.analyzed,
      depthScore: depthScore ?? this.depthScore,
      repCount: repCount ?? this.repCount,
      repGoal: repGoal ?? this.repGoal,
      setCount: setCount ?? this.setCount,
      setGoal: setGoal ?? this.setGoal,
      externalLoadKg: externalLoadKg ?? this.externalLoadKg,
      totalReps: totalReps ?? this.totalReps,
      sessionCount: sessionCount ?? this.sessionCount,
      reminderTime: identical(reminderTime, _sentinel)
          ? this.reminderTime
          : reminderTime as String?,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      planNote: planNote ?? this.planNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Exercise.fromJson(Map<String, Object?> json) {
    return Exercise(
      id: json['id'] as String,
      typeId: json['typeId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      imageAsset: json['imageAsset'] as String,
      trackingProfile: trackingProfileFromJson(json['trackingProfile']),
      analyzed: json['analyzed'] as bool? ?? false,
      depthScore: json['depthScore'] as int? ?? 0,
      repCount: json['repCount'] as int? ?? 0,
      repGoal: json['repGoal'] as int,
      setCount: json['setCount'] as int? ?? 0,
      setGoal: json['setGoal'] as int? ?? 1,
      externalLoadKg: (json['externalLoadKg'] as num?)?.toDouble() ?? 0,
      totalReps: json['totalReps'] as int? ?? 0,
      sessionCount: json['sessionCount'] as int? ?? 0,
      reminderTime: json['reminderTime'] as String?,
      scheduleDays: (json['scheduleDays'] as List<Object?>? ?? const [])
          .map((day) => day as int)
          .toList(growable: false),
      planNote: json['planNote'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'typeId': typeId,
      'name': name,
      'category': category,
      'status': status,
      'imageAsset': imageAsset,
      'trackingProfile': trackingProfile.name,
      'analyzed': analyzed,
      'depthScore': depthScore,
      'repCount': repCount,
      'repGoal': repGoal,
      'setCount': setCount,
      'setGoal': setGoal,
      'externalLoadKg': externalLoadKg,
      'totalReps': totalReps,
      'sessionCount': sessionCount,
      'reminderTime': reminderTime,
      'scheduleDays': scheduleDays,
      'planNote': planNote,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

const Object _sentinel = Object();
