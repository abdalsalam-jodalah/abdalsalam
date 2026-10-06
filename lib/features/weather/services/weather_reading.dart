import '../../../data/models/weather/weather_model.dart';
import 'weather_condition.dart';

class WeatherReading {
  final DateTime? time;
  final double temperature;
  final double? feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final WeatherCondition condition;
  final bool isNight;

  const WeatherReading({
    required this.time,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.condition,
    required this.isNight,
  });

  factory WeatherReading.current(WeatherModel weather) => WeatherReading(
    time: null,
    temperature: weather.temperature,
    feelsLike: weather.feelsLike,
    humidity: weather.humidity,
    windSpeed: weather.windSpeed,
    description: weather.description,
    condition: WeatherCondition.fromIcon(weather.icon),
    isNight: WeatherCondition.isNightIcon(weather.icon),
  );

  factory WeatherReading.forecast(HourlyForecast forecast) => WeatherReading(
    time: forecast.time,
    temperature: forecast.temperature,
    feelsLike: null,
    humidity: forecast.humidity,
    windSpeed: forecast.windSpeed,
    description: forecast.description,
    condition: WeatherCondition.fromIcon(forecast.icon),
    isNight: WeatherCondition.isNightIcon(forecast.icon),
  );
}
