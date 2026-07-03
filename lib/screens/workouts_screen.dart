import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/workout_type.dart';
import '../services/ai_plan_service.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/lime_button.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _goalController = TextEditingController(
    text: 'Build strength and improve form',
  );
  final TextEditingController _reminderController = TextEditingController(
    text: '08:00',
  );
  final TextEditingController _coachController = TextEditingController();

  String _experience = 'Beginner';
  String _equipment = 'Bodyweight';
  int _daysPerWeek = 3;
  String _coachReply =
      'Tell me your goal, training days, and equipment. I will shape it into a trackable plan.';
  bool _isGenerating = false;

  @override
  void dispose() {
    _searchController.dispose();
    _goalController.dispose();
    _reminderController.dispose();
    _coachController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final planned = appState.filterExercises(_searchController.text);
    final catalog = appState.filterWorkoutTypes(_searchController.text);
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 96 + topInset, 24, 128),
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
                _PlanBuilderPanel(
                  goalController: _goalController,
                  reminderController: _reminderController,
                  coachController: _coachController,
                  experience: _experience,
                  equipment: _equipment,
                  daysPerWeek: _daysPerWeek,
                  coachReply: _coachReply,
                  isGenerating: _isGenerating,
                  onExperienceChanged: (value) {
                    if (value != null) {
                      setState(() => _experience = value);
                    }
                  },
                  onDaysChanged: (value) =>
                      setState(() => _daysPerWeek = value),
                  onEquipmentChanged: (value) {
                    if (value != null) {
                      setState(() => _equipment = value);
                    }
                  },
                  onGenerate: _generatePlan,
                  onSendMessage: _sendCoachMessage,
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Your Plan',
                  actionLabel: 'QUICK ADD',
                  onAction: () => _showQuickAddSheet(context),
                ),
                const SizedBox(height: 16),
                if (planned.isEmpty)
                  _EmptyPlan(onTap: () => _showQuickAddSheet(context))
                else
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: planned.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisExtent: 164,
                          mainAxisSpacing: 16,
                        ),
                    itemBuilder: (context, index) {
                      return _WorkoutCard(
                        exercise: planned[index],
                        onTap: () => appState.openExercise(planned[index]),
                      );
                    },
                  ),
                const SizedBox(height: 28),
                const _SectionTitle(title: 'Movement Library'),
                const SizedBox(height: 16),
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: catalog.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisExtent: 118,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    return _WorkoutTypeCard(
                      type: catalog[index],
                      onAdd: () => _showQuickAddSheet(context, catalog[index]),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _SimpleTopBar()),
      ],
    );
  }

  Future<void> _generatePlan() async {
    if (_isGenerating) {
      return;
    }
    setState(() => _isGenerating = true);
    final appState = AppScope.of(context);
    final count = await appState.createAiPlan(
      PlanRequest(
        goal: _goalController.text,
        experience: _experience,
        daysPerWeek: _daysPerWeek,
        equipment: _equipment,
        reminderTime: _reminderController.text.trim().isEmpty
            ? null
            : _reminderController.text.trim(),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isGenerating = false;
      _coachReply =
          'Plan saved with $count workouts. Open one to start camera analysis.';
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.panel,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Saved $count workouts to your plan.',
            style: const TextStyle(color: AppColors.text),
          ),
        ),
      );
  }

  Future<void> _sendCoachMessage() async {
    final message = _coachController.text.trim();
    if (message.isEmpty) {
      return;
    }
    _coachController.clear();
    final reply = AppScope.of(context).replyToCoach(message);
    setState(() {
      _coachReply = reply.message;
      if (reply.request != null) {
        _goalController.text = reply.request!.goal;
        _experience = reply.request!.experience;
        _daysPerWeek = reply.request!.daysPerWeek;
        _equipment = _closestEquipmentOption(reply.request!.equipment);
      }
    });
  }

  String _closestEquipmentOption(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('gym') || normalized.contains('weight')) {
      return 'Gym or weights';
    }
    if (normalized.contains('dumbbell')) {
      return 'Dumbbells';
    }
    if (normalized.contains('band')) {
      return 'Resistance bands';
    }
    return 'Bodyweight';
  }

  Future<void> _showQuickAddSheet(
    BuildContext context, [
    WorkoutType? initialType,
  ]) async {
    final appState = AppScope.of(context);
    var selectedType = initialType ?? appState.workoutTypes.first;
    final repsController = TextEditingController(
      text: selectedType.defaultRepGoal.toString(),
    );
    final setsController = TextEditingController(
      text: selectedType.defaultSetGoal.toString(),
    );
    final reminderController = TextEditingController(text: '08:00');
    var daily = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Workout',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SelectBox<WorkoutType>(
                    value: selectedType,
                    values: appState.workoutTypes,
                    labelBuilder: (type) => type.name,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setSheetState(() {
                        selectedType = value;
                        repsController.text = value.defaultRepGoal.toString();
                        setsController.text = value.defaultSetGoal.toString();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SheetInput(
                          controller: repsController,
                          label: 'REPS',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SheetInput(
                          controller: setsController,
                          label: 'SETS',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SheetInput(
                    controller: reminderController,
                    label: 'REMINDER TIME',
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: daily,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.lime,
                    title: const Text(
                      'Daily',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onChanged: (value) => setSheetState(() => daily = value),
                  ),
                  const SizedBox(height: 18),
                  LimeButton(
                    label: 'SAVE WORKOUT',
                    icon: Icons.add,
                    onPressed: () async {
                      final reps =
                          int.tryParse(repsController.text) ??
                          selectedType.defaultRepGoal;
                      final sets =
                          int.tryParse(setsController.text) ??
                          selectedType.defaultSetGoal;
                      await appState.addWorkout(
                        type: selectedType,
                        repGoal: reps,
                        setGoal: sets,
                        reminderTime: reminderController.text.trim().isEmpty
                            ? null
                            : reminderController.text.trim(),
                        scheduleDays: daily
                            ? const [1, 2, 3, 4, 5, 6, 7]
                            : const [],
                        planNote:
                            '${selectedType.primaryCue} ${selectedType.secondaryCue}',
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    repsController.dispose();
    setsController.dispose();
    reminderController.dispose();
  }
}

class _SimpleTopBar extends StatelessWidget {
  const _SimpleTopBar();

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
          'BUILD A PLAN, SET REMINDERS, AND START CAMERA ANALYSIS',
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
          hintText: 'Search movement or plan',
          hintStyle: TextStyle(color: Color(0x808C937F), fontSize: 16),
        ),
      ),
    );
  }
}

class _PlanBuilderPanel extends StatelessWidget {
  const _PlanBuilderPanel({
    required this.goalController,
    required this.reminderController,
    required this.coachController,
    required this.experience,
    required this.equipment,
    required this.daysPerWeek,
    required this.coachReply,
    required this.isGenerating,
    required this.onExperienceChanged,
    required this.onDaysChanged,
    required this.onEquipmentChanged,
    required this.onGenerate,
    required this.onSendMessage,
  });

  final TextEditingController goalController;
  final TextEditingController reminderController;
  final TextEditingController coachController;
  final String experience;
  final String equipment;
  final int daysPerWeek;
  final String coachReply;
  final bool isGenerating;
  final ValueChanged<String?> onExperienceChanged;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<String?> onEquipmentChanged;
  final VoidCallback onGenerate;
  final VoidCallback onSendMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_alt_outlined, color: AppColors.lime),
              SizedBox(width: 10),
              Text(
                'AI Plan Builder',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CompactInput(controller: goalController, label: 'GOAL'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SelectBox<String>(
                  value: experience,
                  values: const ['Beginner', 'Intermediate', 'Advanced'],
                  labelBuilder: (value) => value,
                  onChanged: onExperienceChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SelectBox<int>(
                  value: daysPerWeek,
                  values: const [1, 2, 3, 4, 5, 6],
                  labelBuilder: (value) => '$value days/week',
                  onChanged: (value) {
                    if (value != null) {
                      onDaysChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LabeledSelectBox<String>(
                  label: 'EQUIPMENT',
                  value: equipment,
                  values: const [
                    'Bodyweight',
                    'Dumbbells',
                    'Resistance bands',
                    'Gym or weights',
                  ],
                  labelBuilder: (value) => value,
                  onChanged: onEquipmentChanged,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 96,
                child: _CompactInput(
                  controller: reminderController,
                  label: 'TIME',
                  keyboardType: TextInputType.datetime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LimeButton(
            label: isGenerating ? 'SAVING PLAN' : 'GENERATE AI PLAN',
            icon: Icons.auto_awesome,
            onPressed: isGenerating ? null : onGenerate,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coachReply,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 18 / 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: coachController,
                        cursorColor: AppColors.lime,
                        minLines: 1,
                        maxLines: 2,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Ask before deciding...',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                        onSubmitted: (_) => onSendMessage(),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Send',
                      onPressed: onSendMessage,
                      icon: const Icon(Icons.send, color: AppColors.lime),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInput extends StatelessWidget {
  const _CompactInput({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              cursorColor: AppColors.lime,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              decoration: const InputDecoration.collapsed(hintText: ''),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectBox<T> extends StatelessWidget {
  const _SelectBox({
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.panel,
          iconEnabledColor: AppColors.lime,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          items: [
            for (final item in values)
              DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelBuilder(item),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _LabeledSelectBox<T> extends StatelessWidget {
  const _LabeledSelectBox({
    required this.label,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.fromLTRB(14, 7, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              height: 1,
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.panel,
                iconEnabledColor: AppColors.lime,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (final item in values)
                    DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        labelBuilder(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 28 / 20,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: AppColors.lime),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.input,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const SizedBox(
          height: 118,
          width: double.infinity,
          child: Center(
            child: Text(
              'Add a simple workout or generate an AI plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
    final progress = exercise.progress.clamp(0, 1).toDouble();

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
                  height: 132,
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
                      '${exercise.category} · ${exercise.scheduleLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
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
                      '${exercise.repCount.toString().padLeft(2, '0')} / ${exercise.targetReps} reps · ${exercise.setGoal} sets · ${exercise.depthScore}% form',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                    if (exercise.reminderTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Reminder ${exercise.reminderTime}',
                        style: const TextStyle(
                          color: AppColors.lime,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _WorkoutTypeCard extends StatelessWidget {
  const _WorkoutTypeCard({required this.type, required this.onAdd});

  final WorkoutType type;
  final VoidCallback onAdd;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              type.imageAsset,
              width: 64,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${type.defaultSetGoal} x ${type.defaultRepGoal} · ${type.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.slate, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  type.primaryCue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 14 / 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Add workout',
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle, color: AppColors.lime),
          ),
        ],
      ),
    );
  }
}

class _SheetInput extends StatelessWidget {
  const _SheetInput({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.slate,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.input,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            cursorColor: AppColors.lime,
            style: const TextStyle(color: AppColors.text, fontSize: 16),
            decoration: const InputDecoration.collapsed(hintText: ''),
          ),
        ),
      ],
    );
  }
}
