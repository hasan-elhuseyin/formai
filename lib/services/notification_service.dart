import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/exercise.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionsRequested = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();
    if (_permissionsRequested) {
      return true;
    }

    var granted = true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? true;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          granted;
    }

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macos != null) {
      granted =
          await macos.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          granted;
    }

    _permissionsRequested = true;
    return granted;
  }

  Future<void> scheduleWorkoutReminder(Exercise workout) async {
    await initialize();
    await cancelWorkoutReminder(workout.id);

    final reminder = _parseReminderTime(workout.reminderTime);
    if (reminder == null) {
      return;
    }

    await requestPermissions();
    final days =
        workout.scheduleDays
            .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
            .toSet()
            .toList()
          ..sort();
    if (days.isEmpty) {
      return;
    }

    for (final weekday in days) {
      await _scheduleWeeklyWorkout(
        workout: workout,
        weekday: weekday,
        hour: reminder.$1,
        minute: reminder.$2,
      );
    }
  }

  Future<void> cancelWorkoutReminder(String workoutId) async {
    await initialize();
    final baseId = _notificationBaseId(workoutId);
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(id: baseId + weekday);
    }
  }

  Future<void> cancelAllWorkoutReminders() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> rescheduleAll(List<Exercise> workouts) async {
    await initialize();
    await cancelAllWorkoutReminders();
    for (final workout in workouts) {
      await scheduleWorkoutReminder(workout);
    }
  }

  Future<void> _scheduleWeeklyWorkout({
    required Exercise workout,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final scheduledDate = _nextWeeklyInstance(
      weekday: weekday,
      hour: hour,
      minute: minute,
    );
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'formai_workout_reminders',
        'Workout reminders',
        channelDescription: 'Upcoming FORMAI workout reminders',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: _notificationBaseId(workout.id) + weekday,
        title: 'FORMAI workout',
        body:
            '${workout.name}: ${workout.setGoal} sets x ${workout.repGoal} reps',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: workout.id,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Workout reminder scheduling failed: $error');
      }
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  tz.TZDateTime _nextWeeklyInstance({
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    final daysUntil = (weekday - scheduled.weekday + 7) % 7;
    scheduled = scheduled.add(Duration(days: daysUntil));
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  (int, int)? _parseReminderTime(String? raw) {
    if (raw == null) {
      return null;
    }
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
    if (match == null) {
      return null;
    }
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return (hour, minute);
  }

  int _notificationBaseId(String workoutId) {
    var hash = 0x811c9dc5;
    for (final unit in workoutId.codeUnits) {
      hash = (hash ^ unit) * 0x01000193;
      hash = hash & 0x7fffffff;
    }
    return math.max(1, hash % 200000000) * 10;
  }
}
