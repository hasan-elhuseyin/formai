import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF111318);
  static const Color input = Color(0xFF1A1C20);
  static const Color panel = Color(0xFF282A2E);
  static const Color glass = Color(0xFF333539);
  static const Color text = Color(0xFFE2E2E8);
  static const Color muted = Color(0xFFB8B8B8);
  static const Color slate = Color(0xFF64748B);
  static const Color lime = Color(0xFFB6F36A);
  static const Color limeAlt = Color(0xFFA3E635);
  static const Color buttonText = Color(0xFF1F3700);
  static const Color alert = Color(0xFFFFB4AB);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Inter',
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.lime,
        secondary: AppColors.limeAlt,
        surface: AppColors.panel,
        onSurface: AppColors.text,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Inter',
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        isCollapsed: true,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
