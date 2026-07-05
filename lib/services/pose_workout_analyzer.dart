import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/exercise.dart';
import '../models/workout_type.dart';

class WorkoutAnalysisFrame {
  const WorkoutAnalysisFrame({
    required this.workoutId,
    required this.repCount,
    required this.setCount,
    required this.formScore,
    required this.primaryFeedback,
    required this.secondaryFeedback,
    required this.phaseLabel,
    required this.landmarks,
    required this.repAdded,
    required this.poseVisible,
  });

  final String workoutId;
  final int repCount;
  final int setCount;
  final int formScore;
  final String primaryFeedback;
  final String secondaryFeedback;
  final String phaseLabel;
  final Map<PoseLandmarkType, Offset> landmarks;
  final bool repAdded;
  final bool poseVisible;

  int remainingReps(Exercise exercise) {
    return (exercise.targetReps - repCount)
        .clamp(0, exercise.targetReps)
        .toInt();
  }
}

enum _RepPhase { top, bottom, lockout }

enum _BodySide { left, right }

class PoseWorkoutAnalyzer {
  String? _workoutId;
  int _repCount = 0;
  int _setCount = 0;
  _RepPhase _phase = _RepPhase.top;
  DateTime? _lastTimedRepAt;

  void resetFor(Exercise exercise) {
    _workoutId = exercise.id;
    _repCount = exercise.repCount;
    _setCount = exercise.setCount;
    _phase = _RepPhase.top;
    _lastTimedRepAt = null;
  }

  WorkoutAnalysisFrame analyze({
    required Exercise exercise,
    required Pose pose,
    required Size imageSize,
  }) {
    if (_workoutId != exercise.id) {
      resetFor(exercise);
    }

    final points = _normalizedLandmarks(pose, imageSize);
    if (points.length < 8) {
      _lastTimedRepAt = null;
      return _frame(
        exercise: exercise,
        formScore: 0,
        primary: 'Step fully into frame',
        secondary:
            'I need shoulders, hips, knees, and ankles visible to track this movement.',
        phase: 'Searching',
        landmarks: points,
        repAdded: false,
        poseVisible: false,
      );
    }

    return switch (exercise.trackingProfile) {
      TrackingProfile.squat => _analyzeSquat(exercise, pose, points),
      TrackingProfile.pushUp => _analyzePushUp(exercise, pose, points),
      TrackingProfile.pullUp => _analyzePullUp(exercise, pose, points),
      TrackingProfile.deadlift => _analyzeDeadlift(exercise, pose, points),
      TrackingProfile.lunge => _analyzeLunge(exercise, pose, points),
      TrackingProfile.plank => _analyzePlank(exercise, pose, points),
      TrackingProfile.shoulderPress => _analyzeShoulderPress(
        exercise,
        pose,
        points,
      ),
      TrackingProfile.burpee => _analyzeBurpee(exercise, pose, points),
      TrackingProfile.mountainClimber => _analyzeMountainClimber(
        exercise,
        pose,
        points,
      ),
      TrackingProfile.gluteBridge => _analyzeGluteBridge(
        exercise,
        pose,
        points,
      ),
      TrackingProfile.benchDip => _analyzeBenchDip(exercise, pose, points),
      TrackingProfile.dumbbellCurl => _analyzeDumbbellCurl(
        exercise,
        pose,
        points,
      ),
      TrackingProfile.dumbbellRow => _analyzeDumbbellRow(
        exercise,
        pose,
        points,
      ),
      TrackingProfile.lateralRaise => _analyzeLateralRaise(
        exercise,
        pose,
        points,
      ),
      TrackingProfile.generic => _analyzeGeneric(exercise, points),
    };
  }

  WorkoutAnalysisFrame _analyzeSquat(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: true);
    final hip = _landmark(
      pose,
      side,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    final knee = _landmark(
      pose,
      side,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    );
    final ankle = _landmark(
      pose,
      side,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    );
    final shoulder = _landmark(
      pose,
      side,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    if ([hip, knee, ankle, shoulder].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final kneeAngle = _angle(hip!, knee!, ankle!);
    final hipAngle = _angle(shoulder!, hip, knee);
    final bottom = kneeAngle < 112 || hipAngle < 82;
    final top = kneeAngle > 158 && hipAngle > 145;
    final repAdded = _countDownUpRep(
      bottom: bottom,
      top: top,
      exercise: exercise,
    );
    final kneeForward =
        (knee.x - ankle.x).abs() > _torsoScale(shoulder, hip) * 0.55;
    final depthGood = kneeAngle < 105 || hip.y > knee.y;
    final score = _score([
      if (depthGood) 0 else 16,
      if (kneeForward) 12 else 0,
      if (hipAngle < 55) 14 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: depthGood ? 'Depth reached' : 'Sink a little deeper',
      secondary: kneeForward
          ? 'Keep the knee stacked over the foot and drive through the heel.'
          : 'Brace your core and keep the chest tall as you stand.',
      phase: bottom
          ? 'Bottom'
          : top
          ? 'Top'
          : 'Moving',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzePushUp(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: false);
    final shoulder = _landmark(
      pose,
      side,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    final elbow = _landmark(
      pose,
      side,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
    );
    final wrist = _landmark(
      pose,
      side,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    );
    final hip = _landmark(
      pose,
      side,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    final ankle = _landmark(
      pose,
      side,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    );
    if ([shoulder, elbow, wrist, hip, ankle].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final elbowAngle = _angle(shoulder!, elbow!, wrist!);
    final bodyLine = _angle(shoulder, hip!, ankle!);
    final bottom = elbowAngle < 100;
    final top = elbowAngle > 156;
    final repAdded = _countDownUpRep(
      bottom: bottom,
      top: top,
      exercise: exercise,
    );
    final sagging = bodyLine < 160;
    final partialDepth = elbowAngle > 112 && _phase == _RepPhase.bottom;
    final score = _score([
      if (sagging) 18 else 0,
      if (partialDepth) 16 else 0,
      if (elbowAngle < 45) 8 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: sagging ? 'Lift your hips slightly' : 'Body line is steady',
      secondary: partialDepth
          ? 'Lower until the elbow closes near 90 degrees before pressing up.'
          : 'Keep ribs tucked and press evenly through both hands.',
      phase: bottom
          ? 'Bottom'
          : top
          ? 'Lockout'
          : 'Moving',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzePullUp(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: false);
    final shoulder = _landmark(
      pose,
      side,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    final elbow = _landmark(
      pose,
      side,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
    );
    final wrist = _landmark(
      pose,
      side,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    );
    final hip = _landmark(
      pose,
      side,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    if ([shoulder, elbow, wrist, hip].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final elbowAngle = _angle(shoulder!, elbow!, wrist!);
    final hollowBody = _angle(shoulder, hip!, _offsetLandmark(hip, 0, 120));
    final hang = elbowAngle > 152;
    final top = elbowAngle < 78;
    var repAdded = false;
    if (_phase == _RepPhase.top && hang) {
      _phase = _RepPhase.bottom;
    } else if (_phase == _RepPhase.bottom && top) {
      repAdded = _addRep(exercise);
      _phase = _RepPhase.lockout;
    } else if (_phase == _RepPhase.lockout && hang) {
      _phase = _RepPhase.bottom;
    }
    final score = _score([
      if (hollowBody < 150) 10 else 0,
      if (top && elbowAngle > 90) 15 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: top ? 'Chin-height pull reached' : 'Drive elbows down',
      secondary: hang
          ? 'Full hang detected. Pull without swinging your legs forward.'
          : 'Control the descent until your elbows are nearly straight.',
      phase: top
          ? 'Top'
          : hang
          ? 'Hang'
          : 'Pulling',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeDeadlift(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: true);
    final shoulder = _landmark(
      pose,
      side,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    final hip = _landmark(
      pose,
      side,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    final knee = _landmark(
      pose,
      side,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    );
    final ankle = _landmark(
      pose,
      side,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    );
    if ([shoulder, hip, knee, ankle].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final hipAngle = _angle(shoulder!, hip!, knee!);
    final kneeAngle = _angle(hip, knee, ankle!);
    final hinge = hipAngle < 92 && kneeAngle > 115;
    final lockout = hipAngle > 154 && kneeAngle > 155;
    final repAdded = _countDownUpRep(
      bottom: hinge,
      top: lockout,
      exercise: exercise,
    );
    final squatty = kneeAngle < 105;
    final score = _score([
      if (squatty) 14 else 0,
      if (hipAngle < 48) 12 else 0,
      if (lockout && hipAngle < 160) 8 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: squatty ? 'Hinge more, squat less' : 'Hip hinge detected',
      secondary: lockout
          ? 'Stand tall without leaning back at the top.'
          : 'Push the hips back and keep your spine long.',
      phase: hinge
          ? 'Hinge'
          : lockout
          ? 'Lockout'
          : 'Moving',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeLunge(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: true);
    final hip = _landmark(
      pose,
      side,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    final knee = _landmark(
      pose,
      side,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    );
    final ankle = _landmark(
      pose,
      side,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    );
    if ([hip, knee, ankle].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final kneeAngle = _angle(hip!, knee!, ankle!);
    final bottom = kneeAngle < 105;
    final top = kneeAngle > 158;
    final repAdded = _countDownUpRep(
      bottom: bottom,
      top: top,
      exercise: exercise,
    );
    final kneeDrift = (knee.x - ankle.x).abs() > 80;
    final score = _score([
      if (kneeDrift) 15 else 0,
      if (!bottom && _phase == _RepPhase.bottom) 12 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: kneeDrift ? 'Stack the front knee' : 'Lunge path is stable',
      secondary: 'Keep the front foot planted and lower under control.',
      phase: bottom
          ? 'Bottom'
          : top
          ? 'Top'
          : 'Moving',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzePlank(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: true);
    final shoulder = _landmark(
      pose,
      side,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    final hip = _landmark(
      pose,
      side,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    final ankle = _landmark(
      pose,
      side,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    );
    if ([shoulder, hip, ankle].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final bodyLine = _angle(shoulder!, hip!, ankle!);
    final hipsLow = hip.y - shoulder.y > _torsoScale(shoulder, hip) * 0.45;
    final score = _score([
      if (bodyLine < 164) 18 else 0,
      if (hipsLow) 16 else 0,
    ]);
    final repAdded = _countTimedRep(
      exercise: exercise,
      active: score >= 70 && !hipsLow,
    );

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: hipsLow ? 'Raise your hips' : 'Core line is strong',
      secondary: 'Hold steady. Plank time counts as reps for this plan.',
      phase: 'Hold',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeShoulderPress(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: false);
    final shoulder = _landmark(
      pose,
      side,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    final elbow = _landmark(
      pose,
      side,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
    );
    final wrist = _landmark(
      pose,
      side,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    );
    final hip = _landmark(
      pose,
      side,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    if ([shoulder, elbow, wrist, hip].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final elbowAngle = _angle(shoulder!, elbow!, wrist!);
    final wristOverShoulder =
        (wrist.x - shoulder.x).abs() < 90 && wrist.y < shoulder.y;
    final bottom = elbowAngle < 88;
    final top = elbowAngle > 156 && wristOverShoulder;
    final repAdded = _countDownUpRep(
      bottom: bottom,
      top: top,
      exercise: exercise,
    );
    final leaningBack =
        (shoulder.x - hip!.x).abs() > _torsoScale(shoulder, hip) * 0.55;
    final score = _score([
      if (leaningBack) 16 else 0,
      if (top && !wristOverShoulder) 12 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: leaningBack ? 'Ribs down' : 'Press path is vertical',
      secondary: 'Finish overhead with the wrist stacked above the shoulder.',
      phase: top
          ? 'Overhead'
          : bottom
          ? 'Rack'
          : 'Pressing',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeGeneric(
    Exercise exercise,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final repAdded = _countTimedRep(exercise: exercise, active: true);
    return _frame(
      exercise: exercise,
      formScore: 70,
      primary: 'Pose visible',
      secondary: 'Tracking visible movement as timed work.',
      phase: 'Tracking',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeDumbbellCurl(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final arms = _upperArmReadings(pose);
    if (arms.isEmpty) {
      return _notVisible(exercise, points);
    }

    final bottom = arms.any(
      (arm) => arm.elbowAngle > 138 && arm.wrist.y > arm.elbow.y,
    );
    final top = arms.any(
      (arm) => arm.elbowAngle < 102 && arm.wrist.y < arm.elbow.y,
    );
    final repAdded = _countDownUpRep(
      bottom: bottom,
      top: top,
      exercise: exercise,
    );
    final activeArm = _mostBentArm(arms);
    final elbowDrift = arms.any(
      (arm) => (arm.elbow.x - arm.shoulder.x).abs() > arm.torsoScale * 0.58,
    );
    final swinging = arms.any(
      (arm) =>
          (arm.wrist.x - arm.elbow.x).abs() > arm.torsoScale * 0.92 &&
          arm.elbowAngle > 108,
    );
    final partialTop = _phase == _RepPhase.bottom && activeArm.elbowAngle > 112;
    final score = _score([
      if (elbowDrift) 14 else 0,
      if (swinging) 12 else 0,
      if (partialTop) 12 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: top
          ? 'Curl height reached'
          : bottom
          ? 'Arms extended'
          : 'Curl with control',
      secondary: elbowDrift
          ? 'Pin the elbows closer to your ribs before curling again.'
          : 'Keep shoulders quiet and lower the dumbbells slowly.',
      phase: top
          ? 'Top'
          : bottom
          ? 'Bottom'
          : 'Curling',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeDumbbellRow(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final arms = _upperArmReadings(pose);
    if (arms.isEmpty) {
      return _notVisible(exercise, points);
    }

    final bottom = arms.any((arm) => arm.elbowAngle > 138);
    final top = arms.any(
      (arm) =>
          arm.elbowAngle < 118 &&
          arm.wrist.y < arm.hip.y - arm.torsoScale * 0.08,
    );
    final repAdded = _countDownUpRep(
      bottom: bottom,
      top: top,
      exercise: exercise,
    );
    final activeArm = _mostBentArm(arms);
    final elbowTooWide =
        (activeArm.elbow.x - activeArm.shoulder.x).abs() >
        activeArm.torsoScale * 0.95;
    final shortenedRep =
        _phase == _RepPhase.bottom && activeArm.elbowAngle > 126;
    final score = _score([
      if (elbowTooWide) 12 else 0,
      if (shortenedRep) 14 else 0,
      if (activeArm.wrist.y > activeArm.hip.y + activeArm.torsoScale * 0.4)
        10
      else
        0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: top ? 'Row pull reached' : 'Pull elbow toward hip',
      secondary: elbowTooWide
          ? 'Keep the elbow path closer to your side.'
          : 'Pause near the ribs, then lower until the arm is long.',
      phase: top
          ? 'Top'
          : bottom
          ? 'Bottom'
          : 'Rowing',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeLateralRaise(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final arms = _upperArmReadings(pose);
    if (arms.isEmpty) {
      return _notVisible(exercise, points);
    }

    final lowered = arms.any(
      (arm) =>
          arm.wrist.y > arm.hip.y - arm.torsoScale * 0.18 ||
          (arm.wrist.x - arm.shoulder.x).abs() < arm.torsoScale * 0.38,
    );
    final raised = arms.any(
      (arm) =>
          (arm.wrist.x - arm.shoulder.x).abs() > arm.torsoScale * 0.54 &&
          arm.wrist.y < arm.shoulder.y + arm.torsoScale * 0.28,
    );
    final repAdded = _countDownUpRep(
      bottom: lowered,
      top: raised,
      exercise: exercise,
    );
    final highestArm = arms.reduce(
      (best, arm) => arm.wrist.y < best.wrist.y ? arm : best,
    );
    final tooHigh =
        highestArm.wrist.y <
        highestArm.shoulder.y - highestArm.torsoScale * 0.22;
    final lockedElbow = arms.any((arm) => arm.elbowAngle > 172 && raised);
    final score = _score([
      if (tooHigh) 12 else 0,
      if (lockedElbow) 10 else 0,
      if (!raised && _phase == _RepPhase.bottom) 10 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: raised ? 'Shoulder height reached' : 'Raise out to the side',
      secondary: tooHigh
          ? 'Stop around shoulder height and keep the neck relaxed.'
          : 'Lead with soft elbows and avoid using momentum.',
      phase: raised
          ? 'Top'
          : lowered
          ? 'Bottom'
          : 'Raising',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeBurpee(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: true);
    final shoulder = _landmark(
      pose,
      side,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    final wrist = _landmark(
      pose,
      side,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    );
    final hip = _landmark(
      pose,
      side,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    final ankle = _landmark(
      pose,
      side,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    );
    if ([shoulder, wrist, hip, ankle].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final bodyLine = _angle(shoulder!, hip!, ankle!);
    final plank = bodyLine > 152 && (hip.y - shoulder.y).abs() < 120;
    final jumpReach = wrist!.y < shoulder.y && shoulder.y < hip.y;
    final repAdded = _countDownUpRep(
      bottom: plank,
      top: jumpReach,
      exercise: exercise,
    );
    final hipsSagging = plank && bodyLine < 165;
    final score = _score([
      if (hipsSagging) 16 else 0,
      if (jumpReach && wrist.y > shoulder.y - 80) 12 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: jumpReach ? 'Full extension reached' : 'Snap to strong plank',
      secondary: hipsSagging
          ? 'Keep hips from sagging as you kick back.'
          : 'Land softly and brace before the next rep.',
      phase: jumpReach
          ? 'Jump'
          : plank
          ? 'Plank'
          : 'Transition',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeMountainClimber(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: true);
    final shoulder = _landmark(
      pose,
      side,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    final hip = _landmark(
      pose,
      side,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    final knee = _landmark(
      pose,
      side,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    );
    final ankle = _landmark(
      pose,
      side,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    );
    if ([shoulder, hip, knee, ankle].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final bodyLine = _angle(shoulder!, hip!, ankle!);
    final kneeDrive =
        (knee!.x - hip.x).abs() > _torsoScale(shoulder, hip) * 0.45;
    final extended = (knee.x - hip.x).abs() < _torsoScale(shoulder, hip) * 0.22;
    final repAdded = _countDownUpRep(
      bottom: kneeDrive,
      top: extended,
      exercise: exercise,
    );
    final hipsBouncing = bodyLine < 154;
    final score = _score([
      if (hipsBouncing) 18 else 0,
      if (!kneeDrive && _phase == _RepPhase.bottom) 10 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: hipsBouncing ? 'Level your hips' : 'Knee drive detected',
      secondary: 'Keep shoulders over hands and move from the hips.',
      phase: kneeDrive ? 'Drive' : 'Reset',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeGluteBridge(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: true);
    final shoulder = _landmark(
      pose,
      side,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    final hip = _landmark(
      pose,
      side,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    final knee = _landmark(
      pose,
      side,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    );
    if ([shoulder, hip, knee].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final bridgeLine = _angle(shoulder!, hip!, knee!);
    final top = bridgeLine > 158;
    final bottom = bridgeLine < 128;
    final repAdded = _countDownUpRep(
      bottom: bottom,
      top: top,
      exercise: exercise,
    );
    final overArch = top && bridgeLine > 176;
    final score = _score([
      if (!top && _phase == _RepPhase.bottom) 12 else 0,
      if (overArch) 10 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: top ? 'Hip lockout reached' : 'Drive hips higher',
      secondary: overArch
          ? 'Squeeze glutes without over-arching the lower back.'
          : 'Press through heels and keep ribs tucked.',
      phase: top
          ? 'Top'
          : bottom
          ? 'Bottom'
          : 'Moving',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  WorkoutAnalysisFrame _analyzeBenchDip(
    Exercise exercise,
    Pose pose,
    Map<PoseLandmarkType, Offset> points,
  ) {
    final side = _bestSide(pose, lowerBody: false);
    final shoulder = _landmark(
      pose,
      side,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    final elbow = _landmark(
      pose,
      side,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
    );
    final wrist = _landmark(
      pose,
      side,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    );
    if ([shoulder, elbow, wrist].any((point) => point == null)) {
      return _notVisible(exercise, points);
    }

    final elbowAngle = _angle(shoulder!, elbow!, wrist!);
    final bottom = elbowAngle < 94;
    final top = elbowAngle > 155;
    final repAdded = _countDownUpRep(
      bottom: bottom,
      top: top,
      exercise: exercise,
    );
    final tooDeep = elbowAngle < 62;
    final score = _score([
      if (tooDeep) 16 else 0,
      if (!bottom && _phase == _RepPhase.bottom) 10 else 0,
    ]);

    return _frame(
      exercise: exercise,
      formScore: score,
      primary: top ? 'Strong lockout' : 'Control the dip',
      secondary: tooDeep
          ? 'Stop around 90 degrees to keep shoulders comfortable.'
          : 'Keep elbows tracking back and shoulders down.',
      phase: bottom
          ? 'Bottom'
          : top
          ? 'Lockout'
          : 'Moving',
      landmarks: points,
      repAdded: repAdded,
      poseVisible: true,
    );
  }

  bool _countDownUpRep({
    required bool bottom,
    required bool top,
    required Exercise exercise,
  }) {
    if (_phase == _RepPhase.top && bottom) {
      _phase = _RepPhase.bottom;
      return false;
    }
    if (_phase == _RepPhase.bottom && top) {
      _phase = _RepPhase.top;
      return _addRep(exercise);
    }
    return false;
  }

  bool _countTimedRep({
    required Exercise exercise,
    required bool active,
    Duration interval = const Duration(seconds: 1),
  }) {
    if (!active) {
      _lastTimedRepAt = null;
      return false;
    }
    final now = DateTime.now();
    final last = _lastTimedRepAt;
    if (last == null) {
      _lastTimedRepAt = now;
      return false;
    }
    if (now.difference(last) < interval) {
      return false;
    }
    _lastTimedRepAt = now;
    return _addRep(exercise);
  }

  bool _addRep(Exercise exercise) {
    if (_repCount >= exercise.targetReps) {
      return false;
    }
    _repCount += 1;
    _setCount = (_repCount / exercise.repGoal)
        .floor()
        .clamp(0, exercise.setGoal)
        .toInt();
    return true;
  }

  WorkoutAnalysisFrame _frame({
    required Exercise exercise,
    required int formScore,
    required String primary,
    required String secondary,
    required String phase,
    required Map<PoseLandmarkType, Offset> landmarks,
    required bool repAdded,
    required bool poseVisible,
  }) {
    return WorkoutAnalysisFrame(
      workoutId: exercise.id,
      repCount: _repCount,
      setCount: _setCount,
      formScore: formScore,
      primaryFeedback: primary,
      secondaryFeedback: secondary,
      phaseLabel: phase,
      landmarks: landmarks,
      repAdded: repAdded,
      poseVisible: poseVisible,
    );
  }

  WorkoutAnalysisFrame _notVisible(
    Exercise exercise,
    Map<PoseLandmarkType, Offset> points,
  ) {
    _lastTimedRepAt = null;
    return _frame(
      exercise: exercise,
      formScore: 0,
      primary: 'Pose partly hidden',
      secondary: 'Keep the full body in view so I can score the movement.',
      phase: 'Searching',
      landmarks: points,
      repAdded: false,
      poseVisible: false,
    );
  }

  Map<PoseLandmarkType, Offset> _normalizedLandmarks(
    Pose pose,
    Size imageSize,
  ) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return const {};
    }
    return {
      for (final entry in pose.landmarks.entries)
        if (entry.value.likelihood > 0.35)
          entry.key: Offset(
            (entry.value.x / imageSize.width).clamp(0, 1).toDouble(),
            (entry.value.y / imageSize.height).clamp(0, 1).toDouble(),
          ),
    };
  }

  _BodySide _bestSide(Pose pose, {required bool lowerBody}) {
    final left = lowerBody
        ? [
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.leftHip,
            PoseLandmarkType.leftKnee,
            PoseLandmarkType.leftAnkle,
          ]
        : [
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.leftElbow,
            PoseLandmarkType.leftWrist,
            PoseLandmarkType.leftHip,
          ];
    final right = lowerBody
        ? [
            PoseLandmarkType.rightShoulder,
            PoseLandmarkType.rightHip,
            PoseLandmarkType.rightKnee,
            PoseLandmarkType.rightAnkle,
          ]
        : [
            PoseLandmarkType.rightShoulder,
            PoseLandmarkType.rightElbow,
            PoseLandmarkType.rightWrist,
            PoseLandmarkType.rightHip,
          ];
    return _confidence(pose, left) >= _confidence(pose, right)
        ? _BodySide.left
        : _BodySide.right;
  }

  double _confidence(Pose pose, List<PoseLandmarkType> types) {
    final scores = types.map((type) => pose.landmarks[type]?.likelihood ?? 0);
    return scores.fold<double>(0, (total, score) => total + score) /
        types.length;
  }

  PoseLandmark? _landmark(
    Pose pose,
    _BodySide side,
    PoseLandmarkType left,
    PoseLandmarkType right,
  ) {
    final landmark = pose.landmarks[side == _BodySide.left ? left : right];
    if (landmark == null || landmark.likelihood < 0.35) {
      return null;
    }
    return landmark;
  }

  List<_UpperArmReading> _upperArmReadings(Pose pose) {
    final readings = <_UpperArmReading>[];
    for (final side in _BodySide.values) {
      final shoulder = _landmark(
        pose,
        side,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
      );
      final elbow = _landmark(
        pose,
        side,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.rightElbow,
      );
      final wrist = _landmark(
        pose,
        side,
        PoseLandmarkType.leftWrist,
        PoseLandmarkType.rightWrist,
      );
      final hip = _landmark(
        pose,
        side,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
      );
      if ([shoulder, elbow, wrist, hip].any((point) => point == null)) {
        continue;
      }
      readings.add(
        _UpperArmReading(
          shoulder: shoulder!,
          elbow: elbow!,
          wrist: wrist!,
          hip: hip!,
          elbowAngle: _angle(shoulder, elbow, wrist),
          torsoScale: _torsoScale(shoulder, hip),
        ),
      );
    }
    return readings;
  }

  _UpperArmReading _mostBentArm(List<_UpperArmReading> readings) {
    return readings.reduce(
      (best, arm) => arm.elbowAngle < best.elbowAngle ? arm : best,
    );
  }

  PoseLandmark _offsetLandmark(PoseLandmark source, double dx, double dy) {
    return PoseLandmark(
      type: source.type,
      x: source.x + dx,
      y: source.y + dy,
      z: source.z,
      likelihood: source.likelihood,
    );
  }

  double _angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = math.atan2(a.y - b.y, a.x - b.x);
    final cb = math.atan2(c.y - b.y, c.x - b.x);
    var angle = (ab - cb).abs() * 180 / math.pi;
    if (angle > 180) {
      angle = 360 - angle;
    }
    return angle;
  }

  double _torsoScale(PoseLandmark shoulder, PoseLandmark hip) {
    return math.max(
      60,
      math.sqrt(
        math.pow(shoulder.x - hip.x, 2) + math.pow(shoulder.y - hip.y, 2),
      ),
    );
  }

  int _score(List<int> penalties) {
    final penalty = penalties.fold<int>(0, (total, value) => total + value);
    return (100 - penalty).clamp(0, 100).toInt();
  }
}

class _UpperArmReading {
  const _UpperArmReading({
    required this.shoulder,
    required this.elbow,
    required this.wrist,
    required this.hip,
    required this.elbowAngle,
    required this.torsoScale,
  });

  final PoseLandmark shoulder;
  final PoseLandmark elbow;
  final PoseLandmark wrist;
  final PoseLandmark hip;
  final double elbowAngle;
  final double torsoScale;
}
