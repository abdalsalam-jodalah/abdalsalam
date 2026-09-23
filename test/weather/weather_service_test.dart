import 'dart:convert';
import 'dart:io';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/features/weather/services/weather_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeatherService', () {
    const weatherKey = 'weather_data';
    const lastUpdateKey = 'weather_last_update';
    final fixedNow = DateTime(2026, 9, 23, 15);
    late DateTime currentTime;
    late int requestCount;

    String validBody({double temperature = 24}) => jsonEncode(<String, dynamic>{
          'current_weather': <String, dynamic>{
            'temperature': temperature,
            'windspeed': 10,
            'weathercode': 0,
            'time': '2026-09-23T15:00',
          },
          'hourly': <String, dynamic>{
            'time': <String>['2026-09-23T15:00'],
            'temperature_2m': <num>[temperature],
            'relative_humidity_2m': <num>[35],
            'weathercode': <num>[0],
            'wind_speed_10m': <num>[10],
          },
        });

    WeatherService buildService(Future<http.Response> Function(http.Request request) handler) {
      return WeatherService(
        LoggerService.forModule('WeatherServiceTest'),
        StorageGateway.instance,
        httpClient: MockClient((request) {
          requestCount++;
          return handler(request);
        }),
        clock: () => currentTime,
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      await StorageGateway.instance.initialize(databaseName: 'test_weather_service_test.db');
      await StorageGateway.instance.delete(weatherKey);
      await StorageGateway.instance.delete(lastUpdateKey);
      StorageGateway.instance.integrityReporter.clearReports();
      currentTime = fixedNow;
      requestCount = 0;
    });

    test('should return fresh weather that is not stale when the API succeeds', () async {
      final service = buildService((_) async => http.Response(validBody(), 200));

      final result = await service.getWeatherForNablus();

      final weather = result.getOrThrow();
      expect(weather.temperature, 24);
      expect(weather.isStale, isFalse);
      expect(await StorageGateway.instance.get<Map<String, dynamic>>(weatherKey), isNotNull);
    });

    test('should serve the cache without a network call while it is still valid', () async {
      final service = buildService((_) async => http.Response(validBody(), 200));
      await service.getWeatherForNablus();
      currentTime = fixedNow.add(const Duration(minutes: 30));

      final result = await service.getWeatherForNablus();

      expect(result.getOrThrow().isStale, isFalse);
      expect(requestCount, 1);
    });

    test('should return stale cached weather when the network fails after the cache expired', () async {
      var isOnline = true;
      final service = buildService((_) async {
        if (!isOnline) {
          throw const SocketException('offline');
        }
        return http.Response(validBody(temperature: 18), 200);
      });
      await service.getWeatherForNablus();
      isOnline = false;
      currentTime = fixedNow.add(const Duration(hours: 2));

      final result = await service.getWeatherForNablus();

      final weather = result.getOrThrow();
      expect(weather.isStale, isTrue);
      expect(weather.temperature, 18);
    });

    test('should return stale weather loaded from storage when the API returns an error status', () async {
      final seeded = buildService((_) async => http.Response(validBody(temperature: 21), 200));
      await seeded.getWeatherForNablus();
      currentTime = fixedNow.add(const Duration(hours: 3));
      final service = buildService((_) async => http.Response('unavailable', 503));

      final result = await service.getWeatherForNablus();

      expect(result.getOrThrow().isStale, isTrue);
      expect(result.data!.temperature, 21);
    });

    test('should return a NetworkError when the network fails and nothing is cached', () async {
      final service = buildService((_) async => throw const SocketException('offline'));

      final result = await service.getWeatherForNablus();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<NetworkError>());
    });

    test('should return a NetworkError when the API responds with a non-OK status and nothing is cached', () async {
      final service = buildService((_) async => http.Response('{}', 500));

      final result = await service.getWeatherForNablus();

      expect(result.error, isA<NetworkError>());
    });

    test('should return CorruptDataError when the API body is malformed and nothing is cached', () async {
      final service = buildService((_) async => http.Response('{"current_weather": "broken"', 200));

      final result = await service.getWeatherForNablus();

      expect(result.error, isA<CorruptDataError>());
    });

    test('should treat an unparseable stored update time as expired and report it', () async {
      final seeded = buildService((_) async => http.Response(validBody(), 200));
      await seeded.getWeatherForNablus();
      await StorageGateway.instance.save(key: lastUpdateKey, value: 'not a date');
      final service = buildService((_) async => http.Response(validBody(temperature: 30), 200));
      requestCount = 0;

      final result = await service.getWeatherForNablus();

      expect(result.getOrThrow().temperature, 30);
      expect(requestCount, 1);
      expect(
        StorageGateway.instance.integrityReporter.reports.map((report) => report.recordId),
        contains(lastUpdateKey),
      );
    });

    test('should ignore corrupt stored weather and fetch fresh data', () async {
      await StorageGateway.instance.save(key: weatherKey, value: <String, dynamic>{'temperature': 'hot'});
      await StorageGateway.instance.save(key: lastUpdateKey, value: fixedNow.toIso8601String());
      final service = buildService((_) async => http.Response(validBody(temperature: 25), 200));

      final result = await service.getWeatherForNablus();

      expect(result.getOrThrow().temperature, 25);
      expect(
        StorageGateway.instance.integrityReporter.reports.map((report) => report.recordId),
        contains(weatherKey),
      );
    });
  });
}
