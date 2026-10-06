import 'package:abdalsalam/data/models/weather/weather_model.dart';
import 'package:abdalsalam/features/dashboard/providers/dashboard_providers.dart';
import 'package:abdalsalam/features/dashboard/screens/dashboard_screen.dart';
import 'package:abdalsalam/features/dashboard/widgets/dashboard_age_card.dart';
import 'package:abdalsalam/features/dashboard/widgets/dashboard_agenda_card.dart';
import 'package:abdalsalam/features/dashboard/widgets/dashboard_quote_card.dart';
import 'package:abdalsalam/features/financial/widgets/currency_rates_widget.dart';
import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/quran_providers.dart';
import 'package:abdalsalam/features/weather/widgets/weather_widget.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../planning/planning_fakes.dart';

final WeatherModel _weather = WeatherModel(
  cityName: 'Nablus',
  temperature: 21,
  feelsLike: 20,
  humidity: 40,
  windSpeed: 3,
  description: 'Clear sky',
  icon: '01d',
  timestamp: DateTime(2026, 1, 1, 12),
);

Future<void> _pumpDashboard(WidgetTester tester, Size size, {Map<String, dynamic> settings = const {}}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appStateManagerProvider.overrideWithValue(logic.AppStateManagerImpl.create(config: const logic.AppStateConfig())),
        prayerCountProvider.overrideWithValue(2),
        quranPagesTodayProvider.overrideWithValue(3),
        appSettingsProvider.overrideWith((ref) async => settings),
        weatherProvider.overrideWith((ref) async => _weather),
        currencyRatesProvider.overrideWith((ref) async => <String, double>{'USD': 0.27, 'JOD': 0.19}),
        usdHistoryProvider.overrideWith((ref) async => []),
        jodHistoryProvider.overrideWith((ref) async => []),
        todaysGoalsProvider.overrideWith((ref) async => []),
        planningTaskRepositoryProvider.overrideWithValue(FakePlanningTaskRepository()),
        taskCategoryRepositoryProvider.overrideWithValue(FakeTaskCategoryRepository()),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stacks every card in one column on a phone without overflow', (tester) async {
    await _pumpDashboard(tester, const Size(390, 900));

    final ageLeft = tester.getTopLeft(find.byType(DashboardAgeCard)).dx;
    final weatherLeft = tester.getTopLeft(find.byType(WeatherWidget)).dx;
    final currencyLeft = tester.getTopLeft(find.byType(CurrencyRatesWidget)).dx;
    expect(weatherLeft, ageLeft);
    expect(currencyLeft, ageLeft);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spreads the cards over several columns on a wide screen without overflow', (tester) async {
    await _pumpDashboard(tester, const Size(1600, 1000));

    final lefts = {
      tester.getTopLeft(find.byType(DashboardAgeCard)).dx,
      tester.getTopLeft(find.byType(WeatherWidget)).dx,
      tester.getTopLeft(find.byType(CurrencyRatesWidget)).dx,
      tester.getTopLeft(find.byType(DashboardAgendaCard)).dx,
    };
    expect(lefts.length, greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('expands the weather details by default on a wide screen only', (tester) async {
    await _pumpDashboard(tester, const Size(1600, 1000));
    expect(find.text('Humidity'), findsOneWidget);

    await _pumpDashboard(tester, const Size(390, 900));
    expect(find.text('Humidity'), findsNothing);
  });

  testWidgets('greets with the date and shows the swapped currency labels', (tester) async {
    await _pumpDashboard(tester, const Size(1600, 1000));

    expect(find.textContaining('Good'), findsOneWidget);
    expect(find.text('1 USD = 3.704 ILS'), findsOneWidget);
    expect(find.text('1 ILS = 0.2700 USD'), findsOneWidget);
  });

  testWidgets('shows the tasks stat tile', (tester) async {
    await _pumpDashboard(tester, const Size(1600, 1000));

    expect(find.text('Tasks today'), findsOneWidget);
    expect(find.text('0 / 0'), findsOneWidget);
  });

  for (final size in const [Size(320, 700), Size(600, 900), Size(800, 900), Size(1000, 800), Size(1920, 1080)]) {
    testWidgets('lays out without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await _pumpDashboard(tester, size);

      expect(tester.takeException(), isNull);
      expect(find.byType(WeatherWidget), findsOneWidget);
      expect(find.byType(CurrencyRatesWidget), findsOneWidget);
    });
  }

  testWidgets('shows the quote of the day full width above all other cards', (tester) async {
    await _pumpDashboard(tester, const Size(1600, 1000));

    final quoteRect = tester.getRect(find.byType(DashboardQuoteCard));
    for (final finder in [
      find.byType(DashboardAgeCard),
      find.byType(WeatherWidget),
      find.byType(CurrencyRatesWidget),
      find.byType(DashboardAgendaCard),
    ]) {
      expect(quoteRect.bottom, lessThanOrEqualTo(tester.getTopLeft(finder).dy));
    }
    expect(quoteRect.width, greaterThan(tester.getRect(find.byType(WeatherWidget)).width * 2));
  });

  testWidgets('hides the quote when it is turned off in the dashboard settings', (tester) async {
    await _pumpDashboard(tester, const Size(1600, 1000), settings: {'dashboardShowQuote': false});

    expect(find.byType(DashboardQuoteCard), findsNothing);
  });

  testWidgets('shows the Arabic quote first when the app language is Arabic', (tester) async {
    await _pumpDashboard(tester, const Size(1600, 1000), settings: {'language': 'ar'});
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('quote-arabic'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('quote-english'))).dy),
    );
  });
}
