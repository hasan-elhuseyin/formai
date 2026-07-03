import 'package:flutter/foundation.dart';

import '../data/workout_repository.dart';
import '../models/app_user.dart';
import '../models/exercise.dart';

class AuthResult {
  const AuthResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class AppState extends ChangeNotifier {
  AppState()
    : _exercises = WorkoutRepository.exercises,
      _selectedExercise = WorkoutRepository.exercises.first {
    _accounts['matt@formai.app'] = const _StoredAccount(
      user: AppUser(name: 'Matt Johnson', email: 'matt@formai.app'),
      password: 'formai24',
    );
  }

  final Map<String, _StoredAccount> _accounts = {};
  final List<Exercise> _exercises;

  AppUser? _currentUser;
  Exercise _selectedExercise;
  int _selectedTab = 0;
  bool _metricUnits = true;
  bool _voiceFeedback = true;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  List<Exercise> get exercises => List.unmodifiable(_exercises);
  Exercise get selectedExercise => _selectedExercise;
  int get selectedTab => _selectedTab;
  bool get metricUnits => _metricUnits;
  bool get voiceFeedback => _voiceFeedback;

  int get completedWorkoutCount {
    return _exercises.where((exercise) => exercise.analyzed).length;
  }

  int get totalSetCount {
    return _exercises.fold(0, (total, exercise) => total + exercise.repCount);
  }

  int get totalWeightKg {
    return 2800 + totalSetCount * 25;
  }

  AuthResult signIn({required String email, required String password}) {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Enter your email and password.',
      );
    }

    final account = _accounts[normalizedEmail];
    if (account == null || account.password != password) {
      return const AuthResult(
        success: false,
        message: 'Email or password is incorrect.',
      );
    }

    _currentUser = account.user;
    _selectedTab = 0;
    notifyListeners();
    return AuthResult(
      success: true,
      message: 'Welcome back, ${account.user.name}.',
    );
  }

  AuthResult signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
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
    if (password.length < 6) {
      return const AuthResult(
        success: false,
        message: 'Password must be at least 6 characters.',
      );
    }
    if (password != confirmPassword) {
      return const AuthResult(
        success: false,
        message: 'Passwords do not match.',
      );
    }
    if (_accounts.containsKey(normalizedEmail)) {
      return const AuthResult(
        success: false,
        message: 'An account with this email already exists.',
      );
    }

    final user = AppUser(name: trimmedName, email: normalizedEmail);
    _accounts[normalizedEmail] = _StoredAccount(user: user, password: password);
    _currentUser = user;
    _selectedTab = 0;
    notifyListeners();
    return AuthResult(success: true, message: 'Account created.');
  }

  void continueWithProvider(String provider) {
    final normalizedProvider = provider.toLowerCase();
    final user = AppUser(
      name: provider == 'Apple' ? 'Apple Athlete' : 'Google Athlete',
      email: '$normalizedProvider@formai.local',
    );
    _accounts[user.email] = _StoredAccount(user: user, password: 'provider');
    _currentUser = user;
    _selectedTab = 0;
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    _selectedTab = 0;
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
    _selectedExercise = _findMatchingExercise(exercise);
    _selectedTab = 2;
    notifyListeners();
  }

  List<Exercise> filterExercises(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return exercises;
    }

    return _exercises
        .where(
          (exercise) =>
              exercise.name.toLowerCase().contains(normalized) ||
              exercise.category.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  void recordAnalysisRep() {
    final nextDepth = (_selectedExercise.depthScore + 2).clamp(0, 99);
    final nextRep = (_selectedExercise.repCount + 1).clamp(
      0,
      _selectedExercise.repGoal,
    );
    _updateSelectedExercise(
      _selectedExercise.copyWith(
        analyzed: true,
        status: 'ANALYZED',
        depthScore: nextDepth,
        repCount: nextRep,
      ),
    );
  }

  void resetSelectedWorkout() {
    _updateSelectedExercise(
      _selectedExercise.copyWith(
        analyzed: false,
        status: 'NOT STARTED',
        repCount: 0,
      ),
    );
  }

  void toggleMetricUnits(bool value) {
    _metricUnits = value;
    notifyListeners();
  }

  void toggleVoiceFeedback(bool value) {
    _voiceFeedback = value;
    notifyListeners();
  }

  void _updateSelectedExercise(Exercise updated) {
    final index = _exercises.indexWhere(
      (exercise) => exercise.name == updated.name,
    );
    if (index != -1) {
      _exercises[index] = updated;
    }
    _selectedExercise = updated;
    notifyListeners();
  }

  Exercise _findMatchingExercise(Exercise exercise) {
    return _exercises.firstWhere(
      (candidate) => candidate.name == exercise.name,
      orElse: () => exercise,
    );
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  bool _looksLikeEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}

class _StoredAccount {
  const _StoredAccount({required this.user, required this.password});

  final AppUser user;
  final String password;
}
