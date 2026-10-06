import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/exchange_rate_model.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/charts/chart_frame.dart';
import '../../../shared/widgets/charts/chart_palette.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../services/exchange_rate_series.dart';
import 'currency_rate_tile.dart';

class CurrencyRatesWidget extends StatefulWidget {
  static const IconData _usdIcon = Icons.attach_money_rounded;
  static const IconData _jodIcon = Icons.account_balance_rounded;
  static const String _sectionTitle = 'Exchange rates';
  static const String _historyTitle = 'Last 30 days · ILS per 1 unit';
  static const String _hint = 'Tap a currency to show or hide it on the chart';
  static const double _stackBreakpoint = 340;
  static const String _usd = 'USD';
  static const String _jod = 'JOD';

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
  State<CurrencyRatesWidget> createState() => _CurrencyRatesWidgetState();
}

class _CurrencyRatesWidgetState extends State<CurrencyRatesWidget> {
  final Set<String> _visibleCodes = <String>{CurrencyRatesWidget._usd, CurrencyRatesWidget._jod};

  void _toggle(String code) {
    setState(() {
      if (!_visibleCodes.remove(code)) {
        _visibleCodes.add(code);
      }
      if (_visibleCodes.isEmpty) {
        _visibleCodes.add(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final palette = ChartPalette.of(context);
    final usdColor = palette[0];
    final jodColor = palette[1];
    final usdSeries = ExchangeRateSeries.ilsPerUnitSeries(widget.usdHistory);
    final jodSeries = ExchangeRateSeries.ilsPerUnitSeries(widget.jodHistory);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: CurrencyRatesWidget._sectionTitle,
            padding: EdgeInsets.zero,
            action: widget.onRefresh == null
                ? null
                : IconButton(
                    tooltip: 'Refresh rates',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: widget.onRefresh,
                  ),
          ),
          SizedBox(height: tokens.spacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                CurrencyRateTile(
                  code: CurrencyRatesWidget._usd,
                  icon: CurrencyRatesWidget._usdIcon,
                  accentColor: usdColor,
                  unitsPerIls: widget.currentRates[CurrencyRatesWidget._usd] ?? 0,
                  changePercent: ExchangeRateSeries.changePercent(usdSeries),
                  isSelected: _visibleCodes.contains(CurrencyRatesWidget._usd),
                  onTap: () => _toggle(CurrencyRatesWidget._usd),
                ),
                CurrencyRateTile(
                  code: CurrencyRatesWidget._jod,
                  icon: CurrencyRatesWidget._jodIcon,
                  accentColor: jodColor,
                  unitsPerIls: widget.currentRates[CurrencyRatesWidget._jod] ?? 0,
                  changePercent: ExchangeRateSeries.changePercent(jodSeries),
                  isSelected: _visibleCodes.contains(CurrencyRatesWidget._jod),
                  onTap: () => _toggle(CurrencyRatesWidget._jod),
                ),
              ];
              if (constraints.maxWidth < CurrencyRatesWidget._stackBreakpoint) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [tiles[0], SizedBox(height: tokens.spacing.md), tiles[1]],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: tiles[0]),
                  SizedBox(width: tokens.spacing.md),
                  Expanded(child: tiles[1]),
                ],
              );
            },
          ),
          if (usdSeries.isNotEmpty || jodSeries.isNotEmpty) ...[
            SizedBox(height: tokens.spacing.lg),
            Text(CurrencyRatesWidget._historyTitle, style: Theme.of(context).textTheme.labelLarge),
            SizedBox(height: tokens.spacing.xs),
            Text(
              CurrencyRatesWidget._hint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: tokens.spacing.sm),
            _buildChart(usdSeries, jodSeries, usdColor, jodColor),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(List<double> usdSeries, List<double> jodSeries, Color usdColor, Color jodColor) {
    final showUsd = _visibleCodes.contains(CurrencyRatesWidget._usd) && usdSeries.isNotEmpty;
    final showJod = _visibleCodes.contains(CurrencyRatesWidget._jod) && jodSeries.isNotEmpty;
    final series = <AppChartSeries>[
      if (showUsd) AppChartSeries(points: usdSeries, color: usdColor),
      if (showJod) AppChartSeries(points: jodSeries, color: jodColor),
    ];
    if (series.isEmpty) {
      return const SizedBox(height: ChartFrame.defaultHeight);
    }
    final labelSource = widget.usdHistory.isNotEmpty ? widget.usdHistory : widget.jodHistory;
    final labels = [for (final entry in labelSource) AppDateFormatter.shortDate(entry.date)];
    return AppLineChart(
      key: ValueKey('rates-chart-${_visibleCodes.toList()..sort()}'),
      height: ChartFrame.defaultHeight,
      points: series.first.points,
      color: series.first.color,
      extraSeries: series.skip(1).toList(growable: false),
      axisLabels: labels,
      yAxisLabelBuilder: (value) => value.toStringAsFixed(2),
    );
  }
}
