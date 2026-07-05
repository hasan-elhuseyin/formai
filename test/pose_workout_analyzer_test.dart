import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:formai/models/exercise.dart';
import 'package:formai/models/workout_type.dart';
import 'package:formai/services/pose_workout_analyzer.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  const imageSize = Size(1000, 1000);

  test('counts a dumbbell curl from extended arm to curled arm', () {
    final analyzer = PoseWorkoutAnalyzer();
    final exercise = _exercise(TrackingProfile.dumbbellCurl);

    final firstFrame = analyzer.analyze(
      exercise: exercise,
      pose: _pose(elbow: const Offset(450, 500), wrist: const Offset(450, 700)),
      imageSize: imageSize,
    );
    final secondFrame = analyzer.analyze(
      exercise: exercise,
      pose: _pose(elbow: const Offset(450, 500), wrist: const Offset(500, 360)),
      imageSize: imageSize,
    );

    expect(firstFrame.repCount, 0);
    expect(secondFrame.repAdded, isTrue);
    expect(secondFrame.repCount, 1);
  });

  test('counts a one-arm dumbbell row from long arm to pulled arm', () {
    final analyzer = PoseWorkoutAnalyzer();
    final exercise = _exercise(TrackingProfile.dumbbellRow);

    analyzer.analyze(
      exercise: exercise,
      pose: _pose(elbow: const Offset(520, 500), wrist: const Offset(560, 700)),
      imageSize: imageSize,
    );
    final frame = analyzer.analyze(
      exercise: exercise,
      pose: _pose(elbow: const Offset(500, 430), wrist: const Offset(450, 360)),
      imageSize: imageSize,
    );

    expect(frame.repAdded, isTrue);
    expect(frame.repCount, 1);
  });

  test('counts a dumbbell lateral raise from side to shoulder height', () {
    final analyzer = PoseWorkoutAnalyzer();
    final exercise = _exercise(TrackingProfile.lateralRaise);

    analyzer.analyze(
      exercise: exercise,
      pose: _pose(elbow: const Offset(450, 480), wrist: const Offset(450, 650)),
      imageSize: imageSize,
    );
    final frame = analyzer.analyze(
      exercise: exercise,
      pose: _pose(elbow: const Offset(590, 350), wrist: const Offset(720, 340)),
      imageSize: imageSize,
    );

    expect(frame.repAdded, isTrue);
    expect(frame.repCount, 1);
  });
}

Exercise _exercise(TrackingProfile profile) {
  final now = DateTime(2026, 7, 5);
  return Exercise(
    id: profile.name,
    typeId: profile.name,
    name: profile.name,
    category: 'TEST',
    status: 'PLANNED',
    imageAsset: '',
    trackingProfile: profile,
    analyzed: false,
    depthScore: 0,
    repCount: 0,
    repGoal: 8,
    setCount: 0,
    setGoal: 2,
    externalLoadKg: 12,
    totalReps: 0,
    sessionCount: 0,
    reminderTime: null,
    scheduleDays: const [],
    planNote: '',
    createdAt: now,
    updatedAt: now,
  );
}

Pose _pose({required Offset elbow, required Offset wrist}) {
  const leftShoulder = Offset(450, 300);
  const leftHip = Offset(450, 610);
  const leftKnee = Offset(450, 780);
  const leftAnkle = Offset(450, 940);
  const rightShoulder = Offset(550, 300);
  const rightHip = Offset(550, 610);
  const rightKnee = Offset(550, 780);
  const rightAnkle = Offset(550, 940);
  final rightElbow = Offset(1000 - elbow.dx, elbow.dy);
  final rightWrist = Offset(1000 - wrist.dx, wrist.dy);

  return Pose(
    landmarks: {
      PoseLandmarkType.leftShoulder: _landmark(
        PoseLandmarkType.leftShoulder,
        leftShoulder,
      ),
      PoseLandmarkType.leftElbow: _landmark(PoseLandmarkType.leftElbow, elbow),
      PoseLandmarkType.leftWrist: _landmark(PoseLandmarkType.leftWrist, wrist),
      PoseLandmarkType.leftHip: _landmark(PoseLandmarkType.leftHip, leftHip),
      PoseLandmarkType.leftKnee: _landmark(PoseLandmarkType.leftKnee, leftKnee),
      PoseLandmarkType.leftAnkle: _landmark(
        PoseLandmarkType.leftAnkle,
        leftAnkle,
      ),
      PoseLandmarkType.rightShoulder: _landmark(
        PoseLandmarkType.rightShoulder,
        rightShoulder,
      ),
      PoseLandmarkType.rightElbow: _landmark(
        PoseLandmarkType.rightElbow,
        rightElbow,
      ),
      PoseLandmarkType.rightWrist: _landmark(
        PoseLandmarkType.rightWrist,
        rightWrist,
      ),
      PoseLandmarkType.rightHip: _landmark(PoseLandmarkType.rightHip, rightHip),
      PoseLandmarkType.rightKnee: _landmark(
        PoseLandmarkType.rightKnee,
        rightKnee,
      ),
      PoseLandmarkType.rightAnkle: _landmark(
        PoseLandmarkType.rightAnkle,
        rightAnkle,
      ),
    },
  );
}

PoseLandmark _landmark(PoseLandmarkType type, Offset point) {
  return PoseLandmark(
    type: type,
    x: point.dx,
    y: point.dy,
    z: 0,
    likelihood: 0.99,
  );
}
