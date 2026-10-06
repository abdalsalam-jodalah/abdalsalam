import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/weather/weather_model.dart';
import '../services/weather_advice.dart';
import '../services/weather_reading.dart';
import 'weather_backdrop.dart';
import 'weather_hour_strip.dart';
import 'weather_look.dart';
import 'weather_metric_tile.dart';

class WeatherWidget extends StatefulWidget {
  static const String _staleHint = 'Offline — showing saved weather';
  static const String _nowLabel = 'Now';
  static const double _heroIconSize = 84;
  static const double _percentScale = 100;
  static const Duration _lookDuration = Duration(milliseconds: 600);
  static const Duration _expandDuration = Duration(milliseconds: 250);

  final WeatherModel weather;
  final VoidCallback? onRefresh;
  final bool initiallyExpanded;

  const WeatherWidget({super.key, required this.weather, this.onRefresh, this.initiallyExpanded = false});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  late bool _isExpanded = widget.initiallyExpanded;
  int? _selectedHour;

  WeatherReading get _reading {
    final index = _selectedHour;
    final forecasts = widget.weather.hourlyForecast;
    if (index == null || index >= forecasts.length) {
      return WeatherReading.current(widget.weather);
    }
    return WeatherReading.forecast(forecasts[index]);
  }

  @override
  void didUpdateWidget(WeatherWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weather.hourlyForecast.length != widget.weather.hourlyForecast.length) {
      _selectedHour = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final reading = _reading;
    final look = WeatherLook.of(reading.condition, isNight: reading.isNight);
    final isAnimated = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

    return ClipRRect(
      borderRadius: tokens.radius.extraLargeBorder,
      child: AnimatedContainer(
        duration: isAnimated ? WeatherWidget._lookDuration : Duration.zero,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: look.gradient),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: WeatherBackdrop(condition: reading.condition, isNight: reading.isNight, isAnimated: isAnimated),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopRow(context),
                  SizedBox(height: tokens.spacing.md),
                  _buildHero(context, reading, look, isAnimated),
                  SizedBox(height: tokens.spacing.md),
                  _AdvicePill(
                    text: WeatherAdvice.forConditions(
                      condition: reading.condition,
                      temperature: reading.temperature,
                      isNight: reading.isNight,
                    ),
                  ),
                  _buildExpandable(context, reading, isAnimated),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      key: const ValueKey('weather-toggle-details'),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                      icon: Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                      label: Text(_isExpanded ? 'Hide details' : 'Hourly & details', style: textTheme.labelLarge),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.xs,
            children: [
              _Pill(icon: Icons.location_on_rounded, text: widget.weather.cityName),
              if (widget.weather.isStale) const _Pill(icon: Icons.cloud_off_rounded, text: WeatherWidget._staleHint),
            ],
          ),
        ),
        if (widget.onRefresh != null)
          IconButton(
            tooltip: 'Refresh weather',
            visualDensity: VisualDensity.compact,
            color: Colors.white,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: widget.onRefresh,
          ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, WeatherReading reading, WeatherLook look, bool isAnimated) {
    final tokens = AppThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final time = reading.time;
    return InkWell(
      key: const ValueKey('weather-hero'),
      borderRadius: tokens.radius.mediumBorder,
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time == null ? WeatherWidget._nowLabel : 'At ${AppDateFormatter.time(time)}',
                  style: textTheme.labelLarge?.copyWith(color: Colors.white70),
                ),
                Text(
                  '${reading.temperature.round()}°C',
                  key: const ValueKey('weather-temperature'),
                  style: textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1.05),
                ),
                Text(
                  reading.description,
                  style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                if (reading.feelsLike != null)
                  Text(
                    'Feels like ${reading.feelsLike!.round()}°C',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: isAnimated ? WeatherWidget._lookDuration : Duration.zero,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              look.icon,
              key: ValueKey('${reading.condition.name}-${reading.isNight}'),
              size: WeatherWidget._heroIconSize,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandable(BuildContext context, WeatherReading reading, bool isAnimated) {
    final details = _isExpanded ? _buildDetails(context, reading) : const SizedBox(width: double.infinity);
    if (!isAnimated) return details;
    return AnimatedSize(duration: WeatherWidget._expandDuration, alignment: Alignment.topCenter, child: details);
  }

  Widget _buildDetails(BuildContext context, WeatherReading reading) {
    final tokens = AppThemeTokens.of(context);
    final time = reading.time;
    final forecasts = widget.weather.hourlyForecast;
    return Padding(
      padding: EdgeInsets.only(top: tokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: WeatherMetricTile(
                  icon: Icons.water_drop_rounded,
                  label: 'Humidity',
                  value: '${reading.humidity}%',
                  progress: reading.humidity / WeatherWidget._percentScale,
                ),
              ),
              SizedBox(width: tokens.spacing.sm),
              Expanded(
                child: WeatherMetricTile(
                  icon: Icons.air_rounded,
                  label: 'Wind',
                  value: '${reading.windSpeed.toStringAsFixed(1)} m/s',
                  caption: WeatherAdvice.windLabel(reading.windSpeed),
                ),
              ),
              SizedBox(width: tokens.spacing.sm),
              Expanded(
                child: reading.feelsLike != null
                    ? WeatherMetricTile(
                        icon: Icons.thermostat_rounded,
                        label: 'Feels like',
                        value: '${reading.feelsLike!.round()}°C',
                      )
                    : WeatherMetricTile(
                        icon: Icons.schedule_rounded,
                        label: 'Hour',
                        value: time == null ? '' : AppDateFormatter.time(time),
                      ),
              ),
            ],
          ),
          if (forecasts.isNotEmpty) ...[
            SizedBox(height: tokens.spacing.md),
            WeatherHourStrip(
              forecasts: forecasts,
              selectedIndex: _selectedHour,
              onSelected: (index) => setState(() => _selectedHour = index),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  static const double _opacity = 0.2;

  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _opacity),
        borderRadius: tokens.radius.pillBorder,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md, vertical: tokens.spacing.xs + 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            SizedBox(width: tokens.spacing.xs),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvicePill extends StatelessWidget {
  final String text;

  const _AdvicePill({required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: tokens.radius.mediumBorder),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md, vertical: tokens.spacing.sm),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Colors.white),
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: Text(
                text,
                key: const ValueKey('weather-advice'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
