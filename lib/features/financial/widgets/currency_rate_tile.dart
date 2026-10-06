import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/icon_badge.dart';
import '../services/exchange_rate_series.dart';

class CurrencyRateTile extends StatelessWidget {
  static const int _ilsDigits = 3;
  static const int _unitDigits = 4;
  static const String _missingValue = '—';
  static const double _selectedBorderWidth = 2;
  static const double _tintOpacity = 0.1;
  static const double _badgeSize = 32;

  final String code;
  final IconData icon;
  final Color accentColor;
  final double unitsPerIls;
  final double? changePercent;
  final bool isSelected;
  final VoidCallback onTap;

  const CurrencyRateTile({
    super.key,
    required this.code,
    required this.icon,
    required this.accentColor,
    required this.unitsPerIls,
    required this.changePercent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final ilsPerUnit = ExchangeRateSeries.ilsPerUnit(unitsPerIls);
    final headline = ilsPerUnit == null ? '1 $code = $_missingValue' : '1 $code = ${ilsPerUnit.toStringAsFixed(_ilsDigits)} ILS';
    final inverse = ilsPerUnit == null ? '1 ILS = $_missingValue' : '1 ILS = ${unitsPerIls.toStringAsFixed(_unitDigits)} $code';

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$code rate, tap to ${isSelected ? 'hide from' : 'show on'} chart',
      child: InkWell(
        borderRadius: tokens.radius.largeBorder,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(tokens.spacing.md),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isSelected ? _tintOpacity : 0),
            borderRadius: tokens.radius.largeBorder,
            border: Border.all(
              color: isSelected ? accentColor : theme.colorScheme.outlineVariant,
              width: isSelected ? _selectedBorderWidth : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(icon: icon, color: accentColor, size: _badgeSize),
                  SizedBox(width: tokens.spacing.sm),
                  Text(code, style: theme.textTheme.titleMedium?.copyWith(color: accentColor, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (changePercent != null) _TrendChip(percent: changePercent!),
                ],
              ),
              SizedBox(height: tokens.spacing.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  headline,
                  key: ValueKey('rate-headline-$code'),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: tokens.spacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  inverse,
                  key: ValueKey('rate-inverse-$code'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  static const double _tolerance = 0.005;

  final double percent;

  const _TrendChip({required this.percent});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final isFlat = percent.abs() < _tolerance;
    final icon = isFlat ? Icons.trending_flat_rounded : (percent > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded);
    return Tooltip(
      message: 'Change over the last 30 days',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: tokens.radius.pillBorder,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 2),
              Text(
                '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%',
                key: const ValueKey('rate-trend'),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
