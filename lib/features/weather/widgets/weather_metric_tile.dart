import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class WeatherMetricTile extends StatelessWidget {
  static const double _tileOpacity = 0.14;
  static const double _barHeight = 4;

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final double? progress;

  const WeatherMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _tileOpacity),
        borderRadius: tokens.radius.mediumBorder,
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.white70),
                SizedBox(width: tokens.spacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            if (progress != null) ...[
              SizedBox(height: tokens.spacing.xs),
              ClipRRect(
                borderRadius: tokens.radius.pillBorder,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: _barHeight,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
            if (caption != null)
              Text(caption!, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
