import 'weather_condition.dart';

class WeatherAdvice {
  static const double hotThreshold = 32;
  static const double coldThreshold = 8;

  const WeatherAdvice._();

  static String forConditions({required WeatherCondition condition, required double temperature, required bool isNight}) {
    return switch (condition) {
      WeatherCondition.thunderstorm => 'Thunderstorm — stay indoors if you can',
      WeatherCondition.rain => 'Rain expected — take an umbrella',
      WeatherCondition.snow => 'Snow — dress warmly and watch the roads',
      WeatherCondition.fog => 'Foggy — drive carefully',
      WeatherCondition.clear || WeatherCondition.partlyCloudy => _forDryWeather(temperature, isNight),
    };
  }

  static String _forDryWeather(double temperature, bool isNight) {
    if (temperature >= hotThreshold) return 'Hot — drink plenty of water';
    if (temperature <= coldThreshold) return 'Cold — bring a jacket';
    return isNight ? 'A calm night' : 'A good day to be outside';
  }

  static String windLabel(double metersPerSecond) {
    if (metersPerSecond < 1.5) return 'Calm';
    if (metersPerSecond < 5.5) return 'Light breeze';
    if (metersPerSecond < 10.8) return 'Breezy';
    return 'Strong wind';
  }
}
