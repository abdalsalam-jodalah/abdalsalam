import 'package:abdalsalam/features/weather/services/weather_advice.dart';
import 'package:abdalsalam/features/weather/services/weather_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeatherCondition.fromIcon', () {
    test('should map OpenWeather icon prefixes to conditions', () {
      expect(WeatherCondition.fromIcon('01d'), WeatherCondition.clear);
      expect(WeatherCondition.fromIcon('02d'), WeatherCondition.partlyCloudy);
      expect(WeatherCondition.fromIcon('09d'), WeatherCondition.rain);
      expect(WeatherCondition.fromIcon('10n'), WeatherCondition.rain);
      expect(WeatherCondition.fromIcon('11d'), WeatherCondition.thunderstorm);
      expect(WeatherCondition.fromIcon('13d'), WeatherCondition.snow);
      expect(WeatherCondition.fromIcon('50d'), WeatherCondition.fog);
    });

    test('should fall back to partly cloudy for unknown or empty icons', () {
      expect(WeatherCondition.fromIcon(''), WeatherCondition.partlyCloudy);
      expect(WeatherCondition.fromIcon('xx'), WeatherCondition.partlyCloudy);
    });

    test('should detect night icons', () {
      expect(WeatherCondition.isNightIcon('01n'), isTrue);
      expect(WeatherCondition.isNightIcon('01d'), isFalse);
    });
  });

  group('WeatherAdvice', () {
    test('should warn about storms rain snow and fog regardless of temperature', () {
      String adviceFor(WeatherCondition condition) =>
          WeatherAdvice.forConditions(condition: condition, temperature: 20, isNight: false);

      expect(adviceFor(WeatherCondition.thunderstorm), contains('indoors'));
      expect(adviceFor(WeatherCondition.rain), contains('umbrella'));
      expect(adviceFor(WeatherCondition.snow), contains('warmly'));
      expect(adviceFor(WeatherCondition.fog), contains('carefully'));
    });

    test('should advise about heat and cold for dry weather', () {
      String adviceFor(double temperature) =>
          WeatherAdvice.forConditions(condition: WeatherCondition.clear, temperature: temperature, isNight: false);

      expect(adviceFor(WeatherAdvice.hotThreshold), contains('water'));
      expect(adviceFor(WeatherAdvice.coldThreshold), contains('jacket'));
      expect(adviceFor(22), contains('outside'));
    });

    test('should describe a mild night differently from a mild day', () {
      final night = WeatherAdvice.forConditions(condition: WeatherCondition.clear, temperature: 20, isNight: true);

      expect(night, contains('night'));
    });

    test('should label wind speed', () {
      expect(WeatherAdvice.windLabel(0.5), 'Calm');
      expect(WeatherAdvice.windLabel(3), 'Light breeze');
      expect(WeatherAdvice.windLabel(8), 'Breezy');
      expect(WeatherAdvice.windLabel(15), 'Strong wind');
    });
  });
}
