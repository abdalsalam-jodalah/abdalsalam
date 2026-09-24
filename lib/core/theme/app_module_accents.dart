import 'package:flutter/painting.dart';

class AppModuleAccents {
  const AppModuleAccents._();

  static const Color fallback = Color(0xFF64748B);

  static const Map<String, Color> byModule = <String, Color>{
    'dashboard': Color(0xFF00B8D4),
    'religious': Color(0xFF8B5CF6),
    'financial': Color(0xFF10B981),
    'habits': Color(0xFF3B82F6),
    'planning': Color(0xFF6366F1),
    'day-planning': Color(0xFF0EA5E9),
    'sports': Color(0xFFF97316),
    'health': Color(0xFFEF4444),
    'sleep': Color(0xFF6366F1),
    'food': Color(0xFFF59E0B),
    'medications': Color(0xFFEC4899),
    'notes': Color(0xFFEAB308),
    'calendar': Color(0xFF14B8A6),
    'security': Color(0xFF475569),
    'analytics': Color(0xFF0891B2),
    'settings': Color(0xFF64748B),
  };

  static Color forModule(String moduleKey) => byModule[moduleKey] ?? fallback;
}
