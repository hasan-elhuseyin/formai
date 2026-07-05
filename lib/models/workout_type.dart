enum TrackingProfile {
  squat,
  pushUp,
  pullUp,
  deadlift,
  lunge,
  plank,
  shoulderPress,
  burpee,
  mountainClimber,
  gluteBridge,
  benchDip,
  dumbbellCurl,
  dumbbellRow,
  lateralRaise,
  generic,
}

enum WorkoutEquipment { bodyweight, dumbbells, gym }

class WorkoutType {
  const WorkoutType({
    required this.id,
    required this.name,
    required this.category,
    required this.imageAsset,
    required this.equipment,
    required this.trackingProfile,
    required this.defaultRepGoal,
    required this.defaultSetGoal,
    required this.metValue,
    required this.secondsPerRep,
    required this.primaryCue,
    required this.secondaryCue,
    required this.defaultLoadKg,
    required this.loadCalorieFactor,
  });

  final String id;
  final String name;
  final String category;
  final String imageAsset;
  final WorkoutEquipment equipment;
  final TrackingProfile trackingProfile;
  final int defaultRepGoal;
  final int defaultSetGoal;
  final double metValue;
  final double secondsPerRep;
  final String primaryCue;
  final String secondaryCue;
  final double defaultLoadKg;
  final double loadCalorieFactor;

  bool get usesExternalLoad =>
      defaultLoadKg > 0 || equipment != WorkoutEquipment.bodyweight;
  bool get usesDumbbells => equipment == WorkoutEquipment.dumbbells;

  factory WorkoutType.fromJson(Map<String, Object?> json) {
    return WorkoutType(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      imageAsset: json['imageAsset'] as String,
      equipment: workoutEquipmentFromJson(json['equipment']),
      trackingProfile: trackingProfileFromJson(json['trackingProfile']),
      defaultRepGoal: json['defaultRepGoal'] as int,
      defaultSetGoal: json['defaultSetGoal'] as int,
      metValue: (json['metValue'] as num?)?.toDouble() ?? 4.5,
      secondsPerRep: (json['secondsPerRep'] as num?)?.toDouble() ?? 4,
      primaryCue: json['primaryCue'] as String,
      secondaryCue: json['secondaryCue'] as String,
      defaultLoadKg: (json['defaultLoadKg'] as num?)?.toDouble() ?? 0,
      loadCalorieFactor: (json['loadCalorieFactor'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'imageAsset': imageAsset,
      'equipment': equipment.name,
      'trackingProfile': trackingProfile.name,
      'defaultRepGoal': defaultRepGoal,
      'defaultSetGoal': defaultSetGoal,
      'metValue': metValue,
      'secondsPerRep': secondsPerRep,
      'primaryCue': primaryCue,
      'secondaryCue': secondaryCue,
      'defaultLoadKg': defaultLoadKg,
      'loadCalorieFactor': loadCalorieFactor,
    };
  }
}

TrackingProfile trackingProfileFromJson(Object? value) {
  final name = value?.toString();
  return TrackingProfile.values.firstWhere(
    (profile) => profile.name == name,
    orElse: () => TrackingProfile.generic,
  );
}

WorkoutEquipment workoutEquipmentFromJson(Object? value) {
  final name = value?.toString();
  return WorkoutEquipment.values.firstWhere(
    (equipment) => equipment.name == name,
    orElse: () => WorkoutEquipment.bodyweight,
  );
}
