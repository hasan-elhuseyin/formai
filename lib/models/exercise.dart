class Exercise {
  const Exercise({
    required this.name,
    required this.category,
    required this.status,
    required this.imageAsset,
    required this.analyzed,
    required this.depthScore,
    required this.repCount,
    required this.repGoal,
  });

  final String name;
  final String category;
  final String status;
  final String imageAsset;
  final bool analyzed;
  final int depthScore;
  final int repCount;
  final int repGoal;

  Exercise copyWith({
    String? name,
    String? category,
    String? status,
    String? imageAsset,
    bool? analyzed,
    int? depthScore,
    int? repCount,
    int? repGoal,
  }) {
    return Exercise(
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      imageAsset: imageAsset ?? this.imageAsset,
      analyzed: analyzed ?? this.analyzed,
      depthScore: depthScore ?? this.depthScore,
      repCount: repCount ?? this.repCount,
      repGoal: repGoal ?? this.repGoal,
    );
  }

  factory Exercise.fromJson(Map<String, Object?> json) {
    return Exercise(
      name: json['name'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      imageAsset: json['imageAsset'] as String,
      analyzed: json['analyzed'] as bool,
      depthScore: json['depthScore'] as int,
      repCount: json['repCount'] as int,
      repGoal: json['repGoal'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'category': category,
      'status': status,
      'imageAsset': imageAsset,
      'analyzed': analyzed,
      'depthScore': depthScore,
      'repCount': repCount,
      'repGoal': repGoal,
    };
  }
}
