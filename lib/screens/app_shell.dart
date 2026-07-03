import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_coach_nav.dart';
import '../widgets/phone_frame.dart';
import 'analysis_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'workouts_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final workoutFullscreen =
        appState.selectedTab == 2 && appState.activeSession != null;

    return PhoneFrame(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned.fill(child: _TabBody(index: appState.selectedTab)),
            if (!workoutFullscreen)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomCoachNav(currentIndex: appState.selectedTab),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => const HomeScreen(),
      1 => const WorkoutsScreen(),
      2 => const AnalysisScreen(),
      3 => const ProfileScreen(),
      4 => const StatsScreen(),
      _ => const HomeScreen(),
    };
  }
}
