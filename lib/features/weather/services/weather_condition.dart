enum WeatherCondition {
  clear,
  partlyCloudy,
  fog,
  rain,
  snow,
  thunderstorm;

  static const int _iconCodeLength = 2;
  static const String _nightSuffix = 'n';

  static WeatherCondition fromIcon(String iconCode) {
    final prefix = iconCode.length >= _iconCodeLength ? iconCode.substring(0, _iconCodeLength) : iconCode;
    return switch (prefix) {
      '01' => WeatherCondition.clear,
      '09' || '10' => WeatherCondition.rain,
      '11' => WeatherCondition.thunderstorm,
      '13' => WeatherCondition.snow,
      '50' => WeatherCondition.fog,
      _ => WeatherCondition.partlyCloudy,
    };
  }

  static bool isNightIcon(String iconCode) => iconCode.endsWith(_nightSuffix);
}
