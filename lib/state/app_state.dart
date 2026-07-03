import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/local_store.dart';
import '../data/workout_repository.dart';
import '../models/app_user.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../models/workout_type.dart';
import '../services/ai_plan_service.dart';
import '../services/pose_workout_analyzer.dart';

class AuthResult {
  const AuthResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class AppState extends ChangeNotifier {
  AppState({LocalStore? store})
    : _store = store ?? LocalStore(),
      _workoutTypes = WorkoutRepository.workoutTypes {
    _load();
  }

  final LocalStore _store;
  final List<WorkoutType> _workoutTypes;
  final AiPlanService _planService = const AiPlanService();
  final Uuid _uuid = const Uuid();

  List<StoredAccount> _accounts = [];
  UserData _data = UserData.empty();
  AppUser? _currentUser;
  Exercise? _selectedExercise;
  WorkoutSession? _activeSession;
  int _selectedTab = 0;
  bool _isReady = false;
  String? _loadError;

  bool get isReady => _isReady;
  String? get loadError => _loadError;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  List<WorkoutType> get workoutTypes => List.unmodifiable(_workoutTypes);
  List<Exercise> get exercises => List.unmodifiable(_data.workouts);
  List<WorkoutSession> get sessions => List.unmodifiable(_data.sessions);
  Exercise? get selectedExercise => _selectedExercise;
  WorkoutSession? get activeSession => _activeSession;
  int get selectedTab => _selectedTab;
  bool get metricUnits => _data.metricUnits;
  bool get voiceFeedback => _data.voiceFeedback;
  double get bodyWeightKg => _data.bodyWeightKg;
  double get heightCm => _data.heightCm;
  String? get profileImagePath => _data.profileImagePath;

  int get completedWorkoutCount {
    return _data.sessions.where((session) => session.isComplete).length;
  }

  int get totalRepCount {
    return _data.sessions.fold(
      0,
      (total, session) => total + session.repsCompleted,
    );
  }

  int get totalSetCount {
    return _data.sessions.fold(
      0,
      (total, session) => total + session.setsCompleted,
    );
  }

  int get averageFormScore {
    final scored = _data.sessions.where((session) => session.formScore > 0);
    if (scored.isEmpty) {
      return 0;
    }
    return (scored.fold<int>(0, (total, session) => total + session.formScore) /
            scored.length)
        .round();
  }

  double get totalCaloriesBurned {
    return _data.sessions.fold(
      0,
      (total, session) => total + session.caloriesBurned,
    );
  }

  void openStats() {
    _selectedTab = 4;
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      _accounts = await _store.loadAccounts();
      final currentUserId = await _store.loadCurrentUserId();
      if (currentUserId != null) {
        final account = _accountByUserId(currentUserId);
        if (account != null) {
          _currentUser = account.user;
          _data = await _store.loadUserData(account.user.id);
          _selectedExercise = _data.workouts.isEmpty
              ? null
              : _data.workouts.first;
        } else {
          await _store.saveCurrentUserId(null);
        }
      }
    } catch (error) {
      _loadError = error.toString();
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (!_isReady) {
      return const AuthResult(success: false, message: 'App is still loading.');
    }

    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Enter your email and password.',
      );
    }

    final account = _accountByEmail(normalizedEmail);
    if (account == null ||
        account.passwordHash != _hashPassword(password, account.passwordSalt)) {
      return const AuthResult(
        success: false,
        message: 'Email or password is incorrect.',
      );
    }

    _currentUser = account.user;
    _data = await _store.loadUserData(account.user.id);
    _selectedExercise = _data.workouts.isEmpty ? null : _data.workouts.first;
    _activeSession = null;
    _selectedTab = 0;
    await _store.saveCurrentUserId(account.user.id);
    notifyListeners();
    return AuthResult(
      success: true,
      message: 'Welcome back, ${account.user.name}.',
    );
  }

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (!_isReady) {
      return const AuthResult(success: false, message: 'App is still loading.');
    }

    final trimmedName = name.trim();
    final normalizedEmail = _normalizeEmail(email);

    if (trimmedName.length < 2) {
      return const AuthResult(
        success: false,
        message: 'Enter your name to create an account.',
      );
    }
    if (!_looksLikeEmail(normalizedEmail)) {
      return const AuthResult(
        success: false,
        message: 'Enter a valid email address.',
      );
    }
    if (password.length < 8) {
      return const AuthResult(
        success: false,
        message: 'Password must be at least 8 characters.',
      );
    }
    if (password != confirmPassword) {
      return const AuthResult(
        success: false,
        message: 'Passwords do not match.',
      );
    }
    if (_accountByEmail(normalizedEmail) != null) {
      return const AuthResult(
        success: false,
        message: 'An account with this email already exists.',
      );
    }

    final user = AppUser(
      id: _uuid.v4(),
      name: trimmedName,
      email: normalizedEmail,
      createdAt: DateTime.now(),
    );
    final salt = _newSalt();
    final account = StoredAccount(
      user: user,
      passwordSalt: salt,
      passwordHash: _hashPassword(password, salt),
    );
    _accounts = [..._accounts, account];
    _currentUser = user;
    _data = UserData.empty();
    _selectedExercise = null;
    _activeSession = null;
    _selectedTab = 0;

    await _store.saveAccounts(_accounts);
    await _store.saveUserData(user.id, _data);
    await _store.saveCurrentUserId(user.id);
    notifyListeners();
    return const AuthResult(success: true, message: 'Account created.');
  }

  Future<void> signOut() async {
    _currentUser = null;
    _selectedExercise = null;
    _activeSession = null;
    _data = UserData.empty();
    _selectedTab = 0;
    await _store.saveCurrentUserId(null);
    notifyListeners();
  }

  void selectTab(int index) {
    if (_selectedTab == index) {
      return;
    }
    _selectedTab = index;
    notifyListeners();
  }

  void openExercise(Exercise exercise) {
    _selectedExercise = _findMatchingExercise(exercise.id);
    _selectedTab = 2;
    notifyListeners();
  }

  List<Exercise> filterExercises(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return exercises;
    }

    return _data.workouts
        .where(
          (exercise) =>
              exercise.name.toLowerCase().contains(normalized) ||
              exercise.category.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  List<WorkoutType> filterWorkoutTypes(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return workoutTypes;
    }

    return _workoutTypes
        .where(
          (type) =>
              type.name.toLowerCase().contains(normalized) ||
              type.category.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  Future<void> addWorkout({
    required WorkoutType type,
    required int repGoal,
    required int setGoal,
    String? reminderTime,
    List<int> scheduleDays = const [],
    String planNote = '',
  }) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final now = DateTime.now();
    final workout = Exercise(
      id: _uuid.v4(),
      typeId: type.id,
      name: type.name,
      category: type.category,
      status: 'PLANNED',
      imageAsset: type.imageAsset,
      trackingProfile: type.trackingProfile,
      analyzed: false,
      depthScore: 0,
      repCount: 0,
      repGoal: repGoal.clamp(1, 120).toInt(),
      setCount: 0,
      setGoal: setGoal.clamp(1, 8).toInt(),
      totalReps: 0,
      sessionCount: 0,
      reminderTime: reminderTime,
      scheduleDays: scheduleDays,
      planNote: planNote,
      createdAt: now,
      updatedAt: now,
    );
    _data = _data.copyWith(workouts: [..._data.workouts, workout]);
    _selectedExercise = workout;
    await _saveUserData();
    notifyListeners();
  }

  Future<int> createAiPlan(PlanRequest request) async {
    final suggestion = _planService.buildPlan(request, _workoutTypes);
    for (final draft in suggestion.workouts) {
      await addWorkout(
        type: draft.type,
        repGoal: draft.repGoal,
        setGoal: draft.setGoal,
        reminderTime: request.reminderTime,
        scheduleDays: draft.scheduleDays,
        planNote: '${suggestion.title}: ${draft.note}',
      );
    }
    return suggestion.workouts.length;
  }

  PlanCoachReply replyToCoach(String message) {
    return _planService.reply(message: message, catalog: _workoutTypes);
  }

  PlanSuggestion previewAiPlan(PlanRequest request) {
    return _planService.buildPlan(request, _workoutTypes);
  }

  Future<void> beginWorkoutSession(Exercise exercise) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final current = _findMatchingExercise(exercise.id);
    if (current == null) {
      return;
    }
    _selectedExercise = current.copyWith(
      repCount: 0,
      setCount: 0,
      status: 'IN SESSION',
      updatedAt: DateTime.now(),
    );
    _replaceWorkout(_selectedExercise!);
    _activeSession = WorkoutSession(
      id: _uuid.v4(),
      workoutId: current.id,
      workoutName: current.name,
      startedAt: DateTime.now(),
      targetReps: current.targetReps,
      targetSets: current.setGoal,
      repsCompleted: 0,
      setsCompleted: 0,
      formScore: current.depthScore,
      caloriesBurned: 0,
      coachSummary: 'Session started.',
    );
    await _saveUserData();
    notifyListeners();
  }

  Future<void> recordAnalysisFrame(WorkoutAnalysisFrame frame) async {
    final user = _currentUser;
    final exercise = _findMatchingExercise(frame.workoutId);
    if (user == null || exercise == null) {
      return;
    }

    final updated = exercise.copyWith(
      analyzed: frame.poseVisible,
      status: frame.poseVisible ? 'TRACKING' : 'SEARCHING',
      depthScore: frame.formScore,
      repCount: frame.repCount,
      setCount: frame.setCount,
      updatedAt: DateTime.now(),
    );
    _replaceWorkout(updated);
    _selectedExercise = updated;

    final active = _activeSession;
    if (active != null && active.workoutId == frame.workoutId) {
      _activeSession = active.copyWith(
        repsCompleted: frame.repCount,
        setsCompleted: frame.setCount,
        formScore: frame.formScore,
        caloriesBurned: _calculateCalories(
          active.copyWith(repsCompleted: frame.repCount),
        ),
        coachSummary: '${frame.primaryFeedback} ${frame.secondaryFeedback}',
      );
    }

    if (frame.repAdded || frame.repCount == updated.targetReps) {
      await _saveUserData();
    }
    notifyListeners();
  }

  Future<void> endWorkoutSession({String summary = 'Session saved.'}) async {
    final active = _activeSession;
    if (active == null) {
      return;
    }

    final completed = active.copyWith(
      endedAt: DateTime.now(),
      caloriesBurned: _calculateCalories(active),
      coachSummary: summary,
    );
    final exercise = _findMatchingExercise(active.workoutId);
    if (exercise != null) {
      final updated = exercise.copyWith(
        analyzed: completed.repsCompleted > 0 || completed.formScore > 0,
        status: completed.repsCompleted >= exercise.targetReps
            ? 'COMPLETED'
            : 'SAVED',
        depthScore: completed.formScore,
        repCount: completed.repsCompleted,
        setCount: completed.setsCompleted,
        totalReps: exercise.totalReps + completed.repsCompleted,
        sessionCount: exercise.sessionCount + 1,
        updatedAt: DateTime.now(),
      );
      _replaceWorkout(updated);
      _selectedExercise = updated;
    }

    _data = _data.copyWith(sessions: [..._data.sessions, completed]);
    _activeSession = null;
    await _saveUserData();
    notifyListeners();
  }

  Future<void> resetSelectedWorkout() async {
    final selected = _selectedExercise;
    if (selected == null) {
      return;
    }
    final updated = selected.copyWith(
      analyzed: false,
      status: 'PLANNED',
      depthScore: 0,
      repCount: 0,
      setCount: 0,
      updatedAt: DateTime.now(),
    );
    _replaceWorkout(updated);
    _selectedExercise = updated;
    await _saveUserData();
    notifyListeners();
  }

  Future<void> toggleMetricUnits(bool value) async {
    _data = _data.copyWith(metricUnits: value);
    await _saveUserData();
    notifyListeners();
  }

  Future<void> toggleVoiceFeedback(bool value) async {
    _data = _data.copyWith(voiceFeedback: value);
    await _saveUserData();
    notifyListeners();
  }

  Future<void> updateBodyMetrics({
    required double bodyWeightKg,
    required double heightCm,
  }) async {
    _data = _data.copyWith(
      bodyWeightKg: bodyWeightKg.clamp(30, 250).toDouble(),
      heightCm: heightCm.clamp(100, 240).toDouble(),
    );
    await _saveUserData();
    notifyListeners();
  }

  Future<void> updateProfileImagePath(String? path) async {
    _data = _data.copyWith(profileImagePath: path);
    await _saveUserData();
    notifyListeners();
  }

  WorkoutType workoutTypeForExercise(Exercise exercise) {
    return _workoutTypes.firstWhere(
      (type) => type.id == exercise.typeId,
      orElse: () => WorkoutRepository.workoutTypeById(exercise.typeId),
    );
  }

  double _calculateCalories(WorkoutSession session) {
    final exercise = _findMatchingExercise(session.workoutId);
    final type = exercise == null
        ? WorkoutRepository.workoutTypeById('push_up')
        : workoutTypeForExercise(exercise);
    final performedSeconds =
        session.repsCompleted * type.secondsPerRep +
        (session.setsCompleted * 20);
    final elapsedSeconds = (session.endedAt ?? DateTime.now())
        .difference(session.startedAt)
        .inSeconds
        .clamp(0, 7200);
    final activeSeconds = performedSeconds > 0
        ? performedSeconds
        : elapsedSeconds.toDouble();
    final minutes = (activeSeconds / 60).clamp(0.05, 240).toDouble();
    return type.metValue * 3.5 * _data.bodyWeightKg / 200 * minutes;
  }

  Future<void> _saveUserData() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }
    await _store.saveUserData(user.id, _data);
  }

  void _replaceWorkout(Exercise updated) {
    _data = _data.copyWith(
      workouts: [
        for (final workout in _data.workouts)
          if (workout.id == updated.id) updated else workout,
      ],
    );
  }

  Exercise? _findMatchingExercise(String id) {
    for (final exercise in _data.workouts) {
      if (exercise.id == id) {
        return exercise;
      }
    }
    return null;
  }

  StoredAccount? _accountByEmail(String email) {
    for (final account in _accounts) {
      if (account.user.email == email) {
        return account;
      }
    }
    return null;
  }

  StoredAccount? _accountByUserId(String userId) {
    for (final account in _accounts) {
      if (account.user.id == userId) {
        return account;
      }
    }
    return null;
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  bool _looksLikeEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  String _newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }
}
