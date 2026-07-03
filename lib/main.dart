import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const FormaiApp());
}

class FormaiApp extends StatefulWidget {
  const FormaiApp({super.key});

  @override
  State<FormaiApp> createState() => _FormaiAppState();
}

class _FormaiAppState extends State<FormaiApp> {
  late final AppState _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: _appState,
      child: AnimatedBuilder(
        animation: _appState,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FORMAI',
            theme: AppTheme.dark,
            home: !_appState.isReady
                ? const _StartupScreen()
                : _appState.isAuthenticated
                ? const AppShell()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.lime, strokeWidth: 2),
      ),
    );
  }
}
