import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../data/models/financial/exchange_rate_model.dart';

class CurrencyRatesWidget extends StatelessWidget {
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.currency_exchange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Exchange Rates',
                      style: TextStyle(
                        fontSize: 18,
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

            const SizedBox(height: 16),

            // Current Rates
            Row(
              children: [
                Expanded(
                  child: _buildRateCard(
                    'USD',
                    '\$',
                    currentRates['USD'] ?? 0.0,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRateCard(
                    'JOD',
                    'JD',
                    currentRates['JOD'] ?? 0.0,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Chart
            if (usdHistory.isNotEmpty || jodHistory.isNotEmpty) ...[
              const Text(
                'Last 30 Days',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: _buildChart(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRateCard(String currency, String symbol, double rate, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                symbol,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currency,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1 ILS = ${rate.toStringAsFixed(4)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '1 $currency = ${(1 / rate).toStringAsFixed(2)} ILS',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (usdHistory.isEmpty && jodHistory.isEmpty) {
      return const Center(child: Text('No historical data'));
    }

    final usdSpots = usdHistory
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.rate))
        .toList();

    final jodSpots = jodHistory
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.rate))
        .toList();

    final allRates = [
      ...usdHistory.map((r) => r.rate),
      ...jodHistory.map((r) => r.rate),
    ];

    final minY = allRates.isEmpty ? 0.0 : allRates.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = allRates.isEmpty ? 1.0 : allRates.reduce((a, b) => a > b ? a : b) * 1.05;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= usdHistory.length) return const Text('');
                final date = usdHistory[value.toInt()].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toStringAsFixed(3),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          if (usdSpots.isNotEmpty)
            LineChartBarData(
              spots: usdSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withValues(alpha: 0.1),
              ),
            ),
          if (jodSpots.isNotEmpty)
            LineChartBarData(
              spots: jodSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
        ],
      ),
    );
  }
}
