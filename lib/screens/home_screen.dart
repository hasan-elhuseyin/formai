import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final exercises = appState.exercises;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 96, 24, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(name: appState.currentUser?.name ?? 'Athlete'),
                const SizedBox(height: 32),
                _WeeklyStatsCard(
                  workouts: appState.completedWorkoutCount,
                  sets: appState.totalSetCount,
                  totalWeightKg: appState.totalWeightKg,
                ),
                const SizedBox(height: 32),
                _ExerciseSection(exercises: exercises),
              ],
            ),
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _HomeTopBar()),
        Positioned(
          right: 24,
          bottom: 112,
          child: _FloatingAddButton(
            onTap: () => appState.openExercise(exercises.first),
          ),
        ),
      ],
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

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
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/avatar.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const FormaiWordmark(size: 20),
                ],
              ),
              const Icon(Icons.stacked_line_chart, color: AppColors.limeAlt),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR TRAINING',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 36,
            fontWeight: FontWeight.w500,
            height: 40 / 36,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'WELCOME, ${name.split(' ').first.toUpperCase()}',
          style: const TextStyle(
            color: AppColors.slate,
            fontSize: 14,
            letterSpacing: 1.4,
            height: 20 / 14,
          ),
        ),
      ],
    );
  }
}

class _WeeklyStatsCard extends StatelessWidget {
  const _WeeklyStatsCard({
    required this.workouts,
    required this.sets,
    required this.totalWeightKg,
  });

  final int workouts;
  final int sets;
  final int totalWeightKg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 241,
      width: double.infinity,
      child: GlassPanel(
        radius: 12,
        padding: const EdgeInsets.all(33),
        color: AppColors.panel.withValues(alpha: 0.72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WEEKLY STATS',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          letterSpacing: 2.8,
                          height: 20 / 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$workouts',
                            style: const TextStyle(
                              color: AppColors.lime,
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'WORKOUTS',
                              style: TextStyle(
                                color: AppColors.slate,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 28 / 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const ProgressRing(progress: 0.80),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _StatPair(value: '$sets Reps', label: 'VOLUME GOAL'),
                const SizedBox(width: 32),
                const SizedBox(
                  width: 1,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0x1AFFFFFF)),
                  ),
                ),
                const SizedBox(width: 32),
                _StatPair(value: '$totalWeightKg Kg', label: 'TOTAL WEIGHT'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(88),
            painter: _RingPainter(progress: progress),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
              color: AppColors.lime,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final trackPaint = Paint()
      ..color = AppColors.input
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.butt;
    final progressPaint = Paint()
      ..color = AppColors.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _StatPair extends StatelessWidget {
  const _StatPair({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 32 / 24,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 10,
              letterSpacing: 1,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({required this.exercises});

  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Flexible(
              child: Text(
                'Daily Routine',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 28 / 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  'VIEW HISTORY',
                  style: TextStyle(
                    color: AppColors.lime,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    height: 16 / 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exercises.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisExtent: 104,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return _ExerciseCard(
              exercise: exercise,
              onTap: () => appState.openExercise(exercise),
            );
          },
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.input,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  exercise.imageAsset,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 22.5 / 18,
                      ),
                    ),
                    Text(
                      exercise.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                        letterSpacing: 0.6,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(exercise: exercise),
              const SizedBox(width: 16),
              Icon(
                Icons.chevron_right,
                color: AppColors.slate.withValues(alpha: 0.65),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final active = exercise.analyzed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.lime.withValues(alpha: 0.10)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        exercise.status,
        style: TextStyle(
          color: active ? AppColors.lime : AppColors.slate,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1.5,
        ),
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.lime.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add, color: AppColors.buttonText, size: 28),
          ),
        ),
      ),
    );
  }
}
