import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/exercise.dart';
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
  bool _isRecording = false;

  void _toggleAnalysis() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (!_isRecording) {
      return;
    }
    AppScope.of(context).recordAnalysisRep();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AnalysisHeader(exercise: exercise),
                const SizedBox(height: 32),
                _VideoPreview(isRecording: _isRecording),
                const SizedBox(height: 32),
                _FeedbackPanel(exercise: exercise, isRecording: _isRecording),
                const SizedBox(height: 24),
                _MetricCard(
                  label: 'DEPTH SCORE',
                  value: '${exercise.depthScore}',
                  suffix: '%',
                  helper: exercise.analyzed
                      ? '+4% from last set'
                      : 'Ready to scan',
                  height: 186,
                ),
                const SizedBox(height: 24),
                _MetricCard(
                  label: 'REP COUNT',
                  value: exercise.repCount.toString().padLeft(2, '0'),
                  suffix: '/ ${exercise.repGoal}',
                  height: 146,
                ),
                const SizedBox(height: 34),
                LimeButton(
                  label: _isRecording ? 'PAUSE ANALYSIS' : 'START ANALYSIS',
                  icon: _isRecording ? Icons.pause : Icons.play_arrow,
                  height: 68,
                  fontSize: 18,
                  onPressed: _toggleAnalysis,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.slate),
                  onPressed: appState.resetSelectedWorkout,
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
  const _VideoPreview({required this.isRecording});

  final bool isRecording;

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
                const _LiveCameraSurface(),
                ColoredBox(color: Colors.white.withValues(alpha: 0.02)),
                const _PoseOverlay(),
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
                          isRecording ? 'RECORDING' : 'READY',
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
              widthFactor: isRecording ? 0.65 : 0.18,
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

class _LiveCameraSurface extends StatefulWidget {
  const _LiveCameraSurface();

  @override
  State<_LiveCameraSurface> createState() => _LiveCameraSurfaceState();
}

class _LiveCameraSurfaceState extends State<_LiveCameraSurface> {
  CameraController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) {
        return;
      }
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera available');
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
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _error = error.description ?? error.code);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
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
        if (_error != null)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Camera fallback: $_error',
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
  const _PoseOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PoseOverlayPainter());
  }
}

class _PoseOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lime.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final shoulderL = Offset(size.width * 0.36, size.height * 0.34);
    final shoulderR = Offset(size.width * 0.64, size.height * 0.34);
    final hipL = Offset(size.width * 0.42, size.height * 0.58);
    final hipR = Offset(size.width * 0.58, size.height * 0.58);
    final kneeL = Offset(size.width * 0.32, size.height * 0.76);
    final kneeR = Offset(size.width * 0.68, size.height * 0.76);

    canvas.drawLine(shoulderL, shoulderR, paint);
    canvas.drawLine(shoulderL, hipL, paint);
    canvas.drawLine(shoulderR, hipR, paint);
    canvas.drawLine(hipL, hipR, paint);
    canvas.drawLine(hipL, kneeL, paint);
    canvas.drawLine(hipR, kneeR, paint);

    final pointPaint = Paint()..color = AppColors.lime;
    for (final point in [shoulderL, shoulderR, hipL, hipR, kneeL, kneeR]) {
      canvas.drawCircle(point, 3.2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.exercise, required this.isRecording});

  final Exercise exercise;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final firstTitle = exercise.depthScore >= 88
        ? 'Depth improving'
        : 'Knees going too\nforward?';
    final firstBody = exercise.depthScore >= 88
        ? 'Your current form is tracking\ncleaner. Keep your chest tall\nand control the last third of\nthe descent.'
        : 'Try to keep your knees\naligned with your feet to\ndistribute weight evenly\nthrough the posterior chain.';

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
              icon: exercise.depthScore >= 88
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              iconColor: exercise.depthScore >= 88
                  ? AppColors.lime
                  : AppColors.alert,
              title: firstTitle,
              body: firstBody,
              height: 166,
            ),
            const SizedBox(height: 16),
            const _FeedbackItem(
              icon: Icons.straighten,
              iconColor: AppColors.limeAlt,
              title: 'Back slightly bent',
              body:
                  'Maintain a straight back\nposture. Engage your core\nand keep your chest upright\nthroughout the descent.',
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
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 20 / 14,
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
              Text(
                suffix,
                style: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.40),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 28 / 20,
                ),
              ),
            ],
          ),
          if (helper != null)
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppColors.lime, size: 13),
                const SizedBox(width: 8),
                Text(
                  helper!,
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.60),
                    fontSize: 12,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
