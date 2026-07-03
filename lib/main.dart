import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
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
            home: _appState.isAuthenticated
                ? const AppShell()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
