import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final exercises = appState.filterExercises(_searchController.text);

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 96, 24, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WorkoutsHeader(),
                const SizedBox(height: 24),
                _SearchField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercises.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisExtent: 146,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    return _WorkoutCard(
                      exercise: exercises[index],
                      onTap: () => appState.openExercise(exercises[index]),
                    );
                  },
                ),
                if (exercises.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: Center(
                      child: Text(
                        'No workouts match your search.',
                        style: TextStyle(color: AppColors.slate),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _SimpleTopBar()),
      ],
    );
  }
}

class _SimpleTopBar extends StatelessWidget {
  const _SimpleTopBar();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppColors.background.withValues(alpha: 0.62),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FormaiWordmark(size: 20),
              Icon(Icons.fitness_center, color: AppColors.limeAlt),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutsHeader extends StatelessWidget {
  const _WorkoutsHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORKOUTS',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 40 / 36,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'CHOOSE AN EXERCISE FOR AI FORM ANALYSIS',
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: AppColors.lime,
        style: const TextStyle(color: AppColors.text, fontSize: 16),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: AppColors.slate),
          hintText: 'Search movement',
          hintStyle: TextStyle(color: Color(0x808C937F), fontSize: 16),
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = exercise.repGoal == 0
        ? 0.0
        : exercise.repCount / exercise.repGoal;

    return Material(
      color: AppColors.input,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  exercise.imageAsset,
                  width: 86,
                  height: 114,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Icon(
                          exercise.analyzed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: exercise.analyzed
                              ? AppColors.lime
                              : AppColors.slate,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.category,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.panel,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.lime,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${exercise.repCount.toString().padLeft(2, '0')} / ${exercise.repGoal} reps  ·  ${exercise.depthScore}% form',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
