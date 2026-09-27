import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/exchange_rate_model.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/charts/chart_frame.dart';
import '../../../shared/widgets/charts/chart_palette.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/icon_badge.dart';

class CurrencyRatesWidget extends StatelessWidget {
  static const IconData _usdIcon = Icons.attach_money_rounded;
  static const IconData _jodIcon = Icons.account_balance_rounded;
  static const String _sectionTitle = 'Exchange Rates';
  static const String _historyTitle = 'Last 30 Days';
  static const int _rateDecimalDigits = 4;
  static const int _inverseRateDecimalDigits = 2;

  final Map<String, double> currentRates;
  final List<ExchangeRateModel> usdHistory;
  final List<ExchangeRateModel> jodHistory;
  final VoidCallback? onRefresh;

  const CurrencyRatesWidget({
    super.key,
    required this.currentRates,
    this.usdHistory = const [],
    this.jodHistory = const [],
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final palette = ChartPalette.of(context);
    final usdColor = palette[0];
    final jodColor = palette[1];
    final hasHistory = usdHistory.isNotEmpty || jodHistory.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: _sectionTitle,
            padding: EdgeInsets.zero,
            action: onRefresh == null
                ? null
                : IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: onRefresh),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _RateInfo(
                  icon: _usdIcon,
                  code: 'USD',
                  rate: currentRates['USD'] ?? 0.0,
                  accentColor: usdColor,
                ),
              ),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: _RateInfo(
                  icon: _jodIcon,
                  code: 'JOD',
                  rate: currentRates['JOD'] ?? 0.0,
                  accentColor: jodColor,
                ),
              ),
            ],
          ),
          if (hasHistory) ...[
            SizedBox(height: tokens.spacing.lg),
            Text(_historyTitle, style: Theme.of(context).textTheme.labelLarge),
            SizedBox(height: tokens.spacing.sm),
            _buildChart(context, usdColor, jodColor),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, Color usdColor, Color jodColor) {
    final labelSource = usdHistory.isNotEmpty ? usdHistory : jodHistory;
    final labels = [for (final entry in labelSource) AppDateFormatter.shortDate(entry.date)];
    return AppLineChart(
      height: ChartFrame.defaultHeight,
      points: [for (final entry in usdHistory) entry.rate],
      color: usdColor,
      extraSeries: [
        if (jodHistory.isNotEmpty) AppChartSeries(points: [for (final entry in jodHistory) entry.rate], color: jodColor),
      ],
      axisLabels: labels,
      yAxisLabelBuilder: (value) => value.toStringAsFixed(3),
    );
  }
}

class _RateInfo extends StatelessWidget {
  final IconData icon;
  final String code;
  final double rate;
  final Color accentColor;

  const _RateInfo({required this.icon, required this.code, required this.rate, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconBadge(icon: icon, color: accentColor, size: IconBadge.defaultSize),
            SizedBox(width: tokens.spacing.sm),
            Text(code, style: theme.textTheme.titleMedium?.copyWith(color: accentColor)),
          ],
        ),
        SizedBox(height: tokens.spacing.sm),
        Text(
          '1 ILS = ${rate.toStringAsFixed(CurrencyRatesWidget._rateDecimalDigits)}',
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '1 $code = ${(1 / rate).toStringAsFixed(CurrencyRatesWidget._inverseRateDecimalDigits)} ILS',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
