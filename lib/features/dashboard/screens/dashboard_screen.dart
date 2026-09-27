import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../../financial/widgets/currency_rates_widget.dart';
import '../../weather/widgets/weather_widget.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_agenda_card.dart';
import '../../../core/constants/dashboard_card_catalog.dart';
import '../widgets/dashboard_goals_section.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/dashboard_status_chips.dart';
import '../widgets/dashboard_storage_warning.dart';
import '../widgets/dashboard_today_stats.dart';

class DashboardScreen extends ConsumerWidget {
  static const double _fabClearance = 96;

  const DashboardScreen({super.key});

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(weatherProvider);
    ref.invalidate(currencyRatesProvider);
    ref.invalidate(usdHistoryProvider);
    ref.invalidate(jodHistoryProvider);
  }

  Widget _buildCard(String card, WidgetRef ref) {
    switch (card) {
      case DashboardCardCatalog.today:
        return const DashboardTodayStats();
      case DashboardCardCatalog.weather:
        return AsyncSection(
          value: ref.watch(weatherProvider),
          onRetry: () => ref.invalidate(weatherProvider),
          builder: (weather) => weather == null
              ? const SizedBox.shrink()
              : WeatherWidget(weather: weather, onRefresh: () => ref.invalidate(weatherProvider)),
        );
      case DashboardCardCatalog.currency:
        return AsyncSection<Map<String, double>>(
          value: ref.watch(currencyRatesProvider),
          onRetry: () => _refreshAll(ref),
          builder: (rates) => CurrencyRatesWidget(
            currentRates: rates,
            usdHistory: ref.watch(usdHistoryProvider).maybeWhen(data: (history) => history, orElse: () => []),
            jodHistory: ref.watch(jodHistoryProvider).maybeWhen(data: (history) => history, orElse: () => []),
            onRefresh: () => _refreshAll(ref),
          ),
        );
      case DashboardCardCatalog.goals:
        return const DashboardGoalsSection();
      case DashboardCardCatalog.agenda:
        return const DashboardAgendaCard();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final isOffline = ref.watch(isOfflineProvider);
    final settings = ref.watch(appSettingsProvider).maybeWhen(data: (values) => values, orElse: () => const <String, dynamic>{});
    final order = DashboardCardCatalog.resolveOrder(settings[DashboardCardCatalog.cardOrderSetting]);
    final hidden = DashboardCardCatalog.resolveHidden(settings[DashboardCardCatalog.hiddenCardsSetting]);
    final now = DateTime.now();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(ref),
        child: ListView(
          padding: const EdgeInsets.only(bottom: _fabClearance),
          children: [
            PageHeader(
              title: DashboardGreeting.forTime(now),
              subtitle: AppDateFormatter.date(now),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DashboardStatusChips(),
                  SizedBox(height: tokens.spacing.md),
                  if (isOffline) ...[OfflineBanner(isOffline: isOffline), SizedBox(height: tokens.spacing.md)],
                  const DashboardStorageWarning(),
                  for (final card in order)
                    if (!hidden.contains(card))
                      Padding(
                        padding: EdgeInsets.only(bottom: tokens.spacing.md),
                        child: _buildCard(card, ref),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
