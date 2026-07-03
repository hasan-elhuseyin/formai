# FORMAI

FORMAI is a Flutter app for an AI fitness coach. It includes local sign-in/sign-up, a working tab shell, workout browsing, profile controls, live camera preview for the AI Coach screen, and real-time form-feedback simulation.

The UI follows the supplied Figma design for:

- Sign in / sign up
- Home / training dashboard
- Workouts
- AI analysis session
- Profile

## Flutter Version

- Flutter 3.41.4 stable
- Dart 3.11.1

## Project Notes

- The app uses Flutter Material widgets plus the official `camera` plugin for live camera preview.
- Sign in and sign up are functional with an in-memory local account store.
- Default demo login: `matt@formai.app` / `formai24`.
- The auth screen is intentionally non-scrollable and Android is configured with `adjustNothing` so keyboard display does not resize/zoom the background.
- AI movement scoring is local simulated feedback layered over the live camera preview.
- Exercise data is modeled from a local JSON-like source using `fromJson` and `toJson`.
- Bottom navigation uses a real tab shell: Home, Workouts, AI Coach, and Profile all work.
- The exercise routine uses `GridView.builder` with a single-column layout to preserve the Figma list design.

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze
flutter test
```

## Structure

```text
lib/
  data/
    workout_repository.dart
  models/
    app_user.dart
    exercise.dart
  screens/
    analysis_screen.dart
    app_shell.dart
    home_screen.dart
    login_screen.dart
    profile_screen.dart
    workouts_screen.dart
  state/
    app_scope.dart
    app_state.dart
  theme/
    app_theme.dart
  widgets/
    app_logo.dart
    bottom_coach_nav.dart
    glass_panel.dart
    lime_button.dart
    phone_frame.dart
  main.dart
assets/
  fonts/
  images/
```

## Screenshots

Capture screenshots after launching on an emulator or device:

```sh
flutter run
```

The implemented screens are available through the normal app flow:

1. Start at the login screen.
2. Use the default credentials or create a new account.
3. Use the bottom navigation to move between Home, Workouts, AI Coach, and Profile.
4. Tap a workout to select it for AI Coach analysis.
