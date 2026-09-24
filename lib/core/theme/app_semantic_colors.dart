import 'package:flutter/material.dart';

class AppSemanticColors {
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color income;
  final Color expense;
  final Color muted;

  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.income,
    required this.expense,
    required this.muted,
  });

  factory AppSemanticColors.forScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final success = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    final danger = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    return AppSemanticColors(
      success: success,
      warning: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      danger: danger,
      info: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
      income: success,
      expense: danger,
      muted: scheme.onSurfaceVariant,
    );
  }

  AppSemanticColors lerp(AppSemanticColors other, double t) {
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}
