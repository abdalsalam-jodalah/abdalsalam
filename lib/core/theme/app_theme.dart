// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

import 'text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00B8D4),
      brightness: Brightness.light,
      surface: const Color(0xFFF7FBFC),
      onSurface: const Color(0xFF0F1C22),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFEAF7FA),
      appBarTheme: const AppBarTheme(centerTitle: false),
      textTheme: const TextTheme(
        headlineMedium: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.subtitle,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00B8D4),
      brightness: Brightness.dark,
      surface: const Color(0xFF0E171C),
      onSurface: const Color(0xFFE6F3F7),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF071318),
      appBarTheme: const AppBarTheme(centerTitle: false),
      textTheme: const TextTheme(
        headlineMedium: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.subtitle,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
