import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/weather/weather_model.dart';

class WeatherWidget extends StatelessWidget {
  static const String _staleHint = 'Offline — showing saved weather';

  final WeatherModel weather;
  final VoidCallback? onRefresh;

  const WeatherWidget({
    super.key,
    required this.weather,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      weather.cityName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                  ),
              ],
            ),
          ),

          if (weather.isStale)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _staleHint,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Current Weather
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Temperature
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weather.description.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Feels like ${weather.feelsLike.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Weather Icon
                Image.network(
                  'https://openweathermap.org/img/wn/${weather.icon}@4x.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.wb_sunny, size: 80);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Weather Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  Icons.water_drop,
                  'Humidity',
                  '${weather.humidity}%',
                ),
                _buildDetailItem(
                  Icons.air,
                  'Wind',
                  '${weather.windSpeed.toStringAsFixed(1)} m/s',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Hourly Forecast
          if (weather.hourlyForecast.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hourly Forecast',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: weather.hourlyForecast.length,
                      itemBuilder: (context, index) {
                        final forecast = weather.hourlyForecast[index];
                        return _buildHourlyItem(forecast);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyItem(HourlyForecast forecast) {
    final timeFormat = DateFormat('HH:mm');

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeFormat.format(forecast.time),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Image.network(
            'https://openweathermap.org/img/wn/${forecast.icon}.png',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.wb_sunny, size: 30);
            },
          ),
          const SizedBox(height: 4),
          Text(
            '${forecast.temperature.toStringAsFixed(0)}°',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
