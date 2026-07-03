import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/exercise.dart';
import '../services/camera_input_image.dart';
import '../services/pose_workout_analyzer.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_panel.dart';
import '../widgets/lime_button.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final PoseWorkoutAnalyzer _workoutAnalyzer = PoseWorkoutAnalyzer();
  late final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  CameraController? _controller;
  CameraDescription? _camera;
  WorkoutAnalysisFrame? _analysis;
  String? _cameraError;
  bool _isRecording = false;
  bool _isProcessingFrame = false;
  DateTime _lastProcessedFrame = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _stopImageStream();
    _controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final exercise = appState.selectedExercise;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 92, 24, 128),
            child: exercise == null
                ? _NoWorkoutSelected(
                    onOpenWorkouts: () => appState.selectTab(1),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AnalysisHeader(exercise: exercise),
                      const SizedBox(height: 32),
                      _VideoPreview(
                        controller: _controller,
                        cameraError: _cameraError,
                        isRecording: _isRecording,
                        analysis: _analysis,
                        progress: exercise.progress.clamp(0, 1).toDouble(),
                      ),
                      const SizedBox(height: 32),
                      _FeedbackPanel(
                        exercise: exercise,
                        analysis: _analysis,
                        isRecording: _isRecording,
                      ),
                      const SizedBox(height: 24),
                      _MetricCard(
                        label: 'FORM SCORE',
                        value: '${_analysis?.formScore ?? exercise.depthScore}',
                        suffix: '%',
                        helper: _analysis?.phaseLabel ?? 'Ready to scan',
                        height: 186,
                      ),
                      const SizedBox(height: 24),
                      _MetricCard(
                        label: 'REP COUNT',
                        value: (_analysis?.repCount ?? exercise.repCount)
                            .toString()
                            .padLeft(2, '0'),
                        suffix: '/ ${exercise.targetReps}',
                        height: 146,
                      ),
                      const SizedBox(height: 34),
                      LimeButton(
                        label: _isRecording
                            ? 'PAUSE ANALYSIS'
                            : 'START ANALYSIS',
                        icon: _isRecording ? Icons.pause : Icons.play_arrow,
                        height: 68,
                        fontSize: 18,
                        onPressed: () => _toggleAnalysis(exercise),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.slate,
                        ),
                        onPressed: () async {
                          if (_isRecording) {
                            await _toggleAnalysis(exercise);
                          }
                          await appState.resetSelectedWorkout();
                          if (mounted) {
                            setState(() => _analysis = null);
                          }
                        },
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text(
                          'RESET CURRENT WORKOUT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const Positioned(left: 0, right: 0, top: 0, child: _AnalysisTopBar()),
      ],
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) {
        return;
      }
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera available');
        return;
      }

      final camera = cameras.firstWhere(
        (description) => description.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: cameraImageFormatGroup(),
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = camera;
        _controller = controller;
        _cameraError = null;
      });
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _cameraError = error.description ?? error.code);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _cameraError = error.toString());
      }
    }
  }

  Future<void> _toggleAnalysis(Exercise exercise) async {
    final appState = AppScope.of(context);
    if (_isRecording) {
      await _stopImageStream();
      if (mounted) {
        setState(() => _isRecording = false);
      }
      await appState.endWorkoutSession(
        summary: _analysis == null
            ? 'Session saved.'
            : '${_analysis!.primaryFeedback} ${_analysis!.secondaryFeedback}',
      );
      return;
    }

    final controller = _controller;
    final camera = _camera;
    if (controller == null ||
        camera == null ||
        !controller.value.isInitialized) {
      _showMessage(_cameraError ?? 'Camera is not ready yet.');
      return;
    }

    _workoutAnalyzer.resetFor(exercise);
    await appState.beginWorkoutSession(exercise);
    try {
      await controller.startImageStream(_processCameraImage);
      if (mounted) {
        setState(() {
          _isRecording = true;
          _analysis = null;
        });
      }
    } on CameraException catch (error) {
      _showMessage(error.description ?? error.code);
    }
  }

  Future<void> _stopImageStream() async {
    final controller = _controller;
    if (controller == null || !controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.stopImageStream();
    } on CameraException {
      // The camera plugin can throw if the stream is already stopping.
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final controller = _controller;
    final camera = _camera;
    final exercise = AppScope.of(context).selectedExercise;
    if (!_isRecording ||
        _isProcessingFrame ||
        controller == null ||
        camera == null ||
        exercise == null) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastProcessedFrame).inMilliseconds < 110) {
      return;
    }
    _lastProcessedFrame = now;
    _isProcessingFrame = true;

    try {
      final inputImage = inputImageFromCameraImage(
        image: image,
        camera: camera,
        controller: controller,
      );
      if (inputImage == null) {
        return;
      }
      final poses = await _poseDetector.processImage(inputImage);
      if (!mounted || poses.isEmpty) {
        return;
      }

      final frame = _workoutAnalyzer.analyze(
        exercise: exercise,
        pose: poses.first,
        imageSize: Size(image.width.toDouble(), image.height.toDouble()),
      );
      if (!mounted) {
        return;
      }
      setState(() => _analysis = frame);
      await AppScope.of(context).recordAnalysisFrame(frame);
    } catch (error) {
      if (mounted) {
        setState(() => _cameraError = error.toString());
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.panel,
          behavior: SnackBarBehavior.floating,
          content: Text(message, style: const TextStyle(color: AppColors.text)),
        ),
      );
  }
}

class _AnalysisTopBar extends StatelessWidget {
  const _AnalysisTopBar();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppColors.background.withValues(alpha: 0.62),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Material(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => AppScope.of(context).selectTab(1),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.text,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const FormaiWordmark(size: 20),
              const SizedBox(
                width: 32,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.stacked_line_chart,
                    color: AppColors.slate,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoWorkoutSelected extends StatelessWidget {
  const _NoWorkoutSelected({required this.onOpenWorkouts});

  final VoidCallback onOpenWorkouts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LIVE SESSION',
          style: TextStyle(
            color: AppColors.lime,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a workout',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 40 / 36,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.video_camera_front_outlined,
                color: AppColors.lime,
                size: 42,
              ),
              const SizedBox(height: 16),
              const Text(
                'Create or open a workout first so the analyzer knows which movement model to run.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
              const SizedBox(height: 20),
              LimeButton(
                label: 'OPEN WORKOUTS',
                icon: Icons.fitness_center,
                onPressed: onOpenWorkouts,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LIVE SESSION',
          style: TextStyle(
            color: AppColors.lime,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
            height: 24 / 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${exercise.name} Analysis',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 40 / 36,
          ),
        ),
      ],
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({
    required this.controller,
    required this.cameraError,
    required this.isRecording,
    required this.analysis,
    required this.progress,
  });

  final CameraController? controller;
  final String? cameraError;
  final bool isRecording;
  final WorkoutAnalysisFrame? analysis;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 192.38,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _LiveCameraSurface(controller: controller, error: cameraError),
                ColoredBox(color: Colors.white.withValues(alpha: 0.02)),
                _PoseOverlay(analysis: analysis),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glass.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isRecording
                                ? AppColors.alert
                                : AppColors.slate,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRecording ? 'TRACKING' : 'READY',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 6,
            color: AppColors.panel,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.05, 1).toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB8F56B), AppColors.lime],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lime.withValues(alpha: 0.60),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveCameraSurface extends StatelessWidget {
  const _LiveCameraSurface({required this.controller, required this.error});

  final CameraController? controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 342,
          height: controller.value.previewSize?.width ?? 192,
          child: CameraPreview(controller),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/squat_video.png', fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.25)),
        if (error != null)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Camera: $error',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
          )
        else
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.lime,
              ),
            ),
          ),
      ],
    );
  }
}

class _PoseOverlay extends StatelessWidget {
  const _PoseOverlay({required this.analysis});

  final WorkoutAnalysisFrame? analysis;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PoseOverlayPainter(analysis: analysis));
  }
}

class _PoseOverlayPainter extends CustomPainter {
  const _PoseOverlayPainter({required this.analysis});

  final WorkoutAnalysisFrame? analysis;

  static const List<(PoseLandmarkType, PoseLandmarkType)> _connections = [
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final landmarks = analysis?.landmarks ?? const {};
    if (landmarks.isEmpty) {
      return;
    }

    final linePaint = Paint()
      ..color = AppColors.lime.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final pointPaint = Paint()..color = AppColors.lime;

    Offset map(Offset normalized) {
      return Offset(normalized.dx * size.width, normalized.dy * size.height);
    }

    for (final connection in _connections) {
      final a = landmarks[connection.$1];
      final b = landmarks[connection.$2];
      if (a != null && b != null) {
        canvas.drawLine(map(a), map(b), linePaint);
      }
    }

    for (final point in landmarks.values) {
      canvas.drawCircle(map(point), 3.2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PoseOverlayPainter oldDelegate) {
    return oldDelegate.analysis != analysis;
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.exercise,
    required this.analysis,
    required this.isRecording,
  });

  final Exercise exercise;
  final WorkoutAnalysisFrame? analysis;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final primary = analysis?.primaryFeedback ?? 'Ready for camera tracking';
    final secondary =
        analysis?.secondaryFeedback ??
        (exercise.planNote.isEmpty
            ? 'Start analysis when your full body is visible.'
            : exercise.planNote);
    final reps = analysis?.repCount ?? exercise.repCount;
    final sets = analysis?.setCount ?? exercise.setCount;
    final remaining = (exercise.targetReps - reps).clamp(
      0,
      exercise.targetReps,
    );

    return SizedBox(
      height: 446,
      width: double.infinity,
      child: GlassPanel(
        radius: 24,
        padding: const EdgeInsets.all(33),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.psychology_alt_outlined,
                      color: AppColors.lime,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'AI Feedback',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 32 / 24,
                      ),
                    ),
                  ],
                ),
                _RealtimeBadge(active: isRecording),
              ],
            ),
            const SizedBox(height: 24),
            _FeedbackItem(
              icon: (analysis?.formScore ?? 0) >= 80
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              iconColor: (analysis?.formScore ?? 0) >= 80
                  ? AppColors.lime
                  : AppColors.alert,
              title: primary,
              body: secondary,
              height: 166,
            ),
            const SizedBox(height: 16),
            _FeedbackItem(
              icon: Icons.format_list_numbered,
              iconColor: AppColors.limeAlt,
              title: '$remaining reps left',
              body:
                  'Completed $reps of ${exercise.targetReps} reps and $sets of ${exercise.setGoal} planned sets.',
              height: 142,
            ),
          ],
        ),
      ),
    );
  }
}

class _RealtimeBadge extends StatelessWidget {
  const _RealtimeBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        active ? 'REAL-TIME' : 'STANDBY',
        style: const TextStyle(
          color: AppColors.lime,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          height: 1.5,
        ),
      ),
    );
  }
}

class _FeedbackItem extends StatelessWidget {
  const _FeedbackItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.height,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.glass.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 35,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    body,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.height,
    this.helper,
  });

  final String label;
  final String value;
  final String suffix;
  final String? helper;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              height: 20 / 14,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: helper == null ? AppColors.text : AppColors.lime,
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  suffix,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.40),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 28 / 20,
                  ),
                ),
              ),
            ],
          ),
          if (helper != null)
            Row(
              children: [
                const Icon(Icons.sensors, color: AppColors.lime, size: 13),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    helper!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.60),
                      fontSize: 12,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
