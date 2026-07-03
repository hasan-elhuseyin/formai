import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
  DateTime _selectedDate = DateTime.now();

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
    final planned = appState.workoutsForDate(
      _selectedDate,
      query: _searchController.text,
    );
    final topInset = MediaQuery.paddingOf(context).top;
    final selectedTitle = _isToday(_selectedDate)
        ? "Today's Workout"
        : _formatDateTitle(_selectedDate);

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
                _PlanCalendarPanel(
                  selectedDate: _selectedDate,
                  workoutsForDate: appState.workoutsForDate,
                  onDateSelected: (date) {
                    setState(() => _selectedDate = _dateOnly(date));
                  },
                  onPickDate: _pickDate,
                ),
                const SizedBox(height: 18),
                LimeButton(
                  label: 'MOVEMENT LIBRARY',
                  icon: Icons.library_add_outlined,
                  onPressed: () => _showMovementLibrarySheet(
                    context,
                    scheduledDate: _selectedDate,
                  ),
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: selectedTitle,
                  actionLabel: 'ADD',
                  onAction: () => _showMovementLibrarySheet(
                    context,
                    scheduledDate: _selectedDate,
                  ),
                ),
                const SizedBox(height: 16),
                if (planned.isEmpty)
                  _EmptyPlan(
                    message:
                        'No workout scheduled for ${_formatShortDate(_selectedDate)}',
                    onTap: () => _showMovementLibrarySheet(
                      context,
                      scheduledDate: _selectedDate,
                    ),
                  )
                else
                  SlidableAutoCloseBehavior(
                    child: GridView.builder(
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
                        final exercise = planned[index];
                        return _SlidableWorkoutCard(
                          exercise: exercise,
                          onTap: () => appState.openExercise(exercise),
                          onEdit: () =>
                              _showEditWorkoutSheet(context, exercise),
                          onDelete: () =>
                              _confirmDeleteWorkout(context, exercise),
                        );
                      },
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.lime,
              onPrimary: AppColors.buttonText,
              surface: AppColors.panel,
              onSurface: AppColors.text,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.panel,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _selectedDate = _dateOnly(picked));
  }

  Future<void> _showMovementLibrarySheet(
    BuildContext context, {
    DateTime? scheduledDate,
  }) async {
    final appState = AppScope.of(context);
    final librarySearchController = TextEditingController(
      text: _searchController.text,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final catalog = appState.filterWorkoutTypes(
              librarySearchController.text,
            );
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Movement Library',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close, color: AppColors.slate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scheduledDate == null
                          ? 'Choose a movement to add to your plan.'
                          : 'Adding to ${_formatDateTitle(scheduledDate)}.',
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SheetSearchField(
                      controller: librarySearchController,
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: catalog.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (sheetContext, index) {
                          final type = catalog[index];
                          return _WorkoutTypeCard(
                            type: type,
                            onAdd: () {
                              Navigator.of(sheetContext).pop();
                              _showQuickAddSheet(
                                context,
                                initialType: type,
                                scheduledDate: scheduledDate,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    librarySearchController.dispose();
  }

  Future<void> _showQuickAddSheet(
    BuildContext context, {
    WorkoutType? initialType,
    DateTime? scheduledDate,
  }) async {
    final appState = AppScope.of(context);
    var selectedType = initialType ?? appState.workoutTypes.first;
    final repsController = TextEditingController(
      text: selectedType.defaultRepGoal.toString(),
    );
    final setsController = TextEditingController(
      text: selectedType.defaultSetGoal.toString(),
    );
    final reminderController = TextEditingController(text: '08:00');
    var daily = scheduledDate == null;

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
                  if (scheduledDate != null) ...[
                    _SelectedDatePill(date: scheduledDate),
                    const SizedBox(height: 12),
                  ],
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
                        scheduleDays: scheduledDate != null && !daily
                            ? [scheduledDate.weekday]
                            : daily
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

  Future<void> _showEditWorkoutSheet(
    BuildContext context,
    Exercise exercise,
  ) async {
    final appState = AppScope.of(context);
    final repsController = TextEditingController(
      text: exercise.repGoal.toString(),
    );
    final setsController = TextEditingController(
      text: exercise.setGoal.toString(),
    );
    final reminderController = TextEditingController(
      text: exercise.reminderTime ?? '',
    );
    final selectedDays = exercise.scheduleDays.toSet();

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
                  Text(
                    'Edit ${exercise.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 16),
                  _DaySelector(
                    selectedDays: selectedDays,
                    onToggle: (day) {
                      setSheetState(() {
                        if (selectedDays.contains(day)) {
                          selectedDays.remove(day);
                        } else {
                          selectedDays.add(day);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  LimeButton(
                    label: 'SAVE CHANGES',
                    icon: Icons.check,
                    onPressed: () async {
                      final reps =
                          int.tryParse(repsController.text) ?? exercise.repGoal;
                      final sets =
                          int.tryParse(setsController.text) ?? exercise.setGoal;
                      await appState.updateWorkout(
                        workoutId: exercise.id,
                        repGoal: reps,
                        setGoal: sets,
                        reminderTime: reminderController.text,
                        scheduleDays: selectedDays.toList(),
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

  Future<void> _confirmDeleteWorkout(
    BuildContext context,
    Exercise exercise,
  ) async {
    final appState = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text(
            'Delete workout?',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Remove ${exercise.name} from your plan and cancel its reminders.',
            style: const TextStyle(color: AppColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.alert),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await appState.deleteWorkout(exercise.id);
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

class _PlanCalendarPanel extends StatelessWidget {
  const _PlanCalendarPanel({
    required this.selectedDate,
    required this.workoutsForDate,
    required this.onDateSelected,
    required this.onPickDate,
  });

  final DateTime selectedDate;
  final List<Exercise> Function(DateTime date, {String query}) workoutsForDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(selectedDate.year, selectedDate.month);
    final gridStart = monthStart.subtract(
      Duration(days: monthStart.weekday - DateTime.monday),
    );
    final days = List<DateTime>.generate(
      42,
      (index) => _dateOnly(gridStart.add(Duration(days: index))),
    );

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'PLAN CALENDAR',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => onDateSelected(
                  DateTime(selectedDate.year, selectedDate.month - 1, 1),
                ),
                icon: const Icon(Icons.chevron_left, color: AppColors.slate),
              ),
              TextButton.icon(
                onPressed: onPickDate,
                style: TextButton.styleFrom(foregroundColor: AppColors.text),
                icon: const Icon(Icons.calendar_month, size: 16),
                label: Text(
                  '${_monthName(selectedDate.month)} ${selectedDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => onDateSelected(
                  DateTime(selectedDate.year, selectedDate.month + 1, 1),
                ),
                icon: const Icon(Icons.chevron_right, color: AppColors.slate),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _WeekdayLabel(label: 'M'),
              _WeekdayLabel(label: 'T'),
              _WeekdayLabel(label: 'W'),
              _WeekdayLabel(label: 'T'),
              _WeekdayLabel(label: 'F'),
              _WeekdayLabel(label: 'S'),
              _WeekdayLabel(label: 'S'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              final count = workoutsForDate(date).length;
              final selected = _sameDate(date, selectedDate);
              final today = _isToday(date);
              final inMonth = date.month == selectedDate.month;
              return _CalendarDay(
                date: date,
                count: count,
                selected: selected,
                today: today,
                inMonth: inMonth,
                onTap: () => onDateSelected(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.slate,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.count,
    required this.selected,
    required this.today,
    required this.inMonth,
    required this.onTap,
  });

  final DateTime date;
  final int count;
  final bool selected;
  final bool today;
  final bool inMonth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? AppColors.buttonText
        : inMonth
        ? AppColors.text
        : AppColors.slate.withValues(alpha: 0.45);
    return Material(
      color: selected
          ? AppColors.lime
          : today
          ? AppColors.lime.withValues(alpha: 0.12)
          : AppColors.input,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                height: 14,
                child: count == 0
                    ? const SizedBox.shrink()
                    : Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.buttonText.withValues(alpha: 0.18)
                              : AppColors.lime.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: selected
                                ? AppColors.buttonText
                                : AppColors.lime,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
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
                  values: const [1, 2, 3, 4, 5, 6, 7],
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
  const _EmptyPlan({required this.message, required this.onTap});

  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.input,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 118,
          width: double.infinity,
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
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

class _SlidableWorkoutCard extends StatelessWidget {
  const _SlidableWorkoutCard({
    required this.exercise,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Slidable(
        key: ValueKey(exercise.id),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.44,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.buttonText,
              icon: Icons.edit_outlined,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppColors.alert,
              foregroundColor: const Color(0xFF35110E),
              icon: Icons.delete_outline,
              label: 'Delete',
            ),
          ],
        ),
        child: _WorkoutCard(exercise: exercise, onTap: onTap),
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

class _SheetSearchField extends StatelessWidget {
  const _SheetSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: AppColors.lime,
        style: const TextStyle(color: AppColors.text, fontSize: 15),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: AppColors.slate, size: 19),
          hintText: 'Search movement',
          hintStyle: TextStyle(color: AppColors.slate),
        ),
      ),
    );
  }
}

class _SelectedDatePill extends StatelessWidget {
  const _SelectedDatePill({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lime.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_outlined,
            color: AppColors.lime,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Scheduled for ${_formatDateTitle(date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.selectedDays, required this.onToggle});

  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    const labels = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DAYS',
          style: TextStyle(
            color: AppColors.slate,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in labels.entries)
              FilterChip(
                selected: selectedDays.contains(entry.key),
                label: Text(entry.value),
                labelStyle: TextStyle(
                  color: selectedDays.contains(entry.key)
                      ? AppColors.buttonText
                      : AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                selectedColor: AppColors.lime,
                backgroundColor: AppColors.input,
                checkmarkColor: AppColors.buttonText,
                side: BorderSide(
                  color: selectedDays.contains(entry.key)
                      ? AppColors.lime
                      : Colors.white.withValues(alpha: 0.06),
                ),
                onSelected: (_) => onToggle(entry.key),
              ),
          ],
        ),
      ],
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

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isToday(DateTime date) => _sameDate(date, DateTime.now());

String _formatDateTitle(DateTime date) {
  return '${_weekdayName(date.weekday)}, ${_monthName(date.month)} ${date.day}';
}

String _formatShortDate(DateTime date) {
  return '${_monthName(date.month)} ${date.day}';
}

String _weekdayName(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    _ => 'Sunday',
  };
}

String _monthName(int month) {
  return switch (month) {
    DateTime.january => 'January',
    DateTime.february => 'February',
    DateTime.march => 'March',
    DateTime.april => 'April',
    DateTime.may => 'May',
    DateTime.june => 'June',
    DateTime.july => 'July',
    DateTime.august => 'August',
    DateTime.september => 'September',
    DateTime.october => 'October',
    DateTime.november => 'November',
    _ => 'December',
  };
}
