import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dashboard_card_catalog.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../financial/widgets/currency_rates_widget.dart';
import '../../weather/widgets/weather_widget.dart';
import '../providers/dashboard_providers.dart';
import '../services/dashboard_column_planner.dart';
import '../widgets/dashboard_age_card.dart';
import '../widgets/dashboard_agenda_card.dart';
import '../widgets/dashboard_goals_section.dart';
import '../widgets/dashboard_hero.dart';
import '../widgets/dashboard_quote_card.dart';
import '../widgets/dashboard_storage_warning.dart';
import '../widgets/dashboard_today_stats.dart';

class DashboardScreen extends ConsumerWidget {
  static const double _fabClearance = 96;
  static const double _maxContentWidth = 1440;

  const DashboardScreen({super.key});

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(weatherProvider);
    ref.invalidate(currencyRatesProvider);
    ref.invalidate(usdHistoryProvider);
    ref.invalidate(jodHistoryProvider);
  }

  Widget _buildCard(String card, WidgetRef ref, {required bool isWide}) {
    switch (card) {
      case DashboardCardCatalog.today:
        return const DashboardTodayStats();
      case DashboardCardCatalog.weather:
        return AsyncSection(
          value: ref.watch(weatherProvider),
          onRetry: () => ref.invalidate(weatherProvider),
          builder: (weather) => weather == null
              ? const SizedBox.shrink()
              : WeatherWidget(
                  weather: weather,
                  initiallyExpanded: isWide,
                  onRefresh: () => ref.invalidate(weatherProvider),
                ),
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
      case DashboardCardCatalog.age:
        return const DashboardAgeCard();
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
    final visibleCards = [for (final card in order) if (!hidden.contains(card)) card];
    final now = DateTime.now();
    final showQuote = settings[DashboardCardCatalog.showQuoteSetting] != false;
    final prefersArabic = settings['language'] == 'ar';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(ref),
        child: ListView(
          padding: EdgeInsets.only(bottom: _fabClearance, left: tokens.spacing.lg, right: tokens.spacing.lg),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardHero(now: now),
                    if (showQuote) ...[
                      DashboardQuoteCard(prefersArabic: prefersArabic),
                      SizedBox(height: tokens.spacing.lg),
                    ],
                    if (isOffline) ...[OfflineBanner(isOffline: isOffline), SizedBox(height: tokens.spacing.md)],
                    const DashboardStorageWarning(),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columnCount = DashboardColumnPlanner.columnCountFor(constraints.maxWidth);
                        final columns = DashboardColumnPlanner.plan(visibleCards, columnCount);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var index = 0; index < columns.length; index++) ...[
                              if (index > 0) SizedBox(width: tokens.spacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    for (final card in columns[index])
                                      Padding(
                                        padding: EdgeInsets.only(bottom: tokens.spacing.lg),
                                        child: _buildCard(card, ref, isWide: columnCount > 1),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
