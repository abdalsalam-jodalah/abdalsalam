import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../data/models/weather/weather_model.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';

class WeatherService {
    List<HourlyForecast> _parseHourlyForecast(Map<String, dynamic> hourly) {
      final times = (hourly['time'] as List).cast<String>();
      final temps = (hourly['temperature_2m'] as List).cast<num>();
      final hums = (hourly['relative_humidity_2m'] as List).cast<num>();
      final codes = (hourly['weathercode'] as List).cast<num>();
      final winds = (hourly['wind_speed_10m'] as List).cast<num>();
      final List<HourlyForecast> result = [];
      for (int i = 0; i < times.length && i < 12; i++) {
        result.add(HourlyForecast(
          time: DateTime.parse(times[i]),
          temperature: temps[i].toDouble(),
          description: _weatherCodeToDescription(codes[i]),
          icon: _weatherCodeToIcon(codes[i]),
          humidity: hums[i].toInt(),
          windSpeed: winds[i].toDouble(),
        ));
      }
      return result;
    }

    String _weatherCodeToDescription(num code) {
      // Basic mapping for demo; expand as needed
      switch (code.toInt()) {
        case 0:
          return 'Clear sky';
        case 1:
        case 2:
        case 3:
          return 'Partly cloudy';
        case 45:
        case 48:
          return 'Fog';
        case 51:
        case 53:
        case 55:
          return 'Drizzle';
        case 61:
        case 63:
        case 65:
          return 'Rain';
        case 71:
        case 73:
        case 75:
          return 'Snow';
        case 80:
        case 81:
        case 82:
          return 'Rain showers';
        case 95:
          return 'Thunderstorm';
        default:
          return 'Unknown';
      }
    }

    String _weatherCodeToIcon(num code) {
      // Basic mapping for demo; expand as needed
      switch (code.toInt()) {
        case 0:
          return '01d'; // clear
        case 1:
        case 2:
        case 3:
          return '02d'; // partly cloudy
        case 45:
        case 48:
          return '50d'; // fog
        case 51:
        case 53:
        case 55:
          return '09d'; // drizzle
        case 61:
        case 63:
        case 65:
          return '10d'; // rain
        case 71:
        case 73:
        case 75:
          return '13d'; // snow
        case 80:
        case 81:
        case 82:
          return '09d'; // rain showers
        case 95:
          return '11d'; // thunderstorm
        default:
          return '01d';
      }
    }
  final LoggerService _logger;
  final StorageGateway _storage;

  // Open-Meteo does not require an API key for free tier
  static const String _weatherKey = 'weather_data';
  static const String _lastUpdateKey = 'weather_last_update';
  static const Duration _cacheExpiry = Duration(hours: 1);

  WeatherModel? _cachedWeather;
  DateTime? _lastUpdate;

  WeatherService(this._logger, this._storage);

  /// Fetch weather for Nablus
  Future<WeatherModel?> getWeatherForNablus() async {
    // Check cache first
    if (_isCacheValid() && _cachedWeather != null) {
      _logger.info('Using cached weather data');
      return _cachedWeather;
    }

    try {
      _logger.info('Fetching weather data for Nablus (Open-Meteo)');
      // Nablus: 32.2211, 35.2544
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=32.2211&longitude=35.2544&current_weather=true&hourly=temperature_2m,relative_humidity_2m,weathercode,wind_speed_10m&timezone=auto',
      );
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.warning('Weather API timeout');
          return http.Response('{}', 408);
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final current = data['current_weather'] as Map<String, dynamic>?;
        final hourly = data['hourly'] as Map<String, dynamic>?;
        if (current == null || hourly == null) {
          _logger.warning('Open-Meteo: Missing current or hourly data');
          await _loadFromStorage();
          return _cachedWeather;
        }
        // Parse current weather
        final weather = WeatherModel(
          cityName: 'Nablus',
          temperature: (current['temperature'] as num).toDouble(),
          feelsLike: (current['temperature'] as num).toDouble(),
          humidity: (hourly['relative_humidity_2m'] as List).isNotEmpty ? (hourly['relative_humidity_2m'][0] as num).toInt() : 0,
          windSpeed: (current['windspeed'] as num).toDouble(),
          description: _weatherCodeToDescription(current['weathercode']),
          icon: _weatherCodeToIcon(current['weathercode']),
          timestamp: DateTime.parse(current['time'] as String),
          hourlyForecast: _parseHourlyForecast(hourly),
        );
        _cachedWeather = weather;
        _lastUpdate = DateTime.now();
        await _saveToStorage();
        _logger.info('Weather data updated for Nablus (Open-Meteo)');
        return _cachedWeather;
      } else {
        _logger.warning('Failed to fetch weather: ${response.statusCode}');
        await _loadFromStorage();
        return _cachedWeather;
      }
    } catch (e, st) {
      _logger.error('Error fetching weather', error: e, stackTrace: st);
      await _loadFromStorage();
      return _cachedWeather;
    }
  }

  bool _isCacheValid() {
    if (_lastUpdate == null) return false;
    final now = DateTime.now();
    return now.difference(_lastUpdate!) < _cacheExpiry;
  }

  Future<void> _saveToStorage() async {
    try {
      if (_cachedWeather != null) {
        await _storage.save(
          key: _weatherKey,
          value: _cachedWeather!.toJson(),
        );
        await _storage.save(
          key: _lastUpdateKey,
          value: _lastUpdate?.toIso8601String(),
        );
      }
    } catch (e, st) {
      _logger.error('Failed to save weather to storage', error: e, stackTrace: st);
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final weatherData = await _storage.get<Map<String, dynamic>>(_weatherKey);
      final lastUpdateStr = await _storage.get<String>(_lastUpdateKey);

      if (weatherData != null) {
        _cachedWeather = WeatherModel.fromJson(weatherData);
        _logger.info('Loaded cached weather from storage');
      }

      if (lastUpdateStr != null) {
        _lastUpdate = DateTime.parse(lastUpdateStr);
      }
    } catch (e, st) {
      _logger.error('Failed to load weather from storage', error: e, stackTrace: st);
    }
  }

  Future<void> initialize() async {
    await _loadFromStorage();
    if (!_isCacheValid()) {
      await getWeatherForNablus();
    }
  }

  Future<void> refresh() async {
    await getWeatherForNablus();
  }

  String getWeatherIconUrl(String icon) {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }
}

// Extension to add copyWith to WeatherModel
extension WeatherModelExtension on WeatherModel {
  WeatherModel copyWith({
    String? cityName,
    double? temperature,
    double? feelsLike,
    int? humidity,
    double? windSpeed,
    String? description,
    String? icon,
    DateTime? timestamp,
    List<HourlyForecast>? hourlyForecast,
  }) {
    return WeatherModel(
      cityName: cityName ?? this.cityName,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
    );
  }
}
