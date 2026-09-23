import 'dart:convert';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/features/weather/services/open_meteo_response_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpenMeteoResponseParser', () {
    const parser = OpenMeteoResponseParser(cityName: 'Nablus');

    test('should parse current weather and hourly forecast', () {
      final body = jsonEncode(<String, dynamic>{
        'current_weather': <String, dynamic>{
          'temperature': 24.5,
          'windspeed': 12,
          'weathercode': 61,
          'time': '2026-09-23T14:00',
        },
        'hourly': <String, dynamic>{
          'time': <String>['2026-09-23T14:00', '2026-09-23T15:00'],
          'temperature_2m': <num>[24.5, 23],
          'relative_humidity_2m': <num>[40, 45],
          'weathercode': <num>[61, 0],
          'wind_speed_10m': <num>[12, 10.5],
        },
      });

      final weather = parser.parse(body);

      expect(weather.cityName, 'Nablus');
      expect(weather.temperature, 24.5);
      expect(weather.windSpeed, 12.0);
      expect(weather.humidity, 40);
      expect(weather.description, 'Rain');
      expect(weather.timestamp, DateTime(2026, 9, 23, 14));
      expect(weather.isStale, isFalse);
      expect(weather.hourlyForecast.length, 2);
      expect(weather.hourlyForecast.last.description, 'Clear sky');
      expect(weather.hourlyForecast.last.windSpeed, 10.5);
    });

    test('should cap the hourly forecast at twelve entries', () {
      final times = List<String>.generate(24, (hour) => '2026-09-23T${hour.toString().padLeft(2, '0')}:00');
      final body = jsonEncode(<String, dynamic>{
        'current_weather': <String, dynamic>{'temperature': 20, 'time': '2026-09-23T00:00'},
        'hourly': <String, dynamic>{
          'time': times,
          'temperature_2m': List<num>.filled(24, 20),
        },
      });

      final weather = parser.parse(body);

      expect(weather.hourlyForecast.length, 12);
    });

    test('should skip hourly entries with invalid values and default optional fields', () {
      final body = jsonEncode(<String, dynamic>{
        'current_weather': <String, dynamic>{
          'temperature': '19.5',
          'windspeed': 'fast',
          'weathercode': 'unknown',
          'time': '2026-09-23T14:00',
        },
        'hourly': <String, dynamic>{
          'time': <Object?>['not a date', '2026-09-23T15:00', null],
          'temperature_2m': <Object?>[20, 'warm', 18],
          'relative_humidity_2m': 'not a list',
        },
      });

      final weather = parser.parse(body);

      expect(weather.temperature, 19.5);
      expect(weather.windSpeed, 0);
      expect(weather.humidity, 0);
      expect(weather.description, 'Unknown');
      expect(weather.hourlyForecast, isEmpty);
    });

    test('should throw CorruptDataError when current weather is missing', () {
      final body = jsonEncode(<String, dynamic>{'hourly': <String, dynamic>{}});

      expect(() => parser.parse(body), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when current time is unparseable', () {
      final body = jsonEncode(<String, dynamic>{
        'current_weather': <String, dynamic>{'temperature': 20, 'time': 'yesterday'},
      });

      expect(() => parser.parse(body), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when the body is not a JSON object', () {
      expect(() => parser.parse('[1, 2, 3]'), throwsA(isA<CorruptDataError>()));
    });
  });
}
