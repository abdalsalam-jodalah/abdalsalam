import 'dart:convert';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/weather/weather_model.dart';
import 'package:abdalsalam/features/weather/services/weather_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _timestamp = DateTime.utc(2026, 4, 1, 12);
final _forecastTime = DateTime.utc(2026, 4, 1, 13);
const _okStatus = 200;
const _serverErrorStatus = 500;

HourlyForecast _forecast() => HourlyForecast(
      time: _forecastTime,
      temperature: 21.5,
      description: 'Clear sky',
      icon: '01d',
      humidity: 40,
      windSpeed: 3.5,
    );

WeatherModel _weather() => WeatherModel(
      cityName: 'Nablus',
      temperature: 22.5,
      feelsLike: 21,
      humidity: 45,
      windSpeed: 4.2,
      description: 'Partly cloudy',
      icon: '02d',
      timestamp: _timestamp,
      hourlyForecast: [_forecast()],
    );

Map<String, dynamic> _openMeteoResponse() => <String, dynamic>{
      'current_weather': <String, dynamic>{
        'temperature': 24.3,
        'windspeed': 5.1,
        'weathercode': 2,
        'time': '2026-04-01T12:00',
      },
      'hourly': <String, dynamic>{
        'time': ['2026-04-01T12:00', '2026-04-01T13:00'],
        'temperature_2m': [24.3, 25.0],
        'relative_humidity_2m': [38, 36],
        'weathercode': [2, 0],
        'wind_speed_10m': [5.1, 4.8],
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('WeatherModel.fromJson', () {
    test('should keep every field including hourly forecast when round-tripping through toJson', () {
      final weather = _weather();

      final parsed = WeatherModel.fromJson(weather.toJson());

      expect(parsed, weather);
      expect(parsed.hourlyForecast, [_forecast()]);
    });

    test('should survive a JSON string encode and decode like the preferences cache', () {
      final weather = _weather();
      final decoded = jsonDecode(jsonEncode(weather.toJson())) as Map<String, dynamic>;

      final parsed = WeatherModel.fromJson(decoded);

      expect(parsed, weather);
    });

    test('should use defaults when optional fields are missing', () {
      final json = <String, dynamic>{
        'temperature': 20,
        'timestamp': _timestamp.toIso8601String(),
      };

      final parsed = WeatherModel.fromJson(json);

      expect(parsed.cityName, '');
      expect(parsed.feelsLike, 20.0);
      expect(parsed.humidity, 0);
      expect(parsed.windSpeed, 0);
      expect(parsed.hourlyForecast, isEmpty);
    });

    test('should tolerate wrong numeric types', () {
      final json = {..._weather().toJson(), 'humidity': 45.0, 'temperature': '23.5', 'windSpeed': 4};

      final parsed = WeatherModel.fromJson(json);

      expect(parsed.humidity, 45);
      expect(parsed.temperature, 23.5);
      expect(parsed.windSpeed, 4.0);
    });

    test('should throw CorruptDataError when timestamp is invalid', () {
      final json = {..._weather().toJson(), 'timestamp': 'now'};

      expect(() => WeatherModel.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when temperature is missing', () {
      final json = _weather().toJson()..remove('temperature');

      expect(() => WeatherModel.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('HourlyForecast.fromJson', () {
    test('should keep every field when round-tripping through toJson', () {
      final forecast = _forecast();

      final parsed = HourlyForecast.fromJson(forecast.toJson());

      expect(parsed, forecast);
    });

    test('should use defaults when optional fields are missing', () {
      final json = <String, dynamic>{
        'time': _forecastTime.toIso8601String(),
        'temperature': 18,
      };

      final parsed = HourlyForecast.fromJson(json);

      expect(parsed.description, '');
      expect(parsed.icon, '');
      expect(parsed.humidity, 0);
      expect(parsed.windSpeed, 0);
    });

    test('should tolerate wrong numeric types', () {
      final json = {..._forecast().toJson(), 'humidity': '41', 'windSpeed': 3};

      final parsed = HourlyForecast.fromJson(json);

      expect(parsed.humidity, 41);
      expect(parsed.windSpeed, 3.0);
    });

    test('should throw CorruptDataError when time is invalid', () {
      final json = {..._forecast().toJson(), 'time': 'later'};

      expect(() => HourlyForecast.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('WeatherService offline cache', () {
    final storage = StorageGateway.instance;
    late LoggerService logger;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      await storage.initialize(databaseName: 'test_weather_models_test.db');
      logger = LoggerService.forModule('WeatherModelsTest');
    });

    test('should return the cached weather with hourly forecast when the network fails after a fetch', () async {
      final onlineClient = MockClient((_) async => http.Response(jsonEncode(_openMeteoResponse()), _okStatus));
      final offlineClient = MockClient((_) async => http.Response('{}', _serverErrorStatus));

      final fetched = await WeatherService(logger, storage, httpClient: onlineClient).getWeatherForNablus();
      final cached = await WeatherService(logger, storage, httpClient: offlineClient).getWeatherForNablus();

      expect(fetched.data?.hourlyForecast, hasLength(2));
      expect(cached.data?.hourlyForecast, fetched.data?.hourlyForecast);
      expect(cached.data?.temperature, fetched.data?.temperature);
    });
  });
}
