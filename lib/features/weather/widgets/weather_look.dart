import 'package:flutter/material.dart';

import '../services/weather_condition.dart';

class WeatherLook {
  final List<Color> gradient;
  final IconData icon;

  const WeatherLook({required this.gradient, required this.icon});

  static const Map<WeatherCondition, List<Color>> _dayGradients = <WeatherCondition, List<Color>>{
    WeatherCondition.clear: [Color(0xFF1E6FD9), Color(0xFF5BA8F5)],
    WeatherCondition.partlyCloudy: [Color(0xFF4A7FC1), Color(0xFF8FB3D9)],
    WeatherCondition.rain: [Color(0xFF3B4A5E), Color(0xFF5F7389)],
    WeatherCondition.thunderstorm: [Color(0xFF2B2145), Color(0xFF4B3F72)],
    WeatherCondition.snow: [Color(0xFF5A7BA0), Color(0xFF9FB8D3)],
    WeatherCondition.fog: [Color(0xFF5B6472), Color(0xFF8A93A1)],
  };

  static const Map<WeatherCondition, List<Color>> _nightGradients = <WeatherCondition, List<Color>>{
    WeatherCondition.clear: [Color(0xFF0B1B3F), Color(0xFF2B3A67)],
    WeatherCondition.partlyCloudy: [Color(0xFF1C2A4A), Color(0xFF3E4C6E)],
    WeatherCondition.rain: [Color(0xFF1F2937), Color(0xFF374151)],
    WeatherCondition.thunderstorm: [Color(0xFF150F26), Color(0xFF30284F)],
    WeatherCondition.snow: [Color(0xFF2F4560), Color(0xFF5B7491)],
    WeatherCondition.fog: [Color(0xFF2E343E), Color(0xFF4B5563)],
  };

  factory WeatherLook.of(WeatherCondition condition, {required bool isNight}) {
    final gradients = isNight ? _nightGradients : _dayGradients;
    return WeatherLook(gradient: gradients[condition]!, icon: _iconFor(condition, isNight: isNight));
  }

  static IconData _iconFor(WeatherCondition condition, {required bool isNight}) {
    return switch (condition) {
      WeatherCondition.clear => isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
      WeatherCondition.partlyCloudy => isNight ? Icons.nights_stay_rounded : Icons.wb_cloudy_rounded,
      WeatherCondition.rain => Icons.umbrella_rounded,
      WeatherCondition.thunderstorm => Icons.thunderstorm_rounded,
      WeatherCondition.snow => Icons.ac_unit_rounded,
      WeatherCondition.fog => Icons.foggy,
    };
  }
}
