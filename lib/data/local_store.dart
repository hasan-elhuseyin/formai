import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';

class StoredAccount {
  const StoredAccount({
    required this.user,
    required this.passwordSalt,
    required this.passwordHash,
  });

  final AppUser user;
  final String passwordSalt;
  final String passwordHash;

  factory StoredAccount.fromJson(Map<String, Object?> json) {
    return StoredAccount(
      user: AppUser.fromJson(json['user'] as Map<String, Object?>),
      passwordSalt: json['passwordSalt'] as String,
      passwordHash: json['passwordHash'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'user': user.toJson(),
      'passwordSalt': passwordSalt,
      'passwordHash': passwordHash,
    };
  }
}

class UserData {
  const UserData({
    required this.workouts,
    required this.sessions,
    required this.metricUnits,
    required this.voiceFeedback,
  });

  final List<Exercise> workouts;
  final List<WorkoutSession> sessions;
  final bool metricUnits;
  final bool voiceFeedback;

  factory UserData.empty() {
    return const UserData(
      workouts: [],
      sessions: [],
      metricUnits: true,
      voiceFeedback: true,
    );
  }

  UserData copyWith({
    List<Exercise>? workouts,
    List<WorkoutSession>? sessions,
    bool? metricUnits,
    bool? voiceFeedback,
  }) {
    return UserData(
      workouts: workouts ?? this.workouts,
      sessions: sessions ?? this.sessions,
      metricUnits: metricUnits ?? this.metricUnits,
      voiceFeedback: voiceFeedback ?? this.voiceFeedback,
    );
  }

  factory UserData.fromJson(Map<String, Object?> json) {
    return UserData(
      workouts: (json['workouts'] as List<Object?>? ?? const [])
          .map((item) => Exercise.fromJson(item as Map<String, Object?>))
          .toList(growable: false),
      sessions: (json['sessions'] as List<Object?>? ?? const [])
          .map((item) => WorkoutSession.fromJson(item as Map<String, Object?>))
          .toList(growable: false),
      metricUnits: json['metricUnits'] as bool? ?? true,
      voiceFeedback: json['voiceFeedback'] as bool? ?? true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'workouts': workouts.map((workout) => workout.toJson()).toList(),
      'sessions': sessions.map((session) => session.toJson()).toList(),
      'metricUnits': metricUnits,
      'voiceFeedback': voiceFeedback,
    };
  }
}

class LocalStore {
  static const String _accountsKey = 'formai.accounts.v1';
  static const String _currentUserKey = 'formai.currentUserId.v1';
  static const String _userDataPrefix = 'formai.userData.v1.';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<StoredAccount>> loadAccounts() async {
    await init();
    final raw = _prefs!.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<Object?>;
    return decoded
        .map((item) => StoredAccount.fromJson(item as Map<String, Object?>))
        .toList(growable: false);
  }

  Future<void> saveAccounts(List<StoredAccount> accounts) async {
    await init();
    final raw = jsonEncode(
      accounts.map((account) => account.toJson()).toList(growable: false),
    );
    await _prefs!.setString(_accountsKey, raw);
  }

  Future<String?> loadCurrentUserId() async {
    await init();
    return _prefs!.getString(_currentUserKey);
  }

  Future<void> saveCurrentUserId(String? userId) async {
    await init();
    if (userId == null) {
      await _prefs!.remove(_currentUserKey);
      return;
    }
    await _prefs!.setString(_currentUserKey, userId);
  }

  Future<UserData> loadUserData(String userId) async {
    await init();
    final raw = _prefs!.getString('$_userDataPrefix$userId');
    if (raw == null || raw.isEmpty) {
      return UserData.empty();
    }
    return UserData.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  Future<void> saveUserData(String userId, UserData data) async {
    await init();
    await _prefs!.setString(
      '$_userDataPrefix$userId',
      jsonEncode(data.toJson()),
    );
  }
}
