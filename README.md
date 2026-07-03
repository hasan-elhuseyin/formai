# FORMAI

FORMAI is a Flutter fitness coach app with local accounts, user-owned workout
plans, saved session stats, AI-assisted plan creation, and live camera pose
analysis through Google ML Kit.

## What Works

- Real local sign-up and sign-in with salted password hashes in device storage.
- No seeded account, seeded progress, or default demo workout data.
- User-scoped workout plans, reminders, rep/set targets, preferences, and saved
  session history.
- Built-in movement catalog for push-up, squat, pull-up, deadlift, lunge, plank,
  and shoulder press.
- AI-style plan builder and coach discussion flow that generates trackable
  workouts from the user's goal, experience, schedule, and equipment.
- Live camera frame processing with `google_mlkit_pose_detection`.
- Workout-specific landmark analysis for rep counting and form feedback.

## Flutter Version

- Flutter 3.41.4 stable
- Dart 3.11.1

## Native Notes

- Android uses `camera` stream frames in `ImageFormatGroup.nv21`.
- iOS uses `ImageFormatGroup.bgra8888`.
- Google ML Kit requires iOS deployment target 15.5 or newer.
- On Apple Silicon with iOS 26+ simulator targets, Google ML Kit currently
  reports missing arm64 simulator slices. Device builds work; simulator support
  depends on the native ML Kit pods.

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --no-codesign
```

## Structure

```text
lib/
  data/
    local_store.dart
    workout_repository.dart
  models/
    app_user.dart
    exercise.dart
    workout_session.dart
    workout_type.dart
  screens/
    analysis_screen.dart
    app_shell.dart
    home_screen.dart
    login_screen.dart
    profile_screen.dart
    workouts_screen.dart
  services/
    ai_plan_service.dart
    camera_input_image.dart
    pose_workout_analyzer.dart
  state/
    app_scope.dart
    app_state.dart
  theme/
  widgets/
  main.dart
assets/
  fonts/
  images/
```

## App Flow

1. Create an account from the login screen.
2. Build a plan in Workouts with the AI plan builder or Quick Add.
3. Open a saved workout to start AI Coach analysis.
4. Allow camera access and keep the full body in frame.
5. Pause analysis to save the session and update stats.
