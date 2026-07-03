import 'dart:ui';

import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme/app_theme.dart';

class BottomCoachNav extends StatelessWidget {
  const BottomCoachNav({required this.currentIndex, super.key});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 83,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.82),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                label: 'HOME',
                icon: Icons.home_outlined,
                active: currentIndex == 0,
                onTap: () => appState.selectTab(0),
              ),
              _NavItem(
                label: 'WORKOUTS',
                icon: Icons.fitness_center,
                active: currentIndex == 1,
                onTap: () => appState.selectTab(1),
              ),
              _NavItem(
                label: 'AI COACH',
                icon: Icons.psychology_alt_outlined,
                active: currentIndex == 2,
                onTap: () => appState.selectTab(2),
              ),
              _NavItem(
                label: 'PROFILE',
                icon: Icons.person_outline,
                active: currentIndex == 3,
                onTap: () => appState.selectTab(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.limeAlt : AppColors.slate;
    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            height: 1.2,
          ),
        ),
      ],
    );

    return Opacity(
      opacity: active ? 1 : 0.62,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 99 : 66,
          height: active ? 50 : 46,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? AppColors.limeAlt.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ),
    );
  }
}
