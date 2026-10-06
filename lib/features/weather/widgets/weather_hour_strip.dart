import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/weather/weather_model.dart';
import '../services/weather_condition.dart';
import 'weather_look.dart';

class WeatherHourStrip extends StatelessWidget {
  static const double _height = 92;
  static const double _chipWidth = 68;
  static const double _selectedOpacity = 0.28;
  static const double _idleOpacity = 0.12;
  static const String _nowLabel = 'Now';

  final List<HourlyForecast> forecasts;
  final int? selectedIndex;
  final ValueChanged<int?> onSelected;

  const WeatherHourStrip({super.key, required this.forecasts, required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: forecasts.length + 1,
        separatorBuilder: (context, index) => SizedBox(width: spacing.sm),
        itemBuilder: (context, position) {
          if (position == 0) {
            return _HourChip(
              key: const ValueKey('weather-hour-now'),
              label: _nowLabel,
              icon: Icons.my_location_rounded,
              temperature: null,
              isSelected: selectedIndex == null,
              onTap: () => onSelected(null),
            );
          }
          final index = position - 1;
          final forecast = forecasts[index];
          final isNight = WeatherCondition.isNightIcon(forecast.icon);
          return _HourChip(
            key: ValueKey('weather-hour-$index'),
            label: AppDateFormatter.time(forecast.time),
            icon: WeatherLook.of(WeatherCondition.fromIcon(forecast.icon), isNight: isNight).icon,
            temperature: forecast.temperature,
            isSelected: selectedIndex == index,
            onTap: () => onSelected(selectedIndex == index ? null : index),
          );
        },
      ),
    );
  }
}

class _HourChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final double? temperature;
  final bool isSelected;
  final VoidCallback onTap;

  const _HourChip({
    super.key,
    required this.label,
    required this.icon,
    required this.temperature,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        borderRadius: tokens.radius.mediumBorder,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: WeatherHourStrip._chipWidth,
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: isSelected ? WeatherHourStrip._selectedOpacity : WeatherHourStrip._idleOpacity,
            ),
            borderRadius: tokens.radius.mediumBorder,
            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: textTheme.labelSmall?.copyWith(color: Colors.white70), maxLines: 1),
              Icon(icon, color: Colors.white, size: 22),
              Text(
                temperature == null ? '' : '${temperature!.round()}°',
                style: textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
