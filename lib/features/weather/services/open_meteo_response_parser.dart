import 'dart:convert';

import '../../../core/errors/app_error.dart';
import '../../../core/json/json_reader.dart';
import '../../../data/models/weather/weather_model.dart';
import 'weather_condition_codes.dart';

class OpenMeteoResponseParser {
  static const String _source = 'OpenMeteoResponse';
  static const String _currentKey = 'current_weather';
  static const String _hourlyKey = 'hourly';
  static const String _currentTemperatureKey = 'temperature';
  static const String _currentWindSpeedKey = 'windspeed';
  static const String _currentWeatherCodeKey = 'weathercode';
  static const String _currentTimeKey = 'time';
  static const String _hourlyTimeKey = 'time';
  static const String _hourlyTemperatureKey = 'temperature_2m';
  static const String _hourlyHumidityKey = 'relative_humidity_2m';
  static const String _hourlyWeatherCodeKey = 'weathercode';
  static const String _hourlyWindSpeedKey = 'wind_speed_10m';
  static const int _maxHourlyEntries = 12;
  static const int _missingHumidity = 0;
  static const double _missingWindSpeed = 0;

  final String cityName;

  const OpenMeteoResponseParser({required this.cityName});

  WeatherModel parse(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map) {
      throw CorruptDataError('$_source: body is not a JSON object', source: _source);
    }
    final reader = JsonReader(_stringKeyed(decoded), source: _source);
    final current = reader.optionalMap(_currentKey);
    if (current == null) {
      throw CorruptDataError('$_source: missing "$_currentKey"', source: _source, field: _currentKey);
    }
    final hourly = reader.readMap(_hourlyKey);
    final currentReader = JsonReader(current, source: '$_source.$_currentKey');
    final temperature = currentReader.requireDouble(_currentTemperatureKey);
    final weatherCode = currentReader.optionalInt(_currentWeatherCodeKey);

    return WeatherModel(
      cityName: cityName,
      temperature: temperature,
      feelsLike: temperature,
      humidity: _intAt(_listAt(hourly, _hourlyHumidityKey), 0) ?? _missingHumidity,
      windSpeed: currentReader.readDouble(_currentWindSpeedKey, fallback: _missingWindSpeed),
      description: WeatherConditionCodes.describe(weatherCode),
      icon: WeatherConditionCodes.iconFor(weatherCode),
      timestamp: currentReader.requireDate(_currentTimeKey),
      hourlyForecast: _parseHourlyForecast(hourly),
    );
  }

  List<HourlyForecast> _parseHourlyForecast(Map<String, dynamic> hourly) {
    final times = _listAt(hourly, _hourlyTimeKey);
    final temperatures = _listAt(hourly, _hourlyTemperatureKey);
    final humidities = _listAt(hourly, _hourlyHumidityKey);
    final weatherCodes = _listAt(hourly, _hourlyWeatherCodeKey);
    final windSpeeds = _listAt(hourly, _hourlyWindSpeedKey);
    final forecasts = <HourlyForecast>[];
    for (var i = 0; i < times.length && forecasts.length < _maxHourlyEntries; i++) {
      final time = _dateAt(times, i);
      final temperature = _doubleAt(temperatures, i);
      if (time == null || temperature == null) {
        continue;
      }
      final weatherCode = _intAt(weatherCodes, i);
      forecasts.add(HourlyForecast(
        time: time,
        temperature: temperature,
        description: WeatherConditionCodes.describe(weatherCode),
        icon: WeatherConditionCodes.iconFor(weatherCode),
        humidity: _intAt(humidities, i) ?? _missingHumidity,
        windSpeed: _doubleAt(windSpeeds, i) ?? _missingWindSpeed,
      ));
    }
    return List<HourlyForecast>.unmodifiable(forecasts);
  }

  Map<String, dynamic> _stringKeyed(Map<dynamic, dynamic> map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }

  List<dynamic> _listAt(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is List ? value : const <dynamic>[];
  }

  Object? _valueAt(List<dynamic> values, int index) {
    return index < values.length ? values[index] : null;
  }

  DateTime? _dateAt(List<dynamic> values, int index) {
    final value = _valueAt(values, index);
    return value is String ? DateTime.tryParse(value) : null;
  }

  double? _doubleAt(List<dynamic> values, int index) {
    final value = _valueAt(values, index);
    return value is num ? value.toDouble() : null;
  }

  int? _intAt(List<dynamic> values, int index) {
    final value = _valueAt(values, index);
    return value is num ? value.toInt() : null;
  }
}
