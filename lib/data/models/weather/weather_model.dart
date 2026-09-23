import 'package:equatable/equatable.dart';

import '../../../core/json/json_reader.dart';

class WeatherModel extends Equatable {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final DateTime timestamp;
  final List<HourlyForecast> hourlyForecast;
  final bool isStale;

  const WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.timestamp,
    this.hourlyForecast = const [],
    this.isStale = false,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'WeatherModel');
    final temperature = reader.requireDouble('temperature');
    return WeatherModel(
      cityName: reader.readString('cityName'),
      temperature: temperature,
      feelsLike: reader.readDouble('feelsLike', fallback: temperature),
      humidity: reader.readInt('humidity'),
      windSpeed: reader.readDouble('windSpeed'),
      description: reader.readString('description'),
      icon: reader.readString('icon'),
      timestamp: reader.requireDate('timestamp'),
      hourlyForecast: reader.readObjectList('hourlyForecast', HourlyForecast.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'cityName': cityName,
        'temperature': temperature,
        'feelsLike': feelsLike,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'description': description,
        'icon': icon,
        'timestamp': timestamp.toIso8601String(),
        'hourlyForecast': hourlyForecast.map((forecast) => forecast.toJson()).toList(growable: false),
      };

  @override
  List<Object?> get props => [
        cityName,
        temperature,
        feelsLike,
        humidity,
        windSpeed,
        description,
        icon,
        timestamp,
        hourlyForecast,
        isStale,
      ];
}

class HourlyForecast extends Equatable {
  final DateTime time;
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'HourlyForecast');
    return HourlyForecast(
      time: reader.requireDate('time'),
      temperature: reader.requireDouble('temperature'),
      description: reader.readString('description'),
      icon: reader.readString('icon'),
      humidity: reader.readInt('humidity'),
      windSpeed: reader.readDouble('windSpeed'),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temperature': temperature,
        'description': description,
        'icon': icon,
        'humidity': humidity,
        'windSpeed': windSpeed,
      };

  @override
  List<Object?> get props => [
        time,
        temperature,
        description,
        icon,
        humidity,
        windSpeed,
      ];
}
