import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/weather/weather_model.dart';
import '../../../shared/widgets/ui/app_card.dart';

class WeatherWidget extends StatelessWidget {
  static const String _staleHint = 'Offline — showing saved weather';
  static const double _conditionIconSize = 96;
  static const double _conditionIconFallbackSize = 56;
  static const double _hourlyIconSize = 32;
  static const double _hourlyIconFallbackSize = 24;
  static const double _hourlyTileWidth = 80;
  static const double _hourlyRowHeight = 118;

  final WeatherModel weather;
  final VoidCallback? onRefresh;

  const WeatherWidget({
    super.key,
    required this.weather,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return AppCard(
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: accentColor),
                  SizedBox(width: tokens.spacing.xs),
                  Text(weather.cityName, style: theme.textTheme.titleMedium),
                ],
              ),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                ),
            ],
          ),
          if (weather.isStale) ...[
            SizedBox(height: tokens.spacing.xs),
            Row(
              children: [
                Icon(Icons.cloud_off, size: theme.textTheme.bodySmall?.fontSize, color: theme.colorScheme.onSurfaceVariant),
                SizedBox(width: tokens.spacing.xs),
                Text(
                  _staleHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
          SizedBox(height: tokens.spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.toStringAsFixed(1)}°C',
                      style: theme.textTheme.displaySmall?.copyWith(color: accentColor, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      weather.description.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: tokens.spacing.sm),
                    Text(
                      'Feels like ${weather.feelsLike.toStringAsFixed(1)}°C',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _ConditionIcon(iconCode: weather.icon, accentColor: accentColor),
            ],
          ),
          SizedBox(height: tokens.spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherDetail(
                icon: Icons.water_drop,
                label: 'Humidity',
                value: '${weather.humidity}%',
                accentColor: tokens.colors.info,
              ),
              _WeatherDetail(
                icon: Icons.air,
                label: 'Wind',
                value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
                accentColor: tokens.colors.info,
              ),
            ],
          ),
          if (weather.hourlyForecast.isNotEmpty) ...[
            SizedBox(height: tokens.spacing.lg),
            const Divider(),
            SizedBox(height: tokens.spacing.sm),
            Text('Hourly Forecast', style: theme.textTheme.titleSmall),
            SizedBox(height: tokens.spacing.sm),
            SizedBox(
              height: _hourlyRowHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final forecast in weather.hourlyForecast)
                      Padding(
                        padding: EdgeInsets.only(right: tokens.spacing.sm),
                        child: _HourlyForecastTile(forecast: forecast, accentColor: accentColor),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConditionIcon extends StatelessWidget {
  final String iconCode;
  final Color accentColor;

  const _ConditionIcon({required this.iconCode, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://openweathermap.org/img/wn/$iconCode@4x.png',
      width: WeatherWidget._conditionIconSize,
      height: WeatherWidget._conditionIconSize,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.wb_sunny, size: WeatherWidget._conditionIconFallbackSize, color: accentColor);
      },
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _WeatherDetail({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: accentColor),
        SizedBox(height: tokens.spacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

class _HourlyForecastTile extends StatelessWidget {
  final HourlyForecast forecast;
  final Color accentColor;

  const _HourlyForecastTile({required this.forecast, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      width: WeatherWidget._hourlyTileWidth,
      child: AppCard(
        padding: EdgeInsets.all(tokens.spacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppDateFormatter.time(forecast.time), style: theme.textTheme.labelSmall),
            SizedBox(height: tokens.spacing.xs),
            Image.network(
              'https://openweathermap.org/img/wn/${forecast.icon}.png',
              width: WeatherWidget._hourlyIconSize,
              height: WeatherWidget._hourlyIconSize,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.wb_sunny, size: WeatherWidget._hourlyIconFallbackSize, color: accentColor);
              },
            ),
            SizedBox(height: tokens.spacing.xs),
            Text('${forecast.temperature.toStringAsFixed(0)}°', style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
