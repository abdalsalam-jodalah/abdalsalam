import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../planning/providers/planning_providers.dart';
import '../../religious/providers/prayer_providers.dart';
import '../../religious/providers/quran_providers.dart';
import '../../weather/widgets/weather_widget.dart';
import '../../financial/widgets/currency_rates_widget.dart';
import '../providers/dashboard_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/offline_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerCount = ref.watch(prayerCountProvider);
    final quranPages = ref.watch(quranPagesTodayProvider);
    final todaysGoalsAsync = ref.watch(todaysGoalsProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final batteryInfo = ref.watch(batteryInfoProvider);
    final storageInfo = ref.watch(storageInfoProvider);
    final stateAware = ref.watch(stateAwareServiceProvider);
    
    // Weather and Currency data
    final weatherAsync = ref.watch(weatherProvider);
    final currencyRatesAsync = ref.watch(currencyRatesProvider);
    final usdHistoryAsync = ref.watch(usdHistoryProvider);
    final jodHistoryAsync = ref.watch(jodHistoryProvider);
    
    final lowStorage = storageInfo.maybeWhen(
      data: (info) => info.usagePercentage >= 90,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abdalsalam Dashboard'),
        actions: [
          Icon(
            isOffline ? Icons.cloud_off : Icons.cloud_done,
            color: isOffline ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          batteryInfo.maybeWhen(
            data: (battery) {
              final level = battery.batteryLevel ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    '$level%',
                    style: TextStyle(
                      color: level < 20 ? Colors.red : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 400)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OfflineBanner(isOffline: isOffline),
            if (isOffline) const SizedBox(height: 12),
            if (lowStorage) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stateAware.storageWarningMessage() ?? 'Storage is running low.',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      ...stateAware.cleanupSuggestions().map((tip) => Text('• $tip')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Weather Widget
            weatherAsync.when(
              data: (weather) {
                if (weather == null) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    WeatherWidget(
                      weather: weather,
                      onRefresh: () {
                        ref.invalidate(weatherProvider);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
              loading: () {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              },
              error: (error, stack) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Weather unavailable',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Currency Rates Widget
            currencyRatesAsync.when(
              data: (rates) {
                return Column(
                  children: [
                    CurrencyRatesWidget(
                      currentRates: rates,
                      usdHistory: usdHistoryAsync.maybeWhen(
                        data: (history) => history,
                        orElse: () => [],
                      ),
                      jodHistory: jodHistoryAsync.maybeWhen(
                        data: (history) => history,
                        orElse: () => [],
                      ),
                      onRefresh: () {
                        ref.invalidate(currencyRatesProvider);
                        ref.invalidate(usdHistoryProvider);
                        ref.invalidate(jodHistoryProvider);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Exchange rates unavailable',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: const Text('Religious Tracking status'),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$prayerCount / 5 prayers',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '$quranPages pages today',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Today\'s Agenda', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text('• Prayer: Maghrib in 40 min'),
                    Text('• Medication: Vitamin D at 20:00'),
                    Text('• Workout: Push session at 19:00'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today\'s Goals', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    todaysGoalsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => const Text('Failed to load goals'),
                      data: (goals) {
                        if (goals.isEmpty) {
                          return const Text('No goals set for today.');
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: goals.map((goal) => Text('• ${goal.title}')).toList(growable: false),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Use the left sidebar to jump between pages.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
