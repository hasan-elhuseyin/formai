import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/workout_session.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

enum _StatsMetric { calories, workouts, reps, form }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _StatsMetric _metric = _StatsMetric.calories;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final points = _buildPoints(appState.sessions, _metric);
    final total = points.fold<double>(0, (sum, point) => sum + point.value);
    final populatedDays = points.where((point) => point.value > 0).length;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 96 + topInset, 24, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatsHeader(),
                const SizedBox(height: 24),
                _MetricSelector(
                  selected: _metric,
                  onChanged: (metric) => setState(() => _metric = metric),
                ),
                const SizedBox(height: 24),
                _StatsSummary(
                  metric: _metric,
                  total: total,
                  populatedDays: populatedDays,
                ),
                const SizedBox(height: 24),
                _ChartPanel(metric: _metric, points: points),
                const SizedBox(height: 24),
                _RecentSessions(sessions: appState.sessions.reversed.toList()),
              ],
            ),
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _StatsTopBar()),
      ],
    );
  }

  List<_StatsPoint> _buildPoints(
    List<WorkoutSession> sessions,
    _StatsMetric metric,
  ) {
    final now = DateTime.now();
    final days = [
      for (var index = 6; index >= 0; index -= 1)
        DateTime(now.year, now.month, now.day).subtract(Duration(days: index)),
    ];
    return [
      for (final day in days)
        _StatsPoint(
          label: _dayLabel(day),
          value: _valueForDay(day, sessions, metric),
        ),
    ];
  }

  double _valueForDay(
    DateTime day,
    List<WorkoutSession> sessions,
    _StatsMetric metric,
  ) {
    final matching = sessions
        .where((session) {
          final date = session.endedAt ?? session.startedAt;
          return date.year == day.year &&
              date.month == day.month &&
              date.day == day.day;
        })
        .toList(growable: false);

    return switch (metric) {
      _StatsMetric.calories => matching.fold<double>(
        0,
        (sum, session) => sum + session.caloriesBurned,
      ),
      _StatsMetric.workouts => matching.length.toDouble(),
      _StatsMetric.reps => matching.fold<double>(
        0,
        (sum, session) => sum + session.repsCompleted,
      ),
      _StatsMetric.form =>
        matching.isEmpty
            ? 0
            : matching.fold<double>(
                    0,
                    (sum, session) => sum + session.formScore,
                  ) /
                  matching.length,
    };
  }

  String _dayLabel(DateTime day) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[day.weekday - 1];
  }
}

class _StatsTopBar extends StatelessWidget {
  const _StatsTopBar();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72 + topInset,
          padding: EdgeInsets.fromLTRB(24, 16 + topInset, 24, 16),
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
                    onTap: () => AppScope.of(context).selectTab(0),
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
                  child: Icon(Icons.show_chart, color: AppColors.limeAlt),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESS',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 40 / 36,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'TRACK CALORIES, WORKOUTS, REPS, AND FORM OVER TIME',
          style: TextStyle(
            color: AppColors.slate,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({required this.selected, required this.onChanged});

  final _StatsMetric selected;
  final ValueChanged<_StatsMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final metric in _StatsMetric.values)
            Expanded(
              child: _MetricTab(
                metric: metric,
                selected: metric == selected,
                onTap: () => onChanged(metric),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricTab extends StatelessWidget {
  const _MetricTab({
    required this.metric,
    required this.selected,
    required this.onTap,
  });

  final _StatsMetric metric;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.lime.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              _metricShortLabel(metric),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppColors.lime : AppColors.slate,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({
    required this.metric,
    required this.total,
    required this.populatedDays,
  });

  final _StatsMetric metric;
  final double total;
  final int populatedDays;

  @override
  Widget build(BuildContext context) {
    final value = metric == _StatsMetric.form
        ? '${total == 0 ? 0 : (total / math.max(1, populatedDays)).round()}%'
        : _formatValue(total, metric);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _metricLongLabel(metric).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.lime,
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(_metricIcon(metric), color: AppColors.limeAlt, size: 38),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.metric, required this.points});

  final _StatsMetric metric;
  final List<_StatsPoint> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 286,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST 7 DAYS',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: CustomPaint(
              painter: _StatsChartPainter(points: points, metric: metric),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsChartPainter extends CustomPainter {
  const _StatsChartPainter({required this.points, required this.metric});

  final List<_StatsPoint> points;
  final _StatsMetric metric;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 28;
    final maxValue = math.max(
      1,
      points.fold<double>(0, (max, point) => math.max(max, point.value)),
    );
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i += 1) {
      final y = chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final barWidth = size.width / (points.length * 1.8);
    final gap = (size.width - barWidth * points.length) / (points.length - 1);
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.lime, AppColors.limeAlt],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var index = 0; index < points.length; index += 1) {
      final point = points[index];
      final x = index * (barWidth + gap);
      final valueHeight = (point.value / maxValue) * (chartHeight - 12);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          chartHeight - valueHeight,
          barWidth,
          math.max(4, valueHeight),
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, fillPaint);
      textPainter.text = TextSpan(
        text: point.label,
        style: const TextStyle(
          color: AppColors.slate,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, chartHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StatsChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.metric != metric;
  }
}

class _RecentSessions extends StatelessWidget {
  const _RecentSessions({required this.sessions});

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final visible = sessions.take(5).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Sessions',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          Container(
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No completed sessions yet.',
              style: TextStyle(color: AppColors.slate),
            ),
          )
        else
          for (final session in visible) ...[
            _SessionRow(session: session),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, color: AppColors.lime, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.workoutName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.repsCompleted} reps · ${session.caloriesBurned.toStringAsFixed(0)} kcal · ${session.formScore}% form',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.slate, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsPoint {
  const _StatsPoint({required this.label, required this.value});

  final String label;
  final double value;
}

String _metricShortLabel(_StatsMetric metric) {
  return switch (metric) {
    _StatsMetric.calories => 'KCAL',
    _StatsMetric.workouts => 'DONE',
    _StatsMetric.reps => 'REPS',
    _StatsMetric.form => 'FORM',
  };
}

String _metricLongLabel(_StatsMetric metric) {
  return switch (metric) {
    _StatsMetric.calories => 'Calories burned',
    _StatsMetric.workouts => 'Workouts done',
    _StatsMetric.reps => 'Reps completed',
    _StatsMetric.form => 'Average form',
  };
}

IconData _metricIcon(_StatsMetric metric) {
  return switch (metric) {
    _StatsMetric.calories => Icons.local_fire_department_outlined,
    _StatsMetric.workouts => Icons.check_circle_outline,
    _StatsMetric.reps => Icons.repeat,
    _StatsMetric.form => Icons.accessibility_new,
  };
}

String _formatValue(double value, _StatsMetric metric) {
  return switch (metric) {
    _StatsMetric.calories => value.toStringAsFixed(0),
    _StatsMetric.workouts => value.toStringAsFixed(0),
    _StatsMetric.reps => value.toStringAsFixed(0),
    _StatsMetric.form => '${value.toStringAsFixed(0)}%',
  };
}
